# Lisp Critic A1: inert claims-source extraction

Base: `1da262deee28c614ab63c2311f5355de2dfaafc5`. This is implementation
verification by Codex, not independent acceptance. No rule, judgement, source
station policy, vendor code or SHOP3 domain is changed.

## Contract

`read-claim-table` returns `(values table nil)` or `(values nil reason)`.
The extractor uses no Common Lisp READ, evaluation, compilation, feature
selection, package lookup or structure constructor. It scans the complete
source before selecting exactly one active top-level, unqualified
`(defun historical-claims () [docstring] (copy-tree 'table))` definition.
Explicit `(quote table)` is also accepted. Comments and strings cannot supply
candidate definitions. Quoted and nested forms cannot supply them either.
Malformed or incomplete source anywhere is refused.

The structural envelope supports balanced lists, whitespace, line comments,
nested block comments, strings with backslash escapes and unescaped token
spellings. Quote, backquote and comma prefixes consume their following form;
only quote is accepted in the candidate definition. `#'`, `#:` and character
literals are inert envelope representations required by ordinary surrounding
source; they are not accepted as table values. No dispatch reader is called.
All other dispatch syntax, including `#S`, `#.`, `#+`, `#-`, vectors, radix
numbers and graph labels, is refused. Escaped symbol spellings are refused.
Package-qualified tokens outside the candidate are inert strings; within the
table they are refused. The envelope is not a validator of arbitrary Common
Lisp programs and makes no claim about execution of the surrounding code.

Table rows are even-length property lists with keyword keys. Values are strings,
keywords with letter/digit/hyphen/underscore/asterisk names, decimal integers,
T, NIL, or proper lists of these. Dotted lists, symbols naming code and computed
tables are refused. Structural nesting is bounded at 128; literal nesting is
bounded at 10 from the table root. Keywords are interned only after the whole
candidate has passed structural and literal validation. Failed extraction does
not create packages or intern source symbols.

`criticise-passage` gates claims parsing on source coherence. A changed or
contradicted source yields `:claims-not-parsed` and discrepancy
`:not-determined`; unavailable text remains `:claims-unreadable`. Existing
source-file statuses retain the detailed reason. `observe-now` delegates to
this boundary. No incompatible observations are compared.

## Executed evidence

`baseline.log` reproduces constructor effects, the changed-source constructor
effect, a block-comment false definition and feature-dependent tables using
the original committed reader. The original 80 checks pass there.
`corrected.log` records zero constructor effects, early source-state gating,
comment refusal and identical conditional refusals under two feature sets.
It also records the 80 checks passing with explicit grammar expectations
updated (no permissive `#.` outside the definition; graph syntax is refused
before a Lisp object exists). Source identity/revision tests are retained.

The probes also cover nested comments, strings, quoted definitions, incomplete
source, unsupported syntax, multiple candidates, source-file/package preservation
and a parser tripwire proving that changed sources never reach parsing.
The authentic committed Fischer source still yields ten primary-paper claims,
five primary-paper observations and five none-observed observations.

Run from this checkout, with the host-specific prepared dependency registry
in `bootstrap.lisp` available:

```sh
export DEFEDERATION_REPO="$PWD"
SBCL=/workspace/scratch/tmdm-mcp-portable/bin/sbcl
git show 1da262deee28c614ab63c2311f5355de2dfaafc5:dreyeck/src/lisp-critic-text-passage.lisp > /tmp/a1-original-passage.lisp
git show 1da262deee28c614ab63c2311f5355de2dfaafc5:dreyeck/tests/lisp-critic-text-criticism.lisp > /tmp/a1-original-tests.lisp
A1_BASELINE_TESTS=/tmp/a1-original-tests.lisp A1_BASELINE_SOURCE=/tmp/a1-original-passage.lisp "$SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load docs/lisp-critic-reader-safety/bootstrap.lisp --load docs/lisp-critic-reader-safety/probes.lisp --eval '(dreyeck/lisp-critic/text-criticism/tests:run-tests)'
"$SBCL" --noinform --no-sysinit --no-userinit --non-interactive --load docs/lisp-critic-reader-safety/bootstrap.lisp --load docs/lisp-critic-reader-safety/probes.lisp --eval '(dreyeck/lisp-critic/text-criticism/tests:run-tests)'
```

For the exact original 80-check baseline, use the original test file as well:
the preserved baseline run preceded changes to its grammar expectations.
The baseline mode deliberately invokes a harmless constructor counter in a
new process; it must not be loaded into a running service.

## Future SHOP3 inputs

- Coherent source state requires matching recorded octet identities; a
  verified-revision fact additionally requires verified Git membership.
- Established discrepancy requires coherent sources, an unambiguous observed
  passage, successfully extracted observations, and the existing comparison.
- Missing, changed, contradicted or refused evidence supports an undetermined
  or unavailable-evidence fact with its reason and provenance.
- Such a gap can justify requesting a further investigation, not a claim that
  a discrepancy is absent. `:not-determined` must never project as false.

Parsing success alone creates no criticism. Observation, derived discrepancy,
reviewer judgement, recommendation, engine Critique and planning remain distinct.

## Regression qualification and independent-review handover

The implementation was published promptly as
`9228ab022e003de815822bdbb1cf4bbd3ba8aba7`. The follow-up adds verification
artifacts and stronger no-effect/line-comment probes; production Lisp and its
80-check test file are unchanged from that commit.

`suites.json` and `baseline-suites.json` retain the original commands, exit
codes and log hashes. All nine suites were attempted in separate processes on
both the correction and clean base `1da262deee28c614ab63c2311f5355de2dfaafc5`.
A nonzero exit is never silently converted into a successful test. BLOCKED
classifications were checked against the actual terminal condition and failing
call on both revisions. The runner now labels a nonzero execution FAIL pending
review; it no longer infers blockers from matching log substrings.

| Suite | Original correction/base runs | Qualification |
|---|---|---|
| Text criticism | 80 checks PASS on each | Changed grammar expectations documented above; identity and membership checks retained |
| A1 probes | Expected old violations reproduced; corrected probes PASS | Reconstruction of the reported counterexamples, not the unavailable original review script |
| Text criticism integration | PASS / PASS | 9 checks; authentic table and unchanged judgement-basis resolver |
| Lisp Critic base | PASS / PASS | Existing smoke tests |
| Federated context | PASS / PASS | Existing observations and judgement-basis contracts |
| Recorded Critiques | PASS / PASS | Stored records, no real engine needed |
| Reading | BLOCKED / BLOCKED in original launcher | Child invoked ELF loader with Lisp options; see new launcher runs |
| Catalog | BLOCKED / BLOCKED in original launcher | Same child-launch defect; see new launcher runs |
| Critique | BLOCKED / BLOCKED | Actual terminal error: real Critic run lacks `a-critic-for-lisp` |
| Engine integration | BLOCKED / BLOCKED | Explicit source-station prerequisite raises an error |
| Page station | BLOCKED / BLOCKED | Same explicit source-station prerequisite |

The three source-station suites returned exit 1 on both revisions. Their real
engine scenarios remain **NOT RUN beyond the prerequisite**, not accepted and
not skipped into PASS. No real station was fabricated or fetched. Expected
negative controls using temporary synthetic stations belong to the existing
Reading tests and do not substitute for these integration scenarios.

### Portable child-process verification

`portable-sbcl` is a test-only adapter around the pre-existing portable SBCL
2.4.10 launcher. It selects the same prepared source registry in every fresh
child and sets `SB-EXT:*RUNTIME-PATHNAME*` to the callable adapter. It neither
changes assertions nor grants source-station permission. All test expressions
and child exit statuses are preserved. `launcher-check.lisp` confirms actual
child Lisp execution and preservation of a deliberate exit code 7; its own
check exits 0. The initial adapter attempt placed a runtime option after Lisp
options and failed before tests started. Its logs and records are retained as
`launcher-initial-*`; they are not suite results.

Reproduction (run from the correction checkout):

```sh
DEFEDERATION_REPO="$PWD" docs/lisp-critic-reader-safety/portable-sbcl --noinform --no-userinit --non-interactive --load docs/lisp-critic-reader-safety/launcher-check.lisp
A1_SBCL="$PWD/docs/lisp-critic-reader-safety/portable-sbcl" A1_LOG_PREFIX=launcher- A1_SYSTEMS='dreyeck/lisp-critic/reading/tests dreyeck/catalog/tests' python docs/lisp-critic-reader-safety/run-suites.py
A1_WORKTREE=/workspace/work/lisp-critic-a1-baseline A1_SBCL="$PWD/docs/lisp-critic-reader-safety/portable-sbcl" A1_LOG_PREFIX=baseline-launcher- A1_SYSTEMS='dreyeck/lisp-critic/reading/tests dreyeck/catalog/tests' python docs/lisp-critic-reader-safety/run-suites.py
```

The baseline worktree must be a clean checkout of the exact base. Existing
run files should be copied aside before reproduction. Host-specific paths in
the bootstrap and portable runtime need reconstruction on another machine;
no active runtime or dependency pin was changed. A current source inventory
and evidence hashes are retained in `handover-manifest.json`.

A different reviewer must inspect the positive grammar and refusal boundary,
reproduce the original attacks against the base and corrected outcomes against
the final commit, confirm early coherence gating and feature independence,
and rerun the 80 checks and nine integration checks. Review the paired
regression logs and rerun the three real-engine suites with a legitimately
available source station before claiming their coverage. Explicitly review
unsupported syntax, the limited structural envelope (not a general Common
Lisp validator), and the SHOP3 input-safety rules above. No independent A1
acceptance follows from these implementer-run results. Browser/UI, Nix builds
and production activation were NOT RUN in A1.

### Final observed outcomes after launcher repair

- Reading: **PASS**, exit 0 on correction and unchanged base, including current
  image, fresh child image, policy canaries, nonfunctional synthetic engine and
  expected integration-failure negative controls.
- Catalog: **FAIL**, exit 1 on both, at the unchanged
  `check-page-loading-repository-context` assertion in
  `dreyeck/tests/upstream-intake-smoke.lisp:1404`: "Local upstream object is
  absent." The context asks for `8a1149197fabcb1ab5622316f09c5a60c2d3f1f8`;
  direct `git --no-lazy-fetch cat-file -t` also fails in both checkouts. This
  is a reproduced baseline assertion failure with a missing local-history
  resource, not a passing Catalog and not a newly established A1 regression.
  Subsequent Catalog assertions were not reached. No history was fetched to
  change the test environment.

`launcher-suites.json` and `baseline-launcher-suites.json` retain the exact
rerun commands, exit codes and hashes. The old launcher failures remain in the
original records; they are not overwritten by these results. A complete Catalog
pass and the three real source-station suites remain outstanding. An independent
reviewer needs those resources to extend the evidence beyond this bounded slice.
