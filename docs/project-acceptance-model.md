# Work package, evidence and acceptance: the model

Decisions D1–D6, approved by the user on 2026-10-19, implemented in the working tree on synthetic fixtures. Recorded as the assignment
`cc-2026-10-19-acceptance-model-draft` on *Implementation Assignments*, which delivers the proposed work package `pwc-wp-6` ("A record of
acceptance, distinct from work status").

- No acceptance has been recorded: the project CTM states none.
- The two draft pages, *Project Work Exchange WBS Dictionary* and *Acceptance Records*, are not sources of the project CTM. Making them sources
  is the user's decision and is not part of this model.
- Everything below is shown on synthetic fixtures in `dreyeck/tests/fixtures/project-acceptance/`, read in memory by
  `dreyeck/tests/project-ctm.lisp`. Nothing there is anyone's decision.

**Definition.** An Acceptance Record records a decision about a **declared** Work Package. The decision is evaluated against an
**identifiable revision** of that package's acceptance criterion and against **identifiable observed evidence**. The model can then explain why a
package is accepted, rejected or undecided, from the criteria and evidence available to that decision.

## Three things, kept apart

| Thing | Authority (page) | In the project CTM |
|---|---|---|
| Work package: acceptance criterion and **required** evidence | a declared WBS Dictionary | the package Topic; occurrences *WBS acceptance criterion*, *WBS evidence*; controls *exercised by* tests |
| Implementation assignment: **reported** evidence and result | *Implementation Assignments* | the assignment Topic; occurrences *evidence*, *observed state*; identified *evidence entries* and *test execution reports* |
| Acceptance record: decision, deciding authority, applied criterion revision, considered evidence | an *Acceptance Records* page | *Acceptance record* and *Withdrawal record* Topics |

None of the following is an acceptance:
- a passed test;
- a completed assignment;
- a work status, for example `ctm-wp-1`'s `verified`, which stays an occurrence of its declaration;
- an evidence entry.

Required evidence is never written as observed evidence. An assignment's evidence is never transferred to the package it delivers.

## D1. Criterion revisions

**Two identities.**
- **The work package** keeps `work/topic/<package>`, independent of any criterion.
- **A criterion revision** is `criterion/<package>/sha256-<hex>`. The hex is the SHA-256 of the UTF-8 octets of the criterion's occurrence value:
  the string the dictionary reader extracts, with entities decoded and the ends trimmed. That is the value a TMDM reader of the CTM gets back.
  - Equal text means the same revision; any edit, even of whitespace, means a new revision.
  - A consumer of the CTM can check every revision identifier from the CTM alone.

**Current and retained.** The dictionary entry states exactly one current criterion. It keeps every earlier text it replaced in a retained list:

```html
<p data-field="acceptance">the current criterion</p>
<ul data-field="retained-acceptance"><li>a criterion this entry stated before</li></ul>
```

- **In the CTM:** the current criterion is the occurrence *WBS acceptance criterion*, as before. A retained one is an occurrence of
  *retained WBS acceptance criterion* on the same package.
- **Reification:** when a record applies a revision, the revision Topic, of type *WBS criterion*, reifies the occurrence that states its text.
  Every revision Topic reifies exactly one occurrence; this is the existing TMDM reification semantics, and no scope is used.
- **When the criterion changes:** the revision Topic keeps its identifier and reifies the retained occurrence instead.

**Explicit, never implied.** A record names its revision: `data-revision="sha256-<hex>"`. The emitter never resolves a record to "the current"
criterion. A changed criterion therefore changes neither the identity nor the applied text of an earlier decision.

**Refused, not completed:**
- a record whose revision the entry neither states nor retains (how a change without retention is caught);
- a retained text equal to the current one, since one Topic would then reify two occurrences;
- a retained text stated twice.

The dictionary reader `read-wbs-dictionary` (`dreyeck/work/ctm-plan-page-authoring.lisp`) reads the retained list. The CTM plan page reading uses
only the current criterion.

## D2. Observed evidence

| | Identity | What it is | Can a record consider it? |
|---|---|---|---|
| Test source file | `file/<path>`, *Repository file* | A program. It proves no run. | no |
| Test execution report | `evidence/<assignment>/<entry>`, *Test execution report* | The executor's report of one run | yes |
| Evidence entry | `evidence/<assignment>/<entry>`, *Evidence entry* | One prose entry of an assignment's evidence | yes |
| Assignment | `assignment/<id>` | The whole report | no |

**Identity.** An entry is identified only by an authored `data-evidence` ID, unique within its assignment. An ID is never derived from position.

**In the CTM.** The entry Topic **reifies** the assignment's existing *evidence* occurrence, so there is no second copy of the text.
- Two identified entries of one assignment with the same text would be one TMDM occurrence with two reifiers, so this is refused.
- Entries without an ID stay plain *evidence* occurrences, exactly as before.

**Execution facts.** An execution report states the facts of its run:

```html
<li data-evidence="ENTRY" data-test="PATH IN ITS REPOSITORY" data-repository="REPOSITORY" data-revision="COMMIT"
    data-tree="clean|modified" data-content="IMMUTABLE CONTENT REFERENCE (optional)"
    data-observation="THE OUTPUT AS OBSERVED" data-observed-at="YYYY-MM-DDThh:mm:ssZ">the entry as written</li>
```

These become the occurrences *source repository*, *test path*, *tested revision*, *tree state*, *content reference*, *observation* and *observed
at*. The emitter also writes *reconstruction*, derived from the tree state:

| Tree state | Reconstruction |
|---|---|
| `clean` | "reconstructible from the tested revision" |
| `modified` with a content reference | "reconstructible from the content reference, not from the tested revision alone" |
| `modified` without one | "not fully reconstructible from the recorded revision: the tree was modified and no immutable content reference is recorded" |

*Reports execution of* (Roles *execution report*, *test file*) links a report to the test's file Topic when the repository is this one
(`codeberg.org/rgb/hyperdoc`). For any other repository, the path stays an occurrence.

**What the CTM states.** It never states that a run happened, only that the executor reported one.

**Refused:**
- an incomplete report;
- a tree state other than `clean` or `modified`;
- a content reference on a clean tree;
- run facts without `data-test`;
- run facts on an entry without an ID.

**History.** Existing entries are not retrofitted in this slice; none has an ID, so the project CTM is unchanged.
- Adding an ID to a historical entry is allowed, because it identifies and adds nothing.
- Adding execution facts to an old report is not allowed.

## D3. Lifecycle

**Append-only.** A record is never edited or removed, and a correction supersedes:

```html
<ul data-field="supersedes"><li data-record="EARLIER-RECORD-ID">why</li></ul>
```

*Supersedes* (Roles *superseding record*, *superseded record*): the superseded record stays, with its decision and its applied revision.

**Refused:** a superseded record that
- does not exist;
- is the record itself;
- decides another work package;
- appears later on the page.

Page order rules out cycles.

**Withdrawal.** A corrective record, not a judgment:

```html
<p data-field="disposition" data-disposition="withdrawn">…</p>
```

- It is a *Withdrawal record*, linked by *withdrawal* (Roles *withdrawal record*, *work package*, *deciding authority*).
- It must supersede at least one earlier record of the same package.
- It names no criterion and considers no evidence, so it asserts no criterion satisfaction. Either of them is refused on a withdrawal.

**Effective decision.** For a declared package, take the set **U** of its records that no record supersedes. `decided-at` never selects
anything.

| U | Effective decision | Derived gap |
|---|---|---|
| no record at all | none | *acceptance not recorded* |
| one judgment | that judgment | none, or *decision under a retained criterion* if its revision is retained |
| one withdrawal | none | *acceptance withdrawn* |
| two or more records, withdrawals included | none | *acceptance records in conflict*, concerning the package and every record in U |

The CTM does not state the effective decision itself. It states the records, their *supersedes* and the gaps. The Project Workspace computes the
explanation from the read-back Topic Map, and the tests check that it agrees with the emitter's gaps.

**Append-only check.** A test compares two CTMs: every record Topic block, and every Association line naming a record, of the earlier CTM must
be in the later one unchanged.
- It runs against the committed CTM at `HEAD`, where it passes vacuously because there is no record.
- It runs between synthetic snapshots, with positive controls for a removed record and for an edited one.

## D4. Decision authority

**Declared, not authenticated.**
- An Acceptance Records page declares authorities (`authority/<id>`, *declared on* the page), and a record names one as *deciding authority*.
- The CTM states that claim and nothing more. An authentication would be a separate statement about a record, never a change of it.

A dictionary's `authority` field is the authority to carry out the work, not to accept it.

**No executor report creates acceptance.**
- Only a source of kind *acceptance records* states records.
- `data-acceptance-record`, `data-decision` or `data-disposition` on any other source is refused.
- An executor never writes a record. This is a process rule, controlled by the user's commit approval; the CTM cannot enforce it.

## D5. Declared work packages only

A record must name a package that a source **declares** (`data-topic`, not a proposal), with an entry in a **declared** dictionary. A proposed
package, or a criterion that is only *proposed in dictionary*, is refused.

A proposed entry stays a proposed requirement, with the gap *acceptance requires declaration*.

A declared dictionary's entry must itself name a declared package.

## D6. One model for all packages

**One records page.** One Acceptance Records page decides packages from any number of declared WBS Dictionaries.
- Every dictionary of kind `:dictionary` is declared.
- An entry ID stated by two dictionaries is refused.
- `ctm-wp-1` to `ctm-wp-5` are decidable as their dictionary stands, once a records page is a source.

**The drafts.**
- `pwc-wp-8`'s draft entry stays a non-binding draft.
- There are no entries for `pwc-wp-1` to `pwc-wp-7`.

## Vocabulary

Written only when a source needs it. The project CTM, with its four sources, contains none of it.

| | Subject identifiers | Names |
|---|---|---|
| Topic types | `schema/acceptance-record`, `schema/withdrawal-record`, `schema/authority`, `schema/wbs-criterion`, `schema/evidence-entry`, `schema/test-execution-report` | Acceptance record, Withdrawal record, Authority, WBS criterion, Evidence entry, Test execution report |
| Association types (Roles) | `acceptance-decision` (acceptance-record-role, work-package, applied-criterion, deciding-authority); `withdrawal` (withdrawal-record-role, work-package, deciding-authority); `considers-evidence` (acceptance-record-role, considered-evidence); `supersedes` (superseding-record, superseded-record); `reports-execution-of` (execution-report, test-file); `proposed-in-dictionary` (work-package, source-page) | |
| Occurrence types | `decision`, `decided-at`, `retained-wbs-acceptance-criterion`, `source-repository`, `test-path`, `tested-revision`, `tree-state`, `content-reference`, `observation`, `observed-at`, `reconstruction` | |
| Gap rules | `acceptance-not-recorded`, `acceptance-records-in-conflict`, `acceptance-withdrawn`, `decision-under-retained-criterion`, `acceptance-requires-declaration` | |

Also:
- **Instance identifiers:** `acceptance/<record>`, `authority/<id>`, `criterion/<package>/sha256-<hex>`, `evidence/<assignment>/<entry>`.
- **Unchanged:** no existing subject identifier, occurrence or Association changes, and `acceptance-not-recordable` stays as it is.

## Synthetic example

The fixtures declare `synthetic-wp-1` and `synthetic-wp-2` in one dictionary and `synthetic-wp-3` in a second one. `synthetic-wp-p` is only
proposed. The two criterion texts of `synthetic-wp-1` are:
- C1 "SYNTHETIC acceptance criterion: the synthetic result is read within 30 s.", `sha256-12a68b2f…091b0d`;
- C2 "…within 10 s.", `sha256-bd81f3b6…57bb0e2`.

| Scenario | Dictionary / records | `synthetic-wp-1` |
|---|---|---|
| S1 | C1 / record 1 accepts against C1, considering run 1 | accepted, by record 1 |
| S2 | C2, C1 retained / the same records | accepted, by record 1, under the retained C1 |
| S3 | C2 / record 2 rejects against C2, considering run 2, and supersedes record 1 | rejected, by record 2; record 1 and its C1 still readable |
| conflict | C2 / records 1 and 2, no supersession, record 2 later | undecided: conflict |
| withdrawn | C2 / record 1, then a withdrawal superseding it | undecided: withdrawn |
| withdrawal conflict | C2 / record 1; record 2 supersedes it; a withdrawal also supersedes it | undecided: conflict |

In every scenario, `synthetic-wp-2` has no record (undecided, not recorded), and `synthetic-wp-3` is accepted from the second dictionary.

The test files in `dreyeck/tests/fixtures/project-acceptance/` are the full pages. `dreyeck/tests/project-ctm.lisp` reads each scenario back
through CTM, TMDM and CXTM. It then checks:
- that the applied criterion of each historical record is reconstructed;
- that the record blocks are identical across S1, S2 and S3;
- the refusals;
- the native Workspace navigation along the new Associations and reifications.

## Inspecting a decision

**The Project Workspace explains each decision from the read-back Topic Map.**
- **In the Overview:** for every package of a declared dictionary, its state and why (`explain-acceptance`, `record-explanation` and
  `evidence-explanation` in `dreyeck/work/project/project-workspace.lisp`).
- **In the Point panel of a package:** the record in force and the criterion revision it applied, current or retained, with its text. Then the
  evidence entries it considered, with their reported facts and reconstruction, and every record on the package, marked superseded or
  unsuperseded.
- **Navigation:** the Point moves along the new Associations. A Topic that reifies an occurrence (a criterion revision, an evidence entry) is
  drawn with an edge *reifies (…)* to that occurrence's Topic. That edge is presentation of TMDM reification, not an Association of the map.

## Limits

- **Authentication** is not modelled: a declared authority is a claim (D4).
- **Run logs** are not retained: a report's observation is the executor's statement, and the emitter does not check it against an output.
- **The append-only check** compares emitted text. A change in how the emitter renders would need the check updated with it.
- **No browser test of the synthetic scenarios.** Navigation in them is tested on the native Workspace model (Point, History, Point panel) in
  Lisp. The browser test covers the productive project CTM only.
- **Unchanged sources.** The page *Implementation Assignments* is not updated for this slice, so that the project CTM stays as it is. Its entry
  `cc-2026-10-19-acceptance-model-draft` does not list the files this slice adds or changes, among them the shared dictionary reader
  `dreyeck/work/ctm-plan-page-authoring.lisp` and the new fixtures.
