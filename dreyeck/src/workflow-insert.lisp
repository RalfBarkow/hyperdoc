;;;; INSERT-OWNED-FORM: a new top-level form in an existing authority.
;;;;
;;;; Three source-authoring operations, with different preconditions and
;;;; different things to protect:
;;;;
;;;;   path absent                   CREATE-LISP-SOURCE
;;;;   path exists, form changes     structural REPLACE (PLAN-CHANGE)
;;;;   path exists, form is new      structural INSERT  (this file)
;;;;
;;;; REPLACE binds itself to exactly one pre-existing form with the key it
;;;; is about to write. An insertion has no such predecessor, so it cannot
;;;; be expressed as a replacement without lying about what it does. What
;;;; it must protect instead is everything it does not touch: every form
;;;; that was already there, in the order it was in.
;;;;
;;;; The structural writing itself is the pinned editor's
;;;; INSERT-TOPLEVEL-EXPRESSION-BEFORE-IN-FILE. Nothing here re-implements
;;;; it; this is the repository-level plan and verification it lacked.

(in-package #:dreyeck/workflow/authoring)

(defclass insertion-plan ()
  ((system :initarg :system :reader insertion-plan-system)
   (path :initarg :path :reader insertion-plan-path)
   (key :initarg :key :reader insertion-plan-key)
   (proposed :initarg :proposed :reader insertion-plan-proposed)
   (anchor-key :initarg :anchor-key :reader insertion-plan-anchor-key)
   (before :initarg :before :reader insertion-plan-before)
   (source :initarg :source :reader insertion-plan-source))
  (:documentation
   "One new top-level form proposed for an existing source authority.
BEFORE is the whole form sequence as observed, because the sequence is
what the operation has to leave alone."))

(defun plan-insertion (system-name path key proposed anchor-key)
  "Observe an owned authority and propose one new top-level form.
Writes nothing and evaluates nothing."
  (let* ((system (asdf:find-system system-name))
         (authority (truename path))
         (source (uiop:read-file-string authority :external-format :utf-8))
         (forms (wf:source-forms source)))
    (unless (member authority (wf::owned-paths system)
                    :key #'truename :test #'equal)
      (error "~A is not owned by ASDF system ~A." authority system-name))
    (unless (equal key (wf:form-key proposed))
      (error "Proposed form does not carry the key ~S it is planned under."
             key))
    (unless (zerop (count key forms :key #'wf:form-key :test #'equal))
      (error "~S already occurs in ~A; this is a replacement, not an insertion."
             key authority))
    (unless (= 1 (count anchor-key forms :key #'wf:form-key :test #'equal))
      (error "Anchor ~S must occur exactly once in ~A." anchor-key authority))
    (make-instance 'insertion-plan
                   :system (asdf:component-name system)
                   :path authority :key key
                   :proposed (copy-tree proposed)
                   :anchor-key anchor-key
                   :before (copy-tree forms)
                   :source source)))

(defun insertion-plan-status (plan)
  (if (string= (insertion-plan-source plan)
               (uiop:read-file-string (insertion-plan-path plan)
                                      :external-format :utf-8))
      :needs-insertion
      :stale-authority))

(defun %inserted-sequence (before proposed index)
  "What the sequence must look like afterwards: nothing but one more form."
  (append (subseq before 0 index) (list proposed) (subseq before index)))

(defun verify-insertion (plan index after)
  "The postcondition, read back from disk and checked against the plan.
Separate from the writing so that a deliberately damaged AFTER can be
offered to it; a check that only ever sees correct input proves nothing."
  (let ((key (insertion-plan-key plan))
        (anchor-key (insertion-plan-anchor-key plan))
        (expected (%inserted-sequence (insertion-plan-before plan)
                                      (insertion-plan-proposed plan) index)))
    (unless (= 1 (count key after :key #'wf:form-key :test #'equal))
      (error "~S does not occur exactly once after the insertion." key))
    (unless (= 1 (count anchor-key after :key #'wf:form-key :test #'equal))
      (error "The anchor did not survive the insertion."))
    (unless (= (length expected) (length after))
      (error "The authority gained or lost more than one form."))
    (unless (every #'wf:form-equal expected after)
      (error "A form other than the inserted one changed."))
    (unless (member (insertion-plan-path plan)
                    (wf::owned-paths (asdf:find-system
                                     (insertion-plan-system plan)))
                    :key #'truename :test #'equal)
      (error "The authority is no longer owned by its system."))
    after))

(defgeneric insert-owned-form (plan capability)
  (:documentation
   "Insert one new top-level form before its anchor, and prove the rest
of the authority survived unchanged."))

(defmethod insert-owned-form ((plan insertion-plan)
                              (capability authoring-environment))
  (unless (eq :needs-insertion (insertion-plan-status plan))
    (error "Authority changed since it was observed."))
  (multiple-value-bind (before code)
      (wf:source-forms (insertion-plan-path plan))
    (let* ((tlfs (hv:top-level-forms-of code))
           (anchors (remove-if-not
                     (lambda (tlf)
                       (equal (insertion-plan-anchor-key plan)
                              (wf:form-key (hv:s-exp tlf))))
                     tlfs))
           (proposed (insertion-plan-proposed plan))
           (key (insertion-plan-key plan)))
      (unless (= 1 (length anchors))
        (error "Anchor ~S is no longer unique." (insertion-plan-anchor-key plan)))
      (unless (zerop (count key before :key #'wf:form-key :test #'equal))
        (error "~S appeared in the authority since it was observed." key))
      (let ((index (position (first anchors) tlfs)))
        ;; The pinned editor does the writing and takes the anchor's own
        ;; package; nothing here re-implements the insertion itself.
        (hv::insert-toplevel-expression-before-in-file
         (insertion-plan-path plan) code (first anchors) proposed)
        ;; The postcondition is checked against what is on disk.
        (verify-insertion plan index
                          (wf:source-forms (insertion-plan-path plan)))))))
