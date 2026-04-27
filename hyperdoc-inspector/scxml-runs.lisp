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
