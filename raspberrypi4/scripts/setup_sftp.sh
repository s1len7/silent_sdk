#!/usr/bin/env bash
# SFTP(SSH) 활성화 자동화 스크립트
# 사용법: sudo bash scripts/setup_sftp.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

# 1. raspi-config 비대화형 모드로 SSH 활성화 (0 = enable)
echo "[1/3] Enabling SSH via raspi-config"
raspi-config nonint do_ssh 0

# 2. 서비스 등록 및 시작
echo "[2/3] Enabling and starting ssh service"
systemctl enable ssh
systemctl start ssh

# 3. 상태 확인 및 접속 정보 출력
echo "[3/3] Checking status"
if systemctl is-active --quiet ssh; then
    echo "ssh service is running"
else
    echo "Failed to start ssh service" >&2
    systemctl status ssh --no-pager >&2 || true
    exit 1
fi

user_name="${SUDO_USER:-$(whoami)}"
port="$(sshd -T 2>/dev/null | awk '/^port /{print $2; exit}')"
port="${port:-22}"

echo
echo "Client (e.g. FileZilla) connection info:"
for ip in $(hostname -I); do
    echo "  Host: sftp://${ip}  User: ${user_name}  Port: ${port}"
done
