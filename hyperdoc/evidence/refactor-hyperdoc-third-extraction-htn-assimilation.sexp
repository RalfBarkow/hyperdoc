(:REFACTOR-HYPERDOC-THIRD-EXTRACTION-HTN-ASSIMILATION
 (:OPERATION (!FILE-OUT-REUSABLE-REFACTORING-HTN-FROM-TEMPORARY-TOPIC-DB))
 (:TEMPORARY-RUN-ID "temporary-htn-assimilation-20260711-1155")
 (:SOURCE-TOPIC-DB "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite")
 (:SOURCE-SELECTION "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp")
 (:SOURCE-REVIEW "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp")
 (:SOURCE-PLAN #1="hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp")
 (:SELECTED-SOURCE-PLAN #2="dreyeck/dmx/sqlite/materialize-build-referee-learning-topics-plan.sexp")
 (:TOPIC-DB-ANCHOR "topic:hyperdoc-refactor:temporary:third-extraction-htn-assimilation")
 (:REVIEWED-TEMPORARY-DB-STATE (:REQUIRED-TOPIC-COUNT 14) (:MISSING-TOPICS NIL)
  (:FAILED-ASSOCIATION-CHECKS NIL) (:REVIEW-VERDICT :ACCEPTED))
 (:LESSON
  "A slice review is both an execution gate and evidence for reusable HTN task vocabulary, risk classification, method ordering, and active-plan adaptation.")
 (:GENERALIZED-TASKS
  (!LOCATE-REUSABLE-HTN-TASKS-BEFORE-SPECIALIZATION !CLASSIFY-REFACTORING-CANDIDATE-OWNERSHIP
   !SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION
   !ADAPT-CURRENT-PLAN-WITH-REUSED-OR-GENERALIZED-TASKS !EXECUTE-REVIEWED-EXTRACTION-SLICE
   !REVIEW-EXECUTED-EXTRACTION-SLICE !ASSIMILATE-REFACTORING-EPISODE-INTO-HTN))
 (:SPECIALIZED-TASK-RELATIONS
  ((!SELECT-THIRD-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE)
   (!REVIEW-THIRD-SLICE-SELECTION-BEFORE-EXECUTION :SPECIALIZES
    !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION)
   (!EXECUTE-THIRD-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !EXECUTE-REVIEWED-EXTRACTION-SLICE)))
 (:CURRENT-SHOP3-PLAN-RELATION
  ((:PLAN #1# :RELATION :ACTIVE-REFACTORING-PLAN-TO-BE-ADAPTED)
   (:PLAN "hyperdoc/refactor-hyperdoc-reusable-extraction-htn.sexp" :RELATION
    :REUSABLE-TASK-LIBRARY)
   (:PLAN #2# :RELATION :SELECTED-SOURCE-PLAN-FOR-THIRD-EXTRACTION)))
 (:TOPIC-DB-SUMMARY
  (:TOPIC
   (:LOCAL-ID "topic:hyperdoc-refactor:temporary:third-extraction-htn-assimilation" :TYPE-URI
    "hyperdoc.refactor.temporary.htn_assimilation" :VALUE
    "Third Extraction Review HTN Assimilation" :SYNC-STATE "temporary")
   :NEIGHBORHOOD
   (:OBJECT
    (:LOCAL-ID "topic:hyperdoc-refactor:temporary:third-extraction-htn-assimilation" :OBJECT-KIND
     "topic" :URI
     "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:third-extraction-htn-assimilation"
     :TYPE-URI "hyperdoc.refactor.temporary.htn_assimilation" :VALUE
     "Third Extraction Review HTN Assimilation" :PAYLOAD-JSON
     "{\"summary\":\"Temporary assimilation of the third extraction review into reusable HTN vocabulary.\",\"source\":\"hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
     :SYNC-STATE "temporary")
    :ASSOCIATIONS
    ((:LOCAL-ID "assoc:third-htn-assimilation:adapts:umbrella-plan" :OBJECT-KIND "assoc" :URI NIL
      :TYPE-URI "hyperdoc.refactor.association.adapts_plan" :VALUE "adapts-plan" :PAYLOAD-JSON NIL
      :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.assimilation" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:third-extraction-htn-assimilation")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.plan" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:plan:upstream-core-and-dreyeck-systems")))
     (:LOCAL-ID "assoc:third-htn-assimilation:derived-from:third-review" :OBJECT-KIND "assoc" :URI
      NIL :TYPE-URI "hyperdoc.refactor.association.derived_from" :VALUE "derived-from"
      :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.assimilation" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:third-extraction-htn-assimilation")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.evidence" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:evidence:third-extraction-review")))
     (:LOCAL-ID "assoc:third-htn-assimilation:derived-from:third-selection" :OBJECT-KIND "assoc"
      :URI NIL :TYPE-URI "hyperdoc.refactor.association.derived_from" :VALUE "derived-from"
      :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.assimilation" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:third-extraction-htn-assimilation")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.evidence" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:evidence:third-extraction-selection"))))
    :NEIGHBORS
    ((:LOCAL-ID "topic:hyperdoc-refactor:plan:upstream-core-and-dreyeck-systems" :OBJECT-KIND
      "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:plan:upstream-core-and-dreyeck-systems"
      :TYPE-URI "hyperdoc.refactor.shop3_plan" :VALUE
      "Refactor HyperDoc to Upstream Core and Dreyeck Systems" :PAYLOAD-JSON
      "{\"summary\":\"Active umbrella SHOP3 refactor plan.\",\"source\":\"hyperdoc/refactor-hyperdoc-to-upstream-core-and-dreyeck-systems-plan.sexp\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID "topic:hyperdoc-refactor:evidence:third-extraction-review" :OBJECT-KIND "topic"
      :URI "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:evidence:third-extraction-review"
      :TYPE-URI "hyperdoc.refactor.evidence" :VALUE "Third Dreyeck Extraction Review" :PAYLOAD-JSON
      "{\"summary\":\"Review evidence for the third low-risk Dreyeck extraction slice.\",\"source\":\"hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID "topic:hyperdoc-refactor:evidence:third-extraction-selection" :OBJECT-KIND "topic"
      :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:evidence:third-extraction-selection"
      :TYPE-URI "hyperdoc.refactor.evidence" :VALUE "Third Dreyeck Extraction Selection"
      :PAYLOAD-JSON
      "{\"summary\":\"Selection evidence for the third low-risk Dreyeck extraction slice.\",\"source\":\"hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")))))
 (:THIRD-EXTRACTION-EXECUTED NIL)
 (:NEXT (!REVIEW-FILED-OUT-REUSABLE-REFACTORING-HTN-BEFORE-THIRD-EXECUTION)))
