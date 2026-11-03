#!/usr/bin/env bash
# 한글 입력: macOS 기본 입력기의 "두벌식"(2-Set Korean)을 입력 소스에 추가
# 입력 방법(IMK)은 "입력 모드"와 "입력 방법(Keyboard Input Method)" 항목이 모두 있어야 동작하므로 둘 다 추가
# 이미 있는 입력 소스(ABC 등)는 그대로 두고 빠진 항목만 추가함
# 입력 메뉴가 이전 목록을 캐시하므로 TextInputMenuAgent를 다시 시작해 바로 반영되게 함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

domain=com.apple.HIToolbox
bundle_id=com.apple.inputmethod.Korean
input_mode=com.apple.inputmethod.Korean.2SetKorean
mode_entry="<dict><key>Bundle ID</key><string>$bundle_id</string><key>Input Mode</key><string>$input_mode</string><key>InputSourceKind</key><string>Input Mode</string></dict>"
method_entry="<dict><key>Bundle ID</key><string>$bundle_id</string><key>InputSourceKind</key><string>Keyboard Input Method</string></dict>"

# 현재 항목을 JSON으로 읽음 (키가 없으면 빈 배열)
enabled_json="$(defaults read "$domain" AppleEnabledInputSources 2>/dev/null | plutil -convert json -o - - 2>/dev/null || echo '[]')"
has_mode="$(jq --arg b "$bundle_id" --arg m "$input_mode" \
    'any(.[]; .["Bundle ID"] == $b and .["Input Mode"] == $m and .InputSourceKind == "Input Mode")' <<<"$enabled_json")"
has_method="$(jq --arg b "$bundle_id" \
    'any(.[]; .["Bundle ID"] == $b and .InputSourceKind == "Keyboard Input Method")' <<<"$enabled_json")"

if [[ "$has_mode" == true && "$has_method" == true ]]; then
    skip_done "Korean 2-Set input source is already enabled"
fi

if [[ "$has_mode" != true ]]; then
    defaults write "$domain" AppleEnabledInputSources -array-add "$mode_entry"
fi
if [[ "$has_method" != true ]]; then
    defaults write "$domain" AppleEnabledInputSources -array-add "$method_entry"
fi
# 입력 메뉴를 다시 띄워 새 입력 소스가 바로 보이게 함 (macOS가 자동으로 다시 실행함)
killall TextInputMenuAgent 2>/dev/null || true
echo "Korean 2-Set input source added. Use the input menu in the menu bar to switch to it"
echo "If it does not appear, log out and log in again"
