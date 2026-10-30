# Pull Request Review — local Reading

This slice starts at observed `dreyeck.ch` commit
`573fe37611a61d984260ebf43c797f7534211bdd` and adds an independent, read-only
Reading for `RalfBarkow/hyperdoc`. It uses native Common Lisp objects,
`dreyeck/topicmap`, `dreyeck/inspector/topicmap`, HTML Inspector views and an
unregistered HyperDoc book. It loads no ISO Topic Maps model, changes no project
Work status and creates no Acceptance Record. MCP services and Catalog authority
policy are untouched.

## The retained example

`dreyeck/pr-review/example/github-snapshot.json` is a completed, explicit GitHub
API observation at **2026-10-30T10:26:43Z**. It contains the six open PRs observed
then, including the current PR #6 documentation revision `4ef218a6...`, their
complete observed PR commit lists and Issue #7. The count is data, not an
application constant. A subsequent seventh PR is covered by tests. Publishing
this Reading's own Draft PR will make the example older than the live list;
rendering does not refresh it or claim that six PRs remain open now.

The first-class snapshot and PR objects retain repository identity, PR number,
base/head SHA and branch, draft/state, source URL and observation time. Commits,
Issue records, PR source bodies, source-warranted evidence/questions, claims and
human notes have separate inspectable objects. The compact table links PR review
objects; those link the observed metadata, all imported commits, source documents,
related Issue objects and GitHub pages. Topicmap workspace navigation retains
these same object handles.

`review-annotations.json` is **separate curated commentary**, not GitHub source
metadata or human acceptance. Its four source relationships are:

| Source → consumer/related work | Type and warrant |
| --- | --- |
| PR #1 → PR #3 | Reported verified CTM source: PR #3 names PR #1's exact source revision |
| PR #1 → PR #4 | Reported verified CTM source: PR #4 explicitly qualifies the unmerged fixture |
| PR #5 → PR #6 | Source port: PR #6 names the verified repair revision |
| PR #6 → Issue #7 | Separate investigation: PR #6 explicitly separates Journal work |

None is a Git merge dependency. Quote, source-body SHA-256, endpoint revisions,
repository authority and supported relation type are checked before projection.
These checks establish syntactic traceability of an explicitly curated reading,
not automatic natural-language entailment. The Reading observes reports of
verification; it does not rerun the tests reported by another PR or infer human
acceptance. In particular PR #6's latest observed head differs from the earlier
runtime revision named by its evidence.

The existing Topicmap epistemic vocabulary is retained: observed →
`:source-observed`, derived → `:mechanically-derived`, inferred →
`:design-inference`, hypothesized → `:working-hypothesis`. Conjectural,
unsupported and stale claims remain inspectable but add no factual edges.
Human review notes are supplied separately through `make-human-review-note`
and `make-reading :notes`; they never modify the source snapshot. A note is
qualified to its chosen PR head; it is not a decision about another revision,
a merge authorization or an accepted Work declaration.

## Explicit capture/import boundary

The Lisp systems contain no GitHub client, refresh operation or write operation.
Only a trusted local caller can import a pathname. JSON is parsed as data, bounded
to 4 MiB, never passed to the Lisp reader or evaluator. Imported PR bodies and
labels are escaped; navigation URLs have qualified GitHub identities. The initial
import supports this repository's same-repository base/head observations; foreign
branch authorities fail explicitly. The stored SHA-256 identifies the retained
UTF-8 document; it is not a GitHub signature or an authenticity claim on an
arbitrary operator-supplied file.

A later capture is an explicit trusted CLI operation, outside HTTP rendering:

```sh
python scripts/capture-pr-review.py --issue 7 --output /tmp/new-github-review.json
```

This uses the existing `gh` configuration and GET-only, paginated API requests.
It retains no credentials/headers and does not change GitHub. A head/state change
while capturing or a failed/unavailable request aborts without replacing a
previous snapshot with an empty list. Capture is non-atomic across API requests.
Use a separate output path; the reviewed example is retained evidence.

In Lisp, `import-snapshot` creates a new observation. `import-annotations` reads
separate curated source references. `changed-revisions` compares two explicit
available observations, including head/base changes and added/removed PRs.
Claims/marks from old heads or edited body digests are quarantined rather than
retargeted. Missing data is represented explicitly by `make-unavailable-snapshot`,
not by a false zero-PR observation. The default one-day age policy is a display
heuristic; even `:within-age-window-unchecked` does not prove current remote state.

## Local REPL entrypoint

Use the target's declared ASDF environment (for example its development shell)
with this checkout in the source registry. First load the smallest required layer:

```lisp
(require :asdf)
```

Then load the Reading before reading forms that mention its packages:

```lisp
(asdf:load-system "dreyeck/pull-request-review/reading")
```

Prepare the explicit local fixture, without starting any service:

```lisp
(in-package :cl-user)
(multiple-value-bind (reading book)
    (dreyeck/pull-request-review:prepare-example-reading)
  (defparameter *pull-request-review* reading)
  (defparameter *pull-request-review-book* book))
(clog-moldable-inspector:clog-inspect :object *pull-request-review*)
```

Inspect **Pull requests**, **Warrants and notes**, then **Topicmap**. Follow a PR
object to **Review**, **Observed metadata**, a **Commit**, a reported source or
Issue #7. Follow **Snapshot provenance** to its observation time and digest.
To read the authored HyperDoc page, inspect `*pull-request-review-book*` directly;
it remains unregistered. `prepare-example-reading` selects the explicitly
prepared object for that local book's `local-reading` links. Retained snapshot
objects are unchanged when another observation is prepared.

The tests below are isolated-process and Inspector-reference proofs. An actual
user SLY session/browser interaction is not claimed executed by those tests.

## Focused checks

```sh
PYTHONDONTWRITEBYTECODE=1 python -m unittest discover -s tests -p test_pr_review_capture.py -v
sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/pull-request-review/reading")' --quit
```

They cover zero/one/multiple/seven PRs, unavailable data and failed capture,
updated head/base revisions, old snapshots, body edits without head changes,
unsupported and conjectural claims, distinct human notes, native object identity,
Inspector references through commits/sources/Issue, native Topicmap rendering and
workspace navigation, inert HTML and authored Reading navigation without Catalog
registration. No complete project suite, PR-reported legacy suite or production
verification is implied. Exact source/digest identities and results are in
`reports/pull-request-review/`.

## Separate Catalog admission proposal — not implemented

A later decision could admit a named book with a pre-imported, immutable snapshot
through trusted startup. It must resolve stale/unavailable-source presentation,
operator-selected snapshot provenance and the existing served-expression and
navigation authority contracts. It must test those contracts without changing
or bypassing the production Catalog policy, and must not refresh GitHub while
handling public requests. Human notes must remain a separate authority. No
Catalog membership, route, server startup, credentials, refresh timer or
admission exception is added here; the local book is deliberately unregistered.
