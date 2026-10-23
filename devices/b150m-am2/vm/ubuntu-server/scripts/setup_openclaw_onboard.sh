#!/usr/bin/env bash
# OpenClaw 온보딩 스크립트 (Ubuntu Server VM 안에서 실행, setup_openclaw.sh 다음에 실행)
# 공식 onboard를 비대화형으로 실행해 Gateway를 사용자 systemd 서비스로 등록 (loopback + token 인증)
# 기본 모델은 무료인 OpenRouter 무료 라우터(openrouter/openrouter/free)로 설정
# vm/ubuntu-server/.env에 OPENROUTER_API_KEY가 있으면 등록하고, 없으면 키 없이 끝냄 (나중에 키를 넣고 다시 실행)
# 사용법: sudo bash vm/ubuntu-server/scripts/setup_openclaw_onboard.sh
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
api_key="${OPENROUTER_API_KEY:-}"

free_model=openrouter/openrouter/free
user_home="$(getent passwd "$user_name" | cut -d: -f6)"
service_file="$user_home/.config/systemd/user/openclaw-gateway.service"

# 사용자 로그인 셸에서 실행 (systemctl --user가 동작하도록 XDG_RUNTIME_DIR 지정, linger로 사용자 systemd가 떠 있음)
as_user() {
    sudo -u "$user_name" -H env XDG_RUNTIME_DIR="/run/user/$(id -u "$user_name")" bash -lc "$1"
}

if ! as_user 'command -v openclaw' >/dev/null 2>&1; then
    echo "openclaw not found for $user_name. Run setup_openclaw.sh first." >&2
    exit 1
fi

gateway_ready() { [[ -f "$service_file" ]]; }
# openclaw는 모델 이름을 줄여서 저장함 (openrouter/openrouter/free -> openrouter/free)
model_ready() { [[ "$(as_user 'openclaw config get agents.defaults.model.primary 2>/dev/null')" == openrouter/free ]]; }
key_ready() {
    [[ -z "$api_key" ]] || as_user 'openclaw models auth list --provider openrouter --json' | grep -q '"openrouter:'
}

if gateway_ready && model_ready && key_ready; then
    skip_done "OpenClaw is already onboarded for $user_name"
fi

# 1. 공식 onboard (비대화형): Gateway는 loopback + token 인증, 채널·스킬은 나중에 사용자가 설정
if ! gateway_ready; then
    echo "[1/3] Running openclaw onboard (gateway service, loopback + token)"
    as_user 'openclaw onboard --non-interactive --accept-risk --mode local --flow quickstart \
        --auth-choice skip --gateway-bind loopback --gateway-auth token --install-daemon \
        --skip-channels --skip-skills --skip-search --skip-ui --suppress-gateway-token-output'
    if ! gateway_ready; then
        echo "Gateway service was not installed: $service_file" >&2
        exit 1
    fi
fi

# 2. 기본 모델을 OpenRouter 무료 라우터로 설정
if ! model_ready; then
    echo "[2/3] Setting the default model to $free_model"
    as_user "openclaw models set $free_model"
fi

# 3. OpenRouter API 키 등록 (명령줄 인자로 넘기면 ps에 보이므로 표준 입력으로 넘김)
if [[ -z "$api_key" ]]; then
    echo "[3/3] OPENROUTER_API_KEY is empty in $env_file. Add the key and run this script again."
elif ! key_ready; then
    echo "[3/3] Saving the OpenRouter API key"
    printf '%s\n' "$api_key" | as_user 'openclaw models auth paste-api-key --provider openrouter'
    as_user 'openclaw gateway restart'
fi

echo "OpenClaw onboarded. Gateway: ws://127.0.0.1:18789 (loopback, connect from other devices via SSH tunnel)"
