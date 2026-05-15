;;;; Package for the Goldberg Programmer-as-Reader HyperDoc Zettel slice.

(defpackage #:hyperdoc-goldberg-programmer-as-reader
  (:use #:cl)
  (:nicknames #:goldberg-reader)
  (:export
   ;; model
   #:goldberg-topic
   #:goldberg-reader-question
   #:goldberg-reader-operation
   #:id-of
   #:title-of
   #:summary-of
   #:references-of
   #:layer-of
   #:question-number-of
   #:question-text-of
   #:prompt-of
   #:operation-id-of
   #:question-id-of
   #:preconditions-of
   #:steps-of
   #:result-of
   #:clickable-expression-of
   ;; registries
   #:all-goldberg-topics
   #:goldberg-topic-by-id
   #:goldberg-topic-by-title
   #:all-goldberg-reader-questions
   #:goldberg-reader-question-by-id
   #:all-goldberg-reader-operations
   #:goldberg-reader-operation-by-id
   ;; examples and operations
   #:goldberg-zettel-summary
   #:goldberg-layer-overview
   #:goldberg-reader-question-demo
   #:goldberg-reader-question-operation
   #:goldberg-operation-report
   #:goldberg-reader-question-matrix
   ;; topic constructors
   #:goldberg-programmer-as-reader-topic
   #:goldberg-programmer-as-reader-arrangement-topic
   #:goldberg-reading-comprehension-questions-topic
   #:goldberg-reader-operations-topic
   #:goldberg-smalltalk-hyperdoc-crosswalk-topic
   ;; integration/materialization
   #:register-goldberg-topics-into-hyperdoc
   #:materialize-goldberg-hyperdoc-pages
   #:goldberg-source-citation))

(defpackage #:hyperdoc-goldberg-programmer-as-reader/tests
  (:use #:cl)
  (:export #:run-goldberg-reader-zettel-smoke-tests))
