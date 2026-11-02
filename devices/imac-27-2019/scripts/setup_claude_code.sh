#!/usr/bin/env bash
# Claude Code 설치 + 사용자 전역 설정(~/.claude/settings.json) 적용
# - 설치: 공식 네이티브 설치 스크립트(~/.local/bin/claude, 자동 업데이트됨)
# - 설정: 원본 config/claude-settings.json의 최상위 키를 덮어쓰고, 나머지 키는 그대로 둠
#   settings.json은 다른 파일을 불러올 수 없어서 원본을 저장소에 두고 키만 복사함
# - 저장소 루트를 permissions.additionalDirectories에 추가 (어느 프로젝트에서든 저장소 규칙·스킬을 읽게)
# - 잘못된 JSON인 settings.json은 덮어쓰지 않고 실패로 끝냄
# - 둘 다 돼 있으면 SKIP, 하나만 돼 있으면 빠진 것만 처리
set -euo pipefail
source "$(dirname "$0")/lib.sh"

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$script_dir/../../.." && pwd)"
source_path="$script_dir/../config/claude-settings.json"
settings_dir="$HOME/.claude"
settings_path="$settings_dir/settings.json"
native_bin="$HOME/.local/bin"

# jq는 macOS 15부터 기본 포함 (/usr/bin/jq)
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. macOS 15 or later includes /usr/bin/jq" >&2
    exit 1
fi
if ! jq -e 'type == "object"' "$source_path" >/dev/null; then
    echo "Invalid settings source: $source_path" >&2
    exit 1
fi

# 네이티브 설치 위치가 PATH에 없을 수도 있으므로 이 스크립트 안에서만 추가해 확인
original_path="$PATH"
PATH="$PATH:$native_bin"
installed=0
command -v claude >/dev/null 2>&1 && installed=1

# 현재 설정 (파일이 없거나 비었으면 빈 객체), 잘못된 JSON이면 덮어쓰지 않도록 실패
current='{}'
if [[ -s "$settings_path" ]]; then
    if ! current="$(jq -e 'if type == "object" then . else error("not an object") end' "$settings_path")"; then
        echo "Invalid JSON in $settings_path, fix or remove it" >&2
        exit 1
    fi
fi

# 원본 키를 덮어쓰고, 저장소 루트가 없으면 additionalDirectories에 추가한 결과
merged="$(jq --slurpfile src "$source_path" --arg repo "$repo" '
    . + $src[0]
    | .permissions.additionalDirectories |= (
        (. // [])
        | if any(.[]; rtrimstr("/") == $repo) then . else . + [$repo] end
      )
' <<<"$current")"
settings_done=0
[[ "$(jq -S . <<<"$current")" == "$(jq -S . <<<"$merged")" ]] && settings_done=1

if (( installed && settings_done )); then
    skip_done "Claude Code is installed ($(command -v claude)) and settings are already set"
fi

if (( ! installed )); then
    echo "Installing Claude Code with the official native installer"
    curl -fsSL https://claude.ai/install.sh | bash
    if ! command -v claude >/dev/null 2>&1; then
        echo "claude not found after install" >&2
        exit 1
    fi
    echo "Claude Code installed: $(command -v claude) ($(claude --version 2>/dev/null || echo 'version unknown'))"
fi

if (( ! settings_done )); then
    mkdir -p "$settings_dir"
    # 임시 파일에 쓴 뒤 바꿔 넣어, 중간에 실패해도 기존 파일이 깨지지 않게 함
    tmp_file="$(mktemp "$settings_dir/settings.json.XXXXXX")"
    jq . <<<"$merged" > "$tmp_file"
    mv "$tmp_file" "$settings_path"
    echo "Claude Code settings updated: $settings_path (keys: $(jq -r 'keys | join(", ")' "$source_path"), permissions.additionalDirectories)"
fi

# PATH에 네이티브 설치 위치가 없으면 안내만 함 (셸 프로필은 사용자 확인 없이 수정하지 않음)
case ":$original_path:" in
    *":$native_bin:"*) ;;
    *)
        echo "$native_bin is not on PATH. Add this line to ~/.zshrc, then open a new terminal:"
        echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
        ;;
esac
