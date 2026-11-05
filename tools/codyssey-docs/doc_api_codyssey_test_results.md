# Codyssey API 역공학 테스트 결과 로그

> 목적: 토큰 부족/중단/다른 에이전트 인계 시 이어서 작업 가능하도록, 테스트 시도·결과·미확인 항목을 기록한다.  
> 보존 문서: `docs/doc_api_codyssey_peer_review_schedule.md`는 수정하지 않음.

## 작업 규칙(사용자 지시)
- API 종류별 문서 분리(`docs/doc_api_codyssey_*.md`) 진행.
- 가능한 것은 실제 관찰/테스트 후 문서화.
- 미완/미지는 테스트 후 결과를 본 파일에 기록.
- 작업 산출물 생성 시마다 커밋/푸시, 마지막에도 푸시.

## 환경
| 항목 | 값 |
|---|---|
| 일시(UTC) | 2026-11-05 |
| 도구 | opencli (로컬 데몬 + 브라우저 확장) |
| 보안 | 쿠키/세션/CSRF/`X-XSRF-TOKEN`/`mbrId`/이메일 등 민감값은 기록·문서화하지 않음(마스킹). 상태 변경 요청 실행 금지. |

> 테스트 장비, 작업 디렉터리, 브라우저 세션 식별자는 기록하지 않는다. 테스트 장비가 매번 달라질 수 있어 인계에 의미가 없기 때문.

## 완료/진행
- [x] Git 상태 확인, opencli 연결 확인.
- [x] 테스트 결과 로그 파일 생성/갱신.
- [x] API 종류별 문서 분리 생성.
- [x] 평가 참여 목록 API 추가 확인(`seachParticipationList`, LP019/LP010).
- [x] 종류별 문서/로그 커밋·푸시.
- [x] 로그인 API 계약 확인(`api.ams.codyssey.kr/authenticate`, T-006).
- [x] 스크립트(HTTP 클라이언트)만으로 실제 로그인 성공 + 데이터 API `200` 확인(T-011).
- [ ] 미지/미완 항목: 참여 상세 읽기 API, 알림 필터/학사일정 상세/전문가 평가 타입 실데이터, 스케줄 파라미터 UI 추가 캡처, 로그아웃/세션 갱신 계약.

## 관찰된 API 요약(고유 Method+Path)
| Method | Path | 분류 | 상태 |
|---|---|---|---|
| POST | `/schedule/scheduleAllList/` | schedule | 관찰됨(캘린더) |
| POST | `/schedule/psblScheduleList/` | schedule | 관찰됨 |
| POST | `/ev/request/searchList` | evaluation_request | 관찰됨 |
| GET | `/ev/request/evlStusCdList` | evaluation_request | 관찰됨 |
| GET | `/ev/request/lastEvList` | evaluation_request | 관찰됨 |
| POST | `/ev/request/selectProjectNmList` | evaluation_request | 관찰됨 |
| POST | `/ev/request/selectLrnCorsNmList` | evaluation_request | 관찰됨 |
| POST | `/ev/request/selectLrnUqstnNmList` | evaluation_request | 관찰됨 |
| POST | `/ev/request/evlTotList` | evaluation_request | 관찰됨 |
| POST | `/ev/request/mtlEvlTxnDtoByPkList` | evaluation_request | 관찰됨 |
| POST | `/notice/noticeList` | notice | 관찰됨 |
| POST | `/alarm/alarmList/optionList` | alarm | 관찰됨 |
| POST | `/alarm/alarmList/alarmCntList` | alarm | 관찰됨 |
| POST | `/learning/learningProgress/allLearningList` | learning | 관찰됨 |
| GET | `/point/exp/total/detail` | user_common | 관찰됨 |
| GET | `/rest/user/info/detail` | user_common | 관찰됨 |
| GET | `/api/common/menu/my` | user_common | 관찰됨 |
| GET | `/main/sidebar/new/detail` | user_common | 관찰됨 |
| GET | `/survey/gate/active` | user_common | 관찰됨 |
| POST | `/myinfo/usr/list` | user_common | 관찰됨 |
| POST | `/smallGather/usr/list` | studygroup | 관찰됨 |

## 테스트 상세

### T-001 비인증 `scheduleAllList` 직접 호출 (이전 수행)
- 요청: `POST https://usr.codyssey.kr/schedule/scheduleAllList/` body `bgngYmd=20261001&endYmd=20261231&scheculeType=request&searchType=T`
- 결과: HTTP 200이지만 **SPA HTML 셸(548 bytes)** 반환, JSON 아님. 비인증/프런트 라우팅 영향으로 실 API 응답 미확보.
- 판정: 인증 세션 필요.

### T-002 로그인 세션 캘린더 관찰
- 페이지: `/ev/schedule/evaluationScheduleList`
- 실제 호출: `POST https://api.usr.codyssey.kr/schedule/scheduleAllList/?mbrId=<redacted>&instCd=<redacted>&bgngYmd=2026.10.26&endYmd=2026.12.06&scheduleType=request`
- 응답: `result.reqList`, `result.timeList`, `result.academicList` 포함. 전문가 특강 3건 `academicList` 확인.
- 판정: 문서화 가능.

### T-003 `scheduleAllList` 파라미터 변형 브라우저 JS 재호출
- 시도: `scheduleType=request+searchType=T`, `request`, `all`, 빈값, 미지정.
- 결과: 모두 `403 {"code":403,"message":"CSRF_TOKEN_INVALID"}`.
- 판정: **CSRF 제약으로 변형 유효성 미확인**. 화면 조작으로 자연 발생 요청만 신뢰.

### T-004 주요 페이지 순회 API 발견
- `/main`, `/notice/noticeGoList`, `/policy/policyGoList`, `/studygroup/studygroupGoList`, `/learning/learningProgress/list`, `/ev/request/evalutionRequestList`, `/ev/request/evalutionRequestWrite`, `/ev/participation/evalutionParticipationList` 순회.
- 판정: 공통/공지/알림/학습/포인트/소모임/평가요청 API 관찰.

### T-005 평가 참여 전용 목록 API
- 화면: `/ev/participation/evalutionParticipationList`, 4건 노출.
- 관찰 API: `POST https://api.usr.codyssey.kr/ev/participation/seachParticipationList` (철자 `seach` 그대로 관찰).
- Content-Type: `application/x-www-form-urlencoded`.
- Body shape(관찰): `projectNm, reqMbrNm, mtlEvlStusCd, mtlEvlPamBgngDt, mtlEvlPamBgngDted, evlStdtFirst, evlStdtLast, mtlEvlResltCd, evlMbrId=<redacted>, evlInstCd=<redacted>, page, pagePerRows`.
- 응답: `result.list[]`에 `mtlEvlSn`, 과제/팀/요청자, 예정/시작일시, `mtlEvlStusCd/Nm`(`00006/평가완료`), `mtlEvlResltCd/Nm`(`00001/PASS`,`00002/FAIL`), `mtlEvlScr`, `paginator`, `allCount`.
- 함께 호출: `GET /ev/request/evlStusCdList?groupCd=LP019`(상호평가 상태), `?groupCd=LP010`(결과 PASS/FAIL).
- 판정: **참여 목록 API 문서화 가능**. 상세 진입은 opencli native input 제약/상태변경 리스크로 미완료.

### T-006 로그인 API (계약 확인)
- 로그인 페이지: `https://ams.codyssey.kr/loginForm` (SPA). 비인증 상태로 `usr` 접근 시 이 주소로 리다이렉트.
- 로그인 API: `POST https://api.ams.codyssey.kr/authenticate`
- 요청 헤더: `Content-Type: application/x-www-form-urlencoded`, `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN: <redacted>`
- 요청 body: `userId`, `password`, 선택 `aliasNm`(다중 역할 계정)
- CSRF: 로그인 전 `api.ams.codyssey.kr`에서 발급되는 `XSRF-TOKEN` 쿠키가 필요. 토큰 없이 호출하면 `403`.
- 실패 응답(실측): `401` `{"message_code":"E0000","success":false,...}` (아이디/비밀번호 불일치)
- 성공 응답(실측): `200`, `Location: https://usr.codyssey.kr/main/`, 본문 `{"success":true,"memberType":"REGULAR"}`
- 세션 쿠키: `JSESSIONID`(`Domain=codyssey.kr`, `Path=/`, `Secure`, `HttpOnly`), `XSRF-TOKEN`(`Domain=codyssey.kr`, `Path=/`, `Secure`). 로그인 성공 시 `XSRF-TOKEN` 교체.
- 잠금 정책(앱 번들 문구): 5회 실패 시 30분 로그인 제한.
- 빈 값 요청은 `200` + `Location: /pwd/pwdChgInfo`로 응답(비정상 케이스, 계약 판단에 사용하지 않음).
- 판정: **API 로그인 구현 가능(계약 확정)**. 미검증: `aliasNm` 필요 조건, 로그아웃/갱신 계약.

### T-011 스크립트만으로 로그인 성공 (브라우저 없음)
- 방법: PowerShell 5.1 `Invoke-WebRequest` + `WebRequestSession`(쿠키 자동 관리). 브라우저·확장·렌더링 없이 HTTP 요청만 사용.
- 절차: `GET api.ams.codyssey.kr/rest/api/auth/status`로 `XSRF-TOKEN` 부트스트랩 → `POST /authenticate` **1회** → 쿠키 저장소에서 교체된 `XSRF-TOKEN` 재조회 → `GET api.usr.codyssey.kr/rest/user/info/detail`.
- 결과: `login_status=200`, `Location=https://usr.codyssey.kr/main/`, `memberType=REGULAR`, `usr_status=200`(응답 12KB대).
- 추가 확인: 같은 세션에서 `X-XSRF-TOKEN` 헤더를 빼면 `403`. `api.usr` 호출에는 `X-XSRF-TOKEN` + `Origin`/`Referer`가 필요하다.
- 판정: **브라우저 없이 자동 로그인 가능**. 앱(네이티브/RN/Flutter)에서 그대로 구현 가능. 웹/PWA는 CORS 때문에 프록시 필요.
- 보안: 실자격증명은 `docs/.env`(git 무시)에서 스크립트가 직접 읽었고, 화면·로그·문서에 값을 남기지 않았다. 실패 시 재시도 없음.

## 미지/후속 TODO
- [x] 로그인 API 계약 + 스크립트 로그인 성공 검증(T-006, T-011).
- [x] 평가 참여 목록 전용 API 확정: `POST /ev/participation/seachParticipationList`.
- [x] 알림 목록 API 확정: `POST /alarm/alarmList/list`.
- [x] 공지 상세/첨부 API 확정: `POST /notice/noticeDetail`, `POST /notice/noticeFileList` (body `pstartSn`).
- [ ] 평가 참여 상세 읽기 API(상태 변경 버튼 제외, UI 제약/리스크로 미완료).
- [ ] 알림 목록 필터 파라미터(구분/기간/검색어) UI 제출 캡처.
- [ ] 알림 읽음/삭제/이동 상태 변경 API(실행 금지).
- [ ] 학사일정/특강 상세/신청 관련 읽기 API(있다면).
- [ ] 공지 첨부파일 다운로드 API(`fileList` 데이터 필요).
- [ ] 운영규정/정책 페이지 API 재사용/분리 확인.
- [ ] `scheduleType`/기간/월 이동/필터의 실제 UI 파라미터 추가 수집(opencli native click 제약으로 JS/UI 대체 필요).
- [ ] 전문가 평가 유형 실데이터/API 확인.
- [ ] ID 불변성/취소·삭제 표현 규칙(변경 이벤트 관찰 필요).
- [x] 로그인 API 계약 확정: `POST https://api.ams.codyssey.kr/authenticate` (XSRF 쿠키 필요).
- [ ] 스크립트만으로 로그인 성공 세션 획득 검증(실패 5회 시 30분 잠금 주의).
- [ ] 로그아웃(`/logout` 관찰)/세션 갱신 계약.


## 2026-11-05 추가 캡처
- T-005 보강: 참여 페이지 로드 시 `seachParticipationList` + `evlStusCdList`(LP019/LP010) 호출 확인. 상세 버튼은 opencli native click 제약으로 미진입(상태 변경 리스크 회피).
- T-007 알림: `POST /alarm/alarmList/list` 확인. `form`, body `page/pagePerRows`, 응답 `alarmCount/list/paginator`. PII 포함 가능(마스킹 필요).
- T-008 공지: `/notice/noticeDetail/{pstartSn}` 라우팅 확인. `POST /notice/noticeDetail`, `POST /notice/noticeFileList` 확인. body `{"pstartSn":"..."}`. `fileList=[]` 사례 관찰.
- T-009 스케줄 월 이동: `browser click`은 “visible browser page” 제약으로 실패. JS 대체 클릭/후속 캡처 필요.
- T-010 인증 후 메인 화면 추가 관찰: `/main/tz/detail`, `/point/pnt/total/detail`, `/badge/myList`, `/schedule/mainScheduleCntList`, `/rest/secom/list`, `/learning/learningProgress/progress/detail`, `/learning/learningProgress/status/list`, `/eventPopup/active/usrList`, `/ev/participation/searchParticipationAllList`. 마지막 것은 `seachParticipationList`와 철자가 다른 별도 API.

