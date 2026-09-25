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
;; make an endpoint-resolution check pass vacuously.
(defparameter *expected-work-associations*
  '("work:interaction:informs:operations"
    "work:operations:informs:connect"
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
    (assert (= 12 (length topics)))
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
                     "D2 Connections"))
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
    (assert (search "<svg" (tala:tala-rendering-svg render)))))

(defun run-tests ()
  (check-work-projection)
  (check-pages-and-example)
  (check-native-work-navigation)
  (check-work-layout)
  (format t "~&WORK-READING-PASS: complete projection integrity, Operations page link, pages, executable widget, D2 SVG, native page navigation, seven-area derived layout.~%")
  t)
