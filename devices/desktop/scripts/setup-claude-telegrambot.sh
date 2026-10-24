#!/usr/bin/env bash
# Claude Code hook: 작업이 끝나면(Stop), 권한 승인을 기다리면(Notification) 텔레그램으로 알림
# 사용자가 질문을 보낼 때(UserPromptSubmit) 질문 앞부분을 세션별로 저장해 두고 알림에 request로 넣음
# setup-claude-telegrambot.ps1이 ~/.claude/hooks/telegram-notify.sh로 복사하고 settings.json에 hook으로 등록함
# 토큰과 chat id는 ~/.claude/telegram.env (TELEGRAM_BOT_TOKEN, TELEGRAM_CHAT_ID)
# chat id 찾기: 봇에게 아무 메시지나 보낸 뒤 bash ~/.claude/hooks/telegram-notify.sh chat-id
set -uo pipefail
# 한글을 바이트가 아닌 글자 단위로 자르기 위해 UTF-8 로캘 사용
export LC_ALL=C.UTF-8

conf="$HOME/.claude/telegram.env"
state_dir="$HOME/.claude/telegram-state"
request_max=60
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
# 이스케이프된 따옴표(\")가 있어도 값 끝까지 읽고, \n·\t는 공백, \"·\\는 원래 문자로 바꿈
field() {
    printf '%s' "$input" \
        | sed -nE "s/.*\"$1\"[[:space:]]*:[[:space:]]*\"((\\\\.|[^\"\\\\])*)\".*/\1/p" \
        | head -n 1 \
        | sed -E 's/\\[nrt]/ /g; s/\\"/"/g; s/\\\\/\\/g'
}
event="$(field hook_event_name)"
session="$(field session_id)"
# 세션 id는 파일 이름에 쓰므로 안전한 문자만 남김
session="${session//[^A-Za-z0-9_-]/}"
state_file="$state_dir/${session:-default}.request"

# 질문을 보낼 때: 한 줄로 만들고 앞부분만 저장 (알림은 보내지 않음), 7일 지난 파일은 정리
if [[ "$event" == UserPromptSubmit ]]; then
    request="$(field prompt | tr -s '[:space:]' ' ')"
    request="${request# }"
    (( ${#request} > request_max )) && request="${request:0:request_max}..."
    mkdir -p "$state_dir"
    printf '%s' "${request//\"/\'}" > "$state_file"
    find "$state_dir" -name '*.request' -mtime +7 -delete 2>/dev/null
    exit 0
fi

cwd="$(field cwd)"
workspace="${cwd##*[\\/]}"
request=""
[[ -f "$state_file" ]] && request="$(cat "$state_file")"

# 메시지 형식: 항목마다 쉼표 뒤에서 줄을 바꿈, ai 값으로 OpenClaw 알림과 구분
nl=$'\n'
head="[Info] ai=\"Claude Code\",${nl}workspace=\"$workspace\",${nl}"
[[ -n "$request" ]] && head+="request=\"$request\",${nl}"
case "$event" in
    Notification) text="${head}event=\"input needed\",${nl}message=\"$(field message)\"" ;;
    Stop) text="${head}event=\"done\"" ;;
    *) exit 0 ;;
esac

# 본문은 표준 입력으로 넘김: Windows용 curl은 명령줄 인자를 시스템 코드페이지로 받아 한글이 깨지고
# 텔레그램이 "strings must be encoded in UTF-8"로 거부함
printf '%s' "$text" | curl -s -m 10 -o /dev/null "$api/sendMessage" \
    --data-urlencode "chat_id=$chat_id" \
    --data-urlencode "text@-"
