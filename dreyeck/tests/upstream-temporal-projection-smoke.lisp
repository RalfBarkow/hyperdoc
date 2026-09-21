;;;; The temporal projection is derived, ordered, and changes nothing.
;;
;; What is worth testing here is not that a diagram appears. It is that
;; the diagram has no opinions of its own: every topic, every edge and
;; every interval must come from the history layer, the order must be
;; the one Git already confirmed, and rendering must leave the Workspace
;; exactly as it found it.

(defpackage #:dreyeck/upstream-intake/temporal/tests
  (:use #:cl)
  (:local-nicknames (#:tm #:dreyeck/topicmap)
                    (#:tala #:dreyeck/topicmap/tala)
                    (#:intake #:dreyeck/upstream-intake)
                    (#:temporal #:dreyeck/upstream-intake/temporal))
  (:export #:run-temporal-projection-tests))

(in-package #:dreyeck/upstream-intake/temporal/tests)

(defun check (condition format &rest arguments)
  (unless condition (apply #'error format arguments))
  t)

(defun %topic (projection id)
  (find id (tm:topicmap-projection-topics-of projection)
        :key #'tm:topicmap-topic-id-of :test #'string=))

(defun %associations-of-type (projection type)
  (remove type (tm:topicmap-projection-associations-of projection)
          :key #'tm:topicmap-association-type-of :test-not #'eq))

(defun check-projection-is-derived-from-the-history ()
  "Every topic must answer to something the history layer already holds.

The failure this guards against is a projection that quietly grows its
own facts — a commit drawn because someone typed it here, a capability
that exists only in the diagram. So the sets are compared both ways."
  (let* ((history (temporal:make-page-loading-history))
         (projection (tm:topicmap-projection-of history))
         (states (intake:page-loading-history-states))
         (attributions (intake:page-loading-capability-attributions))
         (projected (mapcar #'tm:topicmap-topic-id-of
                            (tm:topicmap-projection-topics-of projection)))
         (expected (temporal:page-loading-history-topic-ids)))
    (check (null (set-difference projected expected :test #'string=))
           "The projection carries topics the history does not: ~S."
           (set-difference projected expected :test #'string=))
    (check (null (set-difference expected projected :test #'string=))
           "The projection is missing topics the history holds: ~S."
           (set-difference expected projected :test #'string=))
    (check (= (length states) (length (%associations-of-type projection :in-layer)))
           "Layer membership does not cover every state.")
    (check (= (length attributions)
              (length (%associations-of-type projection :establishes)))
           "The establishing edges do not cover every attribution.")
    ;; A commit topic must lead to the real commit, not to a label.
    (dolist (state states)
      (let* ((id (format nil "git-commit:~A" (getf state :reference)))
             (topic (%topic projection id)))
        (check topic "No topic for observed state ~S." (getf state :reference))
        (check (typep (tm:topicmap-topic-object-of topic) 'dreyeck/git:git-commit)
               "Topic ~S carries ~S instead of the commit object."
               id (tm:topicmap-topic-object-of topic))
        (check (string= (dreyeck/git:git-commit-hash-of
                         (tm:topicmap-topic-object-of topic))
                        (getf state :reference))
               "Topic ~S carries a different commit." id))))
  t)

(defun check-ancestry-order-survives-projection ()
  "The edges must follow the order Git confirmed, not the order of a list."
  (let* ((projection (tm:topicmap-projection-of
                      (temporal:make-page-loading-history)))
         (states (intake:page-loading-history-states))
         (edges (%associations-of-type projection :ancestor-of)))
    (check (= (1- (length states)) (length edges))
           "Expected ~D ancestry edges, found ~D."
           (1- (length states)) (length edges))
    (loop for (state next) on states
          while next
          do (let ((edge (find-if
                          (lambda (association)
                            (and (string= (tm:topicmap-association-from-of association)
                                          (format nil "git-commit:~A"
                                                  (getf state :reference)))
                                 (string= (tm:topicmap-association-to-of association)
                                          (format nil "git-commit:~A"
                                                  (getf next :reference)))))
                          edges)))
               (check edge "No ancestry edge from ~S to ~S."
                      (getf state :reference) (getf next :reference))
               (check (dreyeck/git:git-commit-ancestor-p
                       (intake:page-loading-history-commit (getf state :reference))
                       (intake:page-loading-history-commit (getf next :reference)))
                      "The projected edge ~S -> ~S is not an ancestry in Git."
                      (getf state :reference) (getf next :reference)))))
  t)

(defun check-layers-are-semantic ()
  "Mechanism and contract must be topics, not a way of drawing.

The point of carrying them as signs is that the distinction is then
true in the Topicmap and inspectable there. A test that only looked at
the picture could not tell the difference."
  (let* ((projection (tm:topicmap-projection-of
                      (temporal:make-page-loading-history)))
         (mechanism (%topic projection "page-loading-layer:mechanism"))
         (contract (%topic projection "page-loading-layer:contract")))
    (check mechanism "No mechanism layer topic.")
    (check contract "No contract layer topic.")
    (dolist (state (intake:page-loading-history-states))
      (let* ((from (format nil "git-commit:~A" (getf state :reference)))
             (edge (find from (%associations-of-type projection :in-layer)
                         :key #'tm:topicmap-association-from-of :test #'string=)))
        (check edge "State ~S belongs to no layer." (getf state :reference))
        (check (string= (tm:topicmap-association-to-of edge)
                        (format nil "page-loading-layer:~(~A~)" (getf state :layer)))
               "State ~S is drawn in a layer other than its recorded ~S."
               (getf state :reference) (getf state :layer)))))
  t)

(defun check-publication-state-is-distinguishable ()
  "8a11491 must be readable as the state that published the extension point.

Not by styling and not by position, but by the edge it carries: it is
the state the interpretation attributes the public extension point to.
The matrix stays the authority; this only checks that the projection
reports the same thing rather than a second opinion."
  (let* ((projection (tm:topicmap-projection-of
                      (temporal:make-page-loading-history)))
         (publication "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8")
         (attribution
           (find :load-page-is-a-public-extension-point
                 (intake:page-loading-capability-attributions)
                 :key (lambda (a) (getf a :capability))))
         (edge (find (format nil "page-loading-establishes:~A"
                             (getf attribution :label))
                     (%associations-of-type projection :establishes)
                     :key #'tm:topicmap-association-id-of :test #'string=)))
    (check (string= publication (getf attribution :established-by))
           "The public extension point is now attributed to ~S."
           (getf attribution :established-by))
    (check edge "No establishing edge for the public extension point.")
    (check (string= (tm:topicmap-association-from-of edge)
                    (format nil "git-commit:~A" publication))
           "The establishing edge starts at ~S."
           (tm:topicmap-association-from-of edge))
    ;; And the capability topic must lead to its basis, not to a label.
    (let ((topic (%topic projection (tm:topicmap-association-to-of edge))))
      (check (eq :interpreted (getf (tm:topicmap-topic-object-of topic)
                                    :evidence-status))
             "The capability topic does not carry its attribution.")))
  t)

(defun check-intervals-come-from-the-observed-dates ()
  "The companion must restate the history's own numbers, not compute new ones."
  (let ((intervals (temporal:page-loading-temporal-intervals))
        (states (intake:page-loading-history-states)))
    (check (getf intervals :states-are-in-date-order-p)
           "The interval companion reports the dates out of order.")
    (check (eq :derived (getf intervals :intervals))
           "The intervals are no longer marked as derived.")
    (loop for step in (getf intervals :steps)
          for state in states
          do (check (string= (getf step :from) (getf state :reference))
                    "Interval step ~S does not follow the observed order."
                    (getf step :from))
             (check (eql (getf step :seconds) (getf state :seconds-to-next))
                    "Interval ~S disagrees with the observed gap ~S."
                    (getf step :seconds) (getf state :seconds-to-next))
             (check (plusp (getf step :seconds))
                    "Interval ~S is not positive." (getf step :seconds)))
    ;; The finding the companion exists to keep visible.
    (check (> (getf (first (getf intervals :steps)) :seconds) (* 300 24 60 60))
           "The long latency between mechanism and contract has gone."))
  t)

(defun check-d2-carries-identity-and-not-labels ()
  "Every D2 identifier must decode to the Topic it stands for."
  (let* ((projection (tm:topicmap-projection-of
                      (temporal:make-page-loading-history)))
         (input (tala:projection-tala-input projection))
         (source (tala:tala-input-source input)))
    (dolist (entry (tala:tala-input-topics input))
      (check (string= (getf entry :id)
                      (tala:tala-input-topic-id input (getf entry :d2-id)))
             "The D2 key for ~S does not lead back to it." (getf entry :id))
      (check (search (getf entry :d2-id) source)
             "D2 source does not mention ~S." (getf entry :id)))
    ;; Labels appear, but nothing is identified by them.
    (check (search "\"8a114919\"" source)
           "The D2 source carries no readable label for the publication state.")
    ;; And the source must now be readable: a reader should be able to
    ;; see which commit a line is about without decoding anything.
    (check (search "git_commit_8a1149197fabcb1ab5622316f09c5a60c2d3f1f8" source)
           "The D2 source carries no readable key for the publication state.")
    (check (not (search "n00006700006900007400002D" source))
           "The D2 source still carries hex-encoded identifiers."))
  t)

(defun check-rendering-changes-nothing ()
  "Laying the projection out must leave the Workspace as it was.

Reuses the contract the TALA integration already established:
PROJECTION-STATE before and after, the point unmoved, the history
untouched. When the pinned D2 is absent the example says so instead of
signalling, and that is checked too, because a reading page must not
fail because a tool is missing."
  (let* ((history (temporal:make-page-loading-history))
         (workspace (tm::make-topicmap-workspace-for-object history))
         (projection (tm:topicmap-workspace-projection-of workspace))
         (before (tala:projection-state projection))
         (point (tm:topicmap-workspace-point-of workspace))
         (result (temporal:page-loading-tala-rendering-example)))
    (if (typep result 'tala::tala-rendering)
        (progn
          (check (tala:validate-tala-svg (tala:tala-rendering-input result)
                                         (tala:tala-rendering-svg result))
                 "The rendered SVG does not cover the projected identities.")
          ;; Non-interactive: identity is preserved, actions are not added.
          (check (not (search "onclick" (tala:tala-rendering-svg result)))
                 "The rendered SVG carries a handler; it must stay non-interactive."))
        (check (eq :tala-unavailable (getf result :kind))
               "Without the pinned D2 the example returned ~S." result))
    (check (equal before (tala:projection-state projection))
           "Rendering modified the projection.")
    (check (string= point (tm:topicmap-workspace-point-of workspace))
           "Rendering moved the Workspace point.")
    (check (null (tm:topicmap-workspace-history-of workspace))
           "Rendering changed Workspace history."))
  t)

(defun check-no-page-attached-engine-is-loaded ()
  "Reading this history must not bring the Lisp Critic engine into the image.

Unrelated on its face, and that is the point: these pages share a
runtime, and the cheapest way for the inertness of one to be lost is for
something else to load an engine on the way past."
  (dolist (name '(:lisp-critic :lisp-critic-user :extend-match :a-critic-for-lisp))
    (check (null (find-package name))
           "Package ~S is present; something loaded the page-attached engine."
           name))
  t)

(defun check-identity-maps-are-inspectable ()
  "The Topic and Association maps must survive being opened in the Inspector.

This is where the readable-key contract meets a reader. Identity now
lives in the mapping the projection carries, so the mapping is evidence
and has to be reachable — and reaching it means the Inspector asking
ALL-VIEWS of a plain list and then rendering what comes back.

Written after a live witness: a synthetic DOM click on \"Topic ID map\"
created an Inspector pane that stayed empty, because a view specialized
on CONS read the list with GETF without checking that it was a property
list. GETF signalled, the condition was raised while the pane was being
built, and the pane appeared as a dead link. Nothing in the suite
noticed, because every test asked the mapping for its data and none
asked it for its views.

So the test asks for views, and renders them. It also asks on behalf of
the shapes that broke it: a list of plists, and a list whose length is
odd. A test that only used a well-formed plist would pass against the
defect."
  (let* ((input (tala:projection-tala-input
                 (tm:topicmap-projection-of (temporal:make-page-loading-history))))
         (targets (list (cons "Topic ID map" (tala:tala-input-topics input))
                        (cons "Association map" (tala:tala-input-associations input))
                        (cons "odd list" (list :id "a" :d2-id))
                        (cons "list of lists" (list (list 1 2) (list 3 4))))))
    (dolist (target targets)
      (let ((views (handler-case (html-inspector-views:all-views (cdr target))
                     (error (condition)
                       (error "Opening ~A in the Inspector signalled ~A: ~A~%~
A view specialized on CONS is offered every list, so one that reads an ~
unchecked GETF breaks panes for unrelated objects."
                              (car target) (type-of condition) condition)))))
        (check views "~A offers no Inspector view." (car target))
        ;; A pane renders its selected view; an unrendered view is a
        ;; pane that opens empty, which is what the reader saw.
        (let ((html (handler-case
                        (html-inspector-views:view-html (first views))
                      (error (condition)
                        (error "Rendering the first view of ~A signalled ~A: ~A"
                               (car target) (type-of condition) condition)))))
          (check (plusp (length html))
                 "The first view of ~A renders as nothing." (car target)))))
    ;; And the rendered map must actually show the identities it carries,
    ;; not merely be non-empty.
    (let ((html (html-inspector-views:view-html
                 (first (html-inspector-views:all-views
                         (tala:tala-input-topics input))))))
      (check (search "git-commit:8a1149197fabcb1ab5622316f09c5a60c2d3f1f8" html)
             "The rendered Topic ID map does not show the Topic it maps.")
      (check (search "git_commit_8a1149197fabcb1ab5622316f09c5a60c2d3f1f8" html)
             "The rendered Topic ID map does not show the D2 key it assigns.")))
  t)

(defun run-temporal-projection-tests ()
  (check-no-page-attached-engine-is-loaded)
  (check-projection-is-derived-from-the-history)
  (check-ancestry-order-survives-projection)
  (check-layers-are-semantic)
  (check-publication-state-is-distinguishable)
  (check-intervals-come-from-the-observed-dates)
  (check-d2-carries-identity-and-not-labels)
  (check-identity-maps-are-inspectable)
  (check-rendering-changes-nothing)
  (check-no-page-attached-engine-is-loaded)
  (format t "~&TEMPORAL-PROJECTION-PASS: derived from the history, ordered by ~
ancestry, rendered without mutation.~%")
  t)
