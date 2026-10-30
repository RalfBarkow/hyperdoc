# Operator-controlled DMX MCP candidate deployment and rollback

**Proposal only. No command below has been run on dreyeck.ch.** No SSH, active
NixOS edit, service restart, reverse-proxy change or activation is part of this
review. The current installed package/revision and host disk capacity remain
unverified. Establish them before recommending a replacement.

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
  systemd.services.hyperdoc-mcp.serviceConfig.ExecStart =
    lib.mkForce "${candidate}/bin/hyperdoc-dmx-mcp";
  systemd.services.hyperdoc-mcp.environment.HYPERDOC_MCP_STATE_DIRECTORY =
    "/VERIFIED/EXISTING/WRITABLE/JOURNAL/DIRECTORY";
}
```

Do not install this example blindly or import mutable repository modules into
`/etc/nixos`. Resolve option conflicts against the actual host-owned configuration.
Use the existing service account/group and file permissions. The launcher binds
127.0.0.1 only, accepts `HYPERDOC_MCP_PORT`, and requires a bearer token, explicit
`HYPERDOC_DMX_IMPORT_BASE_URL` and an existing absolute state directory. Supply
bearer/backend credentials through the existing operator-owned secret environment
files, outside the Nix store. It retains all existing backend authentication modes.
No token value belongs in a Nix expression, commit, command-line argument or PR.
The old bearer-less configuration, if observed, needs an explicit operator/client
migration decision before this fail-closed launcher can replace it.

Preserve actual workspace IDs, origins, backend authentication and DMX ownership
rules. Never set `enableLiveWrites = true` merely because a historical example did.
The application defaults to false; retaining an already authorized live-write
setting is an operator decision requiring comparison with the captured contract.
Keep the existing nginx/TLS/vhost/path and production Catalog untouched. The
package does not carry or activate any service or reverse-proxy module.

Evaluate and build the proposed host configuration without switching. Review its
diff: only the MCP package/ExecStart, necessary cache/state wiring and explicitly
agreed values may change. Unexpected Catalog, proxy, firewall or other service
changes block cutover. Back up journals with ownership/permissions preserved;
choose their established location or an explicitly reviewed migration/copy. Never
point the new journal directory into `/nix/store` or silently discard prior data.

## 3. Authorized rehearsal, cutover and observation

A rehearsal process under the service account on a free loopback port (for
example 8788), using a copied/synthetic backend and isolated state, needs separate
operator authorization. Keep live writes off. Initialize, notify initialized,
list templates/resources and read a known local fixture Topic. Confirm missing
bearer and disallowed Origin are rejected and that resource errors retain ids
without backend body/condition leakage. Keep credentials/session IDs private.
No production tool invocation or writes are required for readiness.

Before any public replacement, explicitly assess inherited limitations: no
application Host allowlist, global bearer rather than per-subject ACLs, requests
without Origin, unbounded session accumulation, request/body/depth limits and
backend stalled-body timeouts. Preserve the existing proxy safety boundary;
required hardening beyond it is a separate reviewed change. This slice does not
silently disable guards or claim these limits are solved.

**Only after separate operator authorization**, apply the reviewed host-owned
configuration through its established NixOS procedure. Activation may restart the
MCP unit; it must not restart/change the production Catalog. New clients must
initialize new sessions after replacement. Public readiness checks use HTTPS,
MCP initialize/initialized, resources/templates/list, then resources/list with a
unique request id. Listing should require one backend topicmap read and no Topic
prefetch; stale configured identities do not guarantee successful subsequent reads.
An explicitly authorized known-resource read can establish read-back. Do not run
write tools as an incidental readiness probe.

Monitor unit state, restart count, private journald/backend diagnostics, request
latency, backend HTTP statuses, bounded JSON-RPC errors, journal persistence and
`df` capacity. Record package/source identity alongside observations. Automatic
write enablement, Topic synchronization and ISO service deployment are excluded.

## 4. Rollback

Rollback triggers include startup/restart loops, repeated list/read failures,
authentication/origin regressions, changed tool schemas/resource identities,
journal access errors, or capacity pressure.

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
