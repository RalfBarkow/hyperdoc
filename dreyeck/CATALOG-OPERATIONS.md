# Catalog operations

How the packaged dreyeck.ch HyperBook Catalog starts, what a service running it
needs, and what has not been verified. The sources and tests named here are
authoritative; this note records what they do not say themselves.

## Startup flow

```text
nix run .#catalog / installed hyperdoc-catalog / NixOS ExecStart
  → scripts/catalog-main.lisp            ASDF adapter: the packaged registry only
  → ASDF dreyeck/catalog-application     with dreyeck/local-fedwiki-view and
                                         clack-handler-hunchentoot
  → dreyeck/catalog-application:main     configuration, foreground, signals, exit
  → dreyeck/catalog-application:start-catalog
  → serve-catalog-with-local-fedwiki-view
  → CLOG / Clack / Hunchentoot
```

`main` is the process adapter: only it handles SIGINT and SIGTERM and turns
the outcome into an exit status. `start-catalog` installs no signal handlers
and does not block, so an interactive image, such as a SLY session, can call it
and keeps the server's lifetime (`clog:shutdown`). `hyperdoc-catalog --help`
lists the configuration variables.

The dependency of `dreyeck/catalog-application` on `clack-handler-hunchentoot`
is deliberate. CLOG chooses its Clack backend at run time (CLOG 2.2's
`initialize` defaults to `:server :hunchentoot`), and `clog.asd` names Clack
and Hunchentoot but not that handler system. Without the dependency, the
handler is present only if the environment happens to supply it; with it, one
ASDF load gives a server that can start.

## Running it as a service

The service definition is server-local and not part of this repository. The
following is a **template**, not observed server configuration:

```nix
let
  catalog = inputs.hyperdoc.packages.${pkgs.stdenv.hostPlatform.system}.hyperdoc-catalog;
in {
  systemd.services.hyperdoc.serviceConfig.ExecStart =
    "${catalog}/bin/hyperdoc-catalog 8080";
  systemd.services.hyperdoc.environment = {
    HYPERDOC_CATALOG_HOST = "127.0.0.1";
    HYPERDOC_FEDWIKI_SITE_ROOT = "/home/rgb/.wiki/dreyeck.ch/";
  };
}
```

The server-local module owns the service user, file access and the proxy. The
service user needs a writable Lisp compilation cache and access to its Wiki
store. `ExecStart` needs neither Nix nor a repository checkout to start the
Catalog.

## Operator update procedure for dreyeck.ch

The operator uses the following commands on dreyeck.ch to update the
server-local NixOS configuration:

```sh
cd /etc/nixos
nix flake update hyperdoc
nixos-rebuild switch --flake /etc/nixos#dreyeck
```

The operator supplied output from a successful execution on **2026-10-03**.
It reports the `hyperdoc` input revision changing, `hyperdoc-catalog` being
built, the `hyperdoc.service` unit being rebuilt, and activation stopping the
service, activating the new configuration and starting the service. The
switch completed successfully.

```text
operator deploy/update operation
  → Nix flake input revision changes
  → new NixOS generation is built
  → activation restarts hyperdoc.service

systemd ExecStart
  → starts hyperdoc-catalog inside an already activated generation
```

Updating and activating the configuration is an operator procedure;
`ExecStart` is the service's startup command within that configuration. The
successful switch does not establish the service's ExecStart or
WorkingDirectory, proxy state, browser reachability or application health
after restart. The separate operator confirmation of **2026-10-01** identifies
the program the service starts.

This records the procedure actually used, without requiring every future
deployment to use exactly these commands. HyperDoc adds no SSH automation.
The dated deployment observations are kept in the
[dreyeck.ch deployment reading](pages/work/dreyeck.ch%20deployment.html).

## Limits of the packaged runtime

- The package is not a saved SBCL core. It starts a fresh image from the
  packaged sources, and the first start compiles them into the service user's
  cache.
- The Nix source snapshot has no `.git`. The Git reading examples find their
  checkout through an ASDF system's source location, so in the store they find
  none. An explicit Git context for them would be a separate change.
- `HYPERDOC_CATALOG_SYSTEM` adds a trusted system to the default Catalog
  membership and never replaces it. It can name only systems in the packaged
  registry.
- The package carries the pinned development package set, not a minimal
  closure.

## The Item edit path

`HYPERDOC_CATALOG_SYSTEM=dreyeck/ctm-page-authoring` adds the Story Item `Edit` tab with proposal, preview and
Action context to the served Catalog. The system loads neither the writer nor topic-maps. The execution,
the CTM reading and the TMDM navigation are in `dreyeck/ctm-page-authoring/local`, a loopback review Catalog
(`scripts/serve-ctm-page-authoring.lisp`, see `docs/ctm-page-authoring-review.md`). topic-maps is not in the
packaged registry, so it cannot be named by the variable. The Work page *Item Edit Path in HyperDoc* describes
the objects, the limits and the tests.

## Not verified

The successful operator update above does not verify NixOS activation of the
template shown here, a Linux runtime test, or proxy and WebSocket acceptance
on the server. The executable test
makes real HTTP requests, but no test drives a browser or the WebSocket UI.

## Checks

The flake check runs the application tests and
[`tests/test_catalog_executable.py`](../tests/test_catalog_executable.py)
against the built executable ([`nix/catalog-check.nix`](../nix/catalog-check.nix)):

```sh
nix build .#checks.x86_64-darwin.catalog
```

Use the system name of the machine at hand. The Lisp suites around the
Catalog run in a development shell:

```sh
nix develop -c sbcl --noinform --no-userinit --non-interactive \
  --eval '(require :asdf)' \
  --eval '(asdf:test-system "dreyeck/local-fedwiki-view")' \
  --eval '(asdf:test-system "dreyeck/catalog")'
```

## History

This arrangement was refactored from an earlier startup path in which the
development shell ran `scripts/serve-catalog.sh`, and the script loaded the
systems, configured the server and waited for a signal itself (`64667fca`,
reconstructed from `91785f77`). The script was removed once the operator had
confirmed that the service runs the packaged executable (`b1078097`); it
remains readable as `git show 91785f77:scripts/serve-catalog.sh`. Operator
evidence about the deployed service is kept in the dreyeck.ch deployment
reading, not here.

## Maintained Catalog update procedure

The [deployment reading](pages/work/dreyeck.ch%20deployment.html) separates the
Catalog, static Mech assets and Wiki documentation. Asset commands are maintained
only in [Mech Story](../docs/fedwiki-mech-story.md#operator-procedure-complete-asset-versions).
These Bash steps are human-operated on dreyeck.ch, never executed by HyperDoc.
Use the established administrative account; an operator on a Mac can open their
own SSH session and run the same server-side commands. Tests never use SSH.

### Save the current selection

<!-- deployment-example: catalog-prepare -->
```bash
# Bash on dreyeck.ch, with the operator's NixOS administration privileges.
set -euo pipefail
cd /etc/nixos
catalog_receipt=$(mktemp -d /var/tmp/hyperdoc-catalog-update.XXXXXXXX)
cp -p flake.nix flake.lock "$catalog_receipt/"
readlink -f /run/current-system > "$catalog_receipt/previous-system"
nix-env --list-generations --profile /nix/var/nix/profiles/system > "$catalog_receipt/generations"
locked_hyperdoc_rev() {
  nix eval --raw --impure --expr '
    let lock = builtins.fromJSON (builtins.readFile /etc/nixos/flake.lock);
        key = lock.nodes.${lock.root}.inputs.hyperdoc;
        node = lock.nodes.${key}.locked;
    in assert builtins.isString key;
       assert node.owner == "RalfBarkow" && node.repo == "hyperdoc";
       node.rev'
}
locked_hyperdoc_rev > "$catalog_receipt/previous-revision"
```

### Choose one update mode

**Normal branch progression:** retain the existing input declaration. Run
`nix flake update hyperdoc`, inspect the old/new lock diff and source changes,
then set `REVIEWED_CATALOG_REV` to the exact accepted full OID and
`CATALOG_MODE=branch`. No declaration edit is needed. If the new revision is not
acceptable, restore the saved lock; do not build or activate it.

**Explicit commit pin:** before updating, set `CATALOG_MODE=pin` and `CATALOG_REV`
to the desired full OID. Locate and back up the input declaration (including any
additional file). Change that declaration to
`github:RalfBarkow/hyperdoc/<CATALOG_REV>`, then run `nix flake update hyperdoc`.
Inspect the diff and set `REVIEWED_CATALOG_REV` only after accepting it. This changes
the tracking policy: later updates stay pinned until the declaration is changed
again. It is not the normal branch update. Never substitute an unreviewed branch tip.

The lock helper supports the recorded direct GitHub input; a follows/path input
requires inspection. Reject unrelated input changes. Keep the previous system
and revision receipt; no successful build proves activation.

<!-- deployment-example: catalog-review -->
```bash
# Run after saving the previous pin/generation and updating the input.
# REVIEWED_CATALOG_REV is the full OID approved after inspecting the update.
: "${REVIEWED_CATALOG_REV:?Review the selected revision before building}"
[[ "$REVIEWED_CATALOG_REV" =~ ^[0-9a-f]{40}$ ]]
selected=$(locked_hyperdoc_rev)
test "$selected" = "$REVIEWED_CATALOG_REV" || {
  echo "Unexpected Catalog revision; no build or activation" >&2; exit 1;
}
case "${CATALOG_MODE:-branch}" in
  branch) ;; # Keep the configured branch declaration.
  pin) test "$selected" = "$CATALOG_REV" || { echo "Pin mismatch" >&2; exit 1; } ;;
  *) echo "Unknown Catalog update mode" >&2; exit 1 ;;
esac
nixos-rebuild build --flake /etc/nixos#dreyeck
test "$(locked_hyperdoc_rev)" = "$REVIEWED_CATALOG_REV" || {
  echo "Revision changed during build; no activation" >&2; exit 1;
}
readlink -f result > "$catalog_receipt/built-system"
```

### Activate only the reviewed build

Set `APPROVE_CATALOG_SWITCH` to `REVIEWED_CATALOG_REV` only after build review.

<!-- deployment-example: catalog-activate -->
```bash
: "${APPROVE_CATALOG_SWITCH:?Explicitly approve the reviewed revision}"
test "$APPROVE_CATALOG_SWITCH" = "$REVIEWED_CATALOG_REV"
test "$(locked_hyperdoc_rev)" = "$REVIEWED_CATALOG_REV"
nixos-rebuild switch --flake /etc/nixos#dreyeck
test "$(readlink -f /run/current-system)" = "$(cat "$catalog_receipt/built-system")"
systemctl is-active hyperdoc.service
systemctl show --no-pager --full hyperdoc.service -p MainPID -p ExecStart -p ActiveState
pid=$(systemctl show hyperdoc.service -p MainPID --value)
test "$pid" -gt 0
ps -ww -p "$pid" -o pid=,args=
readlink -f "/proc/$pid/exe"
curl -fsS -D "$catalog_receipt/public-headers" https://dreyeck.ch/ -o "$catalog_receipt/public-body"
```

Correlate ExecStart with the actual PID/program and the built store package.
A process from a different package falsifies activation, even after a successful
switch. HTTP reachability alone does not prove Lisp identity or successful browser
execution. Verify public Inspector navigation and its configured host URL without
dumping secret environment values. Catalog changes do not update the asset symlink.

### Catalog rollback

<!-- deployment-example: catalog-rollback -->
```bash
# Option A: restore the previous input declaration AND lock from the receipt.
# Only after confirming no later/unrelated configuration edits would be lost.
cd /etc/nixos
: "${catalog_receipt:?Path to the saved Catalog update receipt}"
cp -p "$catalog_receipt/flake.nix" "$catalog_receipt/flake.lock" .
# Restore any additional declaration file explicitly saved during this update.
nixos-rebuild build --flake /etc/nixos#dreyeck
# Inspect the selected revision and build; then authorize activation.
nixos-rebuild switch --flake /etc/nixos#dreyeck
# Option B, instead of A: select a KNOWN recorded system generation.
# This rolls back the whole NixOS system, not only HyperDoc; review that scope.
# nix-env --profile /nix/var/nix/profiles/system --switch-generation KNOWN_NUMBER
# /nix/var/nix/profiles/system/bin/switch-to-configuration switch
# Reconcile /etc/nixos with the selected generation before the next rebuild.
# Neither option changes the separately maintained Wiki asset symlink.
```

### Local falsification tests

`python3 scripts/test-mech-deployment-documentation.py` syntax-checks these examples
and runs their asset and Catalog control flow against temporary fixtures and a
loopback HTTP server. Nix/build/service operations are substituted and recorded;
this does not test real NixOS activation. Use fresh Lisp runtimes for the Deployment,
Inspector and navigation tests, and a separate fresh runtime for Catalog startup.
