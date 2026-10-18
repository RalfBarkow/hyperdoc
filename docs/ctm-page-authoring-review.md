# Reading the Item edit path locally and on a server

Work Item `ctm-plan-page-authoring`: Wiki page → Story Item → Edit → Proposal → Preview → Action → Inspector.
Nothing in this path writes the page file. The Execution only acts on a signed request that trusted code attaches.

## Systems

| System | Gives | Needs |
|---|---|---|
| `dreyeck/ctm-page-authoring` | Edit proposal, Preview, Action context, their Inspector views | only this repository; no writer |
| `dreyeck/ctm-page-authoring/local` | the above, the Execution (loads the writer), the CTM example read with the topic-maps reader, the TMDM model navigation | the topic-maps checkout at commit `788899aea1a20b9cd8237c6106e6613e180d7362` |

The packaged `hyperdoc-catalog` takes a system by `HYPERDOC_CATALOG_SYSTEM`; it can name only systems of its packaged
registry. topic-maps is not in that registry (open question E1), so on a server only `dreyeck/ctm-page-authoring` can be named
until topic-maps is packaged.

## Local review Catalog

```sh
git clone --no-hardlinks <topic-maps checkout> topic-maps-slice-12a && git -C topic-maps-slice-12a checkout --detach 788899ae
TOPIC_MAPS_ROOT=$PWD/../topic-maps-slice-12a HYPERDOC_FEDWIKI_SITE_ROOT=$HOME/.wiki/localhost/ \
  nix develop .#tala -c sbcl --noinform --no-userinit --load scripts/serve-ctm-page-authoring.lisp
```

Then open `http://127.0.0.1:18773/view/ctm-and-tmdm-in-hyperdoc` (port: `HYPERDOC_CTM_PORT`).

## Tests

`dreyeck/work/tmdm-reading/tests` and `dreyeck/topic-maps-reading` need the topic-maps checkout in the ASDF registry.
`dreyeck/catalog` and `dreyeck/work/reading/tests` need a Git checkout with a local branch `dreyeck.ch`.
`scripts/test-tmdm-model-navigation.mjs` takes an SBCL binary (it runs it in `sandbox-exec`) and `TOPIC_MAPS_ROOT`.
`CATALOG_SYSTEM` makes `test-item-edit-execution.mjs` serve another system, for example the local one (with `TOPIC_MAPS_ROOT`).
