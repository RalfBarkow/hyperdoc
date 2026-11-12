# Inspecting one source-backed acceptance evidence chain

This optional experiment was developed and tested in a detached worktree based
on HyperDoc `9176349edb473becd7423a7ca246f9bc07a75388`. The tested implementation
was then committed as `637970ba79168d97d6d45455b3601cd9f1183ab8` and published
on `codex/acceptance-evidence-chain`.

At development time, the initially observed main worktree was clean at
`a33fa97a5ae3138b814151745228b1e4f5d1ebb8`; remote `dreyeck.ch` was
`596344ae95d746f436705808462259371f5a593c`. These are historical observations,
not claims about the current checkout or remote branches. Neither worktree nor
branch is assumed to be the evidence source automatically.

The retained `test-results.json` describes the uncommitted test-time state;
its source hashes, including the README hash, refer to the tested files now
preserved in `637970ba`. This publication-status correction does not rewrite
those historical records or claim a new test execution.

## Integration point and reuse

The new optional system is `dreyeck/work/acceptance-evidence-chain`, with a
focused `/tests` system. It extends the existing evaluation protocol for one
retained reading and supplies Inspector views. It does not create an acceptance
record, a test executor, an ISO TMDM schema or a SHOP3 domain.

| Existing object or API | Reuse |
|---|---|
| `git-repository-checkout` | Explicit local object-database resource, not execution authority. |
| `git-revision-reference` | Repository authority plus full OID, separately for retained evidence and the specified tested source. |
| `git-evidence-file`, `ensure-git-evidence-file` | Original report, retained log and Nix descriptor. Per-revision cached file identity is retained. |
| `git-file-blob-spec`, `git-run-string` | Read exact committed blobs through the existing no-lazy-fetch runner. Local replacement-object interpretations are disabled for this reading. No moving files or HEAD determine the source. |
| `source-snapshot:git-object-id` | Verify that text recovered through the existing Git reader re-encodes to precisely the blob's original octets. No generic Git API changes. |
| SHASHT | Existing JSON parser, including its single-value/trailing-junk check; no Lisp reader or source evaluation. |
| Ironclad | SHA-256 of the original retained-log octets. |
| `evaluation-*` | Describe the current inspection, its input, trace, identity, result and timestamps. |
| Inspector `defview`, `object-ref` and existing Git views | Keep source objects separately navigable by EQ identity, with retained checked texts available in the chain's own views. |
| `hyperdoc:defhyperdoc` | Register an optional English reading with separately readable Common Lisp forms; no new Catalog entry. |

The sole new result class is `acceptance-evidence-chain`. Its projected
statements are retained plists, not another graph model. Every statement has a
predicate, value, warrant, source objects and basis. A typed refusal condition
retains its reason, source and underlying Git/JSON condition where applicable.

## Fixed inputs and the revision-binding limit

The public entry point reads these original Git blobs at
`9176349edb473becd7423a7ca246f9bc07a75388`:

- `docs/topic-maps-integration-acceptance/nix-exporter-check.json`
- `docs/topic-maps-integration-acceptance/nix-exporter-check.log`
- `docs/topic-maps-integration-acceptance/candidate-build.nix`

The additional descriptor is retained because the JSON contains **no tested
revision field**. The fixed experiment separately names
`36c69d3312ae70748ecd40a5452759fcfaad25c4`. Its Git commit object must exist;
the descriptor must contain its literal `?rev=...` reference. The adapter does
not parse or evaluate Nix. A literal source reference, even in a retained
descriptor, does not establish that the historical process used those exact
descriptor contents. The historical execution-to-source binding remains
explicitly **not established by this projection**. It is not silently promoted
to a verified property of the run.

The repository authority is explicitly named by the adapter. Git object and
content checks do not authenticate authors, executors, assessors or GitHub.
Recorded working-directory and environment strings are inert data, never paths
to follow or settings to install.

## Warrant and evaluation semantics

| Statement | Warrant |
|---|---|
| Historical command, cwd, overrides, timestamps, exit code and named log | `:reported` |
| Recovered UTF-8 octets match original Git blob identities | `:artifact-verified` |
| Log SHA-256 matches the digest in the report | `:artifact-verified` |
| Retained descriptor contains the literal revision reference | `:observed-in-source` |
| The inspection's specified tested revision | `:specified-context` |
| That exact commit exists locally | `:artifact-verified` |

The original log contains non-ASCII UTF-8. It has **121067 octets**, with SHA-256
`2f9276424cd418cfe55db57a22cbfb542115659d1b98f390a3d0aacd1fa24adf`.
Hashing a lossy decoded or newline-normalized approximation is refused by the
Git blob round-trip check before the SHA-256 comparison. This bounded adapter
is not a generic binary Git reader; it requires compatible UTF-8 text decoding.

`evaluation-status-of` is `:inspected`, never an implementation verdict. The
evaluation times are this inspection's times; historical times remain reported
fields. `evaluation-result-of` is the exact retained parsed JSON object.
`evaluation-evidence-of` is the retained statement list. A successful inspection
with a reported nonzero exit code still has status `:inspected`. No acceptance
decision, independent-author-review assertion or deployment authority follows.

Repeated Inspector rendering retains the same file, revision, parsed report
and statement objects. Repeating the whole inspection makes a new result, with
equal source-derived evaluation identity; EQ is not claimed across processes.
Existing Git views re-query their attached repository. The chain's retained
text views show the actual checked reading independently of later availability.

## Human reading and Inspector forms

The English HyperDoc page is
[`Inspecting One Acceptance Evidence Chain.html`](../../dreyeck/pages/acceptance-evidence-chain/Inspecting%20One%20Acceptance%20Evidence%20Chain.html).
It contains the loading, source selection and inspection forms. Use a newly
prepared coherent image with the project's dependency registry, not an existing
runtime. Register this worktree's ASDF definitions first; replace the path on
another machine. Evaluate this block before reading package-qualified forms:

```lisp
(require :asdf)
(dolist (name '("dreyeck.asd" "hyperbook.asd" "hyperdoc.asd"))
  (asdf:load-asd
   (merge-pathnames name #P"/workspace/work/acceptance-evidence-chain/")))
(asdf:load-system "dreyeck/work/acceptance-evidence-chain")
```

```lisp
(defparameter *acceptance-evidence-repository*
  (make-instance 'dreyeck/git:git-repository-checkout
    :root #P"/workspace/hyperdoc/"
    :root-source :explicit-fixed-acceptance-evidence))
(defparameter *acceptance-evidence-chain*
  (dreyeck/work/acceptance-evidence-chain:inspect-acceptance-evidence-chain
   *acceptance-evidence-repository*))
(inspect *acceptance-evidence-chain*)
```

With an already connected CLOG Inspector in that same image:

```lisp
(clog-moldable-inspector:clog-inspect :object *acceptance-evidence-chain*)
```

Replace the explicit repository path for another machine. Loading this system
does not inspect evidence or start a server. No running image was changed to
develop or test the experiment. Interactive browser navigation is not claimed
by the automated HTML/reference checks.

## Focused verification

The tests inspect the actual fixed report and log, including their exact digest
and non-ASCII byte identity. They check reported versus verified warrants,
evaluation semantics, stable identity, repeated Inspector EQ references, and
absence of action buttons in the chain view.

Additional synthetic Git fixtures live only in temporary repositories and are
deleted afterwards. Their identity and authority are explicitly synthetic;
they do not substitute for the original evidence. They exercise nonzero exit
codes, inert command/cwd data, dirty working files and moving HEAD, invalid
JSON, mismatched SHA-256, malformed records, unsafe log references, a missing
descriptor reference and unavailable Git objects. Fixture commits are confined
to those temporary repositories; no project commit is made.

In the prepared dependency environment, the focused invocation is:

```sh
DEFEDERATION_REPO=/workspace/work/acceptance-evidence-chain \
EVIDENCE_CHAIN_REPOSITORY=/workspace/work/acceptance-evidence-chain \
  /workspace/scratch/tmdm-mcp-portable/bin/sbcl \
  --noinform --no-sysinit --no-userinit --non-interactive \
  --load docs/topic-maps-integration-acceptance/hyperdoc-bootstrap.lisp \
  --eval '(asdf:test-system "dreyeck/work/acceptance-evidence-chain")'
```

The inherited bootstrap is a fixed, host-specific prepared source registry,
not an installer. It selects this implementation worktree explicitly; evidence
still comes from the fixed Git objects. The existing Git API requires Git
2.44 or later for `--no-lazy-fetch` (executed: Git 2.52.0). Runtime limitations
are not translated into missing evidence or successful verification.

`test-results.json` records final commands, actual exit codes and hashes;
`focused.log` and `regressions.log` retain output. No recorded Nix command,
Topic Maps conformance test, SHOP3 action or deployment was rerun by this
experiment. Existing source implementations and active pins are unchanged.
