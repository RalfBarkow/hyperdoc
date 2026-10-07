;;;; Proposed Nested Action Probes

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Two Relations Hidden in One Nest" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:DEFEXAMPLE SEMANTIC-QUESTIONS
  "Questions left open after distinguishing subordinate execution and window event reach."
  (LOOP FOR (ID
             QUESTION) IN '((:ENVIRONMENT
                             "What input object does the current LISTEN pass to its subordinate REPORT?")
                            (:NODE
                             "Retained LISTEN matches topic or name node. Does Ward's current implementation retain that filter?")
                            (:TITLE
                             "The producer supplies message.title. What current nested REPORT target receives it? Retained REPORT reads state.title.")
                            (:EVENT-CONTEXT
                             "What transformation connects received event.data to current nested action input? Rebinding is not established.")
                            (:LIFETIME
                             "How long does the current nested listener computation live? The retained listener's count limit does not prove its lifecycle.")
                            (:TERMINATION
                             "What ends the current listener and nested actions; how are cancellation and unsubscription handled?")
                            (:SCOPE
                             "Ward's proposed scope concerns event-emitter reach through replacing window. No lexical or dynamic variable scope is established."))
        COLLECT (LIST :ID ID :QUESTION QUESTION :STATUS :OPEN :ANSWER NIL
                      :EVIDENCE NIL)))

(HYPERDOC:DEFEXAMPLE PROPOSED-PROBES
  "Future experiments after inspecting the emitted-message witness. No current Solo semantics execute here."
  (LIST
   (LIST :ID :MESSAGE-HANDOFF :STATUS :PROPOSED :EXECUTABLE-P NIL
         :NOTATION-VALIDITY :UNVERIFIED :QUESTION :EVENT-CONTEXT :PRIORITY
         :PRIMARY :PROCEDURE
         "In the matching current Mech revision, capture the same node message at window reception, at LISTEN's nested dispatch and at REPORT's state[key] or actual lookup operation. Preserve identities and revision coordinates."
         :DISCRIMINATES
         "Whether event.data is passed, copied, merged, wrapped or transformed; do not infer the handoff from equal title strings."
         :REQUIRED-EVIDENCE
         "Current LISTEN nested-dispatch and REPORT implementation, plus paired runtime objects."
         :RESULT NIL)
   (LIST :ID :LIFETIME :STATUS :PROPOSED :EXECUTABLE-P NIL :NOTATION-VALIDITY
         :UNVERIFIED :QUESTION :TERMINATION :PROCEDURE
         "Measure callbacks and cleanup after rerunning the enclosing action and closing its UI, in the matching revision."
         :DISCRIMINATES
         "Registration/disposal timing, without importing the retained revision's event-count limit."
         :REQUIRED-EVIDENCE
         "Current registration/cleanup source and timestamped handler identities."
         :RESULT NIL)
   (LIST :ID :OUTER-INNER-TITLE :STATUS :SUPERSEDED :PRIORITY :HISTORICAL
         :EXECUTABLE-P NIL :NOTATION-VALIDITY :UNVERIFIED :FORM
         '("SOLO" ("REPORT" "title") ("LISTEN" "node" ("REPORT" "title")))
         :QUESTION :TITLE :REASON
         "Earlier outer/inner-title proposal is no longer the primary witness. Trace the emitted message and missing handoff first."
         :REQUIRED-EVIDENCE
         "Actual current input and lookup targets, before comparing outer and inner values."
         :RESULT NIL)))
