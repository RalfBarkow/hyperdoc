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
;;;; and is still only a proposal. Nothing here authorises, attempts,
;;;; installs or verifies anything, and nothing here holds the capability
;;;; that could. PLAN-INSERTION writes nothing and evaluates nothing.
;;;;
;;;; This system is authoring-side. The Catalog never loads it.

(defpackage #:dreyeck/gesture/operation-plan
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/gesture/operation-request)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:wf #:dreyeck/workflow)
                    (#:a #:dreyeck/workflow/authoring)
                    (#:views #:html-inspector-views))
  (:export #:operation-plan
           #:operation-plan-request
           #:operation-plan-arguments
           #:operation-plan-insertion
           #:operation-plan-observations
           #:operation-plan-refused
           #:operation-plan-refused-request
           #:operation-plan-refused-reason
           #:plan-operation-request))

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
          (:tr (:td "Executed") (:td "no")))
        (:h3 "Stages")
        (:table :class "inspector-table"
          (%stage "requested" "yes")
          (%stage "fully specified" "yes -- the request and its arguments")
          (%stage "planned" (if (eq :needs-insertion status)
                                "yes"
                                (format nil "no longer current: ~(~A~)" status)))
          (%stage "authorised" "no")
          (%stage "attempted" "no")
          (%stage "installed" "no")
          (%stage "verified" "no"))))))
