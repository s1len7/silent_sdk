#!/usr/bin/env bash
# jtop(jetson-stats) 설치 스크립트: CPU·GPU·온도·전력 모니터
# 최신 7.x는 Python 3.7 이상만 지원하므로, Ubuntu 18.04(Python 3.6)를 지원하고 JetPack 4.6.6을 인식하는 4.3.2로 고정
# 설치 중에 jtop.service 등록과 jtop 그룹에 사용자 추가가 함께 됨 (다시 로그인 후 적용)
# 사용법: sudo bash scripts/setup_jtop.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

version=4.3.2

installed_version() {
    pip3 show jetson-stats 2>/dev/null | awk '/^Version:/ { print $2 }'
}

# 같은 버전이 설치돼 있고 서비스가 실행 중이면 건너뜀
if command -v pip3 >/dev/null && [[ "$(installed_version)" == "$version" ]] \
    && systemctl is-active --quiet jtop.service; then
    skip_done "jtop $version is already installed and running"
fi

# 1. pip 설치
echo "[1/3] Installing python3-pip"
export DEBIAN_FRONTEND=noninteractive
apt-get update
apt-get install -y python3-pip

# 2. jetson-stats 설치 (캐시된 wheel을 쓰면 서비스 등록 단계가 빠지므로 캐시를 쓰지 않음)
echo "[2/3] Installing jetson-stats $version"
pip3 install --no-cache-dir "jetson-stats==$version"

# 3. 서비스 확인
echo "[3/3] Checking jtop.service"
if ! systemctl is-active --quiet jtop.service; then
    echo "jtop.service is not running. Check: systemctl status jtop.service" >&2
    exit 1
fi

echo "jtop $version installed. Log out and back in (or reboot), then run: jtop"
