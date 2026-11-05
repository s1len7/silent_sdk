#!/usr/bin/env bash
# Kilo Code CLI 설치 (npm @kilocode/cli, 사용자 범위)
# OpenCode 모듈이 설치한 Node.js·npm을 쓰고, 사용자 ~/.local에 설치해 ~/.local/bin/kilo로 둠
# 로그인·API 키는 설정하지 않음 (첫 실행에서 /connect로 연결)
# 사용법: sudo bash scripts/setup_kilo_cli.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# sudo로 실행해도 sudo한 사용자에게 설치함 (root로 직접 로그인했으면 root)
user="${SUDO_USER:-root}"
user_home="$(getent passwd "$user" | cut -d: -f6)"
if [[ -z "$user_home" || ! -d "$user_home" ]]; then
    echo "Home directory not found for user $user" >&2
    exit 1
fi
prefix="$user_home/.local"
kilo_bin="$prefix/bin/kilo"

# 사용자 범위에 설치돼 있고 실행되면 건너뜀
if [[ -x "$kilo_bin" ]] && sudo -u "$user" -H "$kilo_bin" --version >/dev/null 2>&1; then
    skip_done "Kilo Code CLI is already installed ($kilo_bin)"
fi

# 1. Node.js/npm (OpenCode 모듈이 먼저 설치하지만, 단독 실행도 대비)
if command -v npm >/dev/null; then
    echo "[1/2] npm is already installed"
else
    echo "[1/2] Installing nodejs and npm"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs npm
fi

# 2. Kilo Code CLI: 사용자 권한으로 설치해 파일이 사용자 소유가 되게 함
echo "[2/2] Installing the Kilo Code CLI (npm @kilocode/cli@latest) to $prefix for $user"
sudo -u "$user" -H npm install -g --prefix "$prefix" @kilocode/cli@latest

if ! version="$(sudo -u "$user" -H "$kilo_bin" --version 2>/dev/null)"; then
    echo "Kilo Code CLI does not run after install: $kilo_bin" >&2
    exit 1
fi

echo "Kilo Code CLI $version installed at $kilo_bin"
echo "Run 'kilo' in a new terminal (log out and back in if the command is not found). Use /connect on first run."
