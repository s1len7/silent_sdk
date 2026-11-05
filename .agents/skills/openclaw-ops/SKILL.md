---
name: openclaw-ops
description: 로컬 OpenClaw Gateway(desktop)를 점검·운영할 때 사용. Gateway·텔레그램 상태 확인, 꺼진 작업 복구, 모델·대체 모델 변경, 시험용 대화를 만들고 흔적 없이 지우는 법, 텔레그램 알림 보내기.
---

# OpenClaw 운영

desktop의 설치·설정은 `devices/desktop/scripts/setup-openclaw-gateway.ps1`이 맡는다. 설정을 바꿨으면 스크립트와 README도 같은 상태로 맞춘다.

## 상태 확인

```powershell
openclaw gateway status          # Gateway version, Connectivity check: ok
openclaw channels status         # Telegram: running, connected 이어야 정상
(Get-ScheduledTask -TaskName 'OpenClaw Gateway').State   # Disabled면 꺼진 것
openclaw models fallbacks list
openclaw config get agents.defaults.model.primary
```

- 실제 대화(`agent:main:main`)에 고정 모델이 있는지도 본다. 고정 모델은 실패해도 대체 모델로 넘어가지 않는다 (시험용 새 대화로는 드러나지 않음)
  ```powershell
  $j = (openclaw sessions --agent main --json --limit all 2>$null) -join "`n" | ConvertFrom-Json
  @(if ($j.sessions) { $j.sessions } else { $j }) | Where-Object key -eq 'agent:main:main' | Select-Object modelProvider, modelOverride
  ```
  - `modelOverride`가 있으면 사용자에게 보고하고, 풀 때는 그 대화에서 `/model default -s`를 보낸다
- 작업이 꺼져 있으면: `schtasks /Change /TN "OpenClaw Gateway" /ENABLE` 후 `schtasks /Run /TN "OpenClaw Gateway"`, 18789 포트가 열리는지 확인
- OpenClaw CLI를 업데이트하면(`npm i -g openclaw@latest`) Gateway 작업이 꺼질 수 있으니 위 상태를 다시 확인한다
- Gateway 안에서 일하는 OpenClaw 자신이 `gateway restart`를 하면 지금 대화가 끊긴다

## 모델

- 순서: 기본 `openrouter/free` → `google/gemini-3.6-flash` → `google/gemini-3.5-flash` → `google/gemini-3.5-flash-lite` (한도 초과 429나 과부하면 다음으로)
- 바꿀 때: `openclaw models set <id>`, `openclaw models fallbacks clear` 후 `openclaw models fallbacks add <id>`를 순서대로
- 새 모델은 먼저 `free-model-check` 스킬로 무료·도구 호출을 시험한다
- 원인 확인: `%TEMP%\openclaw\openclaw-<날짜>.log`에서 `rawErrorPreview` (예: `free-models-per-day`)

## 시험용 대화는 반드시 지운다

```powershell
$sid = "check-" + (Get-Date -Format 'yyyyMMddHHmmss')
openclaw agent --agent main --session-id $sid --message "Reply with exactly: OK" --json
# 끝나면 세 단계 모두
$key = "agent:main:explicit:$sid"
openclaw sessions delete $key --agent main --yes          # 목록에서 삭제 (기록은 .deleted 백업으로 남음)
openclaw memory forget --agent main --session $key        # 기억 색인 삭제
Get-ChildItem $env:USERPROFILE\.openclaw -Recurse -File | Where-Object Name -like "$sid*" | Remove-Item -Force
```

- `sessions archive`는 목록에서 빠지지 않으니 쓰지 않는다
- 마지막에 `openclaw sessions --agent main --json --limit all`에 `$sid`가 없는지 확인한다

## 텔레그램 알림

```powershell
openclaw message send --channel telegram --target <TELEGRAM_ALLOW_FROM> --message "<내용>" --json
```

- 대상 ID는 `devices/desktop/.env`의 `TELEGRAM_ALLOW_FROM`을 읽어 쓴다 (봇 토큰은 필요 없음)
- 사용자가 요청했을 때만 보낸다 (자동 알림 설정 없음)

## 휴대폰 앱 연결 (QR)

- 전제: `gateway.tailscale.mode=serve` (`setup-openclaw-gateway.ps1` 7단계), 이 PC와 휴대폰이 같은 Tailscale 계정
- 설정을 바꾸면(`openclaw config set ...`) Gateway가 스스로 다시 시작한다. 작업 스케줄러로 따로 재시작하지 않는다
- 먼저 QR이 가리키는 주소와 권한을 확인한다 (setup code는 출력하지 않는다)
  ```powershell
  $o = ((openclaw qr --json 2>$null) -join "`n") | ConvertFrom-Json
  "$($o.gatewayUrl) $($o.urlSource) access=$($o.access)"   # wss://<pc>.<tailnet>.ts.net, access=full 이어야 정상
  ```
- QR은 사용자 화면의 새 창에 띄운다 (도구 출력은 사용자에게 보이지 않음)
  ```powershell
  Start-Process powershell -ArgumentList '-NoExit', '-Command', "chcp 65001 > `$null; [Console]::OutputEncoding = [Text.Encoding]::UTF8; openclaw qr"
  ```
- `Gateway is only bound to loopback` 오류: Tailscale Serve가 꺼져 있거나 Tailscale HTTPS 인증서가 꺼져 있음 (`tailscale status --json`의 `CertDomains`가 비어 있음)
- `tailscale serve status`가 `No serve config`여도 `https://<pc>.<tailnet>.ts.net/`이 200이면 정상이다 (상태가 다르게 보이는 이유는 확인하지 못함)
- setup code는 잠깐만 유효하다 (공식 문서: short-lived). 스캔이 안 되면 `openclaw qr`을 다시 띄운다

## Windows에서 주의

- Gateway는 작업 스케줄러(S4U)로 세션 0에서 돌아서, OpenClaw가 띄운 크롬은 화면에 보이지 않는다. 화면은 `chrome://inspect`에 `localhost:18800`을 추가해 볼 수 있다
- PowerShell에서 `openclaw`의 stderr 경고가 오류로 바뀌므로 `try { ... } catch {}`로 감싸거나 `$ErrorActionPreference = 'Continue'`로 부른다
