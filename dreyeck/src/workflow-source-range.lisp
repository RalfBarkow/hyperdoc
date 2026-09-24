;;;; Targeted replacement of source that no Lisp form owns.
;;;;
;;;; The parsed representation of an authority is its whole source string
;;;; and a list of top-level forms, each with a concrete syntax tree. A
;;;; comment before the first form, between two forms or after the last
;;;; one belongs to none of them: no CST node covers a single byte of it.
;;;; Measured on the gesture transport: 887 bytes before the first form,
;;;; 516 between forms, and none of it inside any node's range.
;;;;
;;;; Such text is still persisted source, and it can be wrong. What it
;;;; has in place of a node is a range, so the address here is a range,
;;;; and the bytes expected at that range are the proof that the author
;;;; saw what is being replaced. They are not a search key: if they are
;;;; not where the plan says, nothing is relocated.
;;;;
;;;; The domain is deliberately disjoint from the CST path. A range that
;;;; touches any byte a node owns is refused, because inside a form the
;;;; structure is the authority and the targeted CST replacement is the
;;;; operation that protects it. Two ways of changing the same text would
;;;; let the weaker one bypass the stronger one's guarantees.
;;;;
;;;; One postcondition is new and is the reason this is not simply the CST
;;;; operation with a range. A comment is a comment only because of the
;;;; bytes around it: a replacement carrying a newline ends it, and what
;;;; follows is read as code. That result parses without complaint. It is
;;;; the set of top-level forms, compared in order, that catches it.

(in-package #:dreyeck/workflow/authoring)

(defclass source-range-replacement-plan ()
  ((system :initarg :system :reader range-plan-system)
   (path :initarg :path :reader range-plan-path)
   (range :initarg :range :reader range-plan-range)
   (expected :initarg :expected :reader range-plan-expected)
   (replacement :initarg :replacement :reader range-plan-replacement)
   (source :initarg :source :reader range-plan-source))
  (:documentation
   "One region of an authority that no Lisp form owns, and its new text.
SOURCE is the whole authority as observed; RANGE and EXPECTED are what the
author saw at the address. The postcondition is computed from these three
and nothing else."))

(defun %range-owner (code range)
  "The first CST node whose source range shares a byte with RANGE.
An empty RANGE shares a byte with a node when it lies strictly inside it;
touching a node's boundary from outside does not."
  (destructuring-bind (start . end) range
    (find-if (lambda (node)
               (destructuring-bind (node-start . node-end)
                   (concrete-syntax-tree:source node)
                 (if (= start end)
                     (< node-start start node-end)
                     (and (< start node-end) (> end node-start)))))
             (loop for form in (hv:top-level-forms-of code)
                   append (%cst-nodes (hv:cst-of form))))))

(defun %valid-range-p (range source)
  (and (consp range)
       (integerp (car range)) (integerp (cdr range))
       (<= 0 (car range) (cdr range) (length source))))

(defun plan-source-range-replacement
    (system-name path range expected replacement)
  "Observe one region that no form owns and propose new text for it.
Writes nothing. RANGE is the address; EXPECTED must be exactly the bytes
found there, and a mismatch is refused rather than looked for elsewhere."
  (let* ((system (asdf:find-system system-name))
         (authority (truename path))
         (source (uiop:read-file-string authority :external-format :utf-8)))
    (unless (member authority (wf::owned-paths system)
                    :key #'truename :test #'equal)
      (error "~A is not owned by ASDF system ~A." authority system-name))
    (unless (and (stringp expected) (stringp replacement))
      (error "Expected and replacement text must both be strings."))
    (unless (%valid-range-p range source)
      (error "~S is not a range in a source of length ~D."
             range (length source)))
    (unless (string= expected (subseq source (car range) (cdr range)))
      (error "The expected bytes are not at ~S." range))
    (multiple-value-bind (code recovered) (hv:parse-lisp-code source)
      (when recovered
        (error "The authority needs reader recovery; refusing to plan in it."))
      (let ((owner (%range-owner code range)))
        (when owner
          (error "~S overlaps source owned by a Lisp form at ~S; use the ~
targeted CST-source replacement." range (concrete-syntax-tree:source owner)))))
    (make-instance 'source-range-replacement-plan
                   :system (asdf:component-name system)
                   :path authority :range range :expected expected
                   :replacement replacement :source source)))

(defun source-range-replacement-status (plan)
  (let ((current (uiop:read-file-string (range-plan-path plan)
                                        :external-format :utf-8)))
    (cond ((not (string= current (range-plan-source plan))) :stale-authority)
          ((not (string= (range-plan-expected plan)
                         (subseq current (car (range-plan-range plan))
                                 (cdr (range-plan-range plan)))))
           :stale-authority)
          (t :needs-replacement))))

(defun %top-level-forms (source)
  (multiple-value-bind (code recovered) (hv:parse-lisp-code source)
    (values (mapcar #'hv:s-exp (hv:top-level-forms-of code)) recovered code)))

(defun verify-source-range-replacement (plan after-source)
  "The postcondition, checked against the plan and nothing else.
Separate from the writing so that a deliberately damaged AFTER can be
offered to it. Later form offsets are not compared: a replacement of a
different length moves them, legitimately. What must not move is which
forms there are and what they read as."
  (let* ((before (range-plan-source plan))
         (range (range-plan-range plan))
         (expected-source (hv::replace-source-range
                           before range (range-plan-replacement plan))))
    (unless (string= expected-source after-source)
      (error "Bytes outside the targeted range changed."))
    (multiple-value-bind (old-forms old-recovered old-code)
        (%top-level-forms before)
      (declare (ignore old-recovered))
      (when (%range-owner old-code range)
        (error "The targeted range was owned by a Lisp form."))
      (multiple-value-bind (new-forms new-recovered) (%top-level-forms after-source)
        (when new-recovered
          (error "The result needs reader recovery."))
        (unless (= (length old-forms) (length new-forms))
          (error "The set of top-level forms changed: ~D -> ~D."
                 (length old-forms) (length new-forms)))
        (loop for old in old-forms
              for new in new-forms
              for index from 0
              unless (wf:form-equal old new)
                do (error "Top-level form ~D changed." index))))
    after-source))

(defgeneric replace-owned-source-range (plan capability)
  (:documentation
   "Replace one region no Lisp form owns, verify a candidate, install it.
A refusal at any point leaves the authority byte-identical."))

(defmethod replace-owned-source-range ((plan source-range-replacement-plan)
                                       (capability authoring-environment))
  (unless (eq :needs-replacement (source-range-replacement-status plan))
    (error "Authority changed since it was observed."))
  (let* ((authority (range-plan-path plan))
         (candidate (%candidate-pathname authority))
         (installed nil))
    (unwind-protect
         (let ((after (hv::replace-source-range
                       (uiop:read-file-string authority :external-format :utf-8)
                       (range-plan-range plan)
                       (range-plan-replacement plan))))
           (uiop:with-output-file (stream candidate :external-format :utf-8)
             (write-string after stream))
           ;; Verified as it will be installed: read back from the
           ;; candidate, not from the string that was meant to be written.
           (verify-source-range-replacement
            plan (uiop:read-file-string candidate :external-format :utf-8))
           (rename-file candidate authority)
           (setf installed t)
           after)
      (unless installed
        (ignore-errors (delete-file candidate))))))
