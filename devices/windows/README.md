# windows

- 기본 데스크탑 설정 자동화
- 지원OS: Windows 10 혹은 그 이상

## 기능

- 전체 Setup: PowerShell에서 이 한 줄만 실행 ([setup.ps1](setup.ps1)):

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/windows/setup.ps1 | iex
```

- 실패한 단계가 있어도 나머지 단계는 계속 진행하고, 끝에 단계별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 단계는 SKIP하고, 실패했거나 안 된 단계만 다시 진행함 (단계별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `C:\silent_sdk\logs\windows-<시각>\` (`setup.log` 전체 실행 기록, `*-install.log` 설치 프로그램 로그)



### hostname 설정

- Setup: [scripts/setup-hostname.ps1](scripts/setup-hostname.ps1) (새 hostname을 물어봄, 엔터를 누르면 기본값 `silent-desktop`, 적용 후 재부팅)
  - 전체 Setup 맨 처음에 물어보므로 이후 단계는 입력 없이 진행됨
  - hostname 규칙: 1~15자 영문·숫자·하이픈, 숫자만은 안 됨, 하이픈으로 시작·끝나면 안 됨
  - 다시 실행 시: 고른 hostname이 지금 hostname과 같거나, 변경 후 재부팅 대기 중이면 건너뜀


### Windows 업데이트

- Setup: [scripts/setup-windows-update.ps1](scripts/setup-windows-update.ps1) (드라이버 포함 모든 업데이트 설치, Windows 내장 업데이트 API 사용)
  - 기능 업데이트(Windows 버전 변경)와 사용자 입력이 필요한 업데이트는 제외
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




### Git

- Setup: [scripts/setup-git.ps1](scripts/setup-git.ps1) (Git for Windows 최신 64-bit, 기본 옵션 무인 설치)
  - 다시 실행 시: Git이 설치돼 있고 user.name/user.email이 같으면 건너뜀. 설치만 돼 있으면 사용자 정보만 설정
  - 전역 `user.name`, `user.email` 설정 (이메일은 GitHub noreply 주소로 비식별화)


### Visual Studio Code

- Setup: [scripts/setup-vscode.ps1](scripts/setup-vscode.ps1) (System Installer x64 최신 버전, PATH 추가, 탐색기 "Code로 열기" 메뉴)
  - 다시 실행 시: VS Code가 설치돼 있으면(PC 전체 또는 사용자 단위) 건너뜀


### Docker + Docker Desktop

- Setup: [scripts/setup-docker.ps1](scripts/setup-docker.ps1) (WSL 2 활성화 후 Docker Desktop 최신 버전 설치, docker-users 그룹 추가, 적용 후 재부팅)
  - 다시 실행 시: Docker Desktop이 설치돼 있고 사용자가 docker-users 그룹에 있으면 건너뜀. 그룹만 빠져 있으면 그룹만 추가
  - Docker Engine, CLI, Compose는 Docker Desktop에 포함


### Python

- Setup: [scripts/setup-python.ps1](scripts/setup-python.ps1) (모든 사용자용, `C:\Program Files\Python312`에 설치)
  - 다시 실행 시: Python 3.12와 모든 패키지가 설치돼 있으면 건너뜀. 패키지만 빠져 있으면 패키지만 설치
  - 버전: 가장 많이 쓰는 3.12 ([pypistats](https://pypistats.org/packages/pandas) 기준) 중 Windows 설치 파일이 있는 최신 패치 (3.12.10)
    - 3.12는 보안 수정만 받는 단계라 3.12.11 이후는 Windows 설치 파일이 없음. 버전은 스크립트의 `$minor`로 변경
  - PATH 환경변수에 추가하지 않음. `py -3.12`로 실행 (py 런처는 함께 설치됨)
  - 설치 후 tqdm, pandas, matplotlib, seaborn, scikit-learn, ipykernel, openpyxl, requests 설치