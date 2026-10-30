# generic-windows

제조사/모델: 임의 Windows PC (빌려쓰는 PC용)
지원 OS: Windows 10 이상
사양: 최소 사양 (AI 코딩 CLI 설치용)

## 기능

- Setup: [setup.ps1](setup.ps1) (전체 모듈 실행)
- 다시 실행 시: 이미 설정된 모듈은 건너뛰고, 실패/누락된 부분만 진행
- 로그: `logs/generic-windows-<yyyyMMdd-HHmmss>/` (`setup.log`, `*-install.log`)

### git
- Setup: [scripts/setup-git.ps1](scripts/setup-git.ps1) (Windows 공통 스크립트, desktop·titan-s260·thinkpad-s2-2g도 사용)
- 다시 실행 시: git 설치 및 사용자 정보 설정 여부 확인

### vscode
- Setup: [scripts/setup-vscode.ps1](scripts/setup-vscode.ps1) (Windows 공통 스크립트, desktop·thinkpad-s2-2g도 사용)
- 다시 실행 시: VS Code 설치 여부 확인

### winget
- Setup: [scripts/setup-winget.ps1](scripts/setup-winget.ps1) (Windows 공통 스크립트, 관리자 필요, desktop·titan-s260·thinkpad-s2-2g도 사용)
- 다시 실행 시: winget이 실행되는지 확인
- opencode 단계가 Node.js를 winget으로 설치하므로 opencode보다 먼저 실행 (LTSC나 App Installer가 없는 Windows 10 대응)

### opencode
- Setup: [scripts/setup-opencode.ps1](scripts/setup-opencode.ps1) (Windows 공통 스크립트, desktop·thinkpad-s2-2g도 사용)
- 다시 실행 시: `opencode` 명령 사용 가능 여부 확인

```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-windows/setup.ps1 | iex
```

## 반납 전 정리 (Cleanup)

설치된 프로그램(git, VS Code, OpenCode CLI 등)은 유지하고, `silent_sdk` 저장소와 개인/비공개 정보만 정리합니다.

브라우저(Chrome, Edge, Chromium, Firefox)의 모든 계정도 로그아웃합니다. 프로필마다 쿠키·세션·저장된 비밀번호·브라우저 계정 토큰·사이트 저장소만 지우고 북마크·기록·확장은 남깁니다. 실행 중인 브라우저는 확인(y/N) 후 종료합니다.

```powershell
# 저장소 외부에서 실행 권장
cd ..
.\silent_sdk\devices\generic-windows\setup.ps1 -Cleanup

# 실제 삭제 없이 확인만
.\silent_sdk\devices\generic-windows\setup.ps1 -Cleanup -DryRun

# 확인 없이 강제 실행 (주의)
.\silent_sdk\devices\generic-windows\setup.ps1 -Cleanup -Force
```

주의: 저장소 루트 전체를 삭제합니다. 본 스크립트는 설치된 패키지는 제거하지 않습니다.
