;;;; Navigating the Nested Actions Investigation

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Two Relations Hidden in One Nest" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "From Message to Nested Input" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(DEFUN READING-PAGE (TITLE)
  (HYPERBOOK:FIND-PAGE
   (HYPERBOOK:FIND-HYPERBOOK "dreyeck/nested-actions/reading" :SIGNAL-ERROR? T)
   TITLE :SIGNAL-ERROR? T))

(HYPERDOC:DEFEXAMPLE READING-PROJECTION
  "Three independent concerns: subordination, event reach, and payload-to-input; exact revision and runtime warrants."
  (LET* ((HISTORY (HISTORICAL-CONTEXT-HYPOTHESES))
         (TREE (OBSERVED-ACTION-TREE))
         (LISTEN (FIRST (ACTION-CHILDREN TREE)))
         (REPORT (FIRST (ACTION-CHILDREN LISTEN)))
         (QUESTIONS (SEMANTIC-QUESTIONS))
         (WITNESS (EMITTED-MESSAGE-WITNESS))
         (WARD (WARD-PROPAGATION-EVIDENCE))
         (INPUT (RECEIVED-INPUT-TRACE))
         (SPECS
          (LIST
           (LIST "experiment" "Ward's nested-action experiment"
                 (EXPERIMENT-EVIDENCE) :AUTHOR-REPORTED)
           (LIST "tree" "Observed action tree" TREE :OBSERVED)
           (LIST "syntax" "Nested syntax"
                 (READING-PAGE "Nested Actions in Solo") :DERIVED)
           (LIST "solo" "SOLO" TREE :AUTHOR-REPORTED)
           (LIST "nested-statement" "Nested statement" LISTEN :OBSERVED)
           (LIST "listen" "LISTEN" LISTEN :AUTHOR-REPORTED)
           (LIST "event" "Received MessageEvent (fixture)"
                 (WITNESS-STAGE WITNESS "reception") :OBSERVED)
           (LIST "report" "REPORT" REPORT :AUTHOR-REPORTED)
           (LIST "title" "REPORT title: supplying path / exact gap" INPUT
                 :OPEN)
           (LIST "enclosing-context"
                 "enclosing-context (earlier hypothesis; challenged)"
                 (FIND "enclosing-context" HISTORY :KEY
                       (LAMBDA (H) (GETF H :ID)) :TEST #'EQUAL)
                 :HISTORICAL-HYPOTHESIS)
           (LIST "inherited-context"
                 "inherited-context (earlier hypothesis; challenged)"
                 (FIND "inherited-context" HISTORY :KEY
                       (LAMBDA (H) (GETF H :ID)) :TEST #'EQUAL)
                 :HISTORICAL-HYPOTHESIS)
           (LIST "event-context"
                 "event-context (earlier hypothesis; challenged)"
                 (FIND "event-context" HISTORY :KEY (LAMBDA (H) (GETF H :ID))
                       :TEST #'EQUAL)
                 :HISTORICAL-HYPOTHESIS)
           (LIST "lifetime" "Lifetime (question)"
                 (FIND :LIFETIME QUESTIONS :KEY (LAMBDA (Q) (GETF Q :ID)))
                 :OPEN)
           (LIST "probes" "Message handoff probes" (PROPOSED-PROBES) :PROPOSED)
           (LIST "solo-popup-click"
                 "Solo popup click handler (supplied fragment)"
                 (FIRST (WITNESS-SOURCES WITNESS)) :SOURCE-OBSERVED)
           (LIST "publish-source-data-message" "publishSourceData message"
                 (WITNESS-STAGE WITNESS "emittedMessage") :SOURCE-OBSERVED)
           (LIST "node-topic" "node topic"
                 (GETHASH "topic" (WITNESS-STAGE WITNESS "receivedMessage"))
                 :SOURCE-OBSERVED)
           (LIST "title-payload" "title payload"
                 (GETHASH "title" (WITNESS-STAGE WITNESS "receivedMessage"))
                 :SOURCE-OBSERVED)
           (LIST "window-event-emitter" "window event emitter (opener realm)"
                 (WITNESS-STAGE WITNESS "emitter") :SOURCE-OBSERVED)
           (LIST "broadcast-event-reach"
                 "Broadcast across lineup (Ward reports)" WARD
                 :AUTHOR-REPORTED)
           (LIST "subordinate-execution" "Subordinate execution"
                 (READING-PAGE "Two Relations Hidden in One Nest")
                 :AUTHOR-REPORTED)
           (LIST "scoped-event-emitter-proposal"
                 "Scoped event emitter (proposal)" (GETF WARD :SCOPED-EMITTER)
                 :DESIGN-PROPOSAL)
           (LIST "nested-action-input" "Current nested input: gap"
                 (INPUT-STAGE INPUT "nested-action-input") :OPEN)
           (LIST "report-lookup-target" "Current REPORT lookup target: gap"
                 (INPUT-STAGE INPUT "report-lookup-target") :OPEN)
           (LIST "witness" "One emitted message: recorded witness" WITNESS
                 :OBSERVED)
           (LIST "received-message" "Received MessageEvent (input witness)"
                 (INPUT-STAGE INPUT "received-message") :RUNTIME-OBSERVED)
           (LIST "message-data" "event.data / local data: same object"
                 (INPUT-STAGE INPUT "message-data") :SOURCE-OBSERVED)
           (LIST "listen-match" "publishSourceData + node match"
                 (INPUT-STAGE INPUT "listen-match") :SOURCE-OBSERVED)
           (LIST "title-value" "Current nested title result: unavailable"
                 (INPUT-STAGE INPUT "title-value") :OPEN)
           (LIST "retained-report-state" "Independent retained REPORT state"
                 (INPUT-STAGE INPUT "retained-report-state") :RUNTIME-OBSERVED)
           (LIST "retained-title-value"
                 "Independent retained value: Prior Title"
                 (INPUT-STAGE INPUT "retained-title-value") :RUNTIME-OBSERVED)
           (LIST "input-path" "Message → nested input: exact boundary" INPUT
                 :DERIVED)))
         (TOPICS
          (LOOP FOR (ID LABEL OBJECT STATUS) IN SPECS
                FOR I FROM 0
                COLLECT (TM:MAKE-TOPICMAP-TOPIC :ID ID :TYPE :READING-CONCEPT
                                                :LABEL LABEL :OBJECT OBJECT
                                                :VIEW-PROPERTIES
                                                (LIST :X
                                                      (+ 30 (* 245 (MOD I 5)))
                                                      :Y
                                                      (+ 30
                                                         (* 145 (FLOOR I 5)))
                                                      :VISIBLE T
                                                      :EVIDENCE-STATUS
                                                      STATUS))))
         (RELATIONS
          '(("solo" "listen" "contains / subordinates (observed composition)"
             :SUBORDINATE-EXECUTION :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("listen" "report" "contains (subordinate)" :SUBORDINATE-EXECUTION
             :OBSERVED :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("solo" "nested-statement" "runs nested statements (Ward reports)"
             :SUBORDINATE-EXECUTION :AUTHOR-REPORTED :WARD-ORIGINAL-STATEMENT)
            ("subordinate-execution" "solo"
             "enclosing execution (Ward reports)" :SUBORDINATE-EXECUTION
             :AUTHOR-REPORTED :WARD-ORIGINAL-STATEMENT)
            ("tree" "syntax" "shows nested structure" :SUBORDINATE-EXECUTION
             :OBSERVED :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("syntax" "subordinate-execution"
             "enclosing actions run nested statements (Ward reports)"
             :SUBORDINATE-EXECUTION :AUTHOR-REPORTED :WARD-ORIGINAL-STATEMENT)
            ("solo-popup-click" "publish-source-data-message"
             "constructs message (event)" :EVENT-PROPAGATION :SOURCE-OBSERVED
             :WARD-SUPPLIED-PRODUCER)
            ("solo-popup-click" "title-payload"
             "props.title or normalized props.name (event)" :EVENT-PROPAGATION
             :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("publish-source-data-message" "title-payload"
             "carries title (event)" :EVENT-PROPAGATION :SOURCE-OBSERVED
             :WARD-SUPPLIED-PRODUCER)
            ("publish-source-data-message" "node-topic"
             "carries topic=node (event)" :EVENT-PROPAGATION :SOURCE-OBSERVED
             :WARD-SUPPLIED-PRODUCER)
            ("publish-source-data-message" "window-event-emitter"
             "postMessage to opener (event)" :EVENT-PROPAGATION
             :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("window-event-emitter" "listen"
             "registers on window (retained LISTEN)" :EVENT-PROPAGATION
             :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("node-topic" "listen"
             "matches data.topic or data.name (retained LISTEN)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("window-event-emitter" "broadcast-event-reach"
             "left/right lineup reach (Ward reports)" :EVENT-PROPAGATION
             :AUTHOR-REPORTED :WARD-FOLLOW-UP)
            ("broadcast-event-reach" "listen"
             "can reach an earlier LISTEN (Ward reports)" :EVENT-PROPAGATION
             :AUTHOR-REPORTED :WARD-FOLLOW-UP)
            ("window-event-emitter" "event"
             "native message reception (fixture)" :EVENT-PROPAGATION :OBSERVED
             :RECORDED-NATIVE-BROWSER-WITNESS)
            ("listen" "event" "counts matching messages (retained LISTEN)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("listen" "nested-action-input" "current handoff unestablished"
             :PAYLOAD-TO-INPUT :OPEN :CURRENT-SOURCE-GAP)
            ("nested-action-input" "report-lookup-target"
             "current lookup target unestablished" :PAYLOAD-TO-INPUT :OPEN
             :CURRENT-SOURCE-GAP)
            ("report-lookup-target" "report"
             "current nested invocation/lookup target unavailable"
             :PAYLOAD-TO-INPUT :OPEN :CURRENT-SOURCE-GAP)
            ("report" "title" "names title argument (subordinate)"
             :SUBORDINATE-EXECUTION :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("listen" "scoped-event-emitter-proposal"
             "could-use alternative to window (proposal)" :EVENT-PROPAGATION
             :DESIGN-PROPOSAL :WARD-SCOPED-EMITTER-PROPOSAL)
            ("witness" "publish-source-data-message"
             "records native emitted payload" :EVENT-PROPAGATION :OBSERVED
             :RECORDED-NATIVE-BROWSER-WITNESS)
            ("event" "event-context"
             "payload reception does not establish rebinding"
             :EVENT-PROPAGATION :DERIVED :CURRENT-SOURCE-GAP)
            ("nested-action-input" "inherited-context"
             "current handoff unverified; earlier inheritance hypothesis retained"
             :SUBORDINATE-EXECUTION :OPEN :CURRENT-SOURCE-GAP)
            ("broadcast-event-reach" "enclosing-context"
             "challenges nesting-only context explanation" :EVENT-PROPAGATION
             :DERIVED :WARD-FOLLOW-UP)
            ("listen" "lifetime" "current disposal remains open"
             :EVENT-PROPAGATION :DERIVED :READING-QUESTION)
            ("nested-action-input" "probes" "trace this handoff next"
             :PAYLOAD-TO-INPUT :DERIVED :READING-QUESTION)
            ("experiment" "tree" "transcribed nested structure"
             :SUBORDINATE-EXECUTION :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("solo-popup-click" "window-event-emitter"
             "posts-via window.opener.postMessage (supplied source)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("window-event-emitter" "listen"
             "provides broadcast reach (Ward reports)" :EVENT-PROPAGATION
             :AUTHOR-REPORTED :WARD-FOLLOW-UP)
            ("window-event-emitter" "received-message"
             "native opener reception (bounded input witness)"
             :EVENT-PROPAGATION :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
            ("received-message" "message-data"
             "const { data } = event; direct alias (retained source)"
             :PAYLOAD-TO-INPUT :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("received-message" "message-data"
             "local data === receiver event.data (live identity measured)"
             :PAYLOAD-TO-INPUT :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
            ("message-data" "listen-match"
             "tests action and topic/name inline (no separate dispatcher)"
             :PAYLOAD-TO-INPUT :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("message-data" "listen-match"
             "selected data preserves receiver object identity"
             :PAYLOAD-TO-INPUT :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
            ("listen-match" "listen"
             "matching callback counts/statuses; zero nested dispatches"
             :PAYLOAD-TO-INPUT :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
            ("listen-match" "nested-action-input"
             "matched payload → current input unavailable" :PAYLOAD-TO-INPUT
             :OPEN :CURRENT-SOURCE-GAP)
            ("report" "title-value" "current nested title result unavailable"
             :PAYLOAD-TO-INPUT :OPEN :CURRENT-SOURCE-GAP)
            ("retained-report-state" "report"
             "report_emit accepts state; independent caller only"
             :PAYLOAD-TO-INPUT :SOURCE-OBSERVED :MECH-A028-REPORT)
            ("retained-report-state" "retained-title-value"
             "independent REPORT reads Prior Title from same state object"
             :PAYLOAD-TO-INPUT :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
            ("report" "title"
             "args[0] selects title; retained state[key] lookup"
             :PAYLOAD-TO-INPUT :SOURCE-OBSERVED :MECH-A028-REPORT)
            ("title" "input-path"
             "navigate title supplying path and exact missing boundary"
             :PAYLOAD-TO-INPUT :DERIVED :READING-NAVIGATION)
            ("input-path" "received-message"
             "trace begins at native reception; current handoff gap explicit"
             :PAYLOAD-TO-INPUT :DERIVED :REVISION-BOUNDED-TRACE))))
    (TM:MAKE-TOPICMAP-PROJECTION :SOURCE WARD :TOPICS TOPICS :ASSOCIATIONS
                                 (LOOP FOR (FROM TO LABEL KIND STATUS
                                            SOURCE) IN RELATIONS
                                       FOR I FROM 0
                                       COLLECT (TM:MAKE-TOPICMAP-ASSOCIATION
                                                :ID
                                                (FORMAT NIL
                                                        "nested-relation-~D" I)
                                                :TYPE LABEL :FROM FROM :TO TO
                                                :PROPERTIES
                                                (LIST :RELATION-KIND KIND
                                                      :EVIDENCE-STATUS STATUS
                                                      :WARRANT
                                                      (LIST :STATUS STATUS
                                                            :SOURCE SOURCE)
                                                      :REVISION-BOUNDARY
                                                      (WHEN
                                                          (MEMBER SOURCE
                                                                  '(:MECH-A028-LISTEN
                                                                    :MECH-A028-REPORT))
                                                        "Retained a028b4b; current nested implementation not established."))))
                                 :VIEW-PROPERTIES '(:WIDTH 1300 :HEIGHT 1110))))

(HYPERDOC:DEFEXAMPLE READING-WORKSPACE
  (TM:MAKE-TOPICMAP-WORKSPACE (READING-PROJECTION) "tree"))

(DEFUN TOPIC-WORKSPACE (TOPIC-ID)
  "Navigate to a canonical concept ID; preserve the previous follow-up's native links."
  (LET* ((ALIASES
          '(("popup-handler" . "solo-popup-click")
            ("message" . "publish-source-data-message")
            ("window-emitter" . "window-event-emitter")
            ("broadcast" . "broadcast-event-reach")
            ("scoped-emitter" . "scoped-event-emitter-proposal")
            ("nested-input" . "nested-action-input")
            ("report-target" . "report-lookup-target")))
         (CANONICAL (OR (CDR (ASSOC TOPIC-ID ALIASES :TEST #'EQUAL)) TOPIC-ID))
         (WORKSPACE (READING-WORKSPACE)))
    (TM:TOPICMAP-WORKSPACE-GO-TO WORKSPACE CANONICAL)
    WORKSPACE))

(HYPERDOC:DEFEXAMPLE LAYOUT-COMPARISON
  "Use TALA only for layout; native Topic signs still navigate the original Workspace."
  (LAYOUT:COMPARE-WORKSPACE-LAYOUTS (READING-WORKSPACE) :SEED 44))

(DREYECK/HYPERDOC:DEFHYPERDOC *READING* :TITLE "Nested Actions in Solo" :ID
                              "dreyeck/nested-actions/reading"
                              :ASDF-SYSTEM-NAME
                              "dreyeck/nested-actions/reading" :SUBDIRECTORY
                              "dreyeck/pages/nested-actions" :CODE-SUBDIRECTORY
                              "dreyeck/nested-actions" :MAIN-PAGE-ID
                              "Nested Actions in Solo")

(DOLIST
    (NAME
     '(EXPERIMENT-EVIDENCE OBSERVED-ACTION-TREE SEMANTIC-QUESTIONS
                           PROPOSED-PROBES READING-PROJECTION READING-WORKSPACE
                           LAYOUT-COMPARISON MESSAGE-SOURCE-OBSERVATIONS
                           PRODUCER-SOURCE EMITTED-MESSAGE-WITNESS
                           WARD-PROPAGATION-EVIDENCE
                           HISTORICAL-CONTEXT-HYPOTHESES RECEIVED-INPUT-TRACE
                           INPUT-HYPOTHESES))
  (DREYECK/AUTHORITY-POLICY:REGISTER-OPERATION-CONTRACT :IDENTITY
                                                        (FORMAT NIL
                                                                "nested-actions/~A"
                                                                NAME)
                                                        :OPERATION
                                                        (FORMAT NIL
                                                                "DREYECK/NESTED-ACTIONS::~A"
                                                                NAME)
                                                        :APPLICABILITY :EXAMPLE
                                                        :STATUS :CONTRACTED
                                                        :EFFECT-CLASSES
                                                        '(:OBSERVATIONAL)
                                                        :EFFECT-EXTENT
                                                        "Allocates syntax, evidence, question or Workspace objects; optional layout invokes the existing D2/TALA boundary on temporary files. No FedWiki action runs."
                                                        :AUTHORITY
                                                        "This reading's supplied transcription, persisted Lisp forms and projection."
                                                        :PRECONDITIONS
                                                        "Reading system loaded; layout-comparison requires the pinned D2/TALA runtime."
                                                        :POSTCONDITIONS
                                                        "Persisted pages, source and external FedWiki state are unchanged."
                                                        :VERIFICATION-EVIDENCE
                                                        "dreyeck/nested-actions/reading/tests and dreyeck/nested-actions/tala/tests"
                                                        :REPLAY-SEMANTICS
                                                        "Fresh ephemeral objects; no event subscription."
                                                        :AUDIT-PROVENANCE
                                                        "Nested-actions slice, 2026-10-07"))
