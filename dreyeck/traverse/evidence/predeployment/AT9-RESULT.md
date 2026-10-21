# AT-9 result (2026-10-20)

Scope of the release: AT-9 only (edit through the existing wiki editor, stored page, journal, re-read, changed EXTRACT/TRAVERSE result, site B untouched). AT-8 (Solo display and navigation) and AT-14 (isolated Solo dependencies) were not part of it and remain open. STATUS.md is unchanged; this file adds to it.

**Verdict: AT-9 passes, 15 of 15 checks** (`results/at9-report.json`, computed by `e2e/at9-report.mjs` from `results/at9.json` and the files on disk). Raw evidence: `results/at9.json`. One check failed at first for a reason of my own expectation, see "Corrections during the run".

No change to the Mech implementation (`src/discourse-traverse.mjs` `18cc68ee…`, `src/discourse-entry.mjs` `2b20b362…`, discourse bundle `19b14c31…`, served by the test wikis and byte-identical to the staged artifact). No download. No other wiki, host or branch touched; nothing committed or pushed. The only non-GET request of the whole run was the one PUT to `localhost:3021`; 0 requests were blocked; site B logged no PUT, POST or DELETE.

## What was done

1. Both wikis started from the unchanged seed data (all 8 page files equal `seed-manifest.json`), `localhost:3021` (A) and `localhost:3022` (B), isolated data and home directories, `--security_legacy`.
2. Run 1 on `localhost:3021/view/question-q` in a disposable headless Chrome: a real click on the CLICK block's button.
3. On `localhost:3021/view/claim-a`: a real click on the footer "wiki ✔︎" toggle. Before it `.editEnable` had `display: none`; after it `inline`.
4. Real double-click on item `a200000000000007` (shown as "Evidence Two"), triple-click in the textarea, key input of `[[Evidence One]]`, a click outside to leave the editor.
5. A fresh load of `question-q` and a second run of the block.

## Observed save

- **Request:** `PUT http://localhost:3021/page/claim-a/action`, form body `action={"type":"edit","id":"a200000000000007","item":{"type":"paragraph","id":"a200000000000007","text":"[[Evidence One]]"},"date":1792516396271}`. One request; the `date` is stamped by the client.
- **Response:** `200 OK`; server A log line `PUT /page/claim-a/action 200 2`.
- **Stored page** (`run/siteA/data/pages/claim-a`): item `a200000000000007` has text `[[Evidence One]]`; the other six items are unchanged and in the same order; the served `/claim-a.json` equals the file.
- **Journal:** one entry added, after the seed's `create`: `{"type":"edit","id":"a200000000000007","item":{"type":"paragraph","id":"a200000000000007","text":"[[Evidence One]]"},"date":1792516396271}`. It equals the action the browser sent and lies between the run's start and end.
- **Site B:** all three files byte-identical to the seed. **Site A:** only `claim-a` differs; `question-q`, `evidence-one`, `evidence-two`, `topic-t` are identical.

## Graph relations before and after (real client, `TRAVERSE question claim support oppose`)

Names are `site/slug`; `A = localhost:3021`, `B = localhost:3022`.

| Before the edit (`… ⇒ 8 relations, 9 nodes, 1 unresolved`) | After the edit and a fresh load (`… ⇒ 8 relations, 8 nodes, 1 unresolved`) |
|---|---|
| A/claim-a **oppose** A/evidence-two | A/claim-a **oppose** A/evidence-one |
| A/claim-a **support** A/evidence-one | A/claim-a **support** A/evidence-one |
| A/claim-a support A/evidence-three (unresolved) | A/claim-a support A/evidence-three (unresolved) |
| A/question-q claim A/claim-a | A/question-q claim A/claim-a |
| A/question-q claim B/claim-a | A/question-q claim B/claim-a |
| A/question-q question A/topic-t | A/question-q question A/topic-t |
| B/claim-a oppose B/evidence-three | B/claim-a oppose B/evidence-three |
| B/claim-a support B/evidence-one | B/claim-a support B/evidence-one |

- **Removed:** `A/claim-a oppose A/evidence-two`. **Added:** `A/claim-a oppose A/evidence-one`. Nothing else differs.
- **Same endpoints:** between A/claim-a and A/evidence-one the edge types were `[support]` before and are `[oppose, support]` after.
- **Nodes:** the one node that disappeared is `WikiPage A/evidence-two`, which is no longer reached; no node appeared. Site B's relations are identical in both runs.
- EXTRACT reported `8 typed edges` both times, and no block reported a trouble in either run.

## Corrections during the run

- **First verdict run: 9.3 FAIL, my expectation, not the system.** The check expected the PUT body without a `date`; the client adds one. The first report is kept as `results/at9-report-first-run-9.3-fails-on-expectation.json` (14 PASS, 1 FAIL) and its script as `e2e/at9-report.first.mjs`. I corrected the expectation (the date must be a number inside the run) and added a stronger check that the stored journal entry equals the sent action. No implementation file was changed.
- **Driver:** the only change was the released footer-toggle step plus capture of the PUT response (`e2e/driver.mjs`; the previous version is kept as `e2e/driver.before-at9.mjs`).

## Observations to keep

- The save path through `focusout` worked: one PUT was sent when the edited text was left. The earlier unexplained missing `focusout` log in the diagnosis concerned only the unchanged-text case and is not shown to matter.
- The exception `Cannot read properties of undefined (reading 'setup')` at `client.js getScript` still appears on every page load; it did not affect this run and remains undiagnosed.
- A single run on one seed; the edit changes the data under `run/` (the seed copies `run/siteA.seed-copy`, `run/siteB.seed-copy` are kept for comparison). A repeat would need a new data directory.

## State at the end

Both test wikis stopped; ports 3021, 3022 and the browser port are free; no browser process of mine remains. The wiki repository `~/Projects/RalfBarkow/wiki` is clean; the worktree `claude/discourse-traverse` (4dd6be43) has the same changed and new files as before.
