# Third W1 correction: submissions must be proposed by SHOP3

Reviewed parent: `ee05cddcbe0d5ba0db33494fee808946016a6e34`.
Branch: `codex/11570-w1-welcome-development`, PR #38 (draft).

Before adding each `dev-submission`, `development-state` runs the existing
state-only `(advance-welcome)` planner on the validated preceding record state.
It requires the exact `(!await-submission slice assignment executor)` step
among **all** native alternatives. If absent, it raises
`:submission-not-proposed` before appending/projecting the submission.

This is a small extension to the existing ordered replay, without a domain
change, second planner, recursive `development-state` call, action selection or
execution. Assignment proposal/digest checks and review/verification checks
remain in place. Planned effects and later records cannot authorize an earlier
claim. A retry needs a new assignment actually proposed by SHOP3, within the
existing attempt limit; this does not introduce versioned submissions/history.

## Executed counterexamples

The retained [reviewed-probes.lisp](reviewed-probes.lisp) ran on an isolated
checkout of the exact reviewed parent. It appends a distinct-ID fixture claim
for `c9`, followed by positive fixture verification/review records, and asserts
that real SHOP3 then proposes an S2 assignment based on `c9`. For C1 it also
checks the original accepted `c1` route; for C3 it verifies that the original
prefix had only the attempts-exhausted blocker. These were actual planner runs,
not observations inferred from source.

| Case | Reviewed parent | Corrected branch |
| --- | --- | --- |
| C1: accepted `a1/c1` receives another claim `c9` | admitted; both accepted S1 commits offer S2 bases | `:submission-not-proposed` |
| C2: failed/closed `a1` receives another claim | admitted; `c9` acceptance bypasses failure | `:submission-not-proposed` |
| C3: two attempts exhausted, claim to first closed assignment | admitted; `c9` acceptance bypasses blocker | `:submission-not-proposed` |
| C3: two attempts exhausted, claim to second closed assignment | admitted; `c9` acceptance bypasses blocker | `:submission-not-proposed` |

The corrected tests check every case with the extra claim alone **and** with
the later acceptance chain. Distinct record IDs ensure rejection is due to
planner admissibility rather than the duplicate-ID guard. A further negative
rejects another claim while the first is awaiting verification. Exact-step
negatives independently change slice, assignment ID and executor.

The positive test admits an open assignment's first claim, after which SHOP3
proposes `!verify-submission`. A second positive test checks a valid S2 claim
when `!await-submission` coexists with an S1 integration proposal: membership
uses the entire alternative set. All run results retain `:plan-only`, native
trees/final states, and explicit fixture provenance. Rejected inputs leave the
previous record-derived state unchanged.

## Commands and results

Baseline reproduction, exit **0** (the assertions demonstrate the defect):

```sh
DEFEDERATION_REPO=/workspace/work/welcome-submission-baseline \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --load /workspace/work/reproduce-welcome-submission-negatives.lisp
```

Corrected combined run, exit **0**:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-development \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --load scripts/test-welcome-development.lisp
```

[reviewed-probes.log](reviewed-probes.log) and [tests.log](tests.log) retain the
captured output, with only trailing whitespace trimmed. Source/log hashes,
reviewed parent, environment and exit codes are recorded in
[tested-source.json](tested-source.json). The earlier F1–F5 evidence and original
Claude B1–B5 label mapping are preserved unchanged in the parent directory.

The combined runner passed P0–P11 (including the existing P4b/P10 refusals),
completion, all F1–F5 negative and record-validation tests, Inspector/Topicmap
identity checks, C1–C3/positive submission tests, unchanged Catalog membership,
and the existing Defederation and Local-only suites. The domain form, shared
classifier/normalizer, handoff documents and FedWiki implementations are
unchanged.

This used real pinned SHOP3 `ce53f9b651acde8c44dc21eddb1a1c5b97f10536` (4.3.1),
SBCL 2.4.10, Git 2.52.0 and the existing Linux portable dependency environment.
No dependencies were acquired. The prior limits remain: this is not a full
current-flake build, interactive CLOG/live SLY/macOS validation or whole-process
network syscall audit. Scenario claims and verification/review records are
explicit fixtures, not actual S1 implementation or test-producer evidence.

No source acquisition, test producer, S1, agent dispatch, fork execution,
production change, merge or deployment was added. Stop for a focused independent
Claude Code re-review; PR #38 remains a draft.
