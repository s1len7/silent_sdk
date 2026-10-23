@vibecoding/CLAUDE.md

## silent_sdk 구조

- 장비별 설정 자동화를 한 저장소에서 관리함
- 장비마다 `devices/` 아래에 폴더 하나 (`devices/windows/`, `devices/raspberrypi4/`, `devices/titan-s260/`, `devices/byt-t1/`), 장비 전용 규칙은 각 폴더의 CLAUDE.md를 따를 것
- 한 장비 작업에서 다른 장비 폴더는 수정하지 않을 것
  - 단, `devices/windows/scripts/`는 `devices/titan-s260/setup.ps1`도 호출하므로 수정 시 titan-s260에 미치는 영향도 확인할 것
- 장비의 전체 설치 진입점은 `devices/<장비>/setup.ps1` 또는 `devices/<장비>/scripts/setup.sh`에 두고, 루트에는 두지 않을 것
- 새 장비는 `devices/<장비>/` 폴더에 CLAUDE.md와 README.md를 만들고, 루트 README.md의 장비 목록과 구조에 추가할 것
- 줄바꿈은 .gitattributes를 따름 (`.sh`는 LF, `.ps1`은 CRLF)


## 전체 셋업 공통 동작

- 진입점은 모듈 하나가 실패해도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL) 요약을 보여줄 것
- 로그는 저장소 `logs/<플랫폼>-<yyyyMMdd-HHmmss>/`에 남길 것 (전체 실행 기록 `setup.log`, 설치 프로그램 로그 `*-install.log`)
  - `logs/`는 `.gitkeep`만 git에 올리고 나머지는 무시함
- 모든 모듈은 맨 앞에서 이미 설정돼 있는지 확인하고, 그렇다면 다운로드·설치 없이 SKIP으로 끝낼 것 (전체 셋업을 다시 실행하면 실패한 모듈만 다시 진행되게)
  - 일부만 돼 있으면 빠진 부분만 처리할 것
  - SKIP 알림 방식은 플랫폼 CLAUDE.md를 따름 (PowerShell: `$global:SetupStepSkipped`, bash: 종료 코드 3)
- 사용자 입력이 필요한 모듈은 터미널이 없을 때도 멈추지 않게 기본값을 쓰거나 SKIP할 것


## README 형식

- 플랫폼 README는 `# 장비명` → 제조사·모델명·지원OS·사양표 → `## 기능` (전체 Setup 한 줄 명령, 다시 실행, 로그) → `### 기능` 순서로 작성할 것
- 기능마다 `- Setup: [스크립트](링크) (요약)` 줄과 `- 다시 실행 시: <건너뛰는 기준>` 줄을 둘 것
- 구현 이유(실행 순서를 정한 이유 등)는 README가 아니라 스크립트 주석에 적을 것


## 공개 저장소

- 이 저장소는 공개(public)이므로 비밀번호, 토큰, 키, 위치 좌표 같은 개인정보를 파일에 넣지 말 것
  - 이런 값은 `.env`(git 무시)에 두고, 값이 빈 `.env.example`과 사용법을 함께 둘 것
- 커밋 작성자는 `silent <20176737+s1len7@users.noreply.github.com>`을 쓰고, 실제 이메일이 커밋에 들어가지 않게 할 것
- 커밋 메시지와 PR에 `Co-Authored-By: Claude` 같은 AI 공동 작성자 줄을 넣지 말 것
