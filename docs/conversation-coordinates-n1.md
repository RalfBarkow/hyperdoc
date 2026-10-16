# Conversation Coordinates — final N1 correction

Base: `7a383972849b7ff267d6a02d4dff043e26888c78`, observed on
`codex/conversation-coordinates-review-corrections`, clean index and working tree.
Local correction branch: `codex/conversation-coordinates-n1`.
No production activation or history rewrite is included.

## Observation and correction

Read-only inspection of the original JSONL records establishes:

| Message | Session role | Input form | Author | Wrapper coordinates (Unicode characters) |
|---|---|---|---|---|
| #16 | user | `unwrapped` | `not-recorded` | no paste markers |
| #20 | user | `pasted-wrapper` | `not-recorded` | opening `[2,28)`; closing `[1388,1415)` |

The observed opening marker is `<pasted_content id="31d1">`. The actual closing
marker is `</pasted_content id="31d1">`: the transcript repeats the attribute
on the end marker. These are transcript markers, not XML end-tag syntax.
The verifier now checks paired markers, allowing quoted named attributes,
whitespace and either quote style. Closing attributes, when present, must match
the opening attributes. Bare paired markers remain supported. Wrong tag names,
escaped text, unpaired markers, unquoted attributes and mismatched closing
attributes do not establish a wrapper. Extraction itself remains unchanged.
This checks input form, not authenticated authorship or an authorization.

The new synthetic regression uses the observed markers with a fixture body.
The identical test fails against the old verifier from `7a383972` (observed
`unwrapped`, expected `pasted-wrapper`) and passes against the correction.
No original message body is added to the fixtures or public documents.

Manifest origin, closed Lisp binding, Inspector provenance and the reading page
now agree. The manifest integrity pin changes because the corrected metadata
changes. Source keys, UUIDs, session/parent/time/line coordinates, all text
hashes/lengths, evidence ranges, two historical text identities, F1–F11 offsets,
and CTM Work Subject bindings remain unchanged. The Lisp suite checks fresh
reconstruction, object reuse, links and independent chronology/Point/History.

## Correct attribution of evidence

The previous source-verifier run was executed by Codex. Its classification
PASS for #20 was a false positive; attributing that offline PASS to Claude was
incorrect. The historical validation JSON explicitly invalidates that verdict
while retaining its other recorded results. The new manifest's recorded offline
PASS identifies Codex's new local original-source verification. It is not a
served-mode execution or Claude's final independent review.

The report #8 identity is rechecked locally. Its public HTTP 404 remains a
separately attributed historical Claude observation. No new public availability
or production check is claimed. Without explicit original-source inputs the
optional verifier returns NOT-RUN. The served reader has no private-source
lookup and continues to report its original-source checks as NOT-RUN.

## Validation and reproduction

| New execution | Result |
|---|---|
| Observed attributed-wrapper regression against old verifier | FAIL as expected |
| Same regression against corrected verifier | PASS |
| Synthetic source-verifier suite | 9 tests PASS |
| Original-source verification | 4 records, ancestry, both text identities and 11 F-offsets PASS; 10 transcript and 1 report mutation controls |
| No original-source arguments | Both optional original checks NOT-RUN |
| Full Work Reading test-op | PASS; 363 Conversation checks, 9 Python gate tests, 39 PASS markers |
| Served browser: Conversation / Hubs / CTM Plan / Preview | All 4 PASS; native navigation and retained sources unchanged |

No unexpected failures remain in the new executions.

`conversation-coordinates-n1-validation.json` records new executions separately
from historical validation. Full Work Reading runs in fresh SBCL 2.4.10 with the
pinned dependency registry and D2. Browser checks use local Chrome/Playwright,
served Catalog mode (`development nil`) and no production requests.

```sh
python3 tests/test_conversation_sources.py
python3 scripts/verify-conversation-sources.py
python3 scripts/verify-conversation-sources.py \
  --transcript "$TRANSCRIPT" --report "$LOCAL_REPORT_JSON"
"$LISP" --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/reading/tests")'
"$NODE" scripts/test-conversation-coordinates.mjs \
  "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT/conversation"
"$NODE" scripts/test-hubs-reading-navigation.mjs \
  "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT/hubs"
"$NODE" scripts/test-ctm-plan-page-navigation.mjs \
  "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT/plan"
"$NODE" scripts/test-item-edit-preview-activation.mjs \
  "$LISP" "$PLAYWRIGHT" "$CHROME" "$OUTPUT/preview"
```

Private source arguments are optional read-only inputs, never runtime defaults.
The old-verifier counterprobe loads that script with `git show` into an isolated
Python namespace and runs `test_observed_attributed_paste_markers` against it;
then the same test runs against the corrected module. Expected old failure is
regression evidence, not an unresolved failure of the corrected implementation.

Nix rebuild and packaged-artifact rerun are NOT-RUN in N1; the prior Nix evidence
belongs to the earlier commit. N2 and N4 are outside this correction.

## N3 — history remains open (read-only assessment)

No upstream is configured for the new branch. Locally stored
`github/dreyeck.ch`, `codeberg/dreyeck.ch` and `gitweb/dreyeck.ch` point to
`44ebc23a934b6373b445d88f023332deeafd256c`; these references were not refreshed.
Relative to that base, publishing the correction branch would include:

1. `e120748740b3ad4e28b0b7fddda3cb9f9ce72dac` — initial Conversation slice;
2. `7a383972849b7ff267d6a02d4dff043e26888c78` — review corrections;
3. this N1 correction commit.

The earlier validation file in `e1207487` contains nine local-user-path
occurrences. Its removal in `7a383972` does not remove the ancestor's contents.
The reported private-agent-path finding is therefore not closed by N1. Actual
remote reachability/publication status has not been checked.

A possible later delivery procedure, **not executed**, is to create a separate
branch from an agreed clean base, apply the net reviewed changes without merging
the old ancestry, sanitize and inspect every committed tree, rerun regression
checks, and record the original commit hashes and review provenance in a clean
commit message. Keep the current branch locally as review evidence. Such a new
series needs independent review before publication; it does not retroactively
remove any already published objects. No automatic rewrite or publication is
part of this correction.
