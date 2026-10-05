;;;; Live witness: Change work status by a Topic sign gesture, through CLOG.
;;;;
;;;; The ordinary Inspector, served on the loopback interface only, over a
;;;; Workspace of a temporary copy of Work Breakdown, in an image that has
;;;; loaded the authoring system. Lisp dispatches the browser events itself,
;;;; so they are synthetic (isTrusted false); a physical witness remains
;;;; manual. Run by hand, with a browser pointed at the URL it prints; not
;;;; part of the test operation.
(in-package #:dreyeck/work/authoring/tests)

(defvar *witness-signal* nil)
(defvar *witness-body* nil)
(defvar *witness-inspector* nil)
(defvar *witness-pane* nil)

(defun %witness-await (what predicate &key (seconds 60))
  (loop repeat (* 5 seconds)
        when (funcall predicate) return t
        do (sb-thread:wait-on-semaphore *witness-signal* :timeout 0.2)
        finally (error "Live witness timed out waiting for ~A." what)))

(defun %witness-panes ()
  (uiop:symbol-call :fset :convert 'list
                    (clog-moldable-inspector::inspector-panes *witness-inspector*)))

(defun %witness-js (script)
  (clog:js-query *witness-body* script))

(defun %witness-sign (topic-id)
  (find-if (lambda (occurrence)
             (and (eq *witness-pane* (m:occurrence-pane occurrence))
                  (m:workspace-action-sign-occurrence-current-p occurrence)
                  (equal topic-id (m:occurrence-topic-id occurrence))))
           (m:open-workspace-action-sign-occurrences)))

(defun %witness-pointer (occurrence name button buttons &optional (dx 0))
  "Explicitly synthetic browser input on OCCURRENCE's element."
  (clog:js-query (m:occurrence-element occurrence)
                 (format nil "(function(){const target=~A;const r=target.getBoundingClientRect();target.dispatchEvent(new PointerEvent('~A',{bubbles:true,pointerId:77,pointerType:'mouse',button:~D,buttons:~D,clientX:r.x+r.width/2+~D,clientY:r.y+r.height/2}));return true;})()"
                         (clog:script-id (m:occurrence-element occurrence)) name button buttons dx)))

(defun %witness-click (pane selector text)
  "Click the element under PANE matching SELECTOR whose text is TEXT, as the
page would receive it; the Inspector's own handler does the rest."
  (%witness-js
   (format nil "(function(){const p=document.getElementById('~A');const e=[...p.querySelectorAll('~A')].find(x=>x.textContent.trim()===~S);if(!e)return 'missing';e.dispatchEvent(new MouseEvent('click',{bubbles:true,button:0}));return 'clicked';})()"
           (clog:html-id (clog-moldable-inspector::clog-obj pane)) selector text)))

(defun %witness-pane-text (pane)
  (%witness-js (format nil "document.getElementById('~A').textContent"
                       (clog:html-id (clog-moldable-inspector::clog-obj pane)))))

(defun run-live-work-status-witness (&key (port 18089) (open-browser nil) done-file (linger 300))
  "Serve the Inspector on 127.0.0.1:PORT over a Workspace of a Work Breakdown
copy, then, once a browser has connected: a radial gesture on the Topic sign
of hyperdoc-page-authoring selects Change work status and opens the shared
operation request; its Change work status tab offers the statuses; choosing
\"in progress\" opens a complete request; previewing its plan and explicitly executing
that request opens a fresh Workspace, from which its outcome is inspected. Waits up to LINGER
seconds, or until DONE-FILE exists, before closing."
  (call-with-work-breakdown-fixture
   (lambda (page path)
     (let* ((projection (%project page path))
            (topic (tm:topicmap-projection-topic-by-id projection "hyperdoc-page-authoring"))
            (workspace (tm:make-topicmap-workspace projection "hyperdoc-page-authoring"))
            (operation (w:change-work-status-operation)))
       (setf *witness-signal* (sb-thread:make-semaphore)
             *witness-body* nil *witness-inspector* nil *witness-pane* nil)
       (clog:initialize
        (lambda (body)
          (setf *witness-body* body)
          (setf (clog:text (clog:create-style-block body)) clog-moldable-inspector::*css*)
          (setf *witness-inspector* (clog-moldable-inspector::create-inspector
                                     body :pane-width "900px" :playground? nil))
          (setf *witness-pane* (clog-moldable-inspector::create-pane
                                *witness-inspector* workspace :select "Topicmap"))
          (sb-thread:signal-semaphore *witness-signal*))
        :port port :host "127.0.0.1")
       (format t "~&WITNESS-LISTENING http://127.0.0.1:~D/~%" port)
       (finish-output)
       (when open-browser (clog:open-browser :url (format nil "http://127.0.0.1:~D/" port)))
       (%witness-await "a browser connection" (lambda () *witness-pane*) :seconds 600)
       ;; The Topic sign offers Change work status, here only.
       (%witness-await "the Topic sign" (lambda () (%witness-sign "hyperdoc-page-authoring")))
       (let* ((sign (%witness-sign "hyperdoc-page-authoring"))
              (window (m:occurrence-gesture-window sign)))
         (assert (equal '("binding/radial-menu-change-work-status" "binding/learned-mark-change-work-status")
                        (mapcar #'w:gesture-binding-id
                                (remove operation (m:workspace-action-sign-bindings sign)
                                        :key #'w:gesture-binding-operation :test-not #'eq))))
         (format t "~&WITNESS-SIGN: ~A offers ~{~A~^, ~}~%" (m:occurrence-topic-id sign)
                 (mapcar #'w:gesture-binding-id (m:workspace-action-sign-bindings sign)))
         ;; A radial gesture: press, wait for the menu, move right, release.
         (%witness-pointer sign "pointerdown" 2 2)
         (%witness-await "the radial menu"
                         (lambda () (eq :menu-visible (getf (dreyeck/gesture/clog:gesture-window-result window) :mode))))
         (%witness-pointer sign "pointermove" -1 2 70)
         (%witness-pointer sign "pointerup" 2 0 70)
         (%witness-await "the completed gesture"
                         (lambda () (eq :completed (getf (dreyeck/gesture/clog:gesture-window-result window) :state))))
         ;; The selection opens beside the Workspace pane.
         (%witness-await "the selection pane"
                         (lambda () (typep (%witness-last-object) 'a::work-editor-context)))
         (let ((selection (%witness-last-object))
               (selection-pane (car (last (%witness-panes)))))
           (assert (eq (a::editor-selection selection) (ops:work-topic-operation-request operation topic)))
           (assert (equal "shown" (clog:attribute (m:occurrence-element sign) "data-topic-gesture-outcome")))
           (format t "~&WITNESS-SELECTION-PASS: the gesture opened ~A, the Inspector's own selection.~%"
                   (prin1-to-string selection))
           ;; Its Change work status tab, then the status.
           (assert (equal "clicked" (%witness-click selection-pane ".inspector-tabs button" "Change work status")))
           (%witness-await "the Change work status view"
                           (lambda () (search "Change work status to \"in progress\""
                                              (%witness-pane-text selection-pane))))
           (assert (equal "clicked" (%witness-click selection-pane "button.inspector-action"
                                                    "Change work status to \"in progress\"")))
           ;; The status button now completes a request. Preview and execution
           ;; are separate Inspector actions; the executor replans the request.
           (%witness-await "the complete request"
                           (lambda () (typep (%witness-last-object) 'work:work-status-change-request)))
           (let ((request-pane (car (last (%witness-panes)))))
             (uiop:symbol-call :dreyeck/work/editor/tests :%browser-tab request-pane "Work request" "Preview plan")
             (uiop:symbol-call :dreyeck/work/editor/tests :%browser-open request-pane "button.inspector-action"
                               "Preview plan" 'a:work-status-change-plan))
           (let ((plan-pane (car (last (%witness-panes)))))
             (uiop:symbol-call :dreyeck/work/editor/tests :%browser-tab plan-pane "Work plan" "Execute request after revalidation")
             (uiop:symbol-call :dreyeck/work/editor/tests :%browser-open plan-pane "button.inspector-action"
                               "Execute request after revalidation" 'tm:topicmap-workspace))
           (let ((fresh-pane (car (last (%witness-panes)))))
             (uiop:symbol-call :dreyeck/work/editor/tests :%browser-tab fresh-pane "Work Breakdown" "Inspect execution outcome")
             (uiop:symbol-call :dreyeck/work/editor/tests :%browser-open fresh-pane ".inspector-inspect [id]"
                               "Inspect execution outcome" 'a:work-status-change-outcome))
           (%witness-await "the outcome pane"
                           (lambda () (typep (%witness-last-object) 'a:work-status-change-outcome))
                           :seconds 120)
           (let* ((outcome (%witness-last-object))
                  (outcome-pane (car (last (%witness-panes))))
                  (text (%witness-pane-text outcome-pane)))
             (assert (eq :applied (a:work-status-change-outcome-status outcome)))
             (assert (eq (a::editor-selection selection) (a:work-status-change-outcome-selection outcome)))
             (assert (equal "in progress" (%status (%project page path) "hyperdoc-page-authoring")))
             (let ((anchor (find "hyperdoc-page-authoring"
                                 (plump:get-elements-by-tag-name (hyperbook:dom-of page) "a")
                                 :key (lambda (node) (plump:attribute node "data-topic")) :test #'equal)))
               (assert (equal "in progress" (plump:attribute anchor "data-status"))))
             (dolist (needle '("operation/change-work-status" "applied" "in progress"))
               (assert (search needle text) () "The outcome pane does not show ~S." needle))
             (format t "~&WITNESS-OUTCOME-PASS: ~A; the page copy, its reloaded page object and the outcome pane show \"in progress\".~%"
                     (prin1-to-string outcome)))))
       (format t "~&LIVE-WORK-STATUS-WITNESS-PASS (synthetic input; physical witness remains manual).~%")
       (finish-output)
       (loop repeat (* 5 linger)
             until (and done-file (probe-file done-file))
             do (sleep 0.2))
       (ignore-errors (clog:shutdown))
       t))))

(defun %witness-last-object ()
  (let ((panes (and *witness-inspector* (%witness-panes))))
    (and (rest panes) (clog-moldable-inspector::pane-object (car (last panes))))))
