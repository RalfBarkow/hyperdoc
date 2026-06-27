# Ownership Extraction with Compatibility Shell

This page preserves a completed Codex refactor as a reusable pattern for future
boundary repairs.

## Inspectable objects

- <a hyperbook="topics" page="Ownership Extraction with Compatibility Shell"><tt>Ownership Extraction with Compatibility Shell</tt></a>

## Pattern

Title:

```text
Ownership Extraction with Compatibility Shell
```

Alias:

```text
Substrate / Situated-Surface Split
```

Core rule:

```text
When code inside a reusable substrate starts hard-coding one project's
situated collaboration state, extract that code into the owning project
and leave a temporary compatibility shell behind.
```

Canonical example:

```text
afa829b9 refactor(codex): move collaboration surface into dreyeck
```

## Problem

A reusable substrate contains situated project-specific collaboration state.

In the canonical example, Codex lived under HyperDoc, but described
Dreyeck/Kioskbeerli review, handover, recent-change, and next-route state. That
made a reusable documentation and inspection substrate carry one project's
current collaboration surface.

## Diagnosis

The smell is:

```text
A supposedly reusable layer knows too much about a specific project situation.
```

Concrete smell from this refactor:

```text
HyperDoc knew about Kioskbeerli dashboard status, stations, build evidence,
and blockers.
```

Therefore:

```text
Codex was not HyperDoc substrate.
Codex belonged to Dreyeck.
```

## Operation

Reusable refactor steps:

1. Move canonical implementation from the generic layer to the owning layer.
2. Introduce new canonical ASDF systems in the owning layer.
3. Export a new canonical package API from the owning layer.
4. Preserve old systems and functions as explicit temporary compatibility wrappers.
5. Convert hard optional provider calls into guarded provider dispatch.
6. Record a durable topic/handover artifact explaining the move.

## Validation

Invariant checks:

- New coordinates load.
- Old compatibility coordinates still load.
- Canonical entry points work.
- Compatibility entry points work.
- Missing optional providers return inspectable data, not debugger entries.
- The commit is focused.
- The durable note records ownership, compatibility, and cleanup plan.

## Concrete example

Before:

```text
hyperdoc/codex.lisp
hyperdoc/codex-examples.lisp
hyperdoc-explorer/codex.lisp
```

After:

```text
dreyeck/codex.lisp
dreyeck/codex-examples.lisp
dreyeck-explorer/codex.lisp
```

Canonical systems:

```text
dreyeck/codex
dreyeck/codex/examples
dreyeck/codex/explorer
```

Compatibility systems:

```text
hyperdoc/codex
hyperdoc/codex/examples
hyperdoc/codex/explorer
```

## Optional-provider rule

Missing situated providers must become inspectable data, not
`UNDEFINED-FUNCTION` conditions.

Example:

```lisp
(codex-context-provider-result 'kioskbeerli-dashboard-status)
(codex-context-provider-result 'kioskbeerli-dashboard-stations)
(codex-context-provider-result 'kioskbeerli-build-evidence-status)
(codex-context-provider-result 'kioskbeerli-current-blocker)
```

## Goldberg-style reader questions

Use these questions before preserving or repairing a similar boundary:

- What object is this code really about?
- Who owns that object?
- Is this code substrate, adapter, situated state, or compatibility?
- Which callers still know the old address?
- What must remain stable for readers and inspectors?
- What absence should become inspectable data instead of a debugger?
- What durable page/topic records the move?

## PDDL-style pattern card

```lisp
(:pattern ownership-extraction-with-compatibility-shell
 :also-known-as substrate/situated-surface-split
 :canonical-example "afa829b9 refactor(codex): move collaboration surface into dreyeck"
 :symptom
 ((generic-layer hard-calls situated-provider)
  (generic-layer owns project-specific context)
  (tests-or-inspectors fail-when optional-project-provider-absent))
 :diagnosis
 ((wrong-ownership-boundary)
  (missing-provider-treated-as-hard-dependency)
  (collaboration-state-confused-with-substrate))
 :operation
 ((move-canonical-implementation generic-layer owning-layer)
  (introduce-new-canonical-asdf-systems owning-layer)
  (export-new-canonical-package-api owning-layer)
  (leave-old-entry-points-as-compatibility-wrappers)
  (convert-hard-optional-calls-to-provider-dispatch)
  (record-durable-topic-artifact))
 :validation
 ((new-coordinate-loads)
  (old-coordinate-loads-through-compatibility)
  (canonical-entry-points-work)
  (compat-entry-points-work)
  (missing-optional-provider-becomes-data-not-debugger)
  (commit-is-focused)))
```

## Future-use rule for Codex

When a generic HyperDoc file hard-calls project-specific state, first test
whether the object belongs to Dreyeck, Hauptsache, Kioskbeerli, or another
owning layer. Prefer ownership extraction with compatibility shell over
runtime shims when the boundary is wrong.

## Related pages / references

- <a page="Codex Belongs to Dreyeck">Codex Belongs to Dreyeck</a>
- `afa829b9 refactor(codex): move collaboration surface into dreyeck`
