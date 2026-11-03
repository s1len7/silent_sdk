#!/usr/bin/env bash
# ~/.local/bin을 PATH에 추가 (Node.js·Claude Code·OpenCode 명령을 새 터미널에서 바로 쓰기 위함)
# - ~/.zshrc에 같은 줄이 없을 때만 추가하고, 있으면 건너뜀 (다른 내용은 그대로 둠)
# - 현재 셸에는 적용되지 않으므로 새 터미널을 열어야 함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

profile="$HOME/.zshrc"
path_line='export PATH="$HOME/.local/bin:$PATH"'

if [[ -f "$profile" ]] && grep -qxF "$path_line" "$profile"; then
    skip_done "$LOCAL_BIN is already set in $profile"
fi

mkdir -p "$(dirname "$profile")"
# 기존 파일이 줄바꿈으로 끝나지 않으면 줄이 붙지 않게 먼저 줄바꿈을 넣음
if [[ -s "$profile" && -n "$(tail -c 1 "$profile")" ]]; then
    printf '\n' >> "$profile"
fi
printf '%s\n' "$path_line" >> "$profile"
echo "Added $LOCAL_BIN to PATH in $profile"
echo "Open a new terminal to use commands in $LOCAL_BIN"
