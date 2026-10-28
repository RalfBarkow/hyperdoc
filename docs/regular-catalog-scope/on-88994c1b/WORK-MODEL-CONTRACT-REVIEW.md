# Zettel 11359 — Work Model Contract Review (decision report)

Read-only review, 2026-10-28, of the committed Stage 1 proposal. Nothing in the repository was changed; this file is the one new, **untracked** document.
No test, suite or benchmark was run; every statement below comes from reading source, pages, the committed CTM and git.

Reference identities: HyperDoc Stage 1 `ebb44941b228cd5c3bb9434229b47ecb168444b4` (tree `97752a83…`), Topic Maps `88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`,
Stage 1 CTM `346ae79206e291193e4e13a824a4d7c50fabd180a5328621e9ff4894cdd2b0f5`.

Labels: **[V]** verified source fact (with location); **[D]** derived by reasoning from [V] facts; **[P]** proposed modelling choice, not decided.
Paths are relative to the worktree; `L` numbers are lines at `ebb44941`.

---

## 0. Summary

1. **Work Item → Deliverable.** No existing contract can carry it, and it cannot be derived from existing relations. The Work model itself already knows the hole:
   the emitter derives the gap `work-item-deliverable-unlinked`, and the **declared, productive precedent** (`ctm-plan-page-authoring` / `ctm-page-edit`) has it in the committed
   project CTM today. A new contract is possible but is a Work-model change; keeping the precedent's convention (one carrier page per Work Item) needs none.
2. **Evidence carrier.** The model already has one, designed and tested on synthetic fixtures (D2 of `docs/project-acceptance-model.md`): identified *Evidence entries* and
   *Test execution reports*, kept apart from *Acceptance Records*. It is **deliberately not used on the productive page**, and two existing test guards forbid it there. What is missing is
   not a new model but a decision to lift those slice-scoped guards, plus a way to identify *commits and reviews* (the model's structured form covers only test runs).
3. **WBS and Plan.** The decomposition (one deliverable, six packages) and the plan (six steps, 1:1 `produces`) are cleanly separated. The plan is **not a pure linear chain**: it has
   the chain p1→p2→p3→p4, then p5 and p6 with direct edges to four preconditions. Of the 22 proposed relations, the dependencies that source facts support, those that are planning assumptions,
   and one placement problem (the security-review precondition) are listed in section C.
4. **A defect found in Stage 1 itself** (not a modelling question): the proposals' descriptions on *Implementation Assignments* still say Topic Maps **6162ed68** (work package 1 and plan
   step p1), while the corrected dictionary says 88994c1b. See C.7.

---

## A. Work Item and Deliverable

### A.1 Representations [V]
| Thing | Where it is declared | Form | Source |
|---|---|---|---|
| Work Item | a Work page (`dreyeck/pages/work/Work Breakdown.html`), or a proposal | `<a data-topic=… data-kind="work item" data-status=… page=…>`; proposals: `data-proposed-topic`, no status | Work Breakdown (14 work items, statuses such as open, blocked, complete, in progress); Implementation Assignments (2 proposed) |
| Deliverable | a plan page, or a proposal | `data-kind="deliverable"`; the plan-page validator requires **exactly one** per page | `Authoring the CTM Plan Page.html` (`ctm-page-edit`); `ctm-plan-page-authoring.lisp:320` |
| Work Package | same | `data-kind="work package"`, status open/blocked/verified once declared | `ctm-plan-page-authoring.lisp:61` (`+statuses+`) |
| Plan step, precondition | same | `data-kind="plan step"` / `"precondition"` | `ctm-plan-page-authoring.lisp:164, 263` |
| Carrier page | the `page=`/`hyperbook=` attribute of each declaration | emitted as `carried-by`, **"Not a Work relation"** | `project-ctm.lisp:256` (`%carrier`), `:753`, `:903` |

In Stage 1 all 18 proposals name the *HyperDoc Project Workspace* page as their carrier, so Stage 1 has a single shared carrier for everything on *Implementation Assignments*.

### A.2 Relation contracts actually implemented [V]
| Contract | Declared on | Status | Defined meaning | Roles |
|---|---|---|---|---|
| `work:relation/informs` | Work Breakdown (+ its own page `Relation Contract informs.html`) | draft | A's results or questions are input to B; asserts no order, ownership, prerequisite, causation or authority | Work topics |
| `work:relation/addresses` | Work Breakdown | draft | the Work item includes investigation/implementation/change of a Constraint; asserts no satisfaction | work item → constraint |
| `work:relation/decomposes-into` | Authoring the CTM Plan Page | draft | WBS: the target is part of the source's scope and the targets together are all of it; no order/dependency/status/authority | deliverable → work package (`ctm-plan-page-authoring.lisp:314`) |
| `work:relation/depends-on` | same | draft | Plan: the source cannot be **completed** before the target is satisfied; ordering only | plan step → plan step or precondition (`:316`) |
| `work:relation/produces` | same | draft | Plan: the step yields the work package; asserts what the step is for, not that it may be performed | plan step → work package (`:315`) |

Plain relation words with **no** contract (each yields the gap `uncontracted-relation-word`, 12 in the CTM): `requires, develops, models, observes, current-work, contains, uses, demonstrates, compares-with, raises-question-for, is-related-in`, among others (Work Breakdown).
All four contracts in use are `draft`, hence four `draft-contract-in-use` gaps. Resolution is generic: `resolve-relation-contract` (`dreyeck/work/reading.lisp:114`) requires exactly one Topic of kind `relation` with the ID on the page. The plan-page validator is stricter: it refuses any relation that
is not one of its three contracts and any pair of kinds the contract does not allow (`ctm-plan-page-authoring.lisp:306–318`).

### A.3 Can the link be derived from existing relations? [V]+[D]
- **The emitter itself says no.** `derive-gaps` (`project-ctm.lisp:619–632`) emits `work-item-deliverable-unlinked` when a Work Item and a Deliverable share a carrier page and *no statement relates them*,
  with the text "No Relation Contract defines that relation." `%relates-p` (`:613`) accepts a statement of **any** relation type in either direction, so even an uncontracted word would silence the gap (at the price of an `uncontracted-relation-word` gap).
- **The productive precedent has the gap.** In the committed project CTM at `bc002546` (before Stage 1) the gaps `work-item-deliverable-unlinked/ctm-plan-page-authoring/ctm-page-edit` (declared) and `…/project-work-ctm/project-work-ctm-exchange` (proposed) exist. The model has lived with this gap since the CTM plan page was declared.
- **No existing contract fits** [D from A.2]: `decomposes-into` is deliverable → work package (a Work Item as its source would violate the contract and the validator); `produces` starts at a plan step; `addresses` ends at a Constraint; `informs` asserts no scope. Chaining (Work Item →? plan step → package ← deliverable) is not available: Stage 1 has **no** statement starting at the Work Item (the `work-item-without-breakdown` rule for declared Work Items looks for a planning statement at the Work Item; proposals are exempt, `project-ctm.lisp:633–640`).
- **Carrier sharing is a convention that works only with one carrier per Work Item** [V]: on the shared Project Workspace carrier Stage 1 adds three unlinked-pair gaps, of which only `topic-maps-regular-hyperdoc/tm-regular-catalog` is intended; `project-work-ctm/tm-regular-catalog` and `topic-maps-regular-hyperdoc/project-work-ctm-exchange` are artefacts of the shared carrier. A dedicated carrier page for this scope (as the precedent has) would make the convention yield exactly the intended pair [D].

**Verdict:** not derivable from existing relations; derivable only as the co-carrier convention, which the model records as a gap, not as a link.

### A.4 Minimal alternatives [P]
| | Option | Consequence |
|---|---|---|
| A1 | **Keep the precedent.** One dedicated carrier page names both the Work Item and the Deliverable; no new contract. | No Work-model change. The gap `work-item-deliverable-unlinked` stays visible (one more, like the precedent). The relation remains implicit. |
| A2 | **One new contract**, Work Item → Deliverable. Minimal semantics: "the Work Item is carried out as, and has as its defined scope, the Deliverable; it asserts scope ownership only: no order, dependency, status, authority or evidence". Working name `work:relation/yields` (not `delivers`: the emitter already uses *delivers* for assignment → package). | A contract page and a declared relation Topic (draft). Silences the gap, adds a `draft-contract-in-use` gap while draft. The generic project emitter needs no code change by reading (not executed); **the plan-page validator would refuse it** (`:306–318`) if applied to such a page, and the Work Workspace views specific to the CTM plan page do not know it. It changes the model for all 14 Work Items. |
| A3 | Leave the Stage 1 state (shared Project Workspace carrier), accept three gaps. | Cheapest; keeps two spurious gaps. |

---

## B. Evidence carrier

### B.1 What is represented today, with what identity [V]
| Evidence | In the committed CTM | Persistent identity |
|---|---|---|
| Test source file | `Repository file` Topic `file/<path>`, 33 of them; `evidenced-by-test` associations | path in this repository (and its git blob); the CTM embeds test-file digests of declared controls |
| Implementation commit (HyperDoc, Topic Maps) | **text only** in prose notes (`s:evidence-note`); no commit Topic, no `evidence/` namespace Topic (0) | Git object ids exist outside the CTM; named in prose |
| Independent review | prose note; the report is a file | file + SHA-256 in `SHA256SUMS` of the preserving directory (not in the CTM) |
| Test run | prose note, or—when identified—a *Test execution report* | none today; the structured form exists but is unused on the productive page |
| Runtime/browser observation | prose | none |
| Acceptance | **none**; *Acceptance Records* is a draft page that is not a source (`dreyeck/pages/project/Acceptance Records.html`) | — |

### B.2 The model that already exists [V]
`docs/project-acceptance-model.md` (D2, D5; implemented in `project-ctm.lisp:354–410`, `:798`, `:985`):
- **Evidence entry**: an `<li data-evidence="ID">` in an assignment's evidence list, unique per assignment; its Topic `evidence/<assignment>/<entry>` *reifies* the existing evidence occurrence (no second copy of the text).
- **Test execution report**: an identified entry with `data-test`, `data-repository`, `data-revision`, `data-tree` (clean|modified), `data-observation`, `data-observed-at` (+ optional `data-content`); the emitter derives a *reconstruction* statement. Linked to the test file Topic with `reports-execution-of` only when the repository is `codeberg.org/rgb/hyperdoc` (`+repository+`, `:354`); for other repositories (Topic Maps) the path stays an occurrence.
- **Kept apart:** required evidence (dictionary), reported evidence (assignment), acceptance (a record on *Acceptance Records*). "An assignment's evidence is never transferred to the package it delivers"; no passed test, completed assignment, work status or evidence entry is an acceptance. An executor never writes a record (D4). Records may name only **declared** packages with a **declared** dictionary (D5), so Stage 1's proposed packages cannot be accepted.
- Rules that bind a carrier decision: execution facts may not be added to an old report; adding an ID to a historical entry is allowed (D2 "History").

### B.3 Why it is not in use [V]
Two guards in `dreyeck/tests/project-ctm.lisp` express the earlier slice's promise that the productive CTM stays unchanged:
`productive:no-evidence-entry-or-criterion-revision` (`:770`: no `evidence/` namespace, no reifier in the productive model) and `productive:existing-evidence-entries-are-not-retrofitted` (`:774`: no `li[data-evidence]` on *Implementation Assignments*).
They are **slice-scoped promises**, not domain invariants [D]: the acceptance-model text says "Existing entries are not retrofitted in this slice". Any productive identified evidence—on that page or on a new source page—fails the first guard, so it needs a deliberate, reviewed revision either way.
Stage 1 therefore records run facts as prose (which the commit message and the correction record say).

### B.4 Can it be represented without a parallel model? [D]
- **Test runs:** yes, with the existing Test execution report, once the guards are decided.
- **Commits and reviews:** the structured form does not fit (`data-test` is mandatory for run facts, `:408`). They can be **identified Evidence entries** (prose with the full object id) with no new vocabulary. A structured commit/review type (revision, tree, verdict, report digest) would be new vocabulary—[P], a separate decision, not needed for Stage 2.
- **Preserved logs and reviews** already have SHA-256 identities in evidence directories; they could be cited through `data-content` ("immutable content reference") for a modified tree, or named in the entry text. The CTM would still only state that the executor *reported* them.

### B.5 Relation to a proposed Work Package, without implying acceptance [D]
Evidence attaches to an **assignment** (`assignment-delivers` package) and stays there. A package has *required* evidence (dictionary) and, via its assignments, *reported* evidence; neither is acceptance. For proposed packages there is no acceptance path at all (D5), and the emitter derives `acceptance-requires-declaration` for proposed dictionary entries.
Distinctions to keep: **source authority** (`data-reads`/`data-changes`: what the executor read or changed), **execution evidence** (reported run), **review** (independent report; its verdict is evidence, not acceptance), **Acceptance Record** (the user's decision, on a declared package).

### B.6 Minimal alternatives [P]
| | Option | Consequence |
|---|---|---|
| B1 | Keep prose notes; no guard change. | No model change; run facts stay unidentified; reproducibility lives in `docs/…/evidence/` and git. |
| B2 | Lift the two guards narrowly for **new** assignments on *Implementation Assignments*; use identified Evidence entries for commits and reviews and Test execution reports for runs. | Uses the existing model; changes the productive CTM (new `evidence/` Topics, reifiers); the two tests must be revised, with a negative control that old entries are still not retrofitted. |
| B3 | Separate evidence-carrier source page. | Requires registering a fifth source in `+sources+` (`project-ctm.lisp:109`), same guard revision, and a decision what the page is authoritative for. More structure than B2 without a stated gain. |

---

## C. WBS and Plan

### C.1 What the model requires [V]
- Decomposition: one deliverable decomposed **once** into every package (`ctm-plan-page-authoring.lisp:319–323`).
- Plan: each step produces exactly one package and each package has exactly one step (1:1, `:324–328`); no cycles (`%acyclic-p`, `:285`).
- Status/dependency agreement (`:330–339`): a step is **blocked exactly while an unverified precondition is among its dependencies**; **open** requires its preconditions verified; **verified** requires every dependency verified. Statuses are only open/blocked/verified, changed only by the "Change work status" operation, not by a passing test.
- A dictionary entry per package with controls (the CTM-specific `+required-controls+` at `:63` belong to the CTM edit; the project emitter reads dictionaries generically).

### C.2 Stage 1's actual structure [V] (proposals on *Implementation Assignments*)
- WBS: `tm-regular-catalog` decomposes into `tm-reg-wp-1…6` (6 relations).
- Produces: `p1…p6 → wp-1…6` (6, 1:1).
- depends-on (10): p2→p1, p3→p2, p4→p3, p5→p1, p5→p4, p5→pre-admission, p5→pre-publish, p6→p5, p6→pre-security-review, p6→pre-production.
So it is a chain p1→p2→p3→p4 with p5/p6 hanging off four **user-decision preconditions**; the handoff's phrase "linear chain p1→p6" simplified it. **p5→p1 is redundant** (implied through p5→p4→p3→p2→p1).

### C.3 Decomposition versus sequencing [D]
The six packages are deliverable-style nouns and the dictionary states completeness and overlaps (1/5 at the snapshot, 2/3 at the Workspace, 4/6 at exposure). Sequencing exists only in `depends-on`, which the contract limits to "cannot be completed before". The 1:1 `produces` makes the plan a mirror of the WBS; that mirrored structure is a model rule, not a finding.

### C.4 Dependencies by their grounds
| Edge | Ground | Class |
|---|---|---|
| p2→p1 | The Workspace refuses any root other than its pin (`project-workspace.lisp`, `pinned-state-p`); HyperDoc commit `d9da94d8` moved the manifest, the Catalog/22U/verifier pins and the Workspace pin **in one commit** ("one consistency boundary") | source-supported; note the two steps' work landed in the same commit, so the order is conceptual, not historical |
| p3→p2 | package 3's object *is* the Workspace reading | source-supported by definition |
| p4→p3 | no contract or evidence ties public-view safety to navigation; the Catalog's startup guard and its test (`dreyeck/tests/catalog-topic-maps.lisp`) exist independently of package 3 | **planning assumption** |
| p5→p1 | the package serves the snapshot of package 1 (`nix/topic-maps-source.nix`) | supported; **redundant** by transitivity |
| p5→p4 | building a package does not need the security verdict; deployment does (p6→security review) | **planning assumption** |
| p5→pre-publish | `nix/topic-maps-source.nix` L5: until the archive is published at its URL, only a store already holding the hash can build the packages | source-supported |
| p5→pre-admission | the packaged Catalog's guard refuses the Workspace by design; admission matters only if the regular Catalog is to serve it | **conditional on a scope decision** (does the regular Catalog serve the Workspace?) |
| p6→p5 | deployment needs the package | supported by definition |
| p6→pre-production | the user's approval to activate | supported by definition |
| p6→pre-security-review | the review concerns package 4's output | **placement problem**: the review is the dictionary's own acceptance evidence for package 4 (wp-4), but it is a precondition of p6, so p4 could become *verified* without it |

### C.5 Decisions required before Stage 2 [D]
1. Initial **statuses** for six steps and packages under the agreement rules: p5 and p6 must be **blocked** (their preconditions are user decisions, unverified); p1–p4 may be open or, only on the user's report, verified (the precedent verified P1 by the user's report). Packages' statuses likewise. A green suite verifies nothing.
2. Whether the three planning assumptions and the redundant edge stay, and where the security-review precondition belongs.
3. Whether the regular Catalog serves the Workspace (the admission precondition's ground).
4. Whether assignments **confirm** a plan step: the gap `assignment-without-plan-step` (4 new in Stage 1) fires when the `plan-step` field has no `data-ref` (`project-ctm.lisp:642`); the emitter checks presence, not that the ref resolves to a declared step, and the assignment text says it cannot make one—so confirmation is the user's decision, not something an executor writes.
5. The Acceptance Records page stays a draft (not a source); declaring six packages and a declared dictionary will produce six `acceptance-not-recordable` gaps (the CTM plan page has five today). That is expected, not a defect.

### C.6 What the plan page validator implies for Stage 2 [V]
`validate-ctm-authoring` is applied by `read-ctm-authoring` to the CTM plan page (`:253–267`, `:296`); it is parameterised by source but carries CTM-edit-specific required controls and "exactly one deliverable". The project emitter reads declared Work pages with the ordinary Work reader and does not apply it. Whether a Stage 2 carrier page for this scope needs the validator, a generalisation of it, or none is **not established by Stage 1** and is part of the Stage 2 design.

### C.7 Defect found in the committed Stage 1 [V]
In the proposals on *Implementation Assignments*, the description of **tm-reg-wp-1** reads "the reviewed commit 6162ed68, its snapshot, manifest and pin…" and the label of **tm-reg-p1** reads "Integrate and verify Topic Maps 6162ed68". The corrected dictionary (decision 2) says 88994c1b. The two now disagree. It is textual; fixing it changes the CTM (regeneration and a full rerun), so it was not touched. It belongs in the next Stage 1 change, with decision 2 of the Scope Declaration Review.

---

## Decisions requiring human authorization
| # | Decision | Options |
|---|---|---|
| H1 | Work Item → Deliverable | A1 keep precedent (dedicated carrier page, gap stays) · A2 one new draft contract (Work-model slice, validator and views to be checked) · A3 status quo |
| H2 | Evidence | B1 prose · B2 narrow guard revision, identified entries on *Implementation Assignments* · B3 separate carrier page |
| H3 | Commit/review evidence form | identified Evidence entries (no new vocabulary) · a structured commit/review type (new vocabulary; not needed for Stage 2) |
| H4 | Plan | keep or change the assumed edges (p4→p3, p5→p4, p5→pre-admission); remove the redundant p5→p1; place the security-review precondition at p4 |
| H5 | Initial statuses and step confirmation | per C.5; only the user can verify or confirm |
| H6 | Stale 6162ed68 text in the proposals | correct with the next Stage 1 change (CTM regeneration) |
| H7 | Carrier page for Stage 2 | dedicated page (makes the co-carrier convention exact) vs the shared Project Workspace page |

## Recommended order of subsequent work (each its own reviewed change)
1. **H6** — the textual Stage 1 correction, together with a decision on H7 (carrier), because both change the CTM and neither changes the model.
2. **H4/H5** — plan decisions by the user (they decide the statuses a declaration may honestly carry).
3. **H2/H3** — evidence carrier, as a model slice with the guard revision and negative controls, before any assignment evidence is converted.
4. **H1** — a new contract only if the user wants the gap closed; as a separate Work-model slice with its own review (contract page, validator, views).
5. **Stage 2** — only then, as a declaration over decided semantics; it should not carry model changes.

## What this review did not do
It ran nothing, so statements that a new contract or an identified entry "would be accepted by the emitter" are readings of the code, not executions. It did not examine FedWiki Story Items as a carrier, the Work Workspace views for plan pages, or Topic Maps' own project-work example beyond the pointers above. No Work declaration, status, Acceptance Record, CTM, test or historical evidence was modified; no commit, merge, push, deployment or background run.

---

## D. Second step: H6 (stale revision text) and H7 (page carrier) — design review

Baseline for this step: `ebb44941b228cd5c3bb9434229b47ecb168444b4`. Nothing in the worktree was changed except this file; the experiments below ran in **scratch clones** under the session scratchpad
(a fresh clone of the committed baseline, one SBCL process each, the emitter's own `write-project-ctm` writing into the scratch tree). No test suite ran.

### D.0 Document integrity and source references (verified)
The system reported this file as changed on disk after my first write. The only changes I can identify are my own: a scripted pass at about 21:29 that corrected eight line citations (the file's size and
modification time match that pass; `git status` shows it as the single untracked file; I found no text I did not write). I cannot prove from bytes alone that no other tool touched it. Every `file:line`
citation was then re-read against the committed sources at `ebb44941`; two were off by one and are corrected (`ctm-plan-page-authoring.lisp:314` for `decomposes-into`; `project-ctm.lisp:633–640` for the
`work-item-without-breakdown` rule). All others (`:61 :63 :164 :253–267 :263 :285 :296 :306–318 :315–316 :319–323 :324–328 :330–339 :320`, and `project-ctm.lisp :109 :256 :354–356 :382–410 :408 :613 :617–632 :642 :753 :798 :903 :985`, `reading.lisp:114`,
`tests/project-ctm.lisp :770 :774`) match. The review stays uncommitted.

### D.1 H6 — the exact occurrences and the smallest correction [V]
In the proposals block of `dreyeck/pages/project/Implementation Assignments.html` (committed lines 38 and 57), `6162ed68` occurs exactly twice, and nowhere else in the proposals (the relation
sentences, e.g. line 69, carry no revision):
| Where | Text at `ebb44941` | Kind |
|---|---|---|
| L38, description of `tm-reg-wp-1` | "the reviewed commit 6162ed68, its snapshot, manifest and pin, with the identity that HyperDoc checks." | description of the *current* package → stale |
| L57, **link text = the name** of `tm-reg-p1` (CTM `- "Integrate and verify Topic Maps 6162ed68"`, the Topic name) | "Integrate and verify Topic Maps 6162ed68" | name of the *current* step → stale; description after the dash is generic |
Provenance that must stay: 6162ed68 in the two *assignments* (`cc-2026-10-28-topic-maps-6162ed68-revision` and its evidence), in the dictionary (7 mentions, all historical or as the Task 1C commit), and in the preserved evidence.
IDs do not change (`tm-reg-wp-1`, `tm-reg-p1` are the identities; the label is not), and no scope test or walk names 6162ed68 or these labels (grep).

**Proposed correction (three token edits, no structural change):**
1. L38 → "— the reviewed Topic Maps revision 88994c1b (Task 1C, commit 6162ed68, and Task 1E), its snapshot, manifest and pin, with the identity that HyperDoc checks."
2. L57 link text → "Integrate and verify Topic Maps 88994c1b" (description unchanged).
3. Record `ebb44941` only in the correction record (docs), **not** in the proposals: a commit cannot name itself, and the proposals describe subjects, not the proposal's own commit. `ebb44941` is the committed Stage 1 *source state*; it is not an acceptance.

**Executed on a scratch clone (H6 only):** the emitter's CTM differs from the baseline CTM in exactly **5 lines**: the source digest header, `s:source-sha256`, the wp-1 declaration text, the p1 name and the p1 declaration text. Model and gaps unchanged (47). Digest changes (scratch `59f79ed5…`; the real one would be regenerated).

### D.2 H7 — why the shared carrier produces the gaps [V]
Rule (`project-ctm.lisp:619–632`): for every Work Item w and every Deliverable d with an **equal carrier** `(hyperbook . page)` (`%carrier`, `:256`: the `page`/`hyperbook` attributes of the declaration's link) and no statement
between them, emit `work-item-deliverable-unlinked/w/d`. In the baseline CTM the carrier page `dreyeck/work/project/hyperdoc-project-workspace` carries **28 declarations, among them 2 Work Items
(`project-work-ctm`, `topic-maps-regular-hyperdoc`) and 2 Deliverables (`project-work-ctm-exchange`, `tm-regular-catalog`)**: 2 × 2 = 4 pairs, hence 4 gaps there:
| Pair | Status |
|---|---|
| `project-work-ctm` / `project-work-ctm-exchange` | pre-existing (one pair of the earlier proposals) |
| `topic-maps-regular-hyperdoc` / `tm-regular-catalog` | **intended**; legitimately missing (no relation exists) |
| `project-work-ctm` / `tm-regular-catalog` | **artefact**: two unrelated scopes share a carrier |
| `topic-maps-regular-hyperdoc` / `project-work-ctm-exchange` | **artefact** |
(The 5th unlinked gap is the declared precedent, on its own carrier `authoring-the-ctm-plan-page`.) `%relates-p` (`:613`) sees only statements, so carrier equality alone produces the pairing.

### D.3 H7 — the dedicated-carrier design [P], with executed evidence
Design: a **new static page in the project HyperBook** (`dreyeck/pages/project/`, registered as a static file in `dreyeck.asd` beside the draft dictionary), title e.g. "Regular HyperDoc Catalog Scope Proposal"
(the experiment used the placeholder "Regular HyperDoc Catalog"). It is a **carrier/overview page**, not a CTM source: it declares nothing, says "proposed, not declared", and links the proposals on *Implementation
Assignments*, the draft dictionary and the *HyperDoc Project Workspace* page. The 18 proposals of this scope (Work Item, Deliverable, 6 packages, 6 steps, 4 preconditions) change their `page=` attribute to it; the
other two proposals (`project-work-ctm`, `project-work-ctm-exchange`) keep the Project Workspace page. No relation contract, no Work-model change, no emitter change, no Plan or status change.

**Executed in a scratch clone (H7, then H6+H7), emitter and native Workspace, one process:**
- carried-by edges: still 73 in total; the Project Workspace page carries 10 (was 28) and the new page 18, with exactly the Work Item `topic-maps-regular-hyperdoc` and the Deliverable `tm-regular-catalog` among them.
- gaps: **47 → 45**; `work-item-deliverable-unlinked` **5 → 3**: the two artefacts disappear; the remaining three are the declared precedent, the earlier pair and the intended pair.
- model unchanged: 73 declarations, 79 statements, 8 assignments.
- Workspace navigation (native `topicmap-workspace-go-to`, same walk helper as `tests/project-ctm.lisp:586–605`): hyperbook → dedicated page → Work Item → dedicated page → Deliverable → wp-1 → p1 **passes**; the assignment route to `project-work-ctm` and the Project Workspace page route to `project-work-ctm` still pass.
- the page Topic exists because every carrier is a `hyperdoc-page` Topic (`%page`, `:851`), joined to the declarations by `carried-by` (an edge in `+from-roles+`, `project-workspace.lisp:305`); the hyperbook Topic reaches both pages by `contains-page`.

**The remaining legitimate gap:** `topic-maps-regular-hyperdoc/tm-regular-catalog` stays. A dedicated carrier only makes the co-carrier convention exact; the model records it as "share only their carrier page" and "No Relation Contract defines that relation".
It is closed only by the explicit relation (H1), which this step does not decide, and **the carrier is not an evidence carrier** (H2): it holds no run facts and no evidence entries.

**Placement caveat:** the Stage 2 draft names its carrier "Regular HyperDoc Catalog" in the *Work* HyperBook (`dreyeck/work/reading`), whose page Topic IRI differs from a project-book page. Carrier equality uses the pair, so the proposals' page Topic
is a different Topic from the one Stage 2 would use; since Stage 2 retires the proposals, the project-book page simply ceases to be named. Putting the page in the Work book now would give identical identity but adds a
page to the Work HyperBook before any Work declaration exists; I do not recommend that (H7b: Stage 2 design).

### D.4 Expected effects and the minimum verification
| Change | CTM effect | Gaps |
|---|---|---|
| H6 only | 5 lines (see D.1), new digest | unchanged, 47 |
| H7 only | 18 `carried-by` lines, 2 gap blocks removed, the new page Topic | 47 → 45 |
| H6 + H7 | 37 lines removed, 30 added in the scratch run | 45 |
**Tests that encode the shared carrier:** `scripts/test-project-workspace-scope.mjs:52` hard-codes the row `carried by → HyperDoc Project Workspace` for every proposal; with H7 it would fail. It must be changed to **derive the carrier from the page** (the proposal's `page=`), like its other expectations — a related correction, not a weakening. `dreyeck/tests/project-scope.lisp` names no carrier (grep). Not examined by execution: the other scope assertions after H7.
**Minimum verification after the change** (not run here): regenerate with the emitter; digest equals sidecar; the CTM diff against `ebb44941` has only the lines listed in D.4; the Source stage (345) and the Scope stage (196); one read-and-model (model 73/79/8, 45 gaps, within 90 s); the scope browser walk with the derived carrier expectation. Read-back (224) and Acceptance (125) only if the diff contains more than the listed lines.

### D.5 Open decisions this step leaves
H1 (explicit relation) and H2 (evidence carrier) are untouched and separate. New decisions: **H6** apply the three token edits; **H7** a dedicated project-book page with the 18 proposals pointing to it, its title, and whether the Project Workspace page links to it (a one-line page edit; the Workspace already reaches it through the hyperbook Topic); **H7b** where the Stage 2 carrier lives.

---

## E. Executed H6 + H7 (candidate in the working tree; distinct from the scratch-clone observations of section D)

Baseline `ebb44941`; Topic Maps `88994c1b`. Applied to the worktree, **uncommitted**. Logs, diffs and digests: `docs/regular-catalog-scope/on-88994c1b/h6-h7/evidence/` (with `SHA256SUMS`).
Section D's numbers came from scratch clones; the numbers here come from the worktree itself.

### E.1 What `page=` means in the current model (established before editing) [V]
- A proposal's link `<a page=… hyperbook=… data-proposed-topic=…>` names the **carrier**: emitted as `carried-by` ("The declaration names this page as its carrier (the attribute page). Not a Work relation.", `project-ctm.lisp:753`, `:896–903`; `%carrier`, `:256`).
- The **source authority** is a different association: `proposed-on` ("The page Implementation Assignments proposes the Topic or statement. Nothing is declared.", `:751`, `:901`) for proposals, `declared-on` for declarations, `stated-on` for statements. The Project Workspace page says the same in prose ("*declared on* names the page that declares it, *carried by* the page its declaration names").
- Consequence applied: the new page is described as a presentation/carrier page that **presents and links** and **owns nothing**; the proposals stay written, and authoritative, on *Implementation Assignments* (still `proposed on` it).

### E.2 Exact source changes (7 tracked files, 1 new; 191 insertions, 63 deletions)
1. `dreyeck/pages/project/Implementation Assignments.html`: **H6** wp-1 description and p1 link text (three token edits, section D.1); **H7** the `page=` of the 18 proposals of the scope changed from "HyperDoc Project Workspace" to "Regular HyperDoc Catalog Scope Proposal" (`hyperbook` unchanged); one sentence saying what the carrier is and that the proposals stay authoritative here. The 10 other proposals keep "HyperDoc Project Workspace".
2. `dreyeck/pages/project/Regular HyperDoc Catalog Scope Proposal.html` (new, static): a **presentation page**; no `data-` attribute at all; lists the 18 proposals (IDs and labels copied from the source), links to Implementation Assignments, the draft dictionary, the Project Workspace page and the Workspace reading; says it is no source, declares nothing, owns none of what it lists, and that nothing is declared, accepted or approved; names the Work Item/Deliverable gap and does not close it. It does not decide where a later declaration would be carried.
3. `dreyeck.asd`: the page as a static file of the project HyperBook (comment: presentation page, not a source).
4. `dreyeck/pages/project/HyperDoc Project Workspace.html`: one paragraph with an explicit link to the new page.
5. `dreyeck/tests/project-scope.lisp`: `scope-carrier-tests` (24 new checks, derived from page text and the emitter's CTM): every proposal of the scope names the carrier and none names the Workspace page (negative), unrelated proposals keep it (and none names the scope's carrier), the page lists exactly the proposals that name it, has no `data-` attribute, is registered, linked from the Workspace page and the assignments page, is not a source, is named in the CTM only by `carried-by` and the hyperbook's `contains-page` (never `declared-on`/`proposed-on`/`stated-on`), exactly 18 are carried by it, they stay `proposed on` the assignments page, the Work Item/Deliverable gap remains and the two artefact gaps are absent.
6. `scripts/test-project-workspace-scope.mjs`: the carrier is now **read from each proposal's link** instead of assumed (the literal "HyperDoc Project Workspace" was replaced); each proposal must show exactly its own carrier and not the other (negative); Work Item → carrier page (carried by ← exactly the 18 proposals, none of the 10 unrelated, no declared/proposed/stated on row) → a package → back; an unrelated proposal → the Workspace page → its 10 proposals and none of the scope's; the Project Workspace page links to the carrier page and opens it; the two new pages are among the digests that must stay unchanged. Also an optional `WALK_TIMEOUT_MS` (default unchanged, 600000 ms) used for debugging.
7. `dreyeck/work/project/hyperdoc-project.ctm` and `.sha256`: regenerated by `write-project-ctm` only.

### E.3 CTM identity and diff [obs]
New CTM SHA-256 **`6a54569f9ddbf01ae00e33715d605c0e8ade54b3b6c6d81305d3e68ae519a8b5`** (230,464 octets; sidecar equal; the integration script read the same digest, CTM unchanged by the read). Against `ebb44941` (`346ae792…`): 37 lines removed, 30 added — 18 `carried-by` associations moved to the new page; the new page Topic (`isa hyperdoc-page`, name, hyperbook id, page id) and its `contains-page`; the wp-1 declaration text, the p1 name and its declaration text; the source digest header and `source-sha256` of Implementation Assignments; and the **two artefact gap Topics with their `gap-concerns`**. Identical to the section D prediction (37/30).
Model: **73 declarations, 79 statements, 8 assignments; gaps 47 → 45** (the two artefacts only; no gap added). `work-item-deliverable-unlinked` 5 → 3: the declared precedent, the earlier `project-work-ctm`/`project-work-ctm-exchange`, and the **legitimate** `topic-maps-regular-hyperdoc`/`tm-regular-catalog`, which remains. No new declaration, status, relation or Acceptance Record entry.

### E.4 Verification (finite timeouts, one process at a time, Topic Maps a clean checkout of 88994c1b, unchanged 90-second check) [obs]
| Check | Result |
|---|---|
| Source | `PROJECT-CTM-SOURCE-PASS: 345` (CTM and sidecar equal what the revised pages give) |
| Scope | `PROJECT-CTM-SCOPE-PASS: 220` (196 + 24 carrier checks). A first run failed on **my own** new check (it did not allow the hyperbook's `contains-page`, which every page has); I corrected that check, not the model; the failed log is kept |
| Integration script | PIN-OK; Workspace read and modelled in 20.9 s; model 73/79/8, 45 gaps |
| Browser walk | `PROJECT-WORKSPACE-SCOPE-BROWSER-PASS` with the carrier checks above (two earlier runs failed on my script's own lazy-locator and pane-replacement mistakes; logs kept) |
| **Read-back** | **FAILS in the repository**, see E.5 |
| Acceptance | **not run**: the diff has no acceptance record, criterion, authority or evidence entry (CTM diff above); the productive acceptance/evidence guards sit in the Read-back stage and passed in the diagnostic run below |

### E.5 Unexpected finding: the Read-back preservation guard rejects the intended corrections [obs]
`run-readback-tests` stops at `preserved:no-topic-of-the-committed-revision-lost` (`dreyeck/tests/project-ctm.lisp:442`). The guard compares the CTM with the **committed revision (`HEAD`)** and permits additions only. `preservation-differences` (executed) lists, against `ebb44941`:
`lost-topics` = exactly the 2 artefact gap Topics; `lost-associations` = 6, all `type-instance`/`gap-concerns` of those two gaps; `changed-topics` = exactly `tm-reg-wp-1` and `tm-reg-p1` (H6); `unattributed-additions` = 0.
So **everything the guard flags is the intended outcome and nothing else**; but the guard cannot admit an intended correction (a text fix of an existing Topic, or a derived gap that stops being derived). I did not weaken it.
**Diagnostic only (scratch clone, never committed):** with that guard patched to accept exactly those sets (2 topics, 6 associations, 2 changed topics), the Read-back stage passes **224 checks in 20.6 s**, including the productive no-acceptance/no-evidence guards. So the other 221 read-back checks hold; the repository's Read-back stays red until a decision.

### E.6 Decision this leaves (H8)
How a corrective change may pass the preservation guard: (a) an **explicit, reviewed list of intended differences** per correction step inside the guard (keeps teeth: anything else still fails), (b) rebaseline the guard to a named earlier committed revision per step, or (c) accept a red Read-back until the commit of the correction becomes the new baseline (not acceptable as a committed state). I recommend (a). This also applies to any future text correction after a commit.
Other open items unchanged: H1 (relation contract), H2/H3 (evidence carrier), H4/H5 (plan, statuses), H7b (Stage 2 carrier placement).

### E.7 Not done
No commit; no change to Plan dependencies, statuses, Acceptance Records, Stage 2, an evidence carrier or a Work Item → Deliverable relation. The full Acceptance suite was not run (E.4).

---

## F. The preservation guard and its exact-delta contract (decision H8: explicit allow-list)

Baseline `ebb44941b228cd5c3bb9434229b47ecb168444b4`; Topic Maps `88994c1b`; candidate CTM `6a54569f9ddbf01ae00e33715d605c0e8ade54b3b6c6d81305d3e68ae519a8b5`. Uncommitted. Evidence: `h6-h7/evidence/` (`allowlist-*`, `SHA256SUMS`).

### F.1 The existing guard, read [V] (`dreyeck/tests/project-ctm.lisp`)
- **Baseline selection:** `%committed-ctm` is `git show HEAD:dreyeck/work/project/hyperdoc-project.ctm` — the moving `HEAD`, not a named revision (`:424`).
- **What is preserved** (`preservation-differences`, `:359`): a **Topic** is identified by its first subject identifier; it is *lost* when the baseline has it and the new map has not. An **Association** is its *signature* (type, role-type/player pairs, reifier), counted as a multiset; it is *lost* when the baseline has more of it than the new map **and** it is either of a *derived* type (`type-instance`, `contains-page`, `gap-concerns`, `:232`) **or** the sources still state it. A **derived addition** must involve a new Topic. A **changed Topic** is one whose names or Occurrences (their values included) differ, except the `source-sha256` of a source page.
- **The four losses do not share one semantics** [D]: (1) the two artefact **gap Topics** are *lost topics*: derived Topics that the emitter no longer derives; (2) their **six Associations** (2 × `type-instance` to `plan-gap`, 4 × `gap-concerns`) are *lost associations* of derived types, never excused by the sources; (3) the **two H6 Topics** are *not lost*: they are *changed topics* (a declaration text, and for `tm-reg-p1` also its name), which the guard forbids unless the text equals the baseline's; (4) the **18 relocated `carried-by`** associations appear **nowhere** in the differences: `carried-by` is not derived, the sources no longer state the old ones (so their disappearance is "accounted for by a source change"), and the new ones are not derived additions. The existing guard therefore admits *any* carrier move that the sources justify, silently; the transition below adds the explicit verification of old and new.

### F.2 The invariant (exact-delta contract) [V, implemented]
`dreyeck/tests/project-transition-h6-h7.lisp` states **one named transition as data**, and `oracle-tests` applies it only when all hold: the revision compared with has the project CTM whose SHA-256 is the specification's baseline digest (and the specification's named commit `ebb44941…` has that same CTM: a self-check); and the CTM tested has exactly the result digest `6a54569f…`. Then, and only then, the guard's differences lose exactly the items the transition names **after those are verified**; the residual must still be empty. Otherwise the guard is used unchanged. After the correction is committed the transition no longer applies (the compared revision is then the result), and the file remains the record of what it was allowed to change.
Not a general permission: no wildcard, no "any gap", no "any Topic", nothing derived from `HEAD`.

### F.3 The authorized delta [V]
| Item | Verified in the baseline | Verified in the result | Removed from the differences |
|---|---|---|---|
| gap `work-item-deliverable-unlinked/project-work-ctm/tm-regular-catalog` and `…/topic-maps-regular-hyperdoc/project-work-ctm-exchange` | Topic present; its `gap-rule` text equals the specified rule; exactly its three Associations (type-instance to `plan-gap`, two `gap-concerns`); subjects are a `kind-work-item` and a `kind-deliverable` | Topic absent; the two subjects no longer name a common carrier page (the reason it stopped being derived) | the 2 Topics and their 6 Associations, each required to be present in the differences |
| `tm-reg-wp-1` | exact old declaration-text line | exact new line; nothing else changed | the Topic from `changed-topics`, only if old/new lines equal the specification |
| `tm-reg-p1` | exact old declaration-text and name lines | exact new lines | same |
| carrier of 18 proposals | each `carried-by(id → Project Workspace page)` present | each `carried-by(id → Scope Proposal page)` present; the whole `carried-by` delta is exactly these 18 removals and 18 additions | (not a guard difference; verified for exactness) |
| carrier page | — | page Topic present (and absent in the baseline) with its `contains-page` of the project HyperBook | — |
| legitimate gap `…/topic-maps-regular-hyperdoc/tm-regular-catalog` | — | Topic and all three Associations remain | — |
| model size | — | 73 declarations, 79 statements, 8 assignments, 45 gaps, **counted from the result's Topic Map** and equal to the counts of `build-project-model` | — |

### F.4 Focused controls (27 checks in `run-transition-tests`; run while the working CTM is the result, otherwise it says `NOT-RUN`, which is not a pass) [obs]
Positive: specification equals its commit; applies to (baseline, result); the **unchanged** guard reports exactly the 2 topics, 6 associations and 2 changed topics (and no unattributed addition); no problem and an empty residual after the transition; counts 73/79/8/45; legitimate gap remains; new page is a Topic of its HyperBook; the 18 carrier deltas are exact.
Negative (each mutates the result CTM text, is read, and fails **for its own reason**, asserted by name):
| Mutation | Observed reason |
|---|---|
| an unrelated gap Topic disappears (with its Associations) | in the residual `lost-topics` |
| an unrelated `reads-source` Association disappears | in the residual `lost-associations`, none of the six |
| a permitted Topic (`tm-reg-wp-1`) changes otherwise | problem `h6-change-unauthorized`, and it stays in `changed-topics` |
| the required H6 change is absent (old text restored) | problem `h6-change-absent` |
| one H7 relocation is absent (`tm-reg-wp-3` still on the old page) | problem `relocation-absent` |
| a new carrier relation is wrong (`tm-reg-p2` carried by another page) | problem `relocation-wrong-target` |
| a further relocation (`project-work-ctm` to the new page) | problem `carried-by-delta-has-extras` |
| the carrier page is not in its HyperBook (`contains-page` removed) | problem `carrier-page-missing` |
| another CTM than the named result | `transition-applicable-p` = `result-ctm-differs` |
| an unrelated source revision as the baseline (`d089efe8`) | `baseline-ctm-differs`, and applied directly: `removed-gap-not-in-the-baseline` — nothing excused |

### F.5 Repository results [obs] (one process, finite timeout, Topic Maps a clean checkout of 88994c1b, `asdf:test-system "dreyeck/work/project/tests"`, exit 0)
Source **345**; Read-back **225** (the 224 and one `transition:h6-h7-ebb44941:what-it-names-is-exactly-as-specified`; complete CTM read with the model in **30.4 s** on a loaded machine, against the unchanged 90 s check); Acceptance **125**; Scope **220**; Transition **27**. The Read-back that failed before the contract now passes **in the repository**. Browser walk re-run after the change: `PROJECT-WORKSPACE-SCOPE-BROWSER-PASS` (nothing the walk exercises changed: pages, CTM and walk script are as in its previous pass; only the tests' registration in `dreyeck.asd` and the test files changed).
CTM and sidecar `6a54569f…` (unchanged by this step); no Work page, status, relation contract or Acceptance Record entry changed; the production guard changes are `project-ctm.lisp` (+10/−2: read the compared CTM once, apply a transition only if one applies) and the new file.

### F.6 Remaining limits
The transition self-tests run only while the working CTM is the result (after the commit they report `NOT-RUN`); the production guard is then strict again. A future corrective change needs its own named transition. Open decisions H1 (relation contract), H2/H3 (evidence carrier), H4/H5 (plan, statuses) and H7b (Stage 2 carrier placement) are unchanged.
