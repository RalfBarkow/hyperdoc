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

(defun presentation-controller-coverage-cases nil
       (copy-tree
                  (quote
                         ((:failure-id
                                       "failure:dreyeck/catalog:presentation-controller-not-materialized"
                                       :failure-label
                                       "Catalog presentation controller not materialized"
                                       :condition
                                       :function-not-fbound-after-system-load
                                       :test-case-id
                                       "test-case:dreyeck/catalog:fresh-presentation-controller-present"
                                       :test-case-label
                                       "Fresh catalog presentation controller is present"
                                       :evaluation
                                       "(LET* ((PACKAGE (FIND-PACKAGE \"DREYECK/CATALOG\"))
       (SYMBOL
        (AND PACKAGE (FIND-SYMBOL \"CATALOG-PRESENTATION-STATE\" PACKAGE))))
  (ASSERT (AND SYMBOL (FBOUNDP SYMBOL))))"
                                       :verification
                                       (:status :present :verification
                                                :fresh-process)
                                       :may-fail-as-id
                                       "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:not-materialized"
                                       :covered-by-id
                                       "association:failure:dreyeck/catalog:presentation-controller-not-materialized:covered-by:fresh-presentation-controller-present")
                          (:failure-id
                                       "failure:dreyeck/catalog:presentation-controller-mutates-catalog-sequence"
                                       :failure-label
                                       "Catalog presentation controller mutates catalog sequence"
                                       :condition
                                       :catalog-sequence-changed-by-presentation-controller
                                       :test-case-id
                                       "test-case:dreyeck/catalog:fresh-presentation-controller-preserves-catalog"
                                       :test-case-label
                                       "Fresh presentation controller preserves catalog sequence"
                                       :evaluation
                                       "(LET* ((CATALOG HYPERBOOK:*CATALOG*)
       (BEFORE (COPY-LIST (HYPERBOOK:HYPERBOOKS-OF CATALOG))))
  (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE CATALOG NIL)
  (ASSERT (EQUAL BEFORE (HYPERBOOK:HYPERBOOKS-OF CATALOG))))"
                                       :verification
                                       (:status :present :verification
                                                :fresh-process)
                                       :may-fail-as-id
                                       "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:mutates-catalog-sequence"
                                       :covered-by-id
                                       "association:failure:dreyeck/catalog:presentation-controller-mutates-catalog-sequence:covered-by:fresh-presentation-controller-preserves-catalog")
                          (:failure-id
                                       "failure:dreyeck/catalog:presentation-controller-misrepresents-workspace-topic"
                                       :failure-label
                                       "Catalog presentation controller misrepresents workspace topic"
                                       :condition
                                       :workspace-topic-id-label-or-state-not-preserved
                                       :test-case-id
                                       "test-case:dreyeck/catalog:fresh-presentation-controller-presents-workspace"
                                       :test-case-label
                                       "Fresh presentation controller presents workspace topic"
                                       :evaluation "(LET* ((TOPIC
        (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-TOPIC :ID \"workspace:test\"
                       :TYPE :WORKSPACE :LABEL \"Workspace Test\"))
       (STATE
        (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE HYPERBOOK:*CATALOG*
                                                    (LIST TOPIC)))
       (ENTRY (FIRST (GETF STATE :WORKSPACES))))
  (ASSERT
   (EQUAL ENTRY
          '(:ID \"workspace:test\" :LABEL \"Workspace Test\" :STATE :DISCOVERED)))
  T)"
                                       :verification
                                       (:status :present :verification
                                                :fresh-process)
                                       :may-fail-as-id
                                       "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:misrepresents-workspace-topic"
                                       :covered-by-id
                                       "association:failure:dreyeck/catalog:presentation-controller-misrepresents-workspace-topic:covered-by:fresh-presentation-controller-presents-workspace")
                          (:failure-id
                                       "failure:dreyeck/catalog:presentation-controller-misrepresents-hyperbook"
                                       :failure-label
                                       "Catalog presentation controller misrepresents HyperBook"
                                       :condition
                                       :hyperbook-id-title-or-state-not-presented-correctly
                                       :test-case-id
                                       "test-case:dreyeck/catalog:fresh-presentation-controller-presents-hyperbook"
                                       :test-case-label
                                       "Fresh presentation controller presents HyperBook"
                                       :evaluation "(LET* ((SUBJECT
        (FIND \"hyperdoc\" (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :KEY
              #'HYPERBOOK:ID-OF :TEST #'STRING=))
       (STATE
        (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE HYPERBOOK:*CATALOG* NIL))
       (ENTRY
        (AND SUBJECT
             (FIND (HYPERBOOK:ID-OF SUBJECT) (GETF STATE :HYPERBOOKS) :KEY
                   (LAMBDA (ITEM) (GETF ITEM :ID)) :TEST #'EQUAL))))
  (ASSERT SUBJECT)
  (ASSERT ENTRY)
  (ASSERT (EQUAL (HYPERBOOK:ID-OF SUBJECT) (GETF ENTRY :ID)))
  (ASSERT (EQUAL (HYPERBOOK:TITLE-OF SUBJECT) (GETF ENTRY :LABEL)))
  (ASSERT (EQ :MATERIALIZED (GETF ENTRY :STATE)))
  T)"
                                       :verification
                                       (:status :present :verification
                                                :fresh-process)
                                       :may-fail-as-id
                                       "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:misrepresents-hyperbook"
                                       :covered-by-id
                                       "association:failure:dreyeck/catalog:presentation-controller-misrepresents-hyperbook:covered-by:fresh-presentation-controller-presents-hyperbook")
                          (:failure-id
                                       "failure:dreyeck/catalog:presentation-controller-misorders-hyperbooks"
                                       :failure-label
                                       "Catalog presentation controller misorders HyperBooks"
                                       :condition
                                       :hyperbooks-not-sorted-by-title
                                       :test-case-id
                                       "test-case:dreyeck/catalog:fresh-presentation-controller-sorts-hyperbooks"
                                       :test-case-label
                                       "Fresh presentation controller sorts HyperBooks"
                                       :evaluation "(LET* ((EXPECTED
        (SORT
         (MAPCAR #'HYPERBOOK:TITLE-OF
                 (COPY-LIST (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*)))
         #'STRING<))
       (PRESENTED
        (MAPCAR (LAMBDA (ENTRY) (GETF ENTRY :LABEL))
                (GETF
                 (DREYECK/CATALOG:CATALOG-PRESENTATION-STATE
                  HYPERBOOK:*CATALOG* NIL)
                 :HYPERBOOKS))))
  (ASSERT (EQUAL EXPECTED PRESENTED))
  T)"
                                       :verification
                                       (:status :present :verification
                                                :fresh-process)
                                       :may-fail-as-id
                                       "association:edge:dreyeck/catalog:presentation-controller:may-fail-as:misorders-hyperbooks"
                                       :covered-by-id
                                       "association:failure:dreyeck/catalog:presentation-controller-misorders-hyperbooks:covered-by:fresh-presentation-controller-sorts-hyperbooks")))))

(defun controller-source-coverage-specification ()
  (copy-tree
   '(:path-id "path:dreyeck/catalog:controller-source" :path-label
     "Dreyeck catalog controller source path" :cases
     ((:step 1 :traverses-id
       "association:path:dreyeck/catalog:controller-source:step-1" :edge-id
       "edge:association:asdf-system:dreyeck/catalog:component:asdf-component:dreyeck/catalog:catalog-presentation-state"
       :failure-id "failure:dreyeck/catalog:component-missing" :failure-label
       "dreyeck/catalog component missing" :condition :component-children-nil
       :test-case-id "test-case:dreyeck/catalog:fresh-component-present"
       :test-case-label "Fresh catalog component is present" :evaluation
       "(let* ((system (asdf/system-registry:registered-system \"dreyeck/catalog\")) (children (asdf:component-children system))) (assert (not (null children))))"
       :may-fail-as-id
       "association:edge:dreyeck/catalog:component:may-fail-as:component-missing"
       :covered-by-id
       "association:failure:dreyeck/catalog:component-missing:covered-by:fresh-component-present"
       :verification (:status :present :verification :fresh-process))
      (:step 2 :traverses-id
       "association:path:dreyeck/catalog:controller-source:step-2" :edge-id
       "edge:association:asdf-component:dreyeck/catalog:catalog-presentation-state:source:function:dreyeck/catalog:catalog-presentation-state"
       :failure-id "failure:dreyeck/catalog:component-source-wrong"
       :failure-label "Catalog component source missing or wrong" :condition
       :component-pathname-missing-or-wrong :test-case-id
       "test-case:dreyeck/catalog:fresh-component-source" :test-case-label
       "Fresh catalog component has expected source" :evaluation
       "(LET* ((SYSTEM (ASDF/SYSTEM-REGISTRY:REGISTERED-SYSTEM \"dreyeck/catalog\"))
       (COMPONENT (FIRST (ASDF/COMPONENT:COMPONENT-CHILDREN SYSTEM)))
       (EXPECTED
        (MERGE-PATHNAMES #P\"dreyeck/src/catalog.lisp\"
                         (ASDF/SYSTEM:SYSTEM-SOURCE-DIRECTORY SYSTEM))))
  (ASSERT
   (EQUAL (TRUENAME EXPECTED)
          (TRUENAME (ASDF/COMPONENT:COMPONENT-PATHNAME COMPONENT)))))"
       :may-fail-as-id
       "association:edge:dreyeck/catalog:source:may-fail-as:source-wrong"
       :covered-by-id
       "association:failure:dreyeck/catalog:component-source-wrong:covered-by:fresh-component-source"
       :verification (:status :present :verification :fresh-process))))))

(defun fresh-catalog-evaluations nil
       (append
               (list "(require :asdf)"
                     (format nil "(asdf:load-asd #P~S)"
                             (namestring (dreyeck-asd-pathname))))
               (mapcar
                       (lambda (common-lisp-user::entry)
                               (getf common-lisp-user::entry :evaluation))
                       (getf (controller-source-coverage-specification)
                             :cases))
               (list "(asdf:load-system \"hyperdoc\")"
                     "(asdf:load-system \"hyperbook/server\")"
                     "(assert (null (find-package \"DREYECK/UPSTREAM-INTAKE\")))"
                     "(assert (null (find-package \"DREYECK/FEDWIKI-SOURCE-RELATIONS\")))"
                     "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/upstream-intake\"))))"
                     "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/fedwiki-source-relations\"))))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/wiki-link\")))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/upstream-intake\")))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/fedwiki-source-relations\")))"
                     "(assert (null (find-package \"DREYECK/LISP-IMAGE\")))"
                     "(assert (not (asdf:component-loaded-p (asdf:find-system \"dreyeck/lisp-image\"))))"
                     "(assert (null (hyperbook:find-hyperbook \"dreyeck/lisp-image\")))"
                     "(asdf:load-system \"dreyeck/catalog\")")
               (mapcar
                       (lambda (common-lisp-user::entry)
                               (getf common-lisp-user::entry :evaluation))
                       (presentation-controller-coverage-cases))
               (list
                     "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/lisp-image\")))"
                     "(assert (find-package \"DREYECK/LISP-IMAGE\"))"
                     "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/upstream-intake\")))"
                     "(assert (asdf:component-loaded-p (asdf:find-system \"dreyeck/fedwiki-source-relations\")))"
                     "(assert (find-package \"DREYECK/UPSTREAM-INTAKE\"))"
                     "(assert (find-package \"DREYECK/FEDWIKI-SOURCE-RELATIONS\"))"
                     "(let* ((wiki (hyperbook:find-hyperbook \"dreyeck/wiki-link\" :signal-error? t)) (intake (hyperbook:find-hyperbook \"dreyeck/upstream-intake\" :signal-error? t)) (relations (hyperbook:find-hyperbook \"dreyeck/fedwiki-source-relations\" :signal-error? t)) (members (hyperbook:hyperbooks-of hyperbook:*catalog*))) (hyperdoc::ensure-pages-loaded wiki) (hyperdoc::ensure-pages-loaded intake) (hyperdoc::ensure-pages-loaded relations) (assert (string= \"Wiki-link title and slug lookup contracts\" (hyperbook:main-page-id-of wiki))) (assert (hyperbook:find-page wiki \"Wiki-link title and slug lookup contracts\" :signal-error? t)) (assert (string= \"Upstream Intake as a Read-Only Observation\" (hyperbook:main-page-id-of intake))) (assert (= 4 (hash-table-count (hyperdoc:pages-of intake)))) (dolist (page-id '(\"Upstream Intake as a Read-Only Observation\" \"Observing an Upstream Commit\" \"An Upstream Supersession Hypothesis\" \"Historical ASDF Dependencies as a Topicmap\")) (assert (hyperbook:find-page intake page-id :signal-error? t))) (assert (= 1 (count \"dreyeck/fedwiki-source-relations\" members :key #'hyperbook:id-of :test #'string=))) (assert (string= \"FedWiki Component Order and Source Relations\" (hyperbook:title-of relations))) (assert (string= \"FedWiki Component Order and Source Relations\" (hyperbook:main-page-id-of relations))) (assert (= 1 (hash-table-count (hyperdoc:pages-of relations)))) (assert (hyperbook:find-page relations \"FedWiki Component Order and Source Relations\" :signal-error? t)) (format t \"FRESH-DREYECK-CATALOG=~S~%\" (mapcar (lambda (book) (list (hyperbook:id-of book) (hyperbook:title-of book))) members)))"
                     "(let* ((wiki (hyperbook:find-hyperbook \"dreyeck/wiki-link\" :signal-error? t)) (lisp-image (hyperbook:find-hyperbook \"dreyeck/lisp-image\" :signal-error? t)) (members (hyperbook:hyperbooks-of hyperbook:*catalog*))) (hyperdoc::ensure-pages-loaded wiki) (hyperdoc::ensure-pages-loaded lisp-image) (assert (= 1 (count \"dreyeck/lisp-image\" members :key #'hyperbook:id-of :test #'string=))) (assert (string= \"dreyeck.ch Lisp image\" (hyperbook:title-of lisp-image))) (assert (string= \"Lisp image HyperBook refactor\" (hyperbook:main-page-id-of lisp-image))) (assert (= 1 (hash-table-count (hyperdoc:pages-of lisp-image)))) (assert (hyperbook:find-page lisp-image \"Lisp image HyperBook refactor\" :signal-error? t)) (assert (null (hyperbook:find-page wiki \"Lisp image HyperBook refactor\" :signal-error? nil))))"
                     "(let ((git-intake (dreyeck/upstream-intake:make-hyperdoc-host-not-found-intake)) (component-intake (dreyeck/upstream-intake:make-hyperspec-component-intake))) (assert (find \"Upstream Intake\" (html-inspector-views:all-views git-intake) :key #'html-inspector-views:view-title :test #'string=)) (assert (find \"Upstream Intake\" (html-inspector-views:all-views component-intake) :key #'html-inspector-views:view-title :test #'string=)))"
                     "(format t \"Fresh Dreyeck catalog startup tests passed.~%\")")))

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
