(:shop3-plan-artifact
 (:id kernighan-plauger-critical-reading-style)
 (:title "Kernighan/Plauger critical reading to rewriting style plan")
 (:type :shop3-plan)
 (:planner :shop3-style-ordered-task-decomposition)
 (:status :implemented-validated-pending-commit)
 (:created-before-implementation t)
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:execution-status
  ((planned t)
   (implemented t)
   (validated t)
   (commit-status :pending-implementation-commit)
   (plan-commit "fb534f63245bc52d8bfe156769c1007aed3740b4")
   (implementation-commit nil)
   (closeout-commit nil)))

 (:problem-topic
  (kernighan-plauger-critical-reading-style
   :title "Kernighan/Plauger critical reading to rewriting style"
   :summary
   "Programs can execute successfully while remaining hard for human readers to understand, criticize, rewrite, maintain, and learn from. The base plan records the concrete critical-reading cycle that turns a poor example into a clearer rewrite and then into a reusable style rule."))

 (:source-lineage
  ((kernighan-plauger-1974
    :title "The Elements of Programming Style"
    :role :base-method
    :claim
    "Study real program examples, criticize shortcomings, rewrite the example, and derive a general style rule from the concrete improvement.")
   (goldberg-1987
    :title "Programmer as Reader"
    :role :environment-restatement
    :claim
    "Programmer as reader is a problem statement: programs and systems must support human reading, especially in exploratory programming environments.")
   (knuth-1986
    :title "How to Read a Web"
    :role :projection-response
    :claim
    "A WEB program remains a program, but it can be arranged in reader order while preserving a machine-order projection.")))

 (:long-recognized-problem
  ((program-execution-problem
    :question "Does the program run?"
    :boundary
    "Execution correctness answers whether the machine can perform the program under the tested conditions.")
   (program-readability-problem
    :question
    "Can a human reader understand what the program means, criticize it, rewrite it, maintain it, and derive a transferable style rule?"
    :boundary
    "Readability correctness answers whether the program can be used as material for human comprehension, criticism, maintenance, and style learning.")
   (distinction
    "A running program may still fail the reader. Kernighan/Plauger supply the base training cycle for that failure; Goldberg restates the failure as a system-support problem; Knuth supplies one projection-oriented response.")))

 (:non-goals
  ((not-a-full-kernighan-plauger-edition)
   (not-a-verbatim-source-excerpt-collection)
   (not-a-complete-programming-style-linter)
   (not-a-fedwiki-page-store-or-asset-store-change)
   (not-a-replacement-for-goldberg-reader-operations)
   (not-a-replacement-for-knuth-web-reader-order-machine-order-projection)))

 (:repository-boundaries
  ((hyperdoc-repository "/Users/rgb/workspace/hyperdoc/")
   (allowed-plan-artifact
    "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp")
   (implementation-scope
    ("hyperdoc/*.lisp"
     "hyperdoc/*.html"
     "hyperdoc/topics/*.lisp"
     "hyperdoc-inspector/*.lisp"
     "tests/*.lisp"
     "hyperdoc.asd"))
   (fedwiki-page-store "/Users/rgb/.wiki/wiki.ralfbarkow.ch/pages/")
   (fedwiki-asset-store "/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/")
   (fedwiki-store-boundary :do-not-touch-in-this-slice)))

 (:reviewed-context
  ((goldberg-slice
    ("hyperdoc-goldberg-programmer-as-reader.asd"
     "hyperdoc-goldberg-programmer-as-reader/src/model.lisp"
     "hyperdoc-goldberg-programmer-as-reader/src/data.lisp"
     "hyperdoc-goldberg-programmer-as-reader/src/operations.lisp"
     "hyperdoc-goldberg-programmer-as-reader/src/topics.lisp"
     "hyperdoc/Goldberg Programmer as Reader.html"
     "hyperdoc/Goldberg reader operations.html"))
   (knuth-web-slice
    ("hyperdoc/How to Read a Web.html"
     "hyperdoc/How to Read a Web topic arrangement.html"
     "hyperdoc/How to Read a Web reader operations.html"
     "hyperdoc/How to Read a Web function coverage.html"))
   (shop3-plan-artifacts
    ("hyperdoc/add-plan-then-perform-session-state-to-dreyeck-build-plan.sexp"
     "hyperdoc/materialize-build-referee-learning-topics-plan.sexp"
     "hyperdoc/path-sensitive-hyperdoc-pre-commit-gate-plan.sexp"
     "hyperdoc-shop3/shop3-parser-documentation-plan.sexp"))
   (critic-and-review-contracts
    ("hyperdoc/lisp-critic-review-plan.lisp"
     "hyperdoc/lisp-critic-contracts.lisp"
     "hyperdoc/topics/surfaces.lisp"
     "tests/lisp-critic-review-plan-smoke.lisp"
     "tests/lisp-critic-contract-smoke.lisp"))
   (topic-constructor-families
    ("hyperdoc/topics/surfaces.lisp"
     "hyperdoc/topics/source-stations.lisp"
     "hyperdoc/topics/shop3-introduction.lisp"))))

 (:domain
  (defdomain kernighan-plauger-critical-reading-domain
    ((:operator
      (establish-programming-style-readability-problem)
      ((source-lineage-known kernighan-plauger goldberg knuth))
      ()
      ((readability-problem-established)))

     (:operator
      (select-real-program-example)
      ((readability-problem-established))
      ()
      ((real-program-example-selected)))

     (:operator
      (read-program-critically)
      ((real-program-example-selected))
      ()
      ((critical-reading-recorded)))

     (:operator
      (identify-obscure-expressions)
      ((critical-reading-recorded))
      ()
      ((obscure-expressions-identified)))

     (:operator
      (identify-confusing-control-flow)
      ((critical-reading-recorded))
      ()
      ((confusing-control-flow-identified)))

     (:operator
      (identify-poor-data-representation)
      ((critical-reading-recorded))
      ()
      ((poor-data-representation-identified)))

     (:operator
      (identify-missing-validity-boundary-checks)
      ((critical-reading-recorded))
      ()
      ((missing-validity-boundary-checks-identified)))

     (:operator
      (rewrite-program-for-clarity)
      ((obscure-expressions-identified)
       (confusing-control-flow-identified)
       (poor-data-representation-identified)
       (missing-validity-boundary-checks-identified))
      ()
      ((program-rewritten-for-clarity)))

     (:operator
      (compare-original-and-rewrite)
      ((program-rewritten-for-clarity))
      ()
      ((before-after-comparison-recorded)))

     (:operator
      (derive-style-rule-from-rewrite)
      ((before-after-comparison-recorded))
      ()
      ((style-rule-derived)))

     (:operator
      (record-critical-reading-lesson)
      ((style-rule-derived))
      ()
      ((critical-reading-lesson-recorded)))

     (:operator
      (connect-base-plan-to-goldberg-reader-questions)
      ((critical-reading-lesson-recorded))
      ()
      ((goldberg-reader-question-crosswalk-recorded)))

     (:operator
      (connect-base-plan-to-knuth-web-projections)
      ((critical-reading-lesson-recorded))
      ()
      ((knuth-web-projection-crosswalk-recorded)))

     (:operator
      (validate-critical-reading-plan-artifact)
      ((goldberg-reader-question-crosswalk-recorded)
       (knuth-web-projection-crosswalk-recorded))
      ()
      ((critical-reading-plan-artifact-validated)))

     (:method
      (implement-kernighan-plauger-critical-reading-style)
      ((source-lineage-known kernighan-plauger goldberg knuth))
      ((establish-programming-style-readability-problem)
       (select-real-program-example)
       (read-program-critically)
       (identify-obscure-expressions)
       (identify-confusing-control-flow)
       (identify-poor-data-representation)
       (identify-missing-validity-boundary-checks)
       (rewrite-program-for-clarity)
       (compare-original-and-rewrite)
       (derive-style-rule-from-rewrite)
       (record-critical-reading-lesson)
       (connect-base-plan-to-goldberg-reader-questions)
       (connect-base-plan-to-knuth-web-projections)
       (validate-critical-reading-plan-artifact))))))

 (:problem
  (defproblem kernighan-plauger-critical-reading-style-problem
    kernighan-plauger-critical-reading-domain
    ((source-lineage-known kernighan-plauger goldberg knuth)
     (repository-boundary hyperdoc-repository)
     (forbidden-boundary fedwiki-page-store)
     (forbidden-boundary fedwiki-asset-store))
    ((implement-kernighan-plauger-critical-reading-style))))

 (:selected-ordered-plan
  ((establish-programming-style-readability-problem)
   (select-real-program-example)
   (read-program-critically)
   (identify-obscure-expressions)
   (identify-confusing-control-flow)
   (identify-poor-data-representation)
   (identify-missing-validity-boundary-checks)
   (rewrite-program-for-clarity)
   (compare-original-and-rewrite)
   (derive-style-rule-from-rewrite)
   (record-critical-reading-lesson)
   (connect-base-plan-to-goldberg-reader-questions)
   (connect-base-plan-to-knuth-web-projections)
   (validate-critical-reading-plan-artifact)))

 (:base-cycle
  ((critical-reading
    :operation "Read the program as a human artifact, not only as an executable object.")
   (identify-shortcomings
    :operation "Name the specific obscurities, confusing flow, weak representation, or missing boundary checks that make the example hard to read.")
   (rewrite
    :operation "Change the program so the intended meaning is explicit and maintainable.")
   (compare-before-after
    :operation "Record what the rewrite made easier to see or safer to change.")
   (derive-rule
    :operation "Extract the reusable programming-style rule from the concrete rewrite.")
   (record-lesson
    :operation "Preserve the example, criticism, rewrite, comparison, and rule as an inspectable reader operation.")))

 (:implementation-output-contract
  ((model
    ((preferred-file "hyperdoc/programming-style-critical-reading.lisp")
     (fallback "extend an existing relevant HyperDoc model file only if local structure clearly demands it")
     (exports
      (kernighan-plauger-critical-reading-summary
       make-critical-reading-example
       critical-reading-examples
       critical-reading-plan
       criticize-program-fragment
       rewrite-program-fragment
       derive-style-rule
       critical-reading-report
       programming-style-coverage-report
       goldberg-long-recognized-problem-crosswalk
       knuth-web-projection-crosswalk
       inspect-kernighan-plauger-critical-reading))))
   (built-in-example
    ((source :kernighan-plauger-identity-matrix-case)
     (original-idea "A compact integer-division expression encodes identity-matrix intent.")
     (reader-problem "The reader must reconstruct the intended matrix rule from clever arithmetic.")
     (rewrite "Make the identity-matrix intent explicit.")
     (derived-rule "Write clearly; do not be too clever.")))
   (pages
    ("hyperdoc/Kernighan Plauger critical reading plan.html"
     "hyperdoc/Programming style readability problem.html"
     "hyperdoc/Critical reading to rewriting.html"
     "hyperdoc/Goldberg long recognized problem crosswalk.html"
     "hyperdoc/Knuth WEB as projection response.html"))
   (topic-constructors
    ((file "hyperdoc/topics/surfaces.lisp")
     (constructors
      (programming-style-readability-problem-topic
       kernighan-plauger-critical-reading-topic
       critical-reading-rewriting-style-rule-topic
       goldberg-long-recognized-problem-crosswalk-topic
       knuth-web-projection-response-topic))))
   (tests
    ((preferred-file "tests/programming-style-critical-reading-smoke.lisp")
     (checks
      ((exported-functions-exist t)
       (built-in-critical-reading-example-exists t)
       (report-includes-original-readability-problem-rewrite-rule t)
       (goldberg-crosswalk-includes-exploratory-environment-restatement t)
       (knuth-crosswalk-includes-reader-order-and-machine-order-projection t)
       (plan-artifact-remains-single-s-expression t))))))

 (:validation-contract
  ((plan-artifact-readable
    "sbcl --no-userinit --non-interactive --eval '(with-open-file (s \"hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp\") (read s) (format t \"SEXP_READ_OK~%\"))'")
   (plan-artifact-single-form
    "sbcl --no-userinit --non-interactive --eval '(with-open-file (s \"hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp\") (read s) (let ((tail (read s nil :eof))) (unless (eq tail :eof) (error \"Trailing form: ~S\" tail))) (format t \"SEXP_SINGLE_FORM_OK~%\"))'")
   (whitespace-check "git diff --check")
   (lisp-paren-check "tools/check-lisp-parens.sh")
   (lisp-load-gate "tools/check-lisp-load-gate.sh :hyperbook/server")
   (documentation-slice-check
    "tools/validate-documentation-slice.sh --page \"hyperdoc/Programming style readability problem.html\" --topic programming-style-readability-problem-topic --topic kernighan-plauger-critical-reading-topic --topic critical-reading-rewriting-style-rule-topic")
   (status-check "git status --short")))

 (:phase-commit-contract
  ((phase-1
    :commit-message "docs(hyperdoc): add Kernighan Plauger critical reading plan"
    :files ("hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"))
   (phase-2
    :commit-message "feat(hyperdoc): add Kernighan Plauger critical reading base plan"
    :files (:implementation-output-contract))
   (phase-3
    :commit-message "docs(hyperdoc): close Kernighan Plauger critical reading plan"
    :files ("hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"))))))
