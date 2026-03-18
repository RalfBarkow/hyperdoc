Use this exact rename spec.

The key invariant is that for authored HTML pages, HyperDoc loads the page id from the first title-like element (`title`, `h1`, `h2`, …), and stores the page under that title. So this is not just a cosmetic heading edit; it is a page-id migration. In the same repo, the localhost FedWiki side is conventionally derived from the page title via a slug, and FedWiki links should prefer slug-based `page=` targets when pointing into a FedWiki hyperbook.

For this page, the coordinated rename is:

* HyperDoc title: `HyperBook Journal Tools` → `FedWiki Journal Tools in HyperDoc`
* HyperDoc file: `hyperdoc/HyperBook Journal Tools.html` → `hyperdoc/FedWiki Journal Tools in HyperDoc.html`
* Expected localhost FedWiki slug: `hyperbook-journal-tools` → `fedwiki-journal-tools-in-hyperdoc`
* No story-item ids or journal action ids need to change merely because the page title changes.

Use this slice-local Codex handoff:

```text
Read AGENTS.md and repomix-output-hyperdoc.md first. Then execute only the slice below.

Task
- Perform a coordinated page rename for the HyperDoc page currently titled
  "HyperBook Journal Tools".
- Rename the HyperDoc title to "FedWiki Journal Tools in HyperDoc".
- Keep repo conventions aligned by renaming the HTML file as well.
- Migrate authored HyperDoc links that still target the old page title.
- If a localhost FedWiki twin exists at slug "hyperbook-journal-tools",
  migrate it to slug "fedwiki-journal-tools-in-hyperdoc".
- Do not change story item ids or journal action ids just for this title rename.

In scope
- hyperdoc/HyperBook Journal Tools.html -> hyperdoc/FedWiki Journal Tools in HyperDoc.html
- direct authored references in:
  - hyperdoc/Journal Object Extensions.html
  - hyperdoc/Journal Gate Script and Lisp Implementation.html
  - hyperdoc/Mech Plugin Progress March 2026.html
  - hyperdoc/Story Neighborhood Workflow.html
  - hyperdoc/Ensuring Localhost FedWiki Counterparts for HyperDoc Pages.html
  - hyperdoc/FedWiki Page-Generation Workflow.html
  - hyperdoc/Journalmatic Plugin.html
  - hyperdoc/topics.lisp, but only for direct references to this page title rather than topic-title or topic-id migration
- optional localhost FedWiki twin paths:
  - /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/hyperbook-journal-tools
  - /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/fedwiki-journal-tools-in-hyperdoc

Out of scope
- unrelated topic-title, topic-id, or broad topic-factory migration work
- story-item id or journal action id rewrites done only because the page title changed
- unrelated FedWiki cleanup beyond the twin migration required by this rename

Done when
- hyperdoc/FedWiki Journal Tools in HyperDoc.html exists and begins with
  <h1>FedWiki Journal Tools in HyperDoc</h1>
- authored HyperDoc links no longer target page="HyperBook Journal Tools"
- any retained old-title text is deliberate historical commentary
- if the localhost FedWiki twin existed, the migrated twin parses and its
  journal remains replayable
- report whether the twin existed and whether it changed

Docs coupling
- Update only pages, links, and direct references coupled to this rename.
- Do not broaden into unrelated topic or journal architecture edits.

Validation
- Search for remaining old-title references:
  rg -n 'HyperBook Journal Tools|page="HyperBook Journal Tools"' hyperdoc
- Authoritative repo-shell validation:
  nix develop --command sbcl --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:load-system :hyperdoc)' \
    --quit
- Repo diff, if needed:
  nix develop --command git diff -- hyperdoc/FedWiki\ Journal\ Tools\ in\ HyperDoc.html hyperdoc/Journal\ Object\ Extensions.html hyperdoc/Journal\ Gate\ Script\ and\ Lisp\ Implementation.html hyperdoc/Mech\ Plugin\ Progress\ March\ 2026.html hyperdoc/Story\ Neighborhood\ Workflow.html hyperdoc/Ensuring\ Localhost\ FedWiki\ Counterparts\ for\ HyperDoc\ Pages.html hyperdoc/FedWiki\ Page-Generation\ Workflow.html hyperdoc/Journalmatic\ Plugin.html hyperdoc/topics.lisp
- If the localhost FedWiki twin changed:
  python3 -m json.tool /Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/fedwiki-journal-tools-in-hyperdoc >/tmp/fedwiki-journal-tools-in-hyperdoc.json
- If the localhost FedWiki twin changed, journal checks must be clear of:
  CREATION, CHRONOLOGY, REVISION, MALFORMED

Return format
- Surface answer
- Artifact answer
- Exact files changed
- Conventional commit message
- Remaining risks or unresolved edges
```

One subtle point: if this page is referenced by a topic object anywhere, that topic object is a separate maintenance question. Topic pages use exact title-based canonical ids for authored topic links, so a topic-title rename also requires link migration, but I do not currently see evidence that this page itself is a topic page rather than a normal HyperDoc narrative page. Treat topic changes as out of scope unless Codex finds a matching topic object or authored `hyperbook="topics"` references tied to this exact title.
