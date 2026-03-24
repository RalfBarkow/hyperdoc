;;;; Reviewed promotion from relations to topic proposals
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass relation-topic-proposal ()
  ((relation :initarg :relation :reader relation-of)
   (proposed-id :initarg :proposed-id :reader proposed-id-of)
   (proposed-title :initarg :proposed-title :reader proposed-title-of)
   (proposed-summary :initarg :proposed-summary :reader proposed-summary-of)
   (proposed-references :initarg :proposed-references
                        :reader proposed-references-of)
   (existing-topic :initarg :existing-topic
                   :reader existing-topic-of
                   :initform nil)
   (merge-status :initarg :merge-status :reader merge-status-of)))

(defmethod print-object ((object relation-topic-proposal) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (proposed-title-of object))))

(defmethod id-of ((proposal relation-topic-proposal))
  (proposed-id-of proposal))

(defmethod title-of ((proposal relation-topic-proposal))
  (proposed-title-of proposal))

(defmethod summary-of ((proposal relation-topic-proposal))
  (proposed-summary-of proposal))

(defparameter *generic-relation-topic-kinds*
  '("association"
    "association relation"
    "generic relation"
    "link"
    "relation"
    "related"
    "unclassified association"
    "unclassified relation"))

(defun relation-topic-titleize (value)
  (let* ((raw (string-trim '(#\Space #\Tab #\Newline #\Return)
                           (or value "")))
         (normalized
           (with-output-to-string (stream)
             (loop with previous-space = nil
                   for char across raw
                   for output = (case char
                                  ((#\- #\_ #\/) #\Space)
                                  (otherwise char))
                   do (cond
                        ((char= output #\Space)
                         (unless previous-space
                           (write-char output stream))
                         (setf previous-space t))
                        (t
                         (write-char output stream)
                         (setf previous-space nil)))))))
    (if (zerop (length normalized))
        normalized
        (concatenate 'string
                     (string-upcase (subseq normalized 0 1))
                     (subseq normalized 1)))))

(defun relation-topic-kind-specific-p (value)
  (let ((normalized (string-downcase
                     (string-trim '(#\Space #\Tab #\Newline #\Return)
                                  (or value "")))))
    (and (> (length normalized) 0)
         (not (member normalized
                      *generic-relation-topic-kinds*
                      :test #'string=)))))

(defun relation-topic-slug (value)
  (let* ((text (typecase value
                 (null "relation-topic")
                 (string value)
                 (t (princ-to-string value))))
         (chars
           (loop for char across (string-downcase text)
                 collect (if (or (alpha-char-p char)
                                 (digit-char-p char))
                             char
                             #\-))))
    (string-trim "-"
                 (with-output-to-string (stream)
                   (loop with previous-dash = nil
                         for char in chars
                         do (cond
                              ((char= char #\-)
                               (unless previous-dash
                                 (write-char char stream))
                               (setf previous-dash t))
                              (t
                               (write-char char stream)
                               (setf previous-dash nil))))))))

(defun relation-topic-anchor-label (anchor)
  (and anchor
       (or (ignore-errors (label-of anchor))
           (ignore-errors (anchor-value-of anchor))
           (ignore-errors (anchor-object-id-of anchor)))))

(defun relation-topic-object-title (object)
  (typecase object
    (null nil)
    (string object)
    (pathname (namestring object))
    (t (or (ignore-errors (title-of object))
           (ignore-errors (id-of object))
           nil))))

(defun relation-topic-dom-context-title (relation)
  (or (relation-topic-object-title (context-object-of relation))
      (ignore-errors (page-title-of (source-anchor-of relation)))
      (ignore-errors (page-title-of (target-anchor-of relation)))
      (context-view-title-of relation)))

(defun relation-topic-review-title (left right)
  (format nil "Review relation topic: ~A -> ~A"
          (or left "source")
          (or right "target")))

(defgeneric relation-topic-title-candidate (relation))

(defmethod relation-topic-title-candidate ((relation dom-relation-annotation))
  (let ((kind (relation-kind-of relation)))
    (if (relation-topic-kind-specific-p kind)
        (relation-topic-titleize kind)
        (relation-topic-review-title
         (relation-topic-anchor-label (source-anchor-of relation))
         (relation-topic-anchor-label (target-anchor-of relation))))))

(defmethod relation-topic-title-candidate ((relation git-merge-intent))
  (let ((kind (relation-type-of relation)))
    (if (relation-topic-kind-specific-p kind)
        (relation-topic-titleize kind)
        (relation-topic-review-title
         (branch-name-of (source-branch-of relation))
         (branch-name-of (target-branch-of relation))))))

(defgeneric relation-topic-id-candidate (relation))

(defmethod relation-topic-id-candidate ((relation t))
  (relation-topic-slug (relation-topic-title-candidate relation)))

(defgeneric relation-topic-summary-candidate (relation))

(defmethod relation-topic-summary-candidate ((relation dom-relation-annotation))
  (let* ((kind (if (relation-topic-kind-specific-p (relation-kind-of relation))
                   (string-downcase (relation-topic-titleize
                                     (relation-kind-of relation)))
                   "relation"))
         (source (or (relation-topic-anchor-label (source-anchor-of relation))
                     "source anchor"))
         (target (or (relation-topic-anchor-label (target-anchor-of relation))
                     "target anchor"))
         (context (relation-topic-dom-context-title relation)))
    (format nil "Reviewed topic proposal derived from the ~A between ~A and ~A~@[ in ~A~]."
            kind
            source
            target
            context)))

(defmethod relation-topic-summary-candidate ((relation git-merge-intent))
  (format nil "Reviewed topic proposal derived from the ~A relation between ~A and ~A. ~A"
          (string-downcase (relation-topic-titleize (relation-type-of relation)))
          (branch-name-of (source-branch-of relation))
          (branch-name-of (target-branch-of relation))
          (summary-of relation)))

(defgeneric relation-topic-reference-candidates (relation))

(defmethod relation-topic-reference-candidates ((relation dom-relation-annotation))
  (remove-duplicates
   (remove nil
           (list (relation-topic-dom-context-title relation)
                 (relation-topic-object-title (source-object-of relation))
                 (relation-topic-object-title (target-object-of relation))
                 (relation-topic-object-title (matching-patch-target-of relation))
                 (relation-topic-object-title (matching-defect-of relation))
                 (relation-topic-object-title (matching-inserted-step-of relation))))
   :test #'string=))

(defmethod relation-topic-reference-candidates ((relation git-merge-intent))
  (remove-duplicates
   (append '("Merge Intent Relations Between Git Commits")
           (remove nil (mapcar #'relation-topic-object-title
                               (notes-of relation))))
   :test #'string=))

(defun existing-topic-by-exact-title (title)
  (find-topic-by-title title))

(defun relation-topic-proposal-function-name (proposal)
  (format nil "~A-topic" (proposed-id-of proposal)))

(defun relation-topic-proposal-factory-form (proposal)
  (format nil "(defun ~A ()~%  (make-topic~%   :id ~S~%   :title ~S~%   :summary ~S~%   :references '~S))~%"
          (relation-topic-proposal-function-name proposal)
          (proposed-id-of proposal)
          (proposed-title-of proposal)
          (proposed-summary-of proposal)
          (proposed-references-of proposal)))

(defgeneric relation-topic-proposal-source-expression (relation))

(defmethod relation-topic-proposal-source-expression ((relation t))
  "REPLACE-WITH-STABLE-RELATION-EXPR")

(defmethod relation-topic-proposal-source-expression
    ((relation dom-relation-annotation))
  (if (string= (or (ignore-errors (id-of relation)) "")
               "dom-relation/example-association-topics")
      "(example-association-topics-relation)"
      (call-next-method)))

(defun relation-topic-proposal-page-fragment (proposal)
  (let* ((relation (relation-of proposal))
         (relation-expression
           (relation-topic-proposal-source-expression relation))
         (proposal-expression
           (format nil "(promote-relation-to-topic-proposal ~A)"
                   relation-expression)))
    (format nil
            "<h1>~A</h1>~%~%<in-package>hyperdoc</in-package>~%~%<p>~A</p>~%~%<h2>Inspectable objects</h2>~%~%<ul>~%  <li><a expr=~S><tt>~A</tt></a></li>~%  <li><a expr=~S><tt>~A</tt></a></li>~%</ul>~%"
            (proposed-title-of proposal)
            (proposed-summary-of proposal)
            proposal-expression
            proposal-expression
            relation-expression
            relation-expression)))

(defun relation-topic-proposal-fedwiki-twin-delta (proposal)
  (with-output-to-string (stream)
    (format stream "slug: ~A~%" (proposed-id-of proposal))
    (format stream "title: ~A~%" (proposed-title-of proposal))
    (format stream "summary: ~A~%" (proposed-summary-of proposal))
    (format stream "references:~%")
    (if (proposed-references-of proposal)
        (dolist (reference (proposed-references-of proposal))
          (format stream "- ~A~%" reference))
        (format stream "- none inferred~%"))))

(defun relation-topic-proposal-authoring-bundle (proposal)
  (with-output-to-string (stream)
    (format stream "Merge status: ~A~%~%"
            (merge-status-of proposal))
    (format stream
            "Reminder: search hyperdoc/topics.lisp by exact :title and edit an existing factory in place when the title already exists.~%~%")
    (format stream "Proposed topic factory~%~A~%"
            (relation-topic-proposal-factory-form proposal))
    (format stream "Proposed HyperDoc page fragment~%~A~%"
            (relation-topic-proposal-page-fragment proposal))
    (format stream "Advisory FedWiki twin delta~%~A"
            (relation-topic-proposal-fedwiki-twin-delta proposal))))

(defun make-relation-topic-proposal (relation)
  (let* ((title (relation-topic-title-candidate relation))
         (existing (existing-topic-by-exact-title title))
         (merge-status (if existing
                           :merge-into-existing-topic
                           :new-topic))
         (proposed-id (if existing
                          (id-of existing)
                          (relation-topic-id-candidate relation))))
    (make-instance 'relation-topic-proposal
                   :relation relation
                   :proposed-id proposed-id
                   :proposed-title title
                   :proposed-summary (relation-topic-summary-candidate relation)
                   :proposed-references (relation-topic-reference-candidates relation)
                   :existing-topic existing
                   :merge-status merge-status)))

(defgeneric promote-relation-to-topic-proposal (relation))

(defmethod promote-relation-to-topic-proposal ((relation dom-relation-annotation))
  (make-relation-topic-proposal relation))

(defmethod promote-relation-to-topic-proposal ((relation git-merge-intent))
  (make-relation-topic-proposal relation))

(defun example-association-topics-relation ()
  (make-instance
   'dom-relation-annotation
   :id "dom-relation/example-association-topics"
   :title "Association: stable subject identity -> mutable title"
   :summary
   "Association between Stable subject identity and Mutable title within Association Topics for Stable Identity and Mutable Titles."
   :context-object nil
   :context-view-title "Content"
   :source-anchor
   (make-instance 'dom-annotation-anchor
                  :provider-kind "dom-v1"
                  :strategy "semantic-heading"
                  :value "stable-subject-identity"
                  :label "Stable subject identity"
                  :page-title
                  "Association Topics for Stable Identity and Mutable Titles")
   :target-anchor
   (make-instance 'dom-annotation-anchor
                  :provider-kind "dom-v1"
                  :strategy "semantic-heading"
                  :value "mutable-title"
                  :label "Mutable title"
                  :page-title
                  "Association Topics for Stable Identity and Mutable Titles")
   :relation-kind "association topics"
   :note
   "Example relation used to demonstrate reviewed promotion into a durable topic proposal without auto-writing topics.lisp or page files."))
