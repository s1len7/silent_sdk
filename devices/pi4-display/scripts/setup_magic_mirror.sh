#!/usr/bin/env bash
# Magic Mirror & MMPM 실행 스크립트
# 한글 폰트 설치 후 docker/magic_mirror/docker-compose.yml 실행
# 사용법: sudo bash scripts/setup_magic_mirror.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

repo="$(cd "$(dirname "$0")/.." && pwd)"
env_file="$repo/docker/magic_mirror/.env"
compose="$repo/docker/magic_mirror/docker-compose.yml"
fonts=(fonts-nanum fonts-nanum-extra)
power_rule=/etc/polkit-1/rules.d/50-magicmirror-power.rules

# .env, 한글 폰트, 전원 polkit 규칙, 실행 중인 컨테이너가 모두 있으면 건너뜀 (위치를 다시 묻지 않음)
if [[ -f "$env_file" ]] && pkgs_installed "${fonts[@]}" && [[ -f "$power_rule" ]] && compose_running "$compose"; then
    skip_done "Magic Mirror is already running"
fi

skip() {
    echo "WARNING: $1, Magic Mirror skipped." >&2
    echo "Run: cp $env_file.example $env_file, fill in MM_LAT and MM_LON, then rerun this script." >&2
    exit "$SKIP_EXIT"
}

# 숫자 형식과 범위(-limit ~ limit)가 맞을 때까지 다시 입력받음
read_coord() {
    local name="$1" limit="$2" value
    while true; do
        read -r -p "$name (-$limit to $limit): " value
        if [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && awk -v v="$value" -v l="$limit" 'BEGIN { exit !(v >= -l && v <= l) }'; then
            echo "$value"
            return
        fi
        echo "Invalid $name: $value" >&2
    done
}

# 공인 IP 기준으로 위치 추정 (ipinfo.io의 "loc": "위도,경도"), 실패하면 1 반환
estimate_location() {
    local loc city
    loc="$(curl -fsS --max-time 10 https://ipinfo.io/json | sed -n 's/.*"loc": *"\([^"]*\)".*/\1/p')" || return 1
    [[ "$loc" =~ ^-?[0-9]+(\.[0-9]+)?,-?[0-9]+(\.[0-9]+)?$ ]] || return 1
    lat="${loc%,*}"
    lon="${loc#*,}"
    city="$(curl -fsS --max-time 10 https://ipinfo.io/city || true)"
    echo "Estimated location: $lat, $lon ($city)"
}

# 날씨 위치(MM_LAT, MM_LON)는 저장소에 없으므로 .env가 있어야 함
# 없으면 1) IP로 추정(기본값) 2) 직접 입력 3) 건너뛰기 중 선택
# 묻지 못하는 환경(터미널 없음)은 입력 없음으로 보고 기본값 1을 사용하며, 추정에 실패하면 전체 설치(setup.sh)가 멈추지 않도록 건너뜀
if [[ ! -f "$env_file" ]]; then
    choice=1
    if [[ -t 0 ]]; then
        echo "docker/magic_mirror/.env not found. Set the weather location (MM_LAT, MM_LON):"
        echo "  1) Estimate from current public IP (default)"
        echo "  2) Enter coordinates"
        echo "  3) Skip Magic Mirror"
        while true; do
            read -r -p "Choose [1-3, default 1]: " choice
            choice="${choice:-1}"
            [[ "$choice" =~ ^[123]$ ]] && break
            echo "Invalid choice: $choice" >&2
        done
    fi

    case "$choice" in
        1)
            if ! estimate_location; then
                [[ -t 0 ]] || skip "location estimate from IP failed"
                echo "Location estimate from IP failed, enter coordinates instead." >&2
                choice=2
            fi
            ;;
        3)
            skip "skipped by user"
            ;;
    esac
    if [[ "$choice" == 2 ]]; then
        lat="$(read_coord MM_LAT 90)"
        lon="$(read_coord MM_LON 180)"
    fi

    printf 'MM_LAT=%s\nMM_LON=%s\n' "$lat" "$lon" > "$env_file"
    # sudo로 실행해도 저장소 소유자가 편집할 수 있게 함
    chown "${SUDO_USER:-root}:" "$env_file"
    echo "Created $env_file"
fi

apt-get update
apt-get install -y fonts-nanum fonts-nanum-extra

# 웹 리모컨(MMM-Remote-Control)의 전원 끄기·재부팅은 컨테이너 안에서 systemctl poweroff/reboot으로 호스트 logind에 요청함
# 컨테이너는 로그인 세션이 없어 polkit이 관리자 인증을 요구하므로, 장비 사용자에게 인증 없이 허용함
# (inhibit 액션은 화면 세션이 종료 지연(inhibitor)을 걸어 둔 경우에도 끌 수 있게 함)
user="${SUDO_USER:-root}"
cat > "$power_rule" <<EOF
// MagicMirror 웹 리모컨의 전원 끄기·재부팅 허용 (scripts/setup_magic_mirror.sh가 설치)
polkit.addRule(function (action, subject) {
  var actions = [
    "org.freedesktop.login1.power-off",
    "org.freedesktop.login1.power-off-multiple-sessions",
    "org.freedesktop.login1.power-off-ignore-inhibit",
    "org.freedesktop.login1.reboot",
    "org.freedesktop.login1.reboot-multiple-sessions",
    "org.freedesktop.login1.reboot-ignore-inhibit"
  ];
  if (subject.user === "$user" && actions.indexOf(action.id) >= 0) {
    return polkit.Result.YES;
  }
});
EOF
chmod 644 "$power_rule"
echo "Installed polkit rule: $power_rule (power off/reboot for $user)"

docker compose -f "$repo/docker/magic_mirror/docker-compose.yml" up -d

echo "Magic Mirror and MMPM started (MMPM on port 7890)"
