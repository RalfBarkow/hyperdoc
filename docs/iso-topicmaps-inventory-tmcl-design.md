# Topic Maps implementation inventory and first schema design

This is a source-grounded investigation and application-schema proposal, not
a conformance certificate, TMCL implementation or validator. No TMCL schema
is asserted to conform to ISO/IEC 19756:2011.

## Observed sources and authority

Observed target `dreyeck.ch`: `573fe37611a61d984260ebf43c797f7534211bdd`.
The starting checkout was clean on independent PR #1's branch at
`0484a4b76128c3ed302a6a8d6e0343bfe03cece5`. This task branches directly from
the observed target as `codex/iso-topicmaps-inventory-tmcl-design`; it neither
merges nor modifies PR #1. Topic Maps reference:
`88994c1b9e1edbf13e665e984a5c9c3b2cdf7575` in a separate repository.

The Work Breakdown declares Work. The CTM plan page declares its WBS/plan,
and its Dictionary states requirements, not permission. Implementation
Assignments authors proposals and executor reports. The project CTM is a
deterministic derivative of those four pages; its Inspector projection is not
another authority. This report and its reading page are investigations, not
new authoritative Work or acceptance pages.

HyperDoc sources: [emitter](../dreyeck/work/project/project-ctm.lisp),
[Workspace](../dreyeck/work/project/project-workspace.lisp),
[acceptance model](project-acceptance-model.md),
[exchange review](project-ctm-exchange-review.md), and
[operator feedback](exchange/2026-10-20-juergen-ctm-import-feedback.md).
The offered third-party TMCL schema was not received. Its reported type counts
and constraint names are neither schema source nor normative verification.

All Topic Maps paths below are relative to the separate pinned repository,
available at `https://github.com/RalfBarkow/topic-maps/tree/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`.
`README.md`, `docs/coverage.md` and `docs/architecture.md` retain historical
Slice 0/18/19 descriptions. They cannot override current ASDF/source or later
execution records. The 22A matrix is also historical: its XTM gaps must be
read with 22D–22T, not reported as all still unimplemented.

## Inventory

**Normative access boundary:** no clause of a published ISO edition was newly
verified in this task. The public TMCL reference request
`https://www.isotopicmaps.org/tmcl/tmcl.html` failed at proxy CONNECT with 403
(HTTP destination status 000). This is an environment-proxy refusal, not an
observed remote-server rejection or evidence that the document does not exist.
The public references below are identified by retained source reviews; their
published-edition equivalence is not independently established here. Clauses
in historical reviews remain attributed reviews, not freshly verified rules.

| Requested edition / public reference | Observed implementation at the pin | Existing tests / retained execution evidence | Boundary and proposed next work |
| --- | --- | --- | --- |
| ISO/IEC 13250-2:2006, TMDM. Public reference: `https://www.isotopicmaps.org/sam/sam-model/2006-06-18/`; publication-equivalence statement reported by the retained review. | Present, bounded: `topic-maps/tmdm`, `src/tmdm/{items,item-identifiers,reification,merging,occurrences,variants,associations,import}.lisp`. Native items, equality, canonical handles and source-preserving content import. | `tests/{merge-graphs,item-identifiers,reification,map-import}.lisp`; ASDF systems `/tmdm/identifier-tests`, `/tmdm/reification-tests`, `/tmdm/import-tests`. Core evidence includes TMDM/CTM/CXTM together: 12,100 retained checks in the 22U execution record, not 12,100 independent TMDM conformance clauses. | No independent whole-standard acceptance. Compare selected published invariants/errata with native tests. Import's resolver API, source preservation and transaction policy are implementation choices, not a second model standard. |
| ISO/IEC 13250-3:2007, XTM 2.0. Public reference: `https://www.isotopicmaps.org/sam/sam-xtm/`; retained review reports equivalence to this edition. | Partial/qualified: `topic-maps/xtm`, `/xml`, `/ctm/xtm`; `src/xtm/{iri,reader}.lisp`, `src/xml/{parser,resource-c14n}.lisp`, `src/ctm/xtm.lisp`. Includes occurrences, associations, roles, reification and qualified anyType XML. | `/xtm/tests`, `/ctm/xtm-tests`; `tests/xtm-{identity,associations,resource-datatypes,anytype}.lisp`, `tests/ctm-xtm-{equivalence,anytype-equivalence}.lisp`. 22U records 4,327 XTM checks, 146 XML checks, 34 equivalence pairs plus four contrasts/728 checks; 121 PASS / 0 FAIL / 3 NOT-RUN originals. | Three original dispositions remain, including mergeMap cycle semantics; XML resource policy, locator qualification and editions remain bounded. See `docs/slice-22o-qualified-xtm-corpus-disposition.md` and 22S/22T. No inference of total conformance from the corpus. |
| ISO/IEC 13250-3:2013, later XTM edition. | Not established for this edition. The registered reader explicitly checks version `2.0` (`src/xtm/reader.lisp`, `validate-source`); the pinned profile targets 2007. | No 2013-edition qualification is established by the 2007 reports. Rejecting a different version is not implementing it. | Obtain published 2013 requirements and compare editions before proposing implementation work. No primary text/accessibility for 2013 has been verified here. |
| ISO/IEC 13250-4:2009, CXTM. Public reference: `https://www.isotopicmaps.org/cxtm/cxtm.html`. | Present, bounded: `topic-maps/cxtm`; `src/cxtm/{canonicalizer,unicode,nfc-data}.lisp`. Canonical output of the supported native model. | `/cxtm/tests`, `tests/cxtm.lisp`; `reports/slice-22u/after/retained/core.json.cxtm.json`; 16,294 NFC comparisons recorded separately in 22U. | Date/time contexts and final-edition/errata questions remain. Resolve Q-CXTM against the published clauses; do not alter original canonical expectations to conceal discrepancies. |
| ISO/IEC 13250-5:2015, Reference Model (TMRM). | Not established by this distribution. Full `topic-maps.asd` registration and `src/` module inventory contain the TMDM/CTM/CXTM/XML/XTM implementation, not a separately registered Reference Model implementation. This does not assert absence outside the inspected distribution. | No TMRM-specific execution contract or qualification is established by those registrations/reports. TMDM tests are not TMRM tests. | Obtain the published edition and identify an explicit intended implementation mapping. A primary-text locator and clause review remain unresolved; no inferred mapping to TMDM is substituted. |
| ISO/IEC 13250-6:2010, CTM. Public reference: `https://www.isotopicmaps.org/ctm/ctm.html`, identified in retained reviews as the 2010-03-31 draft. | Present, incomplete qualification: `topic-maps/ctm`; `src/ctm/{lexer,reader,templates,resources,iri,unicode}.lisp`. Contextual Template binding, Include and controlled mergeMap exist. | `/ctm/template-tests`, `/ctm/include-tests`, `/ctm/registered-original-tests` and focused systems in ASDF; `tests/ctm-templates.lisp`; 22U retains CTM 262 PASS / 4 FAIL / 7 NOT-RUN. `reports/slice-22c/{case-evidence,decisions,source-review}.json` record exact disputed originals. | Four baseline mismatches and seven Template-Tail original contracts remain unresolved. Q-CTM/Q-CXTM/Q-ERRATA in `docs/slice-22c-normative-decisions.md` require published text. Encoding and date/time policies are additional boundaries; a general CTM writer is not present in the reader API. |
| ISO/IEC 19756:2011, TMCL. Public reference candidate requested above; edition identity and body inaccessible/unverified. | No TMCL implementation registered in `topic-maps.asd`; module inventory and the explicit profile exclusion in `docs/slice-22a-conformance-closure.md` support this bounded finding. HyperDoc's exchange review explicitly says there is no TMCL implementation at the pin. Existing Lisp project checks are not a TMCL engine. | No executed TMCL validation record is established. A string occurrence referring to a TMCL resource in a CTM test exercises occurrence parsing, not validation. | Obtain published text/PSIs/templates, agree the application profile, then separately authorize a validator project. This task supplies only design requirements. |

The primary retained run examined is
`reports/slice-22u/after/execution.json`: SBCL 2.5.4, 2026-10-25,
base `b9517b977fca2105422892a14b4cf9fe9790bbba`, 119 process outcomes including
113 fault controls. It is not a run performed by this inventory task and not
a run at the later 88994c1b commit. Later pin-integration evidence is separately
recorded in HyperDoc's `docs/topic-maps-88994c1b-integration/README.md`; its
performance controls do not add new standards conformance cases.

ANSI CL qualification is also bounded: model/reader code principally uses
Common Lisp, but `src/ctm/unicode.lisp:decode-iso-8859-5` explicitly uses
`#+sbcl sb-ext:octets-to-string` and signals unsupported on other implementations.
ASDF/UIOP, Python tooling and the qualified CXML path are separate dependencies.
No implementation-independent portability certification follows.

### Pinned source and evidence links

- [Registered systems](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/topic-maps.asd)
- [Native content-import implementation](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/src/tmdm/import.lisp)
- [Native import tests](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/tests/map-import.lisp)
- [CTM reader](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/src/ctm/reader.lisp)
- [Template tests](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/tests/ctm-templates.lisp)
- [CXTM canonicalizer](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/src/cxtm/canonicalizer.lisp)
- [CXTM tests](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/tests/cxtm.lisp)
- [XTM reader](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/src/xtm/reader.lisp)
- [XTM XML-value tests](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/tests/xtm-anytype.lisp)
- [Historical 22U execution record](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/reports/slice-22u/after/execution.json)
- [Originals and normative decisions](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/docs/slice-22c-normative-decisions.md)
- [Historical open-case matrix](https://github.com/RalfBarkow/topic-maps/blob/88994c1b9e1edbf13e665e984a5c9c3b2cdf7575/docs/slice-22a-conformance-matrix.md)

## First schema design: application requirements, not inferred TMCL rules

Application subject identifiers already exist under
`tag:dreyeck.ch,2026:hyperdoc/schema/` (abbreviated **S/** below). These are
HyperDoc identities, not published TMCL PSIs. **For every row, normative TMCL
basis, constraint type/role PSIs, validation semantics and authoring-template
signature remain unresolved.** Cardinalities below are proposed application
requirements, not requirements imposed by the TMCL standard on every project.
No TMCL namespace, template call or runnable schema is minted from inference.

| Design requirement | Existing application identities | Valid / invalid example (design only) | Current Lisp enforcement / gap |
| --- | --- | --- | --- |
| D1. A source-identified Assignment has its intended type. | S/implementation-assignment; `assignment/<authored-id>` | Valid: authored assignment emitted with that type. Invalid candidate: an external map's identified assignment missing it. | `%read-assignments` reads authored sections; `%emit-model` emits the type. No generic TMCL validation of external maps follows. Domain selection itself needs agreement, not merely querying instances that already have the type. |
| D2. Propose exactly one nonblank string Goal per Assignment. | S/goal; S/implementation-assignment | Valid: one goal occurrence. Invalid: missing, duplicate distinct goals, or blank goal. | Emitter writes the selected `goal` field through `%occurrence`; reader collects fields and `assoc` selects the first. It does not refuse all missing/duplicate/blank source goals. Exactly-one and nonblank are proposed additions, not currently enforced schema facts. |
| D3. Distinguish prose evidence from execution reports. | S/evidence-entry; S/test-execution-report | Valid: an identified prose note is Evidence entry; a complete reported run is Test execution report. Invalid: calling a prose note a run without run facts. | `read-evidence-entries`, `entry-execution-p` and `%emit-model` select the type based on authored run facts. Reports are emitted as test-execution-report, not also evidence-entry; do not invent an unimplemented subtype hierarchy. |
| D4. An identified evidence Topic reifies the Assignment's evidence occurrence. Plain unidentified notes may remain unreified. | S/evidence-note; S/evidence-entry or S/test-execution-report; native occurrence parent/reifier | Valid: E reifies evidence on A, inverse reference points to E. Invalid: E reifies A's Goal or another owner's occurrence. | `%reify-occurrence` creates the relation; duplicate entry IDs and identical identified texts are refused to prevent reifier collisions. Native TMDM invariants are separate from an unverified TMCL may-reify/other constraint mapping. |
| D5. Selected source and run Associations have their intended roles/players. | S/declared-on with S/declaration and S/source-page; S/reports-execution-of with S/execution-report and S/test-file; existing S/hyperdoc-page and S/repository-file | Valid: one Assignment source declaration and its page; a reported run relates to its test file where repository policy permits. Invalid candidate: missing source Role, or a non-file test player. | Emitter constructs these Roles; execution-file relation is emitted only for the configured HyperDoc repository identity. Source/native tests exercise it. Closed-world role cardinalities/player unions and a TMCL mapping need explicit approval. |
| D6. Keep authored identities stable and unambiguous. | `assignment/<id>`; `evidence/<assignment>/<data-evidence>` | Valid: distinct evidence IDs under an assignment; same subject SI shared across documents. Invalid source: duplicate data-evidence ID within one assignment. | `%identifier-part`, `read-evidence-entries` enforce authoring syntax/uniqueness. Locator equality and canonical identity are TMDM; globally forbidding repeated SIs across separately authored maps would be incorrect. Any string-pattern schema mapping is unverified. |
| D7. A reported run has complete conditional facts; no false run is inferred from a file. | S/source-repository, S/test-path, S/tested-revision, S/tree-state, S/content-reference, S/observation, S/observed-at | Valid: complete clean-tree report without modified-content reference; modified report clearly records its reconstruction limit. Invalid: incomplete run facts or content reference on a clean tree. | `+run-facts+`, `read-evidence-entries`, `%revision-p`, `%datetime-p`, `entry-reconstruction` enforce current application policy. Cross-field/reconstruction rules remain Lisp-level unless a published TMCL expression is verified. A shape check never proves a run happened. |
| D8. Schema validation grants no provenance authenticity or acceptance authority. | S/acceptance-record, S/authority, S/considers-evidence and the existing record model | A well-shaped attributed report may still be untrue. An execution PASS alone must not create an Acceptance Record. | Acceptance sources are segregated; declared criteria/revisions/evidence are checked by Lisp. D4 of the acceptance model explicitly declares rather than authenticates authority. Authentication, append-only history and truth of reports require separate decisions; no TMCL rule is asserted to establish them. |

Published TMCL subject identifiers, constraint-type definitions, validation
rules, applicable scope/type treatment, and CTM authoring-template definitions
must be obtained and matched to each row before a schema CTM can be authored.
The offered external schema may later inform an independent comparison; it
cannot replace that verification. No `topic-maps/tmcl` system, validator,
template library or runnable TMCL schema is introduced here.

## Project proposals and source-backed navigation

Implementation Assignments proposes one investigation Work Item, one combined
inventory/design Deliverable, two Work Packages, two Plan Steps and a published-
source precondition. Only existing `produces`, `decomposes-into` and `depends-on`
relations are reused, explicitly as proposed statements. No relation to an
existing declared Work Item is invented. The Dictionary is not extended into
an authoritative WBS; authority, approved criteria and schedule remain missing.
The existing separation contract limits produces to Plan Step → Work Package;
therefore no Work Item → Deliverable edge is authored. That missing relation
is left explicit rather than inventing a relation or weakening the contract.

Standards/editions, implementation systems, representative source/test artifacts,
retained execution evidence and normative questions are existing-kind `concept`
proposals with stable application SIs `tag:dreyeck.ch,2026:hyperdoc/work/topic/<id>`.
Their labels do not determine identity. Their source-grounded text is carried
on Implementation Assignments; each links to the registered investigation
reading page. The native Workspace can follow proposed-on/carried-by back to
source. The reading table connects sources, tests and recorded results in prose.
No new implements/tested-by relation is invented to complete a diagram.

## Two maps and one subject: bounded identity demonstration

The project map already uses S/implementation-assignment as an application
type. A future schema map must refer to that exact subject rather than invent
a second type based on a similar label. Its own Document IRI and authoring
authority must remain distinct from the derivative project map's fixed
`tag:dreyeck.ch,2026:hyperdoc/project.ctm`.

The focused test uses ordinary CTM identity fixtures, **not a TMCL schema**,
under distinct project/design Document IRIs. Both mention the existing
S/implementation-assignment and S/goal identities and carry distinct local
note occurrences. It checks separate objects before import, a single canonical
representative for the shared subject after native `import-map-content`,
retained target handles resolved through `canonical-topic`, both notes, and unchanged source CXTM. Raw retained-object EQ is not the importer's
contract; the resolver follows forwarded handles after later merges. It compares
canonical bytes only under explicitly stated Document/base IRIs. These are
identity/import and serialization-comparison observations, not TMCL validation.

The importer copies content and normalizes identities; it does not merge root
Map items or transfer source Map identifiers/reifier. Nor does it automatically
preserve every statement's source authority. A real schema integration must
retain per-statement provenance explicitly before content is combined. This
task does not import a schema into the retained project map or grant its
constraints authority over the Work sources.

No edited-TMDM-to-CTM serialization is claimed: source-page materialization,
native CTM deserialization, canonical CXTM output and unchanged-original CTM
octet export are different operations.

## Decisions required before a TMCL implementation project

1. Supply the published 2011 text/PSIs/templates and relevant corrections;
   resolve D1–D8 mappings rather than substituting inferred constraint rules.
2. Approve the application domain and Goal cardinality/nonblank policy;
   decide open/closed role rules and the treatment of external maps.
3. Decide which conditional, provenance and lifecycle rules remain in Lisp,
   and which verified TMCL constraints are in scope.
4. Decide schema authority/versioning, validation target, import/provenance
   policy and a lawfully available conformance corpus.
5. Declare Work/Dictionary authority and concrete acceptance criteria before
   promoting proposals or authorizing implementation. Nothing here promotes them.

## Focused verification of this slice

The existing source/emitter checks passed **411 assertions**. The new focused
inventory/design checks passed **169 assertions**: **580 total**, process exit 0.
The runner generated a temporary CTM, verified it, then wrote the retained
project CTM/digest only after success. CTM SHA-256:
`75e4234cea1f3abbdf7d35deba61bba97125bf3af4f3ab8f007c535088a01378`.

[Successful execution output](evidence/topicmaps-inventory-design/focused.log),
[exact external launcher](evidence/topicmaps-inventory-design/launcher.py),
[source identities and normative-access record](iso-topicmaps-inventory-sources.json).
The launcher uses the already established direct SBCL 2.4.10 environment and a
clean disposable Topic Maps checkout at the unchanged pin. No source change
was made to Topic Maps or to its normalization/reader algorithms.

The first proposal draft included a Work Item → Deliverable produces edge;
the existing separation test rejected it. It was removed, not accommodated by
a new relation or weakened assertion. A subsequent new test accidentally
selected older tm-prefixed proposals; selection was corrected to the authored
reading page. The first identity assertion incorrectly demanded raw retained
object EQ; it was corrected against the documented canonical-handle API,
adding explicit single-subject and both-resolver checks. These corrections
changed this slice's authoring/test assumptions, not normative TMCL rules.

Tests exercise native objects and Inspector/Workspace references in Lisp.
No graphical browser test, full historical CTM/XTM corpus or performance suite
was run. Constraint-matrix valid/invalid examples are design examples, not
TMCL validation executions. Historical counts in the inventory remain
attributed to their original run. No published TMCL clause was newly verified.
The slice stops at this inventory, project representation and first schema
design; implementing a validator requires a separate decision.
