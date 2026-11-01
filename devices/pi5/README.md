# pi5

- 제조사: [Raspberry Pi Ltd](https://www.raspberrypi.com/)
- 모델명: [Raspberry Pi 5](https://www.raspberrypi.com/products/raspberry-pi-5/), RAM 8GB 모델
  - [제품 사양서(Product Brief)](https://datasheets.raspberrypi.com/rpi5/raspberry-pi-5-product-brief.pdf)
- 지원OS: Raspberry Pi OS Desktop 64-bit (Trixie)
- 작성 원칙: [AGENTS.md](AGENTS.md) 참고 (공통 규칙은 [상위 AGENTS.md](../../AGENTS.md))

| 항목 | 사양 |
| --- | --- |
| SoC | Broadcom BCM2712, Cortex-A76 4코어 64-bit, 2.4GHz |
| RAM | LPDDR4X 8GB |
| 저장장치 | microSD |
| AI 가속기 | Hailo-8 (PCIe) |
| 무선 | Wi-Fi 802.11ac (2.4/5GHz), Bluetooth 5.0 BLE |
| 포트 | USB 3.0 x2, USB 2.0 x2, 기가비트 LAN, micro HDMI x2 (최대 4Kp60), MIPI 카메라/디스플레이 x2, PCIe 2.0 x1 |
| GPIO | 40핀 헤더 |
| 전원 | USB-C 5V 5A (USB PD) |


## 기능

- 전체 Setup: Raspberry Pi OS Desktop 64-bit 클린설치 직후 이 한 줄만 실행 ([setup.sh](setup.sh)). 파일 없이 실행하면 git을 설치하고 저장소를 받은 뒤(이미 받았으면 `git pull`) 그 안의 `setup.sh`로 전체 설치:

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/pi5/setup.sh | sudo bash
```

- 이미 클론되어 있으면: `sudo bash ~/silent_sdk/devices/pi5/setup.sh` (`setup.sh`의 `modules` 목록 순서대로 실행)
- 개별 기능만 설치: 이 폴더(`~/silent_sdk/devices/pi5`)에서 `sudo bash scripts/setup_<기능>.sh`
- 실패한 모듈이 있어도 나머지 모듈은 계속 진행하고, 끝에 모듈별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함 (모듈별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `~/silent_sdk/logs/pi5-<시각>/setup.log`


### 한글 폰트

- Setup: [../pi4-display/scripts/setup_korean_font.sh](../pi4-display/scripts/setup_korean_font.sh) (라즈베리파이 공통 모듈, 설명은 [pi4-display README](../pi4-display/README.md#한글-폰트) 참고)
  - 다시 실행 시: `fonts-nanum`, `fonts-nanum-extra` 패키지가 설치돼 있고 `fc-list`에 나눔고딕(NanumGothic)이 보이면 건너뜀
  - 개별 실행: 이 폴더에서 `sudo bash ../pi4-display/scripts/setup_korean_font.sh`


### 한글 입력

- Setup: [../pi4-display/scripts/setup_korean_input.sh](../pi4-display/scripts/setup_korean_input.sh) (라즈베리파이 공통 모듈, 설명은 [pi4-display README](../pi4-display/README.md#한글-입력) 참고)
  - 다시 실행 시: 패키지가 설치돼 있고, `~/.xinputrc`가 fcitx5를 고르고, `~/.config/fcitx5/profile`에 `hangul`이, `~/.config/fcitx5/config`에 전환 키가 모두 있으면 건너뜀
  - 개별 실행: 이 폴더에서 `sudo bash ../pi4-display/scripts/setup_korean_input.sh`


### VS Code

- Setup: [scripts/setup_vscode.sh](scripts/setup_vscode.sh) (Raspberry Pi OS 저장소의 `code` 패키지 설치)
  - 다시 실행 시: `code` 패키지가 설치돼 있으면 건너뜀
- 업데이트는 apt로 받음 (`sudo apt update && sudo apt upgrade`)


### OpenCode CLI

- Setup: [../pi4-display/scripts/setup_opencode.sh](../pi4-display/scripts/setup_opencode.sh) (라즈베리파이 공통 모듈, 설명은 [pi4-display README](../pi4-display/README.md#opencode-cli) 참고)
  - 다시 실행 시: `~/.local/bin/opencode`가 있고 실행되면 건너뜀
  - 개별 실행: 이 폴더에서 `sudo bash ../pi4-display/scripts/setup_opencode.sh`


### docker

- Setup: [../pi4-display/scripts/setup_docker.sh](../pi4-display/scripts/setup_docker.sh) (라즈베리파이 공통 모듈, Raspberry Pi OS 저장소의 `docker.io`·`docker-compose` 설치, 사용자를 `docker` 그룹에 추가, Portainer Agent(포트 9001) 실행. 설명은 [pi4-display README](../pi4-display/README.md#docker) 참고)
  - 다시 실행 시: 패키지, docker 그룹, 같은 버전의 Portainer Agent 실행이 모두 확인되면 건너뜀
  - 개별 실행: 이 폴더에서 `sudo bash ../pi4-display/scripts/setup_docker.sh`
- 설치 후 다시 로그인해야 sudo 없이 `docker` 명령을 쓸 수 있음
