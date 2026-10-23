# silent_sdk

장비별 기본 설정 자동화

| 장비 | 대상 | 문서 |
|---|---|---|
| desktop | Windows 10 이상 데스크탑 | [devices/desktop/README.md](devices/desktop/README.md) |
| raspberrypi4-8gb | Raspberry Pi 4 (RAM 8GB), Raspberry Pi OS 64-bit (Trixie) | [devices/raspberrypi4-8gb/README.md](devices/raspberrypi4-8gb/README.md) |
| raspberrypi4-2gb | Raspberry Pi 4 (RAM 2GB), Raspberry Pi OS **Lite** 64-bit (Trixie) | [devices/raspberrypi4-2gb/README.md](devices/raspberrypi4-2gb/README.md) |
| titan-s260 | SAM4S TITAN-S260 POS, Windows 10 IoT LTSC 2021 | [devices/titan-s260/README.md](devices/titan-s260/README.md) |
| byt-t1 | PEGATRON BYT-T1 Mini-ITX 보드 (Intel Pentium J2900), Ubuntu Server 24.04 LTS | [devices/byt-t1/README.md](devices/byt-t1/README.md) |
| jetson-nano-b01 | NVIDIA Jetson Nano Developer Kit B01, JetPack 4.6.6 (Ubuntu 18.04) | [devices/jetson-nano-b01/README.md](devices/jetson-nano-b01/README.md) |
| b150m-am2 | ASUS B150M-A/M.2 Micro-ATX 보드 (Intel B150), Proxmox VE 9 + Ubuntu Server 24.04 LTS VM, OpenClaw 서버 | [devices/b150m-am2/README.md](devices/b150m-am2/README.md) |


## 구조

```text
silent_sdk/
├─ devices/          장비별 폴더 (각 폴더에 README.md, CLAUDE.md, 설치 스크립트)
│  ├─ desktop/       Windows 데스크탑, Windows 공통 스크립트 (titan-s260도 사용)
│  ├─ titan-s260/
│  ├─ raspberrypi4-8gb/
│  ├─ raspberrypi4-2gb/
│  ├─ byt-t1/
│  ├─ jetson-nano-b01/
│  └─ b150m-am2/
├─ logs/             설치 로그 (git에는 올라가지 않음)
└─ CLAUDE.md         작성 원칙 (장비 공통)
```


## 전체 설치

desktop (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/desktop/setup.ps1 | iex
```

TITAN-S260 (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/titan-s260/setup.ps1 | iex
```

Raspberry Pi 4 (8GB):
```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/raspberrypi4-8gb/setup.sh
```

Raspberry Pi 4 (2GB):
```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/raspberrypi4-2gb/setup.sh
```

Jetson Nano B01:
```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/jetson-nano-b01/setup.sh
```

ASUS B150M-A/M.2 (Proxmox 호스트 셸, root):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/b150m-am2/setup.sh | bash
```


## 개발

- 작성 원칙: [CLAUDE.md](CLAUDE.md) 참고 (장비 전용 규칙은 각 `devices/<장비>/CLAUDE.md`)
