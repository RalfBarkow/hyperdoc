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
           "Two Relations Hidden in One Nest"))
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
               "Proposed Nested Action Probes" "Following One Node Message"))
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
           "Following One Node Message"))
      (LET ((P (PAGE TITLE)))
        (HYPERDOC:LOAD-PAGE P)
        (LET ((LINKS (HYPERBOOK:PAGE-LINKS-OF (HYPERBOOK:LINKS-OF P))))
          (DOLIST
              (TARGET
               '("Nested Actions in Solo" "What Does a Nested Action Inherit?"
                 "Two Relations Hidden in One Nest"))
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
    (ASSERT (= 25 (LENGTH TOPICS)))
    (DOLIST
        (ID
         '("experiment" "tree" "syntax" "solo" "nested-statement" "listen"
           "event" "report" "title" "enclosing-context" "inherited-context"
           "event-context" "lifetime" "probes" "popup-handler" "message"
           "node-topic" "title-payload" "window-emitter" "broadcast"
           "subordinate-execution" "scoped-emitter" "nested-input"
           "report-target" "witness"))
      (ASSERT (TM:TOPICMAP-PROJECTION-TOPIC-BY-ID PROJECTION ID)))
    (ASSERT (= 29 (LENGTH RELATIONS)))
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
                   :DESIGN-PROPOSAL :OPEN)))
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
      (ASSERT (= 25 (LENGTH ACTIONS)))
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
      (ASSERT (= 2 (LENGTH KINDS)))
      (ASSERT (MEMBER :SUBORDINATE-EXECUTION KINDS))
      (ASSERT (MEMBER :EVENT-PROPAGATION KINDS))
      (DOLIST (A RELATIONS)
        (WHEN
            (MEMBER "scoped-emitter"
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
                 (EQUAL "window-emitter" (TM:TOPICMAP-ASSOCIATION-FROM-OF A))
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

(DEFUN RUN-TESTS ()
  (CHECK-PAGES)
  (CHECK-TREE)
  (CHECK-STATUS)
  (CHECK-WORKSPACE)
  (CHECK-MESSAGE-PATH)
  (DOLIST
      (NAME
       '(R:EXPERIMENT-EVIDENCE R:OBSERVED-ACTION-TREE R:SEMANTIC-QUESTIONS
                               R:PROPOSED-PROBES R:READING-PROJECTION
                               R:READING-WORKSPACE R:LAYOUT-COMPARISON
                               R:MESSAGE-SOURCE-OBSERVATIONS R:PRODUCER-SOURCE
                               R:EMITTED-MESSAGE-WITNESS
                               R:WARD-PROPAGATION-EVIDENCE))
    (ASSERT (DREYECK/AUTHORITY-POLICY:FIND-EXAMPLE-CONTRACT NAME)))
  (FORMAT T
          "~&NESTED-ACTIONS-READING-PASS: 3 text/4 code pages; source -> recorded native witness -> Topicmap; 25 Topics/29 relations with independent subordinate/event kinds; scoped emitter remains proposal; current input/lookup gap explicit; native Point/history.~%")
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
