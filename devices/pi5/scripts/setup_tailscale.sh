#!/usr/bin/env bash
# Tailscale 설치와 tailnet 로그인
# 1) 공식 apt 저장소(pkgs.tailscale.com) 등록 후 설치 2) tailscaled 서비스 실행 3) 로그인
# 로그인: .env의 TS_AUTHKEY가 있으면 그 키로, 없으면 터미널에서 로그인 URL을 띄움 (터미널이 없으면 로그인만 건너뜀)
# 사용법: sudo bash scripts/setup_tailscale.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

env_file="$(cd "$(dirname "$0")/.." && pwd)/.env"
keyring=/usr/share/keyrings/tailscale-archive-keyring.gpg
sources_list=/etc/apt/sources.list.d/tailscale.list

logged_in() {
    tailscale status --json 2>/dev/null | grep -q '"BackendState": *"Running"'
}

if pkgs_installed tailscale && systemctl is-active --quiet tailscaled && logged_in; then
    skip_done "Tailscale is already installed and logged in"
fi

# 1. 공식 저장소 등록 후 설치 (이후 업데이트도 apt로 받음)
if pkgs_installed tailscale; then
    echo "[1/3] tailscale is already installed"
else
    codename="$(. /etc/os-release && echo "${VERSION_CODENAME:-}")"
    if [[ -z "$codename" ]]; then
        echo "VERSION_CODENAME not found in /etc/os-release" >&2
        exit 1
    fi
    repo_url="https://pkgs.tailscale.com/stable/debian/$codename"
    echo "[1/3] Adding the Tailscale repository ($repo_url) and installing tailscale"
    curl -fsSL "$repo_url.noarmor.gpg" -o "$keyring"
    curl -fsSL "$repo_url.tailscale-keyring.list" -o "$sources_list"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y tailscale
fi

# 2. 부팅 시 실행되게 서비스 켜기
if systemctl is-enabled --quiet tailscaled && systemctl is-active --quiet tailscaled; then
    echo "[2/3] tailscaled is already enabled and running"
else
    echo "[2/3] Enabling and starting tailscaled"
    systemctl enable --now tailscaled
fi

# 3. 로그인
if logged_in; then
    echo "[3/3] Tailscale is already logged in"
else
    # .env는 source하지 않고 TS_AUTHKEY 줄만 읽음 (따옴표·CR 제거)
    auth_key=""
    if [[ -f "$env_file" ]]; then
        auth_key="$(sed -n 's/^TS_AUTHKEY=//p' "$env_file" | tail -n 1 | tr -d '\r"'"'")"
    fi

    if [[ -n "$auth_key" ]]; then
        echo "[3/3] Logging in to Tailscale with TS_AUTHKEY from $env_file"
        # 키가 명령줄(ps)에 보이지 않게 파일로 넘김
        key_file="$(mktemp)"
        trap 'rm -f "$key_file"' EXIT
        printf '%s' "$auth_key" >"$key_file"
        tailscale up --auth-key="file:$key_file"
    elif [[ -t 0 ]]; then
        echo "[3/3] Logging in to Tailscale: open the URL below in a browser"
        tailscale up
    else
        echo "[3/3] No TS_AUTHKEY in $env_file and no terminal, login skipped"
        echo "Log in later with: sudo tailscale up"
        exit "$SKIP_EXIT"
    fi

    if ! logged_in; then
        echo "Tailscale is not logged in after tailscale up" >&2
        exit 1
    fi
fi

echo "Tailscale is up: $(tailscale ip -4 2>/dev/null | head -n 1) ($(hostname))"
