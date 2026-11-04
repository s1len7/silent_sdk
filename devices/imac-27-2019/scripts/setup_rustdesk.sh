#!/usr/bin/env bash
# RustDesk 설치(~/Applications) - Chrome Remote Desktop 호스트가 관리자 권한을 요구해 쓰는 대체 도구
# - GitHub 공식 릴리스의 DMG를 받아 ~/Applications에 넣음 (/Applications에 이미 있으면 그대로 사용)
# - 관리자 권한 없이 설치하며, 화면 기록·손쉬운 사용·입력 모니터링 권한은 사용자가 직접 허용해야 함
# - 로그아웃/로그인 화면 접속과 백그라운드 서비스 설치는 관리자 권한이 필요해 다루지 않음
set -euo pipefail
source "$(dirname "$0")/lib.sh"

app_dir="$HOME/Applications"
app_path="$app_dir/RustDesk.app"
# /Applications에 이미 설치돼 있으면 그대로 사용
if [[ -d /Applications/RustDesk.app ]]; then
    app_path=/Applications/RustDesk.app
fi

if [[ -d "$app_path" ]]; then
    skip_done "RustDesk is already installed ($app_path)"
fi

# jq는 macOS 15부터 기본 포함 (/usr/bin/jq)
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. macOS 15 or later includes /usr/bin/jq" >&2
    exit 1
fi

case "$(uname -m)" in
    x86_64) arch=x86_64 ;;
    arm64) arch=aarch64 ;;
    *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac

echo "Finding the latest RustDesk release"
release_json="$(curl -fsSL https://api.github.com/repos/rustdesk/rustdesk/releases/latest)"
version="$(jq -r '.tag_name // empty' <<<"$release_json")"
url="$(jq -r --arg suffix "-$arch.dmg" '.assets[] | select(.name | endswith($suffix)) | .browser_download_url' <<<"$release_json" | head -n 1)"
if [[ -z "$version" || -z "$url" ]]; then
    echo "Failed to find the latest RustDesk $arch DMG in the GitHub release" >&2
    exit 1
fi
version="${version#v}"

work_dir="$(mktemp -d)"
mount_dir="$work_dir/mnt"
trap 'hdiutil detach "$mount_dir" -quiet 2>/dev/null || true; rm -rf "$work_dir"' EXIT
mkdir -p "$mount_dir"

dmg="$work_dir/rustdesk.dmg"
echo "Downloading RustDesk $version ($arch)"
curl -fL -o "$dmg" "$url"
echo "Mounting RustDesk installer"
hdiutil attach "$dmg" -nobrowse -quiet -mountpoint "$mount_dir"

if [[ ! -d "$mount_dir/RustDesk.app" ]]; then
    echo "RustDesk.app not found in the mounted image" >&2
    exit 1
fi

mkdir -p "$app_dir"
rm -rf "$app_path"
cp -R "$mount_dir/RustDesk.app" "$app_path"
hdiutil detach "$mount_dir" -quiet 2>/dev/null || true
trap 'rm -rf "$work_dir"' EXIT

if [[ ! -d "$app_path" ]]; then
    echo "RustDesk.app not found after install: $app_path" >&2
    exit 1
fi

echo "RustDesk $version installed: $app_path"
echo "Open RustDesk, then allow Screen Recording, Accessibility and Input Monitoring in System Settings > Privacy & Security"
echo "Turn on Start at login in RustDesk settings so remote access works after logging in"
echo "Login screen access and the background service require administrator rights and are not installed"
