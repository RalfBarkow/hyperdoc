(:refactor-hyperdoc-asdf-ownership-inventory
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:asdf-files
  ("dreyeck.asd"
   "fedwiki.asd"
   "hyperbook.asd"
   "hyperdoc-fedwiki-loader-examples.asd"
   "hyperdoc-goldberg-programmer-as-reader.asd"
   "hyperdoc.asd"
   "hyperdoc/hyperdoc-mech-run-records-minimal.asd"
   "interaction-net.asd"
   "njson.asd"))
 (:hyperdoc-asdf-systems
  (:candidate-upstream-or-local-core
   (:hyperdoc/kernel
    :hyperdoc/s-expression-prompts
    :hyperdoc/s-expression-prompts/tests
    :hyperdoc/executable-dita-tasks
    :hyperdoc/executable-dita-tasks/tests
    :hyperdoc/topics
    :hyperdoc/dmx-topics
    :hyperdoc/checks
    :hyperdoc/state-machines
    :hyperdoc
    :hyperdoc/shop3-provider-boundary
    :hyperdoc/shop3-provider-boundary/tests
    :hyperdoc/shop3
    :hyperdoc/scxml
    :hyperdoc/scxml-workflows)
   :candidate-page-or-content-asset
   (:hyperdoc/mobile-progressive-chrome
    :hyperdoc/fedwiki-asdf-assets
    :hyperdoc-goldberg-programmer-as-reader
    :hyperdoc-goldberg-programmer-as-reader/test
    :hyperdoc/mech-run-records)
   :candidate-compatibility-shells
   (:hyperdoc/codex
    :hyperdoc/codex/examples
    :hyperdoc/codex/explorer)
   :manual-review
   (:hyperdoc/zotero-support
    :hyperdoc/bibliography
    :hyperdoc/zotero
    :hyperdoc/examples
    :hyperdoc/examples/ops
    :hyperdoc/nor-demo
    :hyperdoc/nor-graph-demo
    :hyperdoc/closures-nor-demo
    :hyperdoc/continuation-route-trace
    :hyperdoc/dmx-import
    :hyperdoc/fedwiki
    :hyperdoc/mcp
    :hyperdoc/inspector
    :hyperdoc/inspector/zotero
    :hyperdoc/explorer
    :hyperdoc/explorer/examples/ops
    :hyperdoc/server
    :hyperdoc/tests
    :hyperdoc/tests/zotero
    :hyperdoc/git
    :hyperdoc/inspector/git
    :hyperdoc/zkn3-import-report-projection
    :hyperdoc/zkn3-import-report-projection/tests)))
 (:dreyeck-asdf-systems
  (:existing
   (:dreyeck/server
    :dreyeck
    :dreyeck/codex
    :dreyeck/codex/examples
    :dreyeck/codex/explorer
    :dreyeck/codex/tests
    :dreyeck/dmx/workspace-selection
    :dreyeck/dmx/workspace-selection/tests
    :dreyeck/dmx/sqlite
    :dreyeck/dmx/sqlite/tests
    :dreyeck/build
    :dreyeck/build/tests
    :dreyeck/zettelkasten))
  :ownership "Situated collaboration, DMX, build/referee, zettelkasten, and local server scaffold surfaces.")
 (:hyperbook-asdf-systems
  (:manual-review
   (:hyperbook
    :hyperbook/explorer
    :hyperbook/server
    :hyperbook/wikipedia
    :hyperbook/fedwiki)))
 (:other-asdf-systems
  (:manual-review
   (:fedwiki
    :hyperdoc-fedwiki-loader-examples
    :interaction-net
    :njson
    :njson/jzon)))
 (:package-definitions
  ((:package :hyperdoc
    :file "hyperdoc/package.lisp"
    :classification :manual-review
    :note "Large export surface; must be split only after caller and downstream review.")
   (:package :dreyeck/codex
    :file "dreyeck/package.lisp"
    :classification :dreyeck-owned-situated-surface
    :sample-public-symbols
    (:codex
     :codex-context-window
     :codex-recent-changes
     :codex-next
     :codex-context-provider-result))
   (:package :dreyeck/server
    :file "dreyeck/package.lisp"
    :classification :dreyeck-owned-situated-surface
    :sample-public-symbols
    (:install-dreyeck-server-scaffold
     :dreyeck-local-boot-link-redirection
     :dreyeck-link-target-rewriter))
   (:package :dreyeck.dmx.sqlite
    :file "dreyeck/dmx/sqlite/package.lisp"
    :classification :dreyeck-owned-situated-surface
    :sample-public-symbols
    (:materialize-durable-notes-into-production-db
     :durable-note-materialization-status
     :record-dmx-topic-value
     :record-dmx-association-value
     :dmx-sqlite-integrity-report))
   (:package :dreyeck/build
    :file "dreyeck/build/package.lisp"
    :classification :dreyeck-owned-situated-surface
    :sample-public-symbols
    (:plan-build-task
     :check-build-task
     :perform-build-task
     :build-session-status
     :run-build-task))
   (:package :hyperbook
    :file "hyperbook/package.lisp"
    :classification :manual-review)
   (:package :hyperbook/server
    :file "hyperbook-server/package.lisp"
    :classification :manual-review)
   (:package :hyperbook/fedwiki
    :file "hyperbook-fedwiki/package.lisp"
    :classification :manual-review)))
 (:known-downstream-consumers
  ((:hauptsache
    :repo-root "/Users/rgb/workspace/hauptsache"
    :recent-boundary-repair "a18158f"
    :uses (:hyperdoc :hyperdoc/shop3 :hyperdoc/scxml :hyperdoc/fedwiki-asdf-assets))
   (:kioskbeerli
    :repo-root "/Users/rgb/workspace/hauptsache/kioskbeerli"
    :status :downstream
    :must-not-become-hyperdoc-dependency t)))
 (:candidate-compatibility-shells
  ((:old-system :hyperdoc/codex :canonical-system :dreyeck/codex)
   (:old-system :hyperdoc/codex/examples :canonical-system :dreyeck/codex/examples)
   (:old-system :hyperdoc/codex/explorer :canonical-system :dreyeck/codex/explorer)))
 (:asdf-introspection
  ((:requested-sample-command
    (:result :failed
     :reason "ASDF:ALREADY-LOADED-SYSTEMS returned system names as strings in this image, not ASDF component objects."))
   (:fallback-command
    "nix develop -c sbcl --noinform --disable-debugger --eval '(require :asdf)' ...")
   (:fallback-result
    ((:system "hyperdoc" :status :found :source "hyperdoc.asd")
     (:system "hyperdoc/kernel" :status :found :source "hyperdoc.asd")
     (:system "hyperdoc/shop3-provider-boundary" :status :found :source "hyperdoc.asd")
     (:system "hyperdoc/shop3" :status :found :source "hyperdoc.asd")
     (:system "dreyeck" :status :found :source "dreyeck.asd")
     (:system "dreyeck/codex" :status :found :source "dreyeck.asd")
     (:system "dreyeck/dmx/sqlite" :status :found :source "dreyeck.asd")
     (:system "dreyeck/build" :status :found :source "dreyeck.asd")
     (:system "hyperbook" :status :found :source "hyperbook.asd")
     (:system "hyperbook/server" :status :found :source "hyperbook.asd"))))))
