Use this exact rename spec.

The key invariant is that for authored HTML pages, HyperDoc loads the page id from the first title-like element (`title`, `h1`, `h2`, …), and stores the page under that title. So this is not just a cosmetic heading edit; it is a page-id migration. In the same repo, the localhost FedWiki side is conventionally derived from the page title via a slug, and FedWiki links should prefer slug-based `page=` targets when pointing into a FedWiki hyperbook.

For this page, the coordinated rename is:

* HyperDoc title: `HyperBook Journal Tools` → `FedWiki Journal Tools in HyperDoc`
* HyperDoc file: `hyperdoc/HyperBook Journal Tools.html` → `hyperdoc/FedWiki Journal Tools in HyperDoc.html`
* Expected localhost FedWiki slug: `hyperbook-journal-tools` → `fedwiki-journal-tools-in-hyperdoc`
* No story-item ids or journal action ids need to change merely because the page title changes.

Use this as the Codex handoff:

```text
Perform a coordinated page rename for the HyperDoc page currently titled
"HyperBook Journal Tools".

Goal
- Rename the HyperDoc page title to:
  "FedWiki Journal Tools in HyperDoc"
- Keep repo conventions aligned by renaming the HTML file as well.
- Migrate authored HyperDoc links that target the old page title.
- If a localhost FedWiki twin exists, migrate that twin from slug
  "hyperbook-journal-tools" to slug
  "fedwiki-journal-tools-in-hyperdoc".
- Do not touch story item ids just for this title rename.

Why
- In this codebase, HTML HyperDoc pages are keyed by the first heading/title
  content, not by filename.
- Therefore changing <h1> changes the HyperDoc page id and requires link
  migration.
- For localhost FedWiki counterparts, title-derived slugs are the expected
  naming convention.

Required edits

1. Rename the HyperDoc file
- Move:
  hyperdoc/HyperBook Journal Tools.html
  ->
  hyperdoc/FedWiki Journal Tools in HyperDoc.html

2. Update the page title inside the file
- Change:
  <h1>HyperBook Journal Tools</h1>
  ->
  <h1>FedWiki Journal Tools in HyperDoc</h1>

3. Keep the rewritten body text that makes the page FedWiki-first and
   HyperDoc-second.
- Do not reintroduce the ambiguous "journal-aware HyperBook" framing in the
  opening paragraphs.

4. Migrate inbound HyperDoc links to the new page title
- Search authored repo content for exact old title references and update:
  page="HyperBook Journal Tools"
  -> page="FedWiki Journal Tools in HyperDoc"

- Also update any visible text that still intentionally names the old page as a
  HyperDoc page title, unless it is historical commentary.

5. Audit likely related pages
- At minimum inspect and update any references in:
  - Journalmatic Plugin
  - Journalmatic Journal Checker
  - Journalmatic Revision Replay
  - Journalmatic Repair Tools
  - FedWiki Page-Generation Workflow
  - any "Related" sections or counterpart pages that mention the old title

6. FedWiki twin handling
- Check whether a localhost FedWiki page exists at:
  /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperbook-journal-tools

- If no such page exists:
  - stop there; do not fabricate a twin just because of this rename

- If it exists:
  - create a migrated twin page under:
    /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/fedwiki-journal-tools-in-hyperdoc
  - set its title to:
    "FedWiki Journal Tools in HyperDoc"
  - preserve the old page’s useful content/story intent
  - preserve or reconstruct a valid journal:
    - create first
    - add actions chained correctly
    - monotonic dates
  - do not overwrite or silently destroy the old page first
  - after confirming the new twin is valid, decide whether the old slug should
    remain as historical residue or be removed in a separate cleanup step

7. Update HyperDoc links that point into FedWiki, if any are present for this page
- For fedwiki hyperbooks, prefer slug-based page targets rather than title-based
  page targets.

Concrete search commands

In the HyperDoc repo:
- rg -n 'HyperBook Journal Tools' hyperdoc
- rg -n 'page="HyperBook Journal Tools"' hyperdoc
- rg -n 'HyperBook Journal Tools' .

In the localhost FedWiki pages repo:
- rg -n '"title":\s*"HyperBook Journal Tools"' /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages
- test -f /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperbook-journal-tools

Validation

HyperDoc side:
- asdf:load-system :hyperdoc
- verify the renamed page resolves by new title
- verify old authored links were migrated and no longer point at the old page id
- optionally run:
  tools/check-topic-coverage.lisp
  on the renamed page if it participates in coverage expectations

FedWiki side, only if twin changed:
- python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/fedwiki-journal-tools-in-hyperdoc >/tmp/fedwiki-journal-tools-in-hyperdoc.json
- journal checks must be clear of:
  CREATION, CHRONOLOGY, REVISION, MALFORMED

Commit slicing
- Commit HyperDoc repo changes separately from localhost FedWiki pages changes.
- Do not mix journal repair work with pure HyperDoc wording/link migration if it
  can be separated cleanly.

Suggested commit messages

If HyperDoc only:
- docs(hyperdoc): rename HyperBook Journal Tools to FedWiki Journal Tools in HyperDoc

If localhost FedWiki twin also changes:
- docs(fedwiki): migrate hyperbook-journal-tools twin to fedwiki-journal-tools-in-hyperdoc
```

One subtle point: if this page is referenced by a topic object anywhere, that topic object is a separate maintenance question. Topic pages use exact title-based canonical ids for authored topic links, so a topic-title rename also requires link migration, but I do not currently see evidence that this page itself is a topic page rather than a normal HyperDoc narrative page. Treat topic changes as out of scope unless Codex finds a matching topic object or authored `hyperbook="topics"` references tied to this exact title.
