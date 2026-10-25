> 이 파일의 규칙은 [공통 규칙](../../AGENTS.md)에 더해 적용됨 (공통 규칙도 함께 읽고 따를 것)

## ds218plus 전용

- CLI로 한 모든 작업은 DSM GUI에서 문제가 없을 것
  - CLI로 만들거나 바꾼 Container Manager 프로젝트·컨테이너는 DSM의 Container Manager 화면에서도 그대로 보이고, 화면에서 시작·중지·수정할 수 있어야 함
  - DSM이 관리하는 파일·설정을 CLI로 직접 고쳐 DSM 화면과 실제 상태가 어긋나게 하지 말 것
- 대상: Synology DS218+ (Intel Celeron J3355 2코어, RAM 12GB(기본 2GB에서 업그레이드), 2베이), DSM 7
- 용도: Container Manager(Docker) 프로젝트 관리
  - 장비 재설치 자동화보다 Container Manager 프로젝트의 생성·수정·업데이트를 중심으로 할 것
  - 프로젝트 하나당 `projects/<프로젝트>/` 폴더 하나로 두고, `compose.yaml`과 값이 빈 `.env.example`을 함께 둘 것
  - NAS의 프로젝트 위치는 `/volume1/docker/<프로젝트>`로 통일할 것
- 제어는 저장소를 받은 PC에서 ssh(키 인증)로 NAS에 접속해 실행할 것
  - 비밀번호를 묻는 대화형 입력 없이 실행되게 할 것 (ssh `BatchMode=yes`)
  - 이미지 업데이트는 `docker compose pull` 후 `up -d`로 하고, 바뀐 것이 없으면 SKIP할 것
- DSM 설정(공유 폴더, 사용자, 권한 등)은 스크립트로 바꾸지 말 것
- 예외: 재설치 자동화가 목적이 아니므로 전체 설치 진입점(`setup`)을 두지 않음
