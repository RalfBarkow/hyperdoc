# SHOP3 as a planning aid for the Critic workflow — handover

> **DRAFT — work-in-progress checkpoint, 12 November 2026.** Not reviewed.
>
> Complete: the role of the planner, the reuse analysis, the three states of the
> worked case as a design, the mapping from evidence records to proposed
> planning inputs. Outstanding: line references for every row of the reuse
> table; a check of the mapping against the corrected claim-table reader under
> review (`c0b5f8328805ebfaa929f4ff4c2e51052dd39511`); the test handover list in
> its final form.
>
> **Nothing here was executed.** No SHOP3 domain exists for criticism, no method
> was run, no plan was produced. Predicate, task and operator names are
> proposals. The SHOP3 tests of the existing domains were not run for this
> document.

## Role

| Step | Who or what does it | SHOP3 |
|---|---|---|
| Observe sources | probes of the text-criticism slice, run by a person or agent | consumes the results as facts |
| Run an engine rule | the Riesbeck engine through `run-critic-rule` | never |
| Judge, review, accept | a named reviewer; the owner | never |
| Decide what to prepare next | — | proposes every alternative plan |
| Coordinate a correction | implementer, independent verifier, reviewer | proposes the next workflow action |

Two purposes, kept apart: **criticism investigation** (which inspection,
evidence check or independent assessment to prepare next) and **development
workflow** (assignment, submission, independent verification, review,
integration proposal for a correction). In both a plan is a proposal with
`:plan-only`; its effects are `planned-*` atoms no precondition reads; an
execution is a separate record made by whoever executed.

## Reuse analysis

Read at `596344ae95d746f436705808462259371f5a593c`; the conformance planning
domain at `25f83196733a611810da2ea9596af1b4b2d215fb` (draft PR #41, not on
`dreyeck.ch`).

| Existing object | Provides | Reusable? |
|---|---|---|
| `hyperdoc-htn-plan-result` (`dreyeck/shop3/plan-objects.lisp`) | plans, raw plans, plan trees, final states, `execution-mode` default `:plan-only` | yes, unchanged |
| `classify-` / `normalize-hyperdoc-plan-step`, `hyperdoc-plan-checklist` (same file) | sorts steps into source-edit, commit, verification; an unknown operator becomes `:source-edit` | no: an investigation step would be labelled a source edit. `welcome-development` declines it too |
| `plan-development-state` (`welcome-development.lisp`), `plan-state` (`topic-maps-conformance-planning.lisp`) | temporary problem, `find-plans :which :all :plan-tree t :collect-state t`, cleanup | as a pattern |
| `read-case-evidence`, `investigation-state` (conformance planning) | facts only from evidence read at a fixed revision and cross-checked; the goal is a proposal; no absent observation becomes a negative | as a pattern for investigation |
| `(requires ?c ?p)` with `(recorded-prerequisite ?c ?p :incomplete)` → `!report-missing-prerequisite` | a missing prerequisite as a positive, sourced fact | as a pattern; the one to use for evidence |
| `method-names` (conformance planning) | method labels read from the native plan tree | as a pattern |
| `development-record` classes, `accepted-records`, `project-development-records`, `refuse-record` (`welcome-development-records.lisp`) | validated records → facts; `:fixture` and `:observed` never mixed; planned effects refused as input; implementer may not verify or review | as a pattern for a correction's workflow |
| `plan-assignment-binding`, `result-next-action-view` | a chosen action bound to the complete search; every alternative kept, `:execution :not-executed` | as a pattern |
| the `welcome-development` domain | task `(advance-welcome)`; slices `s1`–`s4` named in the domain; records about commits of Welcome slices | no |
| the `conformance-investigation` domain | two fixed CTM cases, CXTM-specific predicates | no |

Neither domain supports Critic investigations, and neither should be extended
for them. `welcome-development` negates over its record ledger, which is sound
there because the validated records are the authority on workflow state. For
evidence about sources, positive status facts are the pattern to follow.

## From evidence records to proposed planning inputs

One criticism `k`. Left: what `criticise-passage` and the records return.
Right: the fact a later projection function would assert. No fact is asserted
from an absent field.

| Evidence record field | Value | Proposed fact |
|---|---|---|
| `:source-state :content` | `:matches-recorded` | `(content-identity k :matches-recorded)` |
| | `:differs` | `(content-identity k :differs)` with the per-file statuses kept as the fact's source |
| `:source-state :revision-binding` | `:verified` | `(revision-membership k :verified <commit>)` |
| | `:not-verified` | `(revision-membership k :not-verified <reason>)` |
| | `:contradicted` | `(revision-membership k :contradicted <reason>)` |
| `:passage :status` | `:present-once` / `:absent` / `:ambiguous` / `:not-observed` | `(passage-status k <status>)` |
| `:claims` | an observation / `:claims-unreadable` | `(claims-status k :read)` / `(claims-status k :unreadable <reason>)` |
| `:discrepancies` | a non-empty list | one `(discrepancy k <assertion-id>)` per entry, and `(discrepancy-scope k <scope>)` |
| | `NIL` | `(reading-borne-out k <scope>)` |
| | `:not-determined` | `(discrepancy-status k :not-determined)` — **no** `discrepancy` atom and **no** `reading-borne-out` atom |
| `judgement` record | present, basis resolved | `(judgement-recorded k <label> <author>)` |
| `recommendation` record | present, `:applied-p nil` | `(correction-proposed k)`, `(correction-status k :not-applied)` |
| a review record (does not exist yet) | — | `(review-status k :none-recorded)` until such a record kind exists |

Rules for the projection: a `:verified` membership fact only from an observation
that says `:verified`; `:recorded-content` never promoted to a revision;
`planned-*` atoms refused as input; a judgement is a fact that a judgement was
recorded and by whom, not a fact that it is right.

## The worked case in three states (a design)

**A — coherent sources, discrepancy observed, no accepted judgement.** Possible
plans, all returned: prepare an independent re-run of the probes; prepare
reading of the cited paper passages; frame the question which side is wrong;
request review if a reviewer other than the judgement's author is recorded,
otherwise report that none is. With `:not-verified` membership an additional
alternative: prepare verification of revision membership. Not to be concluded:
that the page is false, that the judgement is accepted, that a correction is due.

**B — passage missing or changed, sources not the recorded ones, or reading
refused.** Possible plans: report the missing prerequisite (a coherent source
state); prepare re-recording at a named revision. Not to be concluded: that the
discrepancy is resolved, or that it persists.

**C — criticism reviewed, correction proposed, not applied.** Needs a review
record naming the judgement by digest and a reviewer other than its author.
Possible plan: propose that a correction slice be opened, which hands over to a
development workflow. Not to be concluded: that the correction is applied or
correct, that the review is a project acceptance decision, or that the
recommendation's predictions held.

## The next slice

Inputs: the records above for one criticism, plus a new criticism-review record.
One explicit, validating projection function; refusals for mixed revisions, an
unresolved basis, a reviewer equal to the judgement's author, unknown status
values, `planned-*` atoms as input, and a discrepancy supplied together with
`:not-determined`. One task in a new optional domain; all alternatives returned
in a `hyperdoc-htn-plan-result` with `:plan-only`. Tests to be run by someone
other than the implementer, including one that no absent record yields a
negative fact. Based on `dreyeck.ch`, not on the draft PR #41.

## Tests that need independent execution in a complete HyperDoc environment

See [evidence/README.md](evidence/README.md): the integration tests of the text
criticism and the existing federated-context, reading, recorded and critique
test systems were NOT RUN by the implementer.
