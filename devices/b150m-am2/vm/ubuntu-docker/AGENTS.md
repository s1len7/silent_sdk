> 이 파일의 규칙은 [b150m-am2 장비 규칙](../../AGENTS.md)과 [공통 규칙](../../../../AGENTS.md)에 더해 적용됨 (둘 다 함께 읽고 따를 것)

## ubuntu-docker VM 전용

- VM 사양·접속 방법·TODO는 이 폴더의 README.md에 정리하고, AGENTS.md에는 AI 에이전트에게 주는 지시만 둘 것
- Docker로 돌리는 서비스 하나당 `projects/<서비스>/compose.yaml` 하나로 두고, `scripts/setup_<서비스>.sh`가 `/srv/docker/<서비스>/`에 복사해 실행할 것
  - 데이터는 `/srv/docker/<서비스>/` 아래에 두고 저장소에는 넣지 않을 것
  - 비밀번호·토큰은 compose에 직접 쓰지 말고 `/srv/docker/<서비스>/.env`에 두고 `${변수}`로 읽을 것 (저장소에는 값이 빈 `.env.example`만 둠)
