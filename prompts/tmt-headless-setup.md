# tmt 헤드리스 켜기 — umbrella 프로젝트 하나에 `tmt headless` 적용

이미 umbrella로 운영 중인 프로젝트(`prompts/tmt-umbrella.md`)에서, 역할 없는 세션을 umbrella 루트에서 열고 붙여 넣는다. 먼저 그 머신이 dev-base 배치여야 하고(`MIGRATE.md`), `UPDATE.md`로 최신이어야 한다(전역 `tmt --version`이 tmt-cli `main` 커밋).
스텝 사이에 실행한다. 리뷰·빌드 턴이 돌고 있을 때는 하지 않는다.

헤드리스는 이슈 트래커(GitHub `gh`, GitLab `glab`은 gitlab.com만. 전역 `tmt`가 `1.0.0` 이상: glab MR·루프, `headless.ignorePaths`, nested 워커 표시, 하루 턴 상한 기본 500, 댓글 재조사 `tmt:investigate`)를 보고 cron이 2분마다 `tmt headless --once`를 돌려, 조사 → 소유자 라벨 → 1형 루프 → PR을 자동으로 진행한다. 설계와 계약은 tmt-cli `README.md` `## Headless`와 `docs/headless.md`. 소유자 명령: 라벨 `tmt:loop-1`·`tmt:loop-2`·`tmt:hotfix`·`tmt:skip`·`tmt:investigate`, 댓글 `tmt:approve`·`tmt:reject`·`tmt:update`·`tmt:cleanup`·`tmt:investigate`(첫 줄에 그대로; 옛 `/…`는 명령이 아니다. 댓글 `tmt:investigate`는 `investigated`·조사 실패 이슈 재조사, 아래 줄은 메모).

쓰는 법: 코드블록 안쪽을 붙여 넣거나, 세션에 "`<이 파일 경로>` 보고 진행해"라고 한다. 파일을 받은 세션은 코드블록 안을 지시로, 그 밖은 실행 조건으로 읽는다.

```
이 umbrella 프로젝트에 tmt 헤드리스를 켜줘. 단계마다 결과를 보고하고, 표시된 곳에서는 내 승인을 받은 뒤 진행한다.

1. 전제 확인 (아무것도 고치지 않음):
   - 레이아웃이 umbrella다: manifest.md `layout: umbrella`, 코드 repo가 umbrella 안 하위 폴더(`loop.repo`가 될 경로)다. 단일 root면 멈추고 보고한다(헤드리스는 umbrella 전용).
   - `tmt --version`이 `tmt 1.0.0` 이상(`tmt X.Y.Z (<커밋>)`, `(dev)`가 아님)이고 `readlink -f "$(which tmt)"`가 전역 node_modules 아래다. 아니면 멈추고 `UPDATE.md`를 먼저 하라고 보고한다.
   - 트래커: 코드 repo `origin`이 `github.com/<owner>/<repo>`이고 `gh auth status`가 로그인 상태다(gh). 또는 `gitlab.com/<group>[/<sub>…]/<repo>`이고 `glab auth status`에 gitlab.com 로그인이 있다(glab; self-hosted GitLab은 미지원). 그 경로가 tracker project다(이슈·PR/MR이 있는 곳).
   - `pgrep -af "tmt (probe|continue|headless)"`가 비어 있다. crontab에 이 umbrella의 `tmt headless`가 이미 있으면 보고한다.
   - umbrella와 코드 repo 모두 `git status -sb`가 `<브랜치>...origin/<브랜치>`(umbrella는 `main`, 코드 repo는 `loop.base`), 변경·미push 커밋 없음. 아니면 목록을 보고하고, 커밋·push·되돌리기 중 무엇을 할지 내 결정을 받는다(임의로 버리지 않는다).
2. tmt.json 수정안 (승인 후 적용, tmt.json은 git-ignore라 커밋하지 않음):
   - `roles.alice`가 없으면 추가한다. omp `{"adapter": "omp", "model": "<모델>"}` 또는 claude `{"adapter": "claude", "model": "<모델>"}`(워커 설정 폴더는 crontab의 `CLAUDE_CONFIG_DIR`로). 앨리스에는 OpenCode를 쓰지 않는다(api는 중첩 `tmt`가 lock에 막히고, standalone은 아래 이유). 워커 역할(bob·richard·roger)의 OpenCode는 api transport(기본)로만 둔다. `"transport": "standalone"`이 있으면(fallback 포함) 빼는 안을 제안한다: 공유 서비스가 재시작할 때 살아 있는 standalone 세션까지 이어받아 두 프로세스가 같은 세션을 돌린다(tmt-cli #97). api 잔여 위험: 서비스 재시작 때 실패·중단한 턴이 tmt 밖에서 다시 돈다(#101, 열림).
   - 보조 역할 폴더: umbrella에서 추적 중인 보조 역할 작업 폴더(오즈 `ops/`, 프로젝트 고유 역할의 폴더)가 있으면 `"ignorePaths": ["<폴더>", …]`를 `headless`에 넣는다. 그 폴더의 미커밋 변경은 headless pre-flight·턴 감사가 무시한다. 보조 역할은 거기 쓰기만 하고 커밋은 헤드풀 앨리스가 headless pause 아래에서 한다(규칙은 `tmt init` router 블록). PROJECT.md에 "<역할>이 직접 커밋"이 있으면 바꿀 문안을 제안하고 내 승인을 받는다.
   - PROJECT.md가 앨리스에게 운영 자격(DB·k8s·클라우드 등)을 주면, headless 앨리스(사람 없이 도는 턴)도 포함할지 묻는다. 권장은 제외이고(tmt-cli `docs/headless.md`: headless 앨리스는 repo 범위 + 중첩 역할 호출, 트래커 쓰기 없음), 승인되면 PROJECT.md에 한 줄로 적는다.
   - `headless`: `{"tracker": {"kind": "gh", "project": "<owner>/<repo>"}, "owner": "<GitHub 로그인>", "trigger": "label"}`. 기본은 Slack 알림 없음(`notify` 생략). 내가 webhook을 만들었다고 할 때만 `"notify": {"slack": {"webhookEnv": "TMT_SLACK_WEBHOOK"}}`를 넣는다(없으면 트래커 댓글만; 조사 실패는 아직 트래커에 남지 않는다, tmt-cli #105). 첫 적용은 `trigger: "label"`(소유자가 `tmt:investigate`나 `tmt:hotfix`를 단 이슈만 대상)로 한다. 열린 이슈 전부를 대상으로 하는 `"all"`은 내가 말할 때만. 자동 루프를 켤지 묻는다(권장: 끔, 전역 `tmt` `1.1.0` 이상). 켜면 조사가 1형·차단 질문 0으로 끝난 이슈는 소유자 라벨 없이 다음 tick에 1형 루프가 PR까지 돈다(머지는 하지 않는다; 설정이 소유자의 상시 go-ahead). 승인되면 `"autoLoop": true`, 아니면 키를 넣지 않는다. glab이면 `"kind": "glab"`, `"project": "<group>/<repo>"`(하위 그룹 포함 전체 경로), `"owner"`는 GitLab 사용자명(`glab auth status`의 `Logged in … as <이름>`).
   - `repos`(최상위)에 코드 repo 폴더를 넣는다(필수: `loop.repo`는 `"."`이거나 `repos`에 있어야 한다). `loop.repo`는 그 폴더가 `repos[0]`이면 생략하고, 아니면 `"loop": {"repo": "<폴더>"}`. 수정 후 `tmt headless status` stderr에 `tmt: invalid tmt.json (…)`이 없어야 한다(전역 `tmt` `1.0.0` 이상; `tmt init`의 `tmt.json:` 줄로도 확인). `loop.base`는 기본 `main`(다르면 `"base": "<브랜치>"`). handoff 폴더가 `handoff/`가 아니면(스코프별 `handoff-be/` 등) `"handoffDir": "<폴더>"`.
   - 기존 역할 설정은 건드리지 않는다. 수정 전후를 보여주고 승인받는다.
   - 라벨: 헤드리스는 라벨을 만들지 않는다. tracker project에 없으면 소유자가 이슈에서 고를 수 없다. `gh label list -R <owner>/<repo> | grep tmt:`로 확인하고, 없는 것만 승인 후 `gh label create <이름> --color <색> --description "<설명>" -R <owner>/<repo>`로 만든다: `tmt:investigate`(FBCA04), `tmt:hotfix`(D93F0B), `tmt:skip`(BFD4F2), `tmt:loop-1`(1D76DB), `tmt:loop-2`(5319E7), `tmt:plan-approved`(0E8A16), `tmt:plan-rejected`(B60205). `autoLoop`을 켰으면 `tmt:auto`(FBCA04, 설명 `headless: added by tmt when a 1형 loop auto-starts (headless.autoLoop)`)도 만든다. 헤드리스는 자격 있는 이슈에 이 라벨을 붙여 자동 루프를 시작하는데, 라벨이 없으면 매 run 붙이기가 실패하고 자동 루프가 시작되지 않는다. `headless.labels`로 이름을 바꿨으면 그 이름으로. glab: `glab label list -R <group>/<repo> | grep tmt:`, 만들기 `glab label create -n <이름> -c '#<색>' -d "<설명>" -R <group>/<repo>`. GitLab은 댓글 첫 줄 `/approve`를 quick action으로 지우므로 승인은 라벨 `tmt:plan-approved`나 댓글 `tmt:approve`로 한다.
3. 블록: `tmt init`으로 블록 diff를 보여주고, 승인 후 `tmt init --apply`. 바뀐 역할 파일·router만 umbrella에 커밋한다(push는 내가 지시할 때).
4. 시험 실행:
   - 중첩 확인 (Alice가 안에서 `tmt`를 부를 수 있는지, 턴 2개): `tmt probe --role alice --prompt "Run exactly: echo \$TMT_LOCK_PID; tmt probe --role <싼 워커 역할> --prompt 'Reply OK only'. Report both outputs verbatim. Change no files."`. 안쪽 probe의 JSON(`"text":"OK"`)이 나오면 통과. `.tmt/.lock` 에러면 멈추고 출력을 보고한다. 끝난 뒤 `git status`가 깨끗하고 `.tmt/.lock`이 없어야 한다.
   - `mkdir -p .scratch`, `tmt headless pause --reason "setup"`, `tmt headless status`(paused, running 빈 목록) 확인, `tmt headless resume`, `tmt headless --once` 1회. `trigger: "label"`이고 라벨 단 이슈가 없으면 `{"picked":null}`이 정상이다. 출력과 `tmt headless top`을 보고한다.
5. 스케줄러: crontab은 내가 직접 넣는다. 넣을 줄만 만들어 보여준다: `*/2 * * * * cd <umbrella 절대경로> && PATH=<node bin>:<harness bin>:/usr/local/bin:/usr/bin:/bin [CLAUDE_CONFIG_DIR=<워커 폴더> CLAUDE_CODE_OAUTH_TOKEN=$(cat <워커 폴더>/oauth-token), claude 어댑터일 때. 토큰 파일은 `WORKER.md` 2단계] [TMT_SLACK_WEBHOOK=<url>, notify를 넣었을 때만] tmt headless --once >> .scratch/cron.log 2>&1`. 경로는 이 머신에서 `which node`·`which <harness>`로 확인한 값이다. webhook URL은 비밀값이라 문서·커밋에 적지 않는다.
6. 끝 보고: 적용한 설정 요약, 커밋 해시, 첫 사용법(이슈에 `tmt:investigate` → 조사 댓글 확인 → `tmt:loop-1` → PR), 상태 확인 명령(`tmt headless status`, `tmt headless top`, `.scratch/cron.log`), 멈추기(`tmt headless pause`).
```
