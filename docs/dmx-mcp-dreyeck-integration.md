# DMX MCP integration into dreyeck.ch

Review slice, 2026-10-30, following [PR #5's downstream integration comment](https://github.com/RalfBarkow/hyperdoc/pull/5#issuecomment-6515647691).

The observed target HEAD was `573fe37611a61d984260ebf43c797f7534211bdd`.
The integration branch is `codex/dmx-mcp-dreyeck-integration`, based directly on
that commit. The source evidence is the verified repair
`f512aa847eab05cc2bdf2e78ef0bd1b516a11926`, whose historical base is
`591f275fc26ebef7967cc8d3e3fb5a0efc19cc85`. This is a source port, not a merge of
`hauptsache`. Draft PRs #4 and #5 are unchanged.

## Independent runtime and retained contract

`(asdf:load-system "hyperdoc/mcp")` loads the target's small HyperDoc/HyperBook
base, the required DMX definitions and Hunchentoot. `hyperdoc/dmx-import` is an
opt-in runtime subsystem. Neither depends on the Inspector, Explorer, FedWiki
systems, Catalog server, or ISO Topic Maps. The application is
`scripts/dmx-mcp-main.lisp`; Nix exposes `hyperdoc-dmx-mcp` and
`checks.<system>.dmx-mcp` using the existing flake.lock. No Topic Maps pin or
production Catalog expression changes.

The eight files under `dmx-mcp/` retain the reachable HTTP client, memory client,
validation, notes, ownership, assignment, annotation-continuation, snippet and
journal definitions needed by the existing tools. Annotation continuation and
journal/restore tools account for much of this closure: dropping them would
change the write contract. UI methods, historical application startup, FedWiki
import/materialization workflows and unrelated page constructors are omitted.
Historical names such as `fedwiki-dmx-import-error` remain the existing condition
identities; their names do not imply loading a FedWiki implementation.

The 2026-10-30 scope correction keeps the Journal as a separate investigation
Topic and [subsequent work item #7](https://github.com/RalfBarkow/hyperdoc/issues/7).
Retaining dependencies and passing fixture regressions do not demonstrate
functional Journal correctness. No Journal repair, redesign, migration, Topic
inventory or cleanup is part of PR #6. The bounded
[launcher state assessment](dmx-mcp-state-boundary.md) documents potential output
redirection, cold-process ignorance of persisted streams and later same-subject
file replacement; it neither changes those behaviors nor observes production data.

[The source manifest](dmx-mcp-source-manifest.json) records original UTF-8 file
hashes and character spans for 644 retained source forms. Each form has a source
location comment. `python scripts/check-dmx-mcp-source.py` audits those spans
against the locally available repair Git object, without downloads. There are
three bounded runtime adaptations in addition to file relocation and extraction:

* Other DMX runtime users of the formerly external `json-array-elements` use the
  privately owned `dmx-runtime-array-elements`, retaining its exact semantics.
  MCP itself keeps the repair's separate `dmx-mcp-array-elements` unchanged.
* `plan-topic-factory-snippet-dmx-write` accepts an explicit
  `topic-definition-chunk` through `dmx-mcp-require-snippet-definition`.
  The MCP caller always constructs this DTO from validated arguments. The old
  generic Lisp API's NIL/pathname fallback into a FedWiki example is deliberately
  outside this application. No MCP argument, default, URI or payload changes.
* The pure `workspace-annotation-render-value` formatter is made available in
  the runtime namespace; historically it was only defined in
  `hyperdoc-explorer/dom-annotations.lisp`, despite runtime references. A forward
  special declaration preserves the annotation topicmap variable's initialization
  in its owning file.

The repaired MCP definitions are retained unchanged. Resource identities remain
`dmx://workspace/context-window`, `dmx://topicmap/<id>` and `dmx://topic/<id>`.
Discovery validates one member-list response, merges configured identities,
deduplicates and excludes journal artifacts. It performs one topicmap GET and
zero per-Topic GETs. Optional titles/content remain on-demand. A listed configured
identity can subsequently be absent or unauthorized. Invalid payloads and backend
401/403/503 responses are bounded errors; unexpected errors retain the request id
without public condition details. The original missing-helper failure still
reproduces with its exact recorded 214-byte response fingerprint when explicitly
loading the historical server in a fresh control process.

The tools/list response SHA-256 remains
`fcb41ea1be5db385ad58060fd45e2dcf0158dc0fb507b6d537029ebd5b9dc85d`.
Bearer checks, Origin policy, sessions, tool schemas, dry-run defaults, ownership,
canonical long-form view properties, explicit backend authentication modes and
live-write gates are unchanged. The new application launcher requires an explicit DMX base URL and existing
absolute state directory and binds only to loopback. It never enables writes
implicitly. The historical optional-bearer contract is retained in both the
library and launcher: a configured token is enforced; an absent token does not
add an authentication requirement. The confirmed migration target is intentional
public Common Workspace use for topicmap `919822`, with
`HYPERDOC_MCP_ENABLE_LIVE_WRITES=1`, the existing listener/Origin and state root
preserved. Do not introduce mandatory bearer authentication or disable production
writes as a substitute for this migration. The generic false default is unchanged;
`0` is used only for the isolated, synthetic rehearsal described in the runbook.

## Running and focused verification

With the declared dependencies in ASDF's registry:

```sh
sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
  --script scripts/dmx-mcp-main.lisp --check
python scripts/check-dmx-mcp-source.py
python scripts/test-dmx-mcp-resource-discovery.py --original --artifacts /tmp/dmx-original
python scripts/test-dmx-mcp-resource-discovery.py --artifacts /tmp/dmx-repaired
sbcl --noinform --no-sysinit --no-userinit --disable-debugger \
  --script scripts/test-dmx-mcp-contracts.lisp
nix build .#hyperdoc-dmx-mcp .#checks.x86_64-linux.dmx-mcp
```

The historical-control/source-audit commands require the source Git objects;
fetch the reviewed repair/base commits explicitly if they are not present.
The application and Nix checks need neither Git history nor a running DMX service.
The Nix check runs the application --check, all 72 repaired discovery checks,
16 checks through the actual packaged executable (eight with a configured bearer
and eight with the historical optional-bearer configuration), and 11 retained historical
contract groups against memory/synthetic/local HTTP backends. Contract groups
cover HTTP content type, delete/remove endpoints, workspace assignment, explicit
Basic login bootstrap, MCP initialization/read/dry-run/write rejection, owned
snippet/topic lifecycle, local journals, foreign-topic ownership, assignment
repair/nonrecursive journaling and bounded HTTP error surfaces.

The retained test fixture uses the exact historical snippet octets as inert text
under `tests/fixtures/`; it never loads or evaluates that snippet. Journal fixtures
use a fresh global store visible to request threads, with file writes disabled.
Thread-local dynamic bindings alone do not isolate Hunchentoot worker threads.
Two Explorer-dependent annotation fixture workflows and the historical localhost
rehearsal fixture are not included or claimed executed. Existing continuation
code and guards remain preserved; exhaustive legacy workflow coverage is not claimed.
In particular, the memory-seeded Journal fixtures with file writes disabled do
not establish persisted-state recovery, Journal functional correctness, or actual
production Common Workspace write capability. This scope correction changes only
documentation: prior verification results stay attributed to `e15e36f...`; the
regression suite and Nix builds are not repeated without a relevant code change.

The separate coexistence check requires clean checkouts, without modifying either:

```sh
python scripts/test-dmx-iso-mcp-coexistence.py \
  --iso-root /path/to/hyperdoc-at-521a1f38 \
  --topic-maps-root /path/to/topic-maps-at-88994c1b \
  --artifacts /tmp/dmx-iso-coexistence
```

It starts independent DMX and unmodified PR #4 ISO processes. A local DMX note
references stable Subject Identifier
`tag:dreyeck.ch,2026:hyperdoc/assignment/codex-2026-10-29-template-identity-substitution`,
naming both fixture authority `local-dmx-fixture-v1` and ISO snapshot source
`0484a4b76128c3ed302a6a8d6e0343bfe03cece5`. The client inspects the native ISO
identity, source Association and Evidence reification; cross-service URIs are
refused. DMX backend failure does not interrupt ISO lookup. No conversion,
synchronization or write-back occurs. The received CTM's native read-back and
CXTM comparison use the established document/base
`tag:dreyeck.ch,2026:hyperdoc/project.ctm` and reader
`88994c1b9e1edbf13e665e984a5c9c3b2cdf7575`. CTM SHA-256:
`8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d`;
CXTM SHA-256:
`776145ba5cc30bdf6b699de245f2c0b5ffc08ebbe07d21b8ceb3a46695128f3f`.

Credential-free results are filed under `reports/dmx-mcp-dreyeck-integration/`.
Private fixture server/session logs are excluded. These are fresh isolated
process results, not evidence from a live SLY image or the production backend.

## Nix evidence and operational limits

The real Nix package and check derivations were built, tested and rebuilt with
`--rebuild` on x86_64-linux; both output comparisons passed. They used Nix 2.20.6
in an isolated Debian container with the cached Nix store mounted at `/nix`.
The container used the session proxy and CA trust; dependencies were fetched
successfully from cache.nixos.org. This avoids the earlier portable wrapper's
`/proc/self/setgroups` failure. Nix sandboxing was disabled inside this container;
this is an actual local package/check build, not a NixOS VM or host activation.
The pinned Debian image is
`debian:bookworm-slim@sha256:99c0b25c46d0214d5a2091092e7908907dcaecd6a962cde0ac700acee222b6f3`.
Nixpkgs remains the target lock's
`50ab793786d9de88ee30ec4e4c24fb4236fc2674`.

`sbcl.withPackages` prefixes colon-form ASDF registry/output settings. The launcher
therefore supplies compatible path pairs, not a parenthesized translation form
that would become invalid after prefixing. Dependencies keep their packaged FASLs;
application FASLs go to the process cache, outside the immutable source store.
No environment-specific absolute workspace launcher paths enter the application.

This preserves the historical server's exposure limitations: no new explicit
Host allowlist, body/depth bounds, session expiry/cap or stalled-response-body
timeout is introduced here. Existing Origin handling accepts requests without an
Origin; the operator must retain the existing TLS/vhost boundary and assess
capacity/timeouts before replacement. Bearer authentication is not a per-subject
ACL: resource templates and read tools retain their existing numeric-id scope.
Session identifiers and detailed backend conditions remain private diagnostics.
Existing structured write-tool diagnostics are preserved rather than redesigned.
This integration is not a general public-exposure hardening claim.

The installed production package, source revision, active host configuration and
available host disk space are **unknown** until operator evidence is supplied.
The public MCP name/version and matching error fingerprint cannot attest them.
No replacement is recommended or authorized on that evidence alone. Follow the
[operator deployment and rollback procedure](dmx-mcp-operator-runbook.md), including
identification of the existing package before choosing any replacement.
