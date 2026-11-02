"""Command-line client for the Codyssey Public API."""

import base64
import json
import os
import time
from pathlib import Path
from typing import Iterator

import httpx
import typer
from rich.console import Console
from rich.markdown import Markdown

# 이 도구 폴더의 .env (저장소 .gitignore가 .env를 무시하므로 키가 git에 올라가지 않음)
CONFIG_PATH = Path(__file__).resolve().parent / ".env"
ENV_KEYS = {"api_key": "CODYSSEY_API_KEY", "base_url": "CODYSSEY_BASE_URL"}
DEFAULT_BASE_URL = "https://copa.codyssey.kr"
DEFAULT_CHAT_MODEL = "gpt-5-mini"
VIDEO_POLL_SECONDS = 5
VIDEO_TIMEOUT_SECONDS = 15 * 60

app = typer.Typer(help="Command-line client for the Codyssey Public API.")
config_app = typer.Typer(help="Manage the API key and base URL.")
app.add_typer(config_app, name="config")

console = Console()


# ===== 설정 =====

def read_env_file() -> dict:
    """.env의 KEY=VALUE 줄을 읽는다 (주석·빈 줄은 무시, 값을 감싼 따옴표는 뗌)."""
    values = {}
    if not CONFIG_PATH.exists():
        return values
    for line in CONFIG_PATH.read_text(encoding="utf-8").splitlines():
        line = line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", 1)
        values[key.strip()] = value.strip().strip("\"'")
    return values


def load_config() -> dict:
    """.env를 읽고, 환경 변수가 있으면 그 값을 우선한다. 빈 값은 없는 것으로 본다."""
    config = {"base_url": DEFAULT_BASE_URL, "api_key": None}
    file_values = read_env_file()

    for name, env_key in ENV_KEYS.items():
        value = os.environ.get(env_key) or file_values.get(env_key)
        if value:
            config[name] = value
    return config


def save_config(config: dict) -> None:
    """설정을 .env에 쓴다. 다른 키는 그대로 두고, API 키가 들어가므로 현재 사용자만 읽을 수 있게 한다."""
    values = read_env_file()
    for name, env_key in ENV_KEYS.items():
        if config.get(name):
            values[env_key] = config[name]
    lines = [f"{key}={value}" for key, value in values.items()]
    CONFIG_PATH.touch(mode=0o600, exist_ok=True)
    CONFIG_PATH.chmod(0o600)
    CONFIG_PATH.write_text("\n".join(lines) + "\n", encoding="utf-8")


# ===== API 클라이언트 =====

class ApiError(Exception):
    """API가 오류 응답을 돌려줄 때 발생한다."""


class CodysseyClient:
    def __init__(self, api_key: str, base_url: str) -> None:
        self.http = httpx.Client(
            base_url=base_url,
            headers={"Authorization": f"Bearer {api_key}"},
            timeout=httpx.Timeout(120.0, connect=10.0),
        )

    def _post(self, path: str, payload: dict) -> dict:
        response = self.http.post(path, json=payload)
        raise_for_error(response)
        return response.json()

    def _get(self, path: str) -> dict:
        response = self.http.get(path)
        raise_for_error(response)
        return response.json()

    def list_models(self) -> list:
        data = self._get("/v1/models")
        return [model["id"] for model in data.get("data", [])]

    # 채팅은 OpenAI 호환 엔드포인트 하나로 모든 채팅 모델(Claude·GPT·Gemini)을 쓴다
    def chat(self, model: str, messages: list) -> str:
        payload = {"model": model, "messages": messages}
        data = self._post("/v1/chat/completions", payload)
        return data["choices"][0]["message"]["content"]

    def chat_stream(self, model: str, messages: list) -> Iterator[str]:
        """답변을 생성되는 대로 조각씩 돌려준다 (SSE)."""
        payload = {"model": model, "messages": messages, "stream": True}
        with self.http.stream(
            "POST", "/v1/chat/completions", json=payload
        ) as response:
            if response.is_error:
                response.read()
                raise_for_error(response)

            for line in response.iter_lines():
                if not line.startswith("data:"):
                    continue
                chunk = line.removeprefix("data:").strip()
                if chunk == "[DONE]":
                    break
                choices = json.loads(chunk).get("choices") or [{}]
                text = choices[0].get("delta", {}).get("content")
                if text:
                    yield text

    def create_image(
        self, model: str, prompt: str, size: str, output: Path
    ) -> None:
        payload = {
            "model": model,
            "prompt": prompt,
            "size": size,
            "response_format": "b64_json",
        }
        data = self._post("/api/v1/images", payload)
        image_b64 = data["result"]["images"][0]["b64_json"]
        output.write_bytes(base64.b64decode(image_b64))

    def create_speech(
        self,
        model: str,
        text: str,
        voice: str,
        audio_format: str,
        output: Path,
    ) -> None:
        # format은 오디오 코덱, response_format은 전달 방식
        payload = {
            "model": model,
            "input": text,
            "voice": voice,
            "format": audio_format,
            "response_format": "b64_json",
        }
        data = self._post("/api/v1/audio/tts", payload)
        output.write_bytes(base64.b64decode(data["result"]["b64_json"]))

    def create_video(
        self,
        model: str,
        prompt: str,
        duration: int,
        resolution: str,
        aspect_ratio: str,
    ) -> str:
        """영상 작업을 시작하고 작업 ID를 돌려준다."""
        payload = {
            "model": model,
            "prompt": prompt,
            "durationSeconds": duration,
            "resolution": resolution,
            "aspectRatio": aspect_ratio,
        }
        data = self._post("/api/v1/videos", payload)
        return data["result"]["jobId"]

    def get_video_status(self, job_id: str) -> dict:
        return self._get(f"/api/v1/videos/{job_id}")["result"]

    def download_video(self, job_id: str, output: Path) -> None:
        # resultUrl은 웹 로그인 전용이므로 API 키로 받을 수 있는 download를 쓴다
        with self.http.stream(
            "GET", f"/api/v1/videos/{job_id}/download"
        ) as response:
            if response.is_error:
                response.read()
                raise_for_error(response)
            with output.open("wb") as file:
                for chunk in response.iter_bytes():
                    file.write(chunk)


def raise_for_error(response: httpx.Response) -> None:
    if response.is_error:
        raise ApiError(f"HTTP {response.status_code}: {response.text}")


def get_client() -> CodysseyClient:
    config = load_config()
    if not config["api_key"]:
        console.print(
            "[red]No API key.[/red] Run "
            "[bold]codyssey-cli config set-key[/bold] or set CODYSSEY_API_KEY."
        )
        raise typer.Exit(1)
    return CodysseyClient(config["api_key"], config["base_url"])


def stream_answer(client: CodysseyClient, model: str, messages: list) -> str:
    """답변을 받는 대로 출력하고, 전체 답변을 돌려준다."""
    parts = []
    for text in client.chat_stream(model, messages):
        console.print(text, end="", markup=False, highlight=False)
        parts.append(text)
    console.print()
    return "".join(parts)


# ===== 명령: config =====

@config_app.command("set-key")
def config_set_key() -> None:
    """Save your virtual API key."""
    api_key = typer.prompt("API key", hide_input=True)
    config = load_config()
    config["api_key"] = api_key
    save_config(config)
    console.print(f"Saved to {CONFIG_PATH}")


@config_app.command("show")
def config_show() -> None:
    """Show the current settings (key is masked)."""
    config = load_config()
    api_key = config["api_key"]
    masked = f"{api_key[:4]}…{api_key[-4:]}" if api_key else "(not set)"
    console.print(f"base_url: {config['base_url']}")
    console.print(f"api_key:  {masked}")


# ===== 명령: 모델·채팅 =====

@app.command()
def models() -> None:
    """List available models."""
    for model_id in get_client().list_models():
        console.print(model_id)


@app.command()
def ask(
    question: str,
    model: str = typer.Option(DEFAULT_CHAT_MODEL, "--model", "-m"),
    stream: bool = typer.Option(True, help="Print the answer as it arrives."),
) -> None:
    """Ask one question and print the answer."""
    client = get_client()
    messages = [{"role": "user", "content": question}]

    if stream:
        stream_answer(client, model, messages)
    else:
        console.print(Markdown(client.chat(model, messages)))


@app.command()
def chat(
    model: str = typer.Option(DEFAULT_CHAT_MODEL, "--model", "-m"),
    system: str = typer.Option(None, "--system", "-s", help="System prompt."),
) -> None:
    """Start an interactive chat. Type /exit to quit, /reset to clear."""
    client = get_client()
    messages = [{"role": "system", "content": system}] if system else []
    console.print(f"[dim]Model: {model}  |  /exit quit, /reset clear[/dim]")

    while True:
        try:
            user_input = console.input("[bold cyan]> [/bold cyan]").strip()
        except (EOFError, KeyboardInterrupt):
            break

        if user_input == "/exit":
            break
        if user_input == "/reset":
            # 시스템 프롬프트는 남기고 대화만 지운다
            messages = messages[:1] if system else []
            console.print("[dim]Conversation cleared.[/dim]")
            continue
        if not user_input:
            continue

        messages.append({"role": "user", "content": user_input})
        try:
            answer = stream_answer(client, model, messages)
        except ApiError as error:
            # 실패한 질문은 대화 기록에서 뺀다
            messages.pop()
            console.print(f"[red]{error}[/red]")
            continue
        messages.append({"role": "assistant", "content": answer})


# ===== 명령: 미디어 =====

@app.command()
def image(
    prompt: str,
    output: Path = typer.Option(Path("image.png"), "--output", "-o"),
    model: str = typer.Option("gpt-image-1-mini", "--model", "-m"),
    size: str = typer.Option("1024x1024"),
) -> None:
    """Generate an image."""
    with console.status("Generating image..."):
        get_client().create_image(model, prompt, size, output)
    console.print(f"Saved {output}")


@app.command()
def tts(
    text: str,
    output: Path = typer.Option(Path("speech.mp3"), "--output", "-o"),
    model: str = typer.Option("tts-1", "--model", "-m"),
    voice: str = typer.Option("alloy"),
    audio_format: str = typer.Option("mp3", "--format"),
) -> None:
    """Convert text to speech."""
    with console.status("Generating speech..."):
        get_client().create_speech(model, text, voice, audio_format, output)
    console.print(f"Saved {output}")


@app.command()
def video(
    prompt: str,
    output: Path = typer.Option(Path("video.mp4"), "--output", "-o"),
    model: str = typer.Option("veo-3.1-fast", "--model", "-m"),
    duration: int = typer.Option(4, help="Length in seconds."),
    resolution: str = typer.Option("720p"),
    aspect_ratio: str = typer.Option("16:9", "--aspect-ratio"),
) -> None:
    """Generate a video, wait until it is done, then download it."""
    client = get_client()
    job_id = client.create_video(
        model, prompt, duration, resolution, aspect_ratio
    )
    console.print(f"Job started: {job_id}")

    deadline = time.monotonic() + VIDEO_TIMEOUT_SECONDS
    with console.status("Generating video...") as status:
        while True:
            result = client.get_video_status(job_id)
            state = result.get("status", "")

            if state == "completed":
                break
            # 실패 상태 값은 문서에 없어서 fail·error가 들어가면 실패로 본다
            if "fail" in state or "error" in state:
                console.print(f"[red]Video job failed: {state}[/red]")
                raise typer.Exit(1)
            if time.monotonic() > deadline:
                console.print(
                    f"[yellow]Still running. Check later with: "
                    f"codyssey-cli video-get {job_id}[/yellow]"
                )
                raise typer.Exit(1)

            status.update(f"Generating video... {result.get('progress', 0)}%")
            time.sleep(VIDEO_POLL_SECONDS)

    client.download_video(job_id, output)
    console.print(f"Saved {output}")


@app.command("video-get")
def video_get(
    job_id: str,
    output: Path = typer.Option(Path("video.mp4"), "--output", "-o"),
) -> None:
    """Check a video job, and download it if it is finished."""
    client = get_client()
    result = client.get_video_status(job_id)
    state = result.get("status")
    console.print(f"status: {state}  progress: {result.get('progress')}")

    if state == "completed":
        client.download_video(job_id, output)
        console.print(f"Saved {output}")


def run() -> None:
    """설치된 codyssey-cli 명령의 진입점. API·네트워크 오류를 한 줄로 출력한다."""
    try:
        app()
    except ApiError as error:
        console.print(f"[red]{error}[/red]")
        raise SystemExit(1)
    except httpx.HTTPError as error:
        console.print(f"[red]Network error: {error}[/red]")
        raise SystemExit(1)


if __name__ == "__main__":
    run()
