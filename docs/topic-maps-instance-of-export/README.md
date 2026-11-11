# One read-only instance-of statement from the Project Topic Map

This optional integration is based on HyperDoc
`25f83196733a611810da2ea9596af1b4b2d215fb`, a direct descendant of the observed
`dreyeck.ch` HEAD `596344ae95d746f436705808462259371f5a593c`. The candidate Topic
Maps revision is `c446a8228017f405c3a2650ca893e9450ac7cd7b`. The implementation
uses the public `topic-maps.tmdm:type-instance-relationship` reader. It contains
no independent structural recognition, new TMDM model or planning domain.

The independent conformance-planning implementation is proposed separately in
[HyperDoc Draft PR #41](https://github.com/RalfBarkow/hyperdoc/pull/41). The
[prepared Topic Maps Draft PR](topic-maps-draft-pr.md) retains its exact title,
base, head and description for the operator; repository integration permissions
prevented its creation. Neither feature branch is merged.

## Boundary and Inspector entry point

The input is the existing Project `ctm-revision`, not a reconstructed graph or
a serialized conformance Case Record. Its `revision-map` supplies the native
Association and player Topics. The first supported example is the retained
`Work Breakdown` assertion `isa hyperdoc-page` in
`dreyeck/work/project/hyperdoc-project.ctm`. This is the HyperDoc Project map,
not the separate Topic Maps Slice 22U sample map (which has no `isa` assertion).

The adapter exports exactly one selected stated relationship. It refuses
missing or ambiguous witnesses, non-single Subject Identifiers and nonempty
Scope. It keeps the actual Scope value (empty in this example) without deciding
how a context applies. It computes no superclass or transitive consequences.
The statement's `:observed-in-map` warrant concerns the retained map, not the
truth of its authored project declarations or conformance of an implementation.

In a separately prepared image using the qualified candidate, evaluate each
block separately so packages exist before later forms are read:

```lisp
(asdf:load-system "dreyeck/work/topic-maps-instance-of-export")
```

```lisp
(defparameter *project-source-revision*
  (dreyeck/work/project:project-ctm-document))
(defparameter *project-instance-of*
  (dreyeck/work/topic-maps-instance-of-export:export-instance-of
   *project-source-revision*
   "tag:dreyeck.ch,2026:hyperdoc/page/dreyeck/work/reading/work-breakdown"
   "tag:dreyeck.ch,2026:hyperdoc/schema/hyperdoc-page"))
(inspect *project-instance-of*)
```

With the existing CLOG Inspector connected in that same image:

```lisp
(clog-moldable-inspector:clog-inspect :object *project-instance-of*)
```

`Instance-of provenance` links to the exact Association, Topics, map, revision
and statement atom by EQ identity. There are no action buttons. The native map
remains mutable: export refuses if its CXTM no longer equals the revision's
retained CXTM, or if the revision octets no longer hash to its recorded digest.
This is an observation at export time, not locking or versioned object history.
The source CTM SHA-256 and map CXTM SHA-256 name different representations;
equal content fingerprints do not imply EQ object identity. Retain the revision
object as the snapshot reference, together with these fingerprints and the
fixed Project Document IRI used in canonicalization.

## Runtime snapshot qualification, without activation

The active `nix/topic-maps-source.nix`, archive, manifest, Project source pin and
source-verification policies remain unchanged at `88994c1b`. The new optional
system can load there, but exporting refuses with
`:relationship-reader-unavailable`; it never substitutes a local reader.

The candidate archive and manifest are retained under `nix/`, unreferenced by
the active Nix source expression. The unchanged generator produces:

| Property | Candidate |
|---|---|
| Commit | `c446a8228017f405c3a2650ca893e9450ac7cd7b` |
| Archive octets | `1076023` |
| Archive SHA-256 | `bb1c64c9b0ecdb2d55ef76c8c4cc4ce19ab3eacebf8a32d380dd5a2453c6bdf2` |
| NAR SHA-256 | `sha256-d+qp4MmVOwHnEIRn3zzyIQhR/eUYCBos+XAu7OHs3/I=` |
| Excluded root | `reports/`, identified by its Git tree in the manifest |

Reproduce in a separate output directory; no Topic Maps worktree change is
needed. `REPO` must already contain the fixed commit's Git objects. Git must
support `check-attr --source` (the executed environment uses Git 2.52.0).

```sh
python3 scripts/topic-maps-snapshot.py create "$REPO" \
  c446a8228017f405c3a2650ca893e9450ac7cd7b /tmp/tm-candidate
python3 scripts/topic-maps-snapshot.py verify "$REPO" \
  c446a8228017f405c3a2650ca893e9450ac7cd7b \
  /tmp/tm-candidate/topic-maps-c446a822-runtime.tar.gz \
  /tmp/tm-candidate/topic-maps-c446a822.manifest /tmp/tm-verification.json
```

Two independent output directories produced byte-identical archives and
manifests. The existing Python/Git/Nix verifier checks the commit object, root
listing, every included blob and mode, attribute effects, exclusions and NAR
hash. The unchanged Lisp `verify-snapshot-tree` separately reconstructs Git
object hashes and rejects a changed source blob before Topic Maps code loads.
The disposable test tree is restored and verified again before execution.
This demonstrates content integrity relative to the selected Git commit, not
cryptographic authentication of its author or an independent human acceptance.

Production adoption still needs independent review, a fixed-output Nix build
using this NAR hash, new runtime source/manifest packaging and coordinated
qualification of Project/22U source pins. Neither the `/nix/store` policy nor
the one-ASDF-root requirement should be relaxed. The test uses the lower-level
tree verifier on an explicit disposable directory; that does not make such a
directory an accepted production store source. No active dependency changes
are part of this branch.

## Verification and reproducibility

`run.lisp` is an explicitly invoked isolated-image runner. Before loading the
candidate it verifies source identity and tests tamper refusal; afterwards it
checks all four Topic Maps systems came from the one verified directory. It
runs exporter tests and the unchanged SHOP3 conformance-planning tests. The
host-specific prepared dependency registry is retained as
`evidence/environment-bootstrap.lisp`; it is not an installer. Output FASLs use
a separate cache. No running Lisp image or service is involved.

```sh
DEFEDERATION_REPO=/path/to/this/hyperdoc \
TOPIC_MAPS_CANDIDATE_ROOT=/path/to/extracted/topic-maps-c446a822 \
TOPIC_MAPS_EVIDENCE_REPOSITORY=/path/to/topic-maps-git \
  sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load docs/topic-maps-instance-of-export/evidence/environment-bootstrap.lisp \
  --load docs/topic-maps-instance-of-export/run.lisp
```

`evidence/results.json` records executed commands, exit codes, source hashes
and limitations. Logs distinguish source verification, the actual Project
observation, synthetic refusal/inference probes and unchanged planning tests.
The exporter creates no Case Record and has no SHOP3 dependency or callback.
The existing conformance planner still operates only on pinned historical
Case Records; its operators change simulated planning state only.

The unchanged planning test's final message says it does not load Topic Maps
code: that describes the planning test itself. In this combined integration
process, the verified candidate's CTM/TMDM/CXTM code was already loaded for the
exporter before that test began. It performs no new conformance execution.

Open decisions beyond this slice: multi-identifier term naming, context/scope
semantics, multiple Association warrants for one atom, snapshot lifetime and
invalidation, any later planner vocabulary, and independent production runtime
acceptance. Interactive browser navigation and a full Nix application build
are not established by automated Inspector-reference tests.
