;;;; The derived reading must follow the evidence, not resemble it.
(defpackage #:dreyeck/gesture/reading/tests
  (:use #:cl)
  (:local-nicknames (#:r #:dreyeck/gesture/reading)
                    (#:w #:dreyeck/gesture-binding-witness)
                    (#:sm #:dreyeck/state-machine)
                    (#:views #:html-inspector-views))
  (:export #:run-gesture-reading-tests))

(in-package #:dreyeck/gesture/reading/tests)

(defun %effect-entries (session)
  "The evidence entries that a reading has to account for, in trace order."
  (remove-if-not (lambda (entry)
                   (member (getf entry :kind)
                           '(:transient-gesture-transition
                             :observation-without-transition)))
                 (sm:state-machine-run-evidence-trace-of session)))

(defun check-reading (session reading)
  "Every invariant the derivation owes the trace it was derived from."
  ;; One record per delivered sample, in the order they were delivered.
  (assert (equal (mapcar (lambda (record) (getf record :sample)) reading)
                 (sm:state-machine-run-input-of session)))
  ;; Every effect entry accounted for exactly once, still in trace order,
  ;; and still the very object the session recorded.
  (let ((claimed (loop for record in reading
                       append (mapcar (lambda (effect) (getf effect :evidence))
                                      (r:reading-record-effects record)))))
    (assert (equal claimed (%effect-entries session))))
  ;; The state chain: each record starts where the previous one ended,
  ;; an observation leaves the state alone, and the last record ends
  ;; where the session says it is.
  (let ((state :idle))
    (dolist (record reading)
      (assert (eq state (getf record :state-before)))
      (dolist (effect (r:reading-record-effects record))
        (ecase (getf effect :disposition)
          (:transition (setf state (getf effect :state-after)))
          (:observation (assert (eq state (getf effect :state-after))))))
      (assert (eq state (getf record :state-after))))
    (assert (eq state (sm:state-machine-run-current-state-of session))))
  t)

(defun %signals (thunk)
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (princ-to-string condition))))

(defun %find-effect (reading reason)
  (loop for record in reading
        do (let ((effect (find reason (r:reading-record-effects record)
                               :key (lambda (e) (getf e :reason)))))
             (when effect (return (values effect record))))))

;;; One sample, two transitions

(defun test-ordered-grouping ()
  (let* ((session (w:make-expert-marking-trace))
         (reading (r:gesture-session-reading session)))
    (check-reading session reading)
    (assert (= 3 (length reading)))
    ;; The pointer-move crosses the dead zone and enters a sector in one
    ;; sample; both transitions carry the same timestamp, so only the
    ;; order of the trace can keep them apart.
    (let* ((record (second reading))
           (effects (r:reading-record-effects record)))
      (assert (= 2 (length effects)))
      (assert (equal '(:pressed->marking :marking->sector-selected)
                     (mapcar (lambda (e) (getf e :transition)) effects)))
      (assert (every (lambda (e) (eq :transition (getf e :disposition))) effects))
      (assert (apply #'= (mapcar (lambda (e) (getf (getf e :evidence) :timestamp))
                                 effects)))
      (assert (eq :pressed (getf record :state-before)))
      (assert (eq :sector-selected (getf record :state-after))))
    ;; The surviving claim, read from the session the page shows.
    (assert (eq (w:insert-executable-defexample-operation)
                (w:gesture-session-selected-operation-of session)))
    t))

;;; A disabled sector is observed, not selected

(defun test-disabled-sector-is-read-as-an-observation ()
  (let* ((session (r:disabled-then-enabled-session))
         (reading (r:gesture-session-reading session)))
    (check-reading session reading)
    (multiple-value-bind (effect record)
        (%find-effect reading :disabled-sector-entered)
      (assert effect)
      (assert (eq :observation (getf effect :disposition)))
      ;; The reading names the Binding that was met, from the raw string
      ;; the trace stored; it does not claim it was selected.
      (assert (string= "binding/radial-disabled-sector" (getf effect :binding-id)))
      (assert (null (getf effect :transition)))
      (assert (eq (getf record :state-before) (getf record :state-after))))
    ;; And the session went on to select the enabled Binding.
    (assert (eq :completed (sm:state-machine-run-current-state-of session)))
    (assert (string= "binding/radial-insert-defexample"
                     (w:gesture-binding-id
                      (w:gesture-session-selected-binding-of session))))
    t))

;;; An obsolete timer changes nothing; a lost sector is a transition

(defun test-observation-and-transition-are-not-confused ()
  (let* ((session (r:obsolete-deadline-session))
         (reading (r:gesture-session-reading session)))
    (check-reading session reading)
    (multiple-value-bind (effect record)
        (%find-effect reading :obsolete-reveal-deadline)
      (assert effect)
      (assert (eq :observation (getf effect :disposition)))
      (assert (eq :sector-selected (getf record :state-before)))
      (assert (eq :sector-selected (getf record :state-after)))))
  ;; Leaving every enabled sector is a transition, not a third kind of
  ;; effect invented to describe it.
  (let* ((operation (w:insert-executable-defexample-operation))
         (bindings (list (dreyeck/gesture-binding-witness::%make-gesture-binding
                          :id "binding/radial-east" :kind :radial-menu
                          :sector-center 0.0d0 :sector-half-width 30.0d0
                          :target-type :lisp-source-definition
                          :enabled-p t :operation operation)))
         (session (w:run-gesture-trace
                   (list (w:make-gesture-input-sample
                          :kind :pointer-down :x 0.0d0 :y 0.0d0
                          :button :secondary
                          :target (list :type :lisp-source-definition)
                          :timestamp 0)
                         (w:make-gesture-input-sample :kind :reveal-deadline
                                                      :timestamp 500)
                         (w:make-gesture-input-sample :kind :pointer-move
                                                      :x 20.0d0 :y 0.0d0
                                                      :timestamp 600)
                         (w:make-gesture-input-sample :kind :pointer-move
                                                      :x 0.0d0 :y -20.0d0
                                                      :timestamp 700)
                         (w:make-gesture-input-sample :kind :pointer-up
                                                      :x 0.0d0 :y -20.0d0
                                                      :timestamp 720))
                   :bindings bindings))
         (reading (r:gesture-session-reading session)))
    (check-reading session reading)
    (let ((effect (%find-effect reading :no-enabled-sector-at-angle)))
      (assert effect)
      (assert (eq :transition (getf effect :disposition)))
      (assert (eq :sector-selected->menu-visible (getf effect :transition)))
      (assert (eq :menu-visible (getf effect :state-after))))
    ;; No effect anywhere carries a disposition the model does not have.
    (assert (every (lambda (record)
                     (every (lambda (effect)
                              (member (getf effect :disposition)
                                      '(:transition :observation)))
                            (r:reading-record-effects record)))
                   reading))
    t))

;;; Positive controls: damage the derived reading, not the session

(defun test-controls-detect-a-damaged-reading ()
  (let* ((session (w:make-expert-marking-trace))
         (honest (r:gesture-session-reading session))
         (disabled-session (r:disabled-then-enabled-session))
         (disabled-honest (r:gesture-session-reading disabled-session))
         (obsolete-session (r:obsolete-deadline-session))
         (obsolete-honest (r:gesture-session-reading obsolete-session)))
    ;; The harness accepts the honest readings, so a rejection below is
    ;; about the damage.
    (assert (check-reading session honest))
    (assert (check-reading disabled-session disabled-honest))
    (assert (check-reading obsolete-session obsolete-honest))
    ;; One effect dropped from the two-transition input.
    (let ((damaged (copy-tree honest)))
      (setf (getf (second damaged) :effects)
            (list (first (getf (second damaged) :effects))))
      (assert (%signals (lambda () (check-reading session damaged)))))
    ;; A transition reclassified as an observation.
    (let ((damaged (copy-tree honest)))
      (setf (getf (first (getf (second damaged) :effects)) :disposition)
            :observation)
      (assert (%signals (lambda () (check-reading session damaged)))))
    ;; The disabled-sector observation omitted.
    (let ((damaged (remove-if (lambda (record)
                                (find :disabled-sector-entered
                                      (r:reading-record-effects record)
                                      :key (lambda (e) (getf e :reason))))
                              (copy-tree disabled-honest))))
      (assert (%signals (lambda () (check-reading disabled-session damaged)))))
    ;; An obsolete deadline credited with a state change.
    (let ((damaged (copy-tree obsolete-honest)))
      (multiple-value-bind (effect record)
          (%find-effect damaged :obsolete-reveal-deadline)
        (declare (ignore record))
        (setf (getf effect :state-after) :completed))
      (assert (%signals (lambda () (check-reading obsolete-session damaged)))))
    t))

;;; The page

(defun test-page ()
  (let* ((book (hyperbook:find-hyperbook "dreyeck/gesture/reading"
                                         :signal-error? t))
         (page (hyperbook:find-page book "Falsifying a Gesture/Binding Witness"
                                    :signal-error? t))
         (view (find "Content" (views:all-views page)
                     :key #'views:view-title :test #'string=))
         (html (views:view-html view))
         (references (views:view-references view))
         ;; Three different questions, measured rather than assumed equal.
         ;; The predicate is spelled out here instead of depending on the
         ;; TALA reading system for one type test.
         (widgets (remove-if-not (lambda (reference)
                                   (typep (cdr reference) 'views:view))
                                 references))
         (executable
           (remove-if-not
            (lambda (reference)
              (views:view-html (cdr reference))
              (find-if (lambda (inner) (typep (cdr inner) 'views:thunk))
                       (views:view-references (cdr reference))))
            widgets)))
    (assert (search "opaque semantic Operation identity" html))
    (assert (= (length references) (length widgets)))
    (assert (= 4 (length widgets)))
    (assert (= 2 (length executable)))
    ;; Every executable widget runs and returns derived records.
    (dolist (reference executable)
      (let* ((thunks (remove-if-not (lambda (inner)
                                      (typep (cdr inner) 'views:thunk))
                                    (views:view-references (cdr reference))))
             (result (views:eval-thunk (cdar thunks))))
        (assert (= 1 (length thunks)))
        (assert (consp result))
        (assert (every (lambda (record) (getf record :sample)) result))))
    ;; The book is in the Catalog under its own name.
    (assert (find book (hyperbook:hyperbooks-of hyperbook:*catalog*) :test #'eq))
    (format t "~&GESTURE-READING-PAGE: ~D references, ~D renderable widgets, ~
~D executable.~%"
            (length references) (length widgets) (length executable))
    t))

(defun %executable-value (reference)
  "The one thunk behind an executable widget, evaluated."
  (let ((thunks
         (remove-if-not (lambda (inner) (typep (cdr inner) 'views:thunk))
                        (views:view-references (cdr reference)))))
    (assert (= 1 (length thunks)))
    (views:eval-thunk (cdar thunks))))

(defun test-ordering-page ()
  "The ordering page's argument, checked against what its widgets return.
The page claims that one geometry yields two Bindings and one Operation,
and that two sequencing authorities cannot be fused. Both claims are read
back from the thunks the page actually runs, not from its prose."
  (let* ((book
          (hyperbook:find-hyperbook "dreyeck/gesture/reading" :signal-error?
                                    t))
         (page
          (hyperbook:find-page book "When Does a Mark Become a Menu?"
                               :signal-error? t))
         (view
          (find "Content" (views:all-views page) :key #'views:view-title :test
                #'string=))
         (html (views:view-html view))
         (references (views:view-references view))
         (widgets
          (remove-if-not
           (lambda (reference) (typep (cdr reference) 'views:view))
           references))
         (executable
          (remove-if-not
           (lambda (reference)
             (views:view-html (cdr reference))
             (find-if (lambda (inner) (typep (cdr inner) 'views:thunk))
                      (views:view-references (cdr reference))))
           widgets)))
    (assert (= (length references) (length widgets)))
    (assert (= 5 (length widgets)))
    (assert (= 3 (length executable)))
    (assert (search "approximately one third of a second" html))
    (assert (search "500 ms" html))
    (assert (search "does not describe a reveal-deadline event" html))
    (let* ((results (mapcar #'%executable-value executable))
           (races
            (remove-if-not (lambda (result) (getf result :operation)) results))
           (merged (find-if (lambda (result) (getf result :offered)) results)))
      (assert (= 2 (length races)))
      (assert merged)
      (assert
       (every
        (lambda (result) (equal '(1 3 2) (getf result :callback-arrival)))
        races))
      (assert
       (every
        (lambda (result) (equal '(1 2 3) (getf result :consumer-delivery)))
        races))
      (assert
       (every (lambda (result) (getf result :operation-is-the-shared-identity))
              races))
      (assert
       (= 1
          (length
           (remove-duplicates
            (mapcar (lambda (result) (getf result :operation)) races) :test
            #'string=))))
      (assert
       (= 2
          (length
           (remove-duplicates
            (mapcar (lambda (result) (getf result :binding)) races) :test
            #'string=))))
      (assert
       (equal '(:marking :menu-visible)
              (sort (mapcar (lambda (result) (getf result :mode)) races)
                    #'string< :key #'symbol-name)))
      (assert
       (= 2
          (count :refused (getf merged :offered) :key
                 (lambda (entry) (getf entry :outcome)))))
      (assert (equal '(1 2) (getf merged :consumer-delivery)))
      (assert
       (equal '(:pointer-down :pointer-move)
              (getf merged :surviving-samples))))
    (format t "~&GESTURE-ORDERING-PAGE: ~D references, ~D renderable widgets, ~
~D executable.~%"
            (length references) (length widgets) (length executable))
    t))

(defun run-gesture-reading-tests ()
  (test-ordered-grouping)
  (test-disabled-sector-is-read-as-an-observation)
  (test-observation-and-transition-are-not-confused)
  (test-controls-detect-a-damaged-reading)
  (test-page)
  (test-ordering-page)
  (format t "~&GESTURE-READING-PASS: input-ordered grouping, two transitions ~
from one sample, disabled sector observed not selected, obsolete timer ~
without state change, four damaged readings refused, and one geometry ~
read as two Bindings over one Operation while two sequencing authorities ~
are kept apart.~%")
  t)
