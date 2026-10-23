#!/usr/bin/env bash
# 전체 설치 스크립트: scripts/setup_*.sh 모듈을 모두 실행
# 사용법: sudo bash scripts/setup.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

script_dir="$(cd "$(dirname "$0")" && pwd)"

for module in "$script_dir"/setup_*.sh; do
    echo "=== Running $(basename "$module") ==="
    bash "$module"
    echo
done

echo "All modules completed."
