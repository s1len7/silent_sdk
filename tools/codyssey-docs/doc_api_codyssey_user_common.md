# Codyssey 공통/사용자 API (관찰 기반)

여러 페이지에서 공통적으로 호출되는 읽기성 API.

## 1. `GET /rest/user/info/detail`
- **URL**: `https://api.usr.codyssey.kr/rest/user/info/detail`
- **Method**: `GET`
- **응답(관찰)**: 사용자 프로필/권한/기관/역할/메뉴 관련 정보. **개인정보 및 권한 정보 포함 가능** → 외부 공유/커밋 본문에 원문 기록 금지.
- **주요 필드 형태**: `roleNm`, `instList[]`, `roleList[]`, `roleMenu[]`, `mbrId`, `mbrNm`, `mbrStusCd` 등(관찰).

## 2. `GET /api/common/menu/my`
- **URL**: `https://api.usr.codyssey.kr/api/common/menu/my`
- **Method**: `GET`
- **용도**: 현재 사용자용 메뉴 구성 조회로 추정.

## 3. `GET /main/sidebar/new/detail`
- **URL**: `https://api.usr.codyssey.kr/main/sidebar/new/detail`
- **Method**: `GET`
- **용도**: 사이드바 신규 항목/배지/상태 조회로 추정.

## 4. `POST /myinfo/usr/list`
- **URL**: `https://api.usr.codyssey.kr/myinfo/usr/list`
- **Method**: `POST`
- **응답(관찰)**: 코드성 목록/내 정보 관련 데이터(`deLearningList`, `interestsCdList` 등). 사용자 정보 포함 가능.

## 5. `GET /point/exp/total/detail`
- **URL**: `https://api.usr.codyssey.kr/point/exp/total/detail`
- **Method**: `GET`
- **응답(관찰)**

| 필드 | 예시 |
|---|---|
| `level` | `0` |
| `nextLvlRequiredExprc` | `1000` |
| `exp` | `35` |
| `levelRegDt` | `null` |
| `levelViewYn` | `null` |

## 6. `GET /survey/gate/active`
- **URL**: `https://api.usr.codyssey.kr/survey/gate/active`
- **Method**: `GET`
- **응답(관찰)**

| 필드 | 설명 |
|---|---|
| `gateActive` | 게이트 활성 여부 |
| `blocked` | 차단 여부 |
| `surveySn/surveyNm/surveyUrl` | 설문 정보(활성 시) |
| `token` | 설문 토큰(민감 가능, 마스킹) |
| `delayNotice` | 지연 안내 여부 |

## 공통 관찰 헤더
- `Accept: application/json`
- `X-Requested-With: XMLHttpRequest`
- 일부 POST에서 `X-XSRF-TOKEN: <redacted>`
- `Referer: https://usr.codyssey.kr/`
- 인증은 브라우저 세션/쿠키 기반으로 보이며, 쿠키 값은 수집/기록하지 않음.

## 미확인
- 각 API의 필수 파라미터/권한별 응답 차이.
- `info/detail`/`myinfo/usr/list`의 개인정보 최소화 필요 필드(연동 구현 시).
- 토큰 갱신/세션 연장 API.
