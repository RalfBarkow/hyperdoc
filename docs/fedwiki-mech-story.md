# Mech in the FedWiki Story Inspector

Story's `:mech` renderer sends the complete original page JSON, source site,
origin slug and selected item ID to a read-only browser Wiki plugin host. The
host supplies the Wiki lineup/page-object contract required by `CODE` and uses
the original Mech parser, formatter, catalog, `emit` and dispatcher. JavaScript
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
Solo popups; it cannot access the Inspector DOM. The host has no CLOG route,
publication endpoint or filesystem-browse endpoint. Its CSP bounds script and
network imports to the original dependency URLs. Do not co-host unrelated
privileged applications, credentials or services at its origin.

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
There is no authorization adapter, modified dispatcher, LISTEN forwarding or
implicit Code evaluation. Plugin failures appear in the frame; module/uncaught
failures also reach the Story status as text.

The retained runtime modules are unchanged Git source files of RalfBarkow's
CODE-capable **local candidate** `0fc36fcd58a8d7c399d3e86d2ee2e9328cafba44`,
version `0.1.32-dev.2`, from the existing `docs/mech-upgrade/` investigation.
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
