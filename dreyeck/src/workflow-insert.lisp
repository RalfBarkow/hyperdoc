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

;;; Target readability
;;;
;;; The first real use of this operation inserted a structurally correct
;;; form and left dreyeck.asd unreadable. The proposed form had been built
;;; in the authoring package, so one lambda-list symbol serialized as
;;; DREYECK/WORKFLOW/AUTHORING::OPERATION, and ASDF's reader has no such
;;; package. Every structural postcondition held; the authority was
;;; broken anyway.
;;;
;;; Structural integrity and target readability are different properties.
;;; The second one cannot be checked in this image, because the authoring
;;; packages exist here and the symbol would read. It has to be checked
;;; where the ordinary consumer reads: a fresh process with nothing but
;;; ASDF, in the binding ASDF itself establishes for a system definition
;;; (WITH-STANDARD-IO-SYNTAX, *PACKAGE* ASDF-USER, the file's directory as
;;; *DEFAULT-PATHNAME-DEFAULTS*).

(defun %target-reader-program (path)
  "The whole form is read before REQUIRE runs, so it may not name a symbol
from ASDF or UIOP; that is the same class of mistake this check exists to
catch."
  (format nil "(progn (require :asdf)
 (with-standard-io-syntax
  (let* ((file (pathname ~S))
         (*package* (find-package :asdf-user))
         (*default-pathname-defaults*
          (make-pathname :name nil :type nil :version nil :defaults file)))
    (with-open-file (stream file :external-format :utf-8)
      (format t \"TARGET-READABLE ~~D~~%\"
              (loop for form = (read stream nil :eof)
                    until (eq form :eof) count t))))))"
          (namestring path)))

(defun read-in-target-reader-context (path)
  "How many top-level forms PATH has when its ordinary consumer reads it.
Signals if the consumer cannot read it at all."
  (multiple-value-bind (output errors status)
      (uiop:run-program (list "env" "-u" "HYPERDOC_WORKFLOW_EDITOR_SOURCE"
                              "-u" "HYPERDOC_WORKFLOW_EDITOR_COMMIT"
                              "-u" "HYPERDOC_RUNTIME_SOURCE_REGISTRY"
                              "sbcl" "--noinform" "--no-userinit"
                              "--non-interactive"
                              "--eval" (%target-reader-program path))
                        :output :string :error-output :string
                        :ignore-error-status t)
    (let ((marker (search "TARGET-READABLE " output)))
      (unless (and (zerop status) marker)
        (error "Candidate is not readable by its ordinary consumer:~%~A"
               (if (plusp (length errors)) errors output)))
      (values (parse-integer output :start (+ marker (length "TARGET-READABLE "))
                                    :junk-allowed t)
              output))))

(defun %candidate-pathname (path)
  "Beside the authority, so the install is a rename within one directory."
  (make-pathname :type (format nil "~A-candidate-~D" (pathname-type path)
                               (random 1000000))
                 :defaults path))

(defun insert-into-candidate (plan)
  "Write, check and install: the authority is replaced only at the end.
A candidate that fails any check is removed and the authority has never
been written to."
  (unless (eq :needs-insertion (insertion-plan-status plan))
    (error "Authority changed since it was observed."))
  (let* ((authority (insertion-plan-path plan))
         (candidate (%candidate-pathname authority))
         (installed nil))
    (unwind-protect
         (progn
           (uiop:copy-file authority candidate)
           (multiple-value-bind (before code) (wf:source-forms candidate)
             (let* ((tlfs (hv:top-level-forms-of code))
                    (anchors (remove-if-not
                              (lambda (tlf)
                                (equal (insertion-plan-anchor-key plan)
                                       (wf:form-key (hv:s-exp tlf))))
                              tlfs))
                    (proposed (insertion-plan-proposed plan))
                    (key (insertion-plan-key plan)))
               (unless (= 1 (length anchors))
                 (error "Anchor ~S is no longer unique."
                        (insertion-plan-anchor-key plan)))
               (unless (zerop (count key before :key #'wf:form-key :test #'equal))
                 (error "~S appeared in the authority since it was observed."
                        key))
               (let ((index (position (first anchors) tlfs)))
                 ;; The pinned editor does the writing, on the candidate.
                 (hv::insert-toplevel-expression-before-in-file
                  candidate code (first anchors) proposed)
                 (let ((after (wf:source-forms candidate)))
                   (verify-insertion plan index after)
                   ;; And the consumer must be able to read what was written.
                   (when (string-equal "asd" (pathname-type authority))
                     ;; Only a system definition is read by ASDF, in
                     ;; ASDF-USER with nothing else loaded. An ordinary
                     ;; source file's consumer is the loader, after the
                     ;; file's own DEFPACKAGE has run, so reading it that
                     ;; way would reject perfectly good source for naming
                     ;; a package the check never gave it.
                     (let ((counted (read-in-target-reader-context candidate)))
                       (unless (eql counted (length after))
                         (error "The consumer reads ~D forms where the ~
authority has ~D." counted (length after)))))
                   (rename-file candidate authority)
                   (setf installed t)
                   after)))))
      (unless installed
        (ignore-errors (delete-file candidate))))))

(defgeneric insert-owned-form (plan capability)
  (:documentation
   "Insert one new top-level form before its anchor, prove the rest of
the authority survived unchanged, and prove the result is readable by the
authority's ordinary consumer before it replaces the authority."))

(defmethod insert-owned-form ((plan insertion-plan)
                              (capability authoring-environment))
  (insert-into-candidate plan))
