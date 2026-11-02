#!/usr/bin/env bash
# 한글 입력: macOS 기본 입력기의 "두벌식"(2-Set Korean)을 입력 소스에 추가
# 이미 있는 입력 소스(ABC 등)는 그대로 두고 빠졌을 때만 추가함
# 메뉴 막대에 바로 나타나지 않으면 로그아웃 후 다시 로그인해야 적용됨
set -euo pipefail
source "$(dirname "$0")/lib.sh"

domain=com.apple.HIToolbox
input_mode=com.apple.inputmethod.Korean.2SetKorean

if defaults read "$domain" AppleEnabledInputSources 2>/dev/null | grep -q "\"$input_mode\""; then
    skip_done "Korean 2-Set input source is already enabled"
fi

defaults write "$domain" AppleEnabledInputSources -array-add \
    "<dict><key>Bundle ID</key><string>com.apple.inputmethod.Korean</string><key>Input Mode</key><string>$input_mode</string><key>InputSourceKind</key><string>Input Mode</string></dict>"
echo "Korean 2-Set input source added. If it is not in the menu bar, log out and log in again"
