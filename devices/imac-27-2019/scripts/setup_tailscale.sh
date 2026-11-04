#!/usr/bin/env bash
# Mac App Store판 Tailscale을 Vaultwarden의 일회용 키로 연결
set -euo pipefail
source "$(dirname "$0")/lib.sh"

app_store_url="https://apps.apple.com/app/tailscale/id1475387142"
env_file="$(cd "$(dirname "$0")/.." && pwd)/.env"
tailscale_cli=""
bw_session=""
auth_key_file=""

cleanup() {
    if [[ -n "$auth_key_file" ]]; then
        rm -f "$auth_key_file"
    fi
    if [[ -n "$bw_session" ]]; then
        BW_SESSION="$bw_session" BW_NOINTERACTION=true bw lock >/dev/null 2>&1 || true
    fi
    unset bw_session auth_key master_password two_factor_code login_args
}
trap cleanup EXIT

for app_path in /Applications/Tailscale.app "$HOME/Applications/Tailscale.app"; do
    if [[ -d "$app_path" ]]; then
        tailscale_cli="$app_path/Contents/MacOS/Tailscale"
        break
    fi
done

if [[ -z "$tailscale_cli" ]]; then
    echo "Tailscale is not installed."
    echo "Install it from the Mac App Store: $app_store_url"
    skip_done "Tailscale installation requires manual App Store setup"
fi
if [[ ! -x "$tailscale_cli" ]]; then
    echo "Tailscale CLI not found in the installed app: $tailscale_cli" >&2
    exit 1
fi

if TAILSCALE_BE_CLI=1 "$tailscale_cli" status --json 2>/dev/null | jq -e '.BackendState == "Running"' >/dev/null 2>&1; then
    skip_done "Tailscale is already connected"
fi

if [[ ! -t 0 || ! -t 1 ]]; then
    echo "Tailscale login requires an interactive terminal."
    skip_done "Tailscale login was not started"
fi
if ! command -v bw >/dev/null 2>&1; then
    echo "Bitwarden CLI is not installed. Run setup_bitwarden_cli.sh first."
    skip_done "Bitwarden CLI is required for Tailscale login"
fi
if [[ ! -f "$env_file" ]]; then
    echo "Vaultwarden configuration not found: $env_file"
    skip_done "Vaultwarden is not configured"
fi

vaultwarden_url="$(sed -n 's/^[[:space:]]*VAULTWARDEN_URL[[:space:]]*=[[:space:]]*//p' "$env_file" | tail -n 1 | tr -d '\r"' | sed 's/[[:space:]]*$//')"
if [[ -z "$vaultwarden_url" ]]; then
    echo "VAULTWARDEN_URL is empty in $env_file"
    skip_done "Vaultwarden is not configured"
fi
if [[ "$vaultwarden_url" == "https://<vaultwarden-example>.duckdns.org" ]]; then
    echo "Replace the example VAULTWARDEN_URL in $env_file before connecting Tailscale."
    skip_done "Vaultwarden is not configured"
fi
if [[ "$(bw config server 2>/dev/null || true)" != "$vaultwarden_url" ]]; then
    echo "Bitwarden CLI is not configured for VAULTWARDEN_URL. Run setup_bitwarden_cli.sh first."
    skip_done "Bitwarden CLI server does not match Vaultwarden"
fi

bw_status="$(bw status 2>/dev/null || true)"
bw_state="$(jq -r '.status // empty' <<<"$bw_status" 2>/dev/null || true)"
case "$bw_state" in
    unlocked)
        ;;
    locked)
        read -r -s -p "Bitwarden master password: " master_password || master_password=""
        printf '\n'
        if [[ -z "$master_password" ]]; then
            echo "Bitwarden master password was not entered."
            skip_done "Vaultwarden was not unlocked"
        fi
        if ! bw_session="$(BW_PASSWORD="$master_password" BW_NOINTERACTION=true bw unlock --passwordenv BW_PASSWORD --raw 2>/dev/null)"; then
            unset master_password
            echo "Failed to unlock the Vaultwarden account." >&2
            exit 1
        fi
        unset master_password
        ;;
    unauthenticated)
        read -r -p "Bitwarden account email: " bw_email || bw_email=""
        read -r -s -p "Bitwarden master password: " master_password || master_password=""
        printf '\n'
        if [[ -z "$bw_email" || -z "$master_password" ]]; then
            echo "Bitwarden email and master password are required."
            skip_done "Vaultwarden login was not completed"
        fi
        read -r -p "Two-step method (0=authenticator, 1=email, 3=YubiKey; blank if disabled): " two_factor_method || two_factor_method=""
        login_args=(login "$bw_email" --passwordenv BW_PASSWORD --raw)
        if [[ -n "$two_factor_method" ]]; then
            case "$two_factor_method" in
                0|1|3) ;;
                *) echo "Unsupported two-step method: $two_factor_method" >&2; exit 1 ;;
            esac
            read -r -s -p "Two-step verification code: " two_factor_code || two_factor_code=""
            printf '\n'
            if [[ -z "$two_factor_code" ]]; then
                echo "Two-step verification code was not entered."
                skip_done "Vaultwarden login was not completed"
            fi
            login_args+=(--method "$two_factor_method" --code "$two_factor_code")
        fi
        if ! bw_session="$(BW_PASSWORD="$master_password" BW_NOINTERACTION=true bw "${login_args[@]}" 2>/dev/null)"; then
            unset master_password two_factor_code login_args
            echo "Failed to log in to the Vaultwarden account." >&2
            exit 1
        fi
        unset master_password two_factor_code login_args
        ;;
    *)
        echo "Could not determine Bitwarden CLI state. Run 'bw status' and try again." >&2
        exit 1
        ;;
esac

if [[ -n "$bw_session" ]]; then
    if ! auth_key="$(BW_SESSION="$bw_session" BW_NOINTERACTION=true bw get password "Tailscale Auth Key" --raw 2>/dev/null)"; then
        echo "Could not read the Tailscale Auth Key item from Vaultwarden." >&2
        exit 1
    fi
else
    if ! auth_key="$(bw get password "Tailscale Auth Key" --raw 2>/dev/null)"; then
        echo "Could not read the Tailscale Auth Key item from Vaultwarden." >&2
        exit 1
    fi
fi
if [[ -z "$auth_key" ]]; then
    echo "The Tailscale Auth Key item is empty in Vaultwarden." >&2
    exit 1
fi

umask 077
auth_key_file="$(mktemp "${TMPDIR:-/tmp}/tailscale-auth-key.XXXXXX")"
printf '%s' "$auth_key" > "$auth_key_file"
unset auth_key

echo "Connecting Tailscale with the one-off key from Vaultwarden"
if ! TAILSCALE_BE_CLI=1 "$tailscale_cli" login --auth-key="file:$auth_key_file" >/dev/null 2>&1; then
    echo "Tailscale login failed. Check the Tailscale app and one-off key." >&2
    exit 1
fi
if ! TAILSCALE_BE_CLI=1 "$tailscale_cli" status --json 2>/dev/null | jq -e '.BackendState == "Running"' >/dev/null 2>&1; then
    echo "Tailscale is not connected after login." >&2
    exit 1
fi
echo "Tailscale is connected. The temporary auth key file will be removed."
