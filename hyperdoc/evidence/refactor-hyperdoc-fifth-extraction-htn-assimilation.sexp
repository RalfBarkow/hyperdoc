(:refactor-hyperdoc-fifth-extraction-htn-assimilation
 (:operation (!assimilate-fifth-refactoring-episode-into-htn))
 (:source-selection
  "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp")
 (:source-review
  "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-review.sexp")
 (:source-execution
  "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-result.sexp")
 (:source-post-review
  "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-post-review.sexp")
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
    "The fifth extraction reused the same one-file data-only plan move pattern with a package-qualified text fallback for minimal-reader validation."))
 (:specialized-task-relations
  ((!select-fifth-low-risk-dreyeck-extraction-slice
    :specializes !select-low-risk-downstream-extraction-slice)
   (!review-fifth-slice-selection-before-execution
    :specializes !review-selected-extraction-slice-before-execution)
   (!execute-fifth-low-risk-dreyeck-extraction-slice
    :specializes !execute-reviewed-extraction-slice)
   (!review-fifth-extraction-slice-after-execution
    :specializes !review-executed-extraction-slice)
   (!assimilate-fifth-refactoring-episode-into-htn
    :specializes !assimilate-refactoring-episode-into-htn)))
 (:episode-result
  (:moved-file
   ("hyperdoc/render-build-referee-decisions-as-routes-plan.sexp"
    "dreyeck/build/render-build-referee-decisions-as-routes-plan.sexp"))
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
 (:next (!select-sixth-low-risk-dreyeck-extraction-slice)))
