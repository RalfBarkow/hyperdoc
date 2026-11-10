# W2 executed acceptance report

**Review correction:** The original A7 vectors below were incomplete. Independent
review reproduced admitted executable D/E attacks at `32209c16`. See the
[D1/D2 correction report and complete rerun](corrections/w2-trust-screen.md) for
the corrected screen and current evidence. The original logs remain historical
observations, not proof that the old trust boundary was sound.

Date: 2026-11-10. Base and remote design branch verified at
`f982619116e33ce61fecd36f26819d62ac53e5fc` before edits; implementation branch
`codex/11570-w2-domain-versions`. W1's accepted implementation is the parent
`61cdec068116891d8455cdff9bb7b81ef1df171a` of that design commit.

These are executed observations, independent of the design document's claims.
All Lisp runs used SBCL 2.4.10, native SHOP3 4.3.1 at the declared flake pin
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536`, Eclector 0.11.0 and Git 2.52.0.
The final audit uses separate child processes, an empty child HOME and a private
FASL cache (seeded from the already prepared local dependency cache). It does not
acquire source or rebuild a Nix closure. Exact dependency registry paths are in
[environment-bootstrap.lisp](w2-evidence/environment-bootstrap.lisp).

## Commands

Executed from `/workspace/work/welcome-w2`:

```sh
DEFEDERATION_REPO=/workspace/work/welcome-w2 \
W2_SBCL=/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
W2_BOOTSTRAP=/workspace/work/defederation-bootstrap.lisp \
W2_LOGS=/workspace/work/w2-reviewed-evidence \
scripts/audit-welcome-domain-versions.sh
```

The checked-in [audit script](../../scripts/audit-welcome-domain-versions.sh)
contains the exact SBCL flags, ASDF output configuration, individual test commands,
fresh-process comparison, tag snapshot comparison and `strace` invocations. It
runs these Lisp entry points:

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load <local-registry-bootstrap> --eval '(require :asdf)' \
  --eval '<private output translations, as in the audit script>' \
  --load scripts/test-welcome-development.lisp
# Then scripts/test-welcome-domain-versions.lisp, followed by its identity,
# fixture and replay modes in fresh processes, with the same flags.
```

The W1 runner executes `asdf:test-system` for Welcome Development, Defederation
Planning and Local-only FedWiki. The W2 acceptance runner enables per-replay public-domain invariant checks.
The W2 runner executes the separate
`dreyeck/work/welcome-development/domain-version-tests` ASDF system.
Exit status of the complete audit: **0**.

## Results

| Acceptance | Executed outcome | Evidence |
|---|---|---|
| A1 | PASS: loaded/git IDs equal; two commits with identical items give the same ID; an added axiom changes it. Two fresh processes produce identical version and v2 binding digests. | acceptance.log; identity-1.log; identity-2.log; audit.log |
| A2 | PASS: version A's journal replays after public B adds an unused axiom and the private cache is cleared. A B binding is unavailable until its B version record precedes it. | acceptance.log, `A2/A8` |
| A3 | PASS: public domain object, symbol plist and dynamic domain survive success, cache clear, injected reader/screen/install/id/planner failures. Replay also works after public deletion, including fresh tagged-Git reconstruction after cache clearing. | acceptance.log, `A3/A4` |
| A4 | PASS: private names are uninterned, no package contains a `WELCOME-DEVELOPMENT@…` symbol, failed creation leaves no cache/registration, cache removal returns its count and clears registration. Current-domain symbol properties remain unchanged. | acceptance.log, `A3/A4` |
| A5 | PASS: absent tag, branch-only retention and wrong target refused; annotated and lightweight accepted. Tag refs unchanged across replay. Traced Git commands are only `cat-file`, `rev-parse`, `show`; no network syscalls. | acceptance.log; tags-before.txt; tags-after.txt; replay.strace; audit.log |
| A6 | PASS: blob/form mismatch, unknown/swapped/late version, record-carried items, wrong planner pin, duplicate, v1 binding and mixed sources refused. A valid cache entry cannot hide forged different source. | acceptance.log |
| A7 | PASS: actual unchanged W1 literal domain reads successfully. All listed unsafe reader/forms/options/costs are refused before construction; foreign probe package unchanged; feature not interned into W1. Real Eclector recover restart observed without invocation; current-package/read-base state APIs exercised. | acceptance.log, `A7` |
| A8 | PASS: first submission uses assignment's A even when public B has no await method. C1–C3 still refuse claims and later acceptance chains. | acceptance.log; regressions.log |
| A9 | PASS: P0–P11, P4b/P10 refusals, completion, binding/record negatives, F1–F5 and C1–C3, first submissions, all native alternatives, plan trees/final states, `:PLAN-ONLY`, Inspector/Topicmap EQ and both unchanged regression suites. | regressions.log |
| A10 | PASS: 100 complete runs + 20 complete-journal builds leave problem registry/current pointer unchanged, with one distinct cached version. Planner failure and failure after problem registration also clean up. | acceptance.log; fixture.log |
| A11 | PASS: every assignment validation/submission check has an EQ version link; version/record/commit Inspector references and Topicmap topics reuse the same objects, with derived edges. Fixture edges are hypothesized; observed Git edges are observed. Current ID/tagged state reported. | acceptance.log; replay.log; fixture.log |
| A12 | PASS: version validator provenance and run source SHA256 present; Inspector contains the exact non-claim sentence. No historical validator behavior is asserted. | acceptance.log; replay.log; fixture.log |
| A13 | PASS: Catalog unchanged, no buttons/execution controls or capabilities. No changes in shared SHOP3, Git, FedWiki, authority or fork implementation paths. Fixture process makes zero Git exec attempts and zero network syscalls. | regressions.log; fixture.strace; audit.log; Git diff against design base |

Domain ID:
`f342bb4ad3455fac873a56d9a7d817ff35e7ace253527ef7db1068e3759ad315`.
P0 Codex S1 assignment binding digest:
`1ebd24a84517314b1087526c13e27518f08f85e0b7e9e67f9185a3e7db3adc61`.
These identities exclude the disposable repository's commit timestamps and
problem names. W2 domain and binding digests agree across the two identity logs.

C1 and C2 refuse with `:submission-not-proposed`; C3 refuses additional claims to
either exhausted closed assignment with the same reason. The positive first
claim is admitted and SHOP3 then proposes `!verify-submission`. The P4 run keeps
both S1 integration and S2 assignment proposals, with neither selected/executed.

The unchanged base also passed W1, Defederation and Local-only before editing:
[baseline.log](w2-evidence/baseline.log). No baseline implementation failure was
observed. The final regression log records test origin paths for this worktree.

## Reproducibility and limits

The [retained evidence](w2-evidence/) contains full successful stdout logs and
raw syscall traces. Git's PATH search can produce several failed `execve`
attempts before a successful Git exec; the audit reports attempts explicitly.
Every attempt still names a read-only subcommand. A separate socket-creation
positive control confirms that the trace can observe network syscalls. Temporary
tag fixtures are removed by the harness; their contents are regenerated by
`w2-git-fixture`, so the temporary commit SHAs may differ on rerun.

`unshare --net true` returned `Operation not permitted` in this container. These
runs therefore have **observed zero network syscalls**, not enforced network
namespace isolation. Use a network namespace for independent validation where
the review host permits it. No remote API calls occur in the replay or fixture
runners; pushing the review branch/opening its draft PR is a separate delivery
operation.

The dependency bootstrap records host-specific store paths. Other hosts must
provide the project's prepared ASDF registry (for example through `nix develop`)
and the pinned reader/planner versions. The tests check the declared SHOP3 pin
and actual ASDF versions; they do not attest a rebuilt historical runtime.
All observed Git-version test records refer to the disposable repository, not
project changes. Their development policy and claims are test inputs; no real
development verification/review or implementation progress is asserted.
The base fixture runtime's pre-existing qualification problems remain registered;
W2-created problems leave no additions to that baseline registry.

Tags are **not cryptographic authentication** and signatures are not verified.
Historical code is screened trusted code executed in-image, not sandboxed code.
Fixture source snapshots are volatile and explicitly hypothetical. Durable replay
requires local tagged blobs. Only the planning domain is versioned; stricter
current record validation can refuse previously acceptable journals.

No S1–S4 implementation, agent execution, production change, merge, deployment or
service restart was performed. Ready for independent Claude Code review only.
