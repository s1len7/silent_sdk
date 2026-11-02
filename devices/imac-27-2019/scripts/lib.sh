#!/usr/bin/env bash
# imac-27-2019 모듈 공통 함수 (macOS 기본 bash 3.2에서도 동작하게 작성)
SKIP_EXIT=3

# 이미 설정돼 있음을 알리고 종료 코드 3(SKIP)으로 끝냄
skip_done() {
    echo "$1, skipped"
    exit "$SKIP_EXIT"
}
