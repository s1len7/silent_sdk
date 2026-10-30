# generic-ubuntu

제조사/모델: 임의 Linux PC (빌려쓰는 PC용)
지원 OS: Ubuntu/Debian 계열
사양: 최소 사양 (AI 코딩 CLI 설치용)

## 기능

- Setup: [setup.sh](setup.sh) (전체 모듈 실행)
- 파일 없이 실행하면 git을 설치하고 저장소를 `~/silent_sdk`에 받은 뒤(이미 받았으면 `git pull`) 그 안의 `setup.sh`를 실행
- 이미 클론되어 있으면: `bash ~/silent_sdk/devices/generic-ubuntu/setup.sh`
- 다시 실행 시: 이미 설정된 모듈은 건너뛰고, 실패/누락된 부분만 진행
- 로그: `logs/generic-ubuntu-<yyyyMMdd-HHmmss>/` (`setup.log`, `*-install.log`)

### git
- Setup: [scripts/setup_git.sh](scripts/setup_git.sh) (사용자 범위 위주 설정)
- 다시 실행 시: git 설치 및 사용자 정보 설정 여부 확인

### vscode
- Setup: [scripts/setup_vscode.sh](scripts/setup_vscode.sh) (가능하면 사용자 단위로 설치)
- 다시 실행 시: `code` 명령 사용 가능 여부 확인

### opencode
- Setup: [scripts/setup_opencode.sh](scripts/setup_opencode.sh) (OpenCode CLI, 사용자 범위 우선)
- 다시 실행 시: `opencode` 명령 사용 가능 여부 확인

### korean-input
- Setup: [scripts/setup_korean_input.sh](scripts/setup_korean_input.sh) (Ubuntu 한글 입력: 빠진 패키지만 설치 후 입력 소스에 hangul 추가)
- 다시 실행 시: ibus/ibus-hangul/fonts-nanum 설치 여부와 GNOME 입력 소스(`org.gnome.desktop.input-sources`)에 hangul이 있는지 확인

```bash
curl -fsSL https://raw.githubusercontent.com/s1len7/silent_sdk/main/devices/generic-ubuntu/setup.sh | bash
```

## 반납 전 정리 (Cleanup)

설치된 프로그램(git, VS Code, OpenCode CLI 등)은 유지하고, `silent_sdk` 저장소와 개인/비공개 정보(`.env`, GitHub 토큰 파일 `~/.gh_token`)만 정리합니다.

```bash
# 저장소 외부에서 실행 권장
cd ..
./silent_sdk/devices/generic-ubuntu/setup.sh --cleanup

# 실제 삭제 없이 확인만
./silent_sdk/devices/generic-ubuntu/setup.sh --cleanup --dry-run

# 확인 없이 강제 실행 (주의)
./silent_sdk/devices/generic-ubuntu/setup.sh --cleanup --force
```

주의: 저장소 루트 전체를 삭제합니다. 본 스크립트는 설치된 패키지는 제거하지 않습니다.

