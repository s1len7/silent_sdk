# codyssey-cli

Codyssey Public API(`https://copa.codyssey.kr`)를 쓰는 명령줄 도구

> 상태: 있는 그대로(as-is) 올린 초기 버전. 2026-11-02 실제 API로 `models`·`ask`·`chat`·`image`·`tts`는 동작 확인, `video`는 서버의 미디어 provider 오류(HTTP 503)로 확인하지 못함

- 채팅은 OpenAI 호환 엔드포인트(`/v1/chat/completions`) 하나로 모든 채팅 모델(Claude·GPT·Gemini)을 씀
- 모델 ID와 차감 배수는 Codyssey API 콘솔의 모델 표 참고


## 설치

저장소 루트에서:

```bash
pip install -e tools/codyssey-cli
codyssey-cli config set-key claude
codyssey-cli config set-key openai
```

- Codyssey는 Claude용·OpenAI용 키를 따로 발급함. `claude-*` 모델은 `CODYSSEY_ANTHROPIC_API_KEY`, 나머지 모델은 `CODYSSEY_OPENAI_API_KEY`를 씀
- API 키는 이 폴더의 `.env`에 저장됨 (git에 올라가지 않음, 현재 사용자만 읽기 가능). 직접 쓰려면 [.env.example](.env.example)을 `.env`로 복사해 값을 채움
- 파일 대신 같은 이름의 환경 변수를 써도 됨 (환경 변수가 우선)


## 사용법

```bash
codyssey-cli models
codyssey-cli ask "파이썬 데코레이터 설명해줘" -m claude-sonnet-4
codyssey-cli chat -m gpt-5-mini -s "You are a helpful tutor."
codyssey-cli image "흰 배경의 파란 원" -o circle.png
codyssey-cli tts "안녕하세요" -o hello.mp3 --voice alloy
codyssey-cli video "제품 소개 영상" -o promo.mp4
codyssey-cli video-get <jobId>
```

| 명령 | 내용 |
| --- | --- |
| `config set-key claude\|openai` / `config show` | API 키 저장 / 현재 설정 보기 (키는 가려서 표시) |
| `models` | 사용 가능한 모델 목록 |
| `ask` | 질문 하나에 답변 (기본 모델 `gpt-5-mini`) |
| `chat` | 대화 이어가기 (`/reset` 대화 지우기, `/exit` 종료) |
| `image` | 이미지 생성 |
| `tts` | 텍스트를 음성으로 변환 |
| `video` | 영상 생성 후 끝날 때까지 기다렸다가 내려받기 (최대 15분) |
| `video-get` | 영상 작업 상태 확인, 끝났으면 내려받기 |

- 스트리밍 답변이 안 되는 모델은 `ask --no-stream` 사용
- 각 명령의 옵션은 `codyssey-cli <명령> --help` 참고


## OpenCode에서 쓰기

OpenCode 전역 설정(`~/.config/opencode/opencode.json`)에 OpenAI 호환 공급자로 추가하고, `opencode auth login` → Other → id `codyssey`로 키를 등록함

```json
{
  "provider": {
    "codyssey": {
      "npm": "@ai-sdk/openai-compatible",
      "name": "Codyssey",
      "options": { "baseURL": "https://copa.codyssey.kr/v1" },
      "models": { "gemini-3-flash": { "name": "gemini-3-flash" } }
    }
  }
}
```

- 2026-11-02 OpenCode 1.19.5 기준 Gemini 모델만 동작함
  - GPT-5 계열: OpenCode가 `reasoning_effort`를 넣는데 Codyssey가 지원하지 않음 (`unsupported_feature`)
  - Claude 계열: OpenCode가 메시지에 `cache_control`을 붙이는데 Codyssey가 지원하지 않음 (`unsupported_feature`)
  - 둘 다 OpenCode가 모델 ID로 정하는 동작이라 설정으로 끌 수 없음
