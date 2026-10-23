## byt-t1 전용

- 대상: PEGATRON BYT-T1 (Intel Pentium J2900, x86_64, RAM 최대 4GB), Ubuntu Server LTS
  - 데스크탑 환경이 없는 서버이므로 GUI나 자동실행(autostart) 대신 systemd 서비스로 구성할 것
  - 저사양이므로 상주 프로그램과 무거운 설치는 피할 것
- 기능 하나당 `scripts/setup_<기능>.sh` 모듈 하나로 만들고, README.md에 해당 기능 섹션과 `자동화:` 줄을 추가할 것
  - `scripts/setup.sh`가 `setup_*.sh`를 모두 실행하므로 전체 설치에 따로 등록할 필요 없음
- 스크립트 공통 형식
  - `#!/usr/bin/env bash`, `set -euo pipefail`
  - 맨 앞에서 root 권한을 확인하고, 아니면 `sudo bash $0` 안내 후 종료
  - 사용자 파일은 `$SUDO_USER`의 홈에 만들고 `chown`할 것
  - 여러 번 실행해도 결과가 같게 만들 것 (이미 설정돼 있으면 건너뜀)
  - 패키지는 `apt-get`으로 설치하고 대화형 질문이 뜨지 않게 할 것 (`DEBIAN_FRONTEND=noninteractive`)
