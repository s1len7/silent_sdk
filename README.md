# 목적

라즈베리파이4에 OS를 설치한 뒤 하는 기본 셋팅을 자동화함

- 대상 OS: Raspberry Pi OS Trixie 이상

## 작성 원칙

- README.md를 포함해 불필요한 수정은 최대한 피함
- 모든 구현은 오캄의 면도날(Occam's razor)에 따라 가능한 한 간단하게 함
- 주석은 한글, 콘솔 출력 메시지는 모두 영어로 작성함
- 스크립트는 기능별 모듈로 나누고, 모듈 전체를 한 번에 설치할 수도 있게 함


# 전체 설치

순정 OS 클린설치 직후 한 번에 설치 (git이 없으면 설치 → 저장소 클론 → 전체 설치):
```
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/<GITHUB_USER>/raspberrypi4.git ~/raspberrypi4 && sudo bash ~/raspberrypi4/scripts/setup.sh
```

이미 클론되어 있으면: `sudo bash scripts/setup.sh` — scripts/setup_*.sh 모듈을 모두 실행


# 기능

## 전원 끄기 버튼

자동화: `sudo bash scripts/setup_power_button.sh` (적용하려면 재부팅 필요)

- 일반 데스크탑 PC처럼 버튼으로 전원을 끔
- `/boot/firmware/config.txt`에 아래 줄을 추가함. 이미 있으면 추가하지 않음
- 배선: 37번 핀(GPIO26) - 버튼 - 39번 핀(GND)
```
dtoverlay=gpio-shutdown,gpio_pin=26
```


## 부팅 완료 비프음

자동화: `sudo bash scripts/setup_boot_beep.sh`

- 능동 부저(High level trigger 모듈) 배선: I/O - 18번(GPIO24), VCC - 2번(5V), GND - 20번


## SFTP 활성화

자동화: `sudo bash scripts/setup_sftp.sh`

수동 설정 방법:
- 터미널에서 `sudo raspi-config` 실행
- 메뉴: Interface Options → SSH 선택
- SSH 서버를 켤지 묻는 질문에 Yes(Enable) 선택 후 종료
- 서비스 시작:
```
sudo systemctl enable ssh
sudo systemctl start ssh
```

- 클라이언트 연결: FileZilla 같은 프로그램에서 호스트(`sftp://라즈베리파이_IP`), 사용자명, 비밀번호, 포트(22)를 입력해 접속


## 화면보호기 / 화면 끄기

자동화: `sudo bash scripts/setup_screen_blanking.sh`


## htop 자동실행

자동화: `sudo bash scripts/setup_htop_autostart.sh`

- `~/.config/autostart/htop.desktop` 설정 파일로 부팅 시 자동실행


## toggle_rotate

자동화: `sudo bash scripts/setup_auto_rotate.sh`

라즈베리파이 OS에서 화면과 터치를 180도 회전하는 프로그램

요구사항:
1. Trixie, labwc에서 동작
2. DSI-1에만 적용
3. 실행할 때마다 기본 → 180도 → 기본으로 번갈아 회전
4. 화면과 터치 좌표가 함께 회전
5. 최종 결과물은 Python 프로그램 (테스트는 셸에서 해도 됨)

수동 설치/실행:
```
sudo apt install wlr-randr
python3 toggle_rotate/toggle_rotate.py
```


### 라즈베리파이4 + 7인치 공식 디스플레이 자동회전

- 목표: 화면을 뒤집으면 화면과 터치가 자동으로 180도 회전
- 센서: SW-520D, SIGNAL - 17번 핀

| orientation | 화면 상단 | 회전 |
|---|---|---|
| 0 | 위 | 0도 |
| 1 | 아래 | 180도 |

설치 위치:
- `~/toggle_rotate/auto_rotate.py`
- `~/.config/autostart/auto_rotate.desktop`


## docker

자동화: `sudo bash scripts/setup_docker.sh`

```
sudo apt-get update
sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
```

설치 후 동작 확인: `sudo docker run hello-world`를 실행해 정상 작동하는지 확인함

권한 설정 (선택): `sudo usermod -aG docker $USER`를 실행하면 매번 sudo 없이 도커를 쓸 수 있음


### portainer

자동화: `sudo bash scripts/setup_docker.sh` (docker 설치에 포함)

```
docker run -d \
  -p 9001:9001 \
  --name portainer_agent \
  --restart=always \
  -v /var/run/docker.sock:/var/run/docker.sock \
  -v /var/lib/docker/volumes:/var/lib/docker/volumes \
  -v /:/host \
  portainer/agent:2.39.4
```


### dozzle

자동화: `sudo bash scripts/setup_dozzle.sh`

<!-- portainer > docker-compose.yml -->
compose 파일: `docker/dozzle/docker-compose.yml`


### Magic Mirror & MMPM

자동화: `sudo bash scripts/setup_magic_mirror.sh`

한글 폰트: `sudo apt install fonts-nanum fonts-nanum-extra`
<!-- portainer > docker-compose.yml -->
compose 파일: `docker/magic_mirror/docker-compose.yml`


### theengs-gateway

자동화: `sudo bash scripts/setup_theengs_gateway.sh`

<!-- portainer -> docker-compose.yml -->
compose 파일: `docker/theengs-gateway/docker-compose.yml`


## shairport-sync

자동화: `sudo bash scripts/setup_shairport_sync.sh`

`sudo apt install shairport-sync`
- 설치하면 재부팅 시 자동실행됨


## uxplay

자동화: `sudo bash scripts/setup_uxplay.sh`

`sudo apt install uxplay`
- `~/.config/autostart/uxplay.desktop` 설정 파일로 자동실행


<!-- 여기까지 진행 -->
<!-- 
# 진행 예정

## duplicati


## openvoiceos

`.config/mycroft/mycroft.conf`


## openclaw
 -->
