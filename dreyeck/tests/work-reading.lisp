(defpackage #:dreyeck/work/tests
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:views #:html-inspector-views)
                    (#:authored #:dreyeck/topicmap/tala/authored)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:sm #:dreyeck/state-machine)
                    (#:m #:dreyeck/inspector/topicmap))
  (:export #:run-tests))
(in-package #:dreyeck/work/tests)

(defun content-view (page)
  (let ((view (find "Content" (views:all-views page)
                    :key #'views:view-title :test #'equal)))
    (assert view)
    (views:view-html view)
    view))

;; Keep the complete authored graph in this regression: a missing edge must not
;; make an endpoint-resolution check pass vacuously. The two informs IDs spell
;; the contract reference because the ID scheme spells whatever the relation is.
(defparameter *expected-work-associations*
  '("work:interaction:work:relation/informs:operations"
    "work:operations:work:relation/informs:connect"
    "work:operations:requires:state"
    "work:dogfooding:develops:corpus"
    "work:planning:models:dogfooding"
    "work:planning:models:corpus"
    "work:planning:observes:operations"
    "work:dogfooding:current-work:connections-example"
    "work:corpus:contains:connections-example"
    "work:connections-example:uses:d2"
    "work:connections-example:demonstrates:connection"
    "work:connections-example:compares-with:association"
    "work:connections-example:raises-question-for:connect"
    "work:connections-example:is-related-in:topicmap"))

(defun check-projection-integrity (projection)
  (let* ((topics (tm:topicmap-projection-topics-of projection))
         (associations (tm:topicmap-projection-associations-of projection))
         (ids (mapcar #'tm:topicmap-association-id-of associations)))
    (assert (= 13 (length topics)))
    (assert (= (length *expected-work-associations*) (length ids)))
    (dolist (id *expected-work-associations*)
      (assert (= 1 (count id ids :test #'equal))))
    (dolist (association associations)
      (dolist (endpoint (list (tm:topicmap-association-from-of association)
                             (tm:topicmap-association-to-of association)))
        (assert (= 1 (count endpoint topics :key #'tm:topicmap-topic-id-of
                                           :test #'equal))
                () "Association ~S endpoint ~S must resolve to exactly one Topic."
                (tm:topicmap-association-id-of association) endpoint)))))

(defun workspace-from-operations-page ()
  ;; EXPR links run inside Content rendering's dynamic tag-dispatcher context.
  ;; HyperDoc stores an evaluation error as a reference, so rendering HTML alone
  ;; is insufficient evidence that the link produced a Workspace.
  (let* ((view (content-view (work:work-page "Operations and Change")))
         (references (mapcar #'cdr (views:view-references view)))
         (workspaces (remove-if-not
                      (lambda (object) (typep object 'tm:topicmap-workspace))
                      references)))
    (assert (notany (lambda (object) (typep object 'condition)) references))
    (assert (= 1 (length workspaces)))
    (first workspaces)))

(defun check-work-projection ()
  (check-projection-integrity (work:work-projection))
  (check-projection-integrity
   (tm:topicmap-projection-of (workspace-from-operations-page))))

(defun check-pages-and-example ()
  (let ((book (hyperbook:find-hyperbook "dreyeck/work/reading" :signal-error? t)))
    (dolist (title '("Work Breakdown" "Interaction" "Operations and Change"
                     "Connect and Associations" "State and Persistence"
                     "HyperDoc Dogfooding" "D2 Corpus" "Planning with SHOP3"
                     "D2 Connections" "Relation Contract: informs"))
      (content-view (hyperbook:find-page book title :signal-error? t)))
    (assert (typep (work:work-page "Working on HyperDoc") 'hyperdoc::code-page))
    ;; The definition must be a real executable Code Page widget, not only prose.
    (let* ((view (content-view (work:work-page "D2 Connections")))
           (widgets (remove-if-not (lambda (ref) (typep (cdr ref) 'views:view))
                                   (views:view-references view))))
      (assert (= 1 (length widgets)))
      (let* ((widget (cdar widgets))
             (html (views:view-html widget))
             (action (find-if (lambda (ref) (typep (cdr ref) 'views:thunk))
                              (views:view-references widget))))
        (assert (search "inspector-action" html))
        (assert action)
        (assert (typep (views:eval-thunk (cdr action)) 'authored:authored-d2)))))
  (let* ((source (work:connections-source))
         (render (work:connections-example))
         (svg (authored:authored-d2-svg render)))
    (assert (string= source (authored:authored-d2-source render)))
    (assert (not (search "&gt;" source)))
    (assert (string= "v0.9.0" (authored:authored-d2-version render)))
    (assert (search "<svg" svg))
    (assert (search "explains" svg))
    (assert (search "compare evidence" svg))
    (assert (find "Authored D2" (views:all-views render)
                  :key #'views:view-title :test #'equal))))

(defun check-native-work-navigation ()
  (let* ((workspace (workspace-from-operations-page))
         (projection (tm:topicmap-projection-of workspace))
         (view (find "Topicmap" (views:all-views workspace)
                     :key #'views:view-title :test #'equal)))
    (assert view)
    (assert (search "dreyeck-topicmap-workspace-action" (views:view-html view)))
    ;; Each informs edge shows the contract label; no sign shows the reference.
    (let ((html (views:view-html view)))
      (dolist (id '("work:interaction:work:relation/informs:operations"
                    "work:operations:work:relation/informs:connect"))
        (let* ((start (search (format nil "data-association-id='~A'" id) html))
               (sign (subseq html start (search "</g>" html :start2 start))))
          (assert (search ">informs</text>" sign))))
      (assert (not (search "work:relation/informs</text>" html)))
      ;; Typed-associations legend rows too. The Topics legend still lists the
      ;; contract Topic under its ID, which is what that column shows.
      (assert (= 2 (count-matches "<tr><td><code>informs</code></td>" html)))
      (assert (not (search "&quot;work:relation/informs&quot;" html))))
    (dolist (entry '(("interaction" "Interaction")
                     ("operations" "Operations and Change")
                     ("connect" "Connect and Associations")
                     ("state" "State and Persistence")
                     ("dogfooding" "HyperDoc Dogfooding")
                     ("corpus" "D2 Corpus")
                     ("planning" "Planning with SHOP3")))
      (let ((topics (remove (first entry) (tm:topicmap-projection-topics-of projection)
                            :key #'tm:topicmap-topic-id-of :test-not #'equal)))
        (assert (= 1 (length topics)))
        (assert (eq (work:work-page (second entry))
                    (tm:topicmap-topic-object-of (first topics))))))
    (dolist (id '("d2" "connection" "association" "connect" "topicmap"))
      (assert (find-if (lambda (a)
                        (and (equal "connections-example" (tm:topicmap-association-from-of a))
                             (equal id (tm:topicmap-association-to-of a))))
                      (tm:topicmap-projection-associations-of projection))))
    (dolist (topic (tm:topicmap-projection-topics-of projection))
      (let* ((old-point (tm:topicmap-workspace-point-of workspace))
             (action (find-if
                      (lambda (ref)
                        (and (typep (cdr ref) 'dreyeck/inspector/topicmap::topic-action-reference)
                             (eq topic (dreyeck/inspector/topicmap::action-topic (cdr ref)))))
                      (views:view-references view)))
             (page (tm:topicmap-topic-object-of topic)))
        (assert action)
        (assert (typep page 'hyperdoc:page))
        (assert (eq topic (views:eval-thunk (cdr action))))
        (assert (eq page (tm:topicmap-workspace-current-object workspace)))
        (let ((updated (find "Topicmap" (views:all-views workspace)
                             :key #'views:view-title :test #'equal)))
          (views:view-html updated)
          (assert (find page (views:view-references updated) :key #'cdr :test #'eq)))
        (assert (equal (tm:topicmap-topic-id-of topic)
                       (tm:topicmap-workspace-point-of workspace)))
        (unless (equal old-point (tm:topicmap-topic-id-of topic))
          (assert (equal old-point (first (tm:topicmap-workspace-history-of workspace)))))))))

(defun check-work-layout ()
  (let* ((projection (work:work-projection :areas-only t))
         (render (work:work-layout-example)))
    (assert (= 7 (length (tm:topicmap-projection-topics-of projection))))
    (assert (= 7 (length (tm:topicmap-projection-associations-of projection))))
    (assert (typep render 'tala:tala-rendering))
    (assert (search "<svg" (tala:tala-rendering-svg render)))
    ;; The seven-area projection omits the contract Topic; the label still
    ;; comes from it, and the D2 identity of each edge stays with its endpoints.
    (let ((source (tala:tala-input-source (tala:tala-rendering-input render))))
      (assert (search "interaction -> operations: \"informs\"" source))
      (assert (search "operations -> connect: \"informs\"" source))
      (assert (not (search "work:relation/" source))))
    (assert (search ">informs</text>" (tala:tala-rendering-svg render)))
    (assert (not (search "work:relation/informs" (tala:tala-rendering-svg render))))
    (assert (equal '("(interaction -> operations)[0]" "(operations -> connect)[0]")
                   (loop for entry in (tala:tala-input-associations
                                       (tala:tala-rendering-input render))
                         when (search "work:relation/informs" (getf entry :id))
                           collect (getf entry :d2-id))))))

;;;; Relation Contract: informs

(defparameter *informs* "work:relation/informs")

(defun work-breakdown-source ()
  (uiop:read-file-string (hyperdoc:file-of (work:work-page "Work Breakdown"))))

(defun replace-once (string old new)
  "STRING with its one occurrence of OLD replaced; a fixture edit that misses fails."
  (let ((start (search old string)))
    (assert start () "Fixture text ~S is absent." old)
    (assert (not (search old string :start2 (1+ start))) ()
            "Fixture text ~S is ambiguous." old)
    (concatenate 'string (subseq string 0 start) new
                 (subseq string (+ start (length old))))))

(defun fixture-projection (html &rest keys)
  (apply #'work:project-work-breakdown html :source :fixture keys))

(defun association-between (projection from to)
  (let ((matches (remove-if-not
                  (lambda (a) (and (equal from (tm:topicmap-association-from-of a))
                                   (equal to (tm:topicmap-association-to-of a))))
                  (tm:topicmap-projection-associations-of projection))))
    (assert (= 1 (length matches)))
    (first matches)))

(defun informs-associations (projection)
  (list (association-between projection "interaction" "operations")
        (association-between projection "operations" "connect")))

(defun association-ids (projection)
  (mapcar #'tm:topicmap-association-id-of
          (tm:topicmap-projection-associations-of projection)))

(defun d2-edge-label (projection from to)
  (let* ((source (tala:tala-input-source (tala:projection-tala-input projection)))
         (prefix (format nil "~A -> ~A: " from to))
         (start (search prefix source)))
    (assert start)
    (subseq source (+ start (length prefix)) (position #\Newline source :start start))))

(defun check-relation-contract ()
  (let* ((projection (work:work-projection))
         (contract (tm:topicmap-projection-topic-by-id projection *informs*))
         (page (tm:topicmap-topic-object-of contract))
         (informs (informs-associations projection)))
    ;; Identity, label and meaning are three things.
    (assert (equal "informs" (tm:topicmap-topic-label-of contract)))
    (assert (equal "relation" (getf (tm:topicmap-topic-view-properties-of contract) :kind)))
    (assert (eq page (work:work-page "Relation Contract: informs")))
    (assert (not (equal *informs* (hyperbook:id-of page))))
    ;; Two distinct Associations refer to the one contract.
    (assert (not (eq (first informs) (second informs))))
    (dolist (association informs)
      (assert (equal *informs* (tm:topicmap-association-type-of association)))
      ;; The resolved Topic is derived: it is the projection's own contract
      ;; Topic, and the label is read from it rather than copied.
      (assert (eq contract (getf (tm:topicmap-association-properties-of association)
                                 :relation-contract)))
      (assert (equal "informs" (tm:topicmap-association-relation-label association))))
    ;; Other relations remain plain strings with nothing resolved.
    (let ((requires (association-between projection "operations" "state")))
      (assert (equal "requires" (tm:topicmap-association-type-of requires)))
      (assert (null (tm:topicmap-association-relation-label requires))))
    ;; Uses: exactly the two informs Associations, by EQUAL.
    (let ((uses (work:relation-uses projection *informs*)))
      (assert (= 2 (length uses)))
      (assert (every (lambda (a) (member a uses :test #'eq)) informs)))
    (assert (null (work:relation-uses projection (copy-seq "informs"))))
    ;; The seven-area projection leaves the contract Topic out and still resolves.
    (let ((areas (work:work-projection :areas-only t)))
      (assert (null (tm:topicmap-projection-topic-by-id areas *informs*)))
      (dolist (association (informs-associations areas))
        (assert (equal "informs" (tm:topicmap-association-relation-label association)))))))

(defun check-relation-reference-integrity ()
  (let ((source (work-breakdown-source))
        (anchor "data-topic=\"work:relation/informs\" data-kind=\"relation\""))
    (flet ((refused (html &rest keys)
             (handler-case (progn (apply #'fixture-projection html keys) nil)
               (work:relation-contract-reference-error (condition) condition))))
      ;; Missing contract Topic, in both projections.
      (let ((missing (replace-once source anchor
                                   "data-topic=\"work:relation/absent\" data-kind=\"relation\"")))
        (dolist (areas-only '(nil t))
          (let ((condition (refused missing :areas-only areas-only)))
            (assert condition)
            (assert (equal *informs* (work::reference-of condition)))
            (assert (null (work::matches-of condition)))
            (assert (search "0 Topics" (princ-to-string condition))))))
      ;; Duplicate contract Topic: the producer can author two anchors.
      (let* ((start (search "<li><a page=\"Relation Contract: informs\"" source))
             (item (subseq source start (+ 5 (search "</li>" source :start2 start))))
             (condition (refused (replace-once source item
                                               (concatenate 'string item item)))))
        (assert condition)
        (assert (= 2 (length (work::matches-of condition))))
        (assert (search "2 Topics" (princ-to-string condition))))
      ;; A reference naming a Topic that is not a Relation Contract.
      (let ((condition (refused (replace-once source anchor
                                              "data-topic=\"work:relation/informs\" data-kind=\"concept\""))))
        (assert condition)
        (assert (= 1 (length (work::matches-of condition))))
        (assert (search "\"concept\"" (princ-to-string condition)))))
    ;; The unedited page projects, so the controls fail for their edit alone.
    (fixture-projection source)))

(defun check-relation-contract-changes ()
  (let* ((source (work-breakdown-source))
         (baseline (fixture-projection source))
         (baseline-ids (association-ids baseline))
         (areas (fixture-projection source :areas-only t)))
    ;; A. Only the label changes.
    (let* ((renamed-html (replace-once source "data-status=\"draft\">informs</a>"
                                       "data-status=\"draft\">provides input to</a>"))
           (renamed (fixture-projection renamed-html)))
      (assert (tm:topicmap-projection-topic-by-id renamed *informs*))
      (assert (equal "provides input to"
                     (tm:topicmap-topic-label-of
                      (tm:topicmap-projection-topic-by-id renamed *informs*))))
      (assert (equal baseline-ids (association-ids renamed)))
      (dolist (association (informs-associations renamed))
        (assert (equal *informs* (tm:topicmap-association-type-of association)))
        (assert (equal "provides input to"
                       (tm:topicmap-association-relation-label association))))
      (assert (equal "\"informs\"" (d2-edge-label areas "interaction" "operations")))
      (assert (equal "\"provides input to\""
                     (d2-edge-label (fixture-projection renamed-html :areas-only t)
                                    "interaction" "operations"))))
    ;; B. Only the contract text changes: a separate copy of the contract page.
    (uiop:with-temporary-file (:pathname file :type "html")
      (with-open-file (out file :direction :output :if-exists :supersede)
        (write-string (replace-once (uiop:read-file-string
                                     (hyperdoc:file-of
                                      (work:work-page "Relation Contract: informs")))
                                    "provide input relevant to B."
                                    "provide input that B takes into account.")
                      out))
      (let* ((changed-page (hyperdoc::make-text-page
                            (hyperbook:find-hyperbook "dreyeck/work/reading") file))
             (find-page (lambda (title book)
                          (if (equal title "Relation Contract: informs")
                              changed-page
                              (work:work-page title book))))
             (changed (fixture-projection source :find-page find-page))
             (contract (tm:topicmap-projection-topic-by-id changed *informs*)))
        (assert (eq changed-page (tm:topicmap-topic-object-of contract)))
        (assert (search "takes into account"
                        (views:view-html (content-view changed-page))))
        (assert (equal baseline-ids (association-ids changed)))
        (dolist (association (informs-associations changed))
          (assert (eq contract (getf (tm:topicmap-association-properties-of association)
                                     :relation-contract)))
          (assert (equal "informs" (tm:topicmap-association-relation-label association))))
        (assert (equal "\"informs\""
                       (d2-edge-label (fixture-projection source :areas-only t
                                                                 :find-page find-page)
                                      "interaction" "operations")))))
    ;; C. One Association is retyped; the other informs Association is untouched.
    (let* ((retyped (fixture-projection
                     (replace-once source
                                   "data-to=\"operations\" data-relation=\"work:relation/informs\""
                                   "data-to=\"operations\" data-relation=\"requires\"")))
           (before (association-between baseline "interaction" "operations"))
           (after (association-between retyped "interaction" "operations"))
           (other (association-between retyped "operations" "connect")))
      (assert (equal (tm:topicmap-association-id-of
                      (association-between baseline "operations" "connect"))
                     (tm:topicmap-association-id-of other)))
      (assert (equal *informs* (tm:topicmap-association-type-of other)))
      (assert (equal "informs" (tm:topicmap-association-relation-label other)))
      (assert (equal "requires" (tm:topicmap-association-type-of after)))
      (assert (null (tm:topicmap-association-relation-label after)))
      ;; Recorded, not endorsed: the current ID scheme spells the relation, so
      ;; the retyped statement has a new ID. Whether that is the same
      ;; Association is an open question this test does not answer.
      (assert (equal "work:interaction:work:relation/informs:operations"
                     (tm:topicmap-association-id-of before)))
      (assert (equal "work:interaction:requires:operations"
                     (tm:topicmap-association-id-of after)))
      (assert (equal (list other) (work:relation-uses retyped *informs*))))
    ;; D. Uses returns both distinct informs Associations.
    (let ((uses (work:relation-uses baseline *informs*)))
      (assert (= 2 (length uses)))
      (assert (not (eq (first uses) (second uses))))
      (assert (equal '("interaction" "operations")
                     (mapcar #'tm:topicmap-association-from-of uses))))))

(defun check-relation-contract-inspection ()
  ;; Existing views only: Association Slots -> properties -> contract Topic,
  ;; Topic Slots -> contract page, contract page -> uses.
  (flet ((references (object title)
           (let ((view (find title (views:all-views object)
                             :key #'views:view-title :test #'search)))
             (assert view)
             (views:view-html view)
             (mapcar #'cdr (views:view-references view)))))
    (let* ((projection (work:work-projection))
           (association (association-between projection "interaction" "operations"))
           (contract (tm:topicmap-projection-topic-by-id projection *informs*))
           (properties (find (tm:topicmap-association-properties-of association)
                             (references association "Slots") :test #'eq)))
      (assert properties)
      (assert (member contract (references properties "Items") :test #'eq))
      (let ((page (find-if (lambda (object) (typep object 'hyperdoc:page))
                           (references contract "Slots"))))
        (assert (eq page (work:work-page "Relation Contract: informs")))
        (let ((uses (find-if #'consp (references page "Content"))))
          (assert (equal '("work:interaction:work:relation/informs:operations"
                           "work:operations:work:relation/informs:connect")
                         (mapcar #'tm:topicmap-association-id-of uses))))))
    ;; The Workspace lists the label at a Point that an informs edge touches.
    (let* ((workspace (work:work-workspace))
           (view (progn (tm:topicmap-workspace-go-to workspace "operations")
                        (find "Topicmap" (views:all-views workspace)
                              :key #'views:view-title :test #'equal)))
           (html (views:view-html view)))
      (assert (= 2 (count-matches "<tt>informs</tt>" html)))
      (assert (not (search "<tt>work:relation/" html))))))

;;;; Interactive TALA: one Inspector reference per D2 group

(defun work-page-sources ()
  "Every authored Work page file with its contents, to show nothing wrote them."
  (mapcar (lambda (file) (cons file (uiop:read-file-string file)))
          (uiop:directory-files
           (asdf:system-relative-pathname "dreyeck" "dreyeck/pages/work/"))))

(defun interactive-tala-view (rendering)
  "A new View, as a new Inspector pane or a refresh would make one."
  (let ((view (find "TALA (interactive)" (views:all-views rendering)
                    :key #'views:view-title :test #'equal)))
    (assert view)
    (views:view-html view)
    view))

(defun view-svg-dom (view)
  (let ((plump:*tag-dispatchers* plump:*xml-tags*))
    (plump:parse (views:view-html view))))

(defun svg-elements-with-attribute (dom name)
  (let (found)
    (plump:traverse dom (lambda (node) (when (plump:attribute node name) (push node found)))
                    :test #'plump:element-p)
    (nreverse found)))

(defun reference-group (view dom object)
  "The one element whose Inspector reference in VIEW is OBJECT."
  (let ((ids (mapcar #'car (remove object (views:view-references view)
                                   :key #'cdr :test-not #'eq))))
    (assert (= 1 (length ids)))
    (let ((elements (remove (first ids) (svg-elements-with-attribute dom "id")
                            :key (lambda (e) (plump:attribute e "id"))
                            :test-not #'equal)))
      (assert (= 1 (length elements)))
      (first elements))))

(defun group-text (group)
  (let ((texts (plump:get-elements-by-tag-name group "text")))
    (assert (= 1 (length texts)))
    (plump:text (first texts))))

(defun check-reference-groups (view rendering)
  "Each reference sits on the top-level group whose D2 identity class is the
one this rendering's input gave its object, and nothing nested in a
referenced group carries another reference."
  (let* ((input (tala:tala-rendering-input rendering))
         (entries (append (tala:tala-input-topics input) (tala:tala-input-associations input)))
         (dom (view-svg-dom view)))
    (assert (= (length entries) (length (views:view-references view))))
    (dolist (reference (views:view-references view))
      (let* ((object (cdr reference))
             (id (if (typep object 'tm:topicmap-association)
                     (tm:topicmap-association-id-of object)
                     (tm:topicmap-topic-id-of object)))
             (entry (find id entries :key (lambda (e) (getf e :id)) :test #'equal))
             (group (reference-group view dom object)))
        (assert (equal "g" (plump:tag-name group)))
        (assert (equal "svg" (plump:tag-name (plump:parent group))))
        (assert (equal (tala:d2-svg-identity-class (getf entry :d2-id))
                       (plump:attribute group "class")))
        ;; D2 may define a marker inside an edge group; only a second
        ;; reference inside the group could take a click from this one.
        (plump:traverse group (lambda (node)
                                (assert (or (eq node group)
                                            (not (assoc (plump:attribute node "id")
                                                        (views:view-references view)
                                                        :test #'equal)))))
                        :test #'plump:element-p)))
    dom))

(defun rendering-with-svg (rendering svg)
  (tala::%make-tala-rendering :input (tala:tala-rendering-input rendering)
                              :version (tala:tala-rendering-version rendering)
                              :svg svg))

(defun check-interactive-tala ()
  (let* ((before (work-page-sources))
         (rendering (work:work-layout-example))
         (projection (tala:tala-input-projection (tala:tala-rendering-input rendering)))
         (a1 (association-between projection "interaction" "operations"))
         (a2 (association-between projection "operations" "connect"))
         (view (interactive-tala-view rendering))
         (dom (check-reference-groups view rendering))
         (g1 (reference-group view dom a1))
         (g2 (reference-group view dom a2)))
    ;; Association references, and only they, are Association signs.
    (dolist (reference (views:view-references view))
      (assert (eq (typep (cdr reference) 'tm:topicmap-association)
                  (and (gethash (car reference) m::*association-sign-ids*) t))))
    ;; The image view stays, and says what it is.
    (assert (search "non-interactive"
                    (views:view-html (find "TALA rendering proof" (views:all-views rendering)
                                           :key #'views:view-title :test #'equal))))
    ;; Two equal visible labels, two distinct Associations, one contract.
    (assert (equal "informs" (group-text g1)))
    (assert (equal "informs" (group-text g2)))
    (assert (not (eq g1 g2)))
    (assert (not (eq a1 a2)))
    (let ((contract (getf (tm:topicmap-association-properties-of a1) :relation-contract)))
      (assert contract)
      (assert (eq contract (getf (tm:topicmap-association-properties-of a2) :relation-contract)))
      (assert (eq (work:work-page "Relation Contract: informs")
                  (tm:topicmap-topic-object-of contract))))
    ;; Path and label of one edge are inside the one referenced group.
    (dolist (group (list g1 g2))
      (assert (plump:get-elements-by-tag-name group "path"))
      (assert (= 1 (length (plump:get-elements-by-tag-name group "text")))))
    ;; Topic shapes are sibling groups with Topic references of their own.
    (let ((interaction (reference-group view dom (tm:topicmap-projection-topic-by-id
                                                  projection "interaction"))))
      (assert (eq (plump:parent interaction) (plump:parent g1)))
      (assert (null (plump:get-elements-by-tag-name interaction "path"))))
    ;; No label identifies anything: with every text emptied, and with the
    ;; two informs labels swapped for other words, the groups map as before.
    (dolist (relabel (list (constantly "")
                           (lambda (text) (if (equal text "informs") "requires" text))))
      (let ((blank (let ((plump:*tag-dispatchers* plump:*xml-tags*))
                     (plump:parse (tala:tala-rendering-svg rendering)))))
        (dolist (text (plump:get-elements-by-tag-name blank "text"))
          (loop for child across (plump:children text)
                when (typep child 'plump:textual-node)
                  do (setf (plump:text child) (funcall relabel (plump:text child)))))
        (let* ((relabelled (rendering-with-svg rendering (plump:serialize blank nil)))
               (other (interactive-tala-view relabelled))
               (other-dom (check-reference-groups other relabelled)))
          (assert (equal (plump:attribute g1 "class")
                         (plump:attribute (reference-group other other-dom a1) "class")))
          (assert (equal (plump:attribute g2 "class")
                         (plump:attribute (reference-group other other-dom a2) "class"))))))
    ;; A new View of the same rendering: new element IDs and a new D2 scope,
    ;; the same Associations. IDs of two Views in one page never coincide,
    ;; and each View's url(#...) references resolve inside that View.
    (let* ((again (interactive-tala-view rendering))
           (again-dom (check-reference-groups again rendering))
           (ids (mapcar (lambda (e) (plump:attribute e "id"))
                        (svg-elements-with-attribute dom "id")))
           (again-ids (mapcar (lambda (e) (plump:attribute e "id"))
                              (svg-elements-with-attribute again-dom "id"))))
      (assert (null (intersection ids again-ids :test #'equal)))
      (assert (= (length ids) (length (remove-duplicates ids :test #'equal))))
      (dolist (entry (list (cons dom ids) (cons again-dom again-ids)))
        (dolist (element (append (svg-elements-with-attribute (car entry) "mask")
                                 (svg-elements-with-attribute (car entry) "marker-end")))
          (let* ((value (or (plump:attribute element "marker-end")
                            (plump:attribute element "mask")))
                 (target (subseq value 5 (position #\) value))))
            (assert (member target (cdr entry) :test #'equal)))))
      (assert (eq a1 (cdr (find (plump:attribute (reference-group again again-dom a1) "id")
                                (views:view-references again) :key #'car :test #'equal))))
      (assert (not (equal (plump:attribute g1 "id")
                          (plump:attribute (reference-group again again-dom a1) "id")))))
    ;; A new rendering has a new Projection; its groups map to its own Associations.
    (let* ((next (work:work-layout-example))
           (next-projection (tala:tala-input-projection (tala:tala-rendering-input next)))
           (next-a1 (association-between next-projection "interaction" "operations"))
           (next-view (interactive-tala-view next)))
      (check-reference-groups next-view next)
      (assert (not (eq a1 next-a1)))
      (assert (equal (tm:topicmap-association-id-of a1) (tm:topicmap-association-id-of next-a1)))
      (reference-group next-view (view-svg-dom next-view) next-a1))
    (assert (equal before (work-page-sources)))))

;;;; Inspect relation contract: selected Operation + exact target -> object

(defparameter *inspect-bindings* (w:make-association-binding-catalog)
  "The production Bindings a Topicmap Association offers.")

(defun association-target (association)
  (list :type :topicmap-association :association association))

(defun gesture-sample (kind &key target (x 0.0d0) (y 0.0d0) button timestamp)
  (w:make-gesture-input-sample :kind kind :target target :x x :y y
                               :button button :modifiers nil :timestamp timestamp))

(defun novice-trace (target &optional (bindings *inspect-bindings*))
  (w:run-gesture-trace
   (list (gesture-sample :pointer-down :target target :button :secondary :timestamp 0)
         (gesture-sample :reveal-deadline :timestamp 500)
         (gesture-sample :pointer-move :x 20.0d0 :timestamp 600)
         (gesture-sample :pointer-up :x 20.0d0 :timestamp 620))
   :bindings bindings))

(defun expert-trace (target &optional (bindings *inspect-bindings*))
  (w:run-gesture-trace
   (list (gesture-sample :pointer-down :target target :button :secondary :timestamp 0)
         (gesture-sample :pointer-move :x 20.0d0 :timestamp 100)
         (gesture-sample :pointer-up :x 20.0d0 :timestamp 120))
   :bindings bindings))

(defun pressed-target (session)
  "The target the reducer kept: the one its pointer-down carried."
  (w:gesture-input-sample-target (first (sm:state-machine-run-input-of session))))

(defun selected-object (session)
  (m:operation-inspectable-object (w:gesture-session-selected-operation-of session)
                                  (pressed-target session)))

(defun refusal (operation target)
  "The condition OPERATION-INSPECTABLE-OBJECT signals, or an error if it returns."
  (handler-case
      (let ((value (m:operation-inspectable-object operation target)))
        (error "Expected a refusal, got ~S." value))
    (m:operation-not-applicable (condition) condition)))

(defun system-dependency-names (name &optional seen)
  (let ((system (asdf:find-system name nil)))
    (if (or (null system) (member (asdf:component-name system) seen :test #'equal))
        seen
        (let ((seen (cons (asdf:component-name system) seen)))
          (dolist (dependency (asdf:system-depends-on system) seen)
            (when (or (stringp dependency) (symbolp dependency))
              (setf seen (system-dependency-names (asdf:coerce-name dependency) seen))))))))

(defun check-inspect-relation-contract ()
  (let* ((operation (w:inspect-relation-contract-operation))
         (projection (work:work-projection))
         (a1 (association-between projection "interaction" "operations"))
         (a2 (association-between projection "operations" "connect"))
         (requires (association-between projection "operations" "state"))
         (contract (tm:topicmap-projection-topic-by-id projection "work:relation/informs"))
         (workspace (work:work-workspace))
         (point (copy-seq (tm:topicmap-workspace-point-of workspace)))
         (history (copy-list (tm:topicmap-workspace-history-of workspace)))
         (state (tala:projection-state projection))
         (pages (work-page-sources))
         ;; Loaded by this test system only, so that "no request" is observed.
         (requests (find-symbol "*REQUESTS*" (find-package "DREYECK/GESTURE/OPERATION-REQUEST")))
         (request-count (and requests (hash-table-count (symbol-value requests))))
         (create-pane (find-symbol "CREATE-PANE" "CLOG-MOLDABLE-INSPECTOR"))
         (panes 0))
    ;; The identity is data, with a title and nothing to call.
    (assert (equal "operation/inspect-relation-contract"
                   (w:semantic-operation-identity-id operation)))
    (assert (equal "Inspect relation contract" (w:semantic-operation-identity-title operation)))
    (assert (not (functionp operation)))
    (assert (eq operation (w:inspect-relation-contract-operation)))
    ;; Test-local watch on the Inspector's pane creation; removed afterwards.
    (sb-int:encapsulate create-pane 'inspect-relation-contract-test
                        (lambda (function &rest arguments)
                          (incf panes) (apply function arguments)))
    (unwind-protect
         (let ((target (association-target a1)))
           ;; Novice and expert: different routes and Bindings, one EQ Operation,
           ;; the exact target kept.
           (let ((novice (novice-trace target))
                 (expert (expert-trace target)))
             (assert (equal '(:idle :pressed :menu-visible :sector-selected :completed)
                            (sm:state-machine-run-visited-states-of novice)))
             (assert (equal '(:idle :pressed :marking :sector-selected :completed)
                            (sm:state-machine-run-visited-states-of expert)))
             (dolist (session (list novice expert))
               (assert (eq operation (w:gesture-session-selected-operation-of session)))
               (assert (eq target (pressed-target session)))
               (assert (eq a1 (getf (pressed-target session) :association))))
             (assert (equal "binding/radial-inspect-relation-contract"
                            (w:gesture-binding-id (w:gesture-session-selected-binding-of novice))))
             (assert (equal "binding/mark-inspect-relation-contract"
                            (w:gesture-binding-id (w:gesture-session-selected-binding-of expert))))
             ;; One object shown for both edges and for both routes.
             (let ((shown (m:operation-inspectable-object operation target)))
               (assert (eq contract shown))
               (assert (eq shown (m:operation-inspectable-object operation (association-target a2))))
               (assert (eq shown (selected-object novice)))
               (assert (eq shown (selected-object expert)))
               (assert (eq shown (selected-object (novice-trace (association-target a2)))))
               (assert (eq (work:work-page "Relation Contract: informs")
                           (tm:topicmap-topic-object-of shown)))))
           ;; Refusals, each a condition, never NIL.
           (flet ((refused (operation target fragment)
                    (let ((condition (refusal operation target)))
                      (assert (search fragment (m:operation-not-applicable-reason condition))
                              () "Refusal ~S lacks ~S." (princ-to-string condition) fragment))))
             (refused (w:insert-executable-defexample-operation) target
                      "only Inspect relation contract")
             (refused operation (list :type :lisp-source-definition :name 'work:work-projection)
                      ":LISP-SOURCE-DEFINITION")
             (refused operation (association-target requires) "refers to no Relation Contract")
             (refused operation (list :type :topicmap-association) "carries NIL")
             (refused operation (association-target (tm:topicmap-association-id-of a1))
                      "carries \"work:interaction:work:relation/informs:operations\""))
           ;; The four events are distinct:
           ;; recognized without a Binding (none applies to this target type),
           (let ((recognized (expert-trace (association-target a1) nil)))
             (assert (member :marking (sm:state-machine-run-visited-states-of recognized)))
             (assert (eq :cancelled (sm:state-machine-run-current-state-of recognized)))
             (assert (null (w:gesture-session-selected-binding-of recognized))))
           ;; two Bindings select one Operation (above), and an Operation
           ;; selected on a target still need not show anything.
           (let ((selected (novice-trace (association-target requires))))
             (assert (eq :completed (sm:state-machine-run-current-state-of selected)))
             (assert (eq operation (w:gesture-session-selected-operation-of selected)))
             (refusal operation (pressed-target selected))))
      (sb-int:unencapsulate create-pane 'inspect-relation-contract-test))
    ;; Nothing happened besides computing the object.
    (assert (zerop panes))
    (assert (equal state (tala:projection-state projection)))
    (assert (equal point (tm:topicmap-workspace-point-of workspace)))
    (assert (equal history (tm:topicmap-workspace-history-of workspace)))
    (assert (equal pages (work-page-sources)))
    (assert requests)
    (assert (= request-count (hash-table-count (symbol-value requests))))
    ;; The code that computes it cannot make a request: its system does not
    ;; depend on the one that defines OPERATION-REQUEST.
    (assert (not (member "dreyeck/gesture/operation-request"
                         (system-dependency-names "dreyeck/inspector/topicmap")
                         :test #'equal)))))

;;;; Traces shaped by a hand
;;
;; A mark is many moves, not one. The first three traces below replay, in the
;; pure reducer, coordinates and times recorded from trusted physical mouse
;; attempts on the Interaction -> Operations sign (relative to the press, in
;; CSS pixels and milliseconds). A replay is not physical evidence; it keeps
;; what the hand did.

(defun hand-trace (target moves &key deadline-after (up-at 1000) up)
  "Press at the origin, then MOVES (x y ms). A reveal deadline is delivered
after the move at DEADLINE-AFTER ms, if given, as the browser delivered it."
  (w:run-gesture-trace
   (append
    (list (gesture-sample :pointer-down :target target :button :secondary :timestamp 0))
    (loop for (x y at) in moves
          collect (gesture-sample :pointer-move :x (float x 1d0) :y (float y 1d0) :timestamp at)
          when (and deadline-after (= at deadline-after))
            collect (gesture-sample :reveal-deadline :timestamp 500))
    (let ((last (or up (car (last moves)))))
      (list (gesture-sample :pointer-up :x (float (first last) 1d0) :y (float (second last) 1d0)
                            :timestamp up-at))))
   :bindings *inspect-bindings*))

(defun check-trace (session visited binding)
  (assert (equal visited (sm:state-machine-run-visited-states-of session)) ()
          "Visited ~S, expected ~S." (sm:state-machine-run-visited-states-of session) visited)
  (if binding
      (progn
        (assert (equal binding (w:gesture-binding-id (w:gesture-session-selected-binding-of session))))
        (assert (eq (w:inspect-relation-contract-operation)
                    (w:gesture-session-selected-operation-of session))))
      (assert (null (w:gesture-session-selected-binding-of session))))
  session)

(defparameter +expert-path+ '(:idle :pressed :marking :sector-selected :completed))
(defparameter +novice-path+ '(:idle :pressed :menu-visible :sector-selected :completed))

(defun check-hand-shaped-traces ()
  (let* ((projection (work:work-projection))
         (a1 (association-between projection "interaction" "operations"))
         (target (association-target a1))
         (mark "binding/mark-inspect-relation-contract")
         (radial "binding/radial-inspect-relation-contract"))
    ;; Recorded P1: fast, with a still start inside the dead zone.
    (let ((s (hand-trace target '((0 0 45) (0 0 60) (0 1 75) (1 1 90) (2 1 105) (11 2 120)
                                 (40 4 135) (106 6 150) (149 6 165) (162 6 180) (168 5 195)
                                 (170 5 270) (172 5 285) (174 5 300))
                         :up-at 330)))
      (check-trace s +expert-path+ mark)
      (assert (not (w:gesture-session-menu-visible-p-of s)))
      (assert (eq a1 (getf (pressed-target s) :association))))
    ;; Recorded P3: rightward with a downward drift.
    (check-trace (hand-trace target '((1 0 105) (1 1 120) (6 2 135) (15 4 150) (30 7 165)
                                      (50 10 180) (56 10 195) (58 10 210) (58 10 225))
                             :up-at 315)
                 +expert-path+ mark)
    ;; Recorded P2: the hand stayed within 2 px for about a second, so the
    ;; browser's reveal deadline came first and the menu opened; moving onto
    ;; its sector then selected the same Operation by the radial Binding.
    (check-trace (hand-trace target '((0 0 255) (1 0 480) (1 0 885) (1 0 930) (2 0 960)
                                      (2 0 990) (2 0 1005) (2 0 1020) (3 0 1035) (7 0 1050)
                                      (13 0 1065) (39 1 1095) (44 1 1110) (48 1 1125) (49 1 1140))
                             :deadline-after 480 :up-at 1455)
                 +novice-path+ radial)
    ;; A gradual, human-like mark crossing the dead zone over several moves.
    (let ((s (hand-trace target '((2 1 40) (4 0 80) (7 1 120) (11 2 160) (16 1 200)
                                  (22 2 240) (30 1 280))
                         :up-at 310)))
      (check-trace s +expert-path+ mark)
      (assert (not (w:gesture-session-menu-visible-p-of s))))
    ;; Expert keeps its mode: leaving the sector returns to MARKING, never to
    ;; MENU-VISIBLE; returning selects again; release completes.
    (let ((s (hand-trace target '((20 0 60) (0 20 120) (25 2 180)) :up-at 220)))
      (check-trace s '(:idle :pressed :marking :sector-selected :marking :sector-selected :completed)
                   mark)
      (assert (not (w:gesture-session-menu-visible-p-of s))))
    ;; ... and release outside every sector cancels cleanly, still marking.
    (let ((s (hand-trace target '((20 0 60) (0 20 120)) :up-at 180)))
      (check-trace s '(:idle :pressed :marking :sector-selected :marking :cancelled) nil)
      (assert (eq :marking (w:gesture-session-mode-of s)))
      (assert (eq :no-active-enabled-sector (w:gesture-session-cancellation-reason-of s))))
    ;; Novice keeps its mode the same way.
    (let ((s (w:run-gesture-trace
              (list (gesture-sample :pointer-down :target target :button :secondary :timestamp 0)
                    (gesture-sample :reveal-deadline :timestamp 500)
                    (gesture-sample :pointer-move :x 20d0 :timestamp 600)
                    (gesture-sample :pointer-move :y 20d0 :timestamp 650)
                    (gesture-sample :pointer-move :x 20d0 :y 1d0 :timestamp 700)
                    (gesture-sample :pointer-up :x 20d0 :y 1d0 :timestamp 750))
              :bindings *inspect-bindings*)))
      (check-trace s '(:idle :pressed :menu-visible :sector-selected :menu-visible
                       :sector-selected :completed)
                   radial))
    ;; Once movement has committed to marking, a later deadline is obsolete:
    ;; after a selection, and while marking outside any sector.
    (dolist (moves '(((20 0 60) (25 1 520)) ((0 20 60) (20 0 520))))
      (let ((s (hand-trace target moves :deadline-after 60 :up-at 560)))
        (check-trace s +expert-path+ mark)
        (assert (not (w:gesture-session-menu-visible-p-of s)))
        (assert (member :obsolete-reveal-deadline (w:gesture-session-observations-of s)
                        :key (lambda (o) (getf o :reason))))))))

(defun count-matches (needle haystack)
  (loop with start = 0 for position = (search needle haystack :start2 start)
        while position count t do (setf start (1+ position))))

(defun run-tests ()
  (check-work-projection)
  (check-pages-and-example)
  (check-native-work-navigation)
  (check-work-layout)
  (check-relation-contract)
  (check-relation-reference-integrity)
  (check-relation-contract-changes)
  (check-relation-contract-inspection)
  (check-interactive-tala)
  (check-inspect-relation-contract)
  (check-hand-shaped-traces)
  (format t "~&WORK-READING-PASS: complete projection integrity, Operations page link, pages, executable widget, D2 SVG, native page navigation, seven-area derived layout, informs relation contract (label, integrity, rename, contract text, retype one, uses, inspection), interactive TALA references, Inspect relation contract (novice/expert selection, one object, refusals, no effect).~%")
  t)
