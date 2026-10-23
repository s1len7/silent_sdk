#!/usr/bin/env bash
# Docker 설치 + Portainer Agent 실행 스크립트 (라즈베리파이 OS 기본 저장소 사용)
# 사용법: sudo bash scripts/setup_docker.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

user_name="${SUDO_USER:-$(whoami)}"
portainer_image=portainer/agent:2.39.4

# 패키지, docker 그룹, 실행 중인 Portainer Agent(같은 버전)가 모두 있으면 건너뜀
if pkgs_installed docker.io docker-compose && id -nG "$user_name" | grep -qw docker \
    && [[ "$(docker ps --filter name=^portainer_agent$ --filter status=running --format '{{.Image}}')" == "$portainer_image" ]]; then
    skip_done "Docker and Portainer Agent are already set up"
fi

# 1. Docker 설치
echo "[1/4] Installing Docker packages"
apt-get update
apt-get install -y docker.io docker-compose

# 2. sudo 없이 docker 명령을 쓸 수 있도록 사용자를 docker 그룹에 추가
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
  "$portainer_image"

echo "Docker installed. Log out and back in to use docker without sudo."
