# Codyssey API 문서 인덱스

> 네이티브 앱/웹 리버스 기반 관찰 문서. 시크릿/개인식별정보는 마스킹하거나 기록하지 않는다.
> 관찰일/세션/화면이 다르면 동작이 달라질 수 있으므로, 새 캡처는 해당 문서에 날짜와 함께 추가한다.

## 문서

| 주제 | 문서 | 상태 |
|---|---|---|
| 사용자/공통 | `doc_api_codyssey_user_common.md` | 2026-11-05 관찰(알림/설정/팀원) |
| 일정/캘린더 | `doc_api_codyssey_schedule.md` | 2026-11-05 관찰(`scheduleAllList` 핵심) |
| 오픈/동료평가 슬롯 | `doc_api_codyssey_peer_review_schedule.md` | 보조 문서(신규는 schedule 문서 우선) |
| 학사일정/강의 | `doc_api_codyssey_academic_lecture.md` | 2026-11-05 관찰 |
| 학습/학습 네이티브·AI 헬퍼 | `doc_api_codyssey_learning.md` | 2026-11-06 갱신(learningProgress/map + 공통 AI 챗봇/헬퍼 `/learning/usr/ai/*`: `learningMap` 패널·`/learning/ai-helper` 공통 확인, history/ask-stream SSE·검증오류·세션 생성·삭제·재생성·중단 관찰; 테스트 세션 정리 완료) |
| 평가 요청 | `doc_api_codyssey_evaluation_request.md` | 2026-11-05 관찰(작성 화면 연계 포함) |
| 평가 참여 | `doc_api_codyssey_evaluation_participation.md` | 2026-11-05 관찰 |
| 공지사항 | `doc_api_codyssey_notice.md` | 2026-11-05 관찰 |
| 스터디그룹 | `doc_api_codyssey_studygroup.md` | 2026-11-05 관찰 |
| 알림 | `doc_api_codyssey_alarm.md` | 2026-11-05 관찰 |
| 인증 | `doc_api_codyssey_auth.md` | 2026-11-05 관찰 |
| 테스트 결과 | `doc_api_codyssey_test_results.md` | 2026-11-05 관찰 |
| 평가 폼 메모 | `peer_review_evaluation_form.md` | 평가 항목 메모 |
| 요구사항 메모 | `requirement_peer_review_schedule_api.md` | 요구사항/추가 캡처 메모 |

## 공통 메모
- Host: `https://usr.codyssey.kr` (웹), `https://api.usr.codyssey.kr` (API) 혼재 관찰.
- 인증: 로그인 세션 + CSRF/XSRF 필요 엔드포인트 존재. 토큰/쿠키/`mbrId`는 문서에 남기지 않는다.
- 날짜 포맷은 엔드포인트별로 다름(`YYYY.MM.DD`, `YYYY-MM-DD`, `YYYYMMDD` 관찰). 호출 전 기존 JS/실응답 확인.
- `POST`로 캡처됐어도 `GET/PUT/DELETE` 허용 여부는 미확인일 수 있음. 상태 변경은 별도 검증.

## 추가 캡처 우선순위
1. 평가 결과/피드백 상세 API (참여 건 클릭 시 XHR).
2. 평가 요청 생성/수정/취소/재요청 제출 API.
3. 일정 등록/삭제/수정의 성공 응답과 캘린더 갱신 흐름.
4. 스터디그룹 상세/가입/게시글/댓글 API.
5. 학습 문항 제출/답안/피드백/파일업로드/진행 갱신(상태 변경) API — **조회 외 호출은 사용자 확인 후**.
6. AI 챗봇 잔여: `conversationSummary` 실제 적용 장문 케이스, `history` 페이지네이션 실제 적용 조건, rename/메시지 일부 삭제 서버 API 존재 여부(현 UI·안전 probe 미관찰, 사용자 데이터 파괴적 probe 제외), 학습 컨텍스트(`projectNo/lcorsNo/uqstnNo/pjtTeamSn`)의 ask-stream 주입 여부.