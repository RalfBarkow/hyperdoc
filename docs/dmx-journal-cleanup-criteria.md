# Criteria for a later targeted historical DMX cleanup

Source-only review; no production Topics or Associations were read. No actual
object ID is nominated for removal. Local JSON journals and DMX objects are
separate authorities: starting a new local epoch does not imply that a DMX object
is disposable.

## Potential candidates, never automatic deletion targets

The retained journal code recognizes legacy companion notes by the URI prefix
`hyperdoc:mcp/workspace-journal/` (including encoded `workspace-journal-*` note
keys). These historical JSON-in-note projections may be redundant when the
operator no longer requires that history and the new server uses its local
journal. The code's `dmx-workspace-journal-legacy-candidate-p` checks a prefix;
it is not sufficient evidence of ownership, redundancy or safe deletion.

The inventory and dry-run cleanup planner expose `assocIds`, `assocCount`, topic
identity and a proposed association-first sequence. That generic order does not
establish that all attached associations are disposable. The reviewed source is
`dmx-mcp/dmx-workspace-journal.lisp`, especially the legacy candidate summary,
inventory and cleanup planner; none of those tools was invoked here.

## Required evidence for each explicit Topic ID

- Verify URI, type (`dmx.notes.note` where applicable), journal ownership/schema,
  subject identity and intended historic purpose. A matching title/prefix alone
  does not prove an object was created by this application.
- Establish that it is an obsolete journal projection, not the subject's actual
  note/handover/annotation, a current Common Workspace member needed by users,
  an ISO Topic, or a foreign/manual note. Do not generalize to all HyperDoc URIs.
- Identify any current readers, restores, clients, links and operational or audit
  obligations. Decide explicitly whether preserving old data is still required.
  Export/back up the selected object and its incident graph privately and prepare
  a tested restore/disposition plan before any mutation proposal.
- Inspect each incident Association separately: explicit ID/type, player roles,
  both endpoints, ownership and use. A candidate Topic's `assocIds` list or zero
  count is not an independent reference check. Include inbound links, topicmap
  memberships/contexts and workspace assignments in the impact analysis.
- Only an Association proven solely to support the obsolete projection may be
  proposed together with it. Preserve associations serving another object,
  shared workspace semantics, user-authored routes or references. Unresolved
  endpoints/roles/types mean defer, not delete.

## Authorization boundary

A later bounded, authorized read-only inventory should produce an explicit
reviewed list of Topic and Association IDs with reasons, preserved references,
backup and rollback evidence. Mutation requires a separate operator-approved
work item. No wildcard deletion, automatic deletion by prefix, orphan inference
from absence in one topicmap, or cleanup during MCP cutover. The current decision
keeps all historical data untouched.
