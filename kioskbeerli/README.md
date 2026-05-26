# kioskbeerli

`kioskbeerli` is the canonical ASDF system for the Kioskbeerli dashboard,
planner, trace, SCXML lifecycle artifact, inspector views, FedWiki page assets,
and optional local SQLite persistence.

## Load From SLY

Start the repo dev shell, then load the system:

```lisp
(asdf:load-system :kioskbeerli)
```

Compatibility systems and package nicknames are still present for older pages:

```lisp
(asdf:load-system :dreyeck/kioskbeerli)
```

The canonical spelling is `kioskbeerli`; `:dreyeck/kioskbeerli` remains only as
a downstream namespace alias.

## Demo Objects

```lisp
(kioskbeerli:make-demo-dashboard)
(kioskbeerli:make-demo-plan)
(kioskbeerli:make-demo-trace)
(kioskbeerli:inspect-demo-dashboard)
```

These entrypoints are local and safe: they do not build Nix images, flash SD
cards, contact devices, write DMX, or require Neo4j.

## Raspberry Pi Den Base-System Milestone

The current Pi checkpoint is documented in
[`raspberry-pi-den-base-system.md`](raspberry-pi-den-base-system.md).

That runbook records the verified Den-based flake switch that survived reboot,
the local backup under `var/kioskbeerli-pi-backup/`, read-only verification
commands, and the reconstruction path for `/etc/nixos`. The backup remains a
local operator artifact and is not committed.

## FedWiki Page Assets

The localhost FedWiki page is:

```text
http://localhost:3000/view/kioskbeerli
```

Materialize the page-local ASDF distribution tree:

```lisp
(kioskbeerli:materialize-fedwiki-assets
 :slug "kioskbeerli"
 :root #p"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/")
```

The asset URL shape is:

```text
http://localhost:3000/assets/pages/kioskbeerli/...
```

The generated ASDF file is directly at:

```text
assets/pages/kioskbeerli/kioskbeerli.asd
```

FedWiki assets are generated distribution artifacts. The source of truth remains
the source-controlled Lisp in this `kioskbeerli/` directory.

## Optional SQLite

Core loading does not require SQLite. SQLite support uses the external
`sqlite3` command, following HyperDoc's local query-store pattern.

```lisp
(kioskbeerli:open-or-create-sqlite-store
 :db-path #p"/tmp/kioskbeerli.sqlite"
 :ensure-schema t)
```

If `sqlite3` is missing or cannot run, SQLite functions signal
`kioskbeerli:kioskbeerli-sqlite-unavailable`. Tests skip SQLite cases cleanly
when the command is unavailable. Generated `.sqlite` files are not committed.

## Smoke Tests

```lisp
(asdf:load-system :kioskbeerli/tests :force t)
(kioskbeerli/tests:run-kioskbeerli-smoke-tests)
```
