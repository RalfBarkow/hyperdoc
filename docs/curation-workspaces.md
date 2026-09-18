# Curation Workspaces

A curation workspace turns observed structural references into an explicit,
read-only account of the consequences of a hypothetical editorial change.

The facility has two layers.

## Reference workspace

`DREYECK/HYPERDOC/CURATION:MAKE-REFERENCE-WORKSPACE` observes a HyperDoc page
together with a bounded source inventory and explicitly declared source
contracts.

It produces a `DREYECK/TOPICMAP:TOPICMAP-WORKSPACE`. Its projection contains
topics for pages, source files, Lisp definitions, expressions, and other
observed objects. Associations represent structural evidence such as:

- `:LINKS-TO-PAGE`
- `:SOURCE-OF-PAGE`
- `:ASSERTS-PAGE-PRESENCE`
- `:ASSERTS-NAVIGATION`
- `:TESTS-PAGE`
- `:EXPOSES-EXECUTABLE-LINK`
- `:PRESENTS-SOURCE-OF`
- `:INVOKES`

These relations are observations, not editorial decisions. Source-derived
relations carry warrants identifying the evidence from which they were
obtained.

A `source-of-function` element contributes `:PRESENTS-SOURCE-OF` from its
page to one uniquely resolved inventoried `DEFUN` or `DEFEXAMPLE`. This is
source presentation, not execution. Its warrant preserves the HTML pathname,
exact character span and original element text, plus the resolved Lisp
source record's CST warrant. Plump performs the parsing; comments and script
text do not become source-view references. Unresolved or non-function names
remain diagnostics, without guessed edges.

Contract declarations select bounded source structures to inspect. They are
not themselves evidence. A declared contract is rejected when the expected
CST structure cannot be demonstrated.

## Impact workspace

`DREYECK/TOPICMAP/CURATION:MAKE-IMPACT-WORKSPACE` derives a second workspace
from a reference workspace.

The generic curation layer knows nothing about HyperDoc relation names. A
domain policy interprets reference relations. For HyperDoc page removal that
policy is:

`DREYECK/HYPERDOC/CURATION:HYPERDOC-REMOVAL-IMPACT`

The policy returns a hypothetical cut, policy findings, and retention edges.
The generic layer verifies that evidence refers to warranted reference edges
and materializes the findings as impact associations.

An impact workspace is explicitly hypothetical:

    :HYPOTHETICAL T
    :AUTHORIZATION :NONE

It therefore describes consequences without authorizing or performing source
changes.

The current impact vocabulary includes:

`REMOVE`
    The explicitly selected object belongs to the hypothetical cut.

`REMOVE-WITH-PAGE`
    An object, currently the page source file, belongs to the cut together
    with the page.

`MUST-EDIT`
    A surviving object contains an incoming reference that would become
    invalid after the cut.

`MUST-EDIT-OR-DELETE`
    A structural contract or test refers to the removed page and must either
    be revised or disappear with the functionality it specifies.

`KEEP`
    An object loses a retention edge through the cut but has another surviving
    warranted retention edge.

`REVIEW-FOR-ORPHANING`
    An object loses its known retention edges and therefore requires an
    editorial decision.

Impact associations have epistemic status `:MECHANICALLY-DERIVED`. Their
warrants identify the policy rule and the reference edges from which the
finding was derived.

## Point identity

A workspace point is a topic ID, not its display label.

For example:

    topic ID:
      page:dreyeck/upstream-intake/Observing an Upstream Commit

    label:
      Observing an Upstream Commit

`MAKE-IMPACT-WORKSPACE` can use the point already stored in the reference
workspace. Passing the display label as `:TARGET` is incorrect.

## What the Inspector shows

The Topicmap Inspector is a view of this decision object. The layout is not
source truth. In particular, a dense graph may be visually unhelpful.

The semantically relevant parts are:

1. the current Point;
2. the impact Associations;
3. the warrant carried by each association;
4. navigation from an affected topic back to the reference evidence.

The workspace is useful when it makes the consequences of an editorial
operation inspectable before any source mutation occurs.
## Editorial interpretation

A MUST-EDIT finding is an obligation only if the referring object survives the
intended editorial cut. If that object is also removed, its edit is subsumed
by removal. Source presentation, executable links and recognized direct calls
are retention evidence; a source view inside a removed page is not itself a
MUST-EDIT finding. KEEP means a retention edge survives this particular cut; it does
not mean the retained object can never be removed.

## Executable Catalog example

Open **HyperBook Catalog → Upstream Intake → Upstream Intake as a Read-Only
Observation**, then choose **Inspect the hypothetical commit-page removal**.

The named DEFEXAMPLE, `UPSTREAM-INTAKE-REMOVAL-WORKSPACE-EXAMPLE`, returns an
actual Topicmap Workspace. It calls MAKE-REFERENCE-WORKSPACE, then
MAKE-IMPACT-WORKSPACE with HYPERDOC-REMOVAL-IMPACT. The private reading helper
UPSTREAM-INTAKE-CURATION-INPUTS supplies a bounded inventory and contract
set matching the focused curation witness.

The Reference Workspace discovers the current five HTML pages from the book;
there is no separate Curation page list. PAGE identity is `page:<book-id>/<page-id>`;
HTML-SOURCE identity is `file:<pathname>`. Labels are presentation values. In
particular, the Page Loading title contains a colon while its HTML filename
uses ` - `; filenames must not be synthesized from page labels.

The example's point remains
`page:dreyeck/upstream-intake/Observing an Upstream Commit`. Fresh derivation
now produces these nine associations:

| Status | Affected topic |
| --- | --- |
| REMOVE | Observing an Upstream Commit |
| REMOVE-WITH-PAGE | Observing an Upstream Commit.html |
| MUST-EDIT | An Upstream Supersession Hypothesis |
| MUST-EDIT | Upstream Intake as a Read-Only Observation |
| MUST-EDIT | +UPSTREAM-INTAKE-PAGE-SPECS+ |
| MUST-EDIT-OR-DELETE | CHECK-PAGE-NAVIGATION |
| MUST-EDIT-OR-DELETE | RUN-HYPERDOC-PAGE-TESTS |
| KEEP | HYPERDOC-HOST-NOT-FOUND-UPSTREAM-INTAKE-EXAMPLE |
| KEEP | MAKE-HYPERDOC-HOST-NOT-FOUND-INTAKE |

Adding the fifth page alone left the previous eight-finding cut unchanged.
Recognizing source presentation adds the ninth finding: the Commit page
presents `MAKE-HYPERDOC-HOST-NOT-FOUND-INTAKE`, which retains a warranted call
from the host-not-found example after this cut. The example itself retains
the Overview's executable link.

The second durable witness uses point
`page:dreyeck/upstream-intake/HyperDoc Page Loading: Source Ahead of the Running Image`
and produces these ten associations:

| Status | Affected topic |
| --- | --- |
| REMOVE | HyperDoc Page Loading: Source Ahead of the Running Image |
| REMOVE-WITH-PAGE | HyperDoc Page Loading - Source Ahead of the Running Image.html |
| MUST-EDIT | Upstream Intake as a Read-Only Observation |
| MUST-EDIT | +UPSTREAM-INTAKE-PAGE-SPECS+ |
| MUST-EDIT-OR-DELETE | CHECK-PAGE-NAVIGATION |
| MUST-EDIT-OR-DELETE | RUN-HYPERDOC-PAGE-TESTS |
| REVIEW-FOR-ORPHANING | HYPERDOC-PAGE-LOADING-COMPARISON-EXAMPLE |
| REVIEW-FOR-ORPHANING | HYPERDOC-PAGE-LOADING-IMAGE-STATE-EXAMPLE |
| REVIEW-FOR-ORPHANING | HYPERDOC-PAGE-LOADING-SOURCE-STATE-EXAMPLE |
| REVIEW-FOR-ORPHANING | HYPERDOC-PAGE-LOADING-CHECKPOINT-EXAMPLE |

The reader test reuses `CHECK-PAGE-EXECUTABLE-CONTRACT`, allowing the existing
lexical recognizer to derive `:TESTS-PAGE` and `:ASSERTS-EXPRESSION-TEXT`.
The exact three-source-reference list and backlink remain separately checked.
The orphan-review findings mean no surviving retention edge was demonstrated
by the bounded projection, not that the functions are globally unused. No
stronger call-graph claim or deletion authorization follows.

The Curation tests compare exact status/topic sets for both points and verify
that source and impact warrants refer to the actual evidence. The runtime
example and tests share `UPSTREAM-INTAKE-CURATION-INPUTS`.

Ordinary Catalog loading registers the example without executing its
hypothetical analysis. Clicking the action performs read-only observation.
No additional server, renderer, authoring environment, or remote access is
required.
