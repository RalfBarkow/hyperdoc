;;;; Smoke tests for structured page-lookup issues
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-PAGE-LOOKUP-ISSUES-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun smoke-find-hyperdoc-page (title)
  (hyperbook:find-page hyperdoc:*hyperdoc* title :signal-error? t))

(defun smoke-heading-texts (page)
  (mapcar #'plump:text
          (plump:get-elements-by-tag-name (hyperbook:dom-of page) "h2")))

(defun smoke-fedwiki-link-texts (page)
  (loop for anchor in (plump:get-elements-by-tag-name (hyperbook:dom-of page) "a")
        for hb = (plump:get-attribute anchor "hyperbook")
        when (and hb (uiop:string-prefix-p "fedwiki:" hb))
          collect (plump:text anchor)))

(defun smoke-find-issue-by-target (issues target-id)
  (find target-id
        issues
        :test #'string=
        :key #'hyperbook:lookup-issue-expected-page-id-of))

(defun run-page-lookup-issues-smoke-tests ()
  (let* ((denk-page (smoke-find-hyperdoc-page "Denkpanzer paper 2013"))
         (denk-headings (smoke-heading-texts denk-page))
         (denk-counterpart-issues
           (slot-value denk-page 'hyperdoc::counterpart-section-issues))
         (denk-link-texts (smoke-fedwiki-link-texts denk-page)))
    (assert-true (member "FedWiki counterparts" denk-headings :test #'string=)
                 "Counterpart heading should be normalized away from Localhost")
    (assert-true (equal '("[wiki.ralfbarkow.ch] denkpanzer-paper-2013"
                          "[wiki.ralfbarkow.ch] denkpanzer-stren")
                        denk-link-texts)
                 "FedWiki counterpart links should be prefixed with their actual site")
    (assert-equal 1 (length denk-counterpart-issues)
                  "Denkpanzer page should record one mislabelled counterpart-section issue")
    (let ((issue (first denk-counterpart-issues)))
      (assert-equal :mislabelled-target-grouping
                    (hyperbook:lookup-issue-classification-of issue)
                    "Counterpart-section issue should be classified as mislabelled target grouping")
      (assert-equal :mislabelled-target
                    (hyperbook:lookup-issue-status-of issue)
                    "Counterpart-section issue should carry the dedicated status"))
    (let* ((writing-page (smoke-find-hyperdoc-page "Writing text pages"))
           (issues (hyperbook:lookup-issues-of writing-page))
           (missing-issue (smoke-find-issue-by-target issues
                                                     "Defining custom views")))
      (assert-true missing-issue
                   "Writing text pages should expose the missing Defining custom views target as a structured issue")
      (assert-equal :missing-hyperdoc-page
                    (hyperbook:lookup-issue-classification-of missing-issue)
                    "Missing HyperDoc page should classify separately from FedWiki publication issues")
      (assert-equal :scaffold-hyperdoc-page
                    (hyperbook:lookup-issue-suggested-repair-of missing-issue)
                    "Missing HyperDoc page should propose a scaffold operation")
      (let ((repair (funcall (slot-value missing-issue 'hyperbook::repair-thunk))))
        (assert-true (typep repair 'hyperdoc::hyperdoc-authoring-scaffold-plan)
                     "Repair thunk should yield a HyperDoc authoring scaffold plan")
        (assert-equal :page
                      (hyperdoc::hyperdoc-authoring-scaffold-mode-of repair)
                      "Missing HyperDoc page scaffold should be page-mode")
        (assert-string= "Defining custom views"
                        (hyperdoc::hyperdoc-authoring-scaffold-page-id-of repair)
                        "Scaffold plan should keep the missing target id"))
      (hyperbook:mark-lookup-issue! missing-issue :fixed)
      (assert-equal :fixed
                    (hyperbook:lookup-issue-status-of missing-issue)
                    "Lookup-issue status should be markable from the operation flow")))
  (format t "~&Page lookup issue smoke tests passed.~%")
  t)

