#!/usr/bin/env bash
# 서드파티 AI 에이전트 스킬·플러그인 설치 (Claude Code, OpenCode, Kilo)
# - Claude Code: 공식 마켓플레이스에서 superpowers, ponytail, document-skills, example-skills 설치
# - OpenCode: superpowers, ponytail 플러그인 + Anthropic 스킬을 npx skills로 설치
# - Kilo: ponytail 플러그인 + Superpowers·Anthropic 스킬을 npx skills로 설치
# - 설치는 사용자 범위로 하고, 이미 있는 항목은 건너뛰고 빠진 항목만 처리
# - npx skills는 Node.js 22.20 이상이 필요 (setup_nodejs가 최신 LTS 설치)
# - jq는 macOS 15부터 기본 포함 (/usr/bin/jq)
# Docs: https://github.com/obra/superpowers, https://github.com/anthropics/skills,
#       https://github.com/DietrichGebert/ponytail
set -euo pipefail
source "$(dirname "$0")/lib.sh"

PATH="$LOCAL_BIN:$PATH"
export DISABLE_TELEMETRY=1
export DO_NOT_TRACK=1

agents_skills="$HOME/.agents/skills"
opencode_config="$HOME/.config/opencode/opencode.json"
opencode_configc="$HOME/.config/opencode/opencode.jsonc"
kilo_configs=(
    "$HOME/.config/kilo/kilo.jsonc"
    "$HOME/.config/kilo/kilo.json"
    "$HOME/.config/kilo/opencode.json"
    "$HOME/.config/kilo/opencode.jsonc"
    "$HOME/.config/kilo/tui.json"
    "$HOME/.config/kilo/tui.jsonc"
)

superpowers_skills=(
    brainstorming diagnosing-superpowers dispatching-parallel-agents
    executing-plans finishing-a-development-branch receiving-code-review
    requesting-code-review subagent-driven-development systematic-debugging
    test-driven-development using-git-worktrees using-superpowers
    verification-before-completion writing-plans writing-skills
)
anthropic_skills=(
    xlsx docx pptx pdf
    algorithmic-art brand-guidelines canvas-design doc-coauthoring
    frontend-design internal-comms mcp-builder skill-creator
    slack-gif-creator theme-factory web-artifacts-builder webapp-testing
)

failures=""
did_work=0
npx_state=""

record_failure() {
    failures="${failures}$1"$'\n'
}

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

# npx skills를 쓸 수 있는 Node.js인지 한 번만 확인
ensure_npx() {
    if [[ "$npx_state" == ok ]]; then
        return 0
    fi
    if [[ "$npx_state" == bad ]]; then
        return 1
    fi
    if ! command -v npx >/dev/null 2>&1; then
        record_failure "npx not found. Run setup_nodejs.sh first"
        npx_state=bad
        return 1
    fi
    local node_version
    node_version="$(node --version 2>/dev/null | sed 's/^v//' || true)"
    if ! version_at_least "$node_version" "22.20.0"; then
        record_failure "Node.js 22.20 or later is required for npx skills (found ${node_version:-unknown})"
        npx_state=bad
        return 1
    fi
    npx_state=ok
    return 0
}

skills_present() {
    local dir="$1"
    shift
    local name
    for name in "$@"; do
        [[ -f "$dir/$name/SKILL.md" ]] || return 1
    done
    return 0
}

# npx skills로 스킬 묶음을 설치 (이미 있으면 호출하지 않음)
install_skill_set() {
    local agent="$1" source="$2"
    shift 2
    local args=()
    local skill
    for skill in "$@"; do
        args+=(--skill "$skill")
    done
    echo "Installing $source skills for $agent"
    if ! npx --yes skills@latest add "$source" -g -a "$agent" -y "${args[@]}"; then
        echo "npx skills add $source for $agent failed" >&2
        return 1
    fi
    did_work=1
}

ensure_anthropic_skills() {
    local agent="$1" label="$2"
    if skills_present "$agents_skills" "${anthropic_skills[@]}"; then
        echo "$label: Anthropic skills are already installed"
        return 0
    fi
    if ! ensure_npx; then
        return 1
    fi
    if ! install_skill_set "$agent" "anthropics/skills" "${anthropic_skills[@]}"; then
        record_failure "$label: failed to install Anthropic skills"
        return 1
    fi
    if ! skills_present "$agents_skills" "${anthropic_skills[@]}"; then
        record_failure "$label: Anthropic skills were not all found in $agents_skills"
        return 1
    fi
    echo "$label: installed Anthropic skills"
}

# Claude Code는 공식 플러그인으로 설치하므로 npx skills가 필요 없음
claude_bin=""

claude_plugin_ids() {
    local out
    if ! out="$("$claude_bin" plugin list --json 2>/dev/null)"; then
        echo "claude plugin list --json failed" >&2
        return 2
    fi
    [[ -n "$out" ]] || return 0
    if ! printf '%s\n' "$out" | jq -r '.[]? | .id // empty'; then
        echo "Could not parse claude plugin list --json" >&2
        return 2
    fi
}

claude_plugin_installed() {
    local id="$1" ids
    if ! ids="$(claude_plugin_ids)"; then
        return 2
    fi
    printf '%s\n' "$ids" | grep -Fxq "$id"
}

install_claude_plugin() {
    local id="$1" marketplace="$2" status
    if claude_plugin_installed "$id"; then
        echo "Claude Code: plugin $id is already installed"
        return 0
    else
        status=$?
    fi
    if (( status == 2 )); then
        record_failure "Claude Code: could not list installed plugins"
        return 1
    fi
    if ! "$claude_bin" plugin marketplace add "$marketplace"; then
        record_failure "Claude Code: failed to add marketplace $marketplace"
        return 1
    fi
    # 비대화형 실행에서 설치 명령이 뜨면 자동 수락
    if ! "$claude_bin" plugin install "$id" -y; then
        record_failure "Claude Code: failed to install $id"
        return 1
    fi
    if ! claude_plugin_installed "$id"; then
        record_failure "Claude Code: $id was not listed after install"
        return 1
    fi
    did_work=1
    echo "Claude Code: installed plugin $id"
}

install_claude_plugins() {
    if ! claude_bin="$(command -v claude)"; then
        if [[ -d "$HOME/.claude" ]]; then
            echo "Claude Code config exists but the claude command was not found, skipped" >&2
        else
            echo "Claude Code is not installed, skipped"
        fi
        return 0
    fi
    local spec id marketplace
    for spec in \
        "superpowers@claude-plugins-official|anthropics/claude-plugins-official" \
        "ponytail@ponytail|DietrichGebert/ponytail" \
        "document-skills@anthropic-agent-skills|anthropics/skills" \
        "example-skills@anthropic-agent-skills|anthropics/skills"; do
        IFS='|' read -r id marketplace <<<"$spec"
        install_claude_plugin "$id" "$marketplace" || true
    done
}

opencode_bin=""
opencode_major=1

opencode_has_plugin() {
    local needle="$1" file
    for file in "$opencode_config" "$opencode_configc"; do
        [[ -f "$file" ]] || continue
        if grep -Fq "$needle" "$file"; then
            return 0
        fi
    done
    return 1
}

# OpenCode V1은 plugin add 명령이 없어 설정 파일에 직접 추가
add_opencode_v1_plugin() {
    local entry="$1" current new tmp
    if [[ -s "$opencode_config" ]]; then
        if ! current="$(jq -e 'if type == "object" then . else error("not an object") end' "$opencode_config")"; then
            echo "Invalid JSON in $opencode_config, fix or remove it" >&2
            return 1
        fi
    else
        current='{"$schema":"https://opencode.ai/config.json"}'
    fi
    if ! new="$(jq --arg e "$entry" '
        .plugin = (
            if (.plugin | type) == "array" then .plugin
            elif (.plugin | type) == "string" then [.plugin]
            elif .plugin == null then []
            else error("plugin must be an array")
            end
        ) + [$e]
    ' <<<"$current")"; then
        echo "Could not update $opencode_config" >&2
        return 1
    fi
    mkdir -p "$(dirname "$opencode_config")"
    if ! tmp="$(mktemp "$opencode_config.XXXXXX")"; then
        return 1
    fi
    if ! jq . <<<"$new" > "$tmp"; then
        rm -f "$tmp"
        return 1
    fi
    if ! mv "$tmp" "$opencode_config"; then
        rm -f "$tmp"
        return 1
    fi
}

install_opencode_plugin() {
    local entry="$1" needle="$2"
    if opencode_has_plugin "$needle"; then
        echo "OpenCode: plugin $entry is already installed"
        return 0
    fi
    if (( opencode_major >= 2 )); then
        if ! "$opencode_bin" plugin add "$entry"; then
            record_failure "OpenCode: failed to add plugin $entry"
            return 1
        fi
    else
        if [[ ! -f "$opencode_config" && -f "$opencode_configc" ]]; then
            record_failure "OpenCode: add this entry to $opencode_configc by hand: $entry"
            return 1
        fi
        if ! add_opencode_v1_plugin "$entry"; then
            record_failure "OpenCode: failed to update $opencode_config"
            return 1
        fi
    fi
    if ! opencode_has_plugin "$needle"; then
        record_failure "OpenCode: $entry was not found in the config after install"
        return 1
    fi
    did_work=1
    echo "OpenCode: installed plugin $entry"
}

install_opencode() {
    if ! opencode_bin="$(command -v opencode)"; then
        if [[ -d "$HOME/.config/opencode" ]]; then
            echo "OpenCode config exists but the opencode command was not found, skipped" >&2
        else
            echo "OpenCode is not installed, skipped"
        fi
        return 0
    fi
    local version major
    version="$("$opencode_bin" --version 2>/dev/null | head -n 1 || true)"
    version="${version#v}"
    major="${version%%.*}"
    case "$major" in
        ''|*[!0-9]*) major=1 ;;
    esac
    opencode_major="$major"
    if (( opencode_major < 2 )); then
        echo "OpenCode V1 detected; plugins use the plugin array in $opencode_config"
    fi
    install_opencode_plugin \
        'superpowers@git+https://github.com/obra/superpowers.git' \
        'superpowers@git+https://github.com/obra/superpowers.git' || true
    install_opencode_plugin '@dietrichgebert/ponytail' '@dietrichgebert/ponytail' || true
    ensure_anthropic_skills opencode OpenCode || true
}

kilo_bin=""

kilo_has_plugin() {
    local file
    for file in "${kilo_configs[@]}"; do
        [[ -f "$file" ]] || continue
        if grep -Fq '@dietrichgebert/ponytail' "$file"; then
            return 0
        fi
    done
    return 1
}

install_kilo() {
    if ! kilo_bin="$(command -v kilo)"; then
        if [[ -d "$HOME/.config/kilo" ]]; then
            record_failure "Kilo: kilo command not found. Run setup_kilo_cli.sh first"
        else
            echo "Kilo is not installed, skipped"
        fi
        return 0
    fi
    if kilo_has_plugin; then
        echo "Kilo: plugin @dietrichgebert/ponytail is already installed"
    elif ! "$kilo_bin" plugin @dietrichgebert/ponytail --global; then
        record_failure "Kilo: failed to install plugin @dietrichgebert/ponytail"
    elif ! kilo_has_plugin; then
        record_failure "Kilo: @dietrichgebert/ponytail was not found in the config after install"
    else
        did_work=1
        echo "Kilo: installed plugin @dietrichgebert/ponytail"
    fi
    if skills_present "$agents_skills" "${superpowers_skills[@]}"; then
        echo "Kilo: Superpowers skills are already installed"
    elif ! ensure_npx; then
        :
    elif ! install_skill_set kilo "obra/superpowers" "${superpowers_skills[@]}"; then
        record_failure "Kilo: failed to install Superpowers skills"
    elif ! skills_present "$agents_skills" "${superpowers_skills[@]}"; then
        record_failure "Kilo: Superpowers skills were not all found in $agents_skills"
    else
        echo "Kilo: installed Superpowers skills"
    fi
    ensure_anthropic_skills kilo Kilo || true
}

if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. macOS 15 or later includes /usr/bin/jq" >&2
    exit 1
fi

install_claude_plugins || true
install_opencode || true
install_kilo || true

if [[ -n "$failures" ]]; then
    echo "Agent skills setup failed:" >&2
    printf '%s' "$failures" >&2
    exit 1
fi
if (( ! did_work )); then
    skip_done "Third-party agent skills and plugins are already set up"
fi
echo "Third-party agent skills and plugins setup done"
