# Conversation Coordinates — review corrections

Basis: clean `codex/conversation-coordinates-slice-1` at
`e120748740b3ad4e28b0b7fddda3cb9f9ce72dac`, index and working tree observed
before creating `codex/conversation-coordinates-review-corrections`.
Authority for this correction: Claude's complete independent review,
2026-10-16, record `1a22c33a-59b8-4eec-bb15-dca10d671e82`, verdict **Revise**.
The private review body is not added here. This is a local correction, not an
activation or a new conversation infrastructure.

## Disposition of every finding

| Finding | Correction and evidence |
|---|---|
| H1 | Stable Subject key `(work-subject/v2, HyperBook ID, declaring page title, Topic ID)`. Historical declaration range, declaration-element SHA-256 and page revision SHA-256 are separate fields. Current evidence compares the declaration element; editing another declaration or moving its coordinates does not lose the Subject. Editing the referenced declaration yields `stale`, retaining historical references. Actual Change-work-status probes pass on temporary page copies and in a complete disposable checkout using default `read-conversation`. |
| H2 | Report #8 is a **local farm** reference at `localhost:3000`. The former public URL is displayed as a historical locator, without an external link. Recorded public availability is FAIL/HTTP 404, 2026-10-16, attributed to the review; current external availability is NOT-RUN. The locally checked #8 identity is unchanged. |
| M1 | Chronology, message/span, CTM source and report views distinguish `checked here`, `recorded offline PASS` (date and executing checker; corrected by N1), and `NOT-RUN`. Runtime #2 checks only the retained digest and F1–F11 offsets; runtime E3 checks the retained local copy. The original transcript and #8 report comparison are NOT-RUN in the served reader. Synthetic source-verifier tests are now gates in Work test-op and the Nix Catalog check. |
| M2 | N1 corrects the former claim that both user records were unwrapped. #16 is `unwrapped`; #20 has paired `pasted_content` markers carrying `id="31d1"`, including the closing marker, and is `pasted-wrapper`. Both have `role=user`, source `origin.kind=human`, `promptSource=sdk`, author `not-recorded`. Wrapper format does not authenticate authorship. The earlier offline verifier PASS was Codex execution with a faulty wrapper check, not Claude confirmation of that classification. See the N1 report and validation. |
| M3 | E3 observation site is `localhost:3000`, the origin established in the review. Matching bytes on `dreyeck.ch` remain a report in #20, with author not recorded; no production observation is claimed. |
| M4 | The historical validation JSON's private paths and wrapper contents are redacted. New evidence uses portable command placeholders and digests. Changed publishable artifacts and the built source were inspected. No new message body or private agent directory is packaged. |
| L1 | #16 evidence span is `[218,343)`; #20 is `[208,437)` (Unicode characters). These bound the relevant source references. #2 `[0,12717)` and #8 `[0,20961)` deliberately remain whole-text identity comparisons. Full-message lengths/digests are retained separately. No quoted text is added. |
| L2 | Work integrity again compares closed semantic sets of Topic IDs and Association IDs, with uniqueness and endpoint checks. It rejects both missing and unexpected subjects/edges; no global Catalog count was introduced. |
| L3 | Real #8 report validation and mutation control call the same function: item selection, octet length, digest and equality with the extracted message. Supplied malformed/non-JSON responses produce structured FAIL and nonzero exit; unavailable originals yield NOT-RUN. Synthetic tests include HTML 404, broken JSON, invalid encoding, JSON null/array, wrong/duplicate item and wrong message. |
| L4 | All six introduced relation types (`has-message`, `has-span`, `follows`, `retained-as`, `reports-observation`, `source-evidence`) pass one closed contract with source/target roles, source key, warrant, attribution and binding/check status. Wrong directions, foreign objects, wrong targets, altered metadata, spans and E3 copies are refused. Imported Work/CTM/Planning edges retain their existing contracts. |
| L5 | Work Topic Conversation sources is secondary (priority 1000). Regression tests compare its first view with an ordinary native carrier for both affected Work Subjects. Existing CTM Plan/WBS default views remain unchanged. |

`current` means the observed declaration element still matches the historical
binding. It does not authenticate authorship, verify all prose in a mutable page,
or repeat an original-source/network check. An existing session remains a
reading of its observed snapshot. A fresh reading obtains current declarations;
its historical evidence is not silently rewritten. Renaming/removing a Subject
identifier is not an automatic identity migration; structural errors and foreign
addresses remain refusals, never a fallback to another Subject.

## Counterprobes and preserved identity

| Real status operation in disposable sources | P1 | WP1 | Reading/navigation |
|---|---|---|---|
| `ctm-wp-5`: open → blocked | current | current | PASS |
| `ctm-wp-1`: verified → blocked | current | stale | PASS |

Both probes check contextual and ordinary Inspector views, chronology, existing
P1 → WP1 relation, Workspace rendering, Point/History and cursor independence.
The complete-checkout probe also keeps the default cached session alive while
reconstructing through the default file-reading entry point. Repository plan,
dictionary, Work Breakdown and retained evidence files are unchanged.

The four original UUID/session/parent/time/line/text identities remain unchanged.
A fresh source check again passed all four originals, selected ancestry, both
text identities and eleven F offsets; 10 transcript mutations and one actual
report-path mutation were refused. With no private inputs, both original checks
report NOT-RUN. The public 404 is review evidence, not a new HTTP observation.

F1–F11 still reuse the original Lisp objects by EQ. No Writer is in the Catalog
load closure. Message bodies remain unavailable (`:BODY-NOT-PUBLISHED`), with no
resolution through a Lisp parser. No existing Work Subjects were duplicated.

## Historical validation executed before N1

These counts describe the earlier correction. The origin-classification PASS for
#20 was a false positive, superseded by `conversation-coordinates-n1.md`. The
source verifier was executed by Codex; attributing its PASS to Claude was wrong.
Other historical results are retained, not presented as new N1 executions.

Fresh SBCL 2.4.10, pinned Nix runtime, D2 0.9.0; Chrome 154.0.8037.98.
The final Work, authoring and Catalog gates exited 0. The authoring environment
was explicitly the existing pinned workflow editor; writes only affected test
fixtures. `conversation-coordinates-review-validation.json` records commands,
log digests, PASS markers and browser evidence without private paths.

- Full Work reading test-op: PASS, including **353** Conversation assertions,
  CTM plan tests (12 refusals and one admitted progress), Planning Case and
  deployment/reading regressions.
- Source-verifier synthetic gate: **7 tests PASS** (also executed by Work and Nix).
- Full Work authoring test-op: PASS, including the two real status operations.
- Page authoring, envelope, authenticated authoring, HTTP and edit-preview:
  all five test-ops PASS.
- Local FedWiki view, Catalog, Catalog application, Topicmap, TALA and gestures:
  all six test-ops PASS.
- Four local browser journeys: PASS (Conversation, Hubs, CTM Plan, Preview).
  Conversation checks #8's local/404/NOT-RUN display, the full E3 and F3 paths,
  actual History values via Slots → Items, retained Point and cursor #8.
- Built Nix Catalog: PASS, same Conversation journey, source without `.git`,
  with private agent directories denied and denial positive controls passing.
  The four inspected packaged files matched the checkout. No private paths
  occurred in the changed publishable artifacts.
- Native `checks.x86_64-darwin.catalog`: PASS, including synthetic source tests
  and packaged executable startup/shutdown checks.

Two preliminary failures are retained as such in the evidence: authoring without
its required pinned capability was refused, then passed with the correct shell;
a Hubs browser attempt timed out on “Codex Plan v1”, then passed with unchanged
assertions and additional failure diagnostics. Its timeout cause was not
established. An accidental aarch64 Nix check could not build uncached dependencies
offline: its tests are NOT-RUN; this report claims only the native x86_64 check.

## Reproduction

`LISP` denotes SBCL with the pinned `.#tala` dependency registry and D2 on PATH;
`AUTHORING_LISP` denotes the existing `.#workflow-authoring` environment.
Node, Playwright and Chrome are explicit local test dependencies. Private source
arguments are optional, read-only inputs; no runtime default points to them.

```sh
"$LISP" --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/reading/tests")'
"$AUTHORING_LISP" --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/authoring/tests")'
"$LISP" --eval '(require :asdf)' \
  --eval '(dolist (s (quote ("dreyeck/fedwiki-page-authoring" "dreyeck/authoring-envelope" "dreyeck/authenticated-page-authoring" "dreyeck/authoring-http" "dreyeck/fedwiki-item-edit-preview"))) (asdf:test-system s))'
"$LISP" --eval '(require :asdf)' \
  --eval '(dolist (s (quote ("dreyeck/local-fedwiki-view" "dreyeck/catalog/tests" "dreyeck/catalog-application/tests" "dreyeck/topicmap/tests" "dreyeck/topicmap/tala/tests" "dreyeck/topicmap/gesture/tests"))) (asdf:test-system s))'
python3 tests/test_conversation_sources.py
python3 scripts/verify-conversation-sources.py
python3 scripts/verify-conversation-sources.py --transcript "$TRANSCRIPT" --report "$LOCAL_REPORT_JSON"
"$NODE" scripts/test-conversation-coordinates.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT"
"$NODE" scripts/test-hubs-reading-navigation.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT_HUBS"
"$NODE" scripts/test-ctm-plan-page-navigation.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT_CTM"
"$NODE" scripts/test-item-edit-preview-activation.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT_PREVIEW"
nix build .#hyperdoc-catalog --offline --no-link --print-out-paths
nix build .#checks.x86_64-darwin.catalog --offline --no-link
# Optional: set HYPERDOC_CATALOG_EXECUTABLE to the built executable (or a
# denial-control wrapper) and repeat the Conversation browser command.
```

Inspector entry: Catalog → Working on HyperDoc → Work Breakdown → Inspect
Conversation Coordinates → Conversation Session. No server is left running.

## File inventory and remaining boundary

Implementation: `dreyeck/work/conversation-coordinates-reading.lisp`,
`dreyeck/work/conversation-evidence/coordinates.json`,
`dreyeck/pages/work/Conversation Coordinates.html`.
Tests/gates: `dreyeck/tests/work-conversation-coordinates.lisp`,
`dreyeck/tests/work-authoring.lisp`, `dreyeck/tests/work-reading.lisp`,
`tests/test_conversation_sources.py`, `scripts/verify-conversation-sources.py`,
`scripts/test-conversation-coordinates.mjs`,
`scripts/test-hubs-reading-navigation.mjs` (failure diagnostics only),
`dreyeck.asd`, `nix/catalog-check.nix`.
Evidence/docs: this report, `conversation-coordinates-review-validation.json`,
corrected historical `conversation-coordinates-slice-1.md` and redacted historical
`conversation-coordinates-validation.json`.

Both complete ChatGPT source histories and verified cross-conversation message
identities remain missing. #20's content author and independent production byte
comparison remain unverified. External report availability is not rechecked.
There is no new authority grant or disclosure decision inferred from a relation.
The existing selected metadata remain; production publication/activation awaits
operator approval after Claude's renewed independent review. No message text,
HyperDoc feature beyond this bounded reading, Wiki edit, SSH, push, deployment or
production reload was added.
