"""Unified proxy: Anthropic (Claude Code) + OpenAI compatible endpoints -> Codyssey gateway."""

import json
import os
import sys
import urllib.error
import urllib.request

if hasattr(sys.stdout, "reconfigure"):
    sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    sys.stderr.reconfigure(encoding="utf-8", errors="replace")
os.environ.setdefault("PYTHONIOENCODING", "utf-8")

# Load .env before validating and selecting the gateway key.
try:
    from dotenv import load_dotenv

    load_dotenv(dotenv_path=os.path.join(os.getcwd(), ".env"))
except Exception:
    pass

raw_base = os.environ.get("CODYSSEY_BASE_URL", "https://copa.codyssey.kr")
GATEWAY = raw_base.strip().rstrip("/")
if not GATEWAY.endswith("/v1"):
    GATEWAY += "/v1"

API_KEY = (os.environ.get("CODYSSEY_OPENAI_API_KEY") or "").strip()


def _key_valid(key):
    if not key:
        return False
    try:
        request = urllib.request.Request(
            f"{GATEWAY}/models",
            headers={"Authorization": f"Bearer {key}"},
        )
        with urllib.request.urlopen(request, timeout=10) as response:
            return response.status == 200
    except urllib.error.HTTPError as error:
        return error.code not in (401, 403)
    except Exception:
        return False


if not _key_valid(API_KEY):
    raise RuntimeError("No valid Codyssey OpenAI-compatible API key found")

# claude-code-proxy reads these values when it is imported. They are internal
# compatibility variables, not user-facing configuration keys.
os.environ["OPENAI_API_KEY"] = API_KEY
os.environ["OPENAI_API_BASE"] = GATEWAY

import httpx
from fastapi import Request, Response
from fastapi.responses import StreamingResponse
from server.fastapi import app


def _headers():
    return {"Authorization": f"Bearer {API_KEY}", "Content-Type": "application/json"}


@app.get("/v1/models")
async def list_models():
    async with httpx.AsyncClient(timeout=30) as client:
        response = await client.get(
            f"{GATEWAY}/models", headers={"Authorization": f"Bearer {API_KEY}"}
        )
    return Response(
        content=response.content,
        status_code=response.status_code,
        media_type="application/json",
    )


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
            response = await client.post(
                f"{GATEWAY}/chat/completions", content=body, headers=_headers()
            )
        return Response(
            content=response.content,
            status_code=response.status_code,
            media_type="application/json",
        )

    async def generate():
        async with httpx.AsyncClient(timeout=300) as client:
            async with client.stream(
                "POST", f"{GATEWAY}/chat/completions", content=body, headers=_headers()
            ) as response:
                async for chunk in response.aiter_bytes():
                    yield chunk

    return StreamingResponse(generate(), media_type="text/event-stream")


def run():
    import uvicorn

    host = os.environ.get("PROXY_HOST", "127.0.0.1")
    port = int(os.environ.get("PROXY_PORT", "8082"))
    uvicorn.run(app, host=host, port=port, log_level="warning")


if __name__ == "__main__":
    run()
