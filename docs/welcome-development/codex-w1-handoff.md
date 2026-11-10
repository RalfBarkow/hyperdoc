# Codex W1 implementation handoff (Zettel 11569/11570)

**Source of truth:** [Claude's revised design](claude-revised-design.md), retained verbatim from the user-provided attachment dated 2026-11-10. Sections 1–3 establish the development HTN state/records and FedWiki reuse; section 6 specifies W1; the P0/P1–P11 scenario table is in section 1. This handoff is a separate review supplement, not part of Claude's design.

**Verified starting commit:** `99dbe5599dc6c0b080bec1b743dd864aa5635e0b` on `dreyeck.ch` when this handoff was prepared. Implement on a new feature branch based on this handoff branch, not directly on a stale worktree. Observe the current HEAD before writing; do not infer it from the handoff.

## Authorised W1 scope

Implement only the optional `dreyeck/work/welcome-development` SHOP3 development-planning system, record objects, `development-state`, a next-action view, and focused tests. Reuse `dreyeck/shop3:hyperdoc-htn-plan-result`. Preserve `:plan-only`, native plans, plan trees and states. Reuse existing Inspector, evaluation-record and Topicmap facilities where their contracts fit.

Do not change `dreyeck/shop3:classify-hyperdoc-plan-step` or `dreyeck/shop3:normalize-hyperdoc-plan-step`. Do not fetch Ward's page, execute forks, write Wiki pages, launch agents, merge, deploy or restart services. Do not install executor buttons in the served Catalog.

## Supplementary acceptance conditions

1. **Alternatives:** `:which :all` exposes every next-action choice. The P4 verified/reviewed-but-not-integrated state must offer both the S1 integration proposal and the S2 assignment. Never silently select or execute a plan.
2. **Outcomes:** distinguish `:actionable`, `:awaiting`, `:blocked` and `:complete` at the workflow level; SHOP3 success with `!report-blocker` is not an executable assignment.
3. **Evidence:** agent submission is a claim only. A `dev-verification` with a positive verdict is grounded in the inspected commit, scope and actual test evidence; `workspace-operation-invocation :returned` is not automatically verified. For W1, synthetic records must be explicitly tagged fixtures; do not fabricate actual git or test observations.
4. **Consistency:** reject contradictory positive/negative verification and review records for the same assignment and commit. Record verifier/reviewer identity and enforce reviewer separation from the implementer.
5. **Completion:** add `!report-complete` for the all-four-integrated case. Do not mistake it for another action to execute.
6. **Replanning:** no SHOP3 `planned-*` effect enters the next initial state. Recompute facts solely from accepted records; maintain actual record-object links from the Inspector and Topicmap. Do not overclaim that a record marked `:verified` has already been independently checked when only a fixture was supplied.
7. **Boundary:** no automatic agent orchestration; manual assignment/submission first. No production file system or service effects.

## Test matrix

Run actual pinned SHOP3 tests for the initial P0 and P1–P11 scenarios from the revised design, plus contradictory records, no silent plan selection, blocker/complete classification, and plan-tree generation with `:plan-tree t`. Record test commands, exit codes and observed output. Run existing defederation and local-only regression suites. Report platform-dependent limits separately rather than marking them passed.

## Deliverables

Feature branch and commit SHA; changed paths; exact test evidence; one read-only Inspector entry point; an example of the first planned S1 assignment and a negative example where a mere claim does not unblock S2. Stop after W1. Submit for independent review by Claude Code (Opus, High Effort, read-only).
