# Codyssey 평가/캘린더 일정 API 문서 (테스트 기반)

## 1. 문서 정보
- **대상 파일**: `docs/doc_api_codyssey_peer_review_schedule.md`
- **작성 기준**: 2026-11-05(UTC) opencli 브라우저 세션(`muunzz2v`, 로그인 상태)에서 실제 Codyssey 화면 진입 시 발생한 네트워크 요청/응답 관찰 결과
- **범위**: 캘린더 일정 조회 및 관련 평가 목록 API의 **관찰된 동작** 정리
- **제한 사항**
  - 비인증 호출은 일정 JSON 대신 프런트 SPA HTML(548 bytes)이 반환될 수 있음.
  - 브라우저 컨텍스트에서 파라미터 변형 재호출 시 `403 CSRF_TOKEN_INVALID`가 발생하여, 실제 화면이 사용한 요청 외 변형의 유효성은 미확인.
  - 개인정보/인증정보(쿠키, 세션, `X-XSRF-TOKEN`, `mbrId`, 이메일 등)는 본 문서에 포함하지 않음. 예시는 익명화.

---

## 2. 테스트 환경/관찰 화면
| 항목 | 값 |
|---|---|
| 사용자 사이트 | `https://usr.codyssey.kr` |
| API 호스트 | `https://api.usr.codyssey.kr` |
| 관찰 화면 | `/ev/schedule/evaluationScheduleList`, `/ev/request/evalutionRequestList`, `/ev/participation/evalutionParticipationList`, `/ev/request/evalutionRequestWrite` |
| 인증 | 로그인된 브라우저 세션 필요. 요청 헤더에 `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN: <redacted>` 관찰. |
| 캘린더 화면에서 확인된 일정 유형 | 평가참여, 평가요청, 전문가 특강(학사일정), 기타 학사일정(응답 포함) |

---

## 3. 캘린더 공통 일정 조회 API

### 3.1 `POST /schedule/scheduleAllList/`
캘린더 페이지 로드 시 실제 호출된 핵심 API.

- **URL**: `https://api.usr.codyssey.kr/schedule/scheduleAllList/`
- **Method**: `POST`
- **관찰된 Request Query Parameters**

| 파라미터 | 관찰값 예시 | 설명/상태 |
|---|---|---|
| `mbrId` | `<redacted>` | 사용자 식별자(개인정보). 실제 호출에 포함됨. |
| `instCd` | `<redacted>` | 기관 코드로 추정. 실제 호출에 포함됨. |
| `bgngYmd` | `2026.10.26` | 조회 시작일. 실제 캘린더 로드에서 `YYYY.MM.DD` 형식 관찰. |
| `endYmd` | `2026.12.06` | 조회 종료일. 실제 캘린더 로드에서 `YYYY.MM.DD` 형식 관찰. |
| `scheduleType` | `request` | 실제 캘린더 로드에서 사용됨(정철자). |

> 참고: 요구사항 문서의 기존 공개소스에는 `scheculeType=request`(오탈자), `searchType=T`, body/form 전달 방식이 언급되었으나, **이번 캘린더 실요청에서는 `scheduleType=request`가 query로 전달**됨. 오탈자/추가 파라미터 유효성은 CSRF 제약으로 미확인.

- **관찰된 Request Headers (일부)**

| Header | 관찰값/형태 |
|---|---|
| `Accept` | `application/json` |
| `Content-Type` | `application/json` |
| `X-Requested-With` | `XMLHttpRequest` |
| `X-XSRF-TOKEN` | `<redacted>` |
| `Referer` | `https://usr.codyssey.kr/` |

- **관찰된 Request Body**
  - 네트워크 상세에서 `body_omitted`, `body_kind: json`, `body_shape: {"$":"null"}` 관찰(실질적 본문 없음/`null` 수준). 정확한 body 계약은 추가 확인 필요.

- **성공 응답 (HTTP 200, `application/json`)**

```json
{
  "code": 200,
  "message": "OK",
  "errors": null,
  "result": {
    "reqList": [],
    "timeList": [],
    "academicList": []
  }
}
```

> 주의: 기존 공개소스에서 언급된 `data.result.timeList` 접근과 달리, 실제 관찰 응답은 `result.reqList`, `result.timeList`, `result.academicList`를 함께 포함한다.

#### `result.reqList[]` (관찰: 17건)
캘린더에 표시되는 평가/일정 항목(EV/AM 성격 혼합 가능).

| 필드 | 타입(관찰) | 설명/예시(익명화) | 동기화 메모 |
|---|---|---|---|
| `scdlId` | number | 일정 식별자 | 후보 키(서버 불변성 미확인) |
| `scdlGubunCd` | string | `EV`(평가), `AM`(학사일정) 등 | 일정 유형 1차 구분 |
| `scdlGubunNm` | string | `평가`, `학사일정` 등 | 표시용 |
| `bgngYmd` | string | `2026.11.05` | 날짜 형식 혼재 가능성 점검 필요(`YYYY.MM.DD`도 관찰됨) |
| `bgngTm` | string | `13:30` | 시작 시간 |
| `endTm` | string | `14:00` | 종료 시간(관찰) |
| `endYmd` | string/null | 종료일 | 종일/기간 일정 확인 필요 |
| `fixedCd` | string | `00006`, `00005`, `03`, `01` 등 | 상태 코드 |
| `fixedNm` | string | `평가완료`, `평가요청취소`, `완료`, `예정` 등 | 상태 표시 |
| `scdlReqUsr` | string/null | 요청자/등록자 표시명 | 개인정보 가능 |
| `title` | string | 일정/과제 제목 | 이벤트 제목 후보 |
| `reqDetail` | string/null | `R||<scdlId>||...` 또는 `A||<scdlId>||...||<상태코드>||...` 패턴 관찰 | 요청/참여 성격 및 상세 식별 정보 포함 가능(민감). 파싱 전 계약 확인 필요. |
| `evlDmndRtrcnRsnCd` | string/null | 취소/철회 사유 코드로 추정 | 취소 판정 보조 |
| `isExamOverlap` | boolean | 시험 겹침 여부로 추정 | 부가 정보 |
| `divNm`, `prosCn`, `dmndCn` 등 | mixed | 분류/내용 필드 | 화면/유형별 채움 수준 다름 |

**관찰된 상태 예시**
- 평가 완료: `fixedCd=00006`, `fixedNm=평가완료`
- 평가요청 취소: `fixedCd=00005`, `fixedNm=평가요청취소`
- 학사일정 완료/예정: `fixedNm=완료/예정` (코드 체계는 유형별 상이 가능)

#### `result.timeList[]` (관찰: 4건)
캘린더 시간 슬롯/등록 일정 정보.

| 필드 | 타입(관찰) | 설명/예시(익명화) |
|---|---|---|
| `scdlId` | number | 일정 식별자 |
| `bgngYmd` | string | `2026.11.03` |
| `evlPsblYmdTm` | string/null | `2026-11-03 18:00` |
| `fixedNm` | string/null | 시간 구간 표시, 예: `18:00 ~ 18:30` |
| `title` | string/null | 예: `등록 일정` |
| `reqDetail` | string/null | 상세 메타 문자열(상태/참여자 정보 포함 가능) |
| `reqYn` | string/null | `Y` 관찰 |
| `reqGu` | string/null | `evl` 관찰 |
| `scdlStusCd` | string/null | 상태 코드(관찰: `00001`) |
| `rpttDivCd`, `rpttDivNm` | string/null | 반복 정보(관찰: `01/반복 없음`) |

#### `result.academicList[]` (관찰: 4건, 전문가 특강 포함)
학사일정/행사/특강 데이터. 캘린더 화면의 특강 카드와 대조 확인됨.

| 필드 | 타입(관찰) | 설명/예시(익명화) |
|---|---|---|
| `scheduleNo` | number | 학사일정 식별자 | 후보 키 |
| `scheduleTypeCd`, `scheduleTypeNm` | string | 예: `99/기타`, `02/이벤트` |
| `scheduleTitle` | string | 예: `11월 2주차 전문가 특강(1회차)` |
| `rcptBgngDt`, `rcptEndDt` | string/null | 신청 시작/종료 |
| `scdlBgngDt`, `scdlEndDt` | string/null | 일정 시작/종료 |
| `bgngYmd`, `endYmd`, `bgngTm`, `endTm` | string/null | 날짜/시간 분리 필드 |
| `place` | string/null | 장소 |
| `scheduleCn` | string/null | 상세 내용 |
| `publicAt` | string/flag | 공개 여부(관찰: `"1"`) |
| `cancelAt` | string/flag | 취소 여부(관찰: `"0"`) | 취소 판정 핵심 후보 |
| `scdlGubunCd`, `scdlGubunNm` | string | `AM/학사일정` 관찰 |
| `fixedCd`, `fixedNm` | string | `01/예정`, `03/완료` 관찰 |
| `myAtndAt` | string/null | 본인 참석/신청 상태 관련 값으로 추정 |

**전문가 특강 관찰 결과**
- `academicList`에 특강 3건 포함 확인.
- 화면 표시(제목/날짜/시간/신청 가능)와 응답 내용이 일치함.
- 별도 특강 전용 조회 API는 캘린더 로드 캡처에서 확인되지 않음.

---

## 4. 평가 가능 슬롯 조회 API

### 4.1 `POST /schedule/psblScheduleList/`
캘린더/스케줄 UI에서 함께 호출됨.

- **URL**: `https://api.usr.codyssey.kr/schedule/psblScheduleList/`
- **Method**: `POST`
- **관찰된 Query Parameters**: `mbrId=<redacted>`, `instCd=<redacted>`, `evlPsblYmd=2026-11-01`
- **성공 응답**: `result.list[]`

| 필드 | 타입(관찰) | 설명 |
|---|---|---|
| `evlScdlSn` | number | 평가 가능 슬롯 식별자 |
| `evlPsblYmd` | string | 가능 날짜 |
| `evlPsblTm` | string | 가능 시간 구간, 예: `12:00 ~ 12:30` |
| `rpttDivCd`, `rpttDivNm` | string | 반복 구분 |
| `offset`, `force` | number/boolean | UI/로직 보조 필드로 추정 |

---

## 5. 평가 요청/참여 목록 API (화면별, 캘린더 API와 분리)

### 5.1 `POST /ev/request/searchList`
평가 요청 목록 화면에서 호출.

- **URL**: `https://api.usr.codyssey.kr/ev/request/searchList`
- **Method**: `POST`
- **관찰된 Request Header**: `Content-Type: application/x-www-form-urlencoded`
- **관찰된 Body(형태)**: `orderBy`, `page`, `pagePerRows` (값은 화면 상태에 따라 달라질 수 있음)
- **응답 요약**: `result.list[]`, `result.paginator`, `result.allCount`

| 필드(일부) | 설명 |
|---|---|
| `evlNo` | 평가 요청/평가 번호 후보 |
| `evlDegr` | 차수 |
| `evlStusCd`, `evlStusNm` | 평가 상태 코드/명(예: 진행중) |
| `projectNo/Nm`, `lcorsNo/Nm`, `uqstnNo/Nm` | 학습 단계/주제/과제 |
| `evlBgngDt`, `evlEndDt` | 평가 시작/종료 시각 |
| `passedYn`, `evlResltCd/Nm`, `evlScr` | 결과 관련 |

> 이 API는 캘린더 표시용 일정(`scdlId`, `bgngTm/endTm` 슬롯)보다는 **평가 요청 레코드 목록** 성격이다. 캘린더 동기화 시 보조 데이터로만 사용 여부를 검토해야 한다.

### 5.2 평가 참여 목록 화면
- 화면에서 참여 건(요청자, 평가 예정일시, 평가 시작일시, 결과 PASS/FAIL, 상태 등) 노출 확인.
- 본 테스트 턴의 네트워크 캡처에서는 참여 목록 전용 엔드포인트를 `scheduleAllList`/요청 목록 API만큼 명확히 확정하지 못함. **추가 캡처 필요**.

---

## 6. 일정 유형별 확인 결과 (테스트 기준)

| 일정 유형 | 캘린더 화면 | `scheduleAllList` 반영 | 판정 |
|---|---|---|---|
| 평가 요청(EV, R 성격) | 표시 | `reqList` 포함 | 확인 |
| 평가 참여(EV, A 성격) | 표시 | `reqList`에 A 패턴 포함 | 확인(캘린더 데이터 기준) |
| 전문가 특강 | 표시 | `academicList` 포함 | 확인 |
| 기타 학사일정 | 응답/화면 맥락 | `academicList` 포함 | 확인 |
| 전문가 평가 | 이번 화면에서 명시적 식별 불가 | 유형 필드만으로 확정 불가 | **미확인** |

---

## 7. 변경/취소/동기화 관찰

| 항목 | 관찰 내용 | 상태 |
|---|---|---|
| EV 일정 식별자 | `reqList.scdlId`, `timeList.scdlId` | 확인 |
| 학사일정 식별자 | `academicList.scheduleNo` | 확인 |
| 슬롯 식별자 | `psblScheduleList.evlScdlSn` | 확인 |
| EV 취소 흔적 | `fixedCd=00005`, `fixedNm=평가요청취소` 관찰 | 부분 확인 |
| 학사일정 취소 | `academicList.cancelAt` 관찰(특강 `0`) | 부분 확인 |
| 변경 시 ID 유지 | 변경 이벤트 미관찰 | **미확인** |
| 삭제 vs 취소 | 응답 제거/플래그 규칙 미확정 | **미확인** |
| 과거/미래 조회 | 관찰 범위(`2026.10.26~2026.12.06`) 내 과거 완료/미래 예정 포함 | 부분 확인 |
| 최대 조회 기간/제한 | 미측정 | **미확인** |

---

## 8. Google Calendar 연동 관점 메모 (잠정)
- **데이터 소스 후보**: 캘린더 화면과 일치하는 `scheduleAllList`의 `reqList/timeList/academicList`.
- **중복 방지 키 후보(잠정)**: `EV:schedule:${scdlId}`, `AM:academic:${scheduleNo}` 등 **복합 키** 사용 권장. `reqDetail` 내부 값은 계약 미확정이므로 단독 키로 사용 시 주의.
- **상태 반영 후보**: EV `fixedCd/fixedNm`, AM `fixedNm/cancelAt`. 취소/삭제 표현 방식 확정 필요.
- **미해결 리스크**: 전문가 평가 유형 누락 여부, `scheduleType`/기간 파라미터 계약, CSRF·세션 기반 호출 자동화 방식, ID 불변성/삭제 규칙.

---

## 9. 재현 시 주의
- 사용자 직접 로그인 후, 접근 권한 있는 데이터만 조회.
- 쿠키/세션/토큰/개인정보를 로그·문서·저장소에 남기지 않음.
- 평가 요청/취소/특강 신청 등 상태 변경 요청은 실행하지 않음.
- Codyssey 서버에 과도한 요청을 보내지 않음.
