#!/usr/bin/env bash
# 주 디스플레이(내장 디스플레이)의 밝기를 최대(1.0)로 설정
# macOS가 공개하지 않은 CoreDisplay 함수를 쓰며 관리자 권한은 필요 없음
# 외장 디스플레이는 대상이 아님 (내장 디스플레이가 주 디스플레이일 때 적용됨)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

set +e
python3 - <<'PY'
import ctypes
import sys

cg = ctypes.CDLL('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
cg.CGMainDisplayID.restype = ctypes.c_uint32
display = cg.CGMainDisplayID()

cd = ctypes.CDLL('/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay')
cd.CoreDisplay_Display_GetUserBrightness.argtypes = [ctypes.c_uint32]
cd.CoreDisplay_Display_GetUserBrightness.restype = ctypes.c_double
cd.CoreDisplay_Display_SetUserBrightness.argtypes = [ctypes.c_uint32, ctypes.c_double]
cd.CoreDisplay_Display_SetUserBrightness.restype = None

before = cd.CoreDisplay_Display_GetUserBrightness(display)
if before < 0:
    print('Failed to read the brightness of the main display', file=sys.stderr)
    sys.exit(1)
if before >= 0.999:
    sys.exit(3)

cd.CoreDisplay_Display_SetUserBrightness(display, 1.0)

# 밝기 변경을 시스템에 알려 설정 화면 등에 바로 반영되게 함 (있을 때만)
try:
    ds = ctypes.CDLL('/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices')
    changed = getattr(ds, 'DisplayServicesBrightnessChanged', None)
    if changed is not None:
        changed.argtypes = [ctypes.c_uint32, ctypes.c_double]
        changed.restype = None
        changed(display, 1.0)
except OSError:
    pass

after = cd.CoreDisplay_Display_GetUserBrightness(display)
if after < 0.999:
    print(f'Failed to set the brightness to maximum (current {after})', file=sys.stderr)
    sys.exit(1)
print(f'Display brightness set to maximum (was {before:.2f}, now {after:.2f})')
PY
status=$?
set -e

case $status in
    0) ;;
    3) skip_done "Display brightness is already at maximum" ;;
    *) exit "$status" ;;
esac
