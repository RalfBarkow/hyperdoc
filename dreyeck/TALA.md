# Experimental TALA layout slice

TALA derives a static layout rendering from an existing Topicmap Projection.
It does not change Topicmap, Projection, Workspace, or navigation semantics.
The native renderer remains the default. The initial demonstrator uses the
existing current Git repository/HEAD projection, not an independently built graph.

## Reconstruct and inspect

From the repository root:

```sh
nix develop .#tala
sbcl --no-userinit --non-interactive --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/topicmap/tala/reading/tests")'
```

For an interactive HyperDoc image in that shell:

```lisp
(asdf:load-system "dreyeck/topicmap/tala/reading")
(hyperbook:find-page
 (hyperbook:find-hyperbook "dreyeck/topicmap/tala/reading")
 "Reading TALA as a Layout Layer" :signal-error? t)
```

Inspect the returned page's Content view, or open the registered book in the
HyperDoc Catalog. Its twelve source transclusions use ordinary DEFEXAMPLE play
buttons. They expose Workspace, Projection, Topic IDs, Association endpoints,
D2 input, reversible ID maps, dependency availability, real TALA rendering,
SVG geometry evidence, invariants, native/TALA comparison, and the existing
ASDF source/system Workspace. Each example constructs its own observation.
Within one comparison, both views retain the same Projection.

## Implementation boundary

- `dreyeck/topicmap/tala`: `projection-tala-input`, `tala-id`,
  `topic-id-from-tala-id`, `run-tala`, `tala-dependency-status`,
  `validate-tala-svg`, `tala-rendering-evidence`.
- `dreyeck/inspector/topicmap/tala`: `compare-workspace-layouts`,
  `repository-layout-comparison`, `comparison-invariants`, and Inspector views.
- `dreyeck/topicmap/tala/reading`: persisted DEFEXAMPLEs and HyperDoc registration.
- `dreyeck/topicmap/tests`: existing tests plus dependency-free adapter tests.
- `dreyeck/topicmap/tala/tests`: real CLI integration and native action tests.
- `dreyeck/topicmap/tala/reading/tests`: integration plus page reconstruction,
  source transclusions, actual play-button thunks and all example results.

The adapter sorts copies by stable IDs. Topic IDs use reversible fixed-width
hex characters; labels never establish identity. Association maps retain their
original IDs and directed endpoints, including deterministic D2 parallel-edge
indices. Input omits manual positions, point and history.

The subprocess receives D2 source through stdin and returns SVG through stdout.
The renderer requires D2 v0.9.0 with bundled TALA, seed 44 by default, and checks
exact SVG group identity coverage before exposing the result. It rejects
unsupported versions, missing executables, malformed coverage, hidden Topics,
and structural-containment presentation. There is no silent native fallback.

The comparison checks original objects and persisted semantic state before and
after layout. Native actions are the existing Inspector thunks: tests invoke
them, check original returned Topics, point/history, and unchanged layout input.
The cached comparison shows point at observation time; follow its Workspace
reference to inspect live navigation state. Navigation never recomputes TALA.

## Reproducibility and limitations

`nix/d2-tala.nix` pins official D2 v0.9.0 release archives by SHA-256 for
Darwin/Linux on x86_64/aarch64. The optional `tala` shell adds that executable;
the default shell and renderer remain unchanged. Validation was performed on
x86_64-darwin. Other platform packages have pinned hashes but were not executed.

Upstream source: D2 commit
`d5a51743b6d5c00f1ec6f8340003f5d5a6ba4eda`. The reading page links its README,
architecture, adapter, result validation, movement, cost, and routing sources.

D2's CLI returns SVG rather than normalized numeric geometry. This is explicitly
a static rendering proof. The TALA image is noninteractive; native signs retain
navigation. Evidence exposes matched SVG rectangle attributes, viewboxes and
route paths without inventing a geometry parser. A future machine-geometry
exporter belongs between the layout result and native sign rendering, keyed by
the existing IDs. This slice does not claim pinned positions, containment,
incremental stability, or identical layouts across platforms/engine versions.

## Structural authoring audit

The existing passing adapter/integration baseline had earlier textual Lisp/ASDF
edits. That deviation is recorded; the definitions were structurally read back
and retained as instructed.

All subsequent Lisp/ASDF edits for the reading companion used the existing
html-inspector-views structural writer from committed source
`4b0607d93b193e21bd2ca5dc0d7e47c062ac8112` in an isolated development process.
MATERIALIZE-LISP-SOURCE created new files; structural insertion/replacement
selected parsed top-level forms. Writer stale-source and reader-recovery guards
remained enabled. Edits were reparsed and intended expressions and unrelated
top-level forms compared; uninterned ASDF symbols are compared by name and package.

That checkout is an authoring tool only. HyperDoc's html-inspector-views runtime
pin remains `386df8937a21457b3d91e1b61e070f836550ff71`; neither dependency metadata
nor runtime code references the local authoring checkout. Fresh tests load the
normal Nix-store runtime without loading the editor. No image-only definitions
are needed to reconstruct the feature or the reading page.

Work was isolated on `feature/topicmap-tala-layout`, based exactly on
`0aae85da29d085e0c41d53243fcff97c460b2c39`, in
`/Users/rgb/workspace/hyperdoc-topicmap-tala`. The three pre-existing HyperDoc
worktrees and the separate html-inspector-views checkout were left untouched.
