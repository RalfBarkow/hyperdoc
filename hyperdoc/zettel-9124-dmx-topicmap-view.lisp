;;;; Zettel 9124 DMX topic-map view bridge.

(DEFPACKAGE #:HYPERDOC/Z9124-DMX-TOPICMAP-VIEW
  (:USE #:CL)
  (:EXPORT #:*Z9124-DMX-TOPICMAP-VIEW-PLAN*
           #:*Z9124-DMX-TOPICMAP-VIEW-IR*
           #:Z9124-DMX-TOPICMAP-VIEW-PLAN
           #:Z9124-DMX-TOPICMAP-VIEW-IR
           #:Z9124-DMX-TOPICMAP-VIEW-OFFLINE-SQL))

(IN-PACKAGE #:HYPERDOC/Z9124-DMX-TOPICMAP-VIEW)

(DEFPARAMETER *Z9124-DMX-TOPICMAP-VIEW-PLAN*
  '(:TOPIC-ID "task:materialize-zettel-9124-dmx-topicmap-view" :TITLE
    "Materialize Zettel 9124 DMX topic-map view" :KIND :SHOP3-PLANNED-VIEW-TASK
    :STATUS :MATERIALIZED :PARENT-PLAN "plan:zettel-9124-pdf-reading-as-web"
    :SOURCE-DB "var/dmx-associative-mirror.sqlite" :VIEW-TOPIC
    "view:zettel-9124-dmx-topicmap" :DECISION
    (:USE-SHOP3 T :ROLE
     "SHOP3 owns decomposition and next-task choice; the offline view must not depend on a live SHOP3 image.")
    :SHOP3-DOMAIN
    (DEFDOMAIN ZETTEL-9124-DMX-TOPICMAP-VIEW
     ((:OPERATOR (!PROJECT-DMX-SQLITE-TO-TOPICMAP-IR ?DB ?VIEW) NIL NIL
       ((TOPICMAP-IR-PROJECTED ?VIEW)))
      (:OPERATOR (!RENDER-TOPICMAP-IR-AS-LIVE-LISP-VIEW ?VIEW)
       ((TOPICMAP-IR-PROJECTED ?VIEW)) NIL ((LIVE-LISP-VIEW-RENDERED ?VIEW)))
      (:OPERATOR (!RENDER-TOPICMAP-IR-AS-OFFLINE-HTML ?VIEW)
       ((TOPICMAP-IR-PROJECTED ?VIEW)) NIL ((OFFLINE-HTML-RENDERED ?VIEW)))
      (:OPERATOR (!PERSIST-VIEW-TASK-TO-DMX-SQLITE ?VIEW)
       ((TOPICMAP-IR-PROJECTED ?VIEW)) NIL
       ((VIEW-TASK-PERSISTED-TO-DMX-SQLITE ?VIEW)))
      (:OPERATOR (!FILE-OUT-TOPICMAP-VIEW-ARTIFACTS ?VIEW)
       ((LIVE-LISP-VIEW-RENDERED ?VIEW) (OFFLINE-HTML-RENDERED ?VIEW)) NIL
       ((TOPICMAP-VIEW-ARTIFACTS-FILED-OUT ?VIEW)))
      (:METHOD (!MATERIALIZE-DMX-TOPICMAP-VIEW ?DB ?VIEW) NIL
       ((!PROJECT-DMX-SQLITE-TO-TOPICMAP-IR ?DB ?VIEW)
        (!RENDER-TOPICMAP-IR-AS-LIVE-LISP-VIEW ?VIEW)
        (!RENDER-TOPICMAP-IR-AS-OFFLINE-HTML ?VIEW)
        (!PERSIST-VIEW-TASK-TO-DMX-SQLITE ?VIEW)
        (!FILE-OUT-TOPICMAP-VIEW-ARTIFACTS ?VIEW)))))
    :SHOP3-PROBLEM
    (DEFPROBLEM ZETTEL-9124-DMX-TOPICMAP-VIEW-PROBLEM
     ZETTEL-9124-DMX-TOPICMAP-VIEW
     ((DMX-SQLITE "var/dmx-associative-mirror.sqlite")
      (VIEW "view:zettel-9124-dmx-topicmap"))
     ((!MATERIALIZE-DMX-TOPICMAP-VIEW "var/dmx-associative-mirror.sqlite"
       "view:zettel-9124-dmx-topicmap")))
    :SELECTED-SHOP3-PLAN
    ((!PROJECT-DMX-SQLITE-TO-TOPICMAP-IR "var/dmx-associative-mirror.sqlite"
      "view:zettel-9124-dmx-topicmap")
     (!RENDER-TOPICMAP-IR-AS-LIVE-LISP-VIEW "view:zettel-9124-dmx-topicmap")
     (!RENDER-TOPICMAP-IR-AS-OFFLINE-HTML "view:zettel-9124-dmx-topicmap")
     (!PERSIST-VIEW-TASK-TO-DMX-SQLITE "view:zettel-9124-dmx-topicmap")
     (!FILE-OUT-TOPICMAP-VIEW-ARTIFACTS "view:zettel-9124-dmx-topicmap"))))

(DEFPARAMETER *Z9124-DMX-TOPICMAP-VIEW-IR*
  '(:TOPIC-MAP-ID "topic-map:zettel-9124-dmx-sqlite-view" :SOURCE-DB
    "/Users/rgb/workspace/hyperdoc/var/dmx-associative-mirror.sqlite" :TOPICS
    ((:ID "bridge:live-lisp-to-dmx-sqlite" :TYPE "hyperdoc.bridge" :VALUE
      "Live Lisp image to DMX SQLite bridge")
     (:ID "concept:how-to-read-a-web-analogy" :TYPE "hyperdoc.concept" :VALUE
      "How to Read a Web as organizing analogy")
     (:ID "episode:zettel-9124-live-image-file-out" :TYPE "hyperdoc.episode"
      :VALUE "Zettel 9124 live-image/file-out episode")
     (:ID "plan:zettel-9124-pdf-reading-as-web" :TYPE "hyperdoc.plan.htn_shop3"
      :VALUE "Zettel 9124 PDF reading as How to Read a Web")
     (:ID "shop3:function:defdomain" :TYPE "shop3.manual.function" :VALUE
      "DEFDOMAIN")
     (:ID "shop3:function:defproblem" :TYPE "shop3.manual.function" :VALUE
      "DEFPROBLEM")
     (:ID "shop3:function:do-problems" :TYPE "shop3.manual.function" :VALUE
      "SHOP3:DO-PROBLEMS")
     (:ID "shop3:function:find-plans" :TYPE "shop3.manual.function" :VALUE
      "SHOP3:FIND-PLANS")
     (:ID "shop3:function:find-plans-stack" :TYPE "shop3.manual.function"
      :VALUE "SHOP3:FIND-PLANS-STACK")
     (:ID "shop3:function:shop-trace" :TYPE "shop3.manual.function" :VALUE
      "SHOP3:SHOP-TRACE")
     (:ID "shop3:function:shop-untrace" :TYPE "shop3.manual.function" :VALUE
      "SHOP3:SHOP-UNTRACE")
     (:ID "shop3:function:shorter-plan" :TYPE "shop3.manual.function" :VALUE
      "SHOP3:SHORTER-PLAN")
     (:ID "store:dmx-sqlite-offline-mirror" :TYPE "hyperdoc.store" :VALUE
      "DMX SQLite offline mirror"))
    :ASSOCIATIONS
    ((:ID "assoc:live-lisp:mirrors-to:dmx-sqlite" :TYPE
      "hyperdoc.assoc.mirrors_to" :FROM "bridge:live-lisp-to-dmx-sqlite" :TO
      "store:dmx-sqlite-offline-mirror")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:defdomain" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:defdomain")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:defproblem" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:defproblem")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:do-problems" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:do-problems")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:find-plans" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:find-plans")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:find-plans-stack" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO
      "shop3:function:find-plans-stack")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:shop-trace" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:shop-trace")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:shop-untrace" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:shop-untrace")
     (:ID "assoc:pdf-reading-plan:links-shop3-function:shorter-plan" :TYPE
      "hyperdoc.assoc.links_shop3_manual_function" :FROM
      "plan:zettel-9124-pdf-reading-as-web" :TO "shop3:function:shorter-plan")
     (:ID "assoc:pdf-reading-plan:organized-by:how-to-read-a-web" :TYPE
      "hyperdoc.assoc.organized_by" :FROM "plan:zettel-9124-pdf-reading-as-web"
      :TO "concept:how-to-read-a-web-analogy")
     (:ID "assoc:pdf-reading-plan:persisted-in:dmx-sqlite" :TYPE
      "hyperdoc.assoc.persisted_in" :FROM "plan:zettel-9124-pdf-reading-as-web"
      :TO "store:dmx-sqlite-offline-mirror")
     (:ID "assoc:pdf-reading-plan:uses:zettel-9124" :TYPE
      "hyperdoc.assoc.uses_episode" :FROM "plan:zettel-9124-pdf-reading-as-web"
      :TO "episode:zettel-9124-live-image-file-out"))))

(DEFUN Z9124-DMX-TOPICMAP-VIEW-PLAN () *Z9124-DMX-TOPICMAP-VIEW-PLAN*)

(DEFUN Z9124-DMX-TOPICMAP-VIEW-IR () *Z9124-DMX-TOPICMAP-VIEW-IR*)

(DEFUN Z9124-DMX-TOPICMAP-VIEW-OFFLINE-SQL ()
  "SELECT local_id, type_uri, value
FROM dmx_sql_object
WHERE object_kind = 'topic'
  AND (local_id LIKE 'plan:zettel-9124-pdf-reading%'
       OR local_id LIKE 'episode:zettel-9124%'
       OR local_id LIKE 'concept:how-to-read-a-web%'
       OR local_id LIKE 'store:dmx-sqlite%'
       OR local_id LIKE 'bridge:live-lisp%'
       OR local_id LIKE 'shop3:function:%')
ORDER BY local_id;
SELECT a.local_id, a.type_uri, p1.player_local_id, p2.player_local_id
FROM dmx_sql_object a
JOIN dmx_sql_assoc_player p1
  ON p1.assoc_id = a.local_id AND p1.player_no = 1
JOIN dmx_sql_assoc_player p2
  ON p2.assoc_id = a.local_id AND p2.player_no = 2
WHERE a.object_kind = 'assoc'
  AND (a.local_id LIKE 'assoc:pdf-reading-plan:%'
       OR a.local_id = 'assoc:live-lisp:mirrors-to:dmx-sqlite')
ORDER BY a.local_id;")
