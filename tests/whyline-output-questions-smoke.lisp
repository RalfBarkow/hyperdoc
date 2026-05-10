;;;; Smoke tests for Whyline-style output questions
;;
;; This file intentionally creates HYPERDOC/TESTS before IN-PACKAGE
;; so it can be loaded directly from SLY as well as through ASDF.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-WHYLINE-OUTPUT-QUESTIONS-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun whyline-smoke-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun run-whyline-output-questions-smoke-tests ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((run (hyperdoc::whyline-color-demo-run))
         (questions (hyperdoc::whyline-run-questions run))
         (why-did (find :why-did questions
                        :key #'hyperdoc::whyline-demo-kind-of))
         (why-not (find :why-not questions
                        :key #'hyperdoc::whyline-demo-kind-of))
         (answer (hyperdoc::whyline-answer-question run why-did))
         (graph (hyperdoc::whyline-demo-graph-of answer))
         (dot (hyperdoc::code-path-graph-dot-text graph)))
    (whyline-smoke-assert-true run "Demo run should exist.")
    (whyline-smoke-assert-true why-did "Demo must expose a why-did question.")
    (whyline-smoke-assert-true why-not "Demo must expose a why-not question.")
    (whyline-smoke-assert-true graph "Answer must expose a code-path graph.")
    (whyline-smoke-assert-true
     (hyperdoc::code-path-graph-trace-event-seq graph)
     "Answer graph must carry trace events.")
    (whyline-smoke-assert-true
     (hyperdoc::code-path-graph-focus-path-seq graph)
     "Answer graph must carry at least one focused path.")
    (whyline-smoke-assert-true
     (search "green-slider" dot)
     "DOT export must mention the wrong value source.")
    (whyline-smoke-assert-true
     (search "blue-slider" dot)
     "DOT export must mention the expected value source.")
    (format t "~&Whyline output-question smoke tests passed.~%")
    t))
