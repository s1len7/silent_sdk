# silent_sdk

장비별 기본 설정 자동화

| 장비 | 대상 | 문서 |
|---|---|---|
| desktop | Windows 10 이상 데스크탑 | [devices/desktop/README.md](devices/desktop/README.md) |
| generic-windows | Windows 10 이상 (빌려쓰는 PC용, 최소 설치) | [devices/generic-windows/README.md](devices/generic-windows/README.md) |
| generic-ubuntu | Ubuntu/Debian 계열 (빌려쓰는 PC용, 최소 설치) | [devices/generic-ubuntu/README.md](devices/generic-ubuntu/README.md) |
| raspberrypi4-8gb | Raspberry Pi 4 (RAM 8GB), Raspberry Pi OS 64-bit (Trixie) | [devices/raspberrypi4-8gb/README.md](devices/raspberrypi4-8gb/README.md) |
| raspberrypi4-2gb | Raspberry Pi 4 (RAM 2GB), Raspberry Pi OS **Lite** 64-bit (Trixie) | [devices/raspberrypi4-2gb/README.md](devices/raspberrypi4-2gb/README.md) |
| titan-s260 | SAM4S TITAN-S260 POS, Windows 10 IoT LTSC 2021 | [devices/titan-s260/README.md](devices/titan-s260/README.md) |
| byt-t1 | PEGATRON BYT-T1 Mini-ITX 보드 (Intel Pentium J2900), Ubuntu Server 24.04 LTS | [devices/byt-t1/README.md](devices/byt-t1/README.md) |
| jetson-nano-b01 | NVIDIA Jetson Nano Developer Kit B01, JetPack 4.6.6 (Ubuntu 18.04) | [devices/jetson-nano-b01/README.md](devices/jetson-nano-b01/README.md) |
| b150m-am2 | ASUS B150M-A/M.2 Micro-ATX 보드 (Intel B150), Proxmox VE 9 + Ubuntu Server 24.04 LTS VM, OpenClaw 서버 | [devices/b150m-am2/README.md](devices/b150m-am2/README.md) |
| thinkpad-s2-2g | Lenovo ThinkPad S2 2G(2nd Gen) 노트북, Windows 10 Pro | [devices/thinkpad-s2-2g/README.md](devices/thinkpad-s2-2g/README.md) |
| gmk87 | ZUOYA GMK87 기계식 키보드 (USB-C / 2.4 GHz / Bluetooth, VIA 키 매핑) | [devices/gmk87/README.md](devices/gmk87/README.md) |
| ds218plus | Synology DS218+ NAS, DSM 7, Container Manager(Docker) 프로젝트 관리 | [devices/ds218plus/README.md](devices/ds218plus/README.md) |


## 구조

```text
silent_sdk/
├─ devices/          장비별 폴더 (각 폴더에 README.md, AGENTS.md(규칙), CLAUDE.md, GEMINI.md, 설치 스크립트)
│  ├─ desktop/       Windows 데스크탑, Windows 공통 스크립트 (titan-s260·thinkpad-s2-2g도 사용)
│  ├─ generic-windows/  빌려쓰는 Windows PC용 최소 설치, Windows 공통 스크립트(git·vscode·winget·opencode) 보관
│  ├─ generic-ubuntu/   빌려쓰는 Ubuntu/Debian PC용 최소 설치
│  ├─ titan-s260/
│  ├─ raspberrypi4-8gb/
│  ├─ raspberrypi4-2gb/
│  ├─ byt-t1/
│  ├─ jetson-nano-b01/
│  ├─ b150m-am2/
│  ├─ thinkpad-s2-2g/
│  ├─ gmk87/         ZUOYA GMK87 키보드 (VIA 키 매핑, 설정 백업, 전체 설치 없음)
│  └─ ds218plus/     Synology NAS, Container Manager 프로젝트 (전체 설치 없음)
├─ logs/             설치 로그 (git에는 올라가지 않음)
├─ AGENTS.md         작성 원칙 (장비 공통)
├─ CLAUDE.md         AGENTS.md를 불러옴 (`@./AGENTS.md`)
└─ GEMINI.md         AGENTS.md를 불러옴 (`@./AGENTS.md`)
```


## 전체 설치

desktop (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/desktop/setup.ps1 | iex
```

generic-windows (PowerShell, borrowed PC):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-windows/setup.ps1 | iex
```

generic-ubuntu (bash, borrowed PC):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-ubuntu/setup.sh | bash
```

TITAN-S260 (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/titan-s260/setup.ps1 | iex
```

ThinkPad S2 2G(2nd Gen) (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/thinkpad-s2-2g/setup.ps1 | iex
```

Raspberry Pi 4 (8GB):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/raspberrypi4-8gb/setup.sh | sudo bash
```

Raspberry Pi 4 (2GB):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/raspberrypi4-2gb/setup.sh | sudo bash
```

Jetson Nano B01:
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/jetson-nano-b01/setup.sh | sudo bash
```

ASUS B150M-A/M.2 (Proxmox 호스트 셸, root):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/setup_host.sh | bash
```

ASUS B150M-A/M.2의 Ubuntu VM (VM 안에서, sudo):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/vm/ubuntu-server/setup_vm.sh | sudo bash
```


## 개발

- 작성 원칙: [AGENTS.md](AGENTS.md) 참고 (장비 전용 규칙은 각 `devices/<장비>/AGENTS.md`, CLAUDE.md·GEMINI.md는 AGENTS.md를 불러오기만 함)
