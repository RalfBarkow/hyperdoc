# HyperDoc library and optional workflow intake

The refactor started on `dreyeck.ch` at `401953522ec503cf78764bddc5534f7a9f16fd22`, initially clean. The interrupted state was retained: 17 modified files, the structurally migrated HyperSpec file removed from its former path, and two new dreyeck source files; nothing staged. Early page-form verification exposed reader representation/package differences. These were repaired and the intended structures read back before further work. No partial failed edit was accepted as proof.

## Verified authority and decision

Konrad Hinsen's locally available `8a1149197fabcb1ab5622316f09c5a60c2d3f1f8`, subject `Allow hyperdoc subclasses to specialized load-page`, was the tip of both upstream/khinsen remote main refs and the read-only upstream checkout. No fetch or worktree transition was performed. This repository contains the library source; there is no second vendored HyperDoc. Upstream source was compared structurally and its page protocol adopted through guarded structural edits, not a Git merge. Consequently source adoption does not assert Git ancestry or patch equivalence.

`PAGE-CLASS (hyperdoc filetype)` selects the concrete page class. `LOAD-PAGE (page)` loads it. Both are public. The upstream default renderer uses COMMON-LISP. `dreyeck/hyperdoc` wraps the existing constructor and changes the book class before deferred text loading. Its PAGE-CLASS method selects a dreyeck HTML subclass. Its LOAD-PAGE :AFTER method prepends in-memory reader-context metadata for CL-USER; explicit later IN-PACKAGE metadata still wins. Reloading replaces the DOM before adding the single default marker. The method uses the inherited HYPERDOC::PARSE-TREE slot, a narrow internal coupling covered by boundary tests; no public DOM setter exists in this baseline. It does not replace the library loading or rendering methods.

## Pre-mutation inventory and final ownership

| Delta | Classification and final owner | Required boundary / retained evidence |
| --- | --- | --- |
| PAGE-CLASS dispatch, public LOAD-PAGE/page classes, current-page/book/package exports | :UPSTREAM-NOW-PROVIDES; upstream library | Adopted upstream forms. Formatting differences from CST serialization are nonsemantic. |
| Global CL-USER default for HTML | :DREYECK-SPECIALIZATION; dreyeck/hyperdoc | Global override removed; subclass uses upstream LOAD-PAGE seam. |
| Separate and recursive ASDF code directory | :LOCAL-COMPATIBILITY-REQUIREMENT; reusable library extension | Retained three definitions described below; constructor has no equivalent public discovery hook. |
| Same-origin HyperSpec configuration, corpus checking and content view | :DREYECK-INTEGRATION; dreyeck/hyperspec | Removed from hyperdoc/inspector source and component list. Catalog and intake Inspector explicitly depend on the new system. |
| FedWiki operational initialization failures and startup race | :LOCAL-COMPATIBILITY-REQUIREMENT; reusable library fixes | Domain parsing and injectable initialization retain real errors and support deterministic tests. No dreyeck hostname/policy. |
| FedWiki context extraction/resolution | :LOCAL-COMPATIBILITY-REQUIREMENT; reusable library factoring | Pure extraction exposes existing journal ordering independently of remote resolution. |
| FedWiki image URLs, dimensions and rendering | :LOCAL-COMPATIBILITY-REQUIREMENT; reusable renderer fixes | Origin-relative resources and validated plugin metadata work for any wiki. Responsive figure rendering is general content presentation, not a site-specific rule. |
| FedWiki slug navigation | :LOCAL-COMPATIBILITY-REQUIREMENT; reusable bug fix | Preserve slug identity instead of interpreting it as a title. |
| Local ASDF test attachment | :DREYECK-INTEGRATION; dreyeck test systems | Tests moved off upstream system definitions. CLOG remains a direct dependency required by existing library source. |
| Catalog, Topicmap, Workspace, Workflow | Existing dreyeck ownership | Semantics unchanged; reading books explicitly select the page policy. |
| Intake model versus its reading registration | Optional workflow capability | Core moved by ASDF ownership, not duplicated; existing package/API preserved. |

## Exact remaining semantic library deltas

All are candidate upstream contributions, not unexplained dreyeck policy. The source-inventory test rejects any other changed top-level form in the library paths and verifies retained compatibility definitions against the pre-refactor commit.

* `hyperdoc/core.lisp`: CL-SOURCE-FILE-COMPONENTS-UNDER and MAKE-HYPERDOC's optional CODE-SUBDIRECTORY with recursive component discovery. `hyperdoc/defining.lisp`: DEFHYPERDOC forwards that option. Workflow/TALA reading books, wiki-link, and page-attached/FedWiki fixture books keep pages and Lisp components in separate modules. MAKE-HYPERDOC is an ordinary function which eagerly creates code pages; PAGE-CLASS/LOAD-PAGE only extend deferred text pages. Other public APIs do not supply a code-discovery hook. Moving this out would duplicate construction or rewrite internal page arrays and indices. Retain this small reusable extension, tested by dreyeck/hyperdoc/compatibility-tests and the actual reading/fixture tests.
* `hyperbook-fedwiki/fedwiki.lisp`: URI prefix removal preserves host ports; PROBE-FEDWIKI-PROTOCOL, INITIALIZE-FEDWIKI and MAKE-FEDWIKI expose injected operations while preserving production behavior. The startup lock prevents a fast result from being overwritten by the thread object; failure aborts dependent fetches and remains observable. Tested by wiki-link's initialization/context regression tests and the image origin/port test.
* `hyperbook-fedwiki/pages.lisp`: CONTEXT-SITE-REFERENCES and RESOLVE-CONTEXT-SITE-REFERENCES factor EXTRACT-CONTEXT. The operational resolver remains GET-FEDWIKI. Tested by wiki-link's journal/context tests.
* `hyperbook-fedwiki/story-items.lisp`: RESOLVE-STORY-ITEM-URL, STORY-ITEM-IMAGE-PRESENTATION-HINTS and the image RENDER-STORY-ITEM method. The library test covers origin URLs including ports, absolute/protocol-relative URLs, valid/invalid dimensions and responsive figure output.
* `hyperbook-fedwiki/wiki-links.lisp`: the wiki-link thunk resolves a slug as a slug; LOOKUP-SLUG-IN-PAGE-CONTEXT has an injectable plugin resolver. Tested by wiki-link and fedwiki-navigation tests.
* `hyperbook.asd`: hyperbook/fedwiki directly depends on CLOG, already named by upstream-owned pages.lisp and views.lisp. This makes a real dependency explicit instead of depending on load order.

The remaining textual differences in package declarations, generic/method forms and ASDF layout are serialization/ordering differences. The CST inventory checks structural equivalence. No other semantic difference is allowed. There is no LOAD-PAGE-only replacement for the code-directory or FedWiki behavior.

## Intake ownership and evidence

`dreyeck/workflow/upstream-intake` owns upstream-intake-package.lisp and upstream-intake.lisp. Its dependencies are dreyeck/git (which already depends on dreyeck/topicmap) and closer-mop. It does not require base workflow, HyperDoc, or authoring. Base dreyeck/workflow retains its existing ASDF/UIOP/introspection/CST-read dependencies and gains no Git edge.

The compatible `dreyeck/upstream-intake` system depends on that optional core and dreyeck/hyperdoc; it owns the reading registration and DEFEXAMPLEs. There is exactly one model implementation and the package remains dreyeck/upstream-intake. Inspector integration remains separately owned. Catalog membership and book ID remain unchanged.

HYPERDOC-PAGE-LOADING-BEFORE returns a copy of the original observed summary at 4019535: available object, no ancestry, merge base `44ed77e9b1d8c4707c86479826e9f0df5cd88684`, LOAD-PAGE internal, consequences POTENTIAL, no integration decision implied. MAKE-HYPERDOC-PAGE-LOADING-INTAKE produces a new current observation. The comparison DEFEXAMPLE exposes both. After source adoption LOAD-PAGE is external; Git still reports AVAILABLE-NOT-INTEGRATED until a separately authorized ancestry-changing integration occurs. Boundary tests, not that label, establish the local protocol behavior.

Observation/comparison produce evidence. Decisions and application remain separate. Observation is never REGISTER-CHANGE, PERSIST-IN, candidate loading, installation or authoring authorization. Remote deployment remains operator-observed and is not probed by examples or tests.

## Authoring and reconstruction

Lisp/ASDF mutations use html-inspector-views structural authoring commit `38afb02d79838d4098589c2e203ba39799a44853` in the isolated pinned authoring environment. Each targeted edit is reparsed and compared with its intended form and unchanged surrounding forms. The ordinary runtime pin remains `386df8937a21457b3d91e1b61e070f836550ff71`; no Nix pin changed. The editor checkout is not a runtime requirement.

Run `sh scripts/check-upstream-boundary.sh` for the fresh ordinary and TALA matrices. Source-comparison tests require the locally retained upstream object and pre-refactor history; they never fetch it. Runtime reconstruction and Catalog startup do not load candidate source or structural authoring. The boundary test must start before any dreyeck page/HyperSpec policy is loaded.

## Deliberately open

Unowned changes still need deliberate source ownership/new top-level insertion. RECORDED-CHANGE remains image-local; transport to another authoring process is not added. No live change-log Workspace/Topicmap projection is added. Future upstream intake still requires an explicit, separately authorized integration operation. These are distinct future work, not hidden steps of intake.
