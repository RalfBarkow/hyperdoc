;;;; From a request to the exact source change it would make, and no further.
;;;;
;;;; An OPERATION-REQUEST names an operation and a definition. For
;;;; "Insert executable DEFEXAMPLE" that is not yet enough to act on: it
;;;; does not say what the example is called or what it does. Those are
;;;; the operation's arguments. Request and arguments together are fully
;;;; specified, and only then can the existing INSERTION-PLAN say exactly
;;;; which form would go where.
;;;;
;;;; An OPERATION-PLAN keeps the four together -- the request, the
;;;; arguments, the insertion plan and what was observed while planning --
;;;; and is still only a proposal. PLAN-INSERTION writes nothing and
;;;; evaluates nothing, and a plan records no execution.
;;;;
;;;; EXECUTE-OPERATION-PLAN carries one out, with the existing structural
;;;; writer and only in an image holding the pinned authoring environment,
;;;; and then reads the code page again. Its result is what that reading
;;;; finds, not what the plan proposed.
;;;;
;;;; This system is authoring-side. The Catalog never loads it.

(defpackage #:dreyeck/gesture/operation-plan
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/gesture/operation-request)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:wf #:dreyeck/workflow)
                    (#:a #:dreyeck/workflow/authoring)
                    (#:hv #:html-inspector-views/standard)
                    (#:views #:html-inspector-views))
  (:export #:operation-plan
           #:operation-plan-request
           #:operation-plan-arguments
           #:operation-plan-insertion
           #:operation-plan-observations
           #:operation-plan-refused
           #:operation-plan-refused-request
           #:operation-plan-refused-reason
           #:plan-operation-request
           #:execute-operation-plan
           #:operation-execution-refused
           #:operation-execution-refused-reason
           #:operation-execution-refused-cause
           #:operation-result-unobserved
           #:operation-result-unobserved-reason))

(in-package #:dreyeck/gesture/operation-plan)

(define-condition operation-plan-refused (error)
  ((request :initarg :request :reader operation-plan-refused-request)
   (reason :initarg :reason :reader operation-plan-refused-reason))
  (:report (lambda (condition stream)
             (format stream "No plan for ~S: ~A"
                     (operation-plan-refused-request condition)
                     (operation-plan-refused-reason condition))))
  (:documentation "The request could not be turned into a plan. Nothing
was written; planning never writes."))

(defclass operation-plan ()
  ((request :initarg :request :reader operation-plan-request)
   (arguments :initarg :arguments :reader operation-plan-arguments)
   (insertion :initarg :insertion :reader operation-plan-insertion)
   (observations :initarg :observations :reader operation-plan-observations))
  (:documentation
   "A request, the arguments that specify it, and the exact insertion they
would make, with what was seen while planning. A proposal: it holds no
capability and records no execution."))

(defmethod print-object ((plan operation-plan) stream)
  (print-unreadable-object (plan stream :type t)
    (format stream "~S before ~S"
            (a::insertion-plan-key (operation-plan-insertion plan))
            (a::insertion-plan-anchor-key (operation-plan-insertion plan)))))

(defun %refuse (request format-control &rest arguments)
  (error 'operation-plan-refused
         :request request
         :reason (apply #'format nil format-control arguments)))

(defun %mentions-p (symbol tree)
  (cond ((eq symbol tree) t)
        ((consp tree) (or (%mentions-p symbol (car tree))
                          (%mentions-p symbol (cdr tree))))))

(defun %examples-calling (subject forms)
  "The names of the DEFEXAMPLEs in FORMS whose bodies name SUBJECT.
An observation, not a judgement: a new example beside these may still be
wanted."
  (loop for form in forms
        for key = (wf:form-key form)
        when (and key (eq :example (first key))
                  (%mentions-p subject (cddr form)))
          collect (second key)))

(defun %anchor-after (request keys target-key)
  "The first keyed form after TARGET-KEY: an insertion goes before an
anchor, so \"after the definition\" is \"before whatever keyed form comes
next\". Unkeyed forms in between stay where they are, before the example.
There is no end-of-file insertion, so a definition with no keyed form
after it is refused rather than placed somewhere else."
  (let ((position (position target-key keys :test #'equal)))
    (or (find-if #'identity (nthcdr (1+ position) keys))
        (%refuse request "no keyed top-level form follows ~S, and an ~
insertion can only be placed before one" target-key))))

(defun plan-operation-request (request &key name body)
  "Plan \"Insert executable DEFEXAMPLE\" for REQUEST, named NAME, doing BODY.
NAME is a symbol in the package the target definition is read in, as a
DEFEXAMPLE beside it would be; BODY is the list of forms after the name,
as DEFEXAMPLE takes them. Writes nothing."
  (unless (eq (r:operation-request-operation request)
              (w:insert-executable-defexample-operation))
    (%refuse request "this planner only plans ~A, not ~A"
             (w:semantic-operation-identity-id (w:insert-executable-defexample-operation))
             (w:semantic-operation-identity-id (r:operation-request-operation request))))
  ;; The existing planner must not reinterpret an old selection by name.
  (handler-case (r:resolve-occurrence (r:operation-request-occurrence request))
    (error (condition) (%refuse request "~A" condition)))
  (let* ((system (r:operation-request-system request))
         (path (r:operation-request-path request))
         (target-key (r:operation-request-form-key request))
         (subject (second target-key)))
    (unless (and (symbolp name) name)
      (%refuse request "the example name must be a symbol, not ~S" name))
    (unless (and (consp body) (listp (cdr (last body))))
      (%refuse request "the example body must be a non-empty list of forms, not ~S"
               body))
    (unless (eq (symbol-package name) (symbol-package subject))
      (%refuse request "~S is not in ~A, the package ~S is read in"
               name (package-name (symbol-package subject)) subject))
    (let* ((forms (wf:source-forms (r:occurrence-source (r:operation-request-occurrence request))))
           (keys (mapcar #'wf:form-key forms)))
      (unless (= 1 (count target-key keys :test #'equal))
        (%refuse request "~S is no longer a single definition in ~A"
                 target-key (namestring path)))
      (let* ((arguments (list :name name :body (copy-tree body)))
             (proposed (list* 'hyperdoc:defexample name (copy-tree body)))
             (anchor (%anchor-after request keys target-key))
             (insertion (a::plan-insertion system path (wf:form-key proposed)
                                           proposed anchor)))
        (make-instance 'operation-plan
                       :request request
                       :arguments arguments
                       :insertion insertion
                       :observations
                       (list :examples-calling-target
                             (%examples-calling subject forms)
                             :authority-status (a::insertion-plan-status insertion)))))))

;;;; Executing a plan, and what reading then finds
;;;;
;;;; The effect is the existing structural writer's, INSERT-OWNED-FORM, which
;;;; verifies its candidate before installing it. What was created is then
;;;; observed, not asserted: the request's code page is read again, and the
;;;; result is the DEFEXAMPLE occurrence that reading finds there. The plan's
;;;; proposed form is a representation before the effect; the occurrence is
;;;; an observation after it. Judging that example is a later, separate
;;;; reading of the occurrence, and no part of the effect.

(define-condition operation-execution-refused (error)
  ((plan :initarg :plan :reader operation-execution-refused-plan)
   (reason :initarg :reason :reader operation-execution-refused-reason)
   (cause :initarg :cause :initform nil :reader operation-execution-refused-cause))
  (:report (lambda (condition stream)
             (format stream "Operation plan not executed: ~A"
                     (operation-execution-refused-reason condition))))
  (:documentation "Nothing was installed: the authority is as it was."))

(define-condition operation-result-unobserved (error)
  ((plan :initarg :plan :reader operation-result-unobserved-plan)
   (reason :initarg :reason :reader operation-result-unobserved-reason))
  (:report (lambda (condition stream)
             (format stream "Operation plan installed but its result not observed: ~A"
                     (operation-result-unobserved-reason condition))))
  (:documentation "The writer installed its verified candidate, but reading
the code page again does not find exactly the proposed example. The effect is
not accepted; nothing is rolled back."))

(defun execute-operation-plan (plan environment)
  "Carry out PLAN with the existing structural writer, if ENVIRONMENT is the
pinned authoring environment this image was given; then read the request's
code page again. Returns the SOURCE-OCCURRENCE of the inserted DEFEXAMPLE that
reading finds. Signals OPERATION-EXECUTION-REFUSED having installed nothing,
or OPERATION-RESULT-UNOBSERVED having installed the writer's verified
candidate. Neither loads nor runs the example."
  (flet ((refuse (reason &optional cause)
           (error 'operation-execution-refused :plan plan :reason reason :cause cause)))
    (unless (typep plan 'operation-plan)
      (refuse (format nil "~S is not an operation plan" plan)))
    (unless (typep environment 'a::authoring-environment)
      (refuse "there is no authoring environment: the pinned authoring capability is absent"))
    (let ((insertion (operation-plan-insertion plan)))
      ;; The writer refuses only before it installs: every check it makes is
      ;; on the candidate beside the authority.
      (handler-case (a::insert-owned-form insertion environment)
        (error (condition)
          (refuse "the structural writer did not install its candidate" condition)))
      (flet ((unobserved (reason)
               (error 'operation-result-unobserved :plan plan :reason reason)))
        (let* ((key (a::insertion-plan-key insertion))
               (found (remove key (r:page-example-occurrences
                                   (r:operation-request-page (operation-plan-request plan)))
                              :key #'r:occurrence-form-key :test-not #'equal)))
          (unless (= 1 (length found))
            (unobserved (format nil "reading the code page again finds ~D examples ~S"
                                (length found) (second key))))
          (unless (wf:form-equal (a::insertion-plan-proposed insertion)
                                 (hv:s-exp (r:resolve-occurrence (first found))))
            (unobserved "the example reading finds is not the proposed form"))
          (first found))))))

(defun %stage (label answer)
  (views:html (:tr (:td (views:esc label)) (:td (views:esc answer)))))

(views:defview operation-plan-overview (plan operation-plan)
  (views:html-view :title "Plan" :priority 1
    (let* ((request (operation-plan-request plan))
           (insertion (operation-plan-insertion plan))
           (arguments (operation-plan-arguments plan))
           (status (a::insertion-plan-status insertion)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Requested")
               (:td (:tt (views:esc (w:semantic-operation-identity-id
                                     (r:operation-request-operation request))))))
          (:tr (:td "On definition")
               (:td (:tt (views:esc (prin1-to-string (r:operation-request-form-key request))))
                    " in " (views:esc (namestring (r:operation-request-path request)))))
          (:tr (:td "Arguments")
               (:td (:tt (views:esc (prin1-to-string arguments)))))
          (:tr (:td "Already calling it")
               (:td (:tt (views:esc (prin1-to-string
                                     (getf (operation-plan-observations plan)
                                           :examples-calling-target))))))
          (:tr (:td "Would insert")
               (:td (:pre (views:esc (let ((*package* (symbol-package
                                                       (getf arguments :name))))
                                       (with-output-to-string (stream)
                                         (pprint (a::insertion-plan-proposed insertion)
                                                 stream)))))))
          (:tr (:td "Before")
               (:td (:tt (views:esc (prin1-to-string (a::insertion-plan-anchor-key insertion))))))
          (:tr (:td "Executed")
               (:td "not recorded here: a plan is a proposal, and executing it returns what reading then finds")))
        (:h3 "Stages")
        (:table :class "inspector-table"
          (%stage "requested" "yes")
          (%stage "fully specified" "yes -- the request and its arguments")
          (%stage "planned" (if (eq :needs-insertion status)
                                "yes"
                                (format nil "no longer current: ~(~A~)" status)))
          (%stage "authorised" "not recorded by the plan")
          (%stage "attempted" "not recorded by the plan")
          (%stage "installed" "not recorded by the plan")
          (%stage "verified" "not recorded by the plan"))))))
