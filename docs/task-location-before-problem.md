# Task location before problem determination

**Status:** Development method and S2 case reading, not an implemented automatic task-location planner. This note belongs to Zettel 11605 and the question raised in Zettel 11601.

## Definition and order

Following the existing `problem-bestimmen` skill and the distinction in Zettel 6129 (Simon 48.2), a *problem* is a **task that cannot be solved by existing routines of behavior, action or interaction**. A task is not a problem merely because it is new to the current conversation, because a tool or representation was proposed, or because the first lookup did not locate a routine. Zettel 8992 calls for **task location** in an already learned task space first.

Use this order:

1. **Specify the task and the requested outcome**, without choosing the implementation (e.g. "determine local presence of this linked page", not "create a SQLite schema").
2. **Locate candidate routines** in the existing HyperDoc/HyperBook/SHOP3 systems, Work pages, source-backed Inspector observations and tests. Name their exact contracts and the object(s) they consume.
3. **Test applicability to this instance:** required inputs, owner/authority, side effects, source identity, observed versus hypothetical state, and limits. Identify which parts existing routines already solve.
4. **Use SHOP3 only where a relevant domain and task network exist.** Inspect all native alternatives, trees and final states as `:plan-only`. A missing planning method or no plan in an incomplete domain does not prove that no routine exists.
5. **Determine whether a problem remains.** Document the missing capability and a falsifier; only then search for or devise another method or interaction pattern. Treat an uninspected task space as *unresolved*, not as proof of novelty.

The skill is a method of inquiry; this repository does **not** currently declare a general `problem-bestimmen` ASDF system or an automatic SHOP3 task-location domain. `hyperdoc-dev task-location` shows this method; it does not execute or certify task location.

## Actual S2 case: following a link from Ward's page

The real S1 observation acquired `http://ward.asia.wiki.org/safe-and-familiar-welcome.json` (11,757 response-body octets, SHA-256 `9e8e4330bb6accb4cb39acbe6a3277c5c162ed856f9154f2d92608288bec125e`). Its native page has 17 Story Items and 28 Journal actions. Story Item index **12** contains one link to `making-the-welcome-page`, which appears in the retained source sitemap. Its presence in the *local destination wiki* has **not** been observed.

These are observations from the operator's SLY image, not checked into this repository as original response bytes; the corresponding capture remains in that image's local evidence directory. The S1 adapter lives at commit `244ff38e55f8a5a91a70bba6dc70dbc02b6fd3b9`. It neither chooses nor writes an S2 destination.

### Locate existing routines

| Existing contract | What it already does | Boundary for this task |
| --- | --- | --- |
| `dreyeck/work/fedwiki-source-acquisition:acquire-source`, `verify-snapshot` | Capture HTTP sitemap/page response bytes; hydrate and independently re-read a local source snapshot | S1 **source evidence**, not membership in the destination wiki |
| `hyperbook:find-page`, `dreyeck/work/fedwiki-local-only:make-own-site` | Resolve a page from an explicitly chosen `OWN-SITE`; current own-site implementation reads a local `pages/` store | File-backed; no SQLite method demonstrated |
| `dreyeck/work/fedwiki-local-only:observe-link` | Examine a Story Item and the actual target's local presence/absence/reading failure, preserving observation | Requires the **source page to be readable in that own-site**; the S1 capture is not automatically that site |
| `dreyeck/work/fedwiki-local-only:prepare-link`, `resolve-link` | Return native SHOP3 plans for defederation and link resolution | `:PLAN-ONLY`, with no fork or destination write |
| ASDF systems `sqlite`, `dbi` | Available in the operator's Lisp image (Zettel 11605 REPL observation) | Library availability is **not** a local-page store, schema, or established storage authority |

The existing `dreyeck/fedwiki-source-relations` reading demonstrates the same *task / task location / existing routine / problem assessment* distinction for an unrelated, historical ASDF compile-order task. It is a useful precedent, **not** a generic task dispatcher.

### Decision

The next task is **to identify the intended local wiki authority and query that authority** for `making-the-welcome-page`. No such destination has yet been selected. An empty, newly created SQLite database would establish absence **only in that new database**; it would not establish absence in an existing local Wiki. Equally, the missing `about-reserved-asset-paths` entry in Ward's sitemap does not show local absence.

Before specifying a SQLite adapter, determine whether the task can be satisfied through the existing `hyperbook:find-page` / `observe-link` contracts against the actual selected destination. If SQLite is chosen as its store, investigate implementing a **storage method behind the existing lookup contract**, preserving existing page identity, provenance and the distinction between `OBSERVED-LOCAL`, `CONFIRMED-LOCAL-ABSENCE` and `UNKNOWN`. This is a candidate adaptation, not an accepted requirement.

No S2 destination is created, no new SHOP3 domain is defined, and no fork, merge, deployment or source acquisition is performed by this document.

## Next inspection

In the existing SLY image, without new network or disk writes, inspect the known S1 object and the one Story Item:

```lisp
(let* ((page (dreyeck/work/fedwiki-source-acquisition:acquisition-page
              *s1-ward*))
       (item (aref (hyperbook/fedwiki::story-of page) 12)))
  (list :source-title (gethash "title" (hyperbook/fedwiki::raw-json-of page))
        :item-type (hyperbook/fedwiki::item-type-of item)
        :item-id (gethash "id" (hyperbook/fedwiki::data-of item))))
```

That inspection does not determine local presence. The next practical experiment must use a **named and observed local store**; it should compare its lookup behavior with existing `observe-link` before implementing new persistence.

## Related living documentation

- Work HyperDoc: **Task Location Before S2 Storage Selection** (this same case).
- Work HyperDoc: **Reading a Local-only FedWiki Link** and **A Missing Local Link in Ward's Defederation Experiment** (existing routines and their exact constraints).
- Work HyperDoc: **Planning with SHOP3** (existing planning example; no general routine-finder).
- `docs/fedwiki-local-only/README.md` (local observation and planning contract).
- `docs/welcome-development/README.md` (W1/W2 development proposals and validation; separate from task location).
