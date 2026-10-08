;;;; Tracing the Received Message Boundary

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "From Message to Nested Input" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Two Relations Hidden in One Nest" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Adding to an Already Rendered Solo Popup" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(DEFCLASS MESSAGE-INPUT-TRACE NIL
          ((STAGES :INITARG :STAGES :READER INPUT-STAGES)
           (CAPTURE :INITARG :CAPTURE :READER INPUT-CAPTURE)
           (SOURCES :INITARG :SOURCES :READER INPUT-SOURCES)
           (INVENTORY :INITARG :INVENTORY :READER INPUT-INVENTORY))
          (:DOCUMENTATION
           "Revision-bounded received-message trace; runtime identity measurements are records, not live JS objects in Lisp."))

(DEFUN INPUT-STAGE (TRACE ID)
  (OR
   (FIND ID (INPUT-STAGES TRACE) :KEY (LAMBDA (S) (GETF S :ID)) :TEST #'EQUAL)
   (ERROR "Unknown input trace stage ~A" ID)))

(HYPERDOC:DEFEXAMPLE INPUT-HYPOTHESES
  "No current handoff implementation has been located. None of A-D is selected by equal title strings."
  (LOOP FOR (ID
             CLAIM) IN '((:A
                          "Direct payload dataflow: event.data passed as nested input.")
                         (:B
                          "Context extension: previous input and payload combined.")
                         (:C
                          "Context replacement: payload replaces current input.")
                         (:D
                          "Named binding: payload.title enters an explicit environment.")
                         (:E
                          "Another mechanism, to be identified in the matching implementation."))
        COLLECT (LIST :ID ID :STATUS :HYPOTHESIZED :CLAIM CLAIM
                      :CURRENT-VERDICT :UNRESOLVED :RETAINED-SOURCE-RESULT
                      "Retained LISTEN counts/statuses only. No nested input or REPORT dispatch follows its match.")))

(HYPERDOC:DEFEXAMPLE RECEIVED-INPUT-TRACE
  "Read the bounded native capture and expose precise source/runtime stages plus explicit unknown current input."
  (LET* ((CAPTURE
          (READ-MESSAGE-JSON "dreyeck/nested-actions/input-witness.json"))
         (EVENT (AREF (GETHASH "events" CAPTURE) 0))
         (INVENTORY
          (READ-MESSAGE-JSON
           "dreyeck/nested-actions/sources/local-input-source-inventory.json")))
    (MAKE-INSTANCE 'MESSAGE-INPUT-TRACE :CAPTURE CAPTURE :SOURCES
                   (MESSAGE-SOURCE-OBSERVATIONS) :INVENTORY INVENTORY :STAGES
                   (LIST
                    (LIST :ID "received-message" :STATUS :RUNTIME-OBSERVED
                          :TYPE "MessageEvent" :OBJECT
                          (GETHASH "reception" EVENT) :SOURCE
                          "Native opener window message callback; bounded fixture"
                          :OPERATION
                          "Native delivery; received payload is distinct from producer object."
                          :PREVIOUS-INPUT "Not involved in transport.")
                    (LIST :ID "message-data" :STATUS :SOURCE-OBSERVED
                          :RUNTIME-STATUS :RUNTIME-OBSERVED :TYPE
                          "JavaScript Object" :OBJECT
                          (GETHASH "receivedPayload" EVENT) :SOURCE
                          (EVIDENCE-SOURCE "listen") :OPERATION
                          "Local data aliases event.data; no copy, wrap, merge or assignment to state."
                          :IDENTITY-EVIDENCE (GETHASH "listenSelection" EVENT)
                          :PREVIOUS-INPUT
                          "LISTEN retains its separately supplied state argument; data is not that object in this witness.")
                    (LIST :ID "listen-match" :STATUS :SOURCE-OBSERVED
                          :RUNTIME-STATUS :RUNTIME-OBSERVED :TYPE
                          "Boolean predicate over action/topic/name; payload remains an Object"
                          :OBJECT (GETHASH "listenSelection" EVENT) :SOURCE
                          (EVIDENCE-SOURCE "listen") :OPERATION
                          "Inline publishSourceData/action + topic/name filter, not a separate dispatch registry. Count/status update only."
                          :PREVIOUS-INPUT
                          "Prior state object/title/context remain accessible and unchanged in this retained witness.")
                    (LIST :ID "nested-action-input" :STATUS :OPEN :TYPE
                          :UNKNOWN :OBJECT NIL :SOURCE
                          :MATCHING-CURRENT-LISTEN-DISPATCH-UNAVAILABLE
                          :OPERATION
                          "No construction/replacement/extension or nested invocation in retained LISTEN."
                          :PREVIOUS-INPUT :UNKNOWN-FOR-CURRENT-EXPERIMENT)
                    (LIST :ID "report-lookup-target" :STATUS :OPEN :TYPE
                          :UNKNOWN :OBJECT NIL :SOURCE
                          :MATCHING-CURRENT-REPORT-CALL-UNAVAILABLE :OPERATION
                          "Current nested REPORT caller/argument unavailable; cannot equate target with payload or prior state."
                          :PREVIOUS-INPUT :UNKNOWN-FOR-CURRENT-EXPERIMENT)
                    (LIST :ID "title-value" :STATUS :OPEN :TYPE :UNKNOWN
                          :OBJECT NIL :SOURCE
                          :CURRENT-NESTED-REPORT-RESULT-UNAVAILABLE :OPERATION
                          "Current nested result unknown. Retained report_emit separately uses args[0] || temperature, key in state, then state[key]."
                          :PREVIOUS-INPUT :UNKNOWN-FOR-CURRENT-EXPERIMENT)
                    (LIST :ID "retained-report-state" :STATUS :RUNTIME-OBSERVED
                          :TYPE "JavaScript Object" :OBJECT
                          (GETHASH "priorState" EVENT) :SOURCE
                          (EVIDENCE-SOURCE "report") :OPERATION
                          "Passed directly as state to independent retained REPORT; inspect receives same state object. No LISTEN connection."
                          :IDENTITY-EVIDENCE
                          (GETHASH "independentReportProbe" EVENT)
                          :PREVIOUS-INPUT
                          "Original title/context accessible; state is distinct from event.data.")
                    (LIST :ID "retained-title-value" :STATUS :RUNTIME-OBSERVED
                          :TYPE "JavaScript string" :OBJECT
                          (GETHASH "value"
                                   (GETHASH "independentReportProbe" EVENT))
                          :SOURCE (EVIDENCE-SOURCE "report") :OPERATION
                          "REPORT title reads Prior Title from supplied prior state, renders report and inspects state."
                          :PREVIOUS-INPUT
                          "This independent result does not establish Ward's nested REPORT target.")))))

(V:DEFVIEW MESSAGE-INPUT-TRACE-VIEW (TRACE MESSAGE-INPUT-TRACE)
           (V:HTML-VIEW :TITLE "Input path" :PRIORITY 1
                        (V:HTML
                          (:P
                           "Retained LISTEN establishes MessageEvent → event.data alias → matching count/status. The transition from that matched payload to current nested REPORT's lookup target remains unavailable locally.")
                          (:TABLE :CLASS "inspector-table"
                           (DOLIST (STAGE (INPUT-STAGES TRACE))
                             (V:HTML
                               (:TR (:TD (CL-WHO:ESC (GETF STAGE :ID)))
                                (:TD
                                 (CL-WHO:ESC
                                  (FORMAT NIL "~A" (GETF STAGE :STATUS))))
                                (:TD
                                 (V:OBJECT-REF STAGE :DISPLAY
                                               "Type, operation, source, identity and prior input"))))))
                          (:P
                           (V:OBJECT-REF (INPUT-CAPTURE TRACE) :DISPLAY
                                         "Native capture with live-object checks recorded before serialization"))
                          (:P
                           (V:OBJECT-REF (INPUT-SOURCES TRACE) :DISPLAY
                                         "Exact retained source definitions"))
                          (:P
                           (V:OBJECT-REF (INPUT-INVENTORY TRACE) :DISPLAY
                                         "24 local refs inspected; no source fetch"))
                          (:P
                           (V:OBJECT-REF (INPUT-HYPOTHESES) :DISPLAY
                                         "A/B/C/D/E remain hypotheses for current handoff"))
                          (:P
                           (V:OBJECT-REF (TOPIC-WORKSPACE "input-path")
                                         :DISPLAY
                                         "Navigate this input path in the Workspace"
                                         :SELECT "Topicmap"))
                          (:P
                           (V:OBJECT-REF
                            (HYPERDOC:PAGE "From Message to Nested Input"
                                           :HYPERBOOK
                                           "dreyeck/nested-actions/reading")
                            :DISPLAY "Return to the reading" :SELECT
                            "Content")))))
