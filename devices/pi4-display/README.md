# pi4-display

- 제조사: [Raspberry Pi Ltd](https://www.raspberrypi.com/)
- 모델명: [Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/), RAM 8GB 모델
  - [제품 사양서(Product Brief)](https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-product-brief.pdf)
- OS 설치 후 기본 셋팅 자동화
- 지원OS: Raspberry Pi OS Trixie 이상
- 작성 원칙: [AGENTS.md](AGENTS.md) 참고 (공통 규칙은 [상위 AGENTS.md](../../AGENTS.md))

| 항목 | 사양 |
| --- | --- |
| SoC | Broadcom BCM2711, Cortex-A72 4코어 64-bit, 1.8GHz |
| RAM | LPDDR4 8GB |
| 저장장치 | microSD |
| 무선 | Wi-Fi 802.11ac (2.4/5GHz), Bluetooth 5.0 BLE |
| 포트 | USB 3.0 x2, USB 2.0 x2, 기가비트 LAN, micro HDMI x2 (최대 4Kp60), MIPI DSI, MIPI CSI, 오디오/컴포지트 |
| GPIO | 40핀 헤더 |
| 디스플레이 | [Raspberry Pi 7인치 터치 디스플레이](https://www.raspberrypi.com/products/raspberry-pi-touch-display/) 800×480 (24-bit RGB), 유효 영역 154.08 × 85.92mm, 밝기 250cd/m², 명암비 500, 외형 192.96 × 110.76mm |
| 터치 | 정전식 멀티터치 최대 10점 (온스크린 키보드 지원) |
| 디스플레이 연결 | DSI (15-way FFC) + GPIO 헤더로 전원 공급 (별도 전원 불필요, 최대 밝기에서 5V 200mA) |
| 전원 | USB-C 5V 3A 이상 (GPIO 5V, PoE HAT도 가능) |
| 동작 온도 | 0~50°C (디스플레이는 -20~+70°C) |


## 기능

- 전체 Setup: 순정 OS 클린설치 직후 이 한 줄만 실행 ([setup.sh](setup.sh)). 파일 없이 실행하면 git을 설치하고 저장소를 받은 뒤(이미 받았으면 `git pull`) 그 안의 `setup.sh`로 전체 설치:

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/pi4-display/setup.sh | sudo bash
```

- 이미 클론되어 있으면: `sudo bash ~/silent_sdk/devices/pi4-display/setup.sh` (`setup.sh`의 `modules` 목록 순서대로 실행)
- 개별 기능만 설치: 이 폴더(`~/silent_sdk/devices/pi4-display`)에서 `sudo bash scripts/setup_<기능>.sh`
- 실패한 모듈이 있어도 나머지 모듈은 계속 진행하고, 끝에 모듈별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함 (모듈별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `~/silent_sdk/logs/pi4-display-<시각>/setup.log`


### 전원 끄기 버튼

- Setup: [scripts/setup_power_button.sh](scripts/setup_power_button.sh) (적용하려면 재부팅 필요)
  - 다시 실행 시: `config.txt`에 같은 줄이 있으면 건너뜀
- 일반 데스크탑 PC처럼 버튼으로 전원을 끔
- `/boot/firmware/config.txt`에 아래 줄을 추가함. 이미 있으면 추가하지 않음
- 배선: 37번 핀(GPIO26) - 버튼 - 39번 핀(GND)
```ini
dtoverlay=gpio-shutdown,gpio_pin=26
```


### 부팅 완료 비프음

- Setup: [scripts/setup_boot_beep.sh](scripts/setup_boot_beep.sh)
  - 다시 실행 시: 서비스 파일이 같고 등록돼 있으면 건너뜀 (테스트 비프음도 울리지 않음)
- 능동 부저(High level trigger 모듈) 배선: I/O - 18번(GPIO24), VCC - 2번(5V), GND - 20번


### SFTP 활성화

- Setup: [scripts/setup_sftp.sh](scripts/setup_sftp.sh)
  - 다시 실행 시: ssh 서비스가 등록돼 있고 실행 중이면 건너뜀

수동 설정 방법:
- 터미널에서 `sudo raspi-config` 실행
- 메뉴: Interface Options → SSH 선택
- SSH 서버를 켤지 묻는 질문에 Yes(Enable) 선택 후 종료
- 서비스 시작:
```bash
sudo systemctl enable ssh
sudo systemctl start ssh
```

- 클라이언트 연결: FileZilla 같은 프로그램에서 호스트(`sftp://라즈베리파이_IP`), 사용자명, 비밀번호, 포트(22)를 입력해 접속


### 화면보호기 / 화면 끄기

- Setup: [scripts/setup_screen_blanking.sh](scripts/setup_screen_blanking.sh)
  - 다시 실행 시: 같은 설정의 swayidle 줄이 하나만 있으면 건너뜀


### htop 자동실행

- Setup: [scripts/setup_htop_autostart.sh](scripts/setup_htop_autostart.sh)
  - 다시 실행 시: htop이 설치돼 있고 자동실행 파일이 저장소와 같으면 건너뜀
- `~/.config/autostart/htop.desktop` 설정 파일로 부팅 시 자동실행


### 런처 전원 끄기 아이콘

- Setup: [scripts/setup_shutdown_shortcut.sh](scripts/setup_shutdown_shortcut.sh)
  - 다시 실행 시: `launchers` 목록에 항목이 있고 찾을 수 있는 `pishutdown.desktop` 파일이 있으면 건너뜀
- 작업표시줄(패널)에 전원 끄기 아이콘을 추가함. 아이콘을 터치하면 라즈베리파이 아이콘 → Shutdown과 마찬가지로 Shutdown Options 창(재부팅 / 게시 중지 / 로그아웃)이 열리고, 창에서 다시 눌러야 실제로 꺼짐
- Trixie Shutdown 메뉴와 같은 프로그램(`pishutdown`)을 실행함. `pishutdown`이 설치돼 있지 않으면 apt로 설치함
- 적용 방법: `~/.config/wf-panel-pi/wf-panel-pi.ini`의 `[panel]` `launchers=` 목록 끝에 `pishutdown`을 추가함. 사용자 파일이 없으면 시스템 기본 파일(`/etc/xdg/wf-panel-pi/wf-panel-pi.ini`)에서 시작
- 시스템 어디에도 `pishutdown.desktop`이 없으면 `~/.local/share/applications/pishutdown.desktop`을 새로 만듦
- 아이콘이 바로 나오지 않으면 다시 로그인


### toggle_rotate

- Setup: [scripts/setup_auto_rotate.sh](scripts/setup_auto_rotate.sh)
  - 다시 실행 시: 패키지가 설치돼 있고 설치된 파일이 저장소와 같으면 건너뜀

라즈베리파이 OS에서 화면과 터치를 180도 회전하는 프로그램

요구사항:
1. Trixie, labwc에서 동작
2. DSI-1에만 적용
3. 실행할 때마다 기본 → 180도 → 기본으로 번갈아 회전
4. 화면과 터치 좌표가 함께 회전
5. 최종 결과물은 Python 프로그램 (테스트는 셸에서 해도 됨)

수동 설치/실행:
```bash
sudo apt install wlr-randr
python3 toggle_rotate/toggle_rotate.py
```


#### 라즈베리파이4 + 7인치 공식 디스플레이 자동회전

- 목표: 화면을 뒤집으면 화면과 터치가 자동으로 180도 회전
- 센서: SW-520D, SIGNAL - 17번 핀

| orientation | 화면 상단 | 회전 |
|---|---|---|
| 0 | 위 | 0도 |
| 1 | 아래 | 180도 |

설치 위치:
- `~/toggle_rotate/auto_rotate.py`
- `~/.config/autostart/auto_rotate.desktop`


### shairport-sync

- Setup: [scripts/setup_shairport_sync.sh](scripts/setup_shairport_sync.sh)
  - 다시 실행 시: 패키지가 설치돼 있으면 건너뜀

`sudo apt install shairport-sync`
- 설치하면 재부팅 시 자동실행됨


### uxplay

- Setup: [scripts/setup_uxplay.sh](scripts/setup_uxplay.sh)
  - 다시 실행 시: uxplay가 설치돼 있고 자동실행 파일이 저장소와 같으면 건너뜀

`sudo apt install uxplay`
- `~/.config/autostart/uxplay.desktop` 설정 파일로 자동실행


### docker

- Setup: [scripts/setup_docker.sh](scripts/setup_docker.sh)
  - 다시 실행 시: 패키지, docker 그룹, 같은 버전의 Portainer Agent 실행이 모두 확인되면 건너뜀

```bash
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

설치 후 동작 확인: `sudo docker run hello-world`를 실행해 정상 작동하는지 확인함

권한 설정 (선택): `sudo usermod -aG docker $USER`를 실행하면 매번 sudo 없이 도커를 쓸 수 있음


#### portainer

- Setup: [scripts/setup_docker.sh](scripts/setup_docker.sh) (docker 설치에 포함)

```bash
docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.39.4
```


#### dozzle

- Setup: [scripts/setup_dozzle.sh](scripts/setup_dozzle.sh)
  - 다시 실행 시: 컨테이너가 실행 중이고 `/data`가 `docker/dozzle/data` 폴더에 바인드돼 있으면 건너뜀. 마운트가 다르면 컨테이너를 다시 만들어 적용 (현재 docker-compose.yml의 마운트 줄은 주석 상태라 항상 실행됨)
<!-- - 로그·설정이 `~/silent_sdk/devices/pi4-display/docker/dozzle/data`(`docker/dozzle/data`) 폴더에 저장됨 (docker-compose.yml `volumes`의 `./data:/data`, compose 파일 위치 기준 상대 경로) -->

<!-- portainer > docker-compose.yml -->
compose 파일: `docker/dozzle/docker-compose.yml`


#### Magic Mirror & MMPM

- Setup: [scripts/setup_magic_mirror.sh](scripts/setup_magic_mirror.sh)
  - 다시 실행 시: `.env`, 한글 폰트, 실행 중인 컨테이너가 모두 있으면 건너뜀 (위치를 다시 묻지 않음)
  - 날씨 위치(`MM_LAT`, `MM_LON`)는 `docker/magic_mirror/.env`에서 읽음. 없으면 실행 중에 1) 공인 IP로 위치 추정(기본값, [ipinfo.io](https://ipinfo.io) 사용) 2) 좌표 직접 입력 3) 건너뛰기 중에서 선택 (직접 만들려면 `.env.example`을 `.env`로 복사해 채움)

한글 폰트: `sudo apt install fonts-nanum fonts-nanum-extra`
<!-- portainer > docker-compose.yml -->
compose 파일: `docker/magic_mirror/docker-compose.yml`


#### theengs-gateway

- Setup: [scripts/setup_theengs_gateway.sh](scripts/setup_theengs_gateway.sh)
  - 다시 실행 시: 컨테이너가 실행 중이면 건너뜀

<!-- portainer -> docker-compose.yml -->
compose 파일: `docker/theengs-gateway/docker-compose.yml`


<!-- 여기까지 진행 -->
<!-- 
## 진행 예정

### duplicati


### openvoiceos

`.config/mycroft/mycroft.conf`


### openclaw
 -->
