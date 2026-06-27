# HyperDoc Core

This page defines `HyperDoc core` as an ownership boundary, not as a
filesystem shortcut.

## Inspectable objects

- <a hyperbook="topics" page="HyperDoc core"><tt>HyperDoc core</tt></a>
- <a hyperbook="topics" page="Ownership Extraction with Compatibility Shell"><tt>Ownership Extraction with Compatibility Shell</tt></a>

## Definition

HyperDoc core is Konrad Hinsen's upstream HyperDoc codebase at Codeberg,
anchored at commit `0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc`.

Repository:

```text
https://codeberg.org/khinsen/hyperdoc/
```

HyperDoc core is defined by upstream provenance and generic substrate role, not
by the local directory name `hyperdoc/`.

The physical path `hyperdoc/` is not sufficient evidence of core ownership.

## Operational meaning

HyperDoc core is the upstream-owned or upstream-generic substrate:
document/topic/page abstractions, generic rendering/navigation machinery,
generic inspector/explorer substrate where appropriate, and local patches that
could plausibly remain upstream-generic.

In the local repo, `hyperdoc/` may contain:

- upstream HyperDoc core
- local generic core patches
- compatibility shells
- misplaced project-owned extensions
- durable notes/topics

Therefore, a file living under `hyperdoc/` is not automatically `HyperDoc
core`.

## Topic storage boundary

Topic object code currently lives under `hyperdoc/topics/`.

Production topic persistence belongs to the Dreyeck/DMX SQLite database.
Markdown notes may serve as bootstrap documents, exports, handover artifacts,
or human-readable projections, but they are not the final production topic
store.

HyperDoc core may provide generic topic abstractions and rendering machinery.
Dreyeck/DMX owns the project production topic store.

## Exclusions

HyperDoc core excludes situated project state such as:

- Dreyeck collaboration state
- Codex recent-changes / next-route / handover state
- Kioskbeerli dashboard/status/station-board context
- Hauptsache build/dependency graph state
- project-specific compatibility wrappers
- local experiments not intended as upstream-generic substrate

## Classification vocabulary

```lisp
(:hyperdoc-core
 "Present in Konrad Hinsen's upstream HyperDoc at the anchored commit.")

(:hyperdoc-core-patch
 "Local generic change that could plausibly be proposed upstream and does not
  depend on Dreyeck/Kioskbeerli/Hauptsache-specific state.")

(:hyperdoc-compatibility-shell
 "Local wrapper preserving old HyperDoc coordinates after ownership moved
  elsewhere. It may live under hyperdoc/ physically, but is not core.")

(:project-owned-extension
 "Situated code owned by Dreyeck, Kioskbeerli, Hauptsache, DMX integration,
  Codex, or another project layer.")

(:topic-code-location
 "The Common Lisp implementation for topic objects currently lives under
  hyperdoc/topics/.")

(:topic-production-store
 "Durable project topics should be persisted in the Dreyeck/DMX SQLite
  production database as topics and associations.")

(:markdown-topic-note
 "A human-readable seed/export/projection of topic content, useful for review
  and handover, but not the final authoritative production store.")
```

## Boundary test

Could this belong in Konrad's upstream HyperDoc lineage without knowing
anything about Dreyeck, Kioskbeerli, Hauptsache, Codex handover state, or our
local collaboration workflow?

If yes, it may be HyperDoc core or a HyperDoc core patch.

If no, it is not core. It belongs to an owning project layer, adapter layer, or
compatibility layer.

## Codex example

Canonical refactor:

```text
afa829b9 refactor(codex): move collaboration surface into dreyeck
```

```lisp
(:object codex
 :old-location "hyperdoc/codex.lisp"
 :new-location "dreyeck/codex.lisp"
 :new-classification :project-owned-extension
 :owner :dreyeck
 :reason
 "Codex describes situated collaboration state: recent changes, next routes,
  handover context, and Kioskbeerli dashboard/status/blocker providers."
 :compatibility
 ((:hyperdoc/codex :loads :dreyeck/codex)
  (:hyperdoc/codex/examples :loads :dreyeck/codex/examples)
  (:hyperdoc/codex/explorer :loads :dreyeck/codex/explorer)
  (hyperdoc::codex dreyeck/codex:codex)
  (hyperdoc::codex-next dreyeck/codex:codex-next)))
```

## Link to refactor pattern

The HyperDoc Core definition supplies the ownership boundary.

The Ownership Extraction with Compatibility Shell pattern supplies the refactor
move when code crosses that boundary.

Local synonym:

```text
Substrate / Situated-Surface Split
```

## Practical future-use rule

Do not ask first: "Which directory is this file in?"

Ask first: "Which ownership boundary does this object cross?"

Then classify:

```text
upstream-generic substrate
  -> HyperDoc core / HyperDoc core patch

old address preserving moved behavior
  -> HyperDoc compatibility shell

situated collaboration or project state
  -> Dreyeck / Kioskbeerli / Hauptsache / owning layer
```

When Codex creates or updates durable project knowledge, prefer a path that can
be materialized into the Dreyeck/DMX SQLite production DB. Markdown notes are
acceptable as transitional handover artifacts, but should be treated as
projections or seeds unless the task explicitly says otherwise.

## Storage follow-up

There is already a Dreyeck-owned generic DMX-shaped SQLite store under
`dreyeck/dmx/sqlite`, including topic and association record functions. This
slice does not implement a broad migration from Markdown or HyperDoc topic
factories into that store because the dedicated durable-note materializer and
production DB status inspector are still separate work.

Follow-up task:

```lisp
(:task materialize-durable-notes-into-dreyeck-dmx-sqlite
 :goal
 ((durable-project-topics stored-in dreyeck-dmx-sqlite-production-db)
  (markdown-notes classified-as projections-or-seeds)
  (codex-can-inspect topic-db-status)))
```

## Related pages / references

- <a page="Ownership Extraction with Compatibility Shell">Ownership Extraction with Compatibility Shell</a>
- <a page="Codex Belongs to Dreyeck">Codex Belongs to Dreyeck</a>
- <a page="Topic factory">Topic factory</a>
- <a page="Authored topic factories">Authored topic factories</a>
- <a page="Topics HyperBook in HyperDoc">Topics HyperBook in HyperDoc</a>
