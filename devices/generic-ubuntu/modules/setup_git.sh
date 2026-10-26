#!/usr/bin/env bash
set -euo pipefail
source "$(dirname "$0")/lib.sh"

GIT_NAME='silent'
GIT_EMAIL='20176737+s1len7@users.noreply.github.com'

if command -v git >/dev/null 2>&1; then
    current_name="$(git config --global user.name 2>/dev/null || true)"
    current_email="$(git config --global user.email 2>/dev/null || true)"
    if [[ "$current_name" == "$GIT_NAME" && "$current_email" == "$GIT_EMAIL" ]]; then
        skip_done "Git is already installed with identity $GIT_NAME <$GIT_EMAIL>"
    fi
    echo "Git is already installed, setting identity"
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

git config --global user.name "$GIT_NAME"
git config --global user.email "$GIT_EMAIL"
echo "Git identity set: $GIT_NAME <$GIT_EMAIL>"
exit 0
