---
name: ps-setup-module
description: silent_sdk의 Windows setup 모듈(devices/desktop/scripts, devices/generic-windows/scripts의 setup-<기능>.ps1)을 새로 만들거나 고칠 때 사용. 템플릿, Windows PowerShell 5.1 함정, 검증 절차를 담음.
---

# Windows setup 모듈 작성

규칙은 루트·`devices/desktop`·`devices/generic-windows`의 AGENTS.md를 따른다. 이 문서는 그 규칙을 지키는 방법만 담는다.

## 템플릿

```powershell
# <한 줄 요약>. Run as admin.
# <단계 흐름: A -> B -> C>

$ErrorActionPreference = 'Stop'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$logDir = if ($env:SILENT_SDK_LOG_DIR) { $env:SILENT_SDK_LOG_DIR } else { $env:TEMP }

function Test-Installed { ... }
function Test-Configured { ... }

if ((Test-Installed) -and (Test-Configured)) {
    Write-Host '<Feature> is already set up, skipped'
    $global:SetupStepSkipped = $true
    return
}

# 설치는 설치가 빠졌을 때만 (설정만 빠졌으면 다시 설치하지 않음)
if (-not (Test-Installed)) { ... }
if (-not (Test-Configured)) { ... }
Write-Host '<Feature> setup done'
```

- generic-windows 모듈을 부르는 장비: `grep -rn "setup-<기능>.ps1" devices/*/setup.ps1`

## Windows PowerShell 5.1 함정

- 편집 도구가 LF로 저장하면 CRLF로 다시 맞춘다
  ```powershell
  $t = [IO.File]::ReadAllText($f) -replace "`r?`n", "`r`n"
  [IO.File]::WriteAllText($f, $t, (New-Object Text.UTF8Encoding($false)))
  ```
- `$ErrorActionPreference = 'Stop'`에서는 외부 프로그램의 stderr 한 줄(경고 포함)이 종료 오류가 된다
  - 외부 명령을 감싼 함수 안에서만 `'Continue'`로 바꾸고, 실패는 `$LASTEXITCODE`로 판단한다
  - npm으로 설치된 `.ps1` 실행 파일(openclaw 등)과 `2>&1`, `2>$null` 모두 해당된다
- `.cmd` 실행 파일은 cmd를 거쳐 부르면 stderr가 오류로 바뀌지 않는다
  ```powershell
  $out = cmd /c "`"$path`" $arguments 2>&1"
  ```
- 파일 쓰기는 `[IO.File]::WriteAllText($path, $text, (New-Object Text.UTF8Encoding($false)))` (Set-Content는 ANSI, Out-File은 BOM)
- `ConvertTo-Json`은 `-Depth`를 충분히 준다 (기본 2)
- 비밀값을 받는 명령은 stdin으로 넘기고, 그 명령의 출력은 버린다 (값이 되풀이돼 찍힐 수 있음)

## 검증 절차

1. ASCII 확인: `@([IO.File]::ReadAllBytes($f) | Where-Object { $_ -gt 127 }).Count`가 0
2. 문법 확인: `[Management.Automation.Language.Parser]::ParseFile($f, [ref]$null, [ref]$errs)`의 `$errs.Count`가 0
3. PSScriptAnalyzer: 시스템에 설치하지 말고 `tmp/`에 받아 쓴다
   - `Invoke-WebRequest https://www.powershellgallery.com/api/v2/package/PSScriptAnalyzer -OutFile tmp\pssa.zip` 후 압축을 풀어 `Import-Module`
   - `PSAvoidUsingWriteHost`, `PSAvoidGlobalVars`(`$global:SetupStepSkipped`)는 저장소 관례라 무시
4. 이미 설정된 PC에서 실행 → SKIP과 `$global:SetupStepSkipped = True` 확인
5. 설정 하나만 일부러 빼고 실행 → 그 단계만 진행되는지 확인 (설치 단계가 다시 돌면 안 됨)
6. 처음 설치 경로는 프로그램을 지워야 시험할 수 있으므로, 못 한 경우 그 사실을 보고에 남긴다
