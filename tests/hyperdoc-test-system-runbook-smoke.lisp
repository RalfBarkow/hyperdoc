;;;; Smoke tests for HyperDoc test-system SCXML runbook
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun test-system-runbook-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun test-system-runbook-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun test-system-runbook-assert-substring (needle haystack message)
  (test-system-runbook-assert-true
   (and haystack
        (search needle haystack :test #'char-equal))
   (format nil "~A -- missing substring ~S" message needle)))

(defun make-test-system-runbook-phase-results
    (&key (dmx-annotations :pass)
       (topic-factory-dmx :pass))
  (list :environment :captured
        :scxml-compiler :pass
        :uscxml-repair :pass
        :dmx-annotations dmx-annotations
        :collective-knowledge :pass
        :fedwiki-promotion-output-sync :pass
        :topic-factory-dmx topic-factory-dmx))

(defun run-hyperdoc-test-system-runbook-all-pass-smoke-test ()
  (let ((run (hyperdoc::run-hyperdoc-test-system-runbook-scxml
              :phase-results
              (make-test-system-runbook-phase-results)
              :full-suite-result
              (list :status :pass
                    :event "ASDF.TEST_SYSTEM.PASS"
                    :classification :none))))
    (test-system-runbook-assert-true
     (hyperdoc::hyperdoc-test-system-scxml-run-done-p-of run)
     "All-pass runbook scenario must reach a final state")
    (test-system-runbook-assert-true
     (hyperdoc::hyperdoc-test-system-scxml-run-passed-p-of run)
     "All-pass runbook scenario must pass")
    (test-system-runbook-assert-equal
     "passed"
     (hyperdoc::hyperdoc-test-system-scxml-run-final-state-of run)
     "All-pass runbook scenario must finish in final state passed")
    (test-system-runbook-assert-equal
     :none
     (hyperdoc::hyperdoc-test-system-scxml-run-blocker-classification-of run)
     "All-pass runbook scenario must classify no blocker")))

(defun run-hyperdoc-test-system-runbook-serializer-contract-smoke-test ()
  (let* ((run (hyperdoc::run-hyperdoc-test-system-runbook-scxml
               :phase-results
               (make-test-system-runbook-phase-results
                :topic-factory-dmx :fail-serializer-contract)
               :full-suite-result
               (list :status :fail
                     :classification :serializer-contract
                     :event "TOPIC_FACTORY_DMX.FAIL_SERIALIZER_CONTRACT"
                     :blocker "Topic factory DMX serializer contract")))
         (trace (hyperdoc::hyperdoc-test-system-scxml-run-trace-of run)))
    (test-system-runbook-assert-true
     (hyperdoc::hyperdoc-test-system-scxml-run-done-p-of run)
     "Serializer-contract runbook scenario must reach a final state")
    (test-system-runbook-assert-true
     (not (hyperdoc::hyperdoc-test-system-scxml-run-passed-p-of run))
     "Serializer-contract runbook scenario must not pass")
    (test-system-runbook-assert-equal
     "failedSerializerContract"
     (hyperdoc::hyperdoc-test-system-scxml-run-final-state-of run)
     "Serializer-contract runbook scenario must finish in failedSerializerContract")
    (test-system-runbook-assert-equal
     :serializer-contract
     (hyperdoc::hyperdoc-test-system-scxml-run-blocker-classification-of run)
     "Serializer-contract runbook scenario must classify serializer-contract")
    (test-system-runbook-assert-true
     (find-if (lambda (line)
                (search "serializer contract"
                        line
                        :test #'char-equal))
              trace)
     "Serializer-contract runbook scenario trace must mention serializer contract")))

(defun run-hyperdoc-test-system-runbook-live-precondition-skip-smoke-test ()
  (let* ((run (hyperdoc::run-hyperdoc-test-system-runbook-scxml
               :phase-results
               (make-test-system-runbook-phase-results
                :dmx-annotations :skipped-live-precondition)
               :full-suite-result
               (list :status :pass
                     :event "ASDF.TEST_SYSTEM.PASS"
                     :classification :none)))
         (events (hyperdoc::hyperdoc-test-system-scxml-run-input-events-of run)))
    (test-system-runbook-assert-true
     (hyperdoc::hyperdoc-test-system-scxml-run-passed-p-of run)
     "Live-precondition skip runbook scenario must still pass")
    (test-system-runbook-assert-true
     (member "DMX.ANNOTATIONS.SKIPPED_LIVE_PRECONDITION"
             events
             :test #'string=)
     "Runbook input events must encode explicit DMX live-precondition skip")
    (test-system-runbook-assert-true
     (eq :none
         (hyperdoc::hyperdoc-test-system-scxml-run-blocker-classification-of run))
     "Live-precondition skip runbook scenario must not classify a product regression")))

(defun run-hyperdoc-test-system-runbook-unknown-failure-smoke-test ()
  (let* ((run (hyperdoc::run-hyperdoc-test-system-runbook-scxml
               :phase-results
               (make-test-system-runbook-phase-results)
               :full-suite-result
               (list :status :fail
                     :classification :unknown
                     :event "ASDF.TEST_SYSTEM.FAIL_UNKNOWN"
                     :condition-text
                     "Unclassified failing form in downstream full suite.")))
         (next-action
          (hyperdoc::hyperdoc-test-system-scxml-run-suggested-next-action-of run)))
    (test-system-runbook-assert-true
     (hyperdoc::hyperdoc-test-system-scxml-run-done-p-of run)
     "Unknown-failure runbook scenario must reach a final state")
    (test-system-runbook-assert-true
     (not (hyperdoc::hyperdoc-test-system-scxml-run-passed-p-of run))
     "Unknown-failure runbook scenario must not pass")
    (test-system-runbook-assert-equal
     "failedUnknown"
     (hyperdoc::hyperdoc-test-system-scxml-run-final-state-of run)
     "Unknown-failure runbook scenario must finish in failedUnknown")
    (test-system-runbook-assert-equal
     :unknown
     (hyperdoc::hyperdoc-test-system-scxml-run-blocker-classification-of run)
     "Unknown-failure runbook scenario must classify unknown blocker")
    (test-system-runbook-assert-substring
     "focused reproduction"
     next-action
     "Unknown-failure runbook scenario must suggest focused reproduction")))

(defun run-hyperdoc-test-system-runbook-smoke-tests ()
  (run-hyperdoc-test-system-runbook-all-pass-smoke-test)
  (run-hyperdoc-test-system-runbook-serializer-contract-smoke-test)
  (run-hyperdoc-test-system-runbook-live-precondition-skip-smoke-test)
  (run-hyperdoc-test-system-runbook-unknown-failure-smoke-test)
  (format t "~&HyperDoc test-system runbook SCXML smoke tests passed.~%")
  t)
