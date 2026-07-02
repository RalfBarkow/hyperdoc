(:artifact
 (:id the-1998-ai-planning-systems-competition-fedwiki-asdf-system)
 (:title "The 1998 AI Planning Systems Competition FedWiki ASDF System")
 (:type :shop3-plan)
 (:status :closed)
 (:created-for-slice
  "FedWiki page-attached ASDF system for Drew V. McDermott, The 1998 AI Planning Systems Competition")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:slug "the-1998-ai-planning-systems-competition")
 (:system "the-1998-ai-planning-systems-competition")
 (:plan-topic the-1998-ai-planning-systems-competition-fedwiki-asdf-system)
 (:commit-references
  ((plan-commit "96cf921f")
   (implementation-commit "ab0fd446")
   (closing-commit "commit containing this plan closure")))

 :knowledge
 ((reading-source
   ((author "Drew V. McDermott")
    (title "The 1998 AI Planning Systems Competition")
    (venue "AI Magazine 21(2)")
    (year 2000)))
  (source-boundary
   ((do-not-copy-whole-pdf)
    (store-bibliography-source-anchors-short-excerpts-and-paraphrases)
    (dmx-sqlite-asset attached-page-asset)
    (fedwiki-page projection-from-dmx-sqlite)
    (validation local-first)
    (validation no-live-dmx-server)
    (validation no-live-fedwiki-server)))
  (reading-claims
   ((competition first-automated-planning-competition)
    (competition creates-shared-planning-domains)
    (competition supports-meaningful-planner-comparison)
    (competition starts-benchmark-repository)
    (pddl represents physics-not-advice)
    (hierarchical-planning-track failed-under-advice-separation)
    (zettel-6537 reads-planning-as-contingency-reduction)
    (shop3-methods expose-contingency-reduction))))

 :input
 ((repository-conventions
   ("hyperdoc/fedwiki-asdf-assets.lisp"
    "hyperdoc/fedwiki-attached-asdf-system.lisp"
    "hyperdoc/fedwiki-attached-asdf-relations.lisp"
    "hyperdoc-inspector/fedwiki-attached-asdf-system.lisp"
    "hyperdoc-inspector/fedwiki-attached-asdf-relations.lisp"
    "hyperdoc/topics/asdf.lisp"
    "hyperdoc/fedwiki-asdf-assets/metagraph"
    "dreyeck/dmx/sqlite"
    "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
    "hyperdoc/materialize-build-referee-learning-topics-plan.sexp"))
  (target-layout
   ("/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.asd"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/src/package.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/src/model.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/src/topics.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/src/dmx-sqlite.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/src/fedwiki-page.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/src/materialize.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/src/inspect.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.dmx.sqlite"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/the-1998-ai-planning-systems-competition"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/examples/mrepl-session.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/tests/package.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/tests/smoke.lisp"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/README.md"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/AGENTS.md"
    "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/MANIFEST.txt")))

 :shop3
 ((:task create-the-1998-ai-planning-systems-competition-fedwiki-asdf-system
   :goal
   ((plan-artifact recorded)
    (plan-artifact validated)
    (plan-artifact committed)
    (fedwiki-attached-asdf-system created)
    (dmx-topic-sqlite-asset created)
    (reading-topics seeded)
    (fedwiki-page materialized-from-dmx)
    (page-reconstruction idempotent)
    (smoke-tests pass)
    (implementation committed)
    (plan-artifact closed)))

  (:operator !record-plan-artifact
   :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc"))
   :effects ((plan-artifact recorded)
             (plan-status :open)))

  (:operator !validate-plan-artifact
   :preconditions ((plan-artifact recorded))
   :effects ((plan-artifact validates-required-operators)
             (plan-artifact validates-target-layout)
             (plan-artifact validated)))

  (:operator !commit-plan-artifact
   :preconditions ((plan-artifact validated)
                   (git-working-tree clean-before-plan))
   :effects ((plan-artifact committed)
             (plan-commit "96cf921f")))

  (:operator !create-fedwiki-attached-asdf-system
   :preconditions ((plan-artifact committed))
   :effects ((asdf-system "the-1998-ai-planning-systems-competition")
             (asdf-test-system "the-1998-ai-planning-systems-competition/test")
             (fedwiki-attached-home inspectable)
             (obsolete-repo-local-page-asdf-route not-used)))

  (:operator !create-dmx-topic-sqlite-asset
   :preconditions ((asdf-system "the-1998-ai-planning-systems-competition"))
   :effects ((sqlite-asset
              "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.dmx.sqlite")
             (dmx-topics-table exists)
             (dmx-associations-table exists)
             (dmx-assoc-players-table exists)
             (fedwiki-pages-table exists)
             (fedwiki-story-items-table exists)
             (fedwiki-journal-actions-table exists)
             (source-fragments-table exists)))

  (:operator !seed-reading-topics
   :preconditions ((sqlite-asset exists))
   :effects ((required-topics exist)
             (required-associations exist)
             (source-fragments recorded)))

  (:operator !materialize-fedwiki-page-from-dmx
   :preconditions ((required-topics exist)
                   (required-associations exist))
   :effects ((fedwiki-page-json
              "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/the-1998-ai-planning-systems-competition")
             (fedwiki-page includes-physics-not-advice)
             (fedwiki-page includes-planung-als-reduktion)))

  (:operator !validate-reconstruction-idempotence
   :preconditions ((fedwiki-page-json exists))
   :effects ((second-materialization semantic-diff nil)
             (page-reconstruction idempotent)))

  (:operator !run-smoke-tests
   :preconditions ((page-reconstruction idempotent))
   :effects ((asdf-load-system succeeds)
             (db-opens t)
             (schema-status inspectable)
             (required-topics exist)
             (required-associations exist)
             (page-reconstruction includes-physics-not-advice)
             (page-reconstruction includes-planung-als-reduktion)
             (network-required nil)
             (smoke-tests pass)))

  (:operator !commit-implementation
   :preconditions ((smoke-tests pass))
   :effects ((implementation committed)
             (implementation-commit "ab0fd446")))

  (:operator !close-plan-artifact
   :preconditions ((implementation committed))
   :effects ((plan-status :closed)
             (plan-artifact records-commit-references)
             (plan-artifact closed))))

 :closure
 ((closed-on "2026-07-02")
  (plan-commit "96cf921f")
  (implementation-commit "ab0fd446")
  (implementation-status
   ((page-attached-asdf-system
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition")
    (sqlite-asset
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.dmx.sqlite")
    (fedwiki-page-projection
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/the-1998-ai-planning-systems-competition")
    (obsolete-repo-local-page-asdf-route
     removed-by-page-system-retirement)))
  (validation-results
   ((asdf-load-system "the-1998-ai-planning-systems-competition")
    (asdf-test-system "the-1998-ai-planning-systems-competition/test")
    (sqlite-counts ((dmx_topics 25)
                    (dmx_associations 18)
                    (fedwiki_story_items 9)))
    (obsolete-repo-local-page-asdf-load removed-by-page-system-retirement)
    (reconstruction-idempotent t)
    (network-required nil)
    (git-diff-check-passes t)
    (pre-commit-load-gate-passes t))))

 :output-contract
 ((required-topic-ids
   ("the-1998-ai-planning-systems-competition"
    "mcdermott-2000-planning-competition"
    "planning-competition"
    "aips-1998"
    "pddl"
    "physics-not-advice"
    "domain-physics"
    "planner-advice"
    "benchmark-repository"
    "syntax-checker"
    "solution-checker"
    "strips-track"
    "adl-track"
    "classical-planning"
    "hierarchical-planning"
    "reactive-planning"
    "learning-in-planning"
    "plan-library"
    "plan-library-as-advice"
    "problematization"
    "zettel-6537"
    "planning-as-contingency-reduction"
    "shop3-methods-as-explicit-contingency-reduction"
    "fedwiki-page-projection"
    "dmx-sqlite-as-reconstruction-basis"))
  (validation
   ((asdf-load-system "the-1998-ai-planning-systems-competition")
    (sqlite-asset-exists t)
    (materialization-idempotent t)
    (smoke-tests-pass t)
    (network-required nil)
    (git-diff-check-passes t)))))
