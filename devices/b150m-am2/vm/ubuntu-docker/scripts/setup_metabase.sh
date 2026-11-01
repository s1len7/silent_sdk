#!/usr/bin/env bash
# Metabase 실행 스크립트 (Docker VM 안에서 실행, Proxmox 호스트에서는 실행하지 않음)
# 저장소의 projects/metabase/compose.yaml을 /srv/docker/metabase/에 복사하고 docker compose로 실행함
# 데이터는 /srv/docker/metabase/metabase-data/ (NAS에서 옮길 때는 README의 "NAS에서 옮기기" 참고)
# 사용법: sudo bash vm/ubuntu-docker/scripts/setup_metabase.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

if command -v pveversion >/dev/null; then
    echo "This is the Proxmox host. Run this script inside the Docker VM." >&2
    exit 1
fi

if ! command -v docker >/dev/null || ! docker compose version >/dev/null 2>&1; then
    echo "Docker with the compose plugin is required. Run setup_docker.sh first." >&2
    exit 1
fi

src="$(cd "$(dirname "$0")/.." && pwd)/projects/metabase/compose.yaml"
project_dir=/srv/docker/metabase
compose_file="$project_dir/compose.yaml"
health_url=http://localhost:3000/api/health

# Windows에서 편집해 CR이 들어갔을 수 있으므로 CR을 뺀 내용으로 비교·복사함
wanted="$(sed 's/\r$//' "$src")"

# compose 내용이 같고 컨테이너가 실행 중이면 건너뜀
if [[ -f "$compose_file" && "$(cat "$compose_file")" == "$wanted" ]] \
    && [[ "$(docker inspect -f '{{.State.Running}}' metabase 2>/dev/null)" == true ]]; then
    skip_done "Metabase is already running ($compose_file)"
fi

mkdir -p "$project_dir/metabase-data"
printf '%s\n' "$wanted" > "$compose_file"

echo "Starting Metabase ($compose_file)"
docker compose -f "$compose_file" up -d

# 첫 시작은 DB 준비에 1~2분 걸리므로 상태 확인 주소가 ok를 줄 때까지 기다림
echo "Waiting for Metabase to become healthy (up to 5 minutes)"
for _ in $(seq 60); do
    if curl -fsS "$health_url" 2>/dev/null | grep -q '"ok"'; then
        echo "Metabase is running: http://$(hostname).local:3000"
        exit 0
    fi
    sleep 5
done
echo "Metabase did not become healthy within 5 minutes. Check: docker logs metabase" >&2
exit 1
