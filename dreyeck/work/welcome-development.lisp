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
   (result :initarg :result :reader development-plan-result)
   (assignment-validations :initarg :assignment-validations :reader development-assignment-validations)
   (alternatives :initarg :alternatives :reader development-alternatives)))

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

(defun development-canonical-string (value)
  "Deterministic readable literal data, independent of caller printer settings.
Reject objects and uninterned symbols rather than printing transient identities."
  (labels ((literal (x)
             (typecase x
               (cons (literal (car x)) (literal (cdr x)))
               (symbol (unless (symbol-package x) (refuse-record :uninterned-planning-input)))
               ((or string integer) nil)
               (t (refuse-record :nonliteral-planning-input)))))
    (literal value))
  (with-standard-io-syntax
    (let ((*package* (find-package "KEYWORD"))) (prin1-to-string value))))

(defun development-data-digest (value)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence
    :sha256 (sb-ext:string-to-octets (development-canonical-string value) :external-format :utf-8))))

(defun development-plan-inputs (state result source)
  "Canonical binding inputs, preserving alternative multiplicity but not enumeration order."
  (list :format "welcome-development-plan-v1" :source source
        ;; Pinned SHOP3's declared domain reader; no generated problem/tree data.
        :domain (shop3::domain-items (shop3:find-domain 'welcome-development))
        :state (sort (mapcar #'development-canonical-string state) #'string<)
        :tasks '((advance-welcome)) :which :all
        :alternatives (sort (mapcar #'development-canonical-string
                                    (dreyeck/shop3:plans-of result)) #'string<)))

(defun plan-assignment-binding (state result source step)
  "Bind a chosen action to a complete native search; never choose an alternative."
  (unless (and (eq '!assign (first step))
               (member (list step) (dreyeck/shop3:plans-of result) :test #'equal))
    (refuse-record (list :assignment-not-proposed step)))
  (let ((inputs (development-plan-inputs state result source)))
    (list :digest (development-data-digest inputs) :step (copy-tree step)
          :alternative-id (development-data-digest (list "welcome-development-action-v1" step))
          :inputs inputs)))

(defun assignment-proposal-binding (records step)
  "Validate prior history and ask SHOP3 for the binding of this explicitly chosen !ASSIGN.
Return binding and native planning result; this does not append/execute an assignment."
  (let* ((state (development-state records))
         (source (record-source (first (accepted-records records))))
         (result (plan-development-state state)))
    (values (plan-assignment-binding state result source step) result)))

(defun development-workflow (records)
  "One read-only planning cycle, with records and every native alternative retained."
  (multiple-value-bind (state validations) (development-state records)
    (let ((result (plan-development-state state)))
      (make-instance 'development-run :records (copy-list records)
                     :initial-state state :result result :assignment-validations validations
                     :alternatives (result-next-action-view result)))))

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

(defun result-next-action-view (result)
  "Interpret every alternative locally. Reports/waits are not development assignments.
No shared plan-step normalizer, default selection, callbacks or execution controls."
  (progn
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
                          :alternative-id (development-data-digest
                                           (list "welcome-development-action-v1" (first plan)))
                          :execution :not-executed)))))

(defun development-next-action-view (source)
  "Return the run's retained alternatives, shared by all Inspector/Topicmap projections.
A bare native result remains supported without claiming a cross-view identity cache."
  (if (typep source 'development-run) (development-alternatives source)
      (result-next-action-view source)))

(defun development-outcome (source)
  "Overall display priority: actionable, awaiting, blocked, complete; all choices remain visible."
  (let ((kinds (mapcar (lambda (alternative) (getf alternative :classification))
                       (development-next-action-view source))))
    (or (find-if (lambda (kind) (member kind kinds)) '(:actionable :awaiting :blocked :complete))
        :blocked)))
