#!/usr/bin/env bash
# Ubuntu Server VM 전체 설치 스크립트: modules 목록의 모듈을 순서대로 실행 (VM 안에서 sudo로 실행)
# 호스트의 scripts/host/setup_vm_ubuntu_server.sh가 만든 VM은 첫 부팅 때 이 스크립트를 자동으로 실행함
# 실패한 모듈이 있어도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨 (다시 실행하면 실패한 모듈만 다시 설치됨)
# 로그: 저장소 logs/b150m-am2-ubuntu-server-<시각>/setup.log
# 사용법: sudo bash vm/ubuntu-server/setup_vm.sh
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

if command -v pveversion >/dev/null; then
    echo "This is the Proxmox host. Run setup_host.sh on the host, and this script inside the Ubuntu VM." >&2
    exit 1
fi

vm_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$vm_dir/../../../.." && pwd)"
log_dir="$repo/logs/b150m-am2-ubuntu-server-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$log_dir"
# 저장소 소유자가 로그를 읽고 지울 수 있게 함
chown -R "${SUDO_USER:-root}:" "$repo/logs"

# 이후 모든 출력을 화면과 로그 파일에 함께 남김
exec > >(tee -a "$log_dir/setup.log") 2>&1

echo "Computer: $(hostname) / User: ${SUDO_USER:-root}"
echo "OS:       $(. /etc/os-release && echo "$PRETTY_NAME") ($(uname -m))"
echo "Repo:     $repo @ $(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Logs:     $log_dir"

summary=()
failed=0
# 실행할 모듈 (위에서부터 순서대로 실행, 새 모듈은 여기에 한 줄 추가)
modules=(
    setup_openclaw
    setup_openclaw_onboard
    setup_openclaw_telegram
)
for name in "${modules[@]}"; do
    module="$vm_dir/scripts/$name.sh"
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
