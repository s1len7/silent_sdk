#!/usr/bin/env bash
# 전체 설치 스크립트: modules 목록의 모듈을 순서대로 실행
# 실패한 모듈이 있어도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨 (다시 실행하면 실패한 모듈만 다시 설치됨)
# 로그: 저장소 logs/generic-ubuntu-<시각>/setup.log
# 사용법: bash setup.sh (sudo 없이 실행, 관리자가 필요한 부분은 모듈에서 sudo 사용)
set -uo pipefail

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
    module="$device_dir/modules/$name.sh"
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
