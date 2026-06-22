;;;; Problem facts for the live Dreyeck DMX SQLite ownership selection.

(in-package #:dreyeck.dmx.workspace-selection)

(defparameter *dmx-sqlite-workspace-selection-facts*
  '((repo hyperdoc)
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
    (property-journal-sync-plan-exists)))

(defproblem dreyeck-dmx-sqlite-workspace-selection-001
  dreyeck-dmx-workspace-selection
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
  ((select-dmx-sqlite-workspace)))

(defparameter *dmx-sqlite-next-task-selection-facts*
  '((repo hyperdoc)
    (repo hauptsache)
    (hyperdoc-owns-primary-dreyeck-asd)
    (dreyeck-owns-dmx-sqlite)
    (hauptsache-depends-on-dreyeck-dmx-sqlite)
    (hauptsache-local-dmx-sqlite-removed)
    (property-journal-sync-gap-open)
    (recorder-wip-isolated)
    (old-hauptsache-property-journal-branch-historical)
    (avoid-recorder-replay-before-store-parity)
    (keep-hyperdoc-core-virtually-unchanged)
    (extensions-belong-in-dreyeck)))

(defproblem dreyeck-dmx-sqlite-next-task-selection-001
  dreyeck-dmx-workspace-selection
  ((repo hyperdoc)
   (repo hauptsache)
   (hyperdoc-owns-primary-dreyeck-asd)
   (dreyeck-owns-dmx-sqlite)
   (hauptsache-depends-on-dreyeck-dmx-sqlite)
   (hauptsache-local-dmx-sqlite-removed)
   (property-journal-sync-gap-open)
   (recorder-wip-isolated)
   (old-hauptsache-property-journal-branch-historical)
   (avoid-recorder-replay-before-store-parity)
   (keep-hyperdoc-core-virtually-unchanged)
   (extensions-belong-in-dreyeck))
  ((select-dmx-sqlite-next-task)))
