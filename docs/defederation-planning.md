# Defederation preparation with SHOP3, slice 1

Zettel 11560, building on Zettel 11483. This implements the task's account of
Ward's proposal as a small planning fixture. It does not establish additional
historical claims about Ward or the CCNx prototypes. The existing
[Zettel 11483 source report](ccnx-federated-wiki/SOURCE-REPORT.md) retains its
separate source-review scope and open questions.

Base verified before work with `git fetch origin dreyeck.ch` and
`git ls-remote origin refs/heads/dreyeck.ch`: both identified
`00d2a18bbc9cbd2045454ce8f9c4af8d8b58e60a`. Feature branch:
`codex/defederation-shop3-slice-1`.

## Existing routines and the small gap

Read `dreyeck/work/planning.lisp`, `dreyeck/shop3/{package,plan-objects,views}.lisp`,
their tests, and the newer `dreyeck/work/remote-control-planning.lisp` example.
The documentation experiment explicitly reports a fixed sequence. The remote
control experiment supplies the reusable pattern: separate SHOP3 methods,
`:which :all`, all four planner return values, and `hyperdoc-htn-plan-result`.

`hyperbook-fedwiki/wiki-links.lisp:lookup-slug-in-page-context` tries local pages,
plugin pages, and remote context. `dreyeck/src/local-fedwiki-page.lisp` supplies
local-store provenance and an exclusively local `hyperbook:find-page` method.
These are future implementation seams; this slice changes neither resolver.
It also changes no renderer, page store, journal, Catalog surface or service.

The existing result's `print-object` and normal CLOS slot inspection remain
available. There is no second result class, HTN interpreter or executor. The
generic source-edit checklist is not used to interpret the simulated actions.

## State and method choice

The opt-in system is `dreyeck/work/defederation-planning`; its tests are
`dreyeck/work/defederation-planning/tests`. No default system depends on it.

| Observation | Explicit opposite | Missing observation |
| --- | --- | --- |
| `local-page(site, slug)` | `local-page-absent(site, slug)` | Local presence unknown |
| `remote-snapshot(site, slug, remote, snapshot)` | `snapshot-unavailable(site, slug)` | Snapshot availability unknown |
| `fork-permitted(site, slug)` | `fork-forbidden(site, slug)` | Permission unknown |

These are hypothetical supplied observations, not discovery or authorization
adapters. Snapshot identity is an opaque fixture token, not a fetched or verified
digest. `snapshot-unavailable` means no snapshot for this target is available;
it conflicts with any positive snapshot observation for that target.

`input-conflict` recognizes each pair of opposites for the requested site/target.
The top method rejects such input before decomposing. Its negative test means
"no contradictory pair supplied", not "the outside world has been validated".
There is no inference from a missing positive fact to an observed negative.

The two `ensure-local-target` method definitions have different preconditions:

* `already-local` needs positive `local-page` evidence and has an empty subtask
  list: no fork. Remote evidence is irrelevant when the target is already local.
* `fork-proven-remote` needs explicit local absence, an identified remote snapshot
  and positive fork permission. It plans `!simulate-fork` with that exact source.

The top task then plans `!prepare-local-links` and
`!prepare-paragraph-rendering`. The first requires the target to be observed
local or simulated local; the second requires local-link preparation. All three
operators only add simulated in-memory facts. They contain no calls, callbacks,
network access, page writes or execution hooks. Initial observations stay in the
final modeled state, alongside the new `modeled-local-page`/`modeled-fork` facts.

The model covers one site and one required target. Preparing a whole site's
complete link inventory, enforcing a real paragraph filter and refederation
are subsequent tasks.

## Reproduce and inspect

In the project's prepared dependency environment, from this checkout:

```sh
nix develop -c sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-defederation-planning.lisp
```

In the existing SLY image, use the registered checkout and evaluate these blocks
separately. Load only the optional system, then run its tests:

```lisp
(asdf:load-system "dreyeck/work/defederation-planning")
(asdf:test-system "dreyeck/work/defederation-planning/tests")
```

Create three ordinary, inspectable result objects:

```lisp
(defparameter *defederation-a*
  (dreyeck/work/defederation-planning:defederation-plan :a))
(defparameter *defederation-b*
  (dreyeck/work/defederation-planning:defederation-plan :b))
(defparameter *defederation-c*
  (dreyeck/work/defederation-planning:defederation-plan :c))
(mapcar (lambda (result)
          (list (dreyeck/work/defederation-planning:planning-outcome result)
                (dreyeck/shop3:plans-of result)
                (dreyeck/shop3:execution-mode-of result)))
        (list *defederation-a* *defederation-b* *defederation-c*))
(inspect *defederation-b*)
```

Expected: `hyperdoc-htn-plan-result` objects; A and B `:planned`, C `:no-plan`,
all `:plan-only`. Return the printed outcomes/plans and any condition if live
SLY confirmation is wanted. The Cloud runs below do not confirm that live image.

For context including initial facts, tasks, native problem/domain/methods and
the result, with the Inspector already loaded:

```lisp
(defparameter *defederation-experiment*
  (dreyeck/work/defederation-planning:defederation-experiment :b))
(clog-moldable-inspector:clog-inspect :object *defederation-experiment*)
```

Inspect result slots `raw-plans`, `plans`, `plan-trees`, `final-states`, `time`
and `execution-mode`. `shop3:state-atoms` exposes each modeled final state's
facts. The recursive `find-plans` API returns native S-expression trees; the
existing `plan-tree->safe-sexp` helper targets the other planner's CLOS tree
representation, so this slice retains and tests the native trees directly.
SHOP3 represents the already-local method's empty decomposition with NIL for
its tree label; its applicability is checked through the state and plan shape.

After a disk update, reload only the owning system:

```lisp
(asdf:load-system "dreyeck/work/defederation-planning" :force t)
(defparameter *defederation-b*
  (dreyeck/work/defederation-planning:defederation-plan :b))
(inspect *defederation-b*)
```

## Executed evidence, 7 November 2026

Real SHOP3 `ce53f9b651acde8c44dc21eddb1a1c5b97f10536` from `flake.lock`,
SBCL 2.4.10, isolated Cloud fixture processes. No SLY evaluation, merge,
deployment or service restart. The Nix shell command above is the reproduction
entrypoint; this Cloud run used the already available portable SBCL and a
prepared ASDF registry rather than building the entire current Nix closure.

| Search | Observed plans / trees / final states | Primitive actions |
| --- | --- | --- |
| A, local | 1 / 1 / 1 | Prepare local links, prepare paragraph rendering |
| B, remote and fork proven | 1 / 1 / 1 | Simulate fork, then both preparations |
| C, fork permission unknown | 0 / 0 / 0 | No complete plan |
| Remove permission, snapshot, or explicit local absence from B, separately | 0 / 0 / 0 each | No complete plan |
| Explicit fork prohibition / unavailable snapshot | 0 / 0 / 0 each | No complete plan |
| Replace local absence with local presence in B | 1 / 1 / 1 | Both preparations; no fork |
| Local target with explicit fork prohibition | 1 / 1 / 1 | Both preparations; no fork needed |
| Contradict local, snapshot, or permission observation, separately | 0 / 0 / 0 each | No complete plan, including via the local method |
| Add `fork-reviewed` to fork **method** preconditions only | 0 / 0 / 0 | All alternatives exhausted; operator unchanged |
| Same changed method, local A | 1 / 1 / 1 | Local method still works |
| Same changed method, add the missing review fact | 1 / 1 / 1 | Fork path becomes available again |
| Add review precondition to local method; local target plus remote/permission evidence | 0 / 0 / 0 | Fork method cannot bypass missing explicit local absence |

The test reads this slice's domain form and uses SHOP3's `defdomain` to build an
isolated mutant. It deletes the mutant afterwards and rechecks the original.
Every search uses `:which :all`; no hidden alternative returned a plan in the
negative probes. Assertions also cover result type/mode, initial-fact
preservation, exact fork arguments, tree structure and final preparation facts.
The optional load/test leaves Catalog membership unchanged.

**Planning success** means `raw-plans` is non-NIL; a successful empty plan would
also count. **No solution** means `raw-plans` is NIL. **Execution has not
occurred** in either case: the result has mode `:plan-only`, the context reports
`:execution :not-executed`, and there is no executor.

Full final runner output is in
[defederation-planning-evidence/tests.log](defederation-planning-evidence/tests.log).
The actual Cloud command, registry setup and dependency pins are recorded in
[defederation-planning-evidence/environment.md](defederation-planning-evidence/environment.md).

Existing suites executed: `dreyeck/work/planning/tests` and
`dreyeck/work/remote-control-planning/tests` passed on the verified unmodified
base before implementation and again with the slice. `dreyeck/wiki-link/tests`
passed all three retained runners. The local FedWiki page assertions also
passed when loaded and called directly in their own fresh process; its ASDF
subprocess-launch wrapper was not used with this portable runtime. No baseline
test failure was observed. Dependency compilation/redefinition warnings are
retained in the full output. This is not a claim that every repository or
upstream SHOP3 test suite was run.

Source delta: the domain, fixtures, tests and opt-in ASDF definitions, one
fresh-process runner, this report and evidence. HyperDoc page delta: none.
FedWiki delta: none. Disk/reload proof: the final fresh process loaded the
durable ASDF entrypoint and passed. Independent Claude-Code review remains
pending; stop after preparing the draft PR.
