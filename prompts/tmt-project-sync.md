# 프로젝트 동기화 프롬프트 — 역할 파일·router를 템플릿 사본으로 덮어쓰기

이미 three-man-team이 세팅된 프로젝트에서, 역할 없는 세션에 붙여 넣는다. 먼저 그 머신이 dev-base 배치여야 하고(`MIGRATE.md`), `UPDATE.md`로 최신이어야 한다.
스텝 사이에 실행한다. 리뷰가 진행 중일 때는 하지 않는다.

역할 파일과 router는 템플릿에서 생성한 사본이다(claude-settings-example #10). 동기화는 병합하지 않고 덮어쓴다. 템플릿과 다른 줄은 보존하지 않고 보고하며, 프로젝트 규칙은 `PROJECT.md`로 옮긴다.

쓰는 법: 코드블록 안쪽을 붙여 넣거나, 세션에 "`<이 파일 경로>` 보고 진행해"라고 한다. 파일을 받은 세션은 코드블록 안을 지시로, 그 밖은 실행 조건으로 읽는다.

```
이 프로젝트의 three-man-team 역할 파일(ARCHITECT·BUILDER·REVIEWER·ROGER)과 router(`CLAUDE.md`·`AGENTS.md`)를 템플릿 사본으로 덮어써줘. 덮어쓰기 전에 템플릿과 다른 줄을 보고하고, 프로젝트 규칙은 `PROJECT.md`로 옮긴다. 삭제와 커밋은 내가 목록과 diff를 본 뒤에 한다.

준비
1. `~/.config/agent-rules/three-man-team/SOURCE`의 `clone=` 경로를 `<checkout>`으로 쓴다 (dev-base의 포크 git clone). origin이 `dreamwayjgs/three-man-team`인지 확인하고 `git -C <checkout> fetch origin` 후 (a) clone HEAD == `origin/main`, (b) `SOURCE`의 `commit=` == clone HEAD를 확인한다. pull은 하지 않는다 (clone 갱신은 `UPDATE.md` 몫).
   - `SOURCE`가 없거나 `clone=`이 dev-base 밖이면: 멈추고 "머신 전환 먼저(`MIGRATE.md`)".
   - HEAD가 `origin/main`보다 뒤거나 (b)가 다르면: 멈추고 "`UPDATE.md` 먼저".
   - HEAD가 `origin/main`보다 앞서면(push 안 된 포크 커밋): 멈추고 "포크 push 먼저".
   - 멈출 때 clone 경로, HEAD, `origin/main`, ahead/behind 수, `SOURCE` commit을 함께 보고한다.
2. 진행 중인 리뷰가 있는지 확인한다: handoff 디렉터리(세션 스코프면 `handoff-*`도)의 REVIEW-REQUEST가 `Ready for Review: YES`인데 REVIEW-FEEDBACK이 아직 없으면 멈추고 보고.
3. 좌표를 확정한다: manifest.md(없으면 프로젝트 루트)에서 역할 파일, 각 역할 이름(기본 Alice·Bob·Richard·Roger, 한국어 이름일 수 있다), 프로젝트 이름, handoff 경로를 찾는다. 파일이 여러 세트(v2/v3 등)면 세트별로 진행한다.

기대본 만들기
4. 역할 파일 기대본 = `git -C <checkout> show origin/main:templates/project-folder/<파일>`에 다음 치환만 한 것.
   - 이름: 단어 `Arch`·`Bob`·`Richard`를 그 프로젝트의 이름으로 (대소문자 구분, 워드바운더리. `Architect` 등 역할명은 보존).
   - 제목의 `[Your Project Name]`을 프로젝트 이름으로.
   - handoff 경로: `handoff/`와 fingerprint 명령의 `':(exclude)handoff'`를 그 프로젝트의 handoff 경로로 (기본값이면 그대로).
   - 기존 파일의 인코딩(UTF-8)과 줄바꿈(CRLF/LF)을 따른다. Windows에서는 pwsh 7을 쓴다.
5. router 기대본 = `~/.config/agent-rules/project-rules.md` 그대로. `CLAUDE.md`·`AGENTS.md` 둘 다 같다.
6. `<!-- tmt-cli:start -->`~`<!-- tmt-cli:end -->` 블록은 `tmt init` 소유다. 비교에서 빼고, 덮어쓴 뒤 8단계에서 다시 넣는다.

차이 보고 (아직 쓰지 않는다)
7. 파일별로 기존 파일과 기대본의 diff를 뽑고, 다른 줄을 하나씩 분류해 목록으로 보여준다.
   - (a) 템플릿 구버전·옛 동기화 잔재: 덮어쓰면 해결. 옮기지 않는다.
   - (b) 프로젝트 규칙(스택, 환경 메모, 하위 repo 메모, 프로젝트 전용 정책, 옵티마이저 지정 등): `PROJECT.md`로 옮길 문안을 같이 보여준다. `PROJECT.md`에 이미 같은 뜻이 있으면 "이미 있음".
   - (c) 판단이 애매한 것: 질문으로 남긴다.
   - 옛 qmd 규칙, caveman 강도 표기(`lite|full|ultra`), harness 전용 스킬 경로는 (a)로 본다.
   그다음 내 승인을 기다린다.

적용 (승인 후)
8. (b)를 `PROJECT.md`에 쓴다(없으면 만든다. 비어도 된다). 역할 파일과 router를 기대본으로 덮어쓴다. 프로젝트에 tmt-cli 블록이 있었거나 `tmt.json`이 있으면 `tmt init --apply`로 블록을 다시 넣는다. 끝나면 `CLAUDE.md`와 `AGENTS.md`가 같은지, 역할 파일과 기대본의 차이가 tmt-cli 블록뿐인지 확인한다.
9. manifest.md: 이번 기준 포크 커밋(`git -C <checkout> rev-parse --short origin/main`)을 `version`에 기록하고 `context_file: PROJECT.md`로 맞춘다. manifest가 없으면 포크 `templates/project-folder/new-setup.md`의 형식으로 만든다.
10. 덮어쓰지 않는 것:
   - OPERATOR.md와 프로젝트 전용 역할 파일(예: TRANSLATOR.md): 환경 좌표가 채워진 프로젝트 파일이다. 포크 `templates/optional/OPERATOR.md` 변경 중 규칙에 해당하는 것만 제안 목록으로 보고하고 적용하지 않는다.
   - 프로젝트에 남은 `new-setup.md`, `_temp/ARCHITECT.md`, `@.claude/skills/token-optimization.md` 같은 옛 import 대상 파일: 삭제를 제안만 한다.

보고
11. 파일별로 정리한다: 덮어쓴 파일, `PROJECT.md`로 옮긴 줄, 버린 줄(a), 남은 질문(c), OPERATOR 제안, tmt init 결과. 그다음 `git diff`를 보여준다. 커밋은 내 승인 후에 한다.
```
