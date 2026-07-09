;;;; Zettel 9124 PDF reading / DMX bridge.
;;;; Load this file to recover the plan without relying on REPL history.

(DEFPACKAGE #:HYPERDOC/Z9124-PDF-READING
  (:USE #:CL)
  (:EXPORT #:*Z9124-PDF-READING-PLAN*
           #:Z9124-PDF-TOPIC-MAP
           #:Z9124-PDF-PLAN-TOPICS
           #:Z9124-PDF-PLAN-ASSOCIATIONS
           #:Z9124-PDF-OFFLINE-INSPECTION-SQL))

(IN-PACKAGE #:HYPERDOC/Z9124-PDF-READING)

(DEFPARAMETER *Z9124-PDF-READING-PLAN*
  '(:ARTIFACT ZETTEL-9124-PDF-READING-HTN-SHOP3-PLAN :KIND
    :HTN-SHOP3-PLAN-WITH-DMX-MIRROR :STATUS :MATERIALIZED-TO-SOURCE-AND-DMX
    :EPISODE ZETTEL-9124 :ORGANIZING-ANALOGY "Knuth: How to Read a Web"
    :REPO-ROOT "/Users/rgb/workspace/hyperdoc" :DMX-SQLITE
    "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite" :CONCEPT
    (:PROBLEM
     "Reading a PDF should not be a one-off extraction. It should become a reorganisable WEB-like topic system: source artifact -> page/range units -> fragments -> named topics -> plan steps -> executable/readable operations -> DMX mirror."
     :ZETTEL-9124-LESSON
     "The live-image/file-out episode shows why a reading workflow must preserve the relation between live Lisp forms, filed-out source, evidence, plan topics, and offline persistence."
     :OFFLINE-REQUIREMENT
     "The DMX SQLite mirror must carry enough topic and association data to inspect the plan without the live Lisp image.")
    :HTN
    ((:TASK
      (!READ-PDF-AS-HYPERDOC-WEB :PDF ?PDF :EPISODE ZETTEL-9124 :AIM
       HOW-TO-READ-A-WEB))
     (:METHOD WEB-LIKE-PDF-READING :SUBTASKS
      ((!RECORD-SOURCE-IDENTITY ?PDF) (!FINGERPRINT-PDF-SOURCE ?PDF)
       (!SEGMENT-PDF-INTO-PAGE-RANGE-UNITS ?PDF)
       (!EXTRACT-READABLE-TEXT-AND-LAYOUT-CANDIDATES ?PDF)
       (!SELECT-READING-QUESTIONS :STYLE GOLDBERG-PROGRAMMER-AS-READER)
       (!CUT-UP-INTO-JARGON-FRAGMENTS ?PDF)
       (!DERIVE-TOPIC-CANDIDATES-FROM-FRAGMENTS ?PDF)
       (!DERIVE-ASSOCIATIONS-BETWEEN-TOPICS ?PDF)
       (!RELATE-FRAGMENTS-TO-SOURCE-PAGES ?PDF)
       (!MATERIALIZE-READING-TOPIC-MAP-IN-LIVE-LISP ?PDF)
       (!FILE-OUT-READING-PLAN-AND-INSPECTION-FUNCTIONS ?PDF)
       (!PERSIST-READING-PLAN-TO-DMX-SQLITE ?PDF)
       (!VERIFY-OFFLINE-DMX-SQLITE-READABILITY ?PDF)
       (!SELECT-NEXT-READING-TASK ?PDF))))
    :SHOP3-DOMAIN
    (DEFDOMAIN ZETTEL-9124-PDF-READING
     ((:OPERATOR (!RECORD-SOURCE-IDENTITY ?PDF) NIL NIL
       ((SOURCE-IDENTITY-RECORDED ?PDF)))
      (:OPERATOR (!FINGERPRINT-PDF-SOURCE ?PDF)
       ((SOURCE-IDENTITY-RECORDED ?PDF)) NIL ((PDF-FINGERPRINT-RECORDED ?PDF)))
      (:OPERATOR (!SEGMENT-PDF-INTO-PAGE-RANGE-UNITS ?PDF)
       ((PDF-FINGERPRINT-RECORDED ?PDF)) NIL
       ((PDF-PAGE-RANGE-UNITS-AVAILABLE ?PDF)))
      (:OPERATOR (!EXTRACT-READABLE-TEXT-AND-LAYOUT-CANDIDATES ?PDF)
       ((PDF-PAGE-RANGE-UNITS-AVAILABLE ?PDF)) NIL
       ((PDF-TEXT-LAYOUT-CANDIDATES-EXTRACTED ?PDF)))
      (:OPERATOR (!SELECT-READING-QUESTIONS ?STYLE) NIL NIL
       ((READING-QUESTIONS-SELECTED ?STYLE)))
      (:OPERATOR (!CUT-UP-INTO-JARGON-FRAGMENTS ?PDF)
       ((PDF-TEXT-LAYOUT-CANDIDATES-EXTRACTED ?PDF)) NIL
       ((JARGON-FRAGMENTS-DERIVED ?PDF)))
      (:OPERATOR (!DERIVE-TOPIC-CANDIDATES-FROM-FRAGMENTS ?PDF)
       ((JARGON-FRAGMENTS-DERIVED ?PDF)) NIL ((TOPIC-CANDIDATES-DERIVED ?PDF)))
      (:OPERATOR (!DERIVE-ASSOCIATIONS-BETWEEN-TOPICS ?PDF)
       ((TOPIC-CANDIDATES-DERIVED ?PDF)) NIL
       ((TOPIC-ASSOCIATIONS-DERIVED ?PDF)))
      (:OPERATOR (!RELATE-FRAGMENTS-TO-SOURCE-PAGES ?PDF)
       ((PDF-PAGE-RANGE-UNITS-AVAILABLE ?PDF) (JARGON-FRAGMENTS-DERIVED ?PDF))
       NIL ((SOURCE-PAGE-FRAGMENT-RELATIONS-DERIVED ?PDF)))
      (:OPERATOR (!MATERIALIZE-READING-TOPIC-MAP-IN-LIVE-LISP ?PDF)
       ((TOPIC-ASSOCIATIONS-DERIVED ?PDF)
        (SOURCE-PAGE-FRAGMENT-RELATIONS-DERIVED ?PDF))
       NIL ((LIVE-LISP-TOPIC-MAP-MATERIALIZED ?PDF)))
      (:OPERATOR (!FILE-OUT-READING-PLAN-AND-INSPECTION-FUNCTIONS ?PDF)
       ((LIVE-LISP-TOPIC-MAP-MATERIALIZED ?PDF)) NIL
       ((READING-PLAN-FILED-OUT ?PDF)))
      (:OPERATOR (!PERSIST-READING-PLAN-TO-DMX-SQLITE ?PDF)
       ((READING-PLAN-FILED-OUT ?PDF)) NIL
       ((READING-PLAN-PERSISTED-TO-DMX-SQLITE ?PDF)))
      (:OPERATOR (!VERIFY-OFFLINE-DMX-SQLITE-READABILITY ?PDF)
       ((READING-PLAN-PERSISTED-TO-DMX-SQLITE ?PDF)) NIL
       ((OFFLINE-DMX-SQLITE-READABLE ?PDF)))
      (:OPERATOR (!SELECT-NEXT-READING-TASK ?PDF)
       ((OFFLINE-DMX-SQLITE-READABLE ?PDF)) NIL
       ((NEXT-READING-TASK-SELECTED ?PDF)))
      (:METHOD (!READ-PDF-AS-HYPERDOC-WEB ?PDF) NIL
       ((!RECORD-SOURCE-IDENTITY ?PDF) (!FINGERPRINT-PDF-SOURCE ?PDF)
        (!SEGMENT-PDF-INTO-PAGE-RANGE-UNITS ?PDF)
        (!EXTRACT-READABLE-TEXT-AND-LAYOUT-CANDIDATES ?PDF)
        (!SELECT-READING-QUESTIONS GOLDBERG-PROGRAMMER-AS-READER)
        (!CUT-UP-INTO-JARGON-FRAGMENTS ?PDF)
        (!DERIVE-TOPIC-CANDIDATES-FROM-FRAGMENTS ?PDF)
        (!DERIVE-ASSOCIATIONS-BETWEEN-TOPICS ?PDF)
        (!RELATE-FRAGMENTS-TO-SOURCE-PAGES ?PDF)
        (!MATERIALIZE-READING-TOPIC-MAP-IN-LIVE-LISP ?PDF)
        (!FILE-OUT-READING-PLAN-AND-INSPECTION-FUNCTIONS ?PDF)
        (!PERSIST-READING-PLAN-TO-DMX-SQLITE ?PDF)
        (!VERIFY-OFFLINE-DMX-SQLITE-READABILITY ?PDF)
        (!SELECT-NEXT-READING-TASK ?PDF)))))
    :SHOP3-PROBLEM
    (DEFPROBLEM ZETTEL-9124-PDF-READING-PROBLEM ZETTEL-9124-PDF-READING
     ((PDF CURRENT-PDF-SOURCE) (EPISODE ZETTEL-9124) (AIM HOW-TO-READ-A-WEB))
     ((!READ-PDF-AS-HYPERDOC-WEB CURRENT-PDF-SOURCE)))
    :SELECTED-SHOP3-PLAN
    ((!RECORD-SOURCE-IDENTITY CURRENT-PDF-SOURCE)
     (!FINGERPRINT-PDF-SOURCE CURRENT-PDF-SOURCE)
     (!SEGMENT-PDF-INTO-PAGE-RANGE-UNITS CURRENT-PDF-SOURCE)
     (!EXTRACT-READABLE-TEXT-AND-LAYOUT-CANDIDATES CURRENT-PDF-SOURCE)
     (!SELECT-READING-QUESTIONS GOLDBERG-PROGRAMMER-AS-READER)
     (!CUT-UP-INTO-JARGON-FRAGMENTS CURRENT-PDF-SOURCE)
     (!DERIVE-TOPIC-CANDIDATES-FROM-FRAGMENTS CURRENT-PDF-SOURCE)
     (!DERIVE-ASSOCIATIONS-BETWEEN-TOPICS CURRENT-PDF-SOURCE)
     (!RELATE-FRAGMENTS-TO-SOURCE-PAGES CURRENT-PDF-SOURCE)
     (!MATERIALIZE-READING-TOPIC-MAP-IN-LIVE-LISP CURRENT-PDF-SOURCE)
     (!FILE-OUT-READING-PLAN-AND-INSPECTION-FUNCTIONS CURRENT-PDF-SOURCE)
     (!PERSIST-READING-PLAN-TO-DMX-SQLITE CURRENT-PDF-SOURCE)
     (!VERIFY-OFFLINE-DMX-SQLITE-READABILITY CURRENT-PDF-SOURCE)
     (!SELECT-NEXT-READING-TASK CURRENT-PDF-SOURCE))
    :SHOP3-MANUAL-FUNCTION-LINK-POLICY
    (:COVERAGE :COMPLETE-REQUIRED :KNOWN-SEED-FUNCTIONS
     ((:SYMBOL "SHOP3:FIND-PLANS" :MANUAL-ROLE
       :SINGLE-PROBLEM-PLANNER-ENTRYPOINT :LIVE-LISP-LINK
       "(find-symbol \"FIND-PLANS\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:find-plans")
      (:SYMBOL "SHOP3:FIND-PLANS-STACK" :MANUAL-ROLE
       :SINGLE-PROBLEM-STACK-PLANNER-ENTRYPOINT :LIVE-LISP-LINK
       "(find-symbol \"FIND-PLANS-STACK\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:find-plans-stack")
      (:SYMBOL "SHOP3:DO-PROBLEMS" :MANUAL-ROLE :PROBLEM-SET-PLANNER-ENTRYPOINT
       :LIVE-LISP-LINK "(find-symbol \"DO-PROBLEMS\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:do-problems")
      (:SYMBOL "SHOP3:SHOP-TRACE" :MANUAL-ROLE :DEBUG-TRACING-ENTRYPOINT
       :LIVE-LISP-LINK "(find-symbol \"SHOP-TRACE\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:shop-trace")
      (:SYMBOL "SHOP3:SHOP-UNTRACE" :MANUAL-ROLE :DEBUG-TRACING-ENTRYPOINT
       :LIVE-LISP-LINK "(find-symbol \"SHOP-UNTRACE\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:shop-untrace")
      (:SYMBOL "SHOP3:SHORTER-PLAN" :MANUAL-ROLE :PLAN-RESULT-SIMPLIFICATION
       :LIVE-LISP-LINK "(find-symbol \"SHORTER-PLAN\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:shorter-plan")
      (:SYMBOL "DEFDOMAIN" :MANUAL-ROLE :DOMAIN-DEFINITION-FORM :LIVE-LISP-LINK
       "(find-symbol \"DEFDOMAIN\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:defdomain")
      (:SYMBOL "DEFPROBLEM" :MANUAL-ROLE :PROBLEM-DEFINITION-FORM
       :LIVE-LISP-LINK "(find-symbol \"DEFPROBLEM\" \"SHOP3\")" :DMX-TOPIC-ID
       "shop3:function:defproblem"))
     :NEXT-REQUIRED-TASK
     (!HARVEST-SHOP3-MANUAL-FUNCTION-INDEX-AND-CLOSE-COVERAGE :SOURCE
      "https://shop-planner.github.io/"
      :MUST-LINK-ALL-MANUAL-DOCUMENTED-FUNCTIONS T))
    :DMX-TOPICS
    ((:ID "plan:zettel-9124-pdf-reading-as-web" :TYPE "hyperdoc.plan.htn_shop3"
      :TITLE "Zettel 9124 PDF reading as How to Read a Web")
     (:ID "episode:zettel-9124-live-image-file-out" :TYPE "hyperdoc.episode"
      :TITLE "Zettel 9124 live-image/file-out episode")
     (:ID "concept:how-to-read-a-web-analogy" :TYPE "hyperdoc.concept" :TITLE
      "How to Read a Web as organizing analogy")
     (:ID "store:dmx-sqlite-offline-mirror" :TYPE "hyperdoc.store" :TITLE
      "DMX SQLite offline mirror")
     (:ID "bridge:live-lisp-to-dmx-sqlite" :TYPE "hyperdoc.bridge" :TITLE
      "Live Lisp image to DMX SQLite bridge"))
    :DMX-ASSOCIATIONS
    ((:ID "assoc:pdf-reading-plan:uses:zettel-9124" :TYPE
      "hyperdoc.assoc.uses_episode" :FROM "plan:zettel-9124-pdf-reading-as-web"
      :TO "episode:zettel-9124-live-image-file-out")
     (:ID "assoc:pdf-reading-plan:organized-by:how-to-read-a-web" :TYPE
      "hyperdoc.assoc.organized_by" :FROM "plan:zettel-9124-pdf-reading-as-web"
      :TO "concept:how-to-read-a-web-analogy")
     (:ID "assoc:pdf-reading-plan:persisted-in:dmx-sqlite" :TYPE
      "hyperdoc.assoc.persisted_in" :FROM "plan:zettel-9124-pdf-reading-as-web"
      :TO "store:dmx-sqlite-offline-mirror")
     (:ID "assoc:live-lisp:mirrors-to:dmx-sqlite" :TYPE
      "hyperdoc.assoc.mirrors_to" :FROM "bridge:live-lisp-to-dmx-sqlite" :TO
      "store:dmx-sqlite-offline-mirror"))))

(DEFUN Z9124-PDF-PLAN-TOPICS ()
  '((:ID "plan:zettel-9124-pdf-reading-as-web" :TYPE "hyperdoc.plan.htn_shop3"
     :TITLE "Zettel 9124 PDF reading as How to Read a Web")
    (:ID "episode:zettel-9124-live-image-file-out" :TYPE "hyperdoc.episode"
     :TITLE "Zettel 9124 live-image/file-out episode")
    (:ID "concept:how-to-read-a-web-analogy" :TYPE "hyperdoc.concept" :TITLE
     "How to Read a Web as organizing analogy")
    (:ID "store:dmx-sqlite-offline-mirror" :TYPE "hyperdoc.store" :TITLE
     "DMX SQLite offline mirror")
    (:ID "bridge:live-lisp-to-dmx-sqlite" :TYPE "hyperdoc.bridge" :TITLE
     "Live Lisp image to DMX SQLite bridge")
    (:ID "shop3:function:find-plans" :TYPE #1="shop3.manual.function" :TITLE
     "SHOP3:FIND-PLANS" :MANUAL-ROLE :SINGLE-PROBLEM-PLANNER-ENTRYPOINT
     :LIVE-LISP-LINK "(find-symbol \"FIND-PLANS\" \"SHOP3\")")
    (:ID "shop3:function:find-plans-stack" :TYPE #1# :TITLE
     "SHOP3:FIND-PLANS-STACK" :MANUAL-ROLE
     :SINGLE-PROBLEM-STACK-PLANNER-ENTRYPOINT :LIVE-LISP-LINK
     "(find-symbol \"FIND-PLANS-STACK\" \"SHOP3\")")
    (:ID "shop3:function:do-problems" :TYPE #1# :TITLE "SHOP3:DO-PROBLEMS"
     :MANUAL-ROLE :PROBLEM-SET-PLANNER-ENTRYPOINT :LIVE-LISP-LINK
     "(find-symbol \"DO-PROBLEMS\" \"SHOP3\")")
    (:ID "shop3:function:shop-trace" :TYPE #1# :TITLE "SHOP3:SHOP-TRACE"
     :MANUAL-ROLE :DEBUG-TRACING-ENTRYPOINT :LIVE-LISP-LINK
     "(find-symbol \"SHOP-TRACE\" \"SHOP3\")")
    (:ID "shop3:function:shop-untrace" :TYPE #1# :TITLE "SHOP3:SHOP-UNTRACE"
     :MANUAL-ROLE :DEBUG-TRACING-ENTRYPOINT :LIVE-LISP-LINK
     "(find-symbol \"SHOP-UNTRACE\" \"SHOP3\")")
    (:ID "shop3:function:shorter-plan" :TYPE #1# :TITLE "SHOP3:SHORTER-PLAN"
     :MANUAL-ROLE :PLAN-RESULT-SIMPLIFICATION :LIVE-LISP-LINK
     "(find-symbol \"SHORTER-PLAN\" \"SHOP3\")")
    (:ID "shop3:function:defdomain" :TYPE #1# :TITLE "DEFDOMAIN" :MANUAL-ROLE
     :DOMAIN-DEFINITION-FORM :LIVE-LISP-LINK
     "(find-symbol \"DEFDOMAIN\" \"SHOP3\")")
    (:ID "shop3:function:defproblem" :TYPE #1# :TITLE "DEFPROBLEM" :MANUAL-ROLE
     :PROBLEM-DEFINITION-FORM :LIVE-LISP-LINK
     "(find-symbol \"DEFPROBLEM\" \"SHOP3\")")))

(DEFUN Z9124-PDF-PLAN-ASSOCIATIONS ()
  '((:ID "assoc:pdf-reading-plan:uses:zettel-9124" :TYPE
     "hyperdoc.assoc.uses_episode" :FROM "plan:zettel-9124-pdf-reading-as-web"
     :TO "episode:zettel-9124-live-image-file-out")
    (:ID "assoc:pdf-reading-plan:organized-by:how-to-read-a-web" :TYPE
     "hyperdoc.assoc.organized_by" :FROM "plan:zettel-9124-pdf-reading-as-web"
     :TO "concept:how-to-read-a-web-analogy")
    (:ID "assoc:pdf-reading-plan:persisted-in:dmx-sqlite" :TYPE
     "hyperdoc.assoc.persisted_in" :FROM "plan:zettel-9124-pdf-reading-as-web"
     :TO "store:dmx-sqlite-offline-mirror")
    (:ID "assoc:live-lisp:mirrors-to:dmx-sqlite" :TYPE
     "hyperdoc.assoc.mirrors_to" :FROM "bridge:live-lisp-to-dmx-sqlite" :TO
     "store:dmx-sqlite-offline-mirror")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:find-plans" :TYPE
     #1="hyperdoc.assoc.links_shop3_manual_function" :FROM
     #2="plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:find-plans")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:find-plans-stack" :TYPE
     #1# :FROM #2# :TO "shop3:function:find-plans-stack")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:do-problems" :TYPE #1#
     :FROM #2# :TO "shop3:function:do-problems")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:shop-trace" :TYPE #1#
     :FROM #2# :TO "shop3:function:shop-trace")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:shop-untrace" :TYPE #1#
     :FROM #2# :TO "shop3:function:shop-untrace")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:shorter-plan" :TYPE #1#
     :FROM #2# :TO "shop3:function:shorter-plan")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:defdomain" :TYPE #1#
     :FROM #2# :TO "shop3:function:defdomain")
    (:ID "assoc:pdf-reading-plan:links-shop3-function:defproblem" :TYPE #1#
     :FROM #2# :TO "shop3:function:defproblem")))

(DEFUN Z9124-PDF-OFFLINE-INSPECTION-SQL ()
  "SELECT local_id, type_uri, value
FROM dmx_sql_object
WHERE local_id LIKE 'plan:zettel-9124-pdf-reading%'
   OR local_id LIKE 'episode:zettel-9124%'
   OR local_id LIKE 'concept:how-to-read-a-web%'
   OR local_id LIKE 'store:dmx-sqlite%'
   OR local_id LIKE 'bridge:live-lisp%'
   OR local_id LIKE 'shop3:function:%'
ORDER BY object_kind, local_id;

SELECT a.local_id AS assoc_id,
       a.type_uri AS assoc_type,
       p1.player_local_id AS from_topic,
       p2.player_local_id AS to_topic
FROM dmx_sql_object a
JOIN dmx_sql_assoc_player p1
  ON p1.assoc_id = a.local_id AND p1.player_no = 1
JOIN dmx_sql_assoc_player p2
  ON p2.assoc_id = a.local_id AND p2.player_no = 2
WHERE a.object_kind = 'assoc'
  AND (a.local_id LIKE 'assoc:pdf-reading-plan:%'
       OR a.local_id = 'assoc:live-lisp:mirrors-to:dmx-sqlite')
ORDER BY a.local_id;")

(DEFUN Z9124-PDF-TOPIC-MAP ()
  (LIST :TOPIC-MAP-ID "topic-map:zettel-9124-pdf-reading-as-web" :PLAN
        *Z9124-PDF-READING-PLAN* :TOPICS (Z9124-PDF-PLAN-TOPICS) :ASSOCIATIONS
        (Z9124-PDF-PLAN-ASSOCIATIONS) :OFFLINE-SQL
        (Z9124-PDF-OFFLINE-INSPECTION-SQL)))
