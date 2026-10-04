;;;; Two concrete mechanisms, not a model of tutorial sessions.
(in-package #:dreyeck/clog-tutorial/reading)

(defclass tutorial-01-click-color ()
  ((objects :initarg :objects :reader observation-objects)
   (dispatches :initform nil :accessor observed-dispatches)
   (pending :initform nil)
   (sequence :initform 0)
   (active :initform t :accessor observation-active-p)))

(defclass tutorial-02-counter-output ()
  ((objects :initarg :objects :reader observation-objects)
   (dispatches :initform nil :accessor observed-dispatches)
   (pending :initform nil)
   (sequence :initform 0)
   (paragraphs :initform nil :accessor observed-paragraphs)
   (counter :initform 0 :accessor observed-counter)
   (active :initform t :accessor observation-active-p)))

(defvar *observe-tutorial-01* nil)
(defvar *observe-tutorial-02* nil)
(defvar *tutorial-01-windows* nil)
(defvar *tutorial-02-windows* nil)
(defvar *registering-click* nil)
(defvar *observing-output* nil)
(defvar *executing-tutorial-01* nil)
(defvar *initializing-tutorial* nil)
(defvar *observation-hook* nil)
(defvar *previous-clog-debug* nil)
(defvar *window-number* 0)

(defun %object (observation key)
  (gethash key (observation-objects observation)))

(defun %require-development ()
  (unless (second hyperbook/server::*server-parameters*)
    (error "Tutorial observation requires an explicit HyperDoc development server.")))

(defun %observation-connected-p (observation)
  ;; CLOG keeps this exact table through its reconnect grace period, then
  ;; removes it in HANDLE-CLOSE-CONNECTION. No browser query is involved.
  (let ((heading (%object observation "Heading"))
        (table (%object observation "Connection/event table")))
    (and heading table (eq table (clog:connection-data heading)))))

(defun %prune-windows (pointers)
  ;; Caller holds the metadata lock. Drop disconnected records even if an
  ;; Inspector/test still holds the observation strongly; GC is not required.
  (delete-if-not
   (lambda (pointer)
     (let ((observation (trivial-garbage:weak-pointer-value pointer)))
       (when observation
         (if (and (observation-active-p observation) (%observation-connected-p observation))
             t
             (progn (%release-observation observation) nil)))))
   pointers))

(defun %live-windows (number)
  ;; CLOG's live connection table owns the observer/observation cycle.
  ;; This reading's registry must not keep a closed connection alive.
  (bordeaux-threads:with-lock-held (*observation-lock*)
    (let ((pointers (ecase number (1 *tutorial-01-windows*) (2 *tutorial-02-windows*))))
      (setf pointers (%prune-windows pointers))
      (ecase number (1 (setf *tutorial-01-windows* pointers))
                    (2 (setf *tutorial-02-windows* pointers)))
      (remove nil (mapcar #'trivial-garbage:weak-pointer-value pointers)))))

(defun %armed-observation-result (number)
  ;; A scalar snapshot for Play's Inspector result, not an observed window.
  ;; Reuse the existing hash-table Items view without retaining runtime objects.
  (let ((result (make-hash-table :test #'equal))
        (count (length (%live-windows number))))
    (setf (gethash "Tutorial" result) (format nil "Tutorial ~2,'0D" number)
          (gethash "Observation" result) "Observation armed"
          (gethash "Observed windows" result) count
          (gethash "Window state" result)
          (if (zerop count) "No observed window yet" "Observed windows available in the reading")
          (gethash "Next step" result)
          "Open a NEW live tutorial window, interact, then reload the reading to inspect its retained mechanism.")
    result))

(defun %install-observation-hook ()
  ;; CLOG already calls this hook with the selected ON-NEW-WINDOW and BODY.
  ;; Install it only on explicit opt-in, without replacing any route/handler.
  (unless (and *observation-hook* (eq clog::*clog-debug* *observation-hook*))
    (let ((previous clog::*clog-debug*))
      (setf *previous-clog-debug* previous
            *observation-hook*
            (lambda (event data)
              (flet ((forward () (if previous (funcall previous event data)
                                    (funcall event data))))
                (let ((number
                        (when (and (second hyperbook/server::*server-parameters*)
                                   (typep data 'clog:clog-body))
                          (cond
                            ((and *observe-tutorial-01*
                                  (or (eq event (tut:tutorial-1-handler))
                                      (eq event (fdefinition (tut:tutorial-1-handler))))
                                  (equal (clog:connection-path data) "/clog-tutorial/01")) 1)
                            ((and *observe-tutorial-02*
                                  (or (eq event (tut:tutorial-2-handler))
                                      (eq event (fdefinition (tut:tutorial-2-handler))))
                                  (equal (clog:connection-path data) "/clog-tutorial/02")) 2)))))
                  (if number
                      (let ((*initializing-tutorial* (cons number data))) (forward))
                      (forward)))))
            clog::*clog-debug* *observation-hook*))))

(hyperdoc:defexample observe-tutorial-01
  "Retain Tutorial 01's objects in subsequently opened development windows.
This enables observation only: it mounts nothing and dispatches no click.
Play returns an armed-status snapshot, even before any window is observed.
After opening the existing live transport, refresh this reading."
  (%require-development)
  (setf *observe-tutorial-01* t)
  (%install-observation-hook)
  (%armed-observation-result 1))

(hyperdoc:defexample observe-tutorial-02
  "Retain Tutorial 02's objects and output in subsequently opened development
windows. This mounts nothing, dispatches no click and inspects no closure
environment. Play returns an armed-status snapshot, even before any window
is observed. After opening the existing live transport, refresh this reading."
  (%require-development)
  (setf *observe-tutorial-02* t)
  (%install-observation-hook)
  (%armed-observation-result 2))

(defun %observed-tutorial (heading)
  ;; A path alone is insufficient: only the original handler's dynamic extent
  ;; can retain a registration. Inspector/other callbacks on that path cannot.
  (when (and *initializing-tutorial*
             (second hyperbook/server::*server-parameters*)
             (ecase (car *initializing-tutorial*)
               (1 *observe-tutorial-01*) (2 *observe-tutorial-02*))
             (eq (cdr *initializing-tutorial*) (clog:connection-body heading)))
    (car *initializing-tutorial*)))

(defun %retain-click (number heading callback)
  (let* ((body (clog:connection-body heading))
         (objects (make-hash-table :test #'equal))
         (observation (make-instance (ecase number
                                       (1 'tutorial-01-click-color)
                                       (2 'tutorial-02-counter-output))
                                     :objects objects)))
    (setf (gethash "ON-NEW-WINDOW" objects)
          (fdefinition (ecase number (1 (tut:tutorial-1-handler)) (2 (tut:tutorial-2-handler))))
          (gethash "Body" objects) body
          (gethash "Window" objects) (clog:window body)
          (gethash "Heading" objects) heading
          (gethash "Tutorial callback" objects) callback
          (gethash "Connection/event table" objects) (clog:connection-data heading)
          (gethash "Event key" objects) (format nil "~A:click" (clog:html-id heading)))
    observation))

(defmethod clog:set-on-click :around ((heading clog:clog-element) callback
                                     &rest options &key one-time cancel-event)
  (declare (ignore options one-time cancel-event))
  (let ((number (and callback (%observed-tutorial heading))))
    (if (or (null number) *registering-click*)
        (call-next-method)
        (let* ((observation (%retain-click number heading callback))
               (*registering-click* observation))
          ;; The original callback argument is passed through unchanged.
          (multiple-value-prog1
              (call-next-method)
            (bordeaux-threads:with-lock-held (*observation-lock*)
              (when (%object observation "Registered observer")
                (if (not (ecase number (1 *observe-tutorial-01*) (2 *observe-tutorial-02*)))
                    ;; Release may have occurred while CLOG registered this
                    ;; not-yet-published observation. Do not leave a wrapper.
                    (%release-observation observation)
                    (progn
                      (setf (gethash "Window number" (observation-objects observation))
                            (incf *window-number*))
                      (let ((pointer (trivial-garbage:make-weak-pointer observation)))
                        (ecase number
                          (1 (setf *tutorial-01-windows*
                                   (cons pointer (%prune-windows *tutorial-01-windows*))))
                          (2 (setf *tutorial-02-windows*
                                   (cons pointer (%prune-windows *tutorial-02-windows*)))))))))))))))

(defun %begin-dispatch (observation)
  (bordeaux-threads:with-lock-held (*observation-lock*)
    (unless (observation-active-p observation) (return-from %begin-dispatch))
    (unless (%observation-connected-p observation)
      (%release-observation observation)
      (return-from %begin-dispatch))
    (let* ((pending (slot-value observation 'pending))
           (frame (list :number (incf (slot-value observation 'sequence))
                        :heading (%object observation "Heading")
                        :overlapping (not (null pending))
                        ;; Preallocate fields: GETF updates must preserve the
                        ;; frame's EQ identity in PENDING and output capture.
                        :completed nil :color-before nil :color-after nil
                        :execution nil
                        :counter-after nil :total-after nil
                        :paragraphs nil
                        :total-before (when (typep observation 'tutorial-02-counter-output)
                                        (length (observed-paragraphs observation)))
                        :counter-before (when (typep observation 'tutorial-02-counter-output)
                                          (observed-counter observation)))))
      (when (and (typep observation 'tutorial-01-click-color) (%object observation "CLOG dispatcher"))
        (setf (getf frame :execution) (%make-01-execution (observation-objects observation) frame)))
      ;; Protect evidence bookkeeping, not tutorial execution. CLOG's event
      ;; threads retain their original scheduling; overlapping calls are marked.
      (dolist (other pending) (setf (getf other :overlapping) t))
      (push frame (slot-value observation 'pending))
      frame)))

(defun %finish-dispatch (observation frame completed)
  (bordeaux-threads:with-lock-held (*observation-lock*)
    (unless (observation-active-p observation) (return-from %finish-dispatch))
    (unless (%observation-connected-p observation)
      (%release-observation observation)
      (return-from %finish-dispatch))
    (setf (slot-value observation 'pending)
          (remove frame (slot-value observation 'pending) :test #'eq)
          (getf frame :completed) completed)
    (when (typep observation 'tutorial-02-counter-output)
      (let* ((count (length (getf frame :paragraphs)))
             (reliable (and completed (plusp count) (not (getf frame :overlapping)))))
        ;; In the installed source, DOTIMES runs X times after INCF X.
        ;; This is an observed value inferred from output, not a lexical-cell
        ;; accessor. No closure environment or implementation-specific cell
        ;; is required. An incomplete/overlapping dispatch cannot establish it.
        (setf (getf frame :counter-before) (when reliable (1- count))
              (getf frame :counter-after) (when reliable count)
              (getf frame :total-after) (length (observed-paragraphs observation))
              (observed-counter observation) (getf frame :counter-after))))
    (setf (observed-dispatches observation)
          (sort (cons frame (observed-dispatches observation)) #'<
                :key (lambda (entry) (getf entry :number))))
    (when (getf frame :execution)
      (%append-01-step (getf frame :execution)
                       (list :kind :css-observed :target (getf frame :heading)
                             :before (getf frame :color-before) :after (getf frame :color-after))))))

(defun %append-01-step (execution step)
  ;; Caller holds the metadata lock. No lock serializes tutorial execution.
  (unless (eq :released (execution-completion execution))
    (setf (execution-steps execution) (append (execution-steps execution) (list step)))
    (case (getf step :kind)
      (:dispatcher-entered (setf (execution-completion execution) :running))
      (:dispatcher-returned (setf (execution-completion execution) :returned-normally))
      (:dispatcher-unwound (setf (execution-completion execution) :did-not-return-normally)))))

(defun %record-01-step (execution step)
  (when execution
    (bordeaux-threads:with-lock-held (*observation-lock*) (%append-01-step execution step))))

(defmethod (setf clog:color) :around (value (heading clog:clog-element))
  (let ((execution *executing-tutorial-01*))
    (when (and execution *observe-tutorial-01* (second hyperbook/server::*server-parameters*)
               (not (eq :released (execution-completion execution)))
               (eq heading (%execution-object execution "Heading")))
      (%record-01-step execution (list :kind :color-write :target heading :value value))))
  (call-next-method))

(defun %observe-dispatch (observation dispatcher data)
  (unless (and (observation-active-p observation)
               (second hyperbook/server::*server-parameters*)
               (etypecase observation
                 (tutorial-01-click-color *observe-tutorial-01*)
                 (tutorial-02-counter-output *observe-tutorial-02*)))
    (return-from %observe-dispatch (funcall dispatcher data)))
  (let* ((frame (%begin-dispatch observation))
         (execution (when (and frame (eq dispatcher (%object observation "CLOG dispatcher")))
                      (getf frame :execution)))
         (completed nil)
         (*observing-output* (when (typep observation 'tutorial-02-counter-output)
                              (cons observation frame))))
    (unless frame (return-from %observe-dispatch (funcall dispatcher data)))
    (when (typep observation 'tutorial-01-click-color)
      (setf (getf frame :color-before) (ignore-errors (clog:color (%object observation "Heading")))))
    (unwind-protect
         (let ((*executing-tutorial-01* execution))
           (%record-01-step execution (list :kind :dispatcher-entered :dispatcher dispatcher))
           (multiple-value-prog1 (funcall dispatcher data)
             (setf completed t)
             (%record-01-step execution (list :kind :dispatcher-returned))))
      (unless completed (%record-01-step execution (list :kind :dispatcher-unwound)))
      (when (and (observation-active-p observation) (typep observation 'tutorial-01-click-color))
        (setf (getf frame :color-after) (ignore-errors (clog:color (%object observation "Heading")))))
      (%finish-dispatch observation frame completed))))

(defmethod clog::set-event :around ((heading clog:clog-obj) event dispatcher
                                  &rest options &key call-back-script pre-eval eval-script
                                    post-eval cancel-event one-time)
  (declare (ignore options call-back-script pre-eval eval-script post-eval cancel-event one-time))
  (let ((observation *registering-click*))
    (if (and observation (observation-active-p observation)
             (second hyperbook/server::*server-parameters*)
             dispatcher (equal event "click")
             (eq heading (%object observation "Heading")))
        (let ((observer (lambda (data) (%observe-dispatch observation dispatcher data))))
          ;; First run the original registration with every original argument
          ;; (including DISPATCHER), preserving even secondary return values.
          ;; Only afterwards replace this specific table entry with an observer.
          (multiple-value-prog1 (call-next-method)
            (bordeaux-threads:with-lock-held (*observation-lock*)
              (let ((table (%object observation "Connection/event table"))
                    (key (%object observation "Event key")))
                (when (and (observation-active-p observation)
                           (etypecase observation
                             (tutorial-01-click-color *observe-tutorial-01*)
                             (tutorial-02-counter-output *observe-tutorial-02*))
                           table (eq (gethash key table) dispatcher))
                  (setf (gethash "CLOG dispatcher" (observation-objects observation)) dispatcher
                        (gethash "Registered observer" (observation-objects observation)) observer
                        (gethash key table) observer))))))
        (call-next-method))))

(defmethod clog:create-child :around ((body clog:clog-obj) html
                                     &rest options &key html-id auto-place clog-type)
  (declare (ignore html options html-id auto-place clog-type))
  (if (and *observing-output*
           (second hyperbook/server::*server-parameters*)
           (observation-active-p (car *observing-output*))
           (eq body (%object (car *observing-output*) "Body")))
      (let ((results (multiple-value-list (call-next-method))))
        (bordeaux-threads:with-lock-held (*observation-lock*)
          (let ((observation (car *observing-output*)) (frame (cdr *observing-output*)))
            (when (and (observation-active-p observation) (first results))
              (setf (getf frame :paragraphs) (append (getf frame :paragraphs) (list (first results)))
                    (observed-paragraphs observation)
                    (append (observed-paragraphs observation) (list (first results)))))))
        (values-list results))
      (call-next-method)))

(defun %release-observation (observation)
  (let* ((objects (observation-objects observation))
         (table (%object observation "Connection/event table"))
         (key (%object observation "Event key"))
         (number (%object observation "Window number")))
    (when (and table (eq (gethash key table) (%object observation "Registered observer")))
      (setf (gethash key table) (%object observation "CLOG dispatcher")))
    (dolist (frame (append (observed-dispatches observation) (slot-value observation 'pending)))
      (when (getf frame :execution) (%release-01-execution (getf frame :execution))))
    (setf (observation-active-p observation) nil
          (observed-dispatches observation) nil
          (slot-value observation 'pending) nil)
    (when (typep observation 'tutorial-02-counter-output)
      (setf (observed-paragraphs observation) nil (observed-counter observation) nil))
    (clrhash objects)
    (setf (gethash "Window number" objects) number)))

(hyperdoc:defexample release-tutorial-observations
  "Stop observation and clear captured bindings even in observations held by
the Inspector. This unmounts nothing and changes no tutorial
callback or state. Closed windows also become collectible through the weak
registry once CLOG releases their connection table."
  (%require-development)
  (bordeaux-threads:with-lock-held (*observation-lock*)
      (setf *observe-tutorial-01* nil *observe-tutorial-02* nil)
      (dolist (pointer (append *tutorial-01-windows* *tutorial-02-windows*))
        (let ((observation (trivial-garbage:weak-pointer-value pointer)))
          (when observation (%release-observation observation))))
      (setf *tutorial-01-windows* nil *tutorial-02-windows* nil)
      (when (and *observation-hook* (eq clog::*clog-debug* *observation-hook*))
        (setf clog::*clog-debug* *previous-clog-debug*))
      (setf *observation-hook* nil *previous-clog-debug* nil))
  :released)

(defmethod hv:text-representation ((observation tutorial-01-click-color))
  (format nil "Tutorial 01, window ~D" (%object observation "Window number")))
(defmethod hv:text-representation ((observation tutorial-02-counter-output))
  (format nil "Tutorial 02, window ~D" (%object observation "Window number")))

(defun %binding-html (observation)
  (hv:html
    (:table :class "inspector-table"
      (loop for (key view label) in '(("ON-NEW-WINDOW" "Source code")
                               ("Heading" "Tree") ("Body" "Slots") ("Window" "Slots" "CLOG window")
                               ("Tutorial callback" "Source code" "original tutorial callback")
                               ("CLOG dispatcher" "Source code" "original click dispatcher")
                               ("Registered observer" "Source code" "forwarding observer")
                               ("Connection/event table" "Items"))
            do (hv:html (:tr (:th :style "text-align:left" (hv:esc key))
                             (:td (hv:object-ref (%object observation key) :select view :display label)))))
      (:tr (:th :style "text-align:left" "Click registration")
           (:td (:code (hv:esc (%object observation "Event key")))
                (hv:esc " → ")
                (hv:object-ref (gethash (%object observation "Event key")
                                        (%object observation "Connection/event table"))
                               :select "Source code" :display "registered function")
                (unless (eq (%object observation "Registered observer")
                            (gethash (%object observation "Event key")
                                     (%object observation "Connection/event table")))
                  (hv:esc " (registration changed since capture)")))))
    (:p "The registered observer forwards to the original CLOG dispatcher, which calls the original tutorial callback with this heading.")
    (:p (hv:esc "Browser DOM effect: ")
        (hv:object-ref (%object observation "Heading") :display "heading HTML" :select "HTML"))))

(defun %dispatch-status (frame)
  (cond ((not (getf frame :completed)) "incomplete")
        ((getf frame :overlapping) "overlapping")
        (t "completed")))

(hv:defview click-color (observation tutorial-01-click-color)
  (hv:html-view :title "Click → color" :priority 0
    (if (not (observation-active-p observation))
        (hv:html (:p "Observation released; no runtime objects retained."))
        (progn
    (%binding-html observation)
    (hv:html
      (:table :class "inspector-table"
        (:tr (:th "Dispatch") (:th "Original heading") (:th "Color before") (:th "Color after") (:th "Observation"))
        (dolist (frame (observed-dispatches observation))
          (hv:html (:tr (:td (hv:esc (princ-to-string (getf frame :number))))
                        (:td (hv:object-ref (getf frame :heading) :select "Tree"))
                        (:td (hv:esc (%color-label (getf frame :color-before))))
                        (:td (hv:esc (%color-label (getf frame :color-after))))
                        (:td (hv:esc (%dispatch-status frame))
                             (when (getf frame :execution)
                               (hv:html " · " (hv:object-ref (getf frame :execution) :select "Dispatch execution"))))))))
      (unless (observed-dispatches observation)
        (hv:html (:p (hv:esc (if (slot-value observation 'pending)
                        "A click observation is in progress; refresh after completion."
                        "No click observed in this window."))))))))))

(hv:defview counter-output (observation tutorial-02-counter-output)
  (hv:html-view :title "Counter → output" :priority 0
    (if (not (observation-active-p observation))
        (hv:html (:p "Observation released; no runtime objects retained."))
        (progn
    (%binding-html observation)
    (hv:html
      (:p "X is an observed lexical-state value inferred from this callback's output and the installed INCF/DOTIMES forms. Its lexical cell is not generally exposed by the Inspector.")
      (:table :class "inspector-table"
        (:tr (:th "Dispatch") (:th "X before") (:th "X after") (:th "New paragraphs") (:th "Total") (:th "Observation"))
        (dolist (frame (observed-dispatches observation))
          (hv:html (:tr (:td (hv:esc (princ-to-string (getf frame :number))))
                        (:td (hv:esc (princ-to-string (or (getf frame :counter-before) "unavailable"))))
                        (:td (hv:esc (princ-to-string (or (getf frame :counter-after) "unavailable"))))
                        (:td (hv:esc (format nil "+~D" (length (getf frame :paragraphs)))))
                        (:td (hv:esc (princ-to-string (getf frame :total-after))))
                        (:td (hv:esc (%dispatch-status frame)))))
          (dolist (paragraph (getf frame :paragraphs))
            (hv:html (:tr (:td :colspan "6"
                          (hv:object-ref paragraph :select "HTML")
                          (hv:esc " — creation parent: ")
                          (hv:object-ref (clog:parent paragraph) :select "Slots")))))))
      (unless (observed-dispatches observation)
        (hv:html (:p (hv:esc (if (slot-value observation 'pending)
                        "A click observation is in progress; refresh after completion."
                        "No click observed; X starts at 0 and this window has no output paragraphs."))))))))))

(defun %observed-reading (windows mechanism)
  (hv:html-view :title "Observed windows" :priority 0
    (hv:html
      (if windows
          (progn
            (hv:html (:p "Observed development windows (each link opens its mechanism):"))
            (hv:html-table (reverse windows))
            (hv:transclusion (funcall mechanism (first windows)))
            (hv:html (:p "Click the heading in its live window, then refresh this Inspector view to read the new observation.")))
          (hv:html (:p "No observed development window in this image. The installed source remains available below. Rendering this reading enables no observer and runs no tutorial."))))))

(defun tutorial-01-live-page ()
  ;; Construct only the existing Web Page value. Its separate Inspector pane
  ;; loads the iframe; rendering/refreshing this reading never loads it.
  (when (and (second hyperbook/server::*server-parameters*) *observe-tutorial-01*
             (eq :mounted (route-state (tutorial-1-route))))
    (html-inspector-views/standard:make-web-page "/clog-tutorial/01" "Tutorial 01 – Live")))

(defun tutorial-01-reading ()
  (let* ((windows (%live-windows 1))
         (live (tutorial-01-live-page))
         (latest (when windows (car (last (observed-dispatches (first windows)))))))
    (hv:html-view :title "Observed windows" :priority 0
      (hv:html
        (:h3 "Live Tutorial")
        (if live
            (hv:html (:p (hv:object-ref live :select "Content" :display "Open embedded live Tutorial 01"))
                     (:p "The existing Web Page view opens the actual tutorial in a separate iframe pane with its own CLOG connection. Keep it open while refreshing this reading. Refreshing the Live pane or reloading its iframe restarts the tutorial."))
            (hv:html (:p "The embedded live surface becomes available after Observe is armed and the existing route is mounted in development mode.")))
        (:h3 "Dispatch execution")
        (if (getf latest :execution)
            (hv:html (:p (hv:object-ref (getf latest :execution) :select "Dispatch execution"))
                     (:p "Shift-click the execution link to keep the Live pane open. Its target, source and registration links open existing Inspector views."))
            (hv:html (:p "No dispatch execution yet. Click the heading in the embedded Live pane, then refresh this reading.")))
        (:h3 "Click → color — mechanism overview")
        (hv:transclusion (%observed-reading windows #'click-color))))))
(defun tutorial-02-reading () (%observed-reading (%live-windows 2) #'counter-output))
