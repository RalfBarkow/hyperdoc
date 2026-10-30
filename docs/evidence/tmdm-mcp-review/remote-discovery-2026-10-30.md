# Remote MCP discovery — 2026-10-30

Endpoint: `https://mcp.dreyeck.ch/mcp`. Observed 05:01–05:02 Europe/Zurich
(UTC+01:00). Review baseline: Draft PR #4, commit
`4f137fb8db1d60f4a526cee986881407a3c09cbf`.
Machine-readable request/response summaries are retained in
[`remote-discovery-2026-10-30.json`](remote-discovery-2026-10-30.json).

## Observed transport and protocol results

The new environment's current, enforced restricted network policy explicitly
allows `mcp.dreyeck.ch`. This resolves the previous environment's CONNECT refusal.
All eight requests completed with curl exit 0, proxy CONNECT **200**, HTTP/2 and
TLS verification result **0**, through the inherited proxy and CA trust.
Redirects were not followed. The proxy-visible `Server: envoy` header does not
identify a deployed Lisp source revision.

| Request | HTTP status | MCP result |
| --- | --- | --- |
| GET `/mcp` | 405 | JSON error `method_not_allowed`; endpoint reachable |
| `initialize`, id 1 | 200 | Protocol `2025-03-26`, session header issued |
| `notifications/initialized` | 202 | Accepted; empty body |
| `resources/list`, id 2 | 200 | JSON-RPC error `-32099`, `Internal MCP server error` |
| `resources/templates/list`, id 3 | 200 | Two DMX templates returned |
| Retry: new `initialize`, id 1 | 200 | Same protocol, server and capabilities |
| Retry: initialized notification | 202 | Accepted |
| Retry: `resources/list`, id 2 | 200 | Same JSON-RPC error and body digest |

The initial request supplied client name `codex-readonly-discovery`, version `1`,
empty client capabilities and requested protocol `2025-03-26`. Subsequent POSTs
used the returned session header and negotiated `MCP-Protocol-Version` header.
Timeouts were 10 seconds for connection, 25 seconds per request, with a 2-MiB
response limit. Only the resource-list failure was retried, once in a new session.
No `resources/read`, tool discovery/call, evaluation or other model operation ran.

Advertised initialization result:

```json
{
  "protocolVersion": "2025-03-26",
  "capabilities": {"resources": {}, "tools": {}},
  "serverInfo": {"name": "hyperdoc-dmx-mcp", "version": "0.1.0"}
}
```

The complete successful template list contains:

| URI template | Name | MIME type |
| --- | --- | --- |
| `dmx://topic/{id}` | `topic/<id>` | `application/json` |
| `dmx://topicmap/{id}` | `topicmap/<id>` | `application/json` |

No credentials were explicitly supplied by the probe. No HTTP 401/403 or
`WWW-Authenticate` challenge was observed. Successful initialization and template
discovery establish access for this client path without a client-supplied bearer;
they do not prove the deployment's global authentication policy, Origin checks,
backend DMX authorization or write availability. Session values were used only
for protocol transport, never displayed or retained in the evidence.

`resources/list` failed at the JSON-RPC layer, despite HTTP 200. Both error
responses used JSON boolean `false` as their id instead of echoing request id 2;
a strict client may reject or fail to correlate such a response. An internal
`error.data.detail` field was present. Its full content was deliberately excluded
to avoid leaking internal information; only field names and fixed diagnostic
categories were retained on the retry. The underlying cause is not established.
This is not the earlier proxy CONNECT denial or an observed HTTP authentication
refusal. A hidden backend refusal cannot be excluded from the available evidence.

## What this establishes

The deployed endpoint advertises a DMX-oriented server and DMX resource
templates. DMX numeric topic/topicmap IDs remain distinct from ISO/IEC 13250
Subject Identifiers and the native TMDM model. No DMX resource content was read,
and no DMX tool or write contract was exercised.

No ISO/IEC 13250 template was advertised. No concrete resource URI can be reported
because `resources/list` returned no successful resource array. Therefore this
check does **not** establish that every fixed ISO resource is absent, or that
both representations are available. It establishes DMX discovery and no successful
ISO discovery. PR #4's isolated prototype was not expected to be deployed;
`serverInfo.version` is not a Git commit or deployment attestation.

## Comparison with PR #4's proposed contract

| Proposed contract | Remote observation | Gap for later integration |
| --- | --- | --- |
| Reachable HTTPS MCP transport and initialization | Successful | Earlier environment-policy blocker resolved for this task |
| Working concrete resource discovery | `resources/list` fails twice | Operator diagnosis of internal failure; restore successful resource listing without changing the DMX write contract |
| Versioned `hyperdoc-iso13250://snapshot/<sha256>/project.ctm` resource returning exact verified octets | Not discovered or read | Approve and publish an immutable, offline-verified snapshot through an explicit ISO resource dispatcher; no generation or evaluation in a request |
| Corresponding `manifest.json` with source revision, SHA-256, reader pin and established Document IRI | Not discovered or verified | Supply reviewed metadata and a client trust anchor, distinct from the running transport's version and retrieval URL |
| Native TMDM lookup `.../topic?si={si}` by stable Subject Identifier | Only DMX numeric-id templates advertised | Add a separate native TMDM read-only lookup; do not reinterpret DMX IDs or introduce another Topic Maps model |
| Resources-only capability profile | Both `resources` and `tools` advertised | Choose an isolated ISO profile/service or equivalent reviewed boundary; do not disable or alter existing DMX tools as a shortcut |
| Approved authentication, Origin and public-data policy | No challenge for these client requests | Operator decision and client-compatible security review; no write-authorization claim follows from successful discovery |
| Digest-verified remote CTM download, native read-back and same-base CXTM comparison | Not run; no CTM retrieved | Exercise these only after an approved ISO snapshot resource is available, retaining `tag:dreyeck.ch,2026:hyperdoc/project.ctm` as the established base |
| Attached Codex MCP resource access | Shell HTTP discovery succeeded; no HyperDoc MCP connector tools attached in this chat | Configure/approve a compatible client attachment and verify resource access there separately |

No protocol upgrade is justified merely by this check: the server accepted the
historical requested version. Broader MCP/client compatibility remains untested.
Nothing here changes the unresolved published-standard/TMCL questions in the
separate implementation inventory or creates new project declarations.

## Evidence boundary

Only this dated report, its redacted JSON summaries and a link from the existing
design are added. Earlier dated failure evidence and all prototype/source/test
files are preserved. HTTP summaries retain safe headers, body lengths/digests,
protocol results, template URIs and error categories; they omit authorization,
cookies, session values and full internal error details. Received content was
parsed as JSON data only, never evaluated or executed.

The previous **60 local prototype checks were not rerun** for this discovery
task. There was no remote CTM read-back, native-model inspection, CXTM comparison,
full corpus validation or claim of production readiness. Discovery evidence was
checked locally for request counts, statuses, capabilities, templates, session
redaction and consistency with the observed results.

No production configuration, service, NixOS file, Topic Maps pin, DMX contract,
Catalog boundary or other worktree was changed. No merge, deployment or restart.
The production code revision, internal list failure and public ISO publication
remain operator/integration questions.
