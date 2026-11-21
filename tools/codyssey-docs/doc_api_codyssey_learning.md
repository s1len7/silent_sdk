# Codyssey 학습/학습 네이티브(Learning Native) API (관찰 기반)

## 관찰 범위/주의
- 관찰일: 2026-11-06, opencli browser 세션(`usr.codyssey.kr` 로그인 상태).
- 관찰 화면: `https://usr.codyssey.kr/learning/learningProgress/list`, `https://usr.codyssey.kr/learning/learningMap?projectNo=158002`
- 보호: 로그인 세션 필요. 일부 POST는 `X-XSRF-TOKEN`(쿠키 `XSRF-TOKEN`) 필요 가능성. 본 문서의 POST probe는 `Content-Type: application/json` + `X-Requested-With: XMLHttpRequest` + `X-XSRF-TOKEN` 기준.
- 응답에 개인식별정보(`mbrId`, `lrnrNm`, 이메일, 프로필 이미지, 팀원 정보 등)가 포함될 수 있음. 문서/로그/공유 시 마스킹.
- `api.usr.codyssey.kr/learning/learningMap?projectNo=...` 는 401(또는 비JSON) 관찰. 실제 학습맵 데이터는 `learningProgress/*` API로 로드됨.

## 공통 응답 형태 (관찰)
대부분 JSON envelope: `{ "code": 200, "message": "OK", "errors": null, "result": ... }`
예외: `/learning/usr/ai/check-ip`는 envelope 없이 `{ allowed, examInProgress, instKeyMissing }` 반환.

## API 요약

| Method | Path | 용도(관찰) | 확인 상태 |
|---|---|---|---|
| GET | `/learning/usr/ai/check-ip` | AI/학습 환경 IP·시험 진행·기관키 체크 | 200 확인 |
| GET | `/learning/usr/ai/models` | AI 챗봇 모델 목록 | 200 확인 (`projectNo` query도 200) |
| GET | `/learning/usr/ai/sessions` | AI 챗봇 세션 목록 | 200 확인 (`sortDesc,limit,offset`, `projectNo`, `sessionId` query 관찰) |
| GET | `/learning/usr/ai/sessions/count` | AI 챗봇 세션 개수 | 200 확인, body `3`/`4` 등 숫자 (`projectNo` query도 200) |
| GET | `/learning/usr/ai/presets` | AI 프리셋/시스템·요약 프롬프트 | 200 확인 (`projectNo` query도 200) |
| GET | `/learning/usr/ai/token-usage` | AI 토큰 사용량/한도/차단 여부 | 200 확인 (`projectNo` query도 200) |
| GET | `/learning/usr/ai/history` | 세션 메시지 이력(목록) | 200 확인, `sessionId` 필수 |
| POST(XHR) | `/learning/usr/ai/ask-stream` | AI 챗봇 메시지 전송/응답(SSE) | **실호출 확인** (request/이벤트/검증 오류 관찰) |
| POST(XHR) | `/learning/usr/ai/sessions/delete` | AI 챗봇 세션 삭제 | **실호출 확인** (`sessionId` query + `X-XSRF-TOKEN`) |
| POST | `/learning/learningProgress/allLearningList` | 내 학습(프로젝트) 목록/락/holyGraph | 200 확인(JSON `{}`) |
| GET | `/learning/learningProgress/child/list` | 프로젝트 학습맵 상세(코스/문항/가이드/팀/진도) | 200 확인(`lpNo`) |
| GET | `/learning/learningProgress/progress/detail` | 프로젝트 진도율 | 200 확인(`projectNo`) |
| GET | `/learning/learningProgress/status/list` | 프로젝트 문항(uqstn) 진행 상태 목록 | 200 확인(`projectNo`) |
| GET | `/learning/learningProgress/lcors/detail` | 코스(lcors) 상세(문항/가이드/스킬) | 200 확인 |
| GET | `/learning/learningProgress/uqstn/detail` | 문항(uqstn/미션) 상세 + 팀 정보 | 200 확인 |
| GET/POST | `/learning/learningProgress/team` | 팀 조회 후보 | 401 관찰(파라미터/권한 미확정) |

---

## 1. `GET /learning/usr/ai/check-ip`
학습/AI 기능 사용 가능 여부 체크.

- **URL**: `https://api.usr.codyssey.kr/learning/usr/ai/check-ip`
- **Method**: `GET`
- **Headers(관찰)**: `Accept: application/json`, `X-Requested-With: XMLHttpRequest`
- **응답(관찰)**:
```json
{ "allowed": true, "examInProgress": false, "instKeyMissing": false }
```

---

## 2. `POST /learning/learningProgress/allLearningList`
학습 진행 목록(프로젝트 단위).

- **URL**: `https://api.usr.codyssey.kr/learning/learningProgress/allLearningList`
- **Method**: `POST`
- **Headers(관찰)**: `Accept: application/json`, `Content-Type: application/json`, `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN: <redacted>`
- **Body(관찰)**: `{}` (빈 JSON)에서 200 확인. `application/x-www-form-urlencoded` 빈 body도 기존 관찰 있음.
- **응답**: `{ code, message, errors, result }`

| `result` 필드 | 관찰 | 설명(추정) |
|---|---|---|
| `learningList[]` | array | 학습 프로젝트 목록 |
| `lockedPjtViewYn` | `"N"` | 잠금 프로젝트 노출 여부 |
| `totalCnt` | number | 전체 개수 |
| `holyGraph` | object/존재 | 학습 그래프 보조 데이터 후보 |

| `learningList[]` 주요 필드(관찰) | 예시(마스킹/축약) | 비고 |
|---|---|---|
| `projectNo/projectNm` | `158002` / `AI 네이티브 입학 연수` | 프로젝트 식별/명 |
| `instCd` | `00035` | 기관 코드 |
| `bgngYmd/endYmd` | `2026-11-02` / `2026-11-13` | 과정 기간 |
| `lcorsCnt` | `"2"` | 코스 수(문자열 관찰) |
| `lcorsDivCd/Nm`, `lcorsFildCd/Nm` | `00004/입학 연수`, `00009/입학연수` | 분류 |
| `rcrtAplyYn/useYn` | `"N"`/null | 모집/사용 |
| `teamSn/teamNm/teamStusCd/teamStusNm` | `<masked>`/`팀62`/`00002`/`학습시작` | 팀 상태(개인정보 가능) |
| `lrnBgngYmd/lrnEndYmd` | `2026-11-03`/`""` | 학습 시작/종료 |
| `mbrId/lrnrNm` | `<redacted>` | **개인식별정보, 문서화 금지** |
| `lockedYn`, `prevPjt*`, `nextPjt*` | `Y/N`, 번호/상태 | 잠금/순서 |
| `pjt*File*`, `pjtBgImg/pjtThumbImg` | number/url 후보 | 자료/이미지 |

---

## 3. `GET /learning/learningProgress/child/list`
학습맵/프로젝트 상세(코스 트리, 문항, 평가가이드, 팀/진도 보조).

- **URL**: `https://api.usr.codyssey.kr/learning/learningProgress/child/list`
- **Method**: `GET`
- **필수 Query(관찰)**: `lpNo` (예: `lpNo=158002`, 프로젝트 번호와 동일 값 관찰)
- **오류 관찰**: `lpNo` 없이 GET → 400 `"요청 처리 중 오류가 발생했습니다."`; `projectNo`만 GET → 400; POST `/child/list` → 404.
- **응답**: `result`

| `result` 필드 | 관찰 | 설명(추정) |
|---|---|---|
| `projectData` | object | 프로젝트/코스/문항 핵심 데이터 |
| `examList` | array | 시험/평가 항목(관찰 0) |
| `pjtProgressRate` | number | 프로젝트 진도율 |
| `qualGrntList` | array | 부여 자격 |
| `qualReqList` | array | 요구 자격 |
| `lockedYn` | `Y/N` | 잠금 |

### `result.projectData` 주요 필드(관찰)
`projectNo, projectNm, instCd, bgngYmd/endYmd, lcorsCnt, uqstnCnt, teamCnt, max/minTmbrNope, useYn, lcors[], lcorsNo/uqstnNo(현재), childProjects, myTeamMemberInfo/myTeamMeberList(오타 필드명 관찰), isEnded, closedYn, prev/nextPjt*, lockedYn, misTeamYn, isTestableYn, pjt*Image/Files, name/projectType` 등.

### `projectData.lcors[]` (코스)
`lcorsNo, lcorsNm, lcorsSqnt, lcorsDivCd/Nm, lcorsFildCd/Nm, periodWk, uqstnCnt, useYn, projectType/lcorsTypeCd, evlGuide, sklls, uqstns[]` 및 `cpblys, evlTypes, predTasks, qitems, sgstTasks, edus, pjtFile*`(빈 배열/null 관찰).

| `lcors.evlGuide` 키(관찰 일부) | 비고 |
|---|---|
| `evlGuideCn, osNm, prlngCd/Nm, uqstnUrlAddr` | 평가 가이드/환경 |
| `tstcdGuideFileSn,dckrFileSn,smlrtFileSn,cdCvrgFileSn,*Url` | 파일 참조 |
| `peer*/spclt*` (`EvlrNope, EvlImplHr, Rate, TrgtScope, RndmDsgn`) | 동료/전문가 평가 설정 |
| `smlrtChckRate, cdCvrgRate, exprcScr, evlScr, evlYn` | 평가 기준 |

| `lcors.sklls` 키(관찰) | 비고 |
|---|---|
| `skillNo, skllDesc, dvlpDesc, rstrtCondDesc, tcaseDesc` | 스킬/설명(긴 텍스트 가능) |

### `lcors.uqstns[]` / 학습맵 문항 요약
관찰 필드: `uqstnNo, uqstnNm, uqstnSqnt, uqstnForceEndYmd, useYn, uqstnResultYn(진행중 등), requireYn, uqstnFildNm, uqstnDivNm, uqstnLearningTm, uqstnDffly`.

관찰 예(AI 네이티브 입학 연수, `lpNo=158002`):
- `1143002 AI와 함께 만들기 연습` — `192011~192014` (4문항)
- `1143003 AI로 나만의 HTML 페이지 만들기` — `192017~192019` (3문항)

---

## 4. `GET /learning/learningProgress/progress/detail`
프로젝트 진도율.

- **URL**: `https://api.usr.codyssey.kr/learning/learningProgress/progress/detail`
- **Query(관찰)**: `projectNo=158002` (200). `projectNo` + `lpNo` 함께도 200 관찰.
- **응답(관찰)**:
```json
{ "code":200, "message":"OK", "errors":null, "result": { "progressRate": 0 } }
```

---

## 5. `GET /learning/learningProgress/status/list`
프로젝트 문항 진행 상태.

- **URL**: `https://api.usr.codyssey.kr/learning/learningProgress/status/list`
- **Method(관찰)**: **GET** 성공. POST(form/json, projectNo/lpNo 조합) probe는 404 관찰(미지원/파라미터 불일치 가능).
- **Query(관찰)**: `projectNo=158002`
- **응답**: `result.uqstns[]`, `result.childProjects`

| `uqstns[]` 필드(관찰) | 예시 |
|---|---|
| `lcorsNo/lcorsSqnt` | `1143002/1` |
| `uqstnNo/uqstnNm/uqstnSqnt` | `192011/.../1` |
| `uqstnResultYn` | `진행중` |
| `requireYn/useYn` | `Y` |
| `uqstnForceEndYmd` | ISO datetime 문자열 관찰 |
| `uqstnLearningTm` | `"1"`/`"2"`/`"4"` |
| `projectNo/projectNm` | `158002/...` |
| `uqstnDivNm/uqstnFildNm` | `입학 연수/입학연수` |

---

## 6. `GET /learning/learningProgress/lcors/detail`
코스(lcors) 상세.

- **URL**: `https://api.usr.codyssey.kr/learning/learningProgress/lcors/detail`
- **Query(관찰)**: `projectNo=158002&lcorsNo=1143002`
- **응답**: `result.lcors` (구조는 `child/list`의 `projectData.lcors[]` 항목과 유사: `evlGuide, sklls, uqstns[], pjtFile*, qitems/sgstTasks/predTasks/evlTypes/cpblys/edus` 등)

---

## 7. `GET /learning/learningProgress/uqstn/detail`
문항(uqstn/미션) 상세 + 팀.

- **URL**: `https://api.usr.codyssey.kr/learning/learningProgress/uqstn/detail`
- **Method(관찰)**: **GET** 성공. POST probe는 404.
- **Query(관찰)**: `projectNo=158002&lcorsNo=1143002&uqstnNo=192011`
- **응답**: `result.uqstn`, `result.uqstnTeam`

### `result.uqstn` 주요 필드(관찰)
식별/상태: `projectNo, lcorsNo, uqstnNo, uqstnNm, uqstnSqnt, uqstnResultYn(진행중), requireYn, useYn, missionStartHideYn, pendingInviteYn, projectType, name`
학습: `uqstnLearningTm, uqstnDffly, uqstnForceEndYmd, lrnBgngYmd/lrnEndYmd`
팀/구성: `teamComposition, min/maxTmbrNope, minRequiredMissionCnt, teamSn/Nm/StusCd, batForceEndYn`
콘텐츠/파일: `uqstnCn, pjtFile, pjtFileUrl, pjtFileDesc, pjtFileSn, pjtDef/CpblyDef/Tech/EvlGuide/PdfFileSn, pdfFile, uqstnPdfUrl`
평가/스킬: `evlGuide(object), evlTypes[], sklls(object: skillNo, skllDesc, dvlpDesc, rstrtCondDesc, tcaseDesc)`
기타: `qitems[], sgstTasks[], predTasks[], cpblys[], edus[]` (빈 배열 관찰), `lcorsTypeCd`, `reevlRejectReason`

### `result.uqstnTeam` (관찰)
`projectNo, lcorsNo, uqstnNo, mbrId(mask), leadrYn, teamSn, teamNm, teamStusCd/Nm, tmbrStusCd, teamComposition, lrnBgngYmd/lrnEndYmd, instCd, evlNo, inviteMbrIds, rejectRsn, uqstnTeamMembers[]`.
`uqstnTeamMembers[]` 키 관찰: `instCd, mbrId, lrnrNm, profImgPath, emlAddr, leadrYn, exp, level, tmbrStusCd, location, qualifiedYn, inviteDt` (**전원 개인정보 가능, 마스킹 필수**).


## 8. AI 챗봇/헬퍼(공통, `/learning/usr/ai/*`) API — 2026-11-06 관찰/검증
관찰 화면(공통 UI 진입점): `https://usr.codyssey.kr/learning/learningMap?projectNo=158002` 우측 AI 챗봇 패널, `https://usr.codyssey.kr/learning/ai-helper` AI 헬퍼 페이지. 두 화면 모두 채팅 UI(새로생성/세션 목록/입력/전송)와 동일한 세션 목록을 사용함을 확인(2026-11-06). `GET /learning/usr/ai/models|sessions|presets|token-usage|sessions/count|check-ip`는 `ai-helper` 페이지 컨텍스트에서도 200/동일 API로 확인.

방법: 브라우저 XHR 훅으로 요청/응답 캡처, 실제 테스트 메시지 전송, 재생성/중단 UI 동작 관찰, 안전한 GET/OPTIONS/검증용 POST probe 수행. `ask-stream`/`history`/세션 삭제 등 상태 변경·실전송 캡처는 **`learningMap` 패널 컨텍스트**에서 테스트 세션으로 수행(동일 `/learning/usr/ai/*` 엔드포인트). **개인식별정보/토큰/실제 사용자 대화 전문/프롬프트 원문은 문서화하지 않음.** 상태 변경 테스트(세션 생성/삭제)는 **본 관찰에서 생성한 테스트 세션만** 사용했고, 관찰 후 삭제 완료(`16921`,`16925` 등; 기존 사용자 세션 `16874,15933,15135` 불변 확인).

### 8.1 `GET /learning/usr/ai/models`
- **Query(관찰)**: 없음/`projectNo=158002` 모두 200.
- **응답(관찰)**: 배열. 항목 키: `modelCd, modelNm, providerCd, apiModelId, multiplier, maxTokens, temperature, isActive, sortOrder, reasoningEffort, apiMethod, timeoutMillis, maxRetries`.
- `providerCd`, `apiModelId` 등은 문서/공유 시 마스킹 권장.

### 8.2 `GET /learning/usr/ai/sessions`
- **Query(관찰)**: `sortDesc=true&limit=20&offset=0` 200; `projectNo=158002` 200; `sessionId=<id>`도 200(배열 형태 관찰).
- **응답(관찰)**: 배열. 항목 키: `sessionId, mbrId, title, lastModelCd, summary, isActive, regDt, modDt, msgCnt`.
- `mbrId` 마스킹 필수. `title`은 대화 내용 일부가 될 수 있어 공유 시 마스킹.

### 8.3 `GET /learning/usr/ai/sessions/count`
- **Query(관찰)**: 없음/`projectNo=158002` 200.
- **응답(관찰)**: `Content-Type: application/json`, body는 **숫자(JSON number)** 예: `3`, `4`. envelope 없음.

### 8.4 `GET /learning/usr/ai/presets`
- **Query(관찰)**: 없음/`projectNo=158002` 200.
- **응답(관찰)**: 배열 4건. 항목 키: `systemPrompt, sortOrd, presetCd, presetNm, presetDesc, summaryPrompt, summaryThreshold`.
- 관찰된 `presetCd`: `tutor(학습 튜터,sortOrd 1)`, `codeReview(코드 리뷰어,2)`, `debug(디버깅 전문,3)`, `concept(개념 설명,4)`, 각 `summaryThreshold=3000`. 프롬프트 원문은 정책/지침 포함 가능하므로 재배포 주의.

### 8.5 `GET /learning/usr/ai/token-usage`
- **Query(관찰)**: 없음/`projectNo=158002` 200.
- **응답(관찰)**: `{ "totalVirtualTokens": <number>, "tokenLimit": 1000000, "isBlocked": "N" }` (값 시점별 변동).

### 8.6 `GET /learning/usr/ai/history`
세션 대화 이력 조회.

- **URL**: `https://api.usr.codyssey.kr/learning/usr/ai/history?sessionId=<id>`
- **필수 Query(관찰)**: `sessionId`.
- **오류/권한(관찰)**: `sessionId` 없이 400 `"요청 처리 중 오류가 발생했습니다."`; 다른 사용/접근 불가 세션 등은 403 + `[]` 관찰(예: `999999999`).
- **페이지네이션 probe(관찰)**: `limit=1`, `offset=1`을 붙여도 테스트 세션에서는 전체 배열과 동일 길이/동일 선두 항목이 반환됨. **`limit/offset` 유효성은 미확정**(무시되거나 특정 조건에서만 동작 가능).
- **응답(관찰)**: 배열. 항목 공통 키: `regDt, role, msgType, logId, inputTokens, virtualTokens, sessionId, outputTokens, content`.
- **assistant 항목(관찰)**: `modelCd` 추가 키 존재. `role`은 `user|assistant`, `msgType`은 `text` 관찰.
- **개인정보/대화 내용**: `content`에 실제 대화가 포함되므로 문서/로그/공유 시 마스킹.

### 8.7 `POST /learning/usr/ai/ask-stream` (핵심, SSE)
실제 챗봇 전송/응답 API. 브라우저 XHR POST 관찰.

- **URL**: `https://api.usr.codyssey.kr/learning/usr/ai/ask-stream`
- **Request headers(관찰)**: `Content-Type: application/json; charset=UTF-8`, `Accept`에 SSE/JSON 허용 형태 관찰 가능, `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN: <token>`.
- **Request body(실캡처, 마스킹)**:
```json
{
  "sessionId": 16921,
  "modelCd": "gemini-3-flash",
  "mbrId": "<masked>",
  "systemPrompt": "<length observed>",
  "summaryPrompt": "<length observed>",
  "summaryTokenThreshold": 3000,
  "presetCd": "debug",
  "conversationSummary": null,
  "messages": [
    { "role": "user", "content": "...", "logId": 305107 },
    { "role": "assistant", "content": "...(이전 응답 전문)", "logId": 305108 },
    { "role": "user", "content": "...(현재 입력)" }
  ]
}
```
- **필수/검증(오류 probe 관찰, SSE `event:error`)**:
  - 비JSON/잘못된 요청 → `event:error` `data:잘못된 요청입니다.`
  - `messages` 없음/빈 배열 + `modelCd`/`systemPrompt` 누락 → `data:요청 검증 실패: messages: 메시지는 최소 1개 이상이어야 합니다., modelCd: 모델 코드는 필수입니다., systemPrompt: 시스템 프롬프트는 필수입니다.`
  - `messages`+`modelCd`만 있고 `systemPrompt` 누락 → `data:요청 검증 실패: systemPrompt: 시스템 프롬프트는 필수입니다.`
  - 검증 오류도 HTTP 200 + `text/event-stream`으로 반환될 수 있음(관찰).
- **새 세션 생성 흐름(확인)**: UI `새로생성` 클릭만으로는 서버 세션 생성 API 호출이 관찰되지 않음. 첫 메시지 전송 시 `sessionId:null`로 `ask-stream` 호출 → `event:done` payload의 `sessionId`로 실제 세션 ID 발급(테스트 세션 생성 후 삭제 검증 완료).
- **멀티턴/컨텍스트(관찰)**: 2번째 이후 요청에서 클라이언트가 `messages[]`에 이전 `user/assistant` 메시지(기존 `logId`, assistant `content` 전문 포함)와 현재 user 메시지를 함께 전송. `conversationSummary`는 `null` 관찰. `summaryPrompt`/`summaryTokenThreshold`가 함께 전달되므로, 긴 대화에서 요약 전환이 발생할 수 있으나 **실제 `conversationSummary`가 채워지는 임계 케이스는 본 관찰에서 미발생**.
- **학습 컨텍스트 필드(관찰 한계)**: 테스트 세션 캡처에서 `projectNo/lcorsNo/uqstnNo/pjtTeamSn` 등 학습 맵 컨텍스트 키는 request body에 관찰되지 않았음. 단, `learningMap` 화면이 `uqstn/detail?...&pjtTeamSn=...`를 로드하므로 서버/프롬프트 구성 경로는 별도일 수 있음(미확정).
- **SSE 응답(확인)**: `200`, `Content-Type: text/event-stream;charset=UTF-8`.
  - `event:delta` + `data:"..."` (텍스트 조각, 반복)
  - `event:done` + `data:{...}` JSON. 관찰 키: `answer, inputTokens, outputTokens, virtualTokens, modelCd, sessionId, userLogId, cacheCreationTokens, cacheReadTokens, codeExecutionIncluded`.
  - `event:error` + `data:...` (검증 오류 관찰).
- **후속 호출(관찰)**: 응답 후 `token-usage`, `sessions?sortDesc...`, `sessions/count` 재조회, 흐름에 따라 `check-ip`/`history` 재조회.
- **재생성(↻ 재생성, 관찰)**: UI 재생성 시 `ask-stream` 재호출. 캡처 예에서 `messages`는 해당 재생성 기준 사용자 메시지 맥락으로 전송됨(전체 히스토리 전체가 아닌 해당 턴 기준 관찰). `GET /history` 재조회. 테스트 세션 history에서 메시지 수가 증가하고 새 `logId`가 추가되는 케이스 관찰(기존 assistant를 동일 `logId`로 교체하는 동작은 미관찰).
- **중단(관찰)**: 스트리밍 중 중단 UI 클릭 시 별도 `stop/cancel/abort` API 호출은 캡처되지 않았고, XHR이 `status 0`으로 종료되는 패턴 관찰(클라이언트 abort/연결 종료 가능성). 서버 중단 엔드포인트 probe(`/learning/usr/ai/stop|cancel|abort`, `/ask-stream/stop|abort`)는 404.

### 8.8 `POST /learning/usr/ai/sessions/delete` (세션 삭제)
AI 챗봇 **세션(대화 세션)** 삭제. 대화 이력 일부 삭제가 아님.

- **실사용 호출(관찰)**: `POST /learning/usr/ai/sessions/delete?sessionId=<id>` (XHR), request body `null`/빈 값 관찰.
- **Headers(관찰)**: `X-Requested-With: XMLHttpRequest`, `X-XSRF-TOKEN` 필요. 토큰 없이 fetch 시 `403 {"code":403,"message":"CSRF_TOKEN_INVALID"}` 관찰.
- **Body 변형 probe(관찰)**: JSON body로 `sessionId` 전달 시 `400 "요청 처리 중 오류가 발생했습니다."` 관찰(실사용은 query).
- **Response(관찰)**: `200 application/json` `{"result":"OK"}`.
- **검증**: 테스트 세션 삭제 후 `sessions` 목록/사이드바에서 제거 확인, 기존 사용자 세션 불변.
- **주의**: UI 클릭/훅 환경에서 동일 POST가 중복 로그로 보일 수 있음(실서버 수신 횟수는 별도 검증 필요).

### 8.9 미관찰/제약(증거 기반)
아래는 “못 찾음”이 아니라, 본 세션에서 관찰/ probe한 결과와 제약을 명시한다.

| 항목 | 관찰/결과 | 제약 |
|---|---|---|
| 세션 제목 변경(rename)/메타 update | UI 더블클릭 시 rename API 호출 미관찰. `POST /sessions/rename`, `/sessions/update` probe 404. | UI 내부 구현/미노출 API 가능성은 배제 불가(증거 없음) |
| 세션 단건 상세 | `GET /sessions/{id}`, `/session?sessionId=` probe 404. | 실사용 조회는 `sessions` 목록/`history` |
| 메시지 목록 전용 경로 | `/sessions/{id}/messages`, `/message/list?sessionId=` probe 404. | 실사용 조회는 `history?sessionId=` |
| 대화 이력 일부/메시지 단건 삭제 | UI에서 기능 미발견. `DELETE/POST` 메시지 삭제 후보는 기존 사용자 데이터 손상 위험으로 실행하지 않음. | **파괴적 probe 미실행**(정당한 제약) |
| 서버 스트리밍 중단 API | `POST /stop|cancel|abort`, `/ask-stream/stop|abort` probe 404. 중단 시 XHR `status 0` 관찰. | 클라이언트 abort 방식으로 보이나 서버 내부 동작 미확정 |
| `conversationSummary` 채움 | request에서 `conversationSummary:null` 관찰, `summaryPrompt/threshold` 전달. | 요약 임계 도달 장문 세션 미생성(테스트 세션 오염/비용 고려) |
| `history` limit/offset | 파라미터 전달 시 200이나 테스트에서 전체 반환. | 페이지네이션 실제 적용 조건 미확정 |
| 학습 컨텍스트 body 필드 | ask-stream 캡처에 `projectNo/lcorsNo/uqstnNo/pjtTeamSn` 미관찰. | 프롬프트/서버측 주입 여부 미확정 |

### 8.10 추가 probe 결과(참고)
- `GET /learning/usr/ai/history?sessionId=<forbidden>` → 403 `[]`
- `OPTIONS /learning/usr/ai/ask-stream` 200, `OPTIONS /learning/usr/ai/sessions/delete` 200 (Allow 헤더 비어 있음 관찰)
- `POST /learning/usr/ai/sessions/delete` JSON body → 400

---

## 학습 네이티브(learningMap) / AI 헬퍼(ai-helper) 화면-API 대응 (관찰)
`/learning/learningMap?projectNo=...` 및 `/learning/ai-helper` 로드/사용 시 확인된 공통 AI API(`/learning/usr/ai/*`)와 학습맵 연계 API:
- `GET /learning/usr/ai/check-ip`
- `GET /learning/usr/ai/models`, `GET /learning/usr/ai/sessions?sortDesc&limit&offset`, `GET /learning/usr/ai/presets`, `GET /learning/usr/ai/token-usage`, `GET /learning/usr/ai/sessions/count`
- `GET /learning/usr/ai/history?sessionId=...` (세션 선택/열람 시)
- `GET /learning/learningProgress/child/list?lpNo=158002` (맵/코스/문항 구조)
- `GET /learning/learningProgress/uqstn/detail?...&pjtTeamSn=...` (문항/팀 컨텍스트 로드 관찰)
- 실사용: `POST(XHR) /learning/usr/ai/ask-stream` (SSE; 기존 세션/`sessionId:null` 신규 생성, 재생성, 검증오류 `event:error` 관찰), `POST(XHR) /learning/usr/ai/sessions/delete?sessionId=...` + `X-XSRF-TOKEN` (세션 삭제, 테스트 세션 확인). 두 호출 모두 `learningMap` 패널에서 캡처; 엔드포인트는 `ai-helper`와 공통 네임스페이스(`/learning/usr/ai/*`).
- 그 외 공통: 사용자정보, 알림/공지, 일정/포인트/배지 등.

---

## 미확인/추가 필요 (남은 범위)
- `lpNo` vs `projectNo` 정확한 의미 차이(관찰상 동일 값 케이스 존재).
- `child/list`, `lcors/detail`, `uqstn/detail`의 POST/다른 파라미터 조합, 권한/기관 조건.
- `learningProgress/team` 정상 호출 조건(직접 probe 401).
- 학습 **제출/답안/피드백/파일 업로드/진행 갱신(상태 변경)** API — 조회 중심 probe만 수행, 상태 변경 미실행(사용자 확인 필요).
- `qitems/sgstTasks/predTasks/cpblys/edus`가 채워지는 케이스 스키마.
- `status/list` GET 외 정식 메서드/필터.
- `myTeamMeberList` 필드명 오타(API 계약 vs 관찰).
- AI 챗봇: `conversationSummary` 실제 채워지는 장문/요약 임계 케이스, `history` 페이지네이션 실제 적용 조건, rename/메시지 일부 삭제의 서버 API 존재 여부(현 UI/안전 probe에서는 미관찰; 사용자 데이터 파괴적 probe 제외).

## 테스트/정리 메모 (2026-11-06)
- AI 챗봇 API 확인용으로 생성한 테스트 세션(`16901`,`16921`,`16925` 등)은 관찰 후 `POST /learning/usr/ai/sessions/delete?sessionId=...`(+`X-XSRF-TOKEN`)로 삭제 확인.
- 기존 사용자 세션(`16874,15933,15135`)은 조회만 수행, 변경/삭제 없음.
- 브라우저 페이지에 임시 XHR 캡처 훅을 설치했으므로, Codyssey 페이지 **새로고침** 시 원상 복구됨.
