# Vendored CLOG Override Files

This directory contains the repo-owned canonical source snapshots for the local
CLOG carry we maintain.

Why it exists:
- former `nix/patches` semantics were moved out of diff patch files and out of
  inline `flake.nix` string rewrites
- `flake.nix` now applies these files deterministically via
  `nix/scripts/apply-clog-source-overrides.py`

Scope:
- `source/clog-element.lisp`
- `static-files/boot.html`
- `static-files/js/boot.js`

Guardrails:
- the apply script enforces exact upstream snapshot hashes before replacement
- builds fail loudly if upstream source layout/content changes unexpectedly
