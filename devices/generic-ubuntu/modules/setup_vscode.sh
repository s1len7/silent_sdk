#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if command -v code >/dev/null 2>&1; then
    skip_done "VS Code is already installed"
fi

echo "Installing VS Code"
if command -v apt-get >/dev/null 2>&1; then
    # Microsoft 저장소가 없을 때만 추가 (스크립트를 다시 실행해도 같은 내용을 다시 쓰지 않음)
    # .list/.sources 어느 형식으로든 이미 있으면 건너뜀
    if ! compgen -G "/etc/apt/sources.list.d/vscode.*" >/dev/null; then
        # wget/gpg는 Ubuntu에 기본 포함이므로 없을 때만 설치
        need=()
        for p in wget gpg; do
            dpkg -s "$p" >/dev/null 2>&1 || need+=("$p")
        done
        if [[ ${#need[@]} -gt 0 ]]; then
            echo "Installing missing packages: ${need[*]}"
            sudo apt-get update -y
            sudo apt-get install -y "${need[@]}"
        fi
        wget -qO- https://packages.microsoft.com/keys/microsoft.asc |
            gpg --dearmor | sudo tee /etc/apt/trusted.gpg.d/packages.microsoft.gpg >/dev/null
        echo "deb [arch=amd64,arm64,armhf signed-by=/etc/apt/trusted.gpg.d/packages.microsoft.gpg] https://packages.microsoft.com/repos/code stable main" |
            sudo tee /etc/apt/sources.list.d/vscode.list >/dev/null
        sudo apt-get update -y
    fi
    sudo apt-get install -y code
elif command -v snap >/dev/null 2>&1; then
    sudo snap install code --classic
else
    echo "No supported package manager for VS Code; install it manually" >&2
    exit 1
fi

if command -v code >/dev/null 2>&1; then
    echo "VS Code setup done"
    exit 0
fi
echo "VS Code not found after install" >&2
exit 1
