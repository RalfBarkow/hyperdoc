# Practical Common Lisp to HyperDoc

This note uses the current HyperDoc/HyperBook codebase as the target, not a greenfield Lisp system. The aim is to extract small refactors that fit the existing inspector, HyperBook, and FedWiki architecture.

## Chapter to Refactor Matrix

| PCL Chapter / Topic | HyperDoc target area (file/module) | What to change (1-3 bullets) | Why (one sentence, pragmatic) | Smallest test / example to prove it works | Risk / constraints |
| --- | --- | --- | --- | --- | --- |
| Chapters 7-9: Macros | `hyperbook-server/playground-eval.lisp`, `hyperdoc-inspector/views.html`, `hyperdoc-explorer/explorer.lisp` | - Introduce one small macro for repeated inspector action/view bundles. - Use it in exactly one place first. - Keep expansion obvious in generated HTML/view code. | HyperDoc has repeated view/button boilerplate and a small macro can reduce drift without hiding control flow. | Migrate one existing view bundle and verify the rendered tabs/buttons stay identical. | Macro misuse can make view code harder to debug if expansion is not kept local and simple. |
| Chapter 16: Object Reorientation / generic functions | `hyperbook-fedwiki/story-items.lisp`, `hyperbook-fedwiki/views.lisp`, `hyperdoc-explorer/html-pages.lisp` | - Prefer one method per story item / page type over type dispatch by conditionals. - Add missing methods where a fallback is swallowing behavior. - Keep view methods close to their data classes. | The repo already leans on CLOS, so missing behavior is usually best fixed by adding the right method, not another branch. | Add one missing method such as markdown link extraction and confirm the Links view populates. | Method proliferation can hide control flow if methods are split across too many files. |
| Chapter 17: Generic functions and class evolution | `hyperbook-server/playground-debug.lisp`, `hyperbook-server/web-debugger.lisp`, `hyperbook-fedwiki/pages.lisp` | - Use small report/session classes for inspector-visible state. - Keep UI state in objects instead of ad hoc plist/thread globals. - Add narrow readers/accessors for report state. | HyperDoc becomes easier to inspect and extend when debugger/eval state is represented as normal objects. | Inspect a debug report/session object and confirm all state needed by the UI is in slots. | Object shape changes affect serialized or long-lived state if the class is reused later. |
| Chapter 19: Conditions and Restarts | `hyperbook-server/playground-debug.lisp`, `hyperbook-server/playground-eval.lisp`, `hyperbook-server/web-debugger.lisp` | - Convert Playground eval failures into inspectable recovery objects. - Offer retry/abort style recovery from the report UI. - Keep full SBCL debugger sessions as the heavier path. | This gives a Lisp-native recovery model inside HyperBook instead of forcing all failures into logs or the terminal debugger. | Select `(/ 1 0)` in Playground, click Debug, then Retry after editing/fixing the code or Abort to keep the report. | Dynamic Common Lisp restarts cannot safely outlive the stack frame unless the thread stays paused; UI-level recovery must be explicit about that boundary. |
| Chapter 21: Packages | `hyperbook-server/playground-package.lisp`, `hyperbook-explorer/catalog.lisp`, `hyperdoc-explorer/tools.lisp` | - Guarantee a non-`NIL` playground package. - Document package-sensitive reader failures near Playground docs. - Keep package resolution in one override layer. | Most current Playground reader failures are package-boundary errors, not evaluator bugs. | Evaluate `(+ 1 2)` in Catalog Playground and confirm no `*package* = NIL` failures. | Package fixes can mask deeper export/API issues if they are used as a blanket workaround. |
| Chapters 30-31: HTML generation DSL | `hyperdoc-inspector/actions.html`, `hyperdoc-inspector/views.html`, `hyperdoc/*.html` | - Keep HyperDoc pages as simple HTML or markdown with minimal logic. - Prefer reusable explanation pages over long inline docs. - Link feature pages from one obvious index page. | Documentation is already part of the product surface, so it should be easy to inspect and easy to patch. | Add one new inspector doc page and confirm it is reachable from the running HyperDoc UI. | Too much embedded code in docs can create brittle symbolic links or package reader errors. |

## Phase 1: Make it work

- `hyperbook-server/playground-debug.lisp`: add a restart-inspired debug report with `Retry` and `Abort` actions.
  Done when a Playground `Debug` on `(/ 1 0)` opens a report with visible recovery actions.
- `hyperbook-server/playground-eval.lisp`: wire the Debug path to build that recovery report from the captured source and current pane object.
  Done when `Debug` re-opens a fresh report on repeated failure and returns a normal value on success.
- `hyperdoc-inspector/playground-restarts.html`: document the recovery flow in the inspector docs.
  Done when the page is reachable from the HyperDoc inspector docs and names the relevant buttons and files.
- `notes/pcl-to-hyperdoc.md`: keep the chapter-to-refactor matrix and roadmap in the repo.
  Done when the note names concrete files, acceptance criteria, and risks.

## Phase 2: Make it right

- `hyperbook-server/playground-debug.lisp` + HVS boundary: replace local shims around `hvs::eval-error` with exported HVS accessors.
  Done when no `hvs::` symbol appears in HyperBook-side Playground code.
- `hyperbook-server/web-debugger.lisp`: unify restart display formatting between full debugger sessions and lightweight Playground reports.
  Done when both views describe recovery choices with the same labels and structure.
- `hyperbook-server/playground-eval.lisp`: factor repeated source-selection/eval wiring into one helper layer.
  Done when `Evaluate`, `Evaluate and Inspect`, `Debug`, and `Step` share one error/result protocol.
- `hyperdoc-inspector/views.html`: document the distinction between report-level recovery and full paused-thread debugger sessions.
  Done when the docs state that Playground retry is explicit re-evaluation, not a live dynamic restart.

## Phase 3: Make it fast / scalable

- `hyperbook-server/playground-stepper.lisp`: cache parsed top-level forms per source string to avoid re-reading large selections.
  Done when repeated stepping over the same source does not re-read forms on every reset.
- `hyperdoc-explorer/html-pages.lisp` and `markdown-pages.lisp`: cache parsed page content and extracted links where safe.
  Done when reopening the same documentation page avoids repeated parse work.
- `hyperbook-fedwiki/plugins.lisp` and `pages.lisp`: cache fetch-derived metadata with explicit invalidation points.
  Done when repeated inspector views stop refetching the same remote structures in a single session.
- `hyperbook-server/server.lisp`: add dev-only diagnostics for expensive page/eval paths.
  Done when a developer can see where repeat work is happening without attaching a profiler first.

## Manual Test Script

1. Start HyperDoc in development mode.
   - `./dev.sh`
2. Open the browser at `/boot.html` and inspect any object with a Playground tab.
3. Select exactly `(/ 1 0)` and click `Debug`.
   - Expected: a `Debug` pane opens with `Retry` and `Abort` actions, plus condition/source/backtrace.
4. Click `Abort`.
   - Expected: the report stays visible and shows that recovery was aborted.
5. Go back to the Playground, replace the selection with `42`, and click `Debug`.
   - Expected: the result `42` is inspected instead of a debug report.
6. Alt-click the `Retry` button in the debug report.
   - Expected: the thunk is inspectable, showing how recovery is wired in HyperBook terms.
