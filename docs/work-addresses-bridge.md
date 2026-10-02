# Bounded Work addresses bridge

The relationship statement belongs to Work Breakdown. The foreign declaration
belongs to Deriving HyperDoc Authoring Constraints. This slice supports
`work:relation/addresses` from a Work item on the former Page to the exact
`serialized-verified-effect` Constraint on the latter, in the same registered
HyperBook. There is no generic cross-page relation/type system or new operation.

The addresses Relation Contract is declared and defined inline on Work Breakdown.
It describes intended Work scope; it does not assert satisfaction, deployment,
permission to change either authority, or evidence for the Work item.
The repository adds this contract only. Test/browser bridge statements are
installed exclusively in temporary copies of both authorities.

## Persisted wire

One qualified source entry is a relationship LI followed immediately, allowing
whitespace, by a separate data-only HTML comment:

```html
<li data-from="fedwiki-item-authoring" data-to="serialized-verified-effect" data-relation="work:relation/addresses" data-work-qualification="addresses-v1">FedWiki Item Authoring → Serialized verified effect: addresses.</li>
<!--work-addresses-warrant:v1:BASE64_OF_UTF8_JSON-->
```

The writer inserts a newline before the LI and between LI/comment. The comment
is outside the guarded statement, so its payload does not contain itself.
The JSON is canonicalized through the reader/writer round trip; malformed or
unknown qualification, duplicate qualification markers, orphan/missing comments,
unknown/missing fields and inconsistent recorded statements are source errors.
The JSON is never evaluated as Lisp.

The exact schema is:

```text
warrant = {
  version: "addresses-v1",
  coordinates: "utf-8/decoded-character/half-open/v1",
  owner: authority,
  source: observation(kind="work item"),
  target: observation(kind="constraint"),
  contract: observation(kind="relation"),
  statement: {range: [start,end], text: exact_statement_LI},
  from: source_Topic_ID,
  to: "serialized-verified-effect",
  relation: "work:relation/addresses"
}
authority = {book: registered_HyperBook_ID,
             page: exact_Page_ID,
             file: canonical_source_file_namestring}
observation = {authority: authority,
               anchor: [start,end], anchorText: exact_Topic_anchor,
               scope: [start,end], scopeText: exact_containing_declaration_LI,
               topic: recorded_Topic_ID, kind: recorded_authored_kind}
```

All JSON keys are case-sensitive strings. Ranges are zero-based half-open
**decoded-character** coordinates, not UTF-8 byte offsets. Scope includes the
source Work item's explanatory text, all target Constraint facets, and the
bounded contract definition respectively. No historical full Page strings or
whole-source digests are stored. Topic IDs are consistency fields, not addresses.

## Freshness versus currentness

`addresses-creation-request`, a subclass of the existing relationship request,
retains its original registered selection, exact snapshot-bound endpoint
occurrences and the complete owner/foreign Page read set. Planning and execution
revalidate every complete snapshot. `%replace-source` retains the existing
owner check and calls the qualified mode's final read-set check just before
rename. The executor remains the existing `execute-work-relationship-creation`
under the same pinned authoring environment. Post-install mismatch yields
`:unverified`; it never rolls the source back blindly.

`resolve-addresses-bridge` is a distinct durable-currentness resolver.
`resolve-work-topic-occurrence` is unchanged. The new resolver verifies the
registered authority/file mapping, reads fresh source, compares each recorded
range/text, validates scanner/DOM boundaries and uniqueness, and checks roles
and fields against those exact occurrences. It then creates fresh ordinary
snapshot-bound occurrences; old request occurrences remain stale.

There is no Topic-ID or label search to repair failed observations, nor carrier
fallback. An unrelated equal-width edit or append after all guards may leave a
bridge current. Changed declarations/facets/contract/statement, shifted ranges,
remapped authorities or invalid source structure cannot yield its current edge.
This remains optimistic source checking, not an atomic multi-file transaction.

## Projections and inspection

`project-work-breakdown` classifies qualified entries before local endpoint
validation. Ordinary local rows retain their original representation and
meaning. The local graph exposes qualified records in its `:qualified-bridges`
view metadata, without foreign Associations or foreign-source reads to validate
them. Valid stale records remain inspectable; malformed qualification refuses
with `addresses-qualification-error` instead of downgrading to a local row.

`evidence-neighborhood` adds current qualified Associations and exact foreign
Topics, then follows the foreign Page's existing `evidenced-by` statement to the
existing milestone and Git commit object. The first neighborhood has:

```text
fedwiki-item-authoring -- work:relation/addresses --> serialized-verified-effect
serialized-verified-effect -- work:relation/evidenced-by --> milestone/m0-page-edit
milestone/m0-page-edit -- object / Git provenance --> bb8bf21f4a1a0cd998b12feafbe19ec5819fe037
```

No new Claim,
Finding, milestone class or SOURCE-EVIDENCE relation is introduced. Contributions
are validated before publication; same IDs from different observed declarations
are not silently merged. Stale/unavailable bridge results are inspection metadata
and publish no cross-edge. Source-format errors remain explicit diagnostics.

The `Qualified addresses bridge` Inspector view separates statement authority,
source, target, contract and statement observations, currentness and stale reason.
The complete request additionally exposes its full `Addresses read set`.

## Human path and launch

From this branch/revision, use the existing isolated authoring demo:

```sh
nix develop path:.#workflow-authoring -c sbcl \
  --noinform --no-userinit --script scripts/work-editor-human-demo.lisp
```

Open `http://127.0.0.1:18091/`. It registers a complete temporary HyperBook and
copies both Pages. Enter in the terminal stops the server and removes the fixture.
No D2/TALA environment is required.

1. In Topicmap, click **FedWiki Item Authoring** to make it Point.
2. **Open Work Topic** → **Work Operations** → **Create relationship**.
3. **Inspect foreign Constraint: Serialized verified effect**.
4. In **Inspected foreign target**, inspect the exact **Serialized verified effect**
   Topic or its foreign Workspace; choose **Use inspected target**.
5. **Use relation: addresses** opens the complete request. Inspect **Addresses read
   set**, then **Work request** → **Preview plan**.
6. **Work plan** → **Execute request after revalidation** returns a fresh local
   Workspace with the source Point retained.
7. **Work Breakdown** → **Inspect Evidence neighborhood** → **Qualified bridges**
   → **Inspect qualified addresses bridge**. Its **Qualified addresses bridge**
   view shows the separate authorities/observations and currentness.

To append independent B, make **Structural HyperDoc Page Authoring** Point in
that fresh local Workspace and repeat steps 2–7. Both bridge warrants remain
current; the shared Constraint/milestone are one pair of exact observations.
Returning to the old pre-effect selection cannot offer an executable addresses
relation, and attempting its old complete request refuses full-snapshot freshness.

The explicit browser regression uses the same fixture and real CLOG/DOM events:

```sh
nix develop path:.#workflow-authoring -c sbcl \
  --noinform --no-userinit --script scripts/work-addresses-browser-witness.lisp
```

Open `http://127.0.0.1:18092/` when it prints LISTENING. Synthetic browser clicks
exercise A, B, record inspection and stale refusal. The runner prints
`LIVE-ADDRESSES-WITNESS-PASS`, then stops/removes its fixture after 30 seconds.
Run this witness separately from the boundary suite, whose HyperSpec HTTP test
also uses port 18092.

## Verification commands

```sh
nix develop path:.#workflow-authoring -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/work/authoring/tests")'

nix develop path:.#tala -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/topicmap/tests")' \
  --eval '(asdf:test-system "dreyeck/work/reading/tests")' \
  --eval '(asdf:test-system "dreyeck/catalog-application/tests")'

sh scripts/check-upstream-boundary.sh
```

The existing reading/layout regressions intentionally use `.#tala`; this does not make TALA a dependency of Work authoring. Normal
Catalog startup remains non-authoring and has no persistent Work executor.
