;;;; Focused smoke tests for DM6 page-local topicmap seeds.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-DM6-PAGE-TOPICMAP-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun dm6-page-topicmap-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun dm6-page-topicmap-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun dm6-page-topicmap-assert-contains (needle haystack message)
  (unless (search needle haystack :test #'char=)
    (error "~A -- missing substring: ~S" message needle)))

(defun dm6-page-topicmap-json (text)
  (with-input-from-string (stream text)
    (shasht:read-json stream)))

(defun dm6-page-topicmap-field (object key)
  (and (hash-table-p object)
       (gethash key object)))

(defun dm6-page-topicmap-list (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (list value))))

(defun dm6-page-topicmap-synthetic-html ()
  "<h1>Synthetic DM6 seed fixture</h1>
   <p>Intro paragraph.</p>
   <script type=\"application/json\" class=\"dm6-stored\" data-dm6-generated=\"page-parse-tree-v1\">{\"topics\":[{\"text\":\"SHOULD-NOT-APPEAR\"}]}</script>
   <section class=\"dm6-hyperdoc-map dm6-island\" data-dm6-slug=\"synthetic-proof\">
     <header><h2>DM6 Topic Map</h2></header>
     <nav>Select Move Cross Fit Reset Evidence</nav>
     <details><summary>Evidence timeline</summary><p>Events appear here.</p></details>
   </section>
   <script src=\"/assets/dm6-elm/app.js\"></script>")

(defun dm6-page-topicmap-synthetic-dom ()
  (let ((plump:*tag-dispatchers* plump:*html-tags*))
    (plump:parse (dm6-page-topicmap-synthetic-html))))

(defun dm6-page-topicmap-model-from-synthetic-json ()
  (multiple-value-bind (json)
      (hyperdoc:page-dm6-topicmap-json
       (dm6-page-topicmap-synthetic-dom)
       :page-title "Synthetic DM6 seed fixture")
    (dm6-page-topicmap-json json)))

(defun dm6-page-topicmap-topic-texts (model)
  (mapcar (lambda (topic)
            (dm6-page-topicmap-field topic "text"))
          (dm6-page-topicmap-list
           (dm6-page-topicmap-field model "topics"))))

(defun dm6-page-topicmap-assoc-signatures (model)
  (mapcar (lambda (assoc)
            (list (dm6-page-topicmap-field assoc "id")
                  (dm6-page-topicmap-field assoc "type")
                  (dm6-page-topicmap-field assoc "topicId1")
                  (dm6-page-topicmap-field assoc "topicId2")))
          (dm6-page-topicmap-list
           (dm6-page-topicmap-field model "assocs"))))

(defun dm6-page-topicmap-max-id (objects)
  (reduce #'max
          (mapcar (lambda (object)
                    (dm6-page-topicmap-field object "id"))
                  objects)
          :initial-value 0))

(defun run-dm6-page-topicmap-native-shape-smoke-test ()
  (let* ((model (dm6-page-topicmap-model-from-synthetic-json))
         (topics (dm6-page-topicmap-list
                  (dm6-page-topicmap-field model "topics")))
         (assocs (dm6-page-topicmap-list
                  (dm6-page-topicmap-field model "assocs")))
         (item-sets (dm6-page-topicmap-list
                     (dm6-page-topicmap-field model "itemSets")))
         (boxes (dm6-page-topicmap-list
                 (dm6-page-topicmap-field model "boxes")))
         (topic-map (dm6-page-topicmap-field model "topicMap"))
         (topic-list (dm6-page-topicmap-field model "topicList"))
         (tool (dm6-page-topicmap-field model "tool")))
    (dolist (pair `(("topics" . ,topics)
                    ("assocs" . ,assocs)
                    ("itemSets" . ,item-sets)
                    ("boxes" . ,boxes)
                    ("topicMap" . ,topic-map)
                    ("topicList" . ,topic-list)
                    ("tool" . ,tool)))
      (dm6-page-topicmap-assert-true
       (cdr pair)
       (format nil "Synthetic native model must contain non-empty ~A"
               (car pair))))
    (dm6-page-topicmap-assert-equal
     "TopicMap"
     (dm6-page-topicmap-field (first boxes) "renderer")
     "Generated model must use the TopicMap renderer")
    (dm6-page-topicmap-assert-equal
     "Cornered"
     (dm6-page-topicmap-field tool "lineStyle")
     "Generated model must preserve the current tool lineStyle shape")))

(defun run-dm6-page-topicmap-self-exclusion-smoke-test ()
  (multiple-value-bind (json)
      (hyperdoc:page-dm6-topicmap-json
       (dm6-page-topicmap-synthetic-dom)
       :page-title "Synthetic DM6 seed fixture")
    (dm6-page-topicmap-assert-true
     (not (search "SHOULD-NOT-APPEAR" json :test #'char=))
     "Generated script.dm6-stored content must not become a topic")
    (dm6-page-topicmap-assert-true
     (not (search "assets/dm6-elm/app.js" json :test #'char=))
     "Raw AppEmbed bundle script includes must not become topics")))

(defun run-dm6-page-topicmap-hierarchy-smoke-test ()
  (let* ((model (dm6-page-topicmap-model-from-synthetic-json))
         (assocs (dm6-page-topicmap-assoc-signatures model)))
    (dm6-page-topicmap-assert-equal
     '((10 "Hierarchy" 0 1)
       (11 "Hierarchy" 0 2)
       (12 "Hierarchy" 0 3)
       (13 "Hierarchy" 3 4)
       (14 "Hierarchy" 4 5)
       (15 "Hierarchy" 3 6)
       (16 "Hierarchy" 3 7)
       (17 "Hierarchy" 7 8)
       (18 "Hierarchy" 7 9))
     assocs
     "Hierarchy associations must be deterministic and traversal-derived")))

(defun run-dm6-page-topicmap-next-id-smoke-test ()
  (let* ((model (dm6-page-topicmap-model-from-synthetic-json))
         (topics (dm6-page-topicmap-list
                  (dm6-page-topicmap-field model "topics")))
         (assocs (dm6-page-topicmap-list
                  (dm6-page-topicmap-field model "assocs")))
         (next-id (dm6-page-topicmap-field model "nextId"))
         (max-id (max (dm6-page-topicmap-max-id topics)
                      (dm6-page-topicmap-max-id assocs))))
    (dm6-page-topicmap-assert-true
     (> next-id max-id)
     "nextId must be greater than every generated topic and association id")))

(defun dm6-page-topicmap-proof-path ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/DM6 AppEmbed HyperDoc Inline Proof.html"))

(defun run-dm6-page-topicmap-proof-json-smoke-test ()
  (multiple-value-bind (json)
      (hyperdoc:page-dm6-topicmap-json
       (hyperdoc::page-dm6-topicmap-pathname-dom
        (dm6-page-topicmap-proof-path))
       :page-title "DM6 AppEmbed HyperDoc Inline Proof"
       :source-file (dm6-page-topicmap-proof-path))
    (dolist (expected '("DM6 AppEmbed HyperDoc Inline Proof"
                        "Goal"
                        "Starting situation"
                        "DM6 Topic Map"
                        "Evidence timeline"))
      (dm6-page-topicmap-assert-contains
       expected
       json
       "Proof page generated JSON must include expected page-structure labels"))))

(defun run-dm6-page-topicmap-proof-materialization-smoke-test ()
  (let* ((source (alexandria:read-file-into-string
                  (dm6-page-topicmap-proof-path))))
    (multiple-value-bind (island-start island-end content-start)
        (hyperdoc::page-dm6-topicmap-find-island-range source)
      (declare (ignore island-start))
      (dm6-page-topicmap-assert-true
       island-end
       "Proof page must contain a .dm6-hyperdoc-map.dm6-island section")
      (let ((ranges (hyperdoc::page-dm6-topicmap-script-ranges-in
                     source content-start island-end)))
        (dm6-page-topicmap-assert-equal
         1
         (length ranges)
         "Proof page island must contain exactly one script.dm6-stored")
        (let* ((range (first ranges))
               (script (subseq source (car range) (cdr range)))
               (open-end (position #\> script))
               (close-start (search "</script>" script :test #'char-equal))
               (json (subseq script (1+ open-end) close-start))
               (model (dm6-page-topicmap-json json))
               (boxes (dm6-page-topicmap-list
                       (dm6-page-topicmap-field model "boxes"))))
          (dm6-page-topicmap-assert-contains
           "data-dm6-generated=\"page-parse-tree-v1\""
           script
           "Proof page stored script must carry the generated-seed marker")
          (dm6-page-topicmap-assert-equal
           "TopicMap"
           (dm6-page-topicmap-field (first boxes) "renderer")
           "Materialized proof seed must use the TopicMap renderer"))))))

(defun run-dm6-page-topicmap-smoke-tests ()
  (run-dm6-page-topicmap-native-shape-smoke-test)
  (run-dm6-page-topicmap-self-exclusion-smoke-test)
  (run-dm6-page-topicmap-hierarchy-smoke-test)
  (run-dm6-page-topicmap-next-id-smoke-test)
  (run-dm6-page-topicmap-proof-json-smoke-test)
  (run-dm6-page-topicmap-proof-materialization-smoke-test)
  (format t "~&DM6 page topicmap smoke tests passed.~%")
  t)
