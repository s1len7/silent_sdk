#!/usr/bin/env bash
# shairport-sync(AirPlay 오디오 수신) 설치 스크립트
# 패키지 설치 시 서비스가 자동 등록되어 부팅 시 자동실행됨
# 사용법: sudo bash scripts/setup_shairport_sync.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

apt-get update
apt-get install -y shairport-sync

echo "shairport-sync installed."
