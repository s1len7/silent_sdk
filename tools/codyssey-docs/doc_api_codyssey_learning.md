# Codyssey 학습 진행 API (관찰 기반)

## 관찰 화면
- `https://usr.codyssey.kr/learning/learningProgress/list`

## 1. `POST /learning/learningProgress/allLearningList`
학습 진행 목록 조회.

- **URL**: `https://api.usr.codyssey.kr/learning/learningProgress/allLearningList`
- **Method**: `POST`
- **Content-Type(관찰)**: `application/x-www-form-urlencoded`
- **Body**: 관찰상 빈 요청(`body_kind: empty`).
- **응답**: `result.learningList[]`, `result.lockedPjtViewYn`, `result.totalCnt`, `result.holyGraph`

| `learningList[]` 필드(관찰) | 설명 |
|---|---|
| `projectNo` | 프로젝트 ID |
| `projectNm` | 학습단계명 |
| `instCd` | 기관 코드 |
| `bgngYmd/endYmd` | 과정 기간 |
| `lcorsCnt` | 코스 수(문자열 관찰) |
| `lcorsDivCd/Nm`, `lcorsFildCd/Nm` | 분류 |
| `mbrId` | 개인 식별자(민감, 문서화 시 마스킹) |
| `lrnrNm` | 학습자명(민감) |
| `teamSn/teamNm/teamStusCd/teamStusNm` | 팀/상태 |
| `lrnBgngYmd/lrnEndYmd` | 학습 시작/종료 |
| `lockedYn`, `prev/next*` | 잠금/순서 관련 |

## 미확인
- 목록 필터/정렬/페이징 파라미터.
- 학습 상세, 과제 상세, 진도 갱신 API.
- `mbrId`가 서버에서 세션 기반으로 강제되는지, 클라이언트 입력값인지.
