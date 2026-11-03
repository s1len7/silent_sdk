> 이 파일의 규칙은 [공통 규칙](../../AGENTS.md)에 더해 적용됨 (공통 규칙도 함께 읽고 따를 것)

## imac-27-2019 전용

- 대상: Apple iMac (Retina 5K, 27-inch, 2019), macOS Sequoia 15
- 이 장비는 `sudo` 권한을 받을 수 없음: 모든 모듈은 `sudo` 없이 사용자 권한으로 실행하고, 관리자 권한이 필요한 작업은 하지 말고 사용자에게 안내할 것
- 모듈은 `devices/imac-27-2019/scripts/setup_<기능>.sh`에 두고, `devices/imac-27-2019/setup.sh`의 `modules` 목록과 README.md에 함께 추가할 것
- 스크립트는 macOS 기본 bash 3.2에서도 동작하게 쓸 것 (연관 배열·`mapfile`·`${var,,}` 등 bash 4 이상 문법 금지)
- 공통 함수는 `scripts/lib.sh` 사용. 이미 설정돼 있으면 `skip_done "<메시지>"`로 종료 코드 3 반환
- 셸 프로필(`~/.zshrc` 등)은 사용자 확인 없이 수정하지 말고, 필요한 줄만 안내할 것
- TODO: AI Agent가 필요한 내용 고민하고 보고한뒤 사용자의 결정에 따라 적용할 것
