# Lenovo ThinkPad S2 2G(2nd Gen)

- 제조사: [레노버(Lenovo)](https://www.lenovo.com/)
- 모델명: ThinkPad S2 2G(2nd Gen) (ThinkPad 13 2nd Gen과 같은 플랫폼, MT 20J1/20J2/20J3)
  - [사양(PSREF, ThinkPad 13 2nd Gen)](https://psref.lenovo.com/syspool/Sys/PDF/ThinkPad/ThinkPad_13_2nd_Gen/ThinkPad_13_2nd_Gen_Spec.PDF)
- 지원OS: Windows 10 Pro (64-bit)

| 항목 | 사양 |
| --- | --- |
| CPU | Intel Core i5-7200U (2코어 4스레드, 2.5GHz / 최대 3.1GHz) |
| RAM | 16GB DDR4-2133 (SO-DIMM 2슬롯, 최대 32GB) |
| 저장장치 | M.2 SSD 256GB |
| 디스플레이 | 13.3" HD (1366x768) 또는 FHD (1920x1080) IPS, FHD는 터치 옵션 |
| 그래픽 | Intel HD Graphics 620 (CPU 내장) |
| 포트 | USB 3.1 Gen 1 x3, USB Type-C x1, HDMI, OneLink+, 4-in-1 카드 리더, 오디오 콤보 잭 |
| 무선 | Intel Wireless-AC 8265 (Wi-Fi 802.11ac 2x2, Bluetooth 4.1) |
| 보안 | TPM 2.0 (dTPM), 지문 인식 옵션 |
| 배터리 | 내장 3셀 42Wh, 45W 어댑터 |
| 무게 | 1.44kg부터 |


## 기능

- 전체 Setup: PowerShell에서 이 한 줄만 실행 ([setup.ps1](setup.ps1)):

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/thinkpad-s2-2g/setup.ps1 | iex
```

- 저장소: 실행할 때마다 `~\silent_sdk`에 최신 버전을 받음 (Git이 없으면 먼저 설치, git clone이면 `git pull`, 아니면 새로 clone해서 폴더를 교체하고 `logs`와 `.env`는 유지)
- 실패한 단계가 있어도 나머지 단계는 계속 진행하고, 끝에 단계별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 단계는 SKIP하고, 실패했거나 안 된 단계만 다시 진행함 (단계별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `~\silent_sdk\logs\thinkpad-s2-2g-<시각>\` (`setup.log` 전체 실행 기록, `*-install.log` 설치 프로그램 로그)
- 공통 스크립트(`desktop/scripts/`, `generic-windows/scripts/`)의 자세한 설명은 [desktop README](../desktop/README.md) 참고


### hostname 설정

- Setup: [desktop/scripts/setup-hostname.ps1](../desktop/scripts/setup-hostname.ps1) (새 hostname을 물어봄, 엔터를 누르면 기본값 `20J3A002CD`, 적용 후 재부팅)
  - 다시 실행 시: 고른 hostname이 지금 hostname과 같거나, 변경 후 재부팅 대기 중이면 건너뜀


### Windows 업데이트

- Setup: [desktop/scripts/setup-windows-update.ps1](../desktop/scripts/setup-windows-update.ps1) (드라이버 포함 모든 업데이트 설치, 자동 재부팅 안 함)
  - 다시 실행 시: 설치할 업데이트가 없거나, 이전 업데이트의 재부팅이 대기 중이면 건너뜀


### 원격 데스크톱 켬

- Setup: [desktop/scripts/setup-rdp.ps1](../desktop/scripts/setup-rdp.ps1) (원격 데스크톱 켬, NLA 사용, 방화벽 3389 허용)
  - 다시 실행 시: 원격 데스크톱 허용, NLA, 방화벽 규칙이 모두 켜져 있으면 건너뜀


### 전원 설정

- Setup: [scripts/setup-power.ps1](scripts/setup-power.ps1) (전원 연결 시 덮개를 닫아도 아무 동작 안 함, 절전·최대 절전 안 함, 현재 전원 계획)
  - 배터리 사용 시 설정은 Windows 기본값 유지
  - 다시 실행 시: 전원 연결 시 덮개 동작, 절전, 최대 절전 값이 모두 적용돼 있으면 건너뜀


### Google Chrome

- Setup: [desktop/scripts/setup-chrome.ps1](../desktop/scripts/setup-chrome.ps1) (엔터프라이즈 64-bit MSI 최신 버전, 무인 설치)
  - 다시 실행 시: Chrome이 설치돼 있으면 건너뜀 (업데이트는 Chrome이 직접 함)


### PowerToys

- Setup: [desktop/scripts/setup-powertoys.ps1](../desktop/scripts/setup-powertoys.ps1) (최신 버전, 환영·새 기능 창 억제, ZoomIt 활성화)
  - 다시 실행 시: 설치돼 있고 창 억제·ZoomIt 설정이 돼 있으면 건너뜀. 설치만 돼 있으면 설정만 적용


### WinGet

- Setup: [generic-windows/scripts/setup-winget.ps1](../generic-windows/scripts/setup-winget.ps1) (winget이 없거나 실행되지 않을 때 설치)
  - 다시 실행 시: `winget --version`이 실행되면 건너뜀


### Lenovo System Update

- Setup: [scripts/setup-lenovo-update.ps1](scripts/setup-lenovo-update.ps1) (winget으로 설치, 드라이버·BIOS·펌웨어 업데이트는 시작 메뉴의 System Update에서 실행)
  - 다시 실행 시: winget 목록에 Lenovo System Update가 있으면 건너뜀


### Sysinternals Suite

- Setup: [desktop/scripts/setup-sysinternals.ps1](../desktop/scripts/setup-sysinternals.ps1) (Program Files 설치, PATH 추가, EULA 자동 동의)
  - 다시 실행 시: 설치 폴더, PATH, EULA 동의가 모두 돼 있으면 건너뜀


### 자동 로그인

- Setup: [desktop/scripts/setup-autologon.ps1](../desktop/scripts/setup-autologon.ps1) (현재 로그인한 로컬 계정, Sysinternals Autologon 사용, 실행 중 계정 비밀번호를 물음)
  - 다시 실행 시: 자동 로그인이 현재 계정으로 켜져 있으면 건너뜀


### Git

- Setup: [generic-windows/scripts/setup-git.ps1](../generic-windows/scripts/setup-git.ps1) (Git for Windows 최신 64-bit, 기본 옵션 무인 설치)
  - 다시 실행 시: Git이 설치돼 있고 user.name/user.email이 같으면 건너뜀. 설치만 돼 있으면 사용자 정보만 설정


### Python

- Setup: [desktop/scripts/setup-python.ps1](../desktop/scripts/setup-python.ps1) (3.12 현재 사용자용, PATH 추가 안 함, `py -3.12`로 실행, 데이터 분석 패키지 설치)
  - 다시 실행 시: Python 3.12와 모든 패키지가 설치돼 있으면 건너뜀. 패키지만 빠져 있으면 패키지만 설치


### Visual Studio Code

- Setup: [generic-windows/scripts/setup-vscode.ps1](../generic-windows/scripts/setup-vscode.ps1) (System Installer x64 최신 버전, PATH 추가, 탐색기 "Code로 열기" 메뉴)
  - 다시 실행 시: VS Code가 설치돼 있으면(PC 전체 또는 사용자 단위) 건너뜀
- Setup: [generic-windows/scripts/setup-vscode-extensions.ps1](../generic-windows/scripts/setup-vscode-extensions.ps1) (현재 사용자에 확장 설치: Python, Remote - SSH, Remote Explorer, 모두 Microsoft 인증 게시자)
  - 다시 실행 시: 세 확장이 모두 설치돼 있으면 건너뜀. 빠진 확장만 설치


### OpenCode

- Setup: [generic-windows/scripts/setup-opencode.ps1](../generic-windows/scripts/setup-opencode.ps1) (Node.js(winget) 최신, OpenCode CLI(npm) 최신, 무료 기본 모델 `opencode/deepseek-v4.1-flash-free`와 대체 모델 설정)
  - 다시 실행 시: `opencode` 명령이 있고 기본 모델·플러그인·대체 모델 설정이 모두 같고, `.env`에 키가 있으면 Gemini 키도 등록돼 있을 때 건너뜀. CLI만 설치돼 있으면 설정만 적용
- 설정: `devices/desktop/.env`의 `GEMINI_API_KEY` (비우면 Gemini 연결 없이 설치만 함)


### OpenClaw Companion (원격 Gateway 연결)

- Setup: [desktop/scripts/setup-openclaw-remote.ps1](../desktop/scripts/setup-openclaw-remote.ps1) (이 노트북에는 Gateway를 설치하지 않고, 트레이 앱을 b150m-am2 VM의 Gateway에 연결)
  - 다시 실행 시: 트레이 앱이 원격 Gateway에 연결·페어링돼 있으면 건너뜀
- 설정: `devices/desktop/.env`의 `OPENCLAW_GATEWAY_URL`(외부에서도 쓰면 리버스 프록시의 `wss://` 주소, 랜에서만 쓰면 `ws://192.168.0.22:18789`), `OPENCLAW_GATEWAY_TOKEN`, `OPENCLAW_GATEWAY_SSH`(`silent@192.168.0.22`) (하나라도 비우면 건너뜀)
- 페어링 승인을 VM에서 ssh로 하므로, Setup은 VM에 ssh 키로 접속되는 랜에서 실행해야 함
