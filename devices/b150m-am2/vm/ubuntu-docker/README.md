# ubuntu-docker

- 호스트: [b150m-am2](../../README.md) (Proxmox VE 9)의 VM
- 지원OS: [Ubuntu Server 24.04 LTS](https://ubuntu.com/server) (공식 cloud 이미지)
- 용도: Docker로 서비스 실행 (OpenClaw VM과 분리, 지금은 Metabase)
- 작성 원칙: [VM AGENTS.md](AGENTS.md) 참고 (장비 규칙은 [장비 AGENTS.md](../../AGENTS.md), 공통 규칙은 [상위 AGENTS.md](../../../../AGENTS.md))

| 항목 | 사양 |
| --- | --- |
| VM 번호 | 101 |
| CPU | 2코어 (host 타입) |
| RAM | 3072MB |
| 디스크 | 32GB (local-lvm) |
| 네트워크 | vmbr0 (유선 브리지), DHCP, mDNS 이름 `ubuntu-docker.local` |
| 계정 | silent (SSH 키 로그인, 비밀번호 없이 sudo) |


## 기능

- 전체 Setup: 호스트의 [Docker VM 생성](../../README.md#docker-vm-생성-호스트)으로 만든 VM은 첫 부팅 때 [setup_vm.sh](setup_vm.sh)가 자동으로 실행됨. 직접 실행하려면 VM 안에서:

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/vm/ubuntu-docker/setup_vm.sh | sudo bash
```

- 이미 클론되어 있으면: `sudo bash ~/silent_sdk/devices/b150m-am2/vm/ubuntu-docker/setup_vm.sh`
- 파일 없이 실행하면 git을 설치하고 저장소를 받은 뒤(이미 받았으면 `git pull`) 그 안의 `setup_vm.sh`를 실행함
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함
- 로그: `~/silent_sdk/logs/b150m-am2-ubuntu-docker-<시각>/setup.log`


### mDNS (Avahi)

- Setup: [scripts/setup_avahi.sh](scripts/setup_avahi.sh) (집 안의 다른 기기에서 `ubuntu-docker.local`로 접속할 수 있게 avahi-daemon 설치)
  - 다시 실행 시: `avahi-daemon`이 설치돼 있고 실행 중이면 건너뜀


### Docker

- Setup: [scripts/setup_docker.sh](scripts/setup_docker.sh) ([Docker 공식 apt 저장소](https://docs.docker.com/engine/install/ubuntu/)로 Docker Engine과 compose 플러그인 설치)
  - 다시 실행 시: Docker 패키지가 모두 설치돼 있고 `docker` 서비스가 실행 중이면 건너뜀
- 업데이트: `sudo apt-get update && sudo apt-get upgrade`


### Metabase

- Setup: [scripts/setup_metabase.sh](scripts/setup_metabase.sh) ([projects/metabase/compose.yaml](projects/metabase/compose.yaml)을 `/srv/docker/metabase/`에 복사해 실행)
  - 다시 실행 시: `/srv/docker/metabase/compose.yaml`이 저장소와 같고 `metabase` 컨테이너가 실행 중이면 건너뜀
- 웹 화면: `http://ubuntu-docker.local:3000`
- 데이터: `/srv/docker/metabase/metabase-data/` (내장 H2 DB 파일)
- 이미지 업데이트: `cd /srv/docker/metabase && sudo docker compose pull && sudo docker compose up -d`

#### NAS에서 옮기기

NAS(ds218plus)의 Metabase 데이터를 그대로 옮긴다. VM에서 Metabase가 한 번 실행된 뒤 아래 순서로 한다.

1. NAS의 metabase 프로젝트를 멈춤 (데이터가 바뀌지 않게): PC에서 `ssh silent-nas.local 'python3 - stop metabase' < devices/ds218plus/scripts/synoproj.py`
2. VM의 Metabase를 멈추고 새로 만들어진 빈 데이터를 치움: VM에서 `cd /srv/docker/metabase && sudo docker compose down && sudo rm -rf metabase-data/metabase.db`
3. NAS의 `/volume1/docker/metabase/metabase-data/metabase.db/`를 VM의 `/srv/docker/metabase/metabase-data/`로 복사 (예: NAS에서 `tar` → VM에서 풀기)
4. VM에서 다시 시작: `sudo docker compose up -d`, `http://ubuntu-docker.local:3000`에서 로그인과 대시보드 확인
5. 확인되면 ds218plus 쪽 정리 (metabase 프로젝트 삭제, README 표·Homepage 항목 수정, 사용자 확인 후)


## TODO

- [ ] 실제 장비에서 아직 시험하지 않음 (2026-11-01 작성 당시 b150m-am2가 꺼져 있었음). 장비를 켠 뒤 확인할 것
  - [ ] 호스트에서 `bash scripts/host/setup_vm_ubuntu_docker.sh`로 VM 생성, 첫 부팅 때 `setup_vm.sh`가 모두 OK인지
  - [ ] 호스트 이름이 `ubuntu-docker`가 되고 다른 기기에서 `ubuntu-docker.local`로 접속되는지
  - [ ] Metabase가 `http://ubuntu-docker.local:3000`에서 열리는지
  - [ ] 위 "NAS에서 옮기기"로 데이터를 옮기고 기존 대시보드가 그대로 보이는지
