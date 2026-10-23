#!/usr/bin/env bash
# uxplay(AirPlay 화면 미러링 수신) 설치 및 자동실행 설정 스크립트
# 저장소의 .config/autostart/uxplay.desktop을 사용자 ~/.config/autostart/에 복사
# 사용법: sudo bash scripts/setup_uxplay.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

apt-get update
apt-get install -y uxplay

# sudo로 실행해도 실제 로그인 사용자의 홈에 적용
user_name="${SUDO_USER:-$(whoami)}"
user_home="$(getent passwd "$user_name" | cut -d: -f6)"

src="$(cd "$(dirname "$0")/.." && pwd)/.config/autostart/uxplay.desktop"
dst="$user_home/.config/autostart/uxplay.desktop"

mkdir -p "$(dirname "$dst")"
# 원본이 Windows에서 편집된 경우를 대비해 CR 제거
tr -d '\r' < "$src" > "$dst"
chown -R "$user_name:" "$user_home/.config/autostart"

echo "Copied uxplay.desktop to $dst"
echo "uxplay will start automatically on next login."
