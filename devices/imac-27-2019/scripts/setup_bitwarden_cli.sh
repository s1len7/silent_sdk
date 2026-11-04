#!/usr/bin/env bash
# Bitwarden CLI를 사용자 범위에 설치하고 Vaultwarden 서버에 연결
set -euo pipefail
source "$(dirname "$0")/lib.sh"

script_dir="$(cd "$(dirname "$0")" && pwd)"
device_dir="$(cd "$script_dir/.." && pwd)"
env_file="$device_dir/.env"
env_example="$device_dir/.env.example"

PATH="$PATH:$LOCAL_BIN"

if ! command -v bw >/dev/null 2>&1; then
    echo "Installing the Bitwarden CLI"
    npm_global_install @bitwarden/cli bw
fi

if [[ ! -f "$env_file" ]]; then
    cp "$env_example" "$env_file"
    echo "Created $env_file. Replace the example VAULTWARDEN_URL, then run this step again."
    exit "$SKIP_EXIT"
fi

server_url="$(sed -n 's/^[[:space:]]*VAULTWARDEN_URL[[:space:]]*=[[:space:]]*//p' "$env_file" | tail -n 1 | tr -d '\r"' | sed 's/[[:space:]]*$//')"
if [[ -z "$server_url" ]]; then
    echo "VAULTWARDEN_URL is empty in $env_file. Set it, then run this step again."
    exit "$SKIP_EXIT"
fi
if [[ "$server_url" == "https://<vaultwarden-example>.duckdns.org" ]]; then
    echo "Replace the example VAULTWARDEN_URL in $env_file, then run this step again."
    exit "$SKIP_EXIT"
fi
case "$server_url" in
    https://*) ;;
    *) echo "VAULTWARDEN_URL must use HTTPS" >&2; exit 1 ;;
esac

current_url="$(bw config server 2>/dev/null || true)"
if [[ "$current_url" == "$server_url" ]]; then
    skip_done "Bitwarden CLI is connected to Vaultwarden"
fi

echo "Configuring the Bitwarden CLI server"
bw config server "$server_url" >/dev/null
current_url="$(bw config server 2>/dev/null || true)"
if [[ "$current_url" != "$server_url" ]]; then
    echo "Bitwarden CLI server configuration did not match VAULTWARDEN_URL" >&2
    exit 1
fi
echo "Bitwarden CLI is connected to Vaultwarden"
