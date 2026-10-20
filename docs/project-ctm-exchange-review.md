# External import of the project CTM: review and open questions

A read-only review, recorded as the assignment `cc-2026-10-20-ctm-exchange-review` on *Implementation Assignments*. It changes no emitter,
vocabulary, Subject Identifier, source page or Work status. It provisionally holds the modelling questions that are open; none of them is
decided here.

## Three kinds of statement

| Kind | What it is | Where |
|---|---|---|
| **Juergen's report** | His import of the project CTM into his own CTM editor, and five remarks he presents under the heading "Claudes Anmerkungen zum Modell". | `docs/exchange/2026-10-20-juergen-ctm-import-feedback.md`, verbatim. The date of his message is not known; the user relayed it on 2026-10-20, together with the image his message refers to. |
| **Claude Code's inspection** | What the project CTM, the emitter and the Work pages show, inspected at commit `306b7fd9`; the project CTM was `db9c5bf1…` then. | the section *Inspection* below |
| **Open questions** | Decisions neither the report nor the inspection makes. | the section *Open questions* below |

**Not received:** Juergen's TMCL schema, which he offers to send. Nothing here compares against it.

## What the report bears on: `pwc-wp-4` and `pwc-wp-7`

`pwc-wp-4` is proposed on *Implementation Assignments* as "Check the project CTM with an independent Topic Maps engine — only the
topic-maps reader of this project has read it so far". No WBS Dictionary entry states its scope or an acceptance criterion.

| Aspect | Status | Provenance |
|---|---|---|
| Import into an independent CTM editor | reported as working ("ok-isch") | Juergen; not observed here |
| Subject Identifiers keep Topic identity across imports | reported | Juergen; it fits the CTM's design, since every Topic has a subject identifier, but it was not observed here |
| Independent CTM/TMDM conformance validation | not reported | an editor's import is not a validation unless it reports conformance |
| Edit, export, re-import and CXTM comparison | not done | the scope of the proposed `pwc-wp-7`, "Compare an external CTM revision item by item" |

**What follows.**
- The report and this review are evidence bearing on the questions of `pwc-wp-4` and `pwc-wp-7`. They deliver neither.
- The assignment names neither package as delivered.
- **Navigation.** In the current Association vocabulary, no Association leads from `pwc-wp-4` or `pwc-wp-7` to this assignment or to this
  document. The assignment reaches the proposed Work Item `project-work-ctm` through *assignment for*, and the packages are reachable from
  there. From a package, the review is not directly reachable.

## Inspection

Each question is classified as presentation, semantics, identity, validation or interoperability. Where the inspection differs from the
report, that is said.

1. **Equal names.**
   - **Topic type and Role type:** `s:kind-work-item` and `s:work-item`, both "work item"; `s:kind-work-package` and `s:work-package`, both
     "work package".
   - **Topic type and Occurrence type:** `s:kind-plan-step` and `s:plan-step-note`, both "plan step"; `s:kind-precondition` and
     `s:precondition`, both "precondition". The report calls all four Role types; for "plan step" and "precondition" the second Topic is an
     Occurrence type.
   - **Case only:** `s:hyperbook` "HyperBook" and `s:hyperbook-role` "hyperbook".
   - **Assessment:** presentation and interoperability. TMDM does not merge Topics by name, and every subject identifier differs.
   - **If changed:** renaming the Role or Occurrence labels changes CXTM and the next export, but no identity or Association.
2. **Relation-specific Role types.**
   - **Constructs:** 32 Role types for the 16 relation types in use: 4 contracts and 12 relation words, matching the report. Each is named
     "source of …" or "target of …", and its description points to the Relation Contract, or says that no contract exists.
   - **Generic roles are not a drop-in replacement.**
     - **Meaning:** one meaning for every source and every target is stated by no contract, and for the 12 uncontracted words it states
       more than the sources do.
     - **Collision:** `s:source`, named "source", already exists: the Role of *reads source*.
     - **Identity:** Role types are part of an Association's identity, so all 57 statement Associations would change in CXTM. The statement
       Topics would reify different Associations, and the read-back trace and the Workspace's direction rule depend on the specific Role
       types.
   - **An additive alternative:** keep them, and declare them subtypes of new generic Role types.
   - **Assessment:** semantics and identity. The current form is a valid model.
3. **Relation words and Relation Contracts.**
   - **Contract relations:** the association type is the declared Work Topic `work/topic/work:relation/<x>` (kind *relation*, status
     *draft*), declared on a Work page. There are 5 such Topics in the project CTM, of which `addresses` is not used.
   - **Relation words:** the association type is `s:relation-word-<slug>`, minted by the emitter from an undeclared `data-relation` word on
     *Work Breakdown*.
   - **Where they are written:** the emitter writes the words and all Role types in the Schema section, and the contract Topics in the
     Topics section, because they are declared content. So an import that takes the Schema section as vocabulary finds the contract types
     in the content. The image shows *depends on* and *decomposes into* as content Topics.
   - **Assessment:** interoperability and authority. A valid choice that encodes authority. Section placement does not change CXTM.
4. **No TMCL.**
   - **What exists:** HyperDoc has none, and the pinned topic-maps has no TMCL implementation.
   - **Derivable from what the emitter guarantees:** Role cardinalities and some Role player types of its own Association types; the
     Occurrence datatype `xsd:string`; patterns for `source-sha256` and for subject identifiers; statement Topics reifying Associations.
   - **Needs authoring decisions:** player types of contract Roles, which exist only in prose (see the next section); cardinalities of
     Work relations; anything about relation words; where TMCL would live and what validates it.
   - **Assessment:** validation.
5. **String datatypes.**
   - **Constructs:** all 484 Occurrences are `xsd:string`.
   - **`issued`** is prose that contains a date ("Given by the user on 2026-10-18 in …"). It is not a date value, so `xsd:date` would need
     a separately authored date.
   - **`source-sha256`** is lowercase hex. `xsd:hexBinary`'s canonical form is uppercase, so a pattern on a string fits better.
   - **The reader:** the pinned topic-maps reader validates `integer`, `decimal`, `date`, `dateTime` and `anyURI`.
   - **Assessment:** validation and interoperability.
   - **If changed:** a datatype is part of an Occurrence's identity, so CXTM and the next export change, but no subject identifier does.

## `decomposes-into`: three senses of "deliverable"

**The contract** (*Authoring the CTM Plan Page*, status draft): "WBS: the target deliverable is part of the source deliverable's scope, and
the targets together are all of it."

**Its uses.** All 13 statements of type `work:relation/decomposes-into` in the project CTM have a source of `data-kind="deliverable"` and a
target of `data-kind="work package"`:
- 5 declared on *Authoring the CTM Plan Page*: `ctm-page-edit` to `ctm-wp-1` … `ctm-wp-5`;
- 8 proposed on *Implementation Assignments*: `project-work-ctm-exchange` to `pwc-wp-1` … `pwc-wp-8`.

**Three senses, kept apart:**
1. **"deliverable" as the general WBS concept.**
   - *Work Breakdown* defines a work package as "One bounded deliverable of the WBS with a stated acceptance criterion".
   - *Authoring the CTM Plan Page* describes "A deliverable-oriented decomposition of the defined scope into verifiable work packages".
   - In this sense, every work package is a deliverable.
2. **`deliverable` as a `data-kind`.** It is used twice, and the project CTM writes it as the Topic type `s:kind-deliverable`.
3. **`work package` as another `data-kind`.** It is used 13 times, and the project CTM writes it as the Topic type `s:kind-work-package`.
   No supertype relation joins it to `s:kind-deliverable`.

**What follows.**
- Read in sense 1, the contract fits all 13 uses. Read with the kinds, its target names a different type than the uses have.
- A player-type constraint derived from the prose with the kind types would reject all 13 uses.
- The claim that "the targets together are all of it" cannot be checked from the data.

**Unresolved.** It is not decided whether the contract means the general concept or the kind. The existing statements are not thereby
incorrect, and the contract and its 13 uses are unchanged.

## Open questions

1. Labels for the Role and Occurrence types that share a name with a Topic type.
2. Whether to declare generic supertypes for the relation-specific Role types. Replacing them is not proposed.
3. Whether to document the Schema/Topics section convention, or also to reference the contract types near the schema.
4. TMCL:
   - its packaging and validator;
   - what "deliverable" means in `decomposes-into`;
   - which contracts state player types;
   - how to compare Juergen's schema once it is received.
5. Datatypes:
   - `statement-number` as `xsd:integer`;
   - whether `issued` should have a separately authored date;
   - a pattern for `source-sha256`;
   - whether *work status* becomes a controlled value.
6. What `pwc-wp-4` requires before it could be decided: a WBS Dictionary entry that defines the check.
7. Whether an assignment should be able to say that it bears on a work package without delivering it. That would need new vocabulary.

## Found while recording this review

An emitter behaviour, recorded and not changed.
- **The behaviour.** When an assignment names a page by its repository path (`data-reads` or `data-changes`), the emitter derives the page's
  title from the file name (`%path-topic` in `dreyeck/work/project/project-ctm.lisp`).
- **The case here.** For *Relation Contract: informs*, stored as `Relation Contract informs.html`, both slug to the same subject identifier,
  so the existing page Topic would gain a second name and a second, wrong *page id*, "Relation Contract informs".
- **How it is avoided.** This assignment therefore names that page without a path. As a consequence, the project CTM has no *reads source*
  Association from this assignment to *Relation Contract: informs*: the source authority is kept as text only, and the Workspace offers no
  edge to it.
- **Still open.** Whether the emitter should look the page up by its HyperBook instead.
