#!/usr/bin/env bash
# 화면 자동회전(센서 + 트레이 토글) 설치 스크립트
# toggle_rotate/auto_rotate.py를 ~/toggle_rotate/에 복사하고 로그인 시 자동실행 등록
# 사용법: sudo bash scripts/setup_auto_rotate.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# wlr-randr: 화면 회전, gpiozero: 센서, gi: 트레이 아이콘
packages=(wlr-randr python3-gpiozero python3-gi)

# sudo로 실행해도 실제 로그인 사용자의 홈에 적용
user_name="${SUDO_USER:-$(whoami)}"
user_home="$(getent passwd "$user_name" | cut -d: -f6)"
repo="$(cd "$(dirname "$0")/.." && pwd)"
py_dst="$user_home/toggle_rotate/auto_rotate.py"
desktop_dst="$user_home/.config/autostart/auto_rotate.desktop"

# 원본이 Windows에서 편집된 경우를 대비해 CR 제거
py_src() { tr -d '\r' < "$repo/toggle_rotate/auto_rotate.py"; }
# .desktop의 @HOME@을 실제 홈 경로로 치환 (Exec에서는 ~가 확장되지 않음)
desktop_src() { tr -d '\r' < "$repo/.config/autostart/auto_rotate.desktop" | sed "s|@HOME@|$user_home|"; }

# 패키지가 있고 설치된 파일이 저장소와 같으면 건너뜀
if pkgs_installed "${packages[@]}" && cmp -s <(py_src) "$py_dst" && cmp -s <(desktop_src) "$desktop_dst"; then
    skip_done "Auto rotate is already installed"
fi

apt-get update
apt-get install -y "${packages[@]}"

mkdir -p "$(dirname "$py_dst")" "$(dirname "$desktop_dst")"
py_src > "$py_dst"
desktop_src > "$desktop_dst"
chown -R "$user_name:" "$user_home/toggle_rotate" "$user_home/.config/autostart"

echo "Installed $py_dst"
echo "Auto rotate will start automatically on next login."
