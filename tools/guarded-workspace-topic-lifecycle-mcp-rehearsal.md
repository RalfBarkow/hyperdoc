# Guarded workspace topic lifecycle MCP rehearsal

This artifact is the operator call sheet for the guarded workspace topic lifecycle
boundary. It keeps two use cases separate:

- deterministic local rehearsal through the memory-backed MCP smoke server
- production-facing call shapes against the real HTTPS MCP endpoint

The boundary remains narrow on purpose:

- canonical reads go through `read_dmx_topicmap` and `read_dmx_topic`
- topic placement goes through `upsert_workspace_topicmap_context`
- HyperDoc-owned topic creation/update goes through `upsert_workspace_topic_factory_snippet`
- hard delete goes through `delete_workspace_note` or `delete_workspace_topic`
- stale HyperDoc workspace-journal companions go through `repair_workspace_journal_companion`
- topicmap unlink stays typed, but live HTTP execution is still intentionally unsupported

For the specific stale journal companion defect class, do not chain raw
`delete_workspace_note` plus manual recreate/placement steps. Use
`repair_workspace_journal_companion` so the runtime can keep delete-and-recreate,
hidden/off-canvas placement, and identity-history reporting on one typed repair
boundary.

## Preconditions

- The server default workspace topicmap is `919822` on the current shared-workspace deployment.
- Live writes require `HYPERDOC_MCP_ENABLE_LIVE_WRITES=1` plus valid `HYPERDOC_DMX_IMPORT_*` write credentials on the server.
- For raw HTTP calls, open an MCP session first and reuse the returned `Mcp-Session-Id`.

## Tool contract sheet

### `upsert_workspace_topicmap_context`

- Purpose: add an existing topic to the workspace topicmap or refresh validated long-form view props for an existing membership.
- Live support: yes.
- Mutation kind: typed topicmap placement or view-props update, not topic creation.
- Ownership restriction: none for placement itself; the target topic must already exist.
- Default topicmap: omitting `topicmapId` uses the server workspace topicmap, currently `919822`.
- Required fields:
  - `topicId` integer
  - `viewProps` object with canonical long-form keys
- Optional fields:
  - `topicmapId` integer
  - `dryRun` boolean
- Success result shape:
  - `operation`
  - `topicmap-id`
  - `topic-id`
  - `topic-uri`
  - `topic-title`
  - `in-topicmap-p`
  - `topicmap-action` as `add` or `set-view-props`
  - `payload-validation-status`
  - `normalized-view-props-json`
  - `intended-method`
  - `intended-endpoint`
  - `live-supported-p`
  - `support-reason`
  - `dry-run`
- Example `arguments`:

```json
{
  "topicId": 907120,
  "topicmapId": 919822,
  "viewProps": {
    "dmx.topicmaps.x": 640,
    "dmx.topicmaps.y": 220,
    "dmx.topicmaps.visibility": true,
    "dmx.topicmaps.pinned": false
  },
  "dryRun": false
}
```

### `upsert_workspace_topic_factory_snippet`

- Purpose: create or update a HyperDoc-owned topic-factory snippet twin and place it into the workspace topicmap.
- Live support: yes.
- Mutation kind: typed topic upsert plus typed topicmap placement.
- Ownership restriction: creates or updates only HyperDoc-owned topic-factory snippet twins under the `hyperdoc:topic-factory-snippet/` URI scheme.
- Default topicmap: omitting `workspaceTopicmapId` uses the server workspace topicmap, currently `919822`.
- Required fields:
  - `snippetId` string
  - `snippetText` string
  - `sourcePath` string
- Optional fields:
  - `sourceOriginId` string
  - `sourceOriginPath` string
  - `relatedHyperdocPageTitle` string
  - `relatedTopicId` string
  - `references` array of strings
  - `provenance` object
  - `workspaceTopicmapId` integer
  - `topicTypeUri` string
  - `topicValue` string
  - `viewProps` object
  - `dryRun` boolean
- Success result shape:
  - `operation`
  - `dry-run`
  - `topic-id`
  - `snippet-id`
  - `uri`
  - `workspace-topicmap-id`
  - `topic-action` as `create` or `update`
  - `topicmap-action` as `add` or `already-present`
  - `topic-type-uri`
  - `topic-value`
  - `source-path`
  - `related-hyperdoc-page-title`
  - `related-topic-id`
  - `view-props-validation-status`
  - `normalized-view-props-json`
- Example `arguments`:

```json
{
  "snippetId": "guarded-workspace-lifecycle-smoke",
  "snippetText": "Initial guarded workspace lifecycle smoke snippet.",
  "sourcePath": "tools/guarded-workspace-topic-lifecycle-mcp-rehearsal.md",
  "relatedHyperdocPageTitle": "Using guarded workspace topic lifecycle tools",
  "relatedTopicId": "using-guarded-workspace-topic-lifecycle-tools",
  "topicValue": "Guarded workspace lifecycle smoke topic",
  "workspaceTopicmapId": 919822,
  "viewProps": {
    "dmx.topicmaps.x": 640,
    "dmx.topicmaps.y": 220,
    "dmx.topicmaps.visibility": true,
    "dmx.topicmaps.pinned": false
  },
  "dryRun": false
}
```

### `delete_workspace_note`

- Purpose: hard-delete a HyperDoc-owned workspace note or handover by `noteKey` or `topicId`.
- Live support: yes.
- Mutation kind: hard delete only.
- Ownership restriction: only HyperDoc-owned workspace notes and handovers. Foreign notes are rejected.
- Default topicmap: omitting `workspaceTopicmapId` uses the server workspace topicmap, currently `919822`.
- Required fields:
  - at least one of `noteKey` or `topicId` is required semantically
- Optional fields:
  - `noteKey` string
  - `topicId` integer
  - `noteKind` string, `workspace-note` or `handover`
  - `workspaceTopicmapId` integer
  - `dryRun` boolean
- Success result shape:
  - `operation`
  - `topic-id`
  - `note-key`
  - `note-kind`
  - `workspace-topicmap-id`
  - `topic-uri`
  - `topic-type-uri`
  - `topic-title`
  - `in-topicmap-p`
  - `ownership-class`
  - `hyperdoc-owned-p`
  - `ownership-reason`
  - `ownership-workspace-topicmap-id`
  - `delete-action` as `hard-delete`
  - `intended-method`
  - `intended-endpoint`
  - `dry-run`
- Example `arguments`:

```json
{
  "noteKey": "guarded-workspace-lifecycle-note",
  "workspaceTopicmapId": 919822,
  "dryRun": false
}
```

### `delete_workspace_topic`

- Purpose: hard-delete a HyperDoc-owned workspace topic by `topicId`.
- Live support: yes.
- Mutation kind: hard delete only.
- Ownership restriction: only HyperDoc-owned workspace notes, handovers, and topic-factory snippet twins. Foreign topics are rejected.
- Default topicmap: omitting `workspaceTopicmapId` uses the server workspace topicmap, currently `919822`, for ownership/in-topicmap planning.
- Required fields:
  - `topicId` integer
- Optional fields:
  - `workspaceTopicmapId` integer
  - `dryRun` boolean
- Success result shape:
  - same delete summary fields as `delete_workspace_note`
- Example `arguments`:

```json
{
  "topicId": 922123,
  "workspaceTopicmapId": 919822,
  "dryRun": false
}
```

### `repair_workspace_journal_companion`

- Purpose: repair a stale HyperDoc-owned workspace-journal companion topic when the existing companion is present but unassigned.
- Live support: yes.
- Mutation kind: typed journal-specific repair only; this is not a generic delete or generic note repair surface.
- Ownership restriction: only HyperDoc-owned workspace-journal companions in the stale/unassigned repair class. Non-journal topics and already-assigned companions are rejected explicitly.
- Default topicmap: omitting `workspaceTopicmapId` uses the server workspace topicmap, currently `919822`.
- Required fields:
  - at least one of `journalTopicId`, `subjectKey`, or `subjectUri` is required semantically
- Optional fields:
  - `journalTopicId` integer
  - `subjectKey` string
  - `subjectUri` string
  - `workspaceTopicmapId` integer
  - `workspaceId` integer
  - `dryRun` boolean
- Success and typed-failure result shape:
  - `operation`
  - `dry-run`
  - `repairable-p`
  - `repair-completed-p`
  - `repair-reason`
  - `subject-key`
  - `subject-uri`
  - `journal-topic-id`
  - `stale-topic-id`
  - `replacement-topic-id`
  - `current-topic-id`
  - `repair-strategy`
  - `repair-status`
  - `repair-step`
  - `repair-action-taken`
  - `assigned-workspace-id-after`
  - `hidden-placement-enforced-p`
  - `hidden-view-props-restored-p`
  - `ownership-class`
  - `hyperdoc-owned-p`
  - `in-topicmap-before`
  - `in-topicmap-after`
  - `writable-workspace-context-used-p`
  - partial-progress fields such as `stale-delete-attempted-p`, `stale-delete-succeeded-p`, `replacement-create-attempted-p`, `replacement-create-succeeded-p`, `hidden-placement-attempted-p`, and `hidden-placement-succeeded-p`
- Operator guidance:
  - use this tool when the report shows an existing journal companion with assigned workspace `none`
  - do not use `delete_workspace_note` as the operator story for this defect class
- Example `arguments`:

```json
{
  "journalTopicId": 928689,
  "workspaceTopicmapId": 919822,
  "workspaceId": 919815,
  "dryRun": false
}
```

### `remove_workspace_topic_from_topicmap`

- Purpose: unlink a topic from the workspace topicmap without deleting the topic.
- Live support:
  - yes on the memory client
  - no on the current HTTP client until DELETE on `/topicmaps/<topicmap>/topic/<topic>` is proven
- Mutation kind: unlink only.
- Ownership restriction: none for planning; live support depends on client type, not topic ownership.
- Default topicmap: omitting `topicmapId` uses the server workspace topicmap, currently `919822`.
- Required fields:
  - `topicId` integer
- Optional fields:
  - `topicmapId` integer
  - `dryRun` boolean
- Success result shape:
  - `operation`
  - `topicmap-id`
  - `topic-id`
  - `topic-uri`
  - `topic-title`
  - `in-topicmap-p`
  - `topicmap-action` as `remove` or `already-absent`
  - `intended-method`
  - `intended-endpoint`
  - `live-supported-p`
  - `support-reason`
  - `dry-run`
- Example `arguments`:

```json
{
  "topicId": 922123,
  "topicmapId": 919822,
  "dryRun": false
}
```

### `validated_dmx_write_dry_run` with `writeKind=topicmap_context_upsert`

- Purpose: dry-run-only validation/planning for typed topicmap placement or view-props update.
- Live support: dry-run only by design.
- Mutation kind: none.
- Ownership restriction: none; the target topic must already exist and be readable.
- Default topicmap: omitting `topicmapId` uses the server workspace topicmap, currently `919822`.
- Required fields:
  - `writeKind`
  - `topicId`
  - `viewProps`
- Optional fields:
  - `topicmapId`
- Success result shape:
  - `writeKind`
  - `summary` with the same membership plan fields returned by `upsert_workspace_topicmap_context`
- Example `arguments`:

```json
{
  "writeKind": "topicmap_context_upsert",
  "topicId": 907120,
  "topicmapId": 919822,
  "viewProps": {
    "dmx.topicmaps.x": 640,
    "dmx.topicmaps.y": 220,
    "dmx.topicmaps.visibility": true,
    "dmx.topicmaps.pinned": false
  }
}
```

### `validated_dmx_write_dry_run` with `writeKind=topicmap_context_remove`

- Purpose: dry-run-only validation/planning for typed topicmap unlink.
- Live support: dry-run only by design.
- Mutation kind: none.
- Ownership restriction: none.
- Default topicmap: omitting `topicmapId` uses the server workspace topicmap, currently `919822`.
- Required fields:
  - `writeKind`
  - `topicId`
- Optional fields:
  - `topicmapId`
- Success result shape:
  - `writeKind`
  - `summary` with the same membership plan fields returned by `remove_workspace_topic_from_topicmap`
- Example `arguments`:

```json
{
  "writeKind": "topicmap_context_remove",
  "topicId": 907120,
  "topicmapId": 919822
}
```

## Deterministic memory-client rehearsal

Run the dedicated proof smoke. It creates a HyperDoc-owned snippet twin through MCP,
unlinks it from the memory-backed workspace topicmap, hard-deletes it, and proves
that the same guarded path rejects hard delete for a foreign topic.

```sh
ASDF_SOURCE_REGISTRY='(:source-registry (:tree "/Users/rgb/workspace/hyperdoc") :inherit-configuration)' \
nix develop -c sbcl --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system :hyperdoc/tests)' \
  --eval '(hyperdoc/tests::run-dmx-mcp-owned-topic-lifecycle-proof-smoke-test)' \
  --eval '(uiop:quit 0)'
```

The broader authoritative suite still remains:

```sh
ASDF_SOURCE_REGISTRY='(:source-registry (:tree "/Users/rgb/workspace/hyperdoc") :inherit-configuration)' \
nix develop -c sbcl --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:load-system :hyperdoc/tests)' \
  --eval '(uiop:symbol-call :hyperdoc/tests :run-dmx-mcp-smoke-tests)' \
  --eval '(uiop:quit 0)'
```

## Production-facing MCP call shape

Open a session first. Copy the returned `Mcp-Session-Id` into later calls.

```json
{
  "jsonrpc": "2.0",
  "id": 1,
  "method": "initialize",
  "params": {
    "protocolVersion": "2025-03-26",
    "clientInfo": {
      "name": "guarded-workspace-topic-lifecycle-rehearsal",
      "version": "1.0"
    }
  }
}
```

Then send:

```json
{
  "jsonrpc": "2.0",
  "method": "notifications/initialized"
}
```

Every tool call then uses the same envelope:

```json
{
  "jsonrpc": "2.0",
  "id": 10,
  "method": "tools/call",
  "params": {
    "name": "TOOL_NAME",
    "arguments": {}
  }
}
```

### Dry-run topicmap-context upsert into topicmap 919822

```json
{
  "jsonrpc": "2.0",
  "id": 11,
  "method": "tools/call",
  "params": {
    "name": "validated_dmx_write_dry_run",
    "arguments": {
      "writeKind": "topicmap_context_upsert",
      "topicId": 907120,
      "topicmapId": 919822,
      "viewProps": {
        "dmx.topicmaps.x": 640,
        "dmx.topicmaps.y": 220,
        "dmx.topicmaps.visibility": true,
        "dmx.topicmaps.pinned": false
      }
    }
  }
}
```

### Live HyperDoc-owned topic upsert into topicmap 919822

```json
{
  "jsonrpc": "2.0",
  "id": 12,
  "method": "tools/call",
  "params": {
    "name": "upsert_workspace_topic_factory_snippet",
    "arguments": {
      "snippetId": "guarded-workspace-lifecycle-smoke",
      "snippetText": "Initial guarded workspace lifecycle smoke snippet.",
      "sourcePath": "tools/guarded-workspace-topic-lifecycle-mcp-rehearsal.md",
      "relatedHyperdocPageTitle": "Using guarded workspace topic lifecycle tools",
      "relatedTopicId": "using-guarded-workspace-topic-lifecycle-tools",
      "topicValue": "Guarded workspace lifecycle smoke topic",
      "workspaceTopicmapId": 919822,
      "viewProps": {
        "dmx.topicmaps.x": 640,
        "dmx.topicmaps.y": 220,
        "dmx.topicmaps.visibility": true,
        "dmx.topicmaps.pinned": false
      },
      "dryRun": false
    }
  }
}
```

### Live update of the same HyperDoc-owned topic

```json
{
  "jsonrpc": "2.0",
  "id": 13,
  "method": "tools/call",
  "params": {
    "name": "upsert_workspace_topic_factory_snippet",
    "arguments": {
      "snippetId": "guarded-workspace-lifecycle-smoke",
      "snippetText": "Updated guarded workspace lifecycle smoke snippet.",
      "sourcePath": "tools/guarded-workspace-topic-lifecycle-mcp-rehearsal.md",
      "relatedHyperdocPageTitle": "Using guarded workspace topic lifecycle tools",
      "relatedTopicId": "using-guarded-workspace-topic-lifecycle-tools",
      "topicValue": "Guarded workspace lifecycle smoke topic",
      "workspaceTopicmapId": 919822,
      "dryRun": false
    }
  }
}
```

### Remove-from-topicmap flow

The call shape is the same on both clients:

```json
{
  "jsonrpc": "2.0",
  "id": 14,
  "method": "tools/call",
  "params": {
    "name": "remove_workspace_topic_from_topicmap",
    "arguments": {
      "topicId": 922123,
      "topicmapId": 919822,
      "dryRun": false
    }
  }
}
```

Current expected behavior:

- memory client: succeeds with `topicmap-action = remove`
- real HTTP client: returns `status = unsupported_operation` until DELETE on the topicmap membership route is proven

### Hard-delete flow for the HyperDoc-owned test topic

Use the `topic-id` returned by the create call.

```json
{
  "jsonrpc": "2.0",
  "id": 15,
  "method": "tools/call",
  "params": {
    "name": "delete_workspace_topic",
    "arguments": {
      "topicId": 922123,
      "workspaceTopicmapId": 919822,
      "dryRun": false
    }
  }
}
```

## First live use on topicmap 919822

When live writes are enabled, the safest first live write is to create a clearly
named HyperDoc-owned snippet twin, inspect it, then delete it.

1. `upsert_workspace_topic_factory_snippet` with snippet id
   `guarded-workspace-first-live-919822`
2. `read_dmx_topicmap` for `919822`
3. `read_dmx_topic` for the returned `topic-id`
4. `delete_workspace_topic` for that same `topic-id`

This exercises typed create, typed placement, canonical inspection, and
ownership-limited cleanup without moving an existing foreign topic.
