;;;; Live SHOP3 domain for selecting the ASDF owner of the DMX SQLite system.

(in-package #:dreyeck.dmx.workspace-selection)

;; Keep SHOP3 operator order: (:operator task preconditions delete-list add-list).
(defdomain dreyeck-dmx-workspace-selection
  ((:operator (!select-hyperdoc-dreyeck-owner)
    ((repo hyperdoc)
     (hyperdoc-owns-primary-dreyeck-asd)
     (desired-final-system dreyeck/dmx/sqlite)
     (asdf-slash-system-requires-primary-owner)
     (avoid-shadowing-dreyeck-asd)
     (keep-hyperdoc-core-virtually-unchanged)
     (extensions-belong-in-dreyeck))
    ()
    ((selected-workspace hyperdoc-dreyeck-owner)))

   (:operator (!select-hauptsache-local-owner)
    ((allow-hauptsache-local-owner))
    ()
    ((selected-workspace hauptsache-local-owner)))

   (:operator (!select-shared-dreyeck-source-tree)
    ((allow-shared-dreyeck-source-tree))
    ()
    ((selected-workspace shared-dreyeck-source-tree)))

   (:operator (!defer-for-more-evidence)
    ((more-evidence-required))
    ()
    ((selected-workspace deferred-for-more-evidence)))

   (:method (select-dmx-sqlite-workspace)
    ((repo hyperdoc)
     (repo hauptsache)
     (hyperdoc-owns-primary-dreyeck-asd)
     (hauptsache-has-local-system hauptsache-dmx-sqlite)
     (desired-final-system dreyeck/dmx/sqlite)
     (asdf-slash-system-requires-primary-owner)
     (avoid-shadowing-dreyeck-asd)
     (keep-hyperdoc-core-virtually-unchanged)
     (extensions-belong-in-dreyeck)
     (main-has-working-kioskbeerli-baseline)
     (recorder-wip-isolated)
     (property-journal-sync-plan-exists))
    ((!select-hyperdoc-dreyeck-owner)))

   (:method (select-dmx-sqlite-workspace)
    ((allow-hauptsache-local-owner))
    ((!select-hauptsache-local-owner)))

   (:method (select-dmx-sqlite-workspace)
    ((allow-shared-dreyeck-source-tree))
    ((!select-shared-dreyeck-source-tree)))

   (:method (select-dmx-sqlite-workspace)
    ((more-evidence-required))
    ((!defer-for-more-evidence)))))
