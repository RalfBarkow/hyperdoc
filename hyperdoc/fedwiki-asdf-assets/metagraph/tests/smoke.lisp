;;;; Smoke tests for metagraph-as-bipartite-graph-json-ld--fluree.

(in-package #:metagraph-as-bipartite-graph-json-ld--fluree/tests)

(defun assert-true (value message)
  (unless value
    (error "Smoke test failed: ~A" message))
  value)

(defun assert-contains (needle haystack message)
  (assert-true (and haystack (search needle haystack :test #'char=))
               (format nil "~A -- missing ~S" message needle)))

(defun run-smoke-tests ()
  (let ((story (mg-conversation-story-topicmap))
        (story-native (mg-conversation-story-topicmap-native))
        (planning (mg-planning-topicmap))
        (planning-native (mg-planning-topicmap-native))
        (contract-native (mg-layer-contract-topicmap-native)))
    (assert-true (= 973197 mg-jsonld-fluree:*source-topic-id*)
                 "source topic id is 973197")
    (assert-true (>= (length (getf story :topics)) 9)
                 "conversation topicmap has expected topics")
    (assert-true (>= (length (getf story :assocs)) 8)
                 "conversation topicmap has expected associations")
    (assert-true (mg-native-topicmap-p story-native)
                 "conversation native topicmap has native shape")
    (assert-true (mg-native-topicmap-p planning-native)
                 "planning native topicmap has native shape")
    (assert-true (mg-native-topicmap-p contract-native)
                 "layer contract native topicmap has native shape")
    (assert-true (= 3 (length (mg-topics-by-layer planning :s)))
                 "planning example has three S-nodes")
    (assert-true (mg-topic-neighborhood planning 208)
                 "causal E-node has an inspectable neighborhood")
    (let* ((projection (mg-topicmap-projection :planning-example))
           (html (mg-rendered-topicmap-html projection)))
      (assert-true (typep projection 'mg-topicmap-projection)
                   "planning projection is a first-class object")
      (assert-contains "class=\"dm6-hyperdoc-map dm6-island\""
                       html
                       "rendered projection contains the DM6 island class")
      (assert-contains "class=\"dm6-stored\""
                       html
                       "rendered projection contains the stored JSON script")
      (assert-contains "data-dm6-bundle=\"/assets/dm6-elm/app.js\""
                       html
                       "rendered projection uses the root-relative AppEmbed bundle")
      (assert-contains "/assets/dm6-elm/hyperdoc-dm6-inline.js"
                       html
                       "rendered projection uses the root-relative inline bridge")
      (assert-true (fboundp 'mg-ensure-inspector-views)
                   "inspector view installer is available")
      (assert-true (fboundp 'mg-inspect-rendered-topicmap)
                   "rendered topicmap inspector entry point is available"))
    (let ((written (mg-write-all-rendered-topicmaps)))
      (assert-true (= 3 (length written))
                   "all three rendered Topic Map pages are written")
      (dolist (pathname written)
        (assert-true (probe-file pathname)
                     (format nil "rendered page exists: ~A" pathname))))
    (list :ok t
          :report (mg-installation-report))))
