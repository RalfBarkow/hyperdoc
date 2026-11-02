;;;; Package for assessing what new upstream commits mean for dreyeck.ch. Read-only: nothing here loads, compiles or evaluates library code.

(defpackage #:dreyeck/upstream-assessment
  (:use #:cl)
  (:local-nicknames (#:g #:dreyeck/git) (#:src #:dreyeck/asdf-source))
  (:export
   ;; epistemic statuses (the vocabulary of the workflow reading: :SOURCE-OBSERVED, :MECHANICALLY-DERIVED, :DESIGN-INFERENCE, :WORKING-HYPOTHESIS)
   #:+epistemic-statuses+ #:claim #:make-claim #:claim-text #:claim-status #:claim-basis
   ;; syntax of source text, without READ
   #:source-definition #:source-definition-key #:source-definition-kind #:source-definition-name #:source-definition-tree
   #:source-definition-text #:source-definition-digest #:source-definition-path #:top-level-definitions
   #:tree-text #:tree-digest #:changed-fragments #:handler-profiles #:tree-contains-p
   ;; repositories and commit evidence
   #:open-repository #:upstream-observation #:observe-upstream #:upstream-observation-ref #:upstream-observation-tip
   #:upstream-observation-repository #:upstream-observation-tip-present-p #:commits-between
   #:commit-evidence #:commit-evidence-sha #:commit-evidence-parents #:commit-evidence-subject #:commit-evidence-authored-at
   #:commit-evidence-origin #:commit-evidence-changes #:commit-evidence-files #:commit-evidence-availability
   #:evidence-from-repository #:missing-evidence #:read-recorded-evidence #:write-recorded-evidence #:recorded-evidence-form
   #:verify-recorded-evidence
   #:definition-change #:definition-change-key #:definition-change-kind #:definition-change-path #:definition-change-before
   #:definition-change-after #:definition-change-fragments #:definition-change-handlers #:definition-change-counterparts #:definition-changes #:loose-key
   ;; the fork
   #:fork-index #:make-fork-index #:fork-integration #:fork-situation #:fork-situation-relation #:fork-situation-locations
   #:fork-situation-fragments #:fork-situation-claims #:fork-situation-counterparts #:situation-of #:situation-digest
   #:ownership-policy #:make-ownership-policy #:ownership-of #:system-owners-of #:dependent-systems
   #:impact-of #:impact-systems #:impact-tests #:impact-callers #:impact-pages #:impact-contracts #:impact-claims
   ;; decisions
   #:decision #:make-decision #:decision-id #:decision-commit #:decision-subject #:decision-kind #:decision-status
   #:decision-rationale #:decision-evidence #:decision-required-migration #:decision-verification #:decision-proposed-by
   #:+decision-kinds+ #:propose-decision #:ledger #:make-ledger #:ledger-decisions #:ledger-record #:ledger-find #:ledger-history #:decision-supersedes #:decision-assessed-situation
   #:ledger-from-form #:ledger-form #:read-ledger #:write-ledger #:decision-conflict
   ;; the assessment as a whole
   #:change-assessment #:change-assessment-change #:change-assessment-situation #:change-assessment-owners
   #:change-assessment-commit #:change-assessment-situation-digest #:change-assessment-stale #:change-assessment-ownership #:change-assessment-impact #:change-assessment-proposal #:change-assessment-recorded
   #:commit-assessment #:commit-assessment-evidence #:commit-assessment-integration #:commit-assessment-changes
   #:commit-assessment-source-adoption #:commit-assessment-notes
   #:intake-run #:intake-run-observation #:intake-run-last-examined #:intake-run-commits #:intake-run-status #:intake-run-state
   #:assess-commit #:assess-upstream #:report-run #:run-exit-status
   #:read-state #:write-state #:state-last-examined #:default-ownership-policy #:read-evidence-directory #:+library-paths+))
