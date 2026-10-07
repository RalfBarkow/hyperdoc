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

(DEFUN READING-PAGE (TITLE)
  (HYPERBOOK:FIND-PAGE
   (HYPERBOOK:FIND-HYPERBOOK "dreyeck/nested-actions/reading" :SIGNAL-ERROR? T)
   TITLE :SIGNAL-ERROR? T))

(HYPERDOC:DEFEXAMPLE READING-PROJECTION
  "Two independent mechanism relation kinds, with revision-specific warrants and explicit handoff gaps."
  (LET* ((TREE (OBSERVED-ACTION-TREE))
         (LISTEN (FIRST (ACTION-CHILDREN TREE)))
         (REPORT (FIRST (ACTION-CHILDREN LISTEN)))
         (QUESTIONS (SEMANTIC-QUESTIONS))
         (WITNESS (EMITTED-MESSAGE-WITNESS))
         (WARD (WARD-PROPAGATION-EVIDENCE))
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
           (LIST "title" "title lookup (question)"
                 (FIND :TITLE QUESTIONS :KEY (LAMBDA (Q) (GETF Q :ID))) :OPEN)
           (LIST "enclosing-context" "Enclosing input (question)"
                 (READING-PAGE "What Does a Nested Action Inherit?") :OPEN)
           (LIST "inherited-context" "Nested input handoff (question)"
                 QUESTIONS :OPEN)
           (LIST "event-context" "Event data transformation (question)"
                 (FIND :EVENT-CONTEXT QUESTIONS :KEY (LAMBDA (Q) (GETF Q :ID)))
                 :OPEN)
           (LIST "lifetime" "Lifetime (question)"
                 (FIND :LIFETIME QUESTIONS :KEY (LAMBDA (Q) (GETF Q :ID)))
                 :OPEN)
           (LIST "probes" "Message handoff probes" (PROPOSED-PROBES) :PROPOSED)
           (LIST "popup-handler" "Solo popup click handler (supplied fragment)"
                 (FIRST (WITNESS-SOURCES WITNESS)) :SOURCE-OBSERVED)
           (LIST "message" "publishSourceData message"
                 (WITNESS-STAGE WITNESS "emittedMessage") :SOURCE-OBSERVED)
           (LIST "node-topic" "node topic"
                 (GETHASH "topic" (WITNESS-STAGE WITNESS "receivedMessage"))
                 :SOURCE-OBSERVED)
           (LIST "title-payload" "title payload"
                 (GETHASH "title" (WITNESS-STAGE WITNESS "receivedMessage"))
                 :SOURCE-OBSERVED)
           (LIST "window-emitter" "window event emitter (opener realm)"
                 (WITNESS-STAGE WITNESS "emitter") :SOURCE-OBSERVED)
           (LIST "broadcast" "Broadcast across lineup (Ward reports)" WARD
                 :AUTHOR-REPORTED)
           (LIST "subordinate-execution" "Subordinate execution"
                 (READING-PAGE "Two Relations Hidden in One Nest")
                 :AUTHOR-REPORTED)
           (LIST "scoped-emitter" "Scoped event emitter (proposal)"
                 (GETF WARD :SCOPED-EMITTER) :DESIGN-PROPOSAL)
           (LIST "nested-input" "Current nested input: gap"
                 (WITNESS-STAGE WITNESS "nestedInput") :OPEN)
           (LIST "report-target" "Current REPORT lookup target: gap"
                 (WITNESS-STAGE WITNESS "reportLookupTarget") :OPEN)
           (LIST "witness" "One emitted message: recorded witness" WITNESS
                 :OBSERVED)))
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
          '(("solo" "listen" "contains (subordinate)" :SUBORDINATE-EXECUTION
             :OBSERVED :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
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
            ("popup-handler" "message" "constructs message (event)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("popup-handler" "title-payload"
             "props.title or normalized props.name (event)" :EVENT-PROPAGATION
             :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("message" "title-payload" "carries title (event)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("message" "node-topic" "carries topic=node (event)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("message" "window-emitter" "postMessage to opener (event)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :WARD-SUPPLIED-PRODUCER)
            ("window-emitter" "listen" "registers on window (retained LISTEN)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("node-topic" "listen"
             "matches data.topic or data.name (retained LISTEN)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("window-emitter" "broadcast"
             "left/right lineup reach (Ward reports)" :EVENT-PROPAGATION
             :AUTHOR-REPORTED :WARD-FOLLOW-UP)
            ("broadcast" "listen" "can reach an earlier LISTEN (Ward reports)"
             :EVENT-PROPAGATION :AUTHOR-REPORTED :WARD-FOLLOW-UP)
            ("window-emitter" "event" "native message reception (fixture)"
             :EVENT-PROPAGATION :OBSERVED :RECORDED-NATIVE-BROWSER-WITNESS)
            ("listen" "event" "counts matching messages (retained LISTEN)"
             :EVENT-PROPAGATION :SOURCE-OBSERVED :MECH-A028-LISTEN)
            ("listen" "nested-input" "current handoff unestablished"
             :EVENT-PROPAGATION :OPEN :CURRENT-SOURCE-GAP)
            ("nested-input" "report-target"
             "current lookup target unestablished" :EVENT-PROPAGATION :OPEN
             :CURRENT-SOURCE-GAP)
            ("report-target" "report"
             "retained REPORT reads state[key]; current target unknown"
             :SUBORDINATE-EXECUTION :SOURCE-OBSERVED :MECH-A028-REPORT)
            ("report" "title" "names title argument (subordinate)"
             :SUBORDINATE-EXECUTION :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("scoped-emitter" "listen" "could replace window (proposal)"
             :EVENT-PROPAGATION :DESIGN-PROPOSAL :WARD-SCOPED-EMITTER-PROPOSAL)
            ("witness" "message" "records native emitted payload"
             :EVENT-PROPAGATION :OBSERVED :RECORDED-NATIVE-BROWSER-WITNESS)
            ("event" "event-context" "requires current transformation evidence"
             :EVENT-PROPAGATION :DERIVED :CURRENT-SOURCE-GAP)
            ("event-context" "inherited-context"
             "asks what becomes nested input" :EVENT-PROPAGATION :DERIVED
             :READING-QUESTION)
            ("inherited-context" "enclosing-context"
             "asks how nested input is supplied" :SUBORDINATE-EXECUTION
             :DERIVED :READING-QUESTION)
            ("listen" "lifetime" "current disposal remains open"
             :EVENT-PROPAGATION :DERIVED :READING-QUESTION)
            ("nested-input" "probes" "trace this handoff next"
             :EVENT-PROPAGATION :DERIVED :READING-QUESTION)
            ("experiment" "tree" "transcribed nested structure"
             :SUBORDINATE-EXECUTION :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION))))
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
                                 :VIEW-PROPERTIES '(:WIDTH 1300 :HEIGHT 830))))

(HYPERDOC:DEFEXAMPLE READING-WORKSPACE
  (TM:MAKE-TOPICMAP-WORKSPACE (READING-PROJECTION) "tree"))

(DEFUN TOPIC-WORKSPACE (TOPIC-ID)
  "Native point navigation using the same reading projection."
  (LET ((WORKSPACE (READING-WORKSPACE)))
    (TM:TOPICMAP-WORKSPACE-GO-TO WORKSPACE TOPIC-ID)
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
                           WARD-PROPAGATION-EVIDENCE))
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
