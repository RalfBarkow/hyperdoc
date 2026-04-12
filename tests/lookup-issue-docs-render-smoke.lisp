;;;; Smoke tests for the rewritten lookup-issue documentation pages
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-LOOKUP-ISSUE-DOCS-RENDER-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *lookup-issue-doc-render-smoke-specs*
  '((:title "Declarative chunk wiring for page-lookup issues and first real Topics chunk"
     :headings ("Current layering"
                "Current page/topic diagnosis model"
                "Current issue-to-chunk flow")
     :content-substrings ("hyperbook-explorer/lookup-failures.lisp"
                          "topic-page-availability-chunk"
                          "repair-lookup-issue-via-chunks")
     :source-substrings ("&lt;h2&gt;Current layering&lt;/h2&gt;"
                         "&lt;h2&gt;Current issue-to-chunk flow&lt;/h2&gt;"))
    (:title "Implement function-lookup-issue from the page-lookup-issue precedent"
     :headings ("Current layering"
                "Current runtime truth"
                "Current correction path")
     :content-substrings ("hyperbook-explorer/lookup-failures.lisp"
                          "function-lookup-correction"
                          "fboundp")
     :source-substrings ("&lt;h2&gt;Current runtime truth&lt;/h2&gt;"
                         "&lt;h2&gt;Current correction path&lt;/h2&gt;"))
    (:title "Repair missing HyperDoc topic from lookup issue"
     :headings ("Current architecture boundary"
                "Current diagnosis logic"
                "Repair procedure")
     :content-substrings ("hyperdoc/page-lookup-chunks.lisp"
                          "repair-lookup-issue-via-chunks"
                          "function-lookup-issue")
     :source-substrings ("&lt;h2&gt;Current architecture boundary&lt;/h2&gt;"
                         "&lt;h2&gt;Repair procedure&lt;/h2&gt;"))))

(defun lookup-issue-docs-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun lookup-issue-docs-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun lookup-issue-docs-h2-texts (page)
  (mapcar #'plump:text
          (plump:get-elements-by-tag-name (hyperbook:dom-of page) "h2")))

(defun lookup-issue-docs-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun lookup-issue-docs-assert-contains-all (haystack label needles)
  (dolist (needle needles)
    (lookup-issue-docs-assert-true
     (search needle haystack :test #'char=)
     (format nil "~A must contain ~S" label needle))))

(defun run-lookup-issue-doc-page-render-smoke-test
    (title headings content-substrings source-substrings)
  (let* ((page (hyperbook:find-page hyperdoc::*hyperdoc* title :signal-error? t))
         (views (lookup-issue-docs-load-inspector-views-for-object page))
         (content-view (lookup-issue-docs-find-view-by-title views "Content"))
         (content-html (and content-view
                            (html-inspector-views:view-html content-view)))
         (source-view (lookup-issue-docs-find-view-by-title views "Source"))
         (source-html (and source-view
                           (html-inspector-views:view-html source-view)))
         (headings-on-page (lookup-issue-docs-h2-texts page))
         (lookup-issues nil)
         (lookup-issues-condition nil))
    (lookup-issue-docs-assert-true
     (typep page 'hyperdoc::html-page)
     (format nil "~A must materialize as a HyperDoc HTML page" title))
    (lookup-issue-docs-assert-true
     content-view
     (format nil "~A must expose a Content view" title))
    (lookup-issue-docs-assert-true
     source-view
     (format nil "~A must expose a Source view" title))
    (lookup-issue-docs-assert-contains-all
     content-html
     (format nil "~A Content render" title)
     (append '("hyperbook-page")
             content-substrings))
    (lookup-issue-docs-assert-contains-all
     source-html
     (format nil "~A Source render" title)
     source-substrings)
    (dolist (heading headings)
      (lookup-issue-docs-assert-true
       (member heading headings-on-page :test #'string=)
       (format nil "~A must keep heading ~S" title heading)))
    (setf lookup-issues
          (handler-case
              (hyperbook:lookup-issues-of page)
            (error (condition)
              (setf lookup-issues-condition condition)
              nil)))
    (lookup-issue-docs-assert-true
     (null lookup-issues-condition)
     (format nil "~A lookup-issue discovery must not signal" title))
    (lookup-issue-docs-assert-true
     (listp lookup-issues)
     (format nil "~A lookup-issue discovery must return a list" title))
    (lookup-issue-docs-assert-true
     (null lookup-issues)
     (format nil "~A must not introduce page-level lookup issues" title))))

(defun run-lookup-issue-docs-render-smoke-tests ()
  (dolist (spec *lookup-issue-doc-render-smoke-specs*)
    (run-lookup-issue-doc-page-render-smoke-test
     (getf spec :title)
     (getf spec :headings)
     (getf spec :content-substrings)
     (getf spec :source-substrings)))
  (format t "~&Lookup-issue docs render smoke tests passed.~%")
  t)
