# Planning Remote Control for the Zettelkasten App with SHOP3

## Scope and provenance

Assignment 1, Zettel 11551 (title and architecture goal supplied by the user;
no productive ZKN3 file was opened). Only HyperDoc source/tests/reading change.
No Application API, agent/MCP client, transport, mobile UI or executor is implemented.
No environment configuration, project WBS, AC-06 artifact, acceptance record,
productive Catalog, Syncthing configuration or application data is changed.
The project-plan/WBS proposals of 5 November 2026 remain drafts.

Observed checkouts on 5 November 2026, all on local branch `work`:

| Repository | HEAD |
| --- | --- |
| hyperdoc | `a33fa97a5ae3138b814151745228b1e4f5d1ebb8` |
| Zettelkasten | `030df373a2e49d9cdc450d32c2a379c20aa96b9d` |
| ZettelkastenFX | `d841883782cf38c1bc8da6405b83f4bfa35385a2` |

The reviewed slice is based on that HyperDoc commit; the review revision is the
commit containing this report (identify with `git rev-parse HEAD`). SHOP3 source is exactly
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536`, from HyperDoc's flake.lock.

Inspected existing routines: `dreyeck/shop3/{package,plan-objects,examples,views}.lisp`,
`dreyeck/work/planning.lisp`, `dreyeck/tests/work-planning.lisp`, both named
Planning/Collaborative Planning HTML readings and their ASDF definitions.
The prior documentation experiment's verdict B is unchanged: one fixed sequence.
The collaborative-planning reading is a provenance case, not an authorization
or an independent SHOP3 assessment.

Read-only FX evidence: `docs/plans/zettelkasten-model-first-refactor.sexp`
is a plan artifact (including historical validation statements, not current
runtime evidence); `CoreBoundaryTest` excludes Swing/AWT/JavaFX/storage/UI imports.
SQLite adapters implement Note/Keyword/Link/Sequence repository ports;
`Zkn3SourceReader` returns `Zkn3ImportBatch`, and `Zkn3DomSourceReader` implements
it. Its package-info still describes an earlier scaffold: that comment does not
negate the present implementation. These ports do not establish the availability
of a UI-independent remote Application API. API, authorization, session and
transport availability below are new hypothetical inputs, not observed services.

## Domain and inspectable artifacts

`(enable-mobile-control zettelkasten macbook-a android)` has two separate HTN
method definitions. Agent requires an agent session; Direct requires a direct
transport. Both require the Application API, hypothetical authorization, local
execution authority and local model authority. They decompose into:

- Agent: `!model-agent-route`, `!model-control-surface … agent`,
  `!verify-modeled-control … agent`.
- Direct: `!model-direct-route`, `!model-control-surface … direct`,
  `!verify-modeled-control … direct`.

All operators only add simulated facts. They contain no external effects or
execution hooks. Both retain execution/model authority on macbook-a. The modeled
`mobile-control-verified` predicate proves only a domain-state condition, never
a real end-to-end test. Planning inputs never grant real access.

`remote-control-plan` returns the existing `hyperdoc-htn-plan-result`, always
`:execution-mode :plan-only`, with all four FIND-PLANS values retained.
`:which :all` enumerates both applicable method definitions. `raw-plans = NIL`
is failure; a list containing an empty plan would be a successful empty plan.
`remote-control-experiment` supplies an inspectable context plist with the actual
SHOP3 problem/domain/method objects, initial facts, existing result and limits;
it is not another plan representation. The generic source-edit checklist is unused.

Representation finding: recursive `shop3:find-plans` builds native S-expression
plan trees via `extract-trees` in `shop3.lisp`; `plan-tree:plan-tree->sexp` has
methods for the explicit-stack planner's CLOS tree nodes. Passing a recursive
planner tree to the existing `plan-tree->safe-sexp` returns a conversion-failed
marker. This slice does not change that existing helper: it keeps native trees
and asserts their root task and method labels directly. Callers must distinguish
these two tree representations before selecting a converter.

## Observed tests

Cloud fixture processes, SBCL 2.5.2, 5 November 2026. No SLY image was evaluated
or inspected by Codex. Tests were executed, not merely compiled or skipped.

| Case | API | Agent | Direct | Authorization | Observed plans / trees / final states |
| --- | --- | --- | --- | --- | --- |
| A | yes | yes | no | yes | 1 / 1 / 1, Agent |
| B | yes | no | yes | yes | 1 / 1 / 1, Direct |
| C | yes | yes | yes | yes | 2 / 2 / 2, distinct Agent and Direct |
| D | yes | yes | yes | absent | 0 / 0 / 0 |
| E | absent | yes | yes | yes | 0 / 0 / 0 |

All five passed assertions on counts, distinctness, route-specific operators,
plan-tree root/method, final modeled verification, initial-fact preservation,
and both authority invariants. The context/result entrypoint passed too.
No test in these runs was skipped. No assertion tests real security or remote control.

Actual commands (dependencies prepared outside the project):

```sh
XDG_CACHE_HOME=/workspace/tooling/lisp-cache \
SBCL_HOME=/workspace/tooling/lisp/usr/lib/sbcl \
/workspace/tooling/lisp/usr/bin/sbcl --no-userinit --non-interactive \
  --load /workspace/tooling/remote-control-asdf-tests.lisp
```

Exit 0. It loads the real SHOP3 system, the repository ASDF definitions, runs
`asdf:test-system "dreyeck/work/remote-control-planning/tests"`, loads the optional
reading and asserts its registration through `hyperbook:find-hyperbook`.
Evidence: `/workspace/tooling/remote-control-asdf.log`.

A separate component run (`/workspace/tooling/shop3-component-tests.lisp`, same
SBCL/environment) loads the repository's exact SHOP3 package/result source,
new experiment/tests, and unchanged `work/planning.lisp` plus
`tests/work-planning.lisp`, then calls `check-plan`. Exit 0; marker
`DOCUMENTATION-PLAN-PASS`: eight modeled stages and missing-source refusal.
Evidence: `/workspace/tooling/shop3-tests.log`.

The complete old `asdf:test-system "dreyeck/work/planning/tests"` invocation
was attempted but blocked before execution by missing `HTML-INSPECTOR-VIEWS`,
required by `hyperbook/explorer` through Work reading dependencies. This is
not a passing full ASDF regression run. Its actual planning assertions passed
in the component run above. Blocked evidence:
`/workspace/tooling/remote-control-asdf-blocked.log`.

SBCL was extracted locally from a signed Debian index; base Alexandria, Iterate,
FiveAM, ASDF-FLV, trivial-backtrace and PURI came from Debian packages.
SHOP3's GitHub dependencies use flake.lock commits. Additional HyperDoc base
sources: arrow-macros `16bdfd31298182099c7d70df4598104e5a38b05e`,
trivial-package-local-nicknames `89141d409a75dc72db968204a3bf5de836dd66cc`.
This is an isolated Cloud test setup, not validation of the entire Nix closure.

## Reproduce in the project's SLY environment

Use the existing checkout and registered ASDF sources; do not load the broad
project or replace a coherent live image. Evaluate separately, in order:

```lisp
(asdf:load-system "dreyeck/work/remote-control-planning/reading")
(asdf:test-system "dreyeck/work/remote-control-planning/tests")
(asdf:test-system "dreyeck/work/planning/tests")
```

If the inspector is not already present, load only its owning system:

```lisp
(unless (find-package "CLOG-MOLDABLE-INSPECTOR")
  (asdf:load-system "clog-moldable-inspector"))
```

Then inspect the context and follow its `:result` slot:

```lisp
(defparameter *remote-control-experiment*
  (dreyeck/work/remote-control-planning:remote-control-experiment :c))
(clog-moldable-inspector:clog-inspect :object *remote-control-experiment*)
```

Expected: actual problem and methods, two distinct three-step plans, two native
plan trees and simulated final states, local authority facts and `:plan-only`.
Return test markers, any condition/backtrace, and observed Inspector slots and
navigation. This is the remaining live review, not an automatic human acceptance.

The optional reading registers under id `dreyeck/work/remote-control-planning`,
with the same title as this document. It is absent from normal Catalog startup.
Catalog registration is tested; browser page materialization and Inspector
navigation are not yet tested. The Cloud lacks Nix and the inspector dependency
closure. A request to the lockfile's source
`https://codeberg.org/khinsen/clog-moldable-inspector.git` was explicitly refused
by the Cloud proxy (CONNECT HTTP 403); Codeberg is outside the current allowlist.
No network policy was changed or bypassed. Cloud Inspector validation would
require Codeberg access and its dependency closure, or the SLY review above.

## Assessment and remaining acceptance

**C — the overall experiment is not yet fully accepted.** The observed conditional
selection, exhaustive enumeration of both methods and refusal of missing
prerequisites demonstrate a bounded addition over the previous fixed sequence.
They do not show discovery of new methods, optimality, repair or architectural
superiority over a handwritten conditional selector. Inspector/browser acceptance
and the complete old ASDF regression remain outstanding, so an unqualified A
or a claim that all acceptance criteria are complete would overstate the evidence.

Process: source localization → reuse existing result → pure-state domain → A–E
execution → optional reading/Catalog registration → documented Inspector blocker.
HyperDoc delta: one separate optional reading. Lisp delta: domain, five fixtures,
runner/context, tests and ASDF systems. FedWiki delta: none. Disk reload: fresh
ASDF load/tests passed; SLY reload and human acceptance pending. Versioning is authorized by the follow-up
Review, Commit & Local Inspector Handoff assignment.

Changed/new project files:

- `dreyeck.asd` (three optional systems only).
- `dreyeck/work/remote-control-planning.lisp` (domain, fixtures and entrypoints).
- `dreyeck/work/remote-control-reading.lisp` (optional Catalog registration).
- `dreyeck/tests/remote-control-planning.lisp` (A–E and context assertions).
- `dreyeck/pages/remote-control-planning/Planning Remote Control for the Zettelkasten App with SHOP3.html`.
- `docs/remote-control-planning.md` (this report).

## Review and local Inspector handoff

The reviewed diff is limited to the six files listed above. Existing
`dreyeck/work/planning.lisp`, `dreyeck/tests/work-planning.lisp`, all Java
repositories, WBS/AC-06 artifacts and authorization rules are unchanged.
The only review correction strengthens the existing tests: raw-plan/tree/state
counts agree; trees are distinct; each tree method and first operator match its
route. There is no new use case or execution mechanism.

GitHub's advertised default/target branch is `dreyeck.ch`, at the recorded base
commit at review time. `main` is a separate branch and is not the PR target.
Review branch: `codex/zettelkasten-remote-control-shop3`.

To obtain the review locally, first preserve any existing local work and verify
that origin identifies RalfBarkow/hyperdoc. Then fetch and switch to the review
branch using your usual Git workflow. Do not reset an existing local branch.
No SSH, running-image changes or service restart is part of this handoff.
If a Git push is unavailable, the accompanying Git bundle can be verified with
`git bundle verify <bundle-path>` and fetched locally with
`git fetch <bundle-path> refs/heads/codex/zettelkasten-remote-control-shop3:refs/remotes/review/zettelkasten-remote-control-shop3`.
The bundle retains the base commit and review commit without requiring a push.

Prerequisites for the human-run SLY acceptance: local checkout contains this
revision; ASDF resolves that checkout and the already prepared SHOP3/HyperDoc
and Inspector dependencies; use the intended coherent development image, not
a productive image. Confirm ASDF resolution before loading:

```lisp
(asdf:system-source-directory "dreyeck/work/remote-control-planning/reading")
```

If ASDF was already initialized before the source update, reread the definition
from the registered project's location (only when necessary):

```lisp
(asdf:load-asd (asdf:system-relative-pathname "dreyeck" "dreyeck.asd"))
```

Then use the separate forms in the SLY section above. If the subsystem was
already loaded and its disk source changed, explicitly reload its owning system:

```lisp
(asdf:load-system "dreyeck/work/remote-control-planning" :force t)
```

For each other case, replace `:a` with `:b`, `:d` or `:e` and evaluate:

```lisp
(defparameter *remote-control-case*
  (dreyeck/work/remote-control-planning:remote-control-experiment :a))
(clog-moldable-inspector:clog-inspect :object *remote-control-case*)
```

A: one Agent plan; B: one Direct plan. D: `:no-plan` because authorization is
absent. E: `:no-plan` because the Application API is absent. D/E retain
inspectable hypothetical initial states and problem/method descriptions;
their result objects have no plans, trees or final states. All cases remain
`:plan-only`. In C, inspect both trees and both final states individually; each
must retain local execution/model authority and use its own route label.
Record actual test outputs, Inspector navigation and any condition/backtrace.
No local Inspector acceptance is claimed by this document.

Review rerun: both commands below exited 0, with A–E counts 1/1/2/0/0,
matching trees/states, `OPTIONAL-READING-LOADED`, `LOCAL-CATALOG-REGISTERED`,
and unchanged `DOCUMENTATION-PLAN-PASS`. No tests were skipped in these runs.

```sh
XDG_CACHE_HOME=/workspace/tooling/lisp-cache \
SBCL_HOME=/workspace/tooling/lisp/usr/lib/sbcl \
/workspace/tooling/lisp/usr/bin/sbcl --no-userinit --non-interactive \
  --load /workspace/tooling/remote-control-asdf-tests.lisp

XDG_CACHE_HOME=/workspace/tooling/lisp-cache \
SBCL_HOME=/workspace/tooling/lisp/usr/lib/sbcl \
/workspace/tooling/lisp/usr/bin/sbcl --no-userinit --non-interactive \
  --load /workspace/tooling/shop3-component-tests.lisp
```

Captured review output: `/workspace/tooling/remote-control-review-asdf.log`
and `/workspace/tooling/remote-control-review-components.log`.
A renewed full old ASDF regression attempt exited 1 before executing its tests:
`HTML-INSPECTOR-VIEWS` remains missing. Output:
`/workspace/tooling/remote-control-review-full-regression.log`. No dependency or
network-policy changes were made during this review. Inspector acceptance is
still unperformed; verdict C remains. The existing GitHub CLI API request
`gh api repos/RalfBarkow/hyperdoc` returned `Forbidden`; Git push is a separate
capability and is reported in the handoff rather than inferred from API access.
