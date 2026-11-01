#!/usr/bin/env bash
# mDNS(Avahi) 설치 스크립트 (Docker VM 안에서 실행, Proxmox 호스트에서는 실행하지 않음)
# Ubuntu cloud 이미지에는 Avahi가 없어서, 집 안의 다른 기기가 이 VM을 <호스트 이름>.local로 찾을 수 있게 설치함
# 사용법: sudo bash vm/ubuntu-docker/scripts/setup_avahi.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

if command -v pveversion >/dev/null; then
    echo "This is the Proxmox host. Run this script inside the Docker VM." >&2
    exit 1
fi

# 설치돼 있고 실행 중이면 건너뜀
if pkgs_installed avahi-daemon && systemctl is-active --quiet avahi-daemon; then
    skip_done "Avahi is already running ($(hostname).local)"
fi

if ! pkgs_installed avahi-daemon; then
    echo "Installing avahi-daemon"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y avahi-daemon
fi
systemctl enable --now avahi-daemon

if ! systemctl is-active --quiet avahi-daemon; then
    echo "avahi-daemon is not running. Check: journalctl -u avahi-daemon" >&2
    exit 1
fi
echo "Avahi is running. This VM is reachable as $(hostname).local"
