;;;; Smoke tests for the Goldberg Programmer-as-Reader HyperDoc Zettel slice.

(defpackage #:hyperdoc-goldberg-programmer-as-reader/tests
  (:use #:cl)
  (:export #:run-goldberg-reader-zettel-smoke-tests))

(in-package #:hyperdoc-goldberg-programmer-as-reader/tests)

(defun assert-true (condition format-control &rest format-arguments)
  (unless condition
    (error "Smoke test failed: ~?" format-control format-arguments)))

(defun unique-p (items &key (test #'eql))
  (= (length items) (length (remove-duplicates items :test test))))

(defun run-goldberg-reader-zettel-smoke-tests ()
  (let* ((topics (hyperdoc-goldberg-programmer-as-reader:all-goldberg-topics))
         (questions (hyperdoc-goldberg-programmer-as-reader:all-goldberg-reader-questions))
         (operations (hyperdoc-goldberg-programmer-as-reader:all-goldberg-reader-operations))
         (question-ids (mapcar #'hyperdoc-goldberg-programmer-as-reader:id-of questions))
         (operation-ids (mapcar #'hyperdoc-goldberg-programmer-as-reader:id-of operations)))
    (assert-true (= 12 (length questions))
                 "expected 12 reader questions, got ~D" (length questions))
    (assert-true (= 12 (length operations))
                 "expected 12 reader operations, got ~D" (length operations))
    (assert-true (>= (length topics) 15)
                 "expected at least 15 topics, got ~D" (length topics))
    (assert-true (unique-p (mapcar #'hyperdoc-goldberg-programmer-as-reader:id-of topics)
                           :test #'string=)
                 "topic ids must be unique")
    (assert-true (unique-p question-ids)
                 "question ids must be unique")
    (assert-true (unique-p operation-ids)
                 "operation ids must be unique")
    (dolist (question questions)
      (assert-true (member (hyperdoc-goldberg-programmer-as-reader:operation-id-of question)
                           operation-ids)
                   "question ~S points to missing operation ~S"
                   (hyperdoc-goldberg-programmer-as-reader:id-of question)
                   (hyperdoc-goldberg-programmer-as-reader:operation-id-of question)))
    (dolist (operation operations)
      (assert-true (member (hyperdoc-goldberg-programmer-as-reader:question-id-of operation)
                           question-ids)
                   "operation ~S points to missing question ~S"
                   (hyperdoc-goldberg-programmer-as-reader:id-of operation)
                   (hyperdoc-goldberg-programmer-as-reader:question-id-of operation)))
    (assert-true (hyperdoc-goldberg-programmer-as-reader:goldberg-reader-question-demo :what-is-that)
                 "expected a demo for :WHAT-IS-THAT")
    (format t "~&Goldberg Programmer-as-Reader Zettel smoke tests passed: ~D topics, ~D questions, ~D operations.~%"
            (length topics) (length questions) (length operations))
    t))
