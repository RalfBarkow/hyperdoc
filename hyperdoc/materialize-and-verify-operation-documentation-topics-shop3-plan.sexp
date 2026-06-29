(:shop3-plan-artifact
 (:id materialize-and-verify-operation-documentation-topics)
 (:title "Materialize and Verify Operation Documentation Topics")
 (:type :shop3-plan)
 (:planner :shop3)
 (:domain-purpose
  "Materialize and verify documentation topics for any maintained graph operation in a chosen DMX SQLite DB.")
 (:repo-root "/Users/rgb/workspace/hyperdoc")
 (:created-after-existing-plan-search
  ("hyperdoc/document-operation-reader-surface-shop3-plan.sexp"
   "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"))

 (:domain
  (defdomain operation-documentation-topic-materialization
    ((:operator
      (!inspect-documentation-topic-definitions ?operation)
      ((operation-documentation-topic-known ?operation))
      ()
      ((documentation-topic-definitions-inspected ?operation)))

     (:operator
      (!derive-required-documentation-topic-ids ?operation)
      ((documentation-topic-definitions-inspected ?operation))
      ()
      ((required-documentation-topic-ids-derived ?operation)))

     (:operator
      (!materialize-documentation-topics ?operation ?db)
      ((required-documentation-topic-ids-derived ?operation)
       (dmx-production-db ?db))
      ()
      ((documentation-topics-materialized ?operation ?db)))

     (:operator
      (!materialize-documentation-topic-associations ?operation ?db)
      ((documentation-topics-materialized ?operation ?db))
      ()
      ((documentation-topic-associations-materialized ?operation ?db)))

     (:operator
      (!verify-documentation-topics-present ?operation ?db)
      ((documentation-topics-materialized ?operation ?db))
      ()
      ((documentation-topics-present ?operation ?db)))

     (:operator
      (!verify-fedwiki-page-topic-present ?operation ?db)
      ((documentation-topics-present ?operation ?db))
      ()
      ((fedwiki-page-topic-present ?operation ?db)))

     (:operator
      (!verify-reader-surface-sees-materialized-topics ?operation ?db)
      ((documentation-topics-present ?operation ?db)
       (fedwiki-page-topic-present ?operation ?db))
      ()
      ((reader-surface-sees-materialized-topics ?operation ?db)))

     (:operator
      (!record-documentation-topic-materialization-report ?operation ?db)
      ((reader-surface-sees-materialized-topics ?operation ?db))
      ()
      ((documentation-topic-materialization-report-recorded
        ?operation ?db)))

     (:method
      (materialize-and-verify-documentation-topics ?operation ?db)
      ((operation-documentation-topic-known ?operation)
       (dmx-production-db ?db))
      ((!inspect-documentation-topic-definitions ?operation)
       (!derive-required-documentation-topic-ids ?operation)
       (!materialize-documentation-topics ?operation ?db)
       (!materialize-documentation-topic-associations ?operation ?db)
       (!verify-documentation-topics-present ?operation ?db)
       (!verify-fedwiki-page-topic-present ?operation ?db)
       (!verify-reader-surface-sees-materialized-topics ?operation ?db)
       (!record-documentation-topic-materialization-report
        ?operation ?db))))))

 (:problem
  (defproblem materialize-bounded-edge-reassignment-documentation-topics
    operation-documentation-topic-materialization
    ((operation-documentation-topic-known
      bounded-convergent-association-edge-reassignment)
     (dmx-production-db dreyeck-dmx-sqlite-production-db))
    ((materialize-and-verify-documentation-topics
      bounded-convergent-association-edge-reassignment
      dreyeck-dmx-sqlite-production-db))))

 (:selected-plan
  ((!inspect-documentation-topic-definitions
    bounded-convergent-association-edge-reassignment)
   (!derive-required-documentation-topic-ids
    bounded-convergent-association-edge-reassignment)
   (!materialize-documentation-topics
    bounded-convergent-association-edge-reassignment
    dreyeck-dmx-sqlite-production-db)
   (!materialize-documentation-topic-associations
    bounded-convergent-association-edge-reassignment
    dreyeck-dmx-sqlite-production-db)
   (!verify-documentation-topics-present
    bounded-convergent-association-edge-reassignment
    dreyeck-dmx-sqlite-production-db)
   (!verify-fedwiki-page-topic-present
    bounded-convergent-association-edge-reassignment
    dreyeck-dmx-sqlite-production-db)
   (!verify-reader-surface-sees-materialized-topics
    bounded-convergent-association-edge-reassignment
    dreyeck-dmx-sqlite-production-db)
   (!record-documentation-topic-materialization-report
    bounded-convergent-association-edge-reassignment
    dreyeck-dmx-sqlite-production-db)))

 (:output-contract
  ((general-task
    (materialize-and-verify-documentation-topics ?operation ?db))
   (current-instance
    (materialize-and-verify-documentation-topics
     bounded-convergent-association-edge-reassignment
     dreyeck-dmx-sqlite-production-db))
   (explicit-writer
    "dreyeck.dmx.sqlite:materialize-operation-documentation-topics")
   (read-only-status
    "dreyeck.dmx.sqlite:operation-documentation-topic-materialization-status")
   (reader-surface-does-not-materialize t)
   (validation
    ((required-topic-ids-derived t)
     (documentation-topics-present t)
     (documentation-topic-associations-present t)
     (reader-surface-operation-topic-present-p t)
     (reader-surface-fedwiki-page-topic-present-p t))))))
