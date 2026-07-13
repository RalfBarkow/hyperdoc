;;;; Runtime smoke test for the live SHOP3 commit-3 localization problem.

(in-package #:dreyeck/shop3/extraction-planning/tests)

(defun commit-3-smoke-assert (condition message)
  (unless condition
    (error "~A" message)))

(defun run-eighth-extraction-commit-3-localization-smoke-tests ()
  (let* ((domain-symbol
           'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-localization-domain)
         (problem-symbol
           'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-localization)
         (package (find-package :dreyeck/shop3))
         (resolved-problem-symbol
           (and package
                (find-symbol
                 "EIGHTH-DREYECK-EXTRACTION-COMMIT-3-LOCALIZATION"
                 package))))
    (commit-3-smoke-assert
     (shop3:find-domain domain-symbol nil)
     "The commit-3 localization domain must be registered.")
    (commit-3-smoke-assert
     (shop3:find-problem problem-symbol nil)
     "The commit-3 localization problem must be registered.")
    (commit-3-smoke-assert
     (eq problem-symbol resolved-problem-symbol)
     "The problem symbol must be owned by DREYECK/SHOP3."))
  (let* ((result
           (dreyeck/shop3::run-eighth-dreyeck-extraction-commit-3-localization-plan))
         (raw-plans (getf result :raw-plans))
         (shorter-plans (getf result :shorter-plans))
         (plan (first shorter-plans))
         (expected-plan
           '((dreyeck/shop3::!record-no-specialized-plan-found
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "59639866a1bb4aa9f27ddc43c383bd2907d196b3")
             (dreyeck/shop3::!classify-legacy-implementation-copy-set
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "59639866a1bb4aa9f27ddc43c383bd2907d196b3")
             (dreyeck/shop3::!classify-live-and-historical-references
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "59639866a1bb4aa9f27ddc43c383bd2907d196b3")
             (dreyeck/shop3::!select-commit-3-preparation-boundary
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "59639866a1bb4aa9f27ddc43c383bd2907d196b3")
             (dreyeck/shop3::!record-localization-result
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "59639866a1bb4aa9f27ddc43c383bd2907d196b3")))
         (final-state (first (getf result :final-states)))
         (localization-atom
           '(dreyeck/shop3::commit-3-localization-recorded
             "/Users/rgb/workspace/hyperdoc/"
             dreyeck/shop3::hauptsache
             "59639866a1bb4aa9f27ddc43c383bd2907d196b3"))
         (next-task-atom
           '(dreyeck/shop3::next-task
             dreyeck/shop3::prepare-eighth-dreyeck-extraction-commit-3)))
    (commit-3-smoke-assert
     (and raw-plans (= 1 (length raw-plans)))
     "Live SHOP3 must return exactly one first plan.")
    (commit-3-smoke-assert
     (equal expected-plan plan)
     "The shortened plan must contain the exact five package-aware actions.")
    (commit-3-smoke-assert
     (= 5 (length plan))
     "The shortened localization plan must contain five operators.")
    (commit-3-smoke-assert
     (getf result :plan-trees)
     "The live planner result must contain a plan tree.")
    (commit-3-smoke-assert
     (getf result :final-states)
     "The live planner result must contain a final state.")
    (commit-3-smoke-assert
     (member localization-atom final-state :test #'equal)
     "The final state must record completed localization.")
    (commit-3-smoke-assert
     (member next-task-atom final-state :test #'equal)
     "The final state must select commit-3 preparation next.")
    (commit-3-smoke-assert
     (eq :shop3 (getf result :planner))
     "The runtime result must identify SHOP3 as its planner.")
    (commit-3-smoke-assert
     (eq :live (getf result :planner-call))
     "The runtime result must identify a live planner call.")
    (commit-3-smoke-assert
     (null (getf result :heuristic-fallback))
     "The runner must not expose a heuristic fallback."))
  (format t "~&Eighth extraction commit-3 SHOP3 localization smoke tests passed.~%")
  t)

(defun run-eighth-extraction-commit-3-preparation-smoke-tests ()
  (let* ((domain-symbol
           'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-preparation-domain)
         (problem-symbol
           'dreyeck/shop3::eighth-dreyeck-extraction-commit-3-preparation)
         (package (find-package :dreyeck/shop3))
         (resolved-problem-symbol
           (and package
                (find-symbol
                 "EIGHTH-DREYECK-EXTRACTION-COMMIT-3-PREPARATION"
                 package))))
    (commit-3-smoke-assert
     (shop3:find-domain domain-symbol nil)
     "The commit-3 preparation domain must be registered.")
    (commit-3-smoke-assert
     (shop3:find-problem problem-symbol nil)
     "The commit-3 preparation problem must be registered.")
    (commit-3-smoke-assert
     (eq problem-symbol resolved-problem-symbol)
     "The preparation problem symbol must be owned by DREYECK/SHOP3."))
  (let* ((result
           (dreyeck/shop3::run-eighth-dreyeck-extraction-commit-3-preparation-plan))
         (raw-plans (getf result :raw-plans))
         (shorter-plans (getf result :shorter-plans))
         (plan (first shorter-plans))
         (expected-plan
           '((dreyeck/shop3::!confirm-live-localization-basis
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "ab1926eb807e5e8721b888a34736ada458209a40")
             (dreyeck/shop3::!select-legacy-copy-deletion-set
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "ab1926eb807e5e8721b888a34736ada458209a40")
             (dreyeck/shop3::!select-reference-lint-design
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "ab1926eb807e5e8721b888a34736ada458209a40")
             (dreyeck/shop3::!classify-reference-policy
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "ab1926eb807e5e8721b888a34736ada458209a40")
             (dreyeck/shop3::!define-commit-3-execution-contract
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "ab1926eb807e5e8721b888a34736ada458209a40")
             (dreyeck/shop3::!record-commit-3-preparation
              "/Users/rgb/workspace/hyperdoc/"
              dreyeck/shop3::hauptsache
              "ab1926eb807e5e8721b888a34736ada458209a40")))
         (final-state (first (getf result :final-states)))
         (prepared-atom
           '(dreyeck/shop3::commit-3-prepared
             "/Users/rgb/workspace/hyperdoc/"
             dreyeck/shop3::hauptsache
             "ab1926eb807e5e8721b888a34736ada458209a40"))
         (next-task-atom
           '(dreyeck/shop3::next-task
             dreyeck/shop3::execute-eighth-dreyeck-extraction-commit-3)))
    (commit-3-smoke-assert
     (and raw-plans (= 1 (length raw-plans)))
     "Live SHOP3 must return exactly one first preparation plan.")
    (commit-3-smoke-assert
     (equal expected-plan plan)
     "The preparation plan must contain the exact six package-aware actions.")
    (commit-3-smoke-assert
     (= 6 (length plan))
     "The shortened preparation plan must contain six operators.")
    (commit-3-smoke-assert
     (getf result :plan-trees)
     "The live preparation result must contain a plan tree.")
    (commit-3-smoke-assert
     (getf result :final-states)
     "The live preparation result must contain a final state.")
    (commit-3-smoke-assert
     (member prepared-atom final-state :test #'equal)
     "The final state must record completed commit-3 preparation.")
    (commit-3-smoke-assert
     (member next-task-atom final-state :test #'equal)
     "The final state must select commit-3 execution next.")
    (commit-3-smoke-assert
     (eq :shop3 (getf result :planner))
     "The preparation result must identify SHOP3 as its planner.")
    (commit-3-smoke-assert
     (eq :live (getf result :planner-call))
     "The preparation result must identify a live planner call.")
    (commit-3-smoke-assert
     (null (getf result :heuristic-fallback))
     "The preparation runner must not expose a heuristic fallback."))
  (format t "~&Eighth extraction commit-3 SHOP3 preparation smoke tests passed.~%")
  t)

(defun run-eighth-extraction-commit-3-localization-smoke-tests-and-preparation ()
  (run-eighth-extraction-commit-3-localization-smoke-tests)
  (run-eighth-extraction-commit-3-preparation-smoke-tests))
