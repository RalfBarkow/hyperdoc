;;;; Smoke tests for merged documentation/topic slices
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-MERGED-DOC-SLICES-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun ensure-hyperdoc-page-lookup-loaded ()
  (asdf:load-system :hyperdoc/explorer))

(defun assert-topic-function-present (symbol title)
  (assert-true (fboundp symbol)
               (format nil "Missing topic function ~A" symbol))
  (assert-true (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
               (format nil "Missing topic page ~A" title)))

(defun assert-hyperdoc-page-present (title)
  (ensure-hyperdoc-page-lookup-loaded)
  (assert-true (hyperbook:find-page hyperdoc::*hyperdoc* title :signal-error? t)
               (format nil "Missing HyperDoc page ~A" title)))

(defun assert-page-source-contains (relative-path substring)
  (let* ((pathname (asdf:system-relative-pathname :hyperdoc relative-path))
         (contents (uiop:read-file-string pathname)))
    (assert-true (search substring contents :test #'char=)
                 (format nil "Expected ~A to contain ~S"
                         relative-path
                         substring))))

(defun assert-hyperdoc-page-absent (title)
  (ensure-hyperdoc-page-lookup-loaded)
  (assert-true (null (hyperbook:find-page hyperdoc::*hyperdoc* title))
               (format nil "Legacy HyperDoc page should be absent ~A" title)))

(defun run-clickable-commit-ids-doc-slice-smoke-test ()
  (assert-topic-function-present 'hyperdoc::clickable-commit-ids-in-fedwiki-stories-topic
                                 "Clickable commit IDs in FedWiki stories")
  (assert-topic-function-present 'hyperdoc::software-heritage-revision-link-topic
                                 "Software Heritage revision link")
  (assert-hyperdoc-page-present "Clickable commit IDs in FedWiki stories"))

(defun run-literate-tracing-doc-slice-smoke-test ()
  (assert-topic-function-present 'hyperdoc::literate-tracing-topic
                                 "Literate Tracing")
  (assert-hyperdoc-page-present "Literate Tracing"))

(defun run-execution-evidence-vocabulary-smoke-test ()
  (dolist (entry '((hyperdoc::runtime-dispatch-seam-topic "Runtime dispatch seam")
                   (hyperdoc::execution-context-bundle-topic "Execution context bundle")
                   (hyperdoc::block-level-interpreter-seam-topic "Block-level interpreter seam")
                   (hyperdoc::explanation-from-execution-topic "Explanation from execution")
                   (hyperdoc::runtime-provenance-topic "Runtime provenance")
                   (hyperdoc::block-registry-protocol-topic "Block registry protocol")
                   (hyperdoc::operation-argument-normalization-topic "Operation/argument normalization")
                   (hyperdoc::structured-findings-tally-topic "Structured findings tally")
                   (hyperdoc::first-class-run-record-topic "First-class run record")
                   (hyperdoc::diagnostic-publication-topic "Diagnostic publication")
                   (hyperdoc::execution-step-object-topic "Execution step object")
                   (hyperdoc::state-delta-topic "State delta")
                   (hyperdoc::artifact-provenance-topic "Artifact provenance")
                   (hyperdoc::findings-ledger-topic "Findings ledger")
                   (hyperdoc::replay-trail-topic "Replay trail")
                   (hyperdoc::retrospective-explanation-pass-topic "Retrospective explanation pass")
                   (hyperdoc::execution-evidence-object-topic "Execution evidence object")
                   (hyperdoc::boundary-report-topic "Boundary report")
                   (hyperdoc::generation-explanation-twin-output-topic "Generation/explanation twin output")
                   (hyperdoc::raw-console-trace-topic "Raw console trace")
                   (hyperdoc::pane-run-topic "Pane run")
                   (hyperdoc::view-render-event-topic "View render event")
                   (hyperdoc::inspector-session-topic "Inspector session")
                   (hyperdoc::same-protocol-evidence-topic "Same-protocol evidence")
                   (hyperdoc::transient-diagnostic-stream-topic "Transient diagnostic stream")
                   (hyperdoc::objectified-execution-evidence-topic "Objectified execution evidence")
                   (hyperdoc::persistence-of-investigation-context-topic
                    "Persistence of investigation context")))
    (destructuring-bind (symbol title) entry
      (assert-topic-function-present symbol title)))
  (dolist (title '("Runtime Dispatch Seams in HyperDoc"
                   "Mech Execution Context and Emit Protocol"
                   "Inspectable Mech Runs"
                   "HyperDoc Evaluation and Inspection Model"
                   "HyperDoc Runtime Model"
                   "Smalltalk Browser Frame and Scene in HyperDoc"
                   "Mech Credible Maintenance Story"
                   "Mech Plugin Progress March 2026"))
    (assert-hyperdoc-page-present title)))

(defun run-sbcl-bootstrapping-doc-slice-smoke-test ()
  (dolist (entry '((hyperdoc::sbcl-bootstrapping-topic "SBCL bootstrapping")
                   (hyperdoc::source-oriented-development-topic "Source-oriented development")
                   (hyperdoc::image-oriented-development-topic "Image-oriented development")
                   (hyperdoc::host-target-separation-topic "Host/target separation")
                   (hyperdoc::cross-compiler-topic "Cross-compiler")
                   (hyperdoc::genesis-build-stage-topic "Genesis build stage")
                   (hyperdoc::cold-core-topic "Cold core")
                   (hyperdoc::cold-init-topic "Cold init")
                   (hyperdoc::bootstrap-determinism-topic "Bootstrap determinism")
                   (hyperdoc::image-as-deployment-artifact-topic "Image as deployment artifact")
                   (hyperdoc::live-image-versus-durable-source-topic "Live image versus durable source")
                   (hyperdoc::bootstrappability-as-social-architecture-topic
                    "Bootstrappability as social architecture")))
    (destructuring-bind (symbol title) entry
      (assert-topic-function-present symbol title)))
  (dolist (title '("SBCL bootstrapping model"
                   "Source-oriented and image-oriented development in Common Lisp"
                   "Host and target separation in SBCL"
                   "SBCL build stages: cross-compiler, genesis, cold core, cold init"
                   "SBCL"
                   "SBCL Process"
                   "Understanding ASDF Systems in HyperDoc"))
    (assert-hyperdoc-page-present title)))

(defun run-codex-handover-doc-slice-smoke-test ()
  (dolist (entry '((hyperdoc::single-slice-codex-thread-topic "Single-slice Codex thread")
                   (hyperdoc::filled-task-slice-topic "Filled task slice")
                   (hyperdoc::prompt-local-slice-contract-topic "Prompt-local slice contract")
                   (hyperdoc::authoritative-nix-develop-validation-topic
                    "Authoritative nix develop validation")
                   (hyperdoc::inventory-outcome-topic "Inventory outcome")
                   (hyperdoc::continuity-shell-by-design-topic
                    "Continuity shell by design")
                   (hyperdoc::exact-outcome-reporting-topic "Exact outcome reporting")))
    (destructuring-bind (symbol title) entry
      (assert-topic-function-present symbol title)))
  (dolist (title '("Codex handover for HyperDoc"
                   "Best handover to Codex for HyperDoc"))
    (assert-hyperdoc-page-present title))
  (dolist (title '("Best Codex Handover for HyperDoc"
                   "Codex prompts v2 for HyperDoc"
                   "Updated Codex prompts for HyperDoc"))
    (assert-hyperdoc-page-absent title)))

(defun run-clickable-commit-example-discovery-smoke-test ()
  (asdf:load-system :hyperdoc/examples)
  (let ((symbols (mapcar (lambda (spec)
                           (getf (hyperdoc::check-locator-of spec) :function))
                         (hyperdoc::discover-example-checks :system "hyperdoc/examples"))))
    (assert-true (member 'hyperdoc::fedwiki-commit-link-example symbols)
                 "Clickable-commit example must be discoverable through the existing Examples surface")))

(defun run-upstream-main-merge-preparation-chain-smoke-test ()
  (dolist (title '("Merge upstream main into hauptsache via dreyeck fallback"
                   "Merge Readiness and Blockers for upstream main into hauptsache"
                   "Merge Path Decisions for upstream main into hauptsache"
                   "Dry-run Merge Rehearsal for upstream main into hauptsache"
                   "Rehearsal Results for manual conflicts"
                   "Extra Raw Merge Conflicts for upstream main into hauptsache"
                   "Manual Merge Dossier for upstream main into hauptsache"
                   "Manual Conflict Resolution Proposals for upstream main into hauptsache"
                   "Manual Merge Execution Recipes for upstream main into hauptsache"
                   "Dreyeck Extraction Plan for upstream main into hauptsache"
                   "Dreyeck Transition Plan for upstream main into hauptsache"
                   "Dreyeck Executable Scaffold for upstream main into hauptsache"))
    (assert-hyperdoc-page-present title))
  (ensure-hyperdoc-page-lookup-loaded)
  (let* ((dossier (hyperdoc::hyperdoc-upstream-main-into-hauptsache-manual-conflict-dossier))
         (rehearsal (hyperdoc::hyperdoc-upstream-main-into-hauptsache-merge-rehearsal))
         (raw-surface (hyperdoc::hyperdoc-upstream-main-into-hauptsache-extra-raw-conflict-surface))
         (proposal-surface
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-conflict-resolution-proposal-surface))
         (recipe-surface
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-manual-merge-execution-recipe-surface))
         (frontier (hyperdoc::hyperdoc-upstream-main-into-hauptsache-current-manual-merge-frontier))
         (remaining-paths (mapcar #'hyperdoc::path-of
                                  (hyperdoc::remaining-historical-results-of frontier)))
         (current-proposal-paths (mapcar #'hyperdoc::path-of
                                         (hyperdoc::current-frontier-proposals-of frontier)))
         (current-recipe-paths (mapcar #'hyperdoc::path-of
                                       (hyperdoc::current-frontier-recipes-of frontier)))
         (proposal-gap-paths (hyperdoc::proposal-gap-paths-of frontier))
         (recipe-gap-paths (hyperdoc::recipe-gap-paths-of frontier))
         (rendering-proposal
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-hyperbook-explorer-rendering-resolution-proposal))
         (fedwiki-proposal
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-hyperbook-fedwiki-fedwiki-resolution-proposal))
         (list-editions-proposal
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-hyperbook-wikipedia-list-editions-resolution-proposal))
         (package-recipe
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-hyperbook-explorer-package-execution-recipe))
         (rendering-recipe
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-hyperbook-explorer-rendering-execution-recipe))
         (list-editions-recipe
           (hyperdoc::hyperdoc-upstream-main-into-hauptsache-hyperbook-wikipedia-list-editions-execution-recipe))
         (rendering-extra
           (find "hyperbook-explorer/rendering.lisp"
                 (hyperdoc::promoted-extra-conflicts-of frontier)
                 :key #'hyperdoc::path-of
                 :test #'string=))
         (fedwiki-extra
           (find "hyperbook-fedwiki/fedwiki.lisp"
                 (hyperdoc::promoted-extra-conflicts-of frontier)
                 :key #'hyperdoc::path-of
                 :test #'string=)))
    (assert-true (typep frontier 'hyperdoc::git-manual-merge-frontier-surface)
                 "Current frontier entrypoint should return a git-manual-merge-frontier-surface")
    (assert-true (typep recipe-surface 'hyperdoc::git-manual-merge-execution-recipe-surface)
                 "Execution recipe entrypoint should return a git-manual-merge-execution-recipe-surface")
    (assert-equal 3
                  (length (hyperdoc::conflicts-of dossier))
                  "Historical manual dossier should preserve the original three-path set")
    (assert-equal 3
                  (length (hyperdoc::rehearsal-results-of rehearsal))
                  "Rehearsal should still materialize three historical dossier results")
    (assert-equal 1
                  (length (hyperdoc::typed-manual-results-of raw-surface))
                  "Only one historical dossier path should remain on the current raw frontier")
    (assert-equal 5
                  (length (hyperdoc::extra-conflicts-of raw-surface))
                  "Five typed extra raw conflicts should remain outside the historical dossier")
    (assert-equal 5
                  (length (hyperdoc::promoted-extra-conflicts-of frontier))
                  "All five typed extra raw conflicts should be promoted into the current frontier")
    (assert-equal 5
                  (length (hyperdoc::promoted-frontier-proposals-of proposal-surface))
                  "All five promoted extra raw conflicts should have proposal objects")
    (assert-equal 6
                  (length (hyperdoc::current-frontier-proposals-of proposal-surface))
                  "The current frontier proposal surface should cover the one remaining dossier path plus the five promoted extras")
    (assert-equal 1
                  (length (hyperdoc::historical-current-recipes-of recipe-surface))
                  "Exactly one historical dossier path should still need a current-frontier execution recipe")
    (assert-equal 5
                  (length (hyperdoc::promoted-current-recipes-of recipe-surface))
                  "All five promoted extra raw conflicts should have execution recipes")
    (assert-equal 6
                  (length (hyperdoc::current-frontier-recipes-of recipe-surface))
                  "The execution recipe surface should cover the full six-path current frontier")
    (assert-equal 8
                  (length (hyperdoc::proposals-of proposal-surface))
                  "The public proposal surface should preserve the three historical dossier proposals and add five promoted ones")
    (assert-equal '("hyperbook-explorer/package.lisp")
                  remaining-paths
                  "Only hyperbook-explorer/package.lisp should remain from the historical dossier on the raw frontier")
    (assert-equal '("hyperbook-explorer/package.lisp"
                    "hyperbook-explorer/rendering.lisp"
                    "hyperbook-fedwiki/fedwiki.lisp"
                    "hyperbook-fedwiki/pages.lisp"
                    "hyperbook-wikipedia/list-wikipedia-editions.lisp"
                    "hyperbook-wikipedia/wikipedia.lisp")
                  current-proposal-paths
                  "The current frontier proposals should cover all six current blocking paths")
    (assert-equal 0
                  (length proposal-gap-paths)
                  "The current proposal surface should leave no proposal gap on the current frontier")
    (assert-equal '("hyperbook-explorer/package.lisp"
                    "hyperbook-explorer/rendering.lisp"
                    "hyperbook-fedwiki/fedwiki.lisp"
                    "hyperbook-fedwiki/pages.lisp"
                    "hyperbook-wikipedia/list-wikipedia-editions.lisp"
                    "hyperbook-wikipedia/wikipedia.lisp")
                  current-recipe-paths
                  "The current frontier execution recipes should cover all six current blocking paths")
    (assert-equal 0
                  (length recipe-gap-paths)
                  "The current execution recipe surface should leave no recipe gap on the current frontier")
    (assert-equal 0
                  (length (hyperdoc::remainder-paths-of frontier))
                  "No untyped raw conflict remainder should remain")
    (assert-true rendering-extra
                 "Rendering conflict should appear in the promoted current frontier")
    (assert-equal "extract-to-dreyeck"
                  (hyperdoc::classification-of
                   (hyperdoc::original-decision-of rendering-extra))
                  "The rendering conflict should preserve its earlier pre-rehearsal extract-to-dreyeck classification")
    (assert-equal "promoted-manual-merge-needed"
                  (hyperdoc::frontier-classification-of rendering-extra)
                  "The rendering conflict should now be typed as promoted manual merge work")
    (assert-true fedwiki-extra
                 "FedWiki conflict should appear in the promoted current frontier")
    (assert-equal "adopt-upstream"
                  (hyperdoc::classification-of
                   (hyperdoc::original-decision-of fedwiki-extra))
                  "The fedwiki conflict should preserve its earlier pre-rehearsal adopt-upstream classification")
    (assert-equal "promoted-manual-merge-needed"
                  (hyperdoc::frontier-classification-of fedwiki-extra)
                  "The fedwiki conflict should now be typed as promoted manual merge work")
    (assert-true rendering-proposal
                 "Rendering conflict should have a durable proposal object")
    (assert-equal "true-manual-splice"
                  (hyperdoc::merge-action-of rendering-proposal)
                  "Rendering proposal should be a shared-core manual splice, not a dreyeck promotion")
    (assert-true (typep (hyperdoc::extra-conflict-of rendering-proposal)
                        'hyperdoc::git-extra-raw-conflict)
                 "Rendering proposal should link back to the promoted extra raw conflict")
    (assert-true fedwiki-proposal
                 "FedWiki conflict should have a durable proposal object")
    (assert-equal "true-manual-splice"
                  (hyperdoc::merge-action-of fedwiki-proposal)
                  "FedWiki proposal should remain shared-core manual merge work")
    (assert-true list-editions-proposal
                 "Wikipedia edition-list add/add conflict should have a durable proposal object")
    (assert-equal "adopt-upstream"
                  (hyperdoc::merge-action-of list-editions-proposal)
                  "Wikipedia edition-list helper should resolve by adopting the richer upstream copy")
    (assert-true package-recipe
                 "The remaining historical dossier raw conflict should have an execution recipe")
    (assert-equal "remaining-historical-dossier-raw-conflict"
                  (hyperdoc::frontier-status-of package-recipe)
                  "The package export-block recipe should stay marked as the remaining historical raw conflict")
    (assert-equal "true-manual-splice"
                  (hyperdoc::merge-action-of package-recipe)
                  "The package export-block recipe should remain a true manual splice")
    (assert-true (typep (hyperdoc::proposal-of package-recipe)
                        'hyperdoc::git-conflict-resolution-proposal)
                 "Execution recipes should link back to their conflict-resolution proposals")
    (assert-true rendering-recipe
                 "The promoted rendering conflict should have an execution recipe")
    (assert-equal "promoted-extra-raw-conflict"
                  (hyperdoc::frontier-status-of rendering-recipe)
                  "The rendering recipe should stay typed as a promoted extra raw conflict")
    (assert-true (hyperdoc::validation-targets-of rendering-recipe)
                 "Execution recipes should record post-splice validation targets")
    (assert-true list-editions-recipe
                 "The adopt-upstream helper conflict should have an execution recipe")
    (assert-equal "adopt-upstream"
                  (hyperdoc::merge-action-of list-editions-recipe)
                  "The list-editions execution recipe should preserve the adopt-upstream action")))

(defun run-drew-mind-and-mechanism-doc-slice-smoke-test ()
  (dolist (entry '((hyperdoc::computationalism-topic "Computationalism")
                   (hyperdoc::symbols-and-semantics-topic "Symbols and semantics")
                   (hyperdoc::informational-meaning-topic "Informational meaning")
                   (hyperdoc::intentionality-topic "Intentionality")))
    (destructuring-bind (symbol title) entry
      (assert-topic-function-present symbol title)))
  (dolist (title '("Mind and Mechanism"
                   "Mind and Mechanism compatibility with HyperDoc"
                   "Symbols and semantics in Mind and Mechanism"
                   "Computationalism in Mind and Mechanism"))
    (assert-hyperdoc-page-present title))
  (dolist (relative-path '("hyperdoc/Mind and Mechanism.html"
                           "hyperdoc/Mind and Mechanism compatibility with HyperDoc.html"
                           "hyperdoc/Symbols and semantics in Mind and Mechanism.html"
                           "hyperdoc/Computationalism in Mind and Mechanism.html"))
    (assert-page-source-contains relative-path
                                 "(mind-and-mechanism-zotero-resolution-report)"))
  (assert-page-source-contains "hyperdoc/Resolve a local PDF from Zotero in HyperDoc.html"
                               "machine-local evidence")
  (assert-true (null (hyperbook:find-page hyperdoc::*topics* "Mind and Mechanism"))
               "Mind and Mechanism should remain a HyperDoc page-level bridge, not a topic"))

(defun run-bibliography-subcollections-doc-slice-smoke-test ()
  (dolist (entry '((hyperdoc::bibliography-subcollection-topic "Bibliography subcollection")
                   (hyperdoc::bibliography-entry-topic "Bibliography entry")
                   (hyperdoc::candidate-topic-topic "Candidate topic")
                   (hyperdoc::topic-comparison-report-topic "Topic comparison report")
                   (hyperdoc::authoring-decision-topic "Authoring decision")
                   (hyperdoc::hyperdoc-authoring-plan-topic "HyperDoc authoring plan")))
    (destructuring-bind (symbol title) entry
      (assert-topic-function-present symbol title)))
  (dolist (title '("Bibliography subcollections in HyperDoc"
                   "Coachmark bibliography authoring plan"
                   "Bibliography authoring plan live evaluation"
                   "Bibliography authoring-plan stand-in inspection"))
    (assert-hyperdoc-page-present title))
  (assert-page-source-contains "hyperdoc/Bibliography subcollections in HyperDoc.html"
                               "(coachmark-bibliography-authoring-plan)")
  (assert-page-source-contains "hyperdoc/Bibliography subcollections in HyperDoc.html"
                               "(coachmark-bibliography-authoring-plan-standin-report)")
  (assert-page-source-contains "hyperdoc/Bibliography subcollections in HyperDoc.html"
                               "collection name can influence candidate extraction")
  (assert-page-source-contains "hyperdoc/Bibliography subcollections in HyperDoc.html"
                               "1 passed, 1 failed, 1 did not run in Chromium")
  (assert-page-source-contains "hyperdoc/Bibliography subcollections in HyperDoc.html"
                               "paneOpenMs")
  (assert-page-source-contains "hyperdoc/Bibliography subcollections in HyperDoc.html"
                               "60_000ms")
  (assert-page-source-contains "hyperdoc/Coachmark bibliography authoring plan.html"
                               "machine-local runtime evidence")
  (assert-page-source-contains "hyperdoc/Coachmark bibliography authoring plan.html"
                               "collection-name evidence")
  (assert-page-source-contains "hyperdoc/Coachmark bibliography authoring plan.html"
                               "entry-derived evidence")
  (assert-page-source-contains "hyperdoc/Coachmark bibliography authoring plan.html"
                               "Collection summary</b>, <b>Entries</b>, and <b>Candidate topics</b>")
  (assert-page-source-contains "hyperdoc/Coachmark bibliography authoring plan.html"
                               "Open authoring plan")
  (assert-page-source-contains "hyperdoc/Coachmark bibliography authoring plan.html"
                               "materialization consequence")
  (assert-page-source-contains "hyperdoc/Bibliography subcollections in HyperDoc.html"
                               "proposed later repo touch")
  (assert-page-source-contains "hyperdoc/Bibliography authoring plan live evaluation.html"
                               "machine-local live evaluation surface")
  (assert-page-source-contains "hyperdoc/Bibliography authoring plan live evaluation.html"
                               "1 passed, 1 failed, 1 did not run in Chromium")
  (assert-page-source-contains "hyperdoc/Bibliography authoring plan live evaluation.html"
                               "pane-open timing JSON artifact")
  (assert-page-source-contains "hyperdoc/Bibliography authoring plan live evaluation.html"
                               "HTML Rewriting live plan")
  (assert-page-source-contains "hyperdoc/Bibliography authoring plan live evaluation.html"
                               "Topological Intelligence live plan")
  (assert-page-source-contains "hyperdoc/Bibliography authoring plan live evaluation.html"
                               "Plastics Packaging live plan")
  (assert-page-source-contains "hyperdoc/Bibliography authoring plan live evaluation.html"
                               "Bibliography authoring-plan stand-in inspection")
  (assert-page-source-contains "hyperdoc/Bibliography authoring-plan stand-in inspection.html"
                               "Universal Thing")
  (assert-page-source-contains "hyperdoc/Bibliography authoring-plan stand-in inspection.html"
                               "Browser stand-in")
  (assert-page-source-contains "hyperdoc/Bibliography authoring-plan stand-in inspection.html"
                               "Browser isolation layer")
  (assert-page-source-contains "hyperdoc/Bibliography authoring-plan stand-in inspection.html"
                               "(plastics-packaging-bibliography-authoring-plan-standin-report)")
  (assert-page-source-contains "hyperdoc/Bibliography authoring-plan stand-in inspection.html"
                               "ready before the pane-open and rendering boundary"))

(defun run-merged-doc-slices-smoke-tests ()
  (run-clickable-commit-ids-doc-slice-smoke-test)
  (run-literate-tracing-doc-slice-smoke-test)
  (run-execution-evidence-vocabulary-smoke-test)
  (run-sbcl-bootstrapping-doc-slice-smoke-test)
  (run-codex-handover-doc-slice-smoke-test)
  (run-clickable-commit-example-discovery-smoke-test)
  (run-upstream-main-merge-preparation-chain-smoke-test)
  (run-drew-mind-and-mechanism-doc-slice-smoke-test)
  (run-bibliography-subcollections-doc-slice-smoke-test)
  (format t "~&Merged documentation slice smoke tests passed.~%")
  t)
