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


;;;; Remote FedWiki fork materialization
;;;; Filed out from the live image during Zettel 9124.


(DEFUN RUN-FEDWIKI-MATERIALIZATION-REMOTE-FORK-SMOKE-TESTS ()
  (LET* ((REMOTE-PAGE
          (LIST :TITLE "What Graphviz Does" :STORY
                (LIST
                 (LIST :ID "c558c39c83b0a0b9" :TYPE "paragraph" :TEXT
                       "first paragraph")
                 (LIST :ID "34e2de627fb48408" :TYPE "paragraph" :TEXT
                       "second paragraph")
                 (LIST :ID "6f9382b76ff19154" :TYPE "html" :TEXT
                       "<p>html</p>"))
                :JOURNAL
                (LIST (LIST :TYPE "create" :DATE 1783522915030)
                      (LIST :TYPE "edit" :DATE 1783522915032))))
         (FORK-ACTION
          (HYPERDOC::FEDWIKI-MATERIALIZATION-MAKE-EXPLICIT-FORK-ACTION :SITE
           "does.ward.dojo.fed.wiki" :DATE 1783525442000))
         (FORK-PAGE
          (HYPERDOC::FEDWIKI-MATERIALIZATION-PAGE-WITH-APPENDED-FORK-ACTION
           REMOTE-PAGE FORK-ACTION))
         (REMOTE-STORY-IDS
          (HYPERDOC::FEDWIKI-MATERIALIZATION-PAGE-STORY-ITEM-IDS REMOTE-PAGE))
         (FORK-STORY-IDS
          (HYPERDOC::FEDWIKI-MATERIALIZATION-PAGE-STORY-ITEM-IDS FORK-PAGE))
         (REMOTE-JOURNAL (GETF REMOTE-PAGE :JOURNAL))
         (FORK-JOURNAL (GETF FORK-PAGE :JOURNAL))
         (LAST-ACTION (CAR (LAST FORK-JOURNAL))))
    (ASSERT-EQUAL "What Graphviz Does" (GETF FORK-PAGE :TITLE)
     "Remote fork candidate must preserve the source page title.")
    (ASSERT-EQUAL REMOTE-STORY-IDS FORK-STORY-IDS
     "Remote fork candidate must preserve source story ids and order.")
    (ASSERT-EQUAL 2 (LENGTH REMOTE-JOURNAL)
     "Remote page fixture must begin with two source journal actions.")
    (ASSERT-EQUAL 3 (LENGTH FORK-JOURNAL)
     "Remote fork candidate must append exactly one fork journal action.")
    (ASSERT-EQUAL "fork" (GETF LAST-ACTION :TYPE)
     "Last journal action must be the explicit fork action.")
    (ASSERT-EQUAL "does.ward.dojo.fed.wiki" (GETF LAST-ACTION :SITE)
     "Fork action must retain the source site.")
    (ASSERT-EQUAL 1783525442000 (GETF LAST-ACTION :DATE)
     "Fork action must retain the selected monotonic date.")
    (ASSERT-TRUE
     (HYPERDOC::FEDWIKI-MATERIALIZATION-CANONICAL-FORK-ACTION-P LAST-ACTION)
     "Fork action must be canonical type/site/date.")
    (ASSERT-TRUE (NOT (GETF FORK-PAGE :SOURCE-SLUG))
     "Canonical page JSON must not include HyperDoc-only source slug.")
    (ASSERT-TRUE (NOT (GETF FORK-PAGE :TARGET-SITE))
     "Canonical page JSON must not include HyperDoc-only target site.")
    T))
