## jetson-nano-b01 전용

- 대상: NVIDIA Jetson Nano Developer Kit B01 (ARM Cortex-A57, aarch64, RAM 4GB), JetPack 4.6.6 (Jetson Linux R32.7.6, Ubuntu 18.04)
  - JetPack 4와 Ubuntu 18.04는 지원이 끝났으므로, 새 패키지나 도구는 Ubuntu 18.04 / aarch64에서 동작하는지 먼저 확인할 것
  - A02 리비전과 하드웨어가 다르므로(카메라 커넥터 등) B01 기준으로 작성할 것
  - RAM이 4GB이므로 무거운 상주 프로그램은 피할 것
- 기능 하나당 `scripts/setup_<기능>.sh` 모듈 하나로 만들고, README.md `## 기능` 아래에 `### <기능>` 섹션과 `- Setup: [scripts/setup_<기능>.sh](...)` 줄을 추가할 것
  - `setup.sh`가 `scripts/setup_*.sh`를 모두 실행하므로 전체 설치에 따로 등록할 필요 없음
- 스크립트 공통 형식
  - `#!/usr/bin/env bash`, `set -euo pipefail`
  - 맨 앞에서 root 권한을 확인하고, 아니면 `sudo bash $0` 안내 후 종료
  - 사용자 파일은 `$SUDO_USER`의 홈에 만들고 `chown`할 것
  - 여러 번 실행해도 결과가 같게 만들 것
  - 맨 앞에서 이미 설정돼 있는지 확인하고 그렇다면 메시지 출력 후 종료 코드 3으로 끝낼 것 (raspberrypi4-8gb의 `scripts/lib.sh`, `setup.sh`와 같은 방식: 실패해도 다음 모듈 진행, OK/SKIP/FAIL 요약, 로그는 저장소 `logs/`)
    - README 해당 기능에 `다시 실행 시:` 줄로 확인 기준을 적을 것
  - 패키지는 `apt-get`으로 설치하고 대화형 질문이 뜨지 않게 할 것 (`DEBIAN_FRONTEND=noninteractive`)
