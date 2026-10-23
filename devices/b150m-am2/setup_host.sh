#!/usr/bin/env bash
# Proxmox 호스트 전체 설치 스크립트: modules 목록의 모듈을 순서대로 실행 (호스트에서 root로 실행)
# 실패한 모듈이 있어도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨 (다시 실행하면 실패한 모듈만 다시 설치됨)
# 로그: 저장소 logs/b150m-am2-host-<시각>/setup.log
# 사용법: bash setup_host.sh
#   curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/setup_host.sh | bash
#   처럼 파일 없이 실행하면 저장소를 ~/silent_sdk에 새로 받은 뒤 그 안의 setup_host.sh를 실행함
#   (저장소 설정 전에는 apt-get update가 실패해 git을 설치할 수 없으므로 압축 파일로 받음)
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run as root: bash $0" >&2
    exit 1
fi

if ! command -v pveversion >/dev/null; then
    echo "Not a Proxmox host. In the Ubuntu VM, run vm/ubuntu-server/setup_vm.sh instead." >&2
    exit 1
fi

# 파일 없이(curl | bash) 실행된 경우: 저장소를 새로 받아 교체하고, 받은 setup_host.sh로 다시 실행
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    install_dir="$HOME/silent_sdk"
    if [[ -d "$install_dir/.git" ]]; then
        echo "$install_dir is a git clone. Update it with git pull, then run: bash $install_dir/devices/b150m-am2/setup_host.sh" >&2
        exit 1
    fi
    new_dir="$(mktemp -d)"
    echo "Downloading the repository to $install_dir"
    if ! curl -fsSL https://github.com/s1len7/silent_sdk/archive/refs/heads/main.tar.gz \
        | tar xz --strip-components=1 -C "$new_dir"; then
        rm -rf "$new_dir"
        echo "Failed to download the repository" >&2
        exit 1
    fi
    # git에 없는 .env(설정)와 logs(이전 실행 기록)는 이전 폴더에서 옮겨 옴
    if [[ -d "$install_dir" ]]; then
        if [[ -f "$install_dir/devices/b150m-am2/.env" ]]; then
            cp -p "$install_dir/devices/b150m-am2/.env" "$new_dir/devices/b150m-am2/.env"
        fi
        if [[ -d "$install_dir/logs" ]]; then
            cp -a "$install_dir/logs/." "$new_dir/logs/"
        fi
        rm -rf "$install_dir"
    fi
    mv "$new_dir" "$install_dir"
    chmod 755 "$install_dir"
    exec bash "$install_dir/devices/b150m-am2/setup_host.sh"
fi

device_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$device_dir/../.." && pwd)"
log_dir="$repo/logs/b150m-am2-host-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$log_dir"

# 이후 모든 출력을 화면과 로그 파일에 함께 남김
exec > >(tee -a "$log_dir/setup.log") 2>&1

echo "Computer: $(hostname) / User: root"
echo "OS:       $(. /etc/os-release && echo "$PRETTY_NAME") ($(uname -m)), $(pveversion)"
echo "Repo:     $repo @ $(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Logs:     $log_dir"

summary=()
failed=0
# 실행할 모듈 (위에서부터 순서대로 실행, 새 모듈은 여기에 한 줄 추가)
modules=(
    # 저장소 설정과 패치를 먼저 한 뒤 VM 생성
    setup_pve_repo
    setup_vm_ubuntu_server
)
for name in "${modules[@]}"; do
    module="$device_dir/scripts/host/$name.sh"
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
    summary+=("$(printf '%-28s %s' "$name" "$result")")
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
