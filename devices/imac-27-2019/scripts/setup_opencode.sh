#!/usr/bin/env bash
# OpenCode CLI 설치(npm, 최신) + 무료 기본 모델과 실패 시 대체 모델 설정
# - 설치: 사용자 Node.js(~/.local/node, setup_nodejs가 설치)에 전역 설치하고 ~/.local/bin/opencode로 링크
# - ~/.config/opencode/opencode.json: 기본 모델과 대체 플러그인 (다른 키는 그대로 둠)
# - ~/.config/opencode/opencode-fallback.json: 플러그인이 읽는 대체 모델 목록 (다른 키는 그대로 둠)
# - 무료 opencode/* 모델은 로그인이 필요 없음. 공용 장비이므로 API 키는 설정하지 않음
# - 모델 값은 generic-windows의 setup-opencode.ps1과 같게 맞춤
# - 잘못된 JSON 설정 파일은 덮어쓰지 않고 실패로 끝냄
# Docs: https://opencode.ai/docs/
set -euo pipefail
source "$(dirname "$0")/lib.sh"

config_dir="$HOME/.config/opencode"
config_file="$config_dir/opencode.json"
fallback_file="$config_dir/opencode-fallback.json"
model=opencode/deepseek-v4.1-flash-free
plugin=opencode-runtime-fallback@0.3.0
fallback_models='["opencode/glm-5.3-flash-free", "opencode/beam-free"]'

# JSON 파일 내용 (없거나 비었으면 기본값), 잘못된 JSON이면 실패
# 사용법: read_json <파일> <기본값>
read_json() {
    if [[ -s "$1" ]]; then
        if ! jq -e 'if type == "object" then . else error("not an object") end' "$1"; then
            echo "Invalid JSON in $1, fix or remove it" >&2
            return 1
        fi
    else
        echo "$2"
    fi
}

# 임시 파일에 쓴 뒤 바꿔 넣음 (중간에 실패해도 기존 파일이 깨지지 않게)
write_json() {
    local tmp_file
    mkdir -p "$(dirname "$1")"
    tmp_file="$(mktemp "$1.XXXXXX")"
    jq . <<<"$2" > "$tmp_file"
    mv "$tmp_file" "$1"
}

PATH="$PATH:$LOCAL_BIN"
installed=0
command -v opencode >/dev/null 2>&1 && installed=1

config="$(read_json "$config_file" '{"$schema": "https://opencode.ai/config.json"}')"
# 기본 모델을 덮어쓰고, 대체 플러그인이 없을 때만 추가 (어느 버전이든 있으면 그대로 둠)
new_config="$(jq --arg model "$model" --arg plugin "$plugin" '
    .model = $model
    | if any((.plugin // [])[]; test("^opencode-runtime-fallback(@|$)")) then .
      else .plugin = ((.plugin // []) + [$plugin]) end
' <<<"$config")"
fallback="$(read_json "$fallback_file" '{}')"
new_fallback="$(jq --argjson models "$fallback_models" '.fallback_models = $models' <<<"$fallback")"

config_done=0
[[ "$(jq -S . <<<"$config")" == "$(jq -S . <<<"$new_config")" && -s "$config_file" ]] && config_done=1
fallback_done=0
[[ "$(jq -S . <<<"$fallback")" == "$(jq -S . <<<"$new_fallback")" && -s "$fallback_file" ]] && fallback_done=1

if (( installed && config_done && fallback_done )); then
    skip_done "OpenCode is installed ($(command -v opencode)) with the default model $model"
fi

if (( ! installed )); then
    echo "Installing the OpenCode CLI (npm, latest)"
    npm_global_install opencode-ai@latest opencode
    opencode --version
fi

if (( ! config_done )); then
    write_json "$config_file" "$new_config"
    echo "OpenCode default model set to $model with the $plugin plugin: $config_file"
fi
if (( ! fallback_done )); then
    write_json "$fallback_file" "$new_fallback"
    echo "OpenCode fallback models set to $(jq -r '.fallback_models | join(", ")' "$fallback_file"): $fallback_file"
fi
echo "OpenCode setup done: run 'opencode' in a new terminal"
