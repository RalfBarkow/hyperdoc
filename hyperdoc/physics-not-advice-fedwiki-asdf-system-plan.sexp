(:artifact
 (:id physics-not-advice-fedwiki-asdf-system)
 (:title "Physics, Not Advice FedWiki ASDF System")
 (:type :shop3-plan)
 (:status :closed)
 (:created-for-slice
  "FedWiki page-attached ASDF, DMX SQLite, and page JSON artifact for the concept page Physics, Not Advice")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:fedwiki-site-root "/Users/rgb/.wiki/wiki.ralfbarkow.ch")
 (:slug "physics-not-advice")
 (:system "physics-not-advice")
 (:plan-topic physics-not-advice-fedwiki-asdf-system)
 (:commit-references
  ((plan-commit "57b3edf7")
   (plan-page-commit "f01cf661")
   (assets-implementation-commit "6868edf2")
   (concept-page-commit "97f7acb5")
   (hyperdoc-contract-test-commit "1834851a")
   (plan-page-close-commit "c94d41cb")
   (closing-commit "commit containing this plan closure")))

 :problem
 ((page-title "Physics, Not Advice")
  (concept
   "McDermott's PDDL slogan separates domain physics from planner-specific advice, while the SHOP3 reading asks where explicit task-decomposition methods belong.")
  (architectural-boundary
   "The FedWiki page identity lives in the pages store; the page-attached ASDF and DMX SQLite assets live under the matching assets/pages slug.")
  (legacy-boundary
   "Do not recreate hyperdoc/page-systems, repo-local hyperdoc/page ASDF systems, or a default registry of individual FedWiki page ASDF systems."))

 :knowledge
 ((mcdermott-2000
   ((claim "PDDL domain descriptions should state possible actions and effects without smuggling planner-specific search advice into the core language.")
    (source-anchor "Drew V. McDermott, The 1998 AI Planning Systems Competition, AI Magazine 21(2), 2000")))
  (zettel-6537
   ((claim "Planning reduces and determines a structurally opened contingency space.")
    (source-anchor "Zettel 6537")))
  (zettel-3014
   ((claim "The advice taker reopens advice as a common-sense interface and relational advising problem.")
    (source-anchor "Zettel 3014, The advice taker")))
  (shop3-reading
   ((claim "SHOP3 methods are explicit, inspectable task-decomposition advice: neither hidden physics nor merely informal advice.")
    (working-question "Are SHOP3 methods advice, physics, or a relational interface layer?"))))

 :target-layout
 ((plan-artifact
   "/Users/rgb/workspace/hyperdoc/hyperdoc/physics-not-advice-fedwiki-asdf-system-plan.sexp")
  (asset-root
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice/")
  (asdf-entrypoint
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice/physics-not-advice.asd")
  (sqlite-asset
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice/physics-not-advice.dmx.sqlite")
  (plan-fedwiki-page
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/physics-not-advice-reconstruction-plan")
  (fedwiki-page
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/physics-not-advice"))

 :domain
 ((:task create-physics-not-advice-fedwiki-asdf-artifact
   :parameters (?plan ?page)
   :goal ((plan-artifact recorded)
          (plan-page-projection materialized)
          (plan-page-journal-actions recorded)
          (plan-page-projection validated)
          (plan-artifact validated)
          (topics recorded)
          (associations recorded)
          (dmx-sqlite-asset initialized)
          (dmx-sqlite-asset seeded)
          (dmx-sqlite-schema valid)
          (fedwiki-story-items drafted)
          (fedwiki-story-ids-derived)
          (fedwiki-story-ids-valid)
          (semantic-fedwiki-story-ids-absent)
          (fedwiki-journal-actions recorded)
          (fedwiki-journal-actions-schema-valid)
          (fedwiki-journal-replay-valid)
          (journalmatic-revision-gate-passed)
          (fedwiki-page-json projected)
          (fedwiki-journal-gate valid)
          (asdf-system written)
          (reconstruction-entrypoint written)
          (asdf-load valid)
          (page-history replayed)
          (reconstruction idempotent)
          (plan-artifact closed)))

  (:method create-physics-not-advice-fedwiki-asdf-artifact
   :task (create-physics-not-advice-fedwiki-asdf-artifact
          physics-not-advice-plan physics-not-advice)
   :ordered-subtasks
   ((!record-plan-artifact
     "hyperdoc/physics-not-advice-fedwiki-asdf-system-plan.sexp")
    (!materialize-plan-as-fedwiki-page
     physics-not-advice-fedwiki-asdf-system-plan
     physics-not-advice-reconstruction-plan
     "Physics, Not Advice Reconstruction Plan")
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 1 create nil)
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 2 add plan-synopsis)
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 3 add problem)
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 4 add domain)
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 5 add selected-ordered-plan)
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 6 add artifact-topology)
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 7 add validation-contract)
    (!record-plan-page-journal-action
     physics-not-advice-reconstruction-plan 8 add closeout-contract)
    (!derive-fedwiki-story-ids
     physics-not-advice-reconstruction-plan wiki-client-compatible-16hex)
    (!validate-fedwiki-story-id-shape physics-not-advice-reconstruction-plan)
    (!reject-semantic-fedwiki-story-ids physics-not-advice-reconstruction-plan)
    (!validate-fedwiki-journal-action-schema physics-not-advice-reconstruction-plan)
    (!replay-fedwiki-journal-with-wiki-client-semantics
     physics-not-advice-reconstruction-plan)
    (!run-journalmatic-revision-gate physics-not-advice-reconstruction-plan)
    (!validate-plan-page-projection physics-not-advice-reconstruction-plan)
    (!validate-plan-artifact physics-not-advice-plan)
    (model-physics-not-advice-reading physics-not-advice)
    (materialize-physics-not-advice-artifact physics-not-advice)
    (validate-physics-not-advice-artifact physics-not-advice)
    (!close-plan-artifact physics-not-advice-plan)))

  (:method model-physics-not-advice-reading
   :task (model-physics-not-advice-reading physics-not-advice)
   :ordered-subtasks
   ((!record-topic physics-not-advice "Physics, Not Advice")
    (!record-topic mcdermott-physics-not-advice "McDermott Physics Not Advice")
    (!record-topic zettel-6537 "Zettel 6537")
    (!record-topic advice-taker "The Advice Taker")
    (!record-topic shop3-methods-as-contingency-reduction
     "SHOP3 Methods as Contingency Reduction")
    (!record-association mcdermott-physics-not-advice separates domain-physics planner-advice)
    (!record-association zettel-6537 interprets planning-as-contingency-reduction physics-not-advice)
    (!record-association advice-taker returns-as relational-advising physics-not-advice)
    (!record-association shop3-methods-as-contingency-reduction answers physics-not-advice)))

  (:method materialize-physics-not-advice-artifact
   :task (materialize-physics-not-advice-artifact physics-not-advice)
   :ordered-subtasks
   ((!initialize-dmx-sqlite-asset
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice/physics-not-advice.dmx.sqlite")
    (!seed-dmx-sqlite physics-not-advice)
    (!validate-dmx-sqlite-schema physics-not-advice)
    (!draft-fedwiki-story-item synopsis)
    (!draft-fedwiki-story-item physics-not-advice)
    (!draft-fedwiki-story-item zettel-6537-bridge)
    (!draft-fedwiki-story-item advice-taker-bridge)
    (!draft-fedwiki-story-item shop3-methods-question)
    (!draft-fedwiki-story-item reconstruction-contract)
    (!derive-fedwiki-story-ids physics-not-advice wiki-client-compatible-16hex)
    (!validate-fedwiki-story-id-shape physics-not-advice)
    (!reject-semantic-fedwiki-story-ids physics-not-advice)
    (!record-fedwiki-journal-action physics-not-advice create)
    (!record-fedwiki-journal-action physics-not-advice add)
    (!validate-fedwiki-journal-action-schema physics-not-advice)
    (!replay-fedwiki-journal-with-wiki-client-semantics physics-not-advice)
    (!run-journalmatic-revision-gate physics-not-advice)
    (!project-fedwiki-page-json physics-not-advice)
    (!validate-fedwiki-journal-gate physics-not-advice)
    (!write-asdf-system physics-not-advice)
    (!write-reconstruction-entrypoint physics-not-advice)))

  (:method validate-physics-not-advice-artifact
   :task (validate-physics-not-advice-artifact physics-not-advice)
   :ordered-subtasks
   ((!validate-asdf-load physics-not-advice)
    (!replay-page-history physics-not-advice)
    (!validate-reconstruction-idempotence physics-not-advice)))

  (:op (!record-plan-artifact ?path)
   :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc"))
   :effects ((plan-artifact recorded)
             (plan-path ?path)
             (plan-status :open)))

  (:op (!materialize-plan-as-fedwiki-page ?plan ?slug ?title)
   :preconditions ((plan-artifact recorded))
   :effects ((plan-page-projection materialized)
             (plan-page-slug ?slug)
             (plan-page-title ?title)
             (plan-page-json-path
              "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/physics-not-advice-reconstruction-plan")))

  (:op (!record-plan-page-journal-action ?slug ?order ?action ?logical-item)
   :preconditions ((plan-page-projection materialized))
   :effects ((plan-page-journal-actions recorded)
             (plan-page-journal-action ?slug ?order ?action ?logical-item)))

  (:op (!validate-plan-page-projection ?slug)
   :preconditions ((plan-page-journal-actions recorded)
                   (journalmatic-revision-gate-passed ?slug))
   :effects ((plan-page-projection validated)
             (plan-page-title "Physics, Not Advice Reconstruction Plan")
             (plan-page-journal-replay-valid t)))

  (:op (!validate-plan-artifact ?plan)
   :preconditions ((plan-artifact recorded)
                   (plan-page-projection validated))
   :effects ((plan-artifact validates-required-primitive-operators)
             (plan-artifact uses-op-not-operator)
             (primitive-task-names-use-bang t)
             (compound-task-names-omit-bang t)
             (plan-artifact validated)))

  (:op (!record-topic ?topic ?title)
   :preconditions ((plan-artifact validated))
   :effects ((topic recorded)
             (topic-title ?topic ?title)))

  (:op (!record-association ?association ?role ?from ?to)
   :preconditions ((topic recorded))
   :effects ((association recorded)
             (association-role ?association ?role)
             (association-from ?association ?from)
             (association-to ?association ?to)))

  (:op (!initialize-dmx-sqlite-asset ?path)
   :preconditions ((plan-artifact validated))
   :effects ((dmx-sqlite-asset initialized)
             (sqlite-path ?path)))

  (:op (!seed-dmx-sqlite ?page)
   :preconditions ((dmx-sqlite-asset initialized)
                   (topic recorded)
                   (association recorded))
   :effects ((dmx-sqlite-asset seeded)
             (shop3-plan-steps seeded)
             (fedwiki-story-items seeded)
             (fedwiki-journal-actions seeded)))

  (:op (!validate-dmx-sqlite-schema ?page)
   :preconditions ((dmx-sqlite-asset seeded))
   :effects ((dmx-sqlite-schema valid)
             (topics-table present)
             (associations-table present)
             (association-players-table present)
             (source-fragments-table present)
             (fedwiki-pages-table present)
             (fedwiki-story-items-table present)
             (fedwiki-journal-actions-table present)
             (shop3-plan-steps-table present)))

  (:op (!draft-fedwiki-story-item ?item)
   :preconditions ((dmx-sqlite-schema valid))
   :effects ((fedwiki-story-item drafted)
             (fedwiki-story-logical-name ?item)))

  (:op (!derive-fedwiki-story-ids ?page ?source)
   :preconditions ((fedwiki-story-item drafted))
   :effects ((fedwiki-story-ids-derived ?page ?source)
             (fedwiki-story-id-source ?source)
             (fedwiki-story-runtime-id-shape 16-hex)))

  (:op (!validate-fedwiki-story-id-shape ?page)
   :preconditions ((fedwiki-story-ids-derived ?page ?source))
   :effects ((fedwiki-story-ids-valid ?page)
             (fedwiki-story-runtime-id-shape 16-hex)
             (wiki-client-compatible-story-ids t)))

  (:op (!reject-semantic-fedwiki-story-ids ?page)
   :preconditions ((fedwiki-story-ids-valid ?page))
   :effects ((semantic-fedwiki-story-ids-absent ?page)
             (semantic-labels-retained-as-logical-item-ids t)))

  (:op (!record-fedwiki-journal-action ?page ?action)
   :preconditions ((semantic-fedwiki-story-ids-absent ?page))
   :effects ((fedwiki-journal-action recorded)
             (fedwiki-journal-action-type ?action)))

  (:op (!validate-fedwiki-journal-action-schema ?page)
   :preconditions ((fedwiki-journal-action recorded)
                   (semantic-fedwiki-story-ids-absent ?page))
   :effects ((fedwiki-journal-actions-schema-valid ?page)
             (journal-add-item-ids-match-story-ids t)
             (journal-action-ids-use-runtime-ids t)))

  (:op (!replay-fedwiki-journal-with-wiki-client-semantics ?page)
   :preconditions ((fedwiki-journal-actions-schema-valid ?page))
   :effects ((fedwiki-journal-replay-valid ?page)
             (fedwiki-current-story-reconstructed-from-journal t)))

  (:op (!run-journalmatic-revision-gate ?page)
   :preconditions ((fedwiki-journal-replay-valid ?page))
   :effects ((journalmatic-revision-gate-passed ?page)
             (journalmatic-findings-clear (:revision :malformed))))

  (:op (!project-fedwiki-page-json ?page)
   :preconditions ((fedwiki-story-item drafted)
                   (journalmatic-revision-gate-passed ?page))
   :effects ((fedwiki-page-json projected)
             (fedwiki-page-json-path
              "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/physics-not-advice")))

  (:op (!validate-fedwiki-journal-gate ?page)
   :preconditions ((fedwiki-page-json projected)
                   (journalmatic-revision-gate-passed ?page))
   :effects ((fedwiki-journal-gate valid)
             (fedwiki-page-title "Physics, Not Advice")
             (fedwiki-journal-create-action present)
             (fedwiki-journal-revision-error absent)
             (fedwiki-journal-malformed-error absent)))

  (:op (!write-asdf-system ?page)
   :preconditions ((dmx-sqlite-schema valid))
   :effects ((asdf-system written)
             (asdf-system-name "physics-not-advice")
             (asdf-test-system-name "physics-not-advice/test")))

  (:op (!write-reconstruction-entrypoint ?page)
   :preconditions ((asdf-system written))
   :effects ((reconstruction-entrypoint written)
             (entrypoint replay-page-history)
             (entrypoint validate-reconstruction-idempotence)))

  (:op (!validate-asdf-load ?page)
   :preconditions ((asdf-system written)
                   (reconstruction-entrypoint written))
   :effects ((asdf-load valid)
             (test-system-load valid)))

  (:op (!replay-page-history ?page)
   :preconditions ((asdf-load valid)
                   (fedwiki-journal-gate valid))
   :effects ((page-history replayed)
             (fedwiki-page-json reconstructed-from-journal)))

  (:op (!validate-reconstruction-idempotence ?page)
   :preconditions ((page-history replayed))
   :effects ((reconstruction idempotent)
             (live-network-required nil)))

  (:op (!close-plan-artifact ?plan)
   :preconditions ((reconstruction idempotent))
   :effects ((plan-status :closed)
             (plan-artifact records-validation)
             (plan-artifact closed))))

 :selected-ordered-plan
 ((!record-plan-artifact
   "hyperdoc/physics-not-advice-fedwiki-asdf-system-plan.sexp")
  (!materialize-plan-as-fedwiki-page
   physics-not-advice-fedwiki-asdf-system-plan
   physics-not-advice-reconstruction-plan
   "Physics, Not Advice Reconstruction Plan")
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 1 create nil)
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 2 add plan-synopsis)
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 3 add problem)
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 4 add domain)
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 5 add selected-ordered-plan)
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 6 add artifact-topology)
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 7 add validation-contract)
  (!record-plan-page-journal-action
   physics-not-advice-reconstruction-plan 8 add closeout-contract)
  (!derive-fedwiki-story-ids
   physics-not-advice-reconstruction-plan wiki-client-compatible-16hex)
  (!validate-fedwiki-story-id-shape physics-not-advice-reconstruction-plan)
  (!reject-semantic-fedwiki-story-ids physics-not-advice-reconstruction-plan)
  (!validate-fedwiki-journal-action-schema physics-not-advice-reconstruction-plan)
  (!replay-fedwiki-journal-with-wiki-client-semantics
   physics-not-advice-reconstruction-plan)
  (!run-journalmatic-revision-gate physics-not-advice-reconstruction-plan)
  (!validate-plan-page-projection physics-not-advice-reconstruction-plan)
  (!validate-plan-artifact physics-not-advice-plan)
  (!record-topic physics-not-advice "Physics, Not Advice")
  (!record-topic mcdermott-physics-not-advice "McDermott Physics Not Advice")
  (!record-topic zettel-6537 "Zettel 6537")
  (!record-topic advice-taker "The Advice Taker")
  (!record-topic shop3-methods-as-contingency-reduction
   "SHOP3 Methods as Contingency Reduction")
  (!record-association mcdermott-physics-not-advice separates domain-physics planner-advice)
  (!record-association zettel-6537 interprets planning-as-contingency-reduction physics-not-advice)
  (!record-association advice-taker returns-as relational-advising physics-not-advice)
  (!record-association shop3-methods-as-contingency-reduction answers physics-not-advice)
  (!initialize-dmx-sqlite-asset
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice/physics-not-advice.dmx.sqlite")
  (!seed-dmx-sqlite physics-not-advice)
  (!validate-dmx-sqlite-schema physics-not-advice)
  (!draft-fedwiki-story-item synopsis)
  (!draft-fedwiki-story-item physics-not-advice)
  (!draft-fedwiki-story-item zettel-6537-bridge)
  (!draft-fedwiki-story-item advice-taker-bridge)
  (!draft-fedwiki-story-item shop3-methods-question)
  (!draft-fedwiki-story-item reconstruction-contract)
  (!derive-fedwiki-story-ids physics-not-advice wiki-client-compatible-16hex)
  (!validate-fedwiki-story-id-shape physics-not-advice)
  (!reject-semantic-fedwiki-story-ids physics-not-advice)
  (!record-fedwiki-journal-action physics-not-advice create)
  (!record-fedwiki-journal-action physics-not-advice add)
  (!validate-fedwiki-journal-action-schema physics-not-advice)
  (!replay-fedwiki-journal-with-wiki-client-semantics physics-not-advice)
  (!run-journalmatic-revision-gate physics-not-advice)
  (!project-fedwiki-page-json physics-not-advice)
  (!validate-fedwiki-journal-gate physics-not-advice)
  (!write-asdf-system physics-not-advice)
  (!write-reconstruction-entrypoint physics-not-advice)
  (!validate-asdf-load physics-not-advice)
  (!replay-page-history physics-not-advice)
  (!validate-reconstruction-idempotence physics-not-advice)
  (!close-plan-artifact physics-not-advice-plan))

 :closure
 ((closed-on "2026-07-02")
  (plan-commit "57b3edf7")
  (plan-page-commit "f01cf661")
  (assets-implementation-commit "6868edf2")
  (concept-page-commit "97f7acb5")
  (hyperdoc-contract-test-commit "1834851a")
  (plan-page-close-commit "c94d41cb")
  (corrective-repair
   ((story-id-boundary-defect
     "Semantic story item labels were incorrectly used as FedWiki runtime ids.")
    (repair
     "FedWiki story ids are now stable opaque 16-hex runtime ids, with semantic labels retained as logical story item names in SQLite and Lisp metadata.")
    (prevention
     "The selected plan now derives ids, validates id shape, rejects semantic story ids, validates journal action schema, replays with wiki-client semantics, and runs the journalmatic revision gate before page projection.")))
  (implementation-status
   ((plan-artifact
     "/Users/rgb/workspace/hyperdoc/hyperdoc/physics-not-advice-fedwiki-asdf-system-plan.sexp")
    (plan-page
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/physics-not-advice-reconstruction-plan")
    (page-attached-asdf-system
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice")
    (sqlite-asset
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice/physics-not-advice.dmx.sqlite")
    (fedwiki-page-projection
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/physics-not-advice")
    (legacy-page-system-registry-created nil)
    (repo-local-hyperdoc-page-asdf-system-created nil)))
  (validation-results
   ((plan-page-title "Physics, Not Advice Reconstruction Plan")
    (plan-page-story-items 7)
    (plan-page-journal-actions 8)
    (concept-page-title "Physics, Not Advice")
    (concept-page-story-items 6)
    (concept-page-journal-actions 7)
    (sqlite-counts ((dmx_topics 19)
                    (dmx_associations 12)
                    (dmx_assoc_players 24)
                    (source_fragments 3)
                    (fedwiki_pages 2)
                    (fedwiki_story_items 13)
                    (fedwiki_journal_actions 15)
                    (shop3_plan_steps 33)))
    (fedwiki-story-id-shape "16 lowercase hex")
    (semantic-fedwiki-story-ids-absent t)
    (journalmatic-findings nil)
    (asdf-load-system "physics-not-advice")
    (asdf-test-system "physics-not-advice/test")
    (page-attached-contract-smoke-test pass)
    (reconstruction-idempotent t)
    (network-required nil)
    (git-diff-check-passes t)
    (pre-commit-load-gate-passes t))))

 :acceptance
 ((fedwiki-page-title "Physics, Not Advice")
  (minimum-story-items
   ("synopsis"
    "physics-not-advice"
    "zettel-6537-bridge"
    "advice-taker-bridge"
    "shop3-methods-question"
    "reconstruction-contract"))
  (sqlite-tables
   ("dmx_topics"
    "dmx_associations"
    "dmx_assoc_players"
    "source_fragments"
    "fedwiki_pages"
    "fedwiki_story_items"
    "fedwiki_journal_actions"
    "shop3_plan_steps"))
  (page-attached-asdf-entrypoint
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/physics-not-advice/physics-not-advice.asd")
  (fedwiki-page-json
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/physics-not-advice")
  (fedwiki-story-item-id-policy
   ((runtime-id-shape "16 lowercase hex")
    (semantic-labels-in-runtime-id-fields nil)
    (journal-add-id-matches-item-id t)
    (journal-after-references-runtime-ids t)
    (journalmatic-revision-gate-required-before-commit t)))
  (no-hyperdoc-page-system-registry-created t)
  (no-repo-local-hyperdoc-page-asdf-system-created t)
  (live-network-required nil)))
