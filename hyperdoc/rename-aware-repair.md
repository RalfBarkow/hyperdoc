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
Add a rename-aware repair operation for HyperDoc page lookup failures.

Problem
- HyperDoc HTML pages are keyed by their current title extracted from the first
  heading/title tag.
- When an authored page link still points to the old title after a page rename,
  lookup fails as a missing hyperdoc page.
- The current repair suggestion "scaffold hyperdoc page" is wrong for rename
  cases and leads to duplicate-page pressure instead of link migration.

Goal
- Add a page-lookup-issue repair operation that finds plausible existing renamed
  target pages and rewrites the broken authored link to the selected page.

New repair operation
- Name: "Retarget to renamed page"

Applies when
- issue target hyperbook is "hyperdoc"
- issue target kind is hyperdoc page
- issue is currently open because the expected page id does not resolve
- at least one plausible existing page candidate can be found in the target
  HyperDoc

Behavior
1. Gather current pages from target HyperDoc.
2. Rank candidate pages against the missing expected page id.
3. Show a candidate list in the Repair tab.
4. When the user selects a candidate:
   - rewrite the source markup in the source page so that
     page="<old-id>"
     becomes
     page="<selected-candidate-title>"
   - preserve visible link text unless there is an explicit separate operation to
     align it
   - reload the source page / target HyperDoc
   - re-evaluate the issue so it can become fixed

Candidate ranking heuristics
- token overlap between old expected id and candidate title
- normalized slug similarity
- optional filename/title continuity if cheaply available
- optional backlink/context overlap if already available
- no automatic rewrite without user selection

UI
- In page-lookup-issue Repair tab:
  - section "Rename candidates"
  - one action per candidate: "Retarget link"
  - keep "Scaffold hyperdoc page" only as fallback when no candidate is correct

Suggested issue classification refinement
- current failure classification can remain "missing hyperdoc page"
- add a derived repair hint such as:
  "possible renamed hyperdoc page"
  when candidates exist

Validation scenario
- rename page title:
  "HyperBook Journal Tools"
  ->
  "FedWiki Journal Tools in HyperDoc"
- leave an inbound authored link in a Related section pointing to old title
- confirm page-lookup-issue appears
- confirm Repair tab offers renamed target candidate
- retarget link
- confirm link resolves and issue becomes fixed

Do not
- auto-create a duplicate page for rename cases
- auto-change visible link text during retarget unless explicitly chosen
```

The right conceptual split is:

* **lookup failure** says “old page id no longer resolves”
* **rename-aware repair** says “select the successor page and migrate the authored link”
* **scaffold** stays only for true absence

That would make your screenshoted case repairable from the issue itself instead of pushing you toward page duplication.
