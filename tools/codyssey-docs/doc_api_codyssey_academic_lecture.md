# Codyssey 학사일정/전문가 특강 API (관찰 기반)

## 관찰 요약
전문가 특강은 캘린더 화면에 표시되었고, 캘린더 로드 시 호출된 `POST /schedule/scheduleAllList/` 응답의 `result.academicList[]`에 포함되었다. 별도 특강 전용 조회 API는 캘린더 로드 캡처에서 확인되지 않았다.

## 데이터 소스
- **API**: `POST https://api.usr.codyssey.kr/schedule/scheduleAllList/`
- **응답 경로**: `result.academicList[]`
- **관련 화면**: `/ev/schedule/evaluationScheduleList`

## `academicList[]` 필드(관찰)
| 필드 | 타입(관찰) | 설명/예시(익명화) |
|---|---|---|
| `scheduleNo` | number | 학사일정 ID 후보 |
| `instCd` | string/null | 기관 코드 |
| `examId` | number/string/null | 시험 연계 여부 추정 |
| `scheduleTypeCd/Nm` | string | 예: `99/기타`, `02/이벤트` |
| `scheduleTitle` | string | 예: `11월 2주차 전문가 특강(1회차)` |
| `rcptBgngDt/rcptEndDt` | string/null | 신청 기간 |
| `scdlBgngDt/scdlEndDt` | string/null | 일정 시작/종료 |
| `bgngYmd/endYmd/bgngTm/endTm` | string/null | 날짜/시간 분리 |
| `place` | string/null | 장소 |
| `scheduleCn` | string/null | 상세 내용 |
| `publicAt` | string/flag | 공개 여부(`"1"` 관찰) |
| `cancelAt` | string/flag | 취소 여부(`"0"` 관찰) |
| `scdlGubunCd/Nm` | string | `AM/학사일정` 관찰 |
| `fixedCd/fixedNm` | string | `01/예정`, `03/완료` 관찰 |
| `myAtndAt` | string/null | 본인 참석/신청 관련 추정 |
| `atndAt` | string | 2026-11-06 존재만 관찰. 값/역할/`myAtndAt`와의 관계 미확인 |

## 전문가 특강 관찰 사례
- 2026-11월 캘린더에서 특강 1~3회차가 `academicList`에 포함됨.
- 장소/신청기간/일시/예정 상태(`fixedNm=예정`, `cancelAt=0`) 확인.

## 신청 저장 API 관찰(2026-11-06)
- 학사일정(AM) 신청 시 `academicScheduleSave` 요청으로 상태 변경이 일어나는 것을 관찰함. 전체 경로/파라미터/응답 본문은 미캡처.
- 신청 성공 후 상태 판별 후보 필드는 `atndAt`/`myAtndAt`(위 표). 캘린더 리소스 갱신 타이밍은 미확인.
- 출처: Codyssey Improved 브라우저 확장 개발 중 네트워크 관찰(2026-11-05 인계 기록 기반). 실행 테스트는 하지 않음(상태 변경 실행 금지 정책).

## Google Calendar 동기화 메모(잠정)
- 이벤트 키 후보: `AM:academic:${scheduleNo}` (서버 불변성 미확인).
- 취소 판단 후보: `cancelAt`, `fixedCd/fixedNm`.
- 시간대/포맷 정규화 필요(`YYYY.MM.DD`, `YYYY-MM-DD HH:mm` 혼재 관찰).

## 미확인
- 특강 상세 조회/취소 전용 API(신청 저장은 위 절의 `academicScheduleSave` 관찰).
- `scheduleTypeCd` 전체 분류와 “전문가 특강”의 안정적 식별 규칙(현재는 제목/유형/맥락 기반 추정 위험).
- `cancelAt` 외 삭제 표현 방식.
