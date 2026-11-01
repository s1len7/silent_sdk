#!/usr/bin/env bash
# VS Code 자동실행 설정 스크립트
# 저장소의 .config/autostart/code.desktop을 사용자 ~/.config/autostart/에 복사
# (labwc가 로그인 시 lxsession-xdg-autostart로 ~/.config/autostart/를 실행함)
# VS Code 설치는 setup_vscode.sh가 하므로 그 다음에 실행할 것
# 사용법: sudo bash scripts/setup_vscode_autostart.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# sudo로 실행해도 실제 로그인 사용자의 홈에 적용
user_name="${SUDO_USER:-$(whoami)}"
user_home="$(getent passwd "$user_name" | cut -d: -f6)"

src="$(cd "$(dirname "$0")/.." && pwd)/.config/autostart/code.desktop"
dst="$user_home/.config/autostart/code.desktop"

# VS Code가 있고 자동실행 파일이 저장소와 같으면 건너뜀 (원본의 CR은 제거하고 비교)
if pkgs_installed code && cmp -s <(tr -d '\r' < "$src") "$dst"; then
    skip_done "VS Code autostart is already set up"
fi

if ! command -v code >/dev/null 2>&1; then
    echo "VS Code not found. Install first with: sudo bash scripts/setup_vscode.sh" >&2
    exit 1
fi

# ~/.config가 없을 때 root 소유로 만들어지지 않게 사용자 권한으로 폴더를 만듦
sudo -u "$user_name" mkdir -p "$(dirname "$dst")"
# 원본이 Windows에서 편집된 경우를 대비해 CR 제거
tr -d '\r' < "$src" > "$dst"
chown "$user_name:" "$dst"

echo "Copied code.desktop to $dst"
echo "VS Code will start automatically on next login."
