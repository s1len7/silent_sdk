# codyssey-proxy

Codyssey 게이트웨이(`https://copa.codyssey.kr`) 앞단의 통합 프록시.
- `/v1/messages` (Anthropic, Claude Code 용) -> 게이트웨이로 변환 (claude-code-proxy 기반)
- `/v1/chat/completions`, `/v1/models` (OpenAI 호환, Cursor/Continue/codex 용) -> 게이트웨이로 패스스루

## 설치
```bash
pip install -e tools/codyssey-proxy
```

## 실행
```bash
codyssey-proxy
```
또는 `python -m` 형태로 `.env`가 있는 디렉터리에서 실행.

## 설정
`.env.example`을 `.env`로 복사 후 `OPENAI_API_KEY`에 Codyssey 키를 채웁니다.
