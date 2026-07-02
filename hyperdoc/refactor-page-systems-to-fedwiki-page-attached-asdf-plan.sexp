(:artifact
 (:id refactor-page-systems-to-fedwiki-page-attached-asdf)
 (:title "Refactor Page Systems To FedWiki Page-Attached ASDF")
 (:type :shop3-plan)
 (:status :open)
 (:created-for-slice
  "Repair HyperDoc page-system claims that model FedWiki pages as repo-local ASDF systems")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:fedwiki-site-root "/Users/rgb/.wiki/wiki.ralfbarkow.ch")
 (:plan-topic refactor-page-systems-to-fedwiki-page-attached-asdf)

 :problem
 ((invalid-claim
   "FedWiki pages are not HyperDoc-owned repo-local ASDF page systems.")
  (correct-fedwiki-page-layout
   ((page "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug>")
    (page-attached-assets
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/")
    (page-local-asdf-entrypoint
     "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/<slug>.asd")))
  (hyperdoc-role
   "HyperDoc may provide generic loader/support code, but must not be the canonical registry or source location for individual FedWiki page ASDF systems."))

 :inventory
 ((fedwiki-asd-defsystems
   ("fedwiki"
    "fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"
    "fedwiki/page/wiki.ralfbarkow.ch/shop3"
    "fedwiki/page/wiki.ralfbarkow.ch/the-1998-ai-planning-systems-competition"))
  (page-system-default-asdf-systems
   ("hyperdoc/page/mobile-progressive-chrome"
    "hyperdoc/page/dm6-appembed-inline-proof"
    "fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc"
    "fedwiki/page/wiki.ralfbarkow.ch/shop3"
    "fedwiki/page/wiki.ralfbarkow.ch/the-1998-ai-planning-systems-competition"))
  (page-system-descriptor-files
   ("hyperdoc/page-systems/mobile-progressive-chrome.lisp"
    "hyperdoc/page-systems/dm6-appembed-inline-proof.lisp"
    "hyperdoc/page-systems/fedwiki-mobile-progressive-chrome.lisp"
    "hyperdoc/page-systems/fedwiki-shop3.lisp"
    "hyperdoc/page-systems/fedwiki-the-1998-ai-planning-systems-competition.lisp"))
  (tests-depending-on-invalid-fedwiki-page-asdf-names
   ("tests/page-system-smoke.lisp"))
  (docs-and-topics-with-invalid-current-claims
   ("hyperdoc/Page systems as ASDF reload boundaries.html"
    "hyperdoc/SHOP3 page as ASDF system.html"
    "hyperdoc/topics/page-systems.lisp"))
  (plan-artifacts-with-migration-context
   ("hyperdoc/the-1998-ai-planning-systems-competition-fedwiki-asdf-system-plan.sexp"
    "hyperdoc/repair-the-1998-ai-planning-systems-competition-fedwiki-asdf-placement-plan.sexp")))

 :target-architecture
 ((fedwiki-page-attached-asdf-systems
   "Discovered and loaded from the page-attached asset root, never from HyperDoc fedwiki.asd.")
  (hyperdoc-page-runtime-boundaries
   "Repo-local ASDF reload boundaries remain only for HyperDoc-owned pages.")
  (fedwiki-asd
   "Keep at most the generic fedwiki runtime namespace system.")
  (default-registry
   "Default loading is restricted to HyperDoc-owned page runtime boundaries.")
  (mcdermott-page-local-entrypoint
   "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/the-1998-ai-planning-systems-competition/the-1998-ai-planning-systems-competition.asd")
  (no-replacement-central-registry t))

 :shop3
 ((:task refactor-page-systems-to-fedwiki-page-attached-asdf
   :ordered-subtasks
   ((!record-plan-artifact
     "hyperdoc/refactor-page-systems-to-fedwiki-page-attached-asdf-plan.sexp")
    (!validate-plan-artifact)
    (!inventory-page-system-claims)
    (!classify-hyperdoc-owned-vs-fedwiki-owned-page-runtime)
    (!identify-invalid-fedwiki-asdf-defsystems)
    (!define-target-fedwiki-page-attached-asdf-contract)
    (!refactor-or-remove-fedwiki-asd-page-defsystems)
    (!refactor-page-systems-default-registry)
    (!rename-or-deprecate-page-system-terminology)
    (!rewrite-topic-and-documentation-claims)
    (!update-tests-for-page-attached-asdf-loading)
    (!validate-mcdermott-page-attached-asdf-still-loads)
    (!validate-shop3-page-does-not-claim-repo-local-fedwiki-page-system)
    (!run-smoke-tests)
    (!commit-plan-artifact)
    (!commit-refactor)
    (!close-plan-artifact)))

  (:op (!record-plan-artifact ?path)
   :preconditions ((repo-root "/Users/rgb/workspace/hyperdoc"))
   :effects ((plan-artifact ?path)
             (plan-status :open)))

  (:op (!validate-plan-artifact)
   :preconditions ((plan-status :open))
   :effects ((plan-uses-op-style t)
             (plan-includes-required-tasks t)
             (plan-records-inventory t)
             (plan-artifact-validated t)))

  (:op (!inventory-page-system-claims)
   :preconditions ((plan-artifact-validated t))
   :effects ((fedwiki-asd-defsystems inventoried)
             (default-page-system-registry inventoried)
             (page-system-descriptors inventoried)
             (tests-and-docs inventoried)))

  (:op (!classify-hyperdoc-owned-vs-fedwiki-owned-page-runtime)
   :preconditions ((page-system-descriptors inventoried))
   :effects ((hyperdoc-page-runtime-boundaries retained)
             (fedwiki-page-identity-descriptors invalid)))

  (:op (!identify-invalid-fedwiki-asdf-defsystems)
   :preconditions ((fedwiki-asd-defsystems inventoried))
   :effects ((invalid-fedwiki-asdf-defsystem
              "fedwiki/page/wiki.ralfbarkow.ch/mobile-progressive-chrome-in-hyperdoc")
             (invalid-fedwiki-asdf-defsystem
              "fedwiki/page/wiki.ralfbarkow.ch/shop3")
             (invalid-fedwiki-asdf-defsystem
              "fedwiki/page/wiki.ralfbarkow.ch/the-1998-ai-planning-systems-competition")))

  (:op (!define-target-fedwiki-page-attached-asdf-contract)
   :preconditions ((fedwiki-page-identity-descriptors invalid))
   :effects ((fedwiki-pages-live-under "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/<slug>")
             (fedwiki-page-assets-live-under
              "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/<slug>/")
             (page-local-asdf-entrypoint-contract recorded)))

  (:op (!refactor-or-remove-fedwiki-asd-page-defsystems)
   :preconditions ((page-local-asdf-entrypoint-contract recorded))
   :effects ((fedwiki-asd-keeps-generic-runtime-system-only t)
             (repo-local-fedwiki-page-defsystems removed)))

  (:op (!refactor-page-systems-default-registry)
   :preconditions ((repo-local-fedwiki-page-defsystems removed))
   :effects ((*page-system-default-asdf-systems* removed)
             (hyperdoc-owned-default-boundaries-only t)
             (no-fedwiki-page-default-loads t)))

  (:op (!rename-or-deprecate-page-system-terminology)
   :preconditions ((hyperdoc-owned-default-boundaries-only t))
   :effects ((page-system-term restricted-to-hyperdoc-owned-boundaries)
             (fedwiki-page-attached-asdf-term used-for-fedwiki-assets)))

  (:op (!rewrite-topic-and-documentation-claims)
   :preconditions ((page-system-term restricted-to-hyperdoc-owned-boundaries))
   :effects ((invalid-fedwiki-page-system-docs rewritten)
             (shop3-page-as-asdf-system-claim removed)
             (fedwiki-page-asset-contract documented)))

  (:op (!update-tests-for-page-attached-asdf-loading)
   :preconditions ((invalid-fedwiki-page-system-docs rewritten))
   :effects ((page-system-smoke-tests-hyperdoc-only t)
             (fedwiki-page-attached-regression-tests added)
             (fedwiki-asd-no-individual-page-tests added)))

  (:op (!validate-mcdermott-page-attached-asdf-still-loads)
   :preconditions ((fedwiki-page-attached-regression-tests added))
   :effects ((mcdermott-page-local-asdf-loads t)
             (mcdermott-test-system-passes t)
             (mcdermott-materialization-idempotent t)
             (mcdermott-live-network-required nil)))

  (:op (!validate-shop3-page-does-not-claim-repo-local-fedwiki-page-system)
   :preconditions ((fedwiki-asd-no-individual-page-tests added))
   :effects ((shop3-fedwiki-page-asdf-name-absent t)
             (shop3-runtime-provider-remains-runtime-only t)))

  (:op (!run-smoke-tests)
   :preconditions ((mcdermott-page-local-asdf-loads t)
                   (shop3-fedwiki-page-asdf-name-absent t))
   :effects ((asdf-load-hyperdoc succeeds)
             (asdf-test-hyperdoc/test succeeds)
             (search-gates pass)))

  (:op (!commit-plan-artifact)
   :preconditions ((plan-artifact-validated t))
   :effects ((plan-commit "pending")))

  (:op (!commit-refactor)
   :preconditions ((asdf-test-hyperdoc/test succeeds)
                   (search-gates pass))
   :effects ((refactor-commit "pending")))

  (:op (!close-plan-artifact)
   :preconditions ((refactor-commit "pending"))
   :effects ((plan-status :closed)
             (plan-artifact records-validation)
             (close-plan-commit "pending"))))

 :acceptance
 ((fedwiki-asd-individual-page-defsystems absent)
  (default-registry-has-no-fedwiki-page-entries t)
  (mcdermott-page-attached-asdf-still-loads t)
  (shop3-fedwiki-page-has-no-repo-local-asdf-name t)
  (no-fedwiki-page-central-registry-created t)
  (submodule-pages-and-assets-untouched t)))
