;;;; Zettel 11560, building on 11483. Opt-in, hypothetical states only.
(defpackage #:dreyeck/work/defederation-planning
  (:use #:cl)
  (:export #:scenario-state #:defederation-plan #:defederation-experiment))
(in-package #:dreyeck/work/defederation-planning)

(shop3:defdomain prepare-wiki-defederation
  (;; These are positive reports, including explicit negative observations.
   ;; NOT below rejects conflicting reports; it never establishes absence.
   (:- (input-conflict)
    local-conflict ((local-page ?site ?page) (local-page-absent ?site ?page))
    remote-conflict ((remote-page ?remote ?page) (remote-page-absent ?remote ?page))
    snapshot-conflict ((snapshot-available ?remote ?page)
                       (snapshot-unavailable ?remote ?page))
    permission-conflict ((fork-permitted ?site ?remote ?page)
                         (fork-forbidden ?site ?remote ?page)))

   (:operator (!simulate-fork ?site ?remote ?page)
    ((local-page-absent ?site ?page) (remote-page ?remote ?page)
     (snapshot-available ?remote ?page) (fork-permitted ?site ?remote ?page))
    ((local-page-absent ?site ?page))
    ((local-page ?site ?page) (fork-prepared ?site ?remote ?page)))
   (:operator (!prepare-local-resolution ?site ?page)
    ((local-page ?site ?page))
    () ((resolution-prepared ?site local-only)))
   (:operator (!prepare-paragraph-rendering ?site)
    ((resolution-prepared ?site local-only))
    () ((rendering-prepared ?site paragraph-only)))

   (:method (prepare-defederation ?site ?remote ?page)
    consistent-input
    ((not (input-conflict)))
    ((ensure-local-target ?site ?remote ?page)
     (!prepare-local-resolution ?site ?page)
     (!prepare-paragraph-rendering ?site)))
   ;; Separate definitions allow :WHICH :ALL to explore every alternative.
   (:method (ensure-local-target ?site ?remote ?page)
    already-local
    ((local-page ?site ?page))
    ())
   (:method (ensure-local-target ?site ?remote ?page)
    fork-supported
    ((local-page-absent ?site ?page) (remote-page ?remote ?page)
     (snapshot-available ?remote ?page) (fork-permitted ?site ?remote ?page))
    ((!simulate-fork ?site ?remote ?page)))))

(shop3:defproblem defederation-a prepare-wiki-defederation
  ((local-page local-wiki target-page))
  ((prepare-defederation local-wiki remote-wiki target-page)))
(shop3:defproblem defederation-b prepare-wiki-defederation
  ((local-page-absent local-wiki target-page)
   (remote-page remote-wiki target-page)
   (snapshot-available remote-wiki target-page)
   (fork-permitted local-wiki remote-wiki target-page))
  ((prepare-defederation local-wiki remote-wiki target-page)))
(shop3:defproblem defederation-c prepare-wiki-defederation
  ((local-page-absent local-wiki target-page)
   (remote-page remote-wiki target-page)
   (snapshot-available remote-wiki target-page))
  ((prepare-defederation local-wiki remote-wiki target-page)))

(defun scenario-problem-name (scenario)
  (ecase scenario (:a 'defederation-a) (:b 'defederation-b) (:c 'defederation-c)))

(defun scenario-state (scenario)
  "Fresh copy of the actual SHOP3 fixture evidence. Missing facts mean unknown.
A: local; B: observed remote-only with fork evidence; C: permission unknown."
  (copy-tree (shop3:state-atoms (shop3:find-problem (scenario-problem-name scenario)))))

(defun defederation-plan (&optional (scenario :b))
  "Return the existing HyperDoc result, retaining all four SHOP3 values.
Enumerate all solutions. RAW-PLANS = NIL means no solution; (NIL) would be
a successful empty plan. No planned action is executed on a real Wiki."
  (let ((name (scenario-problem-name scenario)))
    (multiple-value-bind (raw seconds trees states)
        (shop3:find-plans name :which :all :verbose 0 :plan-tree t :collect-state t)
      (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                     :problem-name name :raw-plans raw
                     :plans (mapcar #'shop3:shorter-plan raw)
                     :time seconds :plan-trees trees :final-states states
                     :execution-mode :plan-only))))

(defun defederation-experiment (&optional (scenario :b))
  "Inspectable planning context, with no executor or Catalog registration."
  (let* ((result (defederation-plan scenario))
         (domain (shop3:find-domain 'prepare-wiki-defederation)))
    (list :scenario scenario :references '(11560 11483)
          :problem (shop3:find-problem (scenario-problem-name scenario))
          :initial-state (scenario-state scenario)
          :tasks '((prepare-defederation local-wiki remote-wiki target-page))
          :domain domain :methods (shop3:domain-methods domain)
          :result result :selected-plan (first (dreyeck/shop3:plans-of result))
          :outcome (if (dreyeck/shop3:raw-plans-of result) :planned :no-plan)
          :execution-status :not-executed
          :limits '(:fixture-evidence :simulated-state-transitions :single-target
                    :no-real-fork :no-resolver-change :no-renderer-change
                    :refederation-out-of-scope))))
