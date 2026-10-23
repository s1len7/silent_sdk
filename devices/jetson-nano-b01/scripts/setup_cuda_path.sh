#!/usr/bin/env bash
# CUDA 경로 등록 스크립트
# JetPack에는 CUDA가 /usr/local/cuda에 설치돼 있지만 PATH에 없어서 nvcc를 찾지 못함
# NVIDIA 포럼 안내대로 사용자 ~/.bashrc 끝에 PATH와 LD_LIBRARY_PATH를 추가
# 사용법: sudo bash scripts/setup_cuda_path.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

user_name="${SUDO_USER:-root}"
bashrc="$(getent passwd "$user_name" | cut -d: -f6)/.bashrc"
path_line='export PATH=/usr/local/cuda/bin${PATH:+:${PATH}}'
lib_line='export LD_LIBRARY_PATH=/usr/local/cuda/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}'

# 두 줄이 모두 있으면 건너뜀
if [[ -f "$bashrc" ]] && grep -qxF "$path_line" "$bashrc" && grep -qxF "$lib_line" "$bashrc"; then
    skip_done "CUDA path is already in $bashrc"
fi

if [[ ! -x /usr/local/cuda/bin/nvcc ]]; then
    echo "CUDA not found at /usr/local/cuda. Check the JetPack installation." >&2
    exit 1
fi

# 없는 줄만 추가
for line in "$path_line" "$lib_line"; do
    if ! grep -qxF "$line" "$bashrc" 2>/dev/null; then
        echo "$line" >> "$bashrc"
    fi
done
chown "$user_name:" "$bashrc"

echo "CUDA path added to $bashrc. Open a new terminal, then check with: nvcc --version"
