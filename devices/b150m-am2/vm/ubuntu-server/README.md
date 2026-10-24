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
  - 다시 실행 시: Gateway 서비스 파일이 있고, 랜 공개(`gateway.bind=lan`)이고, 기본 모델이 OpenRouter 무료 라우터이고, `.env`에 값이 있으면 OpenRouter 키·리버스 프록시 설정도 돼 있을 때 건너뜀
- 설정: `.env` ([.env.example](.env.example) 참고, git에 올라가지 않음)
  - `OPENROUTER_API_KEY`: OpenRouter API 키
  - `OPENCLAW_TRUSTED_PROXY`, `OPENCLAW_PUBLIC_ORIGIN`: 리버스 프록시 IP와 외부 https 주소 (프록시로 `wss://` 주소를 쓸 때만)
- Gateway는 랜에 열려 있음 (`ws://192.168.0.22:18789`, token 인증)
- 데스크탑 OpenClaw 트레이 앱 연결: 새 연결에 Gateway URL과 공유 토큰을 넣음
  - Gateway URL: 리버스 프록시를 쓰면 `wss://<OPENCLAW_PUBLIC_ORIGIN의 호스트>`, 아니면 `ws://192.168.0.22:18789`
  - 공유 토큰 확인 (`openclaw config get`은 값을 가려서 보여 주므로 설정 파일에서 읽음):

```bash
ssh silent@192.168.0.22 "python3 -c \"import json,os;print(json.load(open(os.path.expanduser('~/.openclaw/openclaw.json')))['gateway']['auth']['token'])\""
```

  - 연결 후 승인 대기가 뜨면 VM에서 `openclaw devices list` → `openclaw devices approve <요청 ID>`


### OpenClaw 텔레그램

- Setup: [scripts/setup_openclaw_telegram.sh](scripts/setup_openclaw_telegram.sh) (텔레그램 봇으로 OpenClaw와 대화, 허용 ID 한 명만, 그룹 대화 꺼짐)
  - 다시 실행 시: `.env`에 봇 토큰·허용 ID가 없거나, 토큰 파일과 채널 설정이 같으면 건너뜀
- 설정: `.env`의 `TELEGRAM_BOT_TOKEN`, `TELEGRAM_ALLOW_FROM` ([.env.example](.env.example) 참고)
- 상태 확인: `openclaw channels status`
