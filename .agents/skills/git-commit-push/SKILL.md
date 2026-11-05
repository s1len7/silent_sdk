---
name: git-commit-push
description: silent_sdk(또는 그 파생 저장소)에서 커밋·푸시를 요청받았을 때 사용. 작성자 설정, 여러 작업이 섞인 파일에서 일부만 커밋하는 법, 푸시 전 동기화 절차를 담음.
---

# 커밋과 푸시

규칙(언제 커밋·푸시하는지, 작성자, 공동 작성자 줄, 충돌 처리)은 루트 AGENTS.md를 따른다. 이 문서는 절차만 담는다.

## 자동 진행 조건

- 사용자가 "밤새 작업", "자동으로 진행"처럼 자동 진행을 명시적으로 지시한 경우에만 여러 기능을 연속으로 커밋·푸시한다.
- 그 외에는 요청받은 커밋·푸시만 수행하고, 완료 후 다음 작업은 사용자 확인을 받는다.
- 자동 진행 범위가 애매하면 푸시 전에 확인한다.

## 작성자 지정

- 작성자와 커미터를 함께 지정: `git -c user.name=silent -c user.email=20176737+s1len7@users.noreply.github.com commit ...`
- 메시지 형식은 `git log --oneline -5`로 기존 커밋을 보고 맞춘다
- 커밋 후 `git log -1 --format='%an <%ae> | %cn <%ce>%n%B'`로 작성자와 메시지를 확인한다

## 커밋 전 확인

1. `git status --short`와 `git diff --cached --stat`로 이미 staged된 다른 작업이 있는지 본다
2. 요청 범위의 파일·변경을 고른다 (`git diff -- <path>`로 파일마다 다른 작업이 섞였는지 확인)
3. `git diff --cached`로 담길 내용을 마지막으로 확인한다

## 한 파일에 여러 작업이 섞였을 때

대화형 `git add -p`는 쓸 수 없으므로 임시 index를 쓴다. 사용자의 staged 상태는 그대로 둔다.

1. 담을 내용만 반영한 파일 내용을 만들어 `git hash-object -w --no-filters --stdin`으로 blob을 만든다 (LF 기준)
2. `GIT_INDEX_FILE=<임시 경로> git read-tree HEAD` 후 `git update-index --add --cacheinfo 100644,<sha>,<path>`
3. 같은 `GIT_INDEX_FILE`로 `git diff --cached HEAD`를 확인하고 커밋한다
4. 원래 index에서 이번에 커밋한 파일을 새 HEAD 기준으로 맞춘다
   - 원래 staged가 없던 파일: `git reset -q -- <path>`
   - staged 내용이 있던 파일: 그 staged 내용에 이번 변경을 더한 blob으로 `git update-index --cacheinfo`
5. `git diff --cached --stat`이 커밋 전의 staged 상태와 같은지 확인한다

여러 기능을 차례로 커밋할 때는 원래 index를 그대로 쓰고(staged가 비어 있을 때), 파일마다 index 내용에 이번 기능의 줄만 끼워 넣는 Python 도우미를 `tmp/`에 만들어 쓴다

- index 내용은 `git show :<path>`로 읽는다. 이 저장소의 기존 blob은 CRLF인 파일이 있으므로 index 내용의 줄바꿈을 그대로 유지하고 `git hash-object -w --no-filters --stdin`으로 쓴다
- 끼워 넣을 줄은 작업 트리 파일에서 표시 문자열(고유한 문장 일부)로 찾아 가져온다. 표시 문자열이 한 번만 나오는지 assert로 확인한다
- `git update-index --cacheinfo 100644,<sha>,<path>` 후 `git diff --cached`로 담긴 줄을 보고 커밋한다
- 기능 하나만 바뀐 파일은 그냥 `git add`
- 마지막 커밋 뒤 `git status --short`에 남은 변경이 사용자 작업뿐인지 확인하고 도우미를 지운다
- Python 문자열에 Windows 경로·`\` 가 들어가면 `\U`, `\s` 같은 이스케이프 오류가 나므로 heredoc(`<<'EOF'`)으로 파일을 만들고 문자열은 raw로 쓰거나 `\\`로 적는다

## 푸시

1. `git fetch origin` 후 `git log --oneline HEAD..origin/main`으로 원격에 새 커밋이 있는지 본다
2. 새 커밋이 있으면 `git merge origin/main` (또는 `git pull`). 충돌 파일은 `git diff --name-only --diff-filter=U`로 확인한다
3. `git push origin main`
4. 보고: 커밋 해시, 담긴 파일, 일부러 뺀 변경, 남은 미커밋 변경

## 비밀값 처리

- 커밋/푸시 전 git diff --cached와 관련 출력에 API 키, 토큰, 비밀번호, 암호화 키 등 비밀값이 포함되지 않았는지 확인한다.
- 비밀값이 포함된 변경은 커밋하지 않고, 노출이 발생하면 사용자에게 보고한 뒤 진행 방법을 확인한다.
- 명령 출력에 비밀값이 포함될 수 있으면 원문 대신 마스킹된 요약만 보여준다.