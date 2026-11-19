# Zettel 11806 — an unmarked fork at the first `prepare`

Review question of Draft PR #51: where does the decision come from to replace a
target whose last fork already lacks `releaseSha256` when `prepare` first observes
it? At `a7ab847e29db95c4837a7c6a2b73b34687c4ee7d` it came from nowhere.

## Finding at `a7ab847`

The fork without `releaseSha256` was written before the first `prepare`.

- `prepare` handed SHOP3 `:target-ready … revision=<digest of the legacy fork>`.
- The lineup offered `:PUBLISH-PAGE` with Play.
- Play: `:PUBLISHED`, 1 PUT, next SHOP3 step `:verify-publication`. The legacy fork
  was replaced without any decision.

## Change

- `fedwiki-fork:target-evidence`: an absent target, or this release's own fork, is
  `:target-ready`. Any other existing page is `:target-ready` only under a replacement
  decision for exactly its observed revision; otherwise `:target-conflict`.
- `fedwiki-fork:replacement-decision` names that decision: release, origin, slug and
  revision. The `:target-ready` reference then ends in `replacement-approved-for=<digest>`.
- `fedwiki-fork:publish-page` takes `:replacement`. It checks the decision against the
  plan before reading, and against release, origin, slug and the digest it reads
  immediately before the PUT. A missing or other decision ends in the existing
  `:reconcile-target` path with 0 PUTs.
- `fork-lineup:prepare` passes `:target-ready` or `:target-conflict`; a conflict offer
  is `:reconcile-target` and shows no Play. `fork-lineup:approve-replacement` records
  the operator's decision for exactly the revision an offer observed, outside Play, and
  freezes a new offer. SHOP3 stays `:PLAN-ONLY`.

## Counterprobes run before the commit

All runs by Claude Code, 19 November 2026, on Linux (not on the Mac), with the real
FedWiki server 0.26.2 from `RalfBarkow/wiki` at
`7e3e6bb48351a923ebc13fe83fed58c49f56f59e`, Nix/SBCL 2.4.10 and headless Chromium.

| Run | Starter | Result |
|---|---|---|
| Finding at `a7ab847` | `first-observation-lineup.lisp`, `:before` | `:target-ready`, `:PUBLISH-PAGE`, `:PUBLISHED`, 1 PUT (`lauf-517d06f05f50741d`) |
| Standard acceptance | `run-publish-page.py` | 8 cases as asserted; wire writes fork 403, edit 200, fork 200 |
| Legacy variant | `run-publish-page.py` after `02-legacy-gegenprobe.patch` | 8 cases as asserted; wire writes fork 403, fork 200, fork 200 |
| Four lineup cases | `first-observation-lineup.lisp`, `:cases`, browser Play | below |

The four cases, from the SLY forms below evaluated in a fresh SBCL process (not in SLY), with `:keep t`:

| Case | Fact to SHOP3 | Offer | Play | PUTs | Next step | Recent Changes |
|---|---|---|---|---:|---|---|
| 1. Legacy fork at first `prepare`, no decision | `:target-conflict` | `:RECONCILE-TARGET`, no Play | — | 0 | — | — |
| 1. Executor given a pre-fix `:publish-page` plan | — | — | `:reconcile-target` | 0 | — | — |
| 2. Exactly that revision approved | `:target-ready … replacement-approved-for=…` | `:PUBLISH-PAGE` | `:PUBLISHED`, readback verified | 1 | `:verify-publication` | `lauf-c957a0a06c90eb81` |
| 4. Same confirmed release again | `:target-ready` | `:PUBLISH-PAGE` | `:ALREADY-PUBLISHED` | 0 | `:verify-publication` | `lauf-abdfa32d26cb6cc9` |
| 3. Target changed after the decision | decision for `0268ed04…`, target `936dd3d5…` | `:PUBLISH-PAGE` | `:RECONCILE-TARGET` | 0 | `:reconcile-target` | `lauf-6bf884fbb50e20a1` |

A new `prepare` after case 3 offers `:RECONCILE-TARGET` again. Opening the returned
lineup, Recent Changes and run URLs made 0 wiki requests.

### Linux-specific adaptations of the test environment

None of these is part of the commit.

- `/private/tmp` → `/tmp` and `/usr/sbin/lsof` → `/usr/bin/lsof` (macOS paths of the tooling).
- `~/Projects/RalfBarkow/wiki` → the wiki checkout (default `--wiki` of `--serve`).
- Linux `lsof` prints the socket as `n<path> type=STREAM`; the socket assertion of
  `run-publish-page.py` was matched to that line in the throwaway checkouts only.
- npm hoisted `wiki@0.39.4`, a dependency of `wiki-plugin-journalmatic`, to
  `node_modules/wiki`, which collides with the launcher's own `node_modules/wiki` link;
  it was moved back under the plugin.
- `nix develop` in a clean linked worktree of a shallow clone fails: libgit2 cannot find
  `6243e06090992a9a4175b27aff30b16a4e6f2be3`, the parent of the shallow boundary commit.
  The runs used a complete clone of the same commit. GitHub archive downloads of the flake
  inputs were refused by the session proxy; the same locked revisions were fetched once
  over Git and accepted by Nix against the `narHash` of `flake.lock`.
- `PLAYWRIGHT_MODULE` pointed at Playwright's ESM entry `index.mjs`.

## Mac acceptance

From the PR checkout at the commit that adds this note, with the wiki prepared as in
the PR description (`npm ci`, then `wiki-server@0.26.2`) and also reachable as
`~/Projects/RalfBarkow/wiki` for `--serve`:

```sh
python3 acceptance/run-publish-page.py --hyperdoc "$PWD" --wiki ~/Projects/RalfBarkow/wiki --report /tmp/standard.json
```

```sh
nix develop --no-write-lock-file -c sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load acceptance/ki-plan-next.lisp --load publication/lineup.lisp \
  --load acceptance/zettel-11806/first-observation-lineup.lisp \
  --eval '(print (z11806-first-observation:run :cases))'
```

In the SLY mREPL of the HyperDoc image, with `PLAYWRIGHT_MODULE` set as for
`check-publish-lineup.mjs`:

```lisp
(let ((root #p"/path/to/this/checkout/"))
  (dolist (file '("acceptance/ki-plan-next.lisp" "publication/lineup.lisp"
                  "acceptance/zettel-11806/first-observation-lineup.lisp"))
    (load (merge-pathnames file root))))
(z11806-first-observation:run :cases :keep t)
;; => (:LINEUP "http://127.0.0.1:8080/…" :RECENT-CHANGES "…/recent-changes" :RUNS (…) :FIXTURE :RUNNING)
(z11806-first-observation:stop)
```

The browser check asserts each case and fails loudly otherwise. The returned lineup
URL, Recent Changes and run references are what a visual check opens.
