# Codyssey 알림 API (관찰 기반)

## 관찰
- 공통 헤더: `optionList`, `alarmCntList` 호출 관찰.
- 알림 페이지: `https://usr.codyssey.kr/alarm/alarmList`. 재로드 시 목록 조회 API 확인.

## 1. `POST /alarm/alarmList/optionList`
알림 분류/옵션 코드 목록.

- **URL**: `https://api.usr.codyssey.kr/alarm/alarmList/optionList`
- **Method**: `POST`
- **Body**: 관찰상 빈 요청.
- **응답**: `result.divCdList[]` (코드 테이블)

| 필드(관찰) | 설명 |
|---|---|
| `grupCd` | 그룹 코드(예: `CM005`) |
| `dtlCd` | 상세 코드 |
| `dtlCdNm` | 이름(내 정보, 학습, 시험/투표 등) |
| `dtlCdDescCn` | 설명 |
| `useYn` | 사용 여부 |
| `engDtlCdNm` | 영문/표시명 |

## 2. `POST /alarm/alarmList/alarmCntList`
알림 건수/요약.

- **URL**: `https://api.usr.codyssey.kr/alarm/alarmList/alarmCntList`
- **Method**: `POST`
- **Body**: 관찰상 빈 요청.
- **응답(관찰)**: `level`, `alarmCnt`, `exp`

## 3. `POST /alarm/alarmList/list`
알림 목록 조회.

- **URL**: `https://api.usr.codyssey.kr/alarm/alarmList/list`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/x-www-form-urlencoded`
- **보호**: `X-XSRF-TOKEN: <redacted>` 관찰.
- **관찰된 Body**

| 필드 | 예시 | 비고 |
|---|---|---|
| `page` | `1` | 페이지 |
| `pagePerRows` | `10` | 페이지 크기 |

> UI에 구분(`ntcDivCd` 후보), 알림 일자, 검색어 필터가 있음. 필터 적용 시 body 확장 가능성 높으나 **미확인**(상태 변경 없는 검색 제출만 추가 캡처 필요).

- **응답**: `result.alarmCount`, `result.list[]`, `result.paginator`

| `list[]` 필드(관찰) | 설명 | 민감도 |
|---|---|---|
| `pstartSn` | 알림 ID 후보 | 보통 |
| `pstartTitlNm` | 제목 | 보통 |
| `pstartCn` | 본문(HTML `<br/>` 포함 가능) | 내용/개인정보 포함 가능 |
| `ntcDivCd` | 알림 구분 코드(`optionList` 연계 추정) | 보통 |
| `dtlCdNm` | 구분명 | 보통 |
| `sysDivCd` | 시스템 구분 코드 | 보통 |
| `callPstartSn/2/3/4` | 연관 객체 ID(프로젝트/코스/문제 등 추정) | 보통 |
| `readYn` | 읽음 여부 | 보통 |
| `instCd`, `mbrId` | 기관/회원 ID | **민감** |
| `regDt` | 등록일시 | 보통 |
| `rgtrId/rgtrRoleCd/rgtrEmail/rgtrName` | 발신/등록자 정보 | **민감(PII)** |
| `emlAddr/mbrNm` | 수신자 정보 필드(응답 shape에 존재) | **민감** |
| `total`, `rowNum` | 페이징 보조 | 보통 |

## 미확인
- 목록 필터 파라미터 전체(구분, 기간, 검색어)가 `list` body에 어떻게 매핑되는지.
- 읽음 처리, 삭제, “이동하기”의 상태 변경/네비게이션 API. **실행 금지**.
- `callPstartSn*`와 평가/학습 객체 매핑 규칙.
- 알림 문서/로그/데이터 파일 작성 시 PII(`rgtrEmail`, `rgtrName`, `mbrId`, 본문 내 이메일/이름) 반드시 마스킹.
