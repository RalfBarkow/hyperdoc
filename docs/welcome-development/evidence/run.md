# Executed W1 checks

Date: 2026-11-10. Worktree: `/workspace/work/welcome-development`.
Branch: `codex/11570-w1-welcome-development`.
Parent/handoff: `20ad13e650cd1aca0c40192080e724b3cb4e0304`.
Remote `dreyeck.ch` observed before implementation:
`99dbe5599dc6c0b080bec1b743dd864aa5635e0b`.

## Final combined run

```sh
DEFEDERATION_REPO=/workspace/work/welcome-development \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --load scripts/test-welcome-development.lisp \
  > /workspace/work/welcome-final-tests.log 2>&1
```

**Exit code: 0.** [tests.log](tests.log) is the full captured output, including
dependency warnings. The script records the ASDF source-file origins of both
regression systems, verifies Catalog membership, and ends with
`WELCOME-ALL-PASS`. Nothing was stubbed or skipped in these three suites:

1. `asdf:test-system "dreyeck/work/welcome-development"` dispatches its focused
   `dreyeck/work/welcome-development/tests` suite.
2. `asdf:test-system "dreyeck/work/defederation-planning/tests"`.
3. `asdf:test-system "dreyeck/work/fedwiki-local-only/tests"` (including input/R1
   regressions).

The W1 scenario output is derived from real `find-plans` calls with all solutions,
plan trees and collected states. Synthetic record provenance is printed as
`:FIXTURE`; the suite does not manufacture actual slice observations. Additional
checks include the actual local handoff commit/tree observation, both matching
and nonmatching file scopes, rendered Inspector HTML and EQ object references.

## Baseline

Before source changes, the same portable command prefix and bootstrap ran:

```lisp
(asdf:test-system "dreyeck/work/defederation-planning/tests")
(asdf:test-system "dreyeck/work/fedwiki-local-only/tests")
```

Exit 0, [baseline-tests.log](baseline-tests.log) (trailing whitespace trimmed).
That worktree was then at
`99dbe5599dc6c0b080bec1b743dd864aa5635e0b`; the two subsequent handoff commits
add only the design documents. Final regression sources are unchanged from the
handoff. No existing regression failure was observed.

## Environment and limits

SBCL 2.4.10; real SHOP3 4.3.1 from pinned source
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536`. W1 required no package installation
or dependency downloads. The pre-existing registry/bootstrap and dependency
pins are retained in
[`../../defederation-planning-evidence/cloud-bootstrap.lisp`](../../defederation-planning-evidence/cloud-bootstrap.lisp)
and its environment report. `DEFEDERATION_REPO` points that bootstrap's exact
ASDF loads at this W1 checkout. The runner also adds its own checkout to the
central registry. Private FASLs are under `/workspace/work/defederation-fasls/`.

The available portable dependency closure includes Iterate `release-b0f9a9c6`,
rather than the newer Iterate flake pin. This is real execution in the recorded
fixture environment, not a build/test of the full current flake closure. The
portable reproduction command in the main README uses the normal Nix shell.

Platform: Linux. Network namespace isolation: **none**. Whole-process syscall
trace: **not performed**. The unchanged Local-only suite reports its Lisp-level
network/plugin/context guards; this is not a syscall audit of W1. No macOS,
interactive CLOG or user's live SLY image was tested. No production Wiki or
service was touched.

The shared remote Git observer and an authenticated independent test producer
remain outside W1. Actual source/commit scope can be read locally; real slice
test records must be supplied by a trusted independent observer. Remote
integration is explicitly refused. Synthetic P0–P11 states do not prove that
S1–S4 were performed.

`tested-source.json` binds the successful run to SHA-256 hashes of the ASDF,
runner, implementation and test sources. The shared plan-result/classification
source, defederation domain and Local-only runtime were also checked unchanged
with `git diff --exit-code 20ad13e6 -- <paths>`; `git diff --check` passed.
