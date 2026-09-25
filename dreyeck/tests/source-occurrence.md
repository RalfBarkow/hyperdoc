# Exact observed source occurrences

An Operation Request preserves the selected code-page occurrence. It has no
executor. Gesture semantics and the ordinary button's separate pointer region
are unchanged.

The existing `lisp-code` parser result contains the complete source string;
`TOPLEVEL-FORM` contains its CST and package. Neither alone includes the owning
code page and FORM-KEY. Existing `cst-source-replacement-plan` adds proposed edit
and authoring information, `source-fragment-evidence` describes a Git blob by
line range, and `git-source-slice` describes Git materialization. None fits this
read-only Catalog observation.

`source-occurrence` therefore contains only page, FORM-KEY, source snapshot and
CST character range. `page-occurrences` obtains all ranges and the source string
from one parser result. The previous Operations row discarded the concrete
TOPLEVEL-FORM when it extracted only the key. Now its button closure and gesture
view receive the very same occurrence object. Surface routing still uses its
own transient target identity; that identity is not the request identity.

CST ranges are half-open **character offsets**, used with Common Lisp `subseq`.
The parser reads a string stream. The Unicode fixture (`äλ😀` before the forms)
checks the first DEFUN's range against a string search, and checks both extracted
forms. These are not encoded UTF-8 byte offsets.

Request registry equality is `EQUAL` over `(operation page form-key source range)`:
operation/page use EQ, source strings compare character-for-character, and keys
and ranges compare structurally. Distinct ranges yield distinct requests even
with identical keys. A fresh observation of unchanged source reaches the existing
request; the canonical request retains its first equivalent observation, not a
new CST identity. Snapshot changes yield new requests after re-observation.

`resolve-occurrence` first refuses snapshot mismatch with
`stale-source-occurrence` (`occurrence-status` reports `:stale-authority`). It then
parses the recorded snapshot, verifies range bounds, exactly one top-level form
at that range, and matching FORM-KEY. Missing files are stale. There is no search
by name, relocation, or offset adjustment. This is a point-in-time read-only
check, not a file lock or a promise against later concurrent writes.

Semantic definition identity, the address within an observation, and the
conditions under which the address remains valid are distinct. No Connect
provider/strategy/tier runtime types are introduced.

Existing page/key API callers remain supported only when a fresh observation
contains exactly one matching definition. Rendered button/gesture paths never
use that compatibility branch. The existing authoring planner checks occurrence
resolution before planning and derives its forms from the recorded snapshot;
it still refuses duplicate definition names and is absent from normal Catalog.
This slice does not implement occurrence-based insertion or execute a plan.

## Inspect the real RACE-READING request

In an mREPL started from this checkout's normal `nix develop` environment:

```lisp
(asdf:load-system "dreyeck/gesture/reading")
(defparameter *occurrence-page*
  (hyperbook:find-page
   (hyperbook:find-hyperbook "dreyeck/gesture/reading" :signal-error? t)
   "Reading the two continuations of one interaction." :signal-error? t))
(defparameter *race-occurrence*
  (find '(:definition dreyeck/gesture/ordering:race-reading)
        (dreyeck/gesture/operation-request:page-occurrences *occurrence-page*)
        :key #'dreyeck/gesture/operation-request:occurrence-form-key
        :test #'equal))
(defparameter *race-request*
  (dreyeck/gesture/operation-request:request-through-binding
   (dreyeck/gesture/operation-request:inspector-binding) *race-occurrence*))
(format t "~&~S ~S ~S~%"
        (type-of *race-request*)
        (dreyeck/gesture/operation-request:occurrence-status *race-occurrence*)
        (dreyeck/gesture/operation-request:occurrence-range *race-occurrence*))
(clog-moldable-inspector:clog-inspect :object *race-request*)
```

The Request view shows operation, FORM-KEY, page, character range, CURRENT or
STALE-AUTHORITY, and `Executed: no`. It shows only the selected source excerpt
while current, never the whole snapshot. The snapshot remains accessible through
`operation-request-occurrence` and `occurrence-source`.

## Replay the gates

```sh
nix develop --offline --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(dolist (s (list "dreyeck/gesture/operation-request/tests" "dreyeck/gesture/clog/tests" "dreyeck/gesture/transport/tests" "dreyeck/gesture-binding-witness/tests" "dreyeck/gesture/reading/tests")) (asdf:test-system s))' \
  --eval '(assert (null (find-package "DREYECK/WORKFLOW/AUTHORING")))'
nix develop --offline --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' --eval '(asdf:test-system "dreyeck/catalog/tests")' \
  --eval '(assert (null (find-package "DREYECK/WORKFLOW/AUTHORING")))'
nix develop .#workflow-authoring --offline --command sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/gesture/operation-request/authoring/tests")'
```

Request tests include real button/radial/mark EQ, shared row observations,
unchanged-source rerender, source-byte preservation, malformed range/key refusal,
duplicate DEFUNs, and stale/re-observe behavior. Scratch authorities are temporary
files; their forms are never evaluated.

Four process-local function mutations are restored with UNWIND-PROTECT:

- A drops range from the request key: duplicate-request distinction fails.
- B resolves by FORM-KEY: the second occurrence's value check fails.
- C bypasses freshness during resolution: stale-resolution refusal fails.
- D rereads the file for the snapshot: an instrumented parser changes the file
  immediately after parsing A; the single-observation test detects mixed A/B.

All four controls must print `OCCURRENCE-MUTATION-*-KILLED`.
