#!/usr/bin/env bash
# 마우스·트랙패드 스크롤 방향을 Windows와 같게 설정 (macOS의 "자연스러운 스크롤" 끔)
# macOS는 마우스와 트랙패드가 이 값 하나를 함께 씀 (값이 없으면 기본값인 켜짐)
# 바뀐 값은 로그아웃 후 다시 로그인해야 적용됨
set -euo pipefail
source "$(dirname "$0")/lib.sh"

key=com.apple.swipescrolldirection

if [[ "$(defaults read -g "$key" 2>/dev/null || true)" == "0" ]]; then
    skip_done "Natural scrolling is already off"
fi

defaults write -g "$key" -bool false
echo "Natural scrolling turned off ($key=false). Log out and log in again to apply"
