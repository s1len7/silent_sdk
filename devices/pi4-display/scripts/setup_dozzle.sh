#!/usr/bin/env bash
# dozzle(컨테이너 로그 뷰어) 실행 스크립트
# docker/dozzle/docker-compose.yml 실행 (restart 설정에 따라 재부팅 시 자동 시작)
# 사용법: sudo bash scripts/setup_dozzle.sh
set -euo pipefail

if [[ $EUID -ne 0 ]]; then
    echo "Root privileges required. Run with sudo: sudo bash $0" >&2
    exit 1
fi

source "$(dirname "$0")/lib.sh"

repo="$(cd "$(dirname "$0")/.." && pwd)"
compose="$repo/docker/dozzle/docker-compose.yml"
# /data 마운트 원본 경로 (docker-compose.yml의 ./data와 같은 위치 = compose 파일 옆의 data 폴더)
# docker compose는 상대 경로를 compose 파일 위치 기준으로 풀므로 실행 결과는 항상 이 경로와 같음
data_dir="$(cd "$(dirname "$compose")" && pwd)/data"
user_name="${SUDO_USER:-$(whoami)}"

# 컨테이너가 실행 중이면 /data가 data_dir에 바인드돼 있을 때만 건너뜀
# (docker-compose.yml의 마운트 설정이 바뀌면 아래에서 컨테이너를 다시 만들어 적용)
if compose_running "$compose"; then
    data_mount="$(docker inspect --format '{{range .Mounts}}{{if eq .Destination "/data"}}{{.Type}}:{{.Source}}{{end}}{{end}}' dozzle 2>/dev/null || true)"
    if [[ "$data_mount" == "bind:$data_dir" ]]; then
        skip_done "dozzle is already running with $data_dir mounted"
    fi
    echo "dozzle /data mount is $data_mount, recreating container to apply $data_dir"
fi

# dozzle 컨테이너가 root로 /data에 파일을 만들므로, 저장소 폴더 소유자는 사용자로 맞춤
mkdir -p "$data_dir"
chown -R "$user_name:" "$data_dir"

docker compose -f "$compose" up -d

echo "dozzle started on port 38080"
