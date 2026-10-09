;;;; Navigating a Maintained Mech Composition

(IN-PACKAGE #:DREYECK/MECH-INTAKE)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Reading a Maintained Mech Composition" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "From Upstream Mech to an Owned Extension" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Which Graph Does WALK Produce?" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Evidence, Deviations and Acceptance" :HYPERBOOK
                 "dreyeck/mech-intake/reading"))

(DEFUN WARRANTED-PROJECTION (SOURCE TOPICS RELATIONS)
  "Use the existing projection protocol. Objects are the actual retained domain objects, not IDs."
  (TM:MAKE-TOPICMAP-PROJECTION :SOURCE SOURCE :TOPICS
                               (LOOP FOR (ID LABEL OBJECT STATUS) IN TOPICS
                                     FOR I FROM 0
                                     DO (UNLESS OBJECT
                                          (ERROR
                                           "Missing represented Mech object: ~A"
                                           ID))
                                     COLLECT (TM:MAKE-TOPICMAP-TOPIC :ID ID
                                                                     :TYPE
                                                                     :MECH-INTAKE
                                                                     :LABEL
                                                                     LABEL
                                                                     :OBJECT
                                                                     OBJECT
                                                                     :VIEW-PROPERTIES
                                                                     (LIST :X
                                                                           (+
                                                                            30
                                                                            (*
                                                                             260
                                                                             (MOD
                                                                              I
                                                                              4)))
                                                                           :Y
                                                                           (+
                                                                            30
                                                                            (*
                                                                             135
                                                                             (FLOOR
                                                                              I
                                                                              4)))
                                                                           :VISIBLE
                                                                           T
                                                                           :EVIDENCE-STATUS
                                                                           STATUS)))
                               :ASSOCIATIONS
                               (LOOP FOR (FROM TO LABEL KIND STATUS BASIS
                                          EVIDENCE) IN RELATIONS
                                     FOR I FROM 0
                                     DO (UNLESS (AND BASIS EVIDENCE)
                                          (ERROR
                                           "Unwarranted Mech relation: ~A"
                                           LABEL))
                                     COLLECT (TM:MAKE-TOPICMAP-ASSOCIATION :ID
                                                                           (FORMAT
                                                                            NIL
                                                                            "mech-relation-~D"
                                                                            I)
                                                                           :TYPE
                                                                           LABEL
                                                                           :FROM
                                                                           FROM
                                                                           :TO
                                                                           TO
                                                                           :PROPERTIES
                                                                           (LIST
                                                                            :RELATION-KIND
                                                                            KIND
                                                                            :BASIS
                                                                            BASIS
                                                                            :EVIDENCE-STATUS
                                                                            STATUS
                                                                            :WARRANT
                                                                            (LIST
                                                                             :STATUS
                                                                             STATUS
                                                                             :SOURCE
                                                                             EVIDENCE
                                                                             :BASIS
                                                                             BASIS))))
                               :VIEW-PROPERTIES '(:WIDTH 1150 :HEIGHT 1400)))

(DEFUN SOURCE-PROJECTION (COMPOSITION)
  (LET* ((DECISION (RECORD-OF COMPOSITION "acceptance.json"))
         (BROWSER (GETHASH "browser" (GETHASH "checks" DECISION)))
         (PROFILES (GETHASH "profiles" DECISION))
         (UP (AREF PROFILES 0))
         (DISC (AREF PROFILES 1))
         (CATALOG-SOURCE (SOURCE-BY-KEY COMPOSITION "upstream:blocks"))
         (EXTENSION (SOURCE-BY-KEY COMPOSITION "owned:installDiscourse"))
         (ENTRY (SOURCE-BY-KEY COMPOSITION "owned:src/discourse-entry.mjs"))
         (CATALOG
          (LOOP FOR TEST ACROSS (GETHASH "tests"
                                         (RECORD-OF COMPOSITION
                                                    "browser-results.json"))
                WHEN (AND (EQUAL "upstream" (GETHASH "configuration" TEST))
                          (EQUAL "Bundle loaded with expected plugin entry"
                                 (GETHASH "name" TEST))) RETURN (GETHASH
                                                                 "evidence"
                                                                 TEST)))
         (IDENTITY (GETHASH "moduleIdentity" DECISION))
         (QUESTIONS (OPEN-DECISIONS COMPOSITION))
         (PENDING
          (LIST :STATUS :OPEN :AUTHORITY (GETHASH "authority" IDENTITY) :PATH
                "integrations/mech" :REQUIRED :ACTUAL-FUTURE-COMMIT-OID
                :BASE-IS-EXTENSION-REVISION NIL))
         (REVIEW
          (LIST :KIND :REPORTED-REVIEW :SOURCE
                (EVIDENCE-PATH "review-request.txt") :FINDINGS
                '((:P1 :EDGES-ATTRIBUTE-INJECTION)
                  (:P2 :ACCEPTANCE-EXIT-STATUS) (:P2 :CONTEXT-CLEANUP)
                  (:P2 :DURABLE-ACCEPTANCE))
                :CORRECTION-EVIDENCE (GETHASH "checks" DECISION))))
    (WARRANTED-PROJECTION COMPOSITION
                          (LIST
                           (LIST "upstream"
                                 "Upstream a028b4b: repository + full OID"
                                 (CDR
                                  (ASSOC "upstream"
                                         (COMPOSITION-REVISIONS COMPOSITION)
                                         :TEST #'EQUAL))
                                 :OBSERVED)
                           (LIST "baseline" "Discourse baseline abd88d2"
                                 (CDR
                                  (ASSOC "behavioralBaseline"
                                         (COMPOSITION-REVISIONS COMPOSITION)
                                         :TEST #'EQUAL))
                                 :OBSERVED)
                           (LIST "module" "Owned module: uncommitted snapshot"
                                 IDENTITY :OBSERVED)
                           (LIST "pending-commit"
                                 "Commit link pending in historical observation"
                                 PENDING :OPEN)
                           (LIST "catalog-source" "Exported blocks catalog"
                                 CATALOG-SOURCE :OBSERVED)
                           (LIST "catalog"
                                 "Actual browser-loaded catalog record" CATALOG
                                 :OBSERVED)
                           (LIST "dispatcher" "Unchanged upstream run"
                                 (SOURCE-BY-KEY COMPOSITION "upstream:run")
                                 :OBSERVED)
                           (LIST "extension"
                                 "installDiscourse: separately owned operations"
                                 EXTENSION :OBSERVED)
                           (LIST "entry" "Discourse composition entry" ENTRY
                                 :OBSERVED)
                           (LIST "build" "buildProfiles recipe"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "owned:buildProfiles")
                                 :OBSERVED)
                           (LIST "upstream-profile" "Upstream-only profile" UP
                                 :OBSERVED)
                           (LIST "discourse-profile" "Discourse profile" DISC
                                 :OBSERVED)
                           (LIST "upstream-bundle"
                                 "Upstream bundle: recorded artifact identity"
                                 (GETHASH "client/mech.js"
                                          (GETHASH "artifacts" UP))
                                 :OBSERVED)
                           (LIST "discourse-bundle"
                                 "Composite bundle: recorded artifact identity"
                                 (GETHASH "client/mech.js"
                                          (GETHASH "artifacts" DISC))
                                 :OBSERVED)
                           (LIST "acceptance"
                                 "T1–T9 technical browser acceptance" BROWSER
                                 :OBSERVED)
                           (LIST "behavioral" "Full equivalence: FAIL"
                                 (RECORD-OF COMPOSITION
                                            "behavioral-equivalence.json")
                                 :OBSERVED)
                           (LIST "review"
                                 "Four review findings and retained corrections"
                                 REVIEW :DERIVED)
                           (LIST "code-policy" "Production CODE policy: open"
                                 (THIRD QUESTIONS) :OPEN)
                           (LIST "production-solo"
                                 "Production Solo compatibility: open"
                                 (SECOND QUESTIONS) :OPEN)
                           (LIST "experimental-listen"
                                 "Ward/Paul temporary LISTEN experiment"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "author:listen-experiment")
                                 :AUTHOR-REPORTED)
                           (LIST "verify-source" "Source-integrity check"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "owned:verifySnapshot")
                                 :OBSERVED))
                          (LIST
                           (LIST "upstream" "catalog-source"
                                 "identifies catalog source"
                                 :REVISION-PROVENANCE :OBSERVED
                                 "Exact committed definition and file hash"
                                 CATALOG-SOURCE)
                           (LIST "catalog-source" "catalog"
                                 "defines exported catalog inspected in browser"
                                 :SOURCE-COMPOSITION :DERIVED
                                 "Source registry corresponds to retained browser array; not a new run"
                                 CATALOG)
                           (LIST "upstream" "dispatcher"
                                 "supplies unchanged dispatcher"
                                 :SOURCE-COMPOSITION :OBSERVED
                                 "Pinned run definition"
                                 (SOURCE-BY-KEY COMPOSITION "upstream:run"))
                           (LIST "module" "extension"
                                 "owns extension source snapshot"
                                 :SOURCE-OWNERSHIP :OBSERVED
                                 "Historical module digest and retained definition; later source commit linked separately"
                                 EXTENSION)
                           (LIST "module" "pending-commit"
                                 "awaits actual immutable source authority"
                                 :REVISION-PROVENANCE :OPEN
                                 "No extension commit existed at the retained pre-commit observation"
                                 PENDING)
                           (LIST "extension" "catalog"
                                 "adds EXTRACT EDGES DEBUG; wraps WALK"
                                 :CATALOG-REGISTRATION :OBSERVED
                                 "installDiscourse validates catalog then installs; ordinary WALK delegates"
                                 EXTENSION)
                           (LIST "entry" "extension"
                                 "installs before export/emission"
                                 :SOURCE-COMPOSITION :OBSERVED
                                 "Entry imports shared upstream catalog and calls installDiscourse"
                                 ENTRY)
                           (LIST "entry" "dispatcher" "reexports original run"
                                 :SOURCE-COMPOSITION :OBSERVED
                                 "No owned parser or dispatcher copy" ENTRY)
                           (LIST "build" "upstream-profile"
                                 "selects entry without extension"
                                 :PROFILE-SELECTION :OBSERVED
                                 "Explicit profile branch; upstream entry retained"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "owned:src/upstream-entry.mjs"))
                           (LIST "build" "discourse-profile"
                                 "selects composed entry" :PROFILE-SELECTION
                                 :OBSERVED "Explicit discourse entry branch"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "owned:buildProfiles"))
                           (LIST "upstream-profile" "upstream-bundle"
                                 "records generated artifact"
                                 :ARTIFACT-PROVENANCE :OBSERVED
                                 "Retained decision digest; bytes not bundled into this reading"
                                 UP)
                           (LIST "discourse-profile" "discourse-bundle"
                                 "records generated artifact"
                                 :ARTIFACT-PROVENANCE :OBSERVED
                                 "Retained decision digest; not a newly built artifact"
                                 DISC)
                           (LIST "discourse-bundle" "acceptance"
                                 "passes technical browser contracts"
                                 :TEST-EVIDENCE :OBSERVED
                                 "Retained 36-check correction decision"
                                 DECISION)
                           (LIST "baseline" "behavioral"
                                 "comparison preserves two failures"
                                 :SEMANTIC-COMPARISON :OBSERVED
                                 "33 pass, 2 strict differences; no equivalence promotion"
                                 (RECORD-OF COMPOSITION
                                            "behavioral-equivalence.json"))
                           (LIST "acceptance" "behavioral"
                                 "does not establish full equivalence"
                                 :ACCEPTANCE-BOUNDARY :DERIVED
                                 "Independent decision scopes" DECISION)
                           (LIST "review" "acceptance"
                                 "correction tests recorded" :REVIEW-EVIDENCE
                                 :DERIVED
                                 "Reported findings + retained corrected check counts"
                                 REVIEW)
                           (LIST "acceptance" "production-solo"
                                 "isolated receiver does not prove deployed compatibility"
                                 :DEPLOYMENT-BOUNDARY :OPEN
                                 "Retained receiver contract is bounded to trusted offline harness"
                                 (SECOND QUESTIONS))
                           (LIST "experimental-listen" "code-policy"
                                 "truthy listen initiator would satisfy tested guard if propagated unchanged"
                                 :CONDITIONAL-AUTHORIZATION :INFERRED
                                 "Author experiment plus tested guard; no combined runtime or exploit established"
                                 (LIST
                                  (SOURCE-BY-KEY COMPOSITION
                                                 "author:listen-experiment")
                                  (SOURCE-BY-KEY COMPOSITION
                                                 "upstream:code_emit")))
                           (LIST "verify-source" "upstream"
                                 "checks pinned snapshot bytes"
                                 :SOURCE-INTEGRITY :OBSERVED
                                 "verifySnapshot checks exact file inventory and hashes"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "owned:verifySnapshot"))))))

(DEFUN EXECUTION-PROJECTION (TRACE)
  (LET* ((COMPOSITION (EXECUTION-COMPOSITION TRACE))
         (STAGES (TRACE-STAGES TRACE))
         (STAGE (LAMBDA (KEY) (CDR (ASSOC KEY STAGES :TEST #'EQUAL))))
         (WALKS (SOURCE-BY-KEY COMPOSITION "owned:walks"))
         (DECISION (RECORD-OF COMPOSITION "acceptance.json"))
         (QUESTION (FIRST (OPEN-DECISIONS COMPOSITION))))
    (WARRANTED-PROJECTION TRACE
                          (APPEND
                           (LOOP FOR (ID . OBJECT) IN STAGES
                                 COLLECT (LIST ID ID OBJECT :OBSERVED))
                           (LIST
                            (LIST "extract-source"
                                  "EXTRACT: fold-aware typed relations"
                                  (SOURCE-BY-KEY COMPOSITION
                                                 "owned:extract_edges_from_story")
                                  :OBSERVED)
                            (LIST "walk-source"
                                  "Role WALK root selection and blanket" WALKS
                                  :OBSERVED)
                            (LIST "solo-source" "Pinned upstream SOLO"
                                  (SOURCE-BY-KEY COMPOSITION
                                                 "upstream:solo_emit")
                                  :OBSERVED)
                            (LIST "reverse-order" "Composite, beta first"
                                  (EXECUTION-RECORD
                                   (RETAINED-EXECUTION COMPOSITION "composite"
                                                       "beta.fixture.test"))
                                  :OBSERVED)
                            (LIST "resolution-question"
                                  "Which site's Wiki link target?" QUESTION
                                  :OPEN)
                            (LIST "acceptance"
                                  "Technical acceptance does not settle resolution"
                                  (GETHASH "browser"
                                           (GETHASH "checks" DECISION))
                                  :OBSERVED)
                            (LIST "behavioral" "Full equivalence remains FAIL"
                                  (RECORD-OF COMPOSITION
                                             "behavioral-equivalence.json")
                                  :OBSERVED)))
                          (LIST
                           (LIST "source-page" "source-paragraph"
                                 "contains exact trusted paragraph"
                                 :SOURCE-CONTAINMENT :OBSERVED
                                 "Fixture page identity is site + slug; story item root-link"
                                 (FUNCALL STAGE "source-page"))
                           (LIST "source-paragraph" "typed-relations"
                                 "EXTRACT records question relation"
                                 :TYPED-DISCOURSE-EXTRACTION :OBSERVED
                                 "Retained Node case and fold-aware extractor definition"
                                 (EXECUTION-RECORD TRACE))
                           (LIST "extract-source" "typed-relations"
                                 "defines extraction transform"
                                 :SOURCE-PROVENANCE :OBSERVED
                                 "Exact owned source snapshot"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "owned:extract_edges_from_story"))
                           (LIST "typed-relations" "selected-roots"
                                 "selects fromId roots by role/lineup"
                                 :ROOT-SELECTION :OBSERVED
                                 "Site-qualified root lookup; typed target is not consumed by blanket"
                                 (EXECUTION-RECORD TRACE))
                           (LIST "selected-roots" "blanket-lookup"
                                 "starts separate Wiki-neighborhood traversal"
                                 :WIKI-NEIGHBORHOOD :OBSERVED
                                 "Recorded find(slug) has no site constraint"
                                 (FUNCALL STAGE "blanket-lookup"))
                           (LIST "walk-source" "blanket-lookup"
                                 "defines unqualified child lookup"
                                 :SOURCE-PROVENANCE :OBSERVED
                                 "blanket(info) uses Wiki links and find(link)"
                                 WALKS)
                           (LIST "blanket-lookup" "neighborhood-graph"
                                 "resolves child and adds untyped graph relations"
                                 :WIKI-NEIGHBORHOOD :OBSERVED
                                 "Two nodes/two relations in retained case; not typed Discourse graph"
                                 (EXECUTION-RECORD TRACE))
                           (LIST "neighborhood-graph" "aspects"
                                 "graph is the recorded aspect graph"
                                 :GRAPH-PUBLICATION :OBSERVED
                                 "Same parsed graph object within this retained aspect; original JS identity not recovered"
                                 (FUNCALL STAGE "aspects"))
                           (LIST "aspects" "published-aspects"
                                 "publishes aspect values" :GRAPH-PUBLICATION
                                 :DERIVED
                                 "Value correspondence across serialized observation stages, not EQ"
                                 (EXECUTION-RECORD TRACE))
                           (LIST "published-aspects" "solo-batch"
                                 "packages aspect values in batch" :SOLO-BATCH
                                 :DERIVED
                                 "Recorded batch sources/aspects match publications; independent serialized objects"
                                 (FUNCALL STAGE "solo-batch"))
                           (LIST "solo-source" "solo-batch"
                                 "defines batch postMessage" :SOURCE-PROVENANCE
                                 :OBSERVED
                                 "Pinned solo_emit and retained Node batch; browser lifecycle separately tested"
                                 (SOURCE-BY-KEY COMPOSITION
                                                "upstream:solo_emit"))
                           (LIST "blanket-lookup" "reverse-order"
                                 "ordering changes source selection"
                                 :AMBIGUITY-WITNESS :OBSERVED
                                 "Same composite source, reversed site enumeration"
                                 (RECORD-OF COMPOSITION "twins-results.json"))
                           (LIST "reverse-order" "resolution-question"
                                 "requires an explicit application policy"
                                 :APPLICATION-DECISION :OPEN
                                 "Date order is not a site-resolution contract"
                                 QUESTION)
                           (LIST "acceptance" "resolution-question"
                                 "does not decide intended site"
                                 :ACCEPTANCE-BOUNDARY :OPEN
                                 "Technical checks and policy are independent"
                                 QUESTION)))))

(DEFUN READING-WORKSPACE
       (&OPTIONAL (COMPOSITION (RETAINED-COMPOSITION)) (MODE :SOURCE) TRACE)
  (ECASE MODE
    (:SOURCE
     (TM:MAKE-TOPICMAP-WORKSPACE (SOURCE-PROJECTION COMPOSITION)
                                 "catalog-source"))
    (:EXECUTION
     (TM:MAKE-TOPICMAP-WORKSPACE
      (EXECUTION-PROJECTION (OR TRACE (RETAINED-EXECUTION COMPOSITION)))
      "source-page"))))

(DEFUN SWITCH-PROJECTION (WORKSPACE MODE)
  "Reuse the same Workspace and preserve Point/history, including a Point absent from a projection."
  (LET* ((SOURCE
          (TM:TOPICMAP-PROJECTION-SOURCE-OF
           (TM:TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE)))
         (COMPOSITION
          (IF (TYPEP SOURCE 'EXECUTION-TRACE)
              (EXECUTION-COMPOSITION SOURCE)
              SOURCE)))
    (TM:TOPICMAP-WORKSPACE-REPROJECT WORKSPACE
                                     (ECASE MODE
                                       (:SOURCE
                                        (SOURCE-PROJECTION COMPOSITION))
                                       (:EXECUTION
                                        (EXECUTION-PROJECTION
                                         (RETAINED-EXECUTION COMPOSITION)))))
    WORKSPACE))

(HYPERDOC:DEFEXAMPLE MAINTAINED-MECH-WORKSPACE
  (READING-WORKSPACE))

(HYPERDOC:DEFEXAMPLE LAYOUT-COMPARISON
  "Optional TALA request; rendering and ordinary navigation never invoke a build or test."
  (LAYOUT:COMPARE-WORKSPACE-LAYOUTS (READING-WORKSPACE) :SEED 44))

(DREYECK/HYPERDOC:DEFHYPERDOC *READING* :TITLE
                              "Reading a Maintained Mech Composition" :ID
                              "dreyeck/mech-intake/reading" :ASDF-SYSTEM-NAME
                              "dreyeck/mech-intake/reading" :SUBDIRECTORY
                              "dreyeck/pages/mech-intake" :CODE-SUBDIRECTORY
                              "dreyeck/mech-intake" :MAIN-PAGE-ID
                              "Reading a Maintained Mech Composition")

(DOLIST
    (NAME
     '(RETAINED-COMPOSITION CATALOG-EVIDENCE TRACE-EXTRACT-WALK-SOLO
                            ACCEPTANCE-EVIDENCE MAINTAINED-MECH-WORKSPACE
                            LAYOUT-COMPARISON))
  (DREYECK/AUTHORITY-POLICY:REGISTER-OPERATION-CONTRACT :IDENTITY
                                                        (FORMAT NIL
                                                                "mech-intake/~A"
                                                                NAME)
                                                        :OPERATION
                                                        (FORMAT NIL
                                                                "DREYECK/MECH-INTAKE::~A"
                                                                NAME)
                                                        :APPLICABILITY :EXAMPLE
                                                        :STATUS :CONTRACTED
                                                        :EFFECT-CLASSES
                                                        '(:OBSERVATIONAL)
                                                        :EFFECT-EXTENT
                                                        "Read hash-verified retained files; allocate source, trace and Workspace objects. Optional TALA uses the existing temporary layout boundary."
                                                        :AUTHORITY
                                                        "Pinned source identities, provisional module observation and retained test records"
                                                        :PRECONDITIONS
                                                        "Reading loaded; optional layout requires pinned D2/TALA"
                                                        :POSTCONDITIONS
                                                        "Wiki module, persisted source and external runtimes unchanged"
                                                        :VERIFICATION-EVIDENCE
                                                        "dreyeck/mech-intake/reading/tests"
                                                        :REPLAY-SEMANTICS
                                                        "Fresh Lisp inspection; no Mech execution or implicit rebuild"
                                                        :AUDIT-PROVENANCE
                                                        "Mech intake reading, 2026-10-09"))
