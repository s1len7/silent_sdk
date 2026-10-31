# silent_sdk

장비별 기본 설정 자동화

| 장비 | 대상 | 문서 |
|---|---|---|
| desktop | Windows 10 이상 데스크탑 | [devices/desktop/README.md](devices/desktop/README.md) |
| generic-windows | Windows 10 이상 (빌려쓰는 PC용, 최소 설치) | [devices/generic-windows/README.md](devices/generic-windows/README.md) |
| generic-ubuntu | Ubuntu/Debian 계열 (빌려쓰는 PC용, 최소 설치) | [devices/generic-ubuntu/README.md](devices/generic-ubuntu/README.md) |
| pi4-display | Raspberry Pi 4 (RAM 8GB), Raspberry Pi OS Desktop 64-bit (Trixie) | [devices/pi4-display/README.md](devices/pi4-display/README.md) |
| pi4-2gb | Raspberry Pi 4 (RAM 2GB), Raspberry Pi OS **Lite** 64-bit (Trixie) | [devices/pi4-2gb/README.md](devices/pi4-2gb/README.md) |
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
│  ├─ pi4-display/
│  ├─ pi4-2gb/
│  ├─ byt-t1/
│  ├─ jetson-nano-b01/
│  ├─ b150m-am2/
│  ├─ thinkpad-s2-2g/
│  ├─ gmk87/         ZUOYA GMK87 키보드 (VIA 키 매핑, 설정 백업, 전체 설치 없음)
│  └─ ds218plus/     Synology NAS, Container Manager 프로젝트 (전체 설치 없음)
├─ .vscode/          VS Code 워크스페이스 설정 (이 저장소를 열 때만 적용)
├─ .agents/skills/   AI 에이전트 공통 스킬 (git에 올리지 않음, OpenCode·Codex·Gemini CLI가 읽음, Claude Code는 `.claude/skills` 링크로 읽음, OpenClaw에는 desktop setup이 복사)
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

pi4-display (Raspberry Pi 4, 8GB):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/pi4-display/setup.sh | sudo bash
```

pi4-2gb (Raspberry Pi 4, 2GB):
```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/pi4-2gb/setup.sh | sudo bash
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


## git에 올리지 않는 관리 파일

개인정보·비밀값이 있거나 이 PC에만 두는 파일. 저장소에 없으므로 직접 백업할 것 (비밀값이 든 파일은 암호화된 위치에만)

| 파일 | 위치 | 내용 | 관리 |
| --- | --- | --- | --- |
| `.env` | `.env.example`이 있는 장비·프로젝트 폴더 | API 키, token, 비밀번호 | `.env.example`을 복사해 값을 채움 |
| `~/.ssh/` | 각 PC 사용자 폴더 | 접속 키, 장비별 접속 설정(`config`), `known_hosts` | 직접 백업 (개인 키 포함) |
| `~/.bashrc` | Linux 장비 사용자 폴더 | 셸 환경 | Jetson Nano의 CUDA 경로 줄은 setup이 다시 넣음, 그 밖의 수정은 직접 백업 |
| `.agents/skills/` | 저장소 (desktop) | AI 에이전트 공통 스킬 원본 | 직접 백업 (`.claude/skills`는 이 폴더를 가리키는 링크) |
| `.claude/` | 저장소 | Claude Code 로컬 설정 (`settings.local.json`) | 직접 백업 |
| `~/.openclaw/` | desktop 사용자 폴더 | OpenClaw 설정·대화 기록, 텔레그램 봇 token 파일 | 모델 설정은 setup이 다시 넣음, 텔레그램 연결·token·기록은 직접 백업 |
| VS Code 사용자 설정 | `%APPDATA%\Code\User\settings.json` | 개인 편집기 설정 | setup은 `telemetry.telemetryLevel`만 넣음, 그 밖의 설정은 직접 백업 또는 VS Code 설정 동기화 |

- 장비별 상세 목록: [desktop 백업 대상](devices/desktop/README.md#백업-대상)


## 개발

- 작성 원칙: [AGENTS.md](AGENTS.md) 참고 (장비 전용 규칙은 각 `devices/<장비>/AGENTS.md`, CLAUDE.md·GEMINI.md는 AGENTS.md를 불러오기만 함)
- VS Code 워크스페이스 설정: [.vscode/settings.json](.vscode/settings.json) (이 저장소를 열 때만 적용되고 사용자 설정보다 우선)
  - 저장할 때 줄 끝 공백 제거, 파일 끝 빈 줄을 하나로 맞춤
  - 검색에서 `logs/`, `tmp/` 제외 (탐색기에는 보임)
  - 줄바꿈은 `.gitattributes`, 들여쓰기는 VS Code 기본값(공백 4칸)을 따름
  - 프로그램 전체에 걸리는 설정(예: `telemetry.telemetryLevel`)은 워크스페이스 설정에서 무시되므로 사용자 설정에 둘 것

| 기능 | 단축키 |
| --- | --- |
| 설정 화면 (사용자·워크스페이스 탭) | `Ctrl+,` |
| 워크스페이스 설정 JSON | 명령 팔레트(`Ctrl+Shift+P`) → `Preferences: Open Workspace Settings (JSON)` |
| 사용자 설정 JSON | 명령 팔레트 → `Preferences: Open User Settings (JSON)` |
| VS Code 기본값 보기 (읽기 전용) | 명령 팔레트 → `Preferences: Open Default Settings (JSON)` |
