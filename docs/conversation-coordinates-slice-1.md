# Conversation Coordinates — Slice 1 (historical implementation report)

Corrections: see `conversation-coordinates-review-corrections.md`. The original
claims below have been corrected in place where the independent review disproved
them; original validation counts describe e1207487, not the correction run.

## Boundary and parent

Local branch `codex/conversation-coordinates-slice-1`, parent
`44ebc23a934b6373b445d88f023332deeafd256c`. Index and working tree were clean
before the branch was created. CTM Slice 7 had already been completed separately
at `17dd58775e25ab495e3c83deb4b5a36f5e5a124b`; this slice changes no CTM source.
Production is neither updated nor reloaded. Local browser servers are stopped
by their tests. Independent review and an operator activation decision remain.

## Evidence and disclosure

Basis: Claude's **Befund: Gesprächskoordinaten in HyperDoc**, 2026-10-16,
Claude-Code session `262d6ca6-81c4-4cd2-b4da-1d4613821702`, report record
`d3a18e51-fabb-43b6-90f2-e331c52dad89`. The original report and selected source
records were read locally. None of their files or private message bodies was
copied into the repository. `coordinates.json` contains only coordinates,
provenance, lengths, hashes and the versioned bindings to existing evidence.

The extraction rule preserves user content strings, concatenates assistant text
blocks without adding separators, and takes `ExitPlanMode`'s `input.plan`.
It does not remove a pasted-content wrapper. Generated summaries are not original
user messages. A user role identifies a transcript envelope, not an authenticated
person. In particular, the author of the content in #20 is not recorded.

| Record | Original UUID | Unicode span | Checked binding |
|---|---|---|---|
| #2 | `ad0fb435-b522-4d96-a3cb-5d632b348096` | `[0,12717)` | Existing `claude-review` document `[1386,14103)`; all existing F1–F11 translate by −1386 |
| #8 | `30fc24fb-6c79-41b1-b043-34ee9895b4ea` | `[0,20961)` | 21,211 UTF-8 bytes, local farm original-report Story Item `516961263b8cdbeb`, SHA-256 `68401649423dc6837b3a25bf0b0f6fb6e4fe57ef3ddf92c721fe106b45d7e936` |
| #16 | `a3503eb6-b352-4e39-8473-7fe547184ab9` | `[218,343)` | Session-user-envelope report: transfer observation → existing `ctm-pre-transfer` |
| #20 | `b3acd503-a1d9-4f44-803e-81dcf173019e` | `[208,437)` | Session-user-envelope report: source observation → existing `ctm-plan-p1`, `ctm-wp-1`; unchanged retained E3 source |

These are Claude-Code UUIDs, **not ChatGPT message IDs**. The complete private
bodies remain absent even when verification succeeds. The Inspector does not
substitute a summary for an original. #8 has an inspectable local-source
reference and historical URL, rather than a copied or automatically fetched Wiki body.
The already retained Planning Case and E3 evidence are reused unchanged.
The report is local to localhost:3000. Claude recorded HTTP 404 for the public
URL on 2026-10-16. Original-source identity is recorded offline PASS; served
checks are NOT-RUN, except retained #2 digest/offsets and local E3 integrity.
#16 is `unwrapped`; #20 is `pasted-wrapper`, as established by the original
paired markers with `id="31d1"` (also on the closing marker). Both authors are
`not-recorded`; input form and session role do not authenticate authorship.
The former contrary classification and offline PASS were a Codex verifier
error, not a Claude-confirmed observation. See `conversation-coordinates-n1.md`.

## Objects, keys and relations

`conversation-session`, `conversation-message`, and `conversation-span` are
ordinary Lisp objects. A span specializes the existing source-occurrence
protocol; its source is NIL, status is `:BODY-NOT-PUBLISHED`, and resolution is
explicitly refused. It is never passed to the Lisp source parser.

Message keys are `(sessionId uuid)`, span keys `(sessionId uuid start end)`.
CTM Subjects now use declaring HyperBook/page and Topic ID. Declaration range,
element digest and page digest separately record the historical revision. Changed
declaration evidence becomes stale without losing Subject identity or navigation. The CTM
reading's optional navigation context and the contextual Work Topic subclass
keep reverse references in their own reading, even if another default reading
exists. Existing F1–F11 subjects are reused by EQ, not rebuilt.

The chronology's selected-event cursor follows the bounded cursor pattern of
`select-context-event`. Federated journal-event classes themselves are
inapplicable to Claude records. The native Workspace owns Point, History and
reprojection; cursor motion does not move Point, and Topic navigation does not
change chronological order.

Finite relation contracts admit `follows`, `retained-as`, and
`reports-observation` only with the checked source/target roles. `follows` means
later selected messages in this session, **not immediate parent adjacency**;
the optional original-source test independently checks the intervening ancestry.
Structural `has-message`, `has-span`, and `source-evidence` now also pass the
closed relation-warrant contract (roles, source identity, warrant, check status). CTM plan and Planning Case edges are reused.

Epistemic status is separate from attribution: the corrected projection uses `derived`
record membership and bindings; `inferred` and `hypothesized` are not
promoted into observations. Envelope, observed format and unverified author attribution are separate. None of these four messages is asserted to decide or
authorize anything. In particular, #20 does not independently verify production.

Exactly one Work item, `conversation-coordinates`, is added, with the existing
`planning contains` and `dogfooding current-work` contracts. No separate WBS is
needed for this bounded reading deliverable. The CTM five-package WBS, its plan,
statuses, dictionary and authorization semantics remain unchanged.

## Inspector entry and routes

Catalog → **Working on HyperDoc** → **Work Breakdown** →
**Inspect Conversation Coordinates** → **Conversation Session**.

1. Chronology → Message #20 → Source span #20 → `ctm-plan-p1` →
   Verified page source (`ctm-wp-1`) → **Conversation sources** → E3 source evidence.
2. From that Conversation sources view → Message #20 / Source span #20;
   the E3 evidence itself also returns to the same source span.
3. Message #2 → Source span #2 → `claude-review` → **Conversation findings** →
   existing F1–F11 → **Revision case** (`collaborative-planning-case`).
4. **Conversation Workspace** exposes the same message objects. Native signs
   move Point; its native Slots view exposes History. CTM Plan and WBS remain
   accessible through the Conversation sources view and their existing pages.

Interactive Common Lisp, in the existing TALA environment:

```lisp
(require :asdf)
(asdf:load-system "dreyeck/work/reading")
(describe (dreyeck/work/conversation-coordinates:conversation))
(dreyeck/work/conversation-coordinates:conversation-workspace)
```

## Validation and reproduction

Actual environment: fresh SBCL 2.4.10 processes, cached Nix dependencies and
D2 0.9.0; Chrome 154.0.8037.98 / Playwright. No external browser requests are
allowed by the new browser test. `conversation-coordinates-validation.json`
records portable command placeholders, result lines, source hashes and browser
results. It contains no original transcript text. The two later checks of the
new views repeat the 230 focused assertions and the browser journey after the
presentation-only E3 line-wrapping adjustment.

`LISP` below denotes SBCL with the pinned dependency registry. Private wrapper paths
and content have been removed from the historical validation JSON.
A normal `nix develop .#tala --offline` SBCL environment provides the equivalent
ASDF registry and D2 dependency. `NODE`, `PLAYWRIGHT`, and `CHROME` identify the
local Node executable, Playwright module directory, and Chrome executable.

```sh
"$LISP" --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/reading/tests")'

"$LISP" --eval '(require :asdf)' \
  --eval '(dolist (s (quote ("dreyeck/fedwiki-page-authoring" "dreyeck/authoring-envelope" "dreyeck/authenticated-page-authoring" "dreyeck/authoring-http" "dreyeck/fedwiki-item-edit-preview"))) (asdf:test-system s))'

"$LISP" --eval '(require :asdf)' \
  --eval '(dolist (s (quote ("dreyeck/local-fedwiki-view" "dreyeck/catalog/tests" "dreyeck/catalog-application/tests" "dreyeck/topicmap/tests" "dreyeck/topicmap/tala/tests" "dreyeck/topicmap/gesture/tests"))) (asdf:test-system s))'

"$NODE" scripts/test-conversation-coordinates.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" /tmp/conversation-browser
"$NODE" scripts/test-hubs-reading-navigation.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" /tmp/retained-hubs
"$NODE" scripts/test-ctm-plan-page-navigation.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" /tmp/retained-ctm
"$NODE" scripts/test-item-edit-preview-activation.mjs "$LISP" "$PLAYWRIGHT" "$CHROME" /tmp/retained-activation

# Originals are optional, explicit read-only inputs, never runtime dependencies.
python3 scripts/verify-conversation-sources.py
python3 scripts/verify-conversation-sources.py --transcript "$CC_TRANSCRIPT" --report "$CC_LOCAL_REPORT_JSON"
```

The first Python call reports original-source checks as **NOT-RUN**, with reasons.
The second was executed locally and verifies the four records, two text
identities, eleven finding offsets, parent ancestry and mutation refusals.
The Lisp suite checks the retained review independently, but explicitly does
not claim to have executed the optional original-transcript / #8 comparison.
Nine source keys were also compared byte-for-byte in two separate Lisp
processes. Existing browser regressions and the new served Catalog test pass;
the new test uses development=NIL, enforced policy and no loaded writer.
Tests of existing writers use temporary test pages only, in separate processes.

## File inventory

- `dreyeck/work/conversation-coordinates-reading.lisp`: bounded objects, keys, projections, native views and Workspace example.
- `dreyeck/work/conversation-evidence/coordinates.json`: metadata-only evidence manifest.
- `dreyeck/pages/work/Conversation Coordinates.html`: question-led reading and native executable links.
- `dreyeck/pages/work/Work Breakdown.html`: one appended Work declaration, two existing relation kinds.
- `dreyeck/work/ctm-plan-page-authoring.lisp`: optional read-only navigation context slot.
- `dreyeck.asd`: reading component, static page/manifest and tests.
- `dreyeck/tests/work-conversation-coordinates.lisp`: 230 focused assertions, including fresh-reading context isolation.
- `dreyeck/tests/work-reading.lisp`: explicit existing/new relationship IDs and endpoint integrity, without a numeric global Topic count.
- `dreyeck/tests/work-deployment-reading.lisp`: reuse that integrity check instead of global counts.
- `dreyeck/tests/work-collaborative-planning.lisp`: remove an obsolete global Work-count claim from the success message; case checks unchanged.
- `scripts/verify-conversation-sources.py`: optional original-source verification; absent originals mean NOT-RUN.
- `scripts/test-conversation-coordinates.mjs`: actual served Catalog browser proof, sources unchanged.
- `docs/conversation-coordinates-slice-1.md`: this report.
- `docs/conversation-coordinates-validation.json`: direct validation evidence, commands and results.

## Remaining boundary

Neither complete ChatGPT history is integrated. Their original message bodies,
verified native message identities and source-backed cross-conversation bindings
are still missing. Claude-Code records do not fill this gap. The smallest next
slice is a read-only inventory and identity check of one explicitly supplied
ChatGPT export; publication review precedes retention of any needed excerpt.

No decision/authority model, writer, CTM change, production Wiki edit, SSH, push,
deployment or production reload is added. A local commit is an implementation
proof only. Activation remains an operator action after independent review;
this reading already belongs to the default Work HyperBook and needs no new
capability or additional Catalog system.
