# Zettel 11359 — H4a, H4b, H5a, H5b: decision questions (read-only)

2026-10-28, at HyperDoc `e766ee42956dcc940961af3fb3d2f60219e63835`, Topic Maps `88994c1b…`, CTM `6a54569f…`. Starting point: `H4-H5-PLAN-STATUS-CONTRACT-REVIEW.md`, **left byte-for-byte as written** (checked: 19,320 octets, last modified at its writing, no foreign edit visible). This is a separate untracked file. Nothing in the repository was changed or run.
Labels: **[V]** verified source fact, **[D]** derived, **[P]** proposed. Paths relative to the worktree.

**Correction of my earlier review.** I classified `p5→p4` as a planning assumption and recommended Option B (drop it). The sources I read for this step show the dependency is a **content** dependency of the package on p4's code, so that recommendation is **withdrawn** (H4b). The conclusion about `p4→p3` stands but turns out to be **conditional on H5b**.

---

## Order of the questions
H5b decides what the public surface is, and that decides H4a. So the answers below are given in the order **H5b → H4a → H4b → H5a**, and the final graphs depend on H5b.

---

## H5b — does the regular Catalog serve the Project Workspace?
**Verified facts [V]**
- The Workspace is refused by the packaged Catalog's startup guard, by design: `dreyeck/src/catalog-topic-maps.lisp:3–6` ("`hyperdoc-catalog` and its startup … never see topic-maps"; "admitting it to this runtime is a separate, tested decision, so the refusal stays"), `:43`, `:50`, `:70` (`refuse-project-workspace`). The earlier integration documents repeat it: `docs/topic-maps-6162ed68-integration/README.md:56`, `:143`, `:175` ("a separate, tested policy decision that must also measure the 90-second read on the server's hardware").
- The **regular** Catalog (`hyperdoc-catalog`, tested by `nix/catalog-check.nix:9` through `dreyeck/catalog-application`) does not depend on `dreyeck/work/project`: that system is depended on only by its tests (`dreyeck.asd:3373`) and by two separately registered review readings (`topic-maps-integration-review.asd`, `topic-maps-task-1e-review.asd`), which are local, not served.
- The plan itself makes it conditional: WP5 scope: "… and, **if the user admits it**, the Project Workspace and its source pages and CTM"; WP5 **excludes** "the decision to admit the Workspace" (draft dictionary, `Regular Catalog WBS Dictionary.html`, wp-5 scope).
- WP3 acceptance is local: "In a browser session over the project CTM derived from its source pages" (no served instance), and the scope walk and Project suites already show it in a trusted loopback runtime.
- What reads the other way: the title of the Work Item and Deliverable, "Regular HyperDoc Catalog with a **Navigable Project Topic Map**", and WP4's scope sentence "every view of the Topic Maps readings **and the Project Workspace** is read-only on a public request". Neither says the Workspace is served; WP4's sentence is vacuous for a view that is absent.
- If admitted, the Workspace's own views contain plain run buttons: `%go-to` thunks (`dreyeck/work/project/project-workspace.lisp:449`) and "Import revision" (`:541`); the integration review reading has three more (`dreyeck/work/topic-maps-integration-review/code/reading.lisp:271–275`), the 22U reading two (`dreyeck/work/topic-maps-project-example.lisp:146`, `:148`).
**No source supports the assumption that the regular Catalog serves the Workspace.** The edge `p5→pre-admission` records the *possibility*; the sources record the opposite default.

**Owner decision:** admit the Workspace to the served regular Catalog (yes/no), including that it needs a tested policy change and a measured 90-second read on the server.
**Recommendation [P]:** **no, not in this scope.** Consequences: `pre-admission` is not a precondition of this scope (the decision is outside it, and a precondition whose honest answer may be "no" never becomes `verified`, which would block p5 forever); WP5's "if the user admits it" clause and WP4's Workspace wording get an explicit exclusion; navigation of the project work stays local (WP3 as written). If the owner says **yes**, the graph in "Final graph B" applies.
**Does Option B suffice?** Not the earlier Option B: it was built on a wrong H4b. See the final graphs.

---

## H4a — does p4 depend on p3?
**Products [V]:** p3 → WP3: project work reachable in the Workspace and Inspector as Topics and Associations of the CTM, down to commits and runs, plus "the HyperDoc reading in which a human follows the integration"; effect: "only what the registered source pages and the emitter derive … adds the draft dictionary and, after the user's decision, the declaration pages". p4 → WP4: read-only public views; plain run buttons gated or absent; no page-attached system loading; effect: "the authority policy and the public routes of the Catalog application and the reading systems' run buttons, and … their tests".
**Is completion of p3 materially necessary for p4?**
- *Not admitted* [D]: no. p3's products (CTM content, local Workspace data, review readings) are not on any public surface because the guard refuses them (H5b facts). p4's work concerns the Catalog application, the authority policy and the buttons of readings that can be served. The dependency is then only a scheduling assumption (finish the content before reviewing).
- *Admitted* [D]: yes, partly: the Workspace views and their buttons become public surface, so p4's verification (and the review's scope) should cover the **final** views, i.e. after p2/p3; and the data p3 puts into the Workspace becomes publicly readable.
**Owner decision:** admission (H5b). **Recommendation [P]:** drop `p4→p3` under "not admitted"; keep it (or `p4→p2`, `p4→p3` as written) under "admitted".
**Consequence:** p4 becomes independent of p3 (parallelisable) under "not admitted"; status derivation: p4 has no dependency, so `verified` needs nothing else from the plan.

---

## H4b — does p5 depend on p4?
**Facts [V]:** WP5's result is "the regular HyperDoc Catalog package … built **from the committed tree**", whose derivation must differ from the previous production package "only as the declared changes require" (wp-5 acceptance). WP4's effect changes "the authority policy and the public routes of the **Catalog application**" and its tests; the Catalog application is part of what the package builds and checks (`nix/catalog-check.nix:9` tests `dreyeck/catalog-application`). WP6 acceptance requires the staged instance to show "the boundaries of package 4".
**Can p5 produce its result before p4 is complete?** [D] It can produce **a build**; but the package built before p4's code lands lacks the declared changes of p4, so it is **not the package that p6 may stage**: it would have to be rebuilt. The plan has no "rebuild" step, so the honest dependency is a **content dependency**: the package contains p4's work.
**Distinguish p6** [D]: p6 may not complete before p4 (its acceptance names p4's boundaries). With `p5→p4` kept, `p6→p4` is already derived through p5; no direct edge is needed.
**Owner decision:** whether p5 may be accepted as a *provisional* build ahead of p4 (then `p5→p4` can be dropped and `p6→p4` must be added); otherwise the package includes p4.
**Recommendation [P]:** **keep `p5→p4`**, as a content dependency, and say so in WP5's text ("built from the tree that contains package 4's changes"). Consequence: p5 cannot run in parallel with p4; no new edge; `p6→p4` stays derived.
**Does Option B suffice?** No: dropping `p5→p4` would add `p6→p4` and permit a package accepted without p4's code.

---

## H5a — the Security Review
**The four notions kept apart, and what the existing model can represent without a new contract**
| Notion | Existing representation | Enforced by the status validator? |
|---|---|---|
| prerequisite to **beginning** the review work (p4's implementation exists) | **none.** The review is part of p4 (the p4 step reads "Verify and enforce public Inspector security … an independent review"); the WBS/Plan is 1:1 (`ctm-plan-page-authoring.lisp:324–328`), so there is no step or package for "the review" | no |
| **evidence required for verifying WP4** | the dictionary: wp-4 `evidence` ("the independent security review's report"), acceptance ("… has been made and leaves no unresolved high finding"), the planned control `tm-reg-security-review` | **no**: the validator reads statuses and edges (`:330–339`), not dictionary evidence; a package's status is not tied to its evidence |
| **prerequisite to completing p6** | `p6 depends-on pre-security-review` (`Implementation Assignments.html:83`), contract "cannot be completed before" | **yes, as `blocked`**, but only on a *declared* plan page read with `validate-ctm-authoring` (`:253–267`, `:296`); the project emitter does not apply it to proposals, and whether a Stage 2 carrier page is read with it is **not established** |
| **formal acceptance of WP4** | an Acceptance Record on a **declared** package with a **declared** dictionary, considering identified evidence (`docs/project-acceptance-model.md` D2, D4, D5) | no; and identified evidence is blocked on the productive page by the two guards (H2) |
Also [V]: the precondition's own text is only "a report by a reviewer who is not the executor"; "no unresolved high finding" belongs to WP4's acceptance. So a *verified* `pre-security-review` means "an independent report exists", not "the review passed".
**What stays an owner decision [V]:** setting any status (only through "Change work status" on a declaration; `authorization-permitted-p` is always false, `:178`); verifying the precondition; accepting WP4 (never the executor, D4).
**Can p4 appear `verified` without the review?** Yes under the validator (its only dependency is p3), with **no contract violated** [V]. The requirement "WP4 verified only with the review" is **proposed** in a draft dictionary; it is **not** implemented by the validator and cannot be without a new contract or a step split.
**Recommendation [P]:** keep the review as a precondition of **p6** (the one place the model enforces it) and record the p4 requirement as an **owner rule**, as the precedent does for P1 (`verified` "by the user's report"): p4 is set `verified` only on the user's report that includes the review report; WP4 is accepted only by an Acceptance Record that considers it. This is a **separate H5 requirement that no dependency graph resolves** (it is an authorization/verification rule); Option C (review as a p4 precondition) would add it to the graph at the price that p4 shows `blocked` for its whole implementation.

---

## Final proposed dependency graphs (nothing applied)
`produces` (6, 1:1) and `decomposes-into` (6) unchanged in both.

**Graph A — recommended (Workspace not admitted in this scope), 8 `depends-on` edges:**
```
p2→p1   p3→p2   p5→p1   p5→p4   p5→pre-publish   p6→p5   p6→pre-security-review   p6→pre-production
```
Changes from today: **−`p4→p3`**, **−`p5→pre-admission`** (and the proposal `tm-reg-pre-admission`, otherwise the scope test "every precondition is waited for" fails; its decision is outside the scope). `p5→p1` is **no longer redundant** (p4 no longer reaches p1) and stays. p4 is independent of p3. p5 blocked by `pre-publish`; p6 blocked by `pre-security-review` and `pre-production`.

**Graph B — if the owner admits the Workspace, 9 edges:**
```
p2→p1   p3→p2   p4→p3   p5→p4   p5→pre-admission   p5→pre-publish   p6→p5   p6→pre-security-review   p6→pre-production
```
Change from today: **−`p5→p1` only** (redundant through p4→p3→p2→p1). Statuses: p5 blocked by admission and publication, p6 by review and approval.

**Neither graph adds** `p6→p4` (derived through p5→p4) or moves the review.

## Separate status and verification requirements (not graph changes)
1. p4 `verified` only on the user's report including the independent review report; WP4 accepted only by a record (H5a).
2. Initial statuses: p5 and p6 `blocked` (direct unverified preconditions); p1–p4 `open` or, only on the owner's report, `verified`; no status without a declaration.
3. A precondition that can legitimately be answered "no" (admission) is a decision, not a precondition; its outcome belongs in the scope text (H5b).
4. Whether the Stage 2 carrier page is validated by `validate-ctm-authoring` (and with which controls) is not established (H5a table).
5. Plan-step confirmation for the assignments (`assignment-without-plan-step`) stays an owner act after declaration.

## Expected CTM and regression effects (for whichever graph is chosen)
- **Graph A:** −2 `depends-on` statement Topics (each with its `proposed-on`, reified `depends-on` and type-instance Associations: 3 Associations), −1 precondition Topic with its declaration Associations and its `p5→pre-admission` statement; statements 79 → 77; one fewer declaration. Needs a **named exact-delta transition** for the lost Topics/Associations (the guard forbids loss), scope-test review (the precondition list is derived; the "every precondition is waited for" check holds once the Topic is gone), walk unchanged in shape (the chain p1…p4 ending at p5/p6 still ends in a step with a precondition), Source/Read-back/Acceptance/Scope. WP4/WP5 texts gain the explicit exclusion; the dictionary changes alter no CTM (not a source).
- **Graph B:** −1 statement (79 → 78), same kind of transition, walk unchanged.

## Not done
No edge, status, declaration, dictionary entry, test, CTM or Acceptance Record changed; nothing was run. Statements about what the validator or emitter would do are readings of the code.
