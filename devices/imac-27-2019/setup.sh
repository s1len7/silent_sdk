#!/usr/bin/env bash
# 전체 설치 스크립트: modules 목록의 모듈을 순서대로 실행
# 실패한 모듈이 있어도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨 (다시 실행하면 실패한 모듈만 다시 설치됨)
# 로그: 저장소 logs/imac-27-2019-<시각>/setup.log
# 사용법: sudo 없이 실행 (macOS 기본 bash 3.2에서도 동작하게 작성)
#   curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/imac-27-2019/setup.sh | bash
set -uo pipefail

# 파일 없이(curl | bash) 실행된 경우: 저장소를 ~/silent_sdk에 받은 뒤(이미 받았으면 git pull),
# 받은 setup.sh로 다시 실행 (저장소 안의 파일을 직접 실행할 때는 이 부분을 지나지 않음)
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    install_dir="$HOME/silent_sdk"
    # macOS의 /usr/bin/git은 Command Line Tools가 없으면 설치 창만 띄우므로 실제 실행으로 확인
    if ! git --version >/dev/null 2>&1; then
        echo "git not found. Run 'xcode-select --install', then run this command again" >&2
        exit 1
    fi
    if [[ -d "$install_dir/.git" ]]; then
        echo "Updating the repository in $install_dir"
        if ! git -C "$install_dir" pull --ff-only; then
            echo "git pull failed. Continuing with the existing files in $install_dir" >&2
        fi
    elif [[ -e "$install_dir" ]]; then
        # git 저장소가 아닌 같은 이름의 폴더는 지우지 않고 멈춤
        echo "$install_dir exists but is not a git repository. Move or remove it, then run this command again" >&2
        exit 1
    else
        echo "Cloning the repository to $install_dir"
        if ! git clone https://github.com/s1len7/silent_sdk.git "$install_dir"; then
            echo "Failed to clone the repository" >&2
            exit 1
        fi
    fi
    exec bash "$install_dir/devices/imac-27-2019/setup.sh"
fi

device_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$device_dir/../.." && pwd)"
log_dir="$repo/logs/imac-27-2019-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$log_dir"
exec > >(tee -a "$log_dir/setup.log") 2>&1

echo "Computer: $(scutil --get ComputerName 2>/dev/null || hostname) / User: $(whoami)"
echo "OS:       macOS $(sw_vers -productVersion) ($(uname -m))"
echo "Repo:     $repo @ $(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Logs:     $log_dir"

summary=()
failed=0
modules=(
    setup_git
    setup_claude_code
    setup_scroll_direction
    setup_hangul_input
    setup_nodejs
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
