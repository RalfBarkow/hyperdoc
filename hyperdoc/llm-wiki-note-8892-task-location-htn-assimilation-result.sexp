
(:artifact llm-wiki-note-8892-task-location-htn-assimilation-result :kind
 repository-hygiene-and-htn-assimilation-result :status recorded
 :detected-after
 (!close-llm-wiki-note-8892-okf-profile-materialization-slice :mode
  :record-closure)
 :problem
 (:untracked-project-owned-artifact
  "hyperdoc/task-location-problem-determined-htn.sexp"
  :why-it-must-not-remain-untracked
  "The path is under hyperdoc/ and names a task-location HTN artifact. It is durable project state, not scratch state.")
 :responsible-missing-closure-subtask
 (!assimilate-or-classify-project-owned-untracked-htn-artifacts
  :before-slice-closure t)
 :rectification
 (:assimilate-existing-artifact
  "hyperdoc/task-location-problem-determined-htn.sexp" :record-this-result
  "hyperdoc/llm-wiki-note-8892-task-location-htn-assimilation-result.sexp")
 :form-level-defect-repaired
 (:failed-task (!assimilate-untracked-task-location-problem-determined-htn)
  :reader-error "Comma not inside a backquote." :cause
  "The previous generated form used comma syntax in data construction. This replacement uses only ordinary LIST and QUOTE construction."
  :prevention
  "For SLY pasteable maintenance forms, avoid quasiquote/comma in generated artifact construction when ordinary LIST is sufficient.")
 :htn-correction
 (:close-slice-method-must-include
  ((!scan-project-owned-untracked-artifacts :scope
    ("hyperdoc/*.sexp" "hyperdoc/**/*.sexp"))
   (!classify-untracked-artifact :artifact ?artifact :classes
    (:durable-htn-artifact :scratch :external-unowned-state))
   (!if-durable-htn-artifact :then
    (!assimilate-artifact-into-current-slice-or-record-explicit-deferral
     :artifact ?artifact))
   (!close-slice-only-after-repository-hygiene-decision
    :allow-untracked-only-if-explicitly-classified t)))
 :read-check
 (:file "hyperdoc/task-location-problem-determined-htn.sexp" :exists t
  :readable t :form-count 6 :first-form-preview
  (:task
   (!integrate-problem-determined-systems-into-htn :source-zettel 6129
    :task-location-zettel 8992 :definition
    "48.2 Problem: A task that cannot be solved by existing routines of behavior, action, or interaction.")))
 :acceptance-criteria
 (:task-location-artifact-readable t :task-location-artifact-committed t
  :closure-no-longer-preserves-this-artifact-as-untracked t)
 :next
 (!verify-hyperdoc-status-after-task-location-assimilation :mode :read-only))
