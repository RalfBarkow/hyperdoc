# kioskberrli

`kioskberrli` is the canonical ASDF system for the Kioskberrli dashboard,
planner, trace, SCXML lifecycle artifact, inspector views, FedWiki page assets,
and optional local SQLite persistence.

## Load From SLY

Start the repo dev shell, then load the system:

```lisp
(asdf:load-system :kioskberrli)
```

Compatibility systems and package nicknames are still present for older pages:

```lisp
(asdf:load-system :dreyeck/kioskbeerli)
```

The canonical spelling is `kioskberrli`. The older `kioskbeerli` spelling is
kept only as an alias for existing source/page references.

## Demo Objects

```lisp
(kioskberrli:make-demo-dashboard)
(kioskberrli:make-demo-plan)
(kioskberrli:make-demo-trace)
(kioskberrli:inspect-demo-dashboard)
```

These entrypoints are local and safe: they do not build Nix images, flash SD
cards, contact devices, write DMX, or require Neo4j.

## FedWiki Page Assets

The localhost FedWiki page is:

```text
http://localhost:3000/view/kioskberrli
```

Materialize the page-local ASDF distribution tree:

```lisp
(kioskberrli:materialize-fedwiki-assets
 :slug "kioskberrli"
 :root #p"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/")
```

The asset URL shape is:

```text
http://localhost:3000/assets/pages/kioskberrli/...
```

The generated ASDF file is directly at:

```text
assets/pages/kioskberrli/kioskberrli.asd
```

FedWiki assets are generated distribution artifacts. The source of truth remains
the source-controlled Lisp in this `kioskberrli/` directory.

## Optional SQLite

Core loading does not require SQLite. SQLite support uses the external
`sqlite3` command, following HyperDoc's local query-store pattern.

```lisp
(kioskberrli:open-or-create-sqlite-store
 :db-path #p"/tmp/kioskberrli.sqlite"
 :ensure-schema t)
```

If `sqlite3` is missing or cannot run, SQLite functions signal
`kioskberrli:kioskberrli-sqlite-unavailable`. Tests skip SQLite cases cleanly
when the command is unavailable. Generated `.sqlite` files are not committed.

## Smoke Tests

```lisp
(asdf:load-system :kioskberrli/tests :force t)
(kioskberrli/tests:run-kioskberrli-smoke-tests)
```
