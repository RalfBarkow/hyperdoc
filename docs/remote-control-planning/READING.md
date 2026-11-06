# Assignment 1b: a readable remote-control planning HyperBook

Base: `b886ec3dfa8c2d3b725b1873e2a641bcfd2d669d`, branch
`codex/zettelkasten-remote-control-shop3`, PR #27. The original experiment report
is historical evidence; this note records the reading extension of 6 November 2026.

## Reader's path

The existing book id, title and main-page identity are preserved. Its six text
pages form one argument, using the existing `page` references for forward,
backward and entry links:

1. **Planning Remote Control for the Zettelkasten App with SHOP3**: the MacBook
   runs the application; Android should control it. A network connection alone
   does not settle responsibility. Introduces the two possible approaches before
   asking the reader to inspect code or data.
2. **Model Authority and the Control Surface**: distinguishes a request from its
   execution, explains the local model boundary, and distinguishes existing
   core/repository/ZKN3 adapter evidence from an assumed Application API.
3. **How SHOP3 Reads the Architecture Task**: explains task, method, operator
   and state through the single architecture task. Explains why enumeration is
   useful without attributing architectural invention to SHOP3.
4. **Case C - Two Alternative Plan Trees**: follows Agent and Direct as prose
   explanations, then opens the actual plan, tree and final state of each route.
   A plan is a primitive sequence; a tree records its method decomposition.
5. **Cases D and E - When Planning Refuses**: authorization and Application API
   are shared requirements; a different transport cannot replace either one.
   Includes A/B as positive controls.
6. **Evidence and Open Acceptance**: separates executed model tests, reported
   local Inspector evidence, hypothetical facts, real execution and human review.
   The simulated verification predicate is explicitly bounded.

The central comprehension question can be asked before following an object
link: can the reader explain that access paths differ while model authority
stays local, and why taking away either common prerequisite defeats both?
The prose now supplies that explanation. No human comprehension study was run;
this is a reader-facing design hypothesis, not an observed improvement in speed
or understanding. **Verdict C is unchanged.**

## Reuse and object authority

The TALA reading supplies the pattern: explain a boundary, make a prediction,
then provide an executable route to the object that can challenge it. The CCNx
HyperBook supplies the book-local `html-page-assets` / URL-prefix pattern,
text measure, leading, code/table handling and visible reference treatment.
Its typography note's own evidence distinctions are preserved: these changes
are design hypotheses, not claims derived from unread typography literature.

No new UI, navigation model, plan representation or planning authority is added.
`reading-case` retains one actual experiment observation per case on first use;
`reading-result` returns its existing `hyperdoc-htn-plan-result`.
`reading-alternative` finds a Case C route by the computed first operator, then
returns the actual plan, tree or state at that same index. It never assumes
planner ordering means preference. All 22 page expression targets were evaluated
in tests; component identity is checked with EQ. Reloading the optional reading
resets its observation cache. These are image-local observations, not persisted
or human-approved evidence. HyperDoc evaluates expression references while
materializing a page; no link invokes an executor.

CSS lives only below `.remote-control-reading`, is supplied only for this book
by its EQL-specialized `html-page-assets-of` method, and inherits the next
method's assets. Inheritance is resolved when requested rather than reading an
unbound explorer variable during core-only load. With the Explorer present,
this preserves the existing HyperDoc/HyperBook asset/tag-dispatch chain. The
core-only tests check the same contract without inventing an Inspector stub.

Content remains the existing priority-1 view. No view override was added. A
source-contract test checks that fact; the actual active view in a local Catalog
still needs the browser acceptance below.

## Executed checks and measured observations

- Four Python structure checks passed: exactly six balanced pages, a connected
  native reading path and valid page targets, scoped CSS, computed Case C
  component links, and no view overriding Content.
- `asdf:test-system "dreyeck/work/remote-control-planning/reading/tests"` passed:
  six pages, 22 evaluated object links, shared plan/tree/state identities,
  no-plan D/E, `:plan-only`, Catalog registration and book-local asset isolation.
- Unchanged A–E tests passed again: **1 / 1 / 2 / 0 / 0** plans, with matching
  trees and final states. Unchanged documentation-planning assertions passed
  in the component runner. No tests were skipped in these runs.
- The full old ASDF regression was attempted again and failed before executing
  its assertions: missing `HTML-INSPECTOR-VIEWS`, required by
  `hyperbook/explorer`. That is not a passing full regression.

Real Chromium **155.0.8059.79**, Linux, headless, measured the actual six source
HTML files with this CSS in a **static geometry fixture**. It requested a 16px
Arial/sans-serif baseline; actual macOS fonts were not checked. The fixture has
Inspector-like column wrappers, adversarial table `white-space: nowrap`, and
stand-in reference markup for CSS measurement. It does not load the Inspector,
evaluate Lisp, execute its reference callbacks or prove live Content ordering.
No claim of full Inspector browser acceptance is made.

| Measured property | Wide fixture | Narrow fixture |
| --- | --- | --- |
| Column client/scroll width, every page | 700 / 700 px | 360 / 360 px |
| Text measure | at most 38 em | at most 21 em |
| Requested line-height / body size | 1.6 | 1.6 |
| H1 / H2 | 26.4 / 21.6 px | 26.4 / 21.6 px |
| Comparison-table width, pages 2 and 6 | 676 px | 336 px |
| Escaping tables | 0 | 0 |

All **85 browser assertions passed** across twelve page/width pairs. With only
this book's CSS omitted, **46 of the same 85 assertions failed** (the deliberate
counterproof exits 1). This shows the checks detect measure, leading, hierarchy,
overflow and reference-treatment regressions; it is not a historical screenshot
comparison. Full measurements: [reading-metrics.json](reading-metrics.json) and
[reading-counterproof.json](reading-counterproof.json).

Visual inspection of the narrow Case C screenshot showed both decompositions,
wrapping headings and object links without a clipped right edge. The wide model
boundary page showed the text measure and a three-column comparison. An initially
broken first-column word in that table prompted a six-em first-column minimum;
the final browser rerun still passed at both widths. Screenshots from this Cloud
run are at `/workspace/tooling/remote-control-reading-browser/` (not repository
artifacts). There is no claim that the substituted reference spans are real
clickable Inspector objects.

## Reproduction

In the prepared local development environment:

```sh
python3 dreyeck/remote-control-planning/browser-check/structure.py
CHROMIUM=/path/to/chromium node dreyeck/remote-control-planning/browser-check/check.mjs --fixture /tmp/remote-reading
# Deliberate counterproof: expected exit 1
CHROMIUM=/path/to/chromium node dreyeck/remote-control-planning/browser-check/check.mjs --fixture /tmp/remote-reading-no-css --without-css
```

Playwright or playwright-core must be resolvable from the working directory.
The fixture mode opens local HTML only and cannot validate object navigation.

Cloud Lisp command actually executed (its runner is local setup, not project source):

```sh
XDG_CACHE_HOME=/workspace/tooling/lisp-cache \
SBCL_HOME=/workspace/tooling/lisp/usr/lib/sbcl \
/workspace/tooling/lisp/usr/bin/sbcl --no-userinit --non-interactive \
  --load /workspace/tooling/remote-control-reading-tests.lisp
```

That runner loads the repository ASDF files and real SHOP3, runs the unchanged
A–E test system, loads the optional reading and runs the new reading tests.
Output: `/workspace/tooling/remote-control-reading-tests.log`.
The unchanged documentation assertions were run through
`/workspace/tooling/shop3-component-tests.lisp`, output
`/workspace/tooling/remote-control-reading-components.log`.
Full old ASDF blocker: `/workspace/tooling/remote-control-reading-full-regression.log`.
No dependency, lockfile or network-policy change was made for this slice.

## Local Catalog acceptance, still required

The user reports the baseline experiment is locally reachable in CLOG, with C
showing two plans and `:PLAN-ONLY`. This is recorded as user-reported evidence,
not silently generalized to the new pages or the full regression. The Cloud
still lacks the Inspector dependency closure; its pinned Codeberg source was
previously refused with HTTP 403. No bypass was attempted.

In the intended prepared **development** SLY image, after updating the checkout,
refresh the registered ASDF definition if needed, then load only this reading:

```lisp
(asdf:load-asd (asdf:system-relative-pathname "dreyeck" "dreyeck.asd"))
(asdf:load-system "dreyeck/work/remote-control-planning/reading" :force t)
(asdf:test-system "dreyeck/work/remote-control-planning/reading/tests")
```

The human evaluator performs these forms; no running image was modified by
Codex. No server restart or production change is needed. The optional reading
appears in the existing local Catalog. From there the reader uses only links:
open the book's main page, follow **Weiter** through all six pages, use **Zurück**
or **Zum Einstieg**, then follow the route-specific plan/tree/state links in C
and the D/E links. A/B controls and source/test references remain reachable.
At every page opening, Content should be active first. Compare wide and narrow
Inspector columns; inspect table containment, Lisp identifiers, long headings,
reference contrast and separation of assumptions/evidence/open questions.

For an automated run against that already prepared local Catalog:

```sh
CHROMIUM=/path/to/chromium node dreyeck/remote-control-planning/browser-check/check.mjs --catalog http://127.0.0.1:PORT /tmp/remote-reading-catalog
```

Replace PORT with its actual port. This mode uses the existing Inspector DOM
contract from the CCNx checks. It checks Content on entry, follows the six-page
path and expression references, and measures each page at wide/narrow viewports.
**This mode was supplied but not executed in the Cloud.** It requires the live
local Catalog and full Explorer assets, not a static server. Return its actual
metrics/screenshots or condition/browser failure before claiming acceptance.
No automated pixel test answers the human comprehension question on its own.

## Scope and deltas

- HyperDoc: six connected pages, preserving the original entry identity.
- Lisp: reading-only observation accessors, book-local asset specialization and
  an optional reading-test system. SHOP3 domain and A–E test source unchanged.
- CSS: one scoped reading sheet; no global Inspector changes.
- FedWiki, WBS, AC-06, permissions, Java and productive services: no changes.
- Replay: actual object targets and model tests pass; static-browser typography
  passes; full local Inspector reader journey and human comprehension are open.
