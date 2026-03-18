Yes. That is exactly the right consequence to optimize for.

Because HyperDoc text pages are keyed by the page title extracted from the first heading, changing `<h1>` changes the page id. `find-page` then looks up by that id, so old `page="HyperBook Journal Tools"` links become ordinary missing-page failures.  

So the repair flow should not jump straight from:

* old target missing
  to
* scaffold a new page

It needs an intermediate rename-aware repair.

## Proposed operation

Add a repair operation on `page-lookup-issue`:

**Retarget to renamed page**

That operation should do one job: replace the broken old `page=` target in the source page with the selected existing page title.

For your screenshot, the flow should be:

* issue sees expected page id `HyperBook Journal Tools`
* it searches current `hyperdoc` pages for plausible rename candidates
* user picks `FedWiki Journal Tools in HyperDoc`
* operation rewrites the source link in `Journal Object Extensions`
* issue becomes fixed after reload

That fits the documented maintenance rule already present elsewhere in the repo: a title change is a link migration problem, and the safe procedure is to find authored links using the old title and update them to the new canonical title.

## Why this operation is needed

Right now the issue model treats the failure as “missing hyperdoc page” and suggests “scaffold hyperdoc page.” That is correct for a genuinely absent page, but wrong for a rename. Since HTML pages are loaded under their current heading text, a renamed page is indistinguishable from a missing page unless repair logic explicitly searches for rename candidates.  

So the repair model should distinguish at least:

* **missing page, no plausible successor**
* **missing page, plausible renamed successor exists**

## Exact operation semantics

### Name

**Retarget to renamed page**

### Availability

Show it for `page-lookup-issue` when:

* `target hyperbook = hyperdoc`
* `target kind = hyperdoc page`
* current lookup failed
* at least one plausible existing page candidate is found

### Inputs

From the issue object:

* source page
* source section
* link text
* expected old page id
* target hyperbook

### Candidate discovery

Search current pages in the target HyperBook and rank candidates by heuristics such as:

1. token overlap between old id and candidate title
   example: `HyperBook Journal Tools` vs `FedWiki Journal Tools in HyperDoc`

2. filename/title continuity if available
   useful because repo convention often keeps filename aligned with title, while the semantic identity is the title loaded from `<h1>`. 

3. backlink/context overlap
   pages linked from similar “Related” neighborhoods should rank higher

4. optional exact alias map later, if you decide to add one

The key point is: this is a **candidate finder**, not automatic truth. The human chooses.

### Action

When the user selects a candidate page title:

* rewrite the authored source link target
* from:
  `page="HyperBook Journal Tools"`
* to:
  `page="FedWiki Journal Tools in HyperDoc"`

Do not create a new page.
Do not silently change visible link text unless explicitly requested.

### Result

After rewrite and reload:

* the page link should resolve
* the lookup issue should disappear
* backlinks should accrue to the renamed page

That verification matches the existing documented rename-maintenance procedure.

## UI shape

For the `Repair` tab of `page-lookup-issue`, I would show:

* **Rename candidates**

  * `FedWiki Journal Tools in HyperDoc`

    * reason: shares tokens `journal`, `tools`
    * reason: existing HyperDoc page
* action button: **Retarget link**
* optional fallback below: **Scaffold missing page**

So scaffold remains available, but only as the fallback after rename candidates are rejected.

## Minimal implementation rule

Do **not** try to “open the renamed page” by guessing and navigating only.

The operation should be **editorial**, not merely navigational:

* inspect candidate
* then rewrite source
* then reload

Otherwise the user can view the right page, but the red link and lookup issue remain.

## Exact Codex handoff

```text
Read AGENTS.md and repomix-output-hyperdoc.md first. Then execute only the slice below.

Task
- Add a rename-aware repair operation for HyperDoc page lookup failures.
- Add the repair operation name "Retarget to renamed page".
- When a HyperDoc page link fails because it still points at an old page title,
  offer plausible renamed-page candidates and let the user retarget the authored
  link to the selected existing page.

In scope
- hyperdoc-explorer/lookup-repairs.lisp
- directly coupled issue construction or repair-view files only if needed for
  this behavior:
  - hyperbook-explorer/lookup-failures.lisp
  - hyperbook-explorer/link-views.lisp
  - hyperdoc-explorer/html-pages.lisp

Out of scope
- FedWiki lookup repair behavior
- non-HyperDoc HyperBook lookup repair behavior
- unrelated scaffold-plan redesign or chunk-architecture refactors
- visible link-text rewriting unless you add that as a separate explicit action
- HyperDoc page documentation updates unless they directly document the new
  repair behavior

Done when
- a missing HyperDoc page lookup can surface rename candidates when the current
  page id does not resolve but plausible existing titles do
- the Repair tab lets the user inspect and apply "Retarget to renamed page"
- selecting a candidate rewrites the source link target from the old page id to
  the selected page title
- the operation preserves visible link text by default
- true missing-page cases still leave scaffold repair available as the fallback
- FedWiki and generic non-HyperDoc lookup behavior remain unchanged

Docs coupling
- Update HyperDoc pages only if they directly document the new repair behavior.
- Do not broaden into unrelated lookup-issue design notes.

Validation
- Authoritative repo-shell validation:
  nix develop --command sbcl --no-userinit --non-interactive \
    --eval '(require :asdf)' \
    --eval '(asdf:load-system :hyperdoc)' \
    --quit
- Validate the named scenario in code or a narrow smoke test:
  - rename page title "HyperBook Journal Tools" -> "FedWiki Journal Tools in HyperDoc"
  - leave one inbound authored link pointing at the old title
  - confirm the issue offers the renamed target candidate
  - retarget the link
  - confirm the link resolves and the issue becomes fixed
- Repo diff, if needed:
  nix develop --command git diff -- hyperdoc-explorer/lookup-repairs.lisp hyperbook-explorer/lookup-failures.lisp hyperbook-explorer/link-views.lisp hyperdoc-explorer/html-pages.lisp

Return format
- Surface answer
- Artifact answer
- Exact files changed
- Conventional commit message
- Remaining risks or unresolved edges
```

The right conceptual split is:

* **lookup failure** says “old page id no longer resolves”
* **rename-aware repair** says “select the successor page and migrate the authored link”
* **scaffold** stays only for true absence

That would make your screenshoted case repairable from the issue itself instead of pushing you toward page duplication.
