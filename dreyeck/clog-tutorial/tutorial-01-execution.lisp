;;;; One execution of Tutorial 01's retained dispatcher.
(in-package #:dreyeck/clog-tutorial/reading)

(defvar *observation-lock* (bordeaux-threads:make-lock "Tutorial 01/02 observations"))

(defclass tutorial-01-dispatch-execution ()
  ((number :initarg :number :reader execution-number)
   (context :initarg :context :reader execution-context)
   (frame :initarg :frame :accessor %execution-frame)
   (steps :initform nil :accessor execution-steps)
   (completion :initform :pending :accessor execution-completion)))

(defun execution-color-before (execution) (getf (%execution-frame execution) :color-before))
(defun execution-color-after (execution) (getf (%execution-frame execution) :color-after))
(defun %execution-object (execution key) (gethash key (execution-context execution)))

(defun %make-01-execution (objects frame)
  (let ((context (make-hash-table :test #'equal)))
    (dolist (key '("Heading" "Body" "Window" "Event key" "Connection/event table"
                   "CLOG dispatcher" "Tutorial callback" "ON-NEW-WINDOW"))
      (setf (gethash key context) (gethash key objects)))
    (make-instance 'tutorial-01-dispatch-execution :number (getf frame :number)
                   :context context :frame frame)))

(defun %release-01-execution (execution)
  (clrhash (execution-context execution))
  (setf (%execution-frame execution) nil (execution-steps execution) nil
        (execution-completion execution) :released))

(defun %execution-view-snapshot (execution)
  ;; Copy metadata under the same lock as recording/release. Object rendering
  ;; happens after unlocking; CLOG text representations may query the browser.
  (bordeaux-threads:with-lock-held (*observation-lock*)
    (values (execution-completion execution)
            (alexandria:copy-hash-table (execution-context execution))
            (copy-tree (execution-steps execution))
            (getf (%execution-frame execution) :overlapping))))

(defmethod hv:text-representation ((execution tutorial-01-dispatch-execution))
  (format nil "Dispatch execution #~D" (execution-number execution)))

(defun %color-label (color)
  (cond ((equal color "rgb(0, 0, 0)") "black")
        ((equal color "rgb(0, 128, 0)") "green")
        (color color) (t "unavailable")))

(hv:defview dispatch-execution (execution tutorial-01-dispatch-execution)
  (multiple-value-bind (completion context steps overlapping) (%execution-view-snapshot execution)
    (flet ((object (key) (gethash key context)))
      (hv:html-view :title "Dispatch execution" :priority 0
        (if (eq :released completion)
            (hv:html (:p "Execution released; no runtime objects retained."))
            (hv:html
              (:h3 (hv:esc (hv:text-representation execution)))
              (:h4 "Structural context")
              (:table :class "inspector-table"
                (:tr (:th "Target")
                     (:td (hv:object-ref (object "Heading") :select "Tree" :display "heading Tree")
                          " · " (hv:object-ref (object "Heading") :select "HTML" :display "heading HTML")
                          " · " (hv:object-ref (object "Heading")
                                              :select (html-inspector-views/standard:dimmed "Slots") :display "heading Slots")))
                (loop for (key title label) in '(("Event key" nil "event key")
                                                ("Connection/event table" "Items" "event table")
                                                ("CLOG dispatcher" "Source code" "original dispatcher")
                                                ("Tutorial callback" "Source code" "original callback")
                                                ("ON-NEW-WINDOW" "Source code" "installed ON-NEW-WINDOW"))
                      do (hv:html (:tr (:th (hv:esc key))
                                       (:td (hv:object-ref (object key) :select title :display label)))))
                (:tr (:th "Window")
                     (:td (hv:object-ref (object "Body") :display "original body")
                          " · " (hv:object-ref (object "Window") :display "original window"))))
              (:h4 "Dynamic execution evidence")
              (:ol
                (dolist (step steps)
                  (hv:html
                    (:li
                      (ecase (getf step :kind)
                        (:dispatcher-entered
                         (hv:html "dispatcher entered: "
                                  (hv:object-ref (getf step :dispatcher) :select "Source code" :display "original dispatcher")))
                        (:color-write
                         (hv:html "COLOR write requested — target: "
                                  (hv:object-ref (getf step :target) :select "Tree" :display "original heading")
                                  "; value: " (hv:object-ref (getf step :value))))
                        (:dispatcher-returned (hv:html "dispatcher returned normally"))
                        (:dispatcher-unwound (hv:html "dispatcher did not return normally"))
                        (:css-observed
                         (hv:html "observed CSS: " (hv:esc (%color-label (getf step :before)))
                                  " → " (hv:esc (%color-label (getf step :after))) " on "
                                  (hv:object-ref (getf step :target) :select "HTML" :display "heading HTML"))))))))
              (when overlapping
                (hv:html (:p "Overlapping dispatcher executions: this record does not establish an isolated state transition.")))
              (:p "Callback involvement is structural context from registration and dispatcher source. No callback-entry boundary or per-click event-table lookup is recorded. Dispatch numbers order entry into the observer, not browser event reception.")))))))
