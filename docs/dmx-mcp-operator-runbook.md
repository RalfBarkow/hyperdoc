# Operator-controlled DMX MCP candidate deployment and rollback

**Proposal only. No command below has been run on dreyeck.ch.** No SSH, active
NixOS edit, service restart, reverse-proxy change or activation is part of this
review. The current installed package/revision and host disk capacity remain
unverified. Establish them before recommending a replacement.

## Confirmed migration contract and separate Journal work

The scope correction of 2026-10-30 confirms an intentionally public Common
Workspace. Preserve the following production requirements; this is not an
instruction to change the running service:

| Boundary | Required preserved value |
| --- | --- |
| DMX workspace topicmap / sharing | `919822` / Common, publicly readable and writable |
| Live writes | `HYPERDOC_MCP_ENABLE_LIVE_WRITES=1` |
| MCP listener | `127.0.0.1:8787` |
| Allowed Origin | `https://mcp.dreyeck.ch` |
| Service state root | `/var/lib/hyperdoc/mcp`, with existing data and permissions preserved |
| Bearer policy | No newly mandatory bearer authentication |

The numeric IDs, listener, Origin, state-root path and enabled-write setting
are already documented in the public
[historical sidecar](https://github.com/RalfBarkow/hyperdoc/blob/591f275fc26ebef7967cc8d3e3fb5a0efc19cc85/nix/integration/dreyeck-hyperdoc-mcp-sidecar.nix).
That source documents configuration, not the installed package's identity. The
scope correction supplies the intended migration contract; no fresh production
probe is claimed here. A directory's aggregate size is neither Journal size nor
available disk capacity. No additional private operator measurements are needed
in this public runbook.

Common sharing and enabled writes are intentional. Preserve existing MCP
resource identities, tool schemas, validation, ownership checks and backend
authentication behavior. An Origin allowlist is not user authentication. Token
absence does not remove the existing tool validations. Do not make the migration
appear successful by disabling Common Workspace writes or requiring a new bearer.

Journal dependencies stay only where the existing MCP contract requires them.
Their retention and existing fixture tests do **not** establish functional Journal
correctness. Journal diagnosis, repair, redesign, data migration and any cleanup
of Journal-related DMX Topics belong to the separate investigation Topic and
[subsequent work item #7](https://github.com/RalfBarkow/hyperdoc/issues/7).
Do not invoke Journal inventory, repair, restore or cleanup tools as migration
readiness checks. PR #4's ISO TMDM service remains separate and read-only.

## 1. Identify and retain the currently running release

On the host, the operator should capture these read-only facts privately, then
supply a redacted record containing no tokens, cookies, Authorization headers or
complete process environments. First confirm the actual unit name; the historical
module's default `hyperdoc-mcp.service` is only a candidate name.

```sh
systemctl show hyperdoc-mcp.service \
  -p FragmentPath -p ExecStart -p User -p Group -p WorkingDirectory -p MainPID
readlink -f /run/current-system
nixos-version
uname -m
df -h /nix /var
df -i /nix /var
```

Resolve the executable's package root from the actual ExecStart and inspect its
wrapper/source symlinks locally. The process executable may identify only SBCL;
it does not by itself identify the application revision. If this is the historical
release layout, inspect **that installed package's**
`share/hyperdoc/release.json`: it records `git_revision`, `source_path`,
`flake_lock_sha256` and release id. Compare with the unit's startup journal lines
`HyperDoc MCP revision:` and the installed source; record the store root, deriver
and its NAR hash. Do not substitute a checkout's HEAD for the installed revision.
If the metadata is absent or inconsistent, obtain the original build record and
hash the installed Lisp sources; mark the Git attribution unresolved meanwhile.

The historical source at `591f275...` includes these metadata paths and
`nix/modules/hyperdoc-mcp-release.nix`, but is **not proof** they are deployed.
Likewise the public `hyperdoc-dmx-mcp` version `0.1.0` is not a Git attestation.

Privately compare the authoritative `/etc/nixos` import path and host-owned
sidecar/module copies. Record their revision/digests and redacted values for the
service user/group, loopback address/port, workspace/topicmap IDs, backend URL,
allowed origins, environment-file *paths*, live-write setting, state/journal path
and existing nginx `/mcp` route/TLS host. Never publish the environment-file values.
Identify where the old image actually persists journals; its ASDF source-relative
default must not be confused with the unit's WorkingDirectory.

### State-path boundary: a startup check is not recovery proof

Use the [source-grounded state assessment](dmx-mcp-state-boundary.md) before
planning any cutover. `HYPERDOC_MCP_STATE_DIRECTORY` names the local Journal JSON
directory directly, not the entire service state tree. Do not set it to the
service state root by assumption, create an empty replacement, or copy the whole
state tree into it. Determine the installed release's actual resolved Journal
directory, any extra initialization, canonical directory identity, ownership,
permissions and relationship to other state. Obtain the evidence privately.

The candidate checks only that the supplied path is absolute and an existing
directory. Startup assigns it without moving, copying, deleting or loading
Journal files. It does not reject a different existing directory. The fresh
process's local Journal reads use an initially empty memory table, not prior
files; a later retained write uses a per-subject filename with `:supersede`.
Consequently a wrong path can silently redirect future output, existing files
can remain invisible to reads, and a same-named file can later be replaced.
Ordinary workspace-write hooks can reach this sink even without a Journal-tool
call. A successful initialize/list/read or matching pathname proves neither
recovery nor preservation of history.

This is a source finding about the candidate, not a production-data observation
or a diagnosis of the entire Journal feature. Do not implement hydration,
change sinks, suppress Journal hooks, move/copy data or clean up DMX Topics in
PR #6. If state preservation cannot be established, keep the candidate
unactivated and record the unresolved boundary in #7. Do not resolve that hold
by silently ignoring old state or changing the confirmed public-write contract.

Before builds, estimate the candidate closure with `nix build --dry-run` and
`nix path-info -S` on a prepared package. Compare bytes and inodes with free `/nix`
and `/var`, temporary build space, current journal size and retained rollback
closure. No automatic garbage collection or deletion of the previous release.
Prefer building off-host and transferring a verified closure when host capacity
is insufficient. Local review disk availability does not establish host capacity.

## 2. Prepare an exact candidate, without activation

Use the approved **integration commit SHA**, not a moving branch or the repair
commit as a substitute for the target-branch port. Keep the target flake.lock and
Topic Maps pin unchanged. Build the package and focused check on the host's
architecture (x86_64-linux is the architecture tested in this review):

```sh
nix build --no-link --print-out-paths \
  'github:RalfBarkow/hyperdoc/APPROVED_INTEGRATION_SHA#hyperdoc-dmx-mcp' \
  'github:RalfBarkow/hyperdoc/APPROVED_INTEGRATION_SHA#checks.x86_64-linux.dmx-mcp'
```

Record the resulting application/check store paths, derivations and NAR hashes.
Run the candidate's `bin/hyperdoc-dmx-mcp --version` and `--check`; the version
must name the approved integration revision and repair source `f512aa8...`.
Protect both previous and candidate closures from GC using operator-owned roots
before any authorized cutover. Retain the previous host configuration and unit
ExecStart together with its exact old package. The reviewed branch is a candidate,
not an instruction to replace an unidentified service.

The executable name changes from the historical
`bin/hyperdoc-mcp-release-start` to `bin/hyperdoc-dmx-mcp`. Merely changing the old
module's `package` option would produce a nonexistent ExecStart. If the captured
host-owned module matches the historical `services.hyperdocMcp` contract, prepare
an operator-owned override along these lines, with the **observed** unit name,
architecture and verified journal directory substituted:

```nix
{ lib, pkgs, ... }:
let
  candidateFlake = builtins.getFlake
    "github:RalfBarkow/hyperdoc/APPROVED_INTEGRATION_SHA";
  candidate = candidateFlake.packages.${pkgs.system}.hyperdoc-dmx-mcp;
in {
  # The existing host-owned module continues to own user, environment files,
  # backend/workspace, allowed origins, write flag and the existing proxy route.
  services.hyperdocMcp.package = candidate;
  services.hyperdocMcp.workspaceTopicmapId = 919822;
  services.hyperdocMcp.enableLiveWrites = true; # Preserve the confirmed Common contract.
  services.hyperdocMcp.bindAddress = "127.0.0.1";
  services.hyperdocMcp.port = 8787;
  services.hyperdocMcp.allowedOrigins = [ "https://mcp.dreyeck.ch" ];
  services.hyperdocMcp.dataDir = "/var/lib/hyperdoc/mcp"; # Existing root, not a new Journal store.
  systemd.services.hyperdoc-mcp.serviceConfig.ExecStart =
    lib.mkForce "${candidate}/bin/hyperdoc-dmx-mcp";
  systemd.services.hyperdoc-mcp.environment.HYPERDOC_MCP_STATE_DIRECTORY =
    "/VERIFIED/EXISTING/WRITABLE/JOURNAL/DIRECTORY";
}
```

Do not install this example blindly or import mutable repository modules into
`/etc/nixos`. Resolve option conflicts against the actual host-owned configuration.
Use the existing service account/group and file permissions. The launcher binds
127.0.0.1 only, accepts `HYPERDOC_MCP_PORT`, and requires an explicit
`HYPERDOC_DMX_IMPORT_BASE_URL` and an existing absolute state directory. Supply
bearer/backend credentials through the existing operator-owned secret environment
files, outside the Nix store. It retains all existing backend authentication modes.
No token value belongs in a Nix expression, commit, command-line argument or PR.
Bearer authentication remains optional exactly as in the existing server. A
configured token is enforced. Preserve the intentional public Common Workspace
policy; do not introduce a token requirement or create a bearer secret as part
of this migration. Making bearer authentication mandatory would be a separate
contract change, not an acceptance condition for PR #6.

Preserve actual workspace IDs, origins, backend authentication and DMX ownership
rules. Preserve the explicitly confirmed production live-write value `1`. The
library's false default is unchanged; omitting the production environment setting
would disable intended functionality. `0` belongs to the isolated rehearsal
below, not to the production migration's target state.
Keep the existing nginx/TLS/vhost/path and production Catalog untouched. The
package does not carry or activate any service or reverse-proxy module.

Evaluate and build the proposed host configuration without switching. Review its
diff: only the MCP package/ExecStart, necessary cache/state wiring and explicitly
agreed values may change. Unexpected Catalog, proxy, firewall or other service
changes block cutover. Preserve existing state and permissions; record unresolved
path/recovery risks without migrating or copying Journal data. Never point the
new Journal directory into `/nix/store`, assume an empty store is equivalent, or
silently discard prior data. Separate Journal work may block a later activation;
it must not be absorbed into this contract-preserving port.

## 3. Authorized rehearsal, cutover and observation

A rehearsal process under the service account on a free loopback port (for
example 8788), using a synthetic backend and disposable fixture state, needs
separate operator authorization. Use `HYPERDOC_MCP_ENABLE_LIVE_WRITES=0` for this
isolated rehearsal and no production backend credentials or copied production
state. Initialize, notify initialized, list templates/resources and read a local
fixture Topic. Preserve optional-bearer behavior: absent bearer remains allowed;
if a test token is configured, missing/incorrect bearer is refused. Check the
existing Origin and error-id/privacy rules. Keep session IDs private. This
read-only rehearsal does not prove production Common Workspace write capability
or Journal correctness. PR #6 already has focused fixture regressions; do not
repeat the whole suite for this documentation-only scope correction.

Before any public replacement, explicitly assess inherited limitations: no
application Host allowlist, global bearer rather than per-subject ACLs, requests
without Origin, unbounded session accumulation, request/body/depth limits and
backend stalled-body timeouts. Preserve the existing proxy safety boundary;
required hardening beyond it is a separate reviewed change. These considerations
do not reopen the confirmed public-write/bearer policy as a migration decision.
This slice does not disable guards or claim these limits are solved.

**Only after separate operator authorization**, apply the reviewed host-owned
configuration through its established NixOS procedure. Activation may restart the
MCP unit; it must not restart/change the production Catalog. New clients must
initialize new sessions after replacement. Public readiness checks use HTTPS,
MCP initialize/initialized, resources/templates/list, then resources/list with a
unique request id. Listing should require one backend topicmap read and no Topic
prefetch; stale configured identities do not guarantee successful subsequent reads.
An explicitly authorized known-resource read can establish read-back. Separately
check that the configured Common Workspace contract still specifies topicmap
`919822` and live writes `1`; initialize/discovery success is not write proof.

A real production write probe, if later requested, needs separate explicit
operator authorization, a designated non-Journal test object, bounded effects
and a reviewed reversal plan that accounts for retained Journal side effects.
It is not authorized by this runbook or performed by PR #6. Do not replace this
check with Journal creation, restore or cleanup, and do not report production
write capability as verified merely because fixture tests passed.

Monitor unit state, restart count, private journald/backend diagnostics, request
latency, backend HTTP statuses, bounded JSON-RPC errors, state-directory access
errors and `df` capacity. Record package/source identity alongside observations;
do not label those observations a Journal-correctness result. Preserve the
confirmed live-write configuration; Topic synchronization, Journal cleanup and
ISO service deployment are excluded.

## 4. Rollback

Rollback triggers include startup/restart loops, repeated list/read failures,
authentication/origin regressions, changed tool schemas/resource identities,
journal access errors, or capacity pressure.
Accidentally changing `HYPERDOC_MCP_ENABLE_LIVE_WRITES` to `0`, requiring a new
bearer, or redirecting/ignoring established state are also rollback triggers.

The operator restores the captured **MCP-only** package pin, original ExecStart
(including its old executable name), environment/state wiring and matching
host-owned configuration, then builds/reviews and applies that rollback under
operator authorization. Keep other currently authorized host/Catalog changes;
do not blindly roll the whole machine back to an older generation. Retained old
store paths/GC roots and configuration evidence make this possible without a
network rebuild. Use the host's established recovery procedure if activation
itself fails, under operator control.

Reinitialize a client and repeat the transport/auth checks. The old discovery
defect may return; rollback restores the captured previous service, not the repair.
Preserve new diagnostics and journal backups. If authorized writes occurred
between cutover and rollback, do not overwrite journals or DMX data from an older
backup automatically; reconcile separately with the operator. No automatic
backend rollback, synchronization or write-back is provided.
