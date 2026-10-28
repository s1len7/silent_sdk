#!/usr/bin/env bash
# OpenCode CLI 설치 (사용자 범위 우선: ~/.npm-global 사용)
# PATH는 스크립트가 임의로 바꾸지 않고, 필요하면 추가할 줄을 안내만 함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

user_prefix="$HOME/.npm-global"
original_path="$PATH"

# PATH에 없을 때 ~/.profile에 추가할 줄을 안내 (프로필은 사용자 확인 없이 수정하지 않음)
print_path_hint() {
    echo "Add this line to ~/.profile, then log in again:"
    echo "  export PATH=\"$1:\$PATH\""
}

# PATH에서 바로 실행되면 이미 설정된 것으로 봄
if command -v opencode >/dev/null 2>&1; then
    skip_done "OpenCode CLI is already available ($(command -v opencode))"
fi

# 이전 실행에서 사용자 경로에 설치했지만 PATH에 없는 경우: 다시 설치하지 않고 안내만 함
if [[ -x "$user_prefix/bin/opencode" ]]; then
    echo "OpenCode CLI is installed at $user_prefix/bin/opencode, but not on PATH"
    print_path_hint "$user_prefix/bin"
    exit 0
fi

# Node.js/npm 준비 (Ubuntu Desktop에는 기본 포함되지 않음)
if ! command -v npm >/dev/null 2>&1; then
    echo "npm not found: installing nodejs and npm with apt"
    sudo apt-get update -y
    sudo apt-get install -y nodejs npm
fi

# 사용자 범위 우선: npm 전역 prefix를 사용자 디렉토리로 설정 (권한 오류 방지)
mkdir -p "$user_prefix"
current_prefix="$(npm config get prefix 2>/dev/null || true)"
if [[ "$current_prefix" != "$user_prefix" ]]; then
    npm config set prefix "$user_prefix"
fi
export PATH="$user_prefix/bin:$PATH"

echo "Installing the OpenCode CLI (npm, latest)"
npm install -g opencode-ai@latest

# 설치가 PATH 밖 사용자 prefix에 됐을 수 있으므로 후보 경로를 확인
if ! command -v opencode >/dev/null 2>&1; then
    npm_prefix="$(npm config get prefix 2>/dev/null || true)"
    for dir in "$user_prefix/bin" "${npm_prefix:+$npm_prefix/bin}"; do
        if [[ -n "$dir" && -x "$dir/opencode" ]]; then
            PATH="$dir:$PATH"
            break
        fi
    done
fi

if ! command -v opencode >/dev/null 2>&1; then
    echo "opencode not found after install" >&2
    exit 1
fi

binary_dir="$(dirname "$(command -v opencode)")"
if [[ ":$original_path:" == *":$binary_dir:"* ]]; then
    echo "OpenCode setup done: run 'opencode' in a new terminal"
else
    echo "OpenCode CLI is installed at $binary_dir/opencode, but that folder is not on PATH"
    print_path_hint "$binary_dir"
fi
