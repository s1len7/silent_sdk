#!/usr/bin/env bash
# 스왑 설정 스크립트: zram(nvzramconfig)을 끄고 4GB 스왑파일 사용
# 기본 스왑은 RAM 절반(2GB) 크기의 zram이라 빌드·학습 중 메모리가 부족하기 쉬움
# NVIDIA jetson-inference 가이드의 Nano 권장 설정과 같음 (zram 끄기는 재부팅 후 적용)
# 사용법: sudo bash scripts/setup_swap.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

swap_file=/mnt/4GB.swap
fstab_line="$swap_file  none  swap  sw 0  0"

zram_enabled() {
    systemctl is-enabled --quiet nvzramconfig 2>/dev/null
}

# 스왑파일이 있고 fstab에 등록돼 있으며 zram이 꺼져 있으면 건너뜀
if [[ -f "$swap_file" ]] && grep -qF "$fstab_line" /etc/fstab && ! zram_enabled; then
    skip_done "Swap file is already set up"
fi

# 1. zram 끄기 (사용 중인 zram은 재부팅 후 사라짐)
echo "[1/3] Disabling zram (nvzramconfig)"
if zram_enabled; then
    systemctl disable nvzramconfig
fi

# 2. 스왑파일 만들기 (이미 있으면 그대로 사용)
echo "[2/3] Creating $swap_file"
if [[ ! -f "$swap_file" ]]; then
    # 중간에 실패하면(공간 부족 등) 다시 실행할 때 처음부터 만들도록 파일을 지움
    if ! { fallocate -l 4G "$swap_file" && chmod 600 "$swap_file" && mkswap "$swap_file"; }; then
        rm -f "$swap_file"
        echo "Failed to create $swap_file (check free space with: df -h /)" >&2
        exit 1
    fi
fi
if ! swapon --show=NAME --noheadings | grep -qxF "$swap_file"; then
    swapon "$swap_file"
fi

# 3. 부팅 시 자동으로 켜지도록 fstab에 등록
echo "[3/3] Adding $swap_file to /etc/fstab"
if ! grep -qF "$fstab_line" /etc/fstab; then
    echo "$fstab_line" >> /etc/fstab
fi

echo "Swap file enabled. Reboot to remove zram."
