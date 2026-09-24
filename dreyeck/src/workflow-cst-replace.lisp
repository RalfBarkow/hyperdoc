;;;; Targeted CST-source replacement inside one owned top-level form.
;;;;
;;;; Persisted Lisp source has two structures, and until now only one of
;;;; them was protected:
;;;;
;;;;   reader structure    the S-expressions a form denotes
;;;;   concrete syntax     tokens, whitespace, comments, spelling
;;;;
;;;; PLAN-CHANGE binds itself to a whole top-level form and writes a
;;;; serialization of the proposed data. Measured on a fixture, that turns
;;;;
;;;;   (defun probed ()
;;;;     ;; This comment explains why the value is seven.
;;;;     (let ((x 7))   ; trailing note
;;;;       x))
;;;;
;;;; into
;;;;
;;;;   (defun probed nil (let ((x 8)) x))
;;;;
;;;; Both comments gone, () respelled, the shape lost. For forms whose
;;;; comments record reasons established by earlier falsification, that is
;;;; the worst possible trade. Whole-form replacement is not deprecated --
;;;; it remains right where reserializing the target form is the intent --
;;;; but it is not the tool for a targeted change inside such a form.
;;;;
;;;; The pinned editor already has what is needed. Given an INNER CST node,
;;;; HV::REPLACE-CST-SOURCE-IN-FILE splices text over exactly that node's
;;;; source range and copies every other byte from the original. The
;;;; earlier failure was the granularity of the target, not the editor.
;;;;
;;;; What was missing is this: a repository-level plan that says which
;;;; subexpression, in which owned form, and proves afterwards that
;;;; nothing else moved.

(in-package #:dreyeck/workflow/authoring)

(defclass cst-source-replacement-plan ()
  ((system :initarg :system :reader replacement-plan-system)
   (path :initarg :path :reader replacement-plan-path)
   (key :initarg :key :reader replacement-plan-key)
   (expected :initarg :expected :reader replacement-plan-expected)
   (replacement :initarg :replacement :reader replacement-plan-replacement)
   (expected-value :initarg :expected-value
                   :reader replacement-plan-expected-value)
   (range :initarg :range :reader replacement-plan-range)
   (source :initarg :source :reader replacement-plan-source))
  (:documentation
   "One subexpression of one owned form, and the text proposed for it.
RANGE is the observed source range of the target; SOURCE is the whole
authority as observed. Together they are what the postcondition compares
against, byte for byte."))

(defun %cst-nodes (cst)
  "Every node of CST that owns a source range, outermost first.
A node without a range cannot be spliced, so it cannot be a target."
  (let ((nodes nil))
    (labels ((walk (node)
               (when (typep node 'concrete-syntax-tree:cst)
                 (when (concrete-syntax-tree:source node)
                   (push node nodes))
                 (when (typep node 'concrete-syntax-tree:cons-cst)
                   (walk (concrete-syntax-tree:first node))
                   (walk (concrete-syntax-tree:rest node))))))
      (walk cst))
    (nreverse nodes)))

(defun %matching-nodes (cst expected)
  "The nodes of CST whose current Lisp value is EXPECTED.
The target is addressed by what it is, not by a path of child indices:
an index shifts whenever a neighbour changes, and the point of this
operation is that neighbours do not change."
  (remove-if-not (lambda (node)
                   (handler-case (wf:form-equal (hv:s-exp node) expected)
                     (error () nil)))
                 (%cst-nodes cst)))

(defun %owning-form (code key)
  (let ((matches (remove-if-not
                  (lambda (form) (equal key (wf:form-key (hv:s-exp form))))
                  (hv:top-level-forms-of code))))
    (unless (= 1 (length matches))
      (error "~S must name exactly one top-level form, found ~D."
             key (length matches)))
    (first matches)))

(defun plan-cst-source-replacement
    (system-name path key expected replacement-source expected-value)
  "Observe one subexpression of one owned form and propose text for it.
Writes nothing. REPLACEMENT-SOURCE is text because that is what the
low-level editor accepts; EXPECTED-VALUE is what it must read as, and is
checked afterwards rather than trusted."
  (let* ((system (asdf:find-system system-name))
         (authority (truename path))
         (source (uiop:read-file-string authority :external-format :utf-8))
         (code (hv:parse-lisp-code authority))
         (form (%owning-form code key))
         (matches (%matching-nodes (hv:cst-of form) expected)))
    (unless (member authority (wf::owned-paths system)
                    :key #'truename :test #'equal)
      (error "~A is not owned by ASDF system ~A." authority system-name))
    (unless (stringp replacement-source)
      (error "The replacement must be source text, got ~S."
             replacement-source))
    (unless (= 1 (length matches))
      ;; Never pick one occurrence. An ambiguous address is an error, not
      ;; an invitation to guess.
      (error "~S occurs ~D times inside ~S; a target must occur exactly once."
             expected (length matches) key))
    (make-instance 'cst-source-replacement-plan
                   :system (asdf:component-name system)
                   :path authority :key key
                   :expected (copy-tree expected)
                   :replacement replacement-source
                   :expected-value (copy-tree expected-value)
                   :range (concrete-syntax-tree:source (first matches))
                   :source source)))

(defun cst-source-replacement-status (plan)
  (if (string= (replacement-plan-source plan)
               (uiop:read-file-string (replacement-plan-path plan)
                                      :external-format :utf-8))
      :needs-replacement
      :stale-authority))

(defun %spliced (source range replacement)
  (concatenate 'string (subseq source 0 (car range)) replacement
               (subseq source (cdr range))))

(defun verify-cst-source-replacement (plan after-source)
  "The postcondition: only the targeted range may differ.
This one comparison subsumes the separate worries about comments,
whitespace and token spelling. Any of them changing outside the target
changes a byte, and a byte is what is compared."
  (let* ((range (replacement-plan-range plan))
         (expected-source (%spliced (replacement-plan-source plan) range
                                    (replacement-plan-replacement plan))))
    (unless (string= expected-source after-source)
      (error "Bytes outside the targeted range changed."))
    (let* ((code (hv:parse-lisp-code after-source))
           (form (%owning-form code (replacement-plan-key plan)))
           (written (subseq after-source (car range)
                            (+ (car range)
                               (length (replacement-plan-replacement plan)))))
           (value (handler-case
                      (let ((*package* (hv:package-of form))
                            (*read-eval* nil))
                        (read-from-string written))
                    (error (condition)
                      (error "The replacement does not read: ~A" condition)))))
      (unless (wf:form-equal value (replacement-plan-expected-value plan))
        (error "The replacement reads as ~S, not the expected ~S."
               value (replacement-plan-expected-value plan)))
      (unless (equal (replacement-plan-key plan) (wf:form-key (hv:s-exp form)))
        (error "The owning form's structural key changed."))
      after-source)))

(defun %other-form-sources (source code key)
  "The exact text of every top-level form except the owning one."
  (loop for form in (hv:top-level-forms-of code)
        for range = (concrete-syntax-tree:source (hv:cst-of form))
        unless (equal key (wf:form-key (hv:s-exp form)))
          collect (subseq source (car range) (cdr range))))

(defgeneric replace-owned-cst-source (plan capability)
  (:documentation
   "Replace one subexpression's source and prove nothing else moved."))

(defmethod replace-owned-cst-source ((plan cst-source-replacement-plan)
                                     (capability authoring-environment))
  (unless (eq :needs-replacement (cst-source-replacement-status plan))
    (error "Authority changed since it was observed."))
  (let* ((authority (replacement-plan-path plan))
         (candidate (%candidate-pathname authority))
         (before (replacement-plan-source plan))
         (before-code (hv:parse-lisp-code before))
         (installed nil))
    (unwind-protect
         (progn
           (uiop:copy-file authority candidate)
           (let* ((code (hv:parse-lisp-code candidate))
                  (form (%owning-form code (replacement-plan-key plan)))
                  (matches (%matching-nodes (hv:cst-of form)
                                            (replacement-plan-expected plan))))
             (unless (= 1 (length matches))
               (error "~S no longer occurs exactly once inside ~S."
                      (replacement-plan-expected plan)
                      (replacement-plan-key plan)))
             ;; The editor splices the node's range and copies the rest of
             ;; the file verbatim; it also refuses a result that needs
             ;; reader recovery, and writes through a temporary file.
             (hv::replace-cst-source-in-file
              candidate code (first matches)
              (replacement-plan-replacement plan))
             (let ((after (uiop:read-file-string candidate
                                                 :external-format :utf-8)))
               (verify-cst-source-replacement plan after)
               (unless (equal (%other-form-sources before before-code
                                                   (replacement-plan-key plan))
                              (%other-form-sources
                               after (hv:parse-lisp-code after)
                               (replacement-plan-key plan)))
                 (error "A top-level form other than the owning one changed."))
               (rename-file candidate authority)
               (setf installed t)
               after)))
      (unless installed
        (ignore-errors (delete-file candidate))))))
