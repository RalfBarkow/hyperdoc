(define (domain operation-reader-surface-documentation)
  (:requirements :strips :typing)
  (:types operation artifact topic page surface)

  (:predicates
    (operation ?operation - operation)
    (pddl-problem-artifact ?artifact - artifact)
    (shop3-plan-artifact ?artifact - artifact)
    (documentation-topic ?topic - topic)
    (fedwiki-page ?page - page)
    (reader-surface ?surface - surface)
    (operation-contract-inspected ?operation - operation)
    (reader-question-derived ?operation - operation)
    (effect-model-derived ?operation - operation)
    (pddl-problem-written ?operation - operation ?artifact - artifact)
    (shop3-plan-written ?operation - operation ?artifact - artifact)
    (dmx-documentation-topic-created ?operation - operation ?topic - topic)
    (fedwiki-page-created ?operation - operation ?page - page)
    (reader-surface-created ?operation - operation ?surface - surface ?topic - topic ?page - page)
    (reader-surface-ready ?operation - operation ?surface - surface)
    (goldberg-questions-answered ?operation - operation)
    (reader-surface-documentation-validated ?operation - operation ?surface - surface)
    (operation-reader-surface-documented ?operation - operation))

  (:action inspect-operation-contract
    :parameters (?operation - operation)
    :precondition (operation ?operation)
    :effect (operation-contract-inspected ?operation))

  (:action derive-reader-question
    :parameters (?operation - operation)
    :precondition (operation-contract-inspected ?operation)
    :effect (reader-question-derived ?operation))

  (:action derive-atomic-and-derivative-effect-model
    :parameters (?operation - operation)
    :precondition (reader-question-derived ?operation)
    :effect (effect-model-derived ?operation))

  (:action write-pddl-problem-artifact
    :parameters (?operation - operation ?artifact - artifact)
    :precondition (and
      (effect-model-derived ?operation)
      (pddl-problem-artifact ?artifact))
    :effect (pddl-problem-written ?operation ?artifact))

  (:action write-shop3-plan-artifact
    :parameters (?operation - operation ?artifact - artifact)
    :precondition (and
      (effect-model-derived ?operation)
      (shop3-plan-artifact ?artifact))
    :effect (shop3-plan-written ?operation ?artifact))

  (:action create-dmx-documentation-topic
    :parameters (?operation - operation ?topic - topic)
    :precondition (effect-model-derived ?operation)
    :effect (dmx-documentation-topic-created ?operation ?topic))

  (:action create-fedwiki-page
    :parameters (?operation - operation ?page - page)
    :precondition (effect-model-derived ?operation)
    :effect (fedwiki-page-created ?operation ?page))

  (:action create-reader-surface
    :parameters (?operation - operation ?surface - surface ?topic - topic ?page - page)
    :precondition (and
      (dmx-documentation-topic-created ?operation ?topic)
      (fedwiki-page-created ?operation ?page))
    :effect (and
      (reader-surface-created ?operation ?surface ?topic ?page)
      (reader-surface-ready ?operation ?surface)))

  (:action answer-goldberg-questions
    :parameters (?operation - operation)
    :precondition (reader-question-derived ?operation)
    :effect (goldberg-questions-answered ?operation))

  (:action validate-reader-surface-documentation
    :parameters (?operation - operation ?surface - surface)
    :precondition (and
      (reader-surface-ready ?operation ?surface)
      (goldberg-questions-answered ?operation))
    :effect (and
      (reader-surface-documentation-validated ?operation ?surface)
      (operation-reader-surface-documented ?operation))))
