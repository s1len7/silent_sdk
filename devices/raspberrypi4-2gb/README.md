# Raspberry Pi 4 Model B (2GB)

- 제조사: [Raspberry Pi Ltd](https://www.raspberrypi.com/)
- 모델명: [Raspberry Pi 4 Model B](https://www.raspberrypi.com/products/raspberry-pi-4-model-b/), RAM 2GB 모델
  - [제품 사양서(Product Brief)](https://datasheets.raspberrypi.com/rpi4/raspberry-pi-4-product-brief.pdf)
- 지원OS: Raspberry Pi OS Lite 64-bit (Trixie)
- 작성 원칙: [CLAUDE.md](CLAUDE.md) 참고 (공통 규칙은 [상위 CLAUDE.md](../../CLAUDE.md))

| 항목 | 사양 |
| --- | --- |
| SoC | Broadcom BCM2711, Cortex-A72 4코어 64-bit, 1.8GHz |
| RAM | LPDDR4 2GB |
| 저장장치 | microSD |
| 무선 | Wi-Fi 802.11ac (2.4/5GHz), Bluetooth 5.0 BLE |
| 포트 | USB 3.0 x2, USB 2.0 x2, 기가비트 LAN, micro HDMI x2 (최대 4Kp60), MIPI DSI, MIPI CSI, 오디오/컴포지트 |
| GPIO | 40핀 헤더 |
| 전원 | USB-C 5V 3A 이상 (GPIO 5V, PoE HAT도 가능) |
| 동작 온도 | 0~50°C |


## 기능

- 전체 Setup: Raspberry Pi OS Lite 64-bit 클린설치 직후 이 한 줄만 실행 ([setup.sh](setup.sh)) (git이 없으면 설치 → 저장소 클론 → 전체 설치):

```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/raspberrypi4-2gb/setup.sh
```

- 이미 클론되어 있으면: `sudo bash ~/silent_sdk/devices/raspberrypi4-2gb/setup.sh` (`setup.sh`의 `modules` 목록 순서대로 실행)
- 개별 기능만 설치: 이 폴더(`~/silent_sdk/devices/raspberrypi4-2gb`)에서 `sudo bash scripts/setup_<기능>.sh`
- 실패한 모듈이 있어도 나머지 모듈은 계속 진행하고, 끝에 모듈별 결과(OK/SKIP/FAIL) 요약을 보여줌
- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함 (모듈별 확인 기준은 아래 각 기능의 "다시 실행 시" 참고)
- 로그: `~/silent_sdk/logs/raspberrypi4-2gb-<시각>/setup.log`

처음 설치 순서:
1. 전체 Setup 실행 → Docker 설치, DVB 드라이버 차단, `docker/flight_feeder/.env` 생성 (ADS-B 피더는 SKIP)
2. 재부팅 후 `.env`에 안테나 위치(`FEEDER_LAT`, `FEEDER_LONG`, `FEEDER_ALT_M`) 입력 → 다시 실행하면 ultrafeeder만 시작
3. 아래 "서비스 키 발급"으로 키를 받아 `.env`에 입력 → 다시 실행하면 키가 있는 피더가 시작


### docker

- Setup: [scripts/setup_docker.sh](scripts/setup_docker.sh)
  - 다시 실행 시: `docker.io`, `docker-compose` 패키지가 설치돼 있고 사용자가 docker 그룹에 있으면 건너뜀
- OS 기본 저장소의 `docker.io`, `docker-compose`(v2)를 설치하고, sudo 없이 쓰도록 사용자를 docker 그룹에 추가함 (다시 로그인 후 적용)


### DVB 드라이버 차단

- Setup: [scripts/setup_dvb_blacklist.sh](scripts/setup_dvb_blacklist.sh) (적용하려면 재부팅 필요)
  - 다시 실행 시: `/etc/modprobe.d/exclusions-rtl2832.conf` 내용이 같으면 건너뜀
- 호스트 커널이 RTL-SDR 동글을 TV 수신기로 먼저 잡지 않게 해서 ultrafeeder 컨테이너가 동글을 쓸 수 있게 함
- 차단하지 않으면 ultrafeeder 로그에 `usb_claim_interface error -6`, `Device or resource busy`가 나옴
- 참고: [Blacklist Kernel Modules](https://sdr-enthusiasts.gitbook.io/ads-b/setting-up-rtl-sdrs/blacklist-kernel-modules)


### ADS-B 피더

- Setup: [scripts/setup_flight_feeder.sh](scripts/setup_flight_feeder.sh)
  - 다시 실행 시: ultrafeeder와 키가 있는 피더가 모두 실행 중이면 건너뜀
  - `.env`가 없으면 `.env.example`을 복사해 만들고 건너뜀, 위치가 비었거나 형식이 틀려도 건너뜀
  - 키가 빈 피더는 실행하지 않고 경고만 출력함
- 필요한 장비: RTL-SDR USB 동글 1개, 1090MHz 안테나
- 설정: `docker/flight_feeder/.env` ([.env.example](docker/flight_feeder/.env.example) 참고, git에 올라가지 않음)
- compose 파일: [docker/flight_feeder/docker-compose.yml](docker/flight_feeder/docker-compose.yml) ([sdr-enthusiasts](https://sdr-enthusiasts.gitbook.io/ads-b) 컨테이너)
- `.env`를 고친 뒤 실행 중인 컨테이너에 반영하려면: `sudo docker compose -f ~/silent_sdk/devices/raspberrypi4-2gb/docker/flight_feeder/docker-compose.yml up -d`

```text
RTL-SDR 동글 → ultrafeeder (수신·디코딩, 지도) ─ BEAST 30005 ─┬─ fr24feed    → Flightradar24
                                                              ├─ piaware     → FlightAware
                                                              ├─ airnavradar → AirNav Radar
                                                              └─ planefinder → Plane Finder
```

| 컨테이너 | 웹 페이지 | 피더 혜택 |
|---|---|---|
| ultrafeeder | `http://<IP>:8080` (tar1090 지도) | - |
| fr24feed | `http://<IP>:8754` (상태) | Contributor 플랜 (피드 시작 후 자동) |
| piaware | `http://<IP>:8081` (SkyAware) | Enterprise 계정 (자동) |
| airnavradar | - | Business 계정 (24시간 안에 자동) |
| planefinder | `http://<IP>:30053` | Premium (Plane Finder 팀에 요청) |


#### 서비스 키 발급

Flightradar24 (`FR24KEY`): [flightradar24.com](https://www.flightradar24.com/)에 가입한 뒤 아래를 실행하고, 마지막에 나오는 sharing key를 입력
- 질문 답: 가입한 이메일, sharing key는 비워 둠, MLAT `no`, receiver type `4`, connection type `1`, host `127.0.0.1`, port `30005`, Step 5의 두 질문 `no`
- 계정당 피더 3개까지
```bash
sudo docker run -it --rm --entrypoint /usr/bin/fr24feed ghcr.io/sdr-enthusiasts/docker-flightradar24:latest --signup --configfile=/tmp/config.txt
```

FlightAware (`PIAWARE_FEEDER_ID`): 아래 출력의 `my feeder ID is <ID>`를 입력하고, 피더 시작 후 [PiAware claim](https://flightaware.com/adsb/piaware/claim)에서 계정에 등록
- MLAT을 쓰려면 FlightAware My ADS-B 통계 페이지에서 수신기 위치도 설정해야 함
```bash
timeout 30 sudo docker run --rm ghcr.io/sdr-enthusiasts/docker-piaware:latest | grep "my feeder ID"
```

AirNav Radar (`AIRNAVRADAR_SHARING_KEY`): ultrafeeder가 실행 중일 때 아래를 실행(최대 5분)하고 로그에 나오는 sharing key를 입력, 피더 시작 후 [AirNav Radar claim](https://www.airnavradar.com/raspberry-pi/claim)에서 계정에 등록
```bash
timeout 300s sudo docker run --rm -it --network flight_feeder_default \
    -e BEASTHOST=ultrafeeder -e LAT=<위도> -e LONG=<경도> -e ALT=<고도m> \
    ghcr.io/sdr-enthusiasts/docker-airnavradar:latest
```

Plane Finder (`PLANEFINDER_SHARECODE`): [Create Sharecode](https://planefinder.net/sharing/create-sharecode)에서 발급, 무료 Premium은 Plane Finder 팀에 요청해야 함
