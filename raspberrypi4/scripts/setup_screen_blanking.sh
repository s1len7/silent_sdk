#!/usr/bin/env bash
# 화면끄기 설정 스크립트 (labwc)
# ~/.config/labwc/autostart에 swayidle 줄을 넣어 일정 시간 입력이 없으면 화면을 끔
# raspi-config의 Screen Blanking과 같은 방식이며 시간만 직접 지정
# 사용법: sudo bash scripts/setup_screen_blanking.sh
set -euo pipefail

# 화면이 꺼지기까지 입력 없는 시간(초)
timeout=5

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

# sudo로 실행해도 실제 로그인 사용자의 홈에 적용
user_name="${SUDO_USER:-$(whoami)}"
user_home="$(getent passwd "$user_name" | cut -d: -f6)"
autostart="$user_home/.config/labwc/autostart"
line="swayidle -w timeout $timeout 'wlopm --off \*' resume 'wlopm --on \*' &"

source "$(dirname "$0")/lib.sh"

# 같은 설정의 swayidle 줄 하나만 있으면 건너뜀
if [[ -f "$autostart" && "$(grep -c swayidle "$autostart")" == 1 ]] && grep -qxF "$line" "$autostart"; then
    skip_done "Screen blanking is already set to ${timeout}s"
fi

mkdir -p "$(dirname "$autostart")"
touch "$autostart"

# 기존 swayidle 줄을 지우고 새로 추가 (여러 번 실행해도 중복 없음)
sed -i '/swayidle/d' "$autostart"
echo "$line" >> "$autostart"

chmod +x "$autostart"
chown -R "$user_name:" "$user_home/.config/labwc"

echo "Screen blanking set to ${timeout}s in $autostart"
echo "Reboot or log in again to apply."
