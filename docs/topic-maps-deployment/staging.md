# Staging hyperdoc-catalog-topic-maps on dreyeck.ch, for an authorized operator

Nothing here has been run on the server. Claude Code does not connect to it. This page is the procedure an operator follows
after the preconditions below, and it changes nothing by itself.

## What it is

- **A separate service,** `hyperdoc-catalog-topic-maps-staging`, from the NixOS module `nix/nixos-staging.nix`
  (flake output `nixosModules.hyperdoc-catalog-topic-maps-staging`). It runs the package `hyperdoc-catalog-topic-maps`: the
  HyperDoc Catalog with Topic Maps `b2eecffa` from the verified snapshot, and the review reading
  *Deploying Topic Maps with HyperDoc* as its additional book.
- **Loopback only.** The service sets `HYPERDOC_CATALOG_HOST=127.0.0.1`; the executable refuses any other host before it loads
  anything; the unit allows only loopback traffic (`IPAddressDeny=any`, `IPAddressAllow=localhost`).
- **Not public.** The module adds no reverse-proxy route, no firewall rule and no open port.
- **Beside production.** It does not replace, restart or reconfigure the production `hyperdoc-catalog` service, and it shares
  no state directory, cache or port with it.
- **Explicit.** `wantedBy = [ ]`: it is not started at boot. `Restart = "no"`: a stopped or failed staging Catalog stays stopped.

## Preconditions: none is met by this repository

1. **Fresh capacity evidence, from the operator.** The server has had severe disk-space constraints. Before anything is built
   there, the operator records free space on the store's file system and on `/var`, and the free memory. The first start
   compiles a large Lisp image into `/var/cache/hyperdoc-catalog-topic-maps-staging`, and the service is bounded by
   `MemoryMax=3G`. The package's closure is built elsewhere and copied, or substituted; building on the server is not required
   and is not recommended.
2. **The revision must be reachable by the server's flake.** The server locks `github:RalfBarkow/hyperdoc`. The commit is local
   and unpushed. Pushing is a separate decision of the repository's owner.
3. **The Topic Maps snapshot must be obtainable by whichever machine builds the package.** `nix/topic-maps-source.nix` is a
   fixed-output derivation pinned by NAR hash, whose release URL does not exist yet. A builder that does not already hold the
   path cannot fetch it. Either:
   - **publish** the archive at that URL: a release, which needs the owner's separate authorization; or
   - **transfer** it into the builder's store without publishing: unpack the archive and add it by content,
     `nix store add --mode nar --name source <unpacked directory>`, which yields the same store path
     (`/nix/store/1l6im929rknvgp3jxx83i01crcf3ahmg-source`) only if the content is the pinned one; or copy the path with
     `nix copy`. Verify the archive first: its SHA-256 and size are in `nix/topic-maps-b2eecffa.manifest`, and its NAR hash is
     `sha256-Nu7zDGGWj2rYEozoe4sVj6hiDC3HBHGdSvzOBaBcylw=`. The package's own check verifies the snapshot again against the
     manifest, as a chain of Git objects, without `.git`.
4. **The owner's authorization** to deploy.

## Building the package on an independent Linux builder

This is the procedure that was run on a local Docker builder (`docs/topic-maps-deployment/evidence/after-guard-correction/`); any
x86_64-linux Nix that is not the production server will do. It needs the committed tree and the snapshot archive, and nothing of
the Topic Maps repository.

1. **The tree, without `.git`:** `git archive --format=tar <commit> | ssh BUILDER 'mkdir src && tar -x -C src'`, then on the builder
   `git init && git add -A && git commit` inside `src` (the flake wants a Git tree for `self.rev`), and check that
   `git write-tree` equals `git rev-parse <commit>^{tree}` on your machine.
2. **The snapshot archive:** from the topic-maps repository, read-only, `python3 scripts/topic-maps-snapshot.py create
   <topic-maps> b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc <out>`. It reproduces `nix/topic-maps-b2eecffa.manifest` byte for byte
   (`cmp`), and the archive is 1,033,963 octets with the SHA-256 above. Copy only the archive to the builder.
3. **Add it to the builder's store by content:** unpack it, check `nix hash path --type sha256 --sri` is
   `sha256-Nu7zDGGWj2rYEozoe4sVj6hiDC3HBHGdSvzOBaBcylw=`, then `nix store add --mode nar --name source <unpacked directory>`; it must
   print `/nix/store/1l6im929rknvgp3jxx83i01crcf3ahmg-source`. Nix then finds the fixed-output path present and fetches nothing for it.
4. **Build and check:** `nix build --print-build-logs .#checks.x86_64-linux.catalog-topic-maps
   .#packages.x86_64-linux.hyperdoc-catalog-topic-maps`. The check runs the four Lisp suites, the fresh-process ASDF preservation
   test and the executable contract. A builder with the sandbox enabled makes this a sandboxed build.
5. **Run it:** `HYPERDOC_CATALOG_SYSTEM=topic-maps-deployment-review-asdf-collision result/bin/hyperdoc-catalog-topic-maps PORT`, then
   reach it on `127.0.0.1:PORT` only.

## Use

In the server's NixOS configuration, import the module from the flake and enable it. The port is not defaulted: choose one that
nothing listens on (`ss -ltn`), so that it cannot collide.

```nix
{
  imports = [ inputs.hyperdoc.nixosModules.hyperdoc-catalog-topic-maps-staging ];
  services.hyperdoc-catalog-topic-maps-staging = {
    enable = true;
    package = inputs.hyperdoc.packages.x86_64-linux.hyperdoc-catalog-topic-maps;
    port = 18780;   # an example; check that it is free
  };
}
```

Applying the configuration (`nixos-rebuild switch`) adds the unit. It does not start it.

### Start

```bash
sudo systemctl start hyperdoc-catalog-topic-maps-staging
journalctl -u hyperdoc-catalog-topic-maps-staging -f      # "Topic Maps snapshot verified without .git", then "listening on 127.0.0.1"
ss -ltnp | grep 18780                                     # 127.0.0.1 only
```

The first start takes minutes: it compiles into the unit's cache.

### Access from your own machine: an SSH tunnel

The Catalog listens on the server's loopback, so it is reached through the operator's own SSH session, from a machine and an
account that is authorized to log in:

```bash
ssh -N -L 18780:127.0.0.1:18780 USER@dreyeck.ch
```

Then open `http://127.0.0.1:18780/` locally. The reading's path: Catalog → *Deploying Topic Maps with HyperDoc* → Text pages.
Closing the SSH session closes the tunnel.

### Stop

```bash
sudo systemctl stop hyperdoc-catalog-topic-maps-staging
```

### Roll back

The staging service is the only thing the module adds, and it is not enabled at boot.

- **Stop using it:** `systemctl stop` as above; the service stays stopped.
- **Remove it:** delete the import and the `services.hyperdoc-catalog-topic-maps-staging` block, then `nixos-rebuild switch`.
- **Return to the previous generation:** `nixos-rebuild switch --rollback`, or select the previous generation at boot.

Its state is `/var/lib/hyperdoc-catalog-topic-maps-staging` and `/var/cache/hyperdoc-catalog-topic-maps-staging`; the unit is a
`DynamicUser`, so removing the unit leaves only those two directories. The production service is neither stopped nor restarted
at any point.

## What the Catalog's startup guard protects, and what it does not

`dreyeck/src/catalog-topic-maps.lisp` checks the Catalog's own startup before anything is loaded or served. It reads system
definitions only, and it adds no method to ASDF and replaces none.

**It protects:**

- **The Project Workspace** (`dreyeck/work/project`, bound to Topic Maps `5a4a668`) is not loaded at startup. The Catalog loads
  exactly one system by choice, the one `HYPERDOC_CATALOG_SYSTEM` names. If that system is, or depends on, the Project Workspace
  or one of its subsystems, the executable exits with status 2 before listening.
- **The page-attached system loader** is not in this runtime. `dreyeck/page-attached-hyperdoc` loads a system named by an `.asd`
  that is attached to a wiki page; `dreyeck/fedwiki-hyperdoc` and the *Activate page-attached HyperDoc* button of a local
  FedWiki page reach it. That button is a plain `v:thunk`, which `dreyeck/authority-policy` does not gate. The default Catalog
  does not depend on it, and a catalog system that does is refused in the same way, so a wiki page cannot name a system to load
  after startup, the Project Workspace included.
- **The loopback restriction** is decided before anything is loaded (`scripts/catalog-topic-maps-main.lisp`).
- **ASDF itself.** Its methods are unchanged (`scripts/test-asdf-method-preservation.lisp`).

**It does not protect:**

- **A load made by other means after startup.** The check is made once, at startup. An operator at a Lisp prompt in the running
  image, or code that is not part of this application, can still call `asdf:load-system`. The executable has no such prompt.
  The application's own paths that run page-attached code and are in this runtime, the Lisp critic's loader and the
  reconstruction runner, refuse in a served Catalog that is not in development mode, which is how the executable starts, and
  the reconstruction runner starts a separate image.
- **A raw `load` of the Project Workspace's files.** Nothing in the Catalog does one.
- **The inspector's plain `v:thunk` run buttons.** Those of the 22U reading, the CTM review and the review reading are not
  gated by `dreyeck/authority-policy`. That is why the Catalog serves loopback only, and why it must not be exposed beyond
  loopback until they are gated or removed.
