(:refactor-hyperdoc-local-delta-inventory
 (:upstream-commit "0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc")
 (:local-head "4f0e75af4bc83e2b8baabe62a05af80a67a88d72")
 (:recent-hyperdoc-boundary-repair "4f0e75af")
 (:diff-command
  "git diff --name-only --no-renames -z 0d5bd1b0fba64f0bf9ab1cea21f01603c058f7cc..HEAD")
 (:changed-paths-vs-upstream
  (:count 1195
   :top-level-counts
   ((:path ".codex" :count 1)
    (:path ".envrc" :count 1)
    (:path ".gitignore" :count 1)
    (:path "AGENTS.md" :count 1)
    (:path "Makefile" :count 1)
    (:path "README.md" :count 1)
    (:path "assets" :count 22)
    (:path "dev.sh" :count 1)
    (:path "docs" :count 1)
    (:path "dreyeck" :count 26)
    (:path "dreyeck-explorer" :count 1)
    (:path "dreyeck.asd" :count 1)
    (:path "fedwiki.asd" :count 1)
    (:path "flake.lock" :count 1)
    (:path "flake.nix" :count 1)
    (:path "hyperbook" :count 3)
    (:path "hyperbook-explorer" :count 13)
    (:path "hyperbook-fedwiki" :count 8)
    (:path "hyperbook-server" :count 9)
    (:path "hyperbook-wikipedia" :count 4)
    (:path "hyperbook.asd" :count 1)
    (:path "hyperdoc" :count 747)
    (:path "hyperdoc-explorer" :count 30)
    (:path "hyperdoc-fedwiki-loader-examples.asd" :count 1)
    (:path "hyperdoc-goldberg-programmer-as-reader" :count 13)
    (:path "hyperdoc-goldberg-programmer-as-reader.asd" :count 1)
    (:path "hyperdoc-inspector" :count 49)
    (:path "hyperdoc-scxml" :count 7)
    (:path "hyperdoc-shop3" :count 10)
    (:path "hyperdoc-shop3-asdf-refactor-plan.sexp" :count 1)
    (:path "hyperdoc.asd" :count 1)
    (:path "inspector-hyperdoc" :count 10)
    (:path "interaction-net" :count 2)
    (:path "interaction-net.asd" :count 1)
    (:path "nix" :count 28)
    (:path "njson" :count 2)
    (:path "njson.asd" :count 1)
    (:path "notes" :count 1)
    (:path "package-lock.json" :count 1)
    (:path "package.json" :count 1)
    (:path "repomix.config.core.json" :count 1)
    (:path "repomix.config.deployment.json" :count 1)
    (:path "repomix.config.dm6.json" :count 1)
    (:path "repomix.config.dmx.json" :count 1)
    (:path "repomix.config.dock.json" :count 1)
    (:path "repomix.config.fedwiki.json" :count 1)
    (:path "repomix.config.full.json" :count 1)
    (:path "repomix.config.json" :count 1)
    (:path "repomix.config.validation.json" :count 1)
    (:path "repomix.config.zotero.json" :count 1)
    (:path "start.sh" :count 1)
    (:path "tests" :count 114)
    (:path "tools" :count 64))))
 (:classification-policy
  ((:rule "Previously modeled Dreyeck extraction buckets remain authoritative for their 44 listed paths.")
   (:rule "Current dreyeck/ and dreyeck.asd paths are dreyeck-owned situated surfaces.")
   (:rule "Codex, Kioskbeerli, Hauptsache, and local collaboration pages are dreyeck-owned or downstream situated surfaces unless a later read proves generic substrate.")
   (:rule "FedWiki page-attached assets and generated page-specific assets are page-attached assets.")
   (:rule "The SHOP3 provider boundary repair is a necessary local core delta until a better upstream-generic provider seam exists.")
   (:rule "All paths not classified by a positive rule are manual-review, not core by default.")))
 (:classification-summary
  ((:dreyeck-owned-situated-surface 57)
   (:page-attached-asset 47)
   (:necessary-local-core-delta 16)
   (:manual-review 1075)
   (:upstream-core 0)
   (:compatibility-shell 0)
   (:obsolete-delete 0)))
 (:paths-already-covered-by-existing-dreyeck-extraction-plan
  ((:runtime-hooks
    ("assets/hyperbook-server/js/url.js"
     "hyperbook-server/assets/hyperbook-server/js/url.js"
     "hyperbook-server/inspector-performance.lisp"
     "hyperbook-server/inspector-wiring.lisp"
     "hyperbook-server/playground-bindings.lisp"
     "hyperbook-server/playground-package.lisp"
     "hyperbook-server/playground-stepper.lisp"
     "hyperbook-server/server.lisp"))
   (:local-deployment
    (".envrc"
     "flake.lock"
     "flake.nix"
     "nix/hosts/dreyeck-ch-fallback-hardware.nix"
     "nix/hosts/dreyeck-ch.nix"
     "nix/hosts/dreyeck-ch/hardware-configuration.nix"
     "nix/modules/hyperdoc-release.nix"
     "nix/release/package.nix"
     "start.sh"))
   (:page-content-overlays
    ("hyperdoc-inspector/playground-restarts.html"
     "hyperdoc/Back up dreyeck.ch before deployment.html"
     "hyperdoc/Confirm scoped example parity on dreyeck.html"
     "hyperdoc/Deploy dreyeck.ch from the local flake.html"
     "hyperdoc/Deploy or restart dreyeck and confirm live parity.html"
     "hyperdoc/Detect legacy workspace-checkout hyperdoc.service on dreyeck.ch.html"
     "hyperdoc/Diagnose sbcl command-not-found in the legacy hyperdoc.service.html"
     "hyperdoc/Get hauptsache working on dreyeck.ch.html"
     "hyperdoc/Landing Page Redirect to Local Boot.html"
     "hyperdoc/Live parity evidence.html"
     "hyperdoc/New team member onboarding for dreyeck operations.html"
     "hyperdoc/Onboarding dreyeck deployment and restart.html"
     "hyperdoc/Probe dreyeck runtime load set.html"
     "hyperdoc/Record dreyeck.ch generation before rebuild.html"
     "hyperdoc/Rehearse dreyeck.ch deployment with runner.html"
     "hyperdoc/Restart dreyeck release service.html"
     "hyperdoc/Roll back HyperDoc on dreyeck.ch.html"
     "hyperdoc/Training arc: deploy and restart dreyeck safely.html"
     "hyperdoc/Training arc: verify scoped examples after deployment.html"
     "hyperdoc/Verify HyperDoc locally before deployment.html"
     "hyperdoc/Verify HyperDoc on dreyeck.ch.html"))
   (:glue-code
    ("dev.sh"
     "nix/patches/clog-boot-ignore-empty-ids.patch"
     "nix/patches/clog-moldable-inspector-playground-eval.patch"
     "nix/sbcl-named-closure.nix"
     "nix/vendor/named-closure/named-closure.asd"
     "nix/vendor/named-closure/named-closure.lisp"))))
 (:paths-not-covered-by-existing-plan
  (:count 1151
   :classification "covered by new umbrella classification rules or manual-review"))
 (:sample-classified-paths
  ((:dreyeck-owned-situated-surface
    ("dreyeck.asd"
     "dreyeck/codex.lisp"
     "dreyeck/dmx/sqlite/store.lisp"
     "dreyeck/build/tasks.lisp"
     "hyperdoc/Kioskbeerli Dashboard.html"
     "hyperdoc/Codex Handover Prompt.html"
     "hyperdoc/codex-compat.lisp"))
   (:page-attached-asset
    ("assets/dm6-elm/app.js"
     "assets/hyperdoc/js/scxml-architect.js"
     "hyperdoc-goldberg-programmer-as-reader/pages/Goldberg Programmer as Reader.html"
     "hyperdoc/fedwiki-asdf-assets/metagraph/src/topicmaps.lisp"))
   (:necessary-local-core-delta
    ("hyperdoc-shop3/provider-boundary.lisp"
     "hyperdoc-shop3/provider-boundary-package.lisp"
     "hyperdoc/zettel-9182-shop3-provider-boundary-repair-plan.sexp"
     "hyperdoc/HyperDoc Core.md"
     "hyperdoc/Ownership Extraction with Compatibility Shell.md"))
   (:manual-review
    ("hyperdoc.asd"
     "hyperbook.asd"
     "hyperbook-fedwiki/story-items.lisp"
     "hyperdoc/package.lisp"
     "hyperdoc/core.lisp"
     "tests/test-runner.lisp"))))
 (:all-deltas-classified-or-manual-review t)
 (:file-moves nil)
 (:deletions nil)
 (:destructive-edits nil))
