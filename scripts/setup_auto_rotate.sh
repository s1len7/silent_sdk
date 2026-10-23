#!/usr/bin/env bash
# 화면 자동회전(센서 + 트레이 토글) 설치 스크립트
# toggle_rotate/auto_rotate.py를 ~/toggle_rotate/에 복사하고 로그인 시 자동실행 등록
# 사용법: sudo bash scripts/setup_auto_rotate.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

# wlr-randr: 화면 회전, gpiozero: 센서, gi: 트레이 아이콘
apt-get update
apt-get install -y wlr-randr python3-gpiozero python3-gi

# sudo로 실행해도 실제 로그인 사용자의 홈에 적용
user_name="${SUDO_USER:-$(whoami)}"
user_home="$(getent passwd "$user_name" | cut -d: -f6)"
repo="$(cd "$(dirname "$0")/.." && pwd)"

# 원본이 Windows에서 편집된 경우를 대비해 CR 제거
mkdir -p "$user_home/toggle_rotate"
tr -d '\r' < "$repo/toggle_rotate/auto_rotate.py" > "$user_home/toggle_rotate/auto_rotate.py"

# .desktop의 @HOME@을 실제 홈 경로로 치환 (Exec에서는 ~가 확장되지 않음)
mkdir -p "$user_home/.config/autostart"
tr -d '\r' < "$repo/.config/autostart/auto_rotate.desktop" \
    | sed "s|@HOME@|$user_home|" > "$user_home/.config/autostart/auto_rotate.desktop"

chown -R "$user_name:" "$user_home/toggle_rotate" "$user_home/.config/autostart"

echo "Installed $user_home/toggle_rotate/auto_rotate.py"
echo "Auto rotate will start automatically on next login."
