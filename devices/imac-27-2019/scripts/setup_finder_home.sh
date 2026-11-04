#!/usr/bin/env bash
# Finder의 새 윈도우 기본 위치를 홈 폴더(~)로 설정
# (Finder > 설정 > 일반 > "새로운 Finder 윈도우 보기"와 같은 값)
# 값을 바꾼 뒤 Finder를 다시 시작해 바로 적용함 (열려 있던 Finder 창은 닫힘)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

target=PfHm
path="file://$HOME/"

if [[ "$(defaults read com.apple.finder NewWindowTarget 2>/dev/null || true)" == "$target" \
    && "$(defaults read com.apple.finder NewWindowTargetPath 2>/dev/null || true)" == "$path" ]]; then
    skip_done "New Finder windows already open in $HOME"
fi

defaults write com.apple.finder NewWindowTarget -string "$target"
defaults write com.apple.finder NewWindowTargetPath -string "$path"
killall Finder 2>/dev/null || true
echo "New Finder windows open in $HOME (NewWindowTarget=$target, NewWindowTargetPath=$path)"
