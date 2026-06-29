(:shop3-plan-artifact
 (:id document-operation-reader-surface)
 (:title "Document Operation Reader Surface")
 (:type :shop3-plan)
 (:planner :shop3)
 (:domain-purpose "Create a reusable reader-surface documentation path for any maintained graph operation.")
 (:created-before-implementation t)
 (:repo-root "/Users/rgb/workspace/hyperdoc")

 (:domain
  (defdomain operation-reader-surface-documentation
    ((:operator (!inspect-operation-contract ?operation)
      ((operation ?operation))
      ()
      ((operation-contract-inspected ?operation)))

     (:operator (!derive-reader-question ?operation)
      ((operation-contract-inspected ?operation))
      ()
      ((reader-question-derived ?operation)))

     (:operator (!derive-atomic-and-derivative-effect-model ?operation)
      ((reader-question-derived ?operation))
      ()
      ((effect-model-derived ?operation)))

     (:operator (!write-pddl-problem-artifact ?operation ?artifact)
      ((effect-model-derived ?operation)
       (pddl-problem-artifact ?artifact))
      ()
      ((pddl-problem-written ?operation ?artifact)))

     (:operator (!write-shop3-plan-artifact ?operation ?plan)
      ((effect-model-derived ?operation)
       (shop3-plan-artifact ?plan))
      ()
      ((shop3-plan-written ?operation ?plan)))

     (:operator (!create-dmx-documentation-topic ?operation ?topic)
      ((effect-model-derived ?operation)
       (documentation-topic ?topic))
      ()
      ((dmx-documentation-topic-created ?operation ?topic)))

     (:operator (!create-fedwiki-page ?operation ?page)
      ((effect-model-derived ?operation)
       (fedwiki-page ?page))
      ()
      ((fedwiki-page-created ?operation ?page)))

     (:operator (!create-reader-surface ?operation ?surface ?topic ?page)
      ((dmx-documentation-topic-created ?operation ?topic)
       (fedwiki-page-created ?operation ?page)
       (reader-surface ?surface))
      ()
      ((reader-surface-created ?operation ?surface ?topic ?page)))

     (:operator (!answer-goldberg-questions ?operation)
      ((reader-question-derived ?operation))
      ()
      ((goldberg-questions-answered ?operation)))

     (:operator (!validate-reader-surface-documentation ?operation ?surface)
      ((reader-surface-created ?operation ?surface ?topic ?page)
       (goldberg-questions-answered ?operation))
      ()
      ((reader-surface-documentation-validated ?operation ?surface)
       (operation-reader-surface-documented ?operation)))

     (:method (document-operation-reader-surface ?operation)
      ((operation ?operation)
       (pddl-problem-artifact ?artifact)
       (shop3-plan-artifact ?plan)
       (documentation-topic ?topic)
       (fedwiki-page ?page)
       (reader-surface ?surface))
      ((!inspect-operation-contract ?operation)
       (!derive-reader-question ?operation)
       (!derive-atomic-and-derivative-effect-model ?operation)
       (!write-pddl-problem-artifact ?operation ?artifact)
       (!write-shop3-plan-artifact ?operation ?plan)
       (!create-dmx-documentation-topic ?operation ?topic)
       (!create-fedwiki-page ?operation ?page)
       (!create-reader-surface ?operation ?surface ?topic ?page)
       (!answer-goldberg-questions ?operation)
       (!validate-reader-surface-documentation ?operation ?surface))))))

 (:problem
  (defproblem document-bounded-convergent-association-edge-reassignment
    operation-reader-surface-documentation
    ((operation bounded-convergent-association-edge-reassignment)
     (pddl-problem-artifact
      document-bounded-convergent-association-edge-reassignment-problem)
     (shop3-plan-artifact document-operation-reader-surface-shop3-plan)
     (documentation-topic
      bounded-convergent-association-edge-reassignment-topic)
     (fedwiki-page bounded-convergent-association-edge-reassignment-page)
     (reader-surface
      bounded-convergent-association-edge-reassignment-reader-surface))
    ((document-operation-reader-surface
      bounded-convergent-association-edge-reassignment))))

 (:selected-plan
  ((!inspect-operation-contract
    bounded-convergent-association-edge-reassignment)
   (!derive-reader-question
    bounded-convergent-association-edge-reassignment)
   (!derive-atomic-and-derivative-effect-model
    bounded-convergent-association-edge-reassignment)
   (!write-pddl-problem-artifact
    bounded-convergent-association-edge-reassignment
    document-bounded-convergent-association-edge-reassignment-problem)
   (!write-shop3-plan-artifact
    bounded-convergent-association-edge-reassignment
    document-operation-reader-surface-shop3-plan)
   (!create-dmx-documentation-topic
    bounded-convergent-association-edge-reassignment
    bounded-convergent-association-edge-reassignment-topic)
   (!create-fedwiki-page
    bounded-convergent-association-edge-reassignment
    bounded-convergent-association-edge-reassignment-page)
   (!create-reader-surface
    bounded-convergent-association-edge-reassignment
    bounded-convergent-association-edge-reassignment-reader-surface
    bounded-convergent-association-edge-reassignment-topic
    bounded-convergent-association-edge-reassignment-page)
   (!answer-goldberg-questions
    bounded-convergent-association-edge-reassignment)
   (!validate-reader-surface-documentation
    bounded-convergent-association-edge-reassignment
    bounded-convergent-association-edge-reassignment-reader-surface)))

 (:output-contract
  ((general-task
    (document-operation-reader-surface ?operation))
   (current-instance
    (document-operation-reader-surface
     bounded-convergent-association-edge-reassignment))
   (required-reader-question
    "Did one association edge move from the old target to the new target, and were there any unexpected graph changes?")
   (required-surfaces
    (dmx-documentation-topic fedwiki-page primary-reader-surface))
   (validation
    ((dmx-sqlite-tests-pass t)
     (dreyeck-codex-explorer-loads t)
     (fedwiki-page-artifact-exists t)
     (primary-reader-surface-precedes-raw-materializer-dump t))))))
