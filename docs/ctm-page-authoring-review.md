# Reading the Item edit path locally and on a server

Work Item `ctm-plan-page-authoring`: Wiki page → Story Item → Edit → Proposal → Preview → Action → Inspector.
Nothing in this path writes the page file. The Execution only acts on a signed request that trusted code attaches.

## Systems

| System | Gives | Needs |
|---|---|---|
| `dreyeck/ctm-page-authoring` | Edit proposal, Preview, Action context, their Inspector views | only this repository; no writer |
| `dreyeck/ctm-page-authoring/local` | the above, the Execution (loads the writer), the CTM example read with the topic-maps reader, the TMDM model navigation | a clean topic-maps checkout (see below) |

The packaged `hyperdoc-catalog` takes a system by `HYPERDOC_CATALOG_SYSTEM`; it can name only systems of its packaged
registry. topic-maps is not in that registry (open question E1), so on a server only `dreyeck/ctm-page-authoring` can be named
until topic-maps is packaged.

## Local review Catalog

```sh
git clone --no-hardlinks <topic-maps repository> topic-maps-hyperdoc && git -C topic-maps-hyperdoc checkout --detach 963f2a0
TOPIC_MAPS_ROOT=$PWD/../topic-maps-hyperdoc HYPERDOC_FEDWIKI_SITE_ROOT=$HOME/.wiki/localhost/ \
  nix develop .#tala -c sbcl --noinform --no-userinit --load scripts/serve-ctm-page-authoring.lisp
```

Then open `http://127.0.0.1:18773/view/ctm-and-tmdm-in-hyperdoc` (port: `HYPERDOC_CTM_PORT`).

## Tests

`dreyeck/work/tmdm-reading/tests` and `dreyeck/topic-maps-reading` need the topic-maps checkout in the ASDF registry.
`dreyeck/catalog` and `dreyeck/work/reading/tests` need a Git checkout with a local branch `dreyeck.ch`.
`scripts/test-tmdm-model-navigation.mjs` takes an SBCL binary (it runs it in `sandbox-exec`) and `TOPIC_MAPS_ROOT`.
`CATALOG_SYSTEM` makes `test-item-edit-execution.mjs` serve another system, for example the local one (with `TOPIC_MAPS_ROOT`).
`dreyeck/ctm-page-authoring/tests` follows every link of the pages that document the path (the Work page *Item Edit Path in HyperDoc*,
the carrier page and the WBS Dictionary) and needs the topic-maps checkout; `scripts/test-ctm-page-authoring-documentation.mjs` reads them in a served local Catalog.

## Which Catalog shows `Edit`

The `Edit` tab of a Story Item comes from `dreyeck/fedwiki-item-edit-preview`; a Catalog that does not load that system shows only
the tab `Story item`, for every way of opening the Item (the E3 link of the carrier page as well as Page source → E3). The review
Catalog of `scripts/serve-tmdm-model-review.lisp` loads the TMDM readings and not the preview, so it shows no `Edit`; use
`scripts/serve-ctm-page-authoring.lisp`. `scripts/test-ctm-page-authoring-documentation.mjs` opens `Edit → Prepare edit proposal → Preview`
by both ways, in the local Catalog and (`CATALOG_SYSTEM=dreyeck/ctm-page-authoring`) in the served-sized one, which has no writer, no execution and no topic-maps.

## Which topic-maps checkout

The TMDM reading (`dreyeck/work/tmdm-reading`) accepts a clean checkout of topic-maps that is the commit
`788899aea1a20b9cd8237c6106e6613e180d7362` (Slice 12A) or a descendant of it, and for a descendant it checks that the inputs of the
reading (the CTM source, its CXTM baseline, the stored Slice 12A evidence and the interpretation text) are the same blobs as at the pin.
What the newer reader then does with those inputs is what the run observes: it must still reproduce the baseline. Tested on
2026-10-18 with commit `963f2a0` (branch `codex/ctm-slice-17b`): the reading, the TMDM navigation and the page documentation pass. A
working repository that is being developed is not a suitable `TOPIC_MAPS_ROOT`: it is refused while it has local changes, and a
half-edited tree does not load. Slice 12A (`788899ae`) stays the historical test state; after switching between checkouts, force a
recompile (`(asdf:load-system "dreyeck/work/tmdm-reading" :force t)`), because the compiled HyperDoc code depends on the structures of topic-maps.
