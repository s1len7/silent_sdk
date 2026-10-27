# ASUS B150M-A/M.2

- 제조사: [ASUS](https://www.asus.com/)
- 모델명: [B150M-A/M.2](https://www.asus.com/supportonly/b150m-am.2/helpdesk/) (Micro-ATX 메인보드, Intel B150)
- 지원OS: [Proxmox VE](https://www.proxmox.com/en/products/proxmox-virtual-environment/overview) 9 (호스트, Debian 13 기반) + Ubuntu Server 24.04 LTS VM (OpenClaw 실행)
- 용도: [OpenClaw](https://docs.openclaw.ai/install) 서버
- 작성 원칙: [AGENTS.md](AGENTS.md) 참고 (공통 규칙은 [상위 AGENTS.md](../../AGENTS.md))

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

- 순서: Proxmox VE 9 설치 → 호스트 Setup (저장소 설정, Wi-Fi 연결(선택), Ubuntu Server 24.04 LTS VM 생성, 첫 부팅 때 VM Setup 자동 실행: OpenClaw 설치·온보딩) → VM에 OpenRouter API 키 등록
- 전체 셋업 스크립트: 호스트는 [setup_host.sh](setup_host.sh) (`scripts/host/` 모듈), VM은 [vm/ubuntu-server/setup_vm.sh](vm/ubuntu-server/setup_vm.sh) (`vm/ubuntu-server/scripts/` 모듈)
- VM 사양·접속 방법: [vm/ubuntu-server/README.md](vm/ubuntu-server/README.md)
- 호스트 Setup: Proxmox 셸(root)에서 이 한 줄만 실행 (git 설치 → 저장소를 `~/silent_sdk`에 clone → 전체 설치):

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/setup_host.sh | bash
```

  - 다시 실행하면 `~/silent_sdk`를 `git pull`로 최신으로 받음. git clone이 아니면(예전에 압축 파일로 받은 폴더) 새로 clone해서 교체하고, `.env`와 `logs/`는 옮겨 와서 유지됨

- VM Setup: 호스트 Setup이 만든 VM은 첫 부팅 때 자동으로 실행됨. 직접 만든 VM이면 **VM 안에서** OpenClaw를 쓸 사용자 계정으로 이 한 줄만 실행. 파일 없이 실행하면 git을 설치하고 저장소를 받은 뒤(이미 받았으면 `git pull`) 그 안의 `setup_vm.sh`로 전체 설치:

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/vm/ubuntu-server/setup_vm.sh | sudo bash
```

- 저장소를 새로 받지 않고 실행: 호스트는 `bash ~/silent_sdk/devices/b150m-am2/setup_host.sh`, VM은 `sudo bash ~/silent_sdk/devices/b150m-am2/vm/ubuntu-server/setup_vm.sh`
- 개별 기능만 설치: 이 폴더(`~/silent_sdk/devices/b150m-am2`)에서 `bash scripts/host/setup_<기능>.sh` (호스트) 또는 `sudo bash vm/ubuntu-server/scripts/setup_<기능>.sh` (VM)
- 실패한 모듈이 있어도 나머지 모듈은 계속 진행하고, 끝에 모듈별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함 (모듈별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `~/silent_sdk/logs/b150m-am2-host-<시각>/setup.log` (호스트), `~/silent_sdk/logs/b150m-am2-ubuntu-server-<시각>/setup.log` (VM)


### Proxmox 저장소 (호스트)

- Setup: [scripts/host/setup_pve_repo.sh](scripts/host/setup_pve_repo.sh) (적용 후 새 커널이 설치됐으면 재부팅)
  - 다시 실행 시: enterprise 저장소가 모두 꺼져 있고 no-subscription 저장소가 있으면 건너뜀 (웹 UI로 바꾼 경우도 포함)
- 구독 키가 없으면 기본으로 켜진 enterprise 저장소 때문에 `apt-get update`가 `exit code 100`으로 실패함
- [공식 문서](https://pve.proxmox.com/wiki/Package_Repositories)대로 `pve-enterprise.sources`(와 enterprise인 `ceph.sources`)에 `Enabled: no`를 넣고, `proxmox.sources`에 no-subscription 저장소를 추가한 뒤 `apt-get full-upgrade`로 최신 패치를 적용함
- 웹 UI에서 하려면: 노드 → 업데이트 → 리포지토리에서 enterprise 항목을 비활성화하고, 추가 → No-Subscription


### Wi-Fi (호스트)

- Setup: [scripts/host/setup_wifi.sh](scripts/host/setup_wifi.sh) (유선은 그대로 두고 Wi-Fi도 연결, 내장 Intel Wireless-AC 3168 확인)
  - 다시 실행 시: `WIFI_SSID`가 비어 있거나, 설정 파일 내용이 같고 `wpa_supplicant@<인터페이스>`·`systemd-networkd`·`wifi-failover-nft`가 실행 중이면 건너뜀
- 설정: `.env`의 `WIFI_SSID`, `WIFI_PASSWORD` (선택: `WIFI_COUNTRY`, `WIFI_INTERFACE`, [.env.example](.env.example) 참고)
- `wpasupplicant`, `iw`, `wireless-regdb`, `nftables`를 설치하고 Wi-Fi 인터페이스(기본: 첫 번째 무선 인터페이스)를 공유기 DHCP로 연결함
  - 비밀번호는 해시(psk)로 `/etc/wpa_supplicant/wpa_supplicant-<인터페이스>.conf`(root만 읽기)에 저장
  - DHCP는 `systemd-networkd`가 Wi-Fi 인터페이스만 맡고, 경로는 테이블 100에 넣어 유선 경로와 겹치지 않게 함 (`/etc/systemd/network/50-wifi-<인터페이스>.network`)
- Wi-Fi는 Linux 브리지에 넣을 수 없어 VM은 계속 유선(`vmbr0`)으로 연결됨. 호스트는 유선 IP와 Wi-Fi IP 양쪽으로 접속 가능
- 유선이 끊겨도 Wi-Fi IP로 호스트에 접속됨: Wi-Fi로 들어온 연결에 nftables 표시를 붙여 그 응답을 테이블 100(Wi-Fi)으로 보냄
  - `wifi-failover-nft` 서비스(`/etc/nftables.d/50-wifi-failover.nft`)와 `ip rule`의 `fwmark 0x64 lookup 100`으로 확인
  - ARP가 엉키지 않게 `/etc/sysctl.d/50-wifi-arp.conf`(`arp_ignore=1`, `arp_announce=2`)를 둠
  - Wi-Fi 절전 모드를 끔: `wpa_supplicant@<인터페이스>`가 시작될 때마다 `iw dev <인터페이스> set power_save off` 실행 (`/etc/systemd/system/wpa_supplicant@<인터페이스>.service.d/50-power-save-off.conf`, 확인: `iw dev wlp3s0 get power_save`)
  - 유선이 끊겼을 때 살아나는 것은 Wi-Fi IP로 들어오는 접속(SSH, 웹 UI)뿐이고, 호스트가 밖으로 나가는 연결(apt 등)과 VM 네트워크는 끊김
- 상태 확인: `ip -br addr show`, `ip rule`, `ip route show table 100`, `journalctl -u wpa_supplicant@wlp3s0`


### Ubuntu VM 생성 (호스트)

- Setup: [scripts/host/setup_vm_ubuntu_server.sh](scripts/host/setup_vm_ubuntu_server.sh) ([공식 Cloud-Init 방식](https://pve.proxmox.com/wiki/Cloud-Init_Support))
  - 다시 실행 시: 같은 번호(`VM_ID`)의 VM이 있으면 건너뜀 (기존 VM은 건드리지 않음)
- Ubuntu 24.04 공식 cloud 이미지를 받아 체크섬을 확인한 뒤 VM을 만들고 시작함 (Proxmox 부팅 시 자동 시작)
- 설정: `.env` ([.env.example](.env.example) 참고, git에 올라가지 않음). 비워 두면 아래 기본값

| 항목 | 기본값 | `.env` |
|---|---|---|
| VM 번호, 이름 | 100, ubuntu-server | `VM_ID`, `VM_NAME` |
| 사양 | 2코어, 2048MB, 32GB | `VM_CORES`, `VM_MEMORY_MB`, `VM_DISK_GB` |
| 저장소, 브리지 | local-lvm, vmbr0 | `VM_STORAGE`, `VM_BRIDGE` |
| 계정 | silent (비밀번호 없이 sudo) | `VM_USER` |
| 콘솔 비밀번호 | 없음 | `VM_PASSWORD` |
| SSH 키 | 호스트의 `/root/.ssh/authorized_keys` | `VM_SSH_KEYS_FILE` |
| OpenClaw 자동 설치 | yes | `VM_AUTO_OPENCLAW` |

- SSH는 키로만 접속함 (`VM_PASSWORD`는 웹 화면 콘솔·`qm terminal` 로그인용). 기본값이면 Proxmox 호스트 셸에서 `ssh silent@<VM IP>`로 접속
  - IP는 공유기 DHCP로 받음. 첫 부팅 후 웹 화면의 VM → 요약(guest agent가 알려 줌)에서 확인
- 첫 부팅 때 guest agent와 git을 설치하고, 저장소를 클론해 VM의 `vm/ubuntu-server/setup_vm.sh`(OpenClaw 설치·온보딩)를 실행함 (몇 분 걸림)
  - 진행 확인: 호스트에서 `qm terminal 100` (나가기: Ctrl+O), VM에서 `cloud-init status --wait`
  - 이를 위해 `local` 저장소에 snippets 용도를 추가하고 `/var/lib/vz/snippets/`에 첫 부팅 작업 파일을 만듦

### OpenClaw (VM)

- Setup: [vm/ubuntu-server/scripts/setup_openclaw.sh](vm/ubuntu-server/scripts/setup_openclaw.sh) (VM 안에서 실행, Proxmox 호스트에서는 실행되지 않음)
  - 다시 실행 시: 사용자에게 `openclaw` 명령이 있고 systemd linger가 켜져 있으면 건너뜀
- [공식 설치 스크립트](https://docs.openclaw.ai/install)를 온보딩 없이(`--no-onboard`) 사용자 권한으로 실행함
  - 공식 스크립트가 쓰는 git, 빌드 도구, Node.js 24(NodeSource)는 먼저 설치함
  - 로그인하지 않아도 Gateway가 부팅 시 실행되도록 `loginctl enable-linger`를 켬
- 온보딩은 아래 OpenClaw 온보딩 모듈이 이어서 자동으로 진행함
- 업데이트: `npm i -g openclaw@latest` (sudo 없이)


### OpenClaw 온보딩 (VM)

- Setup: [vm/ubuntu-server/scripts/setup_openclaw_onboard.sh](vm/ubuntu-server/scripts/setup_openclaw_onboard.sh) (공식 `openclaw onboard`를 비대화형으로 실행)
  - 다시 실행 시: Gateway 서비스 파일이 있고, 랜 공개(`gateway.bind=lan`)이고, 기본 모델이 OpenRouter 무료 라우터이고, `.env`에 값이 있으면 OpenRouter·Gemini 키·리버스 프록시 설정도 돼 있을 때 건너뜀. 빠진 것만 설정함
- Gateway를 사용자 systemd 서비스(`openclaw-gateway`)로 등록함 (랜 공개, token 인증, 포트 18789)
  - 예전에 VM 안에서만 열리게(loopback) 설치한 VM도 다시 실행하면 랜 공개로 바뀜
- 기본 모델은 무료인 OpenRouter 무료 라우터 (`openrouter/openrouter/free`)
- OpenRouter API 키: [openrouter.ai/keys](https://openrouter.ai/keys)에서 무료로 발급해 `vm/ubuntu-server/.env`에 넣고 다시 실행 ([vm/ubuntu-server/.env.example](vm/ubuntu-server/.env.example) 참고, git에 올라가지 않음)

```bash
cd ~/silent_sdk/devices/b150m-am2/vm/ubuntu-server && cp .env.example .env && nano .env
sudo bash scripts/setup_openclaw_onboard.sh
```

- 텔레그램은 아래 OpenClaw 텔레그램 모듈이 설정함. 다른 채널·스킬은 필요하면 VM에서 `openclaw configure`로 추가
- 리버스 프록시(예: NAS의 Nginx Proxy Manager)로 `wss://` 주소를 쓸 때는 `.env`에 `OPENCLAW_TRUSTED_PROXY`(프록시 IP)와 `OPENCLAW_PUBLIC_ORIGIN`(외부 https 주소)을 넣고 다시 실행 ([Trusted proxy 문서](https://docs.openclaw.ai/gateway/trusted-proxy-auth))
  - 프록시는 `X-Forwarded-For`를 덧붙이지 말고 덮어써야 함. Nginx Proxy Manager는 해당 호스트의 Custom Locations에 경로 `/`를 추가하면 덮어씀
- Gateway 토큰 확인 (VM에서, `openclaw config get`은 값을 가려서 보여 주므로 설정 파일에서 읽음):

```bash
python3 -c "import json,os;print(json.load(open(os.path.expanduser('~/.openclaw/openclaw.json')))['gateway']['auth']['token'])"
```


### OpenClaw 텔레그램 (VM)

- Setup: [vm/ubuntu-server/scripts/setup_openclaw_telegram.sh](vm/ubuntu-server/scripts/setup_openclaw_telegram.sh) (텔레그램 봇으로 OpenClaw와 대화)
  - 다시 실행 시: `.env`에 봇 토큰·허용 ID가 없거나, 토큰 파일 내용이 같고 채널 설정(토큰 파일, 허용 ID, `dmPolicy=allowlist`, 그룹 꺼짐, 켜짐)이 같으면 건너뜀
- 설정: `vm/ubuntu-server/.env`의 `TELEGRAM_BOT_TOKEN`(@BotFather에서 받은 토큰), `TELEGRAM_ALLOW_FROM`(텔레그램 숫자 ID, @userinfobot에게 메시지를 보내면 알려 줌)
- 허용 ID 한 명만 봇에게 말을 걸 수 있고 그룹 대화는 꺼짐 ([공식 문서](https://docs.openclaw.ai/channels/telegram/access-control))
- 토큰은 `~/.openclaw/telegram-bot-token`(권한 600)에 두고 설정에는 파일 경로만 넣음
- 봇 하나는 한 곳에서만 메시지를 받을 수 있으므로, 같은 봇을 다른 OpenClaw에서 동시에 쓰지 않음
