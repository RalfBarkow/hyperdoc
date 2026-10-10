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
