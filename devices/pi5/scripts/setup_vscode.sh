#!/usr/bin/env bash
# VS Code 설치
# Raspberry Pi OS 저장소(archive.raspberrypi.com)에 code 패키지가 있으므로 apt로 바로 설치함
# (설치하면 code 패키지가 Microsoft 저장소를 apt 목록에 추가해 이후 업데이트도 apt로 받음)
# 사용법: sudo bash scripts/setup_vscode.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# code 패키지가 설치돼 있으면 건너뜀
if pkgs_installed code; then
    skip_done "VS Code is already installed"
fi

echo "[1/1] Installing VS Code (code)"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y code

if ! command -v code >/dev/null; then
    echo "code command not found after installing VS Code" >&2
    exit 1
fi

echo "VS Code installed: $(code --version 2>/dev/null | head -n 1)"
