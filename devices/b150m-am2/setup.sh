#!/usr/bin/env bash
# 전체 설치 스크립트: Proxmox 호스트면 scripts/host/, VM이면 scripts/vm/의 setup_*.sh 모듈을 모두 실행
# 실패한 모듈이 있어도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨 (다시 실행하면 실패한 모듈만 다시 설치됨)
# 로그: 저장소 logs/b150m-am2-<host|vm>-<시각>/setup.log
# 사용법: 호스트는 root로 bash setup.sh, VM은 sudo bash setup.sh
#   curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/setup.sh | bash
#   처럼 파일 없이 실행하면 저장소를 ~/silent_sdk에 새로 받은 뒤 그 안의 setup.sh를 실행함
#   (호스트는 저장소 설정 전에는 apt-get update가 실패해 git을 설치할 수 없으므로 압축 파일로 받음)
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run as root or with sudo: sudo bash $0" >&2
    exit 1
fi

# 파일 없이(curl | bash) 실행된 경우: 저장소를 새로 받아 교체하고, 받은 setup.sh로 다시 실행
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    install_dir="$HOME/silent_sdk"
    if [[ -d "$install_dir/.git" ]]; then
        echo "$install_dir is a git clone. Update it with git pull, then run: bash $install_dir/devices/b150m-am2/setup.sh" >&2
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
    exec bash "$install_dir/devices/b150m-am2/setup.sh"
fi

# 호스트와 VM은 설정할 내용이 달라서 실행 위치로 모듈 폴더를 고름
if command -v pveversion >/dev/null; then
    role=host
else
    role=vm
fi

device_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$device_dir/../.." && pwd)"
log_dir="$repo/logs/b150m-am2-$role-$(date +%Y%m%d-%H%M%S)"
mkdir -p "$log_dir"
# 저장소 소유자가 로그를 읽고 지울 수 있게 함
chown -R "${SUDO_USER:-root}:" "$repo/logs"

# 이후 모든 출력을 화면과 로그 파일에 함께 남김
exec > >(tee -a "$log_dir/setup.log") 2>&1

echo "Computer: $(hostname) / User: ${SUDO_USER:-root}"
echo "OS:       $(. /etc/os-release && echo "$PRETTY_NAME") ($(uname -m))"
echo "Repo:     $repo @ $(git -C "$repo" rev-parse --short HEAD 2>/dev/null || echo unknown)"
echo "Role:     $role (modules: scripts/$role/)"
echo "Logs:     $log_dir"

summary=()
failed=0
for module in "$device_dir/scripts/$role"/setup_*.sh; do
    name="$(basename "$module" .sh)"
    echo
    echo "=== [$name] started $(date +%H:%M:%S)"
    start=$SECONDS
    bash "$module"
    code=$?
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
