# 머신 전환 — dev-base 배치로 옮기기

각 머신에서 한 번, 역할 없는 세션에 붙여 넣는다. harness는 무엇이든 된다 (Claude Code 필수 아님).

쓰는 법: 이 repo를 clone한 뒤 세션에 "`<dev-base>/MIGRATE.md` 보고 진행해"라고 한다. 세션은 코드블록 안을 지시로, 밖을 실행 조건으로 읽는다.

```
이 머신의 설정 repo들을 dev-base 배치로 옮기고 전역 규칙을 다시 빌드해줘. 단계마다 결과를 짧게 보고하고, 막히면 멈추고 물어봐. 지우거나 옮기기 전에는 대상 목록을 보여주고 내 승인을 받는다.
Windows면 pwsh 7 기준으로 바꿔 실행한다. 아래 `~`는 `$HOME`이다. bootstrap.sh 대신 repos.txt를 읽어 같은 git clone을 직접 실행한다.

0. `~/.config/machine-context/local.md`가 있으면 읽고 실행 제약을 따른다.
1. dev-base 위치: 이 파일이 있는 폴더가 dev-base다. 위치가 다른 머신 관례와 다르면(예: 기본 `~/development/personal/dev-base`) 지금 옮길지 물어본다. 이후 `<dev-base>`라고 쓴다.
2. 기존 clone 찾기: repos.txt의 각 name에 대해 이 머신의 기존 clone을 찾는다 (예: `~/claude-settings-example`, `~/development/**/tmt-cli`, `~/deploy/<name>`). origin URL이 repos.txt와 같은 repo인지(ssh/https 차이는 무시) 확인한다.
   - three-man-team의 옛 checkout `~/.claude*/skills/three-man-team`은 옮기지 않는다 (6단계에서 정리).
   - 이 머신에 필요 없는 repo(예: tmt-cli를 안 쓰는 머신)는 건너뛴다. 모르면 물어본다.
3. 옮기기: 기존 clone마다 `git status`가 깨끗하고 미push 커밋(`git log @{u}..`)과 stash가 없을 때만 `<dev-base>/<name>`으로 `mv`한다. git이 추적하지 않는 로컬 파일(`.claude-settings.local`, `tmt.json`, `.tmt/` 등)은 mv로 그대로 따라온다. 더럽거나 미push가 있으면 멈추고 보고. 옛 경로에 호환 symlink는 만들지 않는다.
   옮긴 뒤 여파 처리:
   - Claude Code가 있으면: `~/.claude*/projects/` 아래 옛 경로 slug 폴더(경로의 `/`를 `-`로 바꾼 이름)를 새 경로 slug로 rename한다 (세션 기록·프로젝트 메모리 유지). 새 slug 폴더가 이미 있으면 멈추고 보고.
   - tmt-cli를 옮겼고 전역 `tmt`가 있으면: `<dev-base>/tmt-cli`에서 `npm link` 후 `tmt --help` 확인.
   - 옛 경로 문자열을 설정 파일에서 찾는다: `~/.config`, `~/.claude*/settings*.json`, `~/.omp/agent`, 셸 rc 파일, crontab. 백업·히스토리·로그·세션 DB는 제외. 찾은 곳은 목록으로 보여주고 승인 후 고친다. 원격 명령 안의 경로(ssh로 다른 머신에서 실행되는 부분)는 그 머신 경로라 고치지 않는다.
   - repo 안 문서에 옛 절대경로가 있으면 과거 기록은 고치지 말고 보고만 한다.
4. 빠진 repo 받기: `<dev-base>/bootstrap.sh [name...]`. ssh를 쓰려면 repos.txt 머리 주석의 `insteadOf` 설정을 먼저 한다. tmt-cli는 private이라 https면 `gh auth login`·`gh auth setup-git`이 필요하다. 인증이 없으면 tmt-cli는 건너뛰고 보고.
5. 전역 규칙 빌드: `<dev-base>/claude-settings-example/prompts/tmt-machine-migrate.md`를 읽고 그 절차대로 진행한다 (빌드가 `~/.config/agent-rules/`에 템플릿을 배포하고, 옛 harness별 templates 사본을 정리한다).
6. 옛 three-man-team checkout 정리: `~/.claude*/skills/three-man-team`마다 `git status` 깨끗, 미push 커밋·stash 없음, 로컬 브랜치가 origin에 다 있음을 확인한 뒤 삭제한다. 하나라도 걸리면 멈추고 보고.
7. 검증 (표로 보고):
   - `<dev-base>`에 필요한 repo가 다 있고 각 `git status -sb`가 `main...origin/main`
   - `git -C <dev-base> status --short`가 비어 있음 (하위 repo가 상위에 잡히지 않음)
   - `~/.config/agent-rules/three-man-team/SOURCE`의 `clone=`이 `<dev-base>/three-man-team`
   - `~/.claude*/skills/three-man-team` 없음
   - 3단계에서 찾은 설정 파일에 옛 경로 없음
   - 전역 `tmt`가 있으면 `<dev-base>/tmt-cli`를 가리킴
```
