# Focused presentation verification — 2026-10-30 UTC

Baseline: HyperDoc PR #8, `9dfcf4d705302c561535259b87a4a9f64bd61b5f`.
Task branch: `codex/topicmap-type-status`. All three isolated SBCL 2.4.10
commands were rerun against the final source before publication and exited **0**:

1. `asdf:test-system "dreyeck/topicmap-presentation/tests"` — **269 checks PASS**.
   Independent columns; missing/string/keyword values; HTML escaping; real
   PR Review, Work and Lisp Critic projections; observation-time provenance;
   topic/object/association handles, types, temporal scope, Inspector references,
   Workspace navigation and baseline SVG equality.
2. `asdf:test-system "dreyeck/pull-request-review/reading"` — **141 checks PASS**.
   The existing PR #8 suite is unchanged and ran in a separate fresh process.
3. `sbcl --noinform --no-sysinit --no-userinit --disable-debugger --script
   reports/topicmap-type-status/existing-topicmap-tests.lisp` — **5 selected
   existing regression functions PASS**. The script loads the existing test
   system and calls only the named generic view, workspace, association
   navigation, semantic-presentation and containment-sign functions.

The first two complete command forms are in `docs/topicmap-type-status.md`.
The classification audit was run in the focused-test process after its 269
checks; its standalone replay is:

```sh
sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
  --script reports/topicmap-type-status/classification-review.lisp
```

`classification-review.txt` records the observed type/classification pairs for
PR Review, Work and Lisp Critic. It establishes that retaining both columns is
not justified solely by the PR example; the PR pair's semantic overlap is
explicitly acknowledged in the design document. The audit loads only existing
local fixtures and does not refresh GitHub data.

`tested-sources.json` identifies the exact code, test, baseline and audit bytes
used by this rerun. No runtime source changes followed it.
`*-results.txt` retain the exact result lines, extracted from the process logs.
Dependency loads emitted existing DBI redefinition warnings; the earlier initial
compilation also reported an unused `CONTEXT` style warning in unchanged Work code. These were
not suppressed, treated as test failures or repaired in this slice. No full
Work/Lisp Critic/project corpus suite or browser/SLY session was run.

## Baseline capture, not an adjusted expected output

Before testing the changed source, a separate fresh process loaded the
**unmodified** PR #8 checkout's existing PR Review, Work and Lisp Critic
Readings. `capture-baseline.lisp` reproduces that rendering; point ASDF at that
exact baseline checkout, create an external output directory, set
`TOPICMAP_BASELINE_OUTPUT` to it and run the script with SBCL. Baseline output
lengths in UTF-8 were PR Review **6592**, Work **20515**, Lisp Critic **5273**
octets. `baseline-svg.json` records the SHA-256 of each complete native SVG
rendering string (including its HTML wrapper).

`pr8WithoutObservationCaption` hashes the original PR Review bytes after a
single literal replacement of UTF-8
`'snapshot · 2026-10-30T10:26:43Z'` with `'snapshot'`. The old bytes were checked
to contain that exact caption once. This records the explicit exception being
reviewed; it does not regenerate an expectation from the changed producer.
The new tests compare Work and Lisp Critic outputs byte-for-byte via SHA-256
against their unchanged baseline, and PR Review against that one-change anchor.

`unchanged-sources.json` hashes the GitHub snapshot, separate human annotations
and renderer-independent Topicmap model. Each was compared byte-for-byte with
`git show 9dfcf4d...:<path>` and remains unchanged. Existing PR #8 evidence is
historical and was not rewritten. No CTM, ISO model, Topic Maps pin, Catalog,
MCP service, NixOS or deployment change is included.

Local replay used the existing cached declared dependencies and an external
source-registry/ELF-loader bridge for this Cloud environment. No launcher paths
or dependency-provisioning workaround were added to product code.

## Review boundary

Tests establish fresh-process source loading, HTML text and native reference
behavior. They do not establish browser layout, a user's live-image reload or
human acceptance. The optional Inspector handoff is documented separately.
No additional runtime abstractions, authored page changes, FedWiki changes or
GitHub snapshot refresh were made.

Remaining interactive review questions: Is the additional table width usable in
the actual Inspector window for Work and Lisp Critic? Is “Display classification”
clear to readers without implying a second type system? Does clicking the
snapshot still show its provenance and observation time in the user's live
image? The existing keyword-based Inspector handoff is in the design document.
These are open human observations, not failing automated checks.
