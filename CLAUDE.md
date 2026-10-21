# dev-base — 개발머신 설정 3총사

서로 얽힌 세 repo를 한 세션에서 함께 보기 위한 작업 공간이다. 이 폴더 자체는 manifest repo(GitHub `dreamwayjgs/dev-base`, private)로 `CLAUDE.md`·`repos.txt`·`bootstrap.sh`만 추적한다. 세 repo는 `.gitignore`로 제외된 독립 clone이며 서브모듈이 아니다. 커밋·push는 각 repo 안에서 따로 하고, 각 repo의 `CLAUDE.md` 규칙을 따른다.

- 새 머신: 이 repo를 clone한 뒤 `./bootstrap.sh [name...]` (없는 repo만 clone, upstream remote 설정). 기존 clone이 있는 머신은 `MIGRATE.md` 절차를 따른다.
- 공통 템플릿 배포 경로는 harness 무관 `~/.config/agent-rules/`다. dev-base 밖에서 build하면 아무것도 쓰지 않고 멈춘다.
- repo 추가: `repos.txt`와 `.gitignore`에 함께 넣는다. 상위에서 하위 폴더를 `git add`하지 않는다.

| 경로 | remote | 역할 |
|---|---|---|
| `claude-settings-example/` | GitLab `gsjung_impactAI/claude-settings-example` (`glab`) | 전역 규칙·템플릿 source-of-truth. `build-claude-md.sh`(Windows는 `build-rules.ps1`, 소유자 실행)가 `~/.claude`·`~/.config/opencode`·`~/.omp`·`~/.config/crush`로 **복사** 배포. 포크 관리 주체 |
| `three-man-team/` | GitHub `dreamwayjgs/three-man-team` (public 포크, `upstream` = 원본) | 역할 템플릿. 이 clone이 정본. claude-settings-example build가 `templates/`를 `~/.config/agent-rules/three-man-team/`로 복사(+ `SOURCE`에 clone 경로·커밋)하고, 전역 규칙은 그 복사본을 읽는다. 포크 push 규칙은 claude-settings-example `CLAUDE.md`를 따른다 |
| `tmt-cli/` | GitHub `dreamwayjgs/tmt-cli` | 역할 세션 오케스트레이터 CLI. 전역 `tmt`는 `npm link`로 이 폴더를 가리킨다. `tmt init` 마커 블록·CLI 계약만 소유 |

의존 방향: 역할 파일 문구 변경 → claude-settings-example(이슈) → 포크 템플릿. tmt-cli는 역할 파일·포크를 직접 고치지 않는다.

- 배포본(`~/.claude/CLAUDE.md` 등)을 직접 고치지 말고 claude-settings-example에서 고친 뒤 build한다.
- tmt-cli를 옮기거나 재설치하면 `tmt-cli/`에서 `npm link`를 다시 한다.
- foreman: claude-settings-example·tmt-cli 모두 제외. 이 폴더에서도 실행하지 않는다.
