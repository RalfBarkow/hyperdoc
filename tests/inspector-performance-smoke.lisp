;;;; Smoke tests for inspector performance JS emission
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-INSPECTOR-PERFORMANCE-SMOKE-TESTS" :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun inspector-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun inspector-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun inspector-assert-contains (substring string message)
  (unless (search substring string)
    (error "~A -- missing substring: ~S" message substring)))

(defun inspector-assert-not-contains (substring string message)
  (when (search substring string)
    (error "~A -- unexpected substring: ~S" message substring)))

(defun inspector-smoke-find-view-by-title (views title)
  (find title views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defclass inspector-render-smoke-element ()
  ((html-id :initarg :html-id
            :reader inspector-render-smoke-element-html-id-of)
   (html :initform ""
         :accessor inspector-render-smoke-element-html-of)
   (attributes :initform (make-hash-table :test #'equal)
               :reader inspector-render-smoke-element-attributes-of)
   (children :initform (make-hash-table :test #'equal)
             :reader inspector-render-smoke-element-children-of)
   (click-handler :initform nil
                  :accessor inspector-render-smoke-element-click-handler-of)))

(defmethod clog:html-id ((element inspector-render-smoke-element))
  (inspector-render-smoke-element-html-id-of element))

(defmethod clog:attribute ((element inspector-render-smoke-element)
                           attribute-name
                           &key default-answer)
  (multiple-value-bind (value presentp)
      (gethash attribute-name
               (inspector-render-smoke-element-attributes-of element))
    (if presentp value default-answer)))

(defmethod (setf clog:attribute) (value
                                  (element inspector-render-smoke-element)
                                  attribute-name)
  (setf (gethash attribute-name
                 (inspector-render-smoke-element-attributes-of element))
        value))

(defmethod clog:inner-html ((element inspector-render-smoke-element))
  (inspector-render-smoke-element-html-of element))

(defmethod (setf clog:inner-html) (value
                                   (element inspector-render-smoke-element))
  (setf (inspector-render-smoke-element-html-of element) value))

(defmethod clog:js-execute ((element inspector-render-smoke-element) script)
  (declare (ignore script))
  element)

(defmethod clog:connection-body ((element inspector-render-smoke-element))
  nil)

(defmethod clog:attach-as-child ((element inspector-render-smoke-element)
                                 html-id
                                 &key (clog-type 'inspector-render-smoke-element)
                                   new-id)
  (declare (ignore clog-type new-id))
  (or (gethash html-id (inspector-render-smoke-element-children-of element))
      (setf (gethash html-id
                     (inspector-render-smoke-element-children-of element))
            (make-instance 'inspector-render-smoke-element
                           :html-id html-id))))

(defmethod clog:set-on-mouse-click ((element inspector-render-smoke-element)
                                    handler
                                    &key one-time cancel-event)
  (declare (ignore one-time cancel-event))
  (setf (inspector-render-smoke-element-click-handler-of element) handler)
  element)

(defun clog-empty-id-normalizer-available-p ()
  (let ((sym (find-symbol "NORMALIZE-HTML-ID-FOR-ATTACH" :clog)))
    (and sym (fboundp sym))))

(defun ensure-patched-clog-empty-id-guards-loaded ()
  (unless (clog-empty-id-normalizer-available-p)
    (let* ((clog-src (uiop:getenv "CLOG_SRC"))
           (clog-dir (and clog-src
                          (uiop:ensure-directory-pathname clog-src)))
           (clog-element-source
            (and clog-dir
                 (merge-pathnames "source/clog-element.lisp" clog-dir))))
      (unless (and clog-element-source (probe-file clog-element-source))
        (error "CLOG_SRC does not expose source/clog-element.lisp: ~S" clog-src))
      ;; Loading the patched CLOG element source avoids nested ASDF :force
      ;; during :asdf:test-system while still rebinding attach helpers
      ;; to the patched empty-id normalizer contract.
      (load clog-element-source)))
  (inspector-assert-true
   (clog-empty-id-normalizer-available-p)
   "Patched CLOG runtime must expose NORMALIZE-HTML-ID-FOR-ATTACH"))

(defun run-dom-node-count-query-script-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  (let ((string-script
         (clog-moldable-inspector::dom-node-count-query-script "view817"))
        (symbol-id (make-symbol "view817")))
    (inspector-assert-equal
     "view817"
     (clog-moldable-inspector::normalize-dom-html-id "view817")
     "String ids must remain unchanged")
    (inspector-assert-true
     (search "document.getElementById(\"view817\")" string-script)
     "String ids must be emitted as quoted JS strings")
    (inspector-assert-true
     (null (search "document.getElementById(view817)" string-script))
     "String ids must not be emitted as bare JS tokens")
    (let ((symbol-script
           (clog-moldable-inspector::dom-node-count-query-script symbol-id)))
      (inspector-assert-equal
       "view817"
       (clog-moldable-inspector::normalize-dom-html-id symbol-id)
       "Symbol ids must normalize to their symbol-name")
      (inspector-assert-true
       (search "document.getElementById(\"view817\")" symbol-script)
       "Symbol-ish ids must be emitted as quoted JS strings")
      (inspector-assert-true
       (null (search "#:|view817|" symbol-script))
       "Symbol reader syntax must not leak into emitted JS")
      (inspector-assert-true
       (null (search "document.getElementById(view817)" symbol-script))
       "Symbol-ish ids must not be emitted as bare JS tokens"))))

(defun run-clog-empty-html-id-emission-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  ;; Keep the patched CLOG methods active after loading :hyperdoc/server.
  (ensure-patched-clog-empty-id-guards-loaded)
  (inspector-assert-equal
   "undefined"
   (funcall (intern "NORMALIZE-HTML-ID-FOR-ATTACH" :clog) "")
   "Blank html ids must normalize before any websocket payload is considered")
  (let ((root (clog::make-clog-obj "test-connection" "root")))
    (let ((clog::*connection-cache* (list :cache)))
      (let ((child (clog:attach-as-child root "")))
        (inspector-assert-equal
         "undefined"
         (clog:html-id child)
         "Blank attach-as-child ids must normalize to the shared undefined sentinel")
        (inspector-assert-equal
         '(:cache)
         clog::*connection-cache*
         "Blank attach-as-child ids must not queue websocket eval payloads"))))
  (let ((clog::*connection-cache* (list :cache)))
    (let ((child (clog::attach "test-connection" "")))
      (inspector-assert-equal
       "undefined"
       (clog:html-id child)
       "Blank attach ids must normalize to the shared undefined sentinel")
      (inspector-assert-equal
       '(:cache)
       clog::*connection-cache*
       "Blank attach ids must not queue websocket eval payloads")))
  (let ((root (clog::make-clog-obj "test-connection" "root"))
        (clog::*connection-cache* (list :cache)))
    (let ((child (clog:attach-as-child root "view817")))
      (inspector-assert-equal
       "view817"
       (clog:html-id child)
       "Non-blank attach-as-child ids must still attach normally")
      (inspector-assert-contains
       "clog['view817']=$('#view817').get(0)"
       (first clog::*connection-cache*)
	       "Non-blank attach-as-child ids must still emit the expected websocket payload"))))

(defun inspector-smoke-html-page ()
  (make-instance 'hyperdoc::html-page
                 :hyperbook (make-instance 'hyperbook:hyperbook :id "smoke")
                 :id "Render debugger smoke"
                 :file nil))

(defun inspector-smoke-content-view (&key fail?)
  (html-inspector-views:make-html-view
   (html-inspector-views:thunk
    (if fail?
        (error "forced content render failure")
        (html-inspector-views:html-and-references
         (:p "Rendered content from smoke fixture"))))
   :title "Content"
   :priority 1))

(defun run-html-page-content-render-report-views-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  (let* ((page (inspector-smoke-html-page))
         (view (inspector-smoke-content-view))
         (report
           (clog-moldable-inspector::make-html-page-content-render-report
            page
            view)))
    (clog-moldable-inspector::record-html-page-content-render-event
     report
     :debugger-visible
     :message "Smoke debugger inserted.")
    (setf (clog-moldable-inspector::html-page-content-render-report-html-cache-hit?-of
           report)
          nil
          (clog-moldable-inspector::html-page-content-render-report-html-ms-of
           report)
          3
          (clog-moldable-inspector::html-page-content-render-report-reference-count-of
           report)
          1
          (clog-moldable-inspector::html-page-content-render-report-asset-count-of
           report)
          0)
    (let* ((views (html-inspector-views:all-views report))
           (overview (inspector-smoke-find-view-by-title views "Overview"))
           (events (inspector-smoke-find-view-by-title views "Events"))
           (condition (inspector-smoke-find-view-by-title views "Condition"))
           (page-object (inspector-smoke-find-view-by-title views "Page / Object")))
      (dolist (view-title '("Overview" "Events" "Condition" "Page / Object"))
        (inspector-assert-true
         (inspector-smoke-find-view-by-title views view-title)
         (format nil "Render report must expose ~A view" view-title)))
      (inspector-assert-contains
       "Content Render Debugger"
       (html-inspector-views:view-html overview)
       "Overview view must identify the render debugger")
      (inspector-assert-contains
       "debugger-visible"
       (html-inspector-views:view-html events)
       "Events view must expose recorded phase names")
      (inspector-assert-contains
       "No render condition"
       (html-inspector-views:view-html condition)
       "Condition view must expose the empty-condition state")
      (inspector-assert-contains
       "Render debugger smoke"
       (html-inspector-views:view-html page-object)
       "Page / Object view must link back to the rendered page")))
  t)

(defun run-html-page-content-render-failure-debugger-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  (let* ((page (inspector-smoke-html-page))
         (view (inspector-smoke-content-view :fail? t))
         (pane (make-instance 'clog-moldable-inspector::pane
                              :inspector nil
                              :object page))
         (element (make-instance 'inspector-render-smoke-element
                                 :html-id "view-render-smoke")))
    (multiple-value-bind (result log-output)
        (let ((*trace-output* (make-string-output-stream)))
          (values
           (clog-moldable-inspector::create-view-element pane element view)
           (get-output-stream-string *trace-output*)))
      (let ((html (clog:inner-html element)))
        (inspector-assert-true
         (typep result 'clog-moldable-inspector::html-page-content-render-report)
         "Failed html-page Content render must return the render report")
        (inspector-assert-equal
         "error"
         (clog:attribute element "data-hyperdoc-render-state")
         "Failed html-page Content render must leave the debugger in error state")
        (inspector-assert-equal
         "false"
         (clog:attribute element "aria-busy")
         "Failed html-page Content render must clear aria-busy")
        (inspector-assert-contains
         "Content render debugger"
         html
         "Failed html-page Content render must leave a visible debugger")
        (inspector-assert-contains
         "inspector-inspect"
         html
         "Debugger placeholder must contain an inspectable report link")
        (inspector-assert-not-contains
         "Loading content"
         html
         "Debugger placeholder must not regress to the inert loading string")
        (inspector-assert-contains
         "forced content render failure"
         (or (clog-moldable-inspector::html-page-content-render-report-condition-message-of
              result)
             "")
         "Render report must record the rendering condition message")
        (inspector-assert-equal
         :debugger-visible
         (clog-moldable-inspector::html-page-content-render-report-last-completed-phase-of
          result)
         "Render report must preserve the last completed phase before failure")
        (inspector-assert-contains
         "[INSPECTOR-PERF] VIEW/LOADING"
         log-output
         "Visible debugger path must retain existing loading performance log")
        (inspector-assert-contains
         "[INSPECTOR-PERF] VIEW/RENDER-ERROR"
         log-output
         "Failed render path must emit browser-visible debugger performance evidence"))))
  t)

(defun run-inspector-performance-smoke-tests ()
  (run-dom-node-count-query-script-smoke-test)
  (run-clog-empty-html-id-emission-smoke-test)
  (run-html-page-content-render-report-views-smoke-test)
  (run-html-page-content-render-failure-debugger-smoke-test)
  (format t "~&Inspector performance smoke tests passed.~%")
  t)
