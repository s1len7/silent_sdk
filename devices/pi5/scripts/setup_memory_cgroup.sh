#!/usr/bin/env bash
# 커널 memory cgroup 활성화 스크립트
# Raspberry Pi 펌웨어가 커널 인자에 cgroup_disable=memory를 넣어 Docker 메모리 상한(mem_limit)이 적용되지 않음
# cmdline.txt 끝에 cgroup_enable=memory를 붙이면 뒤에 온 인자가 우선해 다시 켜짐 (재부팅 후 적용)
# 사용법: sudo bash scripts/setup_memory_cgroup.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

# Bookworm 이후는 /boot/firmware, 이전 OS는 /boot
cmdline=/boot/firmware/cmdline.txt
[[ -f "$cmdline" ]] || cmdline=/boot/cmdline.txt
if [[ ! -f "$cmdline" ]]; then
    echo "cmdline.txt not found in /boot/firmware or /boot" >&2
    exit 1
fi

option=cgroup_enable=memory

# memory 컨트롤러가 이미 켜져 있으면 건너뜀
if grep -qw memory /sys/fs/cgroup/cgroup.controllers; then
    skip_done "Memory cgroup is already enabled"
fi
# cmdline.txt에 이미 있으면 재부팅만 남음
if grep -qw "$option" "$cmdline"; then
    skip_done "$option is already in $cmdline. Reboot to apply"
fi

# 수정 전 원본을 남김 (부팅이 안 되면 SD 카드를 다른 PC에서 열어 되돌림)
cp -p "$cmdline" "$cmdline.bak"
echo "Backed up $cmdline to $cmdline.bak"

# cmdline.txt는 반드시 한 줄이어야 하므로 첫 줄 끝에 붙임 (CR과 끝 공백 제거)
sed -i "1{s/\r$//;s/[[:space:]]*$/ $option/}" "$cmdline"
echo "Added $option to $cmdline"
echo "Reboot to apply: sudo reboot"
