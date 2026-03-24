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

(defclass relation-topic-patch-plan ()
  ((proposal :initarg :proposal :reader proposal-of)
   (topics-target-path :initarg :topics-target-path
                       :reader topics-target-path-of)
   (topics-action :initarg :topics-action :reader topics-action-of)
   (existing-topic :initarg :existing-topic
                   :reader existing-topic-of
                   :initform nil)
   (page-target-path :initarg :page-target-path
                     :reader page-target-path-of)
   (page-action :initarg :page-action :reader page-action-of)
   (topics-payload :initarg :topics-payload :reader topics-payload-of)
   (page-payload :initarg :page-payload :reader page-payload-of)))

(defclass approved-relation-topic-patch-application ()
  ((patch-plan :initarg :patch-plan :reader patch-plan-of)
   (applied-paths :initarg :applied-paths :reader applied-paths-of)
   (actions-performed :initarg :actions-performed :reader actions-performed-of)
   (applied-payloads :initarg :applied-payloads :reader applied-payloads-of)
   (approval-token :initarg :approval-token :reader approval-token-of)
   (timestamp :initarg :timestamp :reader timestamp-of)
   (status :initarg :status :reader status-of)))

(define-condition relation-topic-patch-approval-required (error)
  ((patch-plan :initarg :patch-plan :reader patch-plan-of)
   (approval-token :initarg :approval-token :reader approval-token-of))
  (:report
   (lambda (condition stream)
     (format stream
             "Applying ~A requires an explicit valid approval token. No mutation was performed."
             (title-of (patch-plan-of condition))))))

(defmethod print-object ((object relation-topic-proposal) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (proposed-title-of object))))

(defmethod print-object ((object relation-topic-patch-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (proposed-title-of (proposal-of object)))))

(defmethod print-object ((object approved-relation-topic-patch-application)
                         stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defmethod id-of ((proposal relation-topic-proposal))
  (proposed-id-of proposal))

(defmethod title-of ((proposal relation-topic-proposal))
  (proposed-title-of proposal))

(defmethod summary-of ((proposal relation-topic-proposal))
  (proposed-summary-of proposal))

(defmethod title-of ((plan relation-topic-patch-plan))
  (format nil "Patch plan for ~A"
          (proposed-title-of (proposal-of plan))))

(defmethod summary-of ((plan relation-topic-patch-plan))
  (format nil
          "Collision-aware reviewed patch plan for ~A targeting ~A and ~A."
          (proposed-title-of (proposal-of plan))
          (topics-target-path-of plan)
          (page-target-path-of plan)))

(defmethod title-of ((application approved-relation-topic-patch-application))
  (format nil "Applied patch plan for ~A"
          (proposed-title-of
           (proposal-of (patch-plan-of application)))))

(defmethod summary-of ((application approved-relation-topic-patch-application))
  (format nil
          "Approval-gated application result for ~A with status ~A."
          (proposed-title-of
           (proposal-of (patch-plan-of application)))
          (status-of application)))

(defparameter *generic-relation-topic-kinds*
  '("association"
    "association relation"
    "generic relation"
    "link"
    "relation"
    "related"
    "unclassified association"
    "unclassified relation"))

(defparameter *relation-topic-patch-approval-token*
  "APPROVE-RELATION-TOPIC-PATCH-PLAN")

(defparameter *relation-topic-patch-repo-root*
  (uiop:ensure-directory-pathname
   (asdf:system-source-directory :hyperdoc)))

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

(defun relation-topic-patch-repo-root ()
  (uiop:ensure-directory-pathname *relation-topic-patch-repo-root*))

(defun relation-topic-resolve-target-pathname (path)
  (let ((pathname (pathname path)))
    (if (uiop:absolute-pathname-p pathname)
        pathname
        (merge-pathnames pathname
                         (relation-topic-patch-repo-root)))))

(defun relation-topic-read-file-string (path)
  (uiop:read-file-string (relation-topic-resolve-target-pathname path)))

(defun relation-topic-write-file-string (path content &key (if-exists :supersede))
  (let ((pathname (relation-topic-resolve-target-pathname path)))
    (uiop:ensure-all-directories-exist (list pathname))
    (with-open-file (stream pathname
                            :direction :output
                            :if-exists if-exists
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (write-string content stream))
    pathname))

(defun relation-topic-form-make-topic-call (form)
  (cond
    ((atom form)
     nil)
    ((and (consp form)
          (symbolp (first form))
          (string= (symbol-name (first form))
                   "MAKE-TOPIC"))
     form)
    (t
     (or (relation-topic-form-make-topic-call (car form))
         (relation-topic-form-make-topic-call (cdr form))))))

(defun relation-topic-title-of-top-level-form (form)
  (let ((call (relation-topic-form-make-topic-call form)))
    (when call
      (getf (rest call) :title))))

(defun relation-topic-factory-bounds-by-title (path title)
  (let ((pathname (relation-topic-resolve-target-pathname path))
        (matches '()))
    (with-open-file (stream pathname :direction :input :external-format :utf-8)
      (loop with eof = (gensym "EOF")
            for start = (file-position stream)
            for form = (read stream nil eof)
            until (eq form eof)
            for end = (file-position stream)
            when (equal (relation-topic-title-of-top-level-form form)
                        title)
              do (push (list :start start :end end :form form)
                       matches)))
    (setf matches (nreverse matches))
    (cond
      ((null matches)
       (error "No topic factory with exact :title ~S found in ~A."
              title
              path))
      ((cdr matches)
       (error "Multiple topic factories with exact :title ~S found in ~A."
              title
              path))
      (t
       (first matches)))))

(defun relation-topic-replace-range (content start end replacement)
  (concatenate 'string
               (subseq content 0 start)
               replacement
               (subseq content end)))

(defun relation-topic-topics-lisp-payload (proposal)
  (relation-topic-proposal-factory-form proposal))

(defun relation-topic-page-file-path-candidate (proposal)
  (format nil "hyperdoc/~A.html" (proposed-title-of proposal)))

(defun relation-topic-page-file-exists-p
    (proposal &key (page-target-path (relation-topic-page-file-path-candidate
                                      proposal)))
  (not (null (probe-file (relation-topic-resolve-target-pathname
                         page-target-path)))))

(defun relation-topic-page-payload (proposal)
  (relation-topic-proposal-page-fragment proposal))

(defun relation-topic-patch-instructions (plan)
  (with-output-to-string (stream)
    (case (topics-action-of plan)
      (:edit-existing-factory
       (format stream
               "Edit ~A in place because an exact-title collision already exists for ~S.~%"
               (topics-target-path-of plan)
               (proposed-title-of (proposal-of plan))))
      (:append-new-factory
       (format stream
               "Append the new topic factory to ~A at the appropriate authored location after review.~%"
               (topics-target-path-of plan))))
    (case (page-action-of plan)
      (:edit-existing-page
       (format stream
               "Edit the existing page file ~A in place.~%"
               (page-target-path-of plan)))
      (:create-new-page
       (format stream
               "Create the new page file ~A from the proposed payload.~%"
               (page-target-path-of plan)))
      (:no-page-needed
       (format stream
               "No page file is required yet; keep ~A as an optional authored page target only if the relation deserves a durable page.~%"
               (page-target-path-of plan))))
    (format stream
            "No automatic mutation has been performed.~%")))

(defun make-relation-topic-patch-plan
    (proposal
     &key
       (topics-target-path "hyperdoc/topics.lisp")
       (page-target-path (relation-topic-page-file-path-candidate proposal)))
  (let* ((existing (existing-topic-of proposal))
         (topics-action (if existing
                            :edit-existing-factory
                            :append-new-factory))
         (page-exists-p
           (relation-topic-page-file-exists-p
            proposal
            :page-target-path page-target-path))
         (page-action (cond
                        (page-exists-p
                         :edit-existing-page)
                        (existing
                         :no-page-needed)
                        (t
                         :create-new-page))))
    (make-instance 'relation-topic-patch-plan
                   :proposal proposal
                   :topics-target-path topics-target-path
                   :topics-action topics-action
                   :existing-topic existing
                   :page-target-path page-target-path
                   :page-action page-action
                   :topics-payload (relation-topic-topics-lisp-payload proposal)
                   :page-payload (relation-topic-page-payload proposal))))

(defun patch-plan-approval-token-valid-p (approval-token)
  (and (stringp approval-token)
       (string= approval-token
                *relation-topic-patch-approval-token*)))

(defun apply-topics-lisp-patch-plan (plan)
  (let* ((target-path (topics-target-path-of plan))
         (content (relation-topic-read-file-string target-path))
         (payload (topics-payload-of plan))
         (new-content
           (case (topics-action-of plan)
             (:edit-existing-factory
              (destructuring-bind (&key start end &allow-other-keys)
                  (relation-topic-factory-bounds-by-title
                   target-path
                   (proposed-title-of (proposal-of plan)))
                (relation-topic-replace-range
                 content
                 start
                 end
                 (format nil "~A~%" payload))))
             (:append-new-factory
              (format nil "~A~2%~A~%"
                      (string-right-trim '(#\Newline #\Return) content)
                      payload))
             (otherwise
              (error "Unsupported topics.lisp action ~S."
                     (topics-action-of plan))))))
    (relation-topic-write-file-string target-path new-content)
    (list :path target-path
          :action (topics-action-of plan)
          :payload payload)))

(defun apply-page-patch-plan (plan)
  (case (page-action-of plan)
    (:no-page-needed
     (list :path (page-target-path-of plan)
           :action :no-page-needed
           :payload nil))
    (:edit-existing-page
     (relation-topic-write-file-string (page-target-path-of plan)
                                       (page-payload-of plan))
     (list :path (page-target-path-of plan)
           :action :edit-existing-page
           :payload (page-payload-of plan)))
    (:create-new-page
     (relation-topic-write-file-string (page-target-path-of plan)
                                       (page-payload-of plan)
                                       :if-exists :error)
     (list :path (page-target-path-of plan)
           :action :create-new-page
           :payload (page-payload-of plan)))
    (otherwise
     (error "Unsupported page action ~S."
            (page-action-of plan)))))

(defun apply-relation-topic-patch-plan (plan approval-token)
  (unless (patch-plan-approval-token-valid-p approval-token)
    (error 'relation-topic-patch-approval-required
           :patch-plan plan
           :approval-token approval-token))
  (let* ((topics-result (apply-topics-lisp-patch-plan plan))
         (page-result (apply-page-patch-plan plan))
         (applied-results
           (remove nil
                   (list topics-result
                         (unless (eq (getf page-result :action)
                                     :no-page-needed)
                           page-result))))
         (applied-paths (mapcar (lambda (entry)
                                  (getf entry :path))
                                applied-results))
         (actions-performed
           (list (getf topics-result :action)
                 (getf page-result :action)))
         (applied-payloads
           (remove nil
                   (list (cons :topics (getf topics-result :payload))
                         (when (getf page-result :payload)
                           (cons :page (getf page-result :payload)))))))
    (make-instance 'approved-relation-topic-patch-application
                   :patch-plan plan
                   :applied-paths applied-paths
                   :actions-performed actions-performed
                   :applied-payloads applied-payloads
                   :approval-token approval-token
                   :timestamp (get-universal-time)
                   :status :applied)))

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
