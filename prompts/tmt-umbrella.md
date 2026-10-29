# tmt umbrella — 코드 repo와 tmt 운영 repo 분리

tmt를 쓰는 프로젝트의 기본 레이아웃이다(2026-10-29 합의). 코드 repo `abc`는 코드만 갖고, 역할 파일·handoff·PROJECT.md 등 tmt 운영물은 별도 private repo `abc-tmt`(umbrella)에 둔다. 코드 repo는 umbrella 안에 git-ignore된 독립 clone으로 들어간다. 코드 repo의 공개 여부는 umbrella와 무관해진다.

이미 이 구조로 운영 중인 프로젝트는 umbrella 이름을 `-tmt`로 바꾸지 않아도 된다. 새 프로젝트는 visibility와 상관없이 이 레이아웃으로 시작한다. handoff를 코드 repo에서 추적하던 기존 프로젝트는 아래 "마이그레이션"으로 옮긴다. 옛 `<repo>-handoff` 분리 방식(2026-10-23 문서)은 쓰지 않는다.

## 레이아웃

```
abc-tmt/                 umbrella repo (private). 세션은 항상 여기서 연다
  CLAUDE.md AGENTS.md    공통 router (tmt-rules + tmt-cli 마커 블록)
  ARCHITECT.md BUILDER.md REVIEWER.md ROGER.md [OPERATOR.md]   템플릿 사본 (sync가 덮어씀)
  [TRANSLATOR.md ...]    프로젝트 전용 역할 (sync 비대상, 아래 절)
  PROJECT.md manifest.md
  handoff/               (스코프가 여럿이면 handoff-<scope>/)
  local-issues/ ops/ docs/ ...
  .tmt/ tmt.json .scratch/   git-ignore
  abc/                   코드 repo의 독립 clone. git-ignore. 각자 git이 정본
```

- umbrella 하나에 코드 repo 여러 개를 둘 수 있다(예: 백엔드·프론트엔드·CLI repo를 한 umbrella에). 스코프별 handoff 디렉터리는 PROJECT.md가 매핑한다.
- 코드 repo에는 tmt 흔적을 두지 않는다. 코드 repo의 `CLAUDE.md`는 외부 기여자·역할 없는 세션용 프로젝트 지침이다. router 마커 블록·역할 파일·handoff·manifest.md를 넣지 않는다.
- submodule은 쓰지 않는다(detached HEAD가 밥의 스텝 브랜치 작업과 충돌하고, 커밋 연결은 deploy gate 기록으로 충분하다). 같은 repo의 orphan 브랜치에 handoff를 두는 방식도 쓰지 않는다(`git push --all` 한 번에 공개된다).

## 운영 규약

- **세션 루트**: 모든 역할 세션은 umbrella 루트에서 연다. 코드 repo 안에서 역할 세션을 열지 않는다(router가 없어 역할 없이 조용히 돌아간다). PROJECT.md 첫 절에 이 규칙과 레이아웃 표(코드 repo·브랜치·handoff 디렉터리)를 둔다.
- **기본값**: 지칭 없이 쓴 repo·브랜치·`main`·git 명령·히스토리·visibility는 코드 repo를 뜻한다. umbrella를 뜻할 때는 반드시 "umbrella"라고 부른다. umbrella의 파일(handoff·PROJECT.md)은 매 턴 고치지만 umbrella에 git 명령을 치는 일은 앨리스의 deploy gate 커밋뿐이고, 역할 파일·router 갱신은 템플릿 sync로 한다.
- **repo root 해석**: 역할 파일의 "repo root"(test fingerprint, `git log`, 브랜치, `main`)는 코드 repo 루트(`abc/`)다. 코드 repo의 git 명령은 모두 `git -C abc …`로 치거나 `abc/` 안에서 실행한다. umbrella 루트에서 bare `git`을 치는 경우는 앨리스의 deploy gate 커밋뿐이다. PROJECT.md에 명시한다.
- **커밋 주체**: 밥 = 코드 repo 스텝 브랜치. 앨리스 = deploy gate에서 코드 repo `abc` `main` 머지와 umbrella 커밋(handoff·PROJECT.md). umbrella 커밋 메시지에 코드 repo 커밋 해시를 적는다. 문서·handoff에서 `main`은 항상 어느 repo인지 붙여 쓴다(`abc` `main` / umbrella `main`).
- **이슈**: 내부 작업 이슈(Known Gaps 등)는 umbrella repo 이슈 또는 `local-issues/`. 코드 repo 트래커에는 외부에 보여도 되는 이슈만 둔다.
- **manifest.md**: `visibility`는 코드 repo 것. `repo:`에 코드 repo remote·subdir·branch, umbrella 자신의 remote를 적는다(예: `repo: git@host:org/abc.git (subdir abc/, branch main); umbrella: git@host:org/abc-tmt.git`). `handoff_dir`은 디렉터리 또는 스코프별 매핑.
- **새 머신**: `git clone <umbrella>` 후, umbrella clone 안의 manifest.md `repo:`가 적은 subdir(`abc/`)에 코드 repo를 clone한다.
- **상류 변경 감지**: 코드 repo에 tmt 밖에서 커밋이 들어올 수 있다(다른 기여자의 PR 머지, 소유자의 직접 커밋). 로컬 clone은 fetch 전까지 모른다. 앨리스는 세션 시작과 brief 작성 전에 fetch하고 SESSION-CHECKPOINT에 적힌 코드 repo `abc` `main`의 마지막 해시와 대조한다. 새 커밋이 있으면 밥의 스텝 브랜치 rebase 여부와 brief 재스코프를 판단해 체크포인트에 적는다.

  ```
  git -C abc fetch origin
  git -C abc log --oneline <checkpoint 해시>..origin/main
  gh -R <owner>/abc pr list --state merged --limit 10     # GitLab은 glab mr list --merged
  ```

- **프로젝트 전용 역할**(템플릿에 없는 역할 파일, 예: 번역 역할 `TRANSLATOR.md`): umbrella에 둔다. manifest.md `## Customizations`에 "프로젝트 소유, sync 비대상"으로 적고, router에는 넣지 않으며(router는 템플릿 그대로) 호출 규칙·handoff 파일은 PROJECT.md에 적는다. 코드 repo에 두는 경우는 역할 없는 세션도 쓰는 도구 성격일 때뿐이며, 그때는 역할 페르소나가 아니라 프로젝트 지침으로 다시 쓴다.
- **공개 전환**: 코드 repo 전체 히스토리를 비밀값·회사 식별자·개인 경로로 grep한 뒤 `gh repo edit <owner>/abc --visibility public --accept-visibility-change-consequences`(소유자 실행). umbrella는 손대지 않는다. public → private도 설정만 바꾼다(star·watcher를 잃고 남의 fork는 분리된다).

## PROJECT.md·manifest.md 예시

PROJECT.md 첫 절(단일 코드 repo 기준. 스코프가 여럿이면 표에 행을 늘리고 handoff 디렉터리를 나눈다):

```markdown
## 레이아웃 (umbrella)

세션은 항상 umbrella 루트(`abc-tmt/`)에서 연다. `abc/` 안에서 역할 세션을 열지 않는다.
역할 파일의 "repo root"·test fingerprint·`git log`·브랜치·`main`은 코드 repo `abc/` 기준이다. 코드 repo git 명령은 `git -C abc …`. umbrella 루트의 bare `git`은 앨리스 deploy gate 커밋만.
이 문서·handoff의 파일 경로는 umbrella 루트 기준(`abc/src/...`)으로 적는다.
지칭 없는 repo·브랜치·`main`·git 명령은 `abc`를 뜻한다. umbrella를 뜻할 때는 "umbrella"라고 쓴다.

| 스코프 | 코드 repo | 브랜치 | handoff |
|---|---|---|---|
| (단일) | `abc/` (git-ignore, 각자 git이 정본) | `main` | `handoff/` |

- 커밋: 밥 = `abc/` 스텝 브랜치. 앨리스 = deploy gate에서 `abc` `main` 머지 + umbrella repo(`abc-tmt`) 커밋(메시지에 abc 커밋 해시).
- 상류 확인: 세션 시작·brief 작성 전 `git -C abc fetch origin` 후 SESSION-CHECKPOINT에 적힌 `abc` `main` 해시와 대조한다.
- 내부 이슈는 umbrella repo(`abc-tmt`)의 이슈 또는 `local-issues/`. `abc` 트래커에는 외부에 보여도 되는 것만.
```

manifest.md `## Project`·`## Customizations`:

```markdown
## Project
visibility: public                 # 코드 repo abc 기준. umbrella는 항상 private
layout: umbrella
umbrella: git@host:org/abc-tmt.git (private, branch main; abc/ excluded)
repo: git@host:org/abc.git (subdir abc/, branch main)
handoff_dir: handoff/
context_file: PROJECT.md

## Customizations
- TRANSLATOR.md: project-owned role, not synced; invocation rules in PROJECT.md
```

## 새 프로젝트 셋업 (소유자)

1. `abc-tmt/`를 만들고 `git init`, private remote를 만든다(GitHub `gh repo create <owner>/abc-tmt --private`, GitLab은 `glab repo create`).
2. umbrella `.gitignore`(`abc-tmt/.gitignore`): `abc/`, `.tmt/`, `tmt.json`, `.scratch/`, harness 로컬 설정(`.claude/settings.local.json`, `opencode.json` 등 비밀값 포함 파일).
3. `abc/`에 코드 repo를 clone한다(없으면 새로 만든다).
4. umbrella 루트에서 "three-man-team 세팅해줘". 전역 절차의 "프로젝트 루트"·`.gitignore`·`git` 대상은 모두 umbrella 루트로 읽는다(`abc/`는 건드리지 않는다). 필요하면 "operator 세팅해줘".
5. PROJECT.md 첫 절과 manifest.md를 위 예시대로 채운다.
6. umbrella 루트에서 `tmt init --apply`(스코프가 여럿이면 `--handoff-dir` 반복).
7. 코드 repo `CLAUDE.md`는 외부 기여자 관점으로 쓴다. tmt 운영 내용은 PROJECT.md에만 둔다.

## 마이그레이션 — handoff를 코드 repo에서 추적하던 프로젝트 (소유자, 역할 없는 세션)

쓰는 법: 기존 코드 repo 체크아웃에서 세션을 열고 "`<dev-base>/prompts/tmt-umbrella.md` 보고 <repo> 마이그레이션 진행해"라고 한다. 세션은 코드블록 안을 지시로 읽는다.

```
이 프로젝트를 tmt umbrella 레이아웃(코드 repo <repo> + umbrella repo <repo>-tmt)으로 옮길 준비를 해줘. 파일 이동·삭제·히스토리 재작성·push·remote 생성은 각각 목록을 보여주고 내 승인 후에만 한다.

위치: 지금 cwd는 기존 코드 repo 체크아웃이다. umbrella `<repo>-tmt/`는 이 체크아웃의 부모 디렉터리에 만든다(코드 repo 안에 만들지 않는다). `<repo>-tmt/<repo>/`는 기존 체크아웃을 옮기지 않고 origin에서 새로 clone한다(분리를 골랐으면 재작성 후 push된 origin에서). 기존 체크아웃은 마이그레이션이 끝나고 내가 지운다.

준비
1. Step 사이여야 한다(리뷰 대기, 미커밋 handoff가 있으면 멈춤). 모든 머신의 clone이 push되어 있는지 나에게 확인받는다.
2. 코드 repo origin의 실제 visibility를 확인한다(`gh repo view --json visibility` 또는 `glab api projects/<id>`). manifest.md와 다르면 보고한다.

인벤토리 (목록만 만들고 아직 바꾸지 않는다)
3. 코드 repo 루트의 tmt 운영물을 찾아 파일마다 처분(umbrella 이동 / 코드 repo 잔류 / 삭제)을 표로 만든다:
   - 템플릿 역할 파일(ARCHITECT·BUILDER·REVIEWER·ROGER·OPERATOR·new-setup) → umbrella. 히스토리는 보존하지 않아도 된다(템플릿에서 다시 복사).
   - router(CLAUDE.md·AGENTS.md)의 tmt-rules·tmt-cli 마커 블록 → umbrella. 마커 밖에 남는 프로젝트 지침은 "외부 기여자에게 필요한 것"과 "tmt 운영"으로 나눠 전자는 코드 repo CLAUDE.md에, 후자는 PROJECT.md로.
   - PROJECT.md·manifest.md·handoff*/·local-issues/·ops/·루트 메모(START.md·CHECKLIST.md 등) → umbrella. 히스토리 보존 대상.
   - .tmt/·tmt.json·.scratch/ → umbrella의 git-ignore 항목. 파일은 옮긴다.
   - 템플릿 밖 역할 파일(역할 페르소나를 가진 *.md, 예: TRANSLATOR.md): 하나씩 나에게 묻는다 — umbrella 이동(기본) / 폐기 / 코드 repo 잔류(역할 없는 세션도 쓰는 도구 성격일 때만). 이동하면 manifest.md Customizations에 "프로젝트 소유, sync 비대상", 호출 규칙은 PROJECT.md. 잔류하면 페르소나를 빼고 프로젝트 지침으로 다시 쓴다.
   - PROJECT.md·역할 파일·handoff에서 코드 repo 경로를 루트 기준(`src/...`)으로 적은 곳을 grep한다. umbrella의 PROJECT.md·handoff에서는 umbrella 루트 기준 `<repo>/src/...`로 적어야 하므로 고칠 목록을 만든다.

히스토리 (나에게 고르게 한다)
4. 두 가지 중 하나:
   - 스냅샷: umbrella는 현재 파일로 새 히스토리를 시작한다. 코드 repo(origin `main`)에는 tmt 파일을 지우는 커밋 하나(6번). handoff 히스토리는 코드 repo에 남는다(계속 private이면 허용. 공개 예정이면 코드 repo 히스토리를 아래 "분리"로 재작성하거나 새 repo로 재시작해야 한다).
   - 분리: 코드 repo를 `git clone --mirror`로 백업한다. 코드 repo를 새로 두 번 clone해 A·B로 쓴다(기존 작업 체크아웃에서는 filter-repo를 실행하지 않는다). A(→ umbrella)에서 `git filter-repo --path <3번의 umbrella 이동 목록>`(handoff·PROJECT.md·manifest.md·local-issues·ops·루트 메모·프로젝트 전용 역할. 템플릿 역할 파일·router는 제외). B(→ 코드 repo)에서 같은 목록 + 템플릿 역할 파일로 `--invert-paths`(CLAUDE.md·AGENTS.md는 마커 밖 지침이 남으므로 제외하고 6번에서 손으로 고친다). 코드 repo 해시가 전부 바뀐다: 다른 머신은 다시 clone해야 하고, BUILD-LOG의 deploy 해시·`.tmt` 기록은 옛 해시를 가리킨다고 보고한다.

조립
5. umbrella: 위 "새 프로젝트 셋업" 1·2·3·5·6. 역할 파일과 router는 `prompts/tmt-project-sync.md`로 템플릿에서 다시 받는다. PROJECT.md에 레이아웃 표·세션 루트 규칙·repo root 해석·커밋 주체를 추가하고 3번의 경로 목록을 고친다. manifest.md `repo:`·`visibility`·`handoff_dir`·Customizations를 갱신한다.
6. 코드 repo: tmt 파일 삭제(스냅샷이면 커밋), CLAUDE.md를 외부 기여자 관점으로 재작성, `.gitignore`에서 handoff·.tmt·.scratch 항목 제거(umbrella로 갔으므로). `AGENTS.md`가 router였으면 삭제하거나 CLAUDE.md와 같은 내용으로.
7. local-issues/의 열린 항목: umbrella repo 이슈로 만들지 파일로 둘지 나에게 묻는다.

점검
8. 코드 repo에서 `handoff|ARCHITECT|BUILDER|REVIEWER|ROGER|OPERATOR|manifest.md|PROJECT.md|tmt`를 grep해 남은 참조를 보고한다. umbrella에서 역할 파일의 handoff 경로와 PROJECT.md 매핑이 맞는지, BUILD-LOG 마지막 deploy 해시가 코드 repo에 존재하는지 확인한다(스냅샷일 때. 분리면 옛→새 해시 대응만 보고한다).
9. 각 머신 안내: umbrella clone, 코드 repo clone 위치, 분리를 골랐으면 코드 repo 재clone 필수.
10. 공개 전환은 이 절차에 포함하지 않는다. 필요하면 "운영 규약 — 공개 전환"을 따로 진행한다.
```

## 후속 (이 문서 밖)

- 전역 "three-man-team 세팅해줘" 절차와 `new-setup.md`는 프로젝트 루트 = 코드 repo 루트를 전제한다. 역할 파일의 test fingerprint "repo root" 문구도 코드 repo 루트로 명확히 할 필요가 있다. claude-settings-example 이슈 → 포크 템플릿 경로로 처리한다.
- 상류 변경 자동 감지는 tmt-cli 후보 기능이다. 지금은 위 수동 절차다.
