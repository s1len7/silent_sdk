#!/usr/bin/env bash
# Cline CLI 설치 (npm, cline)
# - 사용자 Node.js(~/.local/node, setup_nodejs가 설치)에 전역 설치하고 ~/.local/bin/cline으로 링크
# - 로그인·API 키는 설정하지 않음 (첫 실행에서 /connect로 모델 제공자 연결)
# - 이미 설치돼 있으면 건너뜀
# - Node.js가 먼저 설치돼 있어야 함 (setup_nodejs)
# Docs: https://cline.bot
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PATH="$LOCAL_BIN:$PATH"

if command -v cline >/dev/null 2>&1; then
    skip_done "Cline CLI is already installed ($(command -v cline))"
fi

echo "Installing the Cline CLI (npm, latest)"
npm_global_install cline@latest cline
cline --version
echo "Cline CLI setup done: run 'cline' in a new terminal"
