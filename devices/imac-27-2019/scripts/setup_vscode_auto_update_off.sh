#!/usr/bin/env bash
# VS Code의 자동 업데이트 확인·업데이트 안내 팝업을 끔 (update.mode=none)
# 사용자 설정(~/Library/Application Support/Code/User/settings.json)의 다른 키는 그대로 둠
# 주석이 있는 JSONC 파일은 jq로 읽을 수 없으므로 덮어쓰지 않고 안내만 함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

settings_dir="$HOME/Library/Application Support/Code/User"
settings_path="$settings_dir/settings.json"

# jq는 macOS 15부터 기본 포함 (/usr/bin/jq)
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. macOS 15 or later includes /usr/bin/jq" >&2
    exit 1
fi

# 현재 설정 (파일이 없거나 비었으면 빈 객체), 잘못된 JSON이면 덮어쓰지 않도록 안내
current='{}'
if [[ -s "$settings_path" ]]; then
    if ! current="$(jq -e 'if type == "object" then . else error("not an object") end' "$settings_path")"; then
        echo "Cannot parse $settings_path (comments or invalid JSON). Set \"update.mode\": \"none\" manually" >&2
        exit 1
    fi
fi

if [[ "$(jq -r '.["update.mode"] // empty' <<<"$current")" == "none" ]]; then
    skip_done "VS Code automatic updates are already off"
fi

merged="$(jq '. + {"update.mode": "none"}' <<<"$current")"
mkdir -p "$settings_dir"
# 임시 파일에 쓴 뒤 바꿔 넣어, 중간에 실패해도 기존 파일이 깨지지 않게 함
tmp_file="$(mktemp "$settings_dir/settings.json.XXXXXX")"
jq . <<<"$merged" > "$tmp_file"
mv "$tmp_file" "$settings_path"
echo "VS Code automatic updates turned off (update.mode=none): $settings_path"
