# A temporary DNS failure no longer ends the served Catalog

Follow-up to [public-views-offline](public-views-offline/README.md#a-production-finding-not-changed-here), which recorded the
production risk without changing the library. Branch `claude/modest-cray-d1kinu`, on `dreyeck.ch` at `0a7d4de`.

## The question, verified first

`HYPERBOOK/FEDWIKI::INITIALIZE-FEDWIKI` runs in the thread `MAKE-FEDWIKI` starts for every newly met remote FedWiki site. It
retained `stream-error`, `usocket:timeout-error`, `usocket:ns-host-not-found-error` and `shasht:shasht-invalid-char` as the
site's `STATUS-OF`. When `getaddrinfo` fails temporarily (EAI_AGAIN), `PROBE-FEDWIKI-PROTOCOL`'s `usocket:socket-connect`
signals `usocket:ns-try-again-error`, a sibling of `ns-host-not-found-error` under `usocket:ns-error`, so it escaped the thread.

The packaged `hyperdoc-catalog` runs `sbcl --script`, i.e. with the debugger disabled. Observed on x86_64-linux, 2026-11-03:

| Run | Result |
|---|---|
| `nix build .#hyperdoc-catalog` at `0a7d4de`, started in `unshare -rn` (loopback only; `getaddrinfo` → EAI_AGAIN), a headless browser walks Catalog → *Working on HyperDoc* → Text pages → *Work Breakdown* → *From Two Hubs to One Trail* | **the Catalog process ends (exit 1)** while that page renders: `Unhandled USOCKET:NS-TRY-AGAIN-ERROR` for `ward.voices.ustawi.wiki`, raised in `PROBE-FEDWIKI-PROTOCOL` ← `INITIALIZE-FEDWIKI` ([executable-before.txt](fedwiki-name-service-failures/evidence/executable-before.txt)) |
| The same, executable built with this change | the page renders, *Dewey Alexander Trail* is opened as well, the Catalog still answers `GET /` with 200, has logged no unhandled condition and exits 0 on SIGTERM ([executable-after.txt](fedwiki-name-service-failures/evidence/executable-after.txt)) |

So the open question in `573fe37`'s wake is answered: yes, a transient resolver failure while a visitor opens a page that names a
not-yet-visited remote wiki ended the served Catalog.

## The change

`hyperbook-fedwiki/fedwiki.lisp`, `INITIALIZE-FEDWIKI`: `usocket:ns-host-not-found-error` → `usocket:ns-error`. That keeps
host-not-found (a subclass) and adds `ns-try-again-error`, `ns-no-recovery-error` and `ns-unknown-error`: every name-service
failure is an operational failure to reach that one site, retained as its status like host-not-found already was. Nothing else in
the form changes; no dreyeck hostname or policy enters the library. Candidate upstream contribution (one symbol).

Not changed, deliberately: other `usocket` errors from the probe (e.g. `network-unreachable-error`, `host-unreachable-error`) still
escape the same way. They were not observed here and are left for a separate decision rather than widening this delta.

## Tests

* `dreyeck/wiki-link/tests` (`dreyeck/tests/fedwiki-journal-context-debugger-smoke.lisp`):
  `run-initialization-name-service-failures-test` calls `INITIALIZE-FEDWIKI` directly with a `:protocol-probe` that signals each
  `usocket:ns-error` subclass and checks that nothing escapes, the identical condition is the status, and no fetch follows. It runs
  in the test's own thread, so a regression fails as a check rather than ending the process from a worker thread. The existing
  worker-thread containment test now also runs through `MAKE-FEDWIKI` with `ns-try-again-error`.
  Before the fix: fails with `INITIALIZE-FEDWIKI let USOCKET:NS-TRY-AGAIN-ERROR escape instead of retaining it.`; after: passes
  ([regression-test.txt](fedwiki-name-service-failures/evidence/regression-test.txt)).
* Source inventory (`dreyeck/tests/hyperdoc-library-delta.lisp`): `APPLY-LATER-DELTAS` states this delta as the exact change to the
  pre-refactor `INITIALIZE-FEDWIKI` form (substitute that one symbol), not as a commit pin, so it survives any merge style. It asserts
  that the substitution applies, so a stale inventory fails rather than passing vacuously.
  [hyperdoc-upstream-boundary.md](hyperdoc-upstream-boundary.md) names the delta.

## The boundary check: already failing before this change

`sh scripts/check-upstream-boundary.sh` does not pass, and did not on clean `0a7d4de` either: `dreyeck/hyperdoc/library-tests` fails
because the library files differ from the inventory in forms this change does not touch. Four commits changed library paths without
updating it: `e903974`, `99521dc`, `394bb79`, `77bfb29` (2026-10-10/11; Mech story items, retained sitemaps, WALK topics, POPUP state
dialog). Forms outside the inventory, per file:

| File | Forms |
|---|---|
| `hyperbook-fedwiki/fedwiki.lisp` | changed `FEDWIKI` class, `FETCH-SITEMAP`, two unnamed top-level forms; new `SITEMAP-SNAPSHOT` |
| `hyperbook-fedwiki/pages.lisp` | changed `FEDWIKI-PAGE` class, `SET-PAGE-DATA`, one unnamed form; new `COPY-PAGE-JSON` |
| `hyperbook-fedwiki/story-items.lisp` | two unnamed forms changed; new `*MECH-PLUGIN-HOST-URL*`, `MECH-NEIGHBORHOOD-SNAPSHOT`, `MECH-JSON-BASE64`, `RENDER-STORY-ITEM (eql :mech)` |
| `hyperbook-fedwiki/wiki-links.lisp` | changed `MAKE-REMOTE` |
| `hyperbook.asd` | two forms differ from upstream beyond the CLOG normalization |

`INITIALIZE-FEDWIKI` is not in that list: with `APPLY-LATER-DELTAS` it matches. Classifying those other deltas (upstream candidate,
dreyeck integration to move out, …) is an ownership decision the boundary document asks to be made deliberately; it is not made here.
Per-system results of the matrix at this change, each system in its own process ([boundary-matrix.txt](fedwiki-name-service-failures/evidence/boundary-matrix.txt)): 12 of 14 pass, `dreyeck/wiki-link/tests` among them. The two failures predate this change: `dreyeck/hyperdoc/library-tests` (above) and `dreyeck/catalog/tests` at `dreyeck/lisp-critic/reading/tests` ("cannot reach the Riesbeck engine": the Lisp Critic asset is deliberately not deployed, as recorded in [verification.md](fedwiki-original-editor-farm/verification.md)).

## Reproduce

```bash
nix build .#hyperdoc-catalog --out-link result
REPO=$PWD unshare -rn docs/fedwiki-name-service-failures/reproduce/run.sh result/bin/hyperdoc-catalog out docs/fedwiki-name-service-failures/reproduce/hub.mjs
```

`run.sh` brings loopback up (`loup.py`, no `ip` needed), starts the executable with the environment of
`tests/test_catalog_executable.py`, runs the walk and reports whether the Catalog survived. `hub.mjs` imports Playwright from
`/opt/node-tools/node_modules/playwright` (the container's preinstalled copy); adjust that path elsewhere. Cold start takes several
minutes.
