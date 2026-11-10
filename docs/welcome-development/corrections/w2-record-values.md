# W2 N1: ground record values at the SHOP3 fact boundary

Accepted baseline: `276320e353af9689297cf87656391cbd5d7236bb`, PR #39.
Date: 2026-11-10. This is pre-S1 hardening after W2 acceptance. The historical
source screen, native SHOP3 domain, state-only planner, bindings format and views
are unchanged.

## Independently reproduced failure

A detached worktree at the exact accepted commit loaded its original ASDF
systems. A separate retained probe created domain F and its dedicated approval
fixture tag in an OS-allocated temporary repository. The domain contains the
reviewed method unchanged:

```lisp
(:method (advance-welcome) rv-state
 ((assignment ?s ?a ?e ?b)
  (shop3:call < ?a 1))
 ((!report-blocker ?s rv-state)))
```

The fixture also supplies assignment/await methods so the records have genuine
native proposal bindings. The source screen correctly admits F: its CALL takes
a comparison and a plain logical variable. The old record projection then
places a compound assignment ID in the state. SHOP3 substitutes it for `?a` and
evaluates it as Lisp while checking a submission.

[reviewed-baseline.log](w2-record-values-evidence/reviewed-baseline.log) records
both the required list attack and an atomic symbol-macro variant:

| Assignment ID | Baseline observation | Corrected observation |
|---|---|---|
| `(clear-development-domain-cache)` | Submission admitted; 2 planning calls; 1 real cache-clear call; cache 1 → 0. | `:unsafe-planning-value`, field `:record-id`; 0 planning calls, 0 cache-clear calls. |
| `n1-symbol-macro`, defined to expand to cache clearing | Same baseline execution and cache mutation, although the ID is an atom. | Same early refusal; no macro expansion or evaluation. |

The source is read through the accepted Eclector screen, the tag resolves to a
real local commit, admission recomputes its native domain identity, and actual
SHOP3 planning runs. This is not a mocked evaluator or a forged plan binding.
The test journal's policy/claim are synthetic inputs; no real implementation,
verification, review or progress is asserted. The positive test admits numeric
ID `0` through F and retains **both** its blocker and await alternatives, with
native `:PLAN-ONLY` results. Thus the fix does not simply reject domain F.

## Explicit value contract

`project-development-records` checks each record's projection fields before
building facts and checks **every emitted fact argument** before returning a
state. Ordered `development-state` replay applies the same pure field check to
the current record before its proposal/submission planning check. Neither
validation path calls the planner, reader, macroexpander or evaluator.

| Value kind | Rule |
|---|---|
| Self-evaluating data | Strings, integers, keywords, NIL and T. A string containing Lisp text remains a string. |
| Permitted symbolic constants | Interned symbols in `DREYECK/WORK/WELCOME-DEVELOPMENT`, with no Lisp value binding and SBCL variable kind `:unknown`. Examples: `s1`, `codex`, named human actors. |
| SHOP3 variables | Refused as values, including `?`-prefixed keywords; facts must be ground. The pinned engine's non-mutating name predicate is reused. |
| Lisp variables / macros | Bound names, declared-but-unbound specials, constants/global bindings and symbol macros are not symbolic data constants. Non-evaluating SBCL metadata is inspected; symbol macros are never expanded. |
| Compound/other values | Conses, vectors other than strings, characters, ratios/floats, pathnames, function objects, hash tables, uninterned and foreign non-self-evaluating symbols, and unknown value types refuse. |

Existing field-specific rules still apply: commits are full SHA strings, attempt
limits positive integers, slices one of S1–S4, and evidence/review/identity checks
remain in force. Implementer/reviewer lists must be proper lists of exact
`(actor slice)` pairs. Actors are nonempty strings or non-NIL permitted symbols;
slices must be the workflow's actual S1–S4 symbols. No splicing of arbitrary
pair structure into a planning fact is permitted.

The field audit covers:

| Record | Checked projection / replay fields |
|---|---|
| Policy | Base, attempt limit, both arguments of every implementer/reviewer pair. |
| Assignment | Slice, record ID, executor, base. |
| Submission | Slice, assignment reference, executor, commit. |
| Verification | Slice, assignment reference, commit, verification record ID. |
| Review | Slice, assignment reference, commit, review record ID. |
| Integration | Slice, commit, head. |

Submission assignment references become accepted assignment IDs in `claimed`
facts; executor also appears in the exact await task checked during replay.
Verification/review assignment references are checked even though their result
facts carry their own record IDs. Generated counts and fixed slice/dependency
arguments pass the final emitted-argument check too. A future projection cannot
silently emit a compound value merely by omitting an input-field check.

The ordinary symbolic constants remain in W1's namespace so native domain joins
and actor identities retain their existing meaning. They are inert tokens,
not Lisp variable references; an arbitrary domain comparing such a token to a
number can still have a type/unbound-variable error. This contract prevents
record values from supplying executable Lisp; it does not promise that every
trusted domain performs type-correct comparisons on every legal value.

## Identity and compatibility

Original record objects remain first-class and are retained by EQ in runs,
Inspector references and Topicmap topics. There is no general record-ID coercion,
replacement wrapper or implicit repair. Invalid incoming IDs are refused.
Rich nonprojected evidence, domain-version identities, policy identities and
submission/integration provenance IDs remain on their original records; they
are not planning operands.

Only the fixture constructors for projected composite IDs change:

- Verification IDs explicitly serialize `(:verification assignment-id verdict)`
  into a deterministic canonical **string**.
- Review IDs similarly serialize `(:review assignment-id decision commit)`.
- The complete scenario's assignment IDs serialize `(:all slice)`.

The fixture-only `fixture-record-key` uses the existing canonical literal
printer. It preserves each tuple's parts and package identity, independently of
caller printer settings. Other fixtures keep their existing keyword assignment
IDs. Child references use the exact generated scalar ID. No arbitrary incoming
compound ID is passed through this fixture serialization during replay.

This is a stricter **current record-validator contract**, as allowed by W2's
explicit historical-validator non-claim. Existing journals with compound
assignment/verification/review IDs, Lisp-variable names or unsupported policy
pairs now refuse. Producers must explicitly choose data IDs and update their
references. Bindings whose prior-state facts change must be regenerated from
accepted records using native SHOP3; old digests must not be relabelled.
Binding format remains v2, native domain content ID/tag identity is unchanged,
and the P0 binding digest remains unchanged. Historical validation is not replayed.

## Tests and exact commands

[Probe source](../../../dreyeck/tests/welcome-record-values.lisp) is part of the
existing optional `domain-version-tests` ASDF system. Focused evidence is in
[focused.log](w2-record-values-evidence/focused.log).

Baseline reproduction from `/workspace/work/welcome-w2` in the prepared runtime:

```sh
git worktree add --detach /workspace/work/w2-n1-baseline \
  276320e353af9689297cf87656391cbd5d7236bb
DEFEDERATION_REPO=/workspace/work/w2-n1-baseline \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --load /workspace/work/welcome-w2/dreyeck/tests/welcome-record-values.lisp \
  --eval '(dreyeck/work/welcome-development::n1-tagged-replay t)' \
  --eval '(dreyeck/work/welcome-development::n1-tagged-replay t (quote dreyeck/work/welcome-development::n1-symbol-macro))'
```

Corrected focused command:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --eval '(dreyeck/work/welcome-development::run-record-value-tests)'
```

Complete acceptance/regression/syscall run:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
W2_SBCL=/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
W2_BOOTSTRAP=/workspace/work/defederation-bootstrap.lisp \
W2_LOGS=/workspace/work/w2-n1-final-evidence \
scripts/audit-welcome-domain-versions.sh
```

The unchanged audit script supplies exact SBCL flags, empty child HOME, private
FASL cache, ASDF tests, fresh-process identity comparison and strace invocations.
The cache was seeded from the prepared local dependency cache; no dependency
acquisition occurred. The registry bootstrap is retained in the original
[environment-bootstrap.lisp](../w2-evidence/environment-bootstrap.lisp).

## Executed results

| Check | Result | Evidence |
|---|---|---|
| N1 compound ID and atomic macro ID with tagged F | Both refused with zero planning/cache-clear calls and unchanged cache entry EQ identities, public domain/plist/dynamic domain and problem registry/pointer. | acceptance.log; focused.log |
| All 25 projection fields | 100 negatives: compound expression, bound special, unbound special, symbol macro in each field. All refuse without planning/evaluation. | acceptance.log, `N1 FIELD` / `N1 MATRIX` |
| Policy pairs | 28 malformed-collection/pair/actor/slice cases refuse. | acceptance.log, `N1 POLICY` |
| Other unsupported values / output guard | Ratios, floats, characters, vectors, functions, pathnames, hash tables, uninterned/foreign/variable symbols and nested output fact values refuse. | acceptance.log |
| Positive identity/actors/provenance | Keyword/integer/string/owned-symbol IDs, Lisp text as string, named symbolic/keyword/string actors pass; rich provenance and record EQ identity retained; complete returns `:complete` and `:PLAN-ONLY`. | acceptance.log, `N1 POSITIVES` |
| A1–A13, D1/D2 | PASS, including exact authentic W1 source at `61cdec0`, both expected S1 assignments, private construction failure cleanup, deleted/replaced public domain replay, no recover restart invocation. | acceptance.log |
| P0–P11, completion, F1–F5, C1–C3, record validation | PASS. Claims on closed/exhausted assignments still refuse as `:submission-not-proposed`. | regressions.log |
| Inspector/Topicmap and all native alternatives | PASS; EQ links and fixture provenance retained, all native raw plans/trees/final states and `:PLAN-ONLY` preserved. No Catalog addition. | regressions.log; acceptance.log; fixture.log; replay.log |
| Lifecycle / L1 | PASS: 100 complete runs + 20 complete journal builds; problem registry and current pointer unchanged; exactly one distinct cached version. | acceptance.log; fixture.log |
| Defederation / Local-only | Both unchanged regression suites PASS. | regressions.log |
| Fresh-process identity / syscall audit / tags | PASS: identical version and v2 P0 binding digests; fixture makes zero Git/network calls; replay uses only read-only Git and zero network calls; positive socket control detected; project and temporary replay tag snapshots unchanged. | audit.log; identity logs; traces; tag snapshots |

Complete audit exit status: **0**. All retained raw evidence and checksum manifest
are in [w2-record-values-evidence](w2-record-values-evidence/).

Reproducibility limits are unchanged: prepared SBCL 2.4.10, SHOP3 4.3.1 at the
owning flake pin, Eclector 0.11.0 and Git 2.52.0 were used. Symbol classification
uses non-evaluating metadata from that SBCL runtime. Network namespaces are
unavailable on this host; strace observes zero network calls rather than enforcing
isolation. Tags are provenance, not cryptographic authentication. Domains and
records remain trusted local inputs with explicit screening; this is not a
sandbox or an attestation of a rebuilt historical runtime.

Changed implementation paths: `welcome-development-records.lisp`, explicit
fixture key creation in `welcome-development-examples.lisp`, the optional ASDF
registration, the acceptance runner hook, and new `welcome-record-values.lisp`
tests. The historical-source screen, domain, planner and shared SHOP3/Git/FedWiki/
Defederation/authority implementations are unchanged.

No merge, deployment, project tags, S1 acquisition, agent execution or production
change. Stop for focused independent Claude Code re-review of draft PR #39.
