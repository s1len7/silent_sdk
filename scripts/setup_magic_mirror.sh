#!/usr/bin/env bash
# Magic Mirror & MMPM 실행 스크립트
# 한글 폰트 설치 후 docker/magic_mirror/docker-compose.yml 실행
# 사용법: sudo bash scripts/setup_magic_mirror.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

apt-get update
apt-get install -y fonts-nanum fonts-nanum-extra

repo="$(cd "$(dirname "$0")/.." && pwd)"
docker compose -f "$repo/docker/magic_mirror/docker-compose.yml" up -d

echo "Magic Mirror and MMPM started (MMPM on port 7890)"
