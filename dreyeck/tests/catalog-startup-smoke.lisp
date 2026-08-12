(defpackage #:dreyeck/catalog/tests
  (:use #:cl)
  (:export #:run-catalog-startup-smoke-tests))

(in-package #:dreyeck/catalog/tests)

(defun check (condition format-control &rest format-arguments)
  (unless condition
    (error (apply #'format nil format-control format-arguments))))

(defun dreyeck-asd-pathname ()
  (truename
   (asdf:system-source-file
    (asdf:find-system "dreyeck/catalog/tests"))))

(defun repository-directory ()
  (uiop:pathname-directory-pathname (dreyeck-asd-pathname)))

(defun startup-script-pathname ()
  (merge-pathnames #P"scripts/serve-catalog.sh"
                   (repository-directory)))

(defun historical-startup-script-pathname ()
  (merge-pathnames #P"scripts/serve-wiki-link-contract-demo.sh"
                   (repository-directory)))

(defun deleted-demo-startup-script-pathname ()
  (merge-pathnames #P"dreyeck/scripts/serve-wiki-link-contract-demo.sh"
                   (repository-directory)))

(defun repository-shell-script-pathnames ()
  (directory (merge-pathnames #P"scripts/*.sh" (repository-directory))))

(defun fresh-catalog-evaluations ()
  (list
   "(require :asdf)"
   (format nil "(asdf:load-asd #P~S)"
           (namestring (dreyeck-asd-pathname)))
   "(asdf:load-system \"hyperdoc\")"
   "(asdf:load-system \"hyperbook/server\")"
   "(assert (null (find-package \"DREYECK/UPSTREAM-INTAKE\")))"
   "(assert (null (find-package \"DREYECK/FEDWIKI-SOURCE-RELATIONS\")))"
   "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/upstream-intake\"))))"
   "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/fedwiki-source-relations\"))))"
   "(assert (null (hyperbook:find-hyperbook \"dreyeck/wiki-link\")))"
   "(assert (null (hyperbook:find-hyperbook \"dreyeck/upstream-intake\")))"
   "(assert (null (hyperbook:find-hyperbook \"dreyeck/fedwiki-source-relations\")))"
   "(asdf:load-system \"dreyeck/catalog\")"
   "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/upstream-intake\")))"
   "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/fedwiki-source-relations\")))"
   "(assert (find-package \"DREYECK/UPSTREAM-INTAKE\"))"
   "(assert (find-package \"DREYECK/FEDWIKI-SOURCE-RELATIONS\"))"
   "(let* ((wiki (hyperbook:find-hyperbook \"dreyeck/wiki-link\" :signal-error? t)) (intake (hyperbook:find-hyperbook \"dreyeck/upstream-intake\" :signal-error? t)) (relations (hyperbook:find-hyperbook \"dreyeck/fedwiki-source-relations\" :signal-error? t)) (members (hyperbook:hyperbooks-of hyperbook:*catalog*))) (hyperdoc::ensure-pages-loaded wiki) (hyperdoc::ensure-pages-loaded intake) (hyperdoc::ensure-pages-loaded relations) (assert (string= \"Wiki-link title and slug lookup contracts\" (hyperbook:main-page-id-of wiki))) (assert (hyperbook:find-page wiki \"Wiki-link title and slug lookup contracts\" :signal-error? t)) (assert (string= \"Upstream Intake as a Read-Only Observation\" (hyperbook:main-page-id-of intake))) (assert (= 4 (hash-table-count (hyperdoc:pages-of intake)))) (dolist (page-id '(\"Upstream Intake as a Read-Only Observation\" \"Observing an Upstream Commit\" \"An Upstream Supersession Hypothesis\" \"Historical ASDF Dependencies as a Topicmap\")) (assert (hyperbook:find-page intake page-id :signal-error? t))) (assert (= 1 (count \"dreyeck/fedwiki-source-relations\" members :key #'hyperbook:id-of :test #'string=))) (assert (string= \"FedWiki Component Order and Source Relations\" (hyperbook:title-of relations))) (assert (string= \"FedWiki Component Order and Source Relations\" (hyperbook:main-page-id-of relations))) (assert (= 1 (hash-table-count (hyperdoc:pages-of relations)))) (assert (hyperbook:find-page relations \"FedWiki Component Order and Source Relations\" :signal-error? t)) (format t \"FRESH-DREYECK-CATALOG=~S~%\" (mapcar (lambda (book) (list (hyperbook:id-of book) (hyperbook:title-of book))) members)))"
   "(let ((git-intake (dreyeck/upstream-intake:make-hyperdoc-host-not-found-intake)) (component-intake (dreyeck/upstream-intake:make-hyperspec-component-intake))) (assert (find \"Upstream Intake\" (html-inspector-views:all-views git-intake) :key #'html-inspector-views:view-title :test #'string=)) (assert (find \"Upstream Intake\" (html-inspector-views:all-views component-intake) :key #'html-inspector-views:view-title :test #'string=)))"
   "(format t \"Fresh Dreyeck catalog startup tests passed.~%\")"))

(defun fresh-catalog-command ()
  (append
   (list (namestring sb-ext:*runtime-pathname*)
         "--noinform" "--no-userinit" "--non-interactive")
   (loop for form in (fresh-catalog-evaluations)
         append (list "--eval" form))))

(defun check-normal-startup-contract ()
  (let ((script (startup-script-pathname)))
    (check (uiop:file-exists-p script)
           "The canonical Catalog launcher does not exist: ~A."
           script)
    (uiop:run-program (list "test" "-x" (namestring script)))
    (let ((source (uiop:read-file-string script)))
      (check (search
              "HYPERDOC_CATALOG_SYSTEM=${HYPERDOC_CATALOG_SYSTEM:-dreyeck/catalog}"
              source)
             "Normal Catalog startup has no explicit dreyeck/catalog default.")
      (check (search "asdf:load-system system" source)
             "Normal Catalog startup does not load its configured Catalog system.")
      (check (null (search "HYPERDOC_DEMO_SYSTEM" source))
             "The canonical Catalog launcher still exposes the demo-system contract."))
    (check (not (probe-file (historical-startup-script-pathname)))
           "The historical root-level launcher still exists.")
    (check (not (probe-file (deleted-demo-startup-script-pathname)))
           "The deleted nested Dreyeck demo launcher still exists.")
    (dolist (shell-script (repository-shell-script-pathnames))
      (let ((shell-source (uiop:read-file-string shell-script)))
        (check (null (search
                      "dreyeck/scripts/serve-wiki-link-contract-demo.sh"
                      shell-source))
               "Active launcher ~A still refers to the deleted nested launcher."
               shell-script))))
  t)

(defun run-catalog-startup-smoke-tests ()
  (check-normal-startup-contract)
  (uiop:run-program
   (fresh-catalog-command)
   :directory (repository-directory)
   :output *standard-output*
   :error-output *error-output*)
  (format t "Dreyeck Catalog startup smoke tests passed.~%")
  t)
