#!/usr/bin/env bash
# Node.js 최신 LTS를 관리자 권한 없이 ~/.local/node에 설치 (OpenCode의 npm 설치에 필요)
# nodejs.org 공식 압축 파일을 받아 SHA-256을 확인한 뒤 풀고, node·npm·npx를 ~/.local/bin에 링크
# 셸 프로필은 고치지 않음 (~/.local/bin이 PATH에 없으면 추가할 줄만 안내)
set -euo pipefail
source "$(dirname "$0")/lib.sh"

# 이보다 오래된 설치는 새로 받음 (OpenCode는 최소 버전을 정하지 않음)
min_version=20.18.1
dist_url=https://nodejs.org/dist

# 버전 a가 b 이상이면 성공 (점으로 나눈 세 숫자 비교)
version_at_least() {
    local IFS=. a b i
    read -r -a a <<<"$1"
    read -r -a b <<<"$2"
    for i in 0 1 2; do
        (( ${a[i]:-0} > ${b[i]:-0} )) && return 0
        (( ${a[i]:-0} < ${b[i]:-0} )) && return 1
    done
    return 0
}

# 링크가 모두 이 Node.js를 가리키는지 확인
links_ok() {
    local name
    for name in node npm npx; do
        [[ "$(readlink "$LOCAL_BIN/$name" 2>/dev/null)" == "$NODE_DIR/bin/$name" ]] || return 1
    done
}

link_commands() {
    local name
    mkdir -p "$LOCAL_BIN"
    for name in node npm npx; do
        ln -sf "$NODE_DIR/bin/$name" "$LOCAL_BIN/$name"
    done
}

installed_version=""
[[ -x "$NODE_DIR/bin/node" ]] && installed_version="$("$NODE_DIR/bin/node" --version 2>/dev/null | sed 's/^v//' || true)"

if [[ -n "$installed_version" ]] && version_at_least "$installed_version" "$min_version"; then
    if links_ok; then
        skip_done "Node.js $installed_version is already installed in $NODE_DIR"
    fi
    link_commands
    echo "Node.js $installed_version is installed, linked node, npm and npx into $LOCAL_BIN"
    exit 0
fi

case "$(uname -m)" in
    x86_64) arch=x64 ;;
    arm64) arch=arm64 ;;
    *) echo "Unsupported CPU: $(uname -m)" >&2; exit 1 ;;
esac

version="$(curl -fsSL "$dist_url/index.json" | jq -r '[.[] | select(.lts)][0].version')"
if [[ -z "$version" || "$version" == null ]]; then
    echo "Failed to find the latest Node.js LTS version from $dist_url/index.json" >&2
    exit 1
fi
file="node-$version-darwin-$arch.tar.gz"

work_dir="$(mktemp -d)"
trap 'rm -rf "$work_dir"' EXIT

echo "Downloading Node.js $version ($file)"
curl -fsSL "$dist_url/$version/$file" -o "$work_dir/$file"
expected="$(curl -fsSL "$dist_url/$version/SHASUMS256.txt" | awk -v f="$file" '$2 == f { print $1 }')"
actual="$(shasum -a 256 "$work_dir/$file" | awk '{ print $1 }')"
if [[ -z "$expected" || "$expected" != "$actual" ]]; then
    echo "SHA-256 check failed for $file" >&2
    exit 1
fi

tar -xzf "$work_dir/$file" -C "$work_dir"
# 다 푼 뒤에 바꿔 넣어, 중간에 실패해도 기존 설치가 깨지지 않게 함 (전역 npm 패키지는 새로 설치해야 함)
mkdir -p "$(dirname "$NODE_DIR")"
rm -rf "$NODE_DIR"
mv "$work_dir/node-$version-darwin-$arch" "$NODE_DIR"
link_commands
echo "Node.js installed: $NODE_DIR ($("$NODE_DIR/bin/node" --version)), linked node, npm and npx into $LOCAL_BIN"

case ":$PATH:" in
    *":$LOCAL_BIN:"*) ;;
    *)
        echo "$LOCAL_BIN is not on PATH. Add this line to ~/.zshrc, then open a new terminal:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac
