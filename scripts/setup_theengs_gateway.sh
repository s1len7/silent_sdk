#!/usr/bin/env bash
# theengs-gateway(BLE 센서 -> MQTT) 실행 스크립트
# docker/theengs-gateway/docker-compose.yml 실행 (restart 설정에 따라 재부팅 시 자동 시작)
# 사용법: sudo bash scripts/setup_theengs_gateway.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

repo="$(cd "$(dirname "$0")/.." && pwd)"
docker compose -f "$repo/docker/theengs-gateway/docker-compose.yml" up -d

echo "theengs-gateway started"
