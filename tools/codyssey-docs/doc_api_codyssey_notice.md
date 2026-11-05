# Codyssey 공지 API (관찰 기반)

## 관찰 화면
- `/main` (헤더 공지 요약), `/notice/noticeGoList`, `/notice/noticeDetail/{pstartSn}`

## 1. `POST /notice/noticeList`
공지 목록 조회.

- **URL**: `https://api.usr.codyssey.kr/notice/noticeList`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/json`
- **보호**: `X-XSRF-TOKEN: <redacted>` 관찰.
- **관찰된 Body**

| 필드 | 예시 | 비고 |
|---|---|---|
| `orderBy` | `all` | 정렬 |
| `page` | `1` | 페이지 |
| `pagePerRows` | `10` | 화면 맥락에 따라 다름 |
| `sysDivCd` | `STU` | 대상 구분 |
| `pstartTitlNm` | `null` | 제목 검색 |
| `mbrNm` | `null` | 작성자 검색 |
| `startDt/endDt` | `null` | 기간 |
| `topFixYn` | `null` | 상단 고정 |

- **응답**: `result.list[]`, `result.paginator`, `result.allCount`

| `list[]` 필드(관찰) | 설명 |
|---|---|
| `pstartSn` | 공지 ID 후보 |
| `pstartTitlNm` | 제목 |
| `pstartCn` | HTML 본문(목록에도 포함 관찰) |
| `mbrNm` | 작성자 표시명 |
| `regDt/mdfcnDt` | 등록/수정 일시 |
| `sysDivCd` | 노출 대상 |
| `topFixYn` | 상단 고정 |
| `inqCnt` | 조회수 |
| `fileSn` | 첨부 연계 값(관찰상 null 사례) |

## 2. `POST /notice/noticeDetail`
공지 상세 조회.

- **URL**: `https://api.usr.codyssey.kr/notice/noticeDetail`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/json`
- **Body(관찰)**: `{"pstartSn":"<공지ID>"}`
- **응답**: `result` 객체(목록 항목과 유사 필드 + `sys`, `code` 등).

## 3. `POST /notice/noticeFileList`
공지 첨부파일 목록 조회.

- **URL**: `https://api.usr.codyssey.kr/notice/noticeFileList`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/json`
- **Body(관찰)**: `{"pstartSn":"<공지ID>"}`
- **응답(관찰)**: `result.fileList[]` (첨부 없을 때 빈 배열)

## 라우팅 관찰
- 목록 클릭 시 프런트 라우트: `/notice/noticeDetail/{pstartSn}` (JS 네비게이션 확인).
- 스냅샷에서 `a href=/`로 보이는 경우가 있으나 실제 클릭 동작은 SPA 라우팅일 수 있음.

## 미확인
- 첨부파일 다운로드 API/URL 패턴(`fileList`에 데이터가 있을 때).
- 운영 규정(`policy`) 화면이 `noticeList/noticeDetail` 재사용인지, 별도 필터/엔드포인트인지.
- 검색/페이징 파라미터 전체 계약.
