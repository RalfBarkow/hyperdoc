# Vendored html-inspector-views Override Files

This directory contains the repo-owned canonical source snapshots for the local
`html-inspector-views` carry we maintain.

Why it exists:
- former `nix/patches` graphviz-unification semantics were moved out of diff
  patch files and out of inline `flake.nix` string rewrites
- `flake.nix` now applies these files deterministically via
  `nix/scripts/apply-html-inspector-views-overrides.py`

Scope:
- `package.lisp`
- `view-support.lisp`
- `assets/html-inspector-views/js/process-graphviz-elements.js`
- `assets/html-inspector-views/js/graphviz.js`
- `assets/html-inspector-views/css/graphviz.css`

Guardrails:
- the apply script enforces exact upstream snapshot hashes for rewritten files
- added files are created only from the vendored snapshot
- builds fail loudly if upstream source layout/content changes unexpectedly
