#!/usr/bin/env bash
# Humanizer 스킬 설치 (AI 글쓰기 흔적 제거 스킬)
# - npx skills로 blader/humanizer를 전역 설치해 Claude Code와 OpenCode에서 /humanizer로 사용
# - 이미 설치돼 있으면 건너뜀
# - Node.js가 먼저 설치돼 있어야 함 (setup_nodejs)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

skill_dir="$HOME/.agents/skills/humanizer"
skill_file="$skill_dir/SKILL.md"

if [[ -f "$skill_file" ]]; then
    skip_done "Humanizer skill is already installed ($skill_file)"
fi

# npx가 skills 패키지를 자동으로 받게 함
PATH="$LOCAL_BIN:$PATH" npx --yes skills add blader/humanizer -g -a '*' -y
if [[ ! -f "$skill_file" ]]; then
    echo "Humanizer skill is not installed after running npx skills" >&2
    exit 1
fi
echo "Humanizer skill installed: $skill_file"
echo "Use /humanizer in Claude Code or OpenCode. Restart the agent if it was already running"
