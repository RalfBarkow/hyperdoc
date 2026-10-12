# Mech in the FedWiki Story Inspector

Story's `:mech` renderer sends the complete original page JSON, source site,
origin slug and selected item ID to a read-only browser Wiki plugin host. The
host supplies the Wiki lineup/page-object contract required by `CODE` and uses
the retained Mech parser, formatter, catalog, `emit` and dispatcher, with the
bounded WALK mode intake documented below. JavaScript
runs in the browser; neither page display nor button clicks invoke a Lisp
JavaScript evaluator or an executable Wiki-to-Lisp callback.

## Runtime setup

Serve `assets/hyperbook/fedwiki/mech-host/` as a static site at an origin separate
from the Inspector. The included local launcher uses only Node built-ins:

```sh
node scripts/serve-fedwiki-mech-host.mjs 8099
```

In the **fresh runtime's** configuration, after loading `hyperbook/fedwiki`:

```lisp
(setf hyperbook/fedwiki::*mech-plugin-host-url* "http://127.0.0.1:8099/")
```

Then inspect the original FedWiki page and choose **Story**. The first `CLICK ▶`
runs `CODE trails`; two nested Play buttons appear for Solo and Preview. Solo
requires popup permission. No service is started by loading the Lisp system,
rendering Story or running ASDF tests. Without a configured host the original
item and its native Inspector link remain available, with an explicit status.

For a remotely served Inspector, a separately served HTTPS static host must be
configured explicitly. A loopback URL is a local-development setting, not a
remote deployment choice. The same-origin bridge is deliberately rejected.
The frame permits scripts, same-origin access within the **separate** host and
Solo popups; it cannot access the Inspector DOM. The standalone static host has no CLOG route,
publication endpoint or filesystem-browse endpoint. Its CSP bounds script and
network imports to the original dependency URLs. Do not co-host unrelated
privileged applications, credentials or services at its origin.

The existing Wiki-assets deployment described below shares the Wiki origin and
its potential privileges. Its response headers must be checked independently.

## Preserved source and execution contracts

The page loader retains JSON containers separately from Story/Journal caches.
It no longer removes source fields from the caller's page JSON. Remote-page
projection copies this retained source, preserving the origin and item IDs.
UTF-8 JSON is transported as base64 data, avoiding alteration of Code string
escapes by the CLOG HTML/JavaScript transport. This encoding does not execute
or rewrite Code.

Only passive outer `CLICK` blocks initialize on display. Other top-level
scripts require a separate explicit start action. Ownership is false and the
page object is remote; the original CODE authorization guard still applies.
There is no CODE authorization adapter, LISTEN forwarding or
implicit Code evaluation. Plugin failures appear in the frame; module/uncaught
failures also reach the Story status as text.

The retained runtime modules use Git source files of RalfBarkow's
CODE-capable **local candidate** `0fc36fcd58a8d7c399d3e86d2ee2e9328cafba44`,
with the bounded original Ward WALK topics and POPUP intakes documented below. Only
`library.js` and `blocks.js` differ from that base: topics recognition/calculation
and the original POPUP function/catalog arm are the bounded additions. The
interpreter parser and all pre-existing operations remain unchanged.
The base version is `0.1.32-dev.2`, from the existing `docs/mech-upgrade/` investigation.
This is not a claim about current upstream or deployed Mech. The source-copy
host has no compiled build stamp. Solo is the unchanged `wiki-plugin-solo`
`0.1.30-1` npm receiver. `provenance.json` records repository/package authority,
source paths, complete revision and content digests. The MIT notice for Mech,
Solo's original package/ReadMe license declaration and jQuery's embedded license
are retained. There is no opaque generated Mech bundle.

The original Code items retain their Graph import URL; original Solo retains
its Graphviz/WASM and pan/zoom URLs. Live dependency availability/content is
separate from acceptance against captured, digest-checked responses. This
slice does not pin or rewrite those Wiki-supplied imports.

The original third Play invokes `PREVIEW synopsis items`. In this bounded
candidate, `preview_emit` assigns `item.id` while the original `trails()` puts a
string (`See [[Solo Lineup Browser]]`) into `this.items`. That original operation
fails with `Cannot create property 'id' on string 'See [[Solo Lineup Browser]]'`.
The host displays the failure; it does not normalize the item or patch either
source. Publication/editing and general Wiki navigation are unavailable in
this intentionally small host. They are not required by the CODE/Solo path.

## Repeatable acceptance

```lisp
(asdf:test-system "hyperbook/fedwiki/tests")
```

```sh
node --test tests/fedwiki-mech-host.test.mjs
node scripts/cache-fedwiki-mech-test-assets.mjs /external/cache
node scripts/test-fedwiki-mech-story.mjs LISP_WRAPPER PLAYWRIGHT_DIRECTORY \
  CHROME_EXECUTABLE /external/cache /external/results
```

The cache acquisition is explicit and verifies every dependency digest before
writing it. Browser verification blocks all other executable network requests
and uses a fresh actual CLOG Inspector, a separate loopback static host and
ordinary browser Play/checkbox clicks. Cache contents, browser profiles,
screenshots and execution reports belong outside the source repository.

The retained original page fixture is reused, not duplicated or edited.
Acceptance checks full JSON equality and item identity, no Code import on
display, `2 aspects`, original opener/batch transfer, separate input node
objects, five composed nodes/four Trail relations/one shared destination,
narrow rendering, original Preview failure, failed Graph import diagnostics
and continued native item inspection. These are new isolated executions of
original sources, not replacements for historical captures or claims about
production activation, general Wiki compatibility, re-layout or renaming.

## Production demonstration through the existing Wiki

Use `https://mech.dreyeck.ch/assets/hyperdoc-mech/`. The packaged Catalog reads
`HYPERDOC_MECH_PLUGIN_HOST_URL` at startup into
`hyperbook/fedwiki::*mech-plugin-host-url*`. Missing/empty means inert, including
when clearing an earlier interactive setting. Direct `start-catalog` callers
can retain their explicitly configured value. No host or Code starts implicitly.
The existing Wiki on port 3000 serves the files; unchanged Mech opens Solo at
**`https://mech.dreyeck.ch/plugins/solo/dialog/`**, outside the asset prefix.
No new hostname, virtual host, production Node launcher or Wiki/plugin update
is required by this path.

Read-only GETs on 2026-10-10 found the explicit host `index.html` absent (404).
The directory URL returned a generic Wiki page with HTTP 200, which is not host
installation evidence. The public Solo HTML/CSS and `solo.js` were byte-identical
to the tested `wiki-plugin-solo 0.1.30-1` resources. That identifies those
resources, not the installed package version. The receiver HTML SHA-256 was
`5a513f70546ced3e2af7f83c4f14fb73d30e27f22a295558cbff4b078871aed8`;
its stylesheet was
`dbd8bce99f60ce752847cac274810ea8cd3bd93261495e6412431d5853b4de19`.

The accepted 17-check disposable browser run used a local `wiki-server 0.26.2`
ordinary assets route, versioned unchanged host files, and fresh Catalog startup
through the environment setting. Its local root Solo HTML/CSS responses were
explicitly overlaid with the byte-identical public/tested receiver resources
because the local installed Solo differed. Relative modules, opener transfer,
five nodes/four Trail relations, navigation, no Code on display and the unchanged
Preview failure passed. This is bounded local execution, not production
activation or a claim about the production Wiki server revision. The harness,
reports and screenshots remain outside the repository. The committed standalone
browser driver remains the repeatable source-level acceptance procedure above.

### Operator procedure (human only, after activation approval)

For the parameterized, revision-selected procedure with pre-switch versioned
HTTP checks and independent Catalog/asset rollback, use the **HyperDoc Mech**
section of [`dreyeck.ch deployment`](../dreyeck/pages/work/dreyeck.ch%20deployment.html).
It adds the operator-reported 11 October asset layout without rewriting the
10 October observations above. The original preparation outline below remains
context; use the newer procedure for an update.

First establish the actual paths and packaged startup; no source checkout
proves the loaded server definitions. Run read-only observations:

```sh
hostname
readlink -f /run/current-system
readlink -f /etc/nixos/flake.nix
systemctl show --no-pager --full wiki.service hyperdoc.service hyperdoc-catalog.service \
  -p Id -p ActiveState -p MainPID -p ExecStart -p EnvironmentFiles
```

Use the actual HyperDoc unit name if different. From the Wiki config named in
`ExecStart`, return only non-secret path/routing fields:

```sh
python3 - /OBSERVED/WIKI/CONFIG.json <<'PYCONFIG'
import json, sys
c = json.load(open(sys.argv[1]))
keys = ('data', 'assets', 'farm', 'port', 'host', 'wiki_domain', 'security_type')
print({k: c[k] for k in keys if k in c})
for domain, options in c.get('wikiDomains', {}).items():
    print(domain, {k: options[k] for k in keys if k in options})
PYCONFIG
```

Resolve **mech.dreyeck.ch's effective assets directory** using those settings
and the running package's farm/default-argument code. Domain overrides matter;
do not guess its pathname. Record directory ownership, any existing
`hyperdoc-mech` link, the current HyperDoc source pin/system generation, and the
existing proxy's framing/CSP headers. Do not dump credentials or cookie values.

1. Select the approved HyperDoc commit through the existing source/package
   workflow. Build `hyperdoc-catalog` and the existing NixOS configuration
   without activation. Identify the selected immutable source directory. If
   the service uses a custom old Lisp loader instead of the packaged Catalog,
   stop: that launcher does not automatically consume this setting.
2. Install a versioned copy as the site's asset operator, preserving ownership.
   Substitute the observed directory and selected full commit/source path:

   ```sh
   wiki_assets_dir=/OBSERVED/SITE/ASSETS
   hyperdoc_source=/nix/store/SELECTED-HYPERDOC-SOURCE
   hyperdoc_revision=APPROVED_FULL_COMMIT_OID
   source_assets="$hyperdoc_source/assets/hyperbook/fedwiki/mech-host"
   version_dir="$wiki_assets_dir/hyperdoc-mech-versions/$hyperdoc_revision"
   target="$wiki_assets_dir/hyperdoc-mech"
   previous_link=$(readlink "$target" || true) # retain for rollback
   test ! -e "$target" || test -L "$target" || exit 1
   test ! -e "$version_dir" && test ! -L "$version_dir" || exit 1
   mkdir -p "$version_dir"
   cp -a "$source_assets/." "$version_dir/"
   diff -r "$source_assets" "$version_dir" || exit 1
   chmod -R a+rX,a-w "$version_dir"
   test ! -e "$target.next" && test ! -L "$target.next" || exit 1
   ln -s "hyperdoc-mech-versions/$hyperdoc_revision" "$target.next"
   mv -Tf "$target.next" "$target"
   ```

   A pre-existing real directory needs preservation before proceeding. Copying
   avoids an unrooted Nix-store link disappearing after GC. Keep the full asset
   tree and provenance manifest. The bundled Solo copy stays reproducible;
   production continues using the existing root plugin route. No Wiki restart
   or page edit is needed.
3. Check actual responses, not just the directory fallback:

   ```sh
   base=https://mech.dreyeck.ch/assets/hyperdoc-mech
   curl -fsS -D /tmp/mech-host-headers "$base/index.html" -o /tmp/mech-host-index.html
   cmp "$version_dir/index.html" /tmp/mech-host-index.html || exit 1
   for resource in host.js jquery-3.7.1.min.js plugins/mech/mech.js \
       plugins/mech/blocks.js plugins/mech/interpreter.js plugins/mech/library.js; do
     curl -fsS -D /tmp/mech-js-headers "$base/$resource" -o /tmp/mech-js-body || exit 1
     cmp "$version_dir/$resource" /tmp/mech-js-body || exit 1
     sed -n '/^[Cc]ontent-[Tt]ype:/p' /tmp/mech-js-headers
   done
   curl -fsS -D /tmp/solo-headers https://mech.dreyeck.ch/plugins/solo/dialog/ -o /tmp/solo.html
   cmp "$version_dir/plugins/solo/dialog/index.html" /tmp/solo.html || exit 1
   curl -fsS https://mech.dreyeck.ch/plugins/solo/dialog/style.css -o /tmp/solo.css
   cmp "$version_dir/plugins/solo/dialog/style.css" /tmp/solo.css || exit 1
   ```

   Require HTTP 200 and the actual host HTML; JavaScript must be served as
   `text/javascript` or `application/javascript`. Check recorded response
   headers for CSP, framing restrictions, MIME and cache behavior. If Solo
   differs, stop and establish compatibility rather than replacing its source.
4. Add this single environment setting to the **existing** HyperDoc unit's
   NixOS configuration, preserving ports, site root and Wiki service:

   ```nix
   systemd.services."OBSERVED-HYPERDOC-UNIT".environment.HYPERDOC_MECH_PLUGIN_HOST_URL =
     "https://mech.dreyeck.ch/assets/hyperdoc-mech/";
   ```

   ```sh
   nixos-rebuild build --flake /OBSERVED/CONFIG-CHECKOUT#OBSERVED-CONFIGURATION
   ```

   Inspect the resulting unit/package identity. Activation requires separate
   approval, then the host's existing activation procedure with the same
   selector. Do not hot-load into the old Lisp image. A push alone neither
   changes the running package nor establishes that these definitions are served.

### Security and external browser acceptance

The successful public Wiki/Solo responses had **no observed CSP**, unlike the
local standalone launcher. Ordinary FedWiki assets do not automatically inherit
its CSP or other security headers. Missing CSP is an explicit deployment
constraint, not security parity. Check delivered headers after installation;
if policy parity is required, a separately reviewed header change belongs in
the existing proxy configuration, scoped to this path. No such configuration
change is included here. A future `frame-ancestors` response policy must permit
`https://dreyeck.ch`; a meta tag cannot supply it
([MDN](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Content-Security-Policy/frame-ancestors)).
The root Solo document does not inherit the asset prefix's headers.

The frame is separate from the Inspector but **shares the Wiki origin**,
including storage and potentially authenticated HTTP privileges. The read-only
host adapter does not prevent arbitrary JavaScript from calling Wiki endpoints.
SameSite does not isolate these HTTPS subdomains; parent-domain cookies can
span them ([cookie scope](https://developer.mozilla.org/en-US/docs/Web/HTTP/Reference/Headers/Set-Cookie)).
Keep the tested iframe sandbox unchanged. Use the approved original demonstration
with a fresh anonymous browser and explicit popup permission. Public execution
of arbitrary foreign Wiki Code is not safely isolated by this arrangement.

After human activation, use an ordinary external browser with no response
interception:

- On `https://dreyeck.ch`, open **Trails Rendered public reproduction**, follow
  the original Ward page's native Inspector link and select **Story**.
- Confirm the real asset document/module URLs, original item identities and no
  Code/Graph import before clicking. First `CLICK ▶` must report **2 aspects**.
- Second Play opens the existing root Solo route. Select both aspects: **five
  nodes, four Trail relations, one shared Reflective Practice destination**;
  the two input nodes remain distinct.
- Check native Inspector navigation and the original visible Preview error
  documented above. Record failures without changing original source.

Record source/package identity, asset/receiver digests, headers and browser
results outside the repository. Actual production activation and this ordinary
browser journey remain unverified until the operator performs them.

### Short rollback

Stop the demonstration. Restore the previous asset link atomically using the
saved `previous_link` (or remove only the new `hyperdoc-mech` symlink if none
existed). Remove the environment override and restore the previous HyperDoc pin
using the existing approved NixOS workflow, or its recorded previous generation.
Absent configuration returns the new packaged startup to inert. Keep versioned
copies until evidence is retained; never remove Wiki pages or original plugin
files. Asset-link changes require no Wiki restart. Codex performs no production
action.

## Four separate input contracts

| Subject | Authority and meaning | Current HyperDoc boundary |
|---|---|---|
| Sitemap | JSON read from one concrete site's `/system/sitemap.json`; its original fields and entry order | `fetch-sitemap` retains a copied array independently of page projections or site selection |
| Wiki neighborhood | Sites registered by the Wiki client in its browser session, including page-derived and earlier registrations | Not reconstructed; the host declares a bounded page-origin/context selection |
| Loading state | Availability of each selected site's sitemap | Separate missing/loading/ready/failed state; ready `[]` means proven empty |
| Mech execution | Pinned original NEIGHBORS and WALK interpretation | Base `0fc36fcd58a8d7c399d3e86d2ee2e9328cafba44` plus the bounded topics intake below; exact comparisons apply to identical complete inputs |

### Site selection precedes sitemap availability

The source-qualified Wiki-client reference is
[RalfBarkow/wiki-client 1aba55920f95b957bc8ccf3b3648c9b23d534c9a](https://github.com/RalfBarkow/wiki-client/tree/1aba55920f95b957bc8ccf3b3648c9b23d534c9a).
Its `lib/page.js:getNeighbors(host)` lists remote origin (or local host), then
direct `journal.site` values in forward order, removing duplicates at first occurrence.
Reference items alone are deliberately not added. `lib/refresh.js:whenGotten`
registers those sites; `lib/neighborhood.js:registerNeighbor` keeps site entries
in the browser cache and initiates sitemap loading. Earlier registrations are
not replaced merely because another page is selected. This source reference
is not a claim about the currently deployed Wiki-client revision or a capture
of its live neighborhood.

The HyperDoc snapshot instead contains **page origin and existing page context**.
Context uses most-recent Journal-site occurrence order. Duplicate sites are
removed at first occurrence after origin is prepended. This can have a different
order from Wiki-client registration, as well as omit earlier session sites.
Membership can also differ: HyperDoc `site-of` falls back to
`journal.attribution.site`, whereas this Wiki-client `getNeighbors` reads only
direct `journal.site`. Thus the selection is not guaranteed to be a subset of
the native registry; it is a bounded, explicitly different input.
Remote projection uses the actual origin, not the containing Wiki. The
process-global Lisp `*neighborhood*` registry can supply an already selected
site's cached object; its membership is never iterated to choose the input.
Neither that registry nor page-title/link projections are a browser session.

The declared `page-origin-and-context` selection is therefore a separate input
contract, not native-neighborhood equivalence. Site selection is not filtered
by reachability: an unavailable selected site remains represented, with its
state. No alternative site, reordered list or synthetic fallback is substituted.
The selection-reference fixture records forward native registration versus
HyperDoc context order and includes a fully loaded prior-session site that
must remain excluded, plus an attribution-only site included by HyperDoc but
not by the native page-derived registration. The reference output was checked
by executing the identified original `newPage(...).getNeighbors(...)` factory
offline; this is source-level execution, not a live session observation.

### Lossless retention and transport

The existing Lisp `fetch-sitemap` reads the original `/system/sitemap.json`.
Its page projection uses `slug` and `title`, and converts `links` to hash-table
keys for `make-links`; that projection does not preserve `date`, original link
values or sitemap entry order. Mech therefore receives the separately retained
raw array, not a reconstruction from those page objects.
It retains a copied JSON array and attempted source URL separately from page
skeletons and link projections. All original fields survive: `slug`, `title`,
`date`, `links` with their values, and unknown nested fields. Retention does not
register a neighborhood. A sitemap-specific state and lock distinguish missing,
loading, ready and failed independently of Wiki/plugin initialization. Failures
are recorded and retain their original propagation/handling.

Story supplies a version-1 snapshot through the existing base64 JSON/postMessage
bridge. Each selected site record carries domain, sourceUrl, state, message and
original sitemap. Entry order is unchanged; unavailable values are JSON `null`.
Snapshotting performs no fetch and does not wait for an initializer. `ready`
means retained data is available, not that the remote site was freshly verified
or that automatic refresh matches the Wiki client.

The host's `neighborhood.js` validates the boundary and supplies
`wiki.neighborhoodObject.sites`. Existing Mech extraction, ordering and graph
algorithms remain unchanged; the additional original topics mode is documented below.
There is an explicit **host availability policy**:
all declared sites must be ready before NEIGHBORS reads this input. The native
extractor would instead skip `sitemapRequestInflight` sites and continue with a
partial set. A durable test executes that original behavior and contrasts it
with the strict host gate; the two policies are not called equivalent.

The host explains unavailable data on display and on an attempted NEIGHBORS
access before emitting a zero or partial result. Proven empty input remains
executable with the candidate's original zero-result semantics. CODE trails
never requires this data access and remains usable without sitemaps. Display
initializes CLICK controls but does not execute NEIGHBORS, WALK or Code items.
Reopen Story after data becomes available to obtain another snapshot; this is
not a live subscription or a new retry/refresh implementation.

### Actual data path and the production evidence boundary

The intended data path is the existing HyperDoc **Lisp process**:
`get-fedwiki -> make-fedwiki -> initialize-fedwiki -> protocol probe ->
fetch-sitemap -> fetch-json/Drakma HTTP(S)`. HTTPS is the initial protocol;
only the existing immediate port-443 connection-refused rule switches it to
HTTP. It does not use the browser's Wiki site adapter or `/proxy` route. The
browser receives JSON already retained by HyperDoc. No new public fetch proxy,
browser-side sitemap fetch, service or TLS exception is introduced.

The prior diagnosis observed an HTTP Ward sitemap (45 entries) from the local
inspection machine. It also observed refused HTTPS connections for Ward and
two Pattern Journal sites, plus anonymous HTTP 403 at the Wiki proxy endpoint.
Those are observations of that caller and path, not proof of production-Lisp
DNS, egress, TLS or reachability for every selected site. The live server's
complete selected set and corresponding successful source reads remain
unverified. The missing/loading/failed records are precisely how this boundary
is exposed; fixture success does not establish production completeness.

Before any separate production acceptance, observe the actual service package,
source and network context, then obtain each selected site's `sourceUrl` and
state from that runtime. All declared sites require successfully retained JSON
through its existing loader. A shell curl result outside a service's network
restrictions is insufficient by itself. Do not activate or reload just to obtain
this evidence, weaken TLS or a proxy policy, or turn a failed source into empty
data. No production reachability check or activation is performed by this slice.

### Reproducible tests

`tests/fixtures/mech-sitemaps.json` is labelled trusted test data, not production
source. Its two sitemap sites/four entries include unsorted dates, original link
values, UTF-8, false/null and nested extra fields. Loader tests inject that JSON
via the existing fetch seam; their fixture URLs do **not** prove HTTP delivery.
Selection examples are source-derived reference cases, not recorded browser
sessions. Tests prove independent retention, bounded selection even with loaded
global sites, missing/loading/failed/empty distinctions and original execution.

The browser compares the same Mech revision directly on identical complete
inputs with controlled clock, locale and timezone. It substitutes no graph
algorithm and normalizes no output. Existing CODE trails/Solo and its original
Preview failure remain separate regressions. Full behavioral equivalence from
the earlier composition experiment remains failed; this data contract does not
reclassify it. The bounded `WALK topics` intake below adds a separate Ward
source authority. The subsequent original POPUP intake is documented below.

```sh
node --test tests/fedwiki-mech-host.test.mjs tests/fedwiki-mech-neighborhood.test.mjs
node scripts/test-fedwiki-mech-sitemaps.mjs LISP_WRAPPER PLAYWRIGHT_DIRECTORY \
  CHROME_EXECUTABLE /external/results
```

Run the existing ASDF Story contracts and Trails browser driver as well.
Execution output remains outside the repository. The implementation and initial
tests are in commit `99521dc6a8df21fd56fc0e9da25302bfb7b87f3f`; this clarification
adds documented boundaries and regression controls, not another Mech adapter.
No original page, service, source pin or runtime instance is changed by that
contract clarification.

## Bounded original WALK topics intake

The starting HyperDoc HEAD is `9772eefc4ec84bc2b98e2108d2aaaf2d764f0b58`,
following the sitemap implementation `99521dc6a8df21fd56fc0e9da25302bfb7b87f3f`.
This is an asset-source intake, not a production activation or whole-plugin update.

The selected upstream authority is
[WardCunningham/wiki-plugin-mech c858eff1e655e913418bfe86ddecab6053ce38b5](https://github.com/WardCunningham/wiki-plugin-mech/commit/c858eff1e655e913418bfe86ddecab6053ce38b5)
(`first version of WALK topics`). `src/client/library.js:walks` dispatches to
`topics(count)` with its nested `linked`, `newest` and `partitions` functions.
That complete function body, including its original formatting, is copied
byte-for-byte into the CODE/Discourse base,
and its switch arm is added. The upstream `src/client/blocks.js:walk_emit`
recognizes `topics`; that alternative is added to the existing downstream
`parse_walk_command` expression, preserving role-aware dispatch. No new catalog
operation, graph dependency, browser fetch or helper algorithm is introduced.

The comparison revision
[a028b4bba04e539dcaa090423d38a00a0050489d](https://github.com/WardCunningham/wiki-plugin-mech/tree/a028b4bba04e539dcaa090423d38a00a0050489d)
was inspected separately. Its topics body is reformatted; its broader library,
Graph import and dispatcher have other changes. It is not used as a replacement
for either base module, nor claimed as the executed whole-plugin revision.

The original operation examines successive seven-day windows relative to
`Date.now()`, excludes roots without links and titles ending in ` Survey`, links
to at most three known targets ordered by date, then partitions connected nodes.
It randomly orders traversal using `Math.random()`. Nodes are reconstructed by
name/type and `neighborhood.find(slug)`; the inherited duplicate-slug ambiguity
and title coalescing are not resolved here. Its `count` controls the loop, not a
new promise to return exactly that many aspects. This meaning comes from the
source, not the English word "topics".

`assets/hyperbook/fedwiki/mech-host/provenance.json` records base repository/OID,
base file digests, adopted source repository/OID/region and resulting file digests.
`tests/fixtures/mech-topics/provenance.json` records the upstream library blob,
function digest, exact original utility excerpt and retained data digests. The
source-integrity test removes just the topics insertion/recognition and verifies
that the previous base bytes are recovered. CODE, EXTRACT, EDGES, DEBUG,
role WALK and Solo source are thereby preserved rather than replaced.

### Original data and comparison boundaries

The fixtures retain the original `Pattern Machinery` JSON and Mech item
`3a62aa636c883134` unchanged, plus the original Ward sitemap captured during the
local diagnosis of 2026-10-10 (45 entries). These are historical reads, not newly
verified public content. Tests consume their exact digests; no generated graph,
screenshot or local execution log is committed as source evidence.

The ready browser control explicitly selects that one loaded Ward site. It does
not stand in for the original page/session neighborhood. The separate full
historical-context control retains `thompson.fed.wiki` and
`thompson.patterns.ustawi.wiki` as missing; no sitemap is synthesized for them.
Original page JSON, item IDs, Mech text and Code items never change. This control
changes only the test object's selected context, not production selection policy.
Production still requires every declared selected sitemap to be ready through
HyperDoc's existing loader. Their availability on dreyeck.ch remains unverified.

The Node comparison runs the real parser/dispatcher on the loaded sitemap and
executes the retained original Ward `walks` directly on the identical resulting
neighborhood. The oracle binds only the original library's import location to
its exact original utility excerpt. Original walks/Graph code is untouched;
there is no reimplementation of topics. Clock is fixed at `1791633600000`.
Multiple seeded random sequences exercise different actual node orders.
Comparison retains node type/properties/site/date, directed edges and edge
multiplicity, ignoring only numeric node IDs and enumeration order. The same
seed also checks aspect names. Browser oracle uses controlled en-US/UTC.

Fresh CLOG Inspector acceptance clicks the original first CLICK, verifies
NEIGHBORS and all three WALK commands, and compares aggregate graph content with
the bounded Ward oracle plus the unchanged weeks/hubs reference. Display alone
runs no program. Missing/loading/failed and incomplete historical context retain
visible failures. Existing original `CODE trails -> SOLO` and PREVIEW regressions
are run separately without changing their fixtures.

```sh
node --test tests/fedwiki-mech-host.test.mjs tests/fedwiki-mech-neighborhood.test.mjs \
  tests/fedwiki-mech-topics.test.mjs
node scripts/test-fedwiki-mech-topics.mjs LISP_WRAPPER PLAYWRIGHT_DIRECTORY \
  CHROME_EXECUTABLE /external/results
```

### Historical POPUP boundary after the topics slice

In Ward comparison revision `a028b4b...`, `src/client/blocks.js:popup_emit`
escapes and serializes state into HTML details, then calls
`wiki.dialog(elem.innerText, html.join('\n'))`. The source-qualified Wiki-client
`1aba55920f95b957bc8ccf3b3648c9b23d534c9a:lib/wiki.js` maps `wiki.dialog` to
`lib/dialog.js:open(title, html)`. It opens/reuses `/dialog/#` in a named popup and
posts `{title, body}` to `window.origin` after load if needed. This requires a
separate dialog receiver/lifecycle contract; it is not Solo's graph protocol.
At commit `394bb79fcd738610b7f290e062c4504f095aa070`, the reduced host provided
no `wiki.dialog` and its catalog had no POPUP. The unsupported-command result
was recorded by that slice. The subsequent intake below changes this specific
boundary; the earlier acceptance observations are not rewritten.


## Original POPUP state and regular Wiki dialog intake

Starting HyperDoc HEAD: `394bb79fcd738610b7f290e062c4504f095aa070` on
`dreyeck.ch`, with a clean index/worktree. The user reports public Pattern
Machinery results of 1,532 pages/three sites, 16 topics aspects, 25 hubs aspects
and 62 aspects received by Solo. These are author-reported runtime observations,
not the input or counts of the offline fixtures below.

The complete `popup_emit` function from
[Ward Mech a028b4bba04e539dcaa090423d38a00a0050489d](https://github.com/WardCunningham/wiki-plugin-mech/blob/a028b4bba04e539dcaa090423d38a00a0050489d/src/client/blocks.js)
is copied verbatim into the existing composition, and the POPUP catalog arm is
added. Other commands, CODE authorization, topics and Solo are unchanged.
`tests/fixtures/mech-popup/` retains the original function excerpt and original
client source as executed comparison oracles, with source-file/excerpt digests,
repository/OID/path and Git blob provenance. The product manifest records the
additional intake separately from the existing topics authority. Removing the
bounded additions recovers the previous base source digest.

### Original implementation versus provided host contract

The sender is
[Wiki-client 1aba55920f95b957bc8ccf3b3648c9b23d534c9a:lib/dialog.js](https://github.com/RalfBarkow/wiki-client/blob/1aba55920f95b957bc8ccf3b3648c9b23d534c9a/lib/dialog.js).
`wiki-dialog.js` changes only its CommonJS `module.exports` to an ES module
export. The `open` body is unchanged: open/reuse named `dialog` at `/dialog/#`,
wait for first load when needed, then post `{title, body}` to `window.origin`.
The host supplies only `wiki.dialog = open`; it does not load the full Wiki
client, supply a new authorization rule, grant editing/publication or substitute
Solo. Popup blocking and an inaccessible cross-origin named window remain
visible original errors, without a fallback receiver or permission escalation.

The existing public
[regular receiver](https://mech.dreyeck.ch/dialog/) and `/dialog/style.css` were
read on 2026-10-11. Both returned HTTP 200 with HTML/CSS MIME types and were
byte-identical to that Wiki-client revision:

- HTML SHA256: `5403bb263f87c4a9524c49f338368f0db5eaa82007bb7e25f137e905343b2e91`.
- CSS SHA256: `bb6c170aa9b81b1ea1e41301e57982bf752edef197f5197a2025e7f6bbc6886b`.

This establishes these resources, not the installed server package revision.
No CSP, X-Frame-Options or X-Content-Type-Options header was present in those
responses. The HTML response also had no COOP, COEP or CORP header in a
confirming read. The unchanged receiver/CSS/license mirror under the asset directory
supports the existing standalone local host and repeatable tests. Production
uses its already installed regular `/dialog/` route, not a new service, vhost,
root mount or receiver replacement. The asset-prefix copy is not that public
root route.

### Tested origin and HTML boundaries

The original sender targets its own origin. Tests verify initial load transfer,
fresh delivery on named-window reuse, blocked popups and cross-origin WindowProxy
failure. The existing Inspector-to-host origin/source check is unchanged.

The original receiver has **no `event.origin` or `event.source` validation**.
A real cross-origin trusted offline test sender reproduces acceptance of a
non-opener message. Wrong `targetOrigin` is dropped by the browser, but this is
not receiver authentication: another sender can supply the correct target.
The test sends only non-executable fixture markup; no live attack or production
message injection is performed. We do not add a hidden receiver check, claim
safe isolation or change the server to conceal this source limitation.

Original `popup_emit` escapes `&`, `<` and `>` in values, including serialized
objects, and omits null values. State keys inserted into `<summary>` are not
escaped; tests retain this limitation rather than silently sanitizing upstream
behavior. Actual Pattern Machinery's computed values render as literal text.
The original `images` branch is retained as source, but it is not a new verified
image workflow or endpoint. The receiver and execution frame share the Wiki
origin and its potential privileges. This contract supports the explicit trusted
demonstration; it is not a security boundary for arbitrary public Wiki code or
arbitrary message senders. Receiver validation is a separate decision.

### Acceptance and repeatable fixtures

The fresh CLOG driver keeps the complete original page JSON, Code items and
Mech item `3a62aa636c883134` unchanged. Display creates only CLICK controls.
The first CLICK computes NEIGHBORS, weeks, topics and hubs; the second opens the
regular dialog and shows that actual state. A reader can expand the native
`neighborhood` disclosure to see its values. Received neighborhood data and all
three aspect-source results are compared with the execution snapshot; the DOM
is compared against the identified original `popup_emit`, using only ordinary
browser HTML parsing. Repeated invocation proves fresh message receipt and
reuse; recomputed test input updates the existing dialog without stale state.

Two inputs are distinguished: the retained 45-entry original Ward sitemap with
an explicitly controlled origin-only selection, and an authored generator of
1,500 trusted fixture entries across three sites. The large fixture is test-only,
never production fallback, and is written outside the repository by the driver.
It does not reproduce the user's 1,532-entry public neighborhood. Escaping and
large-state rendering are tested along with popup blocking and the original
receiver's foreign-message limitation.

The browser uses `https://mech.dreyeck.ch/assets/hyperdoc-mech/` and `/dialog/`
as **offline intercepted URLs** backed by the local versioned mirrors. No new
code is executed on production. The public check above is a separate read-only
resource observation. Current public activation of this new host binding is
not established by local acceptance; installation must include the updated
`host.js`, `wiki-dialog.js` and matching composed `blocks.js` before a separate
public browser check.
No server configuration, port, original Wiki content or Lisp runtime is changed.

```sh
node --test tests/fedwiki-mech-host.test.mjs tests/fedwiki-mech-neighborhood.test.mjs \
  tests/fedwiki-mech-topics.test.mjs tests/fedwiki-mech-popup.test.mjs
node scripts/test-fedwiki-mech-dialog.mjs LISP_WRAPPER PLAYWRIGHT_DIRECTORY \
  CHROME_EXECUTABLE /external/results
```

Run the existing topics, sitemap and original CODE trails/Solo browser drivers
and fresh ASDF contracts as well. PREVIEW's original error remains unchanged.
All execution logs, HTTP observations, reports and screenshots remain outside
the source repository. The earlier failed full Behavioral-Equivalence acceptance
remains FAILED; this contract does not reclassify it.
