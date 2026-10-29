# One Codex report in the Project Workspace

Task baseline: HyperDoc `573fe37611a61d984260ebf43c797f7534211bdd`.
Task branch: `codex/codex-ctm-project-evidence`.
Topic Maps pin remains `88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`.

## Authored representation

The assignment `codex-2026-10-29-template-identity-substitution` on
`dreyeck/pages/project/Implementation Assignments.html` records the
operator-supplied account of the previous investigation. Its ten stable
`data-evidence` entries distinguish original source, corpus expectation,
reported reader behavior, expanded control, two competing readings, unresolved
question, unresolved contracts, execution boundary and uncommitted note.
They report the earlier task; they are not newly executed test reports.

The existing emitter already makes an assignment Topic and reifies each
identified evidence occurrence with an Evidence entry Topic. The native
Workspace already draws those reification links and presents the evidence's
assignment and text. No new vocabulary, emitter, Inspector view or independent
graph is required. The assignment links to its authored source page through
the existing declared-on and reads-source Associations.

No source declares a relation to an existing Work Item or Deliverable.
Consequently this entry has no data-ref for either relation, creates no Work
declaration or proposal, and records no plan-status or acceptance decision.
The previous decision note is present locally as an uncommitted Topic Maps
file. Its existence does not establish immutable provenance; no hash,
publication URL or commit for that note is invented here.

## Focused verification prepared

From the repository root in the pinned Lisp runtime, with the dependency ASDF
registry, this HyperDoc checkout and the verified Topic Maps snapshot selected:

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-codex-project-evidence.lisp
```

Use the immutable snapshot rather than changing or cleaning the separate Topic
Maps checkout: the earlier user's uncommitted note remains there. The runner
calls the existing WRITE-PROJECT-CTM, which records source paths and SHA-256
identities in the CTM header and writes the derived file's digest beside it.
It then invokes the existing focused source/read-back/acceptance test entrypoint;
the new case checks execute inside the read-back test's existing reading.

The case checks require native assignment/evidence Topics, reified occurrence
values and parent/reifier identity, source-page Association Roles, navigation
from assignment to evidence and back, native object references in Inspector
views, distinct unresolved interpretations, three still-NOT-RUN contracts,
and preservation of unrelated authored Work and assignment statements. They
introduce no fixed global Topic or Association count. Existing tests check
deterministic regeneration, source attribution, original-octet export and CXTM
equivalence with fixed Document IRI/base locator.

The old productive-project assertions assumed no authored evidence IDs at all.
They now check that occurrence reifiers are exactly the authored evidence
entries and that earlier assignments were not retrofitted. Similarly, existing
acceptance-schema definitions are distinguished from decision instances and
relations: identified evidence needs that schema but creates no acceptance.
These are explicit source-model changes, not adjustments of expected totals.

## Current execution boundary

Preparation is not acceptance or a completed roundtrip. At this stage the
pinned SBCL dependency build failed because beta.quicklisp.org and
tarballs.nixos.org returned HTTP 403. The two required destinations were saved
additively in the environment draft; saving does not apply or publish them.
The runtime build must succeed before running the command above.

No focused Lisp test, native read-back, Inspector navigation or CTM regeneration
has been executed for this change yet. The retained CTM and its digest still
describe the previous authoritative pages until the existing writer runs.
No local task commit is permitted before those checks pass.

Keep these claims separate when recording the eventual results:

1. CTM regenerated from authored pages is source materialization.
2. CTM read into native TMDM is deserialization.
3. Export of retained CTM octets is unchanged-source export.
4. Serialization of a modified TMDM Map into CTM is not implemented or claimed.

No previous reader observation is promoted to an independently reproduced
fact or a normative decision by any of these integration checks.
