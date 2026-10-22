# Claude 워커 폴더 — tmt-cli claude 워커용 (선택)

앨리스가 tmt-cli로 밥·리처드·로저를 claude 어댑터로 호출할 때 쓰는 두 번째 Claude 설정 폴더 `~/.claude-worker`. 계정 분리와 같은 `CLAUDE_CONFIG_DIR` 방식이지만 계정은 같다. 목적은 워커 첫 호출 컨텍스트 축소(tmt-cli Step K 실측 -27%, 비용은 중립)이며 statusLine·플러그인·소유자용 지침이 빠진다. 앨리스 자기 세션은 `~/.claude`를 그대로 쓴다.

필수가 아니다. 폴더가 없으면 tmt는 `~/.claude`로 동작한다. tmt-cli claude 워커를 이 머신에서 쓸 때만 만든다. 이름 `worker`는 tmt-cli 용어(워커 호출)를 따른다. tmt-cli는 이 이름을 모르고 `CLAUDE_CONFIG_DIR` 값만 넘겨받는다 (tmt-cli README).

쓰는 법: 역할 없는 세션에 "`<dev-base>/WORKER.md` 보고 진행해"라고 한다. 세션은 코드블록 안을 지시로, 밖을 실행 조건으로 읽는다.

```
이 머신의 Claude 워커 폴더를 아래 규칙에 맞춰줘. 단계마다 결과를 짧게 보고하고, 막히면 멈추고 물어봐.
Windows면 pwsh 7 기준으로 바꿔 실행한다. 아래 `~`는 `$HOME`이다. 이 파일이 있는 폴더를 `<dev-base>`라고 쓴다.

0. `~/.config/machine-context/local.md`가 있으면 먼저 읽고 실행 제약을 따른다.
1. 존재 확인: `~/.claude-worker`가 있으면 2단계를 건너뛰고 3단계 점검만 한다. 없으면 이 머신에서 tmt-cli claude 워커를 쓸지 나에게 확인한 뒤 2단계로 간다.
2. 생성:
   - `~/.claude-worker`를 만들고 `<dev-base>/claude-settings-example/settings.json.example`을 `~/.claude-worker/settings.json`으로 복사한 뒤 3단계 settings 규칙대로 고친다.
   - 플러그인 캐시는 복사하지 않는다. 워커는 스킬을 `~/.agents/skills/<name>/SKILL.md` 파일로 읽는다.
   - 로그인은 내가 한다: `wclaude login`(4단계 함수)을 실행하라고 안내한다. `.credentials.json`을 복사하지 않는다 (refresh token 공유).
3. 점검 (어긋나면 고치기 전에 목록으로 보고):
   - settings.json: `statusLine` 없음, `enabledPlugins`가 `{}`, `extraKnownMarketplaces` 없음(플러그인을 안 쓰는데 마켓플레이스 캐시만 받아온다), `model`·`tui` 없음. permissions·hooks·autoMode·effortLevel 등 나머지는 `~/.claude/settings.json`과 같고(`theme` 같은 UI 설정은 달라도 된다), hooks 경로는 `~/.claude/hooks/`를 그대로 가리킨다.
   - `~/.claude-worker/CLAUDE.md` 없음. `$HOME` 아래 레포에서는 `~/.claude/CLAUDE.md`가 조상 Project 파일로 로드되므로(haiku `-p` 실측) 두면 중복만 된다. 이름을 바꿔 둔 파일(예: `CLAUDE.md.off`)은 그대로 둔다.
   - claude-settings-example build를 이 폴더에 돌리지 않는다 (`--claude-dir .claude-worker` 금지, 위 CLAUDE.md 규칙 때문).
4. 셸 함수 `wclaude`가 없으면 추가한다. bash는 `~/.bash_aliases`:
     wclaude() { CLAUDE_CONFIG_DIR="$HOME/.claude-worker" command claude "$@"; }
   Windows pwsh는 `$PROFILE` (원래 값 복원):
     function wclaude {
         $old = $env:CLAUDE_CONFIG_DIR
         $env:CLAUDE_CONFIG_DIR = "$HOME\.claude-worker"
         try { claude @args } finally {
             if ($null -eq $old) { Remove-Item Env:\CLAUDE_CONFIG_DIR } else { $env:CLAUDE_CONFIG_DIR = $old }
         }
     }
5. 검증: `$HOME` 아래 아무 레포에서 `wclaude -p --model claude-haiku-5-5 "Reply OK"`가 응답하면 로그인·설정 OK. 결과를 표로 보고한다.
```

- `$HOME` 밖 레포(`/mnt/c/...` 등)에서는 `~/.claude/CLAUDE.md`가 로드되지 않으니 워커를 쓰지 않는다.
- 앨리스의 호출 규칙(`~/.claude-worker`가 있으면 호출 단위로 `CLAUDE_CONFIG_DIR`을 붙인다)은 전역 규칙 `claude-settings-example/fragments/10-three-man-team.md`에 있다.
