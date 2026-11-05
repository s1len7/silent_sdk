---
name: oss-review
description: 오픈소스(라이브러리, CLI, 앱, 확장, 컨테이너 이미지)를 새로 고르거나, 이미 쓰는 것을 설치·업데이트·제거하기 전에 사용. 공식 여부, 인기, 유지보수 상태, 같은 이름의 다른 프로젝트, 공식 설치 방법을 확인하는 절차.
---

# 오픈소스 확인

고르는 기준과 보고·확인이 필요한 경우는 루트 AGENTS.md의 오픈소스 규칙을 따른다. 이 문서는 확인하는 방법만 담는다.

## 절차

1. **공식 저장소 찾기**: 공식 사이트·패키지 레지스트리(npm, PyPI, winget, Docker Hub)의 저장소 링크를 따라간다
2. **공식 README의 설치 안내를 먼저 읽는다**
   - 설치 방법이 여러 개면 각각의 대상(데스크톱 / 서버·CI 등)을 확인한다
   - GitHub releases에 파일이 없다고 비공식으로 판단하지 않는다 (앱은 별도 저장소·사이트에서 배포하기도 함)
3. **인기와 유지보수 상태**
   ```bash
   gh api repos/<owner>/<repo> --jq '{stars: .stargazers_count, archived, pushed_at, open_issues: .open_issues_count, license: .license.spdx_id}'
   gh api 'repos/<owner>/<repo>/releases?per_page=3' --jq '.[] | "\(.tag_name) \(.published_at)"'
   ```
   - `archived: true`, 1년 넘게 커밋·릴리스 없음, 레지스트리 최신 버전이 오래됨(`npm view <pkg> time --json`)이면 유지보수 중단 의심
4. **같은 이름의 프로젝트**
   ```bash
   gh api 'search/repositories?q=<name>+in:name&sort=stars&per_page=6' --jq '.items[] | "\(.full_name) stars=\(.stargazers_count) pushed=\(.pushed_at)"'
   ```
5. **이미 설치된 것 확인**: 명령이 실제로 어디서 실행되는지 본다 (`Get-Command`, 실행 파일·바로가기 내용, 서명). 설치 방식(앱 번들, npm, winget)에 맞는 방법으로만 업데이트한다
6. **라이선스**: `gh api repos/<owner>/<repo>/license --jq .license.spdx_id`, 저장소에 없으면 패키지 레지스트리 정보

## 보고 형식

- 프로젝트: `<owner>/<repo>` (공식 여부, 라이선스)
- 상태: 스타, 최근 릴리스·커밋 날짜, archived 여부
- 같은 이름의 후보: 없음 / 목록
- 권장 설치 방법: 공식 README 기준, 출처 인용
- 확인하지 못한 것: 따로 적는다
