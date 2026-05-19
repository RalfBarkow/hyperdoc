;;;; First-class view contract objects
;;
;;;; Copyright (c) 2026

(in-package #:html-inspector-views)

(defclass inspector-view-specification ()
  ((view-id :accessor view-id-of :initarg :view-id)
   (view-title :accessor view-title-of :initarg :view-title)
   (subject-type :accessor subject-type-of :initarg :subject-type)
   (reader-question :accessor reader-question-of :initarg :reader-question)
   (content-model :accessor content-model-of :initarg :content-model)
   (box-contract :accessor box-contract-of :initarg :box-contract)
   (priority-policy :accessor priority-policy-of :initarg :priority-policy)
   (actions :accessor actions-of :initarg :actions :initform nil)
   (evidence :accessor evidence-of :initarg :evidence :initform nil)
   (failure-modes :accessor failure-modes-of :initarg :failure-modes
                  :initform nil)))

(defgeneric view-specification (view subject)
  (:documentation "Return the inspectable contract for VIEW when applied to SUBJECT."))

(defgeneric view-reader-question (view subject))
(defgeneric view-content-model (view subject))
(defgeneric view-box-contract (view subject))
(defgeneric view-priority-policy (view subject))
(defgeneric view-failure-modes (view subject))

(defmethod text-representation ((spec inspector-view-specification))
  (format nil "View Contract: ~A" (view-title-of spec)))

(defun %view-contract-method-name (view)
  (let ((method (and (slot-boundp view 'method)
                     (ignore-errors (view-method view)))))
    (when method
      (let ((generic (ignore-errors
                       (closer-mop:method-generic-function method))))
        (when generic
          (princ-to-string
           (closer-mop:generic-function-name generic)))))))

(defun %view-contract-default-id (view)
  (or (%view-contract-method-name view)
      (string-downcase
       (substitute #\- #\Space
                   (or (ignore-errors (view-title view))
                       "inspector-view")))))

(defmethod view-reader-question ((view view) subject)
  (declare (ignore subject))
  (format nil "What does the ~A view promise to show about this subject?"
          (view-title view)))

(defmethod view-content-model ((view view) subject)
  (declare (ignore view subject))
  '(:view-title :subject :html-content :references :assets))

(defmethod view-box-contract ((view view) subject)
  (declare (ignore view subject))
  '((:root-box
     :display :block
     :inline-size :available
     :block-size :auto
     :max-inline-size "100%"
     :overflow :auto)
    (:content-box
     :display :block
     :overflow-wrap :anywhere
     :padding-inline :view-default
     :margin-block :view-default)))

(defmethod view-priority-policy ((view view) subject)
  (declare (ignore subject))
  (list :view-priority (view-priority view)
        :tab-title (view-title view)
        :ordering :ascending-priority
        :constraint-policy :defer-to-inspector-pane))

(defmethod view-failure-modes ((view view) subject)
  (declare (ignore view subject))
  '(:missing-layout-snapshot
    :horizontal-overflow
    :hidden-affordance
    :unbounded-content
    :missing-layout-metadata))

(defun %view-contract-default-actions (view subject)
  (declare (ignore subject))
  (list (list :inspect-view :navigation :view-title (view-title view))
        '(:inspect-source :navigation)
        '(:inspect-references :navigation)))

(defun %view-contract-default-evidence (view subject)
  (declare (ignore view subject))
  '((:layout-snapshot :missing-evidence)
    (:explanation
     "No rendered-view-layout-snapshot evidence is available for this view/subject yet.")
    (:model
     "View Contract = declared promise; Rendered Snapshot = runtime evidence; Layout Diagnosis = divergence.")))

(defmethod view-specification ((view view) subject)
  (make-instance
   'inspector-view-specification
   :view-id (%view-contract-default-id view)
   :view-title (view-title view)
   :subject-type (type-of subject)
   :reader-question (view-reader-question view subject)
   :content-model (view-content-model view subject)
   :box-contract (view-box-contract view subject)
   :priority-policy (view-priority-policy view subject)
   :actions (%view-contract-default-actions view subject)
   :evidence (%view-contract-default-evidence view subject)
   :failure-modes (view-failure-modes view subject)))

(defun %render-contract-code-list (items)
  (if items
      (html
       (:ul
        (loop for item in items
              do (html
                  (:li (:code (esc (princ-to-string item))))))))
      (html (:p "None recorded."))))

(defun %render-contract-table (rows)
  (html
   (:table :class "inspector-table"
           (loop for (label value) in rows
                 do (html
                     (:tr (:td (esc label))
                          (:td (:code
                                (esc (princ-to-string value))))))))))

(defview 👀view-contract-summary (spec inspector-view-specification)
  (make-html-view
   (thunk
    (html-and-references
     (html
      (:h3 (esc (view-title-of spec)))
      (%render-contract-table
       `(("View id" ,(view-id-of spec))
         ("Subject type" ,(subject-type-of spec))
         ("Reader question" ,(reader-question-of spec))))
      (:p (:strong "Model: ")
          "View Contract = declared promise; Rendered Snapshot = runtime evidence; Layout Diagnosis = divergence."))))
   :title "Summary"
   :priority 1))

(defview 👀view-contract-content-model (spec inspector-view-specification)
  (make-html-view
   (thunk
    (html-and-references
     (html
      (:h3 "Content model")
      (%render-contract-code-list (content-model-of spec)))))
   :title "Content model"
   :priority 2))

(defview 👀view-contract-box-contract (spec inspector-view-specification)
  (make-html-view
   (thunk
    (html-and-references
     (html
      (:h3 "Box contract")
      (%render-contract-code-list (box-contract-of spec)))))
   :title "Box contract"
   :priority 3))

(defview 👀view-contract-priority-policy (spec inspector-view-specification)
  (make-html-view
   (thunk
    (html-and-references
     (html
      (:h3 "Priority policy")
      (%render-contract-code-list (list (priority-policy-of spec))))))
   :title "Priority policy"
   :priority 4))

(defview 👀view-contract-actions (spec inspector-view-specification)
  (make-html-view
   (thunk
    (html-and-references
     (html
      (:h3 "Actions")
      (%render-contract-code-list (actions-of spec)))))
   :title "Actions"
   :priority 5))

(defview 👀view-contract-evidence (spec inspector-view-specification)
  (make-html-view
   (thunk
    (html-and-references
     (html
      (:h3 "Evidence")
      (%render-contract-code-list (evidence-of spec))
      (when (member '(:layout-snapshot :missing-evidence)
                    (evidence-of spec)
                    :test #'equal)
        (html
         (:p (:strong "Missing evidence: ")
             "No rendered layout snapshot is currently attached to this contract."))))))
   :title "Evidence"
   :priority 6))

(defview 👀view-contract-failure-modes (spec inspector-view-specification)
  (make-html-view
   (thunk
    (html-and-references
     (html
      (:h3 "Failure modes")
      (%render-contract-code-list (failure-modes-of spec)))))
   :title "Failure modes"
   :priority 7))
