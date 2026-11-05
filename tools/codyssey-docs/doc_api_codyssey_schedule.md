# Codyssey 일정/캘린더 API (관찰 기반)

> 보존 문서 `doc_api_codyssey_peer_review_schedule.md`의 후속 분류 문서. 원본 테스트 근거는 보존 문서를 우선 참조.

## 관찰 요약
- 화면: `https://usr.codyssey.kr/ev/schedule/evaluationScheduleList`
- 관찰: 2026-11-05, opencli 로그인 세션(`muunzz2v`).
- 캘린더 로드 시 일정 조회 API가 호출되며, **`scheduleType=request` 단일 호출에서도** `reqList`, `timeList`, `academicList`가 함께 반환되는 사례를 확인.

## 1. `POST /schedule/scheduleAllList/`
- **URL**: `https://api.usr.codyssey.kr/schedule/scheduleAllList/`
- **Method**: `POST`
- **인증/보호**: 로그인 세션 + CSRF 정황. 요청 헤더에 `Accept: application/json`, `Content-Type: application/json`, `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN: <redacted>` 관찰.
- **관찰된 Query Parameters**

| 파라미터 | 예시(익명화/관찰) | 비고 |
|---|---|---|
| `mbrId` | `<redacted>` | 개인 식별자 |
| `instCd` | `<redacted>` | 기관 코드 추정 |
| `bgngYmd` | `2026.10.26` | 조회 시작일, `YYYY.MM.DD` |
| `endYmd` | `2026.12.06` | 조회 종료일, `YYYY.MM.DD` |
| `scheduleType` | `request` | 실제 캘린더 로드에서 관찰(정철자) |

- **Body**: 관찰상 실질 본문 없음/`null` 형태(`body_omitted`, `body_shape.$=null`). 계약 미확정.
- **응답**: `{code, message, errors, result}`

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

### `result.reqList[]`
평가/일정 항목. `scdlGubunCd`가 `EV`(평가), `AM`(학사일정) 등으로 관찰됨.

| 필드 | 타입(관찰) | 설명 |
|---|---|---|
| `scdlId` | number | 일정 ID 후보 |
| `scdlGubunCd/Nm` | string | 일정 구분(`EV/평가`, `AM/학사일정`) |
| `bgngYmd/bgngTm/endTm/endYmd` | string/null | 일시 |
| `fixedCd/fixedNm` | string | 상태(예: `00006/평가완료`, `00005/평가요청취소`, `01/예정`, `03/완료`) |
| `title` | string | 제목 |
| `scdlReqUsr` | string/null | 표시명(개인정보 가능) |
| `reqDetail` | string/null | 메타 문자열. `R||...`/`A||...` 패턴 관찰(요청/참여 성격 단서). 계약 미확정, 민감 가능 |
| `evlDmndRtrcnRsnCd` | string/null | 취소/철회 관련 코드 추정 |
| `isExamOverlap` | boolean | 시험 겹침 추정 |

### `result.timeList[]`
캘린더 슬롯/등록 일정.

| 필드 | 타입(관찰) | 설명 |
|---|---|---|
| `scdlId` | number | 일정 ID 후보 |
| `bgngYmd` | string | 날짜 |
| `evlPsblYmdTm` | string/null | `YYYY-MM-DD HH:mm` 관찰 |
| `fixedNm` | string/null | 시간 구간(예: `18:00 ~ 18:30`) |
| `title` | string/null | 예: `등록 일정` |
| `reqYn` | string/null | `Y` 관찰 |
| `reqGu` | string/null | `evl` 관찰 |
| `scdlStusCd` | string/null | 상태 코드 |
| `rpttDivCd/Nm` | string/null | 반복 |

### `result.academicList[]`
학사일정/특강. 상세는 `doc_api_codyssey_academic_lecture.md` 참조.

## 2. `POST /schedule/psblScheduleList/`
평가 가능 슬롯 조회.

- **URL**: `https://api.usr.codyssey.kr/schedule/psblScheduleList/`
- **Method**: `POST`
- **관찰된 Query Parameters**

| 파라미터 | 예시(익명화) |
|---|---|
| `mbrId` | `<redacted>` |
| `instCd` | `<redacted>` |
| `evlPsblYmd` | `2026-11-01` |

- **응답**: `result.list[]`

| 필드 | 타입(관찰) | 설명 |
|---|---|---|
| `evlScdlSn` | number | 슬롯 ID |
| `evlPsblYmd` | string | 날짜 |
| `evlPsblTm` | string | 시간 구간 |
| `rpttDivCd/Nm` | string | 반복 구분 |
| `offset` | number | 보조 필드 |
| `force` | boolean | 보조 필드 |

## 미확인
- `scheduleType` 전체 값 목록(`request` 외), `searchType`, `scheculeType` 오탈자 호환성.
- 날짜 파라미터 포맷 허용 범위(`YYYYMMDD` vs `YYYY.MM.DD`).
- 최대 조회 기간, 과거 조회 제한.
- 파라미터 변형: 브라우저 JS 재호출 시 `403 CSRF_TOKEN_INVALID`로 미검증.
- 전문가 평가가 항상 포함되는지.
- 변경 시 ID 불변성, 삭제/취소 표현 규칙.
