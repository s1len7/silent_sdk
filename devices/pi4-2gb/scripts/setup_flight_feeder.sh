#!/usr/bin/env bash
# ADS-B 피더 실행 스크립트 (ultrafeeder + Flightradar24, FlightAware, AirNav Radar, Plane Finder)
# docker/flight_feeder/.env의 위치와 서비스 키로 docker-compose.yml을 실행하고, 키가 빈 서비스는 실행하지 않음
# setup.sh는 이름순으로 실행하므로 setup_docker.sh, setup_dvb_blacklist.sh 다음에 실행됨
# 사용법: sudo bash scripts/setup_flight_feeder.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

repo="$(cd "$(dirname "$0")/.." && pwd)"
env_file="$repo/docker/flight_feeder/.env"
compose="$repo/docker/flight_feeder/docker-compose.yml"

# 피더 서비스 이름과 .env의 키 변수 이름
feeders=(fr24feed piaware airnavradar planefinder)
declare -A key_vars=(
    [fr24feed]=FR24KEY
    [piaware]=PIAWARE_FEEDER_ID
    [airnavradar]=AIRNAVRADAR_SHARING_KEY
    [planefinder]=PLANEFINDER_SHARECODE
)

skip() {
    echo "WARNING: $1, flight feeder skipped." >&2
    echo "Fill in $env_file (see README), then rerun this script." >&2
    exit "$SKIP_EXIT"
}

# 숫자 형식과 범위(-limit ~ limit)가 맞으면 0
valid_number() {
    local value="$1" limit="$2"
    [[ "$value" =~ ^-?[0-9]+(\.[0-9]+)?$ ]] && awk -v v="$value" -v l="$limit" 'BEGIN { exit !(v >= -l && v <= l) }'
}

if ! command -v docker >/dev/null; then
    echo "Docker not found. Run scripts/setup_docker.sh first." >&2
    exit 1
fi

# 위치와 키는 저장소에 없으므로 .env가 있어야 함, 없으면 예시를 복사하고 건너뜀 (터미널이 없어도 멈추지 않게 묻지 않음)
if [[ ! -f "$env_file" ]]; then
    tr -d '\r' < "$env_file.example" > "$env_file"
    # sudo로 실행해도 저장소 소유자가 편집할 수 있게 함
    chown "${SUDO_USER:-root}:" "$env_file"
    skip "created $env_file from example"
fi

# Windows에서 편집해 CR이 들어가면 docker compose가 값에 CR을 포함하므로 제거
sed -i 's/\r$//' "$env_file"
# shellcheck source=/dev/null
source "$env_file"

valid_number "${FEEDER_LAT:-}" 90 || skip "FEEDER_LAT is empty or invalid"
valid_number "${FEEDER_LONG:-}" 180 || skip "FEEDER_LONG is empty or invalid"
valid_number "${FEEDER_ALT_M:-}" 10000 || skip "FEEDER_ALT_M is empty or invalid"

# ultrafeeder와 키가 있는 피더만 실행
services=(ultrafeeder)
missing=()
for s in "${feeders[@]}"; do
    var="${key_vars[$s]}"
    if [[ -n "${!var:-}" ]]; then
        services+=("$s")
    else
        missing+=("$var")
    fi
done
if (( ${#missing[@]} )); then
    echo "WARNING: no key for ${missing[*]} in .env, those feeders are not started (see README for how to get the keys)." >&2
fi

# 실행할 서비스가 모두 실행 중이면 건너뜀
running="$(docker compose -f "$compose" ps --services --status running 2>/dev/null || true)"
all_running=true
for s in "${services[@]}"; do
    grep -qx "$s" <<< "$running" || all_running=false
done
if $all_running; then
    skip_done "Flight feeder is already running (${services[*]})"
fi

docker compose -f "$compose" up -d "${services[@]}"

echo "Flight feeder started: ${services[*]}"
echo "Map: http://$(hostname -I | awk '{print $1}'):8080"
