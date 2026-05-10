;;;; Continuation route trace teaching bridge

(in-package :hyperdoc)

(see (page "Graham Closures and the NOR Graph Matcher"))
(see (page "NOR Graph Matcher Teaching Story"))
(see (page "Planning Routes through Uncertain Territory"))
(see (page "CAIR finite route language and route automata"))
(see (page "From Remembered Refusals to Repairable Routes"))

(defstruct continuation-route
  "A minimal inspectable route object extracted from a closure matcher trace.

The structure is intentionally small.  It is a bridge artifact, not a general
planner: it records the intention, endpoints, linear route steps, alternatives,
repairs, source evidence, and the original trace events that can be replayed
without re-running the matcher."
  id
  intention
  origin
  target
  steps
  alternatives
  repairs
  evidence
  trace-events)

(defstruct continuation-route-step
  "One interpreted trace event in a continuation-backed route."
  id
  from
  to
  operation
  premise
  constraint
  result
  on-success
  on-failure
  evidence)

(defstruct continuation-route-repair
  "A visible repair inferred when a failed leaf transfers control to an alternate continuation."
  failed-step
  remembered-refusal
  alternate-step
  continuation
  evidence)

(defun continuation-route-leaf-event-p (event)
  (and (consp event)
       (eq (getf event :event) :leaf)))

(defun continuation-route-final-continuation-event-p (event)
  (and (consp event)
       (eq (getf event :continuation) :success)))

(defun continuation-route-leaf-result (event)
  (if (getf event :matched-p) :matched :refused))

(defun continuation-route-leaf-operation (event)
  (if (getf event :matched-p) :accept-leaf :refuse-leaf))

(defun continuation-route-next-leaf-event (events index)
  (find-if #'continuation-route-leaf-event-p (nthcdr (1+ index) events)))

(defun continuation-route-step-label (event)
  (cond
    ((continuation-route-leaf-event-p event)
     (format nil "leaf ~S" (getf event :leaf)))
    ((continuation-route-final-continuation-event-p event)
     "final success continuation")
    ((getf event :nor-short-circuit)
     (format nil "NOR short-circuit at ~S" (getf event :because)))
    (t
     (format nil "trace event ~S" event))))

(defun continuation-route-make-step (event index previous-label next-label)
  (cond
    ((continuation-route-leaf-event-p event)
     (let ((matched-p (getf event :matched-p)))
       (make-continuation-route-step
        :id (format nil "step-~2,'0D" (1+ index))
        :from previous-label
        :to next-label
        :operation (continuation-route-leaf-operation event)
        :premise (getf event :leaf)
        :constraint (list :leaf-must-match? t)
        :result (continuation-route-leaf-result event)
        :on-success :success-continuation
        :on-failure :failure-continuation
        :evidence (list :trace-event event
                        :remembered-leaf (or (getf event :remembered-leaf)
                                             (getf event :leaf))
                        :continuation-used (if matched-p
                                               :success-continuation
                                               :failure-continuation)))))
    ((continuation-route-final-continuation-event-p event)
     (make-continuation-route-step
      :id (format nil "step-~2,'0D" (1+ index))
      :from previous-label
      :to :terminal
      :operation :finish-route
      :premise :all-refused-leaves-exhausted
      :constraint :no-forbidden-leaf-matched
      :result :success
      :on-success nil
      :on-failure nil
      :evidence (list :trace-event event)))
    (t
     (make-continuation-route-step
      :id (format nil "step-~2,'0D" (1+ index))
      :from previous-label
      :to next-label
      :operation :trace-event
      :premise event
      :constraint nil
      :result :observed
      :on-success nil
      :on-failure nil
      :evidence (list :trace-event event)))))

(defun continuation-route-step-for-event (steps event)
  (find event steps
        :key (lambda (step)
               (getf (continuation-route-step-evidence step) :trace-event))
        :test #'equal))

(defun continuation-route-alternatives-from-events (events)
  (loop for event in events
        for index from 0
        when (and (continuation-route-leaf-event-p event)
                  (not (getf event :matched-p)))
          collect (let ((alternate (continuation-route-next-leaf-event events index)))
                    (list :remembered-refusal (getf event :leaf)
                          :continuation :failure-continuation
                          :alternate (and alternate (getf alternate :leaf))))))

(defun continuation-route-repairs-from-events (events steps)
  (loop for event in events
        for index from 0
        for next-leaf = (and (continuation-route-leaf-event-p event)
                             (continuation-route-next-leaf-event events index))
        when (and next-leaf
                  (not (getf event :matched-p)))
          collect (make-continuation-route-repair
                   :failed-step (continuation-route-step-id
                                 (continuation-route-step-for-event steps event))
                   :remembered-refusal (getf event :leaf)
                   :alternate-step (continuation-route-step-id
                                    (continuation-route-step-for-event steps next-leaf))
                   :continuation :failure-continuation
                   :evidence (list :failed-event event
                                   :alternate-event next-leaf
                                   :repair-kind :try-remembered-alternative))))

(defun continuation-route-steps-from-events (events)
  (loop for event in events
        for index from 0
        for previous = "matcher start" then (continuation-route-step-label event)
        for next-event = (nth (1+ index) events)
        collect (continuation-route-make-step
                 event
                 index
                 previous
                 (and next-event (continuation-route-step-label next-event)))))

(defun continuation-route-from-closure-nor-report
    (report &key
              (id "closure-nor-remembered-refusal-route")
              (intention "Represent a closure-backed NOR matcher trace as a first inspectable route object.")
              (origin "Graham Closures and the NOR Graph Matcher")
              (target "Planning Routes through Uncertain Territory"))
  "Convert an existing closure NOR report into a minimal continuation route.

The conversion does not re-run or rewrite the matcher.  It interprets the
already-recorded trace events as route steps and turns failed leaf events that
lead to later leaves into repair objects."
  (let* ((events (getf report :trace))
         (steps (continuation-route-steps-from-events events)))
    (make-continuation-route
     :id id
     :intention intention
     :origin origin
     :target target
     :steps steps
     :alternatives (continuation-route-alternatives-from-events events)
     :repairs (continuation-route-repairs-from-events events steps)
     :evidence (list :source-pages
                     '("Graham Closures and the NOR Graph Matcher"
                       "NOR Graph Matcher Teaching Story"
                       "Planning Routes through Uncertain Territory")
                     :baseline-report report
                     :route-question
                     "Can the NOR matcher continuation/backtracking trace be represented as a first inspectable HyperDoc route object?")
     :trace-events events)))

(defun make-continuation-route-trace-demo
    (&key
       (expression '(nor (:agent :shuttle) (:agent :joke)))
       (graph *closure-nor-demo-apollo-graph*))
  "Run the existing closure/NOR demo once and convert its trace into a route.

The default expression intentionally refuses two absent leaves.  Those refusals
make the failure-continuation seam visible as route repairs without changing
the underlying matcher."
  (continuation-route-from-closure-nor-report
   (closure-nor-demo-run expression graph)))

(defun continuation-route-replay (route)
  "Return a data-only replay of ROUTE without invoking the matcher again."
  (loop for step in (continuation-route-steps route)
        collect (list :step (continuation-route-step-id step)
                      :from (continuation-route-step-from step)
                      :to (continuation-route-step-to step)
                      :operation (continuation-route-step-operation step)
                      :premise (continuation-route-step-premise step)
                      :result (continuation-route-step-result step))))

(defun continuation-route-pretty-lines (route)
  "Return human-readable lines for ROUTE without invoking the matcher again."
  (append
   (list (format nil "Route ~A" (continuation-route-id route))
         (format nil "Intention: ~A" (continuation-route-intention route))
         (format nil "Origin: ~A" (continuation-route-origin route))
         (format nil "Target: ~A" (continuation-route-target route)))
   (loop for step in (continuation-route-steps route)
         collect (format nil "~A | ~A | ~S => ~S"
                         (continuation-route-step-id step)
                         (continuation-route-step-operation step)
                         (continuation-route-step-premise step)
                         (continuation-route-step-result step)))
   (loop for repair in (continuation-route-repairs route)
         collect (format nil "repair | failed ~A remembered ~S -> alternate ~A via ~A"
                         (continuation-route-repair-failed-step repair)
                         (continuation-route-repair-remembered-refusal repair)
                         (continuation-route-repair-alternate-step repair)
                         (continuation-route-repair-continuation repair)))))

(defun continuation-route-pretty-string (route)
  "Pretty-print ROUTE to a string without invoking the matcher again."
  (with-output-to-string (stream)
    (dolist (line (continuation-route-pretty-lines route))
      (format stream "~A~%" line))))

(defexample continuation-route-trace-demo-example
    (:system "hyperdoc/continuation-route-trace"
     :page "From Remembered Refusals to Repairable Routes"
     :tags '(:closures :nor :continuations :routes :repairs))
    "Convert the existing NOR closure trace into a first inspectable route object."
  (let ((route (make-continuation-route-trace-demo)))
    (assert-eql (typep route 'continuation-route) t)
    (assert-eql (not (endp (continuation-route-steps route))) t)
    (assert-eql (not (endp (continuation-route-repairs route))) t)
    route))

(defun ensure-continuation-route-trace-source-page-registered ()
  "Expose the continuation route trace bridge source file as a HyperDoc code page."
  (when (boundp '*hyperdoc*)
    (when-let (module (asdf:find-component
                       (asdf:find-system :hyperdoc/continuation-route-trace)
                       "hyperdoc"))
      (when-let (component (asdf:find-component module "continuation-route-trace"))
        (let ((page (make-code-page *hyperdoc* component)))
          (setf (gethash (title-of page) (pages-of *hyperdoc*)) page)
          page)))))

(eval-when (:load-toplevel :execute)
  (ensure-continuation-route-trace-source-page-registered))
