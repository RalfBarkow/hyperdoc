# Federated Topicmap representation

This slice fixes represented-object identity before changing primary clicks.
The evidence fixtures and temporal State/Delta derivation are unchanged.

## Existing facilities inspected

- `hyperbook-fedwiki/pages.lisp`: `fedwiki-page` is a native HyperBook page,
  identified by its containing `fedwiki:` HyperBook and slug. A
  `remote-fedwiki-page` additionally retains the origin HyperBook and origin ID.
  `load-page` / `reload-page` fetch live JSON on demand.
- `hyperbook-fedwiki/wiki-links.lisp`: `wiki-link` retains an unresolved title,
  slug, source HyperBook/page coordinates and a resolution thunk. Native lookup
  tries the local site, a plugin/page fetch and journal-derived context in order,
  returning the first match. It is not a multiple-context subject object.
- `hyperbook-fedwiki/pages.lisp`: context sites come from journal site and
  attribution references, ordered by their most recent occurrence. The visited
  `*neighborhood*` is a separate collection of native site proxies.
- `dreyeck/src/fedwiki-page-materialization.lisp`: the existing
  `materialize-fedwiki-page-fork` writes a genuine local page JSON file with a
  source-site/date fork entry. Its test verifies persisted content and provenance.
  `local-fedwiki-page` / `local-fedwiki` load that actual local store.
- `/Users/rgb/workspace/wiki-client/lib/page.js`, `revision.js`, `link.js`,
  `lineup.js`, `pageHandler.js`: page/site identity, journal replay, context,
  lineup navigation and local/origin persistence already exist in that client.
  This slice adds no JavaScript client or navigation state.
- HyperDoc already has Topicmap Point selection and CLOG Inspector panels.
  The separate Lisp FedWiki navigation prototype is a fixture demonstration,
  not a production page lineup to substitute for native HyperBooks.

## Necessary distinctions

The native page has no historical source event and its Reload operation replaces
content with the live version. `context-fedwiki-page` is a small specialization
of that native class, retaining the source evidence, actual `federated-event`
and historical page JSON. Existing `context-page-story-at` supplies item values;
an adapter preserves native story order from the same saved journal. Native
Story/Journal/Links views remain available. Historical collaborative links use
the snapshot's native site/context catalogs; a miss stays unresolved rather
than fetching current content. Reload is not offered for the historical object.

No existing class represented a subject across several source contexts.
`federated-subject` retains the title, actual context/event and native unresolved
`wiki-link` objects. Recorded historical candidates and cached neighborhood
references are separate queries, with no implicit winning site. Reflective
Practice has no concrete page JSON in the saved evidence; cached Jan/Thompson
references do not establish those pages' historical contents.

## Sign/object contract and proof

| Sign | Actual represented value |
| --- | --- |
| Jan / John Dewey | Native `context-fedwiki-page`, Jan HyperBook / `john-dewey`, historical state at 18:03:51.968Z |
| Jan / How We Think | Native Jan page, distinct from Thompson despite equal title/slug |
| Thompson / How We Think | Native Thompson page |
| Reflective Practice | `federated-subject` with context, event and native links |
| Ward event | The cached `federated-event` instance |
| Relation Contract Topic in State | The actual relation hash in State |
| Relation Contract Topic in Delta | The actual change plist in Delta |

Projection IDs and labels remain separate from these values. Existing Relation
Contract Topics label edges without adding domain graph nodes. Inspector
references use the exact `object` value. Per-time caches preserve identity and
historical provenance; the context cursor remains the only selection of time.
Projection construction performs no remote fetch, global registration or local
fork, and native constructors receive copies of the saved JSON.

`check-context-represented-objects` asserts types and `EQ` references, native
historical Story/link targets, frozen snapshots across cursor movement, separate
same-title pages, candidate distinctions, and unchanged evidence/global catalogs.
Work reading, real TALA integration, Wiki-link contracts and existing persisted
fork tests pass.

Local CLOG Inspector walkthrough additionally opened each required object,
its Slots view, John Dewey's historical Story and one Ward Delta change.
QA record: `/Users/rgb/workspace/wiki-trails-rendered-local/federated-representation-inspector-proof.json`.
Primary Topicmap click behavior is unchanged in this representation slice;
opening working material and invoking the existing persisted fork operation
remain the subsequent interaction work.
