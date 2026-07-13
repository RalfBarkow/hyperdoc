(:ARTIFACT (:ID REFACTOR-HYPERDOC-REUSABLE-EXTRACTION-HTN) (:TYPE :HTN-SHOP3-TASK-LIBRARY)
 (:STATUS
  :DRAFT-FILED-OUT-FROM-TEMPORARY-TOPIC-DB-UPDATED-THROUGH-EIGHTH-EXTRACTION-COMMIT-2)
 (:SOURCE-TOPIC-DB "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite")
 (:TEMPORARY-RUN-ID "temporary-htn-assimilation-20260711-1155")
 (:TOPIC-DB-ANCHOR "topic:hyperdoc-refactor:temporary:reusable-extraction-htn")
 (:PURPOSE
  "Codify reusable HTN tasks learned from repeated HyperDoc-to-Dreyeck extraction slices.")
 (:STANDING-RULE
  "Before introducing a new specialised refactoring task, search for reusable HTN/SHOP3 tasks, record the reuse or generalisation decision, and adapt the active plan.")
 (:LAST-COMPLETED-EPISODE
  (:EPISODE :EIGHTH-DREYECK-EXTRACTION-COMMIT-2
   :MERGE-COMMIT "24fc9b0243d50d939741983d10ee5eeb8f68ead6"
   :CANONICAL-SYSTEM :DREYECK/SHOP3
   :COMPATIBILITY-SYSTEM :HYPERDOC/SHOP3
   :PRIMARY-PACKAGE :DREYECK/SHOP3
   :LEGACY-PACKAGE-NICKNAME :HYPERDOC/SHOP3
   :STATUS :MERGED))
 (:REUSABLE-EXTRACTION-RULES
  ((!RECORD-COPY-THEN-VERIFY-AS-INTERMEDIATE-EXTRACTION
    :CANONICAL-OWNERSHIP-MOVED T
    :LEGACY-PHYSICAL-COPIES-MAY-REMAIN T
    :LEGACY-COPIES-MUST-NOT-BE-LIVE-ASDF-COMPONENTS T)
   (!RECORD-LIVE-REFERENCE-POLICY
    :REJECT-CONTRADICTORY-LIVE-REFERENCES T
    :ALLOW-COMPATIBILITY-REFERENCES T
    :ALLOW-DEFERRED-SOURCE-COPIES T
    :ALLOW-HISTORICAL-EVIDENCE-REFERENCES T
    :ALLOW-DEFERRED-DOCUMENTATION-REFERENCES T)
   (!RECORD-PACKAGE-AWARE-PLAN-CANARY-RULE
    :EXPECTED-OPERATOR-PACKAGE :RESOLVE-FROM-DOMAIN
    :OBSERVED-PACKAGE :DREYECK/SHOP3
    :DO-NOT-DEFAULT-TO :CL-USER
    :COMPARE-SYMBOL-IDENTITY T
    :PRINTED-PLAN-EQUALITY-ALONE-INSUFFICIENT T
    :REASON
    "Resolve the expected operator package from the planning domain that owns the operator; the eighth SHOP3 episode observed DREYECK/SHOP3, but that package is evidence rather than a universal default.")
   (!RECORD-BASELINE-COMPARISON-FOR-UNRELATED-TEST-FAILURES
    :OBSERVED-CLASSIFICATION :PRE-EXISTING-STALE-TEST-HARNESS-EXPECTATION
    :REQUIRE-BASE-AND-HEAD-COMPARISON T
    :DO-NOT-BROADEN-CURRENT-SLICE T)))
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
    :ACCEPTED)
   (:TASK !SELECT-FIFTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-selection.sexp")
   (:TASK !REVIEW-FIFTH-SLICE-SELECTION-BEFORE-EXECUTION :SPECIALIZES
    !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-review.sexp")
   (:TASK !EXECUTE-FIFTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !EXECUTE-REVIEWED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-result.sexp" :STATUS :EXECUTED)
   (:TASK !REVIEW-FIFTH-EXTRACTION-SLICE-AFTER-EXECUTION :SPECIALIZES
    !REVIEW-EXECUTED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-fifth-dreyeck-extraction-post-review.sexp" :STATUS
    :ACCEPTED)
   (:TASK !SELECT-SIXTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-selection.sexp")
   (:TASK !REVIEW-SIXTH-SLICE-SELECTION-BEFORE-EXECUTION :SPECIALIZES
    !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-review.sexp")
   (:TASK !EXECUTE-SIXTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !EXECUTE-REVIEWED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-result.sexp" :STATUS :EXECUTED)
   (:TASK !REVIEW-SIXTH-EXTRACTION-SLICE-AFTER-EXECUTION :SPECIALIZES
    !REVIEW-EXECUTED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-sixth-dreyeck-extraction-post-review.sexp" :STATUS
    :ACCEPTED)
   (:TASK !ASSIMILATE-SIXTH-EXTRACTION-SLICE-INTO-REUSABLE-HTN :SPECIALIZES
    !ASSIMILATE-REFACTORING-EPISODE-INTO-HTN :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-sixth-extraction-htn-assimilation.sexp" :STATUS :ACCEPTED)
   (:TASK !RECORD-LIVE-LISP-EXECUTOR-ARCHITECTURE-DECISION :SPECIALIZES
    !ADAPT-CURRENT-PLAN-WITH-REUSED-OR-GENERALIZED-TASKS :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-live-lisp-executor-architecture-decision.sexp" :ROLE
    :ARCHITECTURE-CORRECTION-BEFORE-OWNER-SELECTION)
   (:TASK !REDECIDE-BUILD-REFEREE-SUBGRAPH-OWNER-UNDER-LIVE-LISP-EXECUTOR-MODEL :SPECIALIZES
    !CLASSIFY-REFACTORING-CANDIDATE-OWNERSHIP :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-seventh-build-referee-subgraph-owner-redecision.sexp"
    :ROLE :OWNER-REDECISION-UNDER-CORRECTED-EXECUTOR-MODEL)
   (:TASK !SELECT-SEVENTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !SELECT-LOW-RISK-DOWNSTREAM-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-selection.sexp")
   (:TASK !REVIEW-SEVENTH-SLICE-SELECTION-BEFORE-EXECUTION :SPECIALIZES
    !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-review.sexp")
   (:TASK !EXECUTE-SEVENTH-LOW-RISK-DREYECK-EXTRACTION-SLICE :SPECIALIZES
    !EXECUTE-REVIEWED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-result.sexp")
   (:TASK !RECORD-SEVENTH-EXTRACTION-POST-REVIEW-WITH-DEFERRED-HYPERDOC-LOAD-BOUNDARY-REPAIR
    :SPECIALIZES !REVIEW-EXECUTED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-seventh-dreyeck-extraction-post-review.sexp")
   (:TASK !ASSIMILATE-SEVENTH-EXTRACTION-INTO-REUSABLE-HTN :SPECIALIZES
    !ASSIMILATE-REFACTORING-EPISODE-INTO-HTN :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-seventh-extraction-htn-assimilation.sexp")
   (:TASK !PREPARE-EIGHTH-DREYECK-EXTRACTION-COMMIT-2 :SPECIALIZES
    !REVIEW-SELECTED-EXTRACTION-SLICE-BEFORE-EXECUTION :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-preparation.sexp"
    :STATUS :ACCEPTED)
   (:TASK !EXECUTE-EIGHTH-DREYECK-EXTRACTION-COMMIT-2 :SPECIALIZES
    !EXECUTE-REVIEWED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-execution.sexp"
    :STATUS :EXECUTED)
   (:TASK !REVIEW-EIGHTH-DREYECK-EXTRACTION-COMMIT-2 :SPECIALIZES
    !REVIEW-EXECUTED-EXTRACTION-SLICE :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-eighth-dreyeck-extraction-commit-2-review.sexp"
    :STATUS :ACCEPTED)
   (:TASK !ASSIMILATE-EIGHTH-DREYECK-EXTRACTION-COMMIT-2-INTO-REUSABLE-HTN
    :SPECIALIZES !ASSIMILATE-REFACTORING-EPISODE-INTO-HTN :EVIDENCE
    "hyperdoc/evidence/refactor-hyperdoc-eighth-extraction-commit-2-htn-assimilation.sexp"
    :STATUS :ACCEPTED)))
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
      :SYNC-STATE "temporary")))))
 (:EPISODE-ASSIMILATIONS
  ((:EPISODE :SEVENTH-DREYECK-EXTRACTION :BASE "628aa5f0" :MOVED-FILE
    ("hyperdoc/add-build-referee-subgraph-inspector-view-plan.sexp"
     "dreyeck/build/add-build-referee-subgraph-inspector-view-plan.sexp")
    :TARGET-SYSTEM :DREYECK/BUILD :EXECUTOR-ROLE :COHERENT-LIVE-LISP-IMAGE :CODEX-ROLE
    :LEGACY-COMPATIBILITY-OR-READER-DISPLAY-SURFACE :POST-REVIEW-VERDICT :ACCEPTED
    :LIVE-OLD-PATH-REFERENCES NIL :ASDF-UPDATE-REQUIRED-P NIL :NEW-ASDF-SUBSYSTEM-NEEDED-P NIL
    :NEW-ABSTRACT-TASK-CANDIDATES
    (!RECORD-EXECUTOR-ARCHITECTURE-DECISION-BEFORE-OWNER-SELECTION))
   (:EPISODE :EIGHTH-DREYECK-EXTRACTION-COMMIT-2
    :PREPARATION-COMMIT "c13fc0803ed5c8a7226da67692f0013b5e9af1ea"
    :EXECUTION-COMMIT "1ef7608498df2b9b372e0ac058ce65210ecb4868"
    :REVIEW-COMMIT "5133c6c98c790664ec0fd8fe9ab22d8823ca99fb"
    :MERGE-COMMIT "24fc9b0243d50d939741983d10ee5eeb8f68ead6"
    :CANONICAL-SYSTEM :DREYECK/SHOP3
    :CANONICAL-COMPONENTS 6
    :COMPATIBILITY-SYSTEM :HYPERDOC/SHOP3
    :COMPATIBILITY-DIRECT-COMPONENTS 0
    :COMPATIBILITY-DEPENDS-ON (:DREYECK/SHOP3)
    :PRIMARY-PACKAGE :DREYECK/SHOP3
    :LEGACY-PACKAGE-NICKNAME :HYPERDOC/SHOP3
    :PACKAGE-IDENTITY :SAME
    :DUPLICATE-IMPLEMENTATION-LOAD NIL
    :COPY-THEN-VERIFY-INTERMEDIATE T
    :CONTRADICTORY-LIVE-OLD-PATH-REFERENCES NIL
    :PROJECTION-SMOKE-CLASSIFICATION
    :PRE-EXISTING-STALE-TEST-HARNESS-EXPECTATION
    :POST-REVIEW-VERDICT :ACCEPTED
    :STATUS :MERGED)))
 (:REMAINING-SHOP3-EXTRACTION-DEBT
  (:LEGACY-IMPLEMENTATION-COPIES
   ("hyperdoc-shop3/package.lisp"
    "hyperdoc-shop3/manual-topics.lisp"
    "hyperdoc-shop3/plan-objects.lisp"
    "hyperdoc-shop3/hyperdoc-maintenance-domain.lisp"
    "hyperdoc-shop3/examples.lisp"
    "hyperdoc-shop3/views.lisp"))
  (:PROVIDER-BOUNDARY
   (:SYSTEM :HYPERDOC/SHOP3-PROVIDER-BOUNDARY)
   (:MOVE-DEFERRED T))
  (:DOCUMENTATION-WORKFLOWS
   (:MOVE-OR-REWRITE-DEFERRED T))
  (:REFERENCE-POLICY
   (:NEW-HYPERDOC/SHOP3-REFERENCES-LINT-MISSING T))
  (:PLAN-TREE-PROJECTION
   (:RETURNED-SHAPE-REPAIR-DEFERRED T)))
 (:EIGHTH-EXTRACTION-COMMIT-3-CANDIDATE
  (:CANDIDATE
   (!REMOVE-LEGACY-SHOP3-IMPLEMENTATION-COPIES
    :WITH-NEW-REFERENCE-LINT
    :DEFER-PROVIDER-BOUNDARY-MOVE T
    :DEFER-DOCUMENTATION-WORKFLOW-MOVE T
    :DEFER-PROJECTION-REPAIR T))
  (:STATUS :CANDIDATE-PENDING-TASK-LOCALIZATION))
 (:NEXT
  (!LOCALIZE-EIGHTH-DREYECK-EXTRACTION-COMMIT-3
   :CANDIDATE
   (!REMOVE-LEGACY-SHOP3-IMPLEMENTATION-COPIES
    :WITH-NEW-REFERENCE-LINT)
   :SEARCH-EXISTING-HTN-AND-PLAN-ARTIFACTS-FIRST T)))
