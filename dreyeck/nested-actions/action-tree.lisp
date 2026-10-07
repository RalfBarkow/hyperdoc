;;;; Inspecting the Observed Nested Action Tree

(DEFPACKAGE #:DREYECK/NESTED-ACTIONS
  (:USE #:CL)
  (:LOCAL-NICKNAMES (#:TM #:DREYECK/TOPICMAP)
                    (#:V #:HTML-INSPECTOR-VIEWS)
                    (#:LAYOUT #:DREYECK/INSPECTOR/TOPICMAP/TALA))
  (:EXPORT #:NESTED-ACTION
           #:ACTION-NAME
           #:ACTION-ARGUMENTS
           #:ACTION-CHILDREN
           #:OBSERVED-ACTION-TREE
           #:EXPERIMENT-EVIDENCE
           #:SEMANTIC-QUESTIONS
           #:PROPOSED-PROBES
           #:READING-PROJECTION
           #:READING-WORKSPACE
           #:TOPIC-WORKSPACE
           #:LAYOUT-COMPARISON))

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(DEFCLASS NESTED-ACTION NIL
          ((NAME :INITARG :NAME :READER ACTION-NAME)
           (ARGUMENTS :INITARG :ARGUMENTS :INITFORM NIL :READER
            ACTION-ARGUMENTS)
           (CHILDREN :INITARG :CHILDREN :INITFORM NIL :READER ACTION-CHILDREN))
          (:DOCUMENTATION
           "HyperDoc syntax representation of the supplied experiment.
There is no evaluator, environment, subscription or FedWiki runtime here."))

(HYPERDOC:DEFEXAMPLE OBSERVED-ACTION-TREE
  "Construct fresh inspectable syntax: SOLO contains LISTEN node contains REPORT title.
The representation is HyperDoc code, not Ward's implementation."
  (MAKE-INSTANCE 'NESTED-ACTION :NAME "SOLO" :CHILDREN
                 (LIST
                  (MAKE-INSTANCE 'NESTED-ACTION :NAME "LISTEN" :ARGUMENTS
                                 '("node") :CHILDREN
                                 (LIST
                                  (MAKE-INSTANCE 'NESTED-ACTION :NAME "REPORT"
                                                 :ARGUMENTS '("title")))))))

(HYPERDOC:DEFEXAMPLE EXPERIMENT-EVIDENCE
  "Inspect the supplied testimony and screenshot transcription, not a runtime capture."
  (LIST :ORIGIN :USER-SUPPLIED-TASK :WARD-STATEMENT
        "With Paul's help we now have a few more lines of just right code. With this the SOLO block will run any nested statements. Here we use existing blocks to LISTEN for clicked nodes and then REPORT their titles."
        :COMPOSITION
        '((:CLICK) (:NEIGHBORS :PAGES 1845 :SITES 4)
          (:WALK :ARGUMENT 10 :ASPECTS 4 :NODES 8)
          (:CLICK
           (:SOLO :SOURCES 1 :ASPECTS 4
            (:LISTEN :ARGUMENT "node" :EVENTS 7 :ELAPSED-MS 7984
             (:REPORT :ARGUMENT "title")))))
        :OBSERVATION-LIMIT
        "The original screenshot and matching implementation were not supplied; these are the task's transcription and Ward's reported behavior, not an independently repeated run."
        :RALF-INTERPRETATION
        "A block is beginning to behave less like a command in a pipeline and more like a form that establishes an execution context for nested forms.

This looks like more than nested syntax. SOLO now seems able to establish an execution context in which another statement can wait for future events and continue evaluation. LISTEN node → REPORT title makes the interesting question concrete: what exactly does a nested statement inherit from its enclosing statement, and what does LISTEN rebind when an event arrives? That seems like the place where the semantics of nested actions will become visible."
        :INTERPRETATION-STATUS :HYPOTHESIZED :IMPLEMENTATION-STATUS
        :NOT-LOCALLY-ESTABLISHED :HYPERDOC-WITNESS :SYNTAX-CONSTRUCTION-ONLY))

(V:DEFVIEW ACTION-TREE-VIEW (ACTION NESTED-ACTION)
           (V:HTML-VIEW :TITLE "Action tree" :PRIORITY 1
                        (V:HTML
                          (:P
                           "Syntax representation only. Construction executes in HyperDoc; FedWiki actions do not.")
                          (:P (CL-WHO:ESC (ACTION-NAME ACTION)) " "
                           (CL-WHO:ESC
                            (FORMAT NIL "~{~A~^ ~}" (ACTION-ARGUMENTS ACTION))))
                          (:UL
                           (DOLIST (CHILD (ACTION-CHILDREN ACTION))
                             (V:HTML
                               (:LI
                                (V:OBJECT-REF CHILD :DISPLAY
                                              (ACTION-NAME CHILD) :SELECT
                                              "Action tree")))))
                          (:P
                           (V:OBJECT-REF
                            (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                                           "dreyeck/nested-actions/reading")
                            :DISPLAY "Read the experiment" :SELECT "Content"))
                          (:P
                           (V:OBJECT-REF
                            (HYPERDOC:PAGE
                             "Inspecting the Observed Nested Action Tree"
                             :HYPERBOOK "dreyeck/nested-actions/reading")
                            :DISPLAY "Inspect the constructing code" :SELECT
                            "Source")))))
