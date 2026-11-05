# Codyssey 평가 참여 API (관찰 기반)

## 관찰 화면
- `https://usr.codyssey.kr/ev/participation/evalutionParticipationList`
- 화면에 참여 건 리스트 노출(과제명, 요청자, 평가 예정/시작일시, 결과 PASS/FAIL, 상태). DOM에 `mtlEvlSn-*` 패턴 관찰.

## 1. `POST /ev/participation/seachParticipationList`
평가 참여 목록 조회(엔드포인트 철자 `seach`는 실제 관찰값).

- **URL**: `https://api.usr.codyssey.kr/ev/participation/seachParticipationList`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/x-www-form-urlencoded`
- **보호**: `X-XSRF-TOKEN: <redacted>` 관찰.
- **관찰된 Body**

| 필드 | 예시(관찰) | 비고 |
|---|---|---|
| `projectNm` | `""` | 프로젝트명 필터 |
| `reqMbrNm` | `""` | 요청자명 필터 |
| `mtlEvlStusCd` | `""` | 평가 상태 코드 |
| `mtlEvlPamBgngDt` | `""` | 예정 시작일 |
| `mtlEvlPamBgngDted` | `""` | 예정 종료일 |
| `evlStdtFirst` | `""` | 평가 시작일(시작) |
| `evlStdtLast` | `""` | 평가 시작일(종료) |
| `mtlEvlResltCd` | `""` | 평가 결과 코드 |
| `evlMbrId` | `<redacted>` | 평가자 회원 ID(민감) |
| `evlInstCd` | `<redacted>` | 기관 코드 |
| `page` | `1` | 페이지 |
| `pagePerRows` | `10` | 페이지 크기 |

- **응답**: `result.list[]`, `result.paginator`, `result.allCount`

| `list[]` 필드(관찰) | 설명 |
|---|---|
| `mtlEvlSn` | 참여/상호평가 건 ID 후보(문자열 관찰) |
| `projectNo/Nm` | 프로젝트 |
| `lcorsNo/Nm` | 학습주제 |
| `uqstnNo/Nm` | 과제 |
| `teamNm`, `teamSn` | 팀 |
| `reqMbrId/reqMbrNm` | 요청자(민감) |
| `mtlEvlPamBgngDt` | 평가 예정일시 |
| `mtlEvlBgngDt` | 평가 시작일시 |
| `mtlEvlStusCd/Nm` | 상태(예: `00006/평가완료`) |
| `mtlEvlResltCd/Nm` | 결과(예: `00001/PASS`, `00002/FAIL`) |
| `mtlEvlScr` | 점수(문자열 관찰) |
| `evlDegr` | 차수 |

## 2. 참여 화면에서 함께 사용되는 코드 API
- `GET /ev/request/evlStusCdList?groupCd=LP019` — 상호평가 상태 코드.
  - 관찰: `00001 평가요청중`, `00002 평가대기중`, `00003 평가진행중`, `00004 평가거절`, `00005 평가요청취소`, `00006 평가완료`, `00007 자동평가`, `00008 자동평가 취소`
- `GET /ev/request/evlStusCdList?groupCd=LP010` — 평가 결과 코드.
  - 관찰: `00001 PASS`, `00002 FAIL`

## 캘린더 API와의 관계
- `POST /schedule/scheduleAllList/` `result.reqList[]`의 `reqDetail`이 `A||...` 패턴인 항목이 평가 참여 성격 일정으로 캘린더에 함께 노출될 수 있음(관찰).
- `mtlEvlSn`(참여 목록)과 `scdlId`(캘린더)의 직접 매핑 규칙은 **미확인**.

## 미확인 (중요)
- 참여 상세/수행 화면의 읽기 API(버튼 클릭 시 네이티브 입력 제약으로 상세 진입 미완료; URL/모달 변화 없음).
- 참여 수락/거절/시작/제출/취소 API(상태 변경). **실행 금지**.
- `seachParticipationList` 오탈자 외 정식 alias 존재 여부.
- `evlMbrId` 필터가 서버에서 세션 사용자로 강제되는지.

## 안전 후속 테스트
1. 참여 상세 “보기” 성격 링크/라우트가 있으면 해당 화면의 읽기 API만 캡처.
2. 상태/결과/기간 필터를 UI에서 변경해 실제 요청 파라미터 확인.
3. 상태 변경 버튼(평가 하기/취소/제출)은 누르지 않음.
