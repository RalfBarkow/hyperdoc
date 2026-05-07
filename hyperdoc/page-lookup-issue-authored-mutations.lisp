;;;; Minimal mutation operations for page-lookup authored relation artifacts
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass page-lookup-issue-authored-relation-mutation
    (authored-relation-mutation)
  ())

(defclass page-lookup-issue-authored-mutation-roundtrip-report ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (source-path
    :reader page-lookup-issue-roundtrip-source-path-of
    :initarg :source-path
    :initform nil)
   (before-source-artifact
    :reader page-lookup-issue-roundtrip-before-source-artifact-of
    :initarg :before-source-artifact
    :initform nil)
   (before-authored-artifact
    :reader page-lookup-issue-roundtrip-before-authored-artifact-of
    :initarg :before-authored-artifact
    :initform nil)
   (before-behavior-artifact
    :reader page-lookup-issue-roundtrip-before-behavior-artifact-of
    :initarg :before-behavior-artifact
    :initform nil)
   (before-layout-artifact
    :reader page-lookup-issue-roundtrip-before-layout-artifact-of
    :initarg :before-layout-artifact
    :initform nil)
   (before-consumer
    :reader page-lookup-issue-roundtrip-before-consumer-of
    :initarg :before-consumer
    :initform nil)
   (before-consumer-layout-artifact
    :reader page-lookup-issue-roundtrip-before-consumer-layout-artifact-of
    :initarg :before-consumer-layout-artifact
    :initform nil)
   (before-ordered-panes
    :reader page-lookup-issue-roundtrip-before-ordered-panes-of
    :initarg :before-ordered-panes
    :initform nil)
   (after-source-artifact
    :reader page-lookup-issue-roundtrip-after-source-artifact-of
    :initarg :after-source-artifact
    :initform nil)
   (after-authored-artifact
    :reader page-lookup-issue-roundtrip-after-authored-artifact-of
    :initarg :after-authored-artifact
    :initform nil)
   (after-behavior-artifact
    :reader page-lookup-issue-roundtrip-after-behavior-artifact-of
    :initarg :after-behavior-artifact
    :initform nil)
   (after-layout-artifact
    :reader page-lookup-issue-roundtrip-after-layout-artifact-of
    :initarg :after-layout-artifact
    :initform nil)
   (after-consumer
    :reader page-lookup-issue-roundtrip-after-consumer-of
    :initarg :after-consumer
    :initform nil)
   (after-consumer-layout-artifact
    :reader page-lookup-issue-roundtrip-after-consumer-layout-artifact-of
    :initarg :after-consumer-layout-artifact
    :initform nil)
   (after-ordered-panes
    :reader page-lookup-issue-roundtrip-after-ordered-panes-of
    :initarg :after-ordered-panes
    :initform nil)
   (planned-mutation
    :reader page-lookup-issue-roundtrip-planned-mutation-of
    :initarg :planned-mutation
    :initform nil)
   (applied-mutation
    :reader page-lookup-issue-roundtrip-applied-mutation-of
    :initarg :applied-mutation
    :initform nil)
   (restored-p
    :reader page-lookup-issue-roundtrip-restored-p
    :initarg :restored-p
    :initform nil)
   (findings
    :reader page-lookup-issue-roundtrip-findings-of
    :initarg :findings
    :initform nil)))

(defvar *last-page-lookup-issue-authored-mutation-roundtrip-report* nil)

(defun make-page-lookup-issue-example-consumer
    (&key
       (target-hyperbook-id "topics")
       (expected-page-id "Synthetic mutation walkthrough target")
       (source-page-id
        "Authored relation mutation round-trip for page-lookup issue")
       (source-page-title
        "Authored relation mutation round-trip for page-lookup issue"))
  (hyperbook::enrich-lookup-issue
   (hyperbook::make-page-lookup-issue
    (make-condition 'simple-error
                    :format-control "Synthetic page-lookup issue"
                    :format-arguments nil)
    :source-hyperbook "hyperdoc"
    :source-page-id source-page-id
    :source-page-title source-page-title
    :source-section "Example walkthrough"
    :link-text expected-page-id
    :target-hyperbook-id target-hyperbook-id
    :expected-page-id expected-page-id
    :classification :lookup-failure)))

(defun page-lookup-issue-example-consumer-layout-artifact (&optional issue)
  (declare (ignore issue))
  (page-lookup-issue-layout-artifact))

(defun page-lookup-issue-layout-artifact-ordered-panes (artifact)
  (getf (compiled-layout-artifact-layout-spec-of artifact) :ordered-panes))

(defun run-page-lookup-issue-authored-mutation-roundtrip-example
    (&key source-path)
  (let* ((resolved-source-path
          (namestring
           (page-lookup-issue-authored-layout-source-pathname
            (or source-path
                *page-lookup-issue-authored-layout-source-path*))))
         (original-payload
          (copy-tree
           (page-lookup-issue-authored-layout-override-payload
            :source-path resolved-source-path))))
    (unwind-protect
         (let ((*page-lookup-issue-authored-layout-source-path*
                resolved-source-path))
           (let* ((before-reconstruction
                   (reconstruct-page-lookup-issue-artifacts-from-source
                    :refresh-source t))
                  (before-source (getf before-reconstruction :source))
                  (before-authored (getf before-reconstruction :authored))
                  (before-behavior (getf before-reconstruction :behavior))
                  (before-layout (getf before-reconstruction :layout))
                  (before-consumer (make-page-lookup-issue-example-consumer))
                  (before-consumer-layout
                   (page-lookup-issue-example-consumer-layout-artifact
                    before-consumer))
                  (planned-mutation
                   (make-page-lookup-issue-layout-order-toggle-mutation
                    :source-path resolved-source-path)))
             (multiple-value-bind (applied-mutation after-reconstruction)
                 (apply-authored-relation-mutation
                  planned-mutation
                  :source-path resolved-source-path)
               (let* ((after-source (getf after-reconstruction :source))
                      (after-authored (getf after-reconstruction :authored))
                      (after-behavior (getf after-reconstruction :behavior))
                      (after-layout (getf after-reconstruction :layout))
                      (after-consumer (make-page-lookup-issue-example-consumer))
                      (after-consumer-layout
                       (page-lookup-issue-example-consumer-layout-artifact
                        after-consumer))
                      (before-ordered-panes
                       (page-lookup-issue-layout-artifact-ordered-panes
                        before-consumer-layout))
                      (after-ordered-panes
                       (page-lookup-issue-layout-artifact-ordered-panes
                        after-consumer-layout)))
                 (make-instance
                  'page-lookup-issue-authored-mutation-roundtrip-report
                  :id "example/page-lookup-issue-authored-mutation-roundtrip"
                  :title
                  "Page-lookup authored mutation round-trip report"
                  :summary
                  "Bounded mutation report: write-back to authored source, reconstruction, and consumer-visible layout change."
                  :source-path resolved-source-path
                  :before-source-artifact before-source
                  :before-authored-artifact before-authored
                  :before-behavior-artifact before-behavior
                  :before-layout-artifact before-layout
                  :before-consumer before-consumer
                  :before-consumer-layout-artifact before-consumer-layout
                  :before-ordered-panes before-ordered-panes
                  :after-source-artifact after-source
                  :after-authored-artifact after-authored
                  :after-behavior-artifact after-behavior
                  :after-layout-artifact after-layout
                  :after-consumer after-consumer
                  :after-consumer-layout-artifact after-consumer-layout
                  :after-ordered-panes after-ordered-panes
                  :planned-mutation planned-mutation
                  :applied-mutation applied-mutation
                  :restored-p t
                  :findings
                  (list
                   (format nil
                           "Before ordered panes: ~S"
                           before-ordered-panes)
                   (format nil
                           "After ordered panes: ~S"
                           after-ordered-panes)
                   "The mutation loop writes one relation override, reconstructs artifacts, captures consumer change, then restores source state."))))))
      (write-page-lookup-issue-authored-layout-override-payload
       original-payload
       :source-path resolved-source-path)
      (let ((*page-lookup-issue-authored-layout-source-path*
             resolved-source-path))
        (reconstruct-page-lookup-issue-artifacts-from-source
         :refresh-source t)))))

(defun page-lookup-issue-authored-mutation-roundtrip-report
    (&key refresh source-path)
  (if (or refresh
          (null *last-page-lookup-issue-authored-mutation-roundtrip-report*))
      (setf *last-page-lookup-issue-authored-mutation-roundtrip-report*
            (run-page-lookup-issue-authored-mutation-roundtrip-example
             :source-path source-path))
      *last-page-lookup-issue-authored-mutation-roundtrip-report*))

(defun page-lookup-issue-relation-definition-by-id (definitions relation-id)
  (find relation-id
        definitions
        :key (lambda (definition) (getf definition :id))
        :test #'equal))

(defun page-lookup-issue-relation-definition-replaced-subject-object
    (definition new-subject new-object)
  (let ((updated (copy-list definition)))
    (setf (getf updated :subject) new-subject
          (getf updated :object) new-object)
    updated))

(defun make-page-lookup-issue-layout-relation-mutation
    (&key relation-id new-subject new-object source-path summary)
  (let* ((effective-source-path
          (or source-path
              *page-lookup-issue-authored-layout-source-path*))
         (relations
          (page-lookup-issue-authored-source-relation-definitions
           :source-path effective-source-path))
         (before
          (page-lookup-issue-relation-definition-by-id relations relation-id))
         (after
          (and before
               (page-lookup-issue-relation-definition-replaced-subject-object
                before
                new-subject
                new-object))))
    (unless before
      (error "Unknown page-lookup authored relation id ~S." relation-id))
    (make-instance
     'page-lookup-issue-authored-relation-mutation
     :id (format nil "mutation/page-lookup-issue/~A" relation-id)
     :title "Page-lookup authored relation mutation"
     :summary
     (or summary
         "Narrow authored mutation for one page-lookup layout relation.")
     :target-artifact-id "page-lookup-issue-authored-artifact"
     :source-path
     (namestring
      (page-lookup-issue-authored-layout-source-pathname
       effective-source-path))
     :operation-kind :replace-layout-relation
     :relation-id relation-id
     :before-relation-definition before
     :after-relation-definition after
     :status :planned
     :findings
     '("This operation mutates exactly one authored relation definition."
       "Write-back and reconstruction are explicit follow-up steps."))))

(defun make-page-lookup-issue-layout-order-toggle-mutation (&key source-path)
  (let* ((relation-id "layout/page-lookup/repair-after-overview")
         (effective-source-path
          (or source-path
              *page-lookup-issue-authored-layout-source-path*))
         (relations
          (page-lookup-issue-authored-source-relation-definitions
           :source-path effective-source-path))
         (before
          (page-lookup-issue-relation-definition-by-id relations relation-id)))
    (unless before
      (error "Cannot toggle layout order: relation ~S not found." relation-id))
    (let ((new-subject (getf before :object))
          (new-object (getf before :subject)))
      (make-page-lookup-issue-layout-relation-mutation
       :relation-id relation-id
       :new-subject new-subject
       :new-object new-object
       :source-path effective-source-path
       :summary
       "Toggle the authored layout relation that declares whether Repair follows Overview."))))

(defun page-lookup-issue-authored-relation-mutation-applied
    (mutation source-path findings)
  (make-instance
   (class-name (class-of mutation))
   :id (id-of mutation)
   :title (title-of mutation)
   :summary (summary-of mutation)
   :target-artifact-id
   (authored-relation-mutation-target-artifact-id-of mutation)
   :source-path source-path
   :operation-kind (authored-relation-mutation-operation-kind-of mutation)
   :relation-id (authored-relation-mutation-relation-id-of mutation)
   :before-relation-definition
   (authored-relation-mutation-before-relation-definition-of mutation)
   :after-relation-definition
   (authored-relation-mutation-after-relation-definition-of mutation)
   :status :applied
   :findings findings))

(defun page-lookup-issue-authored-relation-mutation-write-payload
    (mutation source-path)
  (let* ((payload
          (copy-tree
           (page-lookup-issue-authored-layout-override-payload
            :source-path source-path)))
         (relation-overrides
          (copy-tree (or (getf payload :relation-overrides)
                         nil)))
         (updated-overrides
          (page-lookup-issue-authored-source-upsert-relation-definition
           relation-overrides
           (copy-list
            (authored-relation-mutation-after-relation-definition-of mutation)))))
    (setf (getf payload :relation-overrides) updated-overrides)
    payload))

(defmethod apply-authored-relation-mutation
    ((mutation page-lookup-issue-authored-relation-mutation) &key source-path)
  (let* ((selected-source-path
          (or source-path
              (authored-relation-mutation-source-path-of mutation)
              *page-lookup-issue-authored-layout-source-path*))
         (resolved-source-pathname
          (page-lookup-issue-authored-layout-source-pathname
           selected-source-path))
         (resolved-source-path
          (namestring resolved-source-pathname))
         (updated-payload
          (page-lookup-issue-authored-relation-mutation-write-payload
           mutation
           resolved-source-path))
         (applied-findings
          (append
           (copy-list
            (or (authored-relation-mutation-findings-of mutation)
                nil))
           (list
            (format nil
                    "Wrote authored relation override to ~A."
                    resolved-source-path)
            "Reconstructed page-lookup authored, behavior, and layout artifacts from the updated source."))))
    (write-page-lookup-issue-authored-layout-override-payload
     updated-payload
     :source-path resolved-source-path)
    (let ((*page-lookup-issue-authored-layout-source-path*
           resolved-source-path))
      (values
       (page-lookup-issue-authored-relation-mutation-applied
        mutation
        resolved-source-path
        applied-findings)
       (reconstruct-page-lookup-issue-artifacts-from-source
        :refresh-source t)))))
