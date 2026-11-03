# One HTML paragraph, edited with the original Wiki paragraph editor (Zettel 11472)

Smallest slice on top of the Original Wiki Editor integration
(`tests/fedwiki-original-editor/INSPECTOR-INTEGRATION.md`). Local, isolated test data only:
no public legacy write access, no production Wiki data, no deployment. No second editor
infrastructure: the same frame adapter, the same original client, the same Node server writer.

## What is associated with what

| Thing | Where | Role |
|---|---|---|
| HTML source | `dreyeck/pages/upstream-intake/Assessing an Upstream Commit.html` | Prose source of the page. **Never written** by this slice, and not edited by it: the association adds no attribute to the file. |
| Parse-tree object | the first `<p>` of that page's `plump` tree | What the Inspector selects. Its class becomes `associated-paragraph` when the page loads (`dreyeck/src/fedwiki-paragraph-association.lisp`). |
| Wiki Item | page `assessing-an-upstream-commit`, Item `5555555555555555` (type `paragraph`) on `fedwiki:original-editor-test.invalid` | The persisted text, its identity, and its journal. |
| Page-attached ASDF system | **none** | The Wiki page has no `assets` Item and no attached system. Such a system would carry code, never this paragraph's text, and would be a separate Item. |

**The authoritative persisted text is the Wiki Item's `text`** once the association is
configured. The HTML paragraph is only (a) the seed from which the disposable page was first
created and (b) the fallback shown when no site is configured or the stored page cannot be read.
HyperDoc never copies a Wiki edit back into the HTML file; the two may therefore differ, and the
Inspector view shows both texts side by side. Turning an edit back into HTML source is a
separate, deliberate step (not implemented).

The association is declared, not discovered: `+directory-name+` / `+file-name+` and "first `<p>` in
document order" in `fedwiki-paragraph-association.lisp`, and the fixed pair (slug, Item id) in
`fedwiki-original-editor-configuration.lisp` and in `tests/fedwiki-original-editor/server.mjs`.
If the page's first paragraph is moved, the association moves with the *position*, not the text.

## How the original editor is reused

`paragraph` has no `plugin.editor`. The original paragraph plugin binds a double-click to the
client's own `wiki.textEditor`. The frame adapter (`inspector-code-editor.js`, now item-type
generic) therefore triggers that original double-click binding on the hydrated Item (for `code` it
still calls `plugin.editor`). The original editor opens on the stored text; on focus-out it calls
`wiki.pageHandler.put`; client 0.33.0 builds the ordinary `edit` Action; server 0.28.1 authorizes
and writes. `server.mjs` serves the frame for exactly two (slug, Item id, type) pairs and refuses
stale revisions, other pairings and non-loopback parents.

## Seeing the persisted change in HyperDoc

On page load, and whenever **Read stored page again** is used, `refresh-from-storage` observes the
Wiki page file (read only) and, if the Item's plain text differs from the HTML paragraph's plain
text, replaces the paragraph's children in the **in-memory** parse tree with the Item's text. If
they are equal, the HTML's own markup (such as `<code>`) stays. Reopening the page re-reads the
file. Limit: a replaced paragraph shows plain text; inline HTML markup of the source is not in the
Wiki Item.

## Use

```sh
nix develop .#fedwiki-original-editor
npm ci --prefix tests/fedwiki-original-editor --ignore-scripts --no-audit --no-fund
fedwiki-original-editor-demo
```

The launcher now also creates `pages/assessing-an-upstream-commit` in the disposable site, seeded
from the checkout's current HTML paragraph (so a locally edited HTML file is honoured and left
untouched). Then: Catalog → Upstream Intake → *Assessing an Upstream Commit* → Parse tree →
the first paragraph → **Original Wiki editor** → *Edit with original Wiki plugin* → change text →
click the frame's status text → **Read stored page again**. Reopen the page: the changed text is
shown.

## Verification, and what was not run

Run in this session (Linux, Node 22, Chromium from the environment):

```sh
node --test tests/fedwiki-original-editor/server.test.mjs tests/fedwiki-original-editor/commands.test.mjs
node tests/fedwiki-original-editor/paragraph-witness.mjs /path/to/chromium
```

`paragraph-witness.mjs` loads the frame from a loopback parent origin, opens the original editor,
saves by the original focus-out, and asserts: Item id unchanged, text changed, exactly one appended
`edit` Action carrying that id and text, earlier journal entries untouched, other page and the HTML
file byte-identical, and the refusals (stale revision, wrong pairing). It passed.

**Not run here:** no SBCL was available in this environment. The Lisp changes
(`fedwiki-paragraph-association.lisp`, `dreyeck.asd`, the configuration helper and
`dreyeck/tests/fedwiki-paragraph-association.lisp`) were written against the existing code but have
**not been compiled or tested**. In particular assumed, not observed: plump's serializer writes
text nodes unchanged (the code escapes `& < >` itself), `plump:clear`/`make-text-node` behaviour, the
`hyperdoc::file` slot of `html-page`, and the Inspector's treatment of a `plump:element` subclass.
The full Catalog browser acceptance (`fedwiki-original-editor-e2e`) was not extended or run.
Run `(asdf:test-system "dreyeck/fedwiki-original-editor-demo")` first.

Remaining limits as in the Code integration: one fixed target on a temporary site,
`security_legacy` unclaimed-site grant only, no conflict merge, and the known missing
`plugins.security.setup` client error.
