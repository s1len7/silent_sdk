#!/usr/bin/env bash
# Power off 버튼 활성화 스크립트
# 배선: 37번 핀(GPIO26) - 버튼 - 39번 핀(GND)
# 사용법: sudo bash scripts/setup_power_button.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

config=/boot/firmware/config.txt
line="dtoverlay=gpio-shutdown,gpio_pin=26"

if grep -qx "$line" "$config"; then
    skip_done "Power button is already configured in $config"
elif grep -q "^dtoverlay=gpio-shutdown" "$config"; then
    # 다른 설정의 gpio-shutdown이 있으면 GPIO26으로 교체
    sed -i "s|^dtoverlay=gpio-shutdown.*|$line|" "$config"
    echo "Updated existing gpio-shutdown line in $config"
else
    # 파일 끝이 특정 모델 섹션([pi5] 등)일 수 있으므로 [all] 섹션으로 추가
    printf '\n[all]\n%s\n' "$line" >> "$config"
    echo "Added '$line' to $config"
fi

echo "Reboot required to apply: sudo reboot"
