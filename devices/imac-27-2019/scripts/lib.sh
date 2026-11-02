#!/usr/bin/env bash
# imac-27-2019 모듈 공통 함수 (macOS 기본 bash 3.2에서도 동작하게 작성)
SKIP_EXIT=3

# 이미 설정돼 있음을 알리고 종료 코드 3(SKIP)으로 끝냄
skip_done() {
    echo "$1, skipped"
    exit "$SKIP_EXIT"
}

# 사용자 범위 Node.js 위치와 명령 링크 위치 (~/.local/bin은 Claude Code 네이티브 설치와 같은 폴더)
LOCAL_BIN="$HOME/.local/bin"
NODE_DIR="$HOME/.local/node"

# 사용자 Node.js의 npm으로 패키지를 전역 설치하고, 명령을 ~/.local/bin에 링크
# 사용법: npm_global_install <패키지> <명령>
npm_global_install() {
    local package="$1" command_name="$2"
    if [[ ! -x "$NODE_DIR/bin/npm" ]]; then
        echo "Node.js not found in $NODE_DIR. Run scripts/setup_nodejs.sh first" >&2
        return 1
    fi
    # npm이 실행하는 설치 스크립트도 이 Node.js를 쓰게 함
    PATH="$NODE_DIR/bin:$PATH" "$NODE_DIR/bin/npm" install -g --prefix "$NODE_DIR" \
        --allow-scripts="${package%@*}" "$package" --loglevel error
    if [[ ! -x "$NODE_DIR/bin/$command_name" ]]; then
        echo "$command_name not found after install: $NODE_DIR/bin/$command_name" >&2
        return 1
    fi
    mkdir -p "$LOCAL_BIN"
    ln -sf "$NODE_DIR/bin/$command_name" "$LOCAL_BIN/$command_name"
    echo "Installed $package: $LOCAL_BIN/$command_name -> $NODE_DIR/bin/$command_name"
}
