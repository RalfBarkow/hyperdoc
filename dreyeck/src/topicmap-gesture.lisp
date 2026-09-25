;;;; Contextual Gesture input on each occurrence of a Topic's workspace action sign.
;;;;
;;;; The workspace action sign is the hit rectangle that
;;;; %RENDER-NATIVE-TOPICMAP-WORKSPACE-ACTION-SIGN draws over a Topic; a
;;;; primary click on it makes that Topic the Point. That stays exactly as
;;;; it is. A secondary press on the same element is routed through the
;;;; existing Gesture transport and reducer, with the element's occurrence
;;;; as the target.
;;;;
;;;; The occurrence retains the Topic, Projection and Workspace used for
;;;; this rendering. A refresh replaces the element and a closed browser
;;;; loses it. An occurrence is the element together with what it was
;;;; rendered for, and it ends with the element. The same Topic rendered
;;;; again is a new occurrence.
;;;;
;;;; No Topic Operation is installed here. Production Bindings are empty,
;;;; so a secondary gesture is recognized and completes with nothing.

(in-package #:dreyeck/inspector/topicmap)

(defclass topic-action-reference (views:thunk)
  ((topic :initarg :topic :reader action-topic)
   (projection :initarg :projection :reader action-projection)
   (workspace :initarg :workspace :reader action-workspace))
  (:documentation "The ordinary workspace action thunk, with the Topic,
Projection and Workspace it was rendered for. It is still an Inspector
action, not a Gesture Operation."))

(defclass workspace-action-sign-occurrence ()
  ((reference :initarg :reference :reader occurrence-reference)
   (element :initarg :element :reader occurrence-element)
   (pane :initarg :pane :reader occurrence-pane)
   (view :initarg :view :reader occurrence-view)
   (token :initform (symbol-name (gensym "workspace-action-sign-"))
          :reader occurrence-token
          :documentation "Identifies the browser element belonging to this
occurrence while it is current. It does not identify the Topic.")
   (current :initform t :accessor %occurrence-current)
   (inputs :initform nil :accessor occurrence-inputs
           :documentation "Secondary-button events observed on this element,
newest first, each with the browser's isTrusted flag. isTrusted false means
the event was dispatched by script; true means it entered through the
browser's input pipeline, which is not proof of a person at a device.")
   (window :accessor occurrence-gesture-window))
  (:documentation "Represents one concrete occurrence of a Topic's workspace
action sign in an Inspector view. It records the Topic, Projection,
Workspace, View, Pane, browser element, and Gesture Window associated with
that occurrence. A refresh or disconnected browser ends the occurrence."))

(defun occurrence-topic (occurrence) (action-topic (occurrence-reference occurrence)))
(defun occurrence-topic-id (occurrence)
  (dreyeck/topicmap:topicmap-topic-id-of (occurrence-topic occurrence)))
(defun occurrence-projection (occurrence) (action-projection (occurrence-reference occurrence)))
(defun occurrence-workspace (occurrence) (action-workspace (occurrence-reference occurrence)))
(defun occurrence-inspectable-object (occurrence)
  "The inspectable object the Topic stands for, not the Topic itself."
  (dreyeck/topicmap:topicmap-topic-object-of (occurrence-topic occurrence)))

(defvar *workspace-action-sign-bindings* nil
  "The Gesture Bindings a workspace action sign offers. None in production:
no Topic Operation is established. Read when an occurrence is created.")

(defvar *workspace-action-sign-occurrences* nil
  "Weak references for inspection; never a store.")

(defun open-workspace-action-sign-occurrences ()
  (setf *workspace-action-sign-occurrences*
        (remove-if-not #'sb-ext:weak-pointer-value *workspace-action-sign-occurrences*))
  (remove nil (mapcar #'sb-ext:weak-pointer-value *workspace-action-sign-occurrences*)))

(defun workspace-action-sign-occurrence-current-p (occurrence)
  "Whether the element is still the one this occurrence describes: not ended
by a refresh, the connection alive, and the element in the document with
this occurrence's token. Asks the browser; once false, stays false."
  (and (%occurrence-current occurrence)
       (or (and (clog:validp (occurrence-element occurrence))
                (equal "true"
                       (clog:js-query
                        (occurrence-element occurrence)
                        (format nil "(function(){var e=~A;return !!(e && e.isConnected && e.dataset.workspaceActionSignOccurrence === '~A');})()"
                                (clog:script-id (occurrence-element occurrence))
                                (occurrence-token occurrence))
                        :default-answer "false")))
           (progn (setf (%occurrence-current occurrence) nil) nil))))

(defun invalidate-workspace-action-sign-occurrence (occurrence)
  (setf (%occurrence-current occurrence) nil)
  (when (clog:validp (occurrence-element occurrence))
    (clog:js-execute (occurrence-element occurrence)
                     (format nil "(function(){var e=~A;if(e && e.__disposeTopicGesture)e.__disposeTopicGesture();})()"
                             (clog:script-id (occurrence-element occurrence))))))

(defmethod clog-moldable-inspector::refresh :before
    ((pane clog-moldable-inspector::pane))
  (dolist (occurrence (open-workspace-action-sign-occurrences))
    (when (eq pane (occurrence-pane occurrence))
      (invalidate-workspace-action-sign-occurrence occurrence))))

(defun secondary-topic-script (element-expression)
  "Each occurrence's element is its own sequencing authority. PRIMARY never
captures, starts a timer, emits an event or prevents its ordinary click."
  (format nil "(function(){
 const target=~A;
 if(target.__disposeTopicGesture) target.__disposeTopicGesture();
 let active=null, timer=null, sequence=0;
 const listeners=[];
 function clear(){if(timer!==null)clearTimeout(timer);timer=null;}
 function emit(kind,e,trusted){
   const r=target.getBoundingClientRect();
   const data=[e.clientX-r.left,e.clientY-r.top,e.screenX||0,e.screenY||0,
     kind==='pointerdown'||kind==='pointerup'?3:0,!!e.altKey,!!e.ctrlKey,
     !!e.shiftKey,!!e.metaKey,e.clientX,e.clientY,e.pageX||0,e.pageY||0,
     e.buttons,++sequence].join(':');
   target.dispatchEvent(new CustomEvent('topicgesture',
     {detail:kind+'|'+(trusted?'trusted':'untrusted')+'|'+data}));
 }
 function on(kind,fn){target.addEventListener(kind,fn);listeners.push([kind,fn]);}
 on('pointerdown',e=>{
   if(e.button!==2 || active!==null)return;
   active=e.pointerId;
   emit('pointerdown',e,e.isTrusted);
   try{target.setPointerCapture(e.pointerId);}catch(_){}
   timer=setTimeout(()=>{timer=null;if(active!==null && target.isConnected)
     emit('gesturerevealdeadline',e,false);},500);
 });
 on('pointermove',e=>{if(e.pointerId===active)emit('pointermove',e,e.isTrusted);});
 on('pointerup',e=>{if(e.pointerId!==active || e.button!==2)return;
   emit('pointerup',e,e.isTrusted);clear();active=null;});
 on('pointercancel',e=>{if(e.pointerId!==active)return;
   emit('pointercancel',e,e.isTrusted);clear();active=null;});
 on('lostpointercapture',e=>{if(e.pointerId!==active)return;
   emit('lostpointercapture',e,e.isTrusted);clear();active=null;});
 on('contextmenu',e=>{e.preventDefault();});
 const observer=new MutationObserver(()=>{if(!target.isConnected)dispose();});
 function dispose(){clear();
   if(active!==null){try{target.releasePointerCapture(active);}catch(_){}}
   active=null;listeners.forEach(([k,f])=>target.removeEventListener(k,f));
   observer.disconnect();delete target.__disposeTopicGesture;
 }
 observer.observe(document.documentElement,{childList:true,subtree:true});
 target.__disposeTopicGesture=dispose;
})();" element-expression))

(defun %receive-topic-gesture (occurrence target data)
  "One forwarded event: KIND|TRUSTED|PAYLOAD. Refuse queued input for an
ended occurrence, including removal outside the Inspector refresh path."
  (when (workspace-action-sign-occurrence-current-p occurrence)
    (let* ((first (position #\| data))
           (second (and first (position #\| data :start (1+ first))))
           (kind (and second
                      (cdr (assoc (subseq data 0 first)
                                  (dreyeck/gesture/transport:transport-event-kinds)
                                  :test #'string=)))))
      (when kind
        (let ((envelope (dreyeck/gesture/clog::%envelope-from
                         kind (subseq data (1+ second)) target)))
          ;; The browser filters before assigning a sequence number. This is
          ;; a defensive check at the same adapter boundary, not reducer policy.
          (when (and (eq kind :pointer-down)
                     (/= 3 (or (dreyeck/gesture/transport:transport-envelope-which envelope) 0)))
            (return-from %receive-topic-gesture nil))
          (push (list :kind kind
                      :sequence (dreyeck/gesture/transport:transport-envelope-sequence envelope)
                      :trusted (string= "trusted" (subseq data (1+ first) second)))
                (occurrence-inputs occurrence))
          (dreyeck/gesture/clog:receive-envelope
           (occurrence-gesture-window occurrence) envelope))))))

(defun bind-workspace-action-sign-occurrence (occurrence)
  (let* ((element (occurrence-element occurrence))
         ;; The reducer matches Bindings against the target's :TYPE; the
         ;; occurrence itself travels in the target, as the exact object.
         (target (list :type :workspace-action-sign-occurrence :occurrence occurrence))
         (window
           (dreyeck/gesture/clog:make-gesture-window
            :bindings *workspace-action-sign-bindings*
            :projection
            (lambda (window snapshot)
              (declare (ignore window))
              (when (%occurrence-current occurrence)
                (setf (clog:attribute element "data-topic-gesture-state")
                      (string-downcase (princ-to-string (getf snapshot :state)))
                      (clog:attribute element "data-topic-gesture-mode")
                      (string-downcase (princ-to-string (getf snapshot :mode)))))))))
    (setf (occurrence-gesture-window occurrence) window
          (clog:attribute element "data-workspace-action-sign-occurrence")
          (occurrence-token occurrence))
    (clog::set-event element "topicgesture"
                     (lambda (data) (%receive-topic-gesture occurrence target data))
                     :call-back-script "+ e.originalEvent.detail")
    (clog:js-execute element (secondary-topic-script (clog:script-id element)))
    occurrence))

(defmethod clog-moldable-inspector::create-view-element :after
    (pane parent (view views:html-view))
  ;; The Inspector has just wired its ordinary click to these action ids.
  ;; Gesture input goes on the same element, never on a sibling or overlay.
  (dolist (entry (views:view-references view))
    (when (typep (cdr entry) 'topic-action-reference)
      (let ((occurrence (make-instance 'workspace-action-sign-occurrence
                                       :reference (cdr entry)
                                       :element (clog:attach-as-child parent (car entry))
                                       :pane pane :view view)))
        (bind-workspace-action-sign-occurrence occurrence)
        (push (sb-ext:make-weak-pointer occurrence) *workspace-action-sign-occurrences*)))))

(views:defview workspace-action-sign-occurrence-overview
    (occurrence workspace-action-sign-occurrence)
  (views:html-view :title "Workspace action sign occurrence" :priority 1
    (views:html
      (:table :class "inspector-table"
        (:tr (:td "Status")
             (:td (views:esc (if (workspace-action-sign-occurrence-current-p occurrence)
                                 "Current occurrence"
                                 "No longer current"))))
        (:tr (:td "Topic ID") (:td (:tt (views:esc (occurrence-topic-id occurrence)))))
        (:tr (:td "Topic") (:td (views:object-ref (occurrence-topic occurrence))))
        (:tr (:td "Projection") (:td (views:object-ref (occurrence-projection occurrence))))
        (:tr (:td "Workspace") (:td (views:object-ref (occurrence-workspace occurrence))))
        (:tr (:td "Inspectable object")
             (:td (views:object-ref (occurrence-inspectable-object occurrence))))
        (:tr (:td "Element") (:td (views:object-ref (occurrence-element occurrence))))
        (:tr (:td "Pane") (:td (views:object-ref (occurrence-pane occurrence))))
        (:tr (:td "View") (:td (views:object-ref (occurrence-view occurrence))))
        (:tr (:td "Gesture Window")
             (:td (views:object-ref (occurrence-gesture-window occurrence)))))
      (:p "No Topic Operation is installed or executed."))))

;;;; What a selected read-only Operation shows
;;;;
;;;; A gesture is recognized, then completes with a Binding, whose Operation
;;;; is thereby selected; nothing is computed. OPERATION-INSPECTABLE-OBJECT is
;;;; the next step and only that one: the object a read-only Operation shows
;;;; for its exact target. Showing it in a pane is a further step not taken
;;;; here, and nothing is written, requested or remembered. One case is
;;;; recognized: Inspect relation contract on a Topicmap Association.

(define-condition operation-not-applicable (error)
  ((operation :initarg :operation :reader operation-not-applicable-operation)
   (target :initarg :target :reader operation-not-applicable-target)
   (reason :initarg :reason :reader operation-not-applicable-reason))
  (:report (lambda (condition stream)
             (format stream "~A does not apply: ~A"
                     (dreyeck/gesture-binding-witness:semantic-operation-identity-id
                      (operation-not-applicable-operation condition))
                     (operation-not-applicable-reason condition))))
  (:documentation "OPERATION shows nothing for TARGET. Distinct from a result."))

(defun operation-inspectable-object (operation target)
  "The inspectable object OPERATION shows for TARGET, a Gesture target plist.
TARGET must carry the exact Topicmap Association under :ASSOCIATION; an ID
names no Association. Signals OPERATION-NOT-APPLICABLE otherwise."
  (flet ((refuse (format-control &rest arguments)
           (error 'operation-not-applicable
                  :operation operation :target target
                  :reason (apply #'format nil format-control arguments))))
    (unless (eq operation
                (dreyeck/gesture-binding-witness:inspect-relation-contract-operation))
      (refuse "only Inspect relation contract shows an inspectable object"))
    (unless (eq :topicmap-association (getf target :type))
      (refuse "target type ~S is not :TOPICMAP-ASSOCIATION" (getf target :type)))
    (let ((association (getf target :association)))
      (unless (typep association 'dreyeck/topicmap:topicmap-association)
        (refuse "the target carries ~S, not a Topicmap Association" association))
      (or (getf (dreyeck/topicmap:topicmap-association-properties-of association)
                :relation-contract)
          (refuse "Association ~A refers to no Relation Contract"
                  (dreyeck/topicmap:topicmap-association-id-of association))))))
