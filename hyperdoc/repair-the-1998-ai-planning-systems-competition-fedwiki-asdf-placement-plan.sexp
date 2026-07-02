(:artifact
 (:id repair-the-1998-ai-planning-systems-competition-fedwiki-asdf-placement)
 (:title "Repair The 1998 AI Planning Systems Competition FedWiki ASDF Placement")
 (:type :shop3-plan)
 (:status :closed)
 (:created-for-slice
  "Correct the McDermott 2000 FedWiki page-attached ASDF system placement")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:fedwiki-site-root "/Users/rgb/.wiki/wiki.ralfbarkow.ch")
 (:page-identity "the-1998-ai-planning-systems-competition")
 (:misplaced-root
  "/Users/rgb/workspace/hyperdoc/hyperdoc/fedwiki-asdf-assets/the-1998-ai-planning-systems-competition/")
 (:page-attached-asset-root
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/")
 (:fedwiki-page
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/the-1998-ai-planning-systems-competition")
 (:page-local-asdf-entrypoint
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.asd")
 (:attached-dmx-topic-sqlite-database
  "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.dmx.sqlite")
 (:plan-topic repair-the-1998-ai-planning-systems-competition-fedwiki-asdf-placement)

 :knowledge
 ((placement-rule
   ((fedwiki-page-identity maps-to "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug>")
    (page-attached-assets map-to "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/")
    (page-local-asdf-entrypoint maps-to "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/<slug>.asd")))
  (terminology
   ((preferred "FedWiki page-attached ASDF system")
    (preferred "FedWiki page identity")
    (preferred "page-attached asset root")
    (preferred "page-local ASDF entrypoint")
    (preferred "attached DMX topic SQLite database")
    (preferred "FedWiki page projection")
    (avoid "obsolete local-source-of-truth wording")
    (avoid "SQLite DB is the FedWiki page")))
  (sqlite-role
   "The DMX topic SQLite database is an attached page asset containing structured topics, associations, source fragments, story-item data, and reconstruction data used by the page-local ASDF system to materialize or verify the FedWiki page projection."))

 :input
 ((hyperdoc-repo "/Users/rgb/workspace/hyperdoc")
  (fedwiki-site "/Users/rgb/.wiki/wiki.ralfbarkow.ch")
  (current-misplaced-system
   "/Users/rgb/workspace/hyperdoc/hyperdoc/fedwiki-asdf-assets/the-1998-ai-planning-systems-competition/")
  (user-copied-readme
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/README.md"))

 :repair-commits
 ((plan-commit
   (:repo "/Users/rgb/workspace/hyperdoc"
    :commit "ff9c058f"
    :summary "docs(planning): plan FedWiki ASDF placement repair"))
  (hyperdoc-implementation
   (:repo "/Users/rgb/workspace/hyperdoc"
    :commit "3ce91527"
    :summary "fix(planning): move McDermott ASDF system to page assets"))
  (fedwiki-assets
   (:repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets"
    :commit "de8679e2"
    :summary "fix(planning): add McDermott page-attached ASDF assets"))
  (fedwiki-pages
   (:repo "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages"
    :commit "d5ed7df5"
    :summary "fix(planning): materialize McDermott FedWiki page projection")))

 :validation-results
 ((misplaced-root-removed t)
  (asset-side-pages-directory-absent t)
  (canonical-paths-present t)
  (staged-whitespace-checks-pass t)
  (sqlite-counts
   ((dmx-topics 25)
    (dmx-associations 18)
    (fedwiki-story-items 9)))
  (page-local-asdf-load-through-fedwiki-attached-system t)
  (test-system-passes t)
  (materialization
   ((db-path
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.dmx.sqlite")
    (page-path
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/the-1998-ai-planning-systems-competition")
    (topics-present-p t)
    (associations-present-p t)
    (network-required-p nil)))
  (idempotence
   ((idempotent-p t)
    (page-bytes 3188)
    (network-required-p nil))))

 :shop3
 ((:task repair-the-1998-ai-planning-systems-competition-fedwiki-asdf-placement
   :goal
   ((plan-artifact recorded)
    (plan-artifact validated)
    (misplaced-system inspected)
    (fedwiki-page-and-asset-roots identified)
    (page-attached-asdf-files moved)
    (dmx-sqlite-asset moved)
    (fedwiki-page materialized-to-page-store)
    (readme-and-agents-terminology rewritten)
    (path-constants rewritten)
    (page-local-asdf-load validated)
    (dmx-sqlite-asset-location validated)
    (page-materialization idempotent)
    (smoke-tests pass)
    (repair committed)
    (plan-artifact closed)))

  (:operator !record-plan-artifact
   :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc"))
   :effects ((plan-artifact recorded)
             (plan-status :open)))

  (:operator !validate-plan-artifact
   :preconditions ((plan-artifact recorded))
   :effects ((plan-artifact includes-required-repair-tasks)
             (plan-artifact uses-page-attached-asdf-terminology)
             (plan-artifact validated)))

  (:operator !inspect-current-misplaced-system
   :preconditions ((plan-artifact validated))
   :effects ((misplaced-system inspected)
             (misplaced-files checksummed)))

  (:operator !identify-fedwiki-page-and-asset-roots
   :preconditions ((misplaced-system inspected))
   :effects ((fedwiki-page-root identified)
             (page-attached-asset-root identified)
             (page-local-asdf-entrypoint identified)))

  (:operator !move-page-attached-asdf-files
   :preconditions ((fedwiki-page-and-asset-roots identified))
   :effects ((asdf-entrypoint moved-to-page-attached-asset-root)
             (source-files moved-to-page-attached-asset-root)
             (tests moved-to-page-attached-asset-root)
             (examples moved-to-page-attached-asset-root)
             (manifest moved-to-page-attached-asset-root)))

  (:operator !move-dmx-sqlite-asset
   :preconditions ((page-attached-asdf-files moved))
   :effects ((attached-dmx-topic-sqlite-database moved-to-asset-root)
             (sqlite-asset-checksum verified)))

  (:operator !materialize-fedwiki-page-to-page-store
   :preconditions ((attached-dmx-topic-sqlite-database moved-to-asset-root))
   :effects ((fedwiki-page materialized-to-page-store)
             (asset-side-pages-directory not-canonical)))

  (:operator !rewrite-readme-and-agents-terminology
   :preconditions ((fedwiki-page materialized-to-page-store))
   :effects ((readme uses-page-attached-asdf-contract)
             (agents uses-page-attached-asdf-contract)
             (misleading-local-source-of-truth-wording removed)))

  (:operator !rewrite-path-constants
   :preconditions ((readme-and-agents-terminology rewritten))
   :effects ((lisp-path-constants point-at-page-attached-asset-root)
             (tests point-at-page-attached-asset-root)
             (examples point-at-page-attached-asset-root)
             (page-system-descriptor points-at-fedwiki-page-and-assets)
             (plan-artifacts record-placement-correction)))

  (:operator !validate-page-local-asdf-load
   :preconditions ((path-constants rewritten))
   :effects ((load-fedwiki-attached-asdf-system succeeds)
             (asdf-load-system succeeds)))

  (:operator !validate-dmx-sqlite-asset-location
   :preconditions ((page-local-asdf-load validated))
   :effects ((sqlite-db exists-at-page-attached-asset-root)
             (sqlite-db reports-expected-counts)))

  (:operator !validate-page-materialization-idempotence
   :preconditions ((dmx-sqlite-asset-location validated))
   :effects ((fedwiki-page-projection idempotent)
             (second-materialization no-semantic-change)))

  (:operator !run-smoke-tests
   :preconditions ((page-materialization idempotent))
   :effects ((test-system passes)
             (no-live-dmx-server-required)
             (no-live-fedwiki-server-required)))

  (:operator !commit-repair
   :preconditions ((smoke-tests pass))
   :effects ((repair committed)
             (hyperdoc-implementation-commit "3ce91527")
             (fedwiki-assets-commit "de8679e2")
             (fedwiki-pages-commit "d5ed7df5")))

  (:operator !close-plan-artifact
   :preconditions ((repair committed))
   :effects ((plan-status :closed)
             (plan-artifact records-repair-commits)
             (plan-artifact closed))))

 :output-contract
 ((misplaced-root-removed
   "/Users/rgb/workspace/hyperdoc/hyperdoc/fedwiki-asdf-assets/the-1998-ai-planning-systems-competition/")
  (page-attached-asset-root
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/")
  (fedwiki-page
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/the-1998-ai-planning-systems-competition")
  (validation
   ((page-local-asdf-load t)
    (test-system-passes t)
    (sqlite-counts-inspectable t)
    (materialization-idempotent t)
    (terminology-corrected t)
    (git-status-reported t)))))
