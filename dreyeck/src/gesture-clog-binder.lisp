;;;; A CLOG window that owns one marking-menu interaction.
;;;;
;;;; The transport, the input session and the reducer already exist and
;;;; know nothing of CLOG. This file is the only place they meet a browser
;;;; window, and it adds two things: ownership and serialization.
;;;;
;;;; Ownership: each window constructs its own witness -- one ordered
;;;; transport, one input session -- and one lock. A browser page is one
;;;; sequencing authority, its counter starts at one, and so does the
;;;; transport that belongs to it. Two windows sharing one transport was
;;;; measured to fuse a press from one with a deadline from the other.
;;;; The converse holds as well: several surfaces on one page share its
;;;; counter, so they share its window, and a press routes the interaction
;;;; to the surface it began on.
;;;;
;;;;   one browser sequencing authority
;;;;       <-> one ORDERED-TRANSPORT
;;;;       <-> one GESTURE-INPUT-SESSION
;;;;       <-> one serialization lock
;;;;
;;;; Serialization: CLOG runs every event on its own thread, so events
;;;; arrive in an order the browser did not send. Each callback takes the
;;;; window's lock and, holding it, enqueues its envelope, delivers every
;;;; envelope that is now contiguous, runs them through the adapter and
;;;; reducer, and updates the window. At most one execution context
;;;; mutates a window's transport and session at any time, and the reducer
;;;; sees envelopes only in reconstructed browser order. There is no
;;;; long-running consumer, because CLOG 2.2 has no hook that says a window
;;;; is gone; with nothing alive between callbacks, nothing has to be
;;;; stopped, and a window's objects become unreachable when CLOG drops its
;;;; connection data. Nothing here claims when that happens.

(defpackage #:dreyeck/gesture/clog
  (:use #:cl)
  (:local-nicknames (#:tp #:dreyeck/gesture/transport)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:sm #:dreyeck/state-machine)
                    (#:bt #:bordeaux-threads))
  (:export #:gesture-window #:make-gesture-window
           #:gesture-window-witness #:gesture-window-lock
           #:gesture-window-log #:gesture-window-result
           #:receive-envelope
           #:connection-gesture-window #:create-gesture-surface
           #:gesture-window-selection #:newly-completed-p
           #:on-gesture-window #:install-gesture-route
           #:open-gesture-windows))

(in-package #:dreyeck/gesture/clog)

(defclass gesture-window ()
  ((witness :initarg :witness :reader gesture-window-witness)
   (lock :initarg :lock :reader gesture-window-lock)
   (projection :initarg :projection :initform nil
               :accessor gesture-window-projection)
   (log :initform nil :accessor gesture-window-log)
   (surfaces :initform nil :accessor gesture-window-surfaces))
  (:documentation
   "One browser window's interaction: its own witness and its own lock.
PROJECTION, if any, is called with the window and a snapshot after every
delivered envelope, still under the lock. LOG holds the snapshots of the
current interaction, newest first; a new press starts a new one.
SURFACES pairs each subject a surface presses with the function that draws
on that surface; a page with several surfaces is still one window."))

(defun make-gesture-window (&key projection (bindings (w:make-gesture-binding-catalog)))
  "A fresh window: a transport, an input session and a lock of its own."
  (make-instance 'gesture-window
                 :witness (tp:make-gesture-transport-witness :bindings bindings)
                 :lock (bt:make-lock "gesture window")
                 :projection projection))

(defun %binding-id (gesture)
  (let ((binding (and gesture (w:gesture-session-selected-binding-of gesture))))
    (and binding (w:gesture-binding-id binding))))

(defun %snapshot (input envelope)
  (let ((gesture (tp:input-session-gesture-session input)))
    (list :sequence (tp:transport-envelope-sequence envelope)
          :kind (tp:transport-envelope-kind envelope)
          :state (and gesture (sm:state-machine-run-current-state-of gesture))
          :mode (and gesture (w:gesture-session-mode-of gesture))
          :menu-visible (and gesture (w:gesture-session-menu-visible-p-of gesture))
          :binding (%binding-id gesture))))

(defun receive-envelope (window envelope)
  "Everything one CLOG callback does, as one serialized unit.
Holding the window's lock: enqueue ENVELOPE, deliver whatever is now
contiguous, reduce it, record it and project it. An envelope that arrives
before its predecessor is enqueued and waits; the callback that brings
the predecessor delivers both. The lock is not recursive: a callback
that re-entered its own window from inside the projection would signal
rather than interleave."
  (bt:with-lock-held ((gesture-window-lock window))
    (let* ((witness (gesture-window-witness window))
           (transport (tp:witness-transport witness))
           (input (tp:witness-input witness)))
      (tp:enqueue-envelope transport envelope)
      (tp:drain-transport
       transport
       (lambda (delivered)
         (tp:consume-envelope input delivered)
         (when (eq :pointer-down (tp:transport-envelope-kind delivered))
           (setf (gesture-window-log window) nil))
         (let ((snapshot (%snapshot input delivered)))
           (push snapshot (gesture-window-log window))
           (let ((projection (gesture-window-projection window)))
             (when projection (funcall projection window snapshot))))))))
  window)

(defun gesture-window-result (window)
  "What the current interaction selected, as evidence. The Operation is
named, compared with the shared identity, and not executed."
  (let* ((gesture (tp:input-session-gesture-session
                   (tp:witness-input (gesture-window-witness window))))
         (operation (and gesture (w:gesture-session-selected-operation-of gesture))))
    (list :state (and gesture (sm:state-machine-run-current-state-of gesture))
          :mode (and gesture (w:gesture-session-mode-of gesture))
          :binding (%binding-id gesture)
          :operation (and operation (w:semantic-operation-identity-id operation))
          :shared-operation-p
          (and operation (eq operation (w:insert-executable-defexample-operation)))
          :executed nil)))
;;; The window in CLOG
;;;
;;; Everything below knows CLOG. Three of the names it uses are CLOG's
;;; internal ones -- SET-EVENT, POINTER-EVENT-SCRIPT, PARSE-POINTER-EVENT --
;;; because CLOG 2.2's public API binds no custom event and takes no
;;; callback script, and the sixth transport event, the reveal deadline,
;;; is a custom event the browser bridge dispatches.
;;;
;;; The page has no gesture state of its own. The browser numbers events
;;; and runs the reveal timer, as before; whether the menu shows, which
;;; sector is lit and what was chosen are read from the reducer after
;;; every delivered envelope.

(defparameter +menu-radius+ 72
  "How far from the press point a sector's label is drawn.")

(defun %catalog () (w:make-gesture-binding-catalog))

(defun %radial-bindings ()
  "The sectors a visible menu shows: every radial Binding with an angle,
enabled or not, from the same catalog the reducer selects from."
  (remove-if-not (lambda (binding)
                   (and (eq :radial-menu (w:gesture-binding-kind binding))
                        (numberp (w:gesture-binding-sector-center binding))))
                 (%catalog)))

(defun %mark-binding ()
  (find :learned-mark (%catalog) :key #'w:gesture-binding-kind))

(defun %label-text (binding)
  (format nil "~A~:[ (disabled)~;~]"
          (w:semantic-operation-identity-title (w:gesture-binding-operation binding))
          (w:gesture-binding-enabled-p binding)))

(defun %along (binding x y)
  "Where BINDING's sector lies, seen from X Y. The model measures angles in
CSS pixels with y growing downward, and so does this."
  (let ((angle (/ (* pi (w:gesture-binding-sector-center binding)) 180)))
    (list (+ x (* +menu-radius+ (cos angle)))
          (+ y (* +menu-radius+ (sin angle))))))

(defun %press-point (window)
  (let ((press (car (last (tp:input-session-prefix
                           (tp:witness-input (gesture-window-witness window)))))))
    (if press
        (list (w:gesture-input-sample-x press) (w:gesture-input-sample-y press))
        (list 0 0))))

(defun %place (element x y)
  (clog:set-styles element (list (list "left" (format nil "~Dpx" (round x)))
                                 (list "top" (format nil "~Dpx" (round y))))))

(defun %status-line (window)
  (let ((result (gesture-window-result window)))
    (format nil "~(~A~) / ~(~A~) / binding ~A / operation ~A~:[~; (the shared identity; not executed)~]"
            (or (getf result :state) "idle") (or (getf result :mode) "-")
            (or (getf result :binding) "-") (or (getf result :operation) "-")
            (getf result :shared-operation-p))))

(defun %project (window snapshot target labels mark status)
  "Show what the reducer says, and nothing it does not."
  (destructuring-bind (x y) (%press-point window)
    (let ((binding (getf snapshot :binding))
          (menu-visible (and (getf snapshot :menu-visible) t))
          (marked (and (eq :marking (getf snapshot :mode)) (getf snapshot :binding) t)))
      (dolist (entry labels)
        (destructuring-bind (sector . element) entry
          (apply #'%place element (%along sector x y))
          (clog:set-styles element
                           (list (list "background"
                                       (if (equal binding (w:gesture-binding-id sector))
                                           "#ffd54f" "#ffffff"))))
          (setf (clog:visiblep element) menu-visible)))
      (apply #'%place mark (%along (%mark-binding) x y))
      (setf (clog:visiblep mark) marked)
      (setf (clog:attribute target "data-state")
            (string-downcase (princ-to-string (getf snapshot :state)))
            (clog:attribute target "data-mode")
            (string-downcase (princ-to-string (getf snapshot :mode)))
            (clog:attribute target "data-menu-visible") (if menu-visible "true" "false")
            (clog:attribute target "data-binding") (or binding ""))
      (setf (clog:text status) (%status-line window)))))

(defun %envelope-from (kind data subject)
  (multiple-value-bind (buttons sequence) (tp:trailing-transport-fields data)
    (let ((parsed (clog::parse-pointer-event data)))
      (tp:make-transport-envelope
       :sequence sequence :kind kind :buttons buttons
       :which (getf parsed :which-button)
       :x (getf parsed :x) :y (getf parsed :y)
       :modifiers (remove nil (list (when (getf parsed :alt-key) :alt)
                                    (when (getf parsed :ctrl-key) :ctrl)
                                    (when (getf parsed :shift-key) :shift)
                                    (when (getf parsed :meta-key) :meta)))
       :target subject))))

(defun %bind-transport-events (window target subject)
  "The persisted bridge, installed on TARGET, feeding WINDOW about SUBJECT."
  (let ((script (tp:forwarding-script clog::pointer-event-script)))
    (dolist (entry (tp:transport-event-kinds))
      (destructuring-bind (name . kind) entry
        (clog::set-event target name
                         (lambda (data)
                           (receive-envelope window (%envelope-from kind data subject)))
                         :call-back-script script
                         :post-eval
                         (if (string= name "pointerdown")
                             ;; Real pointers can be captured; a synthetic
                             ;; one has no pointer to capture.
                             (format nil "; try { ~A.setPointerCapture(e.pointerId) } catch (x) {}"
                                     (clog:script-id target))
                             "")))))
  (clog:js-execute target (tp:reveal-timer-script (clog:script-id target)))
  ;; Cancelled in the browser and never numbered: a hole in the sequence
  ;; would be a queue that waits forever.
  (clog:set-on-context-menu target (lambda (object) (declare (ignore object)) nil)))

(defvar *open-windows* nil
  "Weak pointers to the gesture windows created so far, for inspection.
It holds no window alive and shares nothing between windows; CLOG's
connection data is what keeps a window reachable.")

(defvar *open-windows-lock* (bt:make-lock "open gesture windows"))

(defun open-gesture-windows ()
  "The gesture windows still reachable, newest first. Listing them does not
keep them alive."
  (bt:with-lock-held (*open-windows-lock*)
    (setf *open-windows* (remove-if-not #'sb-ext:weak-pointer-value *open-windows*))
    (mapcar #'sb-ext:weak-pointer-value *open-windows*)))

(defun %press-sample (window)
  "The pointer-down that began the current interaction, if any."
  (car
   (last
    (tp:input-session-prefix
     (tp:witness-input (gesture-window-witness window))))))

(defun gesture-window-selection (window)
  "The Binding the current interaction completed with, and the subject it
was pressed on, as two values; both NIL unless it completed with one.
The subject is what the surface said it was about. Nothing here reads it."
  (let ((gesture
         (tp:input-session-gesture-session
          (tp:witness-input (gesture-window-witness window))))
        (press (%press-sample window)))
    (if (and gesture
             (eq :completed (sm:state-machine-run-current-state-of gesture))
             (w:gesture-session-selected-binding-of gesture))
        (values (w:gesture-session-selected-binding-of gesture)
                (and press (w:gesture-input-sample-target press)))
        (values nil nil))))

(defun newly-completed-p (window snapshot)
  "True for the one snapshot in which the current interaction completed
with a Binding; the envelopes after it leave the state where it was."
  (and (eq :completed (getf snapshot :state)) (getf snapshot :binding)
       (not
        (eq :completed (getf (second (gesture-window-log window)) :state)))))

(defun %route-to-surface (window snapshot)
  "Draw SNAPSHOT on the surface the current interaction was pressed on,
found by the identity of the subject its press carried."
  (let* ((press (%press-sample window))
         (surface
          (and press
               (cdr
                (assoc (w:gesture-input-sample-target press)
                       (gesture-window-surfaces window) :test #'eq)))))
    (when surface (funcall surface window snapshot))))

(defun connection-gesture-window (clog-obj)
  "The gesture window of CLOG-OBJ's browser page, made on first use.
A page numbers its events with one counter, so it is one sequencing
authority, and every surface on it forwards into this one window. It
lives in the connection's data and goes when CLOG drops that."
  (bt:with-lock-held (*open-windows-lock*)
    (or (clog:connection-data-item clog-obj "dreyeck/gesture-window")
        (let ((window (make-gesture-window :projection #'%route-to-surface)))
          (push (sb-ext:make-weak-pointer window) *open-windows*)
          (setf (clog:connection-data-item clog-obj "dreyeck/gesture-window")
                  window)))))

(defun create-gesture-surface
       (parent
        &key
        (subject (list :type :lisp-source-definition :name 'gesture-window))
        (width "480px") (height "360px") on-completed)
  "A gesture target inside PARENT, feeding its page's gesture window.
SUBJECT is what a press here is about: it travels with the pointer-down
into the reducer and comes back as the subject of the selection. It is
compared by identity, so each surface needs a subject of its own.
ON-COMPLETED, if given, is called once with the window when an
interaction pressed here completes with a Binding; if it signals, the
condition is shown on the surface instead of reaching CLOG."
  (let* ((target (clog:create-div parent))
         (status (clog:create-div parent :content "idle"))
         (labels
          (mapcar
           (lambda (binding)
             (cons binding
                   (clog:create-div target :content (%label-text binding))))
           (%radial-bindings)))
         (mark
          (clog:create-div target :content
                           (format nil "mark: ~A"
                                   (%label-text (%mark-binding)))))
         (window (connection-gesture-window parent)))
    (clog:set-styles target
                     (list (list "position" "relative") (list "width" width)
                           (list "height" height) (list "background" "#dde")
                           (list "touch-action" "none") (list "cursor" "crosshair")
                           (list "user-select" "none")))
    (setf (clog:attribute target "data-gesture-target") "true")
    ;; What the surface is for, not what state it is in: the reducer keeps
    ;; the state labels. The physical input named here is this binder's.
    (clog:set-styles (clog:create-div target
                                      :content "Right-click: hold for menu &middot; move to mark")
                     '(("position" "absolute") ("left" "8px") ("top" "50%")
                       ("transform" "translateY(-50%)") ("color" "#556")
                       ("font-family" "sans-serif") ("font-size" "11px")
                       ("white-space" "nowrap") ("pointer-events" "none")))
    (dolist (element (cons mark (mapcar #'cdr labels)))
      (clog:set-styles element
                       '(("position" "absolute")
                         ("transform" "translate(-50%, -50%)")
                         ("padding" "4px 8px") ("border" "1px solid #555")
                         ("font-family" "sans-serif") ("font-size" "13px")
                         ("white-space" "nowrap") ("pointer-events" "none")
                         ("z-index" "10")))
      (setf (clog:visiblep element) nil))
    (dolist (entry labels)
      (unless (w:gesture-binding-enabled-p (car entry))
        (clog:set-styles (cdr entry)
                         '(("color" "#999") ("font-style" "italic")))))
    (flet ((draw (window snapshot)
             (%project window snapshot target labels mark status)
             (when (and on-completed (newly-completed-p window snapshot))
               (handler-case (funcall on-completed window)
                             (error (condition)
                                    (setf (clog:text status)
                                            (format nil "nothing requested: ~A"
                                                    condition)))))))
      (bt:with-lock-held ((gesture-window-lock window))
        (push (cons subject #'draw) (gesture-window-surfaces window))))
    (%bind-transport-events window target subject)
    window))

(defun on-gesture-window (body)
  "The CLOG handler for the gesture route: one page, one surface."
  (setf (clog:title (clog:html-document body)) "Marking menu")
  (create-gesture-surface body))

(defun install-gesture-route (&key (path "/gesture"))
  "Serve PATH from the CLOG server that is already running. Starts none."
  (clog:set-on-new-window #'on-gesture-window :path path)
  path)
