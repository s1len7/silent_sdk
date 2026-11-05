#!/usr/bin/env bash
# 한글 입력: 구름 입력기(/Library/Input Methods/Gureum.app)가 있으면 서드파티 입력 소스
# 저장소(com.apple.inputsources)에 구름 두벌식을 등록하고, 없으면 macOS 기본 입력기의
# "두벌식"(2-Set Korean)을 com.apple.HIToolbox에 추가
# 입력 방법(IMK)은 "입력 모드"와 "입력 방법(Keyboard Input Method)" 항목이 모두 있어야 동작하므로 둘 다 추가
# 구름은 회사 로그인 스크립트(kr.codyssey.gureum.init)가 로그인 후 선택하므로, 여기서는 두 항목만 등록
# 이미 있는 입력 소스(ABC 등)는 그대로 두고 빠진 항목만 추가함
# 입력 메뉴가 이전 목록을 캐시하므로 TextInputMenuAgent를 다시 시작해 바로 반영되게 함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. Install jq, then run this step again" >&2
    exit 1
fi

if [[ -d "/Library/Input Methods/Gureum.app" ]]; then
    domain=com.apple.inputsources
    source_key=AppleEnabledThirdPartyInputSources
    bundle_id=org.youknowone.inputmethod.Gureum
    input_mode=org.youknowone.inputmethod.Gureum.han2
    name="Gureum"
else
    domain=com.apple.HIToolbox
    source_key=AppleEnabledInputSources
    bundle_id=com.apple.inputmethod.Korean
    input_mode=com.apple.inputmethod.Korean.2SetKorean
    name="Korean 2-Set"
fi

mode_entry="<dict><key>Bundle ID</key><string>$bundle_id</string><key>Input Mode</key><string>$input_mode</string><key>InputSourceKind</key><string>Input Mode</string></dict>"
method_entry="<dict><key>Bundle ID</key><string>$bundle_id</string><key>InputSourceKind</key><string>Keyboard Input Method</string></dict>"

# 현재 항목을 JSON 배열로 읽음. defaults/plutil 출력은 임시 파일로만 처리해 stderr나 빈 stdin이
# JSON 파싱 결과에 섞이지 않게 함 (키가 없거나 변환 실패 시 빈 배열)
enabled_json="[]"
plist_tmp="$(mktemp "${TMPDIR:-/tmp}/imac-hangul.XXXXXX")"
json_tmp="$(mktemp "${TMPDIR:-/tmp}/imac-hangul.XXXXXX")"
trap 'rm -f "$plist_tmp" "$json_tmp"' EXIT

if defaults read "$domain" "$source_key" >"$plist_tmp" 2>/dev/null; then
    if [[ -s "$plist_tmp" ]] && plutil -convert json -o "$json_tmp" "$plist_tmp" >/dev/null 2>&1 && [[ -s "$json_tmp" ]]; then
        if jq -e 'type == "array"' "$json_tmp" >/dev/null 2>&1; then
            enabled_json="$(cat "$json_tmp")"
        fi
    fi
fi

has_mode="$(jq --arg b "$bundle_id" --arg m "$input_mode" \
    'any(.[]; .["Bundle ID"] == $b and .["Input Mode"] == $m and .InputSourceKind == "Input Mode")' <<<"$enabled_json")"
has_method="$(jq --arg b "$bundle_id" \
    'any(.[]; .["Bundle ID"] == $b and .InputSourceKind == "Keyboard Input Method")' <<<"$enabled_json")"

if [[ "$has_mode" == true && "$has_method" == true ]]; then
    skip_done "$name input source is already enabled"
fi

if [[ "$has_mode" != true ]]; then
    defaults write "$domain" "$source_key" -array-add "$mode_entry"
fi
if [[ "$has_method" != true ]]; then
    defaults write "$domain" "$source_key" -array-add "$method_entry"
fi
# 입력 메뉴를 다시 띄워 새 입력 소스가 바로 보이게 함 (macOS가 자동으로 다시 실행함)
killall TextInputMenuAgent 2>/dev/null || true
echo "$name input source added. Use the input menu in the menu bar to switch to it"
echo "If it does not appear, log out and log in again"
