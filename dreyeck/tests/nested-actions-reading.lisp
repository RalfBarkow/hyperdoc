;;;; Nested Actions Reading Acceptance

(DEFPACKAGE #:DREYECK/NESTED-ACTIONS/TESTS
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:R #:DREYECK/NESTED-ACTIONS)
                    (#:TM #:DREYECK/TOPICMAP)
                    (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:LT #:DREYECK/INSPECTOR/TOPICMAP/TALA))
  (:EXPORT #:RUN-TESTS #:RUN-TALA-TESTS))

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS/TESTS)

(DEFUN VIEW-NAMED (OBJECT TITLE)
  (OR (FIND TITLE (V:ALL-VIEWS OBJECT) :KEY #'V:VIEW-TITLE :TEST #'EQUAL)
      (ERROR "Missing ~A view of ~S." TITLE OBJECT)))

(DEFUN RENDER (OBJECT TITLE)
  (LET ((VIEW (VIEW-NAMED OBJECT TITLE)))
    (V:VIEW-HTML VIEW)
    (ASSERT
     (NOTANY (LAMBDA (REF) (TYPEP (CDR REF) 'CONDITION))
             (V:VIEW-REFERENCES VIEW)))
    VIEW))

(DEFUN PAGE (TITLE)
  (HYPERBOOK:FIND-PAGE "dreyeck/nested-actions/reading" TITLE :SIGNAL-ERROR? T))

(DEFUN CHECK-PAGES ()
  (LET ((BOOK
         (HYPERBOOK:FIND-HYPERBOOK "dreyeck/nested-actions/reading"
                                   :SIGNAL-ERROR? T)))
    (ASSERT
     (= 1
        (COUNT "dreyeck/nested-actions/reading"
               (HYPERBOOK:HYPERBOOKS-OF HYPERBOOK:*CATALOG*) :KEY
               #'HYPERBOOK:ID-OF :TEST #'EQUAL)))
    (ASSERT (EQUAL "Nested Actions in Solo" (HYPERBOOK:MAIN-PAGE-ID-OF BOOK)))
    (ASSERT
     (EQ (PAGE "Nested Actions in Solo")
         (HYPERBOOK:LOOKUP-PATH BOOK '("Nested Actions in Solo"))))
    (DOLIST
        (TITLE
         '("Nested Actions in Solo" "What Does a Nested Action Inherit?"
           "Two Relations Hidden in One Nest" "From Message to Nested Input"
           "Adding to an Already Rendered Solo Popup"))
      (LET* ((P (PAGE TITLE))
             (VIEW (RENDER P "Content"))
             (OBJECTS (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW)))
             (DOM (PLUMP-PARSER:PARSE (HYPERDOC:FILE-OF P))))
        (ASSERT
         (EQUAL TITLE
                (PLUMP-DOM:TEXT
                 (FIRST (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM "title")))))
        (ASSERT
         (EQUAL TITLE
                (PLUMP-DOM:TEXT
                 (FIRST (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM "h1")))))
        (DOLIST (A (PLUMP-DOM:GET-ELEMENTS-BY-TAG-NAME DOM "a"))
          (LET ((TARGET (PLUMP-DOM:ATTRIBUTE A "page"))
                (EXPR (PLUMP-DOM:ATTRIBUTE A "expr")))
            (WHEN TARGET (ASSERT (PAGE TARGET)))
            (WHEN EXPR
              (LET* ((*PACKAGE* (FIND-PACKAGE :DREYECK/NESTED-ACTIONS))
                     (VALUE
                      (EVAL
                       (READ-FROM-STRING (PLUMP-DOM:DECODE-ENTITIES EXPR)))))
                (ASSERT VALUE)
                (ASSERT (NOT (TYPEP VALUE 'CONDITION)))
                (WHEN (TYPEP VALUE 'TM:TOPICMAP-WORKSPACE)
                  (ASSERT (TM:TOPICMAP-WORKSPACE-CURRENT-TOPIC VALUE)))))))
        (DOLIST
            (CODE-TITLE
             '("Inspecting the Observed Nested Action Tree"
               "Proposed Nested Action Probes" "Following One Node Message"
               "Tracing the Received Message Boundary"
               "Git Revisions Behind the Source"
               "Tracing Historical Popup Additions"))
          (ASSERT (MEMBER (PAGE CODE-TITLE) OBJECTS :TEST #'EQ)))
        (ASSERT (FIND-IF (LAMBDA (O) (TYPEP O 'R:NESTED-ACTION)) OBJECTS))
        (ASSERT
         (FIND-IF (LAMBDA (O) (TYPEP O 'TM:TOPICMAP-WORKSPACE)) OBJECTS))
        (ASSERT (FIND #'R:OBSERVED-ACTION-TREE OBJECTS :TEST #'EQ))))
    (DOLIST
        (TITLE
         '("Inspecting the Observed Nested Action Tree"
           "Proposed Nested Action Probes"
           "Navigating the Nested Actions Investigation"
           "Following One Node Message" "Tracing the Received Message Boundary"
           "Git Revisions Behind the Source"
           "Tracing Historical Popup Additions"))
      (LET ((P (PAGE TITLE)))
        (HYPERDOC:LOAD-PAGE P)
        (LET ((LINKS (HYPERBOOK:PAGE-LINKS-OF (HYPERBOOK:LINKS-OF P))))
          (DOLIST
              (TARGET
               '("Nested Actions in Solo" "What Does a Nested Action Inherit?"
                 "Two Relations Hidden in One Nest"
                 "From Message to Nested Input"
                 "Adding to an Already Rendered Solo Popup"))
            (LET ((LINK
                   (FIND TARGET LINKS :KEY #'HYPERBOOK:TARGET-PAGE-OF :TEST
                         #'EQUAL)))
              (ASSERT LINK)
              (ASSERT
               (EQ (PAGE TARGET) (V:EVAL-THUNK (HYPERBOOK:THUNK-OF LINK)))))))
        (RENDER P "Source")))))

(DEFUN CHECK-TREE ()
  (LET* ((TREE (R:OBSERVED-ACTION-TREE))
         (LISTEN (FIRST (R:ACTION-CHILDREN TREE)))
         (REPORT (FIRST (R:ACTION-CHILDREN LISTEN))))
    (ASSERT
     (EQUAL '("SOLO" "LISTEN" "REPORT")
            (MAPCAR #'R:ACTION-NAME (LIST TREE LISTEN REPORT))))
    (ASSERT (NULL (R:ACTION-ARGUMENTS TREE)))
    (ASSERT (EQUAL '("node") (R:ACTION-ARGUMENTS LISTEN)))
    (ASSERT (EQUAL '("title") (R:ACTION-ARGUMENTS REPORT)))
    (ASSERT (NULL (R:ACTION-CHILDREN REPORT)))
    (LOOP FOR PARENT IN (LIST TREE LISTEN)
          FOR CHILD IN (LIST LISTEN REPORT)
          DO (ASSERT
              (MEMBER CHILD
                      (MAPCAR #'CDR
                              (V:VIEW-REFERENCES
                               (RENDER PARENT "Action tree")))
                      :TEST #'EQ)))
    (RENDER REPORT "Action tree")
    (ASSERT (NOT (EQ TREE (R:OBSERVED-ACTION-TREE))))
    (LET* ((SOURCE
            (RENDER (PAGE "Inspecting the Observed Nested Action Tree")
                    "Source"))
           (RESULTS
            (LOOP FOR REF IN (V:VIEW-REFERENCES SOURCE)
                  WHEN (TYPEP (CDR REF) 'V:THUNK)
                  COLLECT (V:EVAL-THUNK (CDR REF)))))
      (ASSERT (FIND-IF (LAMBDA (O) (TYPEP O 'R:NESTED-ACTION)) RESULTS)))))

(DEFUN CHECK-STATUS ()
  (LET ((EVIDENCE (R:EXPERIMENT-EVIDENCE))
        (QUESTIONS (R:SEMANTIC-QUESTIONS))
        (PROBES (R:PROPOSED-PROBES)))
    (ASSERT (EQ :USER-SUPPLIED-TASK (GETF EVIDENCE :ORIGIN)))
    (ASSERT (EQ :HISTORICAL-HYPOTHESIS (GETF EVIDENCE :INTERPRETATION-STATUS)))
    (ASSERT
     (EQ :NOT-LOCALLY-ESTABLISHED (GETF EVIDENCE :IMPLEMENTATION-STATUS)))
    (ASSERT (EQ :SYNTAX-CONSTRUCTION-ONLY (GETF EVIDENCE :HYPERDOC-WITNESS)))
    (ASSERT
     (EQUAL
      '((:CLICK) (:NEIGHBORS :PAGES 1845 :SITES 4)
        (:WALK :ARGUMENT 10 :ASPECTS 4 :NODES 8)
        (:CLICK
         (:SOLO :SOURCES 1 :ASPECTS 4
          (:LISTEN :ARGUMENT "node" :EVENTS 7 :ELAPSED-MS 7984
           (:REPORT :ARGUMENT "title")))))
      (GETF EVIDENCE :COMPOSITION)))
    (ASSERT
     (EQUAL
      '(:ENVIRONMENT :NODE :TITLE :EVENT-CONTEXT :LIFETIME :TERMINATION :SCOPE)
      (MAPCAR (LAMBDA (Q) (GETF Q :ID)) QUESTIONS)))
    (DOLIST (Q QUESTIONS)
      (ASSERT (EQ :OPEN (GETF Q :STATUS)))
      (ASSERT (NULL (GETF Q :ANSWER)))
      (ASSERT (NULL (GETF Q :EVIDENCE))))
    (ASSERT (= 3 (LENGTH PROBES)))
    (ASSERT (EQ :MESSAGE-HANDOFF (GETF (FIRST PROBES) :ID)))
    (DOLIST (PROBE PROBES)
      (ASSERT
       (EQ
        (IF (EQ :OUTER-INNER-TITLE (GETF PROBE :ID))
            :SUPERSEDED
            :PROPOSED)
        (GETF PROBE :STATUS)))
      (ASSERT (NOT (GETF PROBE :EXECUTABLE-P)))
      (ASSERT (EQ :UNVERIFIED (GETF PROBE :NOTATION-VALIDITY)))
      (ASSERT (NULL (GETF PROBE :RESULT)))
      (ASSERT (GETF PROBE :REQUIRED-EVIDENCE)))))

(DEFUN CHECK-WORKSPACE ()
  (LET* ((WORKSPACE (R:READING-WORKSPACE))
         (PROJECTION (TM:TOPICMAP-PROJECTION-OF WORKSPACE))
         (TOPICS (TM:TOPICMAP-PROJECTION-TOPICS-OF PROJECTION))
         (RELATIONS (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION)))
    (ASSERT (EQUAL "tree" (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
    (ASSERT (= 39 (LENGTH TOPICS)))
    (DOLIST
        (ID
         '("experiment" "tree" "syntax" "solo" "nested-statement" "listen"
           "event" "report" "title" "enclosing-context" "inherited-context"
           "event-context" "lifetime" "probes" "solo-popup-click"
           "publish-source-data-message" "node-topic" "title-payload"
           "window-event-emitter" "broadcast-event-reach"
           "subordinate-execution" "scoped-event-emitter-proposal"
           "nested-action-input" "report-lookup-target" "witness"
           "received-message" "message-data" "listen-match" "title-value"
           "retained-report-state" "retained-title-value" "input-path"
           "evidence-revision" "solo-append-batch" "solo-popup-beam"
           "solo-replace-batch" "speed-fetch" "speed-result-loop"
           "historical-ancestor"))
      (ASSERT (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION ID)))
    (ASSERT (= 52 (LENGTH RELATIONS)))
    (DOLIST (A RELATIONS)
      (ASSERT
       (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION
                                           (TM:TOPICMAP-ASSOCIATION-FROM-OF
                                            A)))
      (ASSERT
       (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION
                                           (TM:TOPICMAP-ASSOCIATION-TO-OF A)))
      (LET* ((PROPS (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A))
             (STATUS (GETF PROPS :EVIDENCE-STATUS)))
        (ASSERT
         (MEMBER STATUS
                 '(:OBSERVED :DERIVED :SOURCE-OBSERVED :AUTHOR-REPORTED
                   :DESIGN-PROPOSAL :OPEN :RUNTIME-OBSERVED :HYPOTHESIZED)))
        (ASSERT (EQ STATUS (GETF (GETF PROPS :WARRANT) :STATUS)))
        (ASSERT (GETF (GETF PROPS :WARRANT) :SOURCE))))
    (DOLIST (PAIR '(("solo" "listen") ("listen" "report")))
      (LET ((A
             (FIND-IF
              (LAMBDA (A)
                (AND (EQUAL (FIRST PAIR) (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
                     (EQUAL (SECOND PAIR) (TM:TOPICMAP-ASSOCIATION-TO-OF A))))
              RELATIONS)))
        (ASSERT
         (EQ :SUBORDINATE-EXECUTION
             (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A) :RELATION-KIND)))
        (ASSERT
         (EQ :OBSERVED
             (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A)
                   :EVIDENCE-STATUS)))))
    (LET ((A
           (FIND "enclosing-context" RELATIONS :KEY
                 #'TM:TOPICMAP-ASSOCIATION-TO-OF :TEST #'EQUAL)))
      (ASSERT
       (EQ :DERIVED
           (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A) :EVIDENCE-STATUS))))
    (LET* ((VIEW (RENDER WORKSPACE "Topicmap"))
           (HTML (V:VIEW-HTML VIEW))
           (ACTIONS
            (REMOVE-IF-NOT
             (LAMBDA (REF)
               (AND (TYPEP (CDR REF) 'V:THUNK)
                    (SEARCH
                     (FORMAT NIL
                             "id='~A' class='dreyeck-topicmap-workspace-action "
                             (CAR REF))
                     HTML)))
             (V:VIEW-REFERENCES VIEW))))
      (ASSERT (= 39 (LENGTH ACTIONS)))
      (DOLIST (REF ACTIONS)
        (LET* ((OLD (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE))
               (HISTORY
                (COPY-LIST (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE)))
               (TOPIC (V:EVAL-THUNK (CDR REF)))
               (ID (TM:TOPICMAP-TOPIC-ID-OF TOPIC)))
          (ASSERT (EQ TOPIC (TM:TOPICMAP-WORKSPACE-CURRENT-TOPIC WORKSPACE)))
          (ASSERT
           (EQ (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC)
               (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE)))
          (ASSERT
           (EQUAL
            (IF (EQUAL OLD ID)
                HISTORY
                (CONS OLD HISTORY))
            (TM:TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE))))))
    (LET ((AT (R:TOPIC-WORKSPACE "title")))
      (ASSERT (EQUAL "title" (TM:TOPICMAP-WORKSPACE-POINT-OF AT)))
      (ASSERT (EQUAL '("tree") (TM:TOPICMAP-WORKSPACE-HISTORY-OF AT))))))

(DEFUN CHECK-MESSAGE-PATH ()
  (LET* ((WITNESS (R:EMITTED-MESSAGE-WITNESS))
         (CAPTURE (R:WITNESS-CAPTURE WITNESS))
         (EVENTS (GETHASH "events" CAPTURE))
         (SOURCES (R:WITNESS-SOURCES WITNESS))
         (PRODUCER (FIRST SOURCES))
         (SOURCE-VIEW (RENDER PRODUCER "Source evidence"))
         (LINKED-WITNESS
          (FIND-IF (LAMBDA (O) (TYPEP O 'R:MESSAGE-WITNESS))
                   (MAPCAR #'CDR (V:VIEW-REFERENCES SOURCE-VIEW))))
         (PATH-VIEW (RENDER LINKED-WITNESS "Message path"))
         (WORKSPACE
          (FIND-IF (LAMBDA (O) (TYPEP O 'TM:TOPICMAP-WORKSPACE))
                   (MAPCAR #'CDR (V:VIEW-REFERENCES PATH-VIEW)))))
    (PROGN
     (ASSERT
      (EQUAL "df3803329a340bf1c75dc27657acdc1fd20ee2ea3bfc736407e8f0f1fd2b440e"
             (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
              (IRONCLAD:DIGEST-FILE :SHA256
                                    (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
                                     "dreyeck/nested-actions/reading"
                                     "dreyeck/nested-actions/message-witness.json")))))
     (ASSERT
      (EQUAL (GETHASH "fixtureSha256" CAPTURE)
             (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
              (IRONCLAD:DIGEST-FILE :SHA256
                                    (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
                                     "dreyeck/nested-actions/reading"
                                     "dreyeck/nested-actions/message-witness.html"))))))
    (ASSERT
     (EQUAL "native-window-opener-to-retained-listen"
            (GETHASH "mode" CAPTURE)))
    (ASSERT (= 2 (LENGTH EVENTS)))
    (ASSERT (= 6 (LENGTH SOURCES)))
    (ASSERT
     (SEARCH "window.opener.postMessage(message)" (R:SOURCE-TEXT PRODUCER)))
    (ASSERT
     (EQUAL "source-observed" (GETHASH "status" (R:SOURCE-METADATA PRODUCER))))
    (ASSERT (NULL (GETHASH "revision" (R:SOURCE-METADATA PRODUCER))))
    (ASSERT LINKED-WITNESS)
    (ASSERT WORKSPACE)
    (ASSERT (EQUAL "witness" (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
    (ASSERT
     (TYPEP (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE)
            'R:MESSAGE-WITNESS))
    (ASSERT
     (EQ (R:WITNESS-STAGE LINKED-WITNESS "nestedInput")
         (FIND (R:WITNESS-STAGE LINKED-WITNESS "nestedInput")
               (MAPCAR #'CDR (V:VIEW-REFERENCES PATH-VIEW)) :TEST #'EQ)))
    (LOOP FOR EVENT ACROSS EVENTS
          FOR TITLE IN '("Payload Title" "Fallback Node")
          FOR
          COUNT FROM 1
          DO (LET ((EMITTED (GETHASH "emittedMessage" EVENT))
                   (RECEIVED (GETHASH "receivedMessage" EVENT))
                   (RECEPTION (GETHASH "reception" EVENT)))
               (ASSERT (EQUALP EMITTED RECEIVED))
               (ASSERT (EQUAL "publishSourceData" (GETHASH "action" EMITTED)))
               (ASSERT (EQUAL "node" (GETHASH "topic" EMITTED)))
               (ASSERT (EQUAL TITLE (GETHASH "title" EMITTED)))
               (ASSERT (GETHASH "sourceIsPopup" RECEPTION))
               (ASSERT (GETHASH "distinctFromSenderObject" RECEPTION))
               (ASSERT (GETHASH "isTrusted" RECEPTION))
               (LOOP FOR HANDLER ACROSS (GETHASH "listeners" EVENT)
                     DO (ASSERT (= COUNT (GETHASH "count" HANDLER))))
               (DOLIST
                   (KEY '("listenerOutput" "nestedInput" "reportLookupTarget"))
                 (LET ((STAGE (GETHASH KEY EVENT)))
                   (ASSERT (HASH-TABLE-P STAGE))
                   (ASSERT (NTH-VALUE 1 (GETHASH "value" STAGE)))
                   (ASSERT (NULL (GETHASH "value" STAGE)))))
               (ASSERT
                (EQUAL "state.title"
                       (GETHASH "retainedRevisionKey"
                                (GETHASH "reportLookupTarget" EVENT))))))
    (LET* ((EVIDENCE (R:WARD-PROPAGATION-EVIDENCE))
           (PROPOSAL (GETF EVIDENCE :SCOPED-EMITTER)))
      (ASSERT (EQ :DESIGN-PROPOSAL (GETF PROPOSAL :STATUS)))
      (ASSERT (EQ :EVENT-EMITTER-REACH (GETF PROPOSAL :MEANING)))
      (ASSERT (NOT (GETF PROPOSAL :IMPLEMENTED-P)))
      (ASSERT (EQ :NOT-ESTABLISHED (GETF PROPOSAL :VARIABLE-SCOPE)))
      (DOLIST (REPORT (GETF EVIDENCE :REPORTS))
        (ASSERT (EQ :AUTHOR-REPORTED (GETF REPORT :STATUS)))))
    (LET* ((PROJECTION (R:READING-PROJECTION))
           (RELATIONS (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION))
           (KINDS
            (REMOVE-DUPLICATES
             (MAPCAR
              (LAMBDA (A)
                (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A)
                      :RELATION-KIND))
              RELATIONS))))
      (ASSERT (= 5 (LENGTH KINDS)))
      (ASSERT (MEMBER :SUBORDINATE-EXECUTION KINDS))
      (ASSERT (MEMBER :EVENT-PROPAGATION KINDS))
      (DOLIST (A RELATIONS)
        (WHEN
            (MEMBER "scoped-event-emitter-proposal"
                    (LIST (TM:TOPICMAP-ASSOCIATION-FROM-OF A)
                          (TM:TOPICMAP-ASSOCIATION-TO-OF A))
                    :TEST #'EQUAL)
          (ASSERT
           (EQ :DESIGN-PROPOSAL
               (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A)
                     :EVIDENCE-STATUS)))))
      (LET ((SUBORDINATE
             (FIND-IF
              (LAMBDA (A)
                (AND (EQUAL "listen" (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
                     (EQUAL "report" (TM:TOPICMAP-ASSOCIATION-TO-OF A))))
              RELATIONS))
            (EVENT
             (FIND-IF
              (LAMBDA (A)
                (AND
                 (EQUAL "window-event-emitter"
                        (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
                 (EQUAL "listen" (TM:TOPICMAP-ASSOCIATION-TO-OF A))))
              RELATIONS)))
        (ASSERT
         (EQ :SUBORDINATE-EXECUTION
             (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF SUBORDINATE)
                   :RELATION-KIND)))
        (ASSERT
         (EQ :EVENT-PROPAGATION
             (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF EVENT)
                   :RELATION-KIND)))
        (ASSERT (NOT (EQ SUBORDINATE EVENT)))))))

(DEFUN CHECK-WARD-FOLLOW-UP-CONTRACT ()
  (LET* ((EVIDENCE (R:WARD-PROPAGATION-EVIDENCE))
         (QUOTES (GETF EVIDENCE :QUOTATIONS))
         (PROJECTION (R:READING-PROJECTION))
         (RELATIONS (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION)))
    (ASSERT
     (EQUAL
      '("The LISTEN in this example is operational as soon as it is rendered.
The subsequent CLICK MESSAGE will be heard to the left, counter to our habit
of communicating to the right or, in the case of Mech, to subordinate blocks."
        "The broadcast nature of events forward and backwards across the lineup was
a feature I pitched to my original sponsor."
        "Scope could be applied to the LISTEN block by offering an alternative event
emitter to be used in place of window.")
      (MAPCAR (LAMBDA (Q) (GETF Q :TEXT)) QUOTES)))
    (ASSERT
     (EQUAL '(:AUTHOR-REPORTED :AUTHOR-REPORTED :DESIGN-PROPOSAL)
            (MAPCAR (LAMBDA (Q) (GETF Q :STATUS)) QUOTES)))
    (DOLIST
        (ID
         '("solo-popup-click" "publish-source-data-message" "node-topic"
           "title-payload" "window-event-emitter" "broadcast-event-reach"
           "subordinate-execution" "scoped-event-emitter-proposal"))
      (ASSERT (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION ID)))
    (DOLIST
        (REQUIRED
         '(("solo-popup-click" "publish-source-data-message" :EVENT-PROPAGATION
            :SOURCE-OBSERVED "constructs")
           ("publish-source-data-message" "node-topic" :EVENT-PROPAGATION
            :SOURCE-OBSERVED "carries")
           ("publish-source-data-message" "title-payload" :EVENT-PROPAGATION
            :SOURCE-OBSERVED "carries")
           ("solo-popup-click" "window-event-emitter" :EVENT-PROPAGATION
            :SOURCE-OBSERVED "posts-via")
           ("window-event-emitter" "listen" :EVENT-PROPAGATION :AUTHOR-REPORTED
            "provides broadcast reach")
           ("solo" "listen" :SUBORDINATE-EXECUTION :OBSERVED "subordinates")
           ("listen" "scoped-event-emitter-proposal" :EVENT-PROPAGATION
            :DESIGN-PROPOSAL "could-use")))
      (ASSERT
       (FIND-IF
        (LAMBDA (A)
          (LET ((PROPS (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A)))
            (AND (EQUAL (FIRST REQUIRED) (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
                 (EQUAL (SECOND REQUIRED) (TM:TOPICMAP-ASSOCIATION-TO-OF A))
                 (EQ (THIRD REQUIRED) (GETF PROPS :RELATION-KIND))
                 (EQ (FOURTH REQUIRED) (GETF PROPS :EVIDENCE-STATUS))
                 (EQ (FOURTH REQUIRED) (GETF (GETF PROPS :WARRANT) :STATUS))
                 (SEARCH (FIFTH REQUIRED)
                         (TM:TOPICMAP-ASSOCIATION-TYPE-OF A)))))
        RELATIONS)))
    (DOLIST (ID '("enclosing-context" "inherited-context" "event-context"))
      (LET* ((TOPIC (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION ID))
             (HISTORY (TM:TOPICMAP-TOPIC-OBJECT-OF TOPIC)))
        (ASSERT (EQUAL ID (GETF HISTORY :ID)))
        (ASSERT (EQ :HISTORICAL-HYPOTHESIS (GETF HISTORY :STATUS)))
        (ASSERT (GETF HISTORY :ORIGINAL-QUOTATION))
        (ASSERT (GETF HISTORY :NEW-EVIDENCE))
        (ASSERT
         (EQ :HISTORICAL-HYPOTHESIS
             (GETF (TM:TOPICMAP-TOPIC-VIEW-PROPERTIES-OF TOPIC)
                   :EVIDENCE-STATUS)))))
    (ASSERT
     (NOTANY
      (LAMBDA (A)
        (AND (EQUAL "solo" (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
             (EQUAL "listen" (TM:TOPICMAP-ASSOCIATION-TO-OF A))
             (EQ :EVENT-PROPAGATION
                 (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A)
                       :RELATION-KIND))))
      RELATIONS))
    (DOLIST
        (PAIR
         '(("popup-handler" "solo-popup-click")
           ("message" "publish-source-data-message")
           ("window-emitter" "window-event-emitter")
           ("broadcast" "broadcast-event-reach")
           ("scoped-emitter" "scoped-event-emitter-proposal")))
      (ASSERT
       (EQUAL (SECOND PAIR)
              (TM:TOPICMAP-WORKSPACE-POINT-OF
               (R:TOPIC-WORKSPACE (FIRST PAIR)))))))
  (LET* ((READING (RENDER (PAGE "Two Relations Hidden in One Nest") "Content"))
         (PRODUCER
          (FIND-IF (LAMBDA (O) (TYPEP O 'R:MESSAGE-SOURCE))
                   (MAPCAR #'CDR (V:VIEW-REFERENCES READING))))
         (SOURCE (RENDER PRODUCER "Source evidence"))
         (WITNESS
          (FIND-IF (LAMBDA (O) (TYPEP O 'R:MESSAGE-WITNESS))
                   (MAPCAR #'CDR (V:VIEW-REFERENCES SOURCE))))
         (PATH (RENDER WITNESS "Message path"))
         (WORKSPACE
          (FIND-IF (LAMBDA (O) (TYPEP O 'TM:TOPICMAP-WORKSPACE))
                   (MAPCAR #'CDR (V:VIEW-REFERENCES PATH)))))
    (ASSERT PRODUCER)
    (ASSERT WITNESS)
    (ASSERT WORKSPACE)
    (ASSERT
     (EQ :SOURCE-OBSERVED
         (GETF
          (TM:TOPICMAP-TOPIC-VIEW-PROPERTIES-OF
           (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID
            (TM:TOPICMAP-PROJECTION-OF WORKSPACE) "solo-popup-click"))
          :EVIDENCE-STATUS)))
    (ASSERT (EQUAL "witness" (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
    (ASSERT
     (TYPEP (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT WORKSPACE)
            'R:MESSAGE-WITNESS))
    (ASSERT
     (EQUAL "unestablished-for-current-experiment"
            (GETHASH "status" (R:WITNESS-STAGE WITNESS "nestedInput")))))
  (FORMAT T
          "~&WARD-FOLLOW-UP-CONTRACT-PASS: exact quotations, canonical Topics, directed/warranted mechanism relations, retained historical hypotheses, no SOLO event scoping, and native reading/source/witness/Topicmap route.~%"))

(DEFUN CHECK-INPUT-TRACE ()
  (LET* ((TRACE (R:RECEIVED-INPUT-TRACE))
         (CAPTURE (R:INPUT-CAPTURE TRACE))
         (EVENTS (GETHASH "events" CAPTURE))
         (INVOCATION (GETHASH "invocation" CAPTURE))
         (PROJECTION (R:READING-PROJECTION))
         (RELATIONS (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION)))
    (ASSERT
     (EQUAL "0ed82813cb272f09a85ccf1c9dce89794e739544b55f6f590f124e9de8d55a7a"
            (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
             (IRONCLAD:DIGEST-FILE :SHA256
                                   (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
                                    "dreyeck/nested-actions/reading"
                                    "dreyeck/nested-actions/input-witness.json")))))
    (ASSERT
     (EQUAL (GETHASH "fixtureSha256" CAPTURE)
            (IRONCLAD:BYTE-ARRAY-TO-HEX-STRING
             (IRONCLAD:DIGEST-FILE :SHA256
                                   (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
                                    "dreyeck/nested-actions/reading"
                                    "dreyeck/nested-actions/input-witness.html")))))
    (LET ((FIXTURE
           (UIOP/STREAM:READ-FILE-STRING
            (ASDF/SYSTEM:SYSTEM-RELATIVE-PATHNAME
             "dreyeck/nested-actions/reading"
             "dreyeck/nested-actions/input-witness.html"))))
      (DOLIST (ROLE '("producer" "listen" "report" "run"))
        (LET ((SOURCE
               (FIND ROLE (R:INPUT-SOURCES TRACE) :KEY
                     (LAMBDA (S) (GETHASH "role" (R:SOURCE-METADATA S))) :TEST
                     #'EQUAL)))
          (ASSERT SOURCE)
          (ASSERT (SEARCH (R:SOURCE-TEXT SOURCE) FIXTURE)))))
    (ASSERT (= 24 (LENGTH (GETHASH "records" (R:INPUT-INVENTORY TRACE)))))
    (ASSERT (NOT (GETHASH "networkFetch" (R:INPUT-INVENTORY TRACE))))
    (ASSERT
     (EQUAL "derived"
            (GETHASH "classificationStatus" (R:INPUT-INVENTORY TRACE))))
    (ASSERT
     (EQUAL "native-message-to-retained-listen-with-independent-report"
            (GETHASH "mode" CAPTURE)))
    (ASSERT (GETHASH "stateIsPriorObject" INVOCATION))
    (ASSERT (GETHASH "bodyPassedByRun" INVOCATION))
    (ASSERT (NOT (GETHASH "bodyAcceptedByRetainedListen" INVOCATION)))
    (ASSERT
     (EQUAL "REPORT title"
            (GETHASH "command" (AREF (GETHASH "body" INVOCATION) 0))))
    (ASSERT (= 2 (LENGTH EVENTS)))
    (LOOP FOR EVENT ACROSS EVENTS
          FOR
          COUNT FROM 1
          FOR TITLE IN '("Payload Title" "Fallback Node")
          DO (LET* ((RECEPTION (GETHASH "reception" EVENT))
                    (SELECTION (GETHASH "listenSelection" EVENT))
                    (STATE (GETHASH "priorState" EVENT))
                    (EFFECT (GETHASH "listenerEffect" EVENT))
                    (PROBE (GETHASH "independentReportProbe" EVENT)))
               (ASSERT (GETHASH "actualObjectChecksPassed" EVENT))
               (ASSERT
                (EQUAL "[object MessageEvent]"
                       (GETHASH "eventType" RECEPTION)))
               (ASSERT (GETHASH "isTrusted" RECEPTION))
               (ASSERT (GETHASH "sourceIsPopup" RECEPTION))
               (ASSERT (GETHASH "dataIsDistinctFromSender" RECEPTION))
               (ASSERT (GETHASH "eventIsReceiverEvent" SELECTION))
               (ASSERT (GETHASH "dataIsEventData" SELECTION))
               (ASSERT
                (EQUAL "[object Object]" (GETHASH "dataType" SELECTION)))
               (ASSERT (= COUNT (GETHASH "count" SELECTION)))
               (ASSERT
                (EQUAL TITLE
                       (GETHASH "title" (GETHASH "receivedPayload" EVENT))))
               (ASSERT
                (EQUALP (GETHASH "receivedPayload" EVENT)
                        (GETHASH "selectedPayload" SELECTION)))
               (ASSERT
                (EQUAL "publishSourceData"
                       (GETHASH "action" (GETHASH "receivedPayload" EVENT))))
               (ASSERT
                (EQUAL "node"
                       (GETHASH "topic" (GETHASH "receivedPayload" EVENT))))
               (ASSERT (NOT (GETHASH "stateIsSelectedData" STATE)))
               (ASSERT (GETHASH "contextIdentityPreserved" STATE))
               (ASSERT (EQUAL "Prior Title" (GETHASH "titleBefore" STATE)))
               (ASSERT (EQUAL "Prior Title" (GETHASH "titleAfter" STATE)))
               (ASSERT (= 0 (GETHASH "automaticReportDispatches" EFFECT)))
               (ASSERT
                (= (1- COUNT)
                   (GETHASH "reportCallsBeforeIndependentProbe" EFFECT)))
               (ASSERT (GETHASH "inspectedTargetIsPriorState" PROBE))
               (ASSERT (NOT (GETHASH "inspectedTargetIsEventData" PROBE)))
               (ASSERT
                (EQUAL "explicit fixture call, not nested LISTEN"
                       (GETHASH "caller" PROBE)))
               (ASSERT (EQUAL "title" (GETHASH "key" PROBE)))
               (ASSERT (EQUAL "Prior Title" (GETHASH "value" PROBE)))
               (ASSERT
                (EQUAL "<div class=report>Prior Title</div>"
                       (GETHASH "output" PROBE)))
               (DOLIST (KEY '("nestedInput" "reportLookupTarget"))
                 (ASSERT
                  (EQUAL "unavailable-current-implementation"
                         (GETHASH "status" (GETHASH KEY EVENT))))
                 (ASSERT (NULL (GETHASH "value" (GETHASH KEY EVENT)))))))
    (ASSERT (= 8 (LENGTH (R:INPUT-STAGES TRACE))))
    (DOLIST (ID '("nested-action-input" "report-lookup-target" "title-value"))
      (LET ((STAGE (R:INPUT-STAGE TRACE ID)))
        (ASSERT (EQ :OPEN (GETF STAGE :STATUS)))
        (ASSERT (EQ :UNKNOWN (GETF STAGE :TYPE)))
        (ASSERT (NULL (GETF STAGE :OBJECT)))
        (ASSERT (GETF STAGE :SOURCE))))
    (DOLIST (H (R:INPUT-HYPOTHESES))
      (ASSERT (MEMBER (GETF H :ID) '(:A :B :C :D :E)))
      (ASSERT (EQ :HYPOTHESIZED (GETF H :STATUS)))
      (ASSERT (EQ :UNRESOLVED (GETF H :CURRENT-VERDICT))))
    (ASSERT (= 5 (LENGTH (R:INPUT-HYPOTHESES))))
    (DOLIST
        (REQUIRED
         '(("window-event-emitter" "received-message" :EVENT-PROPAGATION
            :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
           ("received-message" "message-data" :PAYLOAD-TO-INPUT
            :SOURCE-OBSERVED :MECH-A028-LISTEN)
           ("received-message" "message-data" :PAYLOAD-TO-INPUT
            :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
           ("message-data" "listen-match" :PAYLOAD-TO-INPUT :SOURCE-OBSERVED
            :MECH-A028-LISTEN)
           ("message-data" "listen-match" :PAYLOAD-TO-INPUT :RUNTIME-OBSERVED
            :NATIVE-INPUT-OBJECT-FLOW)
           ("listen-match" "listen" :PAYLOAD-TO-INPUT :RUNTIME-OBSERVED
            :NATIVE-INPUT-OBJECT-FLOW)
           ("listen-match" "nested-action-input" :PAYLOAD-TO-INPUT :OPEN
            :CURRENT-SOURCE-GAP)
           ("nested-action-input" "report-lookup-target" :PAYLOAD-TO-INPUT
            :OPEN :CURRENT-SOURCE-GAP)
           ("report-lookup-target" "report" :PAYLOAD-TO-INPUT :OPEN
            :CURRENT-SOURCE-GAP)
           ("report" "title-value" :PAYLOAD-TO-INPUT :OPEN :CURRENT-SOURCE-GAP)
           ("retained-report-state" "report" :PAYLOAD-TO-INPUT :SOURCE-OBSERVED
            :MECH-A028-REPORT)
           ("retained-report-state" "retained-title-value" :PAYLOAD-TO-INPUT
            :RUNTIME-OBSERVED :NATIVE-INPUT-OBJECT-FLOW)
           ("report" "title" :PAYLOAD-TO-INPUT :SOURCE-OBSERVED
            :MECH-A028-REPORT)
           ("title" "input-path" :PAYLOAD-TO-INPUT :DERIVED
            :READING-NAVIGATION)
           ("input-path" "received-message" :PAYLOAD-TO-INPUT :DERIVED
            :REVISION-BOUNDED-TRACE)))
      (ASSERT
       (FIND-IF
        (LAMBDA (A)
          (LET* ((P (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A))
                 (W (GETF P :WARRANT)))
            (AND (EQUAL (FIRST REQUIRED) (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
                 (EQUAL (SECOND REQUIRED) (TM:TOPICMAP-ASSOCIATION-TO-OF A))
                 (EQ (THIRD REQUIRED) (GETF P :RELATION-KIND))
                 (EQ (FOURTH REQUIRED) (GETF P :EVIDENCE-STATUS))
                 (EQ (FOURTH REQUIRED) (GETF W :STATUS))
                 (EQ (FIFTH REQUIRED)
                     (OR (GETF W :SOURCE-KEY) (GETF W :SOURCE))))))
        RELATIONS)))
    (DOLIST (A RELATIONS)
      (WHEN
          (MEMBER (TM:TOPICMAP-ASSOCIATION-TO-OF A)
                  '("nested-action-input" "report-lookup-target" "title-value")
                  :TEST #'EQUAL)
        (ASSERT
         (EQ :OPEN
             (GETF (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A)
                   :EVIDENCE-STATUS)))))
    (DOLIST
        (PAIR
         '(("nested-input" "nested-action-input")
           ("report-target" "report-lookup-target")))
      (ASSERT
       (EQUAL (SECOND PAIR)
              (TM:TOPICMAP-WORKSPACE-POINT-OF
               (R:TOPIC-WORKSPACE (FIRST PAIR)))))))
  (LET* ((TREE (R:OBSERVED-ACTION-TREE))
         (REPORT (FIRST (R:ACTION-CHILDREN (FIRST (R:ACTION-CHILDREN TREE)))))
         (VIEW (RENDER REPORT "Action tree"))
         (TRACE
          (FIND-IF (LAMBDA (O) (TYPEP O 'R:MESSAGE-INPUT-TRACE))
                   (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW))))
         (PATH (RENDER TRACE "Input path"))
         (OBJECTS (MAPCAR #'CDR (V:VIEW-REFERENCES PATH)))
         (WORKSPACE
          (FIND-IF (LAMBDA (O) (TYPEP O 'TM:TOPICMAP-WORKSPACE)) OBJECTS)))
    (ASSERT TRACE)
    (ASSERT WORKSPACE)
    (ASSERT (MEMBER (R:INPUT-STAGE TRACE "message-data") OBJECTS :TEST #'EQ))
    (ASSERT
     (MEMBER (R:INPUT-STAGE TRACE "report-lookup-target") OBJECTS :TEST #'EQ))
    (ASSERT (MEMBER (R:INPUT-CAPTURE TRACE) OBJECTS :TEST #'EQ))
    (ASSERT (EQUAL "input-path" (TM:TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
    (ASSERT
     (TYPEP (TM:TOPICMAP-WORKSPACE-CURRENT-OBJECT (R:TOPIC-WORKSPACE "title"))
            'R:MESSAGE-INPUT-TRACE)))
  (LET ((OBJECTS
         (MAPCAR #'CDR
                 (V:VIEW-REFERENCES
                  (RENDER (PAGE "From Message to Nested Input") "Content")))))
    (ASSERT (FIND-IF (LAMBDA (O) (TYPEP O 'R:MESSAGE-INPUT-TRACE)) OBJECTS)))
  (LET* ((SOURCE
          (RENDER (PAGE "Tracing the Received Message Boundary") "Source"))
         (VALUES
          (LOOP FOR REF IN (V:VIEW-REFERENCES SOURCE)
                WHEN (TYPEP (CDR REF) 'V:THUNK)
                COLLECT (V:EVAL-THUNK (CDR REF)))))
    (ASSERT (FIND-IF (LAMBDA (O) (TYPEP O 'R:MESSAGE-INPUT-TRACE)) VALUES)))
  (FORMAT T
          "~&MESSAGE-INPUT-TRACE-PASS: live identity capture, counter-only retained listener, independent REPORT lookup, three relation kinds, precise open boundary and native REPORT/title navigation.~%"))

(DEFUN CHECK-REVISION-PROVENANCE ()
  (LET* ((REVISION (R:MECH-EVIDENCE-REVISION))
         (ROOT (DREYECK/GIT:GIT-COMMIT-REPOSITORY-OF REVISION))
         (OID "a028b4bba04e539dcaa090423d38a00a0050489d")
         (VIEW (RENDER REVISION "Evidence revision"))
         (FILES
          (REMOVE-IF-NOT (LAMBDA (O) (TYPEP O 'DREYECK/GIT:GIT-EVIDENCE-FILE))
                         (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW)))))
    (ASSERT (TYPEP REVISION 'DREYECK/GIT:GIT-COMMIT))
    (ASSERT (EQUAL OID (DREYECK/GIT:GIT-COMMIT-HASH-OF REVISION)))
    (ASSERT
     (EQUAL "a028b4b" (DREYECK/GIT:GIT-REVISION-DISPLAY-ID-OF REVISION)))
    (ASSERT
     (EQUAL "https://github.com/WardCunningham/wiki-plugin-mech"
            (DREYECK/GIT:GIT-REVISION-AUTHORITY-OF REVISION)))
    (ASSERT
     (EQ :COMMIT-PRESENT (DREYECK/GIT:GIT-REVISION-LOCAL-STATUS REVISION)))
    (ASSERT (MEMBER ROOT (MAPCAR #'CDR (V:VIEW-REFERENCES VIEW)) :TEST #'EQ))
    (ASSERT (= 2 (LENGTH FILES)))
    (ASSERT
     (EQUAL (LIST "https://github.com/WardCunningham/wiki-plugin-mech" OID)
            (DREYECK/GIT:GIT-REVISION-IDENTITY REVISION)))
    (LET ((OTHER
           (DREYECK/GIT:MAKE-GIT-REVISION-REFERENCE :REPOSITORY ROOT :AUTHORITY
                                                    "https://example.test/another-repository"
                                                    :OID OID :DISPLAY-ID
                                                    "a028b4b" :ROLE :TEST)))
      (ASSERT
       (NOT
        (EQUAL (DREYECK/GIT:GIT-REVISION-IDENTITY REVISION)
               (DREYECK/GIT:GIT-REVISION-IDENTITY OTHER)))))
    (DOLIST (INVALID '("a028b4b" "deadbeef" "HEAD"))
      (ASSERT
       (HANDLER-CASE
        (PROGN
         (DREYECK/GIT:MAKE-GIT-REVISION-REFERENCE :REPOSITORY ROOT :AUTHORITY
                                                  "test" :OID INVALID)
         NIL)
        (ERROR NIL T))))
    (ASSERT
     (HANDLER-CASE
      (PROGN
       (DREYECK/GIT:MAKE-GIT-REVISION-REFERENCE :REPOSITORY ROOT :AUTHORITY ""
                                                :OID OID)
       NIL)
      (ERROR NIL T)))
    (ASSERT
     (HANDLER-CASE
      (PROGN
       (DREYECK/GIT:MAKE-GIT-REVISION-REFERENCE :REPOSITORY ROOT :AUTHORITY
                                                "test" :OID OID :DISPLAY-ID
                                                "1234567")
       NIL)
      (ERROR NIL T)))
    (LET* ((FILE
            (FIND "src/client/blocks.js" FILES :KEY
                  #'DREYECK/GIT:GIT-FILE-PATH-OF :TEST #'EQUAL))
           (LOCATIONS
            (MAPCAR #'CDR
                    (V:VIEW-REFERENCES (RENDER FILE "Evidence locations")))))
      (ASSERT FILE)
      (DOLIST (ROLE '("listen" "report"))
        (LET* ((SOURCE
                (FIND-IF
                 (LAMBDA (O)
                   (AND (TYPEP O 'R:MESSAGE-SOURCE)
                        (EQUAL ROLE (GETHASH "role" (R:SOURCE-METADATA O)))))
                 LOCATIONS))
               (SOURCE-VIEW (RENDER SOURCE "Source evidence"))
               (REFS (MAPCAR #'CDR (V:VIEW-REFERENCES SOURCE-VIEW))))
          (ASSERT SOURCE)
          (ASSERT (EQ REVISION (R:SOURCE-REVISION SOURCE)))
          (ASSERT (EQ FILE (R:SOURCE-REVISION-FILE SOURCE)))
          (ASSERT (EQ REVISION (DREYECK/GIT:GIT-FILE-COMMIT-OF FILE)))
          (ASSERT (MEMBER REVISION REFS :TEST #'EQ))
          (ASSERT (MEMBER FILE REFS :TEST #'EQ))
          (ASSERT (R:SOURCE-DEFINITION SOURCE))
          (ASSERT
           (SEARCH (R:SOURCE-TEXT SOURCE)
                   (DREYECK/GIT:GIT-FILE-CONTENTS FILE))))))
    (LET* ((READING (RENDER (PAGE "From Message to Nested Input") "Content"))
           (OBJECTS (MAPCAR #'CDR (V:VIEW-REFERENCES READING))))
      (ASSERT
       (FIND-IF (LAMBDA (O) (TYPEP O 'DREYECK/GIT:GIT-REVISION-REFERENCE))
                OBJECTS))
      (DOLIST (ROLE '("listen" "report"))
        (ASSERT
         (FIND-IF
          (LAMBDA (O)
            (AND (TYPEP O 'R:MESSAGE-SOURCE)
                 (EQUAL ROLE (GETHASH "role" (R:SOURCE-METADATA O)))))
          OBJECTS))))
    (ASSERT (NULL (R:SOURCE-REVISION (R:PRODUCER-SOURCE)))))
  (LET* ((HISTORY (R:HISTORICAL-INVESTIGATION))
         (SOURCES (R:HISTORICAL-SOURCES HISTORY))
         (CLAIMS (R:HISTORICAL-CLAIMS HISTORY))
         (ANCESTOR
          (FIND :HISTORICAL-ANCESTOR CLAIMS :KEY (LAMBDA (C) (GETF C :ID)))))
    (ASSERT (= 8 (LENGTH SOURCES)))
    (DOLIST (SOURCE SOURCES)
      (LET ((REVISION (R:SOURCE-REVISION SOURCE))
            (FILE (R:SOURCE-REVISION-FILE SOURCE)))
        (ASSERT (TYPEP REVISION 'DREYECK/GIT:GIT-REVISION-REFERENCE))
        (ASSERT (TYPEP FILE 'DREYECK/GIT:GIT-FILE-AT-COMMIT))
        (ASSERT (EQ REVISION (DREYECK/GIT:GIT-FILE-COMMIT-OF FILE)))
        (ASSERT
         (EQUAL (GETHASH "repository" (R:SOURCE-METADATA SOURCE))
                (DREYECK/GIT:GIT-REVISION-AUTHORITY-OF REVISION)))
        (ASSERT
         (EQUAL (GETHASH "revision" (R:SOURCE-METADATA SOURCE))
                (DREYECK/GIT:GIT-COMMIT-HASH-OF REVISION)))
        (ASSERT
         (EQ :COMMIT-PRESENT (DREYECK/GIT:GIT-REVISION-LOCAL-STATUS REVISION)))
        (ASSERT
         (SEARCH (R:SOURCE-TEXT SOURCE) (DREYECK/GIT:GIT-FILE-CONTENTS FILE)))
        (ASSERT
         (MEMBER SOURCE (DREYECK/GIT:GIT-EVIDENCE-FILE-LOCATIONS-OF FILE) :TEST
                 #'EQ))))
    (ASSERT
     (EQ :AUTHOR-REPORTED
         (GETF (FIND :WARD-CLUE CLAIMS :KEY (LAMBDA (C) (GETF C :ID)))
               :STATUS)))
    (DOLIST
        (ID
         '(:POPUP-APPEND :FETCH-BARRIER :POPUP-REPLACEMENT :SPEED-FETCH
           :SPEED-RESULTS))
      (LET ((CLAIM (FIND ID CLAIMS :KEY (LAMBDA (C) (GETF C :ID)))))
        (ASSERT (EQ :SOURCE-OBSERVED (GETF CLAIM :STATUS)))
        (ASSERT (TYPEP (GETF CLAIM :SOURCE) 'R:MESSAGE-SOURCE))))
    (ASSERT (EQ :HYPOTHESIZED (GETF ANCESTOR :STATUS)))
    (ASSERT (NULL (GETF ANCESTOR :ANSWER)))
    (ASSERT (NOT (GETF ANCESTOR :RUNTIME-CLAIM)))
    (ASSERT (EQ :OPEN (GETF ANCESTOR :CURRENT-LISTEN-HANDOFF)))
    (ASSERT
     (EQ :NOT-ESTABLISHED
         (GETF (FIND :POPUP-APPEND CLAIMS :KEY (LAMBDA (C) (GETF C :ID)))
               :AUTOMATIC-FETCH-TRIGGER)))
    (ASSERT
     (SEARCH "beam.push(...data.graphs)"
             (R:SOURCE-TEXT
              (R:HISTORICAL-SOURCE HISTORY "solo-append-receiver"))))
    (ASSERT
     (SEARCH "beam.splice(0)"
             (R:SOURCE-TEXT
              (R:HISTORICAL-SOURCE HISTORY "solo-replace-receiver"))))
    (ASSERT
     (SEARCH "Promise.all(parsed.graphs)"
             (R:SOURCE-TEXT
              (R:HISTORICAL-SOURCE HISTORY "solo-fetch-barrier"))))
    (ASSERT
     (SEARCH "await getfrom"
             (R:SOURCE-TEXT (R:HISTORICAL-SOURCE HISTORY "speed-run"))))
    (ASSERT
     (NOT
      (SEARCH "solo"
              (R:SOURCE-TEXT (R:HISTORICAL-SOURCE HISTORY "speed-run")))))
    (LET* ((READING
            (RENDER (PAGE "Adding to an Already Rendered Solo Popup")
                    "Content"))
           (LINKED
            (FIND-IF (LAMBDA (O) (TYPEP O 'R:SOLO-HISTORY))
                     (MAPCAR #'CDR (V:VIEW-REFERENCES READING))))
           (PATH (RENDER LINKED "Historical paths"))
           (REFS (MAPCAR #'CDR (V:VIEW-REFERENCES PATH))))
      (ASSERT LINKED)
      (ASSERT
       (FIND-IF (LAMBDA (O) (TYPEP O 'DREYECK/GIT:GIT-REVISION-REFERENCE))
                REFS))
      (ASSERT (FIND-IF (LAMBDA (O) (TYPEP O 'R:MESSAGE-SOURCE)) REFS))
      (ASSERT (FIND-IF (LAMBDA (O) (TYPEP O 'TM:TOPICMAP-WORKSPACE)) REFS))))
  (LET* ((PROJECTION (R:READING-PROJECTION))
         (RELATIONS (TM:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION)))
    (DOLIST (A RELATIONS)
      (LET* ((P (TM:TOPICMAP-ASSOCIATION-PROPERTIES-OF A))
             (W (GETF P :WARRANT))
             (KEY (GETF W :SOURCE-KEY))
             (SOURCE (GETF W :SOURCE)))
        (WHEN
            (MEMBER KEY
                    '(:MECH-A028-LISTEN :MECH-A028-REPORT
                      :WARD-SUPPLIED-PRODUCER :SOLO-APPEND-SENDER
                      :SOLO-REPLACE-RECEIVER :SPEED-RUN))
          (ASSERT (TYPEP SOURCE 'R:MESSAGE-SOURCE))
          (UNLESS (EQ KEY :WARD-SUPPLIED-PRODUCER)
            (ASSERT
             (TYPEP (R:SOURCE-REVISION SOURCE)
                    'DREYECK/GIT:GIT-REVISION-REFERENCE))
            (ASSERT
             (EQ (R:SOURCE-REVISION SOURCE)
                 (GETF (GETF P :REVISION-BOUNDARY) :REVISION)))))
        (WHEN
            (AND
             (EQUAL "historical-ancestor" (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
             (EQUAL "input-path" (TM:TOPICMAP-ASSOCIATION-TO-OF A)))
          (ASSERT (EQ :HYPOTHESIZED (GETF P :EVIDENCE-STATUS))))
        (WHEN
            (AND
             (EQUAL "speed-result-loop" (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
             (EQUAL "solo-popup-beam" (TM:TOPICMAP-ASSOCIATION-TO-OF A)))
          (ASSERT (EQ :OPEN (GETF P :EVIDENCE-STATUS)))))))
  (FORMAT T
          "~&REVISION-PROVENANCE-HISTORY-PASS: repository/full-OID identity, native claim/revision/file/definition routes, exact local blobs, append versus replacement, fetch barrier and open historical/current bridges.~%"))

(DEFUN RUN-TESTS ()
  (CHECK-PAGES)
  (CHECK-TREE)
  (CHECK-STATUS)
  (CHECK-WORKSPACE)
  (CHECK-MESSAGE-PATH)
  (CHECK-WARD-FOLLOW-UP-CONTRACT)
  (CHECK-INPUT-TRACE)
  (CHECK-REVISION-PROVENANCE)
  (DOLIST
      (NAME
       '(R:EXPERIMENT-EVIDENCE R:OBSERVED-ACTION-TREE R:SEMANTIC-QUESTIONS
                               R:PROPOSED-PROBES R:READING-PROJECTION
                               R:READING-WORKSPACE R:LAYOUT-COMPARISON
                               R:MESSAGE-SOURCE-OBSERVATIONS R:PRODUCER-SOURCE
                               R:EMITTED-MESSAGE-WITNESS
                               R:WARD-PROPAGATION-EVIDENCE
                               R:HISTORICAL-CONTEXT-HYPOTHESES
                               R:RECEIVED-INPUT-TRACE R:INPUT-HYPOTHESES
                               R:MECH-EVIDENCE-REVISION
                               R:HISTORICAL-SOURCE-OBSERVATIONS
                               R:HISTORICAL-INVESTIGATION))
    (ASSERT (DREYECK/AUTHORITY-POLICY:FIND-EXAMPLE-CONTRACT NAME)))
  (FORMAT T
          "~&NESTED-ACTIONS-READING-PASS: 5 text/7 code pages; 39 Topics/52 warranted relations; explicit Git provenance; historical append/replacement and separate async fetch; current handoff unchanged, proposal-only scoped emitter; native navigation.~%")
  T)

(DEFUN RUN-TALA-TESTS ()
  (RUN-TESTS)
  (LET* ((COMPARISON (R:LAYOUT-COMPARISON))
         (PROJECTION (LT:COMPARISON-PROJECTION COMPARISON))
         (BEFORE (DREYECK/TOPICMAP/TALA:PROJECTION-STATE PROJECTION)))
    (ASSERT (TYPEP COMPARISON 'LT:TALA-COMPARISON))
    (ASSERT (EQ :PASSED (GETF (LT:COMPARISON-INVARIANTS COMPARISON) :STATUS)))
    (DREYECK/TOPICMAP/TESTS::CHECK-TALA-COMPARISON-NAVIGATION COMPARISON)
    (ASSERT
     (EQUAL BEFORE (DREYECK/TOPICMAP/TALA:PROJECTION-STATE PROJECTION))))
  (FORMAT T
          "~&NESTED-ACTIONS-TALA-PASS: pinned rendering preserves Topic IDs, endpoints, warrants, native actions, objects and Point/history.~%")
  T)
