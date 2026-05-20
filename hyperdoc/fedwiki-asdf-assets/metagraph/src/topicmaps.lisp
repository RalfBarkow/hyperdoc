;;;; Inspectable N/E/S topicmaps for the Metagraph JSON-LD + Fluree page.

(in-package #:metagraph-as-bipartite-graph-json-ld--fluree)

(defparameter *source-topic-id* 973197)
(defparameter *source-title* "Metagraph as Bipartite Graph: JSON-LD + Fluree")

(defun mg-array (items)
  (coerce items 'vector))

(defun mg-size (width height)
  `(("w" . ,width)
    ("h" . ,height)))

(defun mg-topic-width (label)
  (min 420 (max 150 (+ 56 (* 7 (min (length label) 48))))))

(defun mg-layer-icon (layer)
  (ecase layer
    (:n "circle")
    (:e "diamond")
    (:s "rectangle")
    (:artifact "document")
    (:meta "hexagon")))

(defun mg-topic (id label &key layer kind x y summary icon)
  (list :id id
        :label label
        :layer layer
        :kind kind
        :x x
        :y y
        :summary summary
        :icon (or icon (mg-layer-icon layer))))

(defun mg-assoc (id from to &key type role label summary)
  (list :id id
        :from from
        :to to
        :type (or type "Association")
        :role role
        :label label
        :summary summary))

(defun mg-topic-id (topic)
  (getf topic :id))

(defun mg-assoc-id (assoc)
  (getf assoc :id))

(defun mg-find-topic (topic-id topics)
  (find topic-id topics :key #'mg-topic-id :test #'=))

(defun mg-assoc-ids-for-topic (topic-id assocs)
  (loop for assoc in assocs
        when (or (= topic-id (getf assoc :from))
                 (= topic-id (getf assoc :to)))
          collect (mg-assoc-id assoc)))

(defun mg-native-topic (topic assocs)
  (let* ((id (mg-topic-id topic))
         (label (getf topic :label))
         (assoc-ids (sort (copy-list (mg-assoc-ids-for-topic id assocs)) #'<))
         (size (mg-size (mg-topic-width label) 44)))
    `(("id" . ,id)
      ("icon" . ,(getf topic :icon))
      ("text" . ,label)
      ("size" . (("view" . ,size)
                  ("editor" . ,size)))
      ("assocIds" . ,(mg-array assoc-ids)))))

(defun mg-native-assoc (assoc)
  `(("id" . ,(mg-assoc-id assoc))
    ("type" . ,(getf assoc :type))
    ("topicId1" . ,(getf assoc :from))
    ("topicId2" . ,(getf assoc :to))))

(defun mg-native-item (topic)
  `(("topicId" . ,(mg-topic-id topic))))

(defun mg-native-box-topic (topic)
  `(("id" . ,(mg-topic-id topic))
    ("expansion" . "Collapsed")))

(defun mg-native-position (topic)
  `(("id" . ,(mg-topic-id topic))
    ("pos" . (("x" . ,(getf topic :x))
              ("y" . ,(getf topic :y))))))

(defun mg-semantic-topicmap->native (semantic-topicmap)
  (let* ((title (getf semantic-topicmap :title))
         (topics (getf semantic-topicmap :topics))
         (assocs (getf semantic-topicmap :assocs))
         (canvas-width (or (getf semantic-topicmap :width) 1400))
         (canvas-height (or (getf semantic-topicmap :height) 860))
         (max-topic-id (if topics (reduce #'max topics :key #'mg-topic-id) 0))
         (max-assoc-id (if assocs (reduce #'max assocs :key #'mg-assoc-id) max-topic-id))
         (topic-order (mapcar #'mg-topic-id topics)))
    `(("title" . ,title)
      ("sourceTopicId" . ,*source-topic-id*)
      ("topics" . ,(mg-array (mapcar (lambda (topic)
                                        (mg-native-topic topic assocs))
                                      topics)))
      ("assocs" . ,(mg-array (mapcar #'mg-native-assoc assocs)))
      ("itemSets" . ,(mg-array
                      (list `(("id" . 1)
                              ("items" . ,(mg-array
                                            (mapcar #'mg-native-item topics)))))))
      ("boxes" . ,(mg-array
                   (list `(("id" . 0)
                           ("itemSetId" . 1)
                           ("topics" . ,(mg-array
                                          (mapcar #'mg-native-box-topic topics)))
                           ("renderer" . "TopicMap")))))
      ("boxId" . 0)
      ("nextId" . ,(1+ max-assoc-id))
      ("topicMap" . (("viewProps" . ,(mg-array
                                      (list
                                       `(("id" . 0)
                                         ("rect" . (("x1" . 0)
                                                    ("y1" . 0)
                                                    ("x2" . ,canvas-width)
                                                    ("y2" . ,canvas-height)))
                                         ("scroll" . (("x" . 0)
                                                      ("y" . 0)))
                                         ("topics" . ,(mg-array
                                                       (mapcar #'mg-native-position
                                                               topics)))))))))
      ("topicList" . (("viewProps" . ,(mg-array
                                       (list
                                        `(("id" . 0)
                                          ("order" . ,(mg-array topic-order))
                                          ("size" . (("w" . ,canvas-width)
                                                     ("h" . ,canvas-height)))))))))
      ("tool" . (("lineStyle" . "Cornered"))))))

(defun mg-layer-contract-topicmap ()
  (let ((topics
          (list
           (mg-topic 101 "N-node: entity" :layer :n :kind "Layer" :x 100 :y 170
                     :summary "People, projects, milestones, artifacts, and ordinary referents.")
           (mg-topic 102 "E-node: event or relationship" :layer :e :kind "Layer" :x 470 :y 170
                     :summary "A relationship promoted to a first-class inspectable node.")
           (mg-topic 103 "S-node: context or episode" :layer :s :kind "Layer" :x 900 :y 170
                     :summary "A named graph, episode, provenance context, or ledger scope.")
           (mg-topic 104 "Forbidden shortcut: direct N-to-N relation" :layer :e :kind "Constraint" :x 250 :y 430
                     :summary "Important relations must not disappear into a bare entity-to-entity edge.")
           (mg-topic 105 "Repair: lay an E-node route" :layer :e :kind "Repair" :x 720 :y 430
                     :summary "Make the relation attributable, temporal, contextual, and inspectable.")))
        (assocs
          (list
           (mg-assoc 1001 101 102 :type "MEMBER_OF" :role "participant")
           (mg-assoc 1002 102 101 :type "REFERENCES" :role "referent")
           (mg-assoc 1003 102 103 :type "PART_OF" :role "context")
           (mg-assoc 1004 103 102 :type "CONTAINS" :role "member")
           (mg-assoc 1005 103 103 :type "RELATES_TO" :role "context-link")
           (mg-assoc 1006 104 105 :type "REPAIR_BY" :role "modeling-move"))))
    (list :title "Metagraph N/E/S Layer Contract"
          :width 1300
          :height 760
          :topics topics
          :assocs assocs)))

(defun mg-planning-topicmap ()
  (let ((topics
          (list
           (mg-topic 201 "Alice" :layer :n :kind "Person" :x 80 :y 120)
           (mg-topic 202 "Bob" :layer :n :kind "Person" :x 80 :y 230)
           (mg-topic 203 "Carol" :layer :n :kind "Person" :x 80 :y 340)
           (mg-topic 204 "Project Horizon" :layer :n :kind "Project" :x 80 :y 470)
           (mg-topic 205 "Q2 Product Launch" :layer :n :kind "Milestone" :x 80 :y 590)
           (mg-topic 206 "Q2 Planning Meeting" :layer :e :kind "Event" :x 470 :y 170)
           (mg-topic 207 "Decision: Accelerate Q2" :layer :e :kind "Decision" :x 470 :y 350)
           (mg-topic 208 "Causal link: meeting caused decision" :layer :e :kind "Causality" :x 470 :y 540)
           (mg-topic 209 "Q2 Planning Episode" :layer :s :kind "Episode" :x 930 :y 230)
           (mg-topic 210 "Bob's Meeting Notes" :layer :s :kind "NamedGraph" :x 930 :y 410)
           (mg-topic 211 "Fluree Ledger: metagraph/planning" :layer :s :kind "Ledger" :x 930 :y 590)))
        (assocs
          (list
           (mg-assoc 2001 201 206 :type "MEMBER_OF" :role "facilitator")
           (mg-assoc 2002 202 206 :type "MEMBER_OF" :role "presenter")
           (mg-assoc 2003 203 206 :type "MEMBER_OF" :role "decision-maker")
           (mg-assoc 2004 203 207 :type "MEMBER_OF" :role "authority")
           (mg-assoc 2005 204 206 :type "SUBJECT_OF" :role "project")
           (mg-assoc 2006 205 207 :type "TARGET_OF" :role "milestone")
           (mg-assoc 2007 206 208 :type "MEMBER_OF" :role "cause")
           (mg-assoc 2008 207 208 :type "MEMBER_OF" :role "effect")
           (mg-assoc 2009 206 209 :type "PART_OF" :role "event-context")
           (mg-assoc 2010 207 209 :type "PART_OF" :role "decision-context")
           (mg-assoc 2011 208 209 :type "PART_OF" :role "causal-context")
           (mg-assoc 2012 210 209 :type "RELATES_TO" :role "observer-notes")
           (mg-assoc 2013 209 211 :type "RECORDED_IN" :role "ledger-history"))))
    (list :title "Metagraph as N/E/S Topicmap: Q2 Planning"
          :width 1400
          :height 840
          :topics topics
          :assocs assocs)))

(defun mg-conversation-story-topicmap ()
  (let ((topics
          (list
           (mg-topic 973197 "DMX topic 973197: Metagraph as Bipartite Graph" :layer :s :kind "SourceTopic" :x 80 :y 90)
           (mg-topic 302 "Expectation: ASDF asset is source of truth" :layer :meta :kind "Expectation" :x 80 :y 230)
           (mg-topic 303 "Old ZIP/download/unzip loop" :layer :artifact :kind "Failure" :x 440 :y 90)
           (mg-topic 304 "HyperDoc-native ASDF writer" :layer :artifact :kind "Builder" :x 440 :y 230)
           (mg-topic 305 "Exact-path ASDF load" :layer :artifact :kind "LoadBoundary" :x 440 :y 370)
           (mg-topic 306 "Smoke tests in running image" :layer :artifact :kind "Validation" :x 800 :y 120)
           (mg-topic 307 "CLOG inspector Topic Map tab" :layer :artifact :kind "Inspector" :x 800 :y 280)
           (mg-topic 308 "Rendered DM6 pages" :layer :artifact :kind "HTML" :x 800 :y 440)
           (mg-topic 309 "Deployable ZIP output" :layer :artifact :kind "Archive" :x 1160 :y 180)
           (mg-topic 310 "FedWiki page assets directory" :layer :s :kind "Target" :x 1160 :y 340)))
        (assocs
          (list
           (mg-assoc 3001 973197 302 :type "ANCHORS" :role "source")
           (mg-assoc 3002 302 303 :type "DISAPPOINTED_BY" :role "stale-helper")
           (mg-assoc 3003 303 304 :type "REPLACED_BY" :role "workflow-repair")
           (mg-assoc 3004 304 305 :type "MATERIALIZES" :role "asd-file")
           (mg-assoc 3005 305 306 :type "VALIDATED_BY" :role "same-image-test")
           (mg-assoc 3006 306 307 :type "INSPECTED_AS" :role "projection-object")
           (mg-assoc 3007 307 308 :type "RENDERED_AS" :role "dm6-appembed")
           (mg-assoc 3008 308 309 :type "SERIALIZED_AS" :role "post-check-output")
           (mg-assoc 3009 309 310 :type "DEPLOYABLE_TO" :role "fedwiki-assets"))))
    (list :title "Conversation Story: Metagraph ASDF Asset Workflow"
          :width 1500
          :height 760
          :topics topics
          :assocs assocs)))

(defun mg-layer-contract-topicmap-native ()
  (mg-semantic-topicmap->native (mg-layer-contract-topicmap)))

(defun mg-planning-topicmap-native ()
  (mg-semantic-topicmap->native (mg-planning-topicmap)))

(defun mg-conversation-story-topicmap-native ()
  (mg-semantic-topicmap->native (mg-conversation-story-topicmap)))

(defun mg-all-topicmaps ()
  `((:conversation-story . ,(mg-conversation-story-topicmap))
    (:layer-contract . ,(mg-layer-contract-topicmap))
    (:planning-example . ,(mg-planning-topicmap))))

(defun mg-all-topicmaps-native ()
  `((:conversation-story . ,(mg-conversation-story-topicmap-native))
    (:layer-contract . ,(mg-layer-contract-topicmap-native))
    (:planning-example . ,(mg-planning-topicmap-native))))

(defun mg-topics-by-layer (semantic-topicmap layer)
  (remove-if-not (lambda (topic)
                   (eq (getf topic :layer) layer))
                 (getf semantic-topicmap :topics)))

(defun mg-assocs-touching-topic (semantic-topicmap topic-id)
  (remove-if-not
   (lambda (assoc)
     (or (= topic-id (getf assoc :from))
         (= topic-id (getf assoc :to))))
   (getf semantic-topicmap :assocs)))

(defun mg-topic-neighborhood (semantic-topicmap topic-id)
  (let* ((topics (getf semantic-topicmap :topics))
         (center (mg-find-topic topic-id topics))
         (assocs (mg-assocs-touching-topic semantic-topicmap topic-id))
         (neighbor-ids
           (remove-duplicates
            (loop for assoc in assocs
                  append (list (getf assoc :from)
                               (getf assoc :to)))
            :test #'=)))
    (list :center center
          :associations assocs
          :neighbors (mapcar (lambda (id)
                               (mg-find-topic id topics))
                             neighbor-ids))))

(defun mg-native-topicmap-p (object)
  (and (consp object)
       (assoc "topics" object :test #'equal)
       (assoc "assocs" object :test #'equal)
       (assoc "itemSets" object :test #'equal)
       (assoc "boxes" object :test #'equal)
       (assoc "topicMap" object :test #'equal)
       (assoc "topicList" object :test #'equal)
       (assoc "tool" object :test #'equal)))

(defun mg-write-native-topicmap (pathname &key (which :conversation-story))
  (let ((object (ecase which
                  (:conversation-story (mg-conversation-story-topicmap-native))
                  (:planning-example (mg-planning-topicmap-native))
                  (:layer-contract (mg-layer-contract-topicmap-native)))))
    (ensure-directories-exist pathname)
    (with-open-file (stream pathname
                            :direction :output
                            :if-exists :supersede
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (let ((*print-pretty* t)
            (*print-circle* nil))
        (pprint object stream)
        (terpri stream)))
    pathname))
