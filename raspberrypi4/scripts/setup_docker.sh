#!/usr/bin/env bash
# Docker 설치 + Portainer Agent 실행 스크립트 (라즈베리파이 OS 기본 저장소 사용)
# 사용법: sudo bash scripts/setup_docker.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

# 1. Docker 설치
echo "[1/4] Installing Docker packages"
apt-get update
apt-get install -y docker.io docker-compose

# 2. sudo 없이 docker 명령을 쓸 수 있도록 사용자를 docker 그룹에 추가
user_name="${SUDO_USER:-$(whoami)}"
echo "[2/4] Adding $user_name to docker group"
usermod -aG docker "$user_name"

# 3. 동작 테스트
echo "[3/4] Running hello-world test"
docker run --rm hello-world

# 4. Portainer Agent 실행 (이미 있으면 지우고 다시 생성)
echo "[4/4] Starting Portainer Agent on port 9001"
docker rm -f portainer_agent >/dev/null 2>&1 || true
docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.39.4

echo "Docker installed. Log out and back in to use docker without sudo."
