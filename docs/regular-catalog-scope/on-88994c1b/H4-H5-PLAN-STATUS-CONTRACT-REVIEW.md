# Zettel 11359 — H4/H5 Plan and Status Contract Review (read-only)

Review of 2026-10-28 at HyperDoc `e766ee42956dcc940961af3fb3d2f60219e63835` (parent `ebb44941…`), Topic Maps `88994c1b…`, project CTM `6a54569f9ddbf01ae00e33715d605c0e8ade54b3b6c6d81305d3e68ae519a8b5`.
Read against `WORK-MODEL-CONTRACT-REVIEW.md` (sections C and E) and `SCOPE-DECLARATION-REVIEW.md`. **Read-only:** no page, test, CTM, Plan, status or Acceptance Record was changed; no test was run; this file is the only new, **untracked** document.
Labels: **[V]** verified source fact (location), **[D]** derived conclusion, **[P]** proposed decision. Paths relative to the worktree; line numbers were checked at this commit.

---

## 0. Summary

1. **The stored graph is 10 `depends-on` edges, 6 `produces` edges and 6 `decomposes-into` edges** (22 proposed statements, read from the CTM's statement Topics, not from prose). It is a chain p1→p2→p3→p4, with p5 and p6 hanging off four preconditions; it is not a linear chain p1…p6.
2. **No scope Topic has a status.** Proposals carry none (the CTM has no `work-status` occurrence on any of the 18 scope Topics). Statuses are **authored** (`data-status`), not derived; the model only **checks** their consistency, and only for a declared plan page. So "the current status of p1–p6" is *none*; what a declaration could consistently carry is derivable (section 4).
3. **p5 and p6 would have to be `blocked`** because each directly depends on an unverified precondition. The rule counts **direct** preconditions only (a quirk, 4.4).
4. **p4 can appear `verified` without the Security Review** and that violates **no existing contract**: only a *proposed* requirement (WP4's acceptance text in a draft dictionary) and WP4's stated authority.
5. **The edge verdicts:** 6 edges are explicit and source-supported; 3 are explicit but rest on a planning assumption (`p4→p3`, `p5→p4`, and conditionally `p5→pre-admission`); `p5→p1` is source-supported but **redundant only because of the two disputed edges** — if either is removed it becomes necessary. One source-supported edge is **missing as a direct edge**: `p6→p4` (WP6's acceptance names "the boundaries of package 4").
6. **The Security Review** is the required evidence of WP4 *and* a gate for activation (WP6). The model can attach it to a step only as a `depends-on` precondition, which the status rule turns into `blocked` for the whole of that step, including the work the review is about. Section 5.

---

## 1. H4 — Plan: the stored declarations

### 1.1 Contracts [V]
| Contract | Declared | Meaning | Role kinds enforced by the plan-page validator |
|---|---|---|---|
| `work:relation/depends-on` | `dreyeck/pages/work/Authoring the CTM Plan Page.html:60`; constant `dreyeck/work/ctm-plan-page-authoring.lisp:59` | "the source step cannot be **completed** before the target step or precondition is satisfied. It asserts an ordering condition only: no scope, status or authority." | plan step → plan step or precondition (`:316–317`) |
| `work:relation/produces` | same page `:61`; `:60` | "the source step yields the target work package, accepted by the criterion in the WBS Dictionary. It asserts what a step is for, not that it may be performed." | plan step → work package (`:315`) |
| `work:relation/decomposes-into` | same page `:59`; `:58` | WBS: scope membership only: "no order, dependency, status or authority" | deliverable → work package (`:314`) |
All three are `draft` (hence the `draft-contract-in-use` gaps). The page states the separation (`:36`): decomposition says what is in scope; dependency and production say what must happen first and what a step yields; status is a separate datum.

### 1.2 The graph, from the CTM [V]
Proposals on *Implementation Assignments*: steps `p1…p6` (lines 57–62), preconditions (63–66), `produces` (69–74), `depends-on` (75–84).
```
produces:   p1→wp-1  p2→wp-2  p3→wp-3  p4→wp-4  p5→wp-5  p6→wp-6            (1:1, tm-reg-*)
depends-on: p2→p1   p3→p2   p4→p3   p5→p1   p5→p4   p5→pre-admission   p5→pre-publish
            p6→p5   p6→pre-security-review   p6→pre-production
decomposes: tm-regular-catalog → wp-1 … wp-6                                   (WBS only)
```
Checked against the CTM: 22 statement Topics, one each; no dependency touches a work package (the scope test `relations:no-dependency-between-work-packages` and the validator `:324–328` enforce 1:1 production). The WBS contains no order and the Plan no scope: the two families are disjoint (`relations:families-are-distinct`).

### 1.3 Transitive structure [D] (computed from the 10 edges)
Redundant by transitivity: **only `p5→p1`** (path p5→p4→p3→p2→p1). Inherited through p5: p6 depends, transitively, on `pre-admission` and `pre-publish` as well.

### 1.4 Edge-by-edge evidence
Classes: **S** declared and supported by source evidence; **A** declared, rests on a planning assumption; **R** redundant by transitivity; **M** supported but not declared directly.
| # | Edge | Class | Evidence |
|---|---|---|---|
| 1 | p2→p1 | S | The Workspace's pin names the revision package 1 integrates (`dreyeck/work/project/project-workspace.lisp:12`) and refuses another root (`pinned-state-p`, `:22`). HyperDoc commit `d9da94d8` moved the manifest, the Catalog/22U/verifier pins and the Workspace pin **in one commit**: the order is conceptual, not historical. WP2 acceptance: "the pin fails for another commit". |
| 2 | p3→p2 | S | WP3's scope is the project work "reachable in the Project Workspace"; the Workspace is p2's product. |
| 3 | p4→p3 | **A** | WP4's scope covers "every view of the Topic Maps readings and the Project Workspace"; WP3's effect is only "what the registered source pages and the emitter derive" (data, not views). Nothing in a contract or a product makes p4 wait for p3; the only reason is review stability (the review should cover the final views). |
| 4 | p5→p1 | S, **R** | WP5 acceptance: the snapshot and the project CTM "verify against their manifests", every `topic-maps.asd` in the registry is the snapshot's; `nix/topic-maps-source.nix:5` (the archive's URL is the intended release location). Redundant only through edges 3 and 5 (below); direct support is real. |
| 5 | p5→p4 | **A** | WP5's scope and effect (Nix declarations of the package, a derivation comparison) do not use WP4's product; WP5 *excludes* deploying. WP6 (not WP5) names "the boundaries of package 4". |
| 6 | p5→pre-admission | **A** (conditional) | WP5: the package carries the Workspace "if the user admits it" and **excludes the decision to admit**; the Catalog's startup guard refuses the Workspace by design (`dreyeck/src/catalog-topic-maps.lisp:43`, `:70`). Required only if the regular Catalog is to serve the Workspace: a scope decision. |
| 7 | p5→pre-publish | S | `nix/topic-maps-source.nix:5`: until the archive is published, only a store already holding the hash can build the packages; WP5 authority names the publishing decision. |
| 8 | p6→p5 | S | WP6's scope is "the package of package 5 staged … and activated". |
| 9 | p6→pre-security-review | S for p6 | WP6 authority: "an independent security review precedes it". Placement: section 5. |
| 10 | p6→pre-production | S | WP6 acceptance: "the user approved the activation"; the precondition text names the user's approval and the operator's record. |
| – | p6→p4 | **M** | WP6 acceptance: the staged instance showed "the boundaries of package 4". Today p6 reaches p4 only through edge 5. |
No edge is unjustified or inconsistent with the stated products [D]. The assumed edges (3, 5) are the ones whose removal or replacement changes the graph's meaning.

### 1.5 Edges 3, 4, 5 together [D]
Edge 4 is **necessary** if edge 5 is dropped, and edges 3/5 are **unnecessary** if p4 is independent of p3 and p5 independent of p4. So "remove the redundant p5→p1" is not a safe stand-alone change: it is redundant relative to the two disputed edges.

---

## 2. H5 — Status rules [V]
### 2.1 What exists
- **Vocabulary:** `open`, `blocked`, `verified` (`ctm-plan-page-authoring.lisp:61`), checked at `:302–305`.
- **Recorded, not derived:** a status is the `data-status` of a declaration; the model's only derived quantities are `step-dependencies` and `step-unmet-preconditions` (`:166–170`: the **direct** dependencies that are preconditions not `verified`), shown in the plan views (`:417–425`, `:473–477`).
- **Consistency rules** (`validate-ctm-authoring`, `:330–339`, applied by `read-ctm-authoring` to the CTM plan page, `:253–267`; the project emitter does not apply them to proposals): `blocked` requires an unmet direct precondition; `open` is refused while one is unmet; `verified` is refused unless **every** direct dependency is `verified`. The page states the intent (`:36`): "blocked while a precondition … is not verified; open when only earlier steps remain".
- **Packages:** no rule ties a package's status to its step's or to acceptance. **Acceptance** is a separate record (`docs/project-acceptance-model.md:17` "Three things, kept apart", D4 `:160`, D5 `:173`); "a work status … stays an occurrence of its declaration".
- **A status is not a maturity claim** (`dreyeck/pages/work/Work Breakdown.html:3`).

### 2.2 Who may change what
- **Proposals have no status and cannot be given one by the status operation:** "Change work status" requires a selected **declaration** with a Work Topic source occurrence; otherwise it refuses (`dreyeck/work/reading.lisp:1076–1090`). The request object is "intent and evidence only; no executor, no permission, no edit" (`:1045–1050`). The plan reading states no grant exists: `authorization-permitted-p` is always false (`ctm-plan-page-authoring.lisp:178`).
- **Explicit owner decisions** [D]: (a) declaring the proposals (WP3 authority: "the user decides whether proposals become declarations"); (b) every status change of a declared Topic; (c) setting a **precondition** verified (admission, publication, production approval are the user's decisions by their own text; the review's source is an independent reviewer's report); (d) confirming a Plan Step for an assignment (the gap `assignment-without-plan-step` fires on a missing `data-ref`, `project-ctm.lisp:642`; the text of an assignment "cannot make one"); (e) any Acceptance Record (D4: never written by an executor).
- **Precedent:** the declared P1 is `verified` "by the user's report" of a production observation, not by a test (`Authoring the CTM Plan Page.html`, plan section).

### 2.3 Four things kept apart [D]
| Thing | Carried by | Stage 1 state |
|---|---|---|
| Implementation evidence | assignments' reported evidence and observed state (commits `d9da94d8`, `e60d10ba`, `bc002546`, runs) | exists, prose notes; reported by the executor |
| Verification | the `verified` status of a declared step/precondition, set by the owner | none (nothing declared) |
| Confirmation | `data-ref` on an assignment's plan-step field naming a (declared) step | none: 8 gaps `assignment-without-plan-step` |
| Formal acceptance | an Acceptance Record for a **declared** package with a **declared** dictionary | none possible (D5); 6 packages proposed |

---

## 3. Reconstructed status of p1–p6 [D]
**Recorded:** none. **What a declaration could consistently carry** under the existing rules, with every precondition unverified (statuses of preconditions are authored too):
| Step | Direct preconditions | Consistent status |
|---|---|---|
| p1 | – | `open`, or `verified` (no dependencies) |
| p2, p3, p4 | – | `open`; `verified` only if its predecessor is `verified` |
| p5 | pre-admission, pre-publish | **`blocked`** (forced) |
| p6 | pre-security-review, pre-production | **`blocked`** (forced) |
Quirk [D]: blocking counts **direct** preconditions only. If p6 had no direct precondition it could be `open` although p5 is `blocked`.

## 4. Why p5 and p6 are blocked; can p4 be verified without the review?
1. **p5/p6:** each has a direct dependency on a precondition that is not `verified` (`:167–170`, `:333–337`). p5: admission and publication (user decisions); p6: the review and the production approval.
2. **p4 verified without the review:** p4's only dependency is p3 (`depends-on` edge 3). The rule `:338–339` therefore permits `verified` once p3 is `verified`, whatever the state of `pre-security-review`, which is attached to **p6**. **No contract is violated**: `depends-on` says what the *source* cannot complete before, and p4 declares no such condition.
3. What it would contradict is **proposed** only: WP4 acceptance ("an independent security review … has been made and leaves no unresolved high finding"), WP4 evidence ("the independent security review's report") and the planned control `tm-reg-security-review`, all in the draft dictionary, which is not a source; and WP4 authority ("neither the executor's tests nor the review accept the package"). A `verified` step is not an accepted package, so the contradiction is between the step's `verified` and the dictionary's wording of what *verified* should rest on.

## 5. The Security Review: placement [V]/[D]
- **Who requires it:** WP4 (acceptance, evidence, control `tm-reg-security-review`, authority "precedes the production decision") and WP6 (authority "precedes" the activation).
- **What it verifies:** the *output* of p4 (public views read-only, run buttons gated, no ASDF loading by a public request).
- **Current placement:** a precondition of **p6** only (`Implementation Assignments.html:83`).
- **Contract fit** [D]: `depends-on` means "cannot be **completed** before …". The review cannot precede the *work* of p4 (it reviews it), but it can precede p4's *completion* and p6's. The model has no completion-only condition: the status rule turns any unverified direct precondition into `blocked` for the **whole** step. Hence:
  - on p6 only: p4 may be `verified` before the review (section 4); correct for p6;
  - on p4: p4 shows `blocked` during its implementation although only its *completion* waits (the page's "open when only earlier steps remain" would not hold);
  - on both: the p6 edge is derived through p5→p4 (redundant) if p5→p4 stays.
- **Which step should depend:** the step whose completion needs it — p4 for its own acceptance, p6 for activation. The model can express the first only with the status side effect.
- **WBS vs Plan** [D]: the WBS says *what* wp-4 contains (the review is part of its evidence, not a separate package: no seventh package); the Plan says *when*. Moving the review into the Plan does not change the decomposition.

---

## 6. Decision options (no edge or status is changed here)
Verified facts are in sections 1–5; everything below is **[P]**.

### Option A — remove only the redundant `p5→p1`; keep the rest
- **Graph:** −1 edge (9 `depends-on`); no new edge.
- **Status derivation:** unchanged (p5, p6 blocked; p4 free of the review).
- **Human decisions:** accept edges 3 and 5 as planning assumptions; accept that p4 `verified` ≠ wp-4 accepted.
- **WBS Dictionary:** none.
- **CTM:** −1 statement Topic (`…/tm-reg-p5/work:relation/depends-on/tm-reg-p1/1`) and its 3 Associations (type-instance, `proposed-on`, the reified `depends-on`); statements 79 → 78; gaps unchanged.
- **Regression:** a named exact-delta transition for the lost Topic and Associations (the guard forbids loss); scope tests unchanged (they are structural: acyclic, closed, one relation per pair); walk unchanged; Source/Read-back/Acceptance.
- **Caveat:** safe only while edges 3 and 5 stand (1.5).

### Option B — keep only evidence-supported edges
- **Graph:** −`p4→p3`, −`p5→p4`, **+`p6→p4`** (9 edges). `p5→p1` becomes necessary and stays. The review stays on p6.
- **Status derivation:** p4 has no dependency (free, parallel to p2/p3); p5 `blocked`; p6 `blocked`; no new quirk.
- **Human decisions:** that p4's review scope may be fixed independently of p3 (or that a re-review is accepted if p3 changes views); that p5 is independent of p4; that p4's `verified` is not the review (the review is evidence of wp-4's *acceptance*).
- **WBS Dictionary:** wp-4 scope could say which views are in scope and when; wp-6 unchanged (it already names package 4).
- **CTM:** −2 statement Topics, +1; statements 79 → 78; 3 Associations per statement changed.
- **Regression:** named transition (2 lost Topics with their Associations, 1 addition verified); **the browser walk assumes one chain ending in a step that waits for a precondition** and would have to read the actual graph; scope tests stay valid; Source/Read-back/Acceptance.

### Option C — place the review at p4 (move)
- **Graph:** **+`p4→pre-security-review`**, **−`p6→pre-security-review`** (10 edges; p6 then reaches the review through p5→p4); `p5→p1` stays redundant.
- **Status derivation:** p4 `blocked` while the review is unverified (for the whole step); p5/p6 still blocked by their own preconditions; consistent with WP4's wording ("not verified without the review") at the cost of showing p4 `blocked` during implementation.
- **Human decisions:** accept that status semantics; accept that edge 5 is now carrying the activation gate (if edge 5 were later dropped, p6 would lose the review as a gate and would need it directly).
- **WBS Dictionary:** none (wp-4 evidence already requires the review).
- **CTM:** −1 and +1 statement Topics (79 unchanged), 3 Associations each.
- **Regression:** named transition; walk: the step list still ends at p6 with a precondition (pre-production), but the text assertion about "last step waits for a precondition" is not tied to the review; Source/Read-back/Acceptance.

### Option D — no graph change; decide the semantics only
- **Graph/CTM:** none. **Decision recorded** (in the review, not the model): p4 `verified` means "implemented and tested"; wp-4 **acceptance** requires the review; both gates stay with the user.
- Leaves the assumed edges and the redundancy as they are; the smallest change, the weakest answer to the placement question.

## 7. Smallest recommended next implementation slice
1. **Decide first, change nothing:** H4a (is p4→p3 a real dependency?), H4b (is p5→p4 one?), H5a (what `verified` of p4 means and where the review gates), H5b (does the regular Catalog serve the Workspace, i.e. is `p5→pre-admission` real?). These four answers pick the option.
2. **Then one slice** implementing the chosen option as a single Stage 1 change: pages → regenerated CTM → a **named exact-delta transition** for the lost statement Topics → scope/walk adaptations where they assume a chain. Preference [P]: **B** if p4 and p5 are independent as the dictionary reads; **C** if the user wants the dictionary's wording enforced by status; **A** only after 4a/4b are settled as "assumptions accepted".
3. Do not combine with Stage 2, H1 or the evidence carrier: each is its own slice with its own review.

## 8. Not done
No edge, status, dictionary entry, test or Acceptance Record was changed; nothing was run. Statements about what the validator or the emitter "would permit" are readings of the code (and of a graph computation over the stored edges), not executions on a declared Stage 2 page.
