> 이 파일의 규칙은 [desktop 규칙](../desktop/AGENTS.md)과 [공통 규칙](../../AGENTS.md)에 더해 적용됨 (둘 다 함께 읽고 따를 것)

## titan-s260 전용

- 대상: SAM4S TITAN-S260 POS (Intel Celeron N3160, 15" 1024x768 터치), Windows 10 IoT LTSC
  - LTSC라 winget과 Store가 기본으로 없음
  - 저사양이므로 상주 프로그램과 무거운 설치는 피할 것
- titan 전용 스크립트만 `devices/titan-s260/scripts/`에 두고, 공통 기능은 `devices/desktop/scripts/`의 스크립트를 `devices/titan-s260/setup.ps1`에서 호출할 것
