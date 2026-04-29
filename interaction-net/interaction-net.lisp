;;;; interaction-net/interaction-net.lisp
;;;;
;;;; Sequential interaction-net runtime kernel inspired by Lafont (1990).
;;;; This is an implementation seed, not a complete implementation of
;;;; Lafont's full concrete language and typing/deadlock framework.

(in-package :interaction-net)

(define-condition interaction-net-error (error) ())

(define-condition unknown-agent-kind (interaction-net-error)
  ((kind :initarg :kind :reader unknown-agent-kind-of))
  (:report (lambda (condition stream)
             (format stream "Unknown agent kind ~S."
                     (unknown-agent-kind-of condition)))))

(define-condition duplicate-rule-error (interaction-net-error)
  ((left-kind :initarg :left-kind :reader duplicate-rule-left-kind-of)
   (right-kind :initarg :right-kind :reader duplicate-rule-right-kind-of))
  (:report (lambda (condition stream)
             (format stream "Duplicate rule registration for active pair (~S >< ~S)."
                     (duplicate-rule-left-kind-of condition)
                     (duplicate-rule-right-kind-of condition)))))

(define-condition same-symbol-rule-error (interaction-net-error)
  ((kind :initarg :kind :reader same-symbol-rule-kind-of))
  (:report (lambda (condition stream)
             (format stream "No same-symbol rule is allowed by default (~S >< ~S)."
                     (same-symbol-rule-kind-of condition)
                     (same-symbol-rule-kind-of condition)))))

(define-condition typing-error (interaction-net-error)
  ((message :initarg :message :reader typing-error-message-of)
   (details :initarg :details :reader typing-error-details-of :initform nil))
  (:report (lambda (condition stream)
             (format stream "~A~@[ (~S)~]"
                     (typing-error-message-of condition)
                     (typing-error-details-of condition)))))

(define-condition reduction-limit-reached (interaction-net-error)
  ((limit :initarg :limit :reader reduction-limit-of)
   (steps :initarg :steps :reader reduction-steps-of))
  (:report (lambda (condition stream)
             (format stream "Reduction limit ~D reached at step ~D."
                     (reduction-limit-of condition)
                     (reduction-steps-of condition)))))

(defstruct symbol-spec
  kind
  arity
  principal-type
  principal-polarity
  auxiliary-types
  auxiliary-polarities
  auxiliary-partitions)

(defstruct rule-entry
  key
  function
  name
  dsl)

(defstruct (runtime (:constructor %make-runtime))
  (arities (make-hash-table :test #'eq))
  (rules (make-hash-table :test #'equal))
  (rule-entries (make-hash-table :test #'equal))
  (symbol-specs (make-hash-table :test #'eq))
  (typed-mode nil))

(defstruct net
  runtime
  (cells (make-hash-table :test #'equal))
  (free-cells (make-hash-table :test #'equal))
  (free (make-hash-table :test #'equal))
  active-stack
  trace
  trace-object)

(defstruct cell
  id
  kind
  ports
  (live-p t))

(defstruct endpoint
  cell
  port
  link)

(defstruct reduction-step
  step
  active-pair-kinds
  active-pair-cell-ids
  rule-name
  rule-key
  new-active-pairs)

(defstruct reduction-trace
  status
  steps
  total-steps
  final-normal-form
  failure-reason)

(defparameter *collect-new-active-pairs* nil)

(defun make-runtime (&key (typed-mode nil))
  (%make-runtime :typed-mode typed-mode))

(defun %ensure-agent-known (runtime kind)
  (unless (gethash kind (runtime-arities runtime))
    (error 'unknown-agent-kind :kind kind))
  kind)

(defun define-agent (runtime kind arity
                      &key principal-type
                        principal-polarity
                        auxiliary-types
                        auxiliary-polarities
                        auxiliary-partitions)
  "Register KIND with ARITY. Optional typed metadata can be attached incrementally."
  (check-type runtime runtime)
  (check-type kind symbol)
  (check-type arity (integer 0 *))
  (setf (gethash kind (runtime-arities runtime)) arity)
  (let ((spec (or (gethash kind (runtime-symbol-specs runtime))
                  (make-symbol-spec :kind kind :arity arity))))
    (setf (symbol-spec-arity spec) arity)
    (when principal-type
      (setf (symbol-spec-principal-type spec) principal-type))
    (when principal-polarity
      (setf (symbol-spec-principal-polarity spec) principal-polarity))
    (when auxiliary-types
      (setf (symbol-spec-auxiliary-types spec)
            (copy-seq auxiliary-types)))
    (when auxiliary-polarities
      (setf (symbol-spec-auxiliary-polarities spec)
            (copy-seq auxiliary-polarities)))
    (when auxiliary-partitions
      (setf (symbol-spec-auxiliary-partitions spec)
            (copy-tree auxiliary-partitions)))
    (setf (gethash kind (runtime-symbol-specs runtime)) spec))
  kind)

(defun define-symbol (runtime kind arity
                       &key principal-type principal-polarity
                         auxiliary-types auxiliary-polarities auxiliary-partitions)
  "Typed symbol declaration layer.

Polarity convention:
  :input   -- negative polarity in Lafont notation
  :output  -- positive polarity in Lafont notation"
  (define-agent runtime kind arity
                :principal-type principal-type
                :principal-polarity principal-polarity
                :auxiliary-types auxiliary-types
                :auxiliary-polarities auxiliary-polarities
                :auxiliary-partitions auxiliary-partitions))

(defun symbol-spec-for-kind (runtime kind)
  (gethash kind (runtime-symbol-specs runtime)))

(defun agent-arity (runtime kind)
  (or (gethash kind (runtime-arities runtime))
      (error 'unknown-agent-kind :kind kind)))

(defun %rule-key (a b)
  (cons a b))

(defun %lookup-rule-entry (runtime left-kind right-kind)
  (gethash (%rule-key left-kind right-kind)
           (runtime-rule-entries runtime)))

(defun %register-rule-entry (runtime left-kind right-kind function
                              &key name dsl)
  (let ((key (%rule-key left-kind right-kind)))
    (setf (gethash key (runtime-rules runtime)) function)
    (setf (gethash key (runtime-rule-entries runtime))
          (make-rule-entry :key key
                           :function function
                           :name name
                           :dsl dsl))))

(defun define-rule (runtime left-kind right-kind function
                     &key (allow-self-interaction nil) name dsl)
  "Install a symmetric active-pair rewrite rule.

Validation:
- both symbols must be declared
- duplicate registrations are rejected
- same-symbol rules are rejected by default"
  (check-type runtime runtime)
  (check-type left-kind symbol)
  (check-type right-kind symbol)
  (check-type function function)
  (%ensure-agent-known runtime left-kind)
  (%ensure-agent-known runtime right-kind)
  (when (and (eq left-kind right-kind)
             (not allow-self-interaction))
    (error 'same-symbol-rule-error :kind left-kind))
  (when (or (%lookup-rule-entry runtime left-kind right-kind)
            (%lookup-rule-entry runtime right-kind left-kind))
    (error 'duplicate-rule-error
           :left-kind left-kind
           :right-kind right-kind))
  (%register-rule-entry runtime left-kind right-kind function
                        :name (or name (list left-kind right-kind))
                        :dsl dsl)
  (%register-rule-entry
   runtime right-kind left-kind
   (lambda (net right left)
     (funcall function net left right))
   :name (or name (list left-kind right-kind))
   :dsl dsl)
  (values left-kind right-kind))

(defun port-endpoint (cell port)
  (aref (cell-ports cell) port))

(defun make-cell* (id kind arity)
  (let ((cell (make-cell :id id
                         :kind kind
                         :ports (make-array (1+ arity)))))
    (dotimes (i (1+ arity) cell)
      (setf (aref (cell-ports cell) i)
            (make-endpoint :cell cell :port i)))))

(defun install-cell (net cell)
  (setf (gethash (cell-id cell) (net-cells net)) cell)
  cell)

(defun detach-endpoint (endpoint)
  (let ((other (endpoint-link endpoint)))
    (when other
      (setf (endpoint-link other) nil)
      (setf (endpoint-link endpoint) nil))
    other))

(defun endpoint-principal-p (endpoint)
  (and (endpoint-cell endpoint)
       (zerop (endpoint-port endpoint))))

(defun endpoint-live-cell-p (endpoint)
  (let ((cell (endpoint-cell endpoint)))
    (and cell (cell-live-p cell))))

(defun endpoint-description (endpoint)
  (let ((cell (endpoint-cell endpoint)))
    (if cell
        (list :cell-id (cell-id cell)
              :kind (cell-kind cell)
              :port (endpoint-port endpoint))
        (list :free (endpoint-port endpoint)))))

(defun %endpoint-signature (runtime endpoint)
  (let ((cell (endpoint-cell endpoint)))
    (when cell
      (let ((spec (symbol-spec-for-kind runtime (cell-kind cell))))
        (when spec
          (if (zerop (endpoint-port endpoint))
              (list :type (symbol-spec-principal-type spec)
                    :polarity (symbol-spec-principal-polarity spec))
              (let* ((aux-index (1- (endpoint-port endpoint)))
                     (types (symbol-spec-auxiliary-types spec))
                     (polarities (symbol-spec-auxiliary-polarities spec)))
                (list :type (and types (< aux-index (length types))
                                 (elt types aux-index))
                      :polarity (and polarities (< aux-index (length polarities))
                                     (elt polarities aux-index))))))))))

(defun %polarity-opposite-p (left right)
  (or (and (eq left :input) (eq right :output))
      (and (eq left :output) (eq right :input))))

(defun check-port-compatible (net left right &key signal-error?)
  "Check endpoint compatibility when typed metadata is present.

Returns T when compatible.
Returns NIL when incompatible and SIGNAL-ERROR? is NIL.
Signals TYPING-ERROR when incompatible and SIGNAL-ERROR? is true."
  (let* ((runtime (net-runtime net))
         (left-signature (%endpoint-signature runtime left))
         (right-signature (%endpoint-signature runtime right))
         (left-type (getf left-signature :type))
         (right-type (getf right-signature :type))
         (left-polarity (getf left-signature :polarity))
         (right-polarity (getf right-signature :polarity))
         (typed-endpoints-p (and left-signature right-signature left-type right-type
                                 left-polarity right-polarity)))
    (labels ((incompatible (message)
               (if signal-error?
                   (error 'typing-error
                          :message message
                          :details (list :left (endpoint-description left)
                                         :right (endpoint-description right)
                                         :left-signature left-signature
                                         :right-signature right-signature))
                   nil)))
      (cond
        ((not typed-endpoints-p)
         t)
        ((not (equal left-type right-type))
         (incompatible "Endpoint types are incompatible."))
        ((not (%polarity-opposite-p left-polarity right-polarity))
         (incompatible "Endpoint polarities are incompatible."))
        (t
         t)))))

(defun matching-symbols-p (runtime left-kind right-kind)
  "Return true when principal ports have the same type and opposite polarity."
  (let* ((left-spec (symbol-spec-for-kind runtime left-kind))
         (right-spec (symbol-spec-for-kind runtime right-kind))
         (left-type (and left-spec (symbol-spec-principal-type left-spec)))
         (right-type (and right-spec (symbol-spec-principal-type right-spec)))
         (left-polarity (and left-spec (symbol-spec-principal-polarity left-spec)))
         (right-polarity (and right-spec (symbol-spec-principal-polarity right-spec))))
    (and left-type right-type left-polarity right-polarity
         (equal left-type right-type)
         (%polarity-opposite-p left-polarity right-polarity))))

(defun complete-rule-table-p (runtime)
  "Check completeness against typed principal-port matching.

Returns two values:
1) boolean completeness
2) list of missing typed rule pairs" 
  (let ((missing '())
        (symbols '()))
    (maphash (lambda (kind spec)
               (declare (ignore spec))
               (push kind symbols))
             (runtime-symbol-specs runtime))
    (setf symbols (remove-duplicates symbols :test #'eq))
    (dolist (left symbols)
      (dolist (right symbols)
        (when (and (not (eq left right))
                   (matching-symbols-p runtime left right)
                   (null (%lookup-rule-entry runtime left right)))
          (push (list left right) missing))))
    (values (null missing)
            (nreverse missing))))

(defun push-active-if-needed (net left right)
  (when (and (endpoint-principal-p left)
             (endpoint-principal-p right)
             (endpoint-live-cell-p left)
             (endpoint-live-cell-p right))
    (let ((pair (cons (endpoint-cell left) (endpoint-cell right))))
      (push pair (net-active-stack net))
      (when *collect-new-active-pairs*
        (push (list :left (cell-id (car pair))
                    :left-kind (cell-kind (car pair))
                    :right (cell-id (cdr pair))
                    :right-kind (cell-kind (cdr pair)))
              *collect-new-active-pairs*)))))

(defun connect-endpoints (net left right &key check-types)
  "Connect two endpoints, detaching previous wires first.

Type compatibility is enforced when CHECK-TYPES is true or runtime typed mode
is enabled."
  (when (eq left right)
    (error "Cannot connect endpoint to itself: ~S" (endpoint-description left)))
  (let ((should-check-types (if (null check-types)
                                (runtime-typed-mode (net-runtime net))
                                check-types)))
    (when should-check-types
      (check-port-compatible net left right :signal-error? t)))
  (detach-endpoint left)
  (detach-endpoint right)
  (setf (endpoint-link left) right
        (endpoint-link right) left)
  (push-active-if-needed net left right)
  (values left right))

(defun take-port-link (cell port)
  (let* ((endpoint (port-endpoint cell port))
         (other (endpoint-link endpoint)))
    (unless other
      (error "Port ~S of cell ~S is not connected." port (cell-id cell)))
    (detach-endpoint endpoint)
    other))

(defun kill-cell (net cell)
  "Detach and retire CELL.

Killed cells are removed from NET-CELLS and moved to NET-FREE-CELLS."
  (when (cell-live-p cell)
    (dotimes (i (length (cell-ports cell)))
      (detach-endpoint (port-endpoint cell i)))
    (setf (cell-live-p cell) nil)
    (remhash (cell-id cell) (net-cells net))
    (setf (gethash (cell-id cell) (net-free-cells net)) cell))
  cell)

(defun active-pair-valid-p (left right)
  (and (cell-live-p left)
       (cell-live-p right)
       (eq (endpoint-link (port-endpoint left 0)) (port-endpoint right 0))
       (eq (endpoint-link (port-endpoint right 0)) (port-endpoint left 0))))

(defun rule-entry-for (runtime left right)
  (%lookup-rule-entry runtime (cell-kind left) (cell-kind right)))

(defun rule-for (runtime left right)
  (gethash (%rule-key (cell-kind left) (cell-kind right))
           (runtime-rules runtime)))

(defun well-typed-net-p (net &key signal-error?)
  "Check all currently connected links in NET for typed compatibility."
  (let ((ok t))
    (maphash
     (lambda (_id cell)
       (declare (ignore _id))
       (when (cell-live-p cell)
         (dotimes (port-index (length (cell-ports cell)))
           (let* ((endpoint (port-endpoint cell port-index))
                  (other (endpoint-link endpoint)))
             (when other
               (unless (check-port-compatible net endpoint other
                                              :signal-error? signal-error?)
                 (setf ok nil)))))))
     (net-cells net))
    ok))

(defun %net-normal-form-summary (net)
  (let ((live-cells '())
        (free-bindings '()))
    (maphash (lambda (_id cell)
               (declare (ignore _id))
               (when (cell-live-p cell)
                 (push (list :id (cell-id cell)
                             :kind (cell-kind cell))
                       live-cells)))
             (net-cells net))
    (maphash (lambda (name free-endpoint)
               (let ((other (endpoint-link free-endpoint)))
                 (push (list :free name
                             :connected-to (and other (endpoint-description other)))
                       free-bindings)))
             (net-free net))
    (list :live-cells (sort live-cells #'string< :key (lambda (entry)
                                                        (prin1-to-string (getf entry :id))))
          :free-bindings (sort free-bindings #'string< :key (lambda (entry)
                                                              (prin1-to-string (getf entry :free)))))))

(defun reduce-net (net &key (limit 100000) trace)
  "Reduce NET until no active pairs remain or LIMIT interactions have fired.

Returns NET and the number of fired interactions.
When TRACE is non-NIL, step objects are recorded in NET-TRACE and a structured
REDUCTION-TRACE in NET-TRACE-OBJECT."
  (let ((steps 0)
        (step-records '()))
    (setf (net-trace net) nil
          (net-trace-object net) nil)
    (handler-case
        (loop while (net-active-stack net)
              do (when (>= steps limit)
                   (error 'reduction-limit-reached
                          :limit limit
                          :steps steps))
                 (destructuring-bind (left . right)
                     (pop (net-active-stack net))
                   (when (active-pair-valid-p left right)
                     (let* ((rule-entry (rule-entry-for (net-runtime net)
                                                        left right))
                            (rule (and rule-entry
                                       (rule-entry-function rule-entry))))
                       (unless rule
                         (error "No rule for active pair (~S >< ~S)."
                                (cell-kind left) (cell-kind right)))
                       (let ((*collect-new-active-pairs* (and trace '())))
                         (funcall rule net left right)
                         (when trace
                           (push (make-reduction-step
                                  :step steps
                                  :active-pair-kinds
                                  (list (cell-kind left) (cell-kind right))
                                  :active-pair-cell-ids
                                  (list (cell-id left) (cell-id right))
                                  :rule-name (rule-entry-name rule-entry)
                                  :rule-key (rule-entry-key rule-entry)
                                  :new-active-pairs
                                  (nreverse *collect-new-active-pairs*))
                                 step-records))
                         (incf steps)))))
              finally
                 (setf (net-trace net)
                       (nreverse step-records)
                       (net-trace-object net)
                       (make-reduction-trace
                        :status :normal-form
                        :steps (nreverse step-records)
                        :total-steps steps
                        :final-normal-form (%net-normal-form-summary net)
                        :failure-reason nil))
                 (return (values net steps)))
      (reduction-limit-reached (condition)
        (setf (net-trace net)
              (nreverse step-records)
              (net-trace-object net)
              (make-reduction-trace
               :status :limit
               :steps (nreverse step-records)
               :total-steps steps
               :final-normal-form (%net-normal-form-summary net)
               :failure-reason (princ-to-string condition)))
        (error condition))
      (error (condition)
        (setf (net-trace net)
              (nreverse step-records)
              (net-trace-object net)
              (make-reduction-trace
               :status :error
               :steps (nreverse step-records)
               :total-steps steps
               :final-normal-form (%net-normal-form-summary net)
               :failure-reason (princ-to-string condition)))
        (error condition)))))

(defun parse-net (runtime forms)
  "Parse first-order net forms.

Each cell form: (:agent ID KIND PRINCIPAL-WIRE AUX-WIRE...)" 
  (let ((net (make-net :runtime runtime))
        (occurrences (make-hash-table :test #'equal)))
    (labels ((record-occurrence (wire endpoint)
               (push endpoint (gethash wire occurrences))))
      (dolist (form forms)
        (destructuring-bind (tag id kind &rest wires) form
          (unless (eq tag :agent)
            (error "Unknown net form ~S." form))
          (let ((arity (agent-arity runtime kind)))
            (unless (= (length wires) (1+ arity))
              (error "Agent ~S of kind ~S expects ~D wires, got ~D in ~S."
                     id kind (1+ arity) (length wires) form))
            (when (gethash id (net-cells net))
              (error "Duplicate cell id ~S." id))
            (let ((cell (install-cell net (make-cell* id kind arity))))
              (loop for wire in wires
                    for port from 0
                    do (record-occurrence wire (port-endpoint cell port))))))))
    (maphash
     (lambda (wire endpoints)
       (case (length endpoints)
         (1 (let ((free (make-endpoint :cell nil :port wire)))
              (setf (gethash wire (net-free net)) free)
              (connect-endpoints net free (first endpoints))))
         (2 (connect-endpoints net (first endpoints) (second endpoints)))
         (otherwise
          (error "Wire ~S occurs ~D times; expected one or two."
                 wire (length endpoints)))))
     occurrences)
    net))

(defun net-free-endpoint (net name)
  (or (gethash name (net-free net))
      (error "No free interface wire named ~S." name)))

(defun read-nat-from-principal-endpoint (endpoint)
  (let ((cell (endpoint-cell endpoint)))
    (unless (and cell (zerop (endpoint-port endpoint)))
      (error "Expected principal endpoint, got ~S."
             (endpoint-description endpoint)))
    (ecase (cell-kind cell)
      (zero 0)
      (succ (1+ (read-nat-from-principal-endpoint
                 (endpoint-link (port-endpoint cell 1))))))))

(defun read-nat (net free-name)
  (let* ((free (net-free-endpoint net free-name))
         (other (endpoint-link free)))
    (unless other
      (error "Free endpoint ~S is disconnected." free-name))
    (read-nat-from-principal-endpoint other)))

(defun read-atom-from-principal-endpoint (endpoint)
  (let ((cell (endpoint-cell endpoint)))
    (unless (and cell (zerop (endpoint-port endpoint)))
      (error "Expected atom principal endpoint, got ~S."
             (endpoint-description endpoint)))
    (if (zerop (1- (length (cell-ports cell))))
        (cell-kind cell)
        (list :kind (cell-kind cell)
              :id (cell-id cell)))))

(defun read-list-from-principal-endpoint (endpoint &key (atom-reader #'read-atom-from-principal-endpoint))
  (let ((cell (endpoint-cell endpoint)))
    (unless (and cell (zerop (endpoint-port endpoint)))
      (error "Expected list principal endpoint, got ~S."
             (endpoint-description endpoint)))
    (cond
      ((eq (cell-kind cell) 'cons)
       (let* ((head-link (endpoint-link (port-endpoint cell 1)))
              (tail-link (endpoint-link (port-endpoint cell 2))))
         (unless head-link
           (error "CONS head port is disconnected in cell ~S." (cell-id cell)))
         (unless tail-link
           (error "CONS tail port is disconnected in cell ~S." (cell-id cell)))
         (cons (funcall atom-reader head-link)
               (read-list-from-principal-endpoint tail-link
                                                 :atom-reader atom-reader))))
      ((or (eq (cell-kind cell) '|Nil|)
           (eq (cell-kind cell) nil))
       nil)
      (t
       (error "Expected CONS or Nil at list principal, got ~S in cell ~S."
              (cell-kind cell)
              (cell-id cell))))))

(defun read-list (net free-name &key (atom-reader #'read-atom-from-principal-endpoint))
  "Read a list value exposed at FREE-NAME." 
  (let* ((free (net-free-endpoint net free-name))
         (other (endpoint-link free)))
    (unless other
      (error "Free endpoint ~S is disconnected." free-name))
    (read-list-from-principal-endpoint other :atom-reader atom-reader)))

(defun %lafont-cons-append-rule (net cons-cell append-cell)
  ;; append(cons(x,t), v) -> cons(x, append(t,v))
  (let* ((x (take-port-link cons-cell 1))
         (t-link (take-port-link cons-cell 2))
         (v (take-port-link append-cell 1))
         (result (take-port-link append-cell 2))
         (new-append (make-cell* (gensym "APPEND-") 'append 2))
         (new-cons (make-cell* (gensym "CONS-") 'cons 2)))
    (kill-cell net cons-cell)
    (kill-cell net append-cell)
    (install-cell net new-append)
    (install-cell net new-cons)
    (connect-endpoints net (port-endpoint new-append 0) t-link)
    (connect-endpoints net (port-endpoint new-append 1) v)
    (connect-endpoints net (port-endpoint new-cons 0) result)
    (connect-endpoints net (port-endpoint new-cons 1) x)
    (connect-endpoints net (port-endpoint new-cons 2)
                       (port-endpoint new-append 2))))

(defun %lafont-nil-append-rule (net nil-cell append-cell)
  ;; append(nil, v) -> v
  (let ((v (take-port-link append-cell 1))
        (result (take-port-link append-cell 2)))
    (kill-cell net nil-cell)
    (kill-cell net append-cell)
    (connect-endpoints net v result)))

(defun compile-lafont-rule-spec (spec)
  "Compile a very small S-expression DSL for Figure 9 list rules.

Accepted forms:
  ((cons x (append u t)) (append v (cons x t)))
  (nil (append v v))"
  (cond
    ((equal spec '((cons x (append u t))
                   (append v (cons x t))))
     (values 'cons 'append #'%lafont-cons-append-rule :cons-append))
    ((or (equal spec '(nil (append v v)))
         (equal spec '(|Nil| (append v v))))
     (values '|Nil| 'append #'%lafont-nil-append-rule :nil-append))
    (t
     (error "Unsupported Lafont DSL rule spec ~S." spec))))

(defun define-lafont-rule (runtime spec)
  "Define one Figure-9-style declarative interaction rule."
  (multiple-value-bind (left-kind right-kind function name)
      (compile-lafont-rule-spec spec)
    (define-rule runtime left-kind right-kind function
                 :name name
                 :dsl spec)))

(defparameter *demo-runtime* (make-runtime))

(define-agent *demo-runtime* 'zero 0)
(define-agent *demo-runtime* 'succ 1)
(define-agent *demo-runtime* 'plus 2)

(define-rule
    *demo-runtime* 'zero 'plus
  (lambda (net zero plus)
    (let ((result (take-port-link plus 1))
          (n (take-port-link plus 2)))
      (kill-cell net zero)
      (kill-cell net plus)
      (connect-endpoints net result n))))

(define-rule
    *demo-runtime* 'succ 'plus
  (lambda (net succ plus)
    (let ((x (take-port-link succ 1))
          (result (take-port-link plus 1))
          (n (take-port-link plus 2))
          (new-plus (make-cell* (gensym "PLUS-") 'plus 2))
          (new-succ (make-cell* (gensym "SUCC-") 'succ 1)))
      (install-cell net new-plus)
      (install-cell net new-succ)
      (kill-cell net succ)
      (kill-cell net plus)
      (connect-endpoints net (port-endpoint new-plus 0) x)
      (connect-endpoints net (port-endpoint new-plus 2) n)
      (connect-endpoints net (port-endpoint new-succ 0) result)
      (connect-endpoints net (port-endpoint new-succ 1)
                         (port-endpoint new-plus 1)))))

(defun demo-plus ()
  "Compute 2 + 1 in unary interaction-net form.
Returns three values:
1) natural result
2) interaction count
3) trace object list"
  (let ((net (parse-net
              *demo-runtime*
              '((:agent p plus p-wire result n-wire)
                (:agent a succ p-wire a-pred)
                (:agent b succ a-pred b-pred)
                (:agent z0 zero b-pred)
                (:agent c succ n-wire c-pred)
                (:agent z1 zero c-pred)))))
    (multiple-value-bind (_ steps)
        (reduce-net net :trace t)
      (declare (ignore _))
      (values (read-nat net 'result)
              steps
              (net-trace net)))))

(defparameter *figure9-runtime* (make-runtime :typed-mode t))

(define-symbol *figure9-runtime* 'p 0
  :principal-type 'atom
  :principal-polarity :output)
(define-symbol *figure9-runtime* 'l 0
  :principal-type 'atom
  :principal-polarity :output)
(define-symbol *figure9-runtime* '|0| 0
  :principal-type 'atom
  :principal-polarity :output)
(define-symbol *figure9-runtime* 'cons 2
  :principal-type 'list
  :principal-polarity :output
  :auxiliary-types '(atom list)
  :auxiliary-polarities '(:input :input)
  :auxiliary-partitions '((1) (2)))
(define-symbol *figure9-runtime* '|Nil| 0
  :principal-type 'list
  :principal-polarity :output)
(define-symbol *figure9-runtime* 'append 2
  :principal-type 'list
  :principal-polarity :input
  :auxiliary-types '(list list)
  :auxiliary-polarities '(:input :output)
  :auxiliary-partitions '((1) (2)))

(define-lafont-rule *figure9-runtime*
  '((cons x (append u t))
    (append v (cons x t))))

(define-lafont-rule *figure9-runtime*
  '(|Nil| (append v v)))

(defun demo-append-figure9 ()
  "Reduce a Figure-9-style append example and return the resulting list.

The example computes append([P,0], [L]) and returns (P |0| L)."
  (let ((net (parse-net
              *figure9-runtime*
              '((:agent app append first second result)
                (:agent c1 cons first a1 t1)
                (:agent p1 p a1)
                (:agent c2 cons t1 a2 t2)
                (:agent z1 |0| a2)
                (:agent n1 |Nil| t2)
                (:agent c3 cons second a3 t3)
                (:agent l1 l a3)
                (:agent n2 |Nil| t3)))))
    (multiple-value-bind (_ steps)
        (reduce-net net :trace t)
      (declare (ignore _ steps))
      (values (read-list net 'result)
              (net-trace-object net)))))
