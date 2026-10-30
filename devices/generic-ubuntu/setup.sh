#!/usr/bin/env bash
# 전체 설치 스크립트: modules 목록의 모듈을 순서대로 실행
# 실패한 모듈이 있어도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨 (다시 실행하면 실패한 모듈만 다시 설치됨)
# 로그: 저장소 logs/generic-ubuntu-<시각>/setup.log
# 사용법: bash setup.sh (sudo 없이 실행, 관리자가 필요한 부분은 모듈에서 sudo 사용)
#   curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-ubuntu/setup.sh | bash
# Cleanup: bash setup.sh --cleanup [--dry-run] [--force]
set -uo pipefail

CLEANUP=0
DRYRUN=0
FORCE=0
for arg in "$@"; do
    case "$arg" in
        --cleanup) CLEANUP=1 ;;
        --dry-run) DRYRUN=1 ;;
        --force) FORCE=1 ;;
    esac
done

# 파일 없이(curl | bash) 실행된 경우: git을 설치하고 저장소를 받은 뒤(이미 git clone이면 pull),
# 받은 setup.sh로 다시 실행 (저장소 안의 파일을 직접 실행할 때는 이 부분을 지나지 않음)
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    # For cleanup via curl|bash, we need to clone first
    if [[ $CLEANUP -eq 1 ]]; then
        install_dir="$HOME/silent_sdk"
        if [[ -n "${SUDO_USER:-}" ]]; then
            user_home="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
            [[ -n "$user_home" ]] && install_dir="$user_home/silent_sdk"
        fi
        run_root() {
            if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi
        }
        if ! command -v git >/dev/null; then
            run_root apt-get update >/dev/null 2>&1 && DEBIAN_FRONTEND=noninteractive run_root apt-get install -y git >/dev/null 2>&1
        fi
        if [[ ! -d "$install_dir/.git" ]]; then
            git clone https://github.com/s1len7/silent_sdk.git "$install_dir" >/dev/null 2>&1 || true
        fi
        exec bash "$install_dir/devices/generic-ubuntu/setup.sh" --cleanup $([ $DRYRUN -eq 1 ] && echo --dry-run) $([ $FORCE -eq 1 ] && echo --force)
    fi
    # sudo로 실행해도 저장소는 sudo한 사용자의 홈에 받음 (root로 직접 로그인했으면 root 홈)
    install_dir="$HOME/silent_sdk"
    if [[ -n "${SUDO_USER:-}" ]]; then
        user_home="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
        [[ -n "$user_home" ]] && install_dir="$user_home/silent_sdk"
    fi

    # root가 아니면 sudo로 설치 (이 장비는 sudo 없이 실행)
    run_root() {
        if [[ $EUID -eq 0 ]]; then "$@"; else sudo "$@"; fi
    }

    if ! command -v git >/dev/null; then
        echo "Installing git"
        if ! { run_root apt-get update && DEBIAN_FRONTEND=noninteractive run_root apt-get install -y git; }; then
            echo "Failed to install git" >&2
            exit 1
        fi
    fi

    if [[ -d "$install_dir/.git" ]]; then
        echo "Updating the repository in $install_dir"
        if ! git -C "$install_dir" pull --ff-only; then
            echo "git pull failed. Continuing with the existing files in $install_dir" >&2
        fi
    else
        # 새로 clone한 뒤 교체: 예전에 압축 파일로 받은 폴더도 git clone으로 바뀜
        new_dir="$(mktemp -d)"
        echo "Cloning the repository to $install_dir"
        if ! git clone https://github.com/s1len7/silent_sdk.git "$new_dir"; then
            rm -rf "$new_dir"
            echo "Failed to clone the repository" >&2
            exit 1
        fi
        # git에 없는 .env(설정)와 logs(이전 실행 기록)는 이전 폴더에서 옮겨 옴
        if [[ -d "$install_dir" ]]; then
            while IFS= read -r -d '' env_file; do
                rel="${env_file#"$install_dir"/}"
                mkdir -p "$new_dir/$(dirname "$rel")"
                cp -p "$env_file" "$new_dir/$rel"
            done < <(find "$install_dir" -type f -name .env -print0)
            [[ -d "$install_dir/logs" ]] && cp -a "$install_dir/logs/." "$new_dir/logs/"
            cd /
            rm -rf "$install_dir"
        fi
        mv "$new_dir" "$install_dir"
        chmod 755 "$install_dir"
    fi

    # sudo한 사용자의 홈에 받았으면 그 사용자 소유로 (사용자가 git pull·편집할 수 있게)
    if [[ -n "${SUDO_USER:-}" ]]; then
        chown -R "$SUDO_USER:" "$install_dir"
    fi

    exec bash "$install_dir/devices/generic-ubuntu/setup.sh"
fi

# Cleanup logic when running from repo
if [[ $CLEANUP -eq 1 ]]; then
    echo "Cleanup mode: removing silent_sdk repository and related personal info"
    echo "Installed programs will NOT be removed."
    echo ""
    
    device_dir_check="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    repo_check="$(cd "$device_dir_check/../.." && pwd)"
    install_dir_cand="$HOME/silent_sdk"
    if [[ -n "${SUDO_USER:-}" ]]; then
        user_home_cand="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
        [[ -n "$user_home_cand" ]] && install_dir_cand="$user_home_cand/silent_sdk"
    fi
    
    targets=()
    [[ -d "$repo_check" ]] && targets+=("$repo_check")
    [[ -d "$install_dir_cand" && "$install_dir_cand" != "$repo_check" ]] && targets+=("$install_dir_cand")
    
    # Check for other silent_sdk dirs in HOME
    if [[ -d "$HOME" ]]; then
        while IFS= read -r -d '' d; do
            [[ "$d" == "$repo_check" || "$d" == "$install_dir_cand" ]] && continue
            targets+=("$d")
        done < <(find "$HOME" -maxdepth 2 -name 'silent_sdk*' -type d -print0 2>/dev/null)
    fi
    
    # Check for .env files outside repo
    if [[ -d "$HOME" ]]; then
        while IFS= read -r -d '' f; do
            targets+=("$f")
        done < <(find "$HOME" -name '.env' -not -path "*/$repo_check/*" -not -path "*/.git/*" -print0 2>/dev/null)
    fi

    # 홈에 직접 둔 GitHub 토큰 파일
    [[ -f "$HOME/.gh_token" ]] && targets+=("$HOME/.gh_token")

    # Temp logs
    if [[ -d /tmp ]]; then
        while IFS= read -r -d '' f; do
            targets+=("$f")
        done < <(find /tmp -name 'silent_sdk*generic-ubuntu*' -print0 2>/dev/null)
    fi

    # 브라우저 로그아웃: 프로필마다 로그인 정보(쿠키·세션·저장된 비밀번호·계정 토큰·사이트 저장소)만 지움
    # 북마크·기록·확장은 PC 주인의 데이터이므로 남김
    # 브라우저는 sudo로 실행해도 sudo한 사용자의 것을 대상으로 함
    browser_home="${user_home_cand:-$HOME}"
    browser_user="${SUDO_USER:-$(id -un)}"
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
            pgrep -u "$browser_user" -x "$p" >/dev/null && echo "$p"
        done
    }

    collect_browser_targets
    running="$(running_browsers)"

    if [[ ${#targets[@]} -eq 0 && ${#browser_targets[@]} -eq 0 ]]; then
        echo "No silent_sdk related files or browser login data found to clean up."
        exit 0
    fi

    echo "Targets to remove:"
    for t in "${targets[@]}" "${browser_targets[@]}"; do echo "  $t"; done
    echo ""
    [[ -n "$running" ]] && echo "Browsers to close (running): ${running//$'\n'/ }" && echo ""

    if [[ $DRYRUN -eq 1 ]]; then
        echo "DryRun: no changes made."
        exit 0
    fi

    if [[ $FORCE -ne 1 ]]; then
        read -r -p "Are you sure you want to delete these? This cannot be undone. (y/N): " resp
        [[ "$resp" != "y" && "$resp" != "Y" ]] && echo "Cancelled." && exit 0
    fi

    # 브라우저가 켜져 있으면 종료할 때 메모리의 쿠키·세션을 다시 저장하므로 먼저 종료
    running="$(running_browsers)"
    if [[ -n "$running" ]]; then
        echo "Closing browsers: ${running//$'\n'/ }"
        for p in $running; do pkill -u "$browser_user" -x "$p"; done
        # 정상 종료를 최대 5초 기다린 뒤, 남아 있으면 강제 종료
        for _ in {1..10}; do
            [[ -z "$(running_browsers)" ]] && break
            sleep 0.5
        done
        for p in $(running_browsers); do pkill -KILL -u "$browser_user" -x "$p"; done
    fi

    # 브라우저 파일은 저장소 밖에 있으므로 바로 지움 (종료하며 새로 생긴 파일까지 다시 찾음)
    collect_browser_targets
    for t in "${browser_targets[@]}"; do
        if rm -rf -- "$t"; then echo "Removed: $t"; else echo "Failed to remove: $t"; fi
    done

    script_path="${BASH_SOURCE[0]}"
    if [[ "$script_path" == "$repo_check"/* ]]; then
        wrapper="/tmp/silent_sdk_cleanup_wrapper_$$.sh"
        {
            echo '#!/usr/bin/env bash'
            echo 'sleep 2'
            for t in "${targets[@]}"; do
                printf "rm -rf -- %q\n" "$t"
            done
        } > "$wrapper"
        chmod +x "$wrapper"
        nohup bash "$wrapper" >/dev/null 2>&1 &
        echo "Cleanup initiated. This window may close."
        exit 0
    fi
    
    for t in "${targets[@]}"; do
        if [[ -e "$t" ]]; then
            rm -rf -- "$t" && echo "Removed: $t" || echo "Failed to remove: $t"
        fi
    done
    echo "Cleanup complete."
    exit 0
fi

device_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$device_dir/../.." && pwd)"
log_dir="$repo/logs/generic-ubuntu-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$log_dir"
# root로 실행한 경우에만 로그 소유자를 원래 사용자로 바꿈 (일반 실행이면 이미 사용자 소유)
if [[ $EUID -eq 0 && -n "${SUDO_USER:-}" ]]; then
    chown -R "$SUDO_USER:" "$repo/logs"
fi

exec > >(tee -a "$log_dir/setup.log") 2>&1

echo "Computer: $(hostname) / User: ${SUDO_USER:-$(whoami)}"
echo "OS:       $(. /etc/os-release && echo "$PRETTY_NAME") ($(uname -m))"
echo "Repo:     $repo @ $(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Logs:     $log_dir"

summary=()
failed=0
modules=(
    setup_git
    setup_vscode
    setup_opencode
    setup_korean_input
)

for name in "${modules[@]}"; do
    module="$device_dir/scripts/$name.sh"
    echo
    echo "=== [$name] started $(date +%H:%M:%S)"
    start=$SECONDS
    if [[ -f "$module" ]]; then
        bash "$module"
        code=$?
    else
        echo "Module not found: $module" >&2
        code=127
    fi
    case $code in
        0) result=OK ;;
        3) result=SKIP ;;
        *) result="FAIL (exit $code)"; failed=$((failed + 1)) ;;
    esac
    echo "=== [$name] $result ($((SECONDS - start))s)"
    summary+=("$(printf '%-24s %s' "$name" "$result")")
done

echo
echo "=== Summary"
printf '%s\n' "${summary[@]}"
if (( failed )); then
    echo "$failed of ${#summary[@]} modules failed. See the log, then run the setup again (finished modules are skipped)."
else
    echo "All ${#summary[@]} modules succeeded or were already set up."
fi
echo "Log: $log_dir/setup.log"
