#!/usr/bin/env bash
# Night Shift를 꺼서 시간대에 따른 화면 색온도 자동 변경을 끔
# macOS가 공개하지 않은 CoreBrightness의 CBBlueLightClient를 쓰며 관리자 권한은 필요 없음
# Night Shift은 사용자별 설정이라 이 스크립트를 실행한 사용자에게만 적용됨
set -euo pipefail
source "$(dirname "$0")/lib.sh"

set +e
python3 - <<'PY'
import ctypes
import sys

objc = ctypes.CDLL('/usr/lib/libobjc.A.dylib')
ctypes.CDLL('/System/Library/PrivateFrameworks/CoreBrightness.framework/CoreBrightness')
objc.objc_getClass.restype = ctypes.c_void_p
objc.objc_getClass.argtypes = [ctypes.c_char_p]
objc.sel_registerName.restype = ctypes.c_void_p
objc.sel_registerName.argtypes = [ctypes.c_char_p]


def call(restype, argtypes, obj, selector, *args):
    fn = objc.objc_msgSend
    fn.restype = restype
    fn.argtypes = argtypes
    return fn(obj, objc.sel_registerName(selector), *args)


pointer = ctypes.c_void_p
client = call(pointer, [pointer, pointer], objc.objc_getClass(b'CBBlueLightClient'), b'alloc')
client = call(pointer, [pointer, pointer], client, b'init')


# getBlueLightStatus:가 채우는 구조체에서 두 번째 바이트가 활성화 여부
def enabled():
    status = ctypes.create_string_buffer(64)
    if not call(ctypes.c_bool, [pointer, pointer, ctypes.c_void_p], client,
                b'getBlueLightStatus:', ctypes.byref(status)):
        print('Failed to read the Night Shift status', file=sys.stderr)
        sys.exit(1)
    return status.raw[1] != 0


if not enabled():
    sys.exit(3)

call(None, [pointer, pointer, ctypes.c_bool], client, b'setEnabled:', False)
if enabled():
    print('Failed to turn off Night Shift', file=sys.stderr)
    sys.exit(1)
print('Night Shift turned off')
PY
status=$?
set -e

case $status in
    0) ;;
    3) skip_done "Night Shift is already off" ;;
    *) exit "$status" ;;
esac
