(:refactor-hyperdoc-fourth-extraction-htn-assimilation
 (:operation (!assimilate-fourth-refactoring-episode-into-htn))
 (:source-selection
  "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp")
 (:source-review
  "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-review.sexp")
 (:source-execution
  "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-result.sexp")
 (:source-post-review
  "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-post-review.sexp")
 (:updated-task-library
  "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")
 (:reuse-decision
  (:reused-abstract-tasks
   (!locate-reusable-htn-tasks-before-specialization
    !classify-refactoring-candidate-ownership
    !select-low-risk-downstream-extraction-slice
    !review-selected-extraction-slice-before-execution
    !execute-reviewed-extraction-slice
    !review-executed-extraction-slice
    !assimilate-refactoring-episode-into-htn))
   (:new-abstract-tasks nil)
   (:reason
    "The fourth extraction repeated the established selection, review, execution, post-review, and assimilation cycle without requiring a new method pattern."))
 (:specialized-task-relations
  ((!select-fourth-low-risk-dreyeck-extraction-slice
    :specializes !select-low-risk-downstream-extraction-slice)
   (!review-fourth-slice-selection-before-execution
    :specializes !review-selected-extraction-slice-before-execution)
   (!execute-fourth-low-risk-dreyeck-extraction-slice
    :specializes !execute-reviewed-extraction-slice)
   (!review-fourth-extraction-slice-after-execution
    :specializes !review-executed-extraction-slice)
   (!assimilate-fourth-refactoring-episode-into-htn
    :specializes !assimilate-refactoring-episode-into-htn)))
 (:episode-result
  (:moved-file
   ("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
    "dreyeck/build/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"))
  (:target-system :dreyeck/build)
  (:post-review-verdict :accepted)
  (:live-old-path-references nil)
  (:compatibility-shell-required-p nil)
  (:asdf-update-required-p nil))
 (:validations
  ((:task-library-read :passed)
   (:assimilation-artifact-read :passed)
   (:git-diff-check :passed)
   (:hyperdoc-load :passed)
   (:shop3-provider-boundary-tests :passed)))
 (:next (!select-fifth-low-risk-dreyeck-extraction-slice)))
