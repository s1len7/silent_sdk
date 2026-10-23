# ASUS B150M-A/M.2

- 제조사: [ASUS](https://www.asus.com/)
- 모델명: [B150M-A/M.2](https://www.asus.com/supportonly/b150m-am.2/helpdesk/) (Micro-ATX 메인보드, Intel B150)
- 지원OS: [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) 9 (호스트, Debian 13 기반) + Ubuntu Server 24.04 LTS VM (OpenClaw 실행)
- 용도: [OpenClaw](https://docs.openclaw.ai/install) 서버
- 작성 원칙: [CLAUDE.md](CLAUDE.md) 참고 (공통 규칙은 [상위 CLAUDE.md](../../CLAUDE.md))

| 항목 | 사양 |
| --- | --- |
| 폼팩터 | Micro-ATX |
| 칩셋 | Intel B150 |
| CPU | Intel Core i5-7600 (Kaby Lake, 4코어 4스레드, 3.5GHz / 최대 4.1GHz, TDP 65W, VT-x·VT-d 지원) (보드: LGA 1151) |
| RAM | DDR4 16GB (보드: 4슬롯, 최대 64GB) |
| 저장장치 | SSD 256GB (보드: SATA 6Gb/s x6, M.2 x1 (2242/2260/2280, SATA·PCIe x4)) |
| 확장 슬롯 | PCIe 3.0 x16 x1, PCIe 3.0 x1 x2 |
| 디스플레이 출력 | HDMI 1.4, DVI-D, VGA (CPU 내장 그래픽 HD Graphics 630) |
| LAN | Realtek RTL8111H 1Gbps |
| 오디오 | Realtek ALC887 |
| USB (후면) | USB 3.1 Gen1 Type-C x1, USB 3.0 x2, USB 2.0 x2 |
| 기타 | TPM 헤더, 내부 USB 3.0 커넥터 |


## 기능

- 순서: Proxmox VE 9 설치 → 호스트 Setup (저장소 설정, Ubuntu Server 24.04 LTS VM 생성, 첫 부팅 때 VM Setup 자동 실행) → VM에서 OpenClaw 온보딩
- [setup.sh](setup.sh)는 실행 위치를 판별해 Proxmox 호스트면 `scripts/host/`, VM이면 `scripts/vm/`의 모듈을 모두 실행
- 호스트 Setup: Proxmox 셸(root)에서 이 한 줄만 실행 (저장소를 `~/silent_sdk`에 새로 받아 전체 설치):

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/setup.sh | bash
```

  - 다시 실행하면 `~/silent_sdk`를 지우고 최신 저장소로 새로 받음. `.env`와 `logs/`는 옮겨 와서 유지됨 (`~/silent_sdk`가 git clone이면 지우지 않고 중단)

- VM Setup: 호스트 Setup이 만든 VM은 첫 부팅 때 자동으로 실행됨. 직접 만든 VM이면 **VM 안에서** OpenClaw를 쓸 사용자 계정으로 이 한 줄만 실행 (git이 없으면 설치 → 저장소 클론 → 전체 설치):

```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/b150m-am2/setup.sh
```

- 저장소를 새로 받지 않고 실행: 호스트는 `bash ~/silent_sdk/devices/b150m-am2/setup.sh`, VM은 `sudo bash ~/silent_sdk/devices/b150m-am2/setup.sh`
- 개별 기능만 설치: 이 폴더(`~/silent_sdk/devices/b150m-am2`)에서 `bash scripts/host/setup_<기능>.sh` (호스트) 또는 `sudo bash scripts/vm/setup_<기능>.sh` (VM)
- 실패한 모듈이 있어도 나머지 모듈은 계속 진행하고, 끝에 모듈별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함 (모듈별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `~/silent_sdk/logs/b150m-am2-<host|vm>-<시각>/setup.log`


### Proxmox 저장소 (호스트)

- Setup: [scripts/host/setup_pve_repo.sh](scripts/host/setup_pve_repo.sh) (적용 후 새 커널이 설치됐으면 재부팅)
  - 다시 실행 시: enterprise 저장소가 모두 꺼져 있고 no-subscription 저장소가 있으면 건너뜀 (웹 UI로 바꾼 경우도 포함)
- 구독 키가 없으면 기본으로 켜진 enterprise 저장소 때문에 `apt-get update`가 `exit code 100`으로 실패함
- [공식 문서](https://pve.proxmox.com/wiki/Package_Repositories)대로 `pve-enterprise.sources`(와 enterprise인 `ceph.sources`)에 `Enabled: no`를 넣고, `proxmox.sources`에 no-subscription 저장소를 추가한 뒤 `apt-get full-upgrade`로 최신 패치를 적용함
- 웹 UI에서 하려면: 노드 → 업데이트 → 리포지토리에서 enterprise 항목을 비활성화하고, 추가 → No-Subscription


### Ubuntu VM 생성 (호스트)

- Setup: [scripts/host/setup_vm.sh](scripts/host/setup_vm.sh) ([공식 Cloud-Init 방식](https://pve.proxmox.com/wiki/Cloud-Init_Support))
  - 다시 실행 시: 같은 번호(`VM_ID`)의 VM이 있으면 건너뜀 (기존 VM은 건드리지 않음)
- Ubuntu 24.04 공식 cloud 이미지를 받아 체크섬을 확인한 뒤 VM을 만들고 시작함 (Proxmox 부팅 시 자동 시작)
- 설정: `.env` ([.env.example](.env.example) 참고, git에 올라가지 않음). 비워 두면 아래 기본값

| 항목 | 기본값 | `.env` |
|---|---|---|
| VM 번호, 이름 | 100, ubuntu-server | `VM_ID`, `VM_NAME` |
| 사양 | 2코어, 2048MB, 32GB | `VM_CORES`, `VM_MEMORY_MB`, `VM_DISK_GB` |
| 저장소, 브리지 | local-lvm, vmbr0 | `VM_STORAGE`, `VM_BRIDGE` |
| 계정 | silent (비밀번호 없이 sudo) | `VM_USER` |
| SSH 키 | 호스트의 `/root/.ssh/authorized_keys` | `VM_SSH_KEYS_FILE` |
| IP | DHCP | `VM_IP` (CIDR), `VM_GATEWAY`, `VM_DNS` |
| OpenClaw 자동 설치 | yes | `VM_AUTO_OPENCLAW` |

- 비밀번호 로그인은 없고 SSH 키로만 접속함. 기본값이면 Proxmox 호스트 셸에서 `ssh silent@<VM IP>`로 접속
  - DHCP일 때 VM IP는 첫 부팅 후 웹 화면의 VM → 요약(guest agent가 알려 줌)에서 확인
- 첫 부팅 때 guest agent와 git을 설치하고, 저장소를 클론해 VM의 `setup.sh`(OpenClaw 설치)를 실행함 (몇 분 걸림)
  - 진행 확인: 호스트에서 `qm terminal 100` (나가기: Ctrl+O), VM에서 `cloud-init status --wait`
  - 이를 위해 `local` 저장소에 snippets 용도를 추가하고 `/var/lib/vz/snippets/`에 첫 부팅 작업 파일을 만듦
- 호스트가 Wi-Fi뿐이면 VM이 인터넷에 나가도록 호스트에 Wi-Fi와 NAT를 먼저 설정하고, `.env`에 `VM_IP=10.10.10.2/24`, `VM_GATEWAY=10.10.10.1`, `VM_DNS`를 넣음


### OpenClaw (VM)

- Setup: [scripts/vm/setup_openclaw.sh](scripts/vm/setup_openclaw.sh) (VM 안에서 실행, Proxmox 호스트에서는 실행되지 않음)
  - 다시 실행 시: 사용자에게 `openclaw` 명령이 있고 systemd linger가 켜져 있으면 건너뜀
- [공식 설치 스크립트](https://docs.openclaw.ai/install)를 온보딩 없이(`--no-onboard`) 사용자 권한으로 실행함
  - 공식 스크립트가 쓰는 git, 빌드 도구, Node.js 24(NodeSource)는 먼저 설치함
  - 로그인하지 않아도 Gateway가 부팅 시 실행되도록 `loginctl enable-linger`를 켬
- 설치 후 사용자 계정에서 직접 온보딩 (모델 제공자, API 키 입력, Gateway 서비스 등록):

```bash
openclaw onboard --install-daemon
```

- Gateway는 기본값(loopback)으로 VM 안에서만 접속됨. 다른 기기에서 접속하려면 SSH 터널이나 Tailscale Serve를 쓰고, `lan`·`tailnet`으로 열 때는 인증(token 또는 password)을 반드시 설정 ([Linux server 문서](https://docs.openclaw.ai/vps))
- 업데이트: `npm i -g openclaw@latest` (sudo 없이)
