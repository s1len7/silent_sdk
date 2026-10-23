#!/usr/bin/env bash
# 부팅 완료 비프음 활성화 스크립트
# 배선: 능동 부저(High level trigger) I/O - 18번 핀(GPIO24), GND - 20번 핀
# 사용법: sudo bash scripts/setup_boot_beep.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

unit_file=/etc/systemd/system/boot-beep.service
# Type=idle: 부팅 작업이 모두 끝난 뒤 실행되도록 함
unit="$(cat <<'EOF'
[Unit]
Description=Beep when boot is complete

[Service]
Type=idle
ExecStart=/bin/sh -c 'pinctrl set 24 op dh; sleep 0.2; pinctrl set 24 op dl'

[Install]
WantedBy=multi-user.target
EOF
)"

# 서비스 파일이 같고 이미 등록돼 있으면 건너뜀 (테스트 비프음도 울리지 않음)
if [[ -f "$unit_file" && "$(cat "$unit_file")" == "$unit" ]] && systemctl is-enabled --quiet boot-beep.service; then
    skip_done "boot-beep.service is already enabled"
fi

if ! command -v pinctrl >/dev/null 2>&1; then
    echo "pinctrl not found. Install with: sudo apt install raspi-utils" >&2
    exit 1
fi

printf '%s\n' "$unit" > "$unit_file"
systemctl daemon-reload
systemctl enable boot-beep.service
echo "boot-beep.service enabled"

# 설치 확인용으로 한 번 울림
systemctl start boot-beep.service
echo "Test beep sent on GPIO24 (pin 18)"
