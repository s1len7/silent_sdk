> 이 파일의 규칙은 [공통 규칙](../../AGENTS.md)에 더해 적용됨 (공통 규칙도 함께 읽고 따를 것)

## generic-ubuntu 전용

- 대상: Ubuntu/Debian 계열 (빌려쓰는 PC용), bash
- 빌려쓰는 PC용이므로 사용자 범위 설치를 우선하고, 도구에 필요한 최소한만 설정할 것
- 모듈은 `devices/generic-ubuntu/scripts/`에 `setup_*.sh` 형태로 둘 것
- 새 모듈은 `devices/generic-ubuntu/setup.sh`의 `modules` 배열에 순서대로 추가하고, `devices/generic-ubuntu/README.md`에도 해당 기능 섹션을 추가할 것
- 스크립트 형식: `#!/usr/bin/env bash`, `set -euo pipefail`. 필요 시에만 `sudo` 사용, 가능하면 사용자 범위 우선
- 공통 함수는 `scripts/lib.sh` 사용. 이미 설정돼 있으면 `skip_done "<메시지>"`로 종료 코드 3 반환
- 사용자 범위 설치 우선. PATH/프로필 변경이 필요하면 사용자에게 확인할 것
- 최소 도구: git, Visual Studio Code, OpenCode CLI. 빌려쓰는 PC에서 한글 타이핑이 필요할 수 있으므로 `setup_korean_input`(ibus-hangul) 포함
- 다른 장비 폴더는 수정하지 말 것

