# ubuntu-server

- 호스트: [b150m-am2](../../README.md) (Proxmox VE 9)의 VM
- 지원OS: [Ubuntu Server 24.04 LTS](https://ubuntu.com/server) (공식 cloud 이미지)
- 용도: [OpenClaw](https://docs.openclaw.ai/install) 서버
- 작성 원칙: [장비 CLAUDE.md](../../CLAUDE.md) 참고 (공통 규칙은 [상위 CLAUDE.md](../../../../CLAUDE.md))

| 항목 | 사양 |
| --- | --- |
| VM 번호 | 100 |
| CPU | 2코어 (host 타입) |
| RAM | 2048MB |
| 디스크 | 32GB (local-lvm) |
| 네트워크 | vmbr0 (유선 브리지), DHCP (현재 192.168.0.22) |
| 계정 | silent (SSH 키 로그인, 비밀번호 없이 sudo) |


## 기능

- 전체 Setup: 호스트의 [Ubuntu VM 생성](../../README.md#ubuntu-vm-생성-호스트)으로 만든 VM은 첫 부팅 때 [setup_vm.sh](setup_vm.sh)가 자동으로 실행됨. 직접 실행하려면 VM 안에서:

```bash
sudo bash ~/silent_sdk/devices/b150m-am2/vm/ubuntu-server/setup_vm.sh
```

- 다시 실행: 같은 명령을 다시 실행하면 이미 설정된 모듈은 SKIP하고, 실패했거나 안 된 모듈만 다시 진행함
- 로그: `~/silent_sdk/logs/b150m-am2-ubuntu-server-<시각>/setup.log`
- 모듈별 자세한 설명은 [장비 README](../../README.md)의 `(VM)` 기능 참고


### OpenClaw

- Setup: [scripts/setup_openclaw.sh](scripts/setup_openclaw.sh) (공식 설치 스크립트로 설치, Gateway가 부팅 시 실행되도록 linger 켬)
  - 다시 실행 시: 사용자에게 `openclaw` 명령이 있고 systemd linger가 켜져 있으면 건너뜀
- 업데이트: `npm i -g openclaw@latest` (sudo 없이)


### OpenClaw 온보딩

- Setup: [scripts/setup_openclaw_onboard.sh](scripts/setup_openclaw_onboard.sh) (Gateway 서비스 등록, 기본 모델 `openrouter/openrouter/free`)
  - 다시 실행 시: Gateway 서비스 파일이 있고, 기본 모델이 OpenRouter 무료 라우터이고, `OPENROUTER_API_KEY`가 있으면 OpenRouter 키도 등록돼 있을 때 건너뜀
- OpenRouter API 키: `.env`의 `OPENROUTER_API_KEY` ([.env.example](.env.example) 참고, git에 올라가지 않음)
- Gateway는 VM 안에서만 열림 (`ws://127.0.0.1:18789`, token 인증). 데스크탑에서는 SSH 터널로 접속:

```bash
ssh -N -L 18790:127.0.0.1:18789 silent@192.168.0.22
```

  - 터널을 연 동안 웹 대시보드 `http://127.0.0.1:18790`, Gateway `ws://127.0.0.1:18790` (데스크탑의 18789는 데스크탑 자체 Gateway가 사용)
  - 토큰 확인: `ssh silent@192.168.0.22 "bash -lc 'openclaw config get gateway.auth.token'"`


## TODO

- OpenRouter API 키 등록 (무료)
  1. https://openrouter.ai/keys 에서 발급
  2. VM에서 `cd ~/silent_sdk/devices/b150m-am2/vm/ubuntu-server && cp .env.example .env && nano .env` → `OPENROUTER_API_KEY=`에 입력
  3. `sudo bash scripts/setup_openclaw_onboard.sh`
- 데스크탑 companion을 VM과 연동
  1. 트레이 앱 → Connections → SSH 터널: 사용자 `silent`, 호스트 `192.168.0.22`, 원격 포트 `18789`, 로컬 포트 `18790`
  2. 위의 토큰 확인 명령으로 토큰 입력
  3. pairing 요청이 뜨면 VM에서 `openclaw devices list` → `openclaw devices approve <id>`
- 다시 생각해볼 것
  - Gateway를 랜(`192.168.0.22:18789`)에 바로 열지, 지금처럼 SSH 터널로 쓸지
  - 유선이 끊겼을 때 호스트 Wi-Fi(192.168.0.25)로 SSH 접속: 지금(DHCP)은 안 됨 → `setup_wifi.sh`의 `WIFI_IP`(고정 IP) 옵션을 적용할지 ([장비 README](../../README.md#wi-fi-호스트) 참고, 테스트 VM에서 검증됨)
  - 유선이 끊겨도 VM이 인터넷 쓰기: Wi-Fi는 브리지 불가 → VM을 NAT 브리지(`vmbr1`)로 옮길지 (VM 랜 IP는 없어짐)
    - 옮기면 vmbr0에 VM 포트가 없어져서, `ignore_routes_with_linkdown=1`을 더하면 케이블이 빠졌을 때 호스트가 Wi-Fi로 넘어감 (테스트 VM에서 호스트 쪽 확인됨, NAT는 아직 시험 안 함)
