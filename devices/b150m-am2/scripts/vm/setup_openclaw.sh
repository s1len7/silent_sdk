#!/usr/bin/env bash
# OpenClaw 설치 스크립트 (Ubuntu Server VM 안에서 실행, Proxmox 호스트에서는 실행하지 않음)
# 공식 설치 스크립트(https://openclaw.ai/install.sh)를 사용자 권한으로 실행해 OpenClaw를 사용자 npm 경로에 설치
# 공식 스크립트는 Node·git·빌드 도구가 없으면 내부에서 sudo로 설치하는데, 터미널 없이 비밀번호를 물으면 멈추므로
# 이 스크립트가 root로 먼저 설치함 (공식 스크립트와 같은 패키지, Node는 같은 NodeSource 24.x)
# 온보딩(모델 제공자, API 키)은 대화형이라 설치 후 사용자가 직접 실행
# 사용법: sudo bash scripts/vm/setup_openclaw.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/../lib.sh"

if command -v pveversion >/dev/null; then
    echo "This is the Proxmox host. Run this script inside the Ubuntu VM." >&2
    exit 1
fi

user_name="${SUDO_USER:-}"
if [[ -z "$user_name" || "$user_name" == root ]]; then
    echo "Run with sudo from the user account that will run OpenClaw (not as root)." >&2
    exit 1
fi

node_major=24
build_pkgs=(git curl ca-certificates build-essential python3 make g++ cmake)
linger_file="/var/lib/systemd/linger/$user_name"

# 사용자 로그인 셸 기준으로 openclaw를 찾음 (공식 스크립트가 PATH를 ~/.profile 등에 추가함)
openclaw_installed() {
    sudo -u "$user_name" -H bash -lc 'command -v openclaw' >/dev/null 2>&1
}

# OpenClaw가 설치돼 있고 linger가 켜져 있으면 건너뜀 (업데이트는 사용자가 npm i -g openclaw@latest로 직접 함)
if openclaw_installed && [[ -f "$linger_file" ]]; then
    skip_done "OpenClaw is already installed for $user_name"
fi

export DEBIAN_FRONTEND=noninteractive NEEDRESTART_MODE=a

if ! openclaw_installed; then
    # 1. 공식 스크립트가 sudo로 설치하려는 패키지를 미리 설치
    echo "[1/4] Installing git and build tools"
    apt-get update
    apt-get install -y "${build_pkgs[@]}"

    # 2. Node.js: NodeSource 저장소의 최신 24.x로 설치·업데이트
    #    요구 버전은 공식 스크립트가 바뀔 때마다 올라가므로 여기서 비교하지 않고 공식 스크립트의 검사에 맡김
    echo "[2/4] Installing Node.js $node_major"
    if ! compgen -G "/etc/apt/sources.list.d/nodesource*" >/dev/null; then
        nodesource="$(mktemp)"
        curl -fsSL "https://deb.nodesource.com/setup_${node_major}.x" -o "$nodesource"
        bash "$nodesource"
        rm -f "$nodesource"
    fi
    apt-get install -y nodejs
    echo "Node.js $(node -v)"

    # 3. 공식 설치 스크립트를 사용자 권한으로 실행 (온보딩은 건너뜀)
    echo "[3/4] Running the official OpenClaw installer as $user_name"
    installer="$(mktemp)"
    curl -fsSL --proto '=https' --tlsv1.2 https://openclaw.ai/install.sh -o "$installer"
    chmod 644 "$installer"
    sudo -u "$user_name" -H bash "$installer" --no-onboard --no-prompt
    rm -f "$installer"

    if ! openclaw_installed; then
        echo "openclaw command not found for $user_name after install." >&2
        exit 1
    fi
fi

# 4. Gateway는 사용자 systemd 서비스라서, 로그인하지 않아도 부팅 시 실행되도록 linger를 켬
echo "[4/4] Enabling systemd linger for $user_name"
loginctl enable-linger "$user_name"

echo "OpenClaw installed. Next, as $user_name, run: openclaw onboard --install-daemon"
