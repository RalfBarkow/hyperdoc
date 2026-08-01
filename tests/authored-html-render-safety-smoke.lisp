;;;; Smoke tests for safe authored HTML rendering
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-AUTHORED-HTML-RENDER-SAFETY-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *authored-html-render-smoke-log* nil)

(defun clear-authored-html-render-smoke-log ()
  (setf *authored-html-render-smoke-log* nil))

(defun record-authored-html-render-smoke (label)
  (push label *authored-html-render-smoke-log*)
  label)

(defun authored-html-render-smoke-log ()
  (reverse *authored-html-render-smoke-log*))

(defun authored-html-render-safety-tempdir ()
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "authored-html-render-safety-~D-~A/"
            (get-universal-time)
            (gensym "RUN"))
    (uiop:temporary-directory))))

(defclass explosive-render-hyperbook (hyperbook:hyperbook) ())

(defmethod hyperbook:find-page ((book explosive-render-hyperbook) page-id
                                &key signal-error?)
  (declare (ignore book page-id signal-error?))
  (error "Explosive render target should not crash the authored page render path."))

(defun make-authored-html-render-safety-hyperdoc (directory id)
  (make-instance 'hyperdoc::hyperdoc
                 :id id
                 :asdf-system-name :hyperdoc
                 :directory (uiop:ensure-directory-pathname directory)
                 :writable t
                 :title "Authored HTML render safety smoke"
                 :main-page-id nil
                 :code-pages #()
                 :tools nil
                 :data nil
                 :text-pages (make-hash-table :test #'equal)
                 :pages (make-hash-table :test #'equal)))

(defun write-authored-html-render-safety-page
    (directory hyperdoc-id explosive-hyperbook-id)
  (let ((path (merge-pathnames "authored-render-safety.html" directory)))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (format stream
              "<h1>Authored HTML render safety smoke</h1>~%~%<in-package>hyperdoc/tests</in-package>~%~%<p><a expr=\"(record-authored-html-render-smoke &quot;expr-link&quot;)\"><tt>Deferred expr link</tt></a></p>~%~%<p><value-of>(record-authored-html-render-smoke &quot;value-of&quot;)</value-of></p>~%~%<p><a hyperbook=\"~A\" page=\"boom\"><tt>Explosive page link</tt></a></p>~%~%<p><a href=\"file:///tmp/hyperdoc-render-smoke\">Local file</a></p>~%~%<p><a href=\"http://example.test/plain\">HTTP</a> <a href=\"https://example.test/secure\">HTTPS</a> <a href=\"relative-target.html\">Relative</a> <a href=\"#fragment-target\">Fragment</a> <a href=\"mailto:author@example.test\">Mail</a></p>~%~%<p><a hyperbook=\"~A\" page=\"Authored HTML render safety smoke\">Internal page</a></p>~%"
              explosive-hyperbook-id
              hyperdoc-id))
    path))

(defun smoke-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun with-authored-html-render-safety-surface (thunk)
  (let* ((directory (authored-html-render-safety-tempdir))
         (hyperdoc-id (format nil "render-safety-smoke-~A" (gensym "HD")))
         (explosive-id (format nil "render-safety-explosive-~A" (gensym "HB")))
         (book (make-authored-html-render-safety-hyperdoc directory hyperdoc-id))
         (explosive (make-instance 'explosive-render-hyperbook :id explosive-id))
         (original-hyperbooks (copy-list (hyperbook::hyperbooks-of hyperbook:*catalog*))))
    (write-authored-html-render-safety-page directory hyperdoc-id explosive-id)
    (unwind-protect
         (progn
           (hyperbook:register book)
           (hyperbook:register explosive)
           (funcall thunk
                    book
                    explosive-id
                    (hyperbook:find-page book
                                         "Authored HTML render safety smoke"
                                         :signal-error? t)))
      (setf (hyperbook::hyperbooks-of hyperbook:*catalog*) original-hyperbooks)
      (ignore-errors
        (uiop:delete-directory-tree directory :validate t :if-does-not-exist :ignore)))))

(defun authored-expression-smoke-reference (expression &key (label expression))
  (make-instance 'hyperdoc::authored-expression-reference
                 :kind :expr-link
                 :expression expression
                 :package-name "HYPERDOC/TESTS"
                 :label label
                 :source-tag "a"))

(defun rendered-anchor-hrefs (html)
  (let ((dom (plump:parse html)))
    (loop for anchor across (lquery:$ dom "a[href]")
          collect (plump:attribute anchor "href"))))

(defun rendered-hyperbook-reference-with-text-p (html text)
  (let ((dom (plump:parse html)))
    (loop for reference across (lquery:$ dom ".hyperbook-reference")
          thereis (search text (plump:text reference) :test #'char=))))

(defun assert-standard-link-schemes-preserved (html context)
  (let ((hrefs (rendered-anchor-hrefs html)))
    (dolist (href '("http://example.test/plain"
                    "https://example.test/secure"
                    "relative-target.html"
                    "#fragment-target"
                    "mailto:author@example.test"))
      (assert-true (member href hrefs :test #'string=)
                   (format nil "~A must preserve ~A as a link" context href)))
    (assert-true (not (find-if #'hyperbook::local-file-url-p hrefs))
                 (format nil "~A must not render a file: URL as an anchor" context))))

(defun run-authored-html-passive-render-smoke-test ()
  (clear-authored-html-render-smoke-log)
  (with-authored-html-render-safety-surface
      (lambda (book explosive-id page)
        (declare (ignore book explosive-id))
        (let* ((views (load-inspector-views-for-object page))
               (content-view (smoke-find-view-by-title views "Content"))
               (links-view (smoke-find-view-by-title views "Links"))
               (html (and content-view
                          (html-inspector-views:view-html content-view)))
               (links-html (and links-view
                                (html-inspector-views:view-html links-view)))
               (lookup-issues nil)
               (lookup-issues-condition nil))
          (assert-true content-view
                       "Authored HTML smoke page must expose a Content view")
          (assert-equal nil
                        (authored-html-render-smoke-log)
                        "Opening the page and materializing its views must not execute authored expressions")
          (assert-true (search "data-hyperdoc-deferred-expression" html :test #'char=)
                       "Content render must expose deferred expression metadata instead of eager execution")
          (assert-true (search "hyperdoc-computed-value" html :test #'char=)
                       "Immediate computed-value tags must render as deferred references")
          (assert-true (search "hyperbook-error" html :test #'char=)
                       "Unexpected page-link failures must become bounded issue refs instead of crashing content")
          (assert-true (hyperbook::local-file-url-p
                        "FiLe:///tmp/hyperdoc-render-smoke")
                       "The local-file predicate must classify only the file: scheme case-insensitively")
          (dolist (href '("http://example.test/plain"
                          "https://example.test/secure"
                          "relative-target.html"
                          "#fragment-target"
                          "mailto:author@example.test"))
            (assert-true (not (hyperbook::local-file-url-p href))
                         (format nil "The local-file predicate must not classify ~A as local" href)))
          (assert-true (search "hyperbook-local-file-path" html :test #'char=)
                       "Content rendering must retain a local file path as non-clickable text")
          (assert-standard-link-schemes-preserved html "Content rendering")
          (assert-true
           (rendered-hyperbook-reference-with-text-p html "Internal page")
           "Content rendering must preserve an internal page as a HyperBook reference")
          (assert-true links-view
                       "Authored HTML smoke page must expose a Links view")
          (assert-true (search "hyperbook-local-file-path" links-html :test #'char=)
                       "Links view must retain a local file path as non-clickable text")
          (assert-standard-link-schemes-preserved links-html "Links view")
          (setf lookup-issues
                (handler-case
                    (hyperbook:lookup-issues-of page)
                  (error (condition)
                    (setf lookup-issues-condition condition)
                    nil)))
          (assert-equal nil
                        lookup-issues-condition
                        "Lookup issue discovery must stay bounded under the non-executing render contract")
          (assert-true (listp lookup-issues)
                       "Lookup issue discovery must still return a list or NIL")))))

(defun run-authored-html-explicit-evaluation-smoke-test ()
  (clear-authored-html-render-smoke-log)
  (let* ((reference
          (authored-expression-smoke-reference
           "(record-authored-html-render-smoke \"explicit-eval\")"
           :label "explicit-eval"))
         (result (html-inspector-views:eval-thunk reference)))
    (assert-equal "explicit-eval"
                  result
                  "Explicit deferred evaluation must still run when the user requests it")
    (assert-equal '("explicit-eval")
                  (authored-html-render-smoke-log)
                  "Deferred evaluation must be the boundary that triggers the expression")))

(defun run-authored-html-explicit-failure-smoke-test ()
  (let* ((reference
          (authored-expression-smoke-reference
           "(error \"authored-eval-smoke-failure\")"
           :label "failing-reference"))
         (result (html-inspector-views:eval-thunk reference)))
    (assert-true (typep result 'hyperdoc::authored-expression-evaluation-issue)
                 "Deferred authored-expression failure must return a bounded issue object")
    (assert-true (search "authored-eval-smoke-failure"
                         (princ-to-string
                          (hyperdoc::authored-expression-issue-condition-of result))
                         :test #'char=
                         :from-end nil)
                 "Issue object must preserve the underlying evaluation failure")))

(defun run-authored-html-render-safety-smoke-tests ()
  (run-authored-html-passive-render-smoke-test)
  (run-authored-html-explicit-evaluation-smoke-test)
  (run-authored-html-explicit-failure-smoke-test)
  (format t "~&Authored HTML render safety smoke tests passed.~%")
  t)
