#!/usr/bin/env bash
# 부팅 완료 비프음 활성화 스크립트
# 배선: 능동 부저(High level trigger) I/O - 18번 핀(GPIO24), GND - 20번 핀
# 사용법: sudo bash scripts/setup_boot_beep.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

if ! command -v pinctrl >/dev/null 2>&1; then
    echo "pinctrl not found. Install with: sudo apt install raspi-utils" >&2
    exit 1
fi

# Type=idle: 부팅 작업이 모두 끝난 뒤 실행되도록 함
cat > /etc/systemd/system/boot-beep.service <<'EOF'
[Unit]
Description=Beep when boot is complete

[Service]
Type=idle
ExecStart=/bin/sh -c 'pinctrl set 24 op dh; sleep 0.2; pinctrl set 24 op dl'

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable boot-beep.service
echo "boot-beep.service enabled"

# 설치 확인용으로 한 번 울림
systemctl start boot-beep.service
echo "Test beep sent on GPIO24 (pin 18)"
