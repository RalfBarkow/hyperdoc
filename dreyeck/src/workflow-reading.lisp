;;;; Executable workflow reading
(DEFPACKAGE :DREYECK/WORKFLOW/READING
  (:USE :CL)
  (:LOCAL-NICKNAMES (:WF :DREYECK/WORKFLOW)
                    (:TM :DREYECK/TOPICMAP)
                    (:VIEWS :HTML-INSPECTOR-VIEWS)))

(IN-PACKAGE :DREYECK/WORKFLOW/READING)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Reconstructing Workflow"))

(HYPERDOC:DEFEXAMPLE READING-PLAN
  (LET* ((COMPONENT
          (ASDF/COMPONENT:FIND-COMPONENT
           (ASDF/SYSTEM:FIND-SYSTEM "dreyeck/workflow")
           "dreyeck/src/workflow-model"))
         (FORM
          (COPY-TREE
           (FIND '(:DEFINITION WF:PLAN-STATUS)
                 (WF:SOURCE-FORMS
                  (ASDF/COMPONENT:COMPONENT-PATHNAME COMPONENT))
                 :KEY #'WF:FORM-KEY :TEST #'EQUAL))))
    (ASSERT FORM)
    (SETF (CDDDR FORM)
            (CONS "Read-only example of a proposed documentation change."
                  (CDDDR FORM)))
    (WF:PLAN-DEFINITION "dreyeck/workflow" "dreyeck/src/workflow-model"
                        'WF:PLAN-STATUS FORM '(FBOUNDP 'WF:PLAN-STATUS))))

(HYPERDOC:DEFEXAMPLE READING-LIVE-OPERATION
  (WF:OBSERVE-OPERATION 'WF:PLAN-STATUS))

(HYPERDOC:DEFEXAMPLE READING-DEPENDENCY
  (WF:PLAN-DEPENDENCY "dreyeck/workflow" "uiop"
                      '(ASDF/SYSTEM:FIND-SYSTEM "uiop")))

(HYPERDOC:DEFEXAMPLE READING-AUTHORING-BOUNDARY
  (LIST :REQUEST (READING-PLAN) :EXECUTOR 'WF:PERSIST-IN :SYSTEM
        "dreyeck/workflow/authoring" :ENVIRONMENT
        "nix develop .#workflow-authoring" :WRITER-COMMIT
        "38afb02d79838d4098589c2e203ba39799a44853" :ACCEPTANCE
        '(:STRUCTURAL-READ-BACK :FRESH-ORDINARY-RUNTIME-EXPECTATION)
        :CATALOG-STARTUP :READ-ONLY))

(HYPERDOC:DEFEXAMPLE READING-MEDLEY
  (MAPCAR
   (LAMBDA (LOCUS)
     (LIST :STATUS :SOURCE-OBSERVED :REPOSITORY
           "https://github.com/Interlisp/medley" :COMMIT
           "3a14c9aa040d6cd897e3d6c3c3fa664a3e2d1442" :PATH "sources/FILEPKG"
           :BLOB "46d6906bdb1f92c49e19b128459ca223289717ed" :DEFINITION
           (FIRST LOCUS) :LINE (SECOND LOCUS) :OBSERVATION (THIRD LOCUS)
           :LICENSE "MIT; Interlisp.org and original Xerox/Venue/contributors"
           :URL
           (FORMAT NIL
                   "https://github.com/Interlisp/medley/blob/3a14c9aa040d6cd897e3d6c3c3fa664a3e2d1442/sources/FILEPKG#L~D"
                   (SECOND LOCUS))))
   '(("FILECREATED" 3
      "Source header records creation identity; not a workflow verification proof.")
     ("CLEANUP" 362
      "Delegates dumping to MAKEFILES and optional compilation/listing.")
     ("MAKEFILE" 435
      "Reads file properties and TOBEDUMPED changes after UPDATEFILES.")
     ("MARKASCHANGED" 1033
      "Records changed names by type and invokes WHENCHANGED hooks.")
     ("FILECOMS" 1060
      "Resolves a file's command-variable name; not an operation registry.")
     ("FILES?" 1569 "Reports files and changed components needing attention.")
     ("CHECKIMPORTS" 4708
      "Current Medley checks imported versions; the 1971 dependency remark is not a universal claim about modern Medley."))))

(HYPERDOC:DEFEXAMPLE READING-HISTORICAL
  (LIST :STATUS :SOURCE-OBSERVED :REPOSITORY "hyperdoc" :COMMIT
        "c4ebfd8d3d8bec5c9aead22ee8b4f5d046220d34" :PATH
        "dreyeck/src/workflow.lisp" :MECHANISMS
        '(:ENCODED-CARRIERS :FRAGMENT-REGISTRY :ASSEMBLY-SPECIFICATIONS
          :ORDERED-GUARDED-EXTENSIONS :MATERIALIZERS)
        :PERSIST-IN
        '(:CATALOG-ADMIT-APPEND :CATALOG-TESTS-APPEND
          :ASDF-DEPENDENCY-REPLACEMENT)
        :DECISION :REPLACE-WITH-OWNED-STRUCTURAL-PLAN :DECISION-STATUS
        :DESIGN-INFERENCE :WARRANT
        "No direct persisted consumer outside workflow tests/ASDF; overlapping ASDF guards encode editing history, not distinct authority semantics."))

(HYPERDOC:DEFEXAMPLE READING-BOOTSTRAP
                     (LIST :SEED
                           (QUOTE
                                  (:COMMON-LISP :ASDF :HYPERDOC :DEFEXAMPLE
                                                :SOURCE-TRANSCLUSION :INSPECTOR
                                                :TOPICMAP :WORKSPACE))
                           :SOURCE (ASDF/SYSTEM:FIND-SYSTEM "dreyeck/workflow")
                           :MATERIALIZATION (READING-PLAN) :OBSERVATION
                           :INSPECTOR-AND-WORKSPACE :LAYOUT
                           :REPLACEABLE-NATIVE-OR-TALA :SELF-DESCRIPTION
                           (ASDF/SYSTEM:FIND-SYSTEM "dreyeck/workflow/reading")
                           :AUTHORING (READING-AUTHORING-BOUNDARY)
                           :RECONSTRUCTION :FRESH-ASDF-LOAD :SELF-HOSTING NIL
                           :DEPLOYMENT
                           (LIST :AUTHORITY
                                 "dreyeck.ch:/etc/nixos/hyperdoc-service.nix"
                                 :EVIDENCE-KIND :OPERATOR-SUPPLIED
                                 :OBSERVED-COMMAND
                                 "nix develop .#tala -c ./scripts/serve-catalog.sh 8080"
                                 :OPERATOR-REPORT
                                 "TALA reading page is available" :LOCAL-PROOF
                                 :NOT-A-DEPLOYMENT-PROOF :REMOTE-PROBE
                                 :NOT-PERFORMED-BY-WORKFLOW :MUTATION
                                 :OPERATOR-CONTROLLED)))

(HYPERDOC:DEFEXAMPLE READING-WORKSPACE
  (LET* ((PLAN (READING-PLAN))
         (OBJECTS
          (LIST PLAN (ASDF/SYSTEM:FIND-SYSTEM "dreyeck/workflow")
                (READING-HISTORICAL) (READING-MEDLEY)
                (READING-AUTHORING-BOUNDARY)))
         (IDS
          '("workflow:plan" "workflow:asdf" "workflow:history"
            "workflow:medley" "workflow:authoring"))
         (LABELS
          '("Owned persistence plan" "ASDF dependencies" "Historical assembly"
            "Medley File Package" "Pinned authoring boundary"))
         (TOPICS
          (LOOP FOR ID IN IDS
                FOR LABEL IN LABELS
                FOR OBJECT IN OBJECTS
                FOR INDEX FROM 0
                COLLECT (TM:MAKE-TOPICMAP-TOPIC :ID ID :TYPE :WORKFLOW-EVIDENCE
                                                :LABEL LABEL :OBJECT OBJECT
                                                :VIEW-PROPERTIES
                                                (LIST :X (+ 120 (* 210 INDEX))
                                                      :Y
                                                      (+ 130
                                                         (* 100 (MOD INDEX 2)))
                                                      :VISIBLE T))))
         (ASSOCIATIONS
          (LOOP FOR (ID FROM TO TYPE STATUS
                     WARRANT) IN '(("workflow:owned-by" "workflow:plan"
                                    "workflow:asdf" :OWNED-BY
                                    :MECHANICALLY-DERIVED
                                    "ASDF component pathname supplies authority.")
                                   ("workflow:replaces" "workflow:plan"
                                    "workflow:history" :REPLACES
                                    :DESIGN-INFERENCE
                                    "Direct plans preserve tested persistence behavior without fragment assembly.")
                                   ("workflow:analogy" "workflow:plan"
                                    "workflow:medley" :COMPARED-WITH
                                    :WORKING-HYPOTHESIS
                                    "Ownership analogy; not identical implementations.")
                                   ("workflow:executes" "workflow:authoring"
                                    "workflow:plan" :EXECUTES :SOURCE-OBSERVED
                                    "PERSIST-IN specialization is persisted in workflow-authoring.lisp."))
                COLLECT (TM:MAKE-TOPICMAP-ASSOCIATION :ID ID :TYPE TYPE :FROM
                                                      FROM :TO TO :PROPERTIES
                                                      (LIST :PRESENTATION
                                                            :RELATION
                                                            :EPISTEMIC-STATUS
                                                            STATUS :WARRANT
                                                            WARRANT))))
         (PROJECTION
          (TM:MAKE-TOPICMAP-PROJECTION :SOURCE PLAN :TOPICS TOPICS
                                       :ASSOCIATIONS ASSOCIATIONS)))
    (TM:MAKE-TOPICMAP-WORKSPACE PROJECTION "workflow:plan")))

(HYPERDOC:DEFEXAMPLE READING-LAYOUT-COMPARISON
  (LET ((STATUS (DREYECK/TOPICMAP/TALA:TALA-DEPENDENCY-STATUS)))
    (IF (EQ :AVAILABLE (GETF STATUS :STATUS))
        (DREYECK/INSPECTOR/TOPICMAP/TALA:COMPARE-WORKSPACE-LAYOUTS
         (READING-WORKSPACE) :SEED 44)
        (LIST :STATUS :REQUIRES-OPTIONAL-TALA-ENVIRONMENT :DEPENDENCY STATUS
              :WORKSPACE (READING-WORKSPACE)))))

(VIEWS:DEFVIEW VIEW-PERSISTENCE-PLAN (PLAN WF:PERSISTENCE-PLAN)
               (VIEWS:HTML-VIEW :TITLE "Persistence boundary" :PRIORITY 1
                                (VIEWS:HTML
                                  (:P
                                   "A proposal owns one source form. Inspection does not write.")
                                  (:P
                                   (VIEWS:OBJECT-REF (WF:PLAN-PATH PLAN)
                                                     :DISPLAY "Authority"))
                                  (:P
                                   (VIEWS:OBJECT-REF (WF:PLAN-BEFORE PLAN)
                                                     :DISPLAY "Persisted form"))
                                  (:P
                                   (VIEWS:OBJECT-REF (WF:PLAN-PROPOSED PLAN)
                                                     :DISPLAY "Proposed form"))
                                  (:P
                                   (VIEWS:OBJECT-REF (WF:PLAN-EXPECTATION PLAN)
                                                     :DISPLAY
                                                     "Fresh expectation"))
                                  (:P
                                   (VIEWS:OBJECT-REF (WF:PLAN-STATUS PLAN)
                                                     :DISPLAY "Status")))))

(HYPERDOC:DEFEXAMPLE READING-PERSISTENCE-ROUNDTRIP
  (IF (UIOP/OS:GETENV "HYPERDOC_WORKFLOW_EDITOR_SOURCE")
      (PROGN
       (ASDF/OPERATE:LOAD-SYSTEM "dreyeck/workflow/authoring/tests")
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/WORKFLOW/TESTS :RUN-AUTHORING-TESTS)
       (LIST :STATUS :VERIFIED :EXECUTOR 'WF:PERSIST-IN :SCOPE
             :TEMPORARY-AUTHORITIES :RECONSTRUCTION :FRESH-ORDINARY-RUNTIME))
      (LIST :STATUS :REQUIRES-AUTHORING-ENVIRONMENT :COMMAND
            "nix develop .#workflow-authoring" :REQUEST (READING-PLAN))))

(HYPERDOC:DEFEXAMPLE READING-OUTSTANDING-CHANGES
                     (LET
                          ((NAME (GENSYM "WORKFLOW-LIVE-ONLY-INCREMENT-"))
                           (LOG (MAKE-INSTANCE (QUOTE WF:CHANGE-LOG))))
                          (SETF (SYMBOL-FUNCTION NAME)
                                (COMPILE NIL (QUOTE (LAMBDA (X) (+ X 1)))))
                          (LET
                               ((DREYECK/WORKFLOW/READING::A
                                                             (WF:REGISTER-CHANGE
                                                                                 NAME
                                                                                 LOG)))
                               (SETF (SYMBOL-FUNCTION NAME)
                                     (COMPILE NIL
                                              (QUOTE (LAMBDA (X) (+ X 2)))))
                               (LET
                                    ((DREYECK/WORKFLOW/READING::AFTER-REDEFINITION
                                                                                   (LIST
                                                                                         :OUTSTANDING
                                                                                         (WF:OUTSTANDING-CHANGES
                                                                                                                 LOG)
                                                                                         :CURRENT
                                                                                         (DREYECK/WORKFLOW:CURRENT-OUTSTANDING-CHANGES
                                                                                                                                       LOG)
                                                                                         :OBSERVATION
                                                                                         (WF:OBSERVE-CHANGE
                                                                                                            DREYECK/WORKFLOW/READING::A)))
                                     (DREYECK/WORKFLOW/READING::B
                                                                  (WF:REGISTER-CHANGE
                                                                                      NAME
                                                                                      LOG)))
                                    (LIST :LOG LOG :A
                                          DREYECK/WORKFLOW/READING::A :B
                                          DREYECK/WORKFLOW/READING::B
                                          :AFTER-REDEFINITION
                                          DREYECK/WORKFLOW/READING::AFTER-REDEFINITION
                                          :OUTSTANDING
                                          (WF:OUTSTANDING-CHANGES LOG) :CURRENT
                                          (DREYECK/WORKFLOW:CURRENT-OUTSTANDING-CHANGES
                                                                                        LOG)
                                          :OBSERVATIONS
                                          (MAPCAR (FUNCTION WF:OBSERVE-CHANGE)
                                                  (WF:OUTSTANDING-CHANGES LOG))
                                          :SCOPE
                                          :EXPLICIT-REGISTRATIONS-IN-THIS-EXAMPLE)))))

(HYPERDOC:DEFEXAMPLE READING-CHANGE-VERIFICATION
  (IF (UIOP/OS:GETENV "HYPERDOC_WORKFLOW_EDITOR_SOURCE")
      (PROGN
       (ASDF/OPERATE:LOAD-SYSTEM "dreyeck/workflow/authoring/tests")
       (UIOP/PACKAGE:SYMBOL-CALL :DREYECK/WORKFLOW/TESTS :RUN-AUTHORING-TESTS))
      (LIST :STATUS :REQUIRES-AUTHORING-ENVIRONMENT :COMMAND
            "nix develop path:.#workflow-authoring" :EXECUTOR 'WF:VERIFY-CHANGE
            :PERSIST-AND-VERIFY 'WF:PERSIST-IN :EXAMPLE
            (READING-OUTSTANDING-CHANGES))))

(DREYECK/HYPERDOC:DEFHYPERDOC *WORKFLOW-READING* :ID "dreyeck/workflow/reading"
                              :TITLE "Reconstructing Workflow"
                              :ASDF-SYSTEM-NAME "dreyeck/workflow/reading"
                              :SUBDIRECTORY "dreyeck/pages/workflow"
                              :CODE-SUBDIRECTORY "dreyeck/src" :MAIN-PAGE-ID
                              "Reconstructing Workflow")
