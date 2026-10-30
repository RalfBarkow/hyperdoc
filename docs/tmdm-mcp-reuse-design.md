# Read-only ISO Topic Maps resources through the historical HyperDoc MCP transport

Review date: 2026-10-29. Working branch: `codex/tmdm-mcp-readonly-design`.
Current production-source comparison base: `573fe37611a61d984260ebf43c797f7534211bdd`
(`dreyeck.ch`). Historical source: `591f275fc26ebef7967cc8d3e3fb5a0efc19cc85`
(`hauptsache`). No historical merge or cherry-pick was performed.

The HTTP/session boundary is reusable. Its DMX dispatcher is not an ISO Topic
Maps reader. A small, separate read-only adapter can return a verified CTM
snapshot and inspect the native TMDM objects obtained by reading that snapshot.
The isolated prototype below demonstrates that seam; it is not installed in any
ASDF system, Catalog, release package or public service.

## Source comparison

The seven requested historical files were inspected at the exact historical
commit. None of those seven paths exists in the current comparison base.
Current `hyperdoc.asd` has no `hyperdoc/mcp` or `hyperdoc/dmx-import` system.
Historical [`hyperdoc.asd` lines 541ff](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/hyperdoc.asd#L541)
loads `hyperdoc/dmx-import` before the MCP file. Loading that old system wholesale
would introduce the wrong dependency and write surface for this task.

| Historical source | Existing behavior | Smallest reusable part / required adaptation |
| --- | --- | --- |
| [`hyperdoc/mcp-server.lisp`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/hyperdoc/mcp-server.lisp) | Hunchentoot JSON POST `/mcp`, initialization/session headers, optional bearer and Origin checks; DMX resources and typed write tools in the same file | JSON object/array and RPC response helpers (79–90, 146–182), auth/Origin checks (189–220), request accessors (229–240), session lookup (259–270). Separate server state from DMX clients. Adapt initialization, endpoint and dispatcher; do not copy capabilities or `tools/call`. |
| [`.codex/config.toml`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/.codex/config.toml) | `mcp_servers.dmx-context-window.url` points to `https://mcp.dreyeck.ch/mcp` | URL configuration is a client attachment candidate, not evidence of a working attachment or an ISO resource. Use a distinct ISO resource namespace/profile. No connector configuration was changed. |
| [`tests/dmx-mcp-smoke.lisp`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/tests/dmx-mcp-smoke.lisp#L717) | HTTP JSON helper, initialization, initialized notification and resource-list/read assertions; broad DMX fixture and write tests | Reuse the sequence at 717–855 and the response/header assertions. Replace only the fixture and expected resource contract for the new adapter. Do not run live DMX write tests as an ISO conformance check. |
| [`nix/modules/hyperdoc-mcp-release.nix`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/nix/modules/hyperdoc-mcp-release.nix) | Separate service/user/data directory, loopback binding, optional credential environment files, reverse proxy and TLS integration; live writes default false | Packaging/service separation is useful later. A dedicated read-only package must omit DMX clients and credentials. Operator-owned configuration is a separate authorization step. No Nix files changed. |
| [`nix/integration/dreyeck-hyperdoc-mcp-sidecar.nix`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/nix/integration/dreyeck-hyperdoc-mcp-sidecar.nix) | Temporary recovery bridge, mutable checkout import, **live writes true**, DMX base URL/workspace ids | Not a safe read-only deployment template. Historical file contents do not establish the running host's settings. |
| [`DMX MCP server for shared workspace.html`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/hyperdoc/DMX%20MCP%20server%20for%20shared%20workspace.html) | Human reading path for a guarded DMX read/write context window and typed journal-aware tools | Retain its separation of typed operations and raw backend access. Its historical live-test report is not a fresh observation of today's service. |
| [`Add HyperDoc MCP beside the authoritative host config on dreyeck.ch.html`](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/hyperdoc/Add%20HyperDoc%20MCP%20beside%20the%20authoritative%20host%20config%20on%20dreyeck.ch.html) | Corrects an earlier whole-host activation boundary: `/etc/nixos` remains authoritative; host-owned pinned sidecar copies; existing certificate reuse | Preserve this operator boundary. Repository configuration and source do not authorize activation or prove the deployed configuration. |

DMX's numeric `dmx://topic/907120`, workspace/topicmap IDs, layout and backend
JSON are DMX contracts. They are not TMDM Subject Identifiers, ISO Associations,
Roles or Occurrences. This design performs no DMX-to-TMDM conversion and does not
change the DMX write contract.

Current ISO seams are already present in
[`project-ctm.lisp`](../dreyeck/work/project/project-ctm.lisp) and
[`project-workspace.lisp`](../dreyeck/work/project/project-workspace.lisp):
offline generation from authoritative pages, retained CTM octets and SHA-256,
`topic-maps/ctm` deserialization, native `topic-maps/tmdm` queries and same-base
CXTM comparison. The public adapter needs only the core reader/model systems at
startup. It must not make `dreyeck/work/project` executable through the public
Catalog or weaken [`catalog-topic-maps.lisp`](../dreyeck/src/catalog-topic-maps.lisp).

## Actual public-service observation

**Dated follow-up, 2026-10-30:** the new environment now reaches the endpoint.
Initialization and DMX template discovery succeed; concrete resource listing
returns an internal MCP error. See the [remote discovery evidence](evidence/tmdm-mcp-review/remote-discovery-2026-10-30.md).
The observations below retain the earlier 2026-10-29 state.

Both a GET and an MCP `initialize` POST were attempted against exactly
`https://mcp.dreyeck.ch/mcp`, through the configured HTTPS proxy with normal TLS
verification and no bearer credentials. The POST requested protocol `2025-03-26`
with an empty client capability object. Both attempts returned curl exit **56**:
`CONNECT tunnel failed, response 403`; `proxy_connect=403`, `origin_http=000`.
The response header identifies the proxy as `envoy`. This is a tunnel refusal
before an origin HTTP exchange, not evidence of a remote MCP HTTP 403.

The current managed-environment status reports enforced restricted networking,
current observations, `dreyeck.ch` allowed and `mcp.dreyeck.ch` absent from the
effective host list. No proxy bypass was attempted. No HyperDoc/DMX connector or
resource-discovery tool is attached to this chat; the old repository config
alone cannot make one available here.

| Stage | Result |
| --- | --- |
| Network reachability from this task | Blocked at proxy CONNECT 403 |
| MCP initialization | POST attempted; origin not reached |
| Advertised capabilities | Unknown for running public service |
| Resource discovery and successful data retrieval | Not established |
| Deployed code revision, bearer configuration, live-write gate | Unknown |

Raw header evidence is retained under `docs/evidence/tmdm-mcp-review/`; it contains
no credentials. Allowing the exact subdomain through the supported environment
configuration is a prerequisite to a new live probe. A subsequent origin 401/403
would be a separate authorization result. After access is available, use
initialize → initialized notification → resources/list and templates/list →
resources/read. Record the server's negotiated version/capabilities first; do
not call any tools to test connectivity. Actual Codex connector attachment and
resource availability still need an integration check after HTTP succeeds.

## Minimal read-only resource contract

Serve a reviewed immutable snapshot, rather than generating CTM in a request.
At process startup verify the artifact against a digest/revision anchored in
the reviewed release, load it once with `topic-maps/ctm`, and retain native TMDM
handles. Supply no external-resource resolver. Requests do not load ASDF systems,
evaluate Lisp, resolve arbitrary URLs, read filenames or mutate the graph.

Proposed application resource URIs (not new Topic identifiers):

* `hyperdoc-iso13250://snapshot/<sha256>/project.ctm`: exact CTM octets as an MCP
  base64 `blob`, MIME `application/octet-stream` (matching the existing octet
  export; no invented registered CTM media type).
* `hyperdoc-iso13250://snapshot/<sha256>/manifest.json`: source revision, CTM
  SHA-256, pinned Topic Maps revision, established Document IRI and CTM resource
  URI; optional canonical CXTM digest tied to that base and reader revision.
* `hyperdoc-iso13250://snapshot/<sha256>/topic?si={si}`: read-only native inspection
  by a percent-encoded stable Subject Identifier. The prototype precomputes exact
  resource keys for all existing SIs, avoiding substring matching, filesystem
  paths and double decoding. Unknown identifiers/resources return an error.

The manifest is application metadata, not a new Topic Maps representation.
The Topic response is a bounded inspection projection: native identity, names,
typed occurrences, reified occurrence, incident associations and role players.
It is not a complete TMDM serialization (for example name variants and every
construct's item identifiers are not projected). CTM remains the exchange
artifact. Scope/type/datatype and canonical Topic references are read through
the existing TMDM operations; no second graph is stored.

The HTTPS retrieval endpoint, MCP resource URI, established Document/base IRI
`tag:dreyeck.ch,2026:hyperdoc/project.ctm`, and each Topic's Subject Identifier have
different purposes. Never substitute the MCP or HTTPS URL as the CTM base.
The client verifies exact MIME, size and SHA-256 before invoking the CTM reader;
it checks the source revision against its reviewed manifest/release anchor.
A hash supplied by the same untrusted response is insufficient authentication.
Read-back uses the established base, and CXTM is compared at that same base.

Use a dedicated resources-only profile/process initially: capabilities contain
`resources`, with no `tools`, prompts, subscriptions or evaluation methods.
Adding resources to the existing DMX server is an alternative only after
reviewing its actual deployed authorization and write exposure. Merely setting
the historical live-write flag false would still advertise DMX tools. Do not
change their existing contract as a shortcut.

## Authorization review and remaining hardening

Historical bearer auth is optional and checks all HTTP requests if configured,
despite the Nix option's wording about guarded writes. No configured token means
no bearer check. A missing Origin is allowed; an empty Origin allowlist also
allows any supplied Origin. Origin checks are not user authorization.
`dmx-mcp-live-write-available-p` (878ff) requires the flag and a memory client or
HTTP client with a base URL; the source explicitly does **not** require DMX auth
headers there. This is weaker than a prose claim that credentials are always a
hard prerequisite. Backend authorization is a separate boundary.

The prototype requires a nonempty ephemeral bearer, binds literally to loopback,
uses an explicit Origin allowlist, cryptographic random session IDs, a 16-session
cap and 16-KiB declared request limit, and redacts internal error details. It
contains no DMX read/write client. The historical random IDs, permissive default
constructor, unconditional tool capabilities, numeric/substring URI dispatcher
and generic error-detail disclosure are deliberately not reused.

Public readiness still requires a client-compatible authentication decision
(anonymous reviewed public data versus authenticated access; bearer helper alone
does not establish an OAuth authorization implementation), Host/Origin policy,
session expiry/concurrency and per-client limits, timeouts, rate limits, log and
secret handling, strict protocol/header/content-type negotiation and tested body
limits at the HTTP server/proxy. The prototype deliberately requires Content-Length
and tests a bounded JSON POST subset, not complete MCP conformance or Codex
connector compatibility. Public resource selection also needs review for paths,
evidence text, provenance and other information-disclosure risks. Snapshot text
is untrusted project data, never instructions to execute or authority to publish.

## Isolated demonstration and evidence

[`scripts/review-tmdm-mcp.lisp`](../scripts/review-tmdm-mcp.lisp) copies only fourteen
small historical transport/helper definitions with prefix/accessor renaming;
the selected section is marked in source. New initialization/resource dispatch
is confined to the review package. No historical system/default constructor,
DMX fixture, write dispatcher or production entrypoint is loaded.

[`scripts/test-tmdm-mcp-review.py`](../scripts/test-tmdm-mcp-review.py) launches a
fresh isolated Lisp process through the retained environment launcher, retrieves
resources over loopback HTTP, and inspects the known Implementation Assignment
and all ten identified Evidence topics. This is an authorized fresh-process
fixture, not an observation of an operator's SLY image or production service.

Fixture source is the verified PR #1 revision
`0484a4b76128c3ed302a6a8d6e0343bfe03cece5`; it is a review candidate, not a claim
that PR #1 is merged or deployed. Reader pin remains
`88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`. CTM SHA-256:
`8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d`.
Same-base CXTM SHA-256:
`776145ba5cc30bdf6b699de245f2c0b5ffc08ebbe07d21b8ceb3a46695128f3f`.

Run from the repository root (launcher paths are environment evidence, not
production setup requirements):

```sh
python scripts/test-tmdm-mcp-review.py \
  --launcher /workspace/scratch/tmdm-mcp-review/launcher.py \
  --artifacts /workspace/scratch/tmdm-mcp-review
```

Result: **60 focused checks PASS, process exit 0**. Covered initialization,
resources-only capability/list/template/read, missing/wrong bearer, Origin,
missing/unknown/deleted sessions, malformed/oversized requests, unknown version,
fixed CTM bytes and anchored manifest; both source associations and their role
players; ten reification/owner/type links and Operator-report attribution;
source-page path/hash. Missing/file/DMX/unknown-SI resources and all tested tool,
evaluation and subscription calls are rejected. Wrong digest, MIME and unexpected
executable-looking content are rejected by the client before the native reader.
Retrieved bytes then pass native CTM read-back, byte equivalence and expected
same-base CXTM; the original map's CXTM remains unchanged after resource requests.

An initial prototype run stopped after four passing checks because the new
request guard used Hunchentoot's *response* Content-Length accessor. Source review
located the correct incoming-header boundary; only that guard was corrected,
and the same expectations passed on rerun. No production change or expected
output adjustment was made. The initial failure log is retained separately.
There was no full corpus, legacy DMX smoke suite, public MCP success or deployment
test. The harmless Ironclad redefinition warning is visible in the native log.

The inventory remains a separate derived assessment. This PR #1 snapshot has
the project assignment/evidence model, not the additional Standards, edition,
Implementation/Test/Run or Normative Question declarations proposed in inventory
Draft PR #2. Report these as absent; introduce any later declarations through
reviewed authoritative pages and regenerate offline. Neither the lookup nor
the inventory invents Topics, accepted Work or Acceptance Records. TMCL is not
required by this transport prototype.

## Operator decisions before any production change

1. Approve the specific source/artifact revision for publication; PR #1's verified
   review snapshot is not automatically a production release. Keep snapshot
   revision, reader pin, transport code revision and deployed revision distinct.
2. Choose a resources-only service/profile and URL, authentication/public-data
   policy, and whether any shared process with DMX is acceptable. Keep existing
   DMX writes and credentials isolated unless separately authorized.
3. Grant the exact public MCP hostname in the task environment and attach the
   client/connector with the approved authorization. Repeat live initialization,
   capability discovery and a digest-verified resource read.
4. Review/package the adapter and immutable artifacts, then have the operator
   approve host-owned service/proxy configuration, security hardening and an
   activation/rollback plan. Preserve the Catalog admission guard and Topic Maps
   pin. No SSH, restart, active NixOS edit, deployment, merge or production publication was
   performed for this investigation.

## Pre-commit verification for the draft PR

Revalidated on 2026-10-29 from branch `codex/tmdm-mcp-readonly-design`, starting
HEAD `573fe37611a61d984260ebf43c797f7534211bdd`. No applicable `AGENTS.md` was
found in repository ancestors or the affected directories. The existing slice
contained ten new files and 930 lines before this verification note. Prototype,
focused-test and launcher contents were preserved; no features were added.

The focused command above was rerun using the checked-in review launcher path
`docs/evidence/tmdm-mcp-review/launcher.py` with the same artifact directory:
**60 checks PASS, exit 0**, including native read-back and unchanged same-base
CXTM. The retained focused/native logs and result JSON reflect this rerun.
All seven historical source hashes and the fourteen copied helper definitions
were also verified against the exact historical Git commit. No public MCP
request was repeated; `public-probes.json` retains the earlier dated observation.

The configured fetch branch and GitHub default branch both identify `dreyeck.ch`
as the PR target; its remote HEAD was confirmed unchanged at the starting HEAD.
The slice remains an isolated review prototype, with the production limitations
and operator decisions above still open. No other worktree was changed.
