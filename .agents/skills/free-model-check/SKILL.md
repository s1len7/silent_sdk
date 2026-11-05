---
name: free-model-check
description: 에이전트(OpenClaw, OpenCode 등)에 쓸 AI 모델을 고르거나 바꾸기 전에 사용. 무료로 답하는지와 도구 호출을 지원하는지 실제 요청으로 시험하고, 공통 규칙의 "AI 모델 선택" 순서로 비교·보고하는 절차.
---

# 무료 모델 시험

고르는 기준과 순서는 루트 AGENTS.md `### AI 모델 선택`을 따른다. 이 문서는 시험 방법만 담는다.

## 키

- `devices/desktop/.env`의 `GEMINI_API_KEY`, `OPENROUTER_API_KEY`를 읽어 요청 헤더로만 넘긴다 (URL·명령 인자에 넣지 않음)

## Gemini

```powershell
$key = ((Get-Content devices\desktop\.env | Where-Object { $_ -match '^GEMINI_API_KEY=' }) -replace '^GEMINI_API_KEY=','').Trim()
# 모델 목록
(Invoke-RestMethod "https://generativelanguage.googleapis.com/v1beta/models?pageSize=200" -Headers @{ 'x-goog-api-key' = $key }).models.name
# 도구 호출 시험 (functionCall이 오면 통과)
$body = @{
  contents = @(@{ role = 'user'; parts = @(@{ text = 'What time is it in Seoul? Use the tool.' }) })
  tools = @(@{ functionDeclarations = @(@{ name = 'get_time'; description = 'Get the current time in a city'
    parameters = @{ type = 'object'; properties = @{ city = @{ type = 'string' } }; required = @('city') } }) })
} | ConvertTo-Json -Depth 20
Invoke-RestMethod "https://generativelanguage.googleapis.com/v1beta/models/<model>:generateContent" -Method Post `
  -Headers @{ 'x-goog-api-key' = $key } -ContentType 'application/json' -Body $body -TimeoutSec 180
```

- 429의 응답 본문(`$_.Exception.Response.GetResponseStream()`)에 `..._free_tier_...` 한도가 보이면 무료 등급 키다. 무료 등급 키로 성공한 요청은 무료다
- 무료 한도는 모델마다 따로이고 태평양 시간 자정에 초기화된다. 숫자는 AI Studio(https://aistudio.google.com/rate-limit)에서만 보인다
- 같은 모델을 2~3번 시험해 응답 시간과 503(과부하)을 함께 본다

## OpenRouter

- 무료 모델(`:free`, `openrouter/free`)은 크레딧 구매 10 미만이면 하루 50회, 분당 20회, UTC 자정 초기화
- 키 상태: `Invoke-RestMethod https://openrouter.ai/api/v1/key -Headers @{ Authorization = "Bearer $key" }` (`is_free_tier`)

## 보고 형식

| 모델 | 무료 | 도구 호출 | 응답 시간 | 비고 (429/503, 한도) |
| --- | --- | --- | --- | --- |

- 문서로 확인한 한도와 직접 시험한 결과를 구분해 적는다
- OpenClaw에 적용하면 `openclaw-ops` 스킬의 모델 절차와 `setup-openclaw-gateway.ps1`도 함께 맞춘다
