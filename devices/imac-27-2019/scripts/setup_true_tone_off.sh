#!/usr/bin/env bash
# True Tone을 꺼서 주변광에 따른 색온도 자동 보정을 끔
# macOS가 공개하지 않은 CoreBrightness의 CBTrueToneClient를 쓰며 관리자 권한은 필요 없음
# True Tone은 사용자별 설정이라 이 스크립트를 실행한 사용자에게만 적용됨
set -euo pipefail
source "$(dirname "$0")/lib.sh"

set +e
result="$(
    osascript -l JavaScript <<'JS'
ObjC.import('Foundation');
$.NSBundle.bundleWithPath('/System/Library/PrivateFrameworks/CoreBrightness.framework').load;
var cls = $.NSClassFromString('CBTrueToneClient');
if (!cls) {
    'unsupported';
} else {
    var client = cls.alloc.init;
    if (!client.supported || !client.available) {
        'unsupported';
    } else if (!client.enabled) {
        'already';
    } else {
        client.setEnabled(false);
        client.enabled ? 'failed' : 'off';
    }
}
JS
)"
status=$?
set -e

if [[ $status -ne 0 ]]; then
    echo "Failed to control True Tone" >&2
    exit 1
fi

case "$result" in
    off) echo "True Tone turned off" ;;
    already) skip_done "True Tone is already off" ;;
    unsupported) skip_done "True Tone is not supported on this display" ;;
    *) echo "Failed to turn off True Tone (result: $result)" >&2; exit 1 ;;
esac
