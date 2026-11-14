#!/usr/bin/env bash
# 반납 전 정리: silent_sdk 저장소와 개인정보(저장소 밖 .env, GitHub 토큰, 브라우저 로그인 정보)를 삭제
# 설치된 프로그램과 Docker 컨테이너는 삭제하지 않음 (저장소 데이터를 쓰는 컨테이너는 먼저 중지할 것)
# 사용법: sudo bash scripts/cleanup.sh [--dry-run] [--force]
# 라즈베리파이 공통 모듈 (pi4-display, pi4-2gb, pi5에서 사용)
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

dry_run=0
force=0
for arg in "$@"; do
    case "$arg" in
        --dry-run) dry_run=1 ;;
        --force) force=1 ;;
        -h|--help)
            echo "Usage: sudo bash $0 [--dry-run] [--force]"
            exit 0
            ;;
        *)
            echo "Unknown argument: $arg" >&2
            exit 1
            ;;
    esac
done

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(cd "$script_dir/../../.." && pwd)"
user="${SUDO_USER:-$(id -un)}"
user_home="$(getent passwd "$user" | cut -d: -f6)"
if [[ -z "$user_home" || ! -d "$user_home" ]]; then
    echo "Home directory not found for user $user" >&2
    exit 1
fi

echo "Cleanup mode: removing the silent_sdk repository and related personal info"
echo "Installed programs and Docker containers will NOT be removed."
echo ""

targets=()
declare -A seen
add_target() {
    local path="$1"
    [[ -e "$path" || -L "$path" ]] || return 0
    [[ -n "${seen[$path]:-}" ]] && return 0
    seen["$path"]=1
    targets+=("$path")
}

# 실행 중인 이 저장소와 홈에 받은 복사본 (.env는 저장소와 함께 지워짐)
add_target "$repo"
[[ "$user_home/silent_sdk" == "$repo" ]] || add_target "$user_home/silent_sdk"

while IFS= read -r -d '' d; do
    add_target "$d"
done < <(find "$user_home" -maxdepth 2 -name 'silent_sdk*' -type d -print0 2>/dev/null)

# 홈에 직접 둔 GitHub 토큰 파일
add_target "$user_home/.gh_token"

# /tmp에 남은 정리용 임시 파일
while IFS= read -r -d '' f; do
    add_target "$f"
done < <(find /tmp -maxdepth 1 -name 'silent_sdk_cleanup_wrapper_*' -print0 2>/dev/null)

# 브라우저 로그아웃: 프로필마다 로그인 정보(쿠키·세션·저장된 비밀번호·계정 토큰·사이트 저장소)만 지움
# 북마크·기록·확장은 PC 주인의 데이터이므로 남김
browser_home="$user_home"
browser_user="$user"
chromium_dirs=(
    "$browser_home/.config/google-chrome"
    "$browser_home/.config/microsoft-edge"
    "$browser_home/.config/chromium"
    "$browser_home/snap/chromium/common/chromium"
)
chromium_login_files=(
    Cookies Network/Cookies "Extension Cookies"
    "Login Data" "Login Data For Account" "Web Data" "Account Web Data"
    Sessions "Current Session" "Current Tabs" "Last Session" "Last Tabs"
    "Local Storage" "Session Storage" IndexedDB
)
firefox_dirs=(
    "$browser_home/.mozilla/firefox"
    "$browser_home/snap/firefox/common/.mozilla/firefox"
)
firefox_login_files=(
    cookies.sqlite logins.json logins-backup.json signedInUser.json
    sessionstore.jsonlz4 sessionstore-backups storage/default webappsstore.sqlite
)
browser_processes=(chrome chromium msedge firefox firefox-bin)

# 프로필 폴더(표시 파일이 있는 하위 폴더)마다 있는 로그인 정보 경로를 browser_targets에 추가
# 사용법: add_login_files <브라우저 데이터 폴더> <프로필 표시 파일> <파일 이름...>
add_login_files() {
    local base="$1" marker="$2" profile name suffix
    shift 2
    for profile in "$base"/*/; do
        [[ -f "$profile$marker" ]] || continue
        for name in "$@"; do
            # SQLite 보조 파일(-journal, -wal, -shm)도 함께 지움
            for suffix in "" -journal -wal -shm; do
                [[ -e "$profile$name$suffix" ]] && browser_targets+=("$profile$name$suffix")
            done
        done
    done
}

collect_browser_targets() {
    local base
    browser_targets=()
    for base in "${chromium_dirs[@]}"; do
        add_login_files "$base" Preferences "${chromium_login_files[@]}"
    done
    for base in "${firefox_dirs[@]}"; do
        add_login_files "$base" prefs.js "${firefox_login_files[@]}"
    done
}

# 실행 중인 브라우저 프로세스 이름을 한 줄에 하나씩 출력
running_browsers() {
    local p
    for p in "${browser_processes[@]}"; do
        if pgrep -u "$browser_user" -x "$p" >/dev/null; then
            echo "$p"
        fi
    done
}

collect_browser_targets
running="$(running_browsers)"

if [[ ${#targets[@]} -eq 0 && ${#browser_targets[@]} -eq 0 ]]; then
    echo "No silent_sdk related files or browser login data found to clean up."
    exit 0
fi

echo "Targets to remove:"
for t in "${targets[@]}" "${browser_targets[@]}"; do
    echo "  $t"
done
echo ""
if [[ -n "$running" ]]; then
    echo "Browsers to close (running): ${running//$'\n'/ }"
    echo ""
fi

if (( dry_run )); then
    echo "DryRun: no changes made."
    exit 0
fi

if (( ! force )); then
    if [[ ! -t 0 ]]; then
        echo "No terminal for confirmation. Run with --force to delete without confirmation." >&2
        exit 1
    fi
    read -r -p "Are you sure you want to delete these? This cannot be undone. (y/N): " resp
    if [[ "$resp" != "y" && "$resp" != "Y" ]]; then
        echo "Cancelled."
        exit 0
    fi
fi

# 브라우저가 켜져 있으면 종료할 때 메모리의 쿠키·세션을 다시 저장하므로 먼저 종료
running="$(running_browsers)"
if [[ -n "$running" ]]; then
    echo "Closing browsers: ${running//$'\n'/ }"
    while IFS= read -r p; do
        [[ -n "$p" ]] && pkill -u "$browser_user" -x "$p" || true
    done <<< "$running"
    # 정상 종료를 최대 5초 기다린 뒤, 남아 있으면 강제 종료
    for _ in {1..10}; do
        [[ -z "$(running_browsers)" ]] && break
        sleep 0.5
    done
    while IFS= read -r p; do
        [[ -n "$p" ]] && pkill -KILL -u "$browser_user" -x "$p" || true
    done < <(running_browsers)
fi

# 브라우저 파일은 저장소 밖에 있으므로 바로 지움 (종료하며 새로 생긴 파일까지 다시 찾음)
collect_browser_targets
for t in "${browser_targets[@]}"; do
    if rm -rf -- "$t"; then
        echo "Removed: $t"
    else
        echo "Failed to remove: $t" >&2
    fi
done

# 이 스크립트가 저장소 안에 있으면 저장소를 지울 수 없으므로 잠시 뒤 지우는 wrapper를 띄움
if [[ "$script_dir" == "$repo"/* ]]; then
    wrapper="/tmp/silent_sdk_cleanup_wrapper_$$.sh"
    {
        echo '#!/usr/bin/env bash'
        echo 'sleep 2'
        for t in "${targets[@]}"; do
            printf 'rm -rf -- %q\n' "$t"
        done
        echo 'rm -f -- "$0"'
    } > "$wrapper"
    chmod +x "$wrapper"
    nohup bash "$wrapper" >/dev/null 2>&1 &
    echo "Cleanup initiated. This window may close."
    exit 0
fi

for t in "${targets[@]}"; do
    if [[ -e "$t" || -L "$t" ]]; then
        if rm -rf -- "$t"; then
            echo "Removed: $t"
        else
            echo "Failed to remove: $t" >&2
        fi
    fi
done
echo "Cleanup complete."
