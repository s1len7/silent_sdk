#!/usr/bin/env bash
# Claude Code proxy (unified Anthropic + OpenAI proxy to the Codyssey gateway)
# - Python 3 + pip install codyssey-proxy (from the repo, editable)
# - ~/.codyssey-proxy/.env must contain OPENAI_API_KEY (copied from .env.example if missing)
# - updates ~/.claude/settings.json to point Claude Code at http://localhost:8082
# - registers a LaunchAgent for auto-start and starts it now
set -euo pipefail
source "$(dirname "$0")/lib.sh"

script_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$script_dir/../../.." && pwd)"
proxy_dir="$HOME/.codyssey-proxy"
env_path="$proxy_dir/.env"
settings_dir="$HOME/.claude"
settings_path="$settings_dir/settings.json"

# Python 3
if ! command -v python3 >/dev/null 2>&1; then
    echo "python3 not found, skipped. Install Python 3 first." >&2
    exit 1
fi

mkdir -p "$proxy_dir"

# Create .env from example if missing
if [[ ! -f "$env_path" ]]; then
    if [[ -f "$repo/tools/codyssey-proxy/.env.example" ]]; then
        cp "$repo/tools/codyssey-proxy/.env.example" "$env_path"
    else
        cat > "$env_path" <<'EOF'
CODYSSEY_BASE_URL=https://copa.codyssey.kr
CODYSSEY_OPENAI_API_KEY=
BIG_MODEL=claude-sonnet-4
SMALL_MODEL=claude-haiku-4
PROXY_HOST=127.0.0.1
PROXY_PORT=8082
EOF
    fi
    echo "Created $env_path. Fill in OPENAI_API_KEY, then run this step again." >&2
    exit "$SKIP_EXIT"
fi

# Check key present
if ! grep -qE '^[[:space:]]*CODYSSEY_OPENAI_API_KEY[[:space:]]*=[[:space:]]*[^[:space:]]+' "$env_path"; then
    echo "CODYSSEY_OPENAI_API_KEY is empty in $env_path. Fill it in and run again." >&2
    exit "$SKIP_EXIT"
fi

# Install codyssey-proxy (editable from repo)
python3 -m pip install -e "$repo/tools/codyssey-proxy" --quiet 2>&1 | tail -5 || true
if ! python3 -c "import codyssey_proxy" >/dev/null 2>&1; then
    echo "codyssey-proxy import failed after install" >&2
    exit 1
fi

# Update Claude Code settings via jq
if ! command -v jq >/dev/null 2>&1; then
    echo "jq not found. macOS 15+ includes /usr/bin/jq." >&2
    exit 1
fi
mkdir -p "$settings_dir"
current='{}'
if [[ -s "$settings_path" ]]; then
    if ! current="$(jq -e 'if type == "object" then . else error("not an object") end' "$settings_path")"; then
        echo "Invalid JSON in $settings_path" >&2
        exit 1
    fi
fi
merged="$(jq --arg repo "$repo" '
    .env = ((.env // {}) + {
        "ANTHROPIC_BASE_URL": "http://localhost:8082",
        "ANTHROPIC_MODEL": "claude-sonnet-4-5",
        "ANTHROPIC_SMALL_FAST_MODEL": "claude-haiku-4-5",
        "ANTHROPIC_DEFAULT_SONNET_MODEL": "claude-sonnet-4-5",
        "ANTHROPIC_DEFAULT_HAIKU_MODEL": "claude-haiku-4-5",
        "ANTHROPIC_DEFAULT_OPUS_MODEL": "claude-opus-4-7"
    })
    | .permissions.additionalDirectories |= (
        (. // [])
        | if any(.[]; rtrimstr("/") == $repo) then . else . + [$repo] end
      )
' <<<"$current")"
tmp_file="$(mktemp "$settings_dir/settings.json.XXXXXX")"
jq . <<<"$merged" > "$tmp_file"
mv "$tmp_file" "$settings_path"
echo "Claude Code settings updated: $settings_path"

# LaunchAgent for auto-start
plist="$HOME/Library/LaunchAgents/com.silent.codyssey-proxy.plist"
mkdir -p "$HOME/Library/LaunchAgents"
cat > "$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.silent.codyssey-proxy</string>
    <key>ProgramArguments</key>
    <array>
        <string>/bin/bash</string>
        <string>-c</string>
        <string>cd $proxy_dir && PYTHONIOENCODING=utf-8 python3 -m codyssey_proxy</string>
    </array>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>$proxy_dir/proxy.log</string>
    <key>StandardErrorPath</key>
    <string>$proxy_dir/proxy.log</string>
</dict>
</plist>
EOF

# Load (or reload) the agent
launchctl unload "$plist" 2>/dev/null || true
launchctl load "$plist" 2>/dev/null || true
sleep 4
if curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:8082/ | grep -q 200; then
    echo "Codyssey proxy running on http://localhost:8082"
else
    echo "Proxy may not have started; check $proxy_dir/proxy.log" >&2
fi