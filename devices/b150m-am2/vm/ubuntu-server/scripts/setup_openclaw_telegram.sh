#!/usr/bin/env bash
# OpenClaw 텔레그램 채널 설정 스크립트 (Ubuntu Server VM 안에서 실행, setup_openclaw_onboard.sh 다음에 실행)
# vm/ubuntu-server/.env의 TELEGRAM_BOT_TOKEN, TELEGRAM_ALLOW_FROM으로 텔레그램 봇과 대화할 수 있게 함
# 공식 권장대로 한 사람만 쓰는 봇은 dmPolicy=allowlist + allowFrom(숫자 ID)으로 제한하고, 그룹 대화는 끔
# 토큰은 명령줄·설정 파일에 남지 않게 권한 600 파일(tokenFile)로 둠
# 문서: https://docs.openclaw.ai/channels/telegram/access-control
# 사용법: sudo bash vm/ubuntu-server/scripts/setup_openclaw_telegram.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

if command -v pveversion >/dev/null; then
    echo "This is the Proxmox host. Run this script inside the Ubuntu VM." >&2
    exit 1
fi

user_name="${SUDO_USER:-}"
if [[ -z "$user_name" || "$user_name" == root ]]; then
    echo "Run with sudo from the user account that runs OpenClaw (not as root)." >&2
    exit 1
fi

env_file="$(cd "$(dirname "$0")/.." && pwd)/.env"
if [[ -f "$env_file" ]]; then
    # Windows에서 편집해 CR이 들어갔으면 제거
    sed -i 's/\r$//' "$env_file"
    # shellcheck source=/dev/null
    source "$env_file"
fi
bot_token="${TELEGRAM_BOT_TOKEN:-}"
allow_from="${TELEGRAM_ALLOW_FROM:-}"

if [[ -z "$bot_token" || -z "$allow_from" ]]; then
    skip_done "TELEGRAM_BOT_TOKEN or TELEGRAM_ALLOW_FROM is empty in $env_file"
fi
[[ "$allow_from" =~ ^[0-9]+$ ]] || { echo "TELEGRAM_ALLOW_FROM must be a numeric Telegram user ID: $allow_from" >&2; exit 1; }

user_home="$(getent passwd "$user_name" | cut -d: -f6)"
token_file="$user_home/.openclaw/telegram-bot-token"

# 사용자 로그인 셸에서 실행 (systemctl --user가 동작하도록 XDG_RUNTIME_DIR 지정)
as_user() {
    sudo -u "$user_name" -H env XDG_RUNTIME_DIR="/run/user/$(id -u "$user_name")" bash -lc "$1"
}

# 설정 값을 읽음 (배열은 공백·줄바꿈을 빼서 한 줄로)
config_get() {
    as_user "openclaw config get $1 2>/dev/null" | tr -d '[:space:]'
}

if ! as_user 'command -v openclaw' >/dev/null 2>&1 || [[ ! -f "$user_home/.config/systemd/user/openclaw-gateway.service" ]]; then
    echo "OpenClaw gateway is not set up for $user_name. Run setup_openclaw.sh and setup_openclaw_onboard.sh first." >&2
    exit 1
fi

token_ready() { [[ -f "$token_file" && "$(cat "$token_file")" == "$bot_token" ]]; }
config_ready() {
    [[ "$(config_get channels.telegram.tokenFile)" == "$token_file" \
        && "$(config_get channels.telegram.allowFrom)" == "[\"$allow_from\"]" \
        && "$(config_get channels.telegram.dmPolicy)" == allowlist \
        && "$(config_get channels.telegram.groupPolicy)" == disabled \
        && "$(config_get channels.telegram.enabled)" == true ]]
}

if token_ready && config_ready; then
    skip_done "Telegram channel is already set up for $user_name"
fi

# 1. 봇 토큰 파일 (사용자만 읽기)
if ! token_ready; then
    echo "[1/3] Writing the bot token to $token_file"
    printf '%s' "$bot_token" | install -m 600 -o "$user_name" -g "$(id -gn "$user_name")" /dev/stdin "$token_file"
fi

# 2. 채널 설정 (allowlist는 allowFrom이 비어 있으면 검증에서 거부되므로 allowFrom을 먼저 넣음, 재시작 없이 적용됨)
echo "[2/3] Configuring the Telegram channel (allowlist: $allow_from, groups disabled)"
as_user "openclaw config set channels.telegram.tokenFile $token_file"
as_user "openclaw config set channels.telegram.allowFrom '[\"$allow_from\"]'"
as_user 'openclaw config set channels.telegram.dmPolicy allowlist'
as_user 'openclaw config set channels.telegram.groupPolicy disabled'
as_user 'openclaw config set channels.telegram.enabled true'

# 3. 채널이 연결될 때까지 최대 60초 대기
echo "[3/3] Waiting for the Telegram channel to connect"
for _ in {1..30}; do
    status="$(as_user 'openclaw channels status 2>/dev/null' | grep -i '^- Telegram' || true)"
    [[ "$status" == *running* && "$status" == *connected* ]] && break
    sleep 2
done
if [[ "$status" != *running* || "$status" != *connected* ]]; then
    echo "Telegram channel did not connect: ${status:-no status}. Check: openclaw channels logs" >&2
    exit 1
fi

echo "Telegram channel connected: $status"
