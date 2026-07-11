(:REFACTOR-HYPERDOC-UPSTREAM-CORE-PLAN-HTN-ADAPTATION
 (:OPERATION (!ADAPT-UPSTREAM-CORE-REFACTOR-PLAN-WITH-REUSABLE-EXTRACTION-HTN))
 (:TEMPORARY-RUN-ID "temporary-htn-assimilation-20260711-1155")
 (:SOURCE-TOPIC-DB "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite")
 (:BASE-PLAN "hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
 (:REUSABLE-TASK-LIBRARY "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp")
 (:ASSIMILATION-EVIDENCE
  "hyperdoc/evidence/refactor-hyperdoc-third-extraction-htn-assimilation.sexp")
 (:TOPIC-DB-ANCHOR "topic:hyperdoc-refactor:temporary:upstream-core-plan-htn-adaptation")
 (:REASON
  "The refactoring now has repeated selection, review, execution, and post-review cycles. These should be represented as reusable HTN methods and specialised slice tasks, not as isolated numbered events.")
 (:PLAN-ADAPTATION
  (:INSERT-BEFORE-EACH-NEW-SPECIALIZED-TASK
   (!LOCATE-REUSABLE-HTN-TASKS-BEFORE-SPECIALIZATION ?REPO ?CURRENT-TASK ?ACTIVE-PLAN))
  (:INSERT-AFTER-EACH-SELECTION-REVIEW
   (!ADAPT-CURRENT-PLAN-WITH-REUSED-OR-GENERALIZED-TASKS ?ACTIVE-PLAN ?REVIEW
    ?REUSABLE-TASK-LIBRARY))
  (:INSERT-AFTER-EACH-POST-REVIEW
   (!ASSIMILATE-REFACTORING-EPISODE-INTO-HTN ?SELECTION ?REVIEW ?EXECUTION ?POST-REVIEW)))
 (:ACCEPTANCE
  ((:TASK-LOCATION-BEFORE-SPECIALIZATION :RECORDED)
   (:THIRD-REVIEW-RELATED-TO-CURRENT-SHOP3-PLAN :RECORDED)
   (:REUSABLE-ABSTRACT-TASKS-RECORDED :RECORDED)
   (:SPECIALIZED-NUMBERED-TASKS-RELATED-TO-ABSTRACT-TASKS :RECORDED)
   (:THIRD-SLICE-EXECUTION-NOT-PERFORMED T)))
 (:TOPIC-DB-SUMMARY
  (:TOPIC
   (:LOCAL-ID "topic:hyperdoc-refactor:temporary:upstream-core-plan-htn-adaptation" :TYPE-URI
    "hyperdoc.refactor.temporary.plan_adaptation" :VALUE
    "Upstream Core Refactor Plan HTN Adaptation" :SYNC-STATE "temporary")
   :NEIGHBORHOOD
   (:OBJECT
    (:LOCAL-ID "topic:hyperdoc-refactor:temporary:upstream-core-plan-htn-adaptation" :OBJECT-KIND
     "topic" :URI
     "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:upstream-core-plan-htn-adaptation"
     :TYPE-URI "hyperdoc.refactor.temporary.plan_adaptation" :VALUE
     "Upstream Core Refactor Plan HTN Adaptation" :PAYLOAD-JSON
     "{\"summary\":\"Temporary plan adaptation requiring task-location and generalisation before later specialised tasks.\",\"source\":\"hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
     :SYNC-STATE "temporary")
    :ASSOCIATIONS
    ((:LOCAL-ID "assoc:plan-adaptation:requires:task-location-before-specialization" :OBJECT-KIND
      "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.requires_task" :VALUE
      "requires-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.plan_adaptation" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:upstream-core-plan-htn-adaptation")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.required_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!locate-reusable-htn-tasks-before-specialization"))))
    :NEIGHBORS
    ((:LOCAL-ID
      "topic:hyperdoc-refactor:temporary:task:!locate-reusable-htn-tasks-before-specialization"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!locate-reusable-htn-tasks-before-specialization"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE
      "!locate-reusable-htn-tasks-before-specialization" :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")))))
 (:NEXT (!REVIEW-FILED-OUT-REUSABLE-REFACTORING-HTN-BEFORE-THIRD-EXECUTION)))
