# repo 공개 — private repo를 public으로 바꾸기, public repo의 handoff 운영

private 규약(handoff를 코드 repo에서 추적)을 쓰던 repo를 public으로 바꿀 때, 또는 public repo에서 tmt를 쓸 때 따른다. 문서로만 둔 절차다(2026-10-23 기준 tmt를 쓰는 public repo는 없다). 실행 전에 이 절차를 다시 검토한다.

## public 운영 규약

- `handoff/`는 별도 private repo `<repo>-handoff`의 clone이다. 코드 repo는 `handoff/`를 `.gitignore`에 둔다. 역할 파일·tmt 경로(`handoff/`)는 그대로다.
- deploy gate에서 두 repo를 각각 커밋한다. handoff repo 커밋 메시지에 코드 repo 커밋 해시를 적는다.
- 내부 작업 이슈(Known Gaps 등)는 handoff repo의 이슈로 둔다. 외부에 보여도 되는 이슈만 public 트래커에 둔다. 코드 repo에는 `local-issues/`를 두지 않는다.
- `.scratch/`·`.tmt/`는 private과 같이 git-ignore한다.
- manifest.md: `visibility: public`.
- 새 머신: 코드 repo를 clone한 뒤 `git clone <handoff repo> handoff`.
- 같은 repo의 orphan 브랜치에 handoff를 두는 방식은 쓰지 않는다(`git push --all` 한 번에 공개된다).

## private → public 전환 (소유자, 역할 없는 세션)

쓰는 법: 세션에 "`<dev-base>/prompts/repo-go-public.md` 보고 <repo> 전환 진행해"라고 한다. 세션은 코드블록 안을 지시로 읽는다.

```
이 repo를 public으로 바꿀 준비를 해줘. 공개 설정 변경과 push, 히스토리 재작성은 각각 내 승인 후에만 한다.

1. 준비: 진행 중인 Step이 없어야 한다(리뷰 대기, 미커밋 handoff가 있으면 멈춤). 모든 머신의 clone이 push되어 있는지 나에게 확인받는다.
2. handoff repo 만들기:
   - 백업 clone을 따로 만든다(`git clone --mirror`).
   - 작업용 clone에서 `git filter-repo --path handoff/ --path local-issues/`로 handoff와 local-issues 히스토리만 남기고, `handoff/` 아래를 루트로 옮긴다(`--path-rename handoff/:`). `local-issues/`는 이슈로 옮길 것이라 그대로 둔다.
   - private repo `<repo>-handoff`를 만들고(`gh repo create --private`) push한다.
   - `local-issues/`의 열린 항목은 그 repo의 이슈로 만들고 파일은 지운다.
3. 공개할 코드 히스토리 정하기(나에게 고르게 한다):
   - 스냅샷: 현재 트리에서 `handoff/`·`local-issues/`를 뺀 상태로 새 히스토리 1커밋. 기존 private repo는 보관하거나 지운다.
   - 정리: `git filter-repo --path handoff/ --path local-issues/ --invert-paths`. 커밋 해시가 모두 바뀌므로 다른 머신 clone은 다시 받아야 하고, BUILD-LOG의 deploy 해시·`.tmt` 기록은 옛 해시를 가리킨다고 보고한다.
4. 공개 전 점검(남은 히스토리 전체 대상): 비밀값(토큰·키·비밀번호), 회사 식별자(회사명·사내 프로젝트명·내부 호스트·이메일), 개인 경로·호스트를 `git log -p`로 grep한다. 걸리면 멈추고 목록을 보고한다.
5. 코드 repo: `.gitignore`에 `handoff/` 추가, `handoff/`에 handoff repo clone, manifest.md `visibility: public`, 역할 파일·프로젝트 지침이 public 규약을 따르는지 grep.
6. 각 머신 안내: 다시 clone할지(3단계 "정리"를 골랐으면 필수), `handoff/`에 handoff repo clone.
7. 마지막에 공개 설정 변경 명령(`gh repo edit --visibility public --accept-visibility-change-consequences`)을 보여주고, 내가 직접 실행하거나 승인한다.
```

## public → private

설정만 바꾼다(`gh repo edit --visibility private --accept-visibility-change-consequences`). GitHub는 이때 star·watcher를 잃고, 남의 fork는 분리된다. 그 뒤 handoff를 코드 repo에서 추적하려면 `prompts/handoff-cleanup.md`를 따른다(5단계 "추적 전환").
