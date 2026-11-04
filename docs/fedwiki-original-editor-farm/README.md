# Original Wiki Editor demo in the dreyeck.ch Catalog, and the Wiki farm

Prepared 2026-11-02 on `claude/relaxed-meitner-q7l2y4`, from `dreyeck.ch` at
`19e824d326def8bc227101e2494500630f441953` (Zettel 11472). Nothing is deployed, no server was contacted.
The operator steps are in [operator.md](operator.md).

Labels: **[obs]** observed in a run listed under *Evidence*; **[der]** derived from source, not executed;
**[rec]** dated record already in this repository, not re-observed; **[op]** needs the operator.

## Three decisions, kept apart

| | Decision | State after this change |
|---|---|---|
| 1 | **Loading**: the HyperBook *Original Wiki Editor Test* is in the Catalog | `dreyeck/catalog` depends on `dreyeck/fedwiki-original-editor-demo`; the admitted set (`dreyeck/tests/catalog-startup-smoke.lisp`) gains it. No variable is read for this and `HYPERDOC_CATALOG_SYSTEM` is untouched. |
| 2 | **Wiki connection**: which site is read back, which original Wiki origin is linked | Only `HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT` and `HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN`. No defaults, no fallback to `HYPERDOC_FEDWIKI_SITE_ROOT` or any other site. Unset on the server: the demo is *unconfigured* and says so. |
| 3 | **Embedding the editor** (and with it the path to a write) | Only `HYPERDOC_FEDWIKI_EDITOR_TEST_MODE=isolated-loopback` with an origin `http://127.0.0.1:PORT`. Set by the two test launchers only. There is no farm mode. |

Loading grants nothing: an admitted HyperBook renders read-only. HyperDoc never writes the site and holds no Wiki
credential; every write goes from the original client to the original server, whose security module decides it.
The mode only decides whether HyperDoc *offers* the item-specific frame. The frame's sandbox, its CSS, the adapter's
origin checks and the client-side toolbar are not treated as write protection anywhere.

## 1. The load path, and why the default membership

`hyperdoc-catalog` → `scripts/catalog-main.lisp` → `dreyeck/catalog-topic-maps:main` (snapshot verification, Project
Workspace guard) → `dreyeck/catalog-application:main` → `start-catalog`. ASDF loads `dreyeck/catalog` through
`dreyeck/local-fedwiki-view`; `start-catalog` then loads **one** further system, the value of `HYPERDOC_CATALOG_SYSTEM`
(default `dreyeck/catalog`, no-op). The guard (`refuse-project-workspace`) reads exactly that one system's definition.

Naming the demo in `HYPERDOC_CATALOG_SYSTEM` would **replace** whatever the service names there now. The repository's
last recorded reviewed diff sets `dreyeck/work/topic-maps-ctm-review` [rec, `docs/one-catalog/README.md`], but whether
that is active is not observed. The count of 24 HyperBooks does not settle it: the default admitted set has 23, and
starting the Catalog registers its local wiki, and `/view/<slug>` admits pages at run time [rec,
`dreyeck/work/deployment-reading.lisp`, `view-route-response`], so 24 fits "no additional system" but proves nothing.

Considered, in order of size:

1. **Admit the demo to `dreyeck/catalog`** (chosen). One dependency and one admitted id. Additive whatever
   `HYPERDOC_CATALOG_SYSTEM` holds; no service variable changes; the guard is unaffected (the demo depends on no
   refused system). It is the documented mechanism: "admitting or withdrawing one changes this list and nothing else".
2. An aggregate system naming the demo and the currently configured system: needs the server's current value, which is
   not observed, and moves a service choice into the package.
3. A list-valued `HYPERDOC_CATALOG_SYSTEM`: changes the startup contract and the guard, which the one-catalog review
   deliberately left untouched.

A side effect of option 1 (derived first, observed on 2026-11-02, see [verification.md](verification.md#the-base-observed)): since `cc781f7`, `check-reviewed-controls-match-their-sites` (run by
`dreyeck/topic-maps-public-views/tests`, part of `checks.<system>.catalog`) scans `dreyeck/src/*.lisp`, finds the demo's
`reviewed-thunk "fedwiki-original-editor-demo/reread"` and would report it *used but not registered*, because no test
image loaded the demo. With the demo in `dreyeck/catalog` it is registered in every Catalog image.

## 2. The Wiki farm: what the repository records

From dated records only [rec, `dreyeck/work/deployment-reading.lisp`, `dreyeck/fedwiki-config/evidence/dreyeck-flake.nix`];
nothing was re-observed:

- `wiki.service`, user `rgb`, `node … --config /home/rgb/.wiki/config.json`, **farm mode**, `security_type` **friends**,
  listening on `*:3000`; nginx sends `*.dreyeck.ch` to `127.0.0.1:3000` and the apex `dreyeck.ch` to the Catalog at
  `127.0.0.1:8080`. `data`, `root` and `wikiDomains` were "not explicitly configured"; `allowed` was not recorded.
- In farm mode each host gets `<data>/<host>/` and its own server instance on first request
  (`node_modules/wiki/farm.js`). Without `allowed`/`wikiDomains`, any host name routed to the farm is admitted.
- `wiki-security-friends` 0.3.1: an **unclaimed** site is claimed by whoever logs in first (the claim writes a fresh
  secret to the owner file and the session); afterwards only a session carrying that secret is authorized. The session
  cookie is host-only unless a `wiki_domain` applies (`wiki-server/lib/server.js`). Plugins' server components receive
  the site's Express `app` (`plugins.startServers({argv, app, packageJson})`): the farm Wiki's own route extension point.
- The packaged farm Wiki of that record was `wiki` 0.39.2 with pinned client/server revisions; the test pins
  `wiki` 0.41.0, client 0.33.0, server 0.28.1, Code 0.6.1. The farm's current package is not recorded.

What the isolated test needs from a Wiki server, and what the farm has:

| Needed by the embedded editor | Isolated test (`tests/fedwiki-original-editor/server.mjs`) | Farm |
|---|---|---|
| Original client, plugins, pages, PUT | the locked `wiki-server`, unchanged | its own `wiki` package — reusable as is |
| `GET /view/original-editor-test?hyperdocCodeItem=…&revision=…`: original bootstrap plus the item restriction, `frame-ancestors <Catalog origin>` | a wrapper around the server's request handler, in the test process | **absent**; needs a place to run (decision D4) |
| `GET /hyperdoc/code-editor.js` | served by the same wrapper | **absent** |
| Write authorization | default security with `security_legacy=true` on an unclaimed disposable loopback site | friends: an owner session of that farm site |

`server.test.mjs` shows why the test grant must stay where it is [obs]: with `security_legacy=true`, an unclaimed site
lets **any** visitor create **any** page, not just edit the one Code item. On a public farm that is an open wiki. The
adapter's loopback and legacy checks are therefore left as they are; a farm variant must replace them with the farm's
own authorization, not relax them.

### What can already be connected without changing the farm

The *read-only* mode works against any site directory and any https origin: `HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT` names
the site directory to read back, `HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN` the origin linked as *Open original Wiki client*.
Whoever follows the link meets the farm's own login; HyperDoc embeds nothing. It needs a dedicated farm test site that
exists, is claimed by the operator, holds the fixture page, and is readable by the Catalog's service user. Each of those
is an operator decision (D2, D3) and none is made here.

## 3. Implementation

- `dreyeck/src/fedwiki-original-editor-configuration.lisp` (CL + UIOP only): `read-editor-configuration` of an injectable
  `getenv`; modes `:unconfigured`, `:read-only`, `:isolated-loopback-editor`; every rejected value is kept as a readable
  problem; unknown modes (including any "farm" or "write" spelling) and malformed origins are refused, never repaired.
  Target coordinates stay fixed (`fedwiki:original-editor-test.invalid` / `original-editor-test` / `2222222222222222`).
- `dreyeck/src/fedwiki-original-editor-demo.lisp`: `read-stored-page` returns an `unavailable-page` with the reason
  instead of signalling (no site, missing file, not exactly one target item); `render-demo` shows the configuration and
  its state; the *Original Wiki editor* view embeds the frame only when the mode allows it and otherwise says why; an
  *Editor configuration* view makes the configuration inspectable. Only reviewed controls; the existing reread control.
- `dreyeck.asd`: the configuration component, `dreyeck/fedwiki-original-editor-demo/tests`, and the membership.
- `tests/fedwiki-original-editor/{run,commands}.mjs` set `HYPERDOC_FEDWIKI_EDITOR_TEST_MODE=isolated-loopback`;
  `serve.lisp` asserts the demo is in the Catalog once, before and after the additive `:catalog-system`, and that the
  mode is the editor mode (so a browser run cannot silently test the read-only page).
> **Later change (PR #25):** the script described here was renamed `scripts/check-catalog-membership.lisp` and no longer compares with the
> 23 ids of `19e824d`; membership is derived from the product's declaration (`dreyeck/CATALOG-OPERATIONS.md`). The paragraph below records what
> the script did when this evidence was made.

- `nix/catalog-check.nix` runs the demo's test system and `scripts/check-editor-demo-membership.lisp` twice: with no further
  system, and with `HYPERDOC_CATALOG_SYSTEM=dreyeck/work/topic-maps-ctm-review`. The script compares against the 23 ids
  admitted at `19e824d`, frozen in the script, and requires each once, the demo once, nothing else by default, nothing
  lost when the further system loads, and nothing added when the demo is named again. (The closed-membership check of
  `dreyeck/catalog/tests` asserts the same set but is not part of the Nix check.)

Not changed: original Wiki client, server and plugin sources and the npm lockfile; `server.mjs` and
`inspector-code-editor.js`; `catalog-application`, `catalog-topic-maps` (the guard), `nix/catalog.nix`, `flake.nix`.

## Evidence (2026-11-02, x86_64-linux cloud container)

The acceptance with the real runtime (Nix check, closed membership, both browser E2E cases) is recorded in
[verification.md](verification.md#acceptance-record-2026-11-02). The table below is the earlier evidence, gathered while
codeberg.org was unreachable: configuration tests in a bare SBCL, stubs and Node tests only.

| Check | Result |
|---|---|
| `dreyeck/tests/fedwiki-original-editor-configuration.lisp` in a bare SBCL 2.4.10 (`run-tests`) | pass [obs]; two mutants (any origin counted as loopback; root falling back to `HYPERDOC_FEDWIKI_SITE_ROOT`) are killed [obs] |
| Demo source compiled and executed in a bare SBCL over throwaway stubs of the Inspector/HyperBook API (not committed) | 23 checks pass [obs]: unconfigured page signals nothing, links/embeds nothing; missing and non-unique page give the read-only reason; read-only withholds the frame; loopback mode gives exactly one frame with the observed revision, the E2E's class, heading and sandbox; the reread control is a reviewed thunk; site bytes unchanged. Stubs are not the real libraries. |
| `node --test tests/fedwiki-original-editor/server.test.mjs` with Node 24.22.1 and the locked packages (`npm ci`) | 4/4 pass [obs]: without legacy every PUT is 403 and the adapter 409; the adapter serves only the one item at the observed revision to the exact loopback parent (CSP, no CORS, coordinates only, original `client.js` bytes) and refuses stale, other item, no revision, POST, other slug, non-loopback or missing parent; legacy lets anyone create another page |
| `node --test tests/fedwiki-original-editor/commands.test.mjs` | 5/5 pass [obs] |
| `node --check` of `run.mjs`, `commands.mjs`, `server.mjs`; `nix-instantiate --parse nix/catalog-check.nix` | ok [obs] |
| `scripts/check-editor-demo-membership.lisp` over a fake ASDF registry (not committed) | its logic only [obs]: passes with and without a further system; fails on a book registered twice by the further system and on a base without the demo (the state at `19e824d`). Its frozen list is byte-identical to `19e824d`'s admitted set. |

## Not run here

Superseded: on 2026-11-02 the network access was widened and the real runtime ran; see
[verification.md](verification.md#acceptance-record-2026-11-02) for what passed and what cannot pass in a network-less
build sandbox.

## Decisions

- **D1 Membership — decided 2026-11-02 by the owner:** the unconfigured, read-only demo is admitted to the public
  Catalog (option 1).
- **D2 Farm test site.** Whether a dedicated site (for example `original-editor-test.dreyeck.ch`) is created at all; it
  must be claimed by the operator **before** it is reachable, since an unclaimed friends site goes to the first visitor.
  Whether the farm restricts hosts (`allowed`, `wikiDomains`) is unknown.
- **D3 Read path.** Whether the Catalog's service user may read that one site directory
  (`HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT`). The demo then shows its JSON file path publicly.
- **D4 Adapter placement.** The frame route must run at the farm site's origin: (a) a Wiki plugin's server component
  (`<plugin>/server/server.js`, `startServer`, the farm Wiki's own extension point), which changes the farm's Wiki
  package; (b) an nginx location for the one test host to a separate adapter process; or (c) no embedding — the link only.
- **D5 Write authorization on the farm.** Whether the friends owner session of the test site is the accepted
  authorization; whether its cookie reaches a frame embedded by `https://dreyeck.ch` is untested (same site; the
  locked server 0.28.1 sets `httpOnly`, `SameSite=Lax`, which a same-site frame receives; the farm's version and
  `secure_cookie` are unknown); which `frame-ancestors` the adapter sends, and whether nginx adds `X-Frame-Options`.
- **D6 Versions.** Whether `inspector-code-editor.js` works with the farm's client revision (it relies on
  `wiki.getPlugin`, `wiki.pageHandler.useLocalStorage`, `isOwner`, `.editEnable`); tested only with client 0.33.0.

D2–D6 belong to a separate task. Until they are decided, the editor stays available only inside the isolated loopback test.
