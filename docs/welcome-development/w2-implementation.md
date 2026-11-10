# W2 implementation and review entry point

R1 makes [canonical serialization content-stable](corrections/w2-canonical-serialization.md).
The approved P0 digest is now `ba9bbb10…`; historical mixed-string bindings
remain visibly mismatched and are never silently rewritten.

N1 additionally enforces a [record-to-fact value contract](corrections/w2-record-values.md),
with explicit fixture ID compatibility changes and complete regression evidence.

The [D1/D2 review correction](corrections/w2-trust-screen.md) tightens executable
contexts in the historical-source screen and preserves refusal diagnostics.
It supersedes the original A7 coverage and records the current full regression run.

W2 implements the accepted [handoff](w2-domain-versions-handoff.md), based on
`f982619116e33ce61fecd36f26819d62ac53e5fc`. The implementation branch is
`codex/11570-w2-domain-versions`. It extends the existing optional
`dreyeck/work/welcome-development` system; the separate opt-in acceptance system
is `dreyeck/work/welcome-development/domain-version-tests`.

A journal's assignments and submission checks replay with the planning domain
named by their v2 binding. Each observed version requires its dedicated existing
local tag, exact commit, source blob and extracted-form digest. A private domain
is constructed with native SHOP3 after the Eclector reader and structural screen.
The public domain registration and dynamic SHOP3 domain are preserved. Each
planner invocation removes its temporary problem, including a partially
registered problem when construction fails.

Bindings contain the domain content ID, declared SHOP3 pin, canonical state and
all native alternatives. They exclude transient problem names and timing. The
current next-action cycle still uses the currently loaded public domain and
retains every alternative, raw plan, tree and final state, with `:PLAN-ONLY`.
The W1 ordered prefix checks and record rules remain in effect; v1 bindings are
explicitly refused. Fixture factories now prepend a domain-version record and
produce real v2 proposal bindings.

**Planning domain replayed by version; record validation uses the current validator.**

The version record retains historical validator blob provenance. The run reports
the source SHA256 of the current records implementation. Neither loads an old
validator. A newer validator can refuse an old journal.

## Inspector

In the owning checkout's prepared Lisp environment:

```lisp
(asdf:load-system "dreyeck/work/welcome-development")
(defparameter *w2-run*
  (dreyeck/work/welcome-development:welcome-development-demo :p4))
(inspect *w2-run*)
;; In an already running HyperDoc Inspector:
(clog-moldable-inspector:clog-inspect :object *w2-run*)
(dreyeck/work/welcome-development:development-topicmap *w2-run*)
```

The "Development next actions" view links to the native result, retained records,
version objects, current validator provenance and Topicmap. Opening a version
shows "Planning domain provenance", including its retained record, Git commit
object when observed, tag kind/object ID, blob, form digest, screen and private
SHOP3 domain. Assignment validations and submission checks point to the exact
same version object by EQ. Inspector and Topicmap keep the same record/commit
objects. Alternatives also retain W1's stable EQ identity within a run.
Fixture versions have only `:hypothesized` edges; submissions remain claims.
There are no buttons, dispatch functions or Catalog additions.

For read-only local Git preparation:

```lisp
;; CHECKOUT must be an explicitly supplied DREYECK/GIT:GIT-REPOSITORY-CHECKOUT.
(dreyeck/work/welcome-development:describe-development-domain-version
 checkout "<full local commit SHA>")
;; Returns the content ID, blob/form identities and proposed dedicated ref.
;; Does not create the tag. Tag approval/creation is outside replay.
```

Use `git-domain-version-record` to retain that local source description once a
human has approved and created the dedicated tag outside W2. Append its record
before using its ID in `assignment-proposal-binding :domain-version ...`.
Replay rechecks the tag and source; the description itself is no authorization.

Binding `*development-domain-debug*` to T checks public registration/plist and
dynamic-domain invariants around each record replay, including exceptional exits.
The W2 acceptance runner enables these checks.

`clear-development-domain-cache` removes private registrations by domain object
and returns the entry count. Existing results may still reference their private
domain objects for inspection. Fixture source snapshots are volatile per-image
copies captured by the fixture factory, never record-carried items. They support
fixture replay across public-domain changes and cache clearing within that image.
Durable, cross-process historical replay uses tagged Git source instead.

## Verification

See [the executed report](w2-test-report.md) and [retained logs](w2-evidence/).
The complete runner is:

```sh
nix develop -c bash scripts/audit-welcome-domain-versions.sh
```

It uses a disposable child HOME and private FASL cache, runs the W1/Defederation/
Local-only regressions and W2 acceptance tests, compares identity/binding output
from two fresh Lisp processes, then audits fixture-only and historical replay
processes with `strace -f -e trace=%network,execve`. Tag fixture creation happens
in a temporary Git repository outside the traced replay. The runner deletes it
on exit and compares its tag refs before and after replay. It needs `strace`,
`python3`, `rg`, `mktemp` and the prepared SBCL/ASDF registry. Set `W2_LOGS` to retain logs
at a chosen directory. `W2_SBCL` and `W2_BOOTSTRAP` can select an existing runtime
and a local dependency-registry bootstrap; no dependency acquisition is performed.
The bootstrap, if used, runs before the runner establishes its private FASL cache.

Individual entry points are:

```lisp
(asdf:test-system "dreyeck/work/welcome-development")
(asdf:test-system "dreyeck/work/welcome-development/domain-version-tests")
```

The script `scripts/test-welcome-development.lisp` additionally runs the existing
Defederation and Local-only suites. `scripts/test-welcome-domain-versions.lisp`
provides the `W2_MODE=identity`, `fixture` and `replay` subprocess modes used by the
shell audit. The complete acceptance mode alone intentionally retains no tags
unless `W2_KEEP_REPO` is set by the audit harness.

## Trust and runtime limits

A Git tag expresses repository provenance and deliberate retention; **a tag alone
is not cryptographic authentication**. W2 accepts annotated and lightweight tags
and explicitly records signatures as `:not-verified`. Access control and review
of the selected repository/tag remain external responsibilities. The source
screen is defence in depth, not a sandbox. Screened domains still execute in the
replaying Lisp process. Use a disposable process for independent validation,
with a network namespace where the host supports one.

The exact Eclector ASDF version must be **0.11.0**. The running image's declared
SHOP3 revision/nar hash from the owning `flake.lock` and ASDF version 4.3.1 must
match the supported pin. This checks declarations; it does not rebuild or
cryptographically attest the loaded runtime. The SHOP3 source path is description
provenance only. SHA256 domain IDs identify canonical native domain items,
including SHOP3's generated `!!inop`, and do not depend on commit identity.

Local Git observation requires **Git >= 2.44**, because the reused `dreyeck/git`
helpers pass `--no-lazy-fetch` to prohibit implicit object acquisition. An older
Git rejecting that option is an environment limitation. W2 never fetches missing
objects or creates/moves tags during replay. A shared tag lookup/signature API is
still absent; W2 uses a small local read-only adapter to `git-run-values`.

No shared SHOP3, `dreyeck/git`, Defederation, FedWiki, authority or fork-execution
implementation changes are required. No S1–S4 implementation, test producer,
agent dispatch, executor capability, merge, deployment or service restart is
included. Stop here for independent Claude Code review.
