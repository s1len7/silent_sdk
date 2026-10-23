#!/usr/bin/env bash
# theengs-gateway(BLE 센서 -> MQTT) 실행 스크립트
# docker/theengs-gateway/docker-compose.yml 실행 (restart 설정에 따라 재부팅 시 자동 시작)
# 사용법: sudo bash scripts/setup_theengs_gateway.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

repo="$(cd "$(dirname "$0")/.." && pwd)"
compose="$repo/docker/theengs-gateway/docker-compose.yml"

# 컨테이너가 모두 실행 중이면 건너뜀
compose_running "$compose" && skip_done "theengs-gateway is already running"

docker compose -f "$compose" up -d

echo "theengs-gateway started"
