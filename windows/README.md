# windows

- 기본 데스크탑 설정 자동화
- 지원OS: Windows 10 혹은 그 이상

## 기능

- 전체 Setup: PowerShell에서 이 한 줄만 실행 ([setup.ps1](setup.ps1)):

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/windows/setup.ps1 | iex
```

- 실패한 단계가 있어도 나머지 단계는 계속 진행하고, 끝에 단계별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 단계는 SKIP하고, 실패했거나 안 된 단계만 다시 진행함 (단계별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `C:\silent_sdk\logs\windows-<시각>\` (`setup.log` 전체 실행 기록, `*-install.log` 설치 프로그램 로그)



### 원격 데스크톱 켬

- Setup: [scripts/setup-rdp.ps1](scripts/setup-rdp.ps1) (원격 데스크톱 켬, NLA 사용, 방화벽 3389 허용)
  - 다시 실행 시: 원격 데스크톱 허용, NLA, 방화벽 규칙이 모두 켜져 있으면 건너뜀
  - Windows Home 에디션은 원격 데스크톱 호스트를 지원하지 않아 건너뜀
  - 접속하려면 로그인 계정에 비밀번호가 있어야 함


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

- Setup: [scripts/setup-winget.ps1](scripts/setup-winget.ps1) (winget이 없을 때만 설치, LTSC/IoT처럼 Microsoft Store가 없는 환경용)
  - 공식 방법 사용: `Microsoft.WinGet.Client` 모듈의 `Repair-WinGetPackageManager -AllUsers`
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