;;;; Zettel 11560 (after 11483): prepare Ward's defederation, never execute it.
(defpackage #:dreyeck/work/defederation-planning
  (:use #:cl)
  (:export #:scenario-state #:plan-defederation #:defederation-plan
           #:defederation-experiment #:planning-outcome #:run-tests))
(in-package #:dreyeck/work/defederation-planning)

(shop3:defdomain defederation-preparation
  (;; Explicit opposite observations, rather than a closed-world inference.
   (:- (input-conflict ?site ?slug)
    local-conflict
    ((local-page ?site ?slug) (local-page-absent ?site ?slug))
    snapshot-conflict
    ((remote-snapshot ?site ?slug ?_remote ?_snapshot)
     (snapshot-unavailable ?site ?slug))
    permission-conflict
    ((fork-permitted ?site ?slug) (fork-forbidden ?site ?slug)))
   (:- (target-ready ?site ?slug)
    observed ((local-page ?site ?slug))
    simulated ((modeled-local-page ?site ?slug)))

   (:operator (!simulate-fork ?site ?slug ?remote ?snapshot)
    ((local-page-absent ?site ?slug)
     (remote-snapshot ?site ?slug ?remote ?snapshot)
     (fork-permitted ?site ?slug)
     (not (input-conflict ?site ?slug)))
    () ((modeled-local-page ?site ?slug)
        (modeled-fork ?site ?slug ?remote ?snapshot)))
   (:operator (!prepare-local-links ?site ?slug)
    ((target-ready ?site ?slug))
    () ((local-links-prepared ?site)))
   (:operator (!prepare-paragraph-rendering ?site)
    ((local-links-prepared ?site))
    () ((paragraph-rendering-prepared ?site)))

   (:method (prepare-defederation ?site ?slug)
    prepare-after-consistency-check
    ((not (input-conflict ?site ?slug)))
    ((ensure-local-target ?site ?slug)
     (!prepare-local-links ?site ?slug)
     (!prepare-paragraph-rendering ?site)))
   ;; Separate definitions let :WHICH :ALL expose any alternative solution.
   (:method (ensure-local-target ?site ?slug)
    already-local
    ((local-page ?site ?slug))
    ())
   (:method (ensure-local-target ?site ?slug)
    fork-proven-remote
    ((local-page-absent ?site ?slug)
     (remote-snapshot ?site ?slug ?remote ?snapshot)
     (fork-permitted ?site ?slug))
    ((!simulate-fork ?site ?slug ?remote ?snapshot)))))

(defun scenario-state (scenario)
  "Fresh hypothetical observations for a single required link target.
Missing observations are unknown, never evidence of absence or prohibition."
  (copy-tree
   (ecase scenario
     (:a '((local-page :local-wiki :target-page)))
     (:b '((local-page-absent :local-wiki :target-page)
           (remote-snapshot :local-wiki :target-page :remote-wiki :snapshot-1)
           (fork-permitted :local-wiki :target-page)))
     (:c '((local-page-absent :local-wiki :target-page)
           (remote-snapshot :local-wiki :target-page :remote-wiki :snapshot-1))))))

(defun planning-outcome (result)
  "A successful empty plan is still success; execution is always separate."
  (if (dreyeck/shop3:raw-plans-of result) :planned :no-plan))

(defun plan-defederation (initial-state
                          &key (site :local-wiki) (slug :target-page)
                            (problem-name 'defederation-custom)
                            (domain 'defederation-preparation))
  "Search with real SHOP3, retaining all four values in the existing result.
Only hypothetical in-memory facts change. No Wiki I/O or executor is involved."
  (let ((problem
          (shop3:make-problem
           (list problem-name :domain domain :silently t)
           (copy-tree initial-state) `((prepare-defederation ,site ,slug)))))
    (multiple-value-bind (raw seconds trees states)
        (shop3:find-plans problem :which :all :verbose 0
                         :plan-tree t :collect-state t)
      (make-instance 'dreyeck/shop3:hyperdoc-htn-plan-result
                     :problem-name problem-name :raw-plans raw
                     :plans (mapcar #'shop3:shorter-plan raw)
                     :time seconds :plan-trees trees :final-states states
                     :execution-mode :plan-only))))

(defun defederation-plan (&optional (scenario :a))
  (plan-defederation
   (scenario-state scenario)
   :problem-name (ecase scenario
                   (:a 'defederation-a) (:b 'defederation-b) (:c 'defederation-c))))

(defun defederation-experiment (&optional (scenario :a))
  "Inspectable observations and native SHOP3 objects around the shared result."
  (let* ((result (defederation-plan scenario))
         (domain (shop3:find-domain 'defederation-preparation)))
    (list :scenario scenario :reference "Zettel 11560, building on Zettel 11483"
          :initial-state (scenario-state scenario)
          :tasks '((prepare-defederation :local-wiki :target-page))
          :domain domain :methods (shop3:domain-methods domain)
          :problem (shop3:find-problem (dreyeck/shop3:problem-name-of result))
          :result result :outcome (planning-outcome result)
          :execution :not-executed
          :limits '(:hypothetical-observations :simulated-transitions
                    :one-required-target :no-refederation :no-executor))))
