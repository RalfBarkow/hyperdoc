(:artifact
 (:id refactor-page-systems-to-fedwiki-page-attached-asdf)
 (:title "Retire Legacy Page-System Registry In Favor Of FedWiki Page-Attached ASDF")
 (:type :shop3-plan)
 (:status :open)
 (:created-for-slice
  "Delete the obsolete HyperDoc page-system registry after the McDermott page-attached ASDF repair")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:fedwiki-site-root "/Users/rgb/.wiki/wiki.ralfbarkow.ch")
 (:plan-topic refactor-page-systems-to-fedwiki-page-attached-asdf)

 :problem
 ((invalid-claim
   "FedWiki pages are not HyperDoc-owned repo-local ASDF systems or entries in a HyperDoc registry.")
  (legacy-abstraction
   "The page-system abstraction is obsolete. It is kept here only as migration vocabulary for the retired registry and tests.")
  (correct-fedwiki-page-layout
   ((page "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug>")
    (page-attached-assets
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/")
    (page-local-asdf-entrypoint
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/<slug>.asd")))
  (hyperdoc-role
   "HyperDoc may provide generic support for loading page-attached ASDF systems, but must not maintain a default registry of individual FedWiki page ASDF systems."))

 :inventory
 ((legacy-fedwiki-asd-defsystems-to-delete
   ("fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"
    "fedwiki/page/wiki.ralfbarkow.ch/shop3"
    "fedwiki/page/wiki.ralfbarkow.ch/the-1998-ai-planning-systems-competition"))
  (legacy-hyperdoc-page-asdf-defsystems-to-delete
   ("hyperdoc/page/mobile-progressive-chrome"
    "hyperdoc/page/dm6-appembed-inline-proof"))
  (legacy-default-registry-to-delete
   ("*page-system-default-asdf-systems*"
    "ensure-default-page-systems-registered"
    "page-system-registry"))
  (legacy-descriptor-files-to-delete
   ("hyperdoc/page-systems/mobile-progressive-chrome.lisp"
    "hyperdoc/page-systems/dm6-appembed-inline-proof.lisp"
    "hyperdoc/page-systems/fedwiki-mobile-progressive-chrome.lisp"
    "hyperdoc/page-systems/fedwiki-shop3.lisp"
    "hyperdoc/page-systems/fedwiki-the-1998-ai-planning-systems-competition.lisp"))
  (legacy-smoke-tests-to-retire
   ("tests/page-system-smoke.lisp"))
  (obsolete-documents-to-rewrite-or-delete
   ("hyperdoc/Page systems as ASDF reload boundaries.html"
    "hyperdoc/SHOP3 page as ASDF system.html"
    "hyperdoc/topics/page-systems.lisp"))
  (underlying-real-systems-to-preserve
   ("hyperdoc/mobile-progressive-chrome"
    "hyperdoc/explorer"
    "hyperdoc/fedwiki-asdf-assets"
    "hyperdoc/fedwiki"))
  (fedwiki-page-attached-entrypoint-to-preserve
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.asd"))

 :decision
 ((selected-strategy deletion)
  (no-hyperdoc-reload-namespace-created t)
  (no-renamed-registry-created t)
  (non-fedwiki-descriptors
   "The mobile-progressive-chrome and dm6-appembed-inline-proof descriptors are not required by runtime startup. They are legacy developer conveniences loaded by the old registry/tests/docs, so they will be deleted instead of renamed.")
  (fedwiki-pages
   "FedWiki page identity remains only in the FedWiki pages submodule. Page-attached ASDF entrypoints remain only under the FedWiki assets submodule."))

 :target-architecture
 ((fedwiki-pages-live-under
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug>")
  (fedwiki-page-assets-live-under
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/<slug>.asd")
  (hyperdoc-generic-support
   "Keep generic page-attached ASDF loader support, including make-fedwiki-attached-asdf-system and load-fedwiki-attached-asdf-system.")
  (no-default-fedwiki-page-registry t)
  (no-current-page-system-registry t)
  (no-current-hyperdoc-page-asdf-namespace t)
  (mcdermott-page-local-entrypoint
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.asd"))

 :shop3
 ((:task refactor-page-systems-to-fedwiki-page-attached-asdf
   :ordered-subtasks
   ((!record-plan-artifact
     "hyperdoc/refactor-page-systems-to-fedwiki-page-attached-asdf-plan.sexp")
    (!validate-plan-artifact)
    (!inventory-legacy-page-system-claims)
    (!retire-legacy-page-system-abstraction)
    (!delete-fedwiki-page-system-definitions)
    (!delete-nonessential-hyperdoc-page-system-descriptors)
    (!remove-default-page-system-registry)
    (!rewrite-page-system-smoke-tests)
    (!rewrite-page-system-documentation-as-obsolete)
    (!validate-underlying-feature-systems-still-load)
    (!validate-fedwiki-page-attached-asdf-contract)
    (!validate-search-gates)
    (!commit-revised-plan)
    (!commit-deletion-refactor)
    (!close-plan-artifact)))

  (:op (!record-plan-artifact ?path)
   :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc"))
   :effects ((plan-artifact ?path)
             (plan-status :open)))

  (:op (!validate-plan-artifact)
   :preconditions ((plan-status :open))
   :effects ((plan-uses-op-style t)
             (plan-selects-deletion t)
             (plan-forbids-hyperdoc-reload-namespace t)
             (plan-artifact-validated t)))

  (:op (!inventory-legacy-page-system-claims)
   :preconditions ((plan-artifact-validated t))
   :effects ((legacy-fedwiki-asd-defsystems inventoried)
             (legacy-hyperdoc-page-asdf-defsystems inventoried)
             (legacy-default-registry inventoried)
             (legacy-descriptors inventoried)
             (legacy-tests-and-docs inventoried)))

  (:op (!retire-legacy-page-system-abstraction)
   :preconditions ((legacy-tests-and-docs inventoried))
   :effects ((legacy-abstraction retired)
             (no-replacement-registry-created t)
             (no-hyperdoc-reload-namespace-created t)))

  (:op (!delete-fedwiki-page-system-definitions)
   :preconditions ((legacy-fedwiki-asd-defsystems inventoried))
   :effects ((fedwiki-asd-keeps-generic-runtime-system-only t)
             (repo-local-fedwiki-page-defsystems removed)))

  (:op (!delete-nonessential-hyperdoc-page-system-descriptors)
   :preconditions ((legacy-hyperdoc-page-asdf-defsystems inventoried))
   :effects ((hyperdoc-page-asdf-defsystems removed)
             (legacy-descriptor-directory removed)
             (underlying-mobile-progressive-chrome-system preserved)
             (underlying-dm6-proof-validation preserved)))

  (:op (!remove-default-page-system-registry)
   :preconditions ((legacy-default-registry inventoried))
   :effects ((*page-system-default-asdf-systems* removed)
             (ensure-default-page-systems-registered removed)
             (page-system-registry removed)))

  (:op (!rewrite-page-system-smoke-tests)
   :preconditions ((legacy-abstraction retired))
   :effects ((legacy-smoke-tests removed)
             (contract-regression-tests added)
             (mcdermott-page-attached-load-test added)
             (network-free-validation recorded)))

  (:op (!rewrite-page-system-documentation-as-obsolete)
   :preconditions ((legacy-abstraction retired))
   :effects ((current-docs-stop-promoting-page-system-registry t)
             (obsolete-migration-notes-marked t)
             (fedwiki-page-attached-asdf-contract documented)))

  (:op (!validate-underlying-feature-systems-still-load)
   :preconditions ((hyperdoc-page-asdf-defsystems removed))
   :effects ((hyperdoc-mobile-progressive-chrome-loads t)
             (dm6-topicmap-or-proof-validation-path-retained t)
             (underlying-feature-assets-preserved t)))

  (:op (!validate-fedwiki-page-attached-asdf-contract)
   :preconditions ((mcdermott-page-attached-load-test added))
   :effects ((mcdermott-page-json-under-pages-submodule t)
             (mcdermott-asdf-under-assets-submodule t)
             (mcdermott-page-local-asdf-loads t)
             (mcdermott-test-system-passes t)
             (mcdermott-materialization-idempotent t)
             (mcdermott-live-network-required nil)))

  (:op (!validate-search-gates)
   :preconditions ((repo-local-fedwiki-page-defsystems removed)
                   (hyperdoc-page-asdf-defsystems removed)
                   (page-system-registry removed))
   :effects ((no-current-fedwiki-page-asdf-definitions t)
             (no-default-page-system-registry-symbols t)
             (no-current-hyperdoc-page-asdf-systems t)
             (page-system-text-only-obsolete-or-migration t)))

  (:op (!commit-revised-plan)
   :preconditions ((plan-artifact-validated t))
   :effects ((plan-commit "docs(page-assets): revise plan to retire page systems")))

  (:op (!commit-deletion-refactor)
   :preconditions ((mcdermott-page-local-asdf-loads t)
                   (mcdermott-test-system-passes t)
                   (search-gates pass))
   :effects ((refactor-commit "refactor(page-assets): remove legacy page-system registry")))

  (:op (!close-plan-artifact)
   :preconditions ((refactor-commit "refactor(page-assets): remove legacy page-system registry"))
   :effects ((plan-status :closed)
             (plan-artifact records-validation)
             (close-plan-commit "docs(page-assets): close page-system retirement plan"))))

 :acceptance
 ((fedwiki-asd-individual-page-defsystems absent)
  (hyperdoc-page-asdf-defsystems absent)
  (legacy-default-page-system-registry absent)
  (legacy-page-system-descriptors absent)
  (mcdermott-page-attached-asdf-still-loads t)
  (mcdermott-page-json-remains-under-pages-submodule t)
  (mcdermott-asdf-remains-under-assets-submodule t)
  (underlying-mobile-progressive-chrome-system-preserved t)
  (dm6-proof-validation-path-preserved t)
  (no-fedwiki-page-central-registry-created t)
  (submodule-pages-and-assets-untouched t)))
