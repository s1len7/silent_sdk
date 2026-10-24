# CLAUDE 지시사항

## 공통

### 기본 원칙

- 언제나 환각(hallucination)을 발생시키지 말 것
- 모든 수정은 요청한 범위만 하고, 불필요한 수정은 최대한 피할 것
  - 작업 중 발견한 다른 문제는 고치지 말고 보고만 할 것
  - 커밋·푸시는 요청받았을 때만 할 것
- 모든 설계와 구현은 오캄의 면도날(Occam's razor)을 따라 가능한 간단하게 할 것
  - 단, 예외처리는 항상 고려하고 꼼꼼하게 할 것

### 설계

- 아래 설계 결정은 실행 전에 선택지와 각각의 근거·영향을 먼저 제시하고, 사용자의 확인을 받은 뒤 진행할 것 (근거 검토 없이 혼자 판단해 되돌려야 하는 작업을 만들지 않기 위함)
  - 파일·모듈·기능·설정 항목 삭제
  - 여러 대안 중 하나를 고르는 일 (라이브러리, 구조, 방식 등)
  - 사용자에게 보이는 동작 변경 (출력 값의 의미, 화면 흐름, 기본값)
  - 외부에서 참조하는 식별자 변경 (예: `irm`·`curl` 한 줄 명령의 스크립트 경로, `.env` 키 이름, 장비 폴더 이름 — 바꾸면 사용자 쪽 명령·설정이 깨짐)
  - 승인 범위는 좁게 해석할 것
    - "N번 진행해"는 그 항목 안의 명확한 버그 수정까지만 승인한 것이며, 설계 결정이 섞여 있으면 따로 물을 것
    - 개선안에 "둘 중 하나 삭제"라고 적었더라도 어느 쪽을 지울지는 승인받지 않은 것
- 지우기 전에 왜 있는지부터 확인할 것
  - 고장 난 코드라고 필요 없는 코드는 아니므로, 먼저 고치는 것이 맞는지 검토할 것
  - 비슷한 것이 두 개 있으면 각각의 원래 용도·제약·장단점을 비교한 뒤 판단할 것

### 구현

- 모든 구현은 가능한 가독성을 최대한으로 고려할 것
- 주석은 한글, 로그와 콘솔 출력 메시지는 모두 영어로 작성할 것
  - 장비 CLAUDE.md에 다른 규칙이 있으면 그것을 따름 (예: desktop의 `.ps1`은 ASCII만 사용하므로 주석도 영어)

### 검증

- 모든 결과는 사용자에게 보여주기전에 사전에 AI가 직접 확인 후 제공할 것
  - 무엇을 어떤 방법으로 확인했고, 무엇을 확인하지 못했는지 구분해서 보고할 것
  - 실행 환경이 없어 동작을 확인할 수 없으면, 가능한 검증(문법 검사 등)까지 하고 나머지는 "미확인"으로 적을 것

## silent_sdk 구조

- 장비별 설정 자동화를 한 저장소에서 관리함
- 장비마다 `devices/` 아래에 폴더 하나 (`devices/desktop/`, `devices/raspberrypi4-8gb/`, `devices/raspberrypi4-2gb/`, `devices/titan-s260/`, `devices/byt-t1/`, `devices/jetson-nano-b01/`, `devices/b150m-am2/`), 장비 전용 규칙은 각 폴더의 CLAUDE.md를 따를 것
- 한 장비 작업에서 다른 장비 폴더는 수정하지 않을 것
  - 단, `devices/desktop/scripts/`는 `devices/titan-s260/setup.ps1`도 호출하므로 수정 시 titan-s260에 미치는 영향도 확인할 것
- 장비의 전체 설치 진입점은 모든 장비에서 이름을 `setup`으로 통일해 장비 폴더 바로 아래에 둘 것 (`devices/<장비>/setup.ps1` 또는 `devices/<장비>/setup.sh`), 저장소 루트나 `scripts/` 안에는 두지 않을 것
  - 단, Proxmox처럼 호스트와 VM이 나뉘는 장비는 호스트용 `setup_host`, VM용 `vm/<VM 이름>/setup_vm`으로 둠 (장비 CLAUDE.md 참고)
- 새 장비는 `devices/<장비>/` 폴더에 CLAUDE.md와 README.md를 만들고, 루트 README.md의 장비 목록과 구조에 추가할 것
  - 장비에 전체 설치 진입점(`setup`)을 만들거나 설치 명령을 바꾸면, 루트 README.md `## 전체 설치`에도 같은 한 줄 명령을 추가·수정할 것
- 줄바꿈은 .gitattributes를 따름 (`.sh`는 LF, `.ps1`은 CRLF)


## Coding

- 언어별 표준 코딩 스타일 가이드를 준수할 것
  - Python: [PEP 8](https://peps.python.org/pep-0008/)
  - PowerShell: [PowerShell Practice and Style Guide](https://poshcode.gitbook.io/powershell-practice-and-style/), PSScriptAnalyzer 기본 규칙
  - Bash: [Google Shell Style Guide](https://google.github.io/styleguide/shellguide.html), ShellCheck 경고가 없게
  - 스타일 가이드와 이 파일·장비 CLAUDE.md의 규칙이 충돌하면 이 파일·장비 CLAUDE.md의 규칙을 따를 것

### Python

- 가능한 모든 string은 f-string을 사용할 것
- 제어문자도 불필요한 사용은 피할것
  - 예: `print("message1\nmessage2")` 대신 `print("message1"); print("message2")`


## 전체 셋업 공통 동작

- 스크립트는 기능별 모듈로 나누고, 진입점으로 모듈 전체를 한 번에 설치할 수도 있게 할 것
- 진입점은 실행할 모듈을 순서대로 직접 나열해서 실행할 것 (PowerShell: `Invoke-Step` 한 줄씩, bash: `modules` 목록), 와일드카드로 모아 실행하지 않음
- 진입점은 모듈 하나가 실패해도 다음 모듈을 계속 실행하고, 끝에 모듈별 결과(OK / SKIP / FAIL) 요약을 보여줄 것
- 로그는 저장소 `logs/<플랫폼>-<yyyyMMdd-HHmmss>/`에 남길 것 (전체 실행 기록 `setup.log`, 설치 프로그램 로그 `*-install.log`)
  - `logs/`는 `.gitkeep`만 git에 올리고 나머지는 무시함
- 모듈 전체를 한 번에 설치하다 오류가 나서 다시 실행하는 경우를 고려해, 모든 모듈은 맨 앞에서 이미 설정돼 있는지 확인하고 그렇다면 다운로드·설치 없이 SKIP으로 끝낼 것 (다시 실행하면 실패한 모듈만 다시 진행되게)
  - 일부만 돼 있으면 빠진 부분만 처리할 것
  - SKIP 알림 방식은 플랫폼 CLAUDE.md를 따름 (PowerShell: `$global:SetupStepSkipped`, bash: 종료 코드 3)
- 사용자 입력이 필요한 모듈은 터미널이 없을 때도 멈추지 않게 기본값을 쓰거나 SKIP할 것


## README 형식

- 플랫폼 README는 `# 장비명` → 제조사·모델명·지원OS·사양표 → `## 기능` (전체 Setup 한 줄 명령, 다시 실행, 로그) → `### 기능` 순서로 작성할 것
- 기능마다 `- Setup: [스크립트](링크) (요약)` 줄과 `- 다시 실행 시: <건너뛰는 기준>` 줄을 둘 것
- 구현 이유(실행 순서를 정한 이유 등)는 README가 아니라 스크립트 주석에 적을 것
- 코드 블록에는 언어를 표시할 것 (```powershell, ```bash, 설정 파일은 ```ini 등, 폴더 구조처럼 코드가 아니면 ```text)


## 공개 저장소

- 이 저장소는 공개(public)이므로 비밀번호, 토큰, 키, 위치 좌표 같은 개인정보를 파일에 넣지 말 것
  - 이런 값은 `.env`(git 무시)에 두고, 값이 빈 `.env.example`과 사용법을 함께 둘 것
- 커밋 작성자는 `silent <20176737+s1len7@users.noreply.github.com>`을 쓰고, 실제 이메일이 커밋에 들어가지 않게 할 것
- 커밋 메시지와 PR에 `Co-Authored-By: Claude` 같은 AI 공동 작성자 줄을 넣지 말 것


<!--
## 참고
- https://daleseo.com/claude-code-claude-md/
-->
