# Read-only CTM publication bootstrap through dreyeck.ch

Investigation/proposal only. No production route, service restart, SSH,
nginx/NixOS configuration, public executable endpoint or publication is made.
Baseline: HyperDoc `573fe37611a61d984260ebf43c797f7534211bdd`.
Topic Maps remains `88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`.

## Deployed observations, not source-code deductions

Read-only public probes on 2026-10-29 completed HTTPS proxy CONNECT (200):

| URL | Observed destination response | What follows |
| --- | --- | --- |
| `https://dreyeck.ch/` | HTTP 502; HTML body identifies nginx Bad Gateway | This request did not yield a usable Catalog or discovery page. It does not identify the installed revision or prove a global outage. |
| `https://dreyeck.ch/hyperdoc-project.ctm` | HTTP 404; plain `Not Found` | No CTM resource at this candidate URL in this observation. |
| `https://dreyeck.ch/hyperdoc-project.ctm.sha256` | HTTP 404; plain `Not Found` | No digest at this candidate URL in this observation. |

These are responses after the HTTPS tunnel, unlike a CONNECT policy refusal.
They do not prove that no other public CTM URL exists. No suitable resource or
deployed source revision was established; operator-supplied route/revision
evidence remains needed. HTTP response bodies are retained as evidence, not
executed or treated as instructions. Only these named candidates were probed.

## Source-grounded boundaries

- [Project Workspace export](../dreyeck/work/project/project-workspace.lisp),
  `%download`/`revision-export-octets`: the current download is a browser
  `data:application/octet-stream;base64,...` URL of the observed CTM octets.
  It is not an independently fetchable server CTM endpoint or a model writer.
- [Emitter](../dreyeck/work/project/project-ctm.lisp), `write-project-ctm`:
  CTM is generated offline from the four authoritative pages, with source SHA-256
  values in its header and a separate digest. A named file is not proof that
  the deployed HTTP service serves it.
- [HyperBook server](../hyperbook-server/server.lisp), `serve-catalog` and
  `add-path-to-hyperbook`: routes create Inspector windows for registered
  HyperBooks; declared assets have separate paths. No fixed project-CTM
  publication route is identified in this flow.
- [Local routes](../dreyeck/src/local-fedwiki-view.lisp) install `/view` and
  `/gesture`; [Catalog application](../dreyeck/src/catalog-application.lisp)
  loads a trusted startup selection, not an ASDF name supplied by this proposal's
  client. These interactive routes are not used as data endpoints here.
- [Package](../nix/catalog.nix) carries immutable source plus pinned Lisp and
  Topic Maps roots. [Startup adapter](../scripts/catalog-main.lisp) invokes
  [the startup guard](../dreyeck/src/catalog-topic-maps.lisp), which verifies
  the pin and refuses `dreyeck/work/project` and the page-attached loader.
  The proposal leaves that guard unchanged. Shipping bytes in a package
  neither installs a static publication route nor authorizes their release.
- [Operations note](../dreyeck/CATALOG-OPERATIONS.md): service and reverse-proxy
  configuration are operator-local. Historical deployments do not establish
  the live CTM route. Existing HTTP executable tests are application tests,
  not observations of this public URL.

## Smallest proposed publication contract

Publish three already validated, immutable files at an operator-approved
static namespace, for example:

```text
https://dreyeck.ch/project-data/revisions/<full-source-commit>/project.ctm
https://dreyeck.ch/project-data/revisions/<full-source-commit>/project.ctm.sha256
https://dreyeck.ch/project-data/revisions/<full-source-commit>/manifest.json
```

These URLs are proposed, not claimed to be deployed. The static server must
map only the selected files; no user path may become a filesystem path. GET
(and optional HEAD) needs no Lisp execution, generation, ASDF loading,
Project Workspace admission, arbitrary file access or response-supplied code.
The operator may serve an audited static artifact separately from the Catalog;
no change to the Catalog safety boundary is required. No production handler
is implemented in this slice. The loopback fixture is test infrastructure only.

The application manifest format is proposed as
`hyperdoc-project-ctm-snapshot-1`, containing the full HyperDoc source revision,
Topic Maps revision, fixed Document IRI, fixed CTM filename, SHA-256 of exact
CTM octets, and source-page paths/hashes. It is not an ISO serialization format.
Source revision means a commit containing those exact source pages/artifact;
dirty-source releases must not be mislabeled as reconstructible from a clean
commit. The digest covers octets before decoding or newline normalization.

Use `application/octet-stream` for CTM, consistent with the existing export;
this is not a claim of an ISO/IANA-specific CTM media type. The digest is
plain ASCII and the manifest JSON. Fixed immutable revisions can use immutable
caching and content-based ETags; a future latest-revision pointer would be
separate, auditable metadata, never an in-place rewrite of a published revision.

### Client verification and identities

1. Retrieve through normal verified HTTPS using the configured proxy and an
   approved host, with time/size limits and no cross-origin redirect surprise.
2. Require the expected manifest shape, filename, source/pin/Document IRI and
   an approved revision/digest anchor. An adjacent digest alone does not
   authenticate content: a server could change both files. Obtain the anchor
   from reviewed publication metadata or the approved Git artifact, not merely
   a self-consistent untrusted response.
3. Compare manifest digest, sidecar and SHA-256 of raw CTM bytes. Compare source
   page hashes against the named Git revision when available. Reject missing,
   oversized, mismatched or unexpected content before native reading.
4. Pass verified UTF-8 CTM to the fixed existing reader under Document IRI/base
   `tag:dreyeck.ch,2026:hyperdoc/project.ctm`. The retrieval URL is a location;
   it is not an Assignment, Evidence, Topic or source-page subject identifier.
5. Use no resource resolver or response-driven ASDF/system selection. CTM
   templates are data deserialization constructs, never Common Lisp READ/EVAL.
   Inspect native objects and compare CXTM to the pinned trusted artifact.

The loopback client's 2 MiB bound is an explicit review policy, not a CTM
normative limit. Public clients retain HTTPS verification and normal network
configuration; only the isolated loopback fixture bypasses an outbound proxy.

## Isolated local demonstration

The chosen fixture artifact is the previously verified, unmerged PR #1
revision `0484a4b76128c3ed302a6a8d6e0343bfe03cece5`, not the running deployment:

```text
dreyeck/work/project/hyperdoc-project.ctm
SHA256 8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d
```

Its known assignment is
`tag:dreyeck.ch,2026:hyperdoc/assignment/codex-2026-10-29-template-identity-substitution`.
Its ten stable evidence entries remain operator-supplied reports. Public
publication of this candidate has not been approved. The fixture extracts
this exact Git blob and verifies all source-page hashes against the same
commit before placing bytes in a fixed in-memory HTTP route table.

[HTTP/client fixture](../scripts/test-ctm-http-bootstrap.py) retrieves CTM,
sidecar and manifest over loopback HTTP. Missing resources, an incorrect
sidecar and unexpected content with a forged matching sidecar/manifest are
rejected against the trusted anchor before Lisp is called. The server never
generates CTM, maps requests to arbitrary files or runs request-supplied code.

[Native inspection](../scripts/inspect-http-project-ctm.lisp) uses existing
`ctm-revision-from-octets`, which calls `topic-maps.ctm:deserialize-string`,
and the native TMDM/CXTM operations. It checks the known assignment/type,
evidence reification, occurrence parent/type/value, inverse reifier identity,
source Associations and Roles, source-page path/hash, exact octet transport,
CXTM equivalence and unchanged-octet export. Expected CXTM is reconstructed
from the trusted local artifact at the same pin/Document IRI/base, not an
independent ISO conformance oracle. No TMDM-to-CTM serializer is asserted.

Run the fixture with the trusted local Lisp environment launcher:

```sh
python3 scripts/test-ctm-http-bootstrap.py --native-launcher /path/to/trusted-native-launcher.py
```

That launcher must load the fixed local inspection script, never code from
HTTP. Setup uses the already established matching SBCL loader/core and clean
disposable Topic Maps checkout; the user's Topic Maps repository is untouched.
The focused demonstration completed with process exit 0: the HTTP transport
and source identities passed, all three negative cases were rejected before
native reading, and **31 native assertions passed**. Reconstructed CXTM SHA-256:
`776145ba5cc30bdf6b699de245f2c0b5ffc08ebbe07d21b8ceb3a46695128f3f`.

[HTTP output](evidence/ctm-http-bootstrap/http-demo.log),
[native output](evidence/ctm-http-bootstrap/native.log),
[results/source hashes](evidence/ctm-http-bootstrap/results.json),
[manifest example](evidence/ctm-http-bootstrap/manifest-example.json), and
[exact environment launcher](evidence/ctm-http-bootstrap/native-launcher.py)
retain the evidence. Public headers/bodies are stored beside them as plain
text. Raw response headers and compiler logs retain their original CRLF and
trailing whitespace; they are evidence, not normalized source files. The
manifest example is the fixture's metadata format, not an observed
production manifest. This demonstration ran a fixed loopback test server,
not the packaged Catalog; it establishes no public routing, deployment or
browser acceptance result.

## Input for the ISO inventory, not a new authority

No public CTM snapshot was retrieved successfully from dreyeck.ch in this task;
therefore none of the local implementation assessments is attributed to live
public HyperDoc data. The PR #1 fixture contains the known investigation and
evidence, but not the inventory's proposed Standard/edition, Implementation,
Test-artifact or Normative Question concepts.

Independent Draft PR #2, inventory/design revision
`9cb805a877797d16df9a08f19e2acc882ade651e`, supplies those source-authoritative
**proposals** on Implementation Assignments and a separate reading. It does
not declare accepted Work or implement TMCL. Its derived CTM is another review
candidate, not automatically published data. A client must report absent
subjects against the retrieved revision rather than inventing them or treating
newly derived assessments as statements already published by HyperDoc.

## Explicit operator prerequisites; stop before production

1. Identify the actual public service/route configuration and deployed revision;
   resolve the observed root 502 and identify any existing CTM URL.
2. Select and approve the public content/revision. The review artifact contains
   executor reports, source paths and unresolved claims; approval of its public
   scope is separate from test success. If content must change, change its
   authoritative pages and review a new validated materialization, not a
   per-request or ad hoc filtered CTM.
3. Build and preserve a static publication bundle with exact CTM/digest/manifest,
   source hashes and the unchanged Topic Maps pin. Run offline verification.
4. Only the operator may install the fixed static route/TLS/caching configuration
   and perform any necessary service actions after authorization. Keep the
   Project Workspace/public execution refusal intact.
5. Verify the actual public bytes/digest/manifest and native read-back after
   approved publication; retain earlier immutable revisions and review later
   model changes as new revisions. Codex performs no automatic write-back.

No production change is authorized or performed by this bootstrap demonstration.
TMCL validation remains a separate unresolved implementation/design question.
