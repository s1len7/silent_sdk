#!/usr/bin/env bash
# Discord 설치 (DMG 다운로드 후 ~/Applications에 복사, 관리자 권한 불필요)
# Discord는 자체 업데이트를 하므로 이미 있으면 건너뜀
set -euo pipefail
source "$(dirname "$0")/lib.sh"

app_dir="$HOME/Applications"
app_path="$app_dir/Discord.app"
# /Applications에 이미 설치돼 있으면 그대로 사용
if [[ -d /Applications/Discord.app ]]; then
    skip_done "Discord is already installed (/Applications/Discord.app)"
fi
if [[ -d "$app_path" ]]; then
    skip_done "Discord is already installed ($app_path)"
fi

mkdir -p "$app_dir"
work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT
dmg="$work_dir/discord.dmg"
echo "Downloading Discord"
curl -fL -o "$dmg" "https://discord.com/api/download?platform=osx"
echo "Mounting Discord installer"
hdiutil attach "$dmg" -nobrowse -quiet
trap 'hdiutil detach /Volumes/Discord -quiet 2>/dev/null || true; rm -rf "$work_dir"' EXIT
if [[ ! -d /Volumes/Discord/Discord.app ]]; then
    echo "Discord.app not found in the mounted image" >&2
    exit 1
fi
cp -R /Volumes/Discord/Discord.app "$app_path"
hdiutil detach /Volumes/Discord -quiet 2>/dev/null || true
trap 'rm -rf "$work_dir"' EXIT
echo "Discord installed: $app_path"
echo "Launch Discord from $app_path"
