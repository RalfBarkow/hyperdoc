# metagraph-as-bipartite-graph-json-ld--fluree

Flat page-local ASDF asset for FedWiki page:

`metagraph-as-bipartite-graph-json-ld--fluree`

The asset is written by `hyperdoc/fedwiki-asdf-assets` directly into:

```text
assets/pages/metagraph-as-bipartite-graph-json-ld--fluree/
```

The ZIP is not the source of truth. The running HyperDoc image writes this
directory, loads the exact `.asd` pathname, tests the system, renders DM6 Topic
Map pages, and only then creates a deployable ZIP from the tested directory.

## Layout

```text
metagraph-as-bipartite-graph-json-ld--fluree.asd
src/
  package.lisp
  topicmaps.lisp
  projections.lisp
  install.lisp
pages/
examples/
tests/
README.md
INSTALL-STEPS.md
MANIFEST.txt
```

There is intentionally no nested
`metagraph-as-bipartite-graph-json-ld--fluree/` directory inside the page
asset directory.

## Public entry points

```lisp
(mg-conversation-story-topicmap)
(mg-conversation-story-topicmap-native)
(mg-layer-contract-topicmap)
(mg-layer-contract-topicmap-native)
(mg-planning-topicmap)
(mg-planning-topicmap-native)

(mg-topicmap-projection :conversation-story)
(mg-topicmap-projection :layer-contract)
(mg-topicmap-projection :planning-example)

(mg-write-all-rendered-topicmaps)
(mg-open-rendered-topicmap :conversation-story)
(mg-open-rendered-topicmap :layer-contract)
(mg-open-rendered-topicmap :planning-example)

(mg-ensure-inspector-views)
(mg-inspect-rendered-topicmap :conversation-story)
(mg-inspect-rendered-topicmap :layer-contract)
(mg-inspect-rendered-topicmap :planning-example)
```

## Rendered DM6 contract

Rendered pages use root-relative HyperDoc asset paths:

```html
<link rel="stylesheet" href="/assets/dm6-elm/hyperdoc-dm6-inline.css">
<section class="dm6-hyperdoc-map dm6-island"
         data-dm6-bundle="/assets/dm6-elm/app.js">
  <script type="application/json" class="dm6-stored">...</script>
</section>
<script src="/assets/dm6-elm/hyperdoc-dm6-inline.js"></script>
```

No localhost origin or server port is encoded.
