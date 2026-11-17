;;;; Planning model derived from Zettel 11781 and the 2026-11-16 draft.
(defpackage #:den-v2-delivery-outlook
  (:use #:cl)
  (:export #:case-facts #:run-plan #:check-plans))

(in-package #:den-v2-delivery-outlook)

(shop3:defdomain (den-v2-delivery-outlook :redefine-ok t)
  (;; A roadmap proposes work. Only the review methods consume attestations.
   ;; Anonymous operator parameters still unify with the arguments of the task.
   (:operator (!plan-support ?product ?through) ((:support-through ?product ?through)) () ())
   (:operator (!plan-independent-foundation) () () ())
   (:operator (!establish-construction ?_class) () () ())
   (:operator (!review-product-design) () () ())
   (:operator (!plan-parity-integration ?_class) () () ())
   (:operator (!plan-product-sizing) () () ())
   (:operator (!plan-foundation-qualification) () () ())
   (:operator (!plan-end-to-end-integration) () () ())
   (:operator (!plan-migration-and-recovery) () () ())
   (:operator (!plan-release-qualification) () () ())
   (:operator (!prepare-release-review) () () ())

   (:method (delivery-roadmap)
    stages ()
    ((:unordered
      (:ordered (:unordered (!plan-independent-foundation)
                            (:ordered (!establish-construction :parity-1)
                                      (!plan-parity-integration :parity-1))
                            (:ordered (!establish-construction :parity-2)
                                      (!plan-parity-integration :parity-2))
                            (:ordered (!establish-construction :parity-3)
                                      (!plan-parity-integration :parity-3)))
                (!plan-foundation-qualification))
      (:ordered (!review-product-design) (!plan-product-sizing)))
     (!plan-end-to-end-integration)
     (!plan-migration-and-recovery)
     (!plan-release-qualification)
     (!prepare-release-review)))

   (:method (legacy-support ?product)
    published-window ((:support-through ?product ?through))
    ((!plan-support ?product ?through)))

   (:operator (!record-checkpoint-evidence) () () ())
   (:operator (!obtain-forecast-input ?_input) () () ())
   (:operator (!calculate-delivery-range) () () ())
   (:operator (!reassess-target ?_target) () () ())
   (:operator (!report-target-change ?_target ?_evidence) () () ())
   (:operator (!record-forecast-unavailable ?_target) () () ())

   (:method (resolve-parity ?class)
    accepted ((:construction-accepted ?class ?_)) ()
    unresolved () ((!establish-construction ?class)))

   (:method (obtain-forecast-input ?input)
    available ((:forecast-input ?input ?_)) ()
    missing () ((!obtain-forecast-input ?input)))

   (:method (forecast-inputs)
    check ()
    ((:unordered
      (resolve-parity :parity-1)
      (resolve-parity :parity-2)
      (resolve-parity :parity-3)
      (:ordered (obtain-forecast-input :reviewed-product-design)
                (obtain-forecast-input :sized-product-work))
      (obtain-forecast-input :dependency-chain)
      (obtain-forecast-input :integrated-throughput))))

   ;; This axiom is queried against the input facts. Tasks that ask for
   ;; evidence cannot make it true within the current plan search.
   (:- (forecast-supported)
       ((:construction-accepted :parity-1 ?_)
        (:construction-accepted :parity-2 ?_)
        (:construction-accepted :parity-3 ?_)
        (:forecast-input :reviewed-product-design ?_)
        (:forecast-input :sized-product-work ?_)
        (:forecast-input :dependency-chain ?_)
        (:forecast-input :integrated-throughput ?_)))

   (:method (review-delivery-target)
    planning-target ((:planning-target ?target))
    ((delivery-checkpoint ?target)))

   (:method (delivery-checkpoint ?target)
    target-no-longer-credible ((:target-assessment ?target :unrealistic ?evidence))
    ((!report-target-change ?target ?evidence)
     (!record-checkpoint-evidence)
     (forecast-inputs)
     (forecast-review ?target))
    checkpoint ()
    ((!record-checkpoint-evidence)
     (forecast-inputs)
     (forecast-review ?target)))

   (:method (forecast-review ?target)
    ready ((forecast-supported))
    ((!calculate-delivery-range) (!reassess-target ?target))
    awaiting-evidence ()
    ((!record-forecast-unavailable ?target)))

   (:operator (!verify-xmsg-capacity) () () ())
   (:operator (!consider-xmsg-capacity ?_readiness ?_availability ?_throughput) () () ())

   (:method (review-xmsg-capacity)
    observed ((:xmsg-ready ?readiness)
              (:xmsg-capacity-available ?availability)
              (:xmsg-useful-throughput ?throughput))
    ((!consider-xmsg-capacity ?readiness ?availability ?throughput))
    unverified ()
    ((!verify-xmsg-capacity)))

   (:operator (!identify-release-candidate) () () ())
   (:operator (!obtain-release-evidence ?_candidate ?_check) () () ())
   (:operator (!propose-release-decision ?_candidate) () () ())

   (:method (obtain-release-evidence ?candidate ?check)
    available ((:release-evidence ?candidate ?check ?_)) ()
    missing () ((!obtain-release-evidence ?candidate ?check)))

   (:method (review-release ?candidate)
    review-candidate ((:candidate ?candidate))
    ((acceptance-evidence ?candidate))
    identify-candidate ()
    ((!identify-release-candidate)))

   (:method (acceptance-evidence ?candidate)
    checklist ()
    ((:unordered
      (obtain-release-evidence ?candidate :foundation-and-parity)
      (obtain-release-evidence ?candidate :feature-path)
      (obtain-release-evidence ?candidate :representative-migration)
      (obtain-release-evidence ?candidate :failure-and-recovery)
      (obtain-release-evidence ?candidate :regression)
      (obtain-release-evidence ?candidate :performance)
      (obtain-release-evidence ?candidate :compatibility)
      (obtain-release-evidence ?candidate :usable-documentation))
     (obtain-release-evidence ?candidate :recorded-acceptance)))

   (:method (decide-release ?candidate)
    qualification-evidenced
    ((:candidate ?candidate)
     (:release-evidence ?candidate :foundation-and-parity ?_)
     (:release-evidence ?candidate :feature-path ?_)
     (:release-evidence ?candidate :representative-migration ?_)
     (:release-evidence ?candidate :failure-and-recovery ?_)
     (:release-evidence ?candidate :regression ?_)
     (:release-evidence ?candidate :performance ?_)
     (:release-evidence ?candidate :compatibility ?_)
     (:release-evidence ?candidate :usable-documentation ?_)
     (:release-evidence ?candidate :recorded-acceptance ?_))
    ((!propose-release-decision ?candidate)))

   (:operator (!review-evidence-reuse ?_check) () () ())
   (:operator (!plan-rerun ?_check) () () ())

   (:method (review-test-evidence ?check)
    eligible ((:rerun-policy ?check :optional)
              (:test-context ?check :prior ?source ?dependencies ?setup ?criteria)
              (:test-context ?check :current ?source ?dependencies ?setup ?criteria))
    ((!review-evidence-reuse ?check))
    required-or-unverified ()
    ((!plan-rerun ?check)))))

(defparameter *draft-facts*
  '((:source :zettel-11781 :gist-c83c4a86460175413b2a4cff2bfb58191dd96b84)
    (:source-status :draft :2026-11-16)
    (:planning-target :2027-01-01)
    (:support-through :effects-based-den :2027-q1)))

(defun case-facts (case)
  "Return fresh case-specific input facts. :EXAMPLE-* references are illustrative."
  (copy-tree
   (case case
     (:forecast-ready
      '((:construction-accepted :parity-1 :example-parity-1)
        (:construction-accepted :parity-2 :example-parity-2)
        (:construction-accepted :parity-3 :example-parity-3)
        (:forecast-input :reviewed-product-design :example-design)
        (:forecast-input :sized-product-work :example-sizing)
        (:forecast-input :dependency-chain :example-dependencies)
        (:forecast-input :integrated-throughput :example-integration)))
     (:target-unrealistic
      '((:target-assessment :2027-01-01 :unrealistic :example-checkpoint)))
     (:xmsg-verified
      '((:xmsg-ready :example-xmsg-build)
        (:xmsg-capacity-available :example-staffing)
        (:xmsg-useful-throughput :example-measurement)))
     ((:release-blocked :release-ready)
      (cons '(:candidate :rc-example)
            (loop for check in '(:foundation-and-parity :feature-path
                                 :representative-migration :failure-and-recovery
                                 :regression :performance :compatibility
                                 :usable-documentation :recorded-acceptance)
                  collect (list :release-evidence
                                (if (and (eq case :release-blocked)
                                         (eq check :failure-and-recovery))
                                    :other-rc
                                    :rc-example)
                                check :example-qualification))))
     (:evidence-reusable
      '((:rerun-policy :regression :optional)
        (:test-context :regression :prior :example-source :example-deps
         :example-setup :example-criteria)
        (:test-context :regression :current :example-source :example-deps
         :example-setup :example-criteria))))))

(defun case-task (case candidate)
  (ecase case
    (:roadmap '(delivery-roadmap))
    (:support '(legacy-support :effects-based-den))
    ((:checkpoint :forecast-ready :target-unrealistic)
     '(review-delivery-target))
    ((:xmsg :xmsg-verified) '(review-xmsg-capacity))
    (:release-review (list 'review-release candidate))
    ((:release :release-ready :release-blocked) (list 'decide-release candidate))
    ((:evidence-reuse :evidence-reusable) '(review-test-evidence :regression))))

(defun find-case-plans (problem domain case)
  (flet ((search-plans (plan-tree)
           (shop3:find-plans problem :domain domain :which :first :verbose 0
                             :plan-tree plan-tree :collect-state t)))
    (handler-case (search-plans t)
      (type-error (condition)
        ;; SHOP3 can try to strip tree tags from NIL for a successful
        ;; release review with no operators. Confirm the empty plan with
        ;; tree extraction disabled before accepting the result.
        (unless (and (eq case :release-review)
                     (null (type-error-datum condition))
                     (eq 'cons (type-error-expected-type condition)))
          (error condition))
        (multiple-value-bind (plans seconds trees states) (search-plans nil)
          (unless (equal plans '(nil))
            (error condition))
          (values plans seconds trees states))))))

(defun run-plan (case &key (facts nil facts-supplied-p) (candidate :rc-example))
  "Return a HyperDoc plan result. FACTS supplies the complete case evidence."
  (let* ((task (case-task case candidate))
         (evidence (if facts-supplied-p facts (case-facts case)))
         (origin (cond (facts-supplied-p :caller)
                       (evidence :illustrative)
                       (t :source-draft)))
         (state (append (copy-tree *draft-facts*)
                        (list (list :case case origin))
                        (copy-tree evidence)))
         (domain (shop3:find-domain 'den-v2-delivery-outlook))
         (name (gensym "DEN-V2-"))
         (shop3::*problem* shop3::*problem*)
         (problem nil))
    (unwind-protect
         (progn
           (setf problem
                 (shop3:make-problem (list name :domain 'den-v2-delivery-outlook :silently t)
                                     (copy-tree state) (list task)))
           (multiple-value-bind (raw seconds trees states)
               (find-case-plans problem domain case)
             (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                            :problem-name name :initial-facts state
                            :raw-plans raw :plans (mapcar #'shop3:shorter-plan raw)
                            :plan-trees trees :final-states states :time seconds
                            :execution-mode :plan-only)))
      (let ((registered (or problem (shop3:find-problem name))))
        (when registered
          (shop3:delete-problem registered))))))

(defun check-plans ()
  "Exercise the roadmap, forecast and same-candidate release boundaries in SHOP3."
  (flet ((steps (case &rest arguments)
           (dreyeck/shop3:plans-of (apply #'run-plan case arguments))))
    (let ((roadmap (first (steps :roadmap))))
      (dolist (class '(:parity-1 :parity-2 :parity-3))
        (assert (< (position (list '!establish-construction class) roadmap :test #'equal)
                   (position (list '!plan-parity-integration class) roadmap :test #'equal))))
      (assert (eq '!prepare-release-review (caar (last roadmap)))))
    (let ((checkpoint (first (steps :checkpoint))))
      (assert (= 3 (count '!establish-construction checkpoint :key #'first)))
      (assert (member '(!record-forecast-unavailable :2027-01-01) checkpoint :test #'equal))
      (assert (not (assoc '!calculate-delivery-range checkpoint))))
    (assert (assoc '!calculate-delivery-range (first (steps :forecast-ready))))
    (assert (not (assoc '!calculate-delivery-range
                        (first (steps :checkpoint
                                      :facts (rest (case-facts :forecast-ready)))))))
    (assert (equal '(!report-target-change :2027-01-01 :example-checkpoint)
                   (first (first (steps :target-unrealistic)))))
    (assert (null (steps :release)))
    (assert (null (steps :release-blocked)))
    (assert (equal (steps :release-review :facts (case-facts :release-blocked))
                   '(((!obtain-release-evidence :rc-example :failure-and-recovery)))))
    (assert (equal (steps :release-ready)
                   '(((!propose-release-decision :rc-example)))))
    (assert (equal (steps :release-review :facts (case-facts :release-ready)) '(nil)))
    (assert (equal (steps :xmsg) '(((!verify-xmsg-capacity)))))
    (assert (equal '(((!consider-xmsg-capacity :example-xmsg-build
                                              :example-staffing
                                              :example-measurement)))
                   (steps :xmsg-verified)))
    (assert (equal (steps :evidence-reuse) '(((!plan-rerun :regression)))))
    (assert (equal (steps :evidence-reusable) '(((!review-evidence-reuse :regression)))))
    (list :status :ok :execution-mode :plan-only)))
