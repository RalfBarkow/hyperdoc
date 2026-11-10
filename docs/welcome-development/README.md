# W1: Welcome development, proposals from accepted records

Implements only W1 from [Claude's revised design](claude-revised-design.md) and
the [approved handoff](codex-w1-handoff.md). Both documents remain unchanged.
Before implementation, remote `dreyeck.ch` was verified as
`99dbe5599dc6c0b080bec1b743dd864aa5635e0b`, and the handoff branch as
`20ad13e650cd1aca0c40192080e724b3cb4e0304`. Implementation branch:
`codex/11570-w1-welcome-development`, based on the handoff commit.

## Implemented

The optional `dreyeck/work/welcome-development` system contains the supplied
`welcome-development` domain and compound `(advance-welcome)` task, small
development record classes, record validation/state construction, a local
next-action interpretation, an Inspector view and a native Topicmap projection.
There is no default Catalog registration or action runner.

Every search uses `:which :all :plan-tree t :collect-state t`. Each alternative
has exactly one step. `welcome-development-plan` returns the existing
`dreyeck/shop3:hyperdoc-htn-plan-result`, preserving raw plans, shorter plans,
native trees, final states, elapsed time and `:plan-only`.
`development-workflow` retains that same result with its records and initial
state. The shared step classifier and normalizer are unchanged and unused.

The design domain is retained, with two small additions: `all-integrated` /
`!report-complete`, and anonymous operator arguments for the effect-free
`!await-submission` to avoid singleton warnings. Completion requires accepted
(verified and reviewed for the same commit) and integrated evidence for all four
slices. A partial integration state still proposes integration.

`development-next-action-view` exposes **every** alternative with its index,
step, classification, native tree and final state. It never selects a first
plan. Classifications are:

| Operators | Interpretation |
| --- | --- |
| `!assign`, `!verify-submission`, `!request-review`, `!propose-integration` | `:actionable` proposal, still unexecuted |
| `!await-submission` | `:awaiting` |
| `!report-blocker` | `:blocked`, not an assignment |
| `!report-complete` | `:complete`, not another task to execute |

The overall display prioritizes actionable, awaiting, blocked, complete when
alternatives differ; all individual classifications remain visible. No plans
means blocked. This aggregate does not choose an alternative.

## Records and evidence

`make-development-record` retains a typed record with an explicit `:fixture` or
`:observed` source, an ID and inspectable property data. `development-state`
validates the whole supplied record set before producing facts. It accepts
policy, assignment, submission, verification, review and integration records,
including typed record values carried by workspace-operation invocations.

* Assignments retain base, executor, branch, allowed paths, required tests and
  markers, forbidden actions and source plan digest/step. Attempts are counted
  from distinct assignment records, not supplied counter facts.
* Submissions produce claims only. Free text has no planning authority.
* Verification requires a distinct named verifier, explicit independence,
  commit/base/tree identity, ancestry, full base-to-commit changed-file scope,
  required test records, zero exits, passed verdicts, required markers, log
  digests, and test commit/tree bindings. Missing platform, network-isolation or
  syscall-trace metadata is refused. Environment limits are retained.
* Reviews retain reviewer, commit, decision, findings and review digest. The
  reviewer must be permitted and different from the implementer, including
  other assignments claiming that same slice/commit.
* Opposite verification/review decisions are refused for the same assignment
  and commit, and also across assignments for the same slice/commit, because
  SHOP3 joins on that coordinate. Duplicate IDs and duplicate property keys
  are refused. Mixed fixture/observed runs are refused.

`:returned` is transport status, never verification success. A returned rejected
record remains rejected; a checker error (`:failed`) or an untyped returned
value contributes no verification fact. The planner therefore requests another
verification. The existing evaluation-record protocol exposes the actual
invocation and record values; Topicmap and Inspector references retain the
original objects.

The local read-only adapter `observe-local-development-repository` uses an
**explicitly supplied** `dreyeck/git:git-repository-checkout`. It reads exact
commits, ancestry, tree and the full base..commit path set (with rename detection
disabled, so old/deleted paths also require permission). It does not use the
memoized checkout or a previous worktree. The existing Git runner disables
implicit promisor fetching. W1 path globs mean exact relative paths or trailing
`*` prefixes, including directory prefixes; no shell glob/evaluator is used.

For `:observed` verification, repository evidence is re-read and compared, and
test log SHA-256 and marker presence are checked against retained files. Test
exit codes/commands and their commit/tree/observer bindings must come from a
trusted independent local test producer. **W1 does not execute those commands
or authenticate observer identities.** These are cooperative in-image records,
not an ingestion API for agent-supplied verification claims. The read-only Git
adapter alone is not a complete independent test-observer service.

There is still **no shared remote `dreyeck.ch` head observer**. W1 refuses all
`:observed` integration records with `:remote-integration-observer-unavailable`;
it does not substitute local HEAD for remote integration evidence. A future
observer must establish the remote head and ancestry independently. Only
explicit fixture integration records currently demonstrate the completion path.

Replanning reconstructs state solely from records. Passing a plan, raw facts or
a previous simulated final state is refused. P2b's `planned-*` injection is
refused rather than silently promoted or reused. No simulated effect counts as
a verified slice, review, assignment or integration record.

## Reproduce and inspect

From the prepared project environment, with this Git review branch/history:

```sh
nix develop -c sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-welcome-development.lisp
```

The script runs the W1 suite and the existing defederation and Local-only suites.
The local Git adapter tests need the handoff commits and the historical rename
`ee888de1` / its parent `e2dcf884` available in this explicit checkout; they never
fetch missing objects.

In a coherent SLY image, evaluate these blocks separately. Purpose: inspect both
P4 alternatives while retaining the native result and original record links.

```lisp
(asdf:load-system "dreyeck/work/welcome-development")
(asdf:test-system "dreyeck/work/welcome-development/tests")
```

```lisp
(defparameter *welcome-development*
  (dreyeck/work/welcome-development:welcome-development-demo :p4))
(dreyeck/work/welcome-development:development-next-action-view
 *welcome-development*)
(inspect *welcome-development*)
```

With the Inspector already loaded, the read-only entry point is:

```lisp
(clog-moldable-inspector:clog-inspect :object *welcome-development*)
```

Use the **Development next actions** view. Expected: two alternatives, both
`:actionable`, namely `!propose-integration S1` and `!assign S2 CODEX` using the
same fixture commit; native result/tree/state and record/Topicmap links; no
execution buttons. If live confirmation is wanted, return these printed choices
and any condition/Inspector findings. These Cloud tests do not confirm a SLY
image or an interactive CLOG session.

The first-assignment and mere-claim examples are also independently inspectable:

```lisp
(defparameter *welcome-initial*
  (dreyeck/work/welcome-development:welcome-development-demo :p0))
(defparameter *welcome-claim-only*
  (dreyeck/work/welcome-development:welcome-development-demo :p2))
(mapcar #'dreyeck/work/welcome-development:development-next-action-view
        (list *welcome-initial* *welcome-claim-only*))
(inspect *welcome-claim-only*)
```

P0 contains `(!assign S1 CODEX <base>)` and
`(!assign S1 CLAUDE-CODE <base>)`. P2 contains only
`(!verify-submission S1 :A1 <claimed-commit>)`; no S2 progress. All objects here
are explicitly `:fixture`; none claims S1 was implemented or verified.

After a source update, reload only the owning system with
`(asdf:load-system "dreyeck/work/welcome-development" :force t)` and recreate
the run from records. Do not feed its modeled final states into another cycle.

## Executed results, 10 November 2026

Pinned SHOP3 `ce53f9b651acde8c44dc21eddb1a1c5b97f10536`, version 4.3.1,
SBCL 2.4.10 on Linux. These are fresh executed observations, not the design's
claimed executions.

| Scenario | Observed alternatives | Workflow classification |
| --- | --- | --- |
| P0 | 2 S1 assignments | actionable |
| P1 | await S1 submission | awaiting |
| P2 | verify S1 claim, no S2 | actionable |
| P3 | request independent S1 review | actionable |
| P4 | propose S1 integration **and** assign S2 | actionable |
| P4b | mismatched review commit; request S1 review | actionable |
| P5 | assign S2 | actionable |
| P6 | assign S1 to untried Claude Code | actionable |
| P7 | attempts exhausted | blocked |
| P8 | no alternative S2 executor | blocked |
| P9 | no eligible independent reviewer | blocked |
| P10 | verify S1 only, ignoring out-of-order S2 claim | actionable |
| P11 | propose S1 integration, propose S2 integration, assign S3 | actionable |
| all four accepted/integrated | report complete | complete |

All these searches returned equal plan/tree/final-state counts, one-step plans
and `:plan-only`. Additional checks cover P2b injection/replanning, contradictions,
invalid evidence, review rejection/reassignment, carrier status versus verdict,
fixture laundering, missing remote observer, incomplete integration and exact
Inspector/Topicmap record links. The qualification probes show one plan for
qualified `shop3:call`/`shop3:forall`, zero for a failing universal condition,
and zero for each unqualified version. The optional load/test adds no Catalog
member. The retained defederation and Local-only suites pass.

Scenario slice/verification/review/integration records are **synthetic**.
The planner, record validation, view rendering, object references and local Git
adapter checks actually ran. The Git adapter separately observed the real
handoff commit/tree and its two changed documentation paths, then rejected those
paths under an unrelated scope. This is not evidence of an actual S1–S4 slice.

Actual final command and full output: [evidence/run.md](evidence/run.md),
[evidence/tests.log](evidence/tests.log). The tested source hashes are in
[evidence/tested-source.json](evidence/tested-source.json). No dependency was
downloaded for W1. The available portable dependency set was reused; this does
not validate the entire current Nix closure. Network namespace isolation and
whole-process syscall tracing were not performed; the Local-only suite reports
its own Lisp-level guards. macOS and interactive CLOG are untested here.

No S1 acquisition, S2 site/evidence artifact, S3 writer/authorization, S4
investigation, Wiki write, agent launch, Git integration, server change or
deployment was implemented or executed. No HyperDoc page or FedWiki content
delta. Independent Claude Code (Opus, High Effort, read-only) review is pending.
