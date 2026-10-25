# desktop

- 기본 데스크탑 설정 자동화
- 지원OS: Windows 10 혹은 그 이상

## 기능

- 전체 Setup: PowerShell에서 이 한 줄만 실행 ([setup.ps1](setup.ps1)):

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/desktop/setup.ps1 | iex
```

- 저장소: 실행할 때마다 `C:\silent_sdk`에 최신 버전을 받음 (Git이 없으면 먼저 설치, git clone이면 `git pull`, 아니면 새로 clone해서 폴더를 교체하고 `logs`와 `.env`는 유지)
- 실패한 단계가 있어도 나머지 단계는 계속 진행하고, 끝에 단계별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 단계는 SKIP하고, 실패했거나 안 된 단계만 다시 진행함 (단계별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `C:\silent_sdk\logs\desktop-<시각>\` (`setup.log` 전체 실행 기록, `*-install.log` 설치 프로그램 로그)



### hostname 설정

- Setup: [scripts/setup-hostname.ps1](scripts/setup-hostname.ps1) (새 hostname을 물어봄, 엔터를 누르면 기본값 `silent-desktop`, 적용 후 재부팅)
  - 전체 Setup 맨 처음에 물어보므로 이후 단계는 입력 없이 진행됨
  - hostname 규칙: 1~15자 영문·숫자·하이픈, 숫자만은 안 됨, 하이픈으로 시작·끝나면 안 됨
  - 다시 실행 시: 고른 hostname이 지금 hostname과 같거나, 변경 후 재부팅 대기 중이면 건너뜀


### Windows 업데이트

- Setup: [scripts/setup-windows-update.ps1](scripts/setup-windows-update.ps1) (드라이버 포함 모든 업데이트 설치, Windows 내장 업데이트 API 사용)
  - 기능 업데이트(Windows 버전 변경)와 사용자 입력이 필요한 업데이트는 제외
  - 업데이트를 하나씩 받고 설치하며 진행 막대와 `[3/25]` 같은 진행 줄을 보여줌
  - 업데이트 하나가 오래 걸려도 1분마다 `still working ... (경과 시간)` 줄을 남겨 멈추지 않았음을 알 수 있음 (로그에도 기록)
  - 자동으로 재부팅하지 않음. 재부팅이 필요하면 재부팅 후 전체 Setup을 다시 실행해 남은 업데이트 설치
  - 다시 실행 시: 설치할 업데이트가 없거나, 이전 업데이트의 재부팅이 대기 중이면 건너뜀


### 원격 데스크톱 켬

- Setup: [scripts/setup-rdp.ps1](scripts/setup-rdp.ps1) (원격 데스크톱 켬, NLA 사용, 방화벽 3389 허용)
  - 다시 실행 시: 원격 데스크톱 허용, NLA, 방화벽 규칙이 모두 켜져 있으면 건너뜀
  - Windows Home 에디션은 원격 데스크톱 호스트를 지원하지 않아 건너뜀
  - 접속하려면 로그인 계정에 비밀번호가 있어야 함


### 바탕화면 아이콘

- Setup: [scripts/setup-desktop-icons.ps1](scripts/setup-desktop-icons.ps1) (내 PC, 사용자 폴더, 네트워크, 제어판, 휴지통 아이콘 표시, 현재 사용자)
  - 설정 > 개인 설정 > 테마 > 바탕 화면 아이콘 설정과 같은 값
  - 바탕화면에서 F5(새로 고침)하거나 다시 로그인하면 보임
  - 다시 실행 시: 다섯 아이콘이 모두 표시로 설정돼 있으면 건너뜀


### Google Chrome

- Setup: [scripts/setup-chrome.ps1](scripts/setup-chrome.ps1) (엔터프라이즈 64-bit MSI 최신 버전, 무인 설치)
  - 다시 실행 시: Chrome이 설치돼 있으면 건너뜀 (업데이트는 Chrome이 직접 함)


### PowerToys

- Setup: [scripts/setup-powertoys.ps1](scripts/setup-powertoys.ps1) (최신 버전)
  - 다시 실행 시: 설치돼 있고(PC 전체 또는 사용자 단위) 창 억제·ZoomIt 설정이 돼 있으면 건너뜀. 설치만 돼 있으면 설정만 적용
  - 설치 후 환영 창, 새로운 기능(What's new) 창을 띄우지 않음
  - ZoomIt 활성화 (정책으로 켜서 PowerToys 설정에서 끌 수 없음)

<!-- 
### ZoomIt

- Setup: [scripts/setup-zoomit.ps1](scripts/setup-zoomit.ps1) (Program Files 설치, 시작 메뉴 바로가기)
  - 다시 실행 시: 프로그램과 시작 메뉴 바로가기가 있으면 건너뜀
 -->


### WinGet

- Setup: [scripts/setup-winget.ps1](scripts/setup-winget.ps1) (winget이 없거나 실행되지 않을 때 설치, LTSC/IoT처럼 Microsoft Store가 없는 환경용)
  - winget GitHub 릴리스의 설치 파일, 의존 패키지, 라이선스 파일로 PC 전체에 등록 (`Add-AppxProvisionedPackage -LicensePath`) 후 현재 사용자에 바로 연결
  - 라이선스 없이 설치하면 "관련 앱 라이선스를 찾을 수 없습니다" 오류로 winget이 실행되지 않음
  - 다시 실행 시: `winget --version`이 실행되면 건너뜀


### Microsoft PC Manager

- Setup: [scripts/setup-pcmanager.ps1](scripts/setup-pcmanager.ps1) (winget으로 Store 앱 설치, winget은 위 WinGet 단계에서 준비)
  - 다시 실행 시: winget 목록에 PC Manager가 있으면 건너뜀


### Sysinternals Suite

- Setup: [scripts/setup-sysinternals.ps1](scripts/setup-sysinternals.ps1) (Program Files 설치, PATH 추가, EULA 자동 동의)
  - 다시 실행 시: 설치 폴더, PATH, EULA 동의가 모두 돼 있으면 건너뜀


### 자동 로그인

- Setup: [scripts/setup-autologon.ps1](scripts/setup-autologon.ps1) (현재 로그인한 로컬 계정, Sysinternals Autologon 사용, 다음 부팅부터 적용)
  - 다시 실행 시: 자동 로그인이 현재 계정으로 켜져 있으면 건너뜀
  - 실행 중 계정 비밀번호를 물음. 비밀번호가 맞는지 확인한 뒤 설정하고, 빈 값으로 Enter를 누르거나 입력할 수 없는 환경이면 건너뜀
  - 비밀번호는 레지스트리 평문이 아니라 암호화된 LSA secret으로 저장됨 (관리자는 복호화할 수 있음)
  - 로컬 계정만 지원 (Microsoft 계정, 도메인 계정은 건너뜀)
  - 부팅할 때 Shift를 누르고 있으면 한 번 건너뛸 수 있음. 끄려면 `Autologon64.exe`를 실행해 Disable




### Git

- Setup: [scripts/setup-git.ps1](scripts/setup-git.ps1) (Git for Windows 최신 64-bit, 기본 옵션 무인 설치)
  - 다시 실행 시: Git이 설치돼 있고 user.name/user.email이 같으면 건너뜀. 설치만 돼 있으면 사용자 정보만 설정
  - 전역 `user.name`, `user.email` 설정 (이메일은 GitHub noreply 주소로 비식별화)


### Claude Code 텔레그램 알림

- Setup: [scripts/setup-claude-telegrambot.ps1](scripts/setup-claude-telegrambot.ps1) (Claude Code 응답이 끝나거나 권한 승인을 기다리면 텔레그램으로 알림)
  - 다시 실행 시: `.env`에 토큰·chat id가 없거나, hook 스크립트·`telegram.env`가 같고 `settings.json`에 UserPromptSubmit·Stop hook과 Notification hook(권한 요청만)이 있으면 건너뜀. 빠진 것만 다시 만듦
- 설정: `devices/desktop/.env`의 `TELEGRAM_BOT_TOKEN`, `TELEGRAM_CHAT_ID` ([.env.example](.env.example) 참고, git에 올라가지 않음)
  - 토큰: 텔레그램 @BotFather에게 `/newbot`
  - chat id: @userinfobot에게 메시지를 보내면 알려 주는 숫자
- [scripts/setup-claude-telegrambot.sh](scripts/setup-claude-telegrambot.sh)를 `~/.claude/hooks/telegram-notify.sh`로 복사하고, 토큰·chat id를 `~/.claude/telegram.env`에 쓰고, `~/.claude/settings.json`에 hook을 추가함 (기존 설정은 유지, 바꾸기 전 `settings.json.bak`으로 백업)
- 메시지 형식 (항목마다 줄바꿈, `ai` 값으로 다른 알림과 구분, `request`는 마지막 질문의 앞 60자):

```text
[Info] ai="Claude Code",
workspace="silent_sdk",
request="텔레그램 알림봇에 질의내용 간단요약본 추가해서...",
event="done"
```

- 적용: 설치 후 Claude Code를 다시 시작하거나 `/hooks`를 한 번 열기


### Python

- Setup: [scripts/setup-python.ps1](scripts/setup-python.ps1) (현재 사용자용, `%LOCALAPPDATA%\Programs\Python\Python312`에 설치)
  - 다시 실행 시: Python 3.12와 모든 패키지가 설치돼 있으면 건너뜀. 패키지만 빠져 있으면 패키지만 설치
  - 버전: 가장 많이 쓰는 3.12 ([pypistats](https://pypistats.org/packages/pandas) 기준) 중 Windows 설치 파일이 있는 최신 패치 (3.12.10)
    - 3.12는 보안 수정만 받는 단계라 3.12.11 이후는 Windows 설치 파일이 없음. 버전은 스크립트의 `$minor`로 변경
  - PATH 환경변수에 추가하지 않음. `py -3.12`로 실행 (py 런처는 함께 설치됨)
  - 설치 후 tqdm, pandas, matplotlib, seaborn, scikit-learn, ipykernel, openpyxl, requests 설치


### Visual Studio Code

- Setup: [scripts/setup-vscode.ps1](scripts/setup-vscode.ps1) (System Installer x64 최신 버전, PATH 추가, 탐색기 "Code로 열기" 메뉴)
  - 다시 실행 시: VS Code가 설치돼 있으면(PC 전체 또는 사용자 단위) 건너뜀


### Docker + Docker Desktop

- Setup: [scripts/setup-docker.ps1](scripts/setup-docker.ps1) (WSL 2 활성화 후 Docker Desktop 최신 버전 설치, docker-users 그룹 추가, 적용 후 재부팅)
  - 다시 실행 시: Docker Desktop이 설치돼 있고 사용자가 docker-users 그룹에 있으면 건너뜀. 그룹만 빠져 있으면 그룹만 추가
  - Docker Engine, CLI, Compose는 Docker Desktop에 포함


### OpenClaw (로컬 Gateway)

- Setup: [scripts/setup-openclaw-gateway.ps1](scripts/setup-openclaw-gateway.ps1) (Node.js(winget) 최신, OpenClaw CLI(npm) 최신, 이 PC에서만 접속되는 Gateway `ws://localhost:18789`를 token 인증으로 설치, 기본 모델 `openrouter/openrouter/free`)
  - 다시 실행 시: `openclaw` 명령이 있고, 작업 스케줄러에 `OpenClaw Gateway`가 있고, `gateway.bind=loopback`이고, 기본 모델이 OpenRouter 무료 라우터이고, `.env`에 키가 있으면 OpenRouter·Gemini 키도 등록돼 있을 때 건너뜀
- 설정: `.env`의 `OPENROUTER_API_KEY` ([.env.example](.env.example) 참고, 비우면 키 없이 설치만 함)
- 설정: `.env`의 `GEMINI_API_KEY` (비우면 Gemini 연결 안 함, 기본 모델은 그대로 OpenRouter), `openclaw infer model run --model google/gemini-3.6-flash --prompt "..."`로 사용
- Gateway는 작업 스케줄러 `OpenClaw Gateway`로 로그인 시 실행됨
- 업데이트: `npm i -g openclaw@latest`


### OpenClaw Companion (트레이 앱)

- Setup: [scripts/setup-openclaw-companion.ps1](scripts/setup-openclaw-companion.ps1) (winget `OpenClaw.OpenClawCompanion` 설치, 위 로컬 Gateway에 연결, 트레이 앱의 페어링 요청(operator, node) 승인)
  - 다시 실행 시: 트레이 앱이 설치돼 있고, 로컬 Gateway 연결이 활성 연결이고, 그 연결의 기기가 operator·node로 페어링돼 있으면 건너뜀
- 트레이 앱에 이미 있는 다른 Gateway 연결은 그대로 두고, 로컬 연결을 활성 연결로 바꿈 (트레이 앱은 한 번에 Gateway 하나에만 연결됨)


### OpenClaw Companion (원격 Gateway 연결)

- Setup: [scripts/setup-openclaw-remote.ps1](scripts/setup-openclaw-remote.ps1) (이 PC에는 Gateway·OpenClaw CLI를 설치하지 않음, winget `OpenClaw.OpenClawCompanion` 설치, 원격 Gateway에 연결, 트레이 앱의 페어링 요청(operator, node)을 Gateway 장비에서 ssh로 승인)
  - 다시 실행 시: 트레이 앱이 있고, 원격 Gateway 연결이 활성 연결이고 token이 같고, 그 연결의 기기가 Gateway에 operator·node로 페어링돼 있으면 건너뜀
- 설정: `.env`의 `OPENCLAW_GATEWAY_URL`, `OPENCLAW_GATEWAY_TOKEN`, `OPENCLAW_GATEWAY_SSH` ([.env.example](.env.example) 참고, 하나라도 비우면 건너뜀)
- Gateway 장비에 비밀번호 없이(ssh 키로) ssh 접속이 돼야 함 (Setup 중 페어링 승인에만 사용)
- desktop 전체 Setup에서는 실행하지 않음 (desktop은 로컬 Gateway 사용, 다른 Windows 장비의 Setup에서 호출)


### OpenCode

- Setup: [scripts/setup-opencode.ps1](scripts/setup-opencode.ps1) (Node.js(winget) 최신, OpenCode CLI(npm `opencode-ai`) 최신, 기본 모델 `opencode/deepseek-v4.1-flash-free`, 실패 시 `opencode-runtime-fallback` 플러그인으로 `opencode/glm-5.3-flash-free` → `opencode/beam-free` 순으로 전환)
  - 다시 실행 시: `opencode` 명령이 있고, `~\.config\opencode\opencode.json`의 기본 모델과 플러그인, `~\.config\opencode\opencode-fallback.json`의 대체 모델이 모두 같고, `.env`에 키가 있으면 Gemini 키도 등록돼 있을 때 건너뜀. CLI만 설치돼 있으면 설정만 적용
- 설정: `.env`의 `GEMINI_API_KEY` ([.env.example](.env.example) 참고, 비우면 Gemini 연결 없이 설치만 함), `opencode run -m google/gemini-3.6-flash "..."`로 사용 (`gemini-3.8-flash`는 첫 응답까지 1~3분 걸려 대체 모델 플러그인의 30초 제한에 중단됨)
- 무료 `opencode/` 모델은 로그인 없이 사용 가능
- 설정 파일의 다른 항목은 그대로 둠
- 업데이트: `npm i -g --allow-scripts=opencode-ai opencode-ai@latest`
