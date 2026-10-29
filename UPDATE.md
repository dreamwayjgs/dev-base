# 머신 업데이트 — 설정 변경을 이 머신에 반영

설정 repo가 바뀔 때마다 각 머신에서 역할 없는 세션에 맡긴다. harness는 무엇이든 된다 (Claude Code 필수 아님). 아직 dev-base 배치가 아닌 머신은 `MIGRATE.md`를 먼저 한다.

쓰는 법: 세션에 "`<dev-base>/UPDATE.md` 보고 진행해"라고 한다. 세션은 코드블록 안을 지시로, 밖을 실행 조건으로 읽는다.

```
이 머신의 설정 repo들을 최신으로 맞추고 전역 규칙을 다시 빌드해줘. 단계마다 결과를 짧게 보고하고, 막히면 멈추고 물어봐.
Windows면 pwsh 7 기준으로 바꿔 실행한다(Windows PowerShell 5는 지원하지 않는다). 아래 `~`는 `$HOME`이고 하위 경로는 Linux와 같다. 이 파일이 있는 폴더를 `<dev-base>`라고 쓴다.
Windows에서 도구(gh·glab·npm 등)가 없어 보이면 없다고 판단하기 전에 PATH를 다시 읽는다: `$env:PATH = [Environment]::GetEnvironmentVariable('PATH','Machine') + ';' + [Environment]::GetEnvironmentVariable('PATH','User')`. 세션 시작 후 설치한 도구는 셸 PATH에 안 보인다.
Windows에서 `git diff`가 내용 없이 `old mode 100755`/`new mode 100644`만 보이면 그 repo에 `git config core.fileMode false`를 설정하고 다시 확인한다 (Git for Windows clone은 기본 false, WSL 등 다른 git으로 만든 checkout에서 생긴다). repo 파일의 실행 비트는 바꾸지 않는다.

0. `~/.config/machine-context/local.md`가 있으면 먼저 읽고 실행 제약을 따른다.
1. pull: `<dev-base>` 자신과, 그 아래 있는 repos.txt의 각 repo에서 `git pull --ff-only`. 워킹트리가 더럽거나 ff가 안 되면 그 repo에서 멈추고 보고. 이 머신에 없는 repo는 건너뛴다 (필요하면 `bootstrap.sh <name>`).
   pull 전에 `<dev-base>`를 먼저 pull한 뒤, 각 repo의 `git config --get remote.origin.url`이 repos.txt URL과 같은 repo인지 확인한다. 비교는 `host/owner/repo`로 정규화해서 한다(`https://`·`git@host:`·끝의 `.git` 제거). ssh/https 차이만 있으면 그대로 둔다. 다른 repo면 `git remote set-url origin <repos.txt URL>` (https 머신은 repos.txt 주석의 `insteadOf`로. `git remote get-url`은 insteadOf가 적용된 값을 보여 주므로 비교에 쓰지 않는다). 옛 origin에만 있는 커밋이 있으면 멈추고 보고.
   `<dev-base>` pull로 이 파일(`UPDATE.md`)이 바뀌었으면 다시 읽고 새 내용대로 1단계부터 이어간다.
   `<dev-base>/claude-settings-example`이 있고 `agent-rules`가 없으면(2026-10-29 이름 변경) 그 repo에서 `git remote set-url origin git@github.com:dreamwayjgs/agent-rules.git`(https면 같은 host의 https) 후 폴더를 `agent-rules`로 옮기고 나서 pull한다. 옛 경로의 Claude Code 세션 slug 폴더는 MIGRATE.md 3단계 여파 처리와 같다.
   Windows에서 거의 모든 파일이 modified로 나오면 줄바꿈(`core.autocrlf`) 문제다. reset하지 말고 `git diff --stat`·`git config core.autocrlf` 결과를 보고.
2. caveman·ponytail (Claude Code가 있는 머신만, 빌드 전). `claude`가 PATH에 없으면 이 단계와 6단계의 Claude 항목은 대상 아님(`N/A`)으로 적는다. 아래 `claude plugin ...` 명령이 이 버전에 없으면(`unknown command` 등) 다른 방법을 찾지 말고 `claude --version`과 함께 멈추고 보고한다: `agent-rules/agent-skills.txt`의 caveman·ponytail 줄마다, 플러그인을 올리기 전에 upstream 최신 semver 태그(`git ls-remote --tags --refs https://github.com/<repo>`)를 매니페스트 ref(`v<버전>`)와 비교한다.
   - 같으면 그대로 간다.
   - 같은 major의 더 새 태그면: 그 줄 ref와 머리 주석의 버전을 그 태그로 올리고, ponytail이면 `opencode-plugins/ponytail-v2/README.md`의 npm 버전도 같이 올려 agent-rules에 커밋한다. push는 내 승인 후.
   - major가 다르면 멈추고 보고한다. 매니페스트·플러그인 모두 올리지 않는다.
   그다음 `claude plugin marketplace update <이름>` → `claude plugin update <이름>@<이름>` 후 설치된 플러그인 버전이 매니페스트 ref와 같은지 확인한다. 다르면(마켓플레이스가 태그보다 늦는 등) 멈추고 보고.
   ponytail 5.3 이상이면 band·ledger를 끈다 (`agent-rules/claude-settings.md` §5-1): `claude plugin configure ponytail@ponytail`에서 ledger가 설정 안 됨이면 `echo '{"ledger":"false"}' | claude plugin configure ponytail@ponytail --values-stdin`, `~/.claude/.ponytail-band`가 없으면 내용 `off`로 만든다. 다른 Claude 계정 폴더도 ponytail 플러그인이 켜져 있으면 같은 처리를 그 `CLAUDE_CONFIG_DIR`로 한다.
   caveman 버전이 맞으면 `~/.claude/plugins/cache/caveman/caveman/<version>/src/hooks/`의 `package.json`·`caveman-config.js`·`caveman-parse.js`·`caveman-activate.js`·`caveman-mode-tracker.js`·`caveman-stats.js`·`caveman-statusline.sh`·`caveman-statusline.ps1`·`cavecrew-model-overrides.js`를 `~/.claude/hooks/`에 덮어쓴다 (statusline 배지용). 목록은 같은 폴더 `install.ps1`의 `$HookFiles`와 같다. 다르면 그 목록을 따르고 보고한다 — 빠진 형제 파일이 있으면 훅이 "install is incomplete"를 내고 기능을 줄여 돈다.
3. 빌드 (`<dev-base>/agent-rules`에서):
   - Linux·macOS·WSL: `./build-claude-md.sh`
   - Windows: `pwsh -File .\build-rules.ps1`. bash 셸에서 실행 중이어도(예: Claude Code의 Git Bash) ps1을 쓴다. pwsh 7이 없으면 멈추고 보고. 실행 정책 오류가 나면 `-ExecutionPolicy Bypass`를 붙인다.
   - Foreman 질문이 나오면 나에게 물어봐.
   - 빌드는 전역 규칙을 harness별 경로에, 템플릿을 `~/.config/agent-rules/`에 쓰고, `agent-skills.txt`의 스킬을 `npx skills add`로 `~/.agents/skills`에 설치한다 (node·네트워크 필요). `npx`가 없거나 dev-base 배치가 아니면 아무것도 쓰지 않고 실패하고, 스킬 설치가 실패하면 규칙은 써진 뒤 멈춘다. 어느 쪽이든 멈추고 출력 전체를 보고. `build-rules.ps1 -TargetHome <다른 경로>`는 규칙·템플릿만 그 경로에 쓰고 스킬 설치는 건너뛴다(격리 검증용).
   - 빌드는 Claude 설정 폴더 중 `~/.claude`에만 CLAUDE.md를 쓴다. 다른 계정 폴더(예: `~/.claude-personal`·`~/.claude-admin`)가 있으면 쓰는 폴더인지 나에게 물은 뒤, 폴더마다 `./build-claude-md.sh --targets claude --claude-dir <폴더명>`(Windows `-Targets claude -ClaudeDir <폴더명>`)으로 한 번 더 빌드한다. `~/.claude-worker`는 대상이 아니다 (`WORKER.md`).
4. OpenCode V2가 있는 머신(`opencode --version`이 2.x)만: caveman은 `agent-rules/opencode-v2-migration.md` 절차 4(upstream 파일 복사, 설치기 금지, `~/.config/opencode/AGENTS.md`에 `<!-- caveman-begin -->` 블록이 있으면 지우지 말고 보고), ponytail은 `agent-rules/opencode-plugins/ponytail-v2/README.md` 설치 절차로 어댑터와 의존 파일을 맞추고, `opencode-v2-migration.md`의 "검증" 절 항목을 표시(즉시·행동·지연)대로 6단계 분류에 넣는다.
   V2인데 `~/.config/opencode/plugins/`나 `~/.config/opencode/opencode.json`이 없으면 첫 설치다: `opencode-v2-migration.md` 절차 4~6(caveman·ponytail·config)을 따르고(1~3단계 V1 백업·V2 설치는 건너뜀), `opencode serve --service`가 떠 있으면 재시작한다.
5. tmt-cli가 있고 전역 `tmt`가 이 clone을 가리키면: `<dev-base>/tmt-cli`에서 `npm run build` 후 `tmt --help`.
6. 검증 (표로 보고). 각 항목 상태는 `PASS`·`FAIL`·`NOT RUN`·`DEFERRED`·`EXCEPTION`(내가 승인한 예외) 중 하나로 적는다. 빌드가 성공했다는 이유로 돌리지 않은 항목을 PASS로 적지 않는다.
   즉시 게이트 (모델 호출 없음, 전부 PASS여야 완료):
   - 각 repo `git status -sb`가 `main...origin/main`, ahead/behind 없음. `git -C <dev-base> status --short`가 비어 있음
   - `~/.config/agent-rules/`에 `project-rules.md`, `.claudeignore`, `three-man-team/templates/project-folder/ROGER.md`, `three-man-team/templates/optional/OPERATOR.md` 존재, `three-man-team/SOURCE`의 `commit=`이 `<dev-base>/three-man-team` HEAD와 같음
   - 생성된 전역 규칙 파일(이 harness 것)에 `~/.config/agent-rules/` 문자열이 있고, `~/.config/machine-context/local.md`를 작업 전에 읽는 지침이 있음
   - `agent-skills.txt`의 각 줄(repo, ref, 스킬 이름들)에 대해 `~/.agents/skills/<이름>/SKILL.md`가 있고 `~/.agents/.skill-lock.json`의 그 스킬 `ref`가 줄의 ref와 같음. 개수·버전을 외우지 말고 매니페스트에서 읽는다
   - Claude 머신: 설치된 caveman 플러그인 버전이 매니페스트 caveman ref와 같음, 토큰 최적화 표의 caveman 열이 `caveman`
   - Claude Code·OpenCode가 있는 머신: caveman·ponytail `config.json`이 `{"defaultMode":"off"}` (Linux·macOS·WSL `~/.config/<이름>/`, Windows `%APPDATA%\<이름>\`). 없으면 `agent-rules/claude-settings.md` §5-1대로 만들고 보고, 다른 값이면 고치지 말고 보고. `CAVEMAN_DEFAULT_MODE`·`PONYTAIL_DEFAULT_MODE` 환경변수가 off 아닌 값이면 보고(파일보다 우선한다)
   - OpenCode V2 머신: 4단계 "검증" 절의 (즉시) 항목, `~/.config/opencode/plugins/ponytail/node_modules/@dietrichgebert/ponytail/package.json`의 `version`이 매니페스트 ponytail 태그(`v` 제외)와 같음. 다르면 `opencode-plugins/ponytail-v2/README.md` 설치 절차로 재설치
   - Claude 머신, ponytail 5.3 이상: ledger `false`(`claude plugin configure ponytail@ponytail`), `~/.claude/.ponytail-band` = `off`
   행동 검증 (모델 호출, 비용이 들어 실행 전 나에게 승인을 받는다. 승인 없으면 `NOT RUN`):
   - OpenCode V2 머신: "검증" 절의 (행동) 항목 중 역할 없는 `opencode run`
   - 역할 세션 확인은 여기서 띄우지 않고 `NOT RUN`으로 적는다 (역할 세션은 별도 명시 승인 대상)
   지연 관찰 (완료를 막지 않음, `DEFERRED`로 적고 관찰 시점을 쓴다):
   - OpenCode V2 머신: "검증" 절의 (지연) 항목
7. 검증 보고 후 `~/.config/machine-context/local.md`의 "마지막 UPDATE" 줄을 갱신한다: 날짜, 즉시 게이트 결과(행동 검증은 PASS·NOT RUN 표기), 4개 repo HEAD 짧은 해시. 줄이 없으면 추가한다. 머신 별칭 줄이 없으면 나에게 물어 함께 적는다(서버 역할이 드러나는 이름은 피한다). local.md 파일이 없으면 만들지 말고 보고만 한다.
8. 피드백 리포트를 만들지 나에게 묻는다. 원하면 `<dev-base>/prompts/feedback-report.md`대로 진행한다(이번 UPDATE 결과를 환경 항목에 쓴다). 원하지 않으면 끝낸다.
```
