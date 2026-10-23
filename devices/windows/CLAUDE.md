## windows 전용

- 대상: Windows 10 이상, Windows PowerShell 5.1
- 기능 하나당 `scripts/setup-<기능>.ps1` 모듈 하나로 만들고, `devices/windows/setup.ps1`에 호출 한 줄과 devices/windows/README.md에 해당 기능 섹션을 추가할 것
- `.ps1` 파일은 ASCII만 사용할 것 (주석도 영어)
  - `irm | iex`와 BOM 없는 파일을 PowerShell 5.1에서 실행할 때 한글이 깨지므로 공통 규칙의 "주석은 한글"보다 우선함
- 스크립트 공통 형식
  - `$ErrorActionPreference = 'Stop'`, TLS 1.2 설정
  - 관리자 권한으로 실행되는 것을 전제로 함 (권한 상승은 `devices/windows/setup.ps1`이 담당)
  - 설치 파일은 `$env:TEMP`에 받고, 공식 배포 주소나 GitHub releases의 최신 버전을 사용할 것
  - 설치 프로그램의 종료 코드를 확인하고 실패하면 `throw`할 것 (재부팅 필요 코드 3010은 성공으로 봄)
  - 맨 앞에서 이미 설정돼 있는지 확인하고, 그렇다면 다운로드 없이 `$global:SetupStepSkipped = $true` 후 `return` (진입점이 SKIP으로 표시, 다시 실행 시 실패한 단계만 진행)
    - 일부만 돼 있으면 빠진 부분만 처리할 것 (예: 설치는 돼 있고 설정만 빠짐)
    - README 해당 기능에 `다시 실행 시:` 줄로 확인 기준을 적을 것
  - 설치 프로그램 로그는 `$env:SILENT_SDK_LOG_DIR`(없으면 `$env:TEMP`)에 `<기능>-install.log`로 남길 것
- 진입점(`setup.ps1`)은 각 단계를 `devices/windows/scripts/lib-log.ps1`의 `Invoke-Step`으로 실행함 (실패해도 다음 단계 진행, 로그는 저장소 `logs/<플랫폼>-<시각>/`)
