;;;; Proposed Nested Action Probes

(IN-PACKAGE #:DREYECK/NESTED-ACTIONS)

(HYPERDOC:SEE
  (HYPERDOC:PAGE "What Does a Nested Action Inherit?" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:SEE
  (HYPERDOC:PAGE "Nested Actions in Solo" :HYPERBOOK
                 "dreyeck/nested-actions/reading"))

(HYPERDOC:DEFEXAMPLE SEMANTIC-QUESTIONS
  "Fresh open question records. Later answers can carry evidence without rewriting the observation."
  (LOOP FOR (ID
             QUESTION) IN '((:ENVIRONMENT
                             "What environment is visible to LISTEN; which values, aspects and sources are inherited?")
                            (:NODE "What object does node denote?")
                            (:TITLE
                             "What object supplies title, outside and inside LISTEN?")
                            (:EVENT-CONTEXT
                             "Does an event replace, extend, or leave untouched the enclosing context? Is rebind an accurate description?")
                            (:LIFETIME
                             "How long does the nested computation live?")
                            (:TERMINATION
                             "What ends it; how are cancellation and unsubscription handled?")
                            (:SCOPE
                             "What evidence distinguishes lexical from dynamic scope, or establishes closure semantics?"))
        COLLECT (LIST :ID ID :QUESTION QUESTION :STATUS :OPEN :ANSWER NIL
                      :EVIDENCE NIL)))

(HYPERDOC:DEFEXAMPLE PROPOSED-PROBES
  "Construct plans for future semantic experiments. None executes Solo.
Even validity of the proposed action notation requires the matching implementation."
  (LIST
   (LIST :ID :OUTER-INNER-TITLE :STATUS :PROPOSED :EXECUTABLE-P NIL
         :NOTATION-VALIDITY :UNVERIFIED :FORM
         '("SOLO" ("REPORT" "title") ("LISTEN" "node" ("REPORT" "title")))
         :QUESTION :TITLE :PROCEDURE
         "Give the enclosing input a distinguishable title A and click a node with title B. Record both REPORT values and object identities, including missing-title errors."
         :DISCRIMINATES
         "A then B is consistent with different suppliers; A then A is consistent with retained lookup; neither result alone establishes scope or rebinding."
         :REQUIRED-EVIDENCE
         "Exact plugin revision, accepted notation, input and event objects, before/after state and output trace."
         :RESULT NIL)
   (LIST :ID :EVENT-STATE :STATUS :PROPOSED :EXECUTABLE-P NIL
         :NOTATION-VALIDITY :UNVERIFIED :QUESTION :EVENT-CONTEXT :PROCEDURE
         "Observe the enclosing state identity and keys before LISTEN and on two distinct clicks. Compare retained keys and new event fields."
         :DISCRIMINATES
         "Replacement, extension and unchanged state require paired object/key evidence; reported titles alone do not discriminate."
         :REQUIRED-EVIDENCE
         "Matching source and debugger observations at dispatch and nested evaluation."
         :RESULT NIL)
   (LIST :ID :LIFETIME :STATUS :PROPOSED :EXECUTABLE-P NIL :NOTATION-VALIDITY
         :UNVERIFIED :QUESTION :TERMINATION :PROCEDURE
         "Record callbacks after two clicks, rerun the enclosing action, close its UI and click again. Inspect disposal and subscription counts."
         :DISCRIMINATES
         "Repeated, duplicate or absent callbacks delimit lifetime only for the tested run; source must explain cancellation."
         :REQUIRED-EVIDENCE
         "Timestamped events, callback identities and actual cleanup path."
         :RESULT NIL)))
