#!/usr/bin/env bash
# 한글 폰트(나눔) 설치: 한글이 네모(□)로 깨져 보이는 문제 해결
# Raspberry Pi OS에는 기본 한글 폰트가 없어 화면·브라우저의 한글이 깨짐
# 사용법: sudo bash scripts/setup_korean_font.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# Debian 공식 저장소의 나눔 폰트 (SIL OFL 1.1)
# fonts-nanum: 나눔고딕·나눔명조·나눔바른고딕 등, fonts-nanum-extra: 나눔손글씨 등 (Magic Mirror도 이 모듈의 폰트를 사용)
font_pkgs=(fonts-nanum fonts-nanum-extra)

# 패키지가 모두 설치돼 있고 fontconfig가 나눔고딕을 찾으면 건너뜀
if pkgs_installed "${font_pkgs[@]}" && fc-list :family=NanumGothic | grep -q .; then
    skip_done "Korean fonts (${font_pkgs[*]}) are already installed"
fi

echo "[1/2] Installing ${font_pkgs[*]}"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y "${font_pkgs[@]}"

# 패키지 설치 시 폰트 캐시가 갱신되지만, 패키지는 있는데 캐시만 빠진 경우를 위해 다시 갱신
echo "[2/2] Refreshing the font cache"
fc-cache -f

if ! fc-list :family=NanumGothic | grep -q .; then
    echo "NanumGothic not found by fontconfig after installing ${font_pkgs[*]}" >&2
    exit 1
fi

echo "Korean fonts (${font_pkgs[*]}) installed. Restart open apps (e.g. browser) to apply."
