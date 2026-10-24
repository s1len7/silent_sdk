#!/usr/bin/env bash
# Claude Code hook: 작업이 끝나면(Stop), 입력이 필요하면(Notification) 텔레그램으로 알림
# setup-claude-telegram.ps1이 ~/.claude/hooks/telegram-notify.sh로 복사하고 settings.json에 hook으로 등록함
# 토큰과 chat id는 ~/.claude/telegram.env (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID)
# chat id 찾기: 봇에게 아무 메시지나 보낸 뒤 bash ~/.claude/hooks/telegram-notify.sh chat-id
set -uo pipefail

conf="$HOME/.claude/telegram.env"
[[ -f "$conf" ]] || exit 0
# Windows에서 편집해 CR이 들어갔으면 제거
# shellcheck source=/dev/null
source <(sed 's/\r$//' "$conf")
token="${TELEGRAM_BOT_TOKEN:-}"
chat_id="${TELEGRAM_CHAT_ID:-}"
[[ -n "$token" ]] || exit 0
api="https://api.telegram.org/bot$token"

if [[ "${1:-}" == chat-id ]]; then
    ids="$(curl -s -m 10 "$api/getUpdates" | grep -oE '"chat":\{"id":-?[0-9]+' | grep -oE -- '-?[0-9]+$' | sort -u)"
    if [[ -z "$ids" ]]; then
        echo "No chat found. Send any message to the bot in Telegram, then run this again." >&2
        exit 1
    fi
    echo "$ids"
    exit 0
fi

[[ -n "$chat_id" ]] || exit 0

input="$(cat)"
# hook JSON의 최상위 문자열 값을 읽음 (Windows에 jq가 없을 수 있어 sed 사용)
field() {
    printf '%s' "$input" | sed -n "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"\([^\"]*\)\".*/\1/p" | head -n 1
}
event="$(field hook_event_name)"
cwd="$(field cwd)"
workspace="${cwd##*[\\/]}"

# 메시지 형식: 항목마다 쉼표 뒤에서 줄을 바꿈, ai 값으로 OpenClaw 알림과 구분
nl=$'\n'
head="[Info] ai=\"Claude Code\",${nl}workspace=\"$workspace\",${nl}"
case "$event" in
    Notification) text="${head}event=\"input needed\",${nl}message=\"$(field message)\"" ;;
    Stop) text="${head}event=\"done\"" ;;
    *) exit 0 ;;
esac

curl -s -m 10 -o /dev/null "$api/sendMessage" \
    --data-urlencode "chat_id=$chat_id" \
    --data-urlencode "text=$text"
