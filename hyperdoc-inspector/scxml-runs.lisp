;;;; Inspector views for SCXML repair-protocol dry-runs
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun native-scxml-finding-lines (run)
  (let ((findings (hyperdoc::native-scxml-run-validation-findings-of run)))
    (if findings
        (mapcar (lambda (finding)
                  (format nil "[~A] ~A: ~A"
                          (hyperdoc/scxml:scxml-validation-finding-severity-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-code-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-message-of
                           finding)))
                findings)
        (list "No validation findings."))))

(defun native-scxml-trace-string (run)
  (with-output-to-string (stream)
    (dolist (line (or (hyperdoc::native-scxml-run-trace-of run) '()))
      (write-string line stream)
      (terpri stream))))

(defun scxml-expectation-finding-lines (run)
  (let ((findings (hyperdoc::scxml-expectation-run-validation-findings-of run)))
    (if findings
        (mapcar (lambda (finding)
                  (format nil "[~A] ~A: ~A"
                          (hyperdoc/scxml:scxml-validation-finding-severity-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-code-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-message-of
                           finding)))
                findings)
        (list "No validation findings."))))

(defun scxml-expectation-trace-string (run)
  (with-output-to-string (stream)
    (dolist (line (or (hyperdoc::scxml-expectation-run-trace-of run) '()))
      (write-string line stream)
      (terpri stream))))

(defun scxml-expectation-events-string (run)
  (with-output-to-string (stream)
    (dolist (event (or (hyperdoc::scxml-expectation-run-input-events-of run) '()))
      (write-string event stream)
      (terpri stream))))

(defun scxml-expectation-facts-string (run)
  (with-output-to-string (stream)
    (let ((*print-pretty* t))
      (pprint (hyperdoc::scxml-expectation-run-semantic-facts-of run)
              stream))))

(defun test-system-scxml-finding-lines (run)
  (let ((findings
          (hyperdoc::hyperdoc-test-system-scxml-run-validation-findings-of
           run)))
    (if findings
        (mapcar (lambda (finding)
                  (format nil "[~A] ~A: ~A"
                          (hyperdoc/scxml:scxml-validation-finding-severity-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-code-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-message-of
                           finding)))
                findings)
        (list "No validation findings."))))

(defun test-system-scxml-trace-string (run)
  (with-output-to-string (stream)
    (dolist (line (or (hyperdoc::hyperdoc-test-system-scxml-run-trace-of run)
                      '()))
      (write-string line stream)
      (terpri stream))))

(defun test-system-scxml-events-string (run)
  (with-output-to-string (stream)
    (dolist (event
             (or (hyperdoc::hyperdoc-test-system-scxml-run-input-events-of run)
                 '()))
      (write-string event stream)
      (terpri stream))))

(defun test-system-scxml-plist-pairs (plist)
  (loop for (key value) on plist by #'cddr
        collect (list key value)))

(defun test-system-scxml-facts-string (run)
  (with-output-to-string (stream)
    (let ((*print-pretty* t))
      (pprint (hyperdoc::hyperdoc-test-system-scxml-run-environment-summary-of
               run)
              stream))))

(defun localhost-fedwiki-page-promotion-workflow-scxml-finding-lines (run)
  (let ((findings
          (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-validation-findings-of
           run)))
    (if findings
        (mapcar (lambda (finding)
                  (format nil "[~A] ~A: ~A"
                          (hyperdoc/scxml:scxml-validation-finding-severity-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-code-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-message-of
                           finding)))
                findings)
        (list "No validation findings."))))

(defun localhost-fedwiki-page-promotion-workflow-scxml-trace-string (run)
  (with-output-to-string (stream)
    (dolist (line
             (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-trace-of
                  run)
                 '()))
      (write-string line stream)
      (terpri stream))))

(defun localhost-fedwiki-page-promotion-workflow-scxml-events-string (run)
  (with-output-to-string (stream)
    (dolist (event
             (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-input-events-of
                  run)
                 '()))
      (write-string event stream)
      (terpri stream))))

(defun localhost-fedwiki-page-promotion-workflow-scxml-facts-string (run)
  (with-output-to-string (stream)
    (let ((*print-pretty* t))
      (pprint
       (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-semantic-facts-of
        run)
       stream))))

(defun dmx-annotation-acceptance-scxml-finding-lines (run)
  (let ((findings
          (hyperdoc::dmx-annotation-acceptance-scxml-run-validation-findings-of
           run)))
    (if findings
        (mapcar (lambda (finding)
                  (format nil "[~A] ~A: ~A"
                          (hyperdoc/scxml:scxml-validation-finding-severity-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-code-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-message-of
                           finding)))
                findings)
        (list "No validation findings."))))

(defun dmx-annotation-acceptance-scxml-trace-string (run)
  (with-output-to-string (stream)
    (dolist (line
             (or (hyperdoc::dmx-annotation-acceptance-scxml-run-trace-of run)
                 '()))
      (write-string line stream)
      (terpri stream))))

(defun dmx-annotation-acceptance-scxml-events-string (run)
  (with-output-to-string (stream)
    (dolist (event
             (or (hyperdoc::dmx-annotation-acceptance-scxml-run-input-events-of
                  run)
                 '()))
      (write-string event stream)
      (terpri stream))))

(defun dmx-annotation-acceptance-scxml-facts-string (run)
  (with-output-to-string (stream)
    (let ((*print-pretty* t))
      (pprint
       (hyperdoc::dmx-annotation-acceptance-scxml-run-semantic-facts-of run)
       stream))))

(defun dmx-annotation-acceptance-scxml-skipped-checks-string (run)
  (with-output-to-string (stream)
    (let ((*print-pretty* t))
      (pprint
       (hyperdoc::dmx-annotation-acceptance-scxml-run-skipped-checks-of run)
       stream))))

(defun dmx-annotation-acceptance-scxml-commits-string (run)
  (format nil "~{~A~^, ~}"
          (or (hyperdoc::dmx-annotation-acceptance-scxml-run-accepted-commits-of
               run)
              '())))

(defun dmx-annotation-acceptance-scxml-command-string (command)
  (if command
      (format nil "~{~A~^ ~}" command)
      "n/a"))

(defun dmx-annotation-acceptance-scxml-live-enabled-p ()
  (string= (or (uiop:getenv "HYPERDOC_RUN_LIVE_DMX_ANNOTATION_TESTS") "")
           "1"))

(defun dmx-action-auth-session-scxml-finding-lines (run)
  (let ((findings
          (hyperdoc::dmx-action-auth-session-run-validation-findings-of run)))
    (if findings
        (mapcar (lambda (finding)
                  (format nil "[~A] ~A: ~A"
                          (hyperdoc/scxml:scxml-validation-finding-severity-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-code-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-message-of
                           finding)))
                findings)
        (list "No validation findings."))))

(defun dmx-action-auth-session-scxml-trace-string (run)
  (with-output-to-string (stream)
    (dolist (line
             (or (hyperdoc::dmx-action-auth-session-run-trace-of run)
                 '()))
      (write-string line stream)
      (terpri stream))))

(defun dmx-action-auth-session-scxml-events-string (run)
  (with-output-to-string (stream)
    (dolist (event
             (or (hyperdoc::dmx-action-auth-session-run-input-events-of run)
                 '()))
      (write-string event stream)
      (terpri stream))))

(views:defview 👀overview
    (run hyperdoc::page-lookup-topic-repair-scxml-run)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::scxml-run-scxml-path-of run))))))
              (:tr (:td (views:esc "Command"))
                   (:td (:pre
                         (views:esc
                          (format nil "~{~A~^ ~}"
                                  (hyperdoc::scxml-run-command-of run))))))
              (:tr (:td (views:esc "Exit code"))
                   (:td (:tt
                         (views:esc
                          (princ-to-string
                           (hyperdoc::scxml-run-exit-code-of run)))))))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc
             (or (hyperdoc::scxml-run-stdout-of run) "")))
      (when (plusp (length (or (hyperdoc::scxml-run-stderr-of run) "")))
        (views:html
          (:h3 (views:esc "Errors"))
          (:pre (views:esc
                 (hyperdoc::scxml-run-stderr-of run))))))))

(views:defview 👀overview
    (run hyperdoc::page-lookup-topic-repair-native-scxml-run)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::native-scxml-run-scxml-path-of run))))))
              (:tr (:td (views:esc "Generated package"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::native-scxml-run-generated-package-of run)))))
              (:tr (:td (views:esc "Generated function"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::native-scxml-run-generated-function-of run)))))
              (:tr (:td (views:esc "Done"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::native-scxml-run-done-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Final state"))
                   (:td (:tt
                         (views:esc
                          (if-let (final-state
                                   (hyperdoc::native-scxml-run-final-state-of run))
                              (format nil "~A" final-state)
                              "n/a"))))))
      (:h3 (views:esc "Validation findings"))
      (:pre (views:esc
             (format nil "~{~A~%~}"
                     (native-scxml-finding-lines run))))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc (native-scxml-trace-string run))))))

(views:defview 👀overview
    (run hyperdoc::scxml-expectation-run)
  (views:html-view :title "Page promotion output-sync expectation" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Scenario"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::scxml-expectation-run-expected-subject-of run)
                              "n/a")))))
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::scxml-expectation-run-scxml-path-of run))))))
              (:tr (:td (views:esc "Generated package"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::scxml-expectation-run-generated-package-of run)
                              "n/a")))))
              (:tr (:td (views:esc "Generated function"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::scxml-expectation-run-generated-function-of run)
                              "n/a")))))
              (:tr (:td (views:esc "Done"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::scxml-expectation-run-done-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Passed"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::scxml-expectation-run-passed-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Final state"))
                   (:td (:tt
                         (views:esc
                          (if-let (final-state
                                   (hyperdoc::scxml-expectation-run-final-state-of run))
                              (format nil "~A" final-state)
                              "n/a"))))))
      (:h3 (views:esc "Validation findings"))
      (:pre (views:esc
             (format nil "~{~A~%~}"
                     (scxml-expectation-finding-lines run))))
      (:h3 (views:esc "Semantic facts"))
      (:pre (views:esc (scxml-expectation-facts-string run)))
      (:h3 (views:esc "Input events"))
      (:pre (views:esc (scxml-expectation-events-string run)))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc (scxml-expectation-trace-string run))))))

(views:defview 👀overview
    (run hyperdoc::hyperdoc-test-system-scxml-run)
  (views:html-view :title "HyperDoc test-system SCXML runbook" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::hyperdoc-test-system-scxml-run-scxml-path-of
                            run))))))
              (:tr (:td (views:esc "Done"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::hyperdoc-test-system-scxml-run-done-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Passed"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::hyperdoc-test-system-scxml-run-passed-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Final state"))
                   (:td (:tt
                         (views:esc
                          (if-let (final-state
                                   (hyperdoc::hyperdoc-test-system-scxml-run-final-state-of
                                    run))
                              (format nil "~A" final-state)
                              "n/a")))))
              (:tr (:td (views:esc "Blocker"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::hyperdoc-test-system-scxml-run-blocker-of run)
                              "n/a")))))
              (:tr (:td (views:esc "Blocker classification"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::hyperdoc-test-system-scxml-run-blocker-classification-of
                                   run))))))
              (:tr (:td (views:esc "Suggested next action"))
                   (:td (views:esc
                         (or (hyperdoc::hyperdoc-test-system-scxml-run-suggested-next-action-of
                              run)
                             "n/a")))))
      (:h3 (views:esc "Environment summary"))
      (:pre (views:esc (test-system-scxml-facts-string run)))
      (:h3 (views:esc "Phase results"))
      (:table :class "inspector-table"
              (dolist (pair
                       (test-system-scxml-plist-pairs
                        (or (hyperdoc::hyperdoc-test-system-scxml-run-phase-results-of run)
                            '())))
                (views:html
                  (:tr (:td (:tt (views:esc (format nil "~A" (first pair)))))
                       (:td (:tt (views:esc (format nil "~A" (second pair)))))))))
      (:h3 (views:esc "Focused checks"))
      (:table :class "inspector-table"
              (dolist (pair
                       (test-system-scxml-plist-pairs
                        (or (hyperdoc::hyperdoc-test-system-scxml-run-focused-check-results-of
                             run)
                            '())))
                (views:html
                  (:tr (:td (:tt (views:esc (format nil "~A" (first pair)))))
                       (:td (:tt (views:esc (format nil "~A" (second pair)))))))))
      (:h3 (views:esc "Full-suite result"))
      (:table :class "inspector-table"
              (dolist (pair
                       (test-system-scxml-plist-pairs
                        (or (hyperdoc::hyperdoc-test-system-scxml-run-full-suite-result-of
                             run)
                            '())))
                (views:html
                  (:tr (:td (:tt (views:esc (format nil "~A" (first pair)))))
                       (:td (:tt (views:esc (format nil "~A" (second pair)))))))))
      (:h3 (views:esc "Input events"))
      (:pre (views:esc (test-system-scxml-events-string run)))
      (:h3 (views:esc "Validation findings"))
      (:pre (views:esc
             (format nil "~{~A~%~}"
                     (test-system-scxml-finding-lines run))))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc (test-system-scxml-trace-string run))))))

(views:defview 👀overview
    (run hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run)
  (views:html-view :title "Localhost FedWiki page-promotion workflow (SCXML)"
                   :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-scxml-path-of
                            run))))))
              (:tr (:td (views:esc "Plan id"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-plan-id-of
                               run)
                              "n/a")))))
              (:tr (:td (views:esc "Plan title"))
                   (:td (views:esc
                         (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-plan-title-of
                              run)
                             "n/a"))))
              (:tr (:td (views:esc "Done"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-done-p-of
                               run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Passed"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-passed-p-of
                               run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Final state"))
                   (:td (:tt
                         (views:esc
                          (if-let (final-state
                                   (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-final-state-of
                                    run))
                              (format nil "~A" final-state)
                              "n/a")))))
              (:tr (:td (views:esc "Failure classification"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-failure-classification-of
                                   run))))))
              (:tr (:td (views:esc "Blocker"))
                   (:td (views:esc
                         (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-blocker-of
                              run)
                             "n/a"))))
              (:tr (:td (views:esc "Suggested next action"))
                   (:td (views:esc
                         (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-suggested-next-action-of
                              run)
                             "n/a")))))
      (:h3 (views:esc "Semantic facts"))
      (:pre (views:esc
             (localhost-fedwiki-page-promotion-workflow-scxml-facts-string
              run)))
      (:h3 (views:esc "Phase results"))
      (:table :class "inspector-table"
              (dolist (pair
                       (test-system-scxml-plist-pairs
                        (or (hyperdoc::localhost-fedwiki-page-promotion-workflow-scxml-run-phase-results-of
                             run)
                            '())))
                (views:html
                  (:tr (:td (:tt (views:esc (format nil "~A" (first pair)))))
                       (:td (:tt (views:esc (format nil "~A" (second pair)))))))))
      (:h3 (views:esc "Input events"))
      (:pre (views:esc
             (localhost-fedwiki-page-promotion-workflow-scxml-events-string
              run)))
      (:h3 (views:esc "Validation findings"))
      (:pre (views:esc
             (format nil
                     "~{~A~%~}"
                     (localhost-fedwiki-page-promotion-workflow-scxml-finding-lines
                      run))))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc
             (localhost-fedwiki-page-promotion-workflow-scxml-trace-string
             run))))))

(views:defview 👀overview
    (run hyperdoc::dmx-annotation-acceptance-scxml-run)
  (views:html-view :title "DMX annotation acceptance SCXML runbook" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::dmx-annotation-acceptance-scxml-run-scxml-path-of
                            run))))))
              (:tr (:td (views:esc "Accepted commits"))
                   (:td (:tt
                         (views:esc
                          (dmx-annotation-acceptance-scxml-commits-string run)))))
              (:tr (:td (views:esc "Replay mode"))
                   (:td (:tt
                         (views:esc
                          (case (hyperdoc::dmx-annotation-acceptance-scxml-run-replay-mode-of
                                 run)
                            (:live "live")
                            (otherwise "dry/native"))))))
              (:tr (:td (views:esc "Done"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::dmx-annotation-acceptance-scxml-run-done-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Passed"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::dmx-annotation-acceptance-scxml-run-passed-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Final state"))
                   (:td (:tt
                         (views:esc
                          (if-let (final-state
                                   (hyperdoc::dmx-annotation-acceptance-scxml-run-final-state-of
                                    run))
                              (format nil "~A" final-state)
                              "n/a")))))
              (:tr (:td (views:esc "Generated package"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::dmx-annotation-acceptance-scxml-run-generated-package-of run)
                              "n/a")))))
              (:tr (:td (views:esc "Generated function"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::dmx-annotation-acceptance-scxml-run-generated-function-of run)
                              "n/a"))))))
      (:h3 (views:esc "Skipped checks"))
      (:pre (views:esc
             (dmx-annotation-acceptance-scxml-skipped-checks-string run)))
      (:h3 (views:esc "Validation findings"))
      (:pre (views:esc
             (format nil "~{~A~%~}"
                     (dmx-annotation-acceptance-scxml-finding-lines run))))
      (:h3 (views:esc "Semantic facts"))
      (:pre (views:esc
             (dmx-annotation-acceptance-scxml-facts-string run)))
      (:h3 (views:esc "Input events"))
      (:pre (views:esc
             (dmx-annotation-acceptance-scxml-events-string run)))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc
             (dmx-annotation-acceptance-scxml-trace-string run)))
      (when (hyperdoc::dmx-annotation-acceptance-scxml-run-live-ran-p-of run)
        (views:html
          (:h3 (views:esc "Live replay"))
          (:table :class "inspector-table"
                  (:tr (:td (views:esc "Command"))
                       (:td (:tt
                             (views:esc
                              (dmx-annotation-acceptance-scxml-command-string
                               (hyperdoc::dmx-annotation-acceptance-scxml-run-replay-command-of
                                run))))))
                  (:tr (:td (views:esc "Exit code"))
                       (:td (:tt
                             (views:esc
                              (princ-to-string
                               (or (hyperdoc::dmx-annotation-acceptance-scxml-run-live-exit-code-of
                                    run)
                                   "n/a")))))))
          (when (plusp (length (or (hyperdoc::dmx-annotation-acceptance-scxml-run-live-stdout-of
                                    run)
                                   "")))
            (views:html
              (:h3 (views:esc "Live stdout (sanitized)"))
              (:pre (views:esc
                     (hyperdoc::dmx-annotation-acceptance-scxml-run-live-stdout-of
                      run)))))
          (when (plusp (length (or (hyperdoc::dmx-annotation-acceptance-scxml-run-live-stderr-of
                                    run)
                                   "")))
            (views:html
              (:h3 (views:esc "Live stderr (sanitized)"))
              (:pre (views:esc
                     (hyperdoc::dmx-annotation-acceptance-scxml-run-live-stderr-of
                      run))))))))))

(views:defview 👀actions
    (run hyperdoc::dmx-annotation-acceptance-scxml-run)
  (declare (ignore run))
  (views:html-view :title "Replay" :priority 2
    (views:html
      (:p
       (views:action-button
        "Replay SCXML locally"
        (views:thunk
          (hyperdoc::run-dmx-annotation-acceptance-scxml-runbook :live? nil))
        "Parse, validate, and replay the SCXML runbook locally without DMX credentials."))
      (if (dmx-annotation-acceptance-scxml-live-enabled-p)
          (views:html
            (:p
             (views:action-button
              "Replay live smoke"
              (views:thunk
                (hyperdoc::run-dmx-annotation-acceptance-scxml-runbook :live? t))
              "Replay live DMX smoke through the explicit runbook channel.")))
          (views:html
            (:p :style "opacity:0.65"
                (views:esc
                 "Replay live smoke disabled. Set HYPERDOC_RUN_LIVE_DMX_ANNOTATION_TESTS=1 to enable the action.")))))))

(views:defview 👀overview
    (run hyperdoc::dmx-action-auth-session-run)
  (views:html-view :title "DMX action auth/session SCXML" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::dmx-action-auth-session-run-scxml-path-of
                            run))))))
              (:tr (:td (views:esc "Selected auth mode"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-action-auth-session-run-selected-auth-mode-of
                                   run))))))
              (:tr (:td (views:esc "Workspace id"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (or (hyperdoc::dmx-action-auth-session-run-workspace-id-of
                                       run)
                                      "n/a"))))))
              (:tr (:td (views:esc "Topic id"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (or (hyperdoc::dmx-action-auth-session-run-topic-id-of
                                       run)
                                      "n/a"))))))
              (:tr (:td (views:esc "Bootstrap required"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::dmx-action-auth-session-run-bootstrap-required-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Bootstrap attempted"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::dmx-action-auth-session-run-bootstrap-attempted-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Bootstrap status"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-action-auth-session-run-bootstrap-status-of
                                   run))))))
              (:tr (:td (views:esc "Session cookie present"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::dmx-action-auth-session-run-session-cookie-present-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Cookie shape"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-action-auth-session-run-session-cookie-shape-of run)))))
              (:tr (:td (views:esc "Authorization scheme"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-action-auth-session-run-authorization-scheme-of run)))))
              (:tr (:td (views:esc "Continuation readiness"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-action-auth-session-run-continuation-readiness-of
                                   run))))))
              (:tr (:td (views:esc "Redaction status"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-action-auth-session-run-redaction-status-of
                                   run))))))
              (:tr (:td (views:esc "Failure boundary"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-action-auth-session-run-failure-boundary-of
                                   run))))))
              (:tr (:td (views:esc "Done"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::dmx-action-auth-session-run-done-p-of run)
                              "yes"
                              "no")))))
              (:tr (:td (views:esc "Final state"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (or (hyperdoc::dmx-action-auth-session-run-final-state-of run)
                                      "n/a"))))))
              (:tr (:td (views:esc "Passed"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::dmx-action-auth-session-run-passed-p-of run)
                              "yes"
                              "no"))))))
      (:h3 (views:esc "Validation findings"))
      (:pre (views:esc
             (format nil "~{~A~%~}"
                     (dmx-action-auth-session-scxml-finding-lines run))))
      (:h3 (views:esc "Input events"))
      (:pre (views:esc
             (dmx-action-auth-session-scxml-events-string run)))
      (:h3 (views:esc "Trace"))
      (:pre (views:esc
             (dmx-action-auth-session-scxml-trace-string run))))))

(defun dmx-annotation-workspace-view-scxml-finding-lines (run)
  (let ((findings
          (hyperdoc::dmx-annotation-workspace-view-run-validation-findings-of
           run)))
    (if findings
        (mapcar (lambda (finding)
                  (format nil "[~A] ~A: ~A"
                          (hyperdoc/scxml:scxml-validation-finding-severity-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-code-of
                           finding)
                          (hyperdoc/scxml:scxml-validation-finding-message-of
                           finding)))
                findings)
        (list "No validation findings."))))

(defun dmx-annotation-workspace-view-boolean-label (value)
  (if value "yes" "no"))

(defun dmx-annotation-workspace-view-next-states-string (run)
  (let ((states (hyperdoc::dmx-annotation-workspace-view-run-next-states-of run)))
    (if states
        (format nil "~{~A~^, ~}" states)
        "-")))

(defun dmx-annotation-workspace-view-secondary-actions-string (run)
  (let ((labels
          (hyperdoc::dmx-annotation-workspace-view-run-secondary-action-labels-of
           run)))
    (if labels
        (format nil "~{~A~^, ~}" labels)
        "-")))

(defun dmx-annotation-workspace-view-action-plan-bool-label (value)
  (if value "yes" "no"))

(defun dmx-annotation-workspace-view-action-plans-by-origin
    (run mapped-from-scxml-p)
  (remove-if-not (lambda (plan)
                   (eq mapped-from-scxml-p
                       (hyperdoc::dmx-annotation-workspace-view-action-plan-mapped-from-scxml-p
                        plan)))
                 (or (hyperdoc::dmx-annotation-workspace-view-run-enabled-action-plans-of
                      run)
                     '())))

(views:defview 👀overview
    (run hyperdoc::dmx-annotation-workspace-view-run)
  (views:html-view :title "DMX annotation Workspace view SCXML plan" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "SCXML path"))
                   (:td (:tt
                         (views:esc
                          (namestring
                           (hyperdoc::dmx-annotation-workspace-view-run-scxml-path-of
                            run))))))
              (:tr (:td (views:esc "Current state"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-annotation-workspace-view-run-current-state-of
                           run)))))
              (:tr (:td (views:esc "Selected preview event"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-annotation-workspace-view-run-selected-preview-event-of
                           run)))))
              (:tr (:td (views:esc "Expected next states"))
                   (:td (:tt
                         (views:esc
                          (dmx-annotation-workspace-view-next-states-string
                           run)))))
              (:tr (:td (views:esc "Primary action label"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-annotation-workspace-view-run-primary-action-label-of
                           run)))))
              (:tr (:td (views:esc "Target workspace id"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-annotation-workspace-view-run-workspace-id-of
                                   run))))))
              (:tr (:td (views:esc "Target topicmap id"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-annotation-workspace-view-run-workspace-topicmap-id-of
                                   run))))))
              (:tr (:td (views:esc "Local lane state"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-annotation-workspace-view-run-local-lane-state-of
                           run)))))
              (:tr (:td (views:esc "Carrier topic id"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-annotation-workspace-view-run-carrier-topic-label-of
                           run)))))
              (:tr (:td (views:esc "Assignment status"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-annotation-workspace-view-run-assignment-status-label-of
                           run)))))
              (:tr (:td (views:esc "Topicmap placement status"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::dmx-annotation-workspace-view-run-topicmap-placement-status-label-of
                           run)))))
              (:tr (:td (views:esc "Mutates local journal"))
                   (:td (:tt
                         (views:esc
                          (dmx-annotation-workspace-view-boolean-label
                           (hyperdoc::dmx-annotation-workspace-view-run-local-journal-mutation-p-of
                            run))))))
              (:tr (:td (views:esc "Mutates DMX"))
                   (:td (:tt
                         (views:esc
                          (dmx-annotation-workspace-view-boolean-label
                           (hyperdoc::dmx-annotation-workspace-view-run-dmx-mutation-p-of
                            run))))))
              (:tr (:td (views:esc "TOPIC_UPSERT will run"))
                   (:td (:tt
                         (views:esc
                          (dmx-annotation-workspace-view-boolean-label
                           (hyperdoc::dmx-annotation-workspace-view-run-topic-upsert-will-run-p-of
                            run))))))
              (:tr (:td (views:esc "Executor function"))
                   (:td (:tt
                         (views:esc
                          (format nil "~A"
                                  (hyperdoc::dmx-annotation-workspace-view-run-executor-function-of
                                   run)))))))
      (when (hyperdoc::dmx-annotation-workspace-view-run-chart-dot-text-of run)
        (views:html
          (:h3 (views:esc "SCXML chart visualization"))
          (views:graphviz-snippet
           (hyperdoc::dmx-annotation-workspace-view-run-chart-dot-text-of run))
          (:details
           (:summary (views:esc "Derived DOT source"))
           (:pre :style "white-space: pre-wrap;"
                 (views:esc
                  (hyperdoc::dmx-annotation-workspace-view-run-chart-dot-text-of
                   run))))))
      (when (hyperdoc::dmx-annotation-workspace-view-run-workspace-write-plan-of
             run)
        (views:html
          (:h3 (views:esc "Typed write plan"))
          (:p (views:object-ref
               (hyperdoc::dmx-annotation-workspace-view-run-workspace-write-plan-of
                run)
               :display "plan-dmx-workspace-annotation-write-from-object"))))
      (when (hyperdoc::dmx-annotation-workspace-view-run-workspace-write-plan-error-of
             run)
        (views:html
          (:h3 (views:esc "Write plan error"))
          (:pre (views:esc
                 (hyperdoc::dmx-annotation-workspace-view-run-workspace-write-plan-error-of
                  run)))))
      (when (hyperdoc::dmx-annotation-workspace-view-run-auth-session-submachine-run-of
             run)
        (views:html
          (:h3 (views:esc "Continuation auth/session submachine"))
          (:p (views:object-ref
               (hyperdoc::dmx-annotation-workspace-view-run-auth-session-submachine-run-of
                run)
               :display "Inspect continuation auth/session run"))))
      (:h3 (views:esc "Validation findings"))
      (:pre (views:esc
             (format nil "~{~A~%~}"
                     (dmx-annotation-workspace-view-scxml-finding-lines
                      run)))))))

(views:defview 👀actions
    (run hyperdoc::dmx-annotation-workspace-view-run)
  (views:html-view :title "Actions" :priority 2
    (views:html
      (:p
       (views:esc
        "The Workspace dashboard is statechart-backed: primary/secondary actions come from the current SCXML state and mapped diagnostics."))
      (:p
       (views:action-button
        "Explain boundary ownership"
        (views:thunk
          (hyperdoc::compare-dock-annotation-with-guarded-workspace-path
           (hyperdoc::dmx-annotation-workspace-view-run-annotation-of run)
           :workspace-topicmap-id
           (hyperdoc::dmx-annotation-workspace-view-run-workspace-topicmap-id-of
            run)
           :workspace-id
           (hyperdoc::dmx-annotation-workspace-view-run-workspace-id-of run)
           :client
           (hyperdoc::dmx-annotation-workspace-view-run-client-of run)))
        "Show why local save, DMX projection/materialization, and guarded continuation belong to distinct mutation boundaries.")))))
