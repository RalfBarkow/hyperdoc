# Operator guide: the Original Wiki Editor demo on dreyeck.ch

For the operator, on the server, as root. HyperDoc runs none of this and adds no SSH automation. Nothing here starts,
stops or restarts a service except the final `switch`, which needs its own approval. No step writes a Wiki file.
Background and open decisions: [README.md](README.md).

**This step changes the HyperDoc package only.** It adds no service variable, does not touch `wiki.service`,
nginx or any Wiki data, and grants no write permission. On the server the demo stays *unconfigured* and read-only.

## Before the server

On a machine that can reach codeberg.org (this change's container could not), at the reviewed commit:

```bash
nix build .#checks.x86_64-linux.catalog -L
```

```bash
nix develop .#fedwiki-original-editor -c bash -c 'npm ci --prefix tests/fedwiki-original-editor --ignore-scripts --no-audit --no-fund && node --test tests/fedwiki-original-editor/commands.test.mjs tests/fedwiki-original-editor/server.test.mjs && fedwiki-original-editor-e2e'
```

Both must pass (the E2E runs the standalone and the Inspector case); the full list with expected output is in
[verification.md](verification.md). The change must be in the branch the server's
`hyperdoc` input follows (recorded as `github:RalfBarkow/hyperdoc?ref=dreyeck.ch`) or pinned to its reviewed commit,
as in [CATALOG-OPERATIONS.md](../../dreyeck/CATALOG-OPERATIONS.md#choose-one-update-mode).

## 1. Record the current state (read-only)

```bash
receipt=$(mktemp -d /var/tmp/hyperdoc-editor-demo.XXXXXXXX); echo "$receipt"
```

```bash
readlink -f /run/current-system | tee "$receipt/previous-system"; nix-env --list-generations --profile /nix/var/nix/profiles/system | tail -n 3 | tee "$receipt/generations"
```

```bash
systemctl show hyperdoc.service -p ExecStart -p MainPID -p ActiveState -p ActiveEnterTimestamp --no-pager | tee "$receipt/hyperdoc-unit"
```

The service's HyperDoc variables, names and values (they are expected to hold no secrets; check before sharing):

```bash
systemctl show hyperdoc.service -p Environment --value | tr ' ' '\n' | grep '^HYPERDOC_' | tee "$receipt/hyperdoc-environment"
```

Record in particular whether `HYPERDOC_CATALOG_SYSTEM` is set and to what. Where it is declared:

```bash
grep -rn 'HYPERDOC_' /etc/nixos --include='*.nix'
```

```bash
cd /etc/nixos && cp -p flake.nix flake.lock "$receipt/" && ls /etc/nixos
```

The Wiki farm, for the open decisions only (it is not changed by this step); record its PID and start time so that you
can show afterwards it was not restarted:

```bash
systemctl show wiki.service -p ExecStart -p User -p MainPID -p ActiveEnterTimestamp --no-pager | tee "$receipt/wiki-unit"
```

Only the non-secret settings of the farm configuration (never print `cookieSecret`, `admin` or a `wikiDomains` entry's
values); `jq` from `nix shell nixpkgs#jq` if it is not installed. The path is the one recorded earlier; use the
`--config` of the `ExecStart` just shown if it differs:

```bash
jq '{farm, port, data, security_type, security_legacy, secure_cookie, allowed, wikiDomainNames: ((.wikiDomains // {}) | keys)}' /home/rgb/.wiki/config.json
```

The nginx routes and any frame header (for D4/D5):

```bash
nginx -T 2>/dev/null | grep -nE 'server_name|proxy_pass|X-Frame-Options|frame-ancestors|Content-Security-Policy'
```

The Catalog as served now: open `https://dreyeck.ch/` in a browser and note the number of HyperBooks (reported: 24) and
whether *Original Wiki Editor Test* is listed (expected: not yet).

## 2. The configuration change

**None in `hyperdoc-service.nix`.** The demo is a member of the default Catalog (`dreyeck/catalog`), so:

| Variable | Change |
|---|---|
| `HYPERDOC_CATALOG_SYSTEM` | **unchanged** — keep exactly the value recorded in step 1, or keep it unset. Do not set it to `dreyeck/fedwiki-original-editor-demo`: the variable names one system and would displace the current one. |
| `HYPERDOC_CATALOG_HOST`, `HYPERDOC_FEDWIKI_SITE_ROOT`, `HYPERDOC_MECH_PLUGIN_HOST_URL` | unchanged |
| `HYPERDOC_FEDWIKI_EDITOR_TEST_ROOT`, `…_ORIGIN`, `…_MODE` | **do not set** on the server. Unset is the intended *unconfigured* state. In particular never `…_MODE=isolated-loopback`, and never a `…_ROOT` that is a personal site such as `/home/rgb/.wiki/dreyeck.ch/`. |

Only the `hyperdoc` input moves:

```bash
cd /etc/nixos && nix flake update hyperdoc && diff -u "$receipt/flake.lock" flake.lock
```

Gate: only the `hyperdoc` node changes, to the reviewed commit.

## 3. Build and dry-activate

```bash
cd /root && nixos-rebuild build --flake /etc/nixos#dreyeck && readlink -f result | tee "$receipt/built-system"
```

```bash
cd /root && nix store diff-closures /run/current-system ./result
```

```bash
diff /run/current-system/etc/systemd/system/hyperdoc.service /root/result/etc/systemd/system/hyperdoc.service
```

```bash
diff /run/current-system/etc/systemd/system/wiki.service /root/result/etc/systemd/system/wiki.service && echo "wiki.service unchanged"
```

```bash
cd /root && nixos-rebuild dry-activate --flake /etc/nixos#dreyeck
```

Gates: the closure difference is the HyperDoc `source` and `hyperdoc-catalog`; `hyperdoc.service` differs in its
`ExecStart` store path only, its `Environment=` lines are identical; `wiki.service` and nginx are unchanged;
`dry-activate` would restart `hyperdoc.service` only. Anything else: stop, restore the lock from the receipt, report.

## 4. Activate (separate approval)

```bash
cd /root && nixos-rebuild switch --flake /etc/nixos#dreyeck
```

The first start compiles the new sources; the Catalog is unavailable for that time (68–80 s in the builder for the
one-catalog change, longer on the server's CPU).

## 5. Acceptance

```bash
test "$(readlink -f /run/current-system)" = "$(cat "$receipt/built-system")" && systemctl is-active hyperdoc.service
```

```bash
journalctl -u hyperdoc.service -b --since "-15 min" --no-pager | grep -E 'Topic Maps snapshot verified|HyperBook Catalog listening|startup (failed|refused)'
```

```bash
systemctl show wiki.service -p MainPID -p ActiveEnterTimestamp --no-pager | diff - <(grep -E '^(MainPID|ActiveEnterTimestamp)=' "$receipt/wiki-unit") && echo "wiki.service not restarted"
```

```bash
find /home/rgb/.wiki -newer "$receipt/previous-system" -maxdepth 3 -printf '%TY-%Tm-%Td %TH:%TM %u %p\n' | head -n 20
```

The last command lists Wiki files changed since step 1; this step causes none (normal Wiki editing by people may).

In a browser, on `https://dreyeck.ch/`:

1. The Catalog lists **Original Wiki Editor Test** exactly once; every HyperBook listed before is still listed
   (the count is the previous one plus one).
2. *Original Wiki Editor Test → Text pages → Editing One Isolated Wiki Page* shows "This Catalog has no isolated test
   site configured" and the configuration table with mode `unconfigured`; no error box, no frame, no *Open original
   Wiki client* link and no *Read stored page again* button.
3. The HyperBooks from `HYPERDOC_CATALOG_SYSTEM` (if one was recorded in step 1) are still present.

Falsified if: a HyperBook from before is missing or listed twice, the demo page shows a Lisp condition or a frame, the
unit's environment differs, or `wiki.service` was restarted.

## 6. Rollback

Whole system, to the generation recorded in step 1:

```bash
nixos-rebuild switch --rollback
```

Or the sources, then build and switch as in steps 3–4:

```bash
cd /etc/nixos && cp -p "$receipt/flake.nix" "$receipt/flake.lock" .
```

Neither touches Wiki data, the Wiki farm or the Mech asset selection. Nothing is garbage-collected.

## Not part of this step

Creating or claiming a farm test site, setting `HYPERDOC_FEDWIKI_EDITOR_TEST_*`, any frame adapter on the farm, any change
to `wiki.service`, `/home/rgb/.wiki/config.json` or nginx. Those wait for decisions D2–D6 in [README.md](README.md#decisions).
