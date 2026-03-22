;;;; Semantic-first anchor drift audit
;;
;;;; Source-based audit for the current Connect/provider UI surfaces.

(defstruct audit-check
  status
  label
  detail)

(defstruct audit-report
  checks)

(defun read-file-string* (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (with-output-to-string (out)
      (loop for line = (read-line stream nil nil)
            while line
            do (write-line line out)))))

(defun make-pass (label)
  (make-audit-check :status :passed :label label))

(defun make-fail (label detail)
  (make-audit-check :status :failed :label label :detail detail))

(defun check-pattern-present (path content pattern label)
  (if (search pattern content)
      (make-pass label)
      (make-fail label
                 (format nil "Missing pattern in ~A: ~S" path pattern))))

(defun check-pattern-absent (path content pattern label)
  (if (search pattern content)
      (make-fail label
                 (format nil "Found stale pattern in ~A: ~S" path pattern))
      (make-pass label)))

(defun count-checks (checks status)
  (count status checks :key #'audit-check-status))

(defun semantic-first-anchor-audit-report ()
  (let* ((anchor-model-path "hyperdoc/dom-annotations.lisp")
         (anchor-model (read-file-string* anchor-model-path))
         (explorer-path "hyperdoc-explorer/dom-annotations.lisp")
         (explorer (read-file-string* explorer-path))
         (connect-js-path "assets/hyperdoc/js/dom-annotation-connect.js")
         (connect-js (read-file-string* connect-js-path))
         (checks
           (list
            (check-pattern-present
             anchor-model-path
             anchor-model
             "(defun semantic-anchor-identity-fields"
             "anchor envelope exposes semantic identity fields separately")
            (check-pattern-present
             anchor-model-path
             anchor-model
             "(defun presentation-anchor-fallback-fields"
             "anchor envelope exposes presentation fallback fields separately")
            (check-pattern-present
             anchor-model-path
             anchor-model
             "(cons \"Semantic identity\""
             "semantic identity is labeled explicitly")
            (check-pattern-present
             anchor-model-path
             anchor-model
             "(cons \"Fallback strategy\""
             "fallback strategy is labeled as fallback metadata")
            (check-pattern-present
             anchor-model-path
             anchor-model
             "(cons \"Fallback value\""
             "fallback value is labeled as fallback metadata")
            (check-pattern-present
             anchor-model-path
             anchor-model
             "durability-tier"
             "anchor model keeps durability tier available")
            (check-pattern-present
             explorer-path
             explorer
             "(semantic-anchor-identity-fields anchor)"
             "inspector rendering reads semantic identity fields")
            (check-pattern-present
             explorer-path
             explorer
             "(presentation-anchor-fallback-fields anchor)"
             "inspector rendering reads presentation fallback fields")
            (check-pattern-present
             explorer-path
             explorer
             "(:h4 \"Semantic anchor\")"
             "inspector renders a dedicated Semantic anchor section")
            (check-pattern-present
             explorer-path
             explorer
             "(:h4 \"Presentation fallback\")"
             "inspector renders a dedicated Presentation fallback section")
            (check-pattern-present
             explorer-path
             explorer
             "(:h4 \"Durability\")"
             "inspector renders a dedicated Durability section")
            (check-pattern-present
             explorer-path
             explorer
             "\"Connect structural anchors in this view to create an association.\""
             "content provider help uses anchor-first wording")
            (check-pattern-present
             explorer-path
             explorer
             "\"Connect source anchors in this view to create an association.\""
             "source provider help uses anchor-first wording")
            (check-pattern-present
             explorer-path
             explorer
             "\"Connect story-item anchors in this view to create an association.\""
             "FedWiki provider help uses anchor-first wording")
            (check-pattern-present
             connect-js-path
             connect-js
             "\"Connect anchors in this view to create an association.\""
             "generic Connect chrome copy uses anchor/view wording")
            (check-pattern-absent
             explorer-path
             explorer
             "Connect visible elements"
             "provider help avoids stale visible-elements wording")
            (check-pattern-absent
             connect-js-path
             connect-js
             "Connect visible elements"
             "pane chrome copy avoids stale visible-elements wording")
            (check-pattern-absent
             explorer-path
             explorer
             "in this page to create an association"
             "provider help avoids page-scoped wording")
            (check-pattern-absent
             connect-js-path
             connect-js
             "in this page to create an association"
             "pane chrome copy avoids page-scoped wording")
            (check-pattern-absent
             explorer-path
             explorer
             "target element"
             "provider help avoids target-element wording")
            (check-pattern-absent
             connect-js-path
             connect-js
             "target element"
             "pane chrome copy avoids target-element wording"))))
    (make-audit-report :checks checks)))

(defun semantic-first-anchor-audit-pass-p (report)
  (zerop (count-checks (audit-report-checks report) :failed)))

(defun print-prefixed-lines (prefix text)
  (with-input-from-string (stream (princ-to-string text))
    (loop for line = (read-line stream nil nil)
          while line
          do (format t "~A~A~%" prefix line))))

(defun print-semantic-first-anchor-audit-report (report)
  (dolist (check (audit-report-checks report))
    (format t "~A ~A~%"
            (ecase (audit-check-status check)
              (:passed "PASS ")
              (:failed "FAIL "))
            (audit-check-label check))
    (when (audit-check-detail check)
      (print-prefixed-lines "      " (audit-check-detail check))))
  (let ((passes (count-checks (audit-report-checks report) :passed))
        (fails (count-checks (audit-report-checks report) :failed)))
    (format t "----~%")
    (format t "SUMMARY passes=~D fails=~D~%" passes fails)
    (format t "~A~%"
            (if (semantic-first-anchor-audit-pass-p report)
                "SEMANTIC_FIRST_ANCHOR_AUDIT_OK"
                "SEMANTIC_FIRST_ANCHOR_AUDIT_FAIL"))))

(defun main ()
  (let ((args (cdr sb-ext:*posix-argv*)))
    (when (member "--help" args :test #'string=)
      (format t
              "Usage: sbcl --no-userinit --script tools/semantic-first-anchor-audit.lisp~%")
      (sb-ext:exit :code 0))
    (let ((report (semantic-first-anchor-audit-report)))
      (print-semantic-first-anchor-audit-report report)
      (sb-ext:exit :code (if (semantic-first-anchor-audit-pass-p report) 0 1)))))

(main)
