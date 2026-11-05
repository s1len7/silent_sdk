---
name: dotenv-secret
description: 스크립트가 .env 파일의 비밀값(ID·비밀번호·토큰·API 키)을 화면·로그·문서에 남기지 않고 읽어 써야 할 때 사용. 매번 파싱 코드를 새로 쓰지 않도록 scripts/dotenv.ps1 또는 scripts/dotenv.sh를 불러 쓴다. 키가 있는지만 확인하거나, 값을 변수에만 담아 요청에 쓰는 경우에 쓴다.
---

# .env 비밀값 읽기

## 언제 쓰나
- 로그인·API 테스트처럼 저장된 자격증명이 필요한데, 값을 채팅·콘솔·로그에 남기면 안 될 때
- 사용자가 `.env`를 만들어 뒀고 키가 제대로 들어갔는지만 확인하고 싶을 때

## 어느 파일을 쓰나

| 환경 | 불러오기 |
|---|---|
| Windows (PowerShell 5.1 / pwsh 7) | `. "<스킬 경로>\scripts\dotenv.ps1"` |
| Linux · macOS · WSL · Git Bash | `. "<스킬 경로>/scripts/dotenv.sh"` |

두 구현은 같은 규칙으로 파싱하고 같은 일을 한다.

| 하는 일 | PowerShell | POSIX shell |
|---|---|---|
| 값 하나 | `Get-DotEnvValue -Path <f> -Key <k> [-Required]` | `dotenv_get <f> <k>` |
| 키 목록 | `Get-DotEnvKeys -Path <f>` | `dotenv_keys <f>` |
| 키 검사 | `Test-DotEnvKey -Path <f> -Key @('A','B')` | `dotenv_check <f> A B` |
| 전체 맵 | `Get-DotEnvMap -Path <f>` | 없음(필요하면 `dotenv_get` 반복) |

반환/종료 코드: 값이 없으면 PowerShell은 `$null`(`-Required`면 예외), shell은 종료 코드 `1`과 빈 출력.

### PowerShell

```powershell
. "C:\Users\silent\codyssey-ai-native-c2\.agents\skills\dotenv-secret\scripts\dotenv.ps1"

$id = Get-DotEnvValue -Path "docs\.env" -Key CODYSSEY_ID -Required
$pw = Get-DotEnvValue -Path "docs\.env" -Key CODYSSEY_PW -Required

Get-DotEnvKeys -Path "docs\.env"
(Test-DotEnvKey -Path "docs\.env" -Key @('CODYSSEY_ID','CODYSSEY_PW')).Missing
```

### POSIX shell

```sh
. "$REPO/.agents/skills/dotenv-secret/scripts/dotenv.sh"

id=$(dotenv_get "$REPO/docs/.env" CODYSSEY_ID)
pw=$(dotenv_get "$REPO/docs/.env" CODYSSEY_PW)

dotenv_keys "$REPO/docs/.env"
dotenv_check "$REPO/docs/.env" CODYSSEY_ID CODYSSEY_PW
```

`sorted` 대신 `sort -u`를 쓰므로 macOS·Linux 모두에서 동작한다. `awk`만 사용하고 GNU 전용 옵션은 쓰지 않는다.

## 지원하는 .env 형식
- `KEY=value`
- `#`로 시작하는 주석, 빈 줄
- `export KEY=value`
- 앞뒤 공백, 앞뒤 따옴표(`"`/`'`) 제거
- 값 안의 `=` 보존
- CRLF의 `\r` 제거

## 지킬 것
1. **값을 절대 출력하지 않는다.** `Write-Host`, `echo`, 로그, 예외 메시지, 문서 어디에도 넣지 않는다. 출력은 상태코드·헤더 **이름**·응답 **필드 이름**까지만.
2. **`read` 도구로 `.env`를 열지 않는다.** 대화 기록에 값이 남는다. 스크립트가 직접 읽는다.
3. 값을 출력해야 할 것 같으면 **존재 여부·길이·비교 결과(불리언)** 로 바꿔 출력한다.
4. 읽기 전에 커밋 대상이 아닌지 확인한다: `git check-ignore -v docs/.env`
5. 예외 메시지에 값이 섞이지 않게 `try/catch`에서 예외 종류와 상태코드만 출력한다.

## 함정 (실제로 겪은 것)
- **PowerShell 5.1은 BOM 없는 UTF-8 `.ps1`을 ANSI로 읽는다.** 한글 주석을 넣으면 파서 오류(`UnexpectedToken`)가 난다. `.ps1`은 ASCII로만 작성한다.
- **PowerShell 함수 안에서 `Write-Host` 대신 문자열을 그냥 출력하면 반환값에 섞인다.** `$session = New-Session`이 문자열 배열이 되어 이후 `-WebSession`에서 `ParameterBindingException`이 난다. 진행 로그는 `Write-Host`로, 반환은 `return`으로 분리한다.
- **`.sh`는 LF로 저장해야 한다.** Windows에서 편집하면 CRLF가 되어 `bash: \r: command not found`가 난다. `.gitattributes`에 `*.sh text eol=lf`가 있는지 확인한다.
- shell에서 `$(dotenv_get ...)`는 끝의 개행을 지운다. 값 끝 공백은 파서가 이미 제거하므로 문제되지 않는다.
- 값에 따옴표가 있으면 그대로 헤더/본문에 들어가 요청이 깨진다. 두 구현 모두 앞뒤 따옴표를 제거한다.
- PSCustomObject를 반환하는 함수는 `$x = f`로 받고 `$x.속성`으로 쓴다. 문자열 연결에 그대로 넣으면 `@{}`가 찍힌다.
