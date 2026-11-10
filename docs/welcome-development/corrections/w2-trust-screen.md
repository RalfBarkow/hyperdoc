# W2 trust-screen correction: D1 and D2

W2 was independently accepted at `276320e3`. The subsequent
[N1 hardening](w2-record-values.md) addresses record-derived operands;
the D1/D2 historical-source screen remains unchanged.

Reviewed baseline: `32209c16ce93ddec50e30e820fafa3a6cee54d73`, PR #39.
Date: 2026-11-10. Scope remains planning-domain replay and current validation;
no execution capability, shared SHOP3 change or second planning/domain engine.

## D1: observed failure and correction

The old source-to-domain transition lost the distinction between quoted SHOP3
terms and Lisp expression positions. The recursive name screen allowed `<` as
the function but did not validate its evaluated operands. It also omitted
`:sort-by`. The native engine then evaluated the admitted expressions.

Both independent attacks were reproduced in a detached worktree at the exact
reviewed commit. Tags were created only in an OS-allocated temporary repository.
The retained [baseline log](w2-trust-evidence/reviewed-baseline.log) records:

| Attack | Baseline observation | D1 correction |
|---|---|---|
| D: `(shop3:call < (clear-development-domain-cache) 1)` | Admitted, one private build, two cache-clear calls during native planning, cache 2 → 0, one native plan. | Refused before construction: `:non-plain-call-argument`. |
| E: `(:sort-by (clear-development-domain-cache) ((slice ?s)))` | Admitted, one private build, two cache-clear calls during native planning, cache 2 → 0, one native plan. | Refused before construction: `:sort-by-not-supported`. |

`:PLAN-ONLY` was preserved even in the baseline. This did **not** prevent the
historical Lisp side effect; the unsafe source had already crossed the screen.

The correction routes existing item fields to context checks, without expanding,
converting or executing them. Native SHOP3 remains the only domain constructor
and parser. The supported source subset preserves W1's ordinary methods,
optional branch labels, axioms, SHOP2 operators and integer costs. Predicate,
task and effect terms must be atomic. Unsupported extensions are refused.

Comparison calls are allowed only in logical conditions, with an exact
allowlisted comparison and plain SHOP3 variables or self-evaluating literals
(integer, string, keyword, NIL or T). A variable must be a W1-package variable
under the pinned engine's name rule and have no Lisp binding or special
proclamation. SBCL's non-evaluating variable-kind introspection also rejects an
unbound special with a `?` prefix. Nested operand expressions are refused.

All `:sort-by` source is refused. Task lists remain flat data without CALL or
computed networks. Effects contain flat facts or quantified effects; even the
logical bounds of quantified effects cannot contain CALL. Logical wrappers are
checked recursively. Nested predicate terms are refused so source-supplied
expression lists cannot masquerade as data and later bind a comparison operand.
This is a deliberately restricted source screen, not a general Lisp sandbox.
Current record construction and trusted planner inputs remain separate concerns.

## Evaluation-position audit of the pinned engine

Paths below are under pinned `shop3/shop3/` at `ce53f9b651acde8c44dc21eddb1a1c5b97f10536`.

| Native seam | Evaluated input | W2 boundary |
|---|---|---|
| `theorem-prover/theorem-prover.lisp:176–200` | `:sort-by` key and optional comparison expression | `:sort-by` refused throughout source, including quantified bounds. |
| `theorem-prover/theorem-prover.lisp:545–550` | `standard-satisfiers-for-call` evaluates the complete substituted argument expression | Exact comparison function; plain atomic operands; no nested calls, free symbols or Lisp specials. |
| `theorem-prover/theorem-prover.lisp:378–439,538–591` | `eval`, `assign`, `assign*`, `enforce`, `setof`, `bagof`, `:external` | Existing blanket refusals retained, including under logical wrappers. |
| `io/input.lisp:381–415`; `decls.lisp:204–220`; `planning-engine/task-reductions.lisp:335,348` | A CALL in a task network selects `simple-backquote`; its expressions are evaluated on reduction | Only flat task lists with atomic arguments; CALL and computed/quoted network extensions refused. |
| `planning-engine/task-reductions.lisp:214–246` | Quantified effect bounds invoke `find-satisfiers` | Recursively checked logical bounds with CALL disabled; flat effect facts and recursively checked quantified consequents only. |
| `io/input.lisp:506–538`; `planning-engine/task-reductions.lisp:156` | Operator cost expression | Sixth field must be an integer; fifth must be an effect list, ruling out SHOP1 cost-slot ambiguity. |
| `io/input.lisp:945–974`; native logical satisfiers | Axiom bodies and nested logical conditions | Same recursive logical-context checks as method/operator preconditions; flat ordinary predicate terms. |
| `io/input.lisp:831–860` | `:include` loads external source | Existing item-kind/include refusals retained. |

The W1 domain has no implication or arbitrary task-network extensions; local
symbols spelling such logical names do not gain native executable semantics.
No trust-screen check invokes `eval`, a historical form, a recovery restart or a
record-supplied function. Only already screened items reach native construction.

## Executed focused probes

[Probe source](../../../dreyeck/tests/welcome-domain-trust.lisp) retains the D/E
labels. Twenty tagged negatives pass in [d1-focused.log](w2-trust-evidence/d1-focused.log).
Every negative asserts zero `make-domain` calls, zero cache-clear calls, unchanged
cache entry EQ identities, public object/plist/dynamic domain, and problem
registry/current-problem pointer.

| Required path | Probe label | Result |
|---|---|---|
| Nested executable CALL operand | D | Refused; no construction or mutation. |
| Lisp special-variable operand | SPECIAL-VARIABLE | Refused; no construction or mutation. |
| `:sort-by` key expression | E | Refused; no construction or mutation. |
| `:sort-by` comparison expression | SORT-COMPARISON | Refused; no construction or mutation. |
| CALL in method task list | METHOD-TASK, METHOD-TASK-FLAT-CALL | Refused even when the comparison itself has only literal operands. |

Other cases cover a special with a SHOP3-looking name, an unbound special,
a keyword with a variable-looking name, nested CALL, free symbol, NOT/OR/FORALL
wrappers, nested predicate terms, direct/quantified effects, sorting in effect
bounds, operator preconditions and axiom bodies. The exact source from W1 commit
`61cdec068116891d8455cdff9bb7b81ef1df171a` is read locally, copied into the temporary
tag fixture, admitted, and produces both expected P0 S1 assignments with native
plan trees/final states and `:PLAN-ONLY`.

## Reproduction

Using the already prepared dependency registry and SBCL 2.4.10:

```sh
git worktree add --detach /workspace/work/w2-trust-baseline \
  32209c16ce93ddec50e30e820fafa3a6cee54d73
DEFEDERATION_REPO=/workspace/work/w2-trust-baseline \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --load /workspace/work/welcome-w2/dreyeck/tests/welcome-domain-trust.lisp \
  --eval '(dreyeck/work/welcome-development::run-domain-trust-probes t)'
```

Corrected focused command:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --eval '(asdf:load-system "dreyeck/work/welcome-development/domain-version-tests")' \
  --eval '(dreyeck/work/welcome-development::run-domain-trust-probes)'
```

The fixture strings and native item expectations are separately retained; no
host reader is used on historical text to create attack tags. OS `mktemp`
allocates a fresh repository, and `unwind-protect` removes it. Native admission
recomputes each baseline/positive version ID after actual SHOP3 expansion.

## D2: isolated refusal diagnostics

D1 is committed independently as
`36d2cd8f90ed5207a8a312ecbc0edc4b3c704208`. D2 adds one diagnostic helper and
separate [reader refusal probes](../../../dreyeck/tests/welcome-domain-reader-refusals.lisp).
Direct `invalid-development-record` refusals retain their original data instead
of collapsing to the generic reader-condition class. The helper also unwraps
Eclector's real `read-time-evaluation-error` original condition. It uses the
internal `original-condition` accessor inspected in pinned Eclector 0.11.0;
that is not a claim of compatibility with other Eclector releases. Unknown
syntax errors still report the Eclector reader-condition class. Structural
screen refusals keep a single `:domain-version-untrusted` envelope.

The reader's error/warning escape still occurs before any object is admitted.
No recovery, use-value or intern restart is invoked. A failure-injection probe
forces Eclector's read-eval state to T to reach the client-level fallback:
Eclector actually wraps the client's refusal and offers its recover restart.
The strict reader preserves `:read-time-evaluation`, returns no object and
invokes no cache-clearing function. Normal production reading still forces
read-eval NIL. [d2-focused.log](w2-trust-evidence/d2-focused.log) retains the
exact reason checks and recoverable-condition observation.

## Complete final regression run

Executed with the same prepared SBCL 2.4.10 / SHOP3 4.3.1 / Eclector 0.11.0 / Git
2.52.0 runtime, using fresh child processes, empty child HOME and a private FASL
cache seeded from the prepared local dependency cache:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
W2_SBCL=/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
W2_BOOTSTRAP=/workspace/work/defederation-bootstrap.lisp \
W2_LOGS=/workspace/work/w2-trust-final-evidence \
scripts/audit-welcome-domain-versions.sh
```

Exit status: **0**. No dependency acquisition occurred. The unchanged audit
script records the exact individual SBCL flags, source loading, `asdf:test-system`
entry points, fresh-process comparison, tag snapshots and strace commands.
Registry bootstrap paths are retained in the original
[environment-bootstrap.lisp](../w2-evidence/environment-bootstrap.lisp).

| Suite / invariant | Executed result | Evidence |
|---|---|---|
| D1 | All 20 tagged negatives refuse before construction; original W1 blob produces both expected assignments. | [acceptance.log](w2-trust-evidence/acceptance.log) |
| D2 | Exact client reasons preserved; actual wrapped Eclector error/recover restart observed without recovery, returned object or mutation. | acceptance.log; [d2-focused.log](w2-trust-evidence/d2-focused.log) |
| A1–A13 | PASS, now including the missing evaluated-argument, sorting and task/effect contexts in A7. | acceptance.log; [audit.log](w2-trust-evidence/audit.log) |
| P0–P11, P4b/P10 refusals, completion | PASS with real SHOP3 and all native alternatives. | [regressions.log](w2-trust-evidence/regressions.log) |
| F1–F5, C1–C3, record validation, first-submission positives | PASS. C1–C3 remain `:submission-not-proposed`, including later acceptance chains. | regressions.log |
| Inspector / Topicmap | PASS: retained alternative, version, record and commit EQ links, hypothetical fixture provenance, no buttons/Catalog additions. | regressions.log; acceptance.log; [fixture.log](w2-trust-evidence/fixture.log); [replay.log](w2-trust-evidence/replay.log) |
| Private domains and L1 | PASS: injected reader/screen/install/id/planner failures and partial problem construction clean up; 100 complete runs + 20 journal builds leave problem registry/current pointer unchanged. | acceptance.log; fixture.log |
| Defederation / Local-only | Both unchanged regression suites PASS. | regressions.log |
| Cross-process version/binding identity | PASS; IDs remain identical to accepted W1/W2 behavior. | [identity-1.log](w2-trust-evidence/identity-1.log); [identity-2.log](w2-trust-evidence/identity-2.log) |
| Syscalls / Git | Fixture: 0 Git exec attempts, 0 network calls. Replay: only `cat-file`, `rev-parse`, `show`, 0 network calls; socket positive control detected. | audit.log; [fixture.strace](w2-trust-evidence/fixture.strace); [replay.strace](w2-trust-evidence/replay.strace); trace-control.strace |
| Tags | Temporary replay tag refs unchanged. Project tag refs also unchanged before/after the entire run. No project tags created. | tags-before.txt; tags-after.txt; project-tags-before.txt; project-tags-after.txt |
| Plan-only / boundaries | All returned planning results remain `:PLAN-ONLY`; no alternative selected/executed, no shared SHOP3, Git, Defederation, FedWiki, authority or fork implementation changes. | native-result assertions and source diff |

The raw logs, traces and checksum manifest are retained in
[w2-trust-evidence](w2-trust-evidence/). The focused D1 log deliberately retains
its pre-D2 diagnostic shape; the final acceptance log contains the flattened D2
reasons. The previous W2 A7 vectors passed but were incomplete; the independently
reproduced D/E attacks establish why that earlier PASS was insufficient.

Runtime limitations remain: network namespace creation is unavailable on this
host; strace observes zero network calls rather than enforcing network isolation.
The reader screen is defence in depth for trusted source and current accepted
records, not a sandbox. A Git tag is not cryptographic authentication and tag
signatures remain unverified. The planning domain is versioned; current record
validation and source-screen behavior are not historically replayed. Tests do
not assert a historically rebuilt or authenticated runtime.

Changed implementation/test paths since the reviewed commit:

- `dreyeck/work/welcome-development-domain-versions.lisp`
- `dreyeck/tests/welcome-domain-versions.lisp`
- `dreyeck/tests/welcome-domain-trust.lisp`
- `dreyeck/tests/welcome-domain-reader-refusals.lisp`
- `dreyeck.asd`

Documentation adds this report and its evidence and marks the original W2 report
as superseded for A7. The Inspector entry point remains
`(inspect (dreyeck/work/welcome-development:welcome-development-demo :p4))`
after loading the optional ASDF system.

No merge, deployment, service restart, S1 acquisition or agent execution. Stop
for focused independent Claude Code re-review of draft PR #39.
