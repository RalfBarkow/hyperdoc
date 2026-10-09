;;;; Tracing EXTRACT through WALK to SOLO

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

(DEFCLASS EXECUTION-TRACE NIL
          ((COMPOSITION :INITARG :COMPOSITION :READER EXECUTION-COMPOSITION)
           (RECORD :INITARG :RECORD :READER EXECUTION-RECORD)
           (SOURCE-PAGE :INITARG :SOURCE-PAGE :READER EXECUTION-SOURCE-PAGE)))

(DEFUN RETAINED-EXECUTION
       (
        &OPTIONAL (COMPOSITION (RETAINED-COMPOSITION))
        (IMPLEMENTATION "composite") (FIRST-SITE "alpha.fixture.test"))
  "Inspect an actual retained Node case; these Lisp steps do not execute or translate EXTRACT, WALK or SOLO."
  (LET* ((CASE
          (FIND-IF
           (LAMBDA (R)
             (AND (EQUAL IMPLEMENTATION (GETHASH "implementation" R))
                  (EQUAL FIRST-SITE (AREF (GETHASH "siteOrder" R) 0))))
           (GETHASH "results" (RECORD-OF COMPOSITION "twins-results.json"))))
         (PAGE
          (FIND-IF
           (LAMBDA (P)
             (AND (EQUAL "alpha.fixture.test" (GETHASH "site" P))
                  (EQUAL "question-root" (GETHASH "slug" P))))
           (GETHASH "pages" (RECORD-OF COMPOSITION "twins-input.json")))))
    (UNLESS (AND CASE PAGE)
      (ERROR
       "Retained case/input missing; no reconstructed replacement is supplied."))
    (MAKE-INSTANCE 'EXECUTION-TRACE :COMPOSITION COMPOSITION :RECORD CASE
                   :SOURCE-PAGE PAGE)))

(DEFUN TRACE-STAGES (TRACE)
  (LET* ((R (EXECUTION-RECORD TRACE))
         (ASPECT (AREF (GETHASH "result" (AREF (GETHASH "aspects" R) 0)) 0)))
    (LIST (CONS "source-page" (EXECUTION-SOURCE-PAGE TRACE))
          (CONS "source-paragraph"
                (AREF (GETHASH "story" (EXECUTION-SOURCE-PAGE TRACE)) 1))
          (CONS "typed-relations" (GETHASH "edges" (GETHASH "extracted" R)))
          (CONS "selected-roots" (GETHASH "rootSelection" R))
          (CONS "blanket-lookup" (AREF (GETHASH "lookups" R) 1))
          (CONS "neighborhood-graph" (GETHASH "graph" ASPECT))
          (CONS "aspects" (GETHASH "aspects" R))
          (CONS "published-aspects" (GETHASH "publications" R))
          (CONS "solo-batch" (AREF (GETHASH "batches" R) 0)))))

(DEFMETHOD V:TEXT-REPRESENTATION ((TRACE EXECUTION-TRACE))
  (FORMAT NIL "Retained ~A execution, ~A first"
          (GETHASH "implementation" (EXECUTION-RECORD TRACE))
          (AREF (GETHASH "siteOrder" (EXECUTION-RECORD TRACE)) 0)))

(V:DEFVIEW EXECUTION-TRACE-VIEW (TRACE EXECUTION-TRACE)
           (V:HTML-VIEW :TITLE "Execution trace" :PRIORITY 0
                        (V:HTML
                          (:P
                           "Retained traced Node execution with an uninstrumented control, not a new browser run. JSON preserves recorded values and provenance, not original JavaScript reference identity.")
                          (:P
                           (V:OBJECT-REF (EXECUTION-RECORD TRACE) :DISPLAY
                                         "Complete case, lookup candidates and control agreement"))
                          (DOLIST (STAGE (TRACE-STAGES TRACE))
                            (V:HTML
                              (:P (CL-WHO:ESC (CAR STAGE)) " "
                               (V:OBJECT-REF (CDR STAGE)))))
                          (:P
                           "EXTRACT's typed edge selects a source root. blanket constructs separate untyped Wiki-neighborhood edges; it does not project the typed edge's target. Two graph relations are retained, not collapsed into one typed relation.")
                          (:P
                           (V:OBJECT-REF
                            (SOURCE-BY-KEY (EXECUTION-COMPOSITION TRACE)
                             "owned:walks")
                            :SELECT "Composition source" :DISPLAY
                            "Inspect roleWalk, find(slug, site) and blanket(info)"))
                          (:P
                           (V:OBJECT-REF
                            (RETAINED-EXECUTION (EXECUTION-COMPOSITION TRACE)
                             "composite" "beta.fixture.test")
                            :SELECT "Execution trace" :DISPLAY
                            "Compare reverse site order")
                           " · "
                           (V:OBJECT-REF
                            (RETAINED-EXECUTION (EXECUTION-COMPOSITION TRACE)
                             "baseline")
                            :SELECT "Execution trace" :DISPLAY
                            "Compare baseline"))
                          (:P
                           (V:OBJECT-REF
                            (READING-WORKSPACE (EXECUTION-COMPOSITION TRACE)
                             :EXECUTION TRACE)
                            :SELECT "Topicmap" :DISPLAY
                            "Discourse Execution Workspace")
                           " · "
                           (V:OBJECT-REF
                            (READING-PAGE "Which Graph Does WALK Produce?")
                            :SELECT "Content" :DISPLAY
                            "Return to the reading")))))

(HYPERDOC:DEFEXAMPLE TRACE-EXTRACT-WALK-SOLO
  (RETAINED-EXECUTION))
