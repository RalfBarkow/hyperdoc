# One original Wiki editor → JSON → HyperDoc test

This opt-in test creates one disposable site, opens the complete original Wiki
client in a fresh Chromium context, edits a Code item with its original plugin,
and rereads the server's file through the ordinary HyperBook Catalog. No personal
browser, existing Lisp image, production site, or upstream checkout is used.

## Reproduce

Run from this HyperDoc checkout, based on
`2b864774ee6a1e9e4187e64d863f8ea39e53430f`:

```sh
npm ci --prefix tests/fedwiki-original-editor --ignore-scripts \
  --cache /tmp/hyperdoc-fedwiki-npm-cache --no-audit --no-fund
node tests/fedwiki-original-editor/run.mjs \
  /absolute/path/to/fresh-sbcl-wrapper /absolute/path/to/chromium \
  /tmp/hyperdoc-original-editor-evidence
```

The Lisp wrapper must forward all arguments to SBCL, without user/system init,
with this checkout first in the ASDF source registry and the existing HyperDoc
dependencies available. `serve.lisp` asserts the actual ASDF origins of `dreyeck`,
`hyperbook` and the demo. It fails rather than using a different checkout.
In a working repository `nix develop --no-write-lock-file` shell, `sbcl` can be
passed directly; put `$PWD//` first in `CL_SOURCE_REGISTRY` before the command.
The test does not install Lisp dependencies or alter a running image.

The observed cloud run used `/tmp/hyperdoc-editor-lisp-wrapper`, forwarding to
the already available relocated SBCL 2.4.10 and dependency registry from
`/workspace/scratch/tmdm-mcp-portable/environment.json`, with
`/workspace/hyperdoc//` replaced by this worktree's path. This is an execution
environment detail, not a dependency on another worktree's application code.

Output gets a new `run-*` directory, logs, screenshots, `report.json`, and the
retained test site. Both servers bind to random loopback ports; the fresh browser
allows only these two origins. Processes stop at the end. There is no deploy,
push, content evaluation, or Lisp write to the Wiki file.

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

## Observed result and limits

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

## Open the opt-in Catalog demonstration locally

This is an operator procedure for a **fresh local test process**, not an
instruction to reload or modify an existing SLY image or running personal Catalog.
The only application changes are the six-line ASDF system declaration, the
read-only demo Lisp file and its HTML page. Loading
`dreyeck/fedwiki-original-editor-demo` registers the HyperBook named
**Original Wiki Editor Test**; default Catalog membership is not changed.

First make the branch available in a separate local checkout by your chosen
review/transfer procedure (nothing has been pushed), install the locked npm
packages as above and provide SBCL with the existing HyperDoc dependencies and
this checkout first in its source registry. The cloud test asserted those origins;
your local dependency installation has not been tested here.

From that checkout, in a test terminal with two **unused** chosen ports:

```sh
# The port numbers below are examples, not claims about a running local service.
repo_root="$PWD"
test_site="$(mktemp -d /tmp/hyperdoc-wiki-review.XXXXXX)"
mkdir -p "$test_site/pages" "$test_site/home"
cp tests/fedwiki-original-editor/evidence/persisted-page.json \
  "$test_site/pages/original-editor-test"
export HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT="$test_site/"
export HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN="http://127.0.0.1:18091"
export HYPERDOC_EDITOR_TEST_CHECKOUT="$repo_root/"
export HYPERDOC_EDITOR_TEST_CATALOG_PORT=18092
export HYPERDOC_EDITOR_TEST_STOP="$test_site/stop-catalog"
export HYPERDOC_FEDWIKI_SITE_ROOT="$test_site/"

# Use a temporary HOME only for the original Wiki test server.
env HOME="$test_site/home" node tests/fedwiki-original-editor/server.mjs \
  "$test_site" 18091 true >"$test_site/wiki.log" 2>&1 &
wiki_test_pid=$!
trap 'kill "$wiki_test_pid" 2>/dev/null || true' EXIT

# SBCL here means your configured fresh runtime/wrapper, as for run.mjs.
sbcl --noinform --no-sysinit --no-userinit --script \
  tests/fedwiki-original-editor/serve.lisp
```

Before using the browser, confirm the Wiki log reports the chosen `db` and the
Catalog output reports the expected ASDF origins and loopback listener. Change
both port settings and the origin together if either port is occupied. The above
manual port selection is configuration guidance; it was not tested on your machine.
The runner tests the same adapters with allocated free ports.

Open the local Catalog origin **actually reported by that process**, then use the
browser-tested path:

**Catalog → Original Wiki Editor Test → Text pages → Editing One Isolated Wiki Page**.

The Main page also renders this HTML, but the recorded witness used Text pages.
There is no claimed direct HTML-page URL. **Open original Wiki client** supplies
the configured separate Wiki origin and `/view/original-editor-test`; that route
was exercised at the repeat run's allocated port, not at the example ports above.
The copied page already contains the recorded edited text; it is a disposable
copy and may be edited again. **Read stored page again** reads the configured
JSON file afresh. The signed HyperDoc authoring path is not involved.

To stop cleanly, create the configured stop file from a second terminal (use the
actual temporary path printed in the JSON-file display). `serve.lisp` shuts the
Catalog down; the shell's EXIT trap then stops the Wiki process. Retain or remove
only this temporary test directory. Do not substitute a personal site root.
