#!/usr/bin/env bash
# Gemini CLI 설치 (npm, @google/gemini-cli)
# - 사용자 Node.js(~/.local/node, setup_nodejs가 설치)에 전역 설치하고 ~/.local/bin/gemini로 링크
# - 로그인·API 키는 설정하지 않음 (첫 실행에서 Google 계정으로 로그인)
# - 이미 설치돼 있으면 건너뜀
# - Node.js가 먼저 설치돼 있어야 함 (setup_nodejs)
# Docs: https://github.com/google-gemini/gemini-cli
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PATH="$LOCAL_BIN:$PATH"

if command -v gemini >/dev/null 2>&1; then
    skip_done "Gemini CLI is already installed ($(command -v gemini))"
fi

echo "Installing the Gemini CLI (npm, latest)"
npm_global_install @google/gemini-cli@latest gemini
gemini --version
echo "Gemini CLI setup done: run 'gemini' in a new terminal"
