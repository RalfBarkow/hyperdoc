# Bibliography hyperbook / page-open boundary

These screenshots change the diagnosis.

They show that this is **not mainly an expr-link problem**. No authored `<a expr="...">` needs to run for either of these failures:

* loading the direct route `/3DF54-bibliography/coachmark`
* clicking **Bibliography** in the catalog

Both paths already fail at the **Bibliography hyperbook / page-open boundary**.

Why I say that:

The bibliography book is created through `ensure-bibliography-subcollections-hyperbook`, and its default source is `make-default-bibliography-source`, which in turn builds a `zotero-bibliography-source`.

Then page opening inside that book goes through `hb:find-page` on `bibliography-subcollections-hyperbook`, and that method immediately calls `load-bibliography-subcollection-using-source` for the requested page id. 

And the direct `coachmark` surface is wired to exactly that same loader path: `coachmark-bibliography-subcollection` calls `load-bibliography-subcollection-using-source` with `"coachmark"` and the default bibliography source. 

So the common failing seam is:

**open Bibliography book or coachmark page
→ construct default bibliography source
→ use Zotero-backed bibliography loader
→ session drops before pane open completes**

That fits your screenshots much better than the expr-evaluation theory.

It also means the earlier policy you proposed about exprs is still good policy, but it is **not the immediate cause here**. The current failure happens even before any authored expr link would need to be clicked.

There is one more strong clue in the repo context: the bibliography live-evaluation pages already record that the current authoritative Chromium state is fragile, with live cases documented as “1 failed, 2 did not run in Chromium,” and the stand-in inspection exists specifically to prove readiness **before the browser pane-open seam**.

So my answer is:

**`dreyeck.ch/3DF54-bibliography/coachmark` is crashing because the live Bibliography/Zotero-backed hyperbook-open path is failing on dreyeck.**
The failure is upstream of expr-link execution. The shared hot path is the bibliography hyperbook’s default source plus `load-bibliography-subcollection-using-source`, not authored-page rendering.

The next debugging target should therefore be:

* the server log at the exact moment **Bibliography** is opened from the catalog,
* then the same for direct `/3DF54-bibliography/coachmark`,
* specifically around bibliography source creation, Zotero bridge access, and `load-bibliography-subcollection-using-source`.

A good Codex instruction now is:

```text
Treat the current dreyeck failure as a Bibliography hyperbook open crash, not as an expr-link render bug.

Reproduce both paths:
- click Bibliography in the catalog
- open /3DF54-bibliography/coachmark directly

Then inspect the exact server-side failure boundary for:
- ensure-bibliography-subcollections-hyperbook
- make-default-bibliography-source / make-zotero-bibliography-source
- hb:find-page on bibliography-subcollections-hyperbook
- load-bibliography-subcollection-using-source

Goal:
- make opening the Bibliography catalog entry succeed without disconnecting
- make direct /3DF54-bibliography/coachmark succeed without disconnecting

Do not treat authored expr deferral as the primary fix for this slice unless the logs prove that one of those paths is still forcing expr evaluation.
```
