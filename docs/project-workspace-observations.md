# Project Workspace: observed navigation

Observed on 2026-10-19 on commit `d089efe8`, in the native Workspace of the HyperDoc Project Workspace (system `dreyeck/work/project`, topic-maps
`5a4a668`), by moving the Point along the Associations at each Topic. These are observations of what the project CTM states; none of them changes
it, and none adds a relation. What would close a gap is a decision on the authoritative pages, not a change of the emitter.

## Assignment → evidence and result: modelled

At the Point `assignment/cc-2026-10-19-topic-maps-reader-scaling` (the reader-performance assignment):

- *declared on* the page Implementation Assignments; *assignment for* the proposed Work Item `project-work-ctm`; *assignment delivers* `pwc-wp-8`;
  *changes source* `dreyeck/work/project/project-workspace.lisp`; *evidenced by test* `dreyeck/tests/project-ctm.lisp`; the derived gap
  *assignment without Plan Step*.
- As occurrences of the assignment: goal, preconditions, acceptance criteria, the observed state reported by the executor, "No acceptance by the user
  is recorded", and the evidence entries as authored, among them the topic-maps commit `5a4a668`, its suite results and the timings.

## Work package `pwc-wp-8` → evidence and result: not directly modelled

At the Point `pwc-wp-8` the Associations are *proposed on* Implementation Assignments, *carried by* the page HyperDoc Project Workspace,
*decomposes into* from `project-work-ctm-exchange` (proposed) and *assignment delivers* from the assignment above. The package has no status (it is a
proposal) and no Association to a test, a result or evidence. Evidence is reachable only through the assignment that delivers the package.

This is how the sources state it: the page Implementation Assignments names evidence in an assignment's `evidence` list, and a proposed work package
has no evidence field. The project CTM does not transfer the assignment's evidence to the package and does not assert a package-to-evidence
relation. Whether a work package should carry evidence of its own, or whether evidence belongs to the assignment that delivers it, is an open decision
of the project model.

## Further observations on the same walk

- A test file is a Topic named by its repository path. Its Point panel links the pathname; there is no Topic for a test run or its result, and the
  topic-maps commit `5a4a668` is authored text on the assignment, not a Topic of its own.
- A page that is only a carrier (for example *Topicmap Interaction Documentation*, the carrier of the Work Item `topicmap-interaction-documentation`)
  is classed *source* in the Point panel, as the four source pages are, and its panel links no HyperDoc page object; a source page's panel does.
- The Work Item `ctm-plan-page-authoring` reaches its carrier page *Authoring the CTM Plan Page*, and from there its Deliverable, work packages, plan
  steps and preconditions. The Item edit objects (proposal, preview, completion) of the separate CTM Page Authoring Catalog have no identity in the
  project CTM; the bridge between the two is the carrier page and the Work Topic ID `ctm-plan-page-authoring`, which both the Work Breakdown's own
  Workspace and the Project Workspace use as the key of that Work Item.
