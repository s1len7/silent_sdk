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

# 날씨 위치(MM_LAT, MM_LON)는 저장소에 없으므로 .env가 있어야 함
# 없으면 전체 설치(setup.sh)가 멈추지 않도록 경고 후 건너뜀
if [[ ! -f "$repo/docker/magic_mirror/.env" ]]; then
    echo "WARNING: docker/magic_mirror/.env not found, Magic Mirror skipped." >&2
    echo "Run: cp $repo/docker/magic_mirror/.env.example $repo/docker/magic_mirror/.env, fill in MM_LAT and MM_LON, then rerun this script." >&2
    exit 0
fi

docker compose -f "$repo/docker/magic_mirror/docker-compose.yml" up -d

echo "Magic Mirror and MMPM started (MMPM on port 7890)"
