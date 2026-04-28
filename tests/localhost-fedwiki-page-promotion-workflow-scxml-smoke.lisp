;;;; Smoke tests for localhost FedWiki page-promotion workflow SCXML run
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun workflow-scxml-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun workflow-scxml-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun workflow-scxml-assert-substring (needle haystack message)
  (workflow-scxml-assert-true
   (and haystack
        (search needle haystack :test #'char-equal))
   (format nil "~A -- missing substring ~S" message needle)))

(defun workflow-scxml-run-trace-string (run)
  (format nil "~{~A~%~}"
          (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-trace-of
               run)
              '())))

(defun make-workflow-semantic-facts
    (&key
       (plan-id "deterministic-workflow-plan")
       (plan-title "Deterministic localhost FedWiki promotion workflow plan")
       (source-resolved-p t)
       (source-normalized-p t)
       (source-availability-state :available)
       (source-envelope-malformed-p nil)
       (promotion-plan-built-p t)
       (page-composed-p t)
       (snippet-generated-p t)
       (page-artifact-state :synced)
       (snippet-artifact-state :synced)
       (dmx-dry-run-payload-built-p t)
       (dmx-payload-valid-p t)
       (guarded-write-boundary :accepted)
       (live-dmx-write :skipped-precondition)
       (unexpected-regression-p nil)
       (unexpected-regression-condition nil))
  (list :plan-id plan-id
        :plan-title plan-title
        :source-resolved-p source-resolved-p
        :source-normalized-p source-normalized-p
        :source-availability-state source-availability-state
        :source-envelope-malformed-p source-envelope-malformed-p
        :promotion-plan-built-p promotion-plan-built-p
        :page-composed-p page-composed-p
        :snippet-generated-p snippet-generated-p
        :page-artifact-state page-artifact-state
        :snippet-artifact-state snippet-artifact-state
        :dmx-dry-run-payload-built-p dmx-dry-run-payload-built-p
        :dmx-payload-valid-p dmx-payload-valid-p
        :guarded-write-boundary guarded-write-boundary
        :live-dmx-write live-dmx-write
        :unexpected-regression-p unexpected-regression-p
        :unexpected-regression-condition unexpected-regression-condition))

(defun run-workflow-scenario (&rest facts-plist)
  (hyperdoc::run-localhost-fedwiki-page-promotion-workflow-scxml
   :semantic-facts facts-plist
   :package-name "HYPERDOC/SCXML/GENERATED/LOCALHOST-FEDWIKI-PROMOTION-WORKFLOW/SMOKE"
   :function-name "RUN-LOCALHOST-FEDWIKI-PROMOTION-WORKFLOW-SMOKE"))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-happy-path-smoke-test ()
  (let* ((facts (make-workflow-semantic-facts))
         (run (apply #'run-workflow-scenario facts))
         (trace (workflow-scxml-run-trace-string run)))
    (workflow-scxml-assert-true
     (eq :available (getf facts :source-availability-state))
     "Workflow happy-path semantic facts must start from an available source")
    (workflow-scxml-assert-true
     (eq :synced (getf facts :page-artifact-state))
     "Workflow happy-path semantic facts must mark page artifact as synced")
    (workflow-scxml-assert-true
     (eq :synced (getf facts :snippet-artifact-state))
     "Workflow happy-path semantic facts must mark snippet artifact as synced")
    (workflow-scxml-assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-done-p-of run)
     "Workflow happy-path run must reach a final state")
    (workflow-scxml-assert-true
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-passed-p-of run)
     "Workflow happy-path run must pass")
    (workflow-scxml-assert-equal
     "passed"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Workflow happy-path run must finish in passed")
    (workflow-scxml-assert-equal
     :none
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-failure-classification-of
      run)
     "Workflow happy-path run must classify no failure")
    (workflow-scxml-assert-substring
     "Page-promotion workflow passed"
     trace
     "Workflow happy-path trace must contain success summary")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-source-unavailable-smoke-test
    ()
  (let* ((facts
           (make-workflow-semantic-facts
            :source-resolved-p nil
            :source-normalized-p nil
            :source-availability-state :source-unavailable))
         (run (apply #'run-workflow-scenario facts)))
    (workflow-scxml-assert-equal
     :source-unavailable
     (getf facts :source-availability-state)
     "Source-unavailable scenario facts must encode source-unavailable state")
    (workflow-scxml-assert-equal
     "sourceUnavailable"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Source-unavailable scenario must finish in sourceUnavailable")
    (workflow-scxml-assert-equal
     :source-unavailable
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-failure-classification-of
      run)
     "Source-unavailable scenario must classify source-unavailable")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-malformed-source-smoke-test
    ()
  (let* ((facts
           (make-workflow-semantic-facts
            :source-envelope-malformed-p t
            :source-normalized-p nil))
         (run (apply #'run-workflow-scenario facts)))
    (workflow-scxml-assert-true
     (getf facts :source-envelope-malformed-p)
     "Malformed-source scenario facts must encode malformed envelope state")
    (workflow-scxml-assert-equal
     "malformedSourceEnvelope"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Malformed-source scenario must finish in malformedSourceEnvelope")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-page-artifact-stale-smoke-test
    ()
  (let* ((facts (make-workflow-semantic-facts :page-artifact-state :stale))
         (run (apply #'run-workflow-scenario facts)))
    (workflow-scxml-assert-equal
     :stale
     (getf facts :page-artifact-state)
     "Page-artifact-stale scenario facts must encode stale page artifact")
    (workflow-scxml-assert-equal
     "pageArtifactStale"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Page-artifact-stale scenario must finish in pageArtifactStale")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-snippet-artifact-stale-smoke-test
    ()
  (let* ((facts (make-workflow-semantic-facts :snippet-artifact-state :stale))
         (run (apply #'run-workflow-scenario facts)))
    (workflow-scxml-assert-equal
     :stale
     (getf facts :snippet-artifact-state)
     "Snippet-artifact-stale scenario facts must encode stale snippet artifact")
    (workflow-scxml-assert-equal
     "snippetArtifactStale"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Snippet-artifact-stale scenario must finish in snippetArtifactStale")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-dmx-payload-invalid-smoke-test
    ()
  (let* ((facts (make-workflow-semantic-facts :dmx-payload-valid-p nil))
         (run (apply #'run-workflow-scenario facts)))
    (workflow-scxml-assert-true
     (not (getf facts :dmx-payload-valid-p))
     "DMX-payload-invalid scenario facts must encode invalid payload")
    (workflow-scxml-assert-equal
     "dmxPayloadInvalid"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "DMX-payload-invalid scenario must finish in dmxPayloadInvalid")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-guarded-write-rejected-smoke-test
    ()
  (let* ((facts (make-workflow-semantic-facts :guarded-write-boundary :rejected))
         (run (apply #'run-workflow-scenario facts)))
    (workflow-scxml-assert-equal
     :rejected
     (getf facts :guarded-write-boundary)
     "Guarded-write-rejected scenario facts must encode boundary rejection")
    (workflow-scxml-assert-equal
     "guardedWriteRejected"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Guarded-write-rejected scenario must finish in guardedWriteRejected")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-live-write-skip-smoke-test
    ()
  (let* ((facts (make-workflow-semantic-facts :live-dmx-write :skipped-precondition))
         (run (apply #'run-workflow-scenario facts))
         (trace (workflow-scxml-run-trace-string run)))
    (workflow-scxml-assert-equal
     :skipped-precondition
     (getf facts :live-dmx-write)
     "Live-write-skip scenario facts must encode skipped-precondition default mode")
    (workflow-scxml-assert-equal
     "passed"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Live-write-skip scenario must still finish in passed")
    (workflow-scxml-assert-substring
     "Live DMX write skipped by explicit precondition"
     trace
     "Live-write-skip scenario trace must describe explicit precondition skip")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-unexpected-regression-smoke-test
    ()
  (let* ((facts
           (make-workflow-semantic-facts
            :unexpected-regression-p t
            :unexpected-regression-condition
            "simulated deterministic regression marker"))
         (run (apply #'run-workflow-scenario facts))
         (next-action
           (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-suggested-next-action-of
            run)))
    (workflow-scxml-assert-true
     (getf facts :unexpected-regression-p)
     "Unexpected-regression scenario facts must encode an explicit regression")
    (workflow-scxml-assert-equal
     "unexpectedRegression"
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
      run)
     "Unexpected-regression scenario must finish in unexpectedRegression")
    (workflow-scxml-assert-equal
     :unexpected-regression
     (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-failure-classification-of
      run)
     "Unexpected-regression scenario must classify unexpected-regression")
    (workflow-scxml-assert-substring
     "focused reproduction/classification"
     next-action
     "Unexpected-regression scenario must suggest focused reproduction/classification")))

(defun run-localhost-fedwiki-page-promotion-workflow-scxml-smoke-tests ()
  (run-localhost-fedwiki-page-promotion-workflow-scxml-happy-path-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-source-unavailable-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-malformed-source-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-page-artifact-stale-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-snippet-artifact-stale-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-dmx-payload-invalid-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-guarded-write-rejected-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-live-write-skip-smoke-test)
  (run-localhost-fedwiki-page-promotion-workflow-scxml-unexpected-regression-smoke-test)
  (format t "~&Localhost FedWiki page-promotion workflow SCXML smoke tests passed.~%")
  t)
