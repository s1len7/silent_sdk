#!/usr/bin/env bash
# Discord 설치(~/Applications)와 자동 업데이트 확인 끄기
# - /Applications에 이미 설치돼 있으면 그대로 사용
# - 자동 업데이트를 끄면 root 소유 앱을 업데이트하려고 관리자 권한 헬퍼를 설치하는 팝업이 뜨지 않음
# - 설정: ~/Library/Application Support/discord/settings.json의 SKIP_HOST_UPDATE=true (다른 키는 그대로 둠)
# - 관리자 권한 없이 실행하며, 자동 업데이트를 끄므로 새 버전은 직접 설치해야 함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

app_dir="$HOME/Applications"
app_path="$app_dir/Discord.app"
# /Applications에 이미 설치돼 있으면 그대로 사용
if [[ -d /Applications/Discord.app ]]; then
    app_path=/Applications/Discord.app
fi
installed=0
[[ -d "$app_path" ]] && installed=1

settings_dir="$HOME/Library/Application Support/discord"
settings_path="$settings_dir/settings.json"

# jq는 macOS 15부터 기본 포함 (/usr/bin/jq)
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. macOS 15 or later includes /usr/bin/jq" >&2
    exit 1
fi

# 현재 설정 (파일이 없거나 비었으면 빈 객체), 잘못된 JSON이면 덮어쓰지 않도록 실패
current='{}'
if [[ -s "$settings_path" ]]; then
    if ! current="$(jq -e 'if type == "object" then . else error("not an object") end' "$settings_path")"; then
        echo "Cannot parse $settings_path. Set \"SKIP_HOST_UPDATE\": true manually" >&2
        exit 1
    fi
fi
update_off=0
[[ "$(jq -r '.["SKIP_HOST_UPDATE"] == true' <<<"$current")" == "true" ]] && update_off=1

if (( installed && update_off )); then
    skip_done "Discord is installed ($app_path) and host updates are already off"
fi

if (( ! installed )); then
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
fi

if (( ! update_off )); then
    merged="$(jq '. + {"SKIP_HOST_UPDATE": true}' <<<"$current")"
    mkdir -p "$settings_dir"
    # 임시 파일에 쓴 뒤 바꿔 넣어, 중간에 실패해도 기존 파일이 깨지지 않게 함
    tmp_file="$(mktemp "$settings_dir/settings.json.XXXXXX")"
    jq . <<<"$merged" > "$tmp_file"
    mv "$tmp_file" "$settings_path"
    echo "Discord host updates turned off (SKIP_HOST_UPDATE=true): $settings_path"
    if pgrep -x Discord >/dev/null 2>&1; then
        echo "Restart Discord to apply the change"
    fi
fi
