# Federated context: evidence and projection rules

The temporal reading is a Common Lisp experiment over saved evidence. The eight
files in `trails-rendered-evidence/` are byte-for-byte copies of the recovered page
JSON. They retain complete `story` and `journal` values. No script prepares events,
states, forks, or relation effects for the running model.

## Classification of the former fixture

RAW means a value copied from page JSON or its journal. DERIVED means a mechanical
operation on that evidence. INTERPRETIVE means an explicit rule of this experiment.
Selecting which raw items matter is interpretive even when their contents are raw.

| Former field | Class | Origin or rule |
| --- | --- | --- |
| Page `title`; item `type`, `id`, `text` | RAW | Selected values from saved page JSON |
| Journal `type`, `id`, `date`, `site`, `after`, `item` | RAW | Selected actions from saved journals |
| Retrieval `site`, `slug`, URL | RAW metadata | Identity of the downloaded document, outside its JSON body |
| Page aliases such as `jan-think` | INTERPRETIVE | Local names for selected evidence |
| `hyperbook`, `json-url`, composite event/association IDs | DERIVED | Identity formatting from site, slug, item and time |
| `at` and `last-text-edit.at` | DERIVED | UTC formatting of raw epoch milliseconds |
| Link `target` | DERIVED | Extract bracketed wiki-link titles with the existing FedWiki scanner |
| Link `from`, `to`, `kind`; `credited-page` | INTERPRETIVE | Map selected content onto site/page or subject identities |
| `attribution` | DERIVED | Extract the literal `via Thompson` text; this states attribution only |
| Link/journal association and `last-text-edit.date` | DERIVED | Find the corresponding raw action for that item |
| Trail `nodes` and literal `relation-type` | DERIVED | Ordered wiki-link titles and the public builder's `graph.addRel` literal |
| `relation-type-change.before`, `.after`, `.before-line`, `.after-line` | DERIVED | Reconstruct the earlier code item and compare the relevant literal/line |
| Fork `source-site`, `date` | RAW | Fork action fields |
| Fork `from`, `to`, `kind`, `source-page` | DERIVED under a projection rule | Resolve the named source site and same page title to separate page identities |
| Event `operation`, `journal` | RAW | Original action type and action value |
| Event `kind` | INTERPRETIVE | Categorize the selected operation as a link edit, fork or relation-type change |
| Event `date` | RAW | Original action date |
| Event `page`, `site`, `page-title`, `hyperbook` | DERIVED metadata | Attach the action to its actual receiving/publishing document |
| Event `before`/`after` item values | DERIVED | Replay create/add/edit/remove actions through the requested time |
| Fork `after.history = inherited` and imported source state | DERIVED | The receiving journal's prefix precedes its named fork; it is not receiving-site activity |
| `events` ordering | DERIVED | Sort the selected locally owned actions by raw date, then identity for ties |
| `topics-added`, `topics-removed` | DERIVED under projection rules | Compare topics in the two raw-derived graphs |
| `relations-set`, `relations-remove` | DERIVED under projection rules | Compare relation identities and values in those graphs |
| `relations-removed` | Absent | The actual old field name was `relations-remove` |
| `baseline.topics`, `baseline.relations` | DERIVED under projection rules | Project raw page states immediately before the experiment window |
| `concepts`, `shared-concept`, `trail-in-page` | INTERPRETIVE | Selected subject spellings and page/trail membership conventions |
| `scope`, `question`, `summary`, Memex `content-summary`, falsification text | INTERPRETIVE | Editorial descriptions; they do not determine state |
| Event `older-content` | INTERPRETIVE presentation | Reference the selected Memex excerpt/summary as contextual evidence |

The former effect arrays, baseline, ordered event array, link/fork/trail arrays and
relation-type-change record are no longer stored in the configuration JSON. Lisp
derives those readings from the raw files. The configuration retains retrieval
metadata, selected item IDs, a UTC day window and explicit editorial descriptions.

## Bounded projection rules

- Use the selected page and item identities, not every subject on every page.
- A named, dated final fork marks arrival in the receiving site's context. Its
  preceding raw journal prefix remains source history. Validate that prefix against
  the saved source journal when one is available.
- The Memex source has no independent saved download. Its evidence is explicitly
  the prefix inherited by Thompson, not an invented source-page download.
- Reconstruct content from raw create/add/edit/remove actions. Undated fork entries
  remain in the raw evidence; they cannot provide a dated event and do not edit content.
- Include named forks and edits/adds of selected paragraph items in the day window.
  Include a trail-builder edit when its relation literal changes. Factory placeholders
  and language-only changes do not become separate events in this reading.
- Use the existing FedWiki scanner for wiki-link titles, preserving trail order.
- Trail subjects are concept identities. Other links may resolve to a recorded page
  on the same site or named fork source. Same-title subject associations are a
  projection convention, not a claim that two federated pages are one object.
- Stable trail relation identity is paragraph-item ID plus adjacent-node index.
- Read the literal public `graph.addRel` label without executing JavaScript. Reject
  an unrecognized builder form rather than inventing its meaning.
- No rule emits a causal Jan/Thompson-to-Ward relation.

## Lisp inspection

`context-state-at` accepts an ISO UTC string or Unix milliseconds, inclusively.
`context-delta` accepts the context and optionally a `federated-event` or its record;
omitting the event uses the cursor. Neither operation requires browser interaction.

```lisp
(let* ((context (dreyeck/work/trails-rendered-reading:federated-context))
       (events (dreyeck/work/trails-rendered-reading:context-events context))
       (ward (find "2026-10-01T17:18:24.009Z" events
                   :key (lambda (event) (gethash "at" event)) :test #'equal)))
  (values
   (dreyeck/work/trails-rendered-reading:context-state-at context 1790875104008)
   (dreyeck/work/trails-rendered-reading:context-delta context ward)
   (dreyeck/work/trails-rendered-reading:context-state-at context 1790875104009)))
```

The focused test helper `temporal-proof-values` returns seven actual inspectable
values: ordered events, Ward event, before state, Ward delta, after state, Jan fork
event and resulting Jan state. It uses the existing Inspector object references.

Local CLOG inspection on 2026-10-05 opened all seven values independently, then
followed the Before and After relation lists to all four Trail relation objects.
Their IDs, endpoints and item identities were unchanged; the observed `kind` fields
were four empty strings before and four `Trail` strings after. This happened before
the existing Workspace controls were checked against the new model.
