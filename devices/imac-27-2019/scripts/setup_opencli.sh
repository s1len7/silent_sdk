#!/usr/bin/env bash
# OpenCLI 설치 (웹사이트를 CLI로 다루는 도구, @jackwener/opencli)
# - npm으로 CLI를 사용자 범위에 설치하고 ~/.local/bin/opencli로 링크
# - AI 에이전트용 스킬(opencli-browser 등)도 npx skills로 전역 설치
# - 이미 설치돼 있으면 건너뜀
# - Node.js가 먼저 설치돼 있어야 함 (setup_nodejs)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PATH="$LOCAL_BIN:$PATH"

cli_done=0
if command -v opencli >/dev/null 2>&1; then
    cli_done=1
fi
skill_done=0
if [[ -f "$HOME/.agents/skills/opencli-browser/SKILL.md" ]]; then
    skill_done=1
fi

if (( cli_done && skill_done )); then
    skip_done "OpenCLI is already installed ($(command -v opencli)) with skills"
fi

if (( ! cli_done )); then
    echo "Installing the OpenCLI (npm, latest)"
    npm_global_install @jackwener/opencli opencli
    opencli --version
fi

if (( ! skill_done )); then
    echo "Installing OpenCLI skills for AI agents"
    PATH="$LOCAL_BIN:$PATH" npx --yes skills add jackwener/opencli -g -a '*' -y >/dev/null 2>&1 || true
    if [[ ! -f "$HOME/.agents/skills/opencli-browser/SKILL.md" ]]; then
        echo "OpenCLI skills are not installed after running npx skills" >&2
        exit 1
    fi
    echo "OpenCLI skills installed"
fi
echo "OpenCLI setup done: run 'opencli' in a new terminal"
