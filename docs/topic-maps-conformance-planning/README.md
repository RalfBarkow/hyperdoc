# Planning Topic Maps conformance investigations

Independent optional HyperDoc slice on clean base
`596344ae95d746f436705808462259371f5a593c`, local branch
`codex/topic-maps-conformance-planning`. No S1 acquisition code is included.
No Topic Maps source, test, Case Record, registered status or running image was
modified. No push, server action or integration with Fable's new API is included.

The domain and runner are in
[`topic-maps-conformance-planning.lisp`](../../dreyeck/work/topic-maps-conformance-planning.lisp).
It uses the existing pinned SHOP3, `hyperdoc-htn-plan-result` and Inspector
`object-ref` contracts. No shared normalizer was changed. The English
[HyperDoc Text Page](../../dreyeck/pages/topic-maps-conformance-planning/Planning%20Evidence-Based%20Investigations.html)
contains directly executable, separately readable SLY/CLOG inspection forms.

## Historical evidence and proposed contexts

All Topic Maps inputs are Git file-at-commit objects at
`88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`. The repository is explicitly supplied;
its moving HEAD, working files and ASDF definitions are never used. No Topic Maps
code is loaded. An absent pinned object is an evidence-reading error, not an
automatic negative planning fact. Existing `dreyeck/git` disables lazy fetching;
Git >= 2.44 is required. This run used Git 2.52.0.

The [source inventory](pinned-sources.json) binds eleven files by path, Git blob
and SHA-256 and retains the two original serialized Case Record excerpts. The
loader cross-checks those records against the matrix, direct reader/control
reports and original/baseline byte hashes. This is a bounded reading of two
existing records, not a new corpus importer or test-case model.

| Fixture | Historical source observations | Native planning result |
| --- | --- | --- |
| A: `ctm/in/include-template.ctm` | Registered FAIL / cxtm-mismatch; no reader condition; actual 353 versus baseline 401 bytes, first difference 58; unresolved formal disposition C. | Two alternatives: `review-observed-mismatch` and `prepare-normative-question`. |
| B: `ctm/in/template-subject-identifier2.ctm` | Original registered NOT-RUN, actual outcome null. Separate observation: INVALID-TEMPLATE-BODY / template-identity-tail, character 34, line 3, column 15. Separate expanded control matches 204/204 bytes. | `investigate-registered-not-run`; separate original/control evidence and prepare the original inquiry. |
| A with proposed edition-qualified scope | The 22A report explicitly records incomplete published-edition review; the proposed scope requires that completed review. | `report-explicit-prerequisite-gap`; a blocker, not completed qualification. |

The two A methods are simultaneously applicable because comparison evidence and
an unresolved normative question with cited references both exist. Preparing a
byte review does not require resolving the edition question first; preparing an
edition review does not declare either the baseline or implementation correct.
These are alternative next investigation routes, not claims that only one will
ever be useful. Every native alternative remains available with `:which :all`.

The goal/scope and all `planned-*` effects are proposed/hypothetical. Registered
statuses and reader/control observations are historical records; the mapping of
the explicit incomplete-review statement to an unsatisfied completed-review
requirement is a source-backed derivation. It is not a claim that the standard
does not exist, is currently inaccessible, or that the reader lacks a normative
capability. The source evidence retains its editions and limits. The historical
22A execution base is `1c0b92c68fe1114b926d4405b553dfb096d2f425`, with SBCL 2.5.4;
reading it at the later retention pin is not a new execution.

## Executed checks

[Focused tests](../../dreyeck/tests/topic-maps-conformance-planning.lisp) passed
**195 assertions** with real SHOP3. The native four return values are retained.
Tests inspect the native list-based tree's reduction labels, not a fabricated
tree or a checklist inferred from operator names. They also check:

* A has two plans; B and the explicit missing-prerequisite context each have
  their own distinct method and plan.
* Removing comparison evidence disables only the byte route. Removing normative
  references disables only its route. Removing both leaves no plan.
* Removing required B evidence leaves no plan. Removing the explicit incomplete
  prerequisite observation does not turn unknown into missing: no blocker plan.
* A private method-precondition mutation changes the native result; removing
  the remaining route then exposes no unexpected fallback.
* Every observed input/status remains in final states, only `planned-*` facts
  are added, and unrelated UNSUPPORTED status also remains unchanged. No operator
  records PASS. Original serialized records and pinned source bytes are unchanged.
* All results remain `:plan-only`; raw plans, trees and final states have equal
  counts. Inspector links retain the exact record, source, result, tree and state
  objects. Temporary SHOP3 problems and the private mutant are cleaned up.

The unchanged existing suites also passed: `dreyeck/work/planning/tests`,
`dreyeck/work/defederation-planning/tests`, and
`dreyeck/work/remote-control-planning/tests`. The old documentation example still
reports its fixed-sequence limitation; that is not presented as new adaptive
planning evidence. No old test file was edited.

[test-results.json](test-results.json) records exact commands, exit codes and
source hashes. [focused.log](focused.log) and [regressions.log](regressions.log)
retain outputs. A minimal runner in [run.lisp](run.lisp) verifies source hashes
before/after each run. In a prepared ASDF environment:

```sh
TOPIC_MAPS_EVIDENCE_REPOSITORY=/path/to/topic-maps \
  sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load docs/topic-maps-conformance-planning/run.lisp
CONFORMANCE_TEST_MODE=regressions \
  sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load docs/topic-maps-conformance-planning/run.lisp
```

The actual Cloud commands reuse the existing portable SBCL, prepared dependency
registry and cache; the byte-identical bootstrap is retained for provenance. Its
paths are host-specific, not an installer. New tests do not execute Topic Maps
conformance tests, call a CTM reader, import a model or use Fable's associations.
No additional dependencies were acquired.

Automated evidence is Linux SBCL 2.4.10 / SHOP3 4.3.1 at
`ce53f9b651acde8c44dc21eddb1a1c5b97f10536`. It does not establish macOS behavior,
a full Nix rebuild, interactive CLOG navigation, current conformance, source
authenticity beyond the selected Git objects, or the correctness of a normative
disposition. Nothing is selected or executed on behalf of the operator. Further
investigation, conformance execution and Fable integration require separate work.
