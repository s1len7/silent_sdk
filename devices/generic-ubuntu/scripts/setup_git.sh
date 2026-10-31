#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# 전역 설정 (이 계정의 ~/.gitconfig에만 저장)
# 커밋 작성자는 GitHub noreply 주소로 실제 이메일이 커밋에 들어가지 않게 함,
# 새 저장소 첫 브랜치는 GitHub 기본값 main, fetch 때 원격에서 지운 브랜치 정리,
# pull은 rebase 대신 merge (AGENTS.md의 pull 또는 fetch 후 merge, Ubuntu에는 기본값이 없음)
GIT_CONFIG=(
    'user.name=silent'
    'user.email=20176737+s1len7@users.noreply.github.com'
    'init.defaultBranch=main'
    'fetch.prune=true'
    'pull.rebase=false'
)

# 빠졌거나 값이 다른 설정 키를 한 줄에 하나씩 출력
pending_config() {
    local entry
    for entry in "${GIT_CONFIG[@]}"; do
        if [[ "$(git config --global "${entry%%=*}" 2>/dev/null || true)" != "${entry#*=}" ]]; then
            echo "$entry"
        fi
    done
}

if command -v git >/dev/null 2>&1; then
    if [[ -z "$(pending_config)" ]]; then
        skip_done "Git is already installed with the global settings"
    fi
    echo "Git is already installed, setting the global settings"
else
    echo "Installing git (user may need sudo)"
    if command -v apt-get >/dev/null 2>&1; then
        sudo apt-get update -y
        sudo apt-get install -y git
    elif command -v pacman >/dev/null 2>&1; then
        sudo pacman -S --noconfirm git
    elif command -v dnf >/dev/null 2>&1; then
        sudo dnf install -y git
    else
        echo "Package manager not found; install git manually" >&2
        exit 1
    fi
fi

while IFS= read -r entry; do
    git config --global "${entry%%=*}" "${entry#*=}"
    echo "Git global setting ${entry%%=*} = ${entry#*=}"
done < <(pending_config)
echo "Git global settings are set"
exit 0
