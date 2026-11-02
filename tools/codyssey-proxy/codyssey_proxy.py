"""Unified proxy: Anthropic (Claude Code) + OpenAI compatible endpoints -> Codyssey gateway."""

import os
import sys
if hasattr(sys.stdout, 'reconfigure'):
    sys.stdout.reconfigure(encoding='utf-8', errors='replace')
    sys.stderr.reconfigure(encoding='utf-8', errors='replace')
os.environ.setdefault('PYTHONIOENCODING', 'utf-8')

# Load .env BEFORE importing server.fastapi (it reads env vars at import time)
try:
    from dotenv import load_dotenv
    load_dotenv(dotenv_path=os.path.join(os.getcwd(), ".env"))
except Exception:
    pass

import json
import httpx
from fastapi import Request, Response
from fastapi.responses import StreamingResponse
from server.fastapi import app  # claude-code-proxy provides the Anthropic side

GATEWAY = os.environ.get("OPENAI_API_BASE", "https://copa.codyssey.kr/v1").rstrip("/")
API_KEY = os.environ.get("OPENAI_API_KEY", "")


def _headers():
    return {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}


@app.get("/v1/models")
async def list_models():
    async with httpx.AsyncClient(timeout=30) as client:
        r = await client.get(f"{GATEWAY}/models", headers={"Authorization": f"Bearer {API_KEY}"})
    return Response(content=r.content, status_code=r.status_code, media_type="application/json")


@app.post("/v1/chat/completions")
async def chat_completions(request: Request):
    body = await request.body()
    try:
        payload = json.loads(body.decode("utf-8"))
    except Exception:
        payload = {}
    stream = bool(payload.get("stream", False))

    if not stream:
        async with httpx.AsyncClient(timeout=300) as client:
            r = await client.post(f"{GATEWAY}/chat/completions", content=body, headers=_headers())
        return Response(content=r.content, status_code=r.status_code, media_type="application/json")

    async def gen():
        async with httpx.AsyncClient(timeout=300) as client:
            async with client.stream("POST", f"{GATEWAY}/chat/completions", content=body, headers=_headers()) as r:
                async for chunk in r.aiter_bytes():
                    yield chunk

    return StreamingResponse(gen(), media_type="text/event-stream")


def run():
    import uvicorn
    host = os.environ.get("PROXY_HOST", "127.0.0.1")
    port = int(os.environ.get("PROXY_PORT", "8082"))
    uvicorn.run(app, host=host, port=port, log_level="warning")


if __name__ == "__main__":
    run()