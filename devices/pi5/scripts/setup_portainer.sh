#!/usr/bin/env bash
# Portainer CE 서버 설치 스크립트 (Docker)
# docker/portainer/docker-compose.yml로 실행, 웹 UI는 http://<hostname>.local:9000
# setup_docker.sh 다음에 실행할 것
# 사용법: sudo bash scripts/setup_portainer.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

compose="$(cd "$(dirname "$0")/.." && pwd)/docker/portainer/docker-compose.yml"

if ! command -v docker >/dev/null; then
    echo "docker not found. Run setup_docker.sh first." >&2
    exit 1
fi

# 컨테이너가 실행 중이면 건너뜀
if compose_running "$compose"; then
    skip_done "Portainer is already running"
fi

echo "[1/1] Starting Portainer"
docker compose -f "$compose" up -d

echo "Portainer started: http://$(hostname).local:9000"
echo "Create the admin account within 5 minutes, or restart the container: docker restart portainer"
