# Synology DS218+

- 제조사: [시놀로지(Synology)](https://www.synology.com/)
- 모델명: DiskStation DS218+
  - [데이터시트](https://global.download.synology.com/download/Document/Hardware/DataSheet/DiskStation/18-year/DS218+/enu/Synology_DS218_Plus_Data_Sheet_enu.pdf)
- 지원OS: DSM 7.4

| 항목 | 사양 |
| --- | --- |
| CPU | Intel Celeron J3355 (2코어, 2.0GHz / 최대 2.5GHz), AES-NI |
| RAM | 12GB DDR3L (기본 2GB에서 업그레이드, 공식 지원 최대 6GB) |
| 저장장치 | 3.5"/2.5" SATA HDD·SSD 2베이 |
| 하드웨어 트랜스코딩 | H.264, H.265, MPEG-2, VC-1 (최대 4K) |
| 포트 | USB 3.0 x3, eSATA x1 |
| LAN | 기가비트(RJ-45) x1 |


## 기능

- 재설치 자동화 대신 Container Manager(Docker) 프로젝트의 생성·수정·업데이트를 관리함 (전체 Setup 없음)
- 프로젝트는 `projects/<프로젝트>/`에 두고, NAS의 `/volume1/docker/<프로젝트>`에 배포함
- 제어: 저장소를 받은 PC에서 ssh(키 인증)로 NAS에 접속해 실행
- 프로젝트 제어: [scripts/synoproj.py](scripts/synoproj.py) (Container Manager가 쓰는 DSM API로 생성·수정·빌드·시작·중지, DSM 화면과 상태가 같게 유지됨)

```bash
ssh SiLENT_NAS 'python3 - list' < devices/ds218plus/scripts/synoproj.py
```


### 프로젝트 목록

- 프로젝트: Container Manager의 프로젝트 하나 (compose 파일 하나), 서비스: 그 안의 컨테이너 하나

| 프로젝트 | 서비스 | 용도 | NAS 포트 | compose |
| --- | --- | --- | --- | --- |
| adguardhome | adguardhome | DNS 광고 차단 | 53, 3000 | [projects/adguardhome](projects/adguardhome/compose.yaml) |
| authentik | postgresql, server, worker | SSO(통합 로그인), 내부망 전용 | 39000 | [projects/authentik](projects/authentik/compose.yaml) |
| code-server | code-server | 웹 VS Code | 38081 | [projects/code-server](projects/code-server/compose.yaml) |
| dozzle | dozzle | 컨테이너 로그 보기 | 38082 | [projects/dozzle](projects/dozzle/compose.yaml) |
| grafana | vector, loki, grafana | 로그 수집·대시보드 | 1514/udp, 8899, 3100, 33000 | [projects/grafana](projects/grafana/compose.yaml) |
| home-assistant | homeassistant | 스마트홈 | 8123 (host) | [projects/home-assistant](projects/home-assistant/compose.yaml) |
| | whisper | 음성 인식 (HA 음성 비서) | 10300 | |
| | piper | 한국어 음성 합성 (HA 음성 비서) | 10200 | |
| | music-assistant | 음악 스트리밍 | 8095 (host) | |
| | eclipse-mosquitto | MQTT 브로커 | 1883 | |
| | esphome | ESP 기기 펌웨어 관리 | 6052 (host) | |
| homepage | homepage | 서비스 상태판 (내부망 전용) | 33003 | [projects/homepage](projects/homepage/compose.yaml) |
| metabase | metabase | 데이터 시각화 | 33001 | [projects/metabase](projects/metabase/compose.yaml) |
| nginx-proxy-manager | nginx-proxy-manager | 리버스 프록시 (NAS 폴더: `ngnix-proxy-manager`) | 8080, 8181, 4443 | [projects/nginx-proxy-manager](projects/nginx-proxy-manager/compose.yaml) |
| ntfy | ntfy | 알림 (WUD 새 버전 알림 → 주제 `nas-updates`) | 30081 | [projects/ntfy](projects/ntfy/compose.yaml) |
| open-webui | open-webui | LLM 웹 UI | 38080 | (비밀값 정리 전) |
| openclaw | openclaw | OpenClaw Gateway (예비, 주 Gateway는 b150m-am2 VM) | 18789 | [projects/openclaw](projects/openclaw/compose.yaml) |
| portainer | portainer | 컨테이너 관리 UI | 8000, 9000 | [projects/portainer](projects/portainer/compose.yaml) |
| tailscale | tailscale | VPN | - | (비밀값 정리 전) |
| uptime-kuma | uptime-kuma | 서비스 감시 | 3001 | (비밀값 정리 전) |
| vaultwarden | vaultwarden | 비밀번호 관리 (authentik SSO 연결) | 30080 | [projects/vaultwarden](projects/vaultwarden/compose.yaml) |
| wg-easy | wg-easy | WireGuard VPN (이 NAS 커널에서 동작 안 함) | 51820/udp, 51821 | [projects/wg-easy](projects/wg-easy/compose.yaml) |
| wireguard | wireguard | WireGuard VPN (이 NAS 커널에서 동작 안 함) | 51820/udp | (비밀값 정리 전) |
| wud | wud | 이미지 새 버전 확인 | 33002 | [projects/wud](projects/wud/compose.yaml) |
| forgejo | forgejo | 자체 Git 호스팅 (로컬망) | 30082, 2223 | [projects/forgejo](projects/forgejo/compose.yaml) |

- Home Assistant와 함께 쓰는 서비스(음성 인식·합성, 음악, MQTT, ESPHome)는 home-assistant 프로젝트 하나에 서비스로 둠 (데이터는 `home-assistant/<서비스>/` 아래)
- "비밀값 정리 전"인 프로젝트는 NAS의 compose에 비밀값·주소가 직접 들어 있어 저장소에 넣지 않았음 (`.env`로 옮긴 뒤 추가)


### WUD (이미지 새 버전 확인)

- 프로젝트: [projects/wud/compose.yaml](projects/wud/compose.yaml) (What's Up Docker, 매일 05:00에 모든 컨테이너 이미지의 새 버전을 확인해 웹 화면에 표시, 자동 업데이트는 안 함)
- 웹 화면: `http://<NAS>:33002` (계정 `admin`, 비밀번호는 NAS의 `/volume1/docker/wud/.env`의 `WUD_AUTH_ADMIN_PASSWORD`)
- 설정: [projects/wud/.env.example](projects/wud/.env.example)


### ntfy (알림)

- 프로젝트: [projects/ntfy/compose.yaml](projects/ntfy/compose.yaml) (로그인한 사용자만 쓸 수 있음, iOS 즉시 알림은 ntfy.sh 중계 사용)
- 웹 화면: `http://<NAS>:30081` (계정 `admin`, 비밀번호는 NAS의 `/volume1/docker/ntfy/.env`의 `NTFY_ADMIN_PASSWORD`)
- WUD가 새 버전을 찾으면 하루 한 번 묶어서 주제 `nas-updates`로 보냄 (WUD `.env`의 `WUD_NTFY_URL`, `WUD_NTFY_TOKEN`)
- 폰: ntfy 앱에서 서버 주소와 `nas-updates` 구독 (지금은 집 안 네트워크에서만 접속됨)


### Homepage (서비스 상태판)

- 프로젝트: [projects/homepage/compose.yaml](projects/homepage/compose.yaml) (내부망 전용, nginx-proxy-manager로 공개하지 않음)
- 웹 화면: `http://<NAS>:33003` (로그인 없음)
- 서비스마다 이름·포트·프로젝트와 상태 점 2개: 첫째 컨테이너 상태 (초록 실행 중 · 주황 멈춤 · 빨강 확인 불가), 둘째 웹 응답 (실행 중이어야 하는 웹 서비스만)
- 서비스 목록: [projects/homepage/app/config/services.yaml](projects/homepage/app/config/services.yaml) (NAS 주소는 `.env`의 `HOMEPAGE_VAR_NAS`)


### authentik (SSO)

- 프로젝트: [projects/authentik/compose.yaml](projects/authentik/compose.yaml) (내부망 전용, `http://<NAS>:39000`)
- 관리자: `akadmin` (비밀번호를 모르면 NAS에서 복구 링크를 만들어 로그인: `docker exec authentik-server-1 ak create_recovery_key 1440 akadmin`, 1440은 분)
- 연결한 서비스 (authentik 애플리케이션 slug, 집 안에서만 SSO 동작, 각 서비스의 기존 비밀번호 로그인은 그대로 됨)

| 서비스 | slug | 서비스 쪽 설정 |
| --- | --- | --- |
| vaultwarden | `vaultwarden` | compose의 `SSO_*`, 값은 vaultwarden `.env` ([.env.example](projects/vaultwarden/.env.example)) |
| grafana | `grafana` | compose의 `GF_AUTH_GENERIC_OAUTH_*`, 값은 grafana `.env` ([.env.example](projects/grafana/.env.example)), authentik Admins 그룹은 Grafana 관리자 |
| portainer | `portainer` | Portainer 관리자 화면 > Settings > Authentication > OAuth (Custom)에서 입력 |

- 클라이언트 ID·비밀값은 authentik 관리자 화면 > 애플리케이션 > 공급자에서 확인

