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

## Not verified

NixOS activation of the template, a Linux runtime test, and proxy and
WebSocket acceptance on the server have not been verified. The executable test
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
