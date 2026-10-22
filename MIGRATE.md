# 머신 전환 — dev-base 배치로 옮기기

각 머신에서 한 번, 역할 없는 세션에 붙여 넣는다. harness는 무엇이든 된다 (Claude Code 필수 아님).

쓰는 법: 이 repo를 clone한 뒤 세션에 "`<dev-base>/MIGRATE.md` 보고 진행해"라고 한다. 세션은 코드블록 안을 지시로, 밖을 실행 조건으로 읽는다.

```
이 머신의 설정 repo들을 dev-base 배치로 옮기고 전역 규칙을 다시 빌드해줘. 단계마다 결과를 짧게 보고하고, 막히면 멈추고 물어봐. 지우거나 옮기기 전에는 대상 목록을 보여주고 내 승인을 받는다.
Windows면 pwsh 7 기준으로 바꿔 실행한다. 아래 `~`는 `$HOME`이다. bootstrap.sh 대신 repos.txt를 읽어 같은 git clone을 직접 실행한다.
Windows에서 도구(gh·glab·npm 등)가 없어 보이면 없다고 판단하기 전에 PATH를 다시 읽는다: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')`. 세션 시작 후 설치한 도구는 셸 PATH에 안 보인다.
Windows에서 `git diff`가 내용 없이 `old mode 100755`/`new mode 100644`만 보이면 그 repo에 `git config core.fileMode false`를 설정하고 다시 확인한다 (Git for Windows clone은 기본 false, WSL 등 다른 git으로 만든 checkout에서 생긴다). repo 파일의 실행 비트는 바꾸지 않는다.

0. 머신 실행 맥락: 공통 경로는 `~/.config/machine-context/local.md`다 (모든 harness 공유, repo 위치 무관).
   - 파일이 있으면 먼저 읽고 실행 제약을 따른다. 기존 내용은 보존한다.
   - 옛 claude-settings-example clone의 `machine-context/local.md`도 있으면 확인한다. 공통 경로가 없으면 부모 디렉터리를 만들고 복사한다. 양쪽이 다르면 덮어쓰지 말고 물어본다. 원본 삭제는 별도 승인을 받는다.
   - 양쪽 모두 없으면 필요한 머신 제약을 물어보고, 동의한 내용만 공통 경로에 작성한다. 불필요하면 만들지 않는다. 다른 머신의 수치·경로를 복사하거나 비밀값을 기록하지 않는다.
1. dev-base 위치: 이 파일이 있는 현재 폴더가 dev-base다. 정해진 기본 경로는 없으니 옮기자고 하지 않는다. `~/.config/machine-context/local.md`에 dev-base 위치를 기록할지 물어보고, 동의하면 한 줄 추가한다 (파일이 없으면 0단계 규칙대로 만든다). 이후 `<dev-base>`라고 쓴다.
2. 기존 clone 찾기: repos.txt의 각 name에 대해 이 머신의 기존 clone을 찾는다 (예: `~/claude-settings-example`, `~/development/**/tmt-cli`, `~/deploy/<name>`). origin URL이 repos.txt와 같은 repo인지(ssh/https 차이는 무시) 확인한다.
   - three-man-team의 옛 checkout `~/.claude*/skills/three-man-team`은 옮기지 않는다 (6단계에서 정리).
   - 이 머신에 필요 없는 repo(예: tmt-cli를 안 쓰는 머신)는 건너뛴다. 모르면 물어본다.
3. 옮기기: 기존 clone마다 `git status`가 깨끗하고 미push 커밋(`git log @{u}..`)과 stash가 없을 때만 `<dev-base>/<name>`으로 `mv`한다. git이 추적하지 않는 로컬 파일(`.claude-settings.local`, `tmt.json`, `.tmt/` 등)은 mv로 그대로 따라온다. 더럽거나 미push가 있으면 멈추고 보고. 옛 경로에 호환 symlink는 만들지 않는다.
   옮긴 뒤 여파 처리:
   - Claude Code가 있으면: `~/.claude*/projects/` 아래 옛 경로 slug 폴더(절대경로의 영숫자 아닌 문자를 모두 `-`로 바꾼 이름. `/`뿐 아니라 `_`·`.`, Windows의 `:`·`\`도 바뀐다 — 예: `C:\Users\me\local_dev` → `C--Users-me-local-dev`)를 새 경로 slug로 rename한다. 계산하지 말고 `projects/` 목록에서 repo 이름으로 찾아 확인한다 (세션 기록·프로젝트 메모리 유지). 새 slug 폴더가 이미 있으면 멈추고 보고.
   - tmt-cli를 옮겼고 전역 `tmt`가 있으면: `<dev-base>/tmt-cli`에서 `npm install && npm run build` 후 `npm link`, `tmt --help` 확인. `dist/`는 추적하지 않아 빌드 전에는 link해도 `tmt`가 생기지 않는다.
   - 옛 경로 문자열을 설정 파일에서 찾는다: `~/.config`, `~/.claude*/settings*.json`, `~/.omp/agent`, 셸 rc 파일, crontab. 백업·히스토리·로그·세션 DB는 제외. 찾은 곳은 목록으로 보여주고 승인 후 고친다. 원격 명령 안의 경로(ssh로 다른 머신에서 실행되는 부분)는 그 머신 경로라 고치지 않는다.
   - repo 안 문서에 옛 절대경로가 있으면 과거 기록은 고치지 말고 보고만 한다.
4. 빠진 repo 받기: `<dev-base>/bootstrap.sh [name...]`. ssh를 쓰려면 repos.txt 머리 주석의 `insteadOf` 설정을 먼저 한다. tmt-cli는 private이라 https면 `gh auth login`·`gh auth setup-git`이 필요하다. 인증이 없으면 tmt-cli는 건너뛰고 보고.
5. 업데이트: `<dev-base>/UPDATE.md`를 읽고 그 절차(pull·caveman·빌드·검증)대로 진행한다. UPDATE의 검증까지 통과해야 다음으로 간다.
5a. 밀린 일회성 정리 (해당하는 것만, 지우기 전 목록 승인):
   - 옛 템플릿 사본: `~/.claude/templates/`, `~/.config/opencode/templates/`, `~/.omp/agent/templates/`, `~/.config/crush/templates/`의 `project-rules.md`·`.claudeignore`·`OPERATOR.md`를 삭제하고 빈 폴더면 폴더도 지운다. 목록에 없는 파일이 있으면 지우지 말고 보고.
   - 옛 스킬 사본: `~/.config/opencode/skills`·`~/.config/crush/skills`에 caveman·ponytail 사본이 있으면 목록만 보고하고 지우지 않는다.
   - caveman 훅 중복(2026-10-13): `~/.claude*/settings.json`(워커 폴더 포함)의 `hooks`에 `caveman-activate.js`·`caveman-mode-tracker.js`를 부르는 activation·mode-tracker 등록이 있으면 지운다 (플러그인 manifest가 같은 훅을 등록한다). statusLine 설정과 `~/.claude/hooks/` 파일은 건드리지 않는다.
   - omp 마켓플레이스 플러그인(2026-10-13): `omp plugin list`에 `ponytail@ponytail`·`caveman@...` 같은 스킬 플러그인이 있으면 `omp plugin uninstall <id>`. 스킬 소스는 `agent-skills.txt` 하나다. `omp plugin doctor`의 `package_manifest: Not created yet`는 정보성 경고라 그대로 둔다.
   - qmd 폐기(2026-10-13): Claude Code에 `qmd@qmd` 플러그인이 있으면 `claude plugin disable qmd@qmd`, `~/.claude*/settings.json`의 `permissions.allow`에서 `mcp__plugin_qmd_qmd__*` 항목을 지운다. `enabledPlugins`의 `"qmd@qmd": false`와 `extraKnownMarketplaces`의 `qmd`는 남겨도 된다. `~/.agents/skills/qmd`가 있으면 삭제한다. qmd CLI와 인덱스는 지우지 않는다.
5b. `~/.claude-worker`가 있거나 이 머신에서 tmt-cli claude 워커를 쓰면: `<dev-base>/WORKER.md` 절차로 점검·생성한다.
6. 옛 three-man-team checkout 정리: `~/.claude*/skills/three-man-team`마다 `git status` 깨끗, 미push 커밋·stash 없음, 로컬 브랜치가 origin에 다 있음을 확인한 뒤 삭제한다. 하나라도 걸리면 멈추고 보고.
7. 검증 (표로 보고):
   - `<dev-base>`에 필요한 repo가 다 있고 각 `git status -sb`가 `main...origin/main`
   - `git -C <dev-base> status --short`가 비어 있음 (하위 repo가 상위에 잡히지 않음)
   - `~/.config/agent-rules/three-man-team/SOURCE`의 `clone=`이 `<dev-base>/three-man-team`
   - `~/.claude*/skills/three-man-team` 없음
   - 3단계에서 찾은 설정 파일에 옛 경로 없음
   - 전역 `tmt`가 있으면 `<dev-base>/tmt-cli`를 가리킴
   - 5a 옛 템플릿 경로에 `project-rules.md` 없음, `~/.agents/skills/qmd` 없음, 생성된 전역 규칙 파일과 `~/.claude/settings.json`에 `qmd` 문자열 없음(`"qmd@qmd": false`는 허용)
   - `omp plugin list`에 매니페스트 스킬과 겹치는 플러그인이 없고 `omp skill list`에 `name collision` 없음
   - Claude 머신: `~/.agents/skills/caveman/SKILL.md`에 lite/full 강도 표가 없음, `settings.json`들에 caveman activation·mode-tracker 훅 등록이 없음
```
