#!/usr/bin/env bash
# 텔레그램 알림 전용 봇으로 메시지를 보낸다 (설치 없이 바로 실행).
# 설정: 같은 장비 폴더의 .env에 TELEGRAM_NOTIFY_BOT_TOKEN, TELEGRAM_NOTIFY_CHAT_ID
#       (CHAT_ID가 비어 있으면 TELEGRAM_ALLOW_FROM을 쓴다)
# 이 봇은 발신 전용이므로 getUpdates를 호출하지 않는다 (폴러를 띄우면 409 충돌).
# 사용법: notify_telegram.sh "<내용>" [에이전트] [호스트]
# 메시지 형식: [<호스트>][<에이전트>] <내용>, 4096자를 넘으면 자른다.
# 전송에 실패해도 경고만 남기고 종료 코드 0을 돌려준다 (알림이 작업을 막지 않게).
set -uo pipefail

script_dir="$(cd "$(dirname "$0")" && pwd)"
device_dir="$(cd "$script_dir/.." && pwd)"
env_file="$device_dir/.env"

if [[ $# -lt 1 || -z "${1//[[:space:]]/}" ]]; then
    echo "Usage: $(basename "$0") <text> [agent] [host]" >&2
    exit 2
fi

text="$1"
agent="${2:-manual}"
if [[ -n "${3:-}" ]]; then
    host="$3"
elif command -v scutil >/dev/null 2>&1; then
    # macOS: 사용자가 붙인 컴퓨터 이름 (예: silent-imac)
    host="$(scutil --get ComputerName 2>/dev/null || hostname)"
else
    host="$(hostname)"
fi

# .env에서 값을 읽는다 (마지막 줄을 쓰고, CR과 앞뒤 따옴표를 제거)
read_env() {
    sed -n "s/^[[:space:]]*$1[[:space:]]*=[[:space:]]*//p" "$env_file" 2>/dev/null |
        tail -n 1 | tr -d '\r' |
        sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' -e "s/^[\"']//" -e "s/[\"']$//"
}

token="$(read_env TELEGRAM_NOTIFY_BOT_TOKEN)"
chat_id="$(read_env TELEGRAM_NOTIFY_CHAT_ID)"
if [[ -z "$chat_id" ]]; then
    chat_id="$(read_env TELEGRAM_ALLOW_FROM)"
fi

if [[ -z "$token" || -z "$chat_id" ]]; then
    echo "TELEGRAM_NOTIFY_BOT_TOKEN or TELEGRAM_NOTIFY_CHAT_ID is empty in $env_file, notification skipped" >&2
    exit 0
fi
if [[ ! "$chat_id" =~ ^-?[0-9]+$ ]]; then
    echo "TELEGRAM_NOTIFY_CHAT_ID must be a number, notification skipped" >&2
    exit 0
fi

message="[$host][$agent] $text"
if (( ${#message} > 4096 )); then
    message="${message:0:4093}..."
fi

# JSON 문자열로 바꾼다: 역슬래시·큰따옴표를 이스케이프하고 줄바꿈은 \n으로 쓴다
escape_json() {
    sed -e 's/\\/\\\\/g' -e 's/"/\\"/g' |
        awk 'BEGIN { ORS = "" } { gsub(/\r/, ""); if (NR > 1) printf "\\n"; print }'
}
escaped="$(printf '%s' "$message" | escape_json)"
payload="{\"chat_id\":\"$chat_id\",\"text\":\"$escaped\"}"

# 본문을 임시 파일로 넘긴다: Git Bash처럼 인자 인코딩이 UTF-8이 아닌 환경에서도
# 한글이 깨지지 않는다 (인자로 직접 넘기면 400 strings must be encoded in UTF-8).
payload_file="$(mktemp "${TMPDIR:-/tmp}/silent-notify.XXXXXX")" || exit 0
trap 'rm -f "$payload_file"' EXIT
printf '%s' "$payload" > "$payload_file"

response="$(curl -4 -sS -m 30 -X POST "https://api.telegram.org/bot${token}/sendMessage" \
    -H 'Content-Type: application/json; charset=utf-8' --data-binary @"$payload_file" 2>&1)"
curl_status=$?
if (( curl_status != 0 )); then
    echo "Notification failed: curl exit $curl_status" >&2
    exit 0
fi
if [[ "$response" != *'"ok":true'* ]]; then
    echo "Notification failed: $response" >&2
    exit 0
fi
echo "Notification sent"
