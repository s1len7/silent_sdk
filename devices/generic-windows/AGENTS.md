> 이 파일의 규칙은 [desktop 규칙](../desktop/AGENTS.md)과 [공통 규칙](../../AGENTS.md)에 더해 적용됨 (둘 다 함께 읽고 따를 것)

## generic-windows 전용

- 대상: Windows 10 이상 (빌려쓰는 PC용), Windows PowerShell 5.1
- 빌려쓰는 PC용이므로 사용자 범위 설치를 우선하고, 도구에 필요한 최소한만 설정할 것
- Windows 공통 스크립트(git/vscode/winget/opencode, 로깅 `lib-log.ps1`)는 `devices/generic-windows/scripts/`에 두고 desktop·titan-s260·thinkpad-s2-2g도 이 파일을 사용 (수정은 사용자 확인 후 진행)
- Windows 전용 모듈은 `devices/generic-windows/scripts/`에 `setup-<기능>.ps1` 형태로 둘 것
- 새 모듈은 `devices/generic-windows/setup.ps1`에 순서대로 추가하고, `devices/generic-windows/README.md`에도 해당 기능 섹션을 추가할 것
- `.ps1` 파일은 ASCII만 사용할 것 (주석 포함). `irm | iex` 및 BOM 없는 실행(PowerShell 5.1) 때문
- desktop 형식 따름: `$ErrorActionPreference = 'Stop'`, TLS 1.2, 이미 설정돼 있으면 `$global:SetupStepSkipped = $true` 후 `return`, 설치 로그는 `$env:SILENT_SDK_LOG_DIR` 또는 `$env:TEMP`에 기록
- 사용자 범위 설치 우선. PATH/프로필 변경이 필요하면 사용자에게 확인할 것
- 최소 도구: git, Visual Studio Code, OpenCode CLI
- 다른 장비 폴더는 수정하지 말 것

