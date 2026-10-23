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

- 순서: Proxmox VE 9 설치 → 호스트 Setup → Ubuntu Server 24.04 LTS VM 생성 (수동, Proxmox 웹 화면 `https://<호스트 IP>:8006`) → VM Setup
- [setup.sh](setup.sh)는 실행 위치를 판별해 Proxmox 호스트면 `scripts/host/`, VM이면 `scripts/vm/`의 모듈을 모두 실행
- 호스트 Setup: Proxmox 셸(root)에서 이 한 줄만 실행 (저장소를 압축 파일로 받아 전체 설치):

```bash
mkdir -p ~/silent_sdk && curl -fsSL https://github.com/s1len7/silent_sdk/archive/refs/heads/main.tar.gz | tar xz --strip-components=1 -C ~/silent_sdk && bash ~/silent_sdk/devices/b150m-am2/setup.sh
```

- VM Setup: **VM 안에서** OpenClaw를 쓸 사용자 계정으로 이 한 줄만 실행 (git이 없으면 설치 → 저장소 클론 → 전체 설치):

```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/b150m-am2/setup.sh
```

- 이미 받아져 있으면: 호스트는 `bash ~/silent_sdk/devices/b150m-am2/setup.sh`, VM은 `sudo bash ~/silent_sdk/devices/b150m-am2/setup.sh`
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
