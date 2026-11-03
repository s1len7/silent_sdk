#!/usr/bin/env bash
# Dock(화면 아래 독)에 Chrome, Terminal, VSCode, Discord 바로가기를 Chrome, Terminal, VSCode, Discord 순서로 추가
# --remove를 주면 Dock에서 Mail, TV, Music을 제거함 (다른 Dock 항목은 그대로 둠)
# 이미 있으면 마지막 세 항목이 되도록 순서를 맞추고, Dock이 바뀐 항목을 읽도록 다시 시작해 바로 보이게 함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

mode=add
case "${1:-}" in
    --remove) mode=remove ;;
    "") ;;
    *) echo "Usage: $0 [--remove]" >&2; exit 2 ;;
esac

set +e
apps_xml="$(
python3 - "$mode" <<'PY'
import plistlib
import subprocess
import sys
from urllib.parse import quote

mode = sys.argv[1]
add_apps = [
    ("/Applications/Google Chrome.app", "com.google.Chrome", "Google Chrome"),
    ("/System/Applications/Utilities/Terminal.app", "com.apple.Terminal", "Terminal"),
    ("/Applications/Visual Studio Code.app", "com.microsoft.VSCode", "Visual Studio Code"),
    ("/Applications/Discord.app", "com.hnc.Discord", "Discord"),
]
remove_apps = [
    ("/System/Applications/Mail.app", "com.apple.mail"),
    ("/System/Applications/TV.app", "com.apple.TV"),
    ("/System/Applications/Music.app", "com.apple.Music"),
]


def label(path, fallback):
    try:
        name = subprocess.check_output(
            ["mdls", "-raw", "-name", "kMDItemDisplayName", path],
            stderr=subprocess.DEVNULL,
        ).decode().strip()
        return name if name and name != "(null)" else fallback
    except Exception:
        return fallback


def entry(path, bundle_id, fallback):
    return {
        "tile-data": {
            "file-data": {
                "_CFURLString": f"file://{quote(path)}/",
                "_CFURLStringType": 15,
            },
            "file-label": label(path, fallback),
            "file-type": 41,
            "bundle-identifier": bundle_id,
            "dock-extra": 0,
            "is-beta": 0,
        },
        "tile-type": "file-tile",
    }


def matches(item, path, bundle_id):
    tile = item.get("tile-data", {})
    return (
        tile.get("bundle-identifier") == bundle_id
        or tile.get("file-data", {}).get("_CFURLString") == f"file://{quote(path)}/"
    )


prefs = plistlib.loads(subprocess.check_output(["defaults", "export", "com.apple.dock", "-"]))
current = prefs.get("persistent-apps", [])

if mode == "remove":
    new = [e for e in current if not any(matches(e, path, bid) for path, bid in remove_apps)]
    if len(new) == len(current):
        sys.exit(3)
else:
    tail = current[-len(add_apps):]
    tail_ok = len(tail) == len(add_apps) and all(
        matches(e, path, bid) for e, (path, bid, _) in zip(tail, add_apps)
    )
    others = [e for e in current[:-len(add_apps)] if any(matches(e, path, bid) for path, bid, _ in add_apps)]
    if tail_ok and not others:
        sys.exit(3)
    new = [e for e in current if not any(matches(e, path, bid) for path, bid, _ in add_apps)]
    new += [entry(*app) for app in add_apps]

sys.stdout.write(plistlib.dumps(new, fmt=plistlib.FMT_XML).decode())
PY
)"
status=$?
set -e

if [[ $status -eq 3 ]]; then
    if [[ "$mode" == remove ]]; then
        skip_done "Mail, TV and Music are not in the Dock"
    fi
    skip_done "Chrome, Terminal, Visual Studio Code and Discord are already in the Dock in that order"
elif [[ $status -ne 0 ]]; then
    echo "Failed to prepare the Dock items" >&2
    exit 1
fi

defaults write com.apple.dock persistent-apps "$apps_xml"
killall Dock 2>/dev/null || true
if [[ "$mode" == remove ]]; then
    echo "Mail, TV and Music removed from the Dock"
else
    echo "Chrome, Terminal, Visual Studio Code and Discord added to the Dock in that order"
fi
