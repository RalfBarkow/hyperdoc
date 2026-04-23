;;;; Minimal mutation operations for page-lookup authored relation artifacts
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass page-lookup-issue-authored-relation-mutation
    (authored-relation-mutation)
  ())

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
