#!/usr/bin/env bash
# Docker Engine 설치 스크립트 (Docker VM 안에서 실행, Proxmox 호스트에서는 실행하지 않음)
# Docker 공식 apt 저장소로 Docker Engine과 compose 플러그인을 설치함
# 공식 문서: https://docs.docker.com/engine/install/ubuntu/
# 사용법: sudo bash vm/ubuntu-docker/scripts/setup_docker.sh
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

docker_pkgs=(docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin)
keyring=/etc/apt/keyrings/docker.asc
source_file=/etc/apt/sources.list.d/docker.sources

# 패키지가 모두 있고 Docker가 실행 중이면 건너뜀 (업데이트는 apt upgrade로 함)
if pkgs_installed "${docker_pkgs[@]}" && systemctl is-active --quiet docker; then
    skip_done "Docker is already installed ($(docker --version))"
fi

# 1. Docker 공식 저장소 등록 (공식 문서와 같은 방식)
if [[ ! -s "$keyring" || ! -f "$source_file" ]]; then
    echo "Adding the Docker apt repository"
    apt-get update
    DEBIAN_FRONTEND=noninteractive apt-get install -y ca-certificates curl
    install -m 0755 -d /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o "$keyring"
    chmod a+r "$keyring"
    codename="$(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}")"
    cat > "$source_file" <<EOF
Types: deb
URIs: https://download.docker.com/linux/ubuntu
Suites: $codename
Components: stable
Signed-By: $keyring
EOF
fi

# 2. Docker Engine과 compose 플러그인 설치
echo "Installing ${docker_pkgs[*]}"
apt-get update
DEBIAN_FRONTEND=noninteractive apt-get install -y "${docker_pkgs[@]}"
systemctl enable --now docker

if ! docker run --rm hello-world >/dev/null; then
    echo "Docker is installed but the hello-world test failed. Check: journalctl -u docker" >&2
    exit 1
fi
docker image rm hello-world >/dev/null 2>&1 || true
echo "Docker is ready: $(docker --version), $(docker compose version)"
