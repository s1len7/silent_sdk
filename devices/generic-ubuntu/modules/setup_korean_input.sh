#!/usr/bin/env bash
# 한글 입력 설정: 필요한 패키지만 설치하고 입력 소스에 hangul 추가
# Ubuntu Desktop은 ibus/ibus-hangul이 이미 설치돼 있으므로 빠진 패키지만 설치함
set -euo pipefail
source "$(dirname "$0")/lib.sh"

gnome_schema_exists() {
    command -v gsettings >/dev/null 2>&1 && gsettings list-schemas 2>/dev/null | grep -qx 'org.gnome.desktop.input-sources'
}

gnome_sources() {
    gsettings get org.gnome.desktop.input-sources sources 2>/dev/null || true
}

# GNOME 입력 소스 목록에 hangul이 있으면 0
hangul_in_gnome() {
    gnome_schema_exists && gnome_sources | grep -q "('ibus', 'hangul')"
}

# 빠진 패키지 확인 (Desktop 기본 포함 패키지는 건너뜀)
missing=()
for p in ibus ibus-hangul fonts-nanum; do
    dpkg -s "$p" >/dev/null 2>&1 || missing+=("$p")
done

if [[ ${#missing[@]} -eq 0 ]] && hangul_in_gnome; then
    skip_done "Korean input (ibus-hangul) is already set up"
fi

if [[ ${#missing[@]} -gt 0 ]]; then
    echo "Installing missing packages: ${missing[*]}"
    sudo apt-get update -y
    sudo apt-get install -y "${missing[@]}"
else
    echo "ibus/ibus-hangul/fonts-nanum are already installed"
fi

# gsettings는 로그인 세션에서 실행해야 함 (sudo로 실행하면 세션이 없어 설정이 사용자 홈에 반영되지 않음)
if [[ $EUID -eq 0 ]]; then
    echo "Run this as your desktop user to add the Hangul input source (not as root):"
    echo "  gsettings set org.gnome.desktop.input-sources sources \"[('xkb', 'us'), ('ibus', 'hangul')]\""
    exit 0
fi

# GNOME: 입력 소스 목록에 hangul 추가 (기존 항목은 유지)
if gnome_schema_exists; then
    if ! hangul_in_gnome; then
        current="$(gnome_sources)"
        if [[ -z "$current" || "$current" == "@as []" || "$current" == "[]" ]]; then
            new="[('xkb', 'us'), ('ibus', 'hangul')]"
        else
            new="${current%]*}, ('ibus', 'hangul')]"
        fi
        echo "Adding the Hangul input source: $new"
        gsettings set org.gnome.desktop.input-sources sources "$new"
    fi
fi

# GNOME이 아닌 환경(ibus 직접 사용)도 커버하려고 ibus 입력기 목록도 설정 (실패해도 무시)
gsettings set org.freedesktop.ibus.general preload-engines "['xkb:us::eng', 'hangul']" 2>/dev/null || true
gsettings set org.freedesktop.ibus.general engines-order "['xkb:us::eng', 'hangul']" 2>/dev/null || true

echo "Korean input setup done. Switch with Super+Space (log out and back in if it does not apply)."
