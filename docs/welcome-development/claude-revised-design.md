# Revised design: SHOP3-controlled workflow for S1–S4 (Safe and Familiar Welcome)

## Context

Zettel 11569/11570 define four planned slices:
- **S1 Source:** acquire Ward's genuine page JSON.
- **S2 Plan:** a hypothetical fork plan.
- **S3 Execute:** an authorized, create-only local fork.
- **S4 Explore:** the investigation and Topicmap projections.

The review accepted the architecture: development planning, FedWiki planning, signed authorization, execution and independent verification are separate. This revision addresses the six review findings. It is design only: no code, commits, services or Wiki writes.

**Base:** `origin/dreyeck.ch` = `99dbe5599dc6c0b080bec1b743dd864aa5635e0b` (remote default HEAD). It contains the local-only slice through R1. Line numbers refer to this commit.

**Labels:** **[obs]** = executed in this session; **[abg]** = derived from source, not executed.

Two levels, never merged:

| Level | Planner | Who acts | What counts as a fact |
|---|---|---|---|
| Development | new `welcome-development` domain (§1) | the user, Claude Code or Codex, manually assigned | only records from independent verification, review and repository observation (§2) |
| FedWiki | existing `defederation-preparation` (`dreyeck/work/defederation-planning.lisp`), unchanged | a separate Lisp fork executor after signed authorization (§4) | only store observations and the re-read result of a write |

---

## 1. Development planning: a next-action cycle over verified state

**Why the old design failed:** a single `deliver-welcome` plan cannot reach S2, because S2 needs verified S1 state, and the planner can only create `planned-*` effects.

**New shape:** the planner answers one question, "what is the next admissible action?", from verified records. The cycle is:
1. Build the initial state from records only.
2. Plan `(advance-welcome)` with `:which :all`; each plan has exactly one step.
3. A human or executor carries out the chosen step outside SHOP3, producing a record.
4. Rebuild the state from records and plan again.

Planned effects (`planned-*`) never re-enter the state.

**States are kept apart:**
- `slice-verified ?s ?commit ?verification` — independent verification passed;
- `slice-review-accepted ?s ?commit ?review` — a review by someone other than the implementer;
- `slice-integrated ?s ?commit ?head` — the commit is an ancestor of the observed `dreyeck.ch` head.

A slice is **accepted** when it is verified **and** review-accepted for the same commit. The next slice becomes eligible on acceptance, not on integration. Its base is the accepted commit. Integration stays a separate, proposed operation that needs repository evidence, so there is no automatic merge.

### Domain `welcome-development` (verified against pinned SHOP3 `ce53f9b` [obs])

- Package `dreyeck/work/welcome-development` uses only CL, like the other `dreyeck/work` domains.
- Style: `dreyeck/work/remote-control-planning.lisp`, with labelled multi-branch axioms as in `defederation-planning.lisp`.
- `?_x` variables in negations work [obs].

```lisp
(shop3:defdomain (welcome-development :noset t)
 ((:- (accepted ?s) ((slice-verified ?s ?c ?_v) (slice-review-accepted ?s ?c ?_r)))
  (:- (accepted-commit ?s ?c) ((slice-verified ?s ?c ?_v) (slice-review-accepted ?s ?c ?_r)))
  (:- (blocked-by-dependency ?s) ((depends-on ?s ?d) (not (accepted ?d))))
  (:- (eligible ?s) ((slice ?s) (not (blocked-by-dependency ?s))))
  (:- (base-for ?s ?b) from-dependency ((depends-on ?s ?d) (accepted-commit ?d ?b))
                       from-observed-base ((not (depends-on ?s ?_any)) (observed-base ?b)))
  (:- (attempted-by ?s ?e) ((assignment ?s ?_a ?e ?_b)))
  (:- (implemented-by ?s ?c ?e) ((claimed ?s ?a ?c) (assignment ?s ?a ?e ?_b)))
  (:- (eligible-reviewer ?s ?c ?r) ((may-review ?r ?s) (not (implemented-by ?s ?c ?r))))
  (:- (reviewed ?s ?c) accepted ((slice-review-accepted ?s ?c ?_a)) rejected ((slice-review-rejected ?s ?c ?_b)))
  (:- (closed ?s ?a) failed ((claimed ?s ?a ?c) (verification-failed ?s ?c ?_v))
                     rejected ((claimed ?s ?a ?c) (slice-review-rejected ?s ?c ?_r)))
  (:- (open-assignment ?s) ((assignment ?s ?a ?_e ?_b) (not (closed ?s ?a))))
  (:- (has-closed-attempt ?s) ((assignment ?s ?a ?_e ?_b) (closed ?s ?a)))
  (:- (checked ?s ?c) verified ((slice-verified ?s ?c ?_v)) failed ((verification-failed ?s ?c ?_w)))
  (:- (untried-executor ?s ?e) ((may-implement ?e ?s) (not (attempted-by ?s ?e))))
  ;; every operator only proposes; effects are planned-* and never read by any precondition
  (:operator (!propose-integration ?s ?c) () () ((planned-integration-proposal ?s ?c)))
  (:operator (!request-review ?s ?c ?r) () () ((planned-review-request ?s ?c ?r)))
  (:operator (!verify-submission ?s ?a ?c) () () ((planned-verification ?s ?a ?c)))
  (:operator (!await-submission ?s ?a ?e) () () ())
  (:operator (!assign ?s ?e ?b) () () ((planned-assignment ?s ?e ?b)))
  (:operator (!report-blocker ?s ?reason) () () ((planned-blocker-report ?s ?reason)))
  (:method (advance-welcome) propose-integration
   ((accepted-commit ?s ?c) (not (slice-integrated ?s ?c ?_m))) ((!propose-integration ?s ?c)))
  (:method (advance-welcome) request-review
   ((eligible ?s) (slice-verified ?s ?c ?_v) (not (reviewed ?s ?c)) (eligible-reviewer ?s ?c ?r))
   ((!request-review ?s ?c ?r)))
  (:method (advance-welcome) blocker-no-reviewer
   ((eligible ?s) (slice-verified ?s ?c ?_v) (not (reviewed ?s ?c)) (not (eligible-reviewer ?s ?c ?_r)))
   ((!report-blocker ?s no-eligible-reviewer)))
  (:method (advance-welcome) verify-submission
   ((eligible ?s) (claimed ?s ?a ?c) (not (checked ?s ?c))) ((!verify-submission ?s ?a ?c)))
  (:method (advance-welcome) await-submission
   ((eligible ?s) (assignment ?s ?a ?e ?_b) (not (claimed ?s ?a ?_c))) ((!await-submission ?s ?a ?e)))
  (:method (advance-welcome) first-assignment
   ((eligible ?s) (not (accepted ?s)) (not (attempted-by ?s ?_x)) (base-for ?s ?b) (may-implement ?e ?s))
   ((!assign ?s ?e ?b)))
  (:method (advance-welcome) reassignment
   ((eligible ?s) (not (accepted ?s)) (not (open-assignment ?s)) (has-closed-attempt ?s)
    (attempts ?s ?n) (attempt-limit ?max) (shop3:call < ?n ?max) (base-for ?s ?b) (untried-executor ?s ?e))
   ((!assign ?s ?e ?b)))
  (:method (advance-welcome) blocker-attempt-limit
   ((eligible ?s) (not (accepted ?s)) (not (open-assignment ?s)) (has-closed-attempt ?s)
    (attempts ?s ?n) (attempt-limit ?max) (shop3:call >= ?n ?max))
   ((!report-blocker ?s attempts-exhausted)))
  (:method (advance-welcome) blocker-no-alternative
   ((eligible ?s) (not (accepted ?s)) (not (open-assignment ?s)) (has-closed-attempt ?s)
    (attempts ?s ?n) (attempt-limit ?max) (shop3:call < ?n ?max) (not (untried-executor ?s ?_e)))
   ((!report-blocker ?s no-alternative-executor)))))
```

To add during implementation [abg]:
- `(!report-complete)` for the state "all four integrated", so a finished project gives an explicit step instead of `:no-plan`;
- the problem fixtures via `shop3:defproblem`, as in `planning.lisp`.

### SHOP3 syntax findings [obs]

1. **`forall` and `call` must be package-qualified** in a domain whose package does not use SHOP3:
   - `shop3:forall` (home `shop3.theorem-prover`) and `shop3:call` (home `shop3.common`) work;
   - unqualified `forall` / `call` are read as ordinary predicates and **silently yield no plan**;
   - PR #31 already wrote `shop3:call`.

   The domain avoids `forall` and expresses eligibility by negation-as-failure (`blocked-by-dependency`). The W1 test pins both behaviours.
2. **Plan trees.** `advance-welcome` is compound and every plan has one step, so the known plan-tree defect (`STRIP-TREE-TAGS` on an empty plan or a primitive top-level task) does not arise. Running with `:plan-tree t` is a W1 test [abg]. The run above used `:plan-tree nil`.
3. **Normalizer.** `classify-hyperdoc-plan-step` / `normalize-hyperdoc-plan-step` (`dreyeck/shop3/plan-objects.lisp:42–80`) would label every development operator `:source-edit :manual? t`. That is misleading, and the shared contract (`:commit` destructures `(stage message)`) is used by other readings. Decision: **no change to the shared normalizer.** Instead, a local view `development-next-action-view` in the new system reads `hyperdoc-htn-plan-result` (`plan-objects.lisp:3`, `execution-mode` :10) directly.

### Example initial problem and expected first plan [obs]

```lisp
(shop3:defproblem welcome-initial welcome-development
  ((slice s1) (slice s2) (slice s3) (slice s4)
   (depends-on s2 s1) (depends-on s3 s2) (depends-on s4 s3)
   (may-implement codex s1) (may-implement claude-code s1) (may-implement codex s2)
   (may-implement codex s3) (may-implement claude-code s4)
   (may-review claude-code s1) (may-review claude-code s2) (may-review claude-code s3) (may-review codex s4)
   (attempt-limit 2) (observed-base "99dbe5599dc6c0b080bec1b743dd864aa5635e0b"))
  ((advance-welcome)))
```

**Expected first plans** (`:which :all`): `((!ASSIGN S1 CODEX <base>))` and `((!ASSIGN S1 CLAUDE-CODE <base>))`. These are two alternatives; the chosen one becomes an assignment record.

### Scenario and negative tests (all executed in memory with pinned SHOP3) [obs]

| # | Verified state added to the initial problem | Plans (`:which :all`) |
|---|---|---|
| P1 | assignment a1 (codex), no submission | `(!await-submission s1 a1 codex)` |
| P2 | + agent claim `c1` only | `(!verify-submission s1 a1 "c1")`. **No S2 action** |
| P2b | + `planned-verification`, `planned-review-request`, `planned-integration-proposal` | unchanged from P2: planned effects never count |
| P3 | + `slice-verified s1 "c1"` | `(!request-review s1 "c1" claude-code)` |
| P4 | + `slice-review-accepted s1 "c1"` (not integrated) | `(!propose-integration s1 "c1")` **or** `(!assign s2 codex "c1")`. S2 is eligible without a merge |
| P4b | review accepted for another commit `c0` | `(!request-review s1 "c1" …)`. Not accepted |
| P5 | + `slice-integrated s1 "c1" "m1"` | `(!assign s2 codex "c1")` |
| P6 | verification of `c1` failed, attempt 1/2 | `(!assign s1 claude-code …)`: an alternative executor |
| P7 | second attempt rejected by review, 2/2 | `(!report-blocker s1 attempts-exhausted)` |
| P8 | S2 failed, no untried executor | `(!report-blocker s2 no-alternative-executor)` |
| P9 | the only reviewer is the implementer | `(!report-blocker s1 no-eligible-reviewer)` |
| P10 | out-of-order S2 claim while S1 is unverified | only `(!verify-submission s1 …)`. The S2 claim is ignored |
| P11 | S1 and S2 accepted, none integrated | two `!propose-integration` steps or `(!assign s3 codex "c2")`. Nothing is merged automatically |

## 2. Records: from artifacts to facts (planned ≠ done)

New small record classes in the new system. **Only `development-state (records)` builds SHOP3 facts, and only from these records, never from `planned-*` effects or agent text.**

| Record | Retained artifact observations | Fact it may produce |
|---|---|---|
| `dev-assignment` | slice; base commit (40 hex); branch; allowed path globs; acceptance tests and markers; forbidden actions; source plan (plan digest + step) | `(assignment s a e base)`, `(attempts s n)` |
| `dev-submission` | executor, claimed commit, free text. Status `:claimed` | `(claimed s a c)` only |
| `dev-verification` | see the list below | `slice-verified` (verdict `:verified`) / `verification-failed` (verdict `:rejected`) |
| `dev-review` | reviewer, commit, decision, findings, digest of the review text | `slice-review-accepted` / `slice-review-rejected` (commit must match; reviewer ≠ implementer) |
| `integration-observation` | `git ls-remote origin refs/heads/dreyeck.ch` head; `git merge-base --is-ancestor <commit> <head>` | `(slice-integrated s c head)` |

`dev-verification` retains:
- (a) the resolved commit (`git cat-file -t` = commit);
- (b) the ancestry `git merge-base --is-ancestor <base> <commit>`;
- (c) `git diff --name-only <base> <commit>` checked against the allowed globs;
- (d) the tree id;
- (e) per test system: command, exit code, the required markers found, log SHA-256, platform evidence (§5);
- (f) declared environment limits;
- (g) checker and time.

**Positive verification result.** `verdict = :verified` iff (a)–(e) all hold and every required marker is present. An environment-limited suite (D2/TALA) is recorded as a limit, never as a pass, and must not be a required test.

**Not sufficient:** `invoke-workspace-operation-recording-result` (`dreyeck/src/workspace-operation.lisp:44`) with status `:returned` means only that the check function returned. The verdict is in its value. A `:failed` invocation (checker error) produces **no** fact, so the planner proposes `!verify-submission` again.

The invocation stays the inspectable carrier through the existing evaluation-record projection (`dreyeck/src/evaluation-record-workspace-operation.lisp`).

**Missing API:** a shared read-only git observer. Existing calls (`dreyeck/src/git-repository-checkout.lisp`, `dreyeck/work/project/project-workspace.lisp:39`) are local helpers.

## 3. FedWiki planning (S2): reuse unchanged

- `observe-link` (`dreyeck/work/fedwiki-local-only.lisp:184`), `prepare-link` :256, `continue-preparation` :260, `resolve-link` :280.
- Evidence format with `snapshot-path` (:46, `snapshots/[A-Za-z0-9_-]+.json`) and the R1 guards (:198–207).
- `!simulate-fork` (`defederation-planning.lisp:37–45`) stays hypothetical and `:plan-only`.
- S2 adds only:
  - an isolated test site;
  - a test page with `[[Safe and Familiar Welcome]]`;
  - an evidence file referencing the S1 snapshot (`site` `ward.asia.wiki.org`, its SHA-256).

## 4. S3 execution boundary

### 4a. Stable, serializable identities

Lisp object identity is not used across processes; `prepare-link` names problems with `gensym` (`defederation-planning.lisp:100`).

All identities are SHA-256 over canonical JSON (sorted keys, no insignificant whitespace, UTF-8):

| Identity | Canonical content |
|---|---|
| `source-id` | SHA-256 of the exact retrieved octets. S1 record: URL, retrieval time (UTC), HTTP status, content type, byte length |
| `observation-id` | site id; source slug; source page octets digest (`observe-local-fedwiki-page-source`); item index and item id; link slug; finding; target path relative to the site root; evidence-file SHA-256 |
| `plan-id` | domain digest (SHA-256 of the `defdomain` form text, as `%source-form-digest`, `dreyeck/src/authority-policy.lisp:646`); sorted initial facts; task list; `:which :all`; plan count; the ordered operator lists |
| alternative | index **and** the `!simulate-fork` tuple `(site slug remote snapshot)` |
| destination | `{service-id, site-id, slug}`. The root is resolved only by `authoring-authority-site-root` (`dreyeck/src/authenticated-page-authoring.lisp:271`) and recorded, not signed |
| `request-id` | Keccak-256 of the signed body (the existing envelope binding, `verify-authoring-body-binding`, `authoring-envelope.lisp:225`) |

Before writing, the executor recomputes `observation-id` and `plan-id` from a fresh observation and a fresh SHOP3 run (`:which :all`), and compares them with the request. A determinism test is part of S3b.

### 4b. Three different byte sequences

1. **Source bytes:** the snapshot file. Bound by `source-id`; re-hashed before writing.
2. **Signed request body:** canonical JSON of identifiers and digests only (destination, `source-id`, `observation-id`, `plan-id`, alternative, fork entry `{type fork, site, date}`, operation). Expected size about 1–2 KiB, far below `+body-limit+` = 65536 (`authenticated-page-authoring.lisp:318`). **The page JSON is never embedded.**
3. **Persisted bytes:** `materialize-fedwiki-page-fork` (`dreyeck/src/fedwiki-page-materialization.lisp:157`) re-serializes `page-json-with-fork` (:38) with SHASHT, so the result is not equal to the source bytes. Verification is semantic:
   - Story equals the source Story;
   - Journal = source Journal + exactly the signed fork entry;
   - reuse `json-equal` (exported by `fedwiki-item-edit-execution.lisp`).

   The persisted SHA-256 is recorded as an observation after the write, never predicted or signed.

### 4c. Authorization (extend the existing signed authority, design only)

- `+operations+` (`authenticated-page-authoring.lisp:258`): add `("fedwiki-page-fork" . "fork")`.
- New `%fork-body` beside `%edit-body` (:343): exact key set, size limit.
- New `authenticate-authorize-fedwiki-page-fork` mirroring `authenticate-authorize-fedwiki-page-edit` (:357). It reuses:
  - `authenticate-authoring-request` (:324);
  - `%check-challenge` / `%consume-challenge` (:225/:232);
  - `%authorize` (:286, rule per principal/site/page/operation);
  - site roots from `make-authoring-authority` (:276).
- **Not** `%derive-capability` (:309): the item-edit capability (`fedwiki-page-authoring.lisp:38–57`) must not cover a fork. Missing API: a create-only capability.
- First implementation: the authority lists only an explicitly configured isolated test site, and the executor refuses roots outside a configured test-root prefix. The served Catalog gets no `:contracted` executor operation (`authority-policy.lisp:60`, `invocation-decision` :150).

### 4d. Atomically exclusive page creation (no overwrite fallback)

**Defect today:** `materialize-fedwiki-page-json` checks `probe-file` for `:if-exists :error` and later renames with `uiop:rename-file-overwriting-target` (fedwiki-page-materialization.lisp:89–151). A file created in between is overwritten.

**Design:** new `:if-exists :create-exclusive`, used by `materialize-fedwiki-page-fork`:
1. Write the temporary file (`%temporary-page-pathname` :68, already created exclusively in the same directory).
2. Optionally `fsync` it.
3. Publish with `link(2)` temp → target. This fails atomically with `EEXIST` if the target exists, and the target never shows a partial file.
4. Delete the temporary file.

| OS / file system | Support |
|---|---|
| Linux (ext4, xfs, btrfs, tmpfs) | supported. `sb-posix:link` is present in the pinned SBCL [obs] |
| macOS (APFS, HFS+) | supported by POSIX `link(2)` semantics. `sb-posix:link` on macOS must be checked there [abg] |
| No hard links (FAT/exFAT, some SMB/NFS configurations), Windows | not supported → refusal `:exclusive-create-unsupported` |

On `EEXIST`, `EPERM`, `ENOTSUP`, `EXDEV` or any other `link` error: refuse, delete the temporary file, never rename. No crash durability is claimed beyond the optional `fsync`.

**Not covered:** later writes by the Node wiki server. The in-process `%page-lock` (`fedwiki-page-authoring.lisp:82`) does not cover other processes.

### 4e. Executor steps and records

The pattern follows `fedwiki-item-edit-execution.lisp`: stage comment :30–71, `item-edit-execution` :158, `execute-completed-edit` :245, `execution-refusal` :317, new-process `+verifier+` :354, `verify-persisted-edit` :397.

1. `fork-execution-request` (§4a/§4b).
2. Authorization decision object.
3. Revalidation: identities recomputed, source re-hash, target absent, challenge unused.
4. Exclusive write.
5. Verification in a new process, plus a fresh `observe-link`, which must give `:observed-local`, and `resolve-link`, which must give `!open-panel`.
6. `fork-execution-record`. Outcomes:
   - `:refused` (stage, reason; "no byte written" only for refusals before `link`);
   - `:exists`;
   - `:written-verified`;
   - `:written-unverified` / `:unclear` (re-read decides; no automatic deletion).

## 5. Platform-specific acceptance evidence

| Check | Linux | macOS |
|---|---|---|
| Network isolation | `unshare --net` (or `unshare -rn`) | `sandbox-exec` with a `deny network*` profile where available; otherwise the record says `:network-isolation :none` |
| Syscall evidence of no network | `strace -f -e trace=%network`, with a marker and a positive control connection | **recorded unverified** (`:syscall-trace :unverified`). dtrace/dtruss needs SIP changes and is not prescribed. Lisp guards (as in the local-only tests) are reported as Lisp-level evidence only |
| Exclusive creation | two OS processes racing the same target: exactly one success, one `:exists` | same test, run on macOS |
| Test suites | isolated SBCL, empty HOME, private FASL cache | same, without namespace isolation |

Every verification record carries `:platform`, `:network-isolation` and `:syscall-trace`. A missing check is a stated limit, never a pass.

## 6. Slices (inspection grows with each slice)

| Slice | Delivers | Inspectable objects added | Key tests |
|---|---|---|---|
| **W1** | `welcome-development` domain, records, `development-state`, `development-next-action-view` | assignment, submission, verification, review, integration objects; development Topicmap projection | P0–P11 as executable tests; package-qualification test for `shop3:call` / `shop3:forall`; `:plan-tree t` on all |
| **S1** | genuine source acquisition at development time (outside the served image); source record; page/Story/Journal/link objects (reuse `checked-page-json`, `fedwiki-local-only.lisp:22`); Text + Code Page | source snapshot, page, items, journal, links; **Projection 1** (Source and Link Dependencies) | stored octets re-hash; record fields complete; invalid JSON / non-200 → **blocker record, no Story or Journal invented**; no recursive fetch |
| **S2** | test site + evidence + test page | observation, evidence, problem, plan, `!simulate-fork`; hypothetical part of **Projection 2** | `:confirmed-local-absence`; one `!simulate-fork` with `ward.asia.wiki.org` and the source digest; continuation 0 forks; `resolve-link` hypothetical; fixture bytes unchanged; network evidence per §5 |
| **S3a** | `:create-exclusive` materialization | — | existing target → refusal, bytes unchanged; two-process race; unsupported file system → refusal; temporary file removed |
| **S3b** | fork operation, `%fork-body`, create-only capability, identity functions | request, authorization decision | each refusal reason; single-use challenge; each bound field change refused; body size; item-edit capability cannot fork; `plan-id` determinism |
| **S3c** | fork executor | execution and verification records; written target page; completes **Projection 2** | test-root only; `:exists`; new-process semantic verification; persisted digest recorded; fresh observation `:observed-local`; replan → 0 forks |
| **S4** | integrated investigation pages, native Topicmap Workspaces over the existing projections | cross-links between all earlier objects | topic ids stable (§4a); topics hold EQ objects; every association labelled observed/derived/inferred/hypothesized/claimed; no executor control in the served Catalog; interactive CLOG check recorded as open until performed |

Order: W1 ∥ S1 → S2 → S3a → S3b → S3c → S4.

## Missing APIs (marked, not invented)

- `fedwiki-page-fork` operation, `%fork-body`, `authenticate-authorize-fedwiki-page-fork`, create-only capability.
- `:create-exclusive` in `materialize-fedwiki-page-json`; macOS `sb-posix:link` check.
- Canonical identity functions (`source-id`, `observation-id`, `plan-id`); fork request/record classes.
- Development records, `development-state`, a shared read-only git observer.
- The S1 acquisition procedure. `hyperbook/fedwiki::fetch-page-json` exists but performs unrestricted network access and must not run in the served image.

## Verification of this design

The development-domain behaviour (P0–P11) and the `forall`/`call` package findings were executed in memory against the pinned SHOP3 `ce53f9b` and SBCL 2.4.10 [obs]. Nothing was written to the repository.

Everything marked [abg] becomes a test in the slice that implements it.
