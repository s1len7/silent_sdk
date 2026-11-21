#!/usr/bin/env bash
# Codex CLI 설치 (npm, @openai/codex)
# - 사용자 Node.js(~/.local/node, setup_nodejs가 설치)에 전역 설치하고 ~/.local/bin/codex로 링크
# - 로그인·API 키는 설정하지 않음 (첫 실행에서 OpenAI 계정으로 로그인)
# - 이미 설치돼 있으면 건너뜀
# - Node.js가 먼저 설치돼 있어야 함 (setup_nodejs)
# Docs: https://github.com/openai/codex
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PATH="$LOCAL_BIN:$PATH"

if command -v codex >/dev/null 2>&1; then
    skip_done "Codex CLI is already installed ($(command -v codex))"
fi

echo "Installing the Codex CLI (npm, latest)"
npm_global_install @openai/codex@latest codex
codex --version
echo "Codex CLI setup done: run 'codex' in a new terminal"
