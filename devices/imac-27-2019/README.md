# imac-27-2019

- 제조사: [Apple](https://www.apple.com/)
- 모델명: iMac (Retina 5K, 27-inch, 2019), 모델 식별자 iMac19,1
- 지원OS: macOS Sequoia 15
- 작성 원칙: [AGENTS.md](AGENTS.md) 참고 (공통 규칙은 [상위 AGENTS.md](../../AGENTS.md))

| 항목 | 사양 |
| --- | --- |
| CPU | Intel Core i5 6코어, 3.1GHz |
| RAM | 32GB |
| GPU | AMD Radeon Pro 575X (VRAM 4GB) |
| 디스플레이 | 27형 Retina 5K (5120 x 2880) |
| 저장장치 | SSD 512GB |
| 무선 | Wi-Fi 802.11ac |


## 기능

- 전체 Setup: 터미널에서 이 한 줄만 실행 ([setup.sh](setup.sh)). 파일 없이 실행하면 저장소를 `~/silent_sdk`에 받은 뒤(이미 받았으면 `git pull`) 그 안의 `setup.sh`로 전체 설치:

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/imac-27-2019/setup.sh | bash
```

- 다시 실행: 이미 받았으면 `bash ~/silent_sdk/devices/imac-27-2019/setup.sh` (이미 설정된 모듈은 건너뛰고, 실패·누락된 부분만 진행)
- 로그: `logs/imac-27-2019-<yyyyMMdd-HHmmss>/setup.log`
- 이미 설치돼 있는 프로그램 (setup으로 설치하지 않음)
  - Git (`/usr/local/bin/git`)
  - Visual Studio Code (`/Applications/Visual Studio Code.app`, `code` 명령 사용 가능)

### git

- Setup: [scripts/setup_git.sh](scripts/setup_git.sh) (전역 `user.name=silent`, `user.email`은 GitHub noreply 주소로 설정)
- 다시 실행 시: `user.name`·`user.email`이 모두 같으면 건너뜀. 다르거나 빠진 값만 설정

### claude code

- Setup: [scripts/setup_claude_code.sh](scripts/setup_claude_code.sh) (공식 네이티브 설치 스크립트로 `~/.local/bin/claude`에 설치, 원본 [config/claude-settings.json](config/claude-settings.json)의 키와 저장소 경로(`permissions.additionalDirectories`)를 `~/.claude/settings.json`에 넣음, 다른 키는 그대로 둠)
- 다시 실행 시: `claude` 명령이 있고 설정이 모두 같으면 건너뜀. 설치만 돼 있으면 설정만 적용

### scroll direction

- Setup: [scripts/setup_scroll_direction.sh](scripts/setup_scroll_direction.sh) (마우스·트랙패드의 "자연스러운 스크롤"을 꺼서 Windows와 같은 방향으로 스크롤, 로그아웃 후 다시 로그인해야 적용됨)
- 다시 실행 시: 자연스러운 스크롤이 이미 꺼져 있으면 건너뜀
