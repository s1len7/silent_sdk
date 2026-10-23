#!/usr/bin/env bash
# htop 자동실행 설정 스크립트
# 저장소의 .config/autostart/htop.desktop을 사용자 ~/.config/autostart/에 복사
# 사용법: sudo bash scripts/setup_htop_autostart.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# sudo로 실행해도 실제 로그인 사용자의 홈에 적용
user_name="${SUDO_USER:-$(whoami)}"
user_home="$(getent passwd "$user_name" | cut -d: -f6)"

src="$(cd "$(dirname "$0")/.." && pwd)/.config/autostart/htop.desktop"
dst="$user_home/.config/autostart/htop.desktop"

# htop이 있고 자동실행 파일이 저장소와 같으면 건너뜀 (원본의 CR은 제거하고 비교)
if pkgs_installed htop && cmp -s <(tr -d '\r' < "$src") "$dst"; then
    skip_done "htop autostart is already set up"
fi

if ! command -v htop >/dev/null 2>&1; then
    apt-get update
    apt-get install -y htop
fi

mkdir -p "$(dirname "$dst")"
# 원본이 Windows에서 편집된 경우를 대비해 CR 제거
tr -d '\r' < "$src" > "$dst"
chown -R "$user_name:" "$user_home/.config/autostart"

echo "Copied htop.desktop to $dst"
echo "htop will start automatically on next login."
