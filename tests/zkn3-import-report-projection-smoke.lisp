(in-package :cl-user)

(defun zkn3-import-report-projection-assert-true (value message)
  (unless value
    (error "~A" message)))

(defun zkn3-import-report-projection-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun zkn3-import-report-projection-load-views (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun zkn3-import-report-projection-html-contains-all
    (html label needles)
  (dolist (needle needles)
    (zkn3-import-report-projection-assert-true
     (and html (search needle html :test #'char=))
     (format nil "~A must contain ~S" label needle))))

(defun run-zkn3-import-report-projection-smoke-test ()
  (let* ((report
           (hyperdoc/inspector::make-example-zkn3-import-report-projection))
         (reference
           (first
            (hyperdoc/inspector::zkn3-import-report-projection-examples-of
             report)))
         (report-views
           (zkn3-import-report-projection-load-views report))
         (reference-views
           (zkn3-import-report-projection-load-views reference))
         (summary
           (zkn3-import-report-projection-find-view-by-title
            report-views "Summary"))
         (unresolved
           (zkn3-import-report-projection-find-view-by-title
            report-views "Unresolved references"))
         (evidence
           (zkn3-import-report-projection-find-view-by-title
            report-views "Evidence"))
         (edge-boundary
           (zkn3-import-report-projection-find-view-by-title
            reference-views "Edge boundary")))
    (zkn3-import-report-projection-assert-true
     summary
     "Report must expose Summary view")
    (zkn3-import-report-projection-assert-true
     unresolved
     "Report must expose Unresolved references view")
    (zkn3-import-report-projection-assert-true
     evidence
     "Report must expose Evidence view")
    (zkn3-import-report-projection-assert-true
     edge-boundary
     "Reference must expose Edge boundary view")

    (zkn3-import-report-projection-html-contains-all
     (html-inspector-views:view-html summary)
     "Summary view"
     '("ZKN3 import report projection"
       "9023"
       "MANUAL_LINK"
       "OUT_OF_RANGE"
       "Unresolved references"))

    (zkn3-import-report-projection-html-contains-all
     (html-inspector-views:view-html unresolved)
     "Unresolved references view"
     '("240611105406688rgb50919"
       "manlinks"
       "64444"
       "MANUAL_LINK"
       "OUT_OF_RANGE"))

    (zkn3-import-report-projection-html-contains-all
     (html-inspector-views:view-html edge-boundary)
     "Edge boundary view"
     '("No resolved edge created"
       "created Zkn3LinkRecord"
       "false"
       "64444"))

    (zkn3-import-report-projection-html-contains-all
     (html-inspector-views:view-html evidence)
     "Evidence view"
     '("deff040"
       "cf85959"
       "c2a9e34"
       "d841883"))
    t))

(run-zkn3-import-report-projection-smoke-test)
