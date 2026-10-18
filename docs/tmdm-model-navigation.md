# TMDM model navigation — Slice 12B

This optional local Inspector adapter starts at HyperDoc commit
`aabbb983cbaaf713e7406856d853694c5166d5ef` (parent `44ebc23a934b6373b445d88f023332deeafd256c`,
tree `b428328b80864aed864e90889d075413fb4b7271`). It uses the unchanged, clean
Topic Maps Slice 12A commit `788899aea1a20b9cd8237c6106e6613e180d7362`.
No E3/Preview files from another worktree are included.

## Inspect the subjects

In the isolated development Catalog:

1. **Working on HyperDoc → Text pages → Work Breakdown → TMDM model**.
2. Follow the existing **ctm-plan-page-authoring** Work Topic, explicitly selecting
   **TMDM model** if arriving through another existing Work view.
3. **Read default-type example** or **Read explicit-type example** runs a DEFEXAMPLE
   and opens its actual Topic Map. This is an explicit local execution.
4. **Topics → Topic #topic → Topic Name "Name" → Type Topic**. The Name view
   also follows its actual Parent Topic. Every step is an Object Reference to
   the underlying Lisp object, not a copied HyperDoc Topic.
5. **Definitions → add-name → Source code** follows the loaded function;
   **Information-item class** follows the loaded class. Other reader/accessor
   functions and the ASDF system remain inspectable.
6. **Evidence → checked here … → Execution** follows the existing evaluation-record
   protocol to the original test contract, pinned Git CTM source, executed CXTM,
   unchanged baseline, dated model observation and runtime context.
7. **Existing Work Workspace** retains its independent native Point/History.
   Inspector Shift-navigation keeps earlier panes available.

There is no persistent URL for an individual generated Map/Topic/Name. Each
execution creates a new model and runtime-local record identity. Re-run the
DEFEXAMPLE to reproduce the path; do not equate objects from separate runs.

### Two observed model configurations

The views are generic; these original fixtures provide evidence, not view schemas.
Both use their existing deterministic Document IRI:
`https://ctm-tests.example.invalid/cd165b150176c1d6842b37be9cc9051b40d4996b/ctm/in/FILE`.

| Original source | Actual model relation |
| --- | --- |
| `name.ctm`: `topic` followed by `- "Name";.` | Map has two Topics. Owner II ends `name.ctm#topic`; Name Value is `Name`, Parent is EQ to owner, Type is EQ to the Topic whose SI is `http://psi.topicmaps.org/iso13250/model/topic-name`. |
| `name-type.ctm`: `topic` followed by `- nametype : "Name" .` | Map has two Topics. Owner II ends `name-type.ctm#topic`; Name Type is EQ to the Topic with II ending `name-type.ctm#nametype`. No default-type Topic is added. |

The **Topic** view separates Item Identifiers, Subject Identifiers and Subject
Locators. Default and explicit types are display labels over actual Topics.
Retained handles are resolved with public `canonical-topic` /
`canonical-topic-name`; the view exposes a link to the current representative.
No TMDM slots, identity, merge or canonicalization rules have changed.

## Evidence boundaries

- **Observed / checked here:** dated deserialization, actual Map references,
  generated CXTM octets, byte comparison and execution outcome. These are
  runtime-local results, not loaded historical PASS claims.
- **Stored evidence / not executed here:** the pinned Slice 12A execution JSON
  is a separate `git-file-at-commit`, as is the unchanged original baseline.
- **Derived interpretation:** the pinned typed-name reading document and
  its CTM §3.11, TMDM §5.4, CXTM §§3.6/4.7 references. These explain existing
  semantics; a normative claim is not inferred from a byte comparison.
- **Revision context:** observed Git HEAD/dirty state, adapter source hashes,
  Topic Maps revision, implementation/version, actual loaded functions and
  runtime identity. Matching ASDF checkout to loaded definitions is explicitly
  **inferred**. The library does not itself establish that its caller is fresh;
  the bootstrap/browser test starts a fresh process.
- **After mutation:** copied public-property observations retain the previous
  state. The original PASS/output remains dated, and Execution warns that the
  live model changed. Rendering does not re-execute the comparison. Model-level
  execution provenance is not an item-level source span: later-added items are
  not thereby attributed to the original CTM source.
- **Unknown provenance:** arbitrary programmatically created Maps/Topics/Names
  remain navigable. Their Evidence view says that no CTM execution is registered.
  A record for another Map cannot be bound as their execution.
- Known DateTime baseline disagreement remains **FAIL** when executed. It is
  neither concealed nor reclassified as a successful internal semantic test.

The only adapter record class implements the existing evaluation-record protocol.
No second Topic/Evidence model, public route, HyperBook or Topicmap is introduced.
The optional systems are not dependencies of the default Catalog/Nix application.
Local Inspector Slots/Operations/Playground remain available; this is not a public
redaction/security boundary. Existing publication restrictions, including inherited
Nested-Actions path evidence, remain open. There is no publication authorization.

## Reproduce in fresh processes

From this HyperDoc worktree, with the clean accepted Topic Maps checkout:

```sh
export TOPIC_MAPS_ROOT=/Users/rgb/workspace/topic-maps
nix develop .#tala --offline --command sbcl --noinform --no-sysinit --no-userinit \
  --non-interactive --load scripts/test-tmdm-model-regressions.lisp
```

The bootstrap ignores inherited mutable ASDF trees; it admits this worktree,
`TOPIC_MAPS_ROOT` and Nix-store dependencies from the development shell only.
Legacy Work regressions resolve existing public Wiki links read-only; the full
legacy run therefore uses network access. New adapter tests pass separately with
network access denied:

```sh
nix develop .#tala --offline --command sandbox-exec \
  -p '(version 1)(allow default)(deny network*)' \
  sbcl --noinform --no-sysinit --no-userinit --non-interactive \
  --load scripts/tmdm-model-bootstrap.lisp \
  --eval '(asdf:test-system "dreyeck/work/tmdm-reading/tests")'
```

Actual Catalog/browser navigation (supply installed Playwright and Chrome):

```sh
nix develop .#tala --offline --command sh -c '
  node scripts/test-tmdm-model-navigation.mjs "$(command -v sbcl)" \
    "$PLAYWRIGHT_DIRECTORY" "$CHROME" /tmp/tmdm-browser-evidence'
```

Only the fresh Lisp child is network-restricted to loopback; Chromium requires
its local Unix socket. Browser page requests outside the exact loopback origin
are blocked. The fixture route for retained handles exists only in this test.
Pane instrumentation checks actual EQ targets without replacing them.

For an interactive local review:

```sh
export HYPERDOC_TMDM_SITE_ROOT="$(mktemp -d /tmp/tmdm-review.XXXXXX)"
mkdir "$HYPERDOC_TMDM_SITE_ROOT/pages"
export HYPERDOC_TMDM_PORT=18772
nix develop .#tala --offline --command sbcl --noinform --no-sysinit --no-userinit \
  --script scripts/serve-tmdm-model-review.lisp
```

Open the printed loopback Catalog address and follow the path above. Stop this
fresh process when review is finished. No existing image, production process or
Wiki is contacted for writes.

The independent Topic Maps regression is unchanged:

```sh
cd "$TOPIC_MAPS_ROOT"
PYTHONDONTWRITEBYTECODE=1 TOPIC_MAPS_REPORT=/tmp/topic-maps-12b.json ./scripts/test.sh
```

Machine-readable validation and a redacted transcript accompany this document.
Raw local compiler/server logs are kept outside the repository. Their paths and
runtime object IDs are not published as subject addresses.
