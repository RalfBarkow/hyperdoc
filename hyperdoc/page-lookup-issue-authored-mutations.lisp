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
  (let* ((relations (page-lookup-issue-authored-source-relation-definitions))
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
     :source-path source-path
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
         (relations (page-lookup-issue-authored-source-relation-definitions))
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
       :source-path source-path
       :summary
       "Toggle the authored layout relation that declares whether Repair follows Overview."))))
