# Verifying RalfBarkow/hyperdoc#12 with the real HyperDoc/Inspector runtime

What has to pass before the PR is merged, why it could not run where the PR was prepared, and the exact commands for a
machine with working Nix access. None of these commands contacts dreyeck.ch, starts a service there or writes a Wiki.

## The blocker

The PR was prepared in a Claude Code cloud container whose egress proxy refuses two hosts:

| Host | Observed (UTC) | Response |
|---|---|---|
| `codeberg.org:443` | 2026-11-02 07:09:44, again 07:35:30 | proxy `connect_rejected`: "gateway answered 403 to CONNECT" |
| `gitlab.common-lisp.net:443` | 2026-11-02 07:35:30 | the same |

`nix develop .#fedwiki-original-editor` failed with `error: Failed to fetch git repository
'https://codeberg.org/khinsen/clog-moldable-inspector.git'`. The Lisp runtime's source registry (`nix/lisp-runtime.nix`,
`sourceRegistry`) needs these locked inputs, none of which `cache.nixos.org` substitutes:

| Input | Locked source | `narHash` |
|---|---|---|
| `clog-moldable-inspector` | git, codeberg.org/khinsen | `sha256-NsmOHUj3dw73rtnr5afdlxH4DadZjD3Ozk0mZUvwfag=` |
| `html-inspector-views` | git, codeberg.org/khinsen | `sha256-w85sPKIAaFuo+EmkB6m3rwg2JDkeogwpJ2hNWcCLw5s=` |
| `plump-inspector-views` | git, codeberg.org/khinsen | `sha256-PapF0m5tiIhPC6OH/eL4SrEtb3mlQ0wf2WPWZ1X3vvo=` |
| `shop3-iterate` | git, gitlab.common-lisp.net | `sha256-6bYX+Al8x2zBngRUw63vUPaVNP0lLXnzaJYZFP52bEw=` |

(`workflow-source-editor`, a codeberg tarball, is used only by the `workflow-authoring` shell.) Everything else was
available: nixpkgs from the cache, SBCL 2.4.10, Node 24.22.1, the npm registry. The repository has no GitHub workflow
(`.github/` does not exist), so no CI ran on the PR either.

Remedy, either: allow `codeberg.org` and `gitlab.common-lisp.net` in that cloud environment's network settings, or run
the commands below on a machine that reaches them.

## Commands

From a clean checkout of the PR head; use your platform's system name (`x86_64-linux`, `aarch64-darwin`, `x86_64-darwin`):

```bash
git fetch origin claude/relaxed-meitner-q7l2y4 && git checkout --detach origin/claude/relaxed-meitner-q7l2y4 && git log -1 --format=%H
```

### 1. The Nix `catalog` check, with every real ASDF dependency

```bash
nix build .#checks.x86_64-linux.catalog -L --out-link result-pr12-catalog
```

It runs in the build sandbox (no network, empty HOME and cache) against the package's own registry: the
`dreyeck/catalog-application` suite, the new demo test system, the membership proof (item 3), the Topic Maps guard, the
public-views walk with the authority-policy gate checks, ASDF method preservation and the executable tests. Then:

```bash
grep -h -E '^(Catalog application tests passed|FEDWIKI-ORIGINAL-EDITOR-CONFIGURATION-PASS|FEDWIKI-ORIGINAL-EDITOR-DEMO-PASS|DEFAULT-CATALOG|WITH-CATALOG-SYSTEM|EDITOR-DEMO-MEMBERSHIP-PASS|CATALOG-TOPIC-MAPS-PACKAGE-PASS|TOPIC-MAPS-PUBLIC-VIEWS-PASS|ASDF-METHOD-PRESERVATION-PASS)' result-pr12-catalog/*.log
```

Expected, among others:

```text
DEFAULT-CATALOG 24 HyperBooks: the 23 of 19e824d, each once, and dreyeck/fedwiki-original-editor-demo once; no other.
WITH-CATALOG-SYSTEM dreyeck/work/topic-maps-ctm-review: … HyperBooks; the previous 24 kept once each; added (…).
EDITOR-DEMO-MEMBERSHIP-PASS
```

`TOPIC-MAPS-PUBLIC-VIEWS-PASS` includes `check-reviewed-controls-match-their-sites`. If the base commit `19e824d` fails
the same check (expected from reading the code, not observed), that is the earlier state this PR corrects; to see it:

```bash
git checkout --detach 19e824d326def8bc227101e2494500630f441953 && nix build .#checks.x86_64-linux.catalog -L --out-link result-base-catalog; git checkout --detach origin/claude/relaxed-meitner-q7l2y4
```

### 2. The closed-membership check of `dreyeck/catalog` (not part of the Nix check)

`dreyeck/catalog/tests` asserts in a fresh process that the loaded Catalog is exactly the admitted set:

```bash
nix develop -c sbcl --noinform --no-userinit --non-interactive --eval '(require :asdf)' --eval '(asdf:test-system "dreyeck/catalog")' 2>&1 | grep -E 'ADMITTED-CATALOG-PROOF|Fresh Dreyeck catalog startup tests passed'
```

Expected: `ADMITTED-CATALOG-PROOF: 24 admitted HyperBooks, each once, no other.`

### 3. Standalone and Inspector browser E2E

```bash
nix develop .#fedwiki-original-editor
```

Inside that shell:

```bash
npm ci --prefix tests/fedwiki-original-editor --ignore-scripts --no-audit --no-fund
```

```bash
node --test tests/fedwiki-original-editor/commands.test.mjs tests/fedwiki-original-editor/server.test.mjs
```

```bash
fedwiki-original-editor-e2e /tmp/hyperdoc-pr12-evidence
```

Both cases must print `"passed": true`; their reports are `/tmp/hyperdoc-pr12-evidence/run-*/report.json` with
`integrationCase` `standalone` and `inspector`. Each run's Catalog log must show the new startup assertions:

```bash
grep -h -E '^(ASDF-ORIGIN|CATALOG-MEMBERSHIP|EDITOR-MODE|PARSE-TREE-REFERENCE)' /tmp/hyperdoc-pr12-evidence/run-*/catalog.log
```

Expected per run: `ASDF-ORIGIN` lines naming this checkout, `CATALOG-MEMBERSHIP dreyeck/fedwiki-original-editor-demo once
among …`, `EDITOR-MODE isolated-loopback-editor`.

### 4. Optional: the read-only public appearance, locally

The packaged executable as the server runs it, with none of the demo's variables, on loopback only:

```bash
nix build .#hyperdoc-catalog --out-link result-pr12-package && env -u HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT -u HYPERDOC_FEDWIKI_EDITOR_TEST_ORIGIN -u HYPERDOC_FEDWIKI_EDITOR_TEST_MODE HYPERDOC_CATALOG_HOST=127.0.0.1 result-pr12-package/bin/hyperdoc-catalog 18412
```

Open `http://127.0.0.1:18412/`: *Original Wiki Editor Test* is listed once; *Editing One Isolated Wiki Page* says "This
Catalog has no isolated test site configured", shows mode `unconfigured`, and has no frame, no client link and no
*Read stored page again*. Ctrl-C stops it.

## Reporting back

Attach or paste, without secrets: the `git log -1` line, the `grep` outputs of steps 1–3, both E2E `report.json` files,
and any failing log in full. A failure is a result: report it rather than re-running until green.
