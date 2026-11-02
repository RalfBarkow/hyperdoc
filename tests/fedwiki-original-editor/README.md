# One original Wiki editor → JSON → HyperDoc test

This opt-in test creates one disposable site, opens the complete original Wiki
client in a fresh Chromium context, edits a Code item with its original plugin,
and rereads the server's file through the ordinary HyperBook Catalog. No personal
browser, existing Lisp image, production site, or upstream checkout is used.

## Local macOS or Linux: exact commands

From the repository root on this feature branch:

```sh
nix develop .#fedwiki-original-editor
node --version
npm --version
npm ci --prefix tests/fedwiki-original-editor --ignore-scripts --no-audit --no-fund
fedwiki-original-editor-demo
```

The dedicated shell pins **Node 24** (including npm) through the separate
`fedwiki-nixpkgs` input, Nixpkgs `nixos-26.05` at
`fa1373130d5a21c040a47c5dbe1913d59ed91808`. It reuses HyperDoc's existing SBCL,
ASDF dependency sources and HyperSpec. Neither the default shell nor production
Catalog package definition is changed. Since 2026-11-02 the demo is a member of the
default Catalog, read-only there unless configured (see *Catalog membership and
configuration* below). Existing
flake inputs and the npm lockfile are retained. Node 20.18.1 is not sufficient:
its CommonJS/ESM interoperability causes the reported `ERR_REQUIRE_ESM` in the
locked jsdom/html-encoding-sniffer dependency chain. The launchers refuse Node
majors other than 24 before loading that dependency tree.

Run these commands at the checkout root. No manually invented SBCL path or source
registry wrapper is needed.

### macOS cold-compilation startup fix

The former launcher cut off Catalog startup after about 120 seconds and discarded
a per-run FASL cache. On x86_64-darwin, its resulting log can end in
"compilation unit aborted; caught 2 fatal ERROR conditions" after the
launcher terminates an otherwise running compiler. That log alone does not prove
whether compilation would have succeeded.

The interactive demo now retains FASLs in a dedicated, reusable cache under
~/Library/Caches/hyperdoc/fedwiki-original-editor/ on macOS (under
$XDG_CACHE_HOME/hyperdoc/fedwiki-original-editor/, or ~/.cache/..., on Linux).
The cache key includes the checkout path, SBCL executable, ASDF registry, Nix
lock and system definition. ASDF still checks source modification times.
This does not use an existing SLY process or personal ASDF cache.
A clean initial invocation may still compile many dependencies.

The Catalog has a bounded startup deadline of 900 seconds (15 minutes), not the
old 120 seconds. The launcher prints readiness progress every 15 seconds and
includes the last 45 log lines, exit status and full log path on failure;
an early exit is distinguished from a live process exceeding the deadline.
For especially slow development machines, optionally set:

    export HYPERDOC_FEDWIKI_CATALOG_START_TIMEOUT_SECONDS=1800

Only values from 30 to 3600 seconds are accepted. The original Wiki server
retains its shorter startup bound. Neither change alters the original Wiki
client, plugin, Catalog membership, port 8080 or production services. Do not
start multiple simultaneous demos sharing the same FASL cache.

The demo creates a new temporary site with exactly
the Paragraph and original square-function Code Item. It starts the original Wiki
server and a fresh HyperDoc Catalog on automatically selected, distinct loopback
ports, never 8080. It prints both URLs **after** receiving successful HTTP replies
and checking the processes' own bind confirmations. Open the printed Catalog URL:

**Catalog → Original Wiki Editor Test → Text pages → Editing One Isolated Wiki Page**.

For the **embedded Inspector case**, click the small **code** reference above the
grey code block. In that actual Item's Inspector pane, select **Original Wiki
editor**, then click **Edit with original Wiki plugin** inside the frame. Edit
text and language; click the frame's status text outside the Item to save. Then
press **Read stored page again** in the Inspector to verify from the file.
This path opens no second tab. The item ID, logical site, slug and source revision
remain visible above the editor. The separate **Open original Wiki client** link
is retained for the earlier standalone case. There is no claimed direct
HyperDoc-page URL. See [the integration boundary and evidence](INSPECTOR-INTEGRATION.md).

**Stop:** Ctrl-C in the launching terminal stops only the processes it started.
It first requests normal Catalog shutdown via its private stop file, then uses
bounded signal fallbacks. Temporary test data and private logs remain at the
printed directory for inspection. No service, port 8080 or existing Lisp image is
touched. No personal Wiki root is accepted as an input to the demo command.
Optional port variables are `HYPERDOC_FEDWIKI_WIKI_PORT` and
`HYPERDOC_FEDWIKI_CATALOG_PORT` (distinct unused ports 1024–65535, excluding 8080).
No public tunnel or outward-facing proxy is started.

For the automated browser witness, in the same shell after stopping the demo:

```sh
fedwiki-original-editor-e2e
```

It runs `run.mjs` twice with this shell's SBCL and a verified Chrome/Chromium:
first the existing standalone case, then the item-specific Inspector case. Each
gets its own temporary site, browser context and report (`integrationCase` is
`standalone` or `inspector`). Both must pass; both report paths are printed.
An optional single argument selects an output directory outside the checkout:

```sh
fedwiki-original-editor-e2e /tmp/hyperdoc-original-editor-evidence
```

Ctrl-C also terminates this command's own test processes. Each run creates a fresh
site. E2E acceptance remains the same: browser edit, PUT 200, actual file change,
unchanged Item ID/paragraph, dated journal, no localStorage fallback, and independent
HyperDoc reread. The initial fixture is shared by demo and test. HyperDoc's actual
ASDF origins are asserted before startup; FASLs are isolated in the temporary run. Initial Nix downloads and fresh Lisp
compilation can take several minutes; the interactive command prints its log
directory before waiting. Set HYPERDOC_FEDWIKI_TMPDIR only if you need a different
temporary parent (default /tmp, outside nix develop -c's disposable TMPDIR).

### Browser selection

On **macOS**, Playwright Core uses an already installed Google Chrome or Chromium.
The detector checks executables in `/Applications` and `~/Applications`, including
spaces in app paths, then verifies the selected program with `--version`. No browser
is installed globally. An explicit selection is supported (and fails visibly if
not executable or not identifiable as Chrome/Chromium):

```sh
export HYPERDOC_FEDWIKI_BROWSER="/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
fedwiki-original-editor-e2e
```

On **Linux**, Chromium is supplied by the new Nixpkgs pin. The same explicit
variable overrides it. The E2E launcher prints the verified executable and version;
it uses a fresh browser context/profile, not a personal browser session. The
interactive demo itself does not launch or change any browser profile: open its
printed URLs in your browser. Browser detection tests on Linux cover Darwin path
selection but do not establish macOS browser/runtime compatibility.

`commands.test.mjs` checks platform path selection, argument-safe executable probes,
explicit failure and rejection of Node 20:

```sh
node --test tests/fedwiki-original-editor/commands.test.mjs
```

The lower-level `node tests/fedwiki-original-editor/run.mjs LISP CHROMIUM OUTPUT`
and `serve.lisp` remain available for diagnostics; ordinary local use should use
the two shell commands above.

## Catalog membership and configuration

`dreyeck/fedwiki-original-editor-demo` is admitted to `dreyeck/catalog`, so every
Catalog, including the public one, lists *Original Wiki Editor Test*. Loading it
reads no variable and offers no editor. Three variables, all unset by default,
configure it (`dreyeck/src/fedwiki-original-editor-configuration.lisp`):

| Variable | Effect |
| --- | --- |
| `HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT` | The one site directory read back. Unset: *unconfigured*, nothing is read, linked or embedded; the page says so. Never falls back to `HYPERDOC_FEDWIKI_SITE_ROOT`. |
| `HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN` | The original Wiki origin linked as *Open original Wiki client*. Must be `http(s)://host[:port]` without a path. |
| `HYPERDOC_FEDWIKI_EDITOR_TEST_MODE` | Unset or `read-only`: no frame. `isolated-loopback` with an origin `http://127.0.0.1:PORT`: the item-specific frame. Anything else is refused and named. |

Both launchers set `isolated-loopback`; `serve.lisp` asserts that mode and that the
demo is in the Catalog once. A missing page or a page without exactly one target
Code Item gives a read-only explanation instead of a condition. The mode decides
only whether HyperDoc offers the frame; the original server authorizes every write.

`server.test.mjs` runs the original server through `server.mjs` without Lisp or a
browser (after `npm ci`): without `security_legacy` every PUT is 403 and the adapter
refuses; the adapter serves only the one Item at the observed revision to the exact
loopback parent; and with `security_legacy=true` any visitor can create any page of
the unclaimed site, which is why that grant stays in this loopback test:

```sh
node --test tests/fedwiki-original-editor/server.test.mjs
```

Wiki-farm connection, its open decisions and the operator steps:
[docs/fedwiki-original-editor-farm](../../docs/fedwiki-original-editor-farm/README.md).

## Versions and compatibility

The lockfile fixes Wiki 0.41.0, client 0.33.0, server 0.28.1, Code plugin 0.6.1,
Paragraph package 0.4.0 and Playwright Core 1.56.1. Wiki 0.41.0 declares the
client 0.33 and Code 0.6.1 combination; exact overrides prevent version drift.
This is a separate test installation, not an update to `/workspace/wiki`.

Code 0.6.1 exports `emit`, `bind`, and `editor`; its editor requires `.editEnable`,
an enclosing `.page`, `wiki.doPlugin`, `wiki.renderFrom` and `wiki.pageHandler.put`.
The chosen client supplies those APIs. The browser asserts their presence, then
uses actual double-click, fill and pointer input. It also checks that the loaded
`/client.js` and `/plugins/code/code.js` equal the original installed bytes.
No editor, textarea, save handler or pageHandler implementation is supplied here.
Paragraph rendering/editing is built into the original client's `lib/paragraph.js`;
the separate Paragraph 0.4.0 package supplies its documentation pages.

## What passes

1. With original default security and `security_legacy=false`, PUT gets 403 and
   the initial page bytes stay unchanged. That server is then stopped.
2. The original server grants editing of the unclaimed test site using its
   `security_legacy=true` option. This is an explicit loopback test permission,
   not an authenticated owner login or HyperDoc's signed authoring protocol.
3. Catalog → **Original Wiki Editor Test** → **Text pages** →
   **Editing One Isolated Wiki Page** shows the initial Code through the unchanged
   generic renderer: grey block and clickable `code` reference. The reference
   opens the actual item's Data view, including its ID and language.
4. The original client edits `text` to `(defun square (x) (expt x 2))` and
   `language` from `lisp` to `commonlisp`. The PUT returns 200. The server's
   configured `db` is asserted to equal `<run>/site/pages`; its actual file is
   `<run>/site/pages/original-editor-test` (no `.json` suffix).
5. The persisted two-item story retains Code ID `2222222222222222` and the
   unchanged Paragraph ID `1111111111111111`. Exactly one dated `edit` Action is
   appended; the previous journal and paragraph remain structurally equal.
   The last Action equals the browser request. No localStorage page write,
   page key, or `.page.local` fallback is permitted.
6. The Node writer stops. **Read stored page again** invokes the existing
   reviewed-control mechanism for a read-only operation. HyperDoc independently
   reads the same file and displays matching JSON, journal, SHA-256 and code.
   The Verified Example system is not loaded; its renderer cannot mask this test.

One HTML `<p>` has explicit `data-fedwiki-site`, `data-fedwiki-slug` and
`data-fedwiki-item-id` attributes. The test resolves them from the real Lisp
HyperDoc parse tree and checks the exact Paragraph coordinate. The explanatory
HTML text is not a duplicate of the Wiki paragraph text. No automatic conversion
or Topic Map projection is implemented.

## Nix-shell acceptance (2026-11-01)

Observed on x86_64-linux in the managed cloud, using real Nix develop commands:

| Check | Result |
| --- | --- |
| `nix develop .#fedwiki-original-editor -c node --version` | `v24.22.1` |
| `nix develop .#fedwiki-original-editor -c npm --version` | `11.19.1` |
| Locked `npm ci --ignore-scripts` | 270 packages installed |
| `fedwiki-original-editor-e2e` | PASS with Nix Chromium 156.0.8078.79 |
| Browser selection / Node guard tests | 3 passed |
| Interactive demo | Both actual URLs returned HTTP 200; fresh two-item page |
| Ctrl-C / SIGINT | Demo confirmed cleanup; both listeners stopped |
| Explicit port 8080 | Refused before any service startup |
| E2E with a symlink evidence directory | Passed; canonical FASL containment checked |
| `x86_64-darwin` shell evaluation | Passed; no macOS runtime available |

[Validation](evidence/nix-environment/validation.json),
[E2E report](evidence/nix-environment/report.json),
[HTTP / ASDF evidence](evidence/nix-environment/http-and-origins.txt),
[demo lifecycle](evidence/nix-environment/demo-smoke.json),
[Catalog dependency comparison](evidence/nix-environment/catalog-comparison.json),
[stored JSON](evidence/nix-environment/persisted-page.json),
[screenshot](evidence/nix-environment/hyperdoc-reread.png), and
[checksums](evidence/nix-environment/SHA256SUMS) preserve the observations.
Historical temporary URLs in these artifacts are not live services.

The cloud's Nix store is relocated. The actual Nix runs used a temporary bwrap
namespace binding it to /nix outside the shell sandbox; this is an executor
adapter, not a repository requirement or a replacement Node/Lisp/browser runtime.
macOS users with ordinary Nix do not need it. No macOS Chrome launch, ESM load or
E2E success is claimed. Darwin shell evaluation and path-selection tests do not
close that gap: local macOS acceptance is still required.

The existing Lock nodes are unchanged. Standard-shell and production-package
**definitions** are byte-identical to cc781f77. The Catalog dependency derivation
comparison passes after normalizing the changed repository source snapshot and
its output path; the source snapshot necessarily changes with repository edits.
No default Catalog membership, Review page, original Wiki package source or npm
lockfile changed. The initial fixture was extracted unchanged into fixture.mjs;
all prior E2E acceptance assertions remain in run.mjs.

ASDF setup belongs to the fresh test process only: supplied source trees are
selected explicitly, personal ASDF configuration is ignored, and all FASLs go to
an isolated cache preserving full source directories. This avoids appending an
s-expression to Nix's colon-form ASDF_OUTPUT_TRANSLATIONS and avoids collisions
between unrelated package.fasl files. The cache directory is canonicalized first (macOS normally links /tmp to
/private/tmp). The runtime checks cache containment,
separation of same-named files, and actual application ASDF origins before serving.
The first startup diagnostics found these integration issues; the recorded final
Nix E2E run passed after repair. No Nix-store source was modified to work around them.

The SIGINT smoke test signalled its dedicated test process group. The outer
Nix/bwrap wrapper exited by SIGINT (not exit 0); the demo printed its cleanup
confirmation, and independent HTTP probes confirmed both listeners were closed.
Only PIDs created by the launch adapters are targeted during cleanup.

## Earlier cloud witness and remaining limits

The repeat run passed on 2026-11-01 with Chromium 154.0.8037.57.
Durable review evidence is in [evidence/report.json](evidence/report.json),
[evidence/persisted-page.json](evidence/persisted-page.json),
[evidence/http-and-origins.txt](evidence/http-and-origins.txt) and
[evidence/hyperdoc-reread.png](evidence/hyperdoc-reread.png).
`evidence/SHA256SUMS` covers these four files. Full transient logs remain under
`/tmp/hyperdoc-original-editor-review-evidence/run-nEVBrW/`; these contain the
original server's generated session secret and are deliberately not committed.
The retained report's temporary origins are historical evidence, not running URLs.

The actual file was
`/tmp/hyperdoc-original-editor-review-evidence/run-nEVBrW/site/pages/original-editor-test`.
SHA-256 changed from
`42953ba47d6fea227f84d1430a0b41cbdfa98ddaa96a90e5215f9c155b479288` to
`68ddf2c1a208bf0c6d6539ae77b78ab3a226b25c841715abc8c1fc4fcb299a6f`.
The persisted edit date is `1793552287546` milliseconds since the Unix epoch.
The report records matching Item ID, language, request Action, unchanged paragraph,
no localStorage fallback, original asset byte equality, independent HyperDoc reread
and no external browser requests. The original first successful run was
`/tmp/hyperdoc-original-editor-evidence/run-yLi2VV/report.json`.

### Exact legacy security UI limitation

In client 0.33.0, `lib/security.js:7` asks `plugin.getScript` to load
`/security/security.js` and then calls `window.plugins.security.setup(user)`.
In `lib/plugin.js:30–41`, the loader catches a failed script load but still calls
the callback. With the original default `wiki-server/lib/security.js` module,
there is no corresponding browser plugin: the request returns **404**, and
`window.plugins.security` is undefined. Thus the missing callable is
`window.plugins.security.setup(user)`; it is not a missing server-side
`isAuthorized` function. The exception is raised on initial Wiki-client startup,
before the test double-clicks or saves Code. The repeat run recorded exactly one
`Cannot read properties of undefined (reading 'setup')` error.

That security UI cannot initialize a login/owner interaction. The default module
has no login routes, returns an empty user and does not authenticate a person.
Its legacy branch grants requests whenever the site is unclaimed. `isOwner=true`
in this browser therefore means the server granted editing, not that a human
logged in. Editing is enabled through the client's normal footer toggle; the
Code editor and persistence do not depend on the absent security UI setup.
This test does not prove working login, owner claiming, logout or session security.

The grant applies only to this disposable unclaimed site. It is not restricted
to the one Item or to `edit` Actions: anyone able to reach this loopback server
could use its other permitted Wiki writes. The isolation assumptions are the
fresh temporary data/home, loopback-only binding, no public forwarding/proxy,
no personal browser cookies, no production data and stopping the test processes.
The browser's two-origin allowlist restricts this test browser's outbound traffic;
it is not server authentication. Neither the edit-enable UI nor the logical
`.invalid` site identity is a security boundary. No shim, security plugin or new
authorization architecture is introduced to hide the error. The test refuses
other uncaught browser errors. Authenticated deployment remains untested.

The supplied URL navigates to the Wiki **page**, not a particular Item. The
client's standard state path represents site/page lineups; no item-specific
editor deep link was established. No custom item navigation is added.
The original file adapter uses `fs.writeFile`; crash durability is not tested.
HyperDoc's reader can coexist with Node, but this test stops Node before its
final reread; Lisp never writes the test page. Existing review pages remain
unchanged. The demo system is opt-in, not added to default Catalog membership.
