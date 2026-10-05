;;;; Workspace action sign occurrences, without a browser.
;;;;
;;;; Events are fed to the occurrence exactly as its CLOG handler receives
;;;; them -- KIND|TRUSTED|PAYLOAD, the payload in CLOG's pointer format --
;;;; so everything after the browser is the code the page runs. What only
;;;; a browser can show is in topicmap-gesture-browser.lisp.

(defpackage #:dreyeck/topicmap/gesture/tests
  (:use #:cl)
  (:local-nicknames (#:m #:dreyeck/inspector/topicmap)
                    (#:tm #:dreyeck/topicmap)
                    (#:g #:dreyeck/gesture/clog)
                    (#:w #:dreyeck/gesture-binding-witness))
  (:export #:run-workspace-action-sign-tests
           #:inert-test-bindings
           #:reading-workspace
           #:reachable-topic-id))

(in-package #:dreyeck/topicmap/gesture/tests)

(defparameter *reachable-topic-id* "asdf-system:dreyeck/topicmap/tala/reading/tests"
  "The Reading Workspace Topic whose action sign is not covered by another
at the default layout. The browser test checks this rather than assumes it.")

(defun reachable-topic-id () *reachable-topic-id*)

(defun inert-test-bindings ()
  "Test-only: one inert Operation behind a radial and a mark Binding for the
occurrence type. Nothing in production supplies these."
  (let ((operation (w::%make-operation-identity
                    "test-only/workspace-action-sign-witness" "Inert test witness")))
    (loop for kind in '(:radial-menu :learned-mark)
          collect (w::%make-gesture-binding
                   :id (format nil "test-only/~(~A~)" kind) :kind kind
                   :sector-center 0.0d0 :sector-half-width 30.0d0
                   :target-type :workspace-action-sign-occurrence
                   :enabled-p t :operation operation))))

(defun reading-workspace ()
  (uiop:symbol-call :dreyeck/inspector/topicmap/tala :reading-source-workspace))

(defun %topic (workspace id)
  (tm:topicmap-projection-topic-by-id (tm:topicmap-projection-of workspace) id))

(defclass test-element (clog:clog-element) ())
(defmethod clog:validp ((element test-element)) t)
(defmethod clog:js-query ((element test-element) script &key default-answer)
  (declare (ignore script default-answer)) "true")
(defmethod clog:js-execute ((element test-element) script)
  (declare (ignore script)) nil)

(defun %occurrence (workspace topic &key (bindings (inert-test-bindings)))
  "An occurrence as the Inspector makes one, minus the browser element."
  (let ((occurrence (make-instance
                     'm:workspace-action-sign-occurrence
                     :reference (make-instance 'm::topic-action-reference
                                               :topic topic
                                               :projection (tm:topicmap-projection-of workspace)
                                               :workspace workspace
                                               :fn (lambda () nil))
                     :element (make-instance 'test-element :html-id "test" :connection-id "test") :pane nil :view nil)))
    (setf (m:occurrence-gesture-window occurrence) (g:make-gesture-window :bindings bindings))
    occurrence))

(defun %feed (occurrence steps &key (trust "untrusted"))
  "STEPS as (EVENT-NAME X BUTTONS [Y]), in browser order."
  (loop for (name x buttons y) in steps
        for py = (or y 10)
        for sequence from 1
        for which = (if (member name '("pointerdown" "pointerup") :test #'string=) 3 0)
        do (m::%receive-topic-gesture
            occurrence (list :type :workspace-action-sign-occurrence :occurrence occurrence)
            (format nil "~A|~A|~D:~D:0:0:~D:false:false:false:false:~D:~D:~D:~D:~D:~D"
                    name trust x py which x py x py buttons sequence))))

(defparameter *radial*
  '(("pointerdown" 100 2) ("gesturerevealdeadline" 100 2)
    ("pointermove" 180 2) ("pointerup" 180 0)))

(defparameter *mark*
  '(("pointerdown" 100 2) ("pointermove" 180 2) ("pointerup" 180 0)))

(defun %result (occurrence)
  (g:gesture-window-result (m:occurrence-gesture-window occurrence)))

(defun %selected (occurrence)
  (multiple-value-bind (binding subject)
      (g:gesture-window-selection (m:occurrence-gesture-window occurrence))
    (values (and binding (w:gesture-binding-id binding)) (getf subject :occurrence))))

(defun %production-occurrence (workspace topic)
  (let ((occurrence (%occurrence workspace topic :bindings nil)))
    (setf (m:occurrence-gesture-window occurrence)
          (g:make-gesture-window :bindings (m:workspace-action-sign-bindings occurrence)))
    occurrence))

(defun check-topic-binding-sectors (occurrence)
  "Inclusive sectors for different operations must not overlap within either path."
  (dolist (kind '(:radial-menu :learned-mark))
    (let ((bindings (g:menu-bindings (m:occurrence-gesture-window occurrence)
                                   (list :type :workspace-action-sign-occurrence :occurrence occurrence) kind)))
      (loop for (binding . others) on bindings do
        (dolist (other others)
          (assert (> (w::%angular-distance (w:gesture-binding-sector-center binding)
                                          (w:gesture-binding-sector-center other))
                     (+ (w:gesture-binding-sector-half-width binding)
                        (w:gesture-binding-sector-half-width other)))
                  () "Overlapping Topic sectors: ~A / ~A"
                  (w:gesture-binding-id binding) (w:gesture-binding-id other)))))))

(defun check-topic-binding-pair (occurrence operation angle)
  (let* ((bindings (m:workspace-action-sign-bindings occurrence))
         (pair (remove operation bindings :key #'w:gesture-binding-operation :test-not #'eq))
         (radial (find :radial-menu pair :key #'w:gesture-binding-kind))
         (mark (find :learned-mark pair :key #'w:gesture-binding-kind)))
    (assert (= 2 (length pair)))
    (assert (and radial mark))
    (assert (eq (w:gesture-binding-operation radial) (w:gesture-binding-operation mark)))
    (assert (= angle (w:gesture-binding-sector-center radial) (w:gesture-binding-sector-center mark)))
    (assert (= (w:gesture-binding-sector-half-width radial) (w:gesture-binding-sector-half-width mark)))))

(defun %sector-trace (angle kind)
  (let* ((radians (* pi (/ angle 180)))
         (x (round (+ 100 (* 80 (cos radians)))))
         (y (round (+ 100 (* 80 (sin radians))))))
    (append (list '("pointerdown" 100 2 100))
            (when (eq kind :radial-menu) (list '("gesturerevealdeadline" 100 2 100)))
            (list (list "pointermove" x 2 y) (list "pointerup" x 0 y)))))

(defun test-production-topic-inspections (workspace topic)
  (let ((point (tm:topicmap-workspace-point-of workspace))
        (history (tm:topicmap-workspace-history-of workspace)))
    (dolist (case (list (list (w:inspect-represented-object-operation) 180 (tm:topicmap-topic-object-of topic))
                        (list (w:inspect-topicmap-sign-operation) 270 topic)))
      (destructuring-bind (operation angle object) case
        (dolist (kind '(:radial-menu :learned-mark))
          (let ((occurrence (%production-occurrence workspace topic)))
            (check-topic-binding-sectors occurrence)
            (check-topic-binding-pair occurrence operation angle)
            (%feed occurrence (%sector-trace angle kind))
            (assert (eq :completed (getf (%result occurrence) :state)))
            (assert (eq operation (w:gesture-binding-operation
                                  (g:gesture-window-selection (m:occurrence-gesture-window occurrence)))))
            (assert (eq object (m:workspace-action-sign-selected-object occurrence)))))))
    (assert (equal point (tm:topicmap-workspace-point-of workspace)))
    (assert (eq history (tm:topicmap-workspace-history-of workspace))))
  ;; No object: only the sign's original sector remains, rather than shifting.
  (let* ((plain (tm:make-topicmap-topic :id "plain" :label "Plain"))
         (ws (tm:make-topicmap-workspace (tm:make-topicmap-projection :topics (list plain)) "plain"))
         (occurrence (%production-occurrence ws plain))
         (target (list :type :workspace-action-sign-occurrence :occurrence occurrence)))
    (assert (= 2 (length (m:workspace-action-sign-bindings occurrence))))
    (check-topic-binding-pair occurrence (w:inspect-topicmap-sign-operation) 270)
    (assert (handler-case (progn (m:operation-inspectable-object (w:inspect-represented-object-operation) target) nil)
              (m:operation-not-applicable () t))))
  (dolist (operation (list (w:inspect-represented-object-operation) (w:inspect-topicmap-sign-operation)))
    (assert (handler-case (progn (m:operation-inspectable-object operation '(:type :topicmap-association)) nil)
              (m:operation-not-applicable () t)))))

(defun test-the-exact-occurrence-is-the-target (workspace topic)
  (dolist (case (list (list *radial* "test-only/radial-menu" :menu-visible)
                      (list *mark* "test-only/learned-mark" :marking)))
    (destructuring-bind (steps binding-id mode) case
      (let ((occurrence (%occurrence workspace topic)))
        (%feed occurrence steps)
        (assert (eq :completed (getf (%result occurrence) :state)))
        (assert (eq mode (getf (%result occurrence) :mode)))
        (multiple-value-bind (selected target) (%selected occurrence)
          (assert (equal binding-id selected))
          (assert (eq occurrence target)))))))

(defun test-occurrence-is-not-the-topic-id (workspace topic)
  "Falsifier A: two occurrences of one Topic are two objects, with their own
tokens and Gesture Windows; input to one does not reach the other."
  (let ((a (%occurrence workspace topic)) (b (%occurrence workspace topic)))
    (assert (equal (m:occurrence-topic-id a) (m:occurrence-topic-id b)))
    (assert (not (eq a b)))
    (assert (string/= (m:occurrence-token a) (m:occurrence-token b)))
    (assert (not (eq (m:occurrence-gesture-window a) (m:occurrence-gesture-window b))))
    (%feed b *mark*)
    (assert (null (g:gesture-window-log (m:occurrence-gesture-window a))))
    (assert (eq b (nth-value 1 (%selected b))))))

(defun test-topic-and-inspectable-object-differ (workspace topic)
  "Falsifier D: the inspectable object is what the Topic stands for."
  (let ((occurrence (%occurrence workspace topic)))
    (assert (eq topic (m:occurrence-topic occurrence)))
    (assert (typep (m:occurrence-topic occurrence) 'tm:topicmap-topic))
    (assert (m:occurrence-inspectable-object occurrence))
    (assert (eq (tm:topicmap-topic-object-of topic) (m:occurrence-inspectable-object occurrence)))
    (assert (not (typep (m:occurrence-inspectable-object occurrence) 'tm:topicmap-topic)))))

(defun test-inputs-record-trust (workspace topic)
  (let ((synthetic (%occurrence workspace topic)) (trusted (%occurrence workspace topic)))
    (%feed synthetic *mark*)
    (%feed trusted *mark* :trust "trusted")
    (assert (= 3 (length (m:occurrence-inputs synthetic))))
    (assert (notany (lambda (entry) (getf entry :trusted)) (m:occurrence-inputs synthetic)))
    (assert (every (lambda (entry) (getf entry :trusted)) (m:occurrence-inputs trusted)))))

(defun test-an-ended-occurrence-takes-no-input (workspace topic)
  (let ((occurrence (%occurrence workspace topic)))
    (m:invalidate-workspace-action-sign-occurrence occurrence)
    (%feed occurrence *mark*)
    (assert (null (m:occurrence-inputs occurrence)))
    (assert (null (g:gesture-window-log (m:occurrence-gesture-window occurrence))))))

(defun test-primary-refused (workspace topic)
  (let ((occurrence (%occurrence workspace topic)))
    (m::%receive-topic-gesture
     occurrence (list :type :workspace-action-sign-occurrence :occurrence occurrence)
     "pointerdown|untrusted|10:10:0:0:1:false:false:false:false:10:10:10:10:1:1")
    (assert (null (m:occurrence-inputs occurrence)))
    (assert (null (g:gesture-window-log (m:occurrence-gesture-window occurrence))))))

(defun test-occurrence-overview (workspace topic)
  (let ((occurrence (%occurrence workspace topic)))
    (labels ((html ()
               (html-inspector-views:view-html
                (find "Workspace action sign occurrence"
                      (html-inspector-views:all-views occurrence)
                      :key #'html-inspector-views:view-title :test #'equal))))
      (let ((current (html)))
        (dolist (label '("Current occurrence" "Topic ID" "Topic" "Projection"
                         "Workspace" "Inspectable object" "Element" "Pane"
                         "View" "Gesture Window"))
          (assert (search label current))))
      (m:invalidate-workspace-action-sign-occurrence occurrence)
      (assert (search "No longer current" (html))))))

(defun run-workspace-action-sign-tests ()
  (let* ((workspace (reading-workspace))
         (topic (%topic workspace *reachable-topic-id*)))
    (assert topic)
    (test-production-topic-inspections workspace topic)
    (test-the-exact-occurrence-is-the-target workspace topic)
    (test-occurrence-is-not-the-topic-id workspace topic)
    (test-topic-and-inspectable-object-differ workspace topic)
    (test-inputs-record-trust workspace topic)
    (test-primary-refused workspace topic)
    (test-an-ended-occurrence-takes-no-input workspace topic)
    (test-occurrence-overview workspace topic)
    (format t "~&WORKSPACE-ACTION-SIGN-OCCURRENCE-PASS: production inspections share identities/angles, exact targets and disjoint sectors; with test-only Bindings a radial and a mark complete on ~
the exact occurrence; two occurrences of one Topic are distinct; the ~
inspectable object is not the Topic; inputs record isTrusted; an ended ~
occurrence takes no input.~%")
    t))
