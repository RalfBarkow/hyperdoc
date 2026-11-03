# Original Code editor inside the Inspector (Zettel 11472)

## Scope and source observation

Started at the requested published commit
`f03d9a15234b5fdbb7c339c480d021e4a854b38a`, on the new branch
`codex/fedwiki-code-editor-inspector`, in a new clean worktree at
`/workspace/scratch/hyperdoc-fedwiki-code-editor-inspector`.
Before edits, a fresh Nix/SBCL process observed the ASDF origins of `dreyeck`,
`hyperbook` and `dreyeck/fedwiki-original-editor-demo` at that worktree.
Existing worktrees and running Lisp images were not reused or modified.

Only `(fedwiki:original-editor-test.invalid, original-editor-test,
2222222222222222)` of type `code` is supported. The test fixture starts with
`(defun square (x) (* x x))`, language `lisp`. No new generic editor framework,
paragraph editor, Topic Map vocabulary or Lisp writer is involved. The Nix and
npm pins and upstream HyperBook/Wiki files are unchanged.

## One command on macOS or Linux

From this checkout's root:

```sh
nix develop .#fedwiki-original-editor
npm ci --prefix tests/fedwiki-original-editor --ignore-scripts --no-audit --no-fund
fedwiki-original-editor-demo
```

Use the printed **Catalog** URL, then:

**Original Wiki Editor Test → Text pages → Editing One Isolated Wiki Page →
small code reference → Original Wiki editor → Edit with original Wiki plugin**.

The last control is inside the Inspector's frame. It invokes the original Code
editor, including its original textarea and language input. Click the frame's
status text **outside the Item but inside the frame** to save; the original
plugin's document-level pointer handler belongs to that frame. Then use the
Inspector's **Read stored page again**. Clicking outside the frame alone is not
a tested save gesture. Ctrl-C in the launching terminal stops the owned processes.
Both application URLs are allocated loopback ports; port 8080 is excluded.

For automatic acceptance:

```sh
fedwiki-original-editor-e2e
```

It runs two separately reported cases on separate fresh sites: `standalone`
(the pre-existing popup path) and `inspector` (one browser Page, embedded Item).
Existing macOS Chrome/Chromium detection and `HYPERDOC_FEDWIKI_BROWSER` apply.
No macOS runtime was available here: the actual browser acceptance is Linux only.

## Source-backed path, not a second editable text source

* `dreyeck/src/fedwiki-original-editor-demo.lisp`: `read-stored-page` reads the
  actual file and hydrates the existing local FedWiki page. Only the selected
  object changes CLOS class to `inspector-code-item`, inheriting the original
  Story Item's id/text/data. `item-source` retains the observed page provenance.
  The generic upstream `render-story-item` still makes the grey block and object
  reference; it has no new `:code` renderer.
* `original-code-editor-view` adds the **Original Wiki editor** Inspector view.
  It displays logical site, slug, Item ID and observed file SHA-256, then a bounded
  iframe and the existing reviewed read-only reread control. The actual Item
  remains the Inspector target; its Data and Slots views remain available.
* `tests/fedwiki-original-editor/server.mjs`: only the dedicated query on
  `/view/original-editor-test` gains an adapter. It refuses the wrong Item,
  non-code/duplicate target, missing loopback parent configuration or stale file
  revision. It reuses the original server's page/bootstrap HTML at the normal
  Wiki path; original JS assets are served unchanged. Injected configuration has
  coordinates only, no editable text/language copy.
* `inspector-code-editor.js` waits for the original client to load JSON and hydrate
  its real `.page` / `.paper` / `.story` / `.item` and item data. It keeps the
  lineup key, page model and hidden journal. It exposes only the selected Item,
  moves the original edit-enable indicator into the bounded toolbar, and refuses
  unauthorized or already browser-local page contexts. Its action calls
  `wiki.getPlugin(item.type)`, then the registered original `plugin.editor`.
* The original Code 0.6.1 editor owns text/language controls, rendering and its
  `wiki.pageHandler.put` call. Client 0.33.0 dates/serializes the ordinary Action;
  server 0.28.1 authorizes and writes `<temporary-site>/pages/original-editor-test`.
  HyperDoc's existing reread observes that file. Node is the sole writer.

The editor cannot be treated as a standalone textarea: it depends on jQuery,
`wiki.getPlugin`, `wiki.doPlugin`, `wiki.renderFrom`, the edit-enable gate,
page/lineup state and `wiki.pageHandler.put`. Keeping the real runtime within a
restricted frame avoids rebuilding those services. The full client DOM exists
inside the frame for those dependencies; its unrelated page, footer, journal and
navigation UI is suppressed. No original asset or plugin source is patched.

## Origin and authorization boundary

Catalog and Wiki use different ports and therefore different origins. CLOG never
reads or modifies the frame DOM. The adapter runs at the Wiki origin, so original
asset URLs and PUTs remain same-origin. No `postMessage` bridge or added CORS
permission is needed. The dedicated frame response has
`Content-Security-Policy: frame-ancestors <exact assigned Catalog origin>` and no
added Access-Control-Allow-Origin header. The iframe sandbox permits scripts and
its own origin; popups, forms and top-level navigation are not enabled.

This is still the original **unclaimed disposable site's** `security_legacy=true`
grant, not an authenticated person or a public authorization design. The existing
missing `window.plugins.security.setup(user)` UI error remains documented and
recorded. The adapter does not grant server authority or replace a login system.
The origin checks, CSS and edit-enable indicator are not a replacement for server
authorization. Nothing here is intended for a personal or publicly exposed site.

## Browser proof and limits

The Inspector case uses real browser pointer input. A test-only observation wrapper
counts calls and delegates to the loaded original `plugin.editor`; it supplies no
form or save operation. The original function's source digest is retained and its
body is checked for the original language control. Both loaded client and Code
plugin bytes equal the installed locked assets. The actual editor controls and
original PUT then cause the persisted change. This is stronger than a screenshot
of a similar form.

The reports verify one browser Page throughout the Inspector case, one exposed
Item, the exact coordinate, no external browser requests, no localStorage page
write/fallback, PUT 200, preserved ID, unchanged Paragraph, one appended dated edit
Action equal to the request, and a HyperDoc reread matching JSON and SHA-256 after
the Node writer stops. Negative cases refuse stale revision and wrong target.
The original standalone case must also pass. Evidence is stored under
`evidence/inspector/` with checksums; raw server logs containing generated test
session secrets are deliberately excluded.

Final Linux witness: both [standalone](evidence/inspector/standalone-report.json)
and [Inspector](evidence/inspector/inspector-report.json) cases passed with the
unchanged Nix shell, Node 24 and Chromium 156.0.8078.79. The five existing launcher
tests passed. The [embedded editor screenshot](evidence/inspector/inspector-original-editor.png)
shows the actual original controls alongside the coordinate and real Item pane;
the [reread screenshot](evidence/inspector/hyperdoc-reread.png),
[persisted page](evidence/inspector/persisted-page.json) and
[HTTP/ASDF trace](evidence/inspector/http-and-origins.txt) retain the persistence
evidence. [Provenance](evidence/inspector/provenance.json) records the initial
source observation and scope; [SHA256SUMS](evidence/inspector/SHA256SUMS) covers
these files. Historical test URLs in reports are not running services.

Limits: one fixed Code Item on a temporary site, no general plugin or navigation
support. An iframe is still a full client runtime, though its exposed UI is
bounded to the Item. Save gestures must occur inside it. Reopen from a fresh
inspection after a stale-revision refusal; there is no automatic conflict merge,
cross-process locking or crash-durability proof. Original client/plugin defects
and broader keyboard/navigation behavior are not repaired here. A personal macOS
Chrome launch and macOS E2E acceptance remain untested.

## Paragraph Item (Story Item identity and the original text editor)

The same disposable page has a second selectable Item: the Paragraph `1111111111111111`. It is a Story Item of an existing
Wiki page, nothing else: no HTML file is associated with it and the fixture site is not a second source next to any page.

* **Rendering.** The demo's stored page is shown by the page's own existing Story view (`hyperbook/fedwiki` `👀story`),
  transcluded. For the Paragraph Item the upstream `render-story-item` output is kept; the `P` additionally carries
  `data-fedwiki-site`, `-slug` and `-item-id` and an Inspector reference to the Item (a method specialised on the demo's
  `inspector-paragraph-item`, as `inspector-code-item` is for Code).
* **Identity.** `%read-stored-page` finds the declared Items by type and id, never by position (the unit test reorders the
  story). The frame URL names `(slug, id)` taken from the Item itself (`hyperdocItem=`); the server adapter holds a
  slug → id → type table of the two Items and refuses everything else. `hyperdocCodeItem=` stays Code-only.
* **Original editor.** `paragraph` has no `plugin.editor`; the original plugin binds `wiki.textEditor` to a double-click.
  The frame adapter triggers that binding. The browser case asserts `plugins.paragraph.editor` is `undefined` and
  `wiki.textEditor` is a function, then types in the original textarea.
* **Reread.** After the Node writer stops, **Read stored page again** observes the file; the Story view shows the new
  text for the same id, and the JSON shows one appended `edit` Action equal to the PUT.
* **Known upstream behaviours seen, not changed.** The Story view requests the page origin's favicon
  (`https://original-editor-test.invalid/favicon.png`; the browser context aborts it, the report counts it). A wiki
  link `[[...]]` in a stored text makes the upstream renderer fetch `https://<origin>/<slug>.json`; for the fictitious
  `.invalid` origin that signals an error in the Inspector event thread, so the test text contains no wiki link.

Evidence: `evidence/paragraph-item/` (report, screenshots, SHA256SUMS). Run: `fedwiki-original-editor-e2e` now runs
three cases (standalone, inspector, paragraph-item; `run-paragraph.mjs`).
