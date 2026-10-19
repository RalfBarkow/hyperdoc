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

# Observed on commit 29af527f: the synthetic S3 scenario in the browser

On 2026-10-19, a disposable image served the native Workspace of the synthetic scenario S3 through `clog-moldable-inspector:clog-inspect` on
`http://127.0.0.1:18791/inspector` (HyperDoc `29af527f`, topic-maps `5a4a668`, `--no-userinit`). Before the Inspector was opened, the Point
was set to `synthetic-wp-1` in Lisp; every later move was a click in the browser. Nothing here changes the Workspace, the project CTM or the
acceptance model.

Each statement is labelled with where it comes from:

| Label | Meaning |
|---|---|
| **Browser, S3** | Seen in that browser session. |
| **Earlier, d089efe8** | Observed in the walk recorded above, not repeated in the browser session. |
| **Lisp/CTM** | Read from the S3 Topic Map or from the Lisp tests and walks of S3, not from the browser. |
| **Code** | Read from the source or the pages at the cited lines. |
| **Inference** | Concluded from the above or from the commits since `d089efe8`; not observed at runtime. |

## 1. Browser interaction: Point and History

*Browser, S3.*
- **Signs move the Point.** Clicking the sign *SYNTHETIC package one* in the Topicmap drawing moved the Point there. The Point section then
  showed its Acceptance section.
- **Association rows move the Point.** Clicking the right-hand label of a row in the Associations table under *Point* moved the Point to that
  end. The walk went:
  - *SYNTHETIC package one*
  - *SYNTHETIC synthetic-record-2*
  - the criterion revision `sha256-bd81f3b6…`: current, the 10 s text
  - *SYNTHETIC synthetic-record-2*
  - *SYNTHETIC synthetic-record-1*, by the row *supersedes*: accepted, applied criterion retained
  - the criterion revision `sha256-12a68b2f…`: retained, the 30 s text, applied by record 1
- **History.** The Workspace's *Slots* tab showed `point` and `history`, most recent first, and the History listed that walk in order.
- **Moves made outside the walk.** Before the walk, History already held five Points that the person driving the walk had not visited by
  click in that image: `state-and-persistence`, `ctm-plan-p3`, `authoring-the-ctm-plan-page`, `assignment/synthetic-assignment-1` and
  `relation-contract-informs`. The page also held a pane on a *project-topic* and one on the string `assignment/synthetic-assignment-1` that the
  walk did not open. What made these moves is not established.

*Browser, S3: limitations.*
- **The drawing.** It has 174 signs, scaled into the pane at about 67 by 19 pixels each, and it has no search or jump-to control. Reaching a
  Topic means scrolling the drawing to its row.
- **No Back control.** History is shown only as the slot `history` on the *Slots* tab.
- **A mis-click.** One click on a row did not move the Point: the button had been measured before the view scrolled.
- **Untested buttons.** The buttons inside the Point panel's Acceptance, Record and criterion sections were not clicked in the browser.

*Lisp/CTM.* Of those panel buttons, the Lisp tests press only the criterion section's two, to the package and to a record, through the thunks
the view renders.

*Code.*
- A sign's overlay is a transparent rectangle with `data-presentation='WORKSPACE-GO-TO'` whose action calls `topicmap-workspace-go-to`
  (`dreyeck/src/topicmap-inspector.lisp:234`).
- An Association row's label is an action button with the title *Go to …* (`dreyeck/src/topicmap-inspector.lisp:494`).

*Inference.* Both controls move the Point of the one Workspace object the Inspector was opened on, so every window on that object shows the
same Point.

## 2. Test file, execution report and actual execution

*Browser, S3.* At record 2, the Point panel listed its considered evidence:
- `synthetic-assignment-1/synthetic-run-1`, with its observation, revision, clean tree and "reconstructible from the tested revision";
- `synthetic-assignment-1/synthetic-run-2`, with its observation, revision, modified tree and "not fully reconstructible from the recorded
  revision".

*Lisp/CTM.*
- **Types.** In the S3 Topic Map, `file/dreyeck/tests/project-ctm.lisp` is a *Repository file*, while `evidence/synthetic-assignment-1/
  synthetic-run-1` and `…-run-2` are *Test execution reports*.
- **The reports' content.** Each report reifies the assignment's evidence occurrence and carries a source repository, tested revision, tree
  state, observation and time.
- **The link.** An Association *reports execution of* leads from each report to the file.

*Code.*
- **The productive project.** `dreyeck/pages/project/Implementation Assignments.html` has no `data-evidence` (checked by
  `productive:existing-evidence-entries-are-not-retrofitted`). So the project CTM identifies no evidence entry and has no execution report
  Topic.
- **The topic-maps commit `5a4a668`** is authored text in the assignments' evidence and observed-state entries, not a revision Topic.

*Inference.* Three identities are kept apart, and the third has none:

| | Answers | Represented by |
|---|---|---|
| The test program | which file? | the file Topic |
| The execution report | who reports which result under which conditions? | an identified evidence entry, as in S3; the CTM states only that the executor reported the run |
| The actual execution | which event can be shown independently? | no Topic; nothing in the project CTM checks a report against a run, and no output log is retained |

The earlier observation "there is no Topic for a test run or its result" holds for the project CTM, whose sources identify no evidence
entry. It does not hold for a CTM whose sources identify evidence entries, as S3 shows.

## 3. Carrier page, source authority and inspectable page object

*Earlier, d089efe8* (see "Further observations on the same walk" above), not repeated in the browser session:
- A carrier page such as *Topicmap Interaction Documentation* is classed *source* in the Point panel, as the four source pages are.
- A source page's panel links its HyperDoc page object; a carrier page's panel links none.

*Browser, S3.* The panel of `synthetic-wp-1` showed "Declared on NIL".

*Code.*
- **"source" is a fallback.** It is the remaining case of a classification (`dreyeck/work/project/project-workspace.lisp:304–307`): a Topic
  is *proposed* if it plays *proposal* in *proposed on*, *declared* if it plays *declaration* in *declared on*, *derived* in the layer *Plan
  gap*, and *source* otherwise.
- **The page link.** `%source-objects` (`:545`) links a page object only for a page in the sources that were read (`:552`).
- **The fixture source.** The S3 Work source is a test fixture with no HyperBook page object, which accounts for "Declared on NIL".

*Inference.* The class *source* does not mean that a page is one of the four `+sources+` of the project CTM. Three properties are distinct,
and the panel shows only part of them:
1. The page carries a Work declaration.
2. The page is represented in the project CTM.
3. The page is reachable in the Inspector as a HyperDoc page object.

Whether the class *source* for a carrier page is intended or a defect in the presentation is not decided here.

## 4. CTM Page Authoring and the project CTM

*Earlier, d089efe8* (see "Further observations on the same walk" above):
- The Work Topic ID `ctm-plan-page-authoring` keys the Work Item in both the CTM Page Authoring Workspace and the Project Workspace, and its
  carrier page connects the two.
- The Item edit objects of the CTM Page Authoring Catalog have no identity in the project CTM: its proposal, preview and completion.

*Inference*, from the commits since `d089efe8` (`886da3f9`, `cbc13d99`, `29af527f`); this was not observed again at runtime:
- **The project CTM.** No changed line of the project CTM mentions `ctm-plan-page-authoring`.
- **The Item edit systems' own files are unchanged.** No commit changed the implementation files of `dreyeck/ctm-page-authoring` or of the
  item-edit proposal, preview and execution systems: `dreyeck/work/item-edit-proposal`, `dreyeck/fedwiki-item-edit-preview` and
  `dreyeck/fedwiki-item-edit-execution`.
- **A dependency of theirs changed.** `dreyeck/work/item-edit-proposal` depends on `dreyeck/work/reading` (`dreyeck.asd:1625`). `cbc13d99`
  changed `dreyeck/work/ctm-plan-page-authoring.lisp` in that system, in the WBS Dictionary reader only, to read retained criteria. Unchanged
  implementation files therefore do not imply unchanged behavior of the systems that depend on it.
- **Other changes.**
  - one of the four source pages, *Implementation Assignments*, by an added assignment;
  - the wording of *Item Edit Path in HyperDoc*;
  - `docs/ctm-page-authoring-review.md`.
- **Test evidence after that change**, not a runtime observation of proposal, preview or completion. The suites ran on the working tree that
  became `cbc13d99`, which then differed from the commit only in the text of the draft page *Acceptance Records*:
  - `dreyeck/work/reading/tests` passed, including CTM-PLAN-PAGE-AUTHORING-PASS and ITEM-EDIT-VIEW-DIAGNOSIS-PASS;
  - `dreyeck/ctm-page-authoring/tests` passed, CTM-PAGE-AUTHORING-DOCUMENTATION-PASS with 178 checks;
  - `dreyeck/item-edit-ctm` passed, ITEM-EDIT-CTM-PASS with 209 checks.

  `29af527f` changed none of these systems.
- **So** the two observations above are expected to hold on `29af527f` as far as the project CTM and these tests show. Neither was observed
  again at runtime.

*Scope.* The project CTM does not need to hold every runtime object of another Workspace. What remains open is whether an Acceptance Record
could later name the edit results its decision depends on without copying them into the project CTM. Put more generally: which identities
and references must hold across HyperDoc Workspaces for a decision to be reconstructed and checked? That question is not answered here, and
nothing in this document changes the acceptance model.
