#!/usr/bin/env bash
# Docker 설치 스크립트 (라즈베리파이 OS 기본 저장소 사용)
# Trixie의 docker-compose는 v2(2.26)라서 ultrafeeder의 device_cgroup_rules(2.3 이상 필요)를 쓸 수 있음
# 사용법: sudo bash scripts/setup_docker.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

user_name="${SUDO_USER:-$(whoami)}"

# 패키지와 docker 그룹이 모두 있으면 건너뜀
if pkgs_installed docker.io docker-compose && id -nG "$user_name" | grep -qw docker; then
    skip_done "Docker is already set up"
fi

# 1. Docker 설치
echo "[1/3] Installing Docker packages"
apt-get update
apt-get install -y docker.io docker-compose

# 2. sudo 없이 docker 명령을 쓸 수 있도록 사용자를 docker 그룹에 추가
echo "[2/3] Adding $user_name to docker group"
usermod -aG docker "$user_name"

# 3. 동작 테스트
echo "[3/3] Running hello-world test"
docker run --rm hello-world

echo "Docker installed. Log out and back in to use docker without sudo."
