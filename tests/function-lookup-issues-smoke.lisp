;;;; Smoke tests for bounded function-lookup issues
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-FUNCTION-LOOKUP-ISSUES-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun package-qualified-symbol-name (symbol &key internal?)
  (let ((package (symbol-package symbol)))
    (assert-true package
                 "Focused Lisp Functions smoke must use an interned symbol")
    (format nil "~A~A~A"
            (package-name package)
            (if internal? "::" ":")
            (symbol-name symbol))))

(defun find-lisp-function-page-by-id (pages page-id)
  (find page-id pages
        :key #'hyperbook:id-of
        :test #'string=))

(defun run-fbound-generic-function-page-smoke-test ()
  (let* ((symbol 'hyperbook:find-page)
         (page-id (package-qualified-symbol-name symbol))
         (page (hyperbook:find-page hyperbook::*lisp-functions*
                                    page-id
                                    :signal-error? t)))
    (assert-true (fboundp symbol)
                 "Focused Lisp Functions smoke must use an actually fbound generic function")
    (assert-true (typep page 'hyperbook::lisp-function-page)
                 "Opening a known fbound exported function must yield a real lisp-function-page.")
    (assert-equal page-id
                  (hyperbook:id-of page)
                  "The Lisp Functions page id must remain the package-qualified function name.")
    (assert-true (typep (hyperbook::function-of page) 'generic-function)
                 "The Lisp Functions hyperbook must open generic functions as real function pages.")
    (assert-true (eq (hyperbook::function-of page)
                     (fdefinition symbol))
                 "The Lisp Functions page must carry the live function object from the running image.")))

(defun run-package-qualified-internal-function-page-smoke-test ()
  (let* ((symbol 'hyperbook::read-symbol)
         (page-id (package-qualified-symbol-name symbol :internal? t))
         (page (hyperbook:find-page hyperbook::*lisp-functions*
                                    page-id
                                    :signal-error? t)))
    (assert-true (fboundp symbol)
                 "Focused Lisp Functions smoke must use an actually fbound internal helper")
    (assert-true (typep page 'hyperbook::lisp-function-page)
                 "Opening a known fbound internal function must yield a real lisp-function-page.")
    (assert-equal page-id
                  (hyperbook:id-of page)
                  "Package-qualified internal names must resolve through the Lisp Functions hyperbook.")
    (assert-true (typep (hyperbook::function-of page) 'function)
                 "The opened internal Lisp Functions page must hold a function object.")
    (assert-true (eq (hyperbook::function-of page)
                     (fdefinition symbol))
                 "The internal Lisp Functions page must carry the live function object from the running image.")))

(defun run-fbound-macro-function-page-smoke-test ()
  (let* ((symbol 'cl:when)
         (page-id (package-qualified-symbol-name symbol))
         (page (hyperbook:find-page hyperbook::*lisp-functions*
                                    page-id
                                    :signal-error? t)))
    (assert-true (fboundp symbol)
                 "Focused Lisp Functions smoke must use an actually fbound macro name")
    (assert-true (typep page 'hyperbook::lisp-function-page)
                 "Opening a known fbound macro name must still yield a real lisp-function-page.")
    (assert-equal page-id
                  (hyperbook:id-of page)
                  "Package-qualified macro names must resolve through the Lisp Functions hyperbook.")
    (assert-true (typep (hyperbook::function-of page) 'function)
                 "The Lisp Functions hyperbook must open other fbound callable names as function pages.")
    (assert-true (eq (hyperbook::function-of page)
                     (fdefinition symbol))
                 "Macro lookup must carry the live fdefinition object from the running image.")))

(defun run-loaded-functions-inventory-smoke-test ()
  (let* ((generic-id (package-qualified-symbol-name 'hyperbook:find-page))
         (internal-id (package-qualified-symbol-name 'hyperbook::read-symbol
                                                    :internal? t))
         (macro-id (package-qualified-symbol-name 'cl:when))
         (pages (hyperbook::collect-lisp-function-pages
                 hyperbook::*lisp-functions*)))
    (assert-true pages
                 "The Lisp Functions hyperbook must expose a non-empty inventory of loaded function pages.")
    (dolist (page-id (list generic-id internal-id macro-id))
      (let ((page (find-lisp-function-page-by-id pages page-id)))
        (assert-true page
                     (format nil "Loaded function inventory must contain ~A." page-id))
        (assert-true (typep page 'hyperbook::lisp-function-page)
                     (format nil "Loaded function inventory entry ~A must be a real lisp-function-page."
                             page-id))))))

(defun run-loaded-functions-view-smoke-test ()
  (let* ((generic-id (package-qualified-symbol-name 'hyperbook:find-page))
         (internal-id (package-qualified-symbol-name 'hyperbook::read-symbol
                                                    :internal? t))
         (macro-id (package-qualified-symbol-name 'cl:when))
         (views (load-inspector-views-for-object hyperbook::*lisp-functions*))
         (overview-view (smoke-find-view-by-title views "Overview"))
         (loaded-view (smoke-find-view-by-title views "Loaded functions"))
         (overview-html (and overview-view
                             (html-inspector-views:view-html overview-view)))
         (loaded-html (and loaded-view
                           (html-inspector-views:view-html loaded-view))))
    (assert-true overview-view
                 "The Lisp Functions hyperbook must still expose an Overview view.")
    (assert-true loaded-view
                 "The Lisp Functions hyperbook must expose a browseable Loaded functions view.")
    (assert-true (search "Loaded functions view"
                         overview-html
                         :test #'char-equal)
                 "Overview text must now point users to the browseable Loaded functions view.")
    (dolist (page-id (list generic-id internal-id macro-id))
      (assert-true (search page-id loaded-html :test #'char-equal)
                   (format nil "Loaded functions view must list ~A." page-id)))
    (assert-true (search "class='inspector-inspect'"
                         loaded-html
                         :test #'char-equal)
                 "Loaded functions view must render inspectable navigation rows for the listed function pages.")))

(defun run-raw-function-lookup-issue-smoke-test ()
  (let* ((symbol (intern "FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING" :hyperdoc))
         (page-id (format nil "~A::~A"
                          (package-name (symbol-package symbol))
                          (symbol-name symbol))))
    (assert-true (not (fboundp symbol))
                 "Focused function-lookup smoke must use a symbol that is not fbound")
    (let* ((issue (hyperbook:find-page hyperbook::*lisp-functions*
                                       page-id
                                       :signal-error? t))
           (condition (hyperbook:lookup-issue-underlying-condition-of issue))
           (message (hyperbook:lookup-issue-underlying-message-of issue)))
      (assert-true (typep issue 'hyperbook:function-lookup-issue)
                   "A missing Lisp function page should surface as a primary function-lookup-issue")
      (assert-true (typep condition 'undefined-function)
                   "A function-lookup-issue should preserve the underlying undefined-function condition")
      (assert-true (search "is undefined" message :test #'char-equal)
                   "A function-lookup-issue should preserve the rendered undefined-function message text"))))

(defun write-authored-function-lookup-smoke-page (directory)
  (let ((path (merge-pathnames "authored-function-lookup-issue.html" directory)))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (format stream
              "<h1>Authored function lookup issue smoke</h1>~%~%<in-package>hyperdoc/tests</in-package>~%~%<p><source-of-function>FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING</source-of-function></p>~%"))
    path))

(defun with-authored-function-lookup-surface (thunk)
  (let* ((directory (authored-html-render-safety-tempdir))
         (hyperdoc-id (format nil "function-lookup-smoke-~A" (gensym "HD")))
         (book (make-authored-html-render-safety-hyperdoc directory hyperdoc-id))
         (original-hyperbooks (copy-list (hyperbook::hyperbooks-of hyperbook:*catalog*))))
    (write-authored-function-lookup-smoke-page directory)
    (unwind-protect
         (progn
           (hyperbook:register book)
           (funcall thunk
                    book
                    (hyperbook:find-page book
                                         "Authored function lookup issue smoke"
                                         :signal-error? t)))
      (setf (hyperbook::hyperbooks-of hyperbook:*catalog*) original-hyperbooks)
      (ignore-errors
        (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore)))))

(defun make-authored-source-of-function-smoke-reference (page)
  (let ((hyperbook::*current-page* page)
        (hyperdoc::*current-package* (find-package "HYPERDOC/TESTS")))
    (hyperdoc::make-authored-expression-reference
     :kind :source-of-function
     :expression "(function FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING)"
     :raw-source "FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING"
     :label "FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING"
     :source-tag "source-of-function")))

(defun with-temporary-symbol-function (symbol thunk)
  (let ((had-definition (fboundp symbol))
        (original-function (and (fboundp symbol)
                                (symbol-function symbol))))
    (unwind-protect
         (progn
           (setf (symbol-function symbol)
                 (lambda (&rest args)
                   (declare (ignore args))
                   :function-lookup-issue-smoke))
           (funcall thunk))
      (cond
        (had-definition
         (setf (symbol-function symbol) original-function))
        ((fboundp symbol)
         (fmakunbound symbol))))))

(defun run-authored-function-lookup-issue-smoke-test ()
  (let* ((symbol (intern "FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING" :hyperdoc/tests))
         (expected-page-id (format nil "~A::~A"
                                   (package-name (symbol-package symbol))
                                   (symbol-name symbol))))
    (assert-true (not (fboundp symbol))
                 "Authored function-lookup smoke must use a symbol that is not fbound")
    (with-authored-function-lookup-surface
     (lambda (book page)
       (declare (ignore book))
      (let* ((page-id (hyperbook:id-of page))
              (views (load-inspector-views-for-object page))
              (content-view (smoke-find-view-by-title views "Content"))
              (content-html (and content-view
                                 (html-inspector-views:view-html content-view)))
              (reference (make-authored-source-of-function-smoke-reference page))
              (issue (html-inspector-views:eval-thunk reference))
              (condition (hyperbook:lookup-issue-underlying-condition-of issue))
              (message (hyperbook:lookup-issue-underlying-message-of issue))
              (details (hyperbook:lookup-issue-details-of issue))
              (repair-thunk (hyperbook::lookup-issue-repair-thunk-of issue))
              (repair-description
                (hyperbook:lookup-issue-repair-description-of issue))
              (missing-correction (funcall repair-thunk))
              (issue-views (load-inspector-views-for-object issue))
              (overview-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title issue-views "Overview")))
              (details-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title issue-views "Details")))
              (repair-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title issue-views "Repair")))
              (condition-html
                (html-inspector-views:view-html
                 (smoke-find-view-by-title issue-views "Condition"))))
         (assert-true content-view
                      "Authored function lookup smoke page must expose a Content view")
         (assert-true (search "FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING"
                              content-html :test #'char-equal)
                      "Content render must still expose the missing function label when inline source transclusion cannot resolve")
         (assert-equal nil
                       (search "data-hyperdoc-deferred-expression"
                               content-html :test #'char-equal)
                       "Content render must no longer preserve source-of-function as a deferred authored-expression reference")
         (assert-equal nil
                       (search "data-hyperdoc-expression-kind"
                               content-html :test #'char-equal)
                       "Inline source-of-function rendering must not leave deferred authored-expression metadata in page content")
         (assert-true (typep issue 'hyperbook:function-lookup-issue)
                      "Evaluating a broken authored source-of-function reference must yield a primary function-lookup-issue")
         (assert-true (typep condition 'undefined-function)
                      "Authored source-of-function lookup must preserve the underlying undefined-function condition")
         (assert-true (search "is undefined" message :test #'char-equal)
                      "Authored source-of-function lookup must preserve the rendered undefined-function message text")
         (assert-equal page-id
                       (hyperbook:lookup-issue-source-page-id-of issue)
                       "Authored source-of-function lookup must preserve source page id provenance")
         (assert-equal "Authored function lookup issue smoke"
                       (hyperbook:lookup-issue-source-page-title-of issue)
                       "Authored source-of-function lookup must preserve source page title provenance")
         (assert-equal "FUNCTION-LOOKUP-ISSUE-SMOKE-MISSING"
                       (hyperbook:lookup-issue-link-text-of issue)
                       "Authored source-of-function lookup must preserve label text when available")
         (assert-equal expected-page-id
                       (hyperbook:lookup-issue-expected-page-id-of issue)
                       "Authored source-of-function lookup must preserve the expected Lisp Functions page id")
         (assert-equal :source-of-function
                       (getf details :lookup-stage)
                       "Authored function lookup details must record the authored source-of-function seam")
         (assert-equal :source-of-function
                       (getf details :reference-kind)
                       "Authored function lookup details must preserve reference kind")
         (assert-equal "HYPERDOC/TESTS"
                       (getf details :package-name)
                       "Authored function lookup details must preserve the authored package context")
         (assert-equal symbol
                       (getf details :expected-symbol)
                       "Authored function lookup details must preserve the expected symbol object")
         (assert-equal :needs-runtime-load
                       (hyperbook:lookup-issue-status-of issue)
                       "A missing authored source-of-function must classify as needing runtime load")
         (assert-equal :load-or-reload-definition
                       (hyperbook:lookup-issue-suggested-repair-of issue)
                       "A missing authored source-of-function must suggest load/reload guidance")
         (assert-true (search "Load or reload" repair-description :test #'char-equal)
                      "A missing authored source-of-function must explain the load/reload correction path")
         (assert-equal :missing
                       (getf details :runtime-load-state)
                       "Lookup issue details must expose that the expected symbol is still missing at inspection time")
         (assert-equal nil
                       (getf details :current-fboundp)
                       "Lookup issue details must expose the current missing load state")
         (assert-equal :load-or-reload-definition
                       (getf details :correction-mode)
                       "Lookup issue details must expose the derived correction mode")
         (assert-true (typep missing-correction 'hyperbook::function-lookup-correction)
                      "The repair thunk for a still-missing function must expose a bounded correction object")
         (assert-true (search "Source page id / slug" overview-html :test #'char-equal)
                      "Lookup issue overview must expose source page id for authored function lookups")
         (assert-true (search page-id overview-html :test #'char-equal)
                      "Lookup issue overview must show the authored source page id")
         (assert-true (search "needs runtime load" overview-html :test #'char-equal)
                      "Lookup issue overview must surface the runtime-derived status for missing functions")
         (assert-true (search "load or reload definition" overview-html
                              :test #'char-equal)
                      "Lookup issue overview must surface the runtime-derived suggested repair")
         (assert-true (search "Current runtime load state" overview-html :test #'char-equal)
                      "Lookup issue overview must expose the current runtime load-state row")
         (assert-true (search "Current-state reason" overview-html :test #'char-equal)
                      "Lookup issue overview must expose the current-state reason row")
         (assert-true (search "still not fbound" overview-html :test #'char-equal)
                      "Lookup issue overview must explain why the current state still requires load/reload")
         (assert-true (search "Retry available now" overview-html :test #'char-equal)
                      "Lookup issue overview must expose whether retry is currently available")
         (assert-true (search "source-of-function" details-html :test #'char-equal)
                      "Lookup issue details must expose the authored reference seam")
         (assert-true (search "runtime-load-state" details-html :test #'char-equal)
                      "Lookup issue details must expose runtime load-state evidence")
         (assert-true (search "Inspect load or reload guidance" repair-html
                              :test #'char-equal)
                      "Lookup issue Repair view must expose the bounded guidance path while the symbol is still missing")
         (assert-true (search "Repair path on click" repair-html :test #'char-equal)
                      "Lookup issue Repair view must expose what clicking the repair path will inspect")
         (assert-true (search "inspectable load or reload guidance" repair-html
                              :test #'char-equal)
                      "Lookup issue Repair view must describe the current repair target while the symbol is missing")
         (assert-true (search "preserves the original undefined-function evidence"
                              repair-html :test #'char-equal)
                      "Lookup issue Repair view must point back to preserved provenance and condition evidence")
         (assert-true (search "Preserved condition text" condition-html
                              :test #'char-equal)
                      "Lookup issue Condition view must surface preserved condition text")
         (assert-true (search "is undefined" condition-html :test #'char-equal)
                      "Lookup issue Condition view must include the preserved undefined-function message")
         (with-temporary-symbol-function
             symbol
           (lambda ()
             (let* ((refreshed-details (hyperbook:lookup-issue-details-of issue))
                    (refreshed-issue-views (load-inspector-views-for-object issue))
                    (refreshed-overview-html
                      (html-inspector-views:view-html
                       (smoke-find-view-by-title refreshed-issue-views "Overview")))
                    (refreshed-repair-html
                      (html-inspector-views:view-html
                       (smoke-find-view-by-title refreshed-issue-views "Repair")))
                   (reopen-target
                     (funcall (hyperbook::lookup-issue-repair-thunk-of issue))))
               (assert-equal :fixed
                             (hyperbook:lookup-issue-status-of issue)
                             "Once the expected symbol becomes fboundp, the issue must classify as fixed")
               (assert-equal :reopen-lisp-function-page
                             (hyperbook:lookup-issue-suggested-repair-of issue)
                             "Once the expected symbol becomes fboundp, the suggested repair must become reopen/retry")
               (assert-true
                (search "now fbound" (hyperbook:lookup-issue-repair-description-of issue)
                        :test #'char-equal)
                "Once the expected symbol becomes fboundp, the repair description must explain the retry path")
               (assert-equal :fbound
                             (getf refreshed-details :runtime-load-state)
                             "Lookup issue details must refresh when the expected symbol becomes fboundp")
               (assert-equal t
                             (getf refreshed-details :current-fboundp)
                             "Lookup issue details must expose the refreshed fboundp evidence")
               (assert-true (search "fixed" refreshed-overview-html :test #'char-equal)
                            "Lookup issue overview must refresh to the fixed state after the symbol becomes fboundp")
               (assert-true (search "now fbound" refreshed-overview-html :test #'char-equal)
                            "Lookup issue overview must explain why retry is now available")
               (assert-true (search "Retry Lisp Functions lookup"
                                    refreshed-repair-html :test #'char-equal)
                            "Lookup issue Repair view must expose the retry path once the symbol is available")
               (assert-true (search "real Lisp Functions page"
                                    refreshed-repair-html :test #'char-equal)
                             "Lookup issue Repair view must describe the real page retry target once the symbol is available")
               (assert-true (typep reopen-target 'hyperbook::lisp-function-page)
                            "The repair thunk must reopen the Lisp Functions page once the symbol is available")
               (assert-equal expected-page-id
                             (hyperbook:id-of reopen-target)
                             "The reopened Lisp Functions page must target the expected page id")))))))))

(defun run-authored-source-reference-open-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((page
           (hyperbook:find-page hyperdoc::*hyperdoc*
                                "Graphviz story item upstream assimilation example"
                                :signal-error? t))
         (reference
           (let ((hyperbook::*current-page* page)
                 (hyperdoc::*current-package* (find-package "HYPERDOC")))
             (hyperdoc::make-authored-expression-reference
              :kind :source-of-function
              :expression "(function graphviz-story-item-upstream-assimilation-example)"
              :raw-source "graphviz-story-item-upstream-assimilation-example"
              :label "graphviz-story-item-upstream-assimilation-example"
              :source-tag "source-of-function")))
         (result (html-inspector-views:eval-thunk reference))
         (views (load-inspector-views-for-object result))
         (source-view (smoke-find-view-by-title views "Source code"))
         (source-html (and source-view
                           (html-inspector-views:view-html source-view))))
    (assert-true (typep result 'function)
                 "Deferred source-of-function evaluation must return the underlying function object, not a raw HTML-VIEW")
    (assert-true source-view
                 "Opening the evaluated source-of-function target must expose a Source code view without inspector slot failures")
    (assert-true (search "defexample" source-html :test #'char-equal)
                 "The opened Source code view must render the defexample form")
    (assert-true (search "graphviz-story-item-upstream-assimilation-example"
                         source-html :test #'char-equal)
                 "The opened Source code view must render the requested function name")
    (assert-true (search "Run example" source-html :test #'char-equal)
                 "The opened Source code view must still expose the runnable defexample affordance")))

(defun run-function-lookup-issues-smoke-tests ()
  (run-fbound-generic-function-page-smoke-test)
  (run-package-qualified-internal-function-page-smoke-test)
  (run-fbound-macro-function-page-smoke-test)
  (run-loaded-functions-inventory-smoke-test)
  (run-loaded-functions-view-smoke-test)
  (run-raw-function-lookup-issue-smoke-test)
  (run-authored-function-lookup-issue-smoke-test)
  (run-authored-source-reference-open-smoke-test)
  (format t "~&Function lookup issue smoke tests passed.~%")
  t)
