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
git clone --no-hardlinks <topic-maps repository> topic-maps-hyperdoc-5a4a668 && git -C topic-maps-hyperdoc-5a4a668 checkout --detach 5a4a668
TOPIC_MAPS_ROOT=$PWD/../topic-maps-hyperdoc-5a4a668 HYPERDOC_FEDWIKI_SITE_ROOT=$HOME/.wiki/localhost/ \
  nix develop .#tala -c sbcl --noinform --no-userinit --load scripts/serve-ctm-page-authoring.lisp
```

Then open `http://127.0.0.1:18773/view/ctm-and-tmdm-in-hyperdoc` (port: `HYPERDOC_CTM_PORT`).

### Review copy: the DITA topics on Topicmap inspection

To read the four DITA topics (the Work item `topicmap-interaction-documentation`) without a wiki directory, ask for the review copy. The script then
makes a fresh temporary directory (its name contains `TEST-COPY`, and it holds `THIS-IS-A-TEST-COPY.txt`) with copies of the two retained pages
`ctm-and-tmdm-in-hyperdoc` and `topicmap-inspection-dita`, serves that as the site root, and removes it when the Catalog stops. The repository's files stay
the authority; no wiki directory is read or written. The default port is 18775, so it does not meet a Catalog on 18773.

```sh
TOPIC_MAPS_ROOT=$PWD/../topic-maps-hyperdoc HYPERDOC_CTM_REVIEW_COPY=1 \
  nix develop .#tala -c sbcl --noinform --no-userinit --load scripts/serve-ctm-page-authoring.lisp
```

The start prints `REVIEW-MODE`, `SITE-ROOT` and `HYPERDOC-COMMIT`. Open `http://127.0.0.1:18775/`, then *Working on HyperDoc* → *Text pages* → *Work Breakdown* →
*Document the Topicmap Interaction in DITA* → a topic; or `http://127.0.0.1:18775/view/topicmap-inspection-dita` for the page. `HYPERDOC_CTM_REVIEW_COPY=1` together with
`HYPERDOC_FEDWIKI_SITE_ROOT` is refused. `scripts/test-ctm-review-copy.mjs` starts the script in both modes and walks the path to the objects.

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
2026-10-19 with commit `5a4a668` (branch `claude/ctm-reader-normalization-scaling`: `963f2a0`, Slice 17B, plus the indexed search for
equal Topics and Associations, which reads the HyperDoc project CTM in seconds instead of not within 300 s): the reading, the TMDM
navigation, the page documentation, the CTM views of the Item edit and the project CTM (`dreyeck/work/project`) pass. `963f2a0`
was tested on 2026-10-18 and gives the same results on these inputs, but not on a document of the project CTM's size. The
topic-maps repository has no remote: `5a4a668` is kept as a verified Git bundle, and how to recover it is in
`dreyeck/work/project/topic-maps-5a4a668-recovery.txt`. A
working repository that is being developed is not a suitable `TOPIC_MAPS_ROOT`: it is refused while it has local changes, and a
half-edited tree does not load. Slice 12A (`788899ae`) stays the historical test state; after switching between checkouts, force a
recompile (`(asdf:load-system "dreyeck/work/tmdm-reading" :force t)`), because the compiled HyperDoc code depends on the structures of topic-maps.

The completion, preview and proposal have a `CTM` view (system `dreyeck/item-edit-ctm`, part of `dreyeck/ctm-page-authoring/local`): the Item edit written as CTM, read back with the
topic-maps reader, and navigable as TMDM objects, with the Lisp objects each Topic stands for. See the Work page *Item Edit Path in HyperDoc*.

### Click path to the `CTM` tab

Start page → *Working on HyperDoc* → *Text pages* → *Work Breakdown* → *Author the CTM Plan Page through HyperDoc* → *E3* → tab `Edit` → button *Prepare edit proposal* →
change the proposed text (an unchanged text is answered as "no change") → button *Preview* → tab `Execution` → button *Complete the Action with a date*. The new pane is the
`item-edit-completion` (its title shows the class and the view name `Completed Action`); its tabs are `Completed Action`, `CTM`, `Topicmap`, `Slots`, `Print`, `Operations`, `Playground`.
Click the tab `CTM`; the link *the TMDM Topic Map* opens the Topic Map. The link *this one* inside `Completed Action` opens the completed Action, a different object without a `CTM` view.
A Catalog started before `dreyeck/item-edit-ctm` existed (or without `dreyeck/ctm-page-authoring/local`) shows no `CTM` tab: restart it. `scripts/test-ctm-page-authoring-documentation.mjs`
follows exactly this path.

The tab `Topicmap` right after `CTM` draws the Topic Map at once: the seven objects as Topics, the eight Associations as nodes with one edge for each Role (named by the
Role type), each marked observed or derived. Click a sign to move the Point; its panel gives the reason and the Lisp objects. *Lay out with TALA* runs D2 once and gives an interactive
TALA view of the same projection.
