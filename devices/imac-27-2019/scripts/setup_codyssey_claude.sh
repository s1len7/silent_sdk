#!/usr/bin/env bash
# Codyssey Claude Code 설정: ~/.claude/settings.json의 env를 Codyssey 공개 API로 맞춤
# - ANTHROPIC_BASE_URL/ANTHROPIC_MODEL/ANTHROPIC_SMALL_FAST_MODEL은 항상 새 값으로 맞춤
# - ANTHROPIC_API_KEY가 실제 키(sk-… 등)면 키 입력을 건너뜀
# - 키가 없거나 <virtual-key> 같은 자리표시자면 브라우저에 마스킹 입력창을 띄워 받아 저장
# - 기존 settings.json의 다른 키는 그대로 둠
set -euo pipefail
source "$(dirname "$0")/lib.sh"

settings_dir="$HOME/.claude"
settings_path="$settings_dir/settings.json"
base_url="https://copa.codyssey.kr"
model="claude-opus-4-8"
small_model="claude-haiku-4"

# jq는 macOS 15부터 기본 포함 (/usr/bin/jq)
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. macOS 15 or later includes /usr/bin/jq" >&2
    exit 1
fi

# 현재 설정 (파일이 없거나 비었으면 빈 객체), 잘못된 JSON이면 덮어쓰지 않도록 실패
current='{}'
if [[ -s "$settings_path" ]]; then
    if ! current="$(jq -e 'if type == "object" then . else error("not an object") end' "$settings_path")"; then
        echo "Invalid JSON in $settings_path, fix or remove it" >&2
        exit 1
    fi
fi
if ! jq -e '(.env // {}) | type == "object"' <<<"$current" >/dev/null; then
    echo "Invalid env in $settings_path: .env must be an object" >&2
    exit 1
fi

# 실제 키가 있는지: 비어 있지 않고 <virtual-key> 같은 자리표시자가 아닌 값
api_key="$(jq -r '.env.ANTHROPIC_API_KEY // ""' <<<"$current")"
has_key=0
case "$api_key" in
    ""|*"<"*|*">"*) has_key=0 ;;
    *) has_key=1 ;;
esac

# 기존 키가 base URL에서 유효한지 확인 (200: 유효, 401/403: 무효, 그 외: 확인 불가)
# 키가 명령줄에 남지 않도록 헤더는 표준입력으로 넘김
need_prompt=0
if (( has_key )); then
    status="$(printf 'x-api-key: %s\nanthropic-version: 2023-06-01\n' "$api_key" |
        curl -s -o /dev/null -w '%{http_code}' --max-time 10 -H @- "$base_url/v1/models" 2>/dev/null || true)"
    case "$status" in
        200)
            echo "Existing API key is valid for $base_url"
            ;;
        401|403)
            echo "Existing API key is not valid for $base_url, entering a new key" >&2
            need_prompt=1
            ;;
        *)
            echo "Could not verify the existing API key (HTTP ${status:-unknown}), keeping it" >&2
            ;;
    esac
else
    need_prompt=1
fi

# env의 base URL·모델을 맞춘 결과 (키는 기존 값 유지, 없으면 그대로 없음)
merged="$(jq --arg base "$base_url" --arg model "$model" --arg small "$small_model" '
    .env = ((.env // {}) + {
        "ANTHROPIC_BASE_URL": $base,
        "ANTHROPIC_MODEL": $model,
        "ANTHROPIC_SMALL_FAST_MODEL": $small
    })
' <<<"$current")"

if (( ! need_prompt )); then
    if [[ "$(jq -S . <<<"$current")" == "$(jq -S . <<<"$merged")" ]]; then
        skip_done "Claude Code Codyssey settings are already set ($settings_path)"
    fi
    mkdir -p "$settings_dir"
    tmp_file="$(mktemp "$settings_dir/settings.json.XXXXXX")"
    jq . <<<"$merged" > "$tmp_file"
    mv "$tmp_file" "$settings_path"
    echo "Claude Code Codyssey settings updated: $settings_path"
    exit 0
fi

# 키가 없거나 무효: 브라우저 입력창으로 받아 저장 (python3는 macOS Command Line Tools에 포함)
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found. Run 'xcode-select --install', then run this step again" >&2
    exit 1
fi

mkdir -p "$settings_dir"
base_file="$(mktemp "$settings_dir/codyssey-settings.XXXXXX")"
port_file="$(mktemp "$settings_dir/codyssey-port.XXXXXX")"
done_file="$settings_dir/codyssey-done.$$"
rm -f "$done_file"
jq . <<<"$merged" > "$base_file"

cleanup() {
    [[ -n "${server_pid:-}" ]] && kill "$server_pid" 2>/dev/null || true
    rm -f "$base_file" "$port_file" "$done_file"
}
trap cleanup EXIT

python3 - "$base_file" "$settings_path" "$base_url" "$done_file" >"$port_file" <<'PY' &
import http.server
import json
import os
import sys
import tempfile
import threading
import urllib.error
import urllib.request
from urllib.parse import parse_qs

base_path, output_path, base_url, done_path = sys.argv[1:5]
base_url = base_url.rstrip("/")

PAGE = """<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>Codyssey API 키 입력</title>
<style>
  :root { color-scheme: light dark; }
  * { box-sizing: border-box; }
  body {
    margin: 0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #fff;
    color: #202124;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    padding: 24px;
  }
  main { width: 100%; max-width: 480px; text-align: center; }
  h1 { font-size: 1.5rem; font-weight: 500; margin: 0 0 8px; letter-spacing: -0.01em; }
  p { color: #5f6368; font-size: .95rem; margin: 0 0 28px; line-height: 1.5; }
  .error { color: #d93025; font-size: .9rem; margin: 0 0 16px; }
  form { margin: 0; }
  .field {
    display: flex;
    align-items: center;
    border: 1px solid #dadce0;
    border-radius: 999px;
    padding: 0 8px 0 18px;
    background: #fff;
    transition: border-color .15s, box-shadow .15s;
  }
  .field:focus-within { border-color: #1a73e8; box-shadow: 0 0 0 3px rgba(26,115,232,.15); }
  .field input {
    flex: 1;
    min-width: 0;
    border: 0;
    outline: 0;
    background: transparent;
    padding: 14px 8px;
    font-size: 1rem;
    color: inherit;
  }
  .field input::placeholder { color: #9aa0a6; }
  .toggle {
    flex: none;
    display: grid;
    place-items: center;
    width: 40px;
    height: 40px;
    border: 0;
    border-radius: 50%;
    background: transparent;
    color: #5f6368;
    cursor: pointer;
    transition: background .15s, color .15s;
  }
  .toggle:hover { background: #f1f3f4; color: #202124; }
  .toggle:focus-visible { outline: 2px solid #1a73e8; outline-offset: 2px; }
  .toggle svg { width: 20px; height: 20px; }
  .toggle .eye-off { display: none; }
  .toggle[aria-pressed="true"] .eye-on { display: none; }
  .toggle[aria-pressed="true"] .eye-off { display: block; }
  .submit {
    margin-top: 20px;
    border: 0;
    border-radius: 999px;
    background: #1a73e8;
    color: #fff;
    font-size: .95rem;
    font-weight: 500;
    padding: 12px 28px;
    cursor: pointer;
    transition: background .15s, box-shadow .15s;
  }
  .submit:hover { background: #1765cc; box-shadow: 0 1px 3px rgba(0,0,0,.15); }
  .submit:focus-visible { outline: 2px solid #1a73e8; outline-offset: 2px; }
  .submit:disabled { opacity: .7; cursor: default; }
  .hint { margin: 16px 0 0; font-size: .8rem; color: #80868b; }
  @media (prefers-color-scheme: dark) {
    body { background: #202124; color: #e8eaed; }
    p { color: #9aa0a6; }
    .error { color: #f28b82; }
    .field { background: #202124; border-color: #5f6368; }
    .field input::placeholder { color: #80868b; }
    .toggle { color: #9aa0a6; }
    .toggle:hover { background: #303134; color: #e8eaed; }
  }
</style>
</head>
<body>
<main>
  <h1>Claude Code API 키</h1>
  <p>Codyssey에서 발급받은 Anthropic 호환 API 키를 입력하세요.</p>
  <!--ERROR-->
  <form method="post">
    <div class="field">
      <input id="key" type="password" name="key" autofocus required autocomplete="off" spellcheck="false" placeholder="API 키" aria-label="API 키">
      <button type="button" class="toggle" id="toggle" aria-label="키 보기" aria-pressed="false">
        <svg class="eye-on" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M1 12s4-8 11-8 11 8 11 8-4 8-11 8S1 12 1 12z"/><circle cx="12" cy="12" r="3"/></svg>
        <svg class="eye-off" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M17.94 17.94A10.94 10.94 0 0 1 12 20c-7 0-11-8-11-8a18.45 18.45 0 0 1 5.06-5.94"/><path d="M9.9 4.24A10.94 10.94 0 0 1 12 4c7 0 11 8 11 8a18.5 18.5 0 0 1-2.16 3.19"/><path d="M1 1l22 22"/><path d="M14.12 14.12a3 3 0 1 1-4.24-4.24"/></svg>
      </button>
    </div>
    <button type="submit" class="submit">저장</button>
    <p class="hint">입력한 키는 이 컴퓨터의 ~/.claude/settings.json에만 저장됩니다.</p>
  </form>
</main>
<script>
  const input = document.getElementById('key');
  const toggle = document.getElementById('toggle');
  toggle.addEventListener('click', () => {
    const reveal = input.type === 'password';
    input.type = reveal ? 'text' : 'password';
    toggle.setAttribute('aria-pressed', String(reveal));
    toggle.setAttribute('aria-label', reveal ? '키 숨기기' : '키 보기');
    input.focus();
  });
  const form = document.querySelector('form');
  const submit = document.querySelector('.submit');
  form.addEventListener('submit', () => {
    submit.disabled = true;
    submit.textContent = '확인 중...';
  });
</script>
</body>
</html>"""

DONE = """<!doctype html>
<html lang="ko">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<title>저장됨</title>
<style>
  :root { color-scheme: light dark; }
  body {
    margin: 0;
    min-height: 100vh;
    display: flex;
    align-items: center;
    justify-content: center;
    background: #fff;
    color: #202124;
    font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, "Helvetica Neue", Arial, sans-serif;
    padding: 24px;
  }
  main { text-align: center; max-width: 420px; }
  .check {
    width: 56px;
    height: 56px;
    margin: 0 auto 20px;
    border-radius: 50%;
    display: grid;
    place-items: center;
    background: #e6f4ea;
    color: #137333;
  }
  .check svg { width: 28px; height: 28px; }
  h1 { font-size: 1.4rem; font-weight: 500; margin: 0 0 8px; }
  p { color: #5f6368; font-size: .95rem; margin: 0; line-height: 1.5; }
  @media (prefers-color-scheme: dark) {
    body { background: #202124; color: #e8eaed; }
    p { color: #9aa0a6; }
    .check { background: #1e3a2b; color: #81c995; }
  }
</style>
</head>
<body>
<main>
  <div class="check"><svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true"><path d="M20 6L9 17l-5-5"/></svg></div>
  <h1>저장됨</h1>
  <p>이 탭을 닫아도 됩니다.</p>
</main>
</body>
</html>"""


def page(error=""):
    notice = f'<p class="error">{error}</p>' if error else ""
    return PAGE.replace("<!--ERROR-->", notice)


def check_key(key):
    request = urllib.request.Request(
        base_url + "/v1/models",
        headers={"x-api-key": key, "anthropic-version": "2023-06-01"},
    )
    try:
        with urllib.request.urlopen(request, timeout=10) as response:
            return response.status
    except urllib.error.HTTPError as error:
        return error.code
    except Exception:
        return None


class Handler(http.server.BaseHTTPRequestHandler):
    def _send(self, code, body):
        data = body.encode("utf-8")
        self.send_response(code)
        self.send_header("Content-Type", "text/html; charset=utf-8")
        self.send_header("Content-Length", str(len(data)))
        self.end_headers()
        self.wfile.write(data)

    def do_GET(self):
        self._send(200, page())

    def do_POST(self):
        length = int(self.headers.get("Content-Length", 0))
        key = parse_qs(self.rfile.read(length).decode("utf-8")).get("key", [""])[0].strip()
        if not key:
            self._send(400, page("키가 비어 있습니다. 다시 입력하세요."))
            return
        status = check_key(key)
        if status != 200:
            if status in (401, 403):
                self._send(400, page("키가 유효하지 않습니다. 다시 입력하세요."))
            else:
                self._send(502, page("키를 확인할 수 없습니다. 네트워크를 확인한 뒤 다시 시도하세요."))
            return
        with open(base_path, encoding="utf-8") as source:
            settings = json.load(source)
        settings.setdefault("env", {})["ANTHROPIC_API_KEY"] = key
        fd, tmp = tempfile.mkstemp(dir=os.path.dirname(output_path))
        with os.fdopen(fd, "w", encoding="utf-8") as target:
            json.dump(settings, target, ensure_ascii=False, indent=2)
            target.write("\n")
        os.replace(tmp, output_path)
        with open(done_path, "w", encoding="utf-8"):
            pass
        self._send(200, DONE)
        threading.Thread(target=self.server.shutdown, daemon=True).start()

    def log_message(self, *args):
        pass


server = http.server.HTTPServer(("127.0.0.1", 0), Handler)
print(server.server_address[1], flush=True)
server.serve_forever()
PY
server_pid=$!

# 포트가 준비될 때까지 기다림
port=""
for _ in $(seq 1 50); do
    port="$(cat "$port_file" 2>/dev/null || true)"
    [[ -n "$port" ]] && break
    sleep 0.1
done
if [[ -z "$port" ]]; then
    echo "Failed to start the API key input page" >&2
    exit 1
fi

echo "Opening the API key input page in your browser: http://localhost:$port/"
open "http://localhost:$port/"

# 유효한 키가 저장되면 서버가 완료 표시 파일을 만듦 (최대 5분 대기)
saved=0
for _ in $(seq 1 300); do
    if [[ -e "$done_file" ]]; then
        saved=1
        break
    fi
    sleep 1
done
if (( ! saved )); then
    echo "Timed out waiting for a valid API key. Run this step again." >&2
    exit 1
fi
if ! jq -e '(.env.ANTHROPIC_API_KEY // "") | if type == "string" then (length > 0 and (test("[<>]") | not)) else false end' "$settings_path" >/dev/null 2>&1; then
    echo "API key was not saved correctly. Run this step again." >&2
    exit 1
fi

echo "Claude Code Codyssey settings saved: $settings_path"
