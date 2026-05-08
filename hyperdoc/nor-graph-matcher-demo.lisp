;;;; NOR graph matcher teaching code

(in-package :hyperdoc)

(see (page "NOR Matcher Teaching Story"))
(see (page "NOR Matcher Research Report"))
(see (page "NOR Graph Matcher Teaching Story"))
(see (page "Lafont 1990 Interaction Nets"))

(defstruct nor-graph-agent
  id
  symbol
  alive-p
  metadata)

(defstruct nor-graph-port
  agent-id
  kind
  index)

(defstruct nor-graph-edge
  id
  left-port
  right-port)

(defstruct nor-graph
  agents
  edges
  metadata)

(defvar *nor-graph-trace* nil
  "Dynamically bound trace events for one graph matcher run.")

(defun nor-graph-record (event)
  (push event *nor-graph-trace*)
  event)

(defun nor-graph-find-agent (graph agent-id)
  (find agent-id
        (nor-graph-agents graph)
        :key #'nor-graph-agent-id
        :test #'eql))

(defun nor-graph-agent-alive-in-graph-p (graph agent-id)
  (let ((agent (nor-graph-find-agent graph agent-id)))
    (and agent
         (nor-graph-agent-alive-p agent))))

(defun nor-graph-principal-port-p (port)
  (eq (nor-graph-port-kind port) :principal))

(defun nor-graph-port-evidence (port)
  (list :agent-id (nor-graph-port-agent-id port)
        :kind (nor-graph-port-kind port)
        :index (nor-graph-port-index port)))

(defun nor-graph-agent-evidence (agent)
  (list :agent (nor-graph-agent-id agent)
        :symbol (nor-graph-agent-symbol agent)
        :alive-p (nor-graph-agent-alive-p agent)
        :metadata (nor-graph-agent-metadata agent)))

(defun nor-graph-oriented-principal-connection (edge left-id right-id)
  (let ((edge-left-port (nor-graph-edge-left-port edge))
        (edge-right-port (nor-graph-edge-right-port edge)))
    (when (and (nor-graph-principal-port-p edge-left-port)
               (nor-graph-principal-port-p edge-right-port))
      (cond
        ((and (eql (nor-graph-port-agent-id edge-left-port) left-id)
              (eql (nor-graph-port-agent-id edge-right-port) right-id))
         (values edge-left-port edge-right-port))
        ((and (eql (nor-graph-port-agent-id edge-left-port) right-id)
              (eql (nor-graph-port-agent-id edge-right-port) left-id))
         (values edge-right-port edge-left-port))))))

(defun nor-graph-principal-connected-evidence (graph left-id right-id)
  (loop for edge in (nor-graph-edges graph)
        do (multiple-value-bind (left-port right-port)
               (nor-graph-oriented-principal-connection edge left-id right-id)
             (when (and left-port right-port)
               (return
                 (list :leaf :principal-connected
                       :left-agent left-id
                       :right-agent right-id
                       :edge (nor-graph-edge-id edge)
                       :left-port (nor-graph-port-evidence left-port)
                       :right-port (nor-graph-port-evidence right-port)))))))

(defun nor-graph-active-alive-pair-evidence (graph left-id right-id)
  (let ((connection
          (nor-graph-principal-connected-evidence graph left-id right-id)))
    (when (and connection
               (nor-graph-agent-alive-in-graph-p graph left-id)
               (nor-graph-agent-alive-in-graph-p graph right-id))
      (append (list :leaf :active-alive-pair)
              (cddr connection)
              (list :alive-p t)))))

(defun nor-graph-edge-active-alive-pair-evidence (graph edge)
  (let ((left-port (nor-graph-edge-left-port edge))
        (right-port (nor-graph-edge-right-port edge)))
    (when (and (nor-graph-principal-port-p left-port)
               (nor-graph-principal-port-p right-port))
      (let ((left-id (nor-graph-port-agent-id left-port))
            (right-id (nor-graph-port-agent-id right-port)))
        (when (and (nor-graph-agent-alive-in-graph-p graph left-id)
                   (nor-graph-agent-alive-in-graph-p graph right-id))
          (list :leaf :any-active-alive-pair
                :left-agent left-id
                :right-agent right-id
                :edge (nor-graph-edge-id edge)
                :left-port (nor-graph-port-evidence left-port)
                :right-port (nor-graph-port-evidence right-port)
                :alive-p t))))))

(defun nor-graph-any-active-alive-pair-evidence (graph)
  (loop for edge in (nor-graph-edges graph)
        for evidence = (nor-graph-edge-active-alive-pair-evidence graph edge)
        when evidence
          return evidence))

(defun nor-graph-evaluate-leaf (form graph)
  "Evaluate one graph leaf FORM against GRAPH and return matched-p plus evidence."
  (destructuring-bind (operator &rest args) form
    (ecase operator
      (:agent-alive
       (destructuring-bind (agent-id) args
         (let* ((agent (nor-graph-find-agent graph agent-id))
                (matched-p (and agent (nor-graph-agent-alive-p agent))))
           (values matched-p
                   (and matched-p
                        (append (list :leaf :agent-alive)
                                (nor-graph-agent-evidence agent)))))))
      (:agent-dead
       (destructuring-bind (agent-id) args
         (let* ((agent (nor-graph-find-agent graph agent-id))
                (matched-p (and agent
                                (not (nor-graph-agent-alive-p agent)))))
           (values matched-p
                   (and matched-p
                        (append (list :leaf :agent-dead)
                                (nor-graph-agent-evidence agent)))))))
      (:principal-connected
       (destructuring-bind (left-id right-id) args
         (let ((evidence
                 (nor-graph-principal-connected-evidence graph left-id right-id)))
           (values (not (null evidence)) evidence))))
      (:active-alive-pair
       (destructuring-bind (left-id right-id) args
         (let ((evidence
                 (nor-graph-active-alive-pair-evidence graph left-id right-id)))
           (values (not (null evidence)) evidence))))
      (:any-active-alive-pair
       (destructuring-bind () args
         (let ((evidence
                 (nor-graph-any-active-alive-pair-evidence graph)))
           (values (not (null evidence)) evidence))))
      (:agent-symbol
       (destructuring-bind (agent-id expected-symbol) args
         (let* ((agent (nor-graph-find-agent graph agent-id))
                (matched-p (and agent
                                (eql (nor-graph-agent-symbol agent)
                                     expected-symbol))))
           (values matched-p
                   (and matched-p
                        (append (list :leaf :agent-symbol
                                      :expected-symbol expected-symbol)
                                (nor-graph-agent-evidence agent))))))))))

(defun nor-graph-final-success (graph)
  (declare (ignore graph))
  (nor-graph-record '(:continuation :success))
  t)

(defun nor-graph-final-failure (graph)
  (declare (ignore graph))
  (nor-graph-record '(:continuation :failure))
  nil)

(defun nor-graph-make-leaf-matcher (form success failure)
  (lambda (graph)
    (multiple-value-bind (matched-p evidence)
        (nor-graph-evaluate-leaf form graph)
      (nor-graph-record
       (list :leaf (first form)
             :form form
             :matched-p (not (null matched-p))
             :evidence evidence))
      (if matched-p
          (funcall success graph)
          (funcall failure graph)))))

(defun nor-graph-make-nor-matcher (forms success failure)
  "Build a graph-aware matcher for (nor ...)."
  (if (endp forms)
      success
      (let ((rest-matcher
              (nor-graph-make-nor-matcher (rest forms) success failure)))
        (nor-graph-make-matcher-aux
         (first forms)
         (lambda (graph)
           (nor-graph-record
            (list :nor-short-circuit
                  :because (first forms)
                  :succeeded))
           (funcall failure graph))
         rest-matcher))))

(defun nor-graph-nor-form-p (form)
  (and (consp form)
       (symbolp (first form))
       (string= "NOR" (symbol-name (first form)))))

(defun nor-graph-make-matcher-aux (form success failure)
  (cond
    ((nor-graph-nor-form-p form)
     (nor-graph-make-nor-matcher (rest form) success failure))
    ((and (consp form)
          (keywordp (first form)))
     (nor-graph-make-leaf-matcher form success failure))
    (t
     (error "Unsupported NOR graph matcher form: ~S" form))))

(defun nor-graph-make-nor-matcher-function (form)
  (nor-graph-make-matcher-aux form
                              #'nor-graph-final-success
                              #'nor-graph-final-failure))

(defun nor-graph-run (expression target)
  "Compile EXPRESSION to graph-aware closures, run it on TARGET, and report the trace."
  (let ((*nor-graph-trace* nil))
    (let ((result (funcall (nor-graph-make-nor-matcher-function expression)
                           target)))
      (list :expression expression
            :target target
            :result result
            :trace (nreverse *nor-graph-trace*)))))

(defun make-lefty-rita-agent (id symbol)
  (make-nor-graph-agent
   :id id
   :symbol symbol
   :alive-p t
   :metadata (list :role :interaction-net-agent)))

(defun make-lefty-rita-active-graph ()
  (make-nor-graph
   :agents (list (make-lefty-rita-agent 'lefty 'L)
                 (make-lefty-rita-agent 'rita 'R))
   :edges (list
           (make-nor-graph-edge
            :id 'edge-lefty-rita
            :left-port (make-nor-graph-port
                        :agent-id 'lefty
                        :kind :principal
                        :index 0)
            :right-port (make-nor-graph-port
                         :agent-id 'rita
                         :kind :principal
                         :index 0)))
   :metadata (list :fixture :lefty-rita-active
                   :read-only-p t)))

(defun make-lefty-rita-inactive-graph ()
  (make-nor-graph
   :agents (list (make-lefty-rita-agent 'lefty 'L)
                 (make-lefty-rita-agent 'rita 'R))
   :edges (list
           (make-nor-graph-edge
            :id 'edge-lefty-rita-auxiliary
            :left-port (make-nor-graph-port
                        :agent-id 'lefty
                        :kind :aux
                        :index 1)
            :right-port (make-nor-graph-port
                         :agent-id 'rita
                         :kind :principal
                         :index 0)))
   :metadata (list :fixture :lefty-rita-inactive
                   :normal-form-candidate t
                   :read-only-p t)))

(defexample nor-graph-active-pair-leaf-success
    (:system "hyperdoc/nor-graph-demo"
     :page "NOR Graph Matcher Teaching Story"
     :tags '(:nor :graph :interaction-net))
    "The active/alive pair leaf succeeds because Lefty and Rita are alive and principal-connected."
  (let ((report
          (nor-graph-run
           '(:active-alive-pair lefty rita)
           (make-lefty-rita-active-graph))))
    (prog1 report
      (assert-eql (getf report :result) t))))

(defexample nor-graph-active-pair-nor-failure
    (:system "hyperdoc/nor-graph-demo"
     :page "NOR Graph Matcher Teaching Story"
     :tags '(:nor :graph :interaction-net))
    "The NOR form fails because the forbidden active/alive pair exists."
  (let ((report
          (nor-graph-run
           '(nor (:active-alive-pair lefty rita))
           (make-lefty-rita-active-graph))))
    (prog1 report
      (assert-eql (getf report :result) nil))))

(defexample nor-graph-normal-form-success
    (:system "hyperdoc/nor-graph-demo"
     :page "NOR Graph Matcher Teaching Story"
     :tags '(:nor :graph :interaction-net))
    "The graph is in normal form because it has no active/alive pairs."
  (let ((report
          (nor-graph-run
           '(nor (:any-active-alive-pair))
           (make-lefty-rita-inactive-graph))))
    (prog1 report
      (assert-eql (getf report :result) t))))

(defexample nor-graph-normal-form-failure
    (:system "hyperdoc/nor-graph-demo"
     :page "NOR Graph Matcher Teaching Story"
     :tags '(:nor :graph :interaction-net))
    "The graph is not in normal form because Lefty and Rita form an active/alive pair."
  (let ((report
          (nor-graph-run
           '(nor (:any-active-alive-pair))
           (make-lefty-rita-active-graph))))
    (prog1 report
      (assert-eql (getf report :result) nil))))

(defun ensure-nor-graph-demo-source-page-registered ()
  "Expose the scoped NOR graph demo source file as a HyperDoc code page."
  (when (boundp '*hyperdoc*)
    (when-let (module (asdf:find-component (asdf:find-system :hyperdoc/nor-graph-demo)
                                           "hyperdoc"))
      (when-let (component (asdf:find-component module "nor-graph-matcher-demo"))
        (let ((page (make-code-page *hyperdoc* component)))
          (setf (gethash (title-of page) (pages-of *hyperdoc*)) page)
          page)))))

(eval-when (:load-toplevel :execute)
  (ensure-nor-graph-demo-source-page-registered))
