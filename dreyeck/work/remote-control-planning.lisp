;;;; Optional architecture experiment. All facts and effects are hypothetical.
(defpackage #:dreyeck/work/remote-control-planning
  (:use #:cl)
  (:export #:remote-control-plan #:remote-control-experiment #:run-tests))
(in-package #:dreyeck/work/remote-control-planning)

(shop3:defdomain zettelkasten-mobile-control
  ((:operator (!model-agent-route ?app ?host ?mobile)
    ((application-api ?app ?host) (agent-session ?host ?mobile)
     (authorized ?mobile ?app))
    () ((modeled-route ?app ?host ?mobile agent)))
   (:operator (!model-direct-route ?app ?host ?mobile)
    ((application-api ?app ?host) (direct-transport ?host ?mobile)
     (authorized ?mobile ?app))
    () ((modeled-route ?app ?host ?mobile direct)))
   (:operator (!model-control-surface ?app ?host ?mobile ?route)
    ((modeled-route ?app ?host ?mobile ?route))
    () ((control-surface ?mobile ?app ?route)))
   (:operator (!verify-modeled-control ?app ?host ?mobile ?route)
    ((modeled-route ?app ?host ?mobile ?route)
     (control-surface ?mobile ?app ?route)
     (execution-authority ?app ?host) (model-authority ?app ?host)
     (authorized ?mobile ?app) (application-api ?app ?host))
    () ((mobile-control-verified ?app ?host ?mobile ?route)))
   ;; Separate method definitions permit enumeration of both decompositions.
   (:method (enable-mobile-control ?app ?host ?mobile)
    agent-session-method
    ((execution-authority ?app ?host) (model-authority ?app ?host)
     (application-api ?app ?host) (authorized ?mobile ?app)
     (agent-session ?host ?mobile))
    ((!model-agent-route ?app ?host ?mobile)
     (!model-control-surface ?app ?host ?mobile agent)
     (!verify-modeled-control ?app ?host ?mobile agent)))
   (:method (enable-mobile-control ?app ?host ?mobile)
    direct-api-method
    ((execution-authority ?app ?host) (model-authority ?app ?host)
     (application-api ?app ?host) (authorized ?mobile ?app)
     (direct-transport ?host ?mobile))
    ((!model-direct-route ?app ?host ?mobile)
     (!model-control-surface ?app ?host ?mobile direct)
     (!verify-modeled-control ?app ?host ?mobile direct)))))

(defparameter *case-specifications*
  '((:a remote-control-a t t nil t)
    (:b remote-control-b t nil t t)
    (:c remote-control-c t t t t)
    (:d remote-control-d t t t nil)
    (:e remote-control-e nil t t t)))

(defun case-specification (case)
  (or (assoc case *case-specifications*) (error "Unknown planning case ~S" case)))

(defun case-initial-state (case)
  (destructuring-bind (key name api agent direct authorized)
      (case-specification case)
    (declare (ignore key name))
    (append '((execution-authority zettelkasten macbook-a)
              (model-authority zettelkasten macbook-a))
            (when api '((application-api zettelkasten macbook-a)))
            (when agent '((agent-session macbook-a android)))
            (when direct '((direct-transport macbook-a android)))
            (when authorized '((authorized android zettelkasten))))))

;; Define fixtures through the actual SHOP3 problem API, not a second planner.
(loop for (case name) in *case-specifications*
      do (eval `(shop3:defproblem ,name zettelkasten-mobile-control
                  ,(case-initial-state case)
                  ((enable-mobile-control zettelkasten macbook-a android)))))

(defun remote-control-plan (&optional (case :c))
  "Enumerate all plans. NIL raw plans means failure, not a successful empty plan."
  (let ((name (second (case-specification case))))
    (multiple-value-bind (raw seconds trees states)
        (shop3:find-plans name :which :all :verbose 0 :plan-tree t :collect-state t)
      (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                     :problem-name name :raw-plans raw
                     :plans (mapcar #'shop3:shorter-plan raw)
                     :time seconds :plan-trees trees :final-states states
                     :execution-mode :plan-only))))

(defun remote-control-experiment (&optional (case :c))
  "Inspectable context around the existing result object; never executes a plan."
  (let* ((result (remote-control-plan case))
         (domain (shop3:find-domain 'zettelkasten-mobile-control)))
    (list :case case :reference "Zettel 11551: Remote Control für die Zettelkasten-App"
          :architecture-goal "Local execution/model authority; mobile control surface"
          :problem (shop3:find-problem (second (case-specification case)))
          :initial-state (case-initial-state case)
          :domain domain :methods (shop3:domain-methods domain)
          :result result
          :outcome (if (dreyeck/shop3:raw-plans-of result) :planned :no-plan)
          :limits '(:hypothetical-inputs :simulated-effects :no-executor
                    :no-real-authorization :no-end-to-end-evidence
                    :human-acceptance-pending))))
