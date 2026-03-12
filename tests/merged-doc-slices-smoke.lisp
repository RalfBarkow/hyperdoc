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

(defun run-clickable-commit-example-discovery-smoke-test ()
  (asdf:load-system :hyperdoc/examples)
  (let ((symbols (mapcar (lambda (spec)
                           (getf (hyperdoc::check-locator-of spec) :function))
                         (hyperdoc::discover-example-checks :system "hyperdoc/examples"))))
    (assert-true (member 'hyperdoc::fedwiki-commit-link-example symbols)
                 "Clickable-commit example must be discoverable through the existing Examples surface")))

(defun run-merged-doc-slices-smoke-tests ()
  (run-clickable-commit-ids-doc-slice-smoke-test)
  (run-literate-tracing-doc-slice-smoke-test)
  (run-execution-evidence-vocabulary-smoke-test)
  (run-sbcl-bootstrapping-doc-slice-smoke-test)
  (run-clickable-commit-example-discovery-smoke-test)
  (format t "~&Merged documentation slice smoke tests passed.~%")
  t)
