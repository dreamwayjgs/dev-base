# 프로젝트 동기화 프롬프트 — 역할 파일·router를 템플릿 사본으로 덮어쓰기

이미 three-man-team이 세팅된 프로젝트에서, 역할 없는 세션에 붙여 넣는다. 먼저 그 머신이 dev-base 배치여야 하고(`MIGRATE.md`), `UPDATE.md`로 최신이어야 한다.
스텝 사이에 실행한다. 리뷰가 진행 중일 때는 하지 않는다.

역할 파일과 router는 템플릿에서 생성한 사본이다(agent-rules #10). 동기화는 병합하지 않고 덮어쓴다. 템플릿과 다른 줄은 보존하지 않고 보고하며, 프로젝트 규칙은 `PROJECT.md`로 옮긴다.

쓰는 법: 코드블록 안쪽을 붙여 넣거나, 세션에 "`<이 파일 경로>` 보고 진행해"라고 한다. 파일을 받은 세션은 코드블록 안을 지시로, 그 밖은 실행 조건으로 읽는다.

```
이 프로젝트의 three-man-team 역할 파일(ARCHITECT·BUILDER·REVIEWER·ROGER, 있으면 OPERATOR)과 router(`CLAUDE.md`·`AGENTS.md`)를 템플릿 사본으로 덮어써줘. 덮어쓰기 전에 템플릿과 다른 줄을 보고하고, 프로젝트 규칙은 `PROJECT.md`로 옮긴다. 삭제와 커밋은 내가 목록과 diff를 본 뒤에 한다.

준비
1. `~/.config/agent-rules/three-man-team/SOURCE`의 `clone=` 경로를 `<checkout>`으로 쓴다 (dev-base의 포크 git clone). origin이 `dreamwayjgs/three-man-team`인지 확인하고 `git -C <checkout> fetch origin` 후 (a) clone HEAD == `origin/main`, (b) `SOURCE`의 `commit=` == clone HEAD를 확인한다. pull은 하지 않는다 (clone 갱신은 `UPDATE.md` 몫).
   - `SOURCE`가 없거나 `clone=`이 dev-base 밖이면: 멈추고 "머신 전환 먼저(`MIGRATE.md`)".
   - HEAD가 `origin/main`보다 뒤거나 (b)가 다르면: 멈추고 "`UPDATE.md` 먼저".
   - HEAD가 `origin/main`보다 앞서면(push 안 된 포크 커밋): 멈추고 "포크 push 먼저". 같은 세션에서 방금 템플릿을 고친 경우라 내가 명시 승인하면 clone HEAD 기준으로 진행하되, manifest `version`에 HEAD를 적고 push가 남았음을 보고에 남긴다.
   - 멈출 때 clone 경로, HEAD, `origin/main`, ahead/behind 수, `SOURCE` commit을 함께 보고한다.
2. 진행 중인 리뷰가 있는지 확인한다: handoff 디렉터리(세션 스코프면 `handoff-*`도)의 REVIEW-REQUEST가 `Ready for Review: YES`인데 REVIEW-FEEDBACK이 아직 없으면 멈추고 보고. 역할 파일·router에 하다 만 미커밋 변경(이전 부분 동기화)이 있으면 덮어쓰기로 대체되니 보존하지 않고 목록만 보고한다.
2a. `tmt.json`에 `headless`가 있으면 이 트리에 쓰기 전에(8단계 직전) `tmt headless status`로 running이 비었는지 보고 `tmt headless pause --reason "template sync"`를 건다. running이 있으면 빌 때까지 기다린다. 커밋·push까지 끝나거나 내가 중단시키면 `tmt headless resume`. 차이 보고(7단계)까지는 읽기만 하므로 pause하지 않는다.
3. 좌표를 확정한다: manifest.md(없으면 프로젝트 루트)에서 역할 파일, 각 역할 이름(기본 Alice·Bob·Richard·Roger, 한국어 이름일 수 있다), 프로젝트 이름, handoff 경로를 찾는다. 파일이 여러 세트(v2/v3 등)면 세트별로 진행한다.

기대본 만들기
4. 역할 파일 기대본 = `git -C <checkout> show origin/main:templates/project-folder/<파일>`에 다음 치환만 한 것.
   - 이름: 단어 `Arch`·`Bob`·`Richard`를 그 프로젝트의 이름으로 (대소문자 구분, 워드바운더리. `Architect` 등 역할명은 보존).
   - 제목의 `[Your Project Name]`을 프로젝트 이름으로.
   - handoff 경로: `handoff/`와 fingerprint 명령의 `':(exclude)handoff'`를 그 프로젝트의 handoff 경로로 (기본값이면 그대로).
   - 기존 파일의 인코딩(UTF-8)과 줄바꿈(CRLF/LF)을 따른다. Windows에서는 pwsh 7을 쓴다.
   - 프로젝트에 `OPERATOR.md`가 있으면 `templates/optional/OPERATOR.md`로 같은 방식의 기대본을 만든다(이름 치환 없음, 제목의 프로젝트 이름만).
5. router 기대본 = `~/.config/agent-rules/project-rules.md` 그대로. `CLAUDE.md`·`AGENTS.md` 둘 다 같다.
6. `<!-- tmt-cli:start -->`~`<!-- tmt-cli:end -->` 블록은 `tmt init` 소유다. 비교에서 빼고, 덮어쓴 뒤 8단계에서 다시 넣는다.

차이 보고 (아직 쓰지 않는다)
7. 파일별로 기존 파일과 기대본의 diff를 뽑고, 다른 줄을 하나씩 분류해 목록으로 보여준다.
   - (a) 템플릿 구버전·옛 동기화 잔재: 덮어쓰면 해결. 옮기지 않는다.
   - (b) 프로젝트 규칙(스택, 환경 메모, 하위 repo 메모, 프로젝트 전용 정책, 옵티마이저 지정 등): `PROJECT.md`로 옮길 문안을 같이 보여준다. `PROJECT.md`에 이미 같은 뜻이 있으면 "이미 있음".
   - (c) 판단이 애매한 것: 질문으로 남긴다. router 맨 위의 `@<file>` import는 모든 세션에 실리므로, 한 세션만 쓰는 문서면 import 대신 "그 세션만 읽는다" 참조로 바꿀지 (c)로 묻는다.
   - 옛 qmd 규칙, caveman 강도 표기(`lite|full|ultra`), harness 전용 스킬 경로는 (a)로 본다.
   - `OPERATOR.md`를 이번에 처음 넣는데 `ops/`가 이미 있으면, OPERATOR.md Outputs 표(INDEX·jobs·tmp·runbooks·FAQ)와 겹치는 기존 파일·폴더를 목록으로 보여주고 매핑(무엇이 무슨 역할을 대신하는지)을 `PROJECT.md`에 적을 문안을 만든다.
   - 기존 `OPERATOR.md`에 환경 좌표 절이나 프로젝트 전용 소절이 남아 있으면 (b)다: 좌표는 `ops/ENV.md`(없으면 포크 `templates/optional/ops/ENV.md` 형식으로 생성)로, 규칙은 `PROJECT.md`로 옮길 문안을 보여준다.
   - handoff 수명 규약(ARCHITECT.md `## Handoff Lifecycle`)과 충돌하는 문장은 (b)로 옮기지 않는다. handoff 파일 사본 보존(`*.archive.md`·`archive/`·`.bak`·"덮어쓰기 전 보존"), BUILD-LOG를 append-only로 두거나 줄이지 말라는 지시, private repo에서 handoff를 git에서 빼라는 지시는 (a). handoff 밖 산출물(`ops/` 등)의 보존 규칙은 (b) 그대로. public repo의 handoff 제외는 손대지 않고 "`prompts/repo-go-public.md` 대상"으로 보고한다.
   - `PROJECT.md` 쪽도 본다. 역할 파일·router 규칙을 덮어쓰는 줄("…보다 우선", "OPERATOR.md의 … 규칙 대신" 등) 가운데 새 템플릿이 같은 내용을 담게 된 것은 삭제 후보로 보여준다(그 줄, 대신하는 템플릿 문장, 프로젝트 설정이 그 템플릿 조건을 만족하는지 — 예: `headless.ignorePaths`). 템플릿과 결과가 달라지는 줄은 남긴다.
   - 옛 오즈 등급 표기(T0·T1·T2): `PROJECT.md`에 있으면 바꿀 문안을 보여준다(T0 = 읽기 또는 L0, T1 = L1, T2 = L3). `ops/ENV.md`와 기존 `ops/` 보고서는 고치지 않고 개수만 보고한다(OPERATOR.md Permissions 절의 대응 줄로 읽는다).
   그다음 내 승인을 기다린다.

적용 (승인 후)
8. (b)와 승인된 `PROJECT.md` 삭제·문안 변경을 `PROJECT.md`에 쓴다(없으면 만든다. 비어도 된다). 역할 파일과 router를 기대본으로 덮어쓴다. 스테이징은 동기화가 만들거나 바꾼 파일만 한다. `git add -A`를 쓰지 않고, 관련 없는 미추적 파일은 보고만 한다. 프로젝트에 tmt-cli 블록이 있었거나 `tmt.json`이 있으면 `tmt init --apply`로 블록을 다시 넣는다. 끝나면 `CLAUDE.md`와 `AGENTS.md`가 같은지, 역할 파일과 기대본의 차이가 tmt-cli 블록뿐인지 확인한다.
   - `PROJECT.md`에 트래커 언어 절(이슈 본문·댓글·PR 제목·본문의 언어)이 없으면 소유자에게 언어를 고르게 하고 그 절을 쓴다(예: `## 트래커 언어` — 이슈 본문·댓글·PR 제목·본문은 한국어, 커밋·코드·handoff·역할 산출물은 영어). tmt-cli `fa5a34f`부터 router 블록이 이 절을 가리키므로 비워 두지 않는다.
9. manifest.md: 이번 기준 포크 커밋(`git -C <checkout> rev-parse --short origin/main`)을 `version`에, 오늘 날짜를 `synced`에 기록하고 `context_file: PROJECT.md`로 맞춘다. `operator`·`visibility` 줄이 비어 있으면 채운다. manifest가 없으면 포크 `templates/project-folder/new-setup.md`의 형식으로 만든다.
10. 덮어쓰지 않는 것:
   - `ops/ENV.md`: 오즈가 실측으로 채우는 프로젝트 파일이다. 절대 덮어쓰지 않는다.
   - 프로젝트 전용 역할 파일(예: TRANSLATOR.md): 포크에 템플릿이 없으므로 덮어쓰지 않는다.
   - 프로젝트에 남은 `new-setup.md`, `VERSION`, `_temp/ARCHITECT.md`, `@.claude/skills/token-optimization.md` 같은 템플릿 잔재·옛 import 대상 파일: 삭제를 제안만 한다. 루트의 재개 메모·조사 메모·트래커 미러는 `prompts/handoff-cleanup.md` 12단계 몫이다.

보고
11. 파일별로 정리한다: 덮어쓴 파일, `PROJECT.md`로 옮긴 줄, `PROJECT.md`에서 지우거나 바꾼 줄, 버린 줄(a), 남은 질문(c), `ops/ENV.md`로 옮긴 좌표, tmt init 결과. 그다음 `git diff`를 보여준다. 커밋은 내 승인 후에 한다.
```
