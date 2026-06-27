# Codex Belongs to Dreyeck

HyperDoc provides the reusable document, topic, inspector, explorer, page, and
server substrate. Dreyeck owns situated collaboration state: Codex, Recent
Changes, Next, handover routes, and Kioskbeerli context-window/dashboard
surfaces.

This refactor is the canonical example for the reusable pattern
`Ownership Extraction with Compatibility Shell`, also named locally as the
`Substrate / Situated-Surface Split`.

This source refactor moves the canonical Codex collaboration implementation out
of HyperDoc core and into Dreyeck:

- `dreyeck/codex.lisp` owns the Codex home, context window, recent changes,
  next routes, optional-provider dispatcher, and supporting model objects.
- `dreyeck/codex-examples.lisp` owns deterministic Codex examples.
- `dreyeck-explorer/codex.lisp` owns inspector/explorer views for Dreyeck Codex
  objects.

The canonical ASDF systems are now:

- `dreyeck/codex`
- `dreyeck/codex/examples`
- `dreyeck/codex/explorer`

The temporary HyperDoc compatibility ASDF coordinates remain:

- `hyperdoc/codex`
- `hyperdoc/codex/examples`
- `hyperdoc/codex/explorer`

These HyperDoc coordinates load Dreyeck and explicit compatibility wrappers.
They are aliases for existing pages, inspector forms, and collaboration snippets
that still load old HyperDoc Codex systems.

The following old internal HyperDoc function entry points remain temporarily:

- `hyperdoc::codex`
- `hyperdoc::codex-context-window`
- `hyperdoc::codex-recent-changes`
- `hyperdoc::codex-next`

They delegate to:

- `dreyeck/codex:codex`
- `dreyeck/codex:codex-context-window`
- `dreyeck/codex:codex-recent-changes`
- `dreyeck/codex:codex-next`

The compatibility layer is intentionally temporary. The next cleanup step is to
migrate authored pages, inspector forms, examples, and handover snippets to the
`dreyeck/codex:*` functions and `dreyeck/codex/*` ASDF systems. After that
migration, remove `hyperdoc/codex-compat.lisp`,
`hyperdoc/codex-examples-compat.lisp`, and the `hyperdoc/codex*` ASDF
compatibility systems.
