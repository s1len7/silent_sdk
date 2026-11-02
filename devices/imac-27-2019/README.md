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


## 단축키

macOS 기본 단축키 (Windows 키보드를 쓰면 `Command` = Windows 키, `Option` = Alt)

| 기능 | macOS | Windows에서는 |
| --- | --- | --- |
| 화면 잠금 | `Control` + `Command` + `Q` | `Win` + `L` |
| 로그아웃 (확인 창) | `Shift` + `Command` + `Q` | |
| 로그아웃 (바로) | `Option` + `Shift` + `Command` + `Q` | |
| 검색 (Spotlight) | `Command` + `Space` | `Win` + `S` |
| 한/영 전환 | `Control` + `Space` (설정에 따라 `Caps Lock`) | `한/영` |
| 앱 전환 | `Command` + `Tab` | `Alt` + `Tab` |
| 앱 종료 | `Command` + `Q` | `Alt` + `F4` |
| 강제 종료 | `Option` + `Command` + `Esc` | `Ctrl` + `Shift` + `Esc` |
| 스크린샷 (전체 / 영역 / 도구) | `Shift` + `Command` + `3` / `4` / `5` | `Win` + `Shift` + `S` |


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

### hangul input

- Setup: [scripts/setup_hangul_input.sh](scripts/setup_hangul_input.sh) (macOS 기본 한글 입력기의 두벌식을 입력 소스에 추가, 기존 입력 소스는 그대로 둠. 메뉴 막대에 바로 나타나지 않으면 로그아웃 후 다시 로그인해야 적용됨)
- 다시 실행 시: 두벌식 입력 소스가 이미 있으면 건너뜀

### nodejs

- Setup: [scripts/setup_nodejs.sh](scripts/setup_nodejs.sh) (Node.js 최신 LTS를 [nodejs.org](https://nodejs.org/) 공식 압축 파일로 관리자 권한 없이 `~/.local/node`에 설치하고, `node`·`npm`·`npx`를 `~/.local/bin`에 링크. OpenCode 설치에 필요)
- 다시 실행 시: `~/.local/node`에 Node.js 20.18.1 이상이 있고 링크가 모두 있으면 건너뜀. 설치만 돼 있으면 링크만 다시 만듦

### opencode

- Setup: [scripts/setup_opencode.sh](scripts/setup_opencode.sh) (OpenCode CLI를 npm `opencode-ai` 최신으로 설치하고 `~/.local/bin/opencode`로 링크, 무료 기본 모델 `opencode/deepseek-v4.1-flash-free`와 대체 모델 플러그인·목록을 `~/.config/opencode/`에 설정, 다른 키는 그대로 둠)
- 다시 실행 시: `opencode` 명령이 있고 기본 모델·대체 모델 설정이 모두 같으면 건너뜀. 설치만 돼 있으면 설정만 적용
- 무료 `opencode/*` 모델은 로그인이 필요 없음. 공용 장비이므로 API 키는 설정하지 않음
