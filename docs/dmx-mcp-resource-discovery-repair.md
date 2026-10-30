# DMX MCP resource discovery repair and separate ISO MCP coexistence

Reference/contract note, 2026-10-30. Source baseline and PR target:
`hauptsache`, `591f275fc26ebef7967cc8d3e3fb5a0efc19cc85`.
This is the branch that contains the DMX implementation; no historical code is
merged into `dreyeck.ch` or Draft PR #4. The running service's Git revision is
**unknown**: no operator-supplied package/source/deployment record was provided.
`hyperdoc-dmx-mcp` version `0.1.0` is not a source attestation.

## Expectation, observed failure and causal evidence

Expectation: a freshly loaded `hyperdoc/mcp` can list its workspace resources
after initialization. The recorded remote service accepted initialization and
template listing but returned HTTP 200 / JSON-RPC -32099 / `id:false` for list
request 2. This is a disappointed expectation at the ASDF/resource boundary,
not evidence that DMX objects should be interpreted as ISO TMDM objects.

The original source is reproducibly broken in a fresh process:

1. `hyperdoc/mcp` depends on `hyperdoc/dmx-import` and Hunchentoot. That closure
   does not load `hyperdoc/fedwiki`'s `collective-knowledge-slice.lisp`, which owns
   the unqualified `json-array-elements` helper used by MCP.
2. `dmx-mcp-resource-list` calls `dmx-mcp-known-topic-ids`.
3. The real HTTP client GETs `/topicmaps/1?children=true` from a valid local backend.
4. `dmx-mcp-known-topic-ids` calls the unbound `HYPERDOC::JSON-ARRAY-ELEMENTS`.
5. The endpoint catches that undefined-function error, substitutes NIL for the
   request id, and exposes `(princ-to-string condition)` in `error.data.detail`.
   The existing JSON encoder renders NIL as false.

The fresh local historical server produces **exactly 214 response octets**, SHA-256
`4c3cbe31dd2b9f4c489472d172fa90f11e9f144871f1a90f339caa2cbc415df0`.
This equals both retained remote list-error fingerprints in PR #4. The exception
reproduction and complete response fingerprint are confirmed; source attribution
of the running deployment to commit `591f275...` remains unverified. A different
build could carry the same defective code. The backend's full production payload
and its behavior after this exception is removed are also unverified.

Synthetic malformed JSON or wrong-shaped payloads can produce other failures,
but they are not presented as the cause of this matching observed exception.
Loading the unrelated FedWiki helper into a large image can mask the cold-load
defect; the focused test deliberately starts a fresh minimal MCP image.

## Bounded repair

Only `hyperdoc/mcp-server.lisp` changes production Lisp behavior:

* MCP owns a namespaced `dmx-mcp-array-elements` coercion helper with the existing
  helper's semantics. Six MCP references use it, including existing argument
  array conversions. This removes the accidental load dependency without adding
  the broad FedWiki system or changing any write-tool argument contract.
* Discovery validates the backend topicmap object and its Topic-id array, merges
  member ids with configured ids and preserves existing URI identities. A true
  null client can advertise configured identities; HTTP false/blank/null/scalar
  or malformed responses are not mistaken for that client.
* Discovery performs **one topicmap GET, zero per-Topic GETs**. Optional titles
  are no longer fetched while listing. Names remain `topic/<id>`; data and titles
  remain available on demand through `resources/read`. A configured URI can be
  stale or unauthorized: listing is not a promise that a later read succeeds.
* Resource reads validate returned Topic identity. Backend HTTP refusals, malformed
  discovery data and connection failures retain the request id and return bounded
  errors. Resource error responses exclude backend bodies, URLs and private
  condition details. The HTTP layer and JSON-RPC outcome remain distinct.
* The endpoint retains parsed request ids for unexpected and typed errors.
  Unrecoverable/missing ids are JSON null. Unexpected public errors no longer
  contain `error.data.detail`; internal logging stays on the private server log.

The DMX importer/HTTP layer, resource identities, authentication/origin checks,
live-write gate, typed tool schemas and guarded-write behavior are preserved.
The complete `tools/list` response has identical SHA-256 before and after:
`fcb41ea1be5db385ad58060fd45e2dcf0158dc0fb507b6d537029ebd5b9dc85d`.
Guarded write function bodies differ only in references to the equivalent MCP
array helper. Negative tests prove missing bearer is refused and a valid bearer
cannot bypass disabled live writes. Existing canonical dry-run validation still
works, short keys are still refused, and the local backend receives no writes.
Existing structured write-tool diagnostics are not redesigned by this repair.

## Local tests and independent coexistence

Final results: **8 historical-control checks, 72 repair checks and 20 independent
two-server checks passed**, all process exits 0. The memory-only source/metadata
construction replay also passed; interactive SLY/CLOG inspection was not executed.
Exact results, source hashes and credential-free client logs are under
`reports/dmx-mcp-resource-discovery/`. Run from this worktree with its declared
dependencies on the ASDF registry and SBCL/Python 3 available:

```sh
python scripts/test-dmx-mcp-resource-discovery.py --original --artifacts /tmp/dmx-original
python scripts/test-dmx-mcp-resource-discovery.py --artifacts /tmp/dmx-repaired
python scripts/test-dmx-iso-mcp-coexistence.py \
  --iso-root /path/to/clean-hyperdoc-at-521a1f3 \
  --topic-maps-root /path/to/clean-topic-maps-at-88994c1b \
  --artifacts /tmp/mcp-coexistence
```

The original control loads the historical server source from its Git object;
it does not reset or modify the worktree. The repaired suite uses the real DMX
HTTP client against a loopback fixture. It covers valid/duplicate/empty/stale
identities; malformed JSON/HTML/scalars/arrays/false/null/blank/missing fields;
Topic absence and wrong returned identity; backend 401/403/503 and refused
connections; id correlation/privacy; and preserved write gates/dry runs. The
client timeout exceeds the importer's unchanged 20-second connect timeout.
This is not a general guarantee for stalled backend response bodies; review
existing transport timeouts operationally before exposure.

The independent integration starts **two processes** plus a local DMX backend:

* The repaired DMX server owns numeric Topic id 7 and note URI
  `hyperdoc:mcp/workspace-note/local-iso-reference`, from authority
  `local-dmx-fixture-v1`.
* The separate ISO server is the byte-identical prototype from PR #4 commit
  `521a1f38ffe40edf02f8c3d6faae2c373ad150c1`. Its snapshot source is
  `0484a4b76128c3ed302a6a8d6e0343bfe03cece5`, reader pin
  `88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`, CTM SHA-256
  `8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d`.

The fixture note's text references stable Subject Identifier
`tag:dreyeck.ch,2026:hyperdoc/assignment/codex-2026-10-29-template-identity-substitution`
and explicitly names the ISO snapshot revision alongside its own fixture
authority. The client follows that reference using the ISO resource template;
it does not translate DMX id 7 or merge the two subjects. Native Associations,
source references and Evidence reification remain in the ISO model. The client
checks CTM octets; the ISO process checks native read-back and same-base CXTM
SHA-256 `776145ba5cc30bdf6b699de245f2c0b5ffc08ebbe07d21b8ceb3a46695128f3f`
at `tag:dreyeck.ch,2026:hyperdoc/project.ctm`. The ISO service still works after
the DMX backend stops. There is no synchronization or write-back.

No public DMX resource content, tool or production configuration was accessed
for this repair. No Topic Maps source/pin, PR #4 source, active NixOS configuration,
or deployment changed. Earlier prepared ISO application work is outside this PR.

## Validation environment and limits

The repository's requested Nix development-shell attempt failed before evaluation:
`error: opening file '/proc/self/setgroups': Read-only file system`. This is an
environment failure, not a passing Nix result. The local tests use cached Nix
Lisp dependencies with SBCL 2.4.10. The historical inspector source was fetched at
its exact flake.lock commit `5816eaaf445f0f9dbae67cf07d7706b4fb678b3b` and patched
with the repository's hash-guarded overlay routine in a disposable dependency
directory. No production Lisp was changed to compensate for that environment.

Two initial harness assumptions were corrected against existing source: the Topic
GET includes `assocChildren=true`, and valid view props require all four existing
long-form fields. Neither HTTP query nor write validation was relaxed. No corpus
expectation was changed. Broader historical load warnings/unexercised workflows
are not claimed repaired. No full test suite, live write, browser, production
read-back or authoritative Nix build/VM activation is claimed.

## Operator-controlled deployment proposal (not executed)

1. Obtain the running service's package path, source/build revision and configuration
   provenance from the operator, without exposing secrets. Compare it to this
   historical baseline; port/version strings alone are insufficient.
2. Review/rebase the bounded patch onto that actual source if necessary. Build
   with the matching pinned Nix inputs and run these local tests plus applicable
   guarded-write regressions and timeout/authentication checks in staging.
3. Stage a separate loopback DMX candidate and the independently reviewed ISO
   resource application. Keep source authorities, credentials, models and write
   gates separate. Approve any ISO snapshot revision/publication independently.
4. Only the operator may authorize replacing the existing service package and
   restarting it through the host-owned configuration. Do not import an entire
   repository host profile, enable writes, add a public endpoint or change pins
   as a repair shortcut.
5. After an explicitly authorized activation, perform read-only initialize/list/
   read checks, confirm ids/private error boundaries, monitor private diagnostics
   and retain the prior package for rollback. No automatic publication or sync.

HyperDoc reading path: the updated reference page “DMX MCP server for shared
workspace” links this evidence and provides a memory-only SLY inspection form.
Lisp delta: the server boundary plus focused test fixtures. FedWiki delta: none;
no localhost wiki or production path was edited. The replay commands above and
the source-backed inspection form reconstruct the result without a live backend.
