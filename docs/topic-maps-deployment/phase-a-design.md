<!-- The Phase A design as reviewed on 2026-10-26, moved unchanged from the session scratchpad. Corrections and the decisions D1–D5 are in README.md. -->

# Topic Maps in the dreyeck.ch Catalog — Phase A deployment design

Prepared 2026-10-26, read-only. Nothing in either repository, on the server or in any service was changed. The only side effect was
that evaluating the flake offline copied HyperDoc's tracked source (≈19 MB) into the **local** Nix store.

The labels mark how each statement is known:
- **[obs]** observed here today;
- **[der]** derived from source or evaluation, not executed;
- **[inf]** inferred, needs a test;
- **[op]** needs operator evidence.

## 0. Established state

### Revisions
- **topic-maps** [obs]:
  - `b2eecffa05de4fce41c10ae1ada9ae11a0c6e7dc` on `codex/project-work-slice-22u`, clean.
  - The commit object (SHA-1 format) is SSH-signed; its root tree is `2b2ad0589082f3291dd6b1c2be2a0f470b17989b`.
  - Its only remote, `gitweb` (dreyeck.freedombox.rocks), advertises `b2eecffa` as that branch's tip today (`ls-remote`). The design does
    not rely on it.
- **HyperDoc** [obs]:
  - `dreyeck.ch` at `53ee9993` (CTM review), whose parent is `bc28a146` (22U integration). The working tree is clean.
  - Both commits are **unpushed**: `github/dreyeck.ch` is 2 behind.
  - The server locks HyperDoc as `github:RalfBarkow/hyperdoc` (CATALOG-OPERATIONS.md), so the server cannot reach either revision
    today [der].
- **CTM Review revision** [obs]: committed as `53ee9993`. It was validated before the commit on a byte-identical tree (patch SHA-256
  `827e7c37…`). No tests were rerun after the commit.

### Packaging today [obs]
- `hyperdoc-catalog` is a `writeShellApplication` with:
  ```
  CL_SOURCE_REGISTRY = runtime.sourceRegistry : cleanSource(self)
  ```
- `scripts/catalog-main.lisp` loads only `dreyeck/catalog-application`.
- topic-maps is in no packaged registry. Comments in `dreyeck.asd` keep that question open ("E1").

### Size of topic-maps [obs]

| | files | tar | gzip |
|---|---|---|---|
| tracked tree at `b2eecffa` | 12,228 | 2.47 GB | — |
| of which `reports/` | 9,900 | ≈2.46 GB | — |
| tree **without** `reports/` | 2,328 | 7.2 MB | 1.05 MB |

Further facts about the tree:
- No symlinks; 3 executable files.
- `.gitattributes` holds only `-whitespace` rules: no `export-subst`, `eol` or `export-ignore`. So archived bytes equal the blob bytes
  [der].

### Dependency closure, x86_64-linux [der]
Evaluated offline from the locked nixpkgs `50ab7937`; nothing was built.
- **Runtime:** SBCL 2.4.10 with 137 Lisp libraries.
- **Present:** `ironclad` (only transitively), `babel`, `cl-base64`, `cl-who` and `plump`.
- **Native libraries:** openssl and sqlite.
- **topic-maps needs little:** `topic-maps`, `/tmdm`, `/ctm`, `/cxtm` and `/project-work-example` need only `uiop`.
- **Unused:** `cxml` (for `topic-maps/xml` and `/xtm`) is absent and not needed.

### Git-dependent provenance [der from source]
Each of these needs a `.git` at the source location. `git-run-string` signals on a non-zero exit, so all of them **fail closed** in a store
snapshot:
1. `checked-source-path` runs `rev-parse HEAD` and `status`, so the 22U run and the review run refuse.
2. `run-example` compares the CTM text with `git-file-contents` at the commit.
3. The review's `%file-at-revision`: section 3 of the Claim view, and the "Contents" view opened on click.
4. The review's `%hyperdoc-state`: HyperDoc's revision and dirty flag.
5. `tmdm-reading`'s `checked-repository`:
   - it requires pin `788899ae` or a clean descendant (`b2eecffa` is 57 commits later);
   - it checks blobs;
   - it executes corpus cases from `vendor/cxtm`.

The Project Workspace's `topic-maps-source-identity` is different: it ignores Git's exit status, reports `:pinned nil` and does **not**
refuse.

### Project Workspace [obs]
- Pinned to `5a4a6685…`, which is **not an ancestor** of `b2eecffa`: a separate lineage.
- ASDF can hold only one `topic-maps` per image.

### Execution authority in the served Catalog [der from source; not yet tested]
- **What production blocks:**
  - The executable never enables development mode, so there is no Playground.
  - `dreyeck/authority-policy` lets the Operations view and the `defexample` ► buttons run only under a registered contract.
- **What it does not block:** the buttons "Read a fresh 22U Map", "Exercise on a separate fresh Map" and "Run the experiment" are plain
  `v:eval-button` + `v:thunk`. `hv:eval-thunk` is gated only for `operation-thunk` and `example-thunk`.
- **Consequence:** loaded into a public Catalog, these three buttons would run for any visitor. Each click allocates new Maps and
  registers executions, so memory grows without bound.

### Correction to earlier statements [obs]
The bootstrap's "temporary FASL cache" is **not effective**:
- The SBCL wrapper prefixes `ASDF_OUTPUT_TRANSLATIONS` itself, so `env -u` before it does nothing.
- A probe showed the explicit translation does not apply.
- Today's review test runs compiled into `~/.cache/common-lisp/sbcl-2.4.10-macosx-x64/…` (review FASL mtime 10:22:26 CET): 16 MB for
  HyperDoc and 0.8 MB for topic-maps.
- No repository was written. But "fresh process" did not mean "fresh compilation".

### This machine [obs]
- x86_64-darwin, with 48 GiB free on the data volume (95% used).
- It cannot build x86_64-linux natively.

### Server [op]
- No operator evidence came with this request; the newest dated server evidence in the repository is from 11 October.
- The 99% disk figure is your report; I have not observed it.

## 1. Design

### 1.1 Source distribution: one runtime snapshot, two independent pins

**Content.** The snapshot is `git archive --prefix=topic-maps-b2eecffa/ b2eecffa` of every top-level entry **except `reports/`**:
- the rule is one exclusion, so it is easy to state and to check;
- 7.2 MB unpacked;
- keeping `vendor/`, `references/`, `tests/` and `docs/` keeps the corpus readings, topic-maps' own project-work tests and the 22U
  document links usable.

A HyperDoc script generates it on the Mac from the local repository, which stays the authority. The script only reads topic-maps: `git
archive` and `git cat-file`.

**Pin 1, Nix.**
- Flake input `topic-maps-src` (`flake = false`, a tarball URL).
- HyperDoc's `flake.lock` records its `narHash`, the SHA-256 of the unpacked tree. Nix refuses any other content.

**Pin 2, Git.**
- A manifest of about 3 KB is committed in HyperDoc (`nix/topic-maps-b2eecffa.manifest`). It holds:
  - the raw commit object of `b2eecffa`;
  - the root tree listing (mode, id and name for its 16 entries);
  - the `narHash`;
  - the excluded entry (`reports` → tree `44adbb2c…`).
- No implementation file is copied, so nothing is vendored.

**Verification without `.git`.** Every step is recomputed from the store files, in Lisp with ironclad SHA-1:
1. SHA-1 of `"commit <n>\0" + object` equals `b2eecffa`, the constant HyperDoc already pins (`+source-revision+`).
2. The commit's `tree` is `2b2ad058…`, and the root tree object rebuilt from the listing hashes to `2b2ad058…`.
3. For each shipped entry, the blob or tree id recomputed from the files (mode taken from the executable bit) equals the listing.
4. `reports/` is named by its tree id but neither shipped nor verified. The result says so: *"Git-object-verified snapshot of b2eecffa;
   reports/ excluded, not verified"*.

**Strength.**
- Git's object ids are SHA-1. The SHA-256 `narHash` pins the same bytes independently.
- Verifying the SSH signature would need the allowed-signers key; it is not proposed now.
- The same verifier runs in a flake check, so a bad snapshot fails the build.

**Classification.** The run and the Inspector show what the evidence was:
- **`:git-checkout`:** today's path, unchanged;
- **`:verified-snapshot`:** the chain above;
- **refusal:** anything else. Nothing is silently bypassed.

### 1.2 How the revisions reach the builder

- **HyperDoc:** push `dreyeck.ch` to GitHub (`bc28a146`, `53ee9993`, plus the Phase B commit). This needs your approval. The operator
  then follows the existing procedure in CATALOG-OPERATIONS.md.
- **topic-maps snapshot, option A (recommended):** a release asset on `RalfBarkow/hyperdoc` on GitHub.
  - It is the host `/etc/nixos` already trusts for HyperDoc.
  - The content is immutable by `narHash`.
  - It is a publication, so it is yours to do.
- **topic-maps snapshot, option B (no publication):**
  - The operator adds the unpacked snapshot to the server's store with `nix store add --mode nar --name source <dir>`.
  - If the resulting path equals the locked one, Nix uses it without fetching [inf]; Phase C must test this first.
  - It has to be repeated on every builder, and it is not safe from garbage collection until an activated system references it.
- **Rejected:**
  - a `git+https` input of topic-maps: it copies the 2.47 GB tree, plus a Git cache, onto a server at about 99% disk;
  - an absolute path or a mutable checkout on the server: not reproducible.

### 1.3 Minimum changes (Phase B)

1. **`flake.nix` and `nix/catalog.nix`:**
   - Add the input `topic-maps-src`.
   - `catalog.nix` gains `extraSources ? [ ]` and `environment ? { }`. The default must reproduce today's derivation text; a check
     compares it.
   - A **separate** package, `hyperdoc-catalog-topic-maps`, uses the same runtime and the same `catalog-main.lisp`. It adds to that:
     - `${topic-maps-src}//` in the registry;
     - `HYPERDOC_SOURCE_REVISION = self.rev`;
     - `HYPERDOC_SOURCE_NARHASH = self.narHash`;
     - the manifest path.
   - `hyperdoc-catalog` itself is unchanged: production's registry and startup stay as they are (decision D1).
2. **`nix/lisp-runtime.nix`:** unchanged.
   - Adding `ironclad` explicitly would rebuild the production SBCL wrapper for nothing.
   - Instead, a check asserts that every needed library resolves inside the runtime registry.
3. **Lisp, all optional and outside production startup:**
   - **`dreyeck/source-snapshot`** (new, about 150 lines): reads the manifest, hashes Git objects, verifies the chain, and gives a
     snapshot-file object with a "Contents" view.
   - **`checked-source-path`:** dispatches to Git checkout (today's checks, unchanged), verified snapshot, or refusal. The run records
     which.
   - **The review's `%file-at-revision` and `%hyperdoc-state`:** checkout; or snapshot or flake `self`, classified as *"Nix-locked
     input revision, asserted by the flake evaluation"*; or refusal.
   - **`tmdm-reading`:** unchanged. Its corpus executions stay checkout-only and fail closed in the package. This is a stated
     limitation.
   - **Project Workspace guard:** the variant refuses to start if the system it is asked to load is, or depends on, `dreyeck/work/project`, because that is bound to
     `5a4a668`. The Project Workspace itself is not changed.
4. **Execution authority:** Phase B leaves the three plain-thunk buttons as they are. The variant runs loopback-only. Making them public
   needs either:
   - reviewed `example-thunk` contracts, with their effects, a per-click memory bound, and identity of who may run them; or
   - an authenticated, non-public instance.

   That is decision D5.
5. **Tests:** `nix/topic-maps-check.nix` runs in the Nix sandbox, with `HOME=$TMPDIR` and no network.

### 1.4 Acceptance conditions, kept separate

| | Condition | Falsified by |
|---|---|---|
| A1 | **Discoverable:** the packaged registry finds topic-maps, `/tmdm`, `/ctm`, `/cxtm` and `/project-work-example`; each `system-source-directory` is the locked store path, and there is only one topic-maps root | another root, or a non-store path |
| A2 | **Compiled:** a fresh SBCL with an empty cache under `$TMPDIR` loads the three dreyeck systems; no warnings from their own files | a load error, or FASLs outside `$TMPDIR` |
| A3 | **Snapshot verified:** the chain passes | negative controls: one byte changed in a copy → refused; a manifest naming another commit → refused |
| A4 | **Behaviour:** the real reader gives native TMDM; both 22U paths work; the review reads its control and rejects `svn+ssh` (code, position 3); the topic-maps files' SHA-256 is unchanged; rendering runs nothing; no writer is loaded; the Project Workspace guard refuses | each existing check, rerun |
| A5 | **Registration:** both HyperBooks are listed in the variant; `hyperdoc-catalog` lists exactly today's members | a membership diff |
| A6 | **Production compatibility:** `checks.catalog` passes; `hyperdoc-catalog` keeps the same registry string and the same loaded-system set | any difference |
| A7 | **Server staging:** Linux runtime, HTTP 200, Inspector navigation, the browser test through a tunnel, process termination, temporary directories removed | any step |
| A8 | **Public availability:** not part of this deployment; only after D5 | — |

Every result records its start and finish time, the runtime's identity and the command. Stored evidence (`docs/topic-maps-22u-integration/*`,
today's scratch runs) is listed separately and called historical.

**Where Phase C runs** (decision D3):
- x86_64-linux needs either a Linux builder you name, or the server itself running `nix build` only, after the disk check.
- A darwin package test can run on this Mac first. Its size comes from a dry run before anything is built.

## 2. Server evidence the operator should supply (read-only)

Run as the administrative user and **review the output before sending it**. Unit files and Nix configuration can contain secret
environment values: redact everything except names, store paths, ports and hosts. Never print `~/.wiki/config.json`.

```bash
set -u
date -u +%FT%TZ; uname -m; nixos-version; nix --version
readlink -f /run/current-system
nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -5
df -h / /nix /var /tmp /home 2>/dev/null; df -i /nix
nix path-info -Sh /run/current-system
nix-store --gc --print-dead 2>/dev/null | wc -l          # counts only; deletes nothing
cd /etc/nixos && ls && git rev-parse HEAD 2>/dev/null && git status --short 2>/dev/null
grep -n 'hyperdoc' flake.nix
nix eval --raw --impure --expr 'let l = builtins.fromJSON (builtins.readFile /etc/nixos/flake.lock);
  k = l.nodes.${l.root}.inputs.hyperdoc; n = l.nodes.${k}; in builtins.toJSON { locked = n.locked; inputs = n.inputs or {}; }'
nix show-config | grep -E '^(substituters|trusted-public-keys|max-jobs|builders|sandbox|experimental-features) '
systemctl show hyperdoc.service -p ExecStart -p User -p WorkingDirectory -p ActiveState -p ActiveEnterTimestamp -p MainPID
pid=$(systemctl show hyperdoc.service -p MainPID --value); ps -o pid,user,rss,args -p "$pid"; readlink -f "/proc/$pid/exe"
ss -ltn | grep -E ':(8080|187[0-9]{2})\b'
grep -rln 'hyperdoc\|8080' /etc/nixos --include='*.nix'      # file names only: which module holds the proxy
```

## 3. Operator procedure (Phase D outline; nothing in it is automatic)

1. **Make the revisions available:**
   - you push the approved HyperDoc commits;
   - the snapshot is published (A) or side-loaded (B).
2. **Record:** the receipt block from CATALOG-OPERATIONS.md (flake files, the current system, generations, the locked revision), plus
   `df`, `nix --version` and `nix path-info -Sh /run/current-system`.
3. **Build without activating:**
   - `nixos-rebuild build --flake /etc/nixos#dreyeck`.
   - For staging only:
     ```bash
     nix build github:RalfBarkow/hyperdoc/<REV>#hyperdoc-catalog-topic-maps --out-link /var/tmp/tm-staging/result
     ```
     The out-link is a GC root; removing it releases the path.
4. **Check:**
   - `nix store diff-closures /run/current-system ./result`;
   - `nix path-info -S` on the new paths;
   - `df` before and after;
   - the old and new `hyperdoc.service` unit text compared;
   - the locked revisions equal the reviewed ones.
5. **Staging run:**
   - A separate process bound to `127.0.0.1` on port 18780 with temporary directories:
     ```bash
     HYPERDOC_CATALOG_HOST=127.0.0.1 HYPERDOC_CATALOG_SYSTEM=dreyeck/work/topic-maps-ctm-review \
     HYPERDOC_FEDWIKI_SITE_ROOT=$(mktemp -d) XDG_CACHE_HOME=$(mktemp -d) HOME=$(mktemp -d) \
       /var/tmp/tm-staging/result/bin/hyperdoc-catalog-topic-maps 18780
     ```
   - From the Mac: `ssh -L 18780:127.0.0.1:18780 …`, then run the existing browser test against the tunnel.
   - Stop the process, check that the port is closed, and remove the temporary directories and the out-link.
6. **Approval:** `APPROVE_CATALOG_SWITCH` equals the reviewed revision, as in CATALOG-OPERATIONS.md.
7. **Activate:** `nixos-rebuild switch`, as today. Because of D1, the public service still runs `hyperdoc-catalog`, so the Topic Maps
   systems are present in the store but not loaded publicly.
8. **Verify:**
   - the existing PID/ExecStart/store-path correlation;
   - public HTTP and Inspector navigation;
   - the public process has loaded **none** of the Topic Maps systems;
   - rollback stays as documented: the receipt, or a known generation.

## 4. Decisions for you

- **D1. Production package.** Recommended: a separate `hyperdoc-catalog-topic-maps` variant, with `hyperdoc-catalog` unchanged. The
  alternative is to add topic-maps to the production registry (discoverable but not loaded), which needs the Project Workspace guard in
  production code.
- **D2. Snapshot transport.** Recommended: a GitHub release asset (A). The alternative is side-loading into the server's store (B), after
  the Phase C test.
- **D3. Where x86_64-linux is built and tested.** A Linux builder you name, or `nix build` on the server after the disk evidence.
- **D4. Pushing `dreyeck.ch`** (two commits now, the Phase B commit later).
- **D5. Execution authority before any public exposure.** Example contracts, an authenticated instance, or staying loopback-only.
