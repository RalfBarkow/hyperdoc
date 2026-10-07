;;;; Navigating the Nested Actions Investigation

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(DEFUN READING-PAGE (TITLE)
  (HYPERBOOK:FIND-PAGE
   (HYPERBOOK:FIND-HYPERBOOK "dreyeck/nested-actions/reading" :SIGNAL-ERROR? T)
   TITLE :SIGNAL-ERROR? T))

(HYPERDOC:DEFEXAMPLE READING-PROJECTION
  "The learning path and its warrants exist before any layout is requested."
  (LET* ((TREE (OBSERVED-ACTION-TREE))
         (LISTEN (FIRST (ACTION-CHILDREN TREE)))
         (REPORT (FIRST (ACTION-CHILDREN LISTEN)))
         (QUESTIONS (SEMANTIC-QUESTIONS))
         (SPECS
          (LIST
           (LIST "experiment" "Ward's nested-action experiment"
                 (EXPERIMENT-EVIDENCE) :OBSERVED)
           (LIST "tree" "Observed action tree" TREE :OBSERVED)
           (LIST "syntax" "Nested syntax"
                 (READING-PAGE "Nested Actions in Solo") :DERIVED)
           (LIST "solo" "SOLO" TREE :OBSERVED)
           (LIST "nested-statement" "Nested statement" LISTEN :OBSERVED)
           (LIST "listen" "LISTEN" LISTEN :OBSERVED)
           (LIST "event" "Event" (EXPERIMENT-EVIDENCE) :OBSERVED)
           (LIST "report" "REPORT" REPORT :OBSERVED)
           (LIST "title" "title"
                 (FIND :TITLE QUESTIONS :KEY (LAMBDA (Q) (GETF Q :ID))) :OPEN)
           (LIST "enclosing-context" "Enclosing context (hypothesis)"
                 (READING-PAGE "What Does a Nested Action Inherit?")
                 :HYPOTHESIZED)
           (LIST "inherited-context" "Inherited context (question)" QUESTIONS
                 :OPEN)
           (LIST "event-context" "Event context (question)"
                 (FIND :EVENT-CONTEXT QUESTIONS :KEY (LAMBDA (Q) (GETF Q :ID)))
                 :OPEN)
           (LIST "lifetime" "Lifetime (question)"
                 (FIND :LIFETIME QUESTIONS :KEY (LAMBDA (Q) (GETF Q :ID)))
                 :OPEN)
           (LIST "probes" "Proposed discriminating probes" (PROPOSED-PROBES)
                 :PROPOSED)))
         (TOPICS
          (LOOP FOR (ID LABEL OBJECT STATUS) IN SPECS
                FOR I FROM 0
                COLLECT (TM:MAKE-TOPICMAP-TOPIC :ID ID :TYPE :READING-CONCEPT
                                                :LABEL LABEL :OBJECT OBJECT
                                                :VIEW-PROPERTIES
                                                (LIST :X
                                                      (+ 30 (* 230 (MOD I 4)))
                                                      :Y
                                                      (+ 30
                                                         (* 140 (FLOOR I 4)))
                                                      :VISIBLE T
                                                      :EVIDENCE-STATUS
                                                      STATUS))))
         (RELATIONS
          '(("experiment" "tree" "transcribed as" :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("tree" "syntax" "shows nesting" :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("syntax" "solo"
             "enclosing action runs nested statements (Ward reports)" :OBSERVED
             :WARD-STATEMENT)
            ("solo" "listen" "contains" :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("listen" "report" "contains" :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("solo" "nested-statement" "runs (Ward reports)" :OBSERVED
             :WARD-STATEMENT)
            ("listen" "event" "listens for clicked nodes (Ward reports)"
             :OBSERVED :WARD-STATEMENT)
            ("event" "report" "clicked titles reported (Ward reports)"
             :OBSERVED :WARD-STATEMENT)
            ("report" "title" "names argument" :OBSERVED
             :SUPPLIED-SCREENSHOT-TRANSCRIPTION)
            ("title" "inherited-context" "raises lookup question" :DERIVED
             :READING-QUESTION)
            ("solo" "enclosing-context" "may establish" :HYPOTHESIZED
             :RALF-INTERPRETATION)
            ("nested-statement" "inherited-context" "may inherit" :HYPOTHESIZED
             :RALF-INTERPRETATION)
            ("listen" "event-context" "may alter context" :HYPOTHESIZED
             :RALF-INTERPRETATION)
            ("event-context" "inherited-context" "requires comparison" :DERIVED
             :READING-QUESTION)
            ("listen" "lifetime" "raises duration question" :DERIVED
             :READING-QUESTION)
            ("inherited-context" "probes" "investigate with" :DERIVED
             :READING-QUESTION)
            ("lifetime" "probes" "investigate with" :DERIVED
             :READING-QUESTION))))
    (TM:MAKE-TOPICMAP-PROJECTION :SOURCE (EXPERIMENT-EVIDENCE) :TOPICS TOPICS
                                 :ASSOCIATIONS
                                 (LOOP FOR (FROM TO LABEL STATUS
                                            SOURCE) IN RELATIONS
                                       FOR I FROM 0
                                       COLLECT (TM:MAKE-TOPICMAP-ASSOCIATION
                                                :ID
                                                (FORMAT NIL
                                                        "nested-relation-~D" I)
                                                :TYPE LABEL :FROM FROM :TO TO
                                                :PROPERTIES
                                                (LIST :EVIDENCE-STATUS STATUS
                                                      :WARRANT
                                                      (LIST :STATUS STATUS
                                                            :SOURCE SOURCE))))
                                 :VIEW-PROPERTIES '(:WIDTH 1000 :HEIGHT 650))))

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
                           LAYOUT-COMPARISON))
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
