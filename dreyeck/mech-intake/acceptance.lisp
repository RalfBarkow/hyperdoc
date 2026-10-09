;;;; Inspecting Mech Acceptance and Deviations

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

(HYPERDOC:DEFEXAMPLE ACCEPTANCE-EVIDENCE
  "Expose separate retained source/catalog, technical browser, semantic, ambiguity and correction evidence."
  (LET* ((COMPOSITION (RETAINED-COMPOSITION))
         (DECISION (RECORD-OF COMPOSITION "acceptance.json")))
    (LIST :EVIDENCE-STATUS :RETAINED-TEST-RECORD
          :RUNTIME-EXECUTED-BY-THIS-EXAMPLE NIL :COMPOSITION COMPOSITION
          :TECHNICAL-BROWSER (GETHASH "browser" (GETHASH "checks" DECISION))
          :SELECTED-SEMANTIC (RECORD-OF COMPOSITION "selected-contracts.json")
          :FULL-EQUIVALENCE
          (RECORD-OF COMPOSITION "behavioral-equivalence.json") :AMBIGUITY
          (RECORD-OF COMPOSITION "twins-results.json")
          :SOURCE-AND-CATALOG-DECISION DECISION :EARLIER-DECISION
          (RECORD-OF COMPOSITION "prior-acceptance.json") :REVIEW-SOURCE
          (EVIDENCE-PATH "review-request.txt") :CORRECTION-CHECKS
          (GETHASH "checks" DECISION) :CORRECTION-SOURCE
          (SOURCE-BY-KEY COMPOSITION "owned:renderEdgesHtml")
          :ACCEPTANCE-RUNNER-SOURCE
          (SOURCE-BY-KEY COMPOSITION "owned:evaluateAcceptance")
          :CLEANUP-SOURCE (SOURCE-BY-KEY COMPOSITION "owned:contextOwner")
          :OPEN-DECISIONS (OPEN-DECISIONS COMPOSITION))))

(DEFUN OPEN-DECISIONS (&OPTIONAL (COMPOSITION (RETAINED-COMPOSITION)))
  "Application questions remain open; Ward's temporary snippet is author-reported, not committed upstream behavior."
  (LIST
   (LIST :ID :DUPLICATE-SLUG :STATUS :OPEN :QUESTION
         "Which site should an unqualified Wiki link select?" :EVIDENCE
         (RECORD-OF COMPOSITION "twins-results.json") :IMPLEMENTED-POLICY NIL)
   (LIST :ID :PRODUCTION-SOLO :STATUS :OPEN :QUESTION
         "Does the deployed Solo plugin honor this batch/lifecycle contract?"
         :EVIDENCE
         (GETHASH "browser"
                  (GETHASH "checks" (RECORD-OF COMPOSITION "acceptance.json")))
         :BOUNDARY :TRUSTED-ISOLATED-RECEIVER-ONLY)
   (LIST :ID :CODE-TRUST :STATUS :OPEN :QUESTION
         "Which page/message sources and invocation initiators may authorize production CODE?"
         :SOURCE (SOURCE-BY-KEY COMPOSITION "upstream:code_emit") :BOUNDARY
         :INVOCATION-GUARD-NOT-JAVASCRIPT-SANDBOX)
   (LIST :ID :EXPERIMENTAL-LISTEN :STATUS :AUTHOR-REPORTED :REVISION NIL
         :SOURCE (SOURCE-BY-KEY COMPOSITION "author:listen-experiment")
         :TEMPORARY-FRAGMENT
         (N:SOURCE-TEXT (SOURCE-BY-KEY COMPOSITION "author:listen-experiment"))
         :INTENDED-FINAL-IMPLEMENTATION NIL :CURRENT-UPSTREAM-ESTABLISHED NIL
         :CONDITIONAL-INFERENCE
         "If that invocation reached the tested dispatcher unchanged, the truthy 'listen' would satisfy the tested CODE guard."
         :INFERENCE-STATUS :INFERRED :EXPLOIT-ESTABLISHED NIL)))
