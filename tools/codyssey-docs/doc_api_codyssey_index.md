# Codyssey API 문서 인덱스 (관찰 기반)

> 자료 보존: `docs/doc_api_codyssey_peer_review_schedule.md`는 기존 테스트 근거 문서로 **수정하지 않음**.  
> 본 인덱스와 분리 문서는 opencli 로그인 세션(`muunzz2v`)에서 관찰한 읽기/조회 API를 종류별로 정리한 추가 문서다.

## 공통 전제
- 사용자 사이트: `https://usr.codyssey.kr` (SPA)
- API 호스트: `https://api.usr.codyssey.kr`
- 인증: 로그인된 브라우저 세션 필요. 실제 호출에서 `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN: <redacted>` 관찰.
- 비인증 `usr.codyssey.kr`/일부 경로 직접 호출은 SPA HTML 셸이 반환될 수 있음.
- 브라우저 JS 임의 재호출은 CSRF로 거부될 수 있음(`403 CSRF_TOKEN_INVALID` 관찰). **실제 UI 흐름에서 발생한 요청**을 우선 신뢰.
- 민감정보(쿠키/세션/토큰/`mbrId`/이메일/개인식별자)는 문서에 기록하지 않음.
- 상태 변경 API(신청/취소/저장/제출/로그인)는 실행하지 않았거나 미확인으로 표기.

## 문서 목록
| 문서 | 내용 | 상태 |
|---|---|---|
| [`doc_api_codyssey_peer_review_schedule.md`](./doc_api_codyssey_peer_review_schedule.md) | 초기 캘린더/일정 API 상세 테스트(보존) | 기존/보존 |
| [`doc_api_codyssey_test_results.md`](./doc_api_codyssey_test_results.md) | 테스트 로그, 미확인/TODO, 인계용 | 진행 중 |
| [`doc_api_codyssey_schedule.md`](./doc_api_codyssey_schedule.md) | 일정/캘린더/가능 슬롯 | 관찰됨 |
| [`doc_api_codyssey_evaluation_request.md`](./doc_api_codyssey_evaluation_request.md) | 평가 요청 화면/작성 흐름 조회 API | 관찰됨 |
| [`doc_api_codyssey_evaluation_participation.md`](./doc_api_codyssey_evaluation_participation.md) | 평가 참여 목록/코드, 상세는 미확인 | 관찰됨(목록) |
| [`doc_api_codyssey_academic_lecture.md`](./doc_api_codyssey_academic_lecture.md) | 학사일정/전문가 특강(`academicList`) | 관찰됨 |
| [`doc_api_codyssey_notice.md`](./doc_api_codyssey_notice.md) | 공지 목록 | 관찰됨 |
| [`doc_api_codyssey_alarm.md`](./doc_api_codyssey_alarm.md) | 알림 옵션/건수/목록 | 관찰됨 |
| [`doc_api_codyssey_learning.md`](./doc_api_codyssey_learning.md) | 학습 진행 목록 | 관찰됨 |
| [`doc_api_codyssey_user_common.md`](./doc_api_codyssey_user_common.md) | 공통 사용자/메뉴/포인트/설문 게이트 | 관찰됨 |
| [`doc_api_codyssey_studygroup.md`](./doc_api_codyssey_studygroup.md) | 소모임 목록 | 관찰됨 |
| [`doc_api_codyssey_auth.md`](./doc_api_codyssey_auth.md) | 로그인 계약/CSRF/세션 | 관찰됨(계약 확인) |

## 고유 엔드포인트(관찰)
```text
GET  /api/common/menu/my
GET  /ev/request/evlStusCdList
GET  /ev/request/lastEvList
GET  /main/sidebar/new/detail
GET  /point/exp/total/detail
GET  /rest/user/info/detail
GET  /survey/gate/active
POST /alarm/alarmList/alarmCntList
POST /alarm/alarmList/list
POST /alarm/alarmList/optionList
POST /ev/participation/seachParticipationList
POST /ev/request/evlTotList
POST /ev/request/mtlEvlTxnDtoByPkList
POST /ev/request/searchList
POST /ev/request/selectLrnCorsNmList
POST /ev/request/selectLrnUqstnNmList
POST /ev/request/selectProjectNmList
POST /learning/learningProgress/allLearningList
POST /myinfo/usr/list
POST /notice/noticeDetail
POST /notice/noticeFileList
POST /notice/noticeList
POST /schedule/psblScheduleList/
POST /schedule/scheduleAllList/
POST /smallGather/usr/list
```
