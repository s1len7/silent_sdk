# silent_sdk

플랫폼별 기본 설정 자동화

| 플랫폼 | 대상 | 문서 |
|---|---|---|
| windows | Windows 10 이상 데스크탑 | [windows/README.md](windows/README.md) |
| raspberrypi4 | Raspberry Pi 4, Raspberry Pi OS Trixie 이상 | [raspberrypi4/README.md](raspberrypi4/README.md) |
| titan-s260 | SAM4S TITAN-S260 POS, Windows 10 IoT LTSC | [titan-s260/README.md](titan-s260/README.md) |
| byt-t1 | PEGATRON BYT-T1 Mini-ITX 보드 (Intel Pentium J2900) | [byt-t1/README.md](byt-t1/README.md) |


## 전체 설치

Windows (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/setup.ps1 | iex
```

TITAN-S260 (PowerShell):
```powershell
irm https://raw.githubusercontent.com/s1len7/silent_sdk/main/titan-s260/setup.ps1 | iex
```

Raspberry Pi 4:
```
(command -v git >/dev/null || (sudo apt-get update && sudo apt-get install -y git)) && git clone https://github.com/s1len7/silent_sdk.git ~/silent_sdk && sudo bash ~/silent_sdk/raspberrypi4/scripts/setup.sh
```


## 개발

- 작성 원칙: [CLAUDE.md](CLAUDE.md) 참고 (공통 규칙은 [vibecoding](vibecoding) 서브모듈의 CLAUDE.md)
- 개발 PC에서 클론할 때는 서브모듈도 함께 받음: `git clone --recurse-submodules ...` 또는 클론 후 `git submodule update --init`
