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

## Focused verification

From the repository root in the pinned Lisp runtime, with the dependency ASDF
registry, this HyperDoc checkout and the verified Topic Maps snapshot selected:

```sh
sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load scripts/test-codex-project-evidence.lisp
```

The actual run used a disposable clean Git checkout at the exact Topic Maps
pin; the separate user checkout and its uncommitted note were untouched. The
runner calls the existing WRITE-PROJECT-CTM on a temporary materialization,
then invokes the focused source/read-back/acceptance test entrypoint. Only
after all checks pass does it regenerate the retained CTM and digest, requiring
the retained octets to equal the tested temporary materialization. Source paths
and SHA-256 identities are recorded in the CTM header. The new case checks
execute inside the read-back test's existing reading.

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

## Executed results and launcher diagnosis

Verified on 2026-10-29 using SBCL 2.4.10. The updated network policy was current
and enforced; the exact formerly blocked Fast WebSocket source returned HTTP
200 over both HTTP and HTTPS. The GitHub API also became accessible. These are
current observations, not an inference from saved allowlist entries.

Nix-portable had cached its namespace-based runtime. It could not launch the
Lisp shell in this container (`setting up a private mount namespace: Operation
not permitted`); the supported proot alternative also failed before executing
a command. The already-built SBCL runs directly through its matching glibc
loader with an explicit core and relocated ASDF/library search paths. Library
relocation is passed to the loader only, not exported to child Git commands.
SQLite's matching zlib directory is included. This environment configuration
changes no production code, source pin or identity assertion.

The runner itself also contained an unsupported UIOP API:
WITH-TEMPORARY-DIRECTORY. It now uses WITH-TEMPORARY-FILE to reserve a unique
name, creates an owned staging directory, and removes it with UNWIND-PROTECT.
No assertion, expected result or timeout was relaxed.

| Completed focused suite | Result |
| --- | --- |
| Source/emitter | 339 assertions passed |
| Native read-back, CXTM and Inspector/Workspace navigation | 290 assertions passed |
| Acceptance fixtures and preservation | 125 assertions passed |
| Overall runner | exit 0, CODEX-PROJECT-EVIDENCE-PASS |

Read-and-model time was 10.6 seconds, within the unchanged 90-second assertion.
The 754 assertions include the ten attributed native evidence objects, their
occurrence reifications and parent identity, source Association Roles,
assignment/evidence navigation, unresolved contracts, no Acceptance Record,
and preservation of unrelated authored Work and assignment statements.

After successful verification, the retained CTM and digest were regenerated.
CTM SHA-256: `8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d`.
The source identity recorded for Implementation Assignments is
`0d755af7b32bd02c30d41573afc9956767c8027e0e7fb79f20affa294cc1e463`.

[Complete successful output](evidence/codex-project-evidence/focused.log),
[runtime, source roots and tested-file hashes](evidence/codex-project-evidence/runtime.json),
and [the exact external launcher used](evidence/codex-project-evidence/launcher.py)
retain the evidence. The launcher records this restored environment's paths;
it is not a general installation script. Earlier failed attempts were setup
diagnostics, not successful test runs.

The demonstrated roundtrip properties remain distinct:

1. Deterministic CTM regeneration from the authored pages.
2. Deserialization into native TMDM and CXTM equivalence under the same Document
   IRI/base locator, `tag:dreyeck.ch,2026:hyperdoc/project.ctm`.
3. Unchanged-original-octet export, verified separately from semantics.
4. Serialization of a modified TMDM Map into CTM is not implemented or claimed.

Inspector views and native Workspace navigation were exercised in Lisp; this
run does not claim a graphical browser acceptance test. No full CTM/XTM corpus,
Topic Maps performance suite, production Catalog or deployment was exercised.
Dependency load warnings remain in the complete log. The prior investigation's
normative question and three NOT-RUN contracts remain unresolved; these focused
integration tests do not reclassify them or grant acceptance.

No previous reader observation is promoted to an independently reproduced
fact or a normative decision by any of these integration checks.
