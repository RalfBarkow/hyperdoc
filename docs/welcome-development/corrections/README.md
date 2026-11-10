# PR #38 corrections after independent review

Reviewed commit: `dccfd23c0d3f56a5e2ab79f801ea0a25808d85b3`.
Branch: `codex/11570-w1-welcome-development`. Scope remains W1 only.
The original domain form, shared classifier/normalizer, handoff documents and
FedWiki runtime/domain are unchanged.

| Finding | Resolution |
| --- | --- |
| F1 | Every assignment is checked against all real SHOP3 `(advance-welcome)` alternatives from its validated record prefix, including the proposed base. Wrong S2 bases, premature slices and additional open assignments are refused. |
| F2 | Source bindings use deterministic SHA-256 over provenance, the literal domain, canonical sorted facts, tasks, `:which :all` and the complete sorted alternative multiset. Digest, chosen step, stable alternative ID and retained inputs must match. Fixtures obtain real bindings from `assignment-proposal-binding`. |
| F3 | Every review must match a submission for that assignment and commit. Positive reviews additionally require an already validated successful verification. Unclaimed reviews and positive reviews without/after failed verification are refused. |
| F4 (optional) | `development-run` retains its alternatives; repeated Inspector views and Topicmap projections share the same objects by EQ. Prefix-validation audit objects are retained and linked too. |
| F5 | The main README states Git >= 2.44, explains the existing `--no-lazy-fetch` dependency and distinguishes an unsupported runtime from a W1 implementation defect. Git 2.52.0 was used here; no fallback drops the flag. |

## Explicit validation procedure

`development-state` treats records as an ordered journal. For every new record
it validates/projects the current prefix. Before adding an assignment it calls
the state-only native planner on the preceding valid state, checks membership
of the selected `!assign` action, and verifies the complete binding. Neither
later records nor the assignment itself can authorize that action.

The call graph is deliberately acyclic:

* The record-content projector does not plan or call `development-state`.
* `development-state` calls the projector and state-only planner, then validates
  the binding with pure canonicalization/hashing helpers.
* The public `assignment-proposal-binding` first validates its earlier journal,
  then returns a new real proposal binding. It is not called by history replay.

The second return value of `development-state`, also retained in the run's
`development-assignment-validations`, exposes the original assignment, prior
records/state, native plan result and binding. The Inspector and Topicmap link
these objects. All planning results, including prefix searches, are plan-only.

The digest excludes problem gensyms, timing, trees, state objects, object
identities and enumeration indices. It uses standard readable literal Lisp
serialization under a fixed package; unsupported objects/uninterned symbols
are refused. The complete native result still preserves every alternative in
SHOP3's order. A chosen action is identified by its content hash and exact step,
not its position in that order.

## Negative reproductions and changed fixture expectations

Claude's original B1–B5 labels are authoritative. The independently retained
Codex script and logs use a different ordering for B2–B4; the table below makes
that correspondence explicit. The difference is in labels, not failure
conditions. Historical script, test names and log labels remain unchanged so
the retained evidence can be reconciled without rewriting executed results.

The user reports that Claude's original script was retained at
`/tmp/claude-0/-home-user/ba97d797-59fc-5816-9510-72426787f5b2/scratchpad/w1/review-probes.lisp`,
with related `probes.log`, `full.log` and `full.strace`. These files were not
attached or committed; their availability outside Claude's temporary environment
is not established. They were not read or reproduced verbatim here.

`reviewed-negatives.lisp` ran against an isolated checkout of **the exact
reviewed commit**. All five invalid inputs were admitted before correction,
as recorded in [reviewed-negatives.log](reviewed-negatives.log):

| Original Claude label | Retained Codex label | Invalid record | Reviewed commit | Corrected branch |
| --- | --- | --- | --- | --- |
| B1 | B1 (`FORGED-DIGEST`) | Forged `:source-plan` digest | admitted | `:assignment-plan-binding-mismatch` |
| B2 | B3 (`PREMATURE-S3`) | Premature S3 assignment while S1 has not been assigned | admitted | `:assignment-not-proposed` |
| B3 | B4 (`OPEN-ASSIGNMENT`) | Concurrent second S1 assignment while the first is open | admitted | `:assignment-not-proposed` |
| B4 | B2 (`WRONG-S2-BASE`) | S2 based on a commit different from S1's accepted commit | admitted | `:assignment-not-proposed` |
| B5 | B5 (`UNCLAIMED-REVIEW`) | Review accepting a commit that was never submitted | admitted | `:review-without-submission` |

These independent reproductions demonstrate admission at `dccfd23c` and refusal
at correction commit `d367625a`. This label reconciliation is documentation
only; it changes neither the implementation nor the executed evidence, and
does not claim a new test run. PR #38 remains a draft pending Claude Code's
second independent review.

Additional negatives cover positive reviews without a matching successful
verification, future evidence placed after an assignment, and stale bindings
after policy changes even when the offered assignments happen to be unchanged.

The original scenarios P4b and P10 intentionally supplied invalid records.
Under the requested corrections P4b is now refused for an unsubmitted review,
and P10 is refused for a premature S2 assignment. They are still executed as
negative cases, rather than silently admitted. All other P0–P11 cases retain
their plan sets. P4 continues to show both S1 integration and S2 assignment;
completion is still a distinct `!report-complete` report. The older
cross-assignment self-review negative is now rejected earlier, because its
second assignment was never proposed while the first was open.

## Executed commands and results

All runs used fresh SBCL 2.4.10 processes, pinned real SHOP3
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536` (4.3.1), Git 2.52.0 and the existing
portable dependencies. No dependency acquisition or installation was needed.

Baseline reproduction, **exit 0** (observational script; its output demonstrates
the defects, not successful validation of those inputs):

```sh
DEFEDERATION_REPO=/workspace/work/welcome-review-baseline \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --load /workspace/work/reproduce-welcome-reviewed-negatives.lisp
```

Corrected combined run, **exit 0**:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-development \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --load scripts/test-welcome-development.lisp
```

The runner executes W1 (P0–P11, completion, all previous and added negative
cases, package qualification, plan trees, reference/identity checks), then the
existing defederation and Local-only ASDF suites. It verifies unchanged Catalog
membership. [tests.log](tests.log) retains the full output; log copies have only
trailing whitespace trimmed. [tested-source.json](tested-source.json) binds the
results to source/log hashes and records both exit codes.

A separate fresh focused run and the final combined run produced the same
binding digest and stable choice ID:

```text
digest: 3cd65ad15908d07ec47caa8364a21327949e4b4fea7bc2d9540527d7b8e574c9
choice: 78506902f42c56e7ffc5aa553ca4dea0c706afe506a8cd9b65aadb7c3a08045b
```

The focused test additionally reverses facts and plan enumeration, changes
gensym problem names/timing/printer settings, and checks identical bindings.
No second HTN engine or semantic approximation is used.

For the standard prepared project environment, reproduce with:

```sh
nix develop -c sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-welcome-development.lisp
```

This Cloud run does not claim a build of the full current flake closure.
The portable environment's Iterate package remains `release-b0f9a9c6`.
Interactive CLOG, the user's live SLY image, macOS, network namespace isolation
and whole-process syscall tracing remain untested. Source/verification/review
scenario records remain visibly fixtures. The real remote integration observer
remains missing and observed integration is refused.

The existing read-only Inspector entry point remains
`(clog-moldable-inspector:clog-inspect :object (dreyeck/work/welcome-development:welcome-development-demo :p4))`
after loading the owning system and Inspector. No Wiki writes, agent dispatch,
S1 acquisition, fork executor, production changes, merge or deployment was
added. Stop for a second independent Claude Code review.
