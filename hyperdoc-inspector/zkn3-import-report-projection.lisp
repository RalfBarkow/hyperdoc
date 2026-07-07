(in-package :hyperdoc/inspector)

(defclass zkn3-unresolved-reference-projection ()
  ((source-note-id :initarg :source-note-id
                   :reader zkn3-unresolved-reference-source-note-id-of)
   (source-field :initarg :source-field
                 :reader zkn3-unresolved-reference-source-field-of)
   (raw-reference :initarg :raw-reference
                  :reader zkn3-unresolved-reference-raw-reference-of)
   (reference-kind :initarg :reference-kind
                   :reader zkn3-unresolved-reference-kind-of)
   (reason :initarg :reason
           :reader zkn3-unresolved-reference-reason-of)
   (order :initarg :order
          :reader zkn3-unresolved-reference-order-of)
   (edge-boundary :initarg :edge-boundary
                  :initform nil
                  :reader zkn3-unresolved-reference-edge-boundary-of)
   (evidence-artifacts :initarg :evidence-artifacts
                       :initform nil
                       :reader zkn3-unresolved-reference-evidence-artifacts-of)))

(defclass zkn3-import-report-projection ()
  ((source-name :initarg :source-name
                :reader zkn3-import-report-projection-source-name-of)
   (source-path :initarg :source-path
                :reader zkn3-import-report-projection-source-path-of)
   (observed-counts :initarg :observed-counts
                    :reader zkn3-import-report-projection-observed-counts-of)
   (unresolved-reference-count :initarg :unresolved-reference-count
                               :reader zkn3-import-report-projection-unresolved-reference-count-of)
   (by-kind :initarg :by-kind
            :reader zkn3-import-report-projection-by-kind-of)
   (by-reason :initarg :by-reason
              :reader zkn3-import-report-projection-by-reason-of)
   (examples :initarg :examples
             :reader zkn3-import-report-projection-examples-of)
   (edge-boundary :initarg :edge-boundary
                  :initform nil
                  :reader zkn3-import-report-projection-edge-boundary-of)
   (evidence-artifacts :initarg :evidence-artifacts
                       :initform nil
                       :reader zkn3-import-report-projection-evidence-artifacts-of)))

(defun make-zkn3-unresolved-reference-projection
    (&key source-note-id source-field raw-reference reference-kind reason order
       edge-boundary evidence-artifacts)
  (make-instance 'zkn3-unresolved-reference-projection
                 :source-note-id source-note-id
                 :source-field source-field
                 :raw-reference raw-reference
                 :reference-kind reference-kind
                 :reason reason
                 :order order
                 :edge-boundary edge-boundary
                 :evidence-artifacts evidence-artifacts))

(defun make-zkn3-import-report-projection
    (&key source-name source-path observed-counts unresolved-reference-count
       by-kind by-reason examples edge-boundary evidence-artifacts)
  (make-instance 'zkn3-import-report-projection
                 :source-name source-name
                 :source-path source-path
                 :observed-counts observed-counts
                 :unresolved-reference-count unresolved-reference-count
                 :by-kind by-kind
                 :by-reason by-reason
                 :examples examples
                 :edge-boundary edge-boundary
                 :evidence-artifacts evidence-artifacts))

(defun make-example-zkn3-import-report-projection ()
  (let* ((evidence '("deff040"
                     "cf85959"
                     "c2a9e34"
                     "d841883"))
         (reference
           (make-zkn3-unresolved-reference-projection
            :source-note-id "240611105406688rgb50919"
            :source-field "manlinks"
            :raw-reference "64444"
            :reference-kind "MANUAL_LINK"
            :reason "OUT_OF_RANGE"
            :order 15
            :edge-boundary '(:created-Zkn3LinkRecord false
                             :created-resolved-edge false)
            :evidence-artifacts evidence)))
    (make-zkn3-import-report-projection
     :source-name "rgb.zkn3"
     :source-path "/Users/rgb/rgb~Zettelkasten/Zettelkasten-Dateien/rgb.zkn3"
     :observed-counts '(:notes 9023
                        :keywords 13602
                        :links 2436
                        :sequences 7115
                        :attachments 716
                        :diagnostics 3520)
     :unresolved-reference-count 1
     :by-kind '(("MANUAL_LINK" . 1))
     :by-reason '(("OUT_OF_RANGE" . 1))
     :examples (list reference)
     :edge-boundary '(:no-Zkn3LinkRecord-for-rawReference true
                      :no-resolved-edge-created true)
     :evidence-artifacts evidence)))

(defmethod html-inspector-views:text-representation
    ((report zkn3-import-report-projection))
  (format nil "ZKN3 import report: ~A unresolved reference(s)"
          (zkn3-import-report-projection-unresolved-reference-count-of report)))

(defmethod html-inspector-views:text-representation
    ((reference zkn3-unresolved-reference-projection))
  (format nil "~A ~A ~A"
          (zkn3-unresolved-reference-source-field-of reference)
          (zkn3-unresolved-reference-raw-reference-of reference)
          (zkn3-unresolved-reference-reason-of reference)))

(defun zkn3-report-count (report key)
  (getf (zkn3-import-report-projection-observed-counts-of report) key))

(defun zkn3-html-row (label value)
  (html-inspector-views:html
   (:tr
    (:th :scope "row" (html-inspector-views:esc label))
    (:td (html-inspector-views:esc (format nil "~A" value))))))

(defun zkn3-html-pair-rows (pairs)
  (dolist (pair pairs)
    (zkn3-html-row (car pair) (cdr pair))))

(html-inspector-views:defview 👀summary
    (report zkn3-import-report-projection)
  (html-inspector-views:html-view
   :title "Summary"
   :priority 1
   (html-inspector-views:html
    (:h2 (html-inspector-views:esc "ZKN3 import report projection"))
    (:p (html-inspector-views:esc
         "This HyperDoc adapter mirrors Java Zkn3ImportReport facts. It does not resolve references or create graph edges."))
    (:table :class "inspector-table"
            (zkn3-html-row "Source" (zkn3-import-report-projection-source-name-of report))
            (zkn3-html-row "Notes" (zkn3-report-count report :notes))
            (zkn3-html-row "Keywords" (zkn3-report-count report :keywords))
            (zkn3-html-row "Links" (zkn3-report-count report :links))
            (zkn3-html-row "Sequences" (zkn3-report-count report :sequences))
            (zkn3-html-row "Attachments" (zkn3-report-count report :attachments))
            (zkn3-html-row "Diagnostics" (zkn3-report-count report :diagnostics))
            (zkn3-html-row "Unresolved references"
                           (zkn3-import-report-projection-unresolved-reference-count-of report)))
    (:h3 (html-inspector-views:esc "By kind"))
    (:table :class "inspector-table"
            (zkn3-html-pair-rows
             (zkn3-import-report-projection-by-kind-of report)))
    (:h3 (html-inspector-views:esc "By reason"))
    (:table :class "inspector-table"
            (zkn3-html-pair-rows
             (zkn3-import-report-projection-by-reason-of report))))))

(html-inspector-views:defview 👀unresolved-references
    (report zkn3-import-report-projection)
  (html-inspector-views:html-view
   :title "Unresolved references"
   :priority 2
   (html-inspector-views:html
    (:table :class "inspector-table"
            (:thead
             (:tr
              (:th (html-inspector-views:esc "Object"))
              (:th (html-inspector-views:esc "Source note"))
              (:th (html-inspector-views:esc "Field"))
              (:th (html-inspector-views:esc "Raw reference"))
              (:th (html-inspector-views:esc "Kind"))
              (:th (html-inspector-views:esc "Reason"))
              (:th (html-inspector-views:esc "Order"))))
            (:tbody
             (dolist (reference
                       (zkn3-import-report-projection-examples-of report))
               (html-inspector-views:html
                (:tr
                 (:td (html-inspector-views:object-ref reference))
                 (:td (html-inspector-views:esc
                       (zkn3-unresolved-reference-source-note-id-of reference)))
                 (:td (html-inspector-views:esc
                       (zkn3-unresolved-reference-source-field-of reference)))
                 (:td (:code
                       (html-inspector-views:esc
                        (zkn3-unresolved-reference-raw-reference-of reference))))
                 (:td (html-inspector-views:esc
                       (zkn3-unresolved-reference-kind-of reference)))
                 (:td (html-inspector-views:esc
                       (zkn3-unresolved-reference-reason-of reference)))
                 (:td (html-inspector-views:esc
                       (format nil "~A"
                               (zkn3-unresolved-reference-order-of reference))))))))))))

(html-inspector-views:defview 👀edge-boundary
    (reference zkn3-unresolved-reference-projection)
  (html-inspector-views:html-view
   :title "Edge boundary"
   :priority 1
   (html-inspector-views:html
    (:h2 (html-inspector-views:esc "No resolved edge created"))
    (:table :class "inspector-table"
            (zkn3-html-row "Raw reference"
                           (zkn3-unresolved-reference-raw-reference-of reference))
            (zkn3-html-row "Reference kind"
                           (zkn3-unresolved-reference-kind-of reference))
            (zkn3-html-row "Reason"
                           (zkn3-unresolved-reference-reason-of reference))
            (zkn3-html-row "created Zkn3LinkRecord" "false")
            (zkn3-html-row "created resolved edge" "false")))))

(html-inspector-views:defview 👀evidence
    (report zkn3-import-report-projection)
  (html-inspector-views:html-view
   :title "Evidence"
   :priority 3
   (html-inspector-views:html
    (:h2 (html-inspector-views:esc "Evidence artifacts"))
    (:ul
     (dolist (artifact
               (zkn3-import-report-projection-evidence-artifacts-of report))
       (html-inspector-views:html
        (:li (:code (html-inspector-views:esc artifact)))))))))
