;;;; Live DOM evidence owned and checked by Lisp through CLOG. No JSON side channel.
(in-package #:dreyeck/topicmap/gesture/tests)

(defvar *live-signal* nil)
(defvar *live-body* nil)
(defvar *live-pane* nil)
(defvar *live-workspace* nil)
(defvar *live-occurrence* nil)
(defvar *previous-occurrence* nil)
(defvar *live-test-bindings* nil)

(defmethod clog-moldable-inspector::refresh :around
    ((pane clog-moldable-inspector::pane))
  (let ((m:*workspace-action-sign-bindings*
          (if (eq pane *live-pane*) *live-test-bindings*
              m:*workspace-action-sign-bindings*)))
    (multiple-value-prog1 (call-next-method)
      (when *live-signal* (sb-thread:signal-semaphore *live-signal*)))))

(defun %await-live (predicate)
  (loop repeat 150
        when (funcall predicate) return t
        do (sb-thread:wait-on-semaphore *live-signal* :timeout .2)
        finally (error "Live CLOG witness timed out.")))

(defun %pane-occurrences ()
  (remove-if-not (lambda (o) (and (eq *live-pane* (m:occurrence-pane o))
                                 (m:workspace-action-sign-occurrence-current-p o)))
                 (m:open-workspace-action-sign-occurrences)))

(defun %current-occurrence ()
  (find *reachable-topic-id* (%pane-occurrences) :key #'m:occurrence-topic-id :test #'equal))

(defun %watch-occurrence (occurrence)
  (let* ((window (m:occurrence-gesture-window occurrence))
         (original (g::gesture-window-projection window)))
    (setf (g::gesture-window-projection window)
          (lambda (window snapshot)
            (when original (funcall original window snapshot))
            (sb-thread:signal-semaphore *live-signal*))))
  occurrence)

(defun %js (occurrence expression)
  (clog:js-query (m:occurrence-element occurrence)
                (format nil "(function(){const target=~A;~A})()"
                        (clog:script-id (m:occurrence-element occurrence)) expression)))

(defun %assert-hit (occurrence)
  ;; A painted sibling has neither the action class nor the actual hit identity.
  (assert (equal "true"
                 (%js occurrence "const r=target.getBoundingClientRect();return target.tagName.toLowerCase()==='rect' && target.classList.contains('inspector-action') && document.elementFromPoint(r.x+r.width/2,r.y+r.height/2)===target;")))
  (assert (equal (m:occurrence-token occurrence)
                 (%js occurrence "return target.dataset.workspaceActionSignOccurrence;")))
  (assert (eq (m:occurrence-reference occurrence)
              (cdr (assoc (clog:html-id (m:occurrence-element occurrence))
                          (html-inspector-views:view-references (m:occurrence-view occurrence))
                          :test #'equal))))
  (assert (eq *live-workspace* (m:occurrence-workspace occurrence)))
  ;; TOPICMAP-PROJECTION-OF constructs a new projection on every call.
  ;; Check the retained rendering context, not a later reconstruction.
  (assert (eq *live-workspace*
              (tm:topicmap-projection-source-of (m:occurrence-projection occurrence))))
  (assert (eq (m:occurrence-topic occurrence)
              (tm:topicmap-projection-topic-by-id
               (m:occurrence-projection occurrence) (m:occurrence-topic-id occurrence))))
  occurrence)

(defun %pointer (occurrence name button buttons &optional (dx 0))
  "Explicitly synthetic browser input: isTrusted must be false."
  (%js occurrence
       (format nil "const r=target.getBoundingClientRect();target.dispatchEvent(new PointerEvent('~A',{bubbles:true,pointerId:77,pointerType:'mouse',button:~D,buttons:~D,clientX:r.x+r.width/2+~D,clientY:r.y+r.height/2}));return true;"
               name button buttons dx)))

(defun %browser-barrier (milliseconds)
  (let ((done nil))
    (clog::set-event *live-body* "occurrencetestbarrier"
                     (lambda (data) (declare (ignore data))
                       (setf done t) (sb-thread:signal-semaphore *live-signal*)))
    (clog:js-execute *live-body*
                     (format nil "setTimeout(()=>document.body.dispatchEvent(new Event('occurrencetestbarrier')),~D)"
                             milliseconds))
    (clog:flush-connection-cache *live-body*)
    (%await-live (lambda () done))))

(defun start-workspace-action-sign-witness (&key (port 18088) test-bindings (open-browser t))
  "Start the ordinary Inspector on the actual Reading Workspace. No layout edits.
TEST-BINDINGS is opt-in and inert; NIL is the production behavior."
  (setf *live-signal* (sb-thread:make-semaphore) *live-body* nil *live-pane* nil
        *live-workspace* (reading-workspace)
        *live-test-bindings* (when test-bindings (inert-test-bindings)))
  (clog:initialize
   (lambda (body)
     (let ((m:*workspace-action-sign-bindings* *live-test-bindings*))
       (setf *live-body* body)
       (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
       (let ((inspector (clog-moldable-inspector::create-inspector
                        body :pane-width "1000px" :playground? nil)))
         (setf *live-pane* (clog-moldable-inspector::create-pane
                           inspector *live-workspace* :select "Topicmap")))
       (sb-thread:signal-semaphore *live-signal*)))
   :port port :host "127.0.0.1")
  (when open-browser (clog:open-browser :url (format nil "http://127.0.0.1:~D/" port)))
  (%await-live (lambda () (and *live-pane* (%current-occurrence))))
  (setf *live-occurrence* (%watch-occurrence (%assert-hit (%current-occurrence))))
  (format t "~&REACHABLE-ACTION-SIGN: ~A (~A)~%"
          (m:occurrence-topic-id *live-occurrence*)
          (clog:html-id (m:occurrence-element *live-occurrence*)))
  *live-occurrence*)

(defun run-live-workspace-action-sign-test (&key (port 18088) (open-browser t))
  (let* ((a (start-workspace-action-sign-witness :port port :test-bindings t
                                                :open-browser open-browser))
         (point (tm:topicmap-workspace-point-of *live-workspace*)))
    ;; Fresh DOM observation, not a presumption that the preferred Topic is hit.
    (let ((preferred (find "asdf-system:dreyeck/topicmap/tala" (%pane-occurrences)
                           :key #'m:occurrence-topic-id :test #'equal)))
      (assert preferred)
      (assert (equal *reachable-topic-id*
                     (%js preferred "const r=target.getBoundingClientRect();return document.elementFromPoint(r.x+r.width/2,r.y+r.height/2).dataset.topicId;"))))
    (test-topic-and-inspectable-object-differ *live-workspace* (m:occurrence-topic a))
    ;; Instrument only in the test: primary must not ask for Gesture capture.
    (%js a "target.__captureCalls=0;const capture=target.setPointerCapture.bind(target);target.setPointerCapture=function(id){target.__captureCalls++;return capture(id);};return true;")
    (%pointer a "pointerdown" 0 1)
    (%browser-barrier 650)
    (assert (null (m:occurrence-inputs a)))
    (assert (null (g:gesture-window-log (m:occurrence-gesture-window a))))
    (assert (equal "0" (%js a "return target.__captureCalls;")))
    (%pointer a "pointerup" 0 0)
    ;; Scripted pointer events do not manufacture a native click. Exercise the
    ;; existing Inspector click separately; physical click remains manual.
    (%js a "target.dispatchEvent(new MouseEvent('click',{bubbles:true,button:0}));return true;")
    (%await-live (lambda () (equal *reachable-topic-id* (tm:topicmap-workspace-point-of *live-workspace*))))
    (%await-live (lambda () (let ((b (%current-occurrence))) (and b (not (eq a b))))))
    (assert (not (m:workspace-action-sign-occurrence-current-p a)))
    (assert (equal point (first (tm:topicmap-workspace-history-of *live-workspace*))))
    (setf *previous-occurrence* a
          *live-occurrence* (%watch-occurrence (%assert-hit (%current-occurrence))))
    (let ((b *live-occurrence*))
      (assert (not (eq a b)))
      (assert (m:workspace-action-sign-occurrence-current-p b))
      (format t "~&PRIMARY-REFRESH-PASS: A invalid, B current, ordinary Point/history; no Gesture input/capture/timer.~%")
      (%pointer b "pointerdown" 2 2)
      (%await-live (lambda () (eq :menu-visible (getf (%result b) :mode))))
      (%pointer b "pointermove" -1 2 70)
      (%pointer b "pointerup" 2 0 70)
      (%await-live (lambda () (eq :completed (getf (%result b) :state))))
      (assert (eq b (nth-value 1 (%selected b))))
      (assert (equal "test-only/radial-menu" (%selected b)))
      (%pointer b "pointerdown" 2 2)
      (%pointer b "pointermove" -1 2 70)
      (%pointer b "pointerup" 2 0 70)
      (%await-live (lambda () (and (eq :completed (getf (%result b) :state))
                                   (eq :marking (getf (%result b) :mode)))))
      (assert (eq b (nth-value 1 (%selected b))))
      (assert (equal "test-only/learned-mark" (%selected b)))
      (assert (notany (lambda (event) (getf event :trusted)) (m:occurrence-inputs b)))
      (assert (equal *reachable-topic-id* (tm:topicmap-workspace-point-of *live-workspace*)))
      (assert (= 1 (length (tm:topicmap-workspace-history-of *live-workspace*))))
      (assert (eq b (%current-occurrence)))
      (assert (equal "completed/marking"
                     (%js b "return target.dataset.topicGestureState+'/'+target.dataset.topicGestureMode;")))
      (format t "~&SECONDARY-PASS: radial + mark, exact occurrence, no navigation, isTrusted=false.~%")
      ;; Removing the element outside refresh must also end this occurrence.
      (%js b "target.remove();return true;")
      (assert (not (m:workspace-action-sign-occurrence-current-p b)))
      (clog-moldable-inspector::refresh *live-pane*)
      (setf *live-occurrence* (%current-occurrence))
      (assert *live-occurrence*)
      (clog:close-connection (clog:window *live-body*))
      (%await-live (lambda () (not (clog:validp (m:occurrence-element *live-occurrence*)))))
      (assert (not (m:workspace-action-sign-occurrence-current-p *live-occurrence*)))
      (format t "~&DISCONNECT-PASS: the last occurrence is no longer current.~%")))
  (format t "~&LIVE-CLOG-WORKSPACE-ACTION-SIGN-PASS (synthetic input; physical witness remains manual).~%")
  t)
