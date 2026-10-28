# handoff 정리 — 기존 프로젝트를 handoff 수명 규약에 맞추기 (일회성)

handoff 수명 규약(claude-settings-example #5: handoff 추적, `handoff/evidence/<step>/`, 이슈 또는 `local-issues/`, `.scratch/`) 이전에 만들어진 프로젝트를 한 번 정리한다. handoff 밖에 쌓인 루트 메모(재개 메모·조사 메모·트래커 미러·템플릿 잔재)도 같이 분류한다(12번). 프로젝트가 있는 머신의 역할 없는 세션에서, Step 사이에 실행한다. 먼저 `prompts/tmt-project-sync.md`로 역할 파일을 #5가 반영된 템플릿에 맞춘다.

쓰는 법: 세션에 "`<dev-base>/prompts/handoff-cleanup.md` 보고 진행해"라고 한다. 이미 정리한 프로젝트에서 로테이션만 할 때는 "준비(1~5)와 10번만"이라고 덧붙인다. 세션은 코드블록 안을 지시로, 밖을 실행 조건으로 읽는다.

```
이 프로젝트의 handoff를 수명 규약에 맞게 정리해줘. 지우거나 옮기기 전에 항상 목록을 보여주고 내 승인을 받는다. 커밋은 내가 diff를 본 뒤에 한다. 파일 내용은 분류에 필요한 만큼만 읽는다.

준비
1. 역할 파일(ARCHITECT.md 등)에 `## Handoff Lifecycle` 절이 있는지 grep한다. 없으면 멈추고 "tmt-project-sync 먼저"라고 보고한다.
2. 진행 중인 리뷰가 있으면 멈춘다(REVIEW-REQUEST가 `Ready for Review: YES`인데 REVIEW-FEEDBACK이 없음). 워킹트리가 더러우면 목록을 보고하고 계속할지 묻는다.
3. 공개 여부: origin remote의 실제 visibility를 확인한다(GitHub `gh repo view <owner/repo> --json visibility`, GitLab `glab api projects/<id>`). manifest.md의 `visibility`와 다르거나 없으면 보고한다. public이면 멈추고 "`prompts/repo-go-public.md`의 public 운영 절차 대상"이라고 보고한다.
4. handoff 디렉터리 목록: manifest.md의 `handoff_dir`이 현재 디렉터리다. `handoff*/`가 여러 개면(예: v2·v3) 현재 것이 아닌 디렉터리를 따로 표시한다.
5. 충돌 지시 점검: `PROJECT.md`·router 마커 밖·SESSION-CHECKPOINT에서 `archive|\.bak|보존|append-only|append only|never trim`을 grep한다. 기준은 `prompts/tmt-project-sync.md` 7단계의 handoff 수명 규약 항목과 같다: 충돌 문장은 삭제·수정안을, handoff 밖 산출물 규칙은 그대로 두고, public repo의 handoff 제외는 보고만 한다. 결과는 12번 표에 함께 넣는다.

분류 (목록만 만들고 아직 바꾸지 않는다)
6. 추적 상태: `git check-ignore -v <handoff_dir>`로 handoff가 ignore되는지 본다. ignore되면 "추적 전환" 대상이다(현재 파일을 처음 커밋한다. 그 이전 히스토리는 없다).
7. handoff 안 파일을 아래로 나눈다. 판단이 애매하면 "확인 필요"로 둔다.
   - 상태 파일: ARCHITECT-BRIEF·REVIEW-REQUEST·REVIEW-FEEDBACK·SESSION-CHECKPOINT·BUILD-LOG, 진행 중인 `ARCHITECT-BRIEF-<name>.md` → 유지
   - 아카이브 사본: `*.archive.md`, `archive/`, `*.bak`, `*-ARCHIVE.md`, 끝난 작업의 `ARCHITECT-BRIEF-<name>.md` → 삭제(추적 파일이면 git에 남는다. 미추적이면 지우면 사라지니 따로 표시한다)
   - Step 산출물(증거·보고서·측정): 진행 중 Step 것 → `<handoff_dir>/evidence/<step>/`로 이동. 끝난 Step 것 → 삭제, 또는 이 repo의 배포할 만한 문서면 `docs/`로 이동 제안
   - 데이터·큰 출력(실험 결과, 덤프, 바이너리, 100KB 넘는 비텍스트) → `.scratch/`로 이동
   - 현재 것이 아닌 handoff 디렉터리 전체 → 추적되면 삭제 제안(git에 남는다), 미추적 데이터가 섞였으면 그 부분은 `.scratch/`로
8. BUILD-LOG의 Known Gaps 중 끝난 Step에서 넘어온 미해결 항목 → 이슈 초안 목록. 트래커가 gh/glab이면 이슈 제목·본문 초안, 없으면 `local-issues/NNN-slug.md` 초안. 이미 같은 이슈가 있으면 표시만 한다.
9. SESSION-CHECKPOINT: ARCHITECT.md `## Checkpoint Maintenance` 기준으로 점검한다. 대체된 승인·일시정지·재개 지시, 서로 모순되는 상태가 있으면 정리안을 만든다(새 권한·예산을 만들지 않는다).
10. BUILD-LOG 로테이션(ARCHITECT.md `## Handoff Lifecycle`의 Step Index 규칙). handoff 디렉터리가 여럿이면 각각 한다.
   - 먼저 상시 참조 절을 찾는다: 체크포인트·PROJECT.md·역할 파일이 원문으로 가리키는 절, 상시 전제·규칙, 아키텍처 결정, 체크포인트가 근거로 인용하는 ID 장부(A번호 등). 규칙·전제는 `PROJECT.md`, 오래 유지할 결정은 `docs/decisions.md`로 옮기는 안을 만들고, 가리키던 쪽의 참조도 고친다. 인용 ID는 색인 줄의 커밋으로 찾을 수 있으니 옮기지 않는다.
   - 기록 순서를 확인한다. 최신이 위로 쌓이는 로그면 현재 Step이 맨 위다.
   - 끝난 Step 기록 전체를 `## Step Index` 아래 한 줄(`- Steps ≤N (through YYYY-MM-DD) — entries: git show <정리 직전 커밋>:handoff/BUILD-LOG.md`)로 바꾸는 안을 보여준다. 진행 중인 Step 기록은 남긴다. BUILD-LOG에 커밋 안 된 변경이 있으면 먼저 커밋할지 묻는다(색인이 가리킬 커밋에 원문이 다 있어야 한다). 이후 Step은 deploy gate에서 Step마다 한 줄씩 붙는다.
11. `.gitignore`: `.scratch/`가 없으면 추가 대상. handoff가 ignore되고 있고 private이면 그 줄 제거 대상. manifest.md에 `visibility` 줄이 없으면 추가 대상.
12. 루트의 낡은 메모(handoff 밖). 분류만 하고 조치는 승인 후.
   - 재개·상태 메모(`START.md`, `RESUME.md`, 날짜가 이름인 `YYYYMMDD.md` 등): SESSION-CHECKPOINT가 같은 내용을 담으면 삭제 제안(추적 파일이면 git에 남는다). 체크포인트에 없는 결정·지시가 있으면 그 줄을 체크포인트나 `PROJECT.md`로 옮길 문안을 만든다.
   - 조사·분석 메모: 오즈가 있으면 `ops/investigation-<date>-<topic>.md`로 이동 제안(INDEX 등록은 오즈 몫), 없으면 `docs/`.
   - 외부 트래커의 수동 미러(`docs/TICKETS.md` 같은 것): 트래커가 정본이면 삭제 제안. 미러에만 있는 항목(커밋 해시·판단 메모)은 먼저 목록으로 보여준다.
   - 템플릿 잔재(`new-setup.md`, `VERSION`, `_temp/`, 옛 import 대상 스킬 파일): 삭제 제안. `prompts/tmt-project-sync.md` 10단계와 같은 항목이다.
   - 미추적 파일은 `git mv`가 실패한다. `mv` 후 `git add`로 옮긴다.

보고와 적용
13. 분류 결과를 표로 보여준다: 경로, 분류, 조치, 추적 여부, 크기. 미추적 파일 삭제(복구 불가)는 따로 모아 보여준다. 내 승인을 받은 항목만 적용한다.
14. 이슈는 내가 승인한 초안만 만든다(`gh issue create`/`glab issue create` 또는 `local-issues/` 파일).
15. 적용은 이 정리가 만들거나 바꾼 파일만 스테이징한다. `git add -A`를 쓰지 않는다. 관련 없는 미추적 파일은 목록으로 보고만 한다. 그다음 `git status`와 `git diff --stat`을 보여준다. 커밋 메시지 제안: `chore(handoff): adopt handoff lifecycle (evidence, issues, .scratch)`. 커밋·push는 내 승인 후.
```
