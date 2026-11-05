# Codyssey 인증/로그인/세션 API

## 결론
로그인 API 계약을 확인했고, **브라우저 없이 스크립트만으로 실제 계정 로그인에 성공**했다(세션으로 데이터 API `200` 응답까지 확인). 따라서 앱에서의 자동 로그인 구현은 **기술적으로 가능**하다.

단, 로그인 전 CSRF 토큰 부트스트랩이 필요하고, 5회 실패 시 30분 로그인 제한이 있으므로 자동 재시도는 금지한다.

## 로그인 계약

```http
POST https://api.ams.codyssey.kr/authenticate
Content-Type: application/x-www-form-urlencoded
X-Requested-With: XMLHttpRequest
X-XSRF-TOKEN: <XSRF-TOKEN 쿠키 값>

userId=<ID>&password=<PW>[&aliasNm=<역할>]
```

| 항목 | 내용 |
|---|---|
| 로그인 페이지 | `https://ams.codyssey.kr/loginForm` (SPA) |
| 인증 시작 | 비인증 상태로 `usr.codyssey.kr` 접근 시 `ams` 로그인으로 리다이렉트 |
| CSRF | 로그인 전 `api.ams.codyssey.kr`에서 `XSRF-TOKEN` 쿠키 발급. 요청 시 `X-XSRF-TOKEN` 헤더로 전송. 없으면 `403` |
| 요청 body | `userId`, `password`, 선택 `aliasNm`(다중 역할 계정) |
| 성공 | `200` + `Location: https://usr.codyssey.kr/main/` + `{"success":true,"memberType":"REGULAR"}` |
| 실패 | `401` `{"message_code":"E0000","success":false,...}` |
| 잠금 | 5회 실패 시 30분 로그인 제한(앱 번들 문구) |
| 세션 쿠키 | `JSESSIONID`(`Domain=codyssey.kr`, `Path=/`, `Secure`, `HttpOnly`), `XSRF-TOKEN`(`Domain=codyssey.kr`, `Path=/`, `Secure`) |
| 데이터 API | `api.usr.codyssey.kr` — 세션 쿠키 공유. 단 **`X-XSRF-TOKEN` 헤더 필수** |

## 데이터 API 호출 계약

```http
GET https://api.usr.codyssey.kr/rest/user/info/detail
X-Requested-With: XMLHttpRequest
X-XSRF-TOKEN: <로그인 후 재발급된 XSRF-TOKEN 쿠키 값>
Origin: https://usr.codyssey.kr
Referer: https://usr.codyssey.kr/
```

- `XSRF-TOKEN`은 **로그인 성공 시 교체**된다. 로그인 전 값을 그대로 쓰면 안 되고, 쿠키에서 다시 읽어야 한다.
- `X-XSRF-TOKEN` 헤더를 빼면 세션이 유효해도 `403`이 온다(실측).

## 실측 결과

| 케이스 | 결과 |
|---|---|
| XSRF 토큰 없이 `POST /authenticate` | `403` |
| 잘못된 계정 | `401` `E0000` |
| 빈 ID/PW | `200` + `Location: /pwd/pwdChgInfo` (비정상 케이스, 계약 판단에 사용하지 않음) |
| 실제 브라우저 로그인 | 성공, 최종 `https://usr.codyssey.kr/main/` |
| **스크립트(HTTP 클라이언트)만으로 로그인** | **성공** — `200`, `Location: https://usr.codyssey.kr/main/`, `memberType: REGULAR` |
| 위 세션으로 `GET /rest/user/info/detail` | **`200`** (응답 12KB대) |
| 위 세션에서 `X-XSRF-TOKEN` 헤더 생략 | `403` |

검증 환경: PowerShell 5.1 `Invoke-WebRequest` + `WebRequestSession`(쿠키 자동 관리). 브라우저·확장·화면 렌더링 없이 순수 HTTP 요청만 사용했다.

## 미확인
| 항목 | 비고 |
|---|---|
| `aliasNm` 필요 조건 | 다중 역할 계정에서 역할 선택이 필요한지 (이번 계정은 `REGULAR`로 로그인) |
| `memberType` 값 종류 | `REGULAR`(일반) 외 `AMS` 응답도 관찰. 값별 분기 의미는 미확인 |
| 로그아웃/세션 갱신 계약 | `POST /logout`은 번들에서 관찰, 실행/응답 미확인 |
| 세션 만료 시각 | `JSESSIONID`는 세션 쿠키(브라우저 종료 시 소멸). 서버측 만료 시간 미확인 |
| SSO/MFA/CAPTCHA | 로그인 폼에는 없음. 향후 정책 변경 가능 |
| 이용약관/권한 범위 | 자동 로그인 허용 여부 별도 확인 |

## 권장 구현 방식(앱)

1. **앱 시작** → 저장된 `JSESSIONID`로 데이터 API 1회 조회 → `200`이면 그대로 사용(비밀번호 미사용)
2. **만료(401/403 또는 로그인 리다이렉트)** → 아래 순서로 1회만 재로그인
   1. `GET https://api.ams.codyssey.kr/rest/api/auth/status` → `XSRF-TOKEN` 쿠키 획득 (로그인 횟수와 무관)
   2. `POST /authenticate` (form-urlencoded, `X-XSRF-TOKEN` 헤더) **1회**
   3. 쿠키 저장소에서 **교체된 `XSRF-TOKEN`을 다시 읽는다**
   4. 이후 모든 `api.usr` 호출에 `X-XSRF-TOKEN` 헤더를 붙인다
3. **실패 처리**: `401`이면 즉시 중단하고 사용자에게 알린다. 자동 재시도 금지(5회 실패 시 30분 잠금). 네트워크 오류만 별도로 1회 재시도.
4. **자격증명 저장**: iOS Keychain / Android Keystore. 평문 파일·메모 저장 금지. 세션 쿠키만 저장하고 비밀번호는 만료 시에만 꺼내는 방식을 권장.
5. **플랫폼 제약**: 네이티브/React Native/Flutter는 그대로 가능. 웹/PWA는 브라우저 CORS 정책 때문에 프록시 서버가 필요하다.

## 보안/준수 제약
- 비밀번호, OTP, 쿠키, 세션, `X-XSRF-TOKEN` 실값을 저장/공유/커밋하지 않는다.
- 캡차 우회, 인증 우회, 무차별 대입, 속도 제한 회피를 시도하지 않는다.
- 사용자 본인 계정/권한 범위 내 읽기 관찰만 수행한다.
- 자동 로그인 구현 시 실패는 1회에서 중단한다(잠금 방지).
