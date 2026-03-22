# Semantic-first anchor audit

This is a small source-based drift audit for the current provider-based
Connect UI.

It protects these invariants:

- semantic anchor identity is defined separately from presentation fallback metadata
- fallback fields stay visibly labeled as fallback-level
- durability remains explicitly available
- provider help/copy stays anchor-first instead of drifting back to stale DOM-first wording
- inspector rendering keeps semantic identity, presentation fallback, and durability in separate sections

Run it with:

```sh
./tools/semantic-first-anchor-audit.sh
```

Or directly:

```sh
sbcl --no-userinit --script tools/semantic-first-anchor-audit.lisp
```

Scope note:

- this is a source audit for wording and rendering boundaries
- it is not a runtime association proof or a full cross-pane/fedwiki integration test

Source of truth:

- the audit logic lives in `hyperdoc/validation.lisp`
- `tools/semantic-first-anchor-audit.lisp` is a thin CLI wrapper around
  `hyperdoc:semantic-first-anchor-audit-report`
