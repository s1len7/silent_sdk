# Codyssey 평가 요청 API (관찰 기반)

## 관찰 화면
- `https://usr.codyssey.kr/ev/request/evalutionRequestList`
- `https://usr.codyssey.kr/ev/request/evalutionRequestWrite` (읽기 흐름 관찰)

## 1. `POST /ev/request/searchList`
평가 요청 목록 조회.

- **URL**: `https://api.usr.codyssey.kr/ev/request/searchList`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/x-www-form-urlencoded`
- **보호**: `X-XSRF-TOKEN: <redacted>` 관찰.
- **관찰된 Body**

| 필드 | 예시 | 비고 |
|---|---|---|
| `orderBy` | `all` | 정렬/조건 |
| `page` | `1` | 페이지 |
| `pagePerRows` | `10` | 페이지 크기 |

- **응답**: `result.list[]`, `result.paginator`, `result.allCount`

| `list[]` 필드(관찰) | 설명 |
|---|---|
| `evlNo` | 평가 번호 후보 |
| `evlDegr` | 평가 차수 |
| `evlStusCd/Nm` | 상태 코드/명 |
| `projectNo/Nm` | 학습단계/프로젝트 |
| `lcorsNo/Nm` | 학습주제/코스 |
| `uqstnNo/Nm` | 과제/문항 |
| `evlBgngDt/evlEndDt` | 평가 시작/종료 |
| `passedYn` | 통과 여부 |
| `evlResltCd/Nm`, `evlScr` | 결과/점수(있을 때) |

## 2. `GET /ev/request/evlStusCdList`
평가 상태 코드 목록.

- **URL**: `https://api.usr.codyssey.kr/ev/request/evlStusCdList?groupCd=LP012`
- **Method**: `GET`
- **응답**: `result.codeInfo`, `result.codeList[]`
- **관찰 코드(LP012)**: `00001/대기중`, `00002/진행중`, `00003/완료`

## 3. `GET /ev/request/lastEvList`
최근 평가 선택값/컨텍스트.

- **URL**: `https://api.usr.codyssey.kr/ev/request/lastEvList`
- **Method**: `GET`
- **응답 필드(관찰)**: `lastProjectNo`, `lastLcorsNo`, `lastUpProjectNo`, `lastUqstnNo`

## 4. 평가 요청 작성/선택 연쇄 API
요청 작성 화면에서 순차 호출 관찰. 요청 body는 화면 상태 의존 가능성이 높아 필드 계약은 미확정(민감값 제외).

| Method | Path | 관찰 응답 요약 |
|---|---|---|
| POST | `/ev/request/selectProjectNmList` | `result[]` 프로젝트 목록(`projectNo`, `projectNm` 등) |
| POST | `/ev/request/selectLrnCorsNmList` | `result[]` 학습주제 목록(`lcorsNo`, `lrnCorsNm` 등) |
| POST | `/ev/request/selectLrnUqstnNmList` | `result.lrnUqstnNmList[]` 과제 목록(`uqstnNo`, `uqstnNm`, `peerEvlrNope`, `collEvlYn`, `profEvlYn`, `evlMandatoryYn` 등) |
| POST | `/ev/request/evlTotList` | 평가 총괄/기준/동료평가 데이터(`evalBasDto`, `peerEvlrNope`, `mtlEvlDataTxnDtoList` 등) |
| POST | `/ev/request/mtlEvlTxnDtoByPkList` | 동료평가 트랜잭션 상세 배열. 상태/예약/실시/결과/피드백/점수 필드 포함. 개인 식별·피드백 본문은 민감. |

## 미확인
- `searchList` 필터 전체(프로젝트명, 상태, 요청일자 등 UI 필터가 API에 어떻게 매핑되는지).
- 작성 화면 POST body 스키마(실제 UI 선택 시 캡처 필요).
- 평가 요청 생성/수정/취소 제출 API(상태 변경, 관찰/실행 금지).
- `evlNo` vs `scdlId` vs `mtlEvlSn`의 관계와 동기화 키 적합성.
