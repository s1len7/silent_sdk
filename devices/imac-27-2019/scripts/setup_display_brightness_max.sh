#!/usr/bin/env bash
# 주 디스플레이(내장 디스플레이)의 밝기를 최대(1.0)로 설정
# macOS는 부팅/로그인 때 저장된 밝기를 복원하므로 CoreDisplay로 설정한 값은 재부팅 후 유지되지 않음
# → 로그인 직후 LaunchAgent가 다시 최대로 설정하게 등록 (5초·15초 뒤 두 번, 늦은 복원까지 덮음)
# macOS가 공개하지 않은 CoreDisplay 함수를 쓰며 관리자 권한은 필요 없음
# 외장 디스플레이는 대상이 아님 (내장 디스플레이가 주 디스플레이일 때 적용됨)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

support_dir="$HOME/Library/Application Support/silent_sdk/imac-27-2019"
helper="$support_dir/set_display_brightness_max.py"
log="$support_dir/display-brightness-max.log"
plist="$HOME/Library/LaunchAgents/com.silent.display-brightness-max.plist"
label="com.silent.display-brightness-max"

mkdir -p "$support_dir" "$HOME/Library/LaunchAgents"

cat > "$helper" <<'PY'
#!/usr/bin/env python3
import ctypes
import sys
import time

FORCE = '--force' in sys.argv

cg = ctypes.CDLL('/System/Library/Frameworks/CoreGraphics.framework/CoreGraphics')
cg.CGMainDisplayID.restype = ctypes.c_uint32
display = cg.CGMainDisplayID()

cd = ctypes.CDLL('/System/Library/Frameworks/CoreDisplay.framework/CoreDisplay')
cd.CoreDisplay_Display_GetUserBrightness.argtypes = [ctypes.c_uint32]
cd.CoreDisplay_Display_GetUserBrightness.restype = ctypes.c_double
cd.CoreDisplay_Display_SetUserBrightness.argtypes = [ctypes.c_uint32, ctypes.c_double]
cd.CoreDisplay_Display_SetUserBrightness.restype = None

# 밝기 변경을 시스템에 알려 설정 화면 등에 바로 반영되게 함 (있을 때만)
changed = None
try:
    ds = ctypes.CDLL('/System/Library/PrivateFrameworks/DisplayServices.framework/DisplayServices')
    changed = getattr(ds, 'DisplayServicesBrightnessChanged', None)
    if changed is not None:
        changed.argtypes = [ctypes.c_uint32, ctypes.c_double]
        changed.restype = None
except OSError:
    pass

for attempt in range(3):
    before = cd.CoreDisplay_Display_GetUserBrightness(display)
    if before < 0:
        print('Failed to read the brightness of the main display', file=sys.stderr)
        sys.exit(1)
    if before >= 0.999 and not FORCE:
        sys.exit(3)
    cd.CoreDisplay_Display_SetUserBrightness(display, 1.0)
    if changed is not None:
        changed(display, 1.0)
    after = cd.CoreDisplay_Display_GetUserBrightness(display)
    if after >= 0.999:
        if before < 0.999:
            print(f'Display brightness set to maximum (was {before:.2f}, now {after:.2f})')
        sys.exit(0)
    if attempt < 2:
        time.sleep(1)

print(f'Failed to set the brightness to maximum (current {after})', file=sys.stderr)
sys.exit(1)
PY

cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>$label</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>sleep 5; /usr/bin/python3 "$helper" --force; sleep 10; /usr/bin/python3 "$helper" --force</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$log</string>
    <key>StandardErrorPath</key>
    <string>$log</string>
</dict>
</plist>
EOF

# 로그인 에이전트를 최신 내용으로 다시 로드
launchctl unload "$plist" 2>/dev/null || true
launchctl load "$plist" 2>/dev/null || true
if ! launchctl list 2>/dev/null | grep -q "$label"; then
    echo "Failed to load $label" >&2
    exit 1
fi

# 지금 바로 적용 (이미 최대면 SKIP)
set +e
python3 "$helper"
status=$?
set -e

case $status in
    0) echo "Display brightness set to maximum and kept at login by $label" ;;
    3) skip_done "Display brightness is already at maximum" ;;
    *) exit "$status" ;;
esac
