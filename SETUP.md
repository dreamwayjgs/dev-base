# dev-base — 개발머신 설정 3총사

서로 얽힌 세 repo를 한 세션에서 함께 보기 위한 작업 공간이다. 이 폴더 자체는 manifest repo(GitHub `dreamwayjgs/dev-base`, public)로 이 지침·`repos.txt`·`bootstrap.sh`와 머신 절차 문서(`MIGRATE.md`·`UPDATE.md`·`WORKER.md`·`prompts/`)만 추적한다. 세 repo는 `.gitignore`로 제외된 독립 clone이며 서브모듈이 아니다. 커밋·push는 각 repo 안에서 따로 하고, 각 repo의 `CLAUDE.md` 규칙을 따른다.

- dev-base 위치: 현재 clone 폴더가 기준이다. 정해진 기본 경로는 없고 옮기자고 하지 않는다. 처음 쓰는 머신이면 `~/.config/machine-context/local.md`에 dev-base 위치를 기록할지 물어본다.
- 새 머신: 이 repo를 clone한 뒤 `./bootstrap.sh [name...]` (없는 repo만 clone, upstream remote 설정). 기존 clone이 있는 머신은 `MIGRATE.md` 절차를 따른다.
- 설정 변경 반영: 각 머신에서 `UPDATE.md` (pull → build → 검증). 프로젝트 역할 파일·router 동기화는 `prompts/tmt-project-sync.md`.
- tmt-cli claude 워커용 설정 폴더(선택): `WORKER.md`.
- handoff 수명 규약(agent-rules #5) 도입: 기존 프로젝트는 `prompts/handoff-cleanup.md`(일회성, Step 사이). tmt 레이아웃(코드 repo + umbrella repo)·마이그레이션·공개 전환은 `prompts/tmt-umbrella.md`.
- 사용 피드백(선택, 소유자 동의 후): `prompts/feedback-report.md`. 리포트는 머신 로컬 `~/.config/dev-base-feedback/`에 쓰고, 원본(`.private.md`)은 public repo에 올리지 않는다.
- 머신·repo에 걸친 절차는 이 repo에 둔다. agent-rules에는 규칙 내용과 build 도구만 둔다.
- 공통 템플릿 배포 경로는 harness 무관 `~/.config/agent-rules/`다. dev-base 밖에서 build하면 아무것도 쓰지 않고 멈춘다.
- repo 추가: `repos.txt`와 `.gitignore`에 함께 넣는다. 상위에서 하위 폴더를 `git add`하지 않는다.

| 경로 | remote | 역할 |
|---|---|---|
| `agent-rules/` | GitHub `dreamwayjgs/agent-rules` (public; 2026-10-21 GitLab에서 이전, 옛 이슈 #1~#11은 GitLab에 남음; 2026-10-29 `claude-settings-example`에서 이름 변경, 옛 URL은 redirect) | 전역 규칙·템플릿 source-of-truth. `build-claude-md.sh`(Windows는 `build-rules.ps1`, 소유자 실행)가 harness별 전역 규칙 파일과 `~/.config/agent-rules/`(템플릿)로 **복사** 배포. 포크 관리 주체 |
| `three-man-team/` | GitHub `dreamwayjgs/three-man-team` (public 포크, `upstream` = 원본) | 역할 템플릿. 이 clone이 정본. agent-rules build가 `templates/`를 `~/.config/agent-rules/three-man-team/`로 복사(+ `SOURCE`에 clone 경로·커밋)하고, 전역 규칙은 그 복사본을 읽는다. 포크 push 규칙은 agent-rules `CLAUDE.md`를 따른다 |
| `tmt-cli/` | GitHub `dreamwayjgs/tmt-cli` | 역할 세션 오케스트레이터 CLI. 전역 `tmt`는 `npm link`로 이 폴더를 가리킨다. `tmt init` 마커 블록·CLI 계약만 소유 |

의존 방향: 역할 파일 문구 변경 → agent-rules(이슈) → 포크 템플릿. tmt-cli는 역할 파일·포크를 직접 고치지 않는다.

- 배포본(`~/.claude/CLAUDE.md` 등)을 직접 고치지 말고 agent-rules에서 고친 뒤 build한다.
- tmt-cli를 옮기거나 재설치하면 `tmt-cli/`에서 `npm install && npm run build` 후 `npm link`를 다시 한다 (`dist/`는 추적하지 않는다).
- foreman: agent-rules·tmt-cli 모두 제외. 이 폴더에서도 실행하지 않는다.
