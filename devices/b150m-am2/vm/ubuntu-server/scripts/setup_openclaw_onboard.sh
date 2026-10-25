#!/usr/bin/env bash
# OpenClaw 온보딩 스크립트 (Ubuntu Server VM 안에서 실행, setup_openclaw.sh 다음에 실행)
# 공식 onboard를 비대화형으로 실행해 Gateway를 사용자 systemd 서비스로 등록 (랜 공개 + token 인증)
# 기본 모델은 무료인 OpenRouter 무료 라우터(openrouter/openrouter/free)로 설정
# vm/ubuntu-server/.env에 OPENROUTER_API_KEY가 있으면 등록하고, 없으면 키 없이 끝냄 (나중에 키를 넣고 다시 실행)
# GEMINI_API_KEY가 있으면 google 제공자 키도 등록 (google/* 모델을 고를 수 있게 함, 기본 모델은 그대로)
# 리버스 프록시(NAS의 Nginx Proxy Manager 등)를 거쳐 wss로 접속할 때는 .env의
# OPENCLAW_TRUSTED_PROXY(프록시 IP), OPENCLAW_PUBLIC_ORIGIN(외부 https 주소)을 Gateway 설정에 넣음
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
gemini_key="${GEMINI_API_KEY:-}"
trusted_proxy="${OPENCLAW_TRUSTED_PROXY:-}"
public_origin="${OPENCLAW_PUBLIC_ORIGIN:-}"

if [[ -n "$trusted_proxy" && ! "$trusted_proxy" =~ ^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "OPENCLAW_TRUSTED_PROXY must be an IPv4 address: $trusted_proxy" >&2
    exit 1
fi
# 공식 스키마상 publicOrigin은 https만 허용 (http는 localhost만)
if [[ -n "$public_origin" && ! "$public_origin" =~ ^https://[^/]+$ ]]; then
    echo "OPENCLAW_PUBLIC_ORIGIN must be https://<host> without a path: $public_origin" >&2
    exit 1
fi

free_model=openrouter/openrouter/free
user_home="$(getent passwd "$user_name" | cut -d: -f6)"
service_file="$user_home/.config/systemd/user/openclaw-gateway.service"

# 사용자 로그인 셸에서 실행 (systemctl --user가 동작하도록 XDG_RUNTIME_DIR 지정, linger로 사용자 systemd가 떠 있음)
as_user() {
    sudo -u "$user_name" -H env XDG_RUNTIME_DIR="/run/user/$(id -u "$user_name")" bash -lc "$1"
}

# Gateway 설정 값을 읽음 (배열은 공백·줄바꿈을 빼서 한 줄로)
config_get() {
    as_user "openclaw config get $1 2>/dev/null" | tr -d '[:space:]'
}

if ! as_user 'command -v openclaw' >/dev/null 2>&1; then
    echo "openclaw not found for $user_name. Run setup_openclaw.sh first." >&2
    exit 1
fi

gateway_ready() { [[ -f "$service_file" ]]; }
bind_ready() { [[ "$(config_get gateway.bind)" == lan ]]; }
proxy_ready() { [[ -z "$trusted_proxy" || "$(config_get gateway.trustedProxies)" == "[\"$trusted_proxy\"]" ]]; }
origin_ready() { [[ -z "$public_origin" || "$(config_get gateway.publicOrigin)" == "$public_origin" ]]; }
# openclaw는 모델 이름을 줄여서 저장함 (openrouter/openrouter/free -> openrouter/free)
model_ready() { [[ "$(config_get agents.defaults.model.primary)" == openrouter/free ]]; }
# grep -q로 바로 파이프하면 pipefail에서 SIGPIPE로 실패할 수 있어 출력을 받아서 비교함
key_ready() {
    [[ -z "$api_key" ]] || [[ "$(as_user 'openclaw models auth list --provider openrouter --json')" == *'"openrouter:'* ]]
}
gemini_ready() {
    [[ -z "$gemini_key" ]] || [[ "$(as_user 'openclaw models auth list --provider google --json')" == *'"google:'* ]]
}

if gateway_ready && bind_ready && proxy_ready && origin_ready && model_ready && key_ready && gemini_ready; then
    skip_done "OpenClaw is already onboarded for $user_name"
fi

# 1. 공식 onboard (비대화형): Gateway는 랜 공개 + token 인증, 채널·스킬은 나중에 사용자가 설정
if ! gateway_ready; then
    echo "[1/6] Running openclaw onboard (gateway service, lan + token)"
    as_user 'openclaw onboard --non-interactive --accept-risk --mode local --flow quickstart \
        --auth-choice skip --gateway-bind lan --gateway-auth token --install-daemon \
        --skip-channels --skip-skills --skip-search --skip-ui --suppress-gateway-token-output'
    if ! gateway_ready; then
        echo "Gateway service was not installed: $service_file" >&2
        exit 1
    fi
fi

# 2. 예전에 loopback으로 온보딩한 VM은 랜 공개로 바꿈 (bind 변경은 Gateway 재시작이 필요)
restart_needed=false
if ! bind_ready; then
    echo "[2/6] Opening the gateway to the LAN (gateway.bind=lan)"
    as_user 'openclaw config set gateway.bind lan'
    restart_needed=true
fi

# 3. 리버스 프록시 설정: 프록시만 접속자 정보 헤더를 줄 수 있게 하고, 외부 https 주소를 허용 출처로 둠
if ! proxy_ready; then
    echo "[3/6] Trusting the reverse proxy $trusted_proxy (gateway.trustedProxies)"
    as_user "openclaw config set gateway.trustedProxies '[\"$trusted_proxy\"]'"
fi
if ! origin_ready; then
    echo "[3/6] Setting the public origin $public_origin (gateway.publicOrigin)"
    as_user "openclaw config set gateway.publicOrigin $public_origin"
fi

# 4. 기본 모델을 OpenRouter 무료 라우터로 설정
if ! model_ready; then
    echo "[4/6] Setting the default model to $free_model"
    as_user "openclaw models set $free_model"
fi

# 5. OpenRouter API 키 등록 (명령줄 인자로 넘기면 ps에 보이므로 표준 입력으로 넘김)
if [[ -z "$api_key" ]]; then
    echo "[5/6] OPENROUTER_API_KEY is empty in $env_file. Add the key and run this script again."
elif ! key_ready; then
    echo "[5/6] Saving the OpenRouter API key"
    printf '%s\n' "$api_key" | as_user 'openclaw models auth paste-api-key --provider openrouter'
    restart_needed=true
fi

# 6. Gemini API 키 등록 (google/* 모델을 고를 수 있게 함, 기본 모델은 그대로 OpenRouter)
if [[ -z "$gemini_key" ]]; then
    echo "[6/6] GEMINI_API_KEY is empty in $env_file. Add the key and run this script again to use Gemini."
elif ! gemini_ready; then
    echo "[6/6] Saving the Gemini API key"
    printf '%s\n' "$gemini_key" | as_user 'openclaw models auth paste-api-key --provider google'
    restart_needed=true
fi

if [[ "$restart_needed" == true ]]; then
    as_user 'openclaw gateway restart'
fi

echo "OpenClaw onboarded. Gateway: ws://<VM IP>:18789 (lan, token auth)${public_origin:+, public: ${public_origin/https/wss}}"
