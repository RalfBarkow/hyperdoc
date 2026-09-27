;;;; REMOVE-OWNED-FORM: one top-level form out of an existing authority.
;;;;
;;;; The fourth source-authoring operation, beside the three that were:
;;;;
;;;;   path absent                   CREATE-LISP-SOURCE
;;;;   path exists, form changes     structural REPLACE
;;;;   path exists, form is new      structural INSERT
;;;;   path exists, form goes        structural REMOVE  (this file)
;;;;
;;;; Without it a definition whose responsibility had left the architecture
;;;; could only stay, dead or renamed to mean something else, or be cut out
;;;; as text. Removal names its target the way insertion and replacement do,
;;;; by structural key, and must protect the same thing insertion protects:
;;;; everything it does not touch.
;;;;
;;;; The pinned editor has no removal primitive. The deletion here is of
;;;; exactly the range the plan observed, in exactly the source it observed:
;;;; the form's own source, and the whitespace after it through the end of
;;;; its last line. Comments are not forms and stay; a comment that
;;;; belonged to the form is removed separately, as a range no form owns.
;;;; The result is written beside the authority, checked as a whole, and
;;;; only then installed.

(in-package #:dreyeck/workflow/authoring)

(defclass removal-plan ()
  ((system :initarg :system :reader removal-plan-system)
   (path :initarg :path :reader removal-plan-path)
   (key :initarg :key :reader removal-plan-key)
   (index :initarg :index :reader removal-plan-index)
   (before :initarg :before :reader removal-plan-before)
   (range :initarg :range :reader removal-plan-range)
   (source :initarg :source :reader removal-plan-source))
  (:documentation
   "One top-level form proposed for removal from an existing source
authority. BEFORE is the whole form sequence as observed, INDEX the removed
form's place in it, RANGE the bytes that go and SOURCE the authority as
observed; the postcondition is stated against all four."))

(defun %removal-range (source form)
  "FORM's source, and the whitespace after it through its last newline, so
that removing a form does not leave its blank lines behind."
  (destructuring-bind (start . end) (concrete-syntax-tree:source (hv:cst-of form))
    (let* ((run-end (or (position-if-not (lambda (character)
                                           (member character '(#\Space #\Tab #\Newline #\Return)))
                                         source :start end)
                        (length source)))
           (last-newline (position #\Newline source :start end :end run-end :from-end t)))
      (cons start (if last-newline (1+ last-newline) end)))))

(defun plan-removal (system-name path key)
  "Observe an owned authority and propose removing the one top-level form
KEY names. Writes nothing and evaluates nothing."
  (let* ((system (asdf:find-system system-name))
         (authority (truename path))
         (source (uiop:read-file-string authority :external-format :utf-8)))
    (unless (member authority (wf::owned-paths system)
                    :key #'truename :test #'equal)
      (error "~A is not owned by ASDF system ~A." authority system-name))
    (unless key
      (error "A form without a structural key cannot be named for removal."))
    (multiple-value-bind (code recovered) (hv:parse-lisp-code source)
      (when recovered
        (error "The authority needs reader recovery; refusing to plan in it."))
      (let* ((tlfs (hv:top-level-forms-of code))
             (before (wf:source-forms source))
             (matches (remove-if-not (lambda (tlf) (equal key (wf:form-key (hv:s-exp tlf))))
                                     tlfs)))
        (unless (= 1 (length matches))
          (error "~S must name exactly one top-level form in ~A, found ~D."
                 key authority (length matches)))
        (unless (= (length tlfs) (length before))
          (error "The authority's forms and their sources disagree."))
        (make-instance 'removal-plan
                       :system (asdf:component-name system)
                       :path authority :key key
                       :index (position (first matches) tlfs)
                       :before (copy-tree before)
                       :range (%removal-range source (first matches))
                       :source source)))))

(defun removal-plan-status (plan)
  (if (string= (removal-plan-source plan)
               (uiop:read-file-string (removal-plan-path plan)
                                      :external-format :utf-8))
      :needs-removal
      :stale-authority))

(defun verify-removal (plan after-source)
  "The postcondition, checked against the plan. Separate from the writing
so that a deliberately damaged AFTER-SOURCE can be offered to it."
  (multiple-value-bind (code recovered) (hv:parse-lisp-code after-source)
    (declare (ignore code))
    (when recovered
      (error "The result needs reader recovery.")))
  (let* ((key (removal-plan-key plan))
         (before (removal-plan-before plan))
         (index (removal-plan-index plan))
         (expected (append (subseq before 0 index) (subseq before (1+ index))))
         (after (wf:source-forms after-source)))
    (unless (zerop (count key after :key #'wf:form-key :test #'equal))
      (error "~S still occurs after the removal." key))
    (unless (= (length expected) (length after))
      (error "The authority lost or gained a form other than the removed one."))
    (unless (every #'wf:form-equal expected after)
      (error "A form other than the removed one changed."))
    (unless (equal (mapcar #'wf:form-key expected) (mapcar #'wf:form-key after))
      (error "The remaining forms' identities changed."))
    (unless (string= after-source
                     (%spliced (removal-plan-source plan) (removal-plan-range plan) ""))
      (error "Bytes outside the removed range changed."))
    (unless (member (removal-plan-path plan)
                    (wf::owned-paths (asdf:find-system (removal-plan-system plan)))
                    :key #'truename :test #'equal)
      (error "The authority is no longer owned by its system."))
    after))

(defun remove-from-candidate (plan)
  "Write, check and install: the authority is replaced only at the end.
A candidate that fails any check is removed and the authority has never
been written to."
  (unless (eq :needs-removal (removal-plan-status plan))
    (error "Authority changed since it was observed."))
  (let* ((authority (removal-plan-path plan))
         (candidate (%candidate-pathname authority))
         (installed nil))
    (unwind-protect
         (progn
           (uiop:with-output-file (stream candidate :external-format :utf-8)
             (write-string (%spliced (removal-plan-source plan) (removal-plan-range plan) "")
                           stream))
           (let ((after (verify-removal
                         plan (uiop:read-file-string candidate :external-format :utf-8))))
             ;; A system definition must stay readable where ASDF reads it.
             (when (string-equal "asd" (pathname-type authority))
               (let ((counted (read-in-target-reader-context candidate)))
                 (unless (eql counted (length after))
                   (error "The consumer reads ~D forms where the authority has ~D."
                          counted (length after)))))
             (rename-file candidate authority)
             (setf installed t)
             after))
      (unless installed
        (ignore-errors (delete-file candidate))))))

(defgeneric remove-owned-form (plan capability)
  (:documentation
   "Remove one top-level form, prove every other form and every other
byte of the authority survived unchanged and that it still reads, before
the result replaces the authority."))

(defmethod remove-owned-form ((plan removal-plan)
                              (capability authoring-environment))
  (remove-from-candidate plan))
