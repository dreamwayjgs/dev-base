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
   Windows에서 거의 모든 파일이 modified로 나오면 줄바꿈(`core.autocrlf`) 문제다. reset하지 말고 `git diff --stat`·`git config core.autocrlf` 결과를 보고.
2. caveman (Claude Code가 있는 머신만, 빌드 전): `claude plugin update caveman@caveman` 후 설치된 플러그인 버전이 `claude-settings-example/agent-skills.txt`의 caveman ref(`v<버전>`)와 같은지 확인한다. 플러그인이 더 새 버전이면 멈추고 보고 — 매니페스트 ref는 소유자만 올린다. 같으면 `~/.claude/plugins/cache/caveman/caveman/<version>/src/hooks/`의 `package.json`·`caveman-config.js`·`caveman-parse.js`·`caveman-activate.js`·`caveman-mode-tracker.js`·`caveman-stats.js`·`caveman-statusline.sh`·`caveman-statusline.ps1`·`cavecrew-model-overrides.js`를 `~/.claude/hooks/`에 덮어쓴다 (statusline 배지용). 목록은 같은 폴더 `install.ps1`의 `$HookFiles`와 같다. 다르면 그 목록을 따르고 보고한다 — 빠진 형제 파일이 있으면 훅이 "install is incomplete"를 내고 기능을 줄여 돈다.
3. 빌드 (`<dev-base>/claude-settings-example`에서):
   - Linux·macOS·WSL: `./build-claude-md.sh`
   - Windows: `pwsh -File .\build-rules.ps1`. bash 셸에서 실행 중이어도(예: Claude Code의 Git Bash) ps1을 쓴다. pwsh 7이 없으면 멈추고 보고. 실행 정책 오류가 나면 `-ExecutionPolicy Bypass`를 붙인다.
   - Foreman 질문이 나오면 나에게 물어봐.
   - 빌드는 전역 규칙을 harness별 경로에, 템플릿을 `~/.config/agent-rules/`에 쓰고, `agent-skills.txt`의 스킬을 `npx skills add`로 `~/.agents/skills`에 설치한다 (node·네트워크 필요). `npx`가 없거나 dev-base 배치가 아니면 아무것도 쓰지 않고 실패하고, 스킬 설치가 실패하면 규칙은 써진 뒤 멈춘다. 어느 쪽이든 멈추고 출력 전체를 보고. `build-rules.ps1 -TargetHome <다른 경로>`는 규칙·템플릿만 그 경로에 쓰고 스킬 설치는 건너뛴다(격리 검증용).
   - 빌드는 Claude 계정 폴더 중 `~/.claude`·`~/.claude-personal`에만 CLAUDE.md를 쓴다. 다른 계정 폴더(예: `~/.claude-admin`)가 있으면 `~/.claude/CLAUDE.md`를 그 폴더에 복사한다.
4. OpenCode V2가 있는 머신(`opencode --version`이 2.x)만: caveman은 `claude-settings-example/opencode-v2-migration.md` 절차 4(upstream 파일 복사, 설치기 금지, `~/.config/opencode/AGENTS.md`에 `<!-- caveman-begin -->` 블록이 있으면 지우지 말고 보고), ponytail은 `claude-settings-example/opencode-plugins/ponytail-v2/README.md` 설치 절차로 어댑터와 의존 파일을 맞추고, `opencode-v2-migration.md`의 "검증" 절을 돌린다.
5. tmt-cli가 있고 전역 `tmt`가 이 clone을 가리키면: `<dev-base>/tmt-cli`에서 `npm run build` 후 `tmt --help`.
6. 검증 (표로 보고):
   - 각 repo `git status -sb`가 `main...origin/main`, ahead/behind 없음. `git -C <dev-base> status --short`가 비어 있음
   - `~/.config/agent-rules/`에 `project-rules.md`, `.claudeignore`, `three-man-team/templates/project-folder/ROGER.md`, `three-man-team/templates/optional/OPERATOR.md` 존재, `three-man-team/SOURCE`의 `commit=`이 `<dev-base>/three-man-team` HEAD와 같음
   - 생성된 전역 규칙 파일(이 harness 것)에 `~/.config/agent-rules/` 문자열이 있고, `~/.config/machine-context/local.md`를 작업 전에 읽는 지침이 있음
   - `agent-skills.txt`의 각 줄(repo, ref, 스킬 이름들)에 대해 `~/.agents/skills/<이름>/SKILL.md`가 있고 `~/.agents/.skill-lock.json`의 그 스킬 `ref`가 줄의 ref와 같음. 개수·버전을 외우지 말고 매니페스트에서 읽는다
   - Claude 머신: 설치된 caveman 플러그인 버전이 매니페스트 caveman ref와 같음, 토큰 최적화 표의 caveman 열이 `caveman`
```
