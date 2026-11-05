# Codyssey 소모임 API (관찰 기반)

## 관찰 화면
- `https://usr.codyssey.kr/studygroup/studygroupGoList`

## 1. `POST /smallGather/usr/list`
소모임 목록 조회.

- **URL**: `https://api.usr.codyssey.kr/smallGather/usr/list`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/json`
- **보호**: `X-XSRF-TOKEN: <redacted>` 관찰.
- **관찰된 Body**

| 필드 | 예시 | 비고 |
|---|---|---|
| `page` | `1` | 페이지 |
| `pagePerRows` | `10` | 페이지 크기 |
| `smlGathrSbjtNm` | `""` | 소모임 주제명 검색 |
| `leaderNm` | `""` | 리더명 검색 |
| `status` | `""` | 상태 필터 |
| `joinableYn` | `""` | 참여 가능 필터 |
| `joinedOnly` | `""` | 내 참여만 |

- **응답**: `result.list[]`, `result.paginator`
- **관찰 사례**: 빈 목록(`list=[]`, `total=0`).

## 미확인
- 목록 아이템 필드(데이터 존재 시).
- 소모임 상세/참여/탈퇴/생성/수정 API. 상태 변경은 실행 금지.
- 상태/필터 코드값.
