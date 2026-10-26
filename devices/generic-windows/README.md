# generic-windows

제조사/모델: 임의 Windows PC (빌려쓰는 PC용)
지원 OS: Windows 10 이상
사양: 최소 사양 (AI 코딩 CLI 설치용)

## 기능

- Setup: [setup.ps1](setup.ps1) (전체 모듈 실행)
- 다시 실행 시: 이미 설정된 모듈은 건너뛰고, 실패/누락된 부분만 진행
- 로그: `logs/generic-windows-<yyyyMMdd-HHmmss>/` (`setup.log`, `*-install.log`)

### git
- Setup: [../desktop/scripts/setup-git.ps1](../desktop/scripts/setup-git.ps1) (desktop 공통 스크립트 사용)
- 다시 실행 시: git 설치 및 사용자 정보 설정 여부 확인

### vscode
- Setup: [../desktop/scripts/setup-vscode.ps1](../desktop/scripts/setup-vscode.ps1) (desktop 공통 스크립트 사용)
- 다시 실행 시: VS Code 설치 여부 확인

### winget
- Setup: [../desktop/scripts/setup-winget.ps1](../desktop/scripts/setup-winget.ps1) (desktop 공통 스크립트 사용, 관리자 필요)
- 다시 실행 시: winget이 실행되는지 확인
- opencode 단계가 Node.js를 winget으로 설치하므로 opencode보다 먼저 실행 (LTSC나 App Installer가 없는 Windows 10 대응)

### opencode
- Setup: [../desktop/scripts/setup-opencode.ps1](../desktop/scripts/setup-opencode.ps1) (desktop 공통 스크립트 사용)
- 다시 실행 시: `opencode` 명령 사용 가능 여부 확인

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-windows/setup.ps1 | iex
```
