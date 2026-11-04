# imac-27-2019

- 제조사: [Apple](https://www.apple.com/)
- 모델명: iMac (Retina 5K, 27-inch, 2019), 모델 식별자 iMac19,1
- 지원OS: macOS Sequoia 15
- 제약: 이 장비는 `sudo` 권한을 받을 수 없어 모든 Setup과 모듈은 관리자 권한 없이 사용자 계정으로 실행함
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
| 같은 앱의 창 전환 (VSCode 등) | `Command` + `` ` `` | `Alt` + `` ` `` |
| VSCode 탭 전환 | `Control` + `Tab` | `Ctrl` + `Tab` |
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
- 재부팅: 전체 Setup 끝에 재부팅. 모든 모듈이 OK면 묻지 않고 자동 재부팅, FAIL/SKIP이 하나라도 있으면 재부팅 여부를 물음(인터랙티브) 또는 안내만 출력(비대화형). sudo 없음 (`osascript`). 스크롤 방향·입력 소스 등은 재부팅/재로그인 후 적용됨
- 이미 설치돼 있는 프로그램 (setup으로 설치하지 않음)
  - Git (`/usr/local/bin/git`)
  - Visual Studio Code (`/Applications/Visual Studio Code.app`, `code` 명령 사용 가능)

### git

- Setup: [scripts/setup_git.sh](scripts/setup_git.sh) (전역 `user.name=silent`, `user.email`은 GitHub noreply 주소로 설정)
- 다시 실행 시: `user.name`·`user.email`이 모두 같으면 건너뜀. 다르거나 빠진 값만 설정

### shell path

- Setup: [scripts/setup_shell_path.sh](scripts/setup_shell_path.sh) (`~/.local/bin`을 `~/.zshrc`의 PATH에 추가해 `claude`·`node`·`opencode`를 새 터미널에서 바로 실행. 다른 내용은 그대로 둠)
- 다시 실행 시: `~/.zshrc`에 같은 PATH 줄이 있으면 건너뜀

### claude code

- Setup: [scripts/setup_claude_code.sh](scripts/setup_claude_code.sh) (공식 네이티브 설치 스크립트로 `~/.local/bin/claude`에 설치, 원본 [config/claude-settings.json](config/claude-settings.json)의 키와 저장소 경로(`permissions.additionalDirectories`)를 `~/.claude/settings.json`에 넣음, 다른 키는 그대로 둠)
- 다시 실행 시: `claude` 명령이 있고 설정이 모두 같으면 건너뜀. 설치만 돼 있으면 설정만 적용

### scroll direction

- Setup: [scripts/setup_scroll_direction.sh](scripts/setup_scroll_direction.sh) (마우스·트랙패드의 "자연스러운 스크롤"을 꺼서 Windows와 같은 방향으로 스크롤, 로그아웃 후 다시 로그인해야 적용됨)
- 다시 실행 시: 자연스러운 스크롤이 이미 꺼져 있으면 건너뜀

### hangul input

- Setup: [scripts/setup_hangul_input.sh](scripts/setup_hangul_input.sh) (macOS 기본 한글 입력기의 두벌식을 입력 소스에 추가, 입력 방법과 입력 모드 항목을 모두 넣고 입력 메뉴를 다시 시작해 바로 반영. 기존 입력 소스는 그대로 둠. 메뉴 막대에 나타나지 않으면 로그아웃 후 다시 로그인)
- 다시 실행 시: 두벌식 입력 방법과 입력 모드 항목이 모두 있으면 건너뜀. 빠진 항목만 추가

### dock apps

- Setup: [scripts/setup_dock_apps.sh](scripts/setup_dock_apps.sh) (Dock에 `Chrome`, `Terminal`, `VSCode`, `Discord` 바로가기를 이 순서로 추가하고, 기본으로 고정된 `Mail`, `TV`, `Music`, `Games`를 제거. 다른 Dock 항목은 그대로 둠. `Games`는 macOS Tahoe 26 이상에만 있음)
- 제거만: `bash scripts/setup_dock_apps.sh --remove` (`Mail`, `TV`, `Music`, `Games`만 제거, 다른 Dock 항목은 그대로 둠)
- 다시 실행 시: Dock 마지막 네 항목이 `Chrome`, `Terminal`, `VSCode`, `Discord` 순서이고 중복이 없으며 `Mail`, `TV`, `Music`, `Games`가 모두 없으면 건너뜀. 아니면 순서를 맞추고 네 앱을 제거. `--remove`는 네 앱이 모두 없으면 건너뜀

### finder home

- Setup: [scripts/setup_finder_home.sh](scripts/setup_finder_home.sh) (Finder의 새 윈도우 기본 위치를 홈 폴더(`~`)로 설정. 값을 바꾼 뒤 Finder를 다시 시작해 바로 적용하며, 열려 있던 Finder 창은 닫힘)
- 다시 실행 시: 새 윈도우 위치가 이미 홈 폴더면 건너뜀

### display brightness

- Setup: [scripts/setup_display_brightness_max.sh](scripts/setup_display_brightness_max.sh) (주 디스플레이인 내장 디스플레이의 밝기를 최대로 설정, 관리자 권한 불필요, 외장 디스플레이는 대상 아님)
- 다시 실행 시: 주 디스플레이 밝기가 이미 최대면 건너뜀

### true tone

- Setup: [scripts/setup_true_tone_off.sh](scripts/setup_true_tone_off.sh) (주변광에 따른 색온도 자동 보정인 True Tone을 끔, 관리자 권한 불필요, 사용자별 설정)
- 다시 실행 시: True Tone이 이미 꺼져 있거나 이 디스플레이가 지원하지 않으면 건너뜀

### night shift

- Setup: [scripts/setup_night_shift_off.sh](scripts/setup_night_shift_off.sh) (시간대에 따른 화면 색온도 자동 변경인 Night Shift를 끔, 관리자 권한 불필요, 사용자별 설정)
- 다시 실행 시: Night Shift가 이미 꺼져 있으면 건너뜀

### vscode auto update off

- Setup: [scripts/setup_vscode_auto_update_off.sh](scripts/setup_vscode_auto_update_off.sh) (VS Code 자동 업데이트 확인과 업데이트 안내 팝업을 끔. 사용자 설정 `settings.json`의 `update.mode`를 `none`으로 바꾸고 다른 설정은 그대로 둠. 이미 실행 중이면 VS Code를 다시 시작한 뒤 적용됨)
- 다시 실행 시: `update.mode`가 이미 `none`이면 건너뜀. `settings.json`에 주석이 있어 읽을 수 없으면 덮어쓰지 않고 실패

### nodejs

- Setup: [scripts/setup_nodejs.sh](scripts/setup_nodejs.sh) (Node.js 최신 LTS를 [nodejs.org](https://nodejs.org/) 공식 압축 파일로 관리자 권한 없이 `~/.local/node`에 설치하고, `node`·`npm`·`npx`를 `~/.local/bin`에 링크. OpenCode 설치에 필요)
- 다시 실행 시: `~/.local/node`에 Node.js 20.18.1 이상이 있고 링크가 모두 있으면 건너뜀. 설치만 돼 있으면 링크만 다시 만듦

### bitwarden cli

- Setup: [scripts/setup_bitwarden_cli.sh](scripts/setup_bitwarden_cli.sh) (공식 `@bitwarden/cli`를 사용자 범위에 설치하고 Vaultwarden 서버에 연결. 전체 Setup에서 Node.js 다음에 실행)
- 다시 실행 시: `bw`가 설치돼 있고 `.env`의 `VAULTWARDEN_URL`과 서버 설정이 같으면 건너뜀. `.env`가 없으면 예시에서 만들고 URL을 입력할 때까지 SKIP
- 설정: 첫 실행에서 만든 `.env`의 `VAULTWARDEN_URL`을 실제 HTTPS 주소로 바꿈. 예시 형식은 [.env.example](.env.example) 참고. `.env`는 Git에서 무시됨
- 금고 로그인/잠금 해제는 Tailscale 미연결 상태에서만 필요할 때 대화형으로 요청. 마스터 암호와 세션 키는 설정 파일이나 로그에 저장하지 않음

### opencode

- Setup: [scripts/setup_opencode.sh](scripts/setup_opencode.sh) (OpenCode CLI를 npm `opencode-ai` 최신으로 설치하고 `~/.local/bin/opencode`로 링크, 무료 기본 모델 `opencode/deepseek-v4.1-flash-free`와 대체 모델 플러그인·목록을 `~/.config/opencode/`에 설정, 다른 키는 그대로 둠)
- 다시 실행 시: `opencode` 명령이 있고 기본 모델·대체 모델 설정이 모두 같으면 건너뜀. 설치만 돼 있으면 설정만 적용
- 무료 `opencode/*` 모델은 로그인이 필요 없음. 공용 장비이므로 API 키는 설정하지 않음

### humanizer

- Setup: [scripts/setup_humanizer.sh](scripts/setup_humanizer.sh) ([blader/humanizer](https://github.com/blader/humanizer) 스킬을 `npx skills`로 전역 설치. Claude Code와 OpenCode에서 `/humanizer`로 사용, 다른 키는 그대로 둠)
- 다시 실행 시: `~/.agents/skills/humanizer/SKILL.md`가 있으면 건너뜀. 새 버전이 필요하면 `npx skills remove humanizer -g` 후 재실행

### discord

- Setup: [scripts/setup_discord.sh](scripts/setup_discord.sh) (Discord DMG를 받아 `~/Applications`에 설치하고, 자동 업데이트 확인을 꺼서 관리자 권한 헬퍼 설치 팝업이 뜨지 않게 함. 설정은 `~/Library/Application Support/discord/settings.json`의 `SKIP_HOST_UPDATE=true`, 다른 키는 그대로 둠. 관리자 권한 불필요)
- 다시 실행 시: `Discord.app`이 설치돼 있고 `SKIP_HOST_UPDATE`가 이미 `true`면 건너뜀. 설치만 돼 있으면 설정만 적용
- 참고: 자동 업데이트를 끄므로 새 버전은 직접 받아 설치해야 함. `/Applications`에 설치된 앱을 업데이트하려면 관리자 권한이 필요하며, Discord가 실행 중이면 설정 적용을 위해 다시 시작해야 함

### tailscale

- Setup: [scripts/setup_tailscale.sh](scripts/setup_tailscale.sh) (Mac App Store판 앱이 설치돼 있고 미연결 상태일 때 Vaultwarden의 `Tailscale Auth Key` 항목으로 연결. 미설치면 공식 [Tailscale 앱](https://apps.apple.com/app/tailscale/id1475387142) 링크를 안내)
- 다시 실행 시: 앱이 미설치됐거나 터미널이 없으면 건너뜀. 이미 연결돼 있으면 Vaultwarden을 열지 않고 건너뜀
- 키 준비: Vaultwarden에 `Tailscale Auth Key`라는 항목을 만들고 password 필드에 짧은 만료의 일회용 Tailscale 인증 키를 저장. 사용된 키는 자동 무효화되므로 다시 인증할 때 새 키로 교체
- 키는 `.env`에 복사하지 않으며, 연결 중 권한 제한 임시 파일로만 전달하고 삭제

### opencli

- Setup: [scripts/setup_opencli.sh](scripts/setup_opencli.sh) ([@jackwener/opencli](https://github.com/jackwener/opencli)를 npm으로 사용자 범위에 설치해 `opencli` 명령으로 사용, AI 에이전트용 스킬(opencli-browser 등)도 함께 전역 설치)
- 다시 실행 시: `opencli` 명령과 `~/.agents/skills/opencli-browser/SKILL.md`가 모두 있으면 건너뜀. 빠진 부분만 설치

### codyssey proxy

- Setup: [scripts/setup_codyssey_proxy.sh](scripts/setup_codyssey_proxy.sh) (Codyssey 게이트웨이 앞단의 통합 프록시, `~/.codyssey-proxy/`에 설치)
  - `~/.codyssey-proxy/.env`가 없으면 예시 파일을 복사하고 건너뜀 (CODYSSEY_OPENAI_API_KEY 채운 뒤 재실행)
  - `CODYSSEY_OPENAI_API_KEY`가 비어 있으면 건너뜀
  - Python 3가 없으면 실패
  - `tools/codyssey-proxy`를 pip으로 editable 설치, `~/.claude/settings.json`을 프록시 주소(`http://localhost:8082`)로 갱신
  - LaunchAgent(`com.silent.codyssey-proxy`) 등록으로 자동 시작, 즉시 실행
  - 재실행 시: 키가 있고 설정이 같으면 LaunchAgent 재로드 후 상태 확인
