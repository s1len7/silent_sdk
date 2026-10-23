# windows

- 기본 데스크탑 설정 자동화
- 지원OS: Windows 10 혹은 그 이상

## 기능

- 전체 Setup: PowerShell에서 이 한 줄만 실행 ([setup.ps1](setup.ps1)):

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/windows/setup.ps1 | iex
```



### 원격 데스크톱 켬

- Setup: [scripts/setup-rdp.ps1](scripts/setup-rdp.ps1) (원격 데스크톱 켬, NLA 사용, 방화벽 3389 허용)
  - Windows Home 에디션은 원격 데스크톱 호스트를 지원하지 않아 건너뜀
  - 접속하려면 로그인 계정에 비밀번호가 있어야 함


### Google Chrome

- Setup: [scripts/setup-chrome.ps1](scripts/setup-chrome.ps1) (엔터프라이즈 64-bit MSI 최신 버전, 무인 설치)


### PowerToys

- Setup: [scripts/setup-powertoys.ps1](scripts/setup-powertoys.ps1) (최신 버전)

<!-- 
### ZoomIt

- Setup: [scripts/setup-zoomit.ps1](scripts/setup-zoomit.ps1) (Program Files 설치, 시작 메뉴 바로가기)
 -->


### Microsoft PC Manager

- Setup: [scripts/setup-pcmanager.ps1](scripts/setup-pcmanager.ps1) (winget으로 Store 앱 설치, winget 없으면 먼저 설치)


### Sysinternals Suite

- Setup: [scripts/setup-sysinternals.ps1](scripts/setup-sysinternals.ps1) (Program Files 설치, PATH 추가, EULA 자동 동의)




### Git

- Setup: [scripts/setup-git.ps1](scripts/setup-git.ps1) (Git for Windows 최신 64-bit, 기본 옵션 무인 설치)
  - 전역 `user.name`, `user.email` 설정 (이메일은 GitHub noreply 주소로 비식별화)


### Visual Studio Code

- Setup: [scripts/setup-vscode.ps1](scripts/setup-vscode.ps1) (System Installer x64 최신 버전, PATH 추가, 탐색기 "Code로 열기" 메뉴)


### Docker + Docker Desktop

- Setup: [scripts/setup-docker.ps1](scripts/setup-docker.ps1) (WSL 2 활성화 후 Docker Desktop 최신 버전 설치, docker-users 그룹 추가, 적용 후 재부팅)
  - Docker Engine, CLI, Compose는 Docker Desktop에 포함


### Python

- Setup: [scripts/setup-python.ps1](scripts/setup-python.ps1) (모든 사용자용, `C:\Program Files\Python312`에 설치)
  - 버전: 가장 많이 쓰는 3.12 ([pypistats](https://pypistats.org/packages/pandas) 기준) 중 Windows 설치 파일이 있는 최신 패치 (3.12.10)
    - 3.12는 보안 수정만 받는 단계라 3.12.11 이후는 Windows 설치 파일이 없음. 버전은 스크립트의 `$minor`로 변경
  - PATH 환경변수에 추가하지 않음. `py -3.12`로 실행 (py 런처는 함께 설치됨)
  - 설치 후 tqdm, pandas, matplotlib, seaborn, scikit-learn, ipykernel, openpyxl, requests 설치