# silent_sdk

장비별 기본 설정 자동화

| 장비 | 대상 | 문서 |
|---|---|---|
| windows | Windows 10 이상 데스크탑 | [devices/windows/README.md](devices/windows/README.md) |
| raspberrypi4 | Raspberry Pi 4, Raspberry Pi OS Trixie 이상 | [devices/raspberrypi4/README.md](devices/raspberrypi4/README.md) |
| titan-s260 | SAM4S TITAN-S260 POS, Windows 10 IoT LTSC | [devices/titan-s260/README.md](devices/titan-s260/README.md) |
| byt-t1 | PEGATRON BYT-T1 Mini-ITX 보드 (Intel Pentium J2900), Ubuntu Server LTS | [devices/byt-t1/README.md](devices/byt-t1/README.md) |


## 구조

```text
silent_sdk/
├─ devices/          장비별 폴더 (각 폴더에 README.md, CLAUDE.md, 설치 스크립트)
│  ├─ windows/       Windows 공통 스크립트 (titan-s260도 사용)
│  ├─ titan-s260/
│  ├─ raspberrypi4/
│  └─ byt-t1/
├─ logs/             설치 로그 (git에는 올라가지 않음)
├─ vibecoding/       공통 CLAUDE.md 규칙 (서브모듈)
└─ CLAUDE.md
```


## 전체 설치

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/windows/setup.ps1 | iex
```

TITAN-S260 (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/titan-s260/setup.ps1 | iex
```

Raspberry Pi 4:
```bash
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/devices/raspberrypi4/scripts/setup.sh
```


## 개발

- 작성 원칙: [CLAUDE.md](CLAUDE.md) 참고 (공통 규칙은 [vibecoding](vibecoding) 서브모듈의 CLAUDE.md)
- 개발 PC에서 클론할 때는 서브모듈도 함께 받음: `git clone --recurse-submodules ...` 또는 클론 후 `git submodule update --init`
