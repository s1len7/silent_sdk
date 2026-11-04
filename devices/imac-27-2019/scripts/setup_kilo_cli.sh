#!/usr/bin/env bash
# Kilo Code CLI 설치 (npm, @kilocode/cli)
# - 사용자 Node.js(~/.local/node, setup_nodejs가 설치)에 전역 설치하고 ~/.local/bin/kilo로 링크
# - 로그인·API 키는 설정하지 않음 (첫 실행에서 /connect로 연결)
# - 이미 설치돼 있으면 건너뜀
# - Node.js가 먼저 설치돼 있어야 함 (setup_nodejs)
# Docs: https://kilo.ai/docs/code-with-ai/platforms/cli
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PATH="$LOCAL_BIN:$PATH"

if command -v kilo >/dev/null 2>&1; then
    skip_done "Kilo Code CLI is already installed ($(command -v kilo))"
fi

echo "Installing the Kilo Code CLI (npm, latest)"
npm_global_install @kilocode/cli@latest kilo
kilo --version
echo "Kilo Code CLI setup done: run 'kilo' in a new terminal. Use /connect on first run"
