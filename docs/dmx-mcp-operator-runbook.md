# Operator-controlled DMX MCP integration and rollback

**Preparation only: no production commands have been executed.** The operator
owns approval, host configuration, cutover and rollback. This PR neither activates
NixOS configuration nor changes the public MCP connector automatically.

## Confirmed contract and explicit new journal epoch

The operator decision of 2026-10-30 supersedes the former requirement to import
old local journal histories. Start the candidate with an explicitly newly
initialized, empty journal directory. Preserve all old directories, files,
ownership and permissions in place as a fallback. This is initialization of a
new journal epoch, not a migration or deletion of old history.

| Boundary | Required value |
| --- | --- |
| Common workspace topicmap | `919822`, publicly readable and writable |
| Live writes | `HYPERDOC_MCP_ENABLE_LIVE_WRITES=1` |
| Listener / Origin | `127.0.0.1:8787` / `https://mcp.dreyeck.ch` |
| Existing service state root | `/var/lib/hyperdoc/mcp`, preserved |
| New journal directory | Explicit, new, empty, writable absolute directory, separate from all old stores |
| Bearer / backend authentication | Existing policy; no newly mandatory bearer |

For example, the operator may approve
`/var/lib/hyperdoc/mcp/journal-epoch-20261030-pr6/` only after establishing that it
has never been used and cannot alias an old store. Do not reuse a populated path,
truncate a directory to make it empty, copy old journals into it, or repoint any
old path/symlink. A pre-existing candidate path is a reason to stop and choose a
new one, not to delete its contents. The launcher deliberately does not create,
empty or migrate the configured directory automatically.

The Issue #7 repair restores and validates journals created under this new epoch
on subsequent starts. Reads restore persisted subjects; writes append revisions;
unchanged writes preserve file bytes. Invalid/unreadable files produce explicit
errors. See [repair/replay notes](dmx-journal-restart-repair.md). Choosing an empty
new directory does not disable journaling or remove restart persistence.

## 1. Private operator prerequisites

Confirm the actual service name (historically `hyperdoc-mcp.service`), installed
package/source identity, ExecStart, service uid/gid, host architecture, state paths,
backend URL/authentication, Origin and live-write configuration. The checkout's
HEAD and historical sidecar configuration do not identify the installed release.
Capture environment-file paths, never credential values, in the review record.
Resolve the old journal location separately from WorkingDirectory and the service
state root. Do not publish journal contents or complete process environments.

The operator privately checks free bytes/inodes on `/nix` and `/var`, temporary
build capacity, candidate closure size and retained rollback closures. Local cloud
build capacity is not host capacity. Keep both the old package and host-owned
configuration protected from GC. No automatic garbage collection or state cleanup.

Record the new directory's canonical identity and ensure it does not equal,
alias or replace any old journal directory. Have the operator create it exactly
once, under the existing service uid/gid and appropriate private permissions,
verify emptiness and service-account read/write access, then record the epoch
boundary. Do not recursively change ownership or permissions of the old state
root. No old Journal contents need be read or copied for this cutover.

## 2. Pin and build the approved integration commit

Use the exact integration commit approved from PR #6, not a moving branch:

```sh
nix build --no-link --print-out-paths \
  'github:RalfBarkow/hyperdoc/APPROVED_INTEGRATION_SHA#hyperdoc-dmx-mcp' \
  'github:RalfBarkow/hyperdoc/APPROVED_INTEGRATION_SHA#checks.x86_64-linux.dmx-mcp'
```

Build for the actual host architecture; the recorded cloud validation is
x86_64-linux. Record package/check paths, derivations and NAR hashes. Verify the
candidate's `--version` names the approved commit and `--check` succeeds. Retain
the existing flake.lock, Topic Maps pin and independent ISO/Catalog services.

The new executable is `bin/hyperdoc-dmx-mcp`; the historical
`bin/hyperdoc-mcp-release-start` is not interchangeable. Prepare the following
values in the **actual host-owned MCP configuration**, resolving option conflicts
and the observed unit name before activation:

```nix
{ lib, pkgs, ... }:
let
  candidateFlake = builtins.getFlake
    "github:RalfBarkow/hyperdoc/APPROVED_INTEGRATION_SHA";
  candidate = candidateFlake.packages.${pkgs.system}.hyperdoc-dmx-mcp;
in {
  services.hyperdocMcp.package = candidate;
  services.hyperdocMcp.workspaceTopicmapId = 919822;
  services.hyperdocMcp.enableLiveWrites = true;
  services.hyperdocMcp.bindAddress = "127.0.0.1";
  services.hyperdocMcp.port = 8787;
  services.hyperdocMcp.allowedOrigins = [ "https://mcp.dreyeck.ch" ];
  services.hyperdocMcp.dataDir = "/var/lib/hyperdoc/mcp";
  systemd.services.hyperdoc-mcp.serviceConfig.ExecStart =
    lib.mkForce "${candidate}/bin/hyperdoc-dmx-mcp";
  systemd.services.hyperdoc-mcp.environment.HYPERDOC_MCP_STATE_DIRECTORY =
    "/OPERATOR/APPROVED/NEW/EMPTY/JOURNAL/DIRECTORY";
}
```

The historical `services.hyperdocMcp` module is a reference, not proof of the
installed configuration. Preserve the existing service account, backend URL,
authentication environment files and writable FASL/cache wiring. Keep secrets
outside the Nix store and public review. Do not introduce mandatory bearer auth
or switch production live writes to `0`. The synthetic tests' disabled-write
settings do not describe the intended production contract.

Build/evaluate the proposed host configuration without switching. Review that
only the MCP package, ExecStart and approved new journal/cache wiring change.
Keep nginx/TLS/vhost/path, Catalog, ISO service and other host changes untouched.
Unexpected changes block cutover. The package itself activates no service module.

## 3. Minimal MCP-only cutover, after operator approval

1. Retain the old package/configuration/old state mapping and verify the new
   directory is still unused, empty and writable by the service account.
2. Apply only the reviewed MCP package/ExecStart/new journal-directory change
   through the operator's established host procedure. A service replacement is
   operator work; this runbook does not execute it. Keep proxy and Catalog intact.
3. Initialize fresh MCP sessions. Observe initialize/initialized, resource
   discovery and a separately authorized real resource read through the existing
   connector. Session identifiers remain private. Fixture success does not prove
   the previously timed-out real connector now works with the new release.
4. Verify private startup diagnostics, directory access, capacity and the
   configured topicmap `919822` / live-write value `1`. Readiness checks do not
   authorize a production write or restart probe. A later write/restart-persistence
   acceptance probe needs explicit operator scope, a designated object and a
   reversal plan that accounts for new journal events.

A synthetic host rehearsal may use a separate free loopback port, synthetic
backend, disposable state and no production credentials. That is distinct from
the live-write Common Workspace contract. Cloud checks cover protocol, guarded
write fixtures and file-backed journal restart behavior, not host acceptance.

Inherited Host/body/session/backend-timeout limits remain outside this patch.
The journal repair does not add concurrent-writer synchronization, fsync or
power-loss/mid-write atomicity. Use one server writer for the new directory;
operators must assess these boundaries before activation.

## 4. Rollback without state mixing

Rollback triggers include startup loops, repeated list/read failures, journal
access errors, capacity pressure, changed public schemas/Origin/auth behavior or
an incorrect live-write value. Restore only the captured MCP package, original
ExecStart and original environment/state mapping through the operator's procedure.
Do not blindly roll back the whole host or restart the Catalog.

Leave both old histories and the new epoch directory untouched. Do not copy new
journals into the old release or overwrite new state from an older backup. New
DMX writes are not undone by reverting the MCP executable; any reconciliation
requires a separate decision. Reinitialize client sessions after rollback. The
old discovery defect may return with the old release.

## 5. Historical DMX cleanup is a separate, targeted decision

See [source-based cleanup criteria](dmx-journal-cleanup-criteria.md). No production
Topic/Association inventory, journal inventory tool, deletion, repair or cleanup
was run for this preparation. A URI prefix or a dry-run planner's acceptance is
not deletion authority. Neither local journal initialization nor this PR authorizes
removing DMX data.
