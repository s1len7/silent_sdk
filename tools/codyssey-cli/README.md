# codyssey-cli

Codyssey Public API(`https://copa.codyssey.kr`)를 쓰는 명령줄 도구

> 상태: 있는 그대로(as-is) 올린 초기 버전. `models`·`ask`만 실제 API로 확인했고, 나머지 명령은 테스트 중

- 채팅은 OpenAI 호환 엔드포인트(`/v1/chat/completions`) 하나로 모든 채팅 모델(Claude·GPT·Gemini)을 씀
- 모델 ID와 차감 배수는 Codyssey API 콘솔의 모델 표 참고


## 설치

저장소 루트에서:

```bash
pip install -e tools/codyssey-cli
codyssey-cli config set-key
```

- API 키는 이 폴더의 `.env`에 `CODYSSEY_API_KEY`로 저장됨 (git에 올라가지 않음, 현재 사용자만 읽기 가능). 직접 쓰려면 [.env.example](.env.example)을 `.env`로 복사해 값을 채움
- 파일 대신 환경 변수 `CODYSSEY_API_KEY`, `CODYSSEY_BASE_URL`을 써도 됨 (환경 변수가 우선)


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
| `config set-key` / `config show` | API 키 저장 / 현재 설정 보기 (키는 가려서 표시) |
| `models` | 사용 가능한 모델 목록 |
| `ask` | 질문 하나에 답변 (기본 모델 `gpt-5-mini`) |
| `chat` | 대화 이어가기 (`/reset` 대화 지우기, `/exit` 종료) |
| `image` | 이미지 생성 |
| `tts` | 텍스트를 음성으로 변환 |
| `video` | 영상 생성 후 끝날 때까지 기다렸다가 내려받기 (최대 15분) |
| `video-get` | 영상 작업 상태 확인, 끝났으면 내려받기 |

- 스트리밍 답변이 안 되는 모델은 `ask --no-stream` 사용
- 각 명령의 옵션은 `codyssey-cli <명령> --help` 참고
