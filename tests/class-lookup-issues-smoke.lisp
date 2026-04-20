;;;; Smoke tests for browseable Lisp class pages
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-CLASS-LOOKUP-ISSUES-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun find-lisp-class-page-by-id (pages page-id)
  (find page-id pages
        :key #'hyperbook:id-of
        :test #'string=))

(defun run-exported-lisp-class-page-smoke-test ()
  (let* ((symbol 'hyperbook:hyperbook)
         (page-id (hyperbook::package-qualified-symbol-name symbol))
         (page (hyperbook:find-page hyperbook::*lisp-classes*
                                    page-id
                                    :signal-error? t)))
    (assert-true (find-class symbol nil)
                 "Focused Lisp Classes smoke must use a real exported class")
    (assert-true (typep page 'hyperbook::lisp-class-page)
                 "Opening a known exported class must yield a real lisp-class-page.")
    (assert-equal page-id
                  (hyperbook:id-of page)
                  "The Lisp Classes page id must remain the package-qualified class name.")
    (assert-true (eq (hyperbook::class-object-of page)
                     (find-class symbol nil))
                 "The Lisp Classes page must carry the live class object from the running image.")))

(defun run-internal-lisp-class-page-smoke-test ()
  (let* ((symbol 'hyperbook::lisp-class-page)
         (page-id (hyperbook::package-qualified-symbol-name symbol))
         (page (hyperbook:find-page hyperbook::*lisp-classes*
                                    page-id
                                    :signal-error? t)))
    (assert-true (find-class symbol nil)
                 "Focused Lisp Classes smoke must use a real internal class")
    (assert-true (typep page 'hyperbook::lisp-class-page)
                 "Opening a known internal class must yield a real lisp-class-page.")
    (assert-equal page-id
                  (hyperbook:id-of page)
                  "Package-qualified internal class names must resolve through the Lisp Classes hyperbook.")
    (assert-true (eq (hyperbook::class-object-of page)
                     (find-class symbol nil))
                 "The opened internal Lisp Classes page must hold the live class object.")))

(defun run-built-in-lisp-class-page-smoke-test ()
  (let* ((symbol 'cl:standard-object)
         (page-id (hyperbook::package-qualified-symbol-name symbol))
         (page (hyperbook:find-page hyperbook::*lisp-classes*
                                    page-id
                                    :signal-error? t)))
    (assert-true (find-class symbol nil)
                 "Focused Lisp Classes smoke must use a real built-in class")
    (assert-true (typep page 'hyperbook::lisp-class-page)
                 "Opening a known built-in class must still yield a real lisp-class-page.")
    (assert-equal page-id
                  (hyperbook:id-of page)
                  "Built-in class page ids must use the canonical package-qualified class name.")
    (assert-true (eq (hyperbook::class-object-of page)
                     (find-class symbol nil))
                 "Built-in class lookup must carry the live class object from the running image.")))

(defun run-loaded-classes-inventory-smoke-test ()
  (let* ((exported-id (hyperbook::package-qualified-symbol-name 'hyperbook:hyperbook))
         (internal-id (hyperbook::package-qualified-symbol-name 'hyperbook::lisp-class-page))
         (built-in-id (hyperbook::package-qualified-symbol-name 'cl:standard-object))
         (pages (hyperbook::collect-lisp-class-pages
                 hyperbook::*lisp-classes*)))
    (assert-true pages
                 "The Lisp Classes hyperbook must expose a non-empty inventory of loaded class pages.")
    (dolist (page-id (list exported-id internal-id built-in-id))
      (let ((page (find-lisp-class-page-by-id pages page-id)))
        (assert-true page
                     (format nil "Loaded class inventory must contain ~A." page-id))
        (assert-true (typep page 'hyperbook::lisp-class-page)
                     (format nil "Loaded class inventory entry ~A must be a real lisp-class-page."
                             page-id))))))

(defun run-loaded-classes-view-smoke-test ()
  (let* ((exported-id (hyperbook::package-qualified-symbol-name 'hyperbook:hyperbook))
         (internal-id (hyperbook::package-qualified-symbol-name 'hyperbook::lisp-class-page))
         (built-in-id (hyperbook::package-qualified-symbol-name 'cl:standard-object))
         (views (load-inspector-views-for-object hyperbook::*lisp-classes*))
         (overview-view (smoke-find-view-by-title views "Overview"))
         (loaded-view (smoke-find-view-by-title views "Loaded classes"))
         (overview-html (and overview-view
                             (html-inspector-views:view-html overview-view)))
         (loaded-html (and loaded-view
                           (html-inspector-views:view-html loaded-view))))
    (assert-true overview-view
                 "The Lisp Classes hyperbook must still expose an Overview view.")
    (assert-true loaded-view
                 "The Lisp Classes hyperbook must expose a browseable Loaded classes view.")
    (assert-true (search "Loaded classes view"
                         overview-html
                         :test #'char-equal)
                 "Overview text must now point users to the browseable Loaded classes view.")
    (dolist (page-id (list exported-id internal-id built-in-id))
      (assert-true (search page-id loaded-html :test #'char-equal)
                   (format nil "Loaded classes view must list ~A." page-id)))
    (assert-true (search "class='inspector-inspect'"
                         loaded-html
                         :test #'char-equal)
                 "Loaded classes view must render inspectable navigation rows for the listed class pages.")))

(defun run-missing-lisp-class-lookup-issue-smoke-test ()
  (let* ((symbol (intern "CLASS-LOOKUP-ISSUE-SMOKE-MISSING" :hyperdoc))
         (page-id (format nil "~A::~A"
                          (package-name (symbol-package symbol))
                          (symbol-name symbol)))
         (issue (hyperbook:find-page hyperbook::*lisp-classes*
                                     page-id
                                     :signal-error? t))
         (condition (hyperbook:lookup-issue-underlying-condition-of issue))
         (details (hyperbook:lookup-issue-details-of issue)))
    (assert-true (null (find-class symbol nil))
                 "Focused Lisp Classes smoke must use a symbol that does not name a class")
    (assert-true (typep issue 'hyperbook:page-lookup-issue)
                 "A missing Lisp class page should surface as a bounded page-lookup-issue.")
    (assert-equal :lisp-class-page
                  (hyperbook:lookup-issue-target-kind-of issue)
                  "Missing Lisp class lookup issues must target lisp-class-page.")
    (assert-equal :missing-lisp-class-definition
                  (hyperbook:lookup-issue-classification-of issue)
                  "Missing Lisp class lookup issues must keep the class-specific classification.")
    (assert-true condition
                 "A missing Lisp class lookup issue must preserve the underlying find-class condition.")
    (assert-equal :find-class
                  (getf details :lookup-stage)
                  "Missing Lisp class lookup issue details must record the find-class lookup stage.")
    (assert-true (eq symbol (getf details :expected-symbol))
                 "Missing Lisp class lookup issue details must preserve the missing symbol.")
    (assert-equal nil
                  (getf details :classp)
                  "Missing Lisp class lookup issue details must preserve the failed classp check.")
    (assert-equal (type-of condition)
                  (getf details :condition-type)
                  "Missing Lisp class lookup issue details must preserve the underlying condition type.")))

(defun run-class-lookup-issues-smoke-tests ()
  (run-exported-lisp-class-page-smoke-test)
  (run-internal-lisp-class-page-smoke-test)
  (run-built-in-lisp-class-page-smoke-test)
  (run-loaded-classes-inventory-smoke-test)
  (run-loaded-classes-view-smoke-test)
  (run-missing-lisp-class-lookup-issue-smoke-test)
  (format t "~&Class lookup issue smoke tests passed.~%")
  t)
