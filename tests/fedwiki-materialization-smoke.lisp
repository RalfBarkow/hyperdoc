;;;; Smoke tests for FedWiki materialization plans
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-FEDWIKI-MATERIALIZATION-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun fedwiki-materialization-smoke-tempdir ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "fedwiki-materialization-smoke-~D/" (get-universal-time))
    (uiop:temporary-directory))))

(defun run-fedwiki-materialization-smoke-tests ()
  (let* ((root (fedwiki-materialization-smoke-tempdir))
         (pages-dir (merge-pathnames "pages/" root))
         (page-plan
           (hyperdoc:plan-fedwiki-page-materialization
            "civilian-casualty-mitigation"
            :fedwiki-pages-directory pages-dir
            :fedwiki-repo-root root
            :hyperdoc-repo-root (asdf:system-source-directory :hyperdoc)
            :expected-fedwiki-branch nil))
         (page-entry (first (hyperdoc::fedwiki-materialization-entries-of page-plan)))
         (slice-plan
           (hyperdoc:plan-fedwiki-slice-materialization
            "minab-school-strike"
            :include-daily-anchor-p t
            :fedwiki-pages-directory pages-dir
            :fedwiki-repo-root root
            :hyperdoc-repo-root (asdf:system-source-directory :hyperdoc)
            :expected-fedwiki-branch nil)))
    (assert-equal 1
                  (length (hyperdoc::fedwiki-materialization-entries-of page-plan))
                  "Page materialization must plan exactly one entry")
    (assert-equal :topic-fedwiki-page
                  (hyperdoc::fedwiki-materialization-entry-source-kind-of page-entry)
                  "Missing topic-linked page should fall back to topic-derived materialization")
    (assert-equal :create
                  (hyperdoc::fedwiki-materialization-entry-action-of page-entry)
                  "Missing page should be planned as a create")
    (assert-equal 8
                  (length (hyperdoc::fedwiki-materialization-entries-of slice-plan))
                  "Slice plan should include seven FedWiki pages plus the daily anchor")
    (hyperdoc::materialize-fedwiki-materialization-plan page-plan)
    (let* ((target (merge-pathnames "civilian-casualty-mitigation" pages-dir))
           (page (hyperdoc::article-allegation-read-json-file target)))
      (assert-true (uiop:file-exists-p target)
                   "Materialization should create the requested live page")
      (assert-string= "Civilian casualty mitigation in targeting operations"
                      (getf page :title)
                      "Topic-derived FedWiki page title should match the topic title")
      (assert-true (hyperdoc::journalmatic-commit-gate-pass-p page)
                   "Materialized page must satisfy the journal gate")))
  (format t "~&FedWiki materialization smoke tests passed.~%")
  t)
