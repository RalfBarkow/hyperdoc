(define (problem document-bounded-convergent-association-edge-reassignment)
  (:domain operation-reader-surface-documentation)
  (:objects
    bounded-convergent-association-edge-reassignment - operation
    document-bounded-convergent-association-edge-reassignment-problem - artifact
    document-operation-reader-surface-shop3-plan - artifact
    bounded-convergent-association-edge-reassignment-topic - topic
    bounded-convergent-association-edge-reassignment-page - page
    bounded-convergent-association-edge-reassignment-reader-surface - surface)
  (:init
    (operation bounded-convergent-association-edge-reassignment)
    (pddl-problem-artifact document-bounded-convergent-association-edge-reassignment-problem)
    (shop3-plan-artifact document-operation-reader-surface-shop3-plan)
    (documentation-topic bounded-convergent-association-edge-reassignment-topic)
    (fedwiki-page bounded-convergent-association-edge-reassignment-page)
    (reader-surface bounded-convergent-association-edge-reassignment-reader-surface))
  (:goal
    (operation-reader-surface-documented bounded-convergent-association-edge-reassignment)))
