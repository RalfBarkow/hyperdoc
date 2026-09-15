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
- `:INVOKES`

These relations are observations, not editorial decisions. Source-derived
relations carry warrants identifying the evidence from which they were
obtained.

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
by removal. KEEP means a retention edge survives this particular cut; it does
not mean the retained object can never be removed.

## Executable Catalog example

Open **HyperBook Catalog → Upstream Intake → Upstream Intake as a Read-Only
Observation**, then choose **Inspect the hypothetical commit-page removal**.

The named DEFEXAMPLE, `UPSTREAM-INTAKE-REMOVAL-WORKSPACE-EXAMPLE`, returns an
actual Topicmap Workspace. It calls MAKE-REFERENCE-WORKSPACE, then
MAKE-IMPACT-WORKSPACE with HYPERDOC-REMOVAL-IMPACT. The private reading helper
UPSTREAM-INTAKE-CURATION-INPUTS supplies a bounded inventory and contract
set matching the focused curation witness.

The Workspace point is
`page:dreyeck/upstream-intake/Observing an Upstream Commit`. Its eight impact
associations describe removal of the page and its HTML, edits to the component
page, overview and expected-page set, revision or deletion of two test
contracts, and retention of the host-not-found example through the surviving
Overview link.

Ordinary Catalog loading registers the example without executing its
hypothetical analysis. Clicking the action performs read-only observation.
No additional server, renderer, authoring environment, or remote access is
required.
