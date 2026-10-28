#!/usr/bin/env bash
# 전체 설치 스크립트: modules 목록의 모듈을 순서대로 실행
# 실패한 모듈이 있어도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL)를 요약함
# 모듈은 이미 설정돼 있으면 종료 코드 3으로 끝나며 SKIP으로 표시됨 (다시 실행하면 실패한 모듈만 다시 설치됨)
# 로그: 저장소 logs/pi4-2gb-<시각>/setup.log
# 사용법: sudo bash setup.sh
#   curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/pi4-2gb/setup.sh | sudo bash
#   처럼 파일 없이 실행하면 git을 설치하고 저장소를 ~/silent_sdk에 받은 뒤 그 안의 setup.sh를 실행함
set -uo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

# 파일 없이(curl | sudo bash) 실행된 경우: git을 설치하고 저장소를 받은 뒤(이미 git clone이면 pull),
# 받은 setup.sh로 다시 실행 (저장소 안의 파일을 직접 실행할 때는 이 부분을 지나지 않음)
if [[ ! -f "${BASH_SOURCE[0]:-}" ]]; then
    # sudo로 실행해도 저장소는 sudo한 사용자의 홈에 받음 (root로 직접 로그인했으면 root 홈)
    install_dir="$HOME/silent_sdk"
    if [[ -n "${SUDO_USER:-}" ]]; then
        user_home="$(getent passwd "$SUDO_USER" 2>/dev/null | cut -d: -f6)"
        [[ -n "$user_home" ]] && install_dir="$user_home/silent_sdk"
    fi

    # root가 아니면 sudo로 설치 (generic-ubuntu처럼 sudo 없이 실행하는 장비 대비)
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

    exec bash "$install_dir/devices/pi4-2gb/setup.sh"
fi

device_dir="$(cd "$(dirname "$0")" && pwd)"
repo="$(cd "$device_dir/../.." && pwd)"
log_dir="$repo/logs/pi4-2gb-$(date +%Y%m%d-%H%M%S)"
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
    # 피더 컨테이너보다 Docker 설치와 DVB 드라이버 차단이 먼저
    setup_docker
    setup_dvb_blacklist
    setup_flight_feeder
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
