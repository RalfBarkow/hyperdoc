(:artifact
 (:id add-domkin-2017-asdf-source-topics)
 (:title "Add Domkin 2017 ASDF Source Topics")
 (:type :shop3-plan)
 (:status :seed-or-projection-for-dmx-persistence)
 (:created-for-slice "feat(dmx): add Domkin 2017 ASDF source topics")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:production-store dreyeck-dmx-sqlite-production-db)
 (:plan-topic add-domkin-2017-asdf-source-topics)

 :knowledge
 ((core-rule
   ((domkin-2017 source-paper)
    (domkin-2017 expands-beyond bibliographic-reference)
    (production-dmx-store contains source-topic-subgraph)
    (source-reading-stores summaries-page-hints-and-typed-relations)
    (source-reading-does-not-store long-verbatim-quotations)))
  (source-evidence
   ((local-pdf
     "/Users/rgb/Zotero/storage/AYP7XXH7/Domkin - 2017 - Loading Multiple Versions of an ASDF System in the Same Lisp Image..pdf")
    (article-title
     "Loading Multiple Versions of an ASDF System in the Same Lisp Image")
    (article-pages "ELS 2017 pages 10-18")
    (pdf-pages "local proceedings PDF pages 16-26")))
  (view-contract
   ((tab-title "Domkin 2017 Source Subgraph")
    (source domkin-2017)
    (paper
     "Loading Multiple Versions of an ASDF System in the Same Lisp Image")
    (missing-topic-ids nil)
    (missing-association-ids nil))))

 :input
 ((canonical-object "dreyeck/codex:codex-domkin-2017-source-topics")
  (source-reading-artifact "hyperdoc/domkin-2017-asdf-source-topics.sexp")
  (canonical-explorer-system :dreyeck/codex/explorer)
  (compatibility-explorer-system :hyperdoc/codex/explorer)
  (production-db
   "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite")
  (required-topics
   (domkin-2017-loading-multiple-asdf-versions
    common-lisp-dependency-hell
    package-name-conflict
    global-package-registry
    asdf-unversioned-system-registry
    package-renaming-conflict-resolution
    rename-package-as-low-level-mechanism
    load-system-with-renamings
    dependency-tree-conflict-analysis
    topological-load-order-with-load-last-conflict-strategy
    post-load-package-capture
    asdf-public-api-gap
    asdf-plan-api-underdocumented
    asdf-caching-underdocumented
    asdf-monolithic-loading-strategy
    production-build-dependency-immutability
    nontransactional-package-capture-limitation
    preexisting-package-discipline-limitation
    monkey-patching-limitation
    implicit-transitive-dependency-limitation
    same-name-same-version-social-limitation
    runtime-intern-eval-renaming-limitation
    asdf-api-future-work
    hyperdoc-asdf-session-action-reading
    alternative-asdf-system-strategies))
  (required-associations
   ((domkin-2017 describes domkin-2017-loading-multiple-asdf-versions)
    (domkin-2017-loading-multiple-asdf-versions addresses common-lisp-dependency-hell)
    (common-lisp-dependency-hell manifests-as package-name-conflict)
    (package-name-conflict occurs-in global-package-registry)
    (package-renaming-conflict-resolution uses rename-package-as-low-level-mechanism)
    (load-system-with-renamings implements package-renaming-conflict-resolution)
    (load-system-with-renamings performs dependency-tree-conflict-analysis)
    (load-system-with-renamings uses topological-load-order-with-load-last-conflict-strategy)
    (load-system-with-renamings records post-load-package-capture)
    (load-system-with-renamings assumes production-build-dependency-immutability)
    (asdf-unversioned-system-registry contributes-to common-lisp-dependency-hell)
    (asdf-public-api-gap limits load-system-with-renamings)
    (asdf-plan-api-underdocumented limits alternative-asdf-system-strategies)
    (asdf-caching-underdocumented limits alternative-asdf-system-strategies)
    (asdf-monolithic-loading-strategy explains asdf-public-api-gap)
    (nontransactional-package-capture-limitation constrains load-system-with-renamings)
    (preexisting-package-discipline-limitation constrains load-system-with-renamings)
    (monkey-patching-limitation constrains load-system-with-renamings)
    (implicit-transitive-dependency-limitation constrains load-system-with-renamings)
    (runtime-intern-eval-renaming-limitation constrains load-system-with-renamings)
    (same-name-same-version-social-limitation constrains package-renaming-conflict-resolution)
    (asdf-api-future-work responds-to asdf-public-api-gap)
    (asdf-api-future-work responds-to asdf-plan-api-underdocumented)
    (asdf-3-3-session-action-model described-by domkin-2017)
    (plan-then-perform-build-session inspired-by hyperdoc-asdf-session-action-reading)
    (hyperdoc-asdf-session-action-reading derived-from domkin-2017-loading-multiple-asdf-versions)
    (build-referee-decision-route responds-to asdf-plan-api-underdocumented)
    (lisp-referee-form responds-to asdf-monolithic-loading-strategy))))

 :shop3
 ((:task add-domkin-2017-asdf-source-topics
   :goal
   ((source-paper domkin-2017-loaded)
    (dmx-topic domkin-2017-loading-multiple-asdf-versions)
    (dmx-topic common-lisp-dependency-hell)
    (dmx-topic package-name-conflict)
    (dmx-topic global-package-registry)
    (dmx-topic asdf-unversioned-system-registry)
    (dmx-topic package-renaming-conflict-resolution)
    (dmx-topic load-system-with-renamings)
    (dmx-topic dependency-tree-conflict-analysis)
    (dmx-topic topological-load-order-with-load-last-conflict-strategy)
    (dmx-topic asdf-public-api-gap)
    (dmx-topic asdf-plan-api-underdocumented)
    (dmx-topic nontransactional-package-capture-limitation)
    (dmx-topic implicit-transitive-dependency-limitation)
    (dmx-topic runtime-intern-eval-renaming-limitation)
    (dmx-associations domkin-2017-source-associations)
    (inspector-view domkin-2017-source-subgraph)
    (materializer-replay idempotent)))

  (:operator inspect-existing-domkin-topic
   :preconditions ((production-db exists))
   :effects ((known current-domkin-2017-topic)
             (known existing-asdf-session-action-model-topic)
             (known current-materializer)))

  (:operator read-domkin-2017-paper
   :preconditions ((source-paper available))
   :effects ((known paper-problem)
             (known paper-mechanism)
             (known paper-asdf-critique)
             (known paper-limitations)
             (known paper-hyperdoc-relevance)))

  (:operator add-domkin-2017-source-topic-seeds
   :preconditions ((known paper-problem)
                   (known paper-mechanism)
                   (known paper-asdf-critique)
                   (known paper-limitations))
   :effects ((materializer-knows domkin-2017-source-topics)))

  (:operator add-domkin-2017-source-associations
   :preconditions ((materializer-knows domkin-2017-source-topics))
   :effects ((materializer-knows domkin-2017-source-associations)))

  (:operator add-domkin-2017-source-subgraph-view
   :preconditions ((materializer-knows domkin-2017-source-topics))
   :effects ((inspector-view domkin-2017-source-subgraph)))

  (:operator validate-domkin-2017-source-topics
   :preconditions ((materializer-updated)
                   (inspector-view domkin-2017-source-subgraph))
   :effects ((domkin-2017-source-topic-validation passed)
             (second-replay unchanged))))

 :output-contract
 ((new-source-reading-artifact
   "hyperdoc/domkin-2017-asdf-source-topics.sexp")
  (new-api
   ("dreyeck/codex:codex-domkin-2017-source-topics"
    "dreyeck/codex:codex-domkin-2017-source-subgraph"))
  (new-inspector-tab
   (:object code-domkin-2017-source-topics
    :title "Domkin 2017 Source Subgraph"))
  (validation
   ((shop3-plan-artifact-exists
     "hyperdoc/add-domkin-2017-asdf-source-topics-plan.sexp")
    (source-reading-artifact-exists
     "hyperdoc/domkin-2017-asdf-source-topics.sexp")
    (missing-topic-ids nil)
    (missing-association-ids nil)
    (materializer-second-replay unchanged)
    (dreyeck-dmx-sqlite-tests pass)
    (dreyeck-codex-tests pass)
    (dreyeck-build-tests pass)
    (dreyeck-codex-explorer-loads t)
    (hyperdoc-codex-explorer-loads t)
    (git-diff-check-passes t)))))
