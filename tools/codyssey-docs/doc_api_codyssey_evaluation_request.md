# Codyssey 평가 요청 API (관찰 기반)

## 관찰 화면
- `https://usr.codyssey.kr/ev/request/evalutionRequestList`
- `https://usr.codyssey.kr/ev/request/evalutionRequestWrite` (URL 파라미터 없음. `location.state`로 `projectNo, lcorsNo, uqstnNo` 전달 관찰)

## 공통 (관찰)
- `api.usr.codyssey.kr` 사용, 로그인 세션/쿠키 필요.
- JSON POST는 `Content-Type: application/json`, `Accept: application/json`, `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN`(쿠키 `XSRF-TOKEN` 기반) 필요 사례 관찰. 일부는 `application/x-www-form-urlencoded` 허용/요구 관찰. 엔드포인트별 차이 미확정.

## 1. `POST /ev/request/searchList`
평가 요청 목록 조회.

- **URL**: `https://api.usr.codyssey.kr/ev/request/searchList`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/x-www-form-urlencoded;charset=UTF-8`
- **보호**: `X-XSRF-TOKEN: <redacted>` 관찰
- **관찰된 Body**

| 필드 | 예시 | 비고 |
|---|---|---|
| `orderBy` | `all` | 정렬/조건 |
| `page` | `1` | 페이지 |
| `pagePerRows` | `10` | 페이지 크기 |

- **응답**: `result.list[]`, `result.paginator`, `result.allCount` (관찰: `allCount=7`)
- **`paginator` 키(관찰)**: `total, startPage, endPage, totalPage, currentPage, pageCount, pagePerRows`

| `list[]` 필드(관찰) | 예시(마스킹/축약) | 설명 |
|---|---|---|
| `evlNo` | `"732113"` | 평가 번호 후보 |
| `evlDegr` | `"1"` | 평가 차수 |
| `evlStusCd/Nm` | `"00002"/"진행중"` | 상태 |
| `projectNo/Nm` | `"158002"/"AI 네이티브 입학 연수"` | 프로젝트 |
| `lcorsNo/Nm` | `"1143003"/...` | 코스 |
| `uqstnNo/Nm` | `"192019"/...` | 문항/과제 |
| `evlBgngDt/evlEndDt` | `"2026-11-05 15:57:44"`/null | 시작/종료 |
| `evlResltCd/Nm`, `evlScr` | null | 결과/점수(있을 때) |
| `passedYn/passedScr` | `"N"`/null | 통과 |
| `total/rowNumb/page/pagePerRows` | number | 페이징/순번 보조 |
| `kwajungStr/startDt/endDt/orderBy/criteria/language` | null/미사용 관찰 | 필터/표시 보조 후보 |

## 2. `GET /ev/request/evlStusCdList`
평가 상태 코드 목록.

- **URL**: `https://api.usr.codyssey.kr/ev/request/evlStusCdList?groupCd=LP012`
- **Method**: `GET`
- **응답**: `result.codeInfo`, `result.codeList[]`
- **관찰 코드(LP012)**: `00001/대기중`, `00002/진행중`, `00003/완료` (`useYn=Y`)

## 3. `GET /ev/request/lastEvList`
최근 평가 선택값/컨텍스트.

- **URL**: `https://api.usr.codyssey.kr/ev/request/lastEvList`
- **Method**: `GET`
- **응답(관찰)**: `{ "lastProjectNo":"158002", "lastLcorsNo":"1143003", "lastUpProjectNo":null, "lastUqstnNo":"192019" }`

## 4. 평가 요청 작성/선택 연계 API
요청 작성 화면에서 순서 호출 관찰. JSON POST(`X-XSRF-TOKEN`) 기준 probe.

| Method | Path | 요청(관찰) | 응답 요약(관찰) |
|---|---|---|---|
| POST | `/ev/request/selectProjectNmList` | `{}` | `result[]` 예: `projectNo, projectNoStr, projectNm, instCd, bgngYmd, endYmd, lcorsCnt, teamCnt, max/minTmbrNope, useYn, pjtFile*` |
| POST | `/ev/request/selectLrnCorsNmList` | `{projectNo}` | `result[]` 예: `projectNo/Nm, lcorsNo, lrnCorsNm, uqstnNo, peerEvlrNope, spcltEvlrNope, testEvlrNope, collEvlYn, profEvlYn, testEvlYn, teamSn` |
| POST | `/ev/request/selectLrnUqstnNmList` | `{projectNo,lcorsNo}`(추가 필드 가능) | `result.lrnUqstnNmList[]` 과제 목록 기대. 본 probe에서는 빈 배열(조건/파라미터 미확정). 기존 관찰 필드: `uqstnNo, uqstnNm, peerEvlrNope, collEvlYn, profEvlYn, evlMandatoryYn` 등 |
| POST | `/ev/request/evlTotList` | JSON 또는 form `projectNo&lcorsNo&uqstnNo` | `result` top-level(관찰): `spcltEvlrNope, peerEvlrNope, evalBasDto, testEvlYn, prlngNm, misTeamYn, teamSn, peerPassAccmCd, leadrYn, profEvlYn, evlPsblYn, collEvlYn`. 평가자 이름 문자열 미확인. |
| POST | `/ev/request/mtlEvlTxnDtoByPkList` | **JSON + `X-XSRF-TOKEN` 권장.** `{projectNo,lcorsNo,uqstnNo}` | **평가 요청 상세/평가자 이력 핵심.** `result[]` 대량(관찰 13k+). form-urlencoded 단독은 빈 `result[]` 관찰. |

### `mtlEvlTxnDtoByPkList` `result[]` 필드 (2026-11-05 관찰, 평가자 `박서영` 사례)
개인식별/피드백 본문 포함 가능. 문서화/로그는 민감값 마스킹.

| 필드 | 예시/형태(마스킹) | 설명(추정) |
|---|---|---|
| `mtlEvlSn` | number | 상호평가 트랜잭션/슬롯 SN |
| `evlNo` | number | 평가 번호(요청/평가 단위 후보) |
| `evlDegr` | number | 평가 차수 |
| `projectNo/lcorsNo/uqstnNo` | number | 프로젝트/코스/문항 |
| `teamSn` | number | 팀 번호 |
| `evlInstCd` | string | 기관 코드 |
| `evlMbrId` | string(민감) | **평가자 회원 ID** |
| `evlMbrNm` | string | **평가자명** (`evaluationRequestWrite` “평가자명(아이디)”와 일치) |
| `evlMbrEmail` | string(민감) | 평가자 이메일 |
| `evlrTypeCd/Nm` | string | 평가자 유형(`00001/동료`) |
| `mtlEvlPamBgngDt/PamEndDt/PamBgngDtTxt` | datetime/string | 평가 예정/예약 시간 |
| `mtlEvlBgngDt/EndDt` | datetime | 실제 평가 시작/종료 |
| `mtlEvlStusCd/Nm` | string | 상태(`00006/평가완료` 등) |
| `mtlEvlResltCd/Nm` | string | 결과(`00001/PASS`, `00002/FAIL` 등) |
| `mtlEvlScr/AdtnlScr` | string/number | 점수 |
| `mtlEvlAdtnlScrPvsnYn` | string | 추가 점수 제공 여부 |
| `evlFdbkCn/WrtDt` | string/datetime(민감) | 평가자 피드백 |
| `fdbkReplyCn/RegDt/UseYn/TargetYn/WritableYn` | mixed | 피드백 답글 |
| `respectScore/criteriaComplianceScore/specificityScore/explanationOpportunityScore/learningHelpScore` | number/null | 항목 점수(있을 때) |
| `evlDmndRtrcnRsnCd/Nm/rjctRsnCn` | string | 철회/취소/반려 사유 후보 |
| `ruleCnfrmDttm` | string | 규칙 확인 시각 |
| `profImgPath` | string(URL, 민감 가능) | 평가자 프로필 이미지 |
| `mteDmndSn/exprcDgrCd` | number/string | 매칭/경험 차수 후보 |
| `rgtrId/regDt/mdfrId/mdfcnDt` | string/datetime | 감사 필드 |

## 캘린더 연계 메모 (codyssey_improved/CIM)
- `/main/month` React Big Calendar `event.resource`는 `scheduleAllList` 기반. R(`평가요청`) 리소스는 `scdlReqUsr`만 값이 있고 `scdlOwnUsr/mbrNm/scdlUsr=null` 관찰 → **평가자명 없음**.
- `evaluationRequestWrite` 상세는 `mtlEvlTxnDtoByPkList`의 `evlMbrNm`(평가자명) 사용. 캘린더에 평가자명을 넣으려면 `evlNo/mtlEvlSn`-`scdlId/reqDetail` 매핑 + 조회/캐시 전략 필요(요구사항 “추가 API 호출 없음”과 충돌 가능, 미확인).

## 미확인
- `searchList` UI 필터 전체 매핑.
- 작성 화면 POST body 스키마 전체, `selectLrnUqstnNmList` 빈 배열 조건.
- 평가 요청 생성/수정/취소 제출 API.
- `evlNo` vs `scdlId` vs `mtlEvlSn` 관계/동기화.
- `mtlEvlTxnDtoByPkList` 전건 범위/성능/권한/기간/필터 파라미터.
- 엔드포인트별 JSON/form/CSRF 허용 범위.