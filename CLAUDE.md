@vibecoding/CLAUDE.md

## silent_sdk 구조

- 플랫폼별 설정 자동화를 한 저장소에서 관리함
- 플랫폼마다 최상위 폴더 하나 (`windows/`, `raspberrypi4/`, `titan-s260/`, `byt-t1/`), 플랫폼 전용 규칙은 각 폴더의 CLAUDE.md를 따를 것
- 한 플랫폼 작업에서 다른 플랫폼 폴더는 수정하지 않을 것
  - 단, `windows/scripts/`는 `titan-s260/setup.ps1`도 호출하므로 수정 시 titan-s260에 미치는 영향도 확인할 것
- 새 플랫폼은 `<플랫폼>/` 폴더에 CLAUDE.md와 README.md를 만들고, 루트 README.md의 플랫폼 목록에 추가할 것
- 줄바꿈은 .gitattributes를 따름 (`.sh`는 LF, `.ps1`은 CRLF)
