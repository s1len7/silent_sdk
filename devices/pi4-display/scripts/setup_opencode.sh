#!/usr/bin/env bash
# OpenCode CLI 설치 (npm opencode-ai, 사용자 범위)
# 사용자의 ~/.local에 설치해 ~/.local/bin/opencode로 둠
# ~/.local/bin은 Debian 기본 ~/.profile이 PATH에 넣으므로 프로필은 고치지 않음 (폴더가 처음 생기면 다시 로그인해야 PATH에 들어감)
# 사용자 범위에 두면 업데이트에 sudo가 필요 없음: npm install -g --prefix ~/.local opencode-ai@latest
# 사용법: sudo bash scripts/setup_opencode.sh
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
opencode_bin="$prefix/bin/opencode"

# 사용자 범위에 설치돼 있고 실행되면 건너뜀
if [[ -x "$opencode_bin" ]] && sudo -u "$user" -H "$opencode_bin" --version >/dev/null 2>&1; then
    skip_done "OpenCode CLI is already installed ($opencode_bin)"
fi

# 1. Node.js/npm (Raspberry Pi OS에는 기본으로 없음)
if command -v npm >/dev/null; then
    echo "[1/2] npm is already installed"
else
    echo "[1/2] Installing nodejs and npm"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y nodejs npm
fi

# 2. OpenCode CLI: 사용자 권한으로 설치해 파일이 사용자 소유가 되게 함
echo "[2/2] Installing the OpenCode CLI (npm opencode-ai@latest) to $prefix for $user"
sudo -u "$user" -H npm install -g --prefix "$prefix" opencode-ai@latest

if ! version="$(sudo -u "$user" -H "$opencode_bin" --version 2>/dev/null)"; then
    echo "OpenCode CLI does not run after install: $opencode_bin" >&2
    exit 1
fi

echo "OpenCode CLI $version installed at $opencode_bin"
echo "Run 'opencode' in a new terminal (log out and back in if the command is not found)."
