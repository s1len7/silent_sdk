#!/usr/bin/env bash
# OpenClaw Gateway 설치 스크립트 (Docker, 클라우드 모델용)
# docker/openclaw/docker-compose.yml로 Gateway를 실행하고 공식 onboard를 비대화형으로 실행 (랜 공개 + token 인증)
# 기본 모델은 b150m-am2 OpenClaw와 같은 OpenRouter 무료 라우터(openrouter/openrouter/free)
# 이 장비 .env에 OPENROUTER_API_KEY가 있으면 등록하고, 없으면 키 없이 끝냄 (나중에 키를 넣고 다시 실행)
# GEMINI_API_KEY가 있으면 google 제공자 키도 등록 (기본 모델은 그대로)
# setup_docker.sh 다음에 실행할 것
# 사용법: sudo bash scripts/setup_openclaw.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

device_dir="$(cd "$(dirname "$0")/.." && pwd)"
compose="$device_dir/docker/openclaw/docker-compose.yml"
data_dir="$device_dir/docker/openclaw/data"
config="$data_dir/openclaw.json"
env_file="$device_dir/.env"
free_model=openrouter/openrouter/free
# 이미지의 컨테이너 사용자 node의 uid·gid
node_id=1000

if ! command -v docker >/dev/null; then
    echo "docker not found. Run setup_docker.sh first." >&2
    exit 1
fi

if [[ -f "$env_file" ]]; then
    # Windows에서 편집해 CR이 들어갔으면 제거
    sed -i 's/\r$//' "$env_file"
    # shellcheck source=/dev/null
    source "$env_file"
fi
api_key="${OPENROUTER_API_KEY:-}"
gemini_key="${GEMINI_API_KEY:-}"

# openclaw CLI는 Gateway와 같은 PID 네임스페이스에서만 설정을 읽고 쓸 수 있어 실행 중인 컨테이너 안에서 실행함
oc() {
    docker compose -f "$compose" exec -T openclaw node openclaw.mjs "$@"
}
config_get() {
    oc config get "$1" 2>/dev/null | tr -d '[:space:]'
}

# openclaw는 모델 이름을 줄여서 저장함 (openrouter/openrouter/free -> openrouter/free)
model_ready() { [[ "$(config_get agents.defaults.model.primary)" == openrouter/free ]]; }
# grep -q로 바로 파이프하면 pipefail에서 SIGPIPE로 실패할 수 있어 출력을 받아서 비교함
key_ready() {
    [[ -z "$api_key" ]] || [[ "$(oc models auth list --provider openrouter --json 2>/dev/null)" == *'"openrouter:'* ]]
}
gemini_ready() {
    [[ -z "$gemini_key" ]] || [[ "$(oc models auth list --provider google --json 2>/dev/null)" == *'"google:'* ]]
}

# Gateway가 healthy가 될 때까지 기다림 (Raspberry Pi 5에서 시작에 약 1분 걸림)
wait_healthy() {
    local i status
    for ((i = 0; i < 60; i++)); do
        status="$(docker inspect -f '{{.State.Health.Status}}' openclaw 2>/dev/null || true)"
        [[ "$status" == healthy ]] && return 0
        sleep 5
    done
    echo "OpenClaw gateway did not become healthy (status: ${status:-none})" >&2
    docker compose -f "$compose" logs --tail 20 openclaw >&2 || true
    return 1
}

# 온보딩돼 있고, Gateway가 실행 중이고, 모델과 키가 모두 설정돼 있으면 건너뜀
if [[ -f "$config" ]] && compose_running "$compose" && model_ready && key_ready && gemini_ready; then
    skip_done "OpenClaw gateway is already running and onboarded"
fi

# 1. 데이터 폴더 (컨테이너 사용자 node가 쓸 수 있게 소유자를 맞춤)
echo "[1/5] Preparing $data_dir"
mkdir -p "$data_dir"
chown -R "$node_id:$node_id" "$data_dir"

# 2. 공식 onboard (비대화형): Gateway는 랜 공개 + token 인증, 채널·스킬은 나중에 사용자가 설정
#    Gateway가 아직 없으므로 일회용 컨테이너로 실행하고, 서비스 설치·상태 확인은 하지 않음
if [[ ! -f "$config" ]]; then
    echo "[2/5] Running openclaw onboard (lan + token)"
    docker compose -f "$compose" down
    docker compose -f "$compose" run --rm --no-deps -T openclaw node openclaw.mjs onboard \
        --non-interactive --accept-risk --mode local --flow quickstart \
        --auth-choice skip --gateway-bind lan --gateway-auth token --no-install-daemon --skip-health \
        --skip-channels --skip-skills --skip-search --skip-ui --suppress-gateway-token-output
    if [[ ! -f "$config" ]]; then
        echo "Onboarding did not create $config" >&2
        exit 1
    fi
fi

# 3. Gateway 실행
echo "[3/5] Starting OpenClaw gateway"
docker compose -f "$compose" up -d
wait_healthy

# 4. 기본 모델을 OpenRouter 무료 라우터로 설정
restart_needed=false
if ! model_ready; then
    echo "[4/5] Setting the default model to $free_model"
    oc models set "$free_model"
fi

# 5. API 키 등록 (명령줄 인자로 넘기면 ps에 보이므로 표준 입력으로 넘김)
if [[ -z "$api_key" ]]; then
    echo "[5/5] OPENROUTER_API_KEY is empty in $env_file. Add the key and run this script again."
elif ! key_ready; then
    echo "[5/5] Saving the OpenRouter API key"
    printf '%s\n' "$api_key" | oc models auth paste-api-key --provider openrouter
    restart_needed=true
fi
if [[ -z "$gemini_key" ]]; then
    echo "[5/5] GEMINI_API_KEY is empty in $env_file. Add the key and run this script again to use Gemini."
elif ! gemini_ready; then
    echo "[5/5] Saving the Gemini API key"
    printf '%s\n' "$gemini_key" | oc models auth paste-api-key --provider google
    restart_needed=true
fi

if [[ "$restart_needed" == true ]]; then
    docker compose -f "$compose" restart openclaw
    wait_healthy
fi

echo "OpenClaw gateway is running: ws://$(hostname).local:18789 (lan, token auth)"
