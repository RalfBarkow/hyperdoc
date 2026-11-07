# Cloud fixture environment

Observed on 2026-11-07. SBCL 2.4.10 was already installed in the portable Nix
store; no system packages were installed. The wrapper uses that runtime's
loader/core explicitly. ASDF compilation output is isolated under
`/workspace/work/defederation-fasls/`.

The exact registry setup used is retained in [cloud-bootstrap.lisp](cloud-bootstrap.lisp).
It registers source trees; it does not load a replacement planner or stub any
ASDF system. Its paths are Cloud-instance-specific. The portable reproduction
entrypoint in the report uses the project's normal `nix develop` instead.

The seven GitHub SHOP3 dependency source archives were retrieved from
`https://api.github.com/repos/OWNER/REPO/tarball/REV`, using the repository's
`flake.lock` revisions:

| Input | Revision |
| --- | --- |
| shop3 | `ce53f9b651acde8c44dc21eddb1a1c5b97f10536` |
| shop3-documentation-utils | `fcbd927dee7f311915a27ee557e3db1d4510403c` |
| shop3-fiveam-asdf | `7f11d9f5bdf6be425ffc9c1744955b1c460d9183` |
| shop3-pddl-tools | `fc2de73c9e6ef732cceb3c74d22a25724ae697e4` |
| shop3-random-state | `1eda41f2f392b09305c72113226da0814a1137b8` |
| shop3-trivial-garbage | `fff99d96b6a94811606dc8019cd25c771575dc30` |
| shop3-trivial-indent | `87b35ff9202b107230e35790e93c471cc7880900` |

The remaining dependencies came from the environment's existing portable Nix
store, with exact directories recorded in the bootstrap. In particular Iterate
is the available `release-b0f9a9c6` package, not the newer `shop3-iterate` lock
revision. This run proves the real SHOP3 searches and the current repository
ASDF systems under this recorded fixture environment; it does not validate the
entire current flake closure.

Actual final command, working directory `/workspace/work/defederation-shop3`:

```sh
DEFEDERATION_REPO=/workspace/work/defederation-shop3 \
/workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load /workspace/work/defederation-bootstrap.lisp \
  --load scripts/test-defederation-planning.lisp \
  > /workspace/work/defederation-final-tests.log 2>&1
```

Exit 0. [tests.log](tests.log) is that full output, including dependency
redefinition warnings, rather than a rewritten expected-output file. The runner
asserts unchanged Catalog membership immediately after the optional system's
load/test, before loading the pre-existing regression suites.

Before editing, separate fresh processes used the same bootstrap with each of:

```lisp
(asdf:test-system "dreyeck/work/remote-control-planning/tests")
(asdf:test-system "dreyeck/work/planning/tests")
```

Both passed on base `00d2a18bbc9cbd2045454ce8f9c4af8d8b58e60a`.
The final runner repeats both unchanged suites and runs
`dreyeck/wiki-link/tests`. No observed baseline failure needed reproduction.

Local-page regression, separate fresh process with the same command prefix:

```sh
--eval '(asdf:load-system "dreyeck/local-fedwiki-page/tests")' \
--eval '(assert (uiop:symbol-call :dreyeck/local-fedwiki-page/tests :run-local-fedwiki-page-tests))'
```

Exit 0. This executed its provenance, page-attached ASDF and Inspector-view
assertions directly in the fresh process. It did not run the system's additional
subprocess-launch wrapper. The suite uses its retained temporary fixtures; no
user Wiki page was changed.

All final searches ran from durable source through ASDF. No live SLY image,
external Wiki, renderer or resolver was changed. No upstream SHOP3 full test
suite or independent Claude-Code review is claimed.
