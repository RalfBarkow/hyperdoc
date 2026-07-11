(:refactor-hyperdoc-sixth-extraction-htn-assimilation
 (:operation (!assimilate-sixth-extraction-slice-into-reusable-htn))
 (:base "40ec30c1")
 (:reusable-task-library "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")
 (:input-episode
  (:selection "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp")
  (:review "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-review.sexp")
  (:execution "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-result.sexp")
  (:post-review "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-post-review.sexp"))
 (:reused-abstract-tasks
  (!locate-reusable-htn-tasks-before-specialization
   !classify-refactoring-candidate-ownership
   !select-low-risk-downstream-extraction-slice
   !review-selected-extraction-slice-before-execution
   !adapt-current-plan-with-reused-or-generalized-tasks
   !execute-reviewed-extraction-slice
   !review-executed-extraction-slice
   !assimilate-refactoring-episode-into-htn))
 (:new-abstract-tasks nil)
 (:new-specializations
  ((!select-sixth-low-risk-dreyeck-extraction-slice
    :specializes !select-low-risk-downstream-extraction-slice
    :evidence "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp")
   (!review-sixth-slice-selection-before-execution
    :specializes !review-selected-extraction-slice-before-execution
    :evidence "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-review.sexp")
   (!execute-sixth-low-risk-dreyeck-extraction-slice
    :specializes !execute-reviewed-extraction-slice
    :evidence "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-result.sexp")
   (!review-sixth-extraction-slice-after-execution
    :specializes !review-executed-extraction-slice
    :evidence "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-post-review.sexp")
   (!assimilate-sixth-extraction-slice-into-reusable-htn
    :specializes !assimilate-refactoring-episode-into-htn
    :evidence "hyperdoc/evidence/refactor-hyperdoc-sixth-extraction-htn-assimilation.sexp")))
 (:plan-adaptation
  ((:status-updated
    (:from :draft-filed-out-from-temporary-topic-db-updated-through-fifth-extraction
     :to :draft-filed-out-from-temporary-topic-db-updated-through-sixth-extraction))
   (:specialized-tasks-added 5)
   (:generic-cycle-reused-p t)
   (:generalization-required-p nil)))
 (:accepted-outcome
  (:moved-file
   ("hyperdoc/inspect-dmx-materialized-learning-topics-plan.sexp"
    "dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"))
  (:target-system :dreyeck/codex)
  (:compatibility-shell-required-p nil)
  (:asdf-update-required-p nil)
  (:tracked-source-old-path-references nil))
 (:next
  (!record-sixth-dreyeck-extraction-checkpoint)))
