#!/usr/bin/env bash
# Git 전역 커밋 작성자 설정 (이 계정의 ~/.gitconfig에만 저장)
# 실제 이메일이 커밋에 들어가지 않게 GitHub noreply 주소를 씀
# Git은 이미 설치돼 있다고 보고 설치하지 않음 (없으면 Xcode Command Line Tools 설치를 안내하고 실패)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

GIT_CONFIG=(
    'user.name=silent'
    'user.email=20176737+s1len7@users.noreply.github.com'
)

# macOS의 /usr/bin/git은 Command Line Tools가 없으면 설치 창만 띄우므로 실제 실행으로 확인
if ! git --version >/dev/null 2>&1; then
    echo "git not found. Run 'xcode-select --install', then run this setup again" >&2
    exit 1
fi

# 빠졌거나 값이 다른 설정을 한 줄에 하나씩 출력
pending_config() {
    local entry
    for entry in "${GIT_CONFIG[@]}"; do
        if [[ "$(git config --global --get "${entry%%=*}" 2>/dev/null || true)" != "${entry#*=}" ]]; then
            echo "$entry"
        fi
    done
}

pending="$(pending_config)"
if [[ -z "$pending" ]]; then
    skip_done "Git user.name and user.email are already set"
fi

while IFS= read -r entry; do
    git config --global "${entry%%=*}" "${entry#*=}"
    echo "Git global setting ${entry%%=*} = ${entry#*=}"
done <<<"$pending"
