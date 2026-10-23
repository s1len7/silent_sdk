## raspberrypi4 전용

- 대상: Raspberry Pi 4, Raspberry Pi OS Trixie 이상 (labwc / Wayland)
- 기능 하나당 `scripts/setup_<기능>.sh` 모듈 하나로 만들고, README.md의 해당 기능에 `자동화:` 줄을 추가할 것
  - `scripts/setup.sh`가 `setup_*.sh`를 모두 실행하므로 전체 설치에 따로 등록할 필요 없음
- 스크립트 공통 형식
  - `#!/usr/bin/env bash`, `set -euo pipefail`
  - 맨 앞에서 root 권한을 확인하고, 아니면 `sudo bash $0` 안내 후 종료
  - 사용자 파일은 `$SUDO_USER`의 홈에 만들고 `chown`할 것
  - 여러 번 실행해도 결과가 같게 만들 것 (이미 설정돼 있으면 건너뜀)
  - Windows에서 편집한 파일을 복사할 때는 CR을 제거할 것
