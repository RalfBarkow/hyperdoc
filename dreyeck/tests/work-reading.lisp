(defpackage #:dreyeck/work/tests
  (:use #:cl)
  (:local-nicknames (#:work #:dreyeck/work/reading)
                    (#:tm #:dreyeck/topicmap)
                    (#:views #:html-inspector-views)
                    (#:authored #:dreyeck/topicmap/tala/authored)
                    (#:tala #:dreyeck/topicmap/tala))
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
  (format t "~&WORK-READING-PASS: complete projection integrity, Operations page link, pages, executable widget, D2 SVG, native page navigation, seven-area derived layout, informs relation contract (label, integrity, rename, contract text, retype one, uses, inspection).~%")
  t)
