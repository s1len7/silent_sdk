#!/usr/bin/env bash
# setup_*.sh 모듈 공통 함수 (각 모듈에서 source해서 사용, setup.sh가 모듈로 실행하지 않음)

# 이미 설정돼 있을 때의 종료 코드 (setup.sh가 SKIP으로 표시)
SKIP_EXIT=3

# 이미 설정돼 있다는 메시지를 출력하고 SKIP으로 종료
skip_done() {
    echo "$1, skipped"
    exit "$SKIP_EXIT"
}

# 인자로 받은 apt 패키지가 모두 설치돼 있으면 0
pkgs_installed() {
    local p
    for p in "$@"; do
        dpkg-query -W -f='${Status}' "$p" 2>/dev/null | grep -q 'install ok installed' || return 1
    done
}
