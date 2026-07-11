(:ARTIFACT (:ID REFACTOR-HYPERDOC-REUSABLE-EXTRACTION-HTN) (:TYPE :HTN-SHOP3-TASK-LIBRARY)
 (:STATUS :DRAFT-FILED-OUT-FROM-TEMPORARY-TOPIC-DB-UPDATED-THROUGH-FOURTH-EXTRACTION)
 (:SOURCE-TOPIC-DB "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite")
 (:TEMPORARY-RUN-ID "temporary-htn-assimilation-20260711-1155")
 (:TOPIC-DB-ANCHOR "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
 (:PURPOSE
  "Codify reusable HTN tasks learned from repeated HyperDoc-to-Dreyeck extraction slices.")
 (:STANDING-RULE
  "Before introducing a new specialised refactoring task, search for reusable HTN/SHOP3 tasks, record the reuse or generalisation decision, and adapt the active plan.")
 (:ABSTRACT-TASKS
  ((!LOCATE-REUSABLE-HTN-TASKS-BEFORE-SPECIALIZATION :INPUTS (?REPO ?CURRENT-TASK ?CURRENT-PLAN)
    :OUTPUTS (?EXISTING-TASKS ?GENERALIZATION-CANDIDATES ?REUSE-DECISION))
   (!CLASSIFY-REFACTORING-CANDIDATE-OWNERSHIP :INPUTS
    (?CANDIDATE ?UPSTREAM-BASELINE ?ASDF-OWNERSHIP-INVENTORY) :OUTPUTS
    (?CLASSIFICATION ?OWNER ?TARGET-SYSTEM ?RISK-CLASS))
   (!SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE :INPUTS
    (?CANDIDATE-INVENTORY ?PREVIOUS-SLICES ?SELECTION-CRITERIA) :OUTPUTS
    (?SELECTED-GROUP ?REJECTED-GROUPS ?SELECTION-ARTIFACT))
   (!REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION :INPUTS
    (?SELECTION-ARTIFACT ?SOURCE-PLAN ?REFERENCE-SCAN) :OUTPUTS
    (?REVIEW-VERDICT ?REFERENCES-TO-UPDATE ?EXECUTION-REQUIREMENTS))
   (!ADAPT-CURRENT-PLAN-WITH-REUSED-OR-GENERALIZED-TASKS :INPUTS
    (?ACTIVE-PLAN ?REVIEW ?REUSABLE-TASK-LIBRARY) :OUTPUTS
    (?PLAN-ADAPTATION ?NEW-OR-REUSED-TASK-RELATIONS))
   (!EXECUTE-REVIEWED-EXTRACTION-SLICE :INPUTS
    (?REVIEW-ARTIFACT ?SELECTED-FILES ?REFERENCES-TO-UPDATE) :OUTPUTS
    (?MOVED-FILES ?UPDATED-REFERENCES ?EXECUTION-RESULT))
   (!REVIEW-EXECUTED-EXTRACTION-SLICE :INPUTS
    (?EXECUTION-RESULT ?TRACKED-REFERENCE-SCAN ?LOAD-VALIDATIONS) :OUTPUTS
    (?POST-REVIEW-VERDICT ?RESIDUE-CLASSIFICATION))
   (!ASSIMILATE-REFACTORING-EPISODE-INTO-HTN :INPUTS (?SELECTION ?REVIEW ?EXECUTION ?POST-REVIEW)
    :OUTPUTS (?NEW-ABSTRACT-TASKS ?NEW-SPECIALIZATIONS ?PLAN-ADAPTATION))))
 (:SPECIALIZED-TASKS
  ((:TASK !SELECT-THIRD-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-selection.sexp")
   (:TASK !REVIEW-THIRD-SLICE-SELECTION-BEFORE-EXECUTION :SPECIALIZES
    !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp")
   (:TASK !EXECUTE-THIRD-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !EXECUTE-REVIEWED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-result.sexp" :STATUS :EXECUTED)
   (:TASK !REVIEW-THIRD-EXTRACTION-SLICE-AFTER-EXECUTION :SPECIALIZES
    !REVIEW-EXECUTED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-third-dreyeck-extraction-review.sexp" :STATUS :ACCEPTED)
   (:TASK !SELECT-FOURTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-selection.sexp")
   (:TASK !REVIEW-FOURTH-SLICE-SELECTION-BEFORE-EXECUTION :SPECIALIZES
    !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-review.sexp")
   (:TASK !EXECUTE-FOURTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !EXECUTE-REVIEWED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-result.sexp" :STATUS :EXECUTED)
   (:TASK !REVIEW-FOURTH-EXTRACTION-SLICE-AFTER-EXECUTION :SPECIALIZES
    !REVIEW-EXECUTED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fourth-dreyeck-extraction-post-review.sexp" :STATUS
    :ACCEPTED)))
 (:METHOD-TEMPLATE
  (:METHOD REUSABLE-REFACTORING-SLICE-CYCLE :TASK
   (!ADVANCE-HYPERDOC-TO-DREYECK-EXTRACTION-BY-ONE-REVIEWED-SLICE ?PLAN ?INVENTORY)
   :ORDERED-SUBTASKS
   ((!LOCATE-REUSABLE-HTN-TASKS-BEFORE-SPECIALIZATION ?REPO ?CURRENT-TASK ?PLAN)
    (!CLASSIFY-REFACTORING-CANDIDATE-OWNERSHIP ?CANDIDATE ?UPSTREAM-BASELINE
     ?ASDF-OWNERSHIP-INVENTORY)
    (!SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE ?INVENTORY ?PREVIOUS-SLICES ?CRITERIA)
    (!REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION ?SELECTION ?PLAN ?REFERENCE-SCAN)
    (!ADAPT-CURRENT-PLAN-WITH-REUSED-OR-GENERALIZED-TASKS ?PLAN ?REVIEW ?REUSABLE-TASK-LIBRARY)
    (!EXECUTE-REVIEWED-EXTRACTION-SLICE ?REVIEW ?SELECTED-FILES ?REFERENCES-TO-UPDATE)
    (!REVIEW-EXECUTED-EXTRACTION-SLICE ?EXECUTION-RESULT ?TRACKED-REFERENCE-SCAN ?LOAD-VALIDATIONS)
    (!ASSIMILATE-REFACTORING-EPISODE-INTO-HTN ?SELECTION ?REVIEW ?EXECUTION ?POST-REVIEW))))
 (:TOPIC-DB-SUMMARY
  (:TOPIC
   (:LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn" :TYPE-URI
    "hyperdoc.refactor.temporary.htn_task_library" :VALUE
    "Reusable HTN Tasks for HyperDoc to Dreyeck Extraction" :SYNC-STATE "temporary")
   :NEIGHBORHOOD
   (:OBJECT
    (:LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn" :OBJECT-KIND "topic"
     :URI "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:reusable-extraction-htn"
     :TYPE-URI "hyperdoc.refactor.temporary.htn_task_library" :VALUE
     "Reusable HTN Tasks for HyperDoc to Dreyeck Extraction" :PAYLOAD-JSON
     "{\"summary\":\"Temporary topic DB record of reusable extraction-cycle HTN tasks.\",\"source\":\"mREPL\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
     :SYNC-STATE "temporary")
    :ASSOCIATIONS
    ((:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!adapt-current-plan-with-reused-or-generalized-tasks"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!adapt-current-plan-with-reused-or-generalized-tasks")))
     (:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!assimilate-refactoring-episode-into-htn"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!assimilate-refactoring-episode-into-htn")))
     (:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!classify-refactoring-candidate-ownership"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!classify-refactoring-candidate-ownership")))
     (:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!execute-reviewed-extraction-slice"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!execute-reviewed-extraction-slice")))
     (:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!locate-reusable-htn-tasks-before-specialization"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!locate-reusable-htn-tasks-before-specialization")))
     (:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!review-executed-extraction-slice"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!review-executed-extraction-slice")))
     (:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!review-selected-extraction-slice-before-execution"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!review-selected-extraction-slice-before-execution")))
     (:LOCAL-ID
      "assoc:topic:hyperdoc-refactor:temporary:reusable-extraction-htn:codifies:topic:hyperdoc-refactor:temporary:task:!select-low-risk-downstream-extraction-slice"
      :OBJECT-KIND "assoc" :URI NIL :TYPE-URI "hyperdoc.refactor.association.codifies_task" :VALUE
      "codifies-task" :PAYLOAD-JSON NIL :SYNC-STATE "local" :PLAYERS
      ((:PLAYER-NO 1 :ROLE-TYPE-URI "hyperdoc.refactor.role.task_library" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
       (:PLAYER-NO 2 :ROLE-TYPE-URI "hyperdoc.refactor.role.abstract_task" :PLAYER-KIND "topic"
        :PLAYER-LOCAL-ID
        "topic:hyperdoc-refactor:temporary:task:!select-low-risk-downstream-extraction-slice"))))
    :NEIGHBORS
    ((:LOCAL-ID
      "topic:hyperdoc-refactor:temporary:task:!adapt-current-plan-with-reused-or-generalized-tasks"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!adapt-current-plan-with-reused-or-generalized-tasks"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE
      "!adapt-current-plan-with-reused-or-generalized-tasks" :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID "topic:hyperdoc-refactor:temporary:task:!assimilate-refactoring-episode-into-htn"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!assimilate-refactoring-episode-into-htn"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE
      "!assimilate-refactoring-episode-into-htn" :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID "topic:hyperdoc-refactor:temporary:task:!classify-refactoring-candidate-ownership"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!classify-refactoring-candidate-ownership"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE
      "!classify-refactoring-candidate-ownership" :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID "topic:hyperdoc-refactor:temporary:task:!execute-reviewed-extraction-slice"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!execute-reviewed-extraction-slice"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE "!execute-reviewed-extraction-slice"
      :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID
      "topic:hyperdoc-refactor:temporary:task:!locate-reusable-htn-tasks-before-specialization"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!locate-reusable-htn-tasks-before-specialization"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE
      "!locate-reusable-htn-tasks-before-specialization" :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID "topic:hyperdoc-refactor:temporary:task:!review-executed-extraction-slice"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!review-executed-extraction-slice"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE "!review-executed-extraction-slice"
      :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID
      "topic:hyperdoc-refactor:temporary:task:!review-selected-extraction-slice-before-execution"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!review-selected-extraction-slice-before-execution"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE
      "!review-selected-extraction-slice-before-execution" :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary")
     (:LOCAL-ID
      "topic:hyperdoc-refactor:temporary:task:!select-low-risk-downstream-extraction-slice"
      :OBJECT-KIND "topic" :URI
      "temporary://hyperdoc-refactor/topic:hyperdoc-refactor:temporary:task:!select-low-risk-downstream-extraction-slice"
      :TYPE-URI "hyperdoc.refactor.htn_abstract_task" :VALUE
      "!select-low-risk-downstream-extraction-slice" :PAYLOAD-JSON
      "{\"summary\":\"Reusable abstract HTN task candidate learned from repeated extraction slices.\",\"source\":\"mREPL temporary assimilation\",\"temporary-run-id\":\"temporary-htn-assimilation-20260711-1155\"}"
      :SYNC-STATE "temporary"))))))
