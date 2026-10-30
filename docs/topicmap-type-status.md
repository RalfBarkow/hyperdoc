# Topic type, classification and status in the Inspector

This isolated presentation slice starts at Draft PR #8, commit
`9dfcf4d705302c561535259b87a4a9f64bd61b5f`, on
`codex/topicmap-type-status`. PR #8's branch and retained GitHub snapshots remain
unchanged. The local diff is against PR #8, not the production branch.

## The existing reading path

`dreyeck/src/topicmap-inspector.lisp:topicmap-topic-caption` combines the
producer's `:kind`, its `:status` and a specified temporal scope with ` · `,
falling back to the topic's projection type. The native SVG renderer uses this
short caption below the topic label. Previously `render-topicmap-topic-row`
reused that entire caption in a table column that `render-topicmap-legend`
called **Kind**. A status or temporal qualifier could consequently appear to
be part of a type, and the table did not separately show the actual type.

The legend now shows these independent values:

| Table label | Existing source | Interpretation |
| --- | --- | --- |
| Topic type | `topicmap-topic-type-of` | The producer's renderer-independent projection type, printed as a Lisp value, e.g. `:PULL-REQUEST` or `:WORK-PAGE` |
| Display classification | View property `:kind` | The producer's existing classification, e.g. `pull request`, `work item`, `relation` |
| Status | View property `:status` | The producer's existing status, e.g. `draft` or `prototype` |
| Temporal scope | `topicmap-topic-temporal-scope-of` | The existing qualifier, independently of classification and status |
| Inspectable object | `topicmap-topic-object-of` | The same native object reference as before |

The optional classification, status and temporal columns appear only when some
topic supplies a value. Missing classification/status cells stay empty. No
status or type is inferred. All text remains HTML-escaped.

“Display classification” describes the field being presented, not a claim that
`:kind` is dispensable or purely cosmetic. Work's `%work-topic` preserves
source-authored kinds under the shared `:work-page` projection type;
`resolve-relation-contract` also uses the `relation` kind. None of those domain
contracts, authored declarations or producers is renamed or changed.

The distinction is useful beyond PR Review. A read-only audit of the actual
fixture projections (`reports/topicmap-type-status/classification-review.txt`)
finds four classifications under Work's single `:WORK-PAGE` type (`area`,
`concept`, `relation`, `work item`), five under Lisp Critic's `:STATION`, and
two under its `:DOCUMENTED-STAGE`. These values convey different granularity,
rather than repeating the same field. In the Item edit producer, static source
inspection likewise finds `:TMDM-TOPIC` paired with authored spec types or
schema uses (`dreyeck/work/item-edit-topicmap.lisp:build-projection`); that
Reading was not runtime-tested here.

For PR Review, `:PULL-REQUEST` and `pull request` largely overlap in meaning.
They are not two independent observations or a new domain distinction. The
shared legend retains both the literal projection type and the supplied
classification consistently because other existing Readings use them
differently. Readings without `:kind` get no classification column. No
string-normalization heuristic guesses whether two producer values mean the
same thing, and no extra classification is invented for the PR example.

The wrapper's CLOS class (`topicmap-topic`, or Work's `work-topic` subclass),
its `type` slot and the represented object's CLOS class are distinct. The table
reports the existing `type` slot; it neither changes CLOS dispatch nor invents
an ontology from class names. This renderer-independent projection remains
separate from the ISO/IEC 13250 native TMDM model.

## Observation time and the sole SVG exception

PR #8's `tm:topicmap-projection-of` method for `review-reading` put
`snapshot-observed-at` into the snapshot root's `:status`. That timestamp is
already available by following the exact snapshot object to **Snapshot
provenance**. It is now omitted from `:status`, with no replacement status.
No imported snapshot data, source digest, observation time or object identity
changes.

For example, the root has type `:GITHUB-OBSERVATION`, classification `snapshot`
and an empty Status cell. A PR has type `:PULL-REQUEST`, classification
`pull request` and status `draft` in this retained example.

The SVG caption algorithm and legacy CSS classes are unchanged. The justified
exception is this root's caption: `snapshot · 2026-10-30T10:26:43Z` becomes
`snapshot`, because observation time is provenance rather than state. Work and
Lisp Critic SVG renderings are byte-identical to the unmodified PR #8 outputs.
The PR Review SVG is byte-identical after precisely that one caption removal.
Baseline hashes and their capture method are in
`reports/topicmap-type-status/`.

## Yen's Four Words

Conceptual reference: [Yen Overview](https://yen.oeiuwq.com/start/overview/),
particularly **The Four Words**. The user supplied this section directly. The
original Markdown was independently read at
[`vic/yen`, revision `44d4eb6890d4499c9348024d532f02dbd136429d`](https://github.com/vic/yen/blob/44d4eb6890d4499c9348024d532f02dbd136429d/docs/src/content/docs/start/overview.mdx),
blob `b7d42d525ed3669d200817efa894acf95f29205a`.
Direct website retrieval was refused by the environment proxy at CONNECT with
403, before any destination HTTP response; this is not evidence of a website
HTTP 403.

Yen defines a Kind as “a type of thing you configure, and the fields each one
has.” It participates in a configuration language: its `spawns` places instances
in a Scope tree, Aspects provide behavior at matching scopes, and Sinks collect
and reduce elements. HyperDoc's existing projection type classifies a projected
subject; its `:kind` is a producer-specific classification. Neither is a Yen
Kind declaration. A CLOS class separately determines object structure and method
dispatch. A presentation heading does not establish any of these semantics.

Similarly HyperDoc's temporal scope is not Yen's instance-placement Scope.
No Kind, Scope, Aspect or Sink runtime primitive, configuration model or
configuration routing is introduced here.

## Local replay and human inspection

With this checkout and its existing dependencies in the ASDF source registry:

```sh
sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/topicmap-presentation/tests")' --quit
sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/pull-request-review/reading")' --quit
```

Use separate fresh processes: the existing PR Review tests also check its
isolated, unregistered book boundary. The new focused system additionally
loads the existing Work and Lisp Critic Readings, but does not run their full
suites. See the evidence report for the five existing Topicmap regression
functions run separately.

For optional inspection in the user's SLY image, load the Reading before
reading forms that mention its package:

```lisp
(require :asdf)
(asdf:load-system "dreyeck/pull-request-review/reading")
```

Then evaluate separately:

```lisp
(defparameter *type-status-reading*
  (dreyeck/pull-request-review:example-reading))
(clog-moldable-inspector:clog-inspect :object *type-status-reading*)
```

Open Topicmap, compare the independent table columns, and follow the snapshot
object to Snapshot provenance for the observation time. These instructions
provide a human review path; automated fresh-process HTML/reference checks are
not claimed as a completed user SLY/browser review. No HyperDoc page, FedWiki
page, Catalog admission, CTM, MCP or production configuration changes occur.
