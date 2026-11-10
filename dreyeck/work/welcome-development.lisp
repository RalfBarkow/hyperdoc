;;;; Claude revised design section 1, plus the W1 completion path.
(in-package #:dreyeck/work/welcome-development)

(shop3:defdomain (welcome-development :noset t)
 ((:- (accepted ?s) ((slice-verified ?s ?c ?_v) (slice-review-accepted ?s ?c ?_r)))
  (:- (accepted-commit ?s ?c) ((slice-verified ?s ?c ?_v) (slice-review-accepted ?s ?c ?_r)))
  (:- (blocked-by-dependency ?s) ((depends-on ?s ?d) (not (accepted ?d))))
  (:- (eligible ?s) ((slice ?s) (not (blocked-by-dependency ?s))))
  (:- (base-for ?s ?b) from-dependency ((depends-on ?s ?d) (accepted-commit ?d ?b))
                       from-observed-base ((not (depends-on ?s ?_any)) (observed-base ?b)))
  (:- (attempted-by ?s ?e) ((assignment ?s ?_a ?e ?_b)))
  (:- (implemented-by ?s ?c ?e) ((claimed ?s ?a ?c) (assignment ?s ?a ?e ?_b)))
  (:- (eligible-reviewer ?s ?c ?r) ((may-review ?r ?s) (not (implemented-by ?s ?c ?r))))
  (:- (reviewed ?s ?c) accepted ((slice-review-accepted ?s ?c ?_a)) rejected ((slice-review-rejected ?s ?c ?_b)))
  (:- (closed ?s ?a) failed ((claimed ?s ?a ?c) (verification-failed ?s ?c ?_v))
                     rejected ((claimed ?s ?a ?c) (slice-review-rejected ?s ?c ?_r)))
  (:- (open-assignment ?s) ((assignment ?s ?a ?_e ?_b) (not (closed ?s ?a))))
  (:- (has-closed-attempt ?s) ((assignment ?s ?a ?_e ?_b) (closed ?s ?a)))
  (:- (checked ?s ?c) verified ((slice-verified ?s ?c ?_v)) failed ((verification-failed ?s ?c ?_w)))
  (:- (untried-executor ?s ?e) ((may-implement ?e ?s) (not (attempted-by ?s ?e))))
  ;; every operator only proposes; effects are planned-* and never read by any precondition
  (:operator (!propose-integration ?s ?c) () () ((planned-integration-proposal ?s ?c)))
  (:operator (!request-review ?s ?c ?r) () () ((planned-review-request ?s ?c ?r)))
  (:operator (!verify-submission ?s ?a ?c) () () ((planned-verification ?s ?a ?c)))
  (:operator (!await-submission ?_s ?_a ?_e) () () ())
  (:operator (!assign ?s ?e ?b) () () ((planned-assignment ?s ?e ?b)))
  (:operator (!report-blocker ?s ?reason) () () ((planned-blocker-report ?s ?reason)))
  (:method (advance-welcome) propose-integration
   ((accepted-commit ?s ?c) (not (slice-integrated ?s ?c ?_m))) ((!propose-integration ?s ?c)))
  (:method (advance-welcome) request-review
   ((eligible ?s) (slice-verified ?s ?c ?_v) (not (reviewed ?s ?c)) (eligible-reviewer ?s ?c ?r))
   ((!request-review ?s ?c ?r)))
  (:method (advance-welcome) blocker-no-reviewer
   ((eligible ?s) (slice-verified ?s ?c ?_v) (not (reviewed ?s ?c)) (not (eligible-reviewer ?s ?c ?_r)))
   ((!report-blocker ?s no-eligible-reviewer)))
  (:method (advance-welcome) verify-submission
   ((eligible ?s) (claimed ?s ?a ?c) (not (checked ?s ?c))) ((!verify-submission ?s ?a ?c)))
  (:method (advance-welcome) await-submission
   ((eligible ?s) (assignment ?s ?a ?e ?_b) (not (claimed ?s ?a ?_c))) ((!await-submission ?s ?a ?e)))
  (:method (advance-welcome) first-assignment
   ((eligible ?s) (not (accepted ?s)) (not (attempted-by ?s ?_x)) (base-for ?s ?b) (may-implement ?e ?s))
   ((!assign ?s ?e ?b)))
  (:method (advance-welcome) reassignment
   ((eligible ?s) (not (accepted ?s)) (not (open-assignment ?s)) (has-closed-attempt ?s)
    (attempts ?s ?n) (attempt-limit ?max) (shop3:call < ?n ?max) (base-for ?s ?b) (untried-executor ?s ?e))
   ((!assign ?s ?e ?b)))
  (:method (advance-welcome) blocker-attempt-limit
   ((eligible ?s) (not (accepted ?s)) (not (open-assignment ?s)) (has-closed-attempt ?s)
    (attempts ?s ?n) (attempt-limit ?max) (shop3:call >= ?n ?max))
   ((!report-blocker ?s attempts-exhausted)))
  (:method (advance-welcome) blocker-no-alternative
   ((eligible ?s) (not (accepted ?s)) (not (open-assignment ?s)) (has-closed-attempt ?s)
    (attempts ?s ?n) (attempt-limit ?max) (shop3:call < ?n ?max) (not (untried-executor ?s ?_e)))
   ((!report-blocker ?s no-alternative-executor)))
  (:- (all-integrated)
   ((accepted-commit s1 ?c1) (slice-integrated s1 ?c1 ?_h1)
    (accepted-commit s2 ?c2) (slice-integrated s2 ?c2 ?_h2)
    (accepted-commit s3 ?c3) (slice-integrated s3 ?c3 ?_h3)
    (accepted-commit s4 ?c4) (slice-integrated s4 ?c4 ?_h4)))
  (:operator (!report-complete) () () ((planned-complete-report)))
  (:method (advance-welcome) report-complete ((all-integrated)) ((!report-complete)))))

(defclass development-run ()
  ((records :initarg :records :reader development-records)
   (initial-state :initarg :initial-state :reader development-initial-state)
   (result :initarg :result :reader development-plan-result)))

(defun plan-development-state (state)
  (let* ((name (gensym "WELCOME-DEVELOPMENT-"))
         (problem (shop3:make-problem
                   (list name :domain 'welcome-development :silently t)
                   (copy-tree state) '((advance-welcome)))))
    (multiple-value-bind (raw seconds trees states)
        (shop3:find-plans problem :which :all :verbose 0 :plan-tree t :collect-state t)
      (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                     :problem-name name :raw-plans raw
                     :plans (mapcar #'shop3:shorter-plan raw)
                     :time seconds :plan-trees trees :final-states states
                     :execution-mode :plan-only))))

(defun development-workflow (records)
  "One read-only planning cycle, with records and every native alternative retained."
  (let ((state (development-state records)))
    (make-instance 'development-run :records (copy-list records)
                   :initial-state state :result (plan-development-state state))))

(defun welcome-development-plan (records)
  "Return the existing native result, never a selected plan or an executed action."
  (development-plan-result (development-workflow records)))

(defun action-classification (operator)
  (case operator
    ((!assign !verify-submission !request-review !propose-integration) :actionable)
    (!await-submission :awaiting)
    (!report-blocker :blocked)
    (!report-complete :complete)
    (otherwise (refuse-record :unknown-development-operator))))

(defun development-next-action-view (source)
  "Interpret every alternative locally. Reports/waits are not development assignments.
No shared plan-step normalizer, default selection, callbacks or execution controls."
  (let ((result (if (typep source 'development-run) (development-plan-result source) source)))
    (check-type result dreyeck/shop3:hyperdoc-htn-plan-result)
    (unless (eq :plan-only (dreyeck/shop3:execution-mode-of result))
      (refuse-record :plan-only-required))
    (unless (= (length (dreyeck/shop3:plans-of result))
               (length (dreyeck/shop3:raw-plans-of result))
               (length (dreyeck/shop3:plan-trees-of result))
               (length (dreyeck/shop3:final-states-of result)))
      (refuse-record :incomplete-alternative-data))
    (loop for plan in (dreyeck/shop3:plans-of result)
          for tree in (dreyeck/shop3:plan-trees-of result)
          for state in (dreyeck/shop3:final-states-of result)
          for index from 0
          collect (progn
                    (unless (= 1 (length plan)) (refuse-record :one-step-alternative-required))
                    (list :index index :classification (action-classification (caar plan))
                          :step (first plan) :plan plan :plan-tree tree :final-state state
                          :assignment-proposal-p (eq '!assign (caar plan))
                          :execution :not-executed)))))

(defun development-outcome (source)
  "Overall display priority: actionable, awaiting, blocked, complete; all choices remain visible."
  (let ((kinds (mapcar (lambda (alternative) (getf alternative :classification))
                       (development-next-action-view source))))
    (or (find-if (lambda (kind) (member kind kinds)) '(:actionable :awaiting :blocked :complete))
        :blocked)))
