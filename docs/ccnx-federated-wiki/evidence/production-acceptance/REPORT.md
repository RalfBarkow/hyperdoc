# CCNx Federated Wiki: production acceptance on dreyeck.ch

**Browser acceptance passed; deployed NixOS revision not verified.**

This is an observation of one moment. The earlier browser evidence (`../navigation.json`, `../navigation.png`, `../reading-in-catalog.png`) was made
against a locally built Catalog before the merge and stays as it is; this is a separate observation of the served production Catalog.

## Observation

| | |
|---|---|
| Target | `https://dreyeck.ch/` (regular Catalog; nothing was configured to add the book) |
| Time | 2026-11-04, about 12:02 UTC (first response `Date` header 11:56:01 GMT; the recorded run finished 12:02 UTC) |
| Browser | Chromium 153.0.8010.12, headless, viewport 1500×1000 (`acceptance.json`, `userAgent`) |
| Environment | Linux x86_64 cloud container of a Claude Code session; HTTPS through the session's egress proxy; service workers blocked; Playwright driving the browser |
| Script | `accept.mjs` in this directory (read-only; it writes nothing to the site) |
| Repository state at the time | `origin/dreyeck.ch` = `479bdd213c4d0e3c3b1b373110239811e5c7a86c` (Merge pull request #25) |

## What was done

1. Opened the Catalog, found exactly one visible `The CCNx Federated Wiki` entry, opened the book, and read its tabs.
2. `Text pages` listed four items; opened `Reading the CCNx Federated Wiki` from there. The book's `Main page` tab shows the same reading.
3. Followed the reading order: `One Page From Browser to NDN and Back` → `Identity, Versions and Signatures` → `Plain Text After CCNx` → back link to `Reading the CCNx Federated Wiki`.
4. Followed both expression links (`the page as a Federated Wiki server stores it`, `the same page as the Main code leaves it in IndexedDB`) to the example page `Plain Text Example`.
5. Followed every reference of every page once, from its own pane (19 links, `reference.allLinks` in `acceptance.json`), and recorded the title and start of the pane each opened.

## Observed results

| Page | Shown in the Inspector | Links followed |
|---|---|---|
| Reading the CCNx Federated Wiki | yes | 3 page links and 2 expression links, each opened the right object |
| One Page From Browser to NDN and Back | yes | `Identity, Versions and Signatures`, `Open page A`, `Open page B` |
| Identity, Versions and Signatures | yes | `Plain Text After CCNx` |
| Plain Text After CCNx | yes | `Identity, Versions and Signatures`, the back link to the reading, `open it`, `form A`, `form B` |

- Each link opened a pane of the right kind (an `html-page` with the linked title, or a `local-fedwiki-page` with the Story view of `Plain Text Example`). No fixed pane count was asserted; counts are recorded relative to the click. A link followed from the last pane added one pane; from an earlier pane the totals differed from case to case, which was not investigated.
- The example page's Story view is readable: two paragraphs under the title.
- Content: every text block of the four pages at `479bdd21` (read with `git show`) is present in the rendered production panes. This shows the served content, not a revision.

## Console, errors and requests

- Uncaught page errors: none.
- HTTP responses with status 400 or above: none. Failed requests to `dreyeck.ch`: none.
- The only failed request is `GET https://ccnx-example.invalid/favicon.png`. It is the documented favicon of the example's logical site, a reserved name that never resolves, and the broken icon beside the example title is that request. In this environment it fails as `ERR_TUNNEL_CONNECTION_FAILED` (the proxy refuses the tunnel); on an ordinary network it would be a DNS failure. The console shows one `Failed to load resource` line per such request.

## Not verified

| Link in the chain | Status |
|---|---|
| GitHub branch updated | observed: `origin/dreyeck.ch` is `479bdd21` |
| NixOS flake input updated | **not verified** (the server's `/etc/nixos` is not readable from here) |
| New NixOS generation activated | **not verified** (no SSH, no observable generation) |
| Catalog serves a given revision | **not verified**; only the served content was observed. The public surface exposes no revision, and reachability of a page is not treated as one. |

The merge commit is **not** claimed to be the activated NixOS generation. An operator can compare `readlink /run/current-system` and the `hyperdoc` entry of
`/etc/nixos/flake.lock` with `479bdd21` (procedure in `dreyeck/CATALOG-OPERATIONS.md`).

## Editorial observations (not blocking; no page was changed)

1. The main page's "Three kinds of statement" (Implemented, Documented, Open) does not define `Derived, not run`, which the other pages use.
2. The answer to question 5 on the main page combines two labels: "(Implemented, by the source; not run.)".

Both are for a separate, small follow-up; the reading pages are unchanged by this record.

## Files

- `REPORT.md` this report
- `acceptance.json` the structured result of the run (steps, links, console, failed requests), as produced
- `screenshots/01-reading.png` … `06-example-b.png` the Inspector after each step (public pages only). A first screenshot of the empty Catalog taken before it had rendered is left out.
- `accept.mjs` the script, portable: arguments `OUTPUT_DIR [ORIGIN]`; optional `CHROMIUM` (browser path) and `PROXY_SERVER` (no credentials).

## Reproduce

```sh
cd <a directory from which `playwright` resolves>
node /path/to/docs/ccnx-federated-wiki/evidence/production-acceptance/accept.mjs /tmp/ccnx-acceptance https://dreyeck.ch
```
