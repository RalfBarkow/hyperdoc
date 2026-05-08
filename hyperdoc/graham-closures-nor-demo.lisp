;;;; Graham closures and NOR graph matcher teaching code

(in-package :hyperdoc)

(see (page "Graham Closures and the NOR Graph Matcher"))
(see (page "NOR Matcher Teaching Story"))
(see (page "Running HyperDoc Examples"))
(see (page "Writing source code pages"))

;;;; Graham-style closure warmups

(defun closure-nor-demo-make-adder (n)
  "Return a function that remembers N and adds it to its argument."
  (lambda (x)
    (+ x n)))

(defun closure-nor-demo-our-complement (predicate)
  "Return a predicate that remembers PREDICATE and reverses its result."
  (lambda (&rest args)
    (not (apply predicate args))))

(defexample closure-nor-demo-make-adder-example
    (:system "hyperdoc/closures-nor-demo"
     :page "Graham Closures and the NOR Graph Matcher"
     :tags '(:graham :closures :nor :graph :teaching))
    "A returned function remembers the lexical value N from MAKE-ADDER."
  (let* ((add3 (closure-nor-demo-make-adder 3))
         (add27 (closure-nor-demo-make-adder 27))
         (report (list :add3-of-2 (funcall add3 2)
                       :add27-of-2 (funcall add27 2))))
    (assert-eql (getf report :add3-of-2) 5)
    (assert-eql (getf report :add27-of-2) 29)
    report))

(defexample closure-nor-demo-complement-example
    (:system "hyperdoc/closures-nor-demo"
     :page "Graham Closures and the NOR Graph Matcher"
     :tags '(:graham :closures :nor :graph :teaching))
    "A complement closure remembers the original predicate and reverses it."
  (let* ((not-oddp (closure-nor-demo-our-complement #'oddp))
         (report (list :input '(1 2 3 4 5 6)
                       :not-odd-results (mapcar not-oddp '(1 2 3 4 5 6)))))
    (assert-equal (getf report :not-odd-results)
                  '(nil t nil t nil t))
    report))

;;;; Tiny graph model used only for the teaching examples

(defparameter *closure-nor-demo-apollo-graph*
  '(:agents (:moon :landing :camera)
    :ports  ((:moon :principal)
             (:landing :target)
             (:camera :aux))
    :edges  ((:moon :principal :landing :target)
             (:camera :aux :landing :target)))
  "A tiny graph that contains a moon-landing shape.")

(defparameter *closure-nor-demo-space-mission-graph*
  '(:agents (:space :mission :probe)
    :ports  ((:space :principal)
             (:mission :target)
             (:probe :aux))
    :edges  ((:space :principal :mission :target)
             (:probe :aux :mission :target)))
  "A tiny graph that contains a space-mission shape.")

(defparameter *closure-nor-demo-shuttle-graph*
  '(:agents (:shuttle :program :joke)
    :ports  ((:shuttle :principal)
             (:program :target)
             (:joke :aux))
    :edges  ((:shuttle :principal :program :target)))
  "A tiny graph that does not satisfy the moon-landing or space-mission query.")

(defparameter *closure-nor-demo-original-graph-query*
  '(nor
    (nor
     (nor (nor (:agent :space))
          (nor (:agent :mission)))
     (nor (nor (nor (nor (:agent :moon) (:agent :lunar))))
          (nor (:agent :landing)))))
  "NOR-only spelling of:
(or (and (:agent :space) (:agent :mission))
    (and (or (:agent :moon) (:agent :lunar)) (:agent :landing)))")

(defvar *closure-nor-demo-trace* nil
  "Dynamically bound trace events for one graph matcher run.")

(defun closure-nor-demo-record (event)
  (push event *closure-nor-demo-trace*)
  event)

(defun closure-nor-demo-agent-present-p (name graph)
  (not (null (member name (getf graph :agents) :test #'eq))))

(defun closure-nor-demo-port-present-p (agent port graph)
  (not (null (member (list agent port) (getf graph :ports) :test #'equal))))

(defun closure-nor-demo-edge-present-p (from from-port to to-port graph)
  (let ((edge (list from from-port to to-port))
        (reverse-edge (list to to-port from from-port)))
    (not (null (or (member edge (getf graph :edges) :test #'equal)
                   (member reverse-edge (getf graph :edges) :test #'equal))))))

(defun closure-nor-demo-leaf-succeeds-p (form graph)
  "Evaluate one graph leaf form against GRAPH."
  (ecase (first form)
    (:agent
     (destructuring-bind (_ name) form
       (declare (ignore _))
       (closure-nor-demo-agent-present-p name graph)))
    (:port
     (destructuring-bind (_ agent port) form
       (declare (ignore _))
       (closure-nor-demo-port-present-p agent port graph)))
    (:edge
     (destructuring-bind (_ from from-port to to-port) form
       (declare (ignore _))
       (closure-nor-demo-edge-present-p from from-port to to-port graph)))))

(defun closure-nor-demo-nor-form-p (form)
  "Return true when FORM is a package-tolerant (NOR ...) form."
  (and (consp form)
       (symbolp (first form))
       (string= "NOR" (symbol-name (first form)))))

(defun closure-nor-demo-final-success (graph)
  (declare (ignore graph))
  (closure-nor-demo-record '(:continuation :success))
  t)

(defun closure-nor-demo-final-failure (graph)
  (declare (ignore graph))
  (closure-nor-demo-record '(:continuation :failure))
  nil)

(defun closure-nor-demo-make-graph-leaf-matcher (form success failure)
  "Return a closure that remembers FORM plus the SUCCESS and FAILURE exits."
  (lambda (graph)
    (let ((succeeded-p (closure-nor-demo-leaf-succeeds-p form graph)))
      (closure-nor-demo-record
       (list :event :leaf
             :leaf form
             :remembered-leaf form
             :matched-p succeeded-p
             :succeeded-p succeeded-p))
      (if succeeded-p
          (funcall success graph)
          (funcall failure graph)))))

(defun closure-nor-demo-make-nor-matcher (forms success failure)
  "Build a closure matcher for (nor ...).

A NOR form succeeds only if every subform fails.  If any subform succeeds,
the enclosing NOR fails immediately."
  (if (endp forms)
      success
      (let ((rest-matcher
              (closure-nor-demo-make-nor-matcher (rest forms) success failure)))
        (closure-nor-demo-make-matcher-aux
         (first forms)
         ;; If the subform succeeds, the enclosing NOR fails.
         (lambda (graph)
           (closure-nor-demo-record
            (list :event :nor-short-circuit
                  :nor-short-circuit t
                  :because (first forms)
                  :child-matched-p t
                  :nor-result nil))
           (funcall failure graph))
         ;; If the subform fails, continue checking the rest.
         rest-matcher))))

(defun closure-nor-demo-make-matcher-aux (form success failure)
  (cond
    ((closure-nor-demo-nor-form-p form)
     (closure-nor-demo-make-nor-matcher (rest form) success failure))
    ((and (consp form) (member (first form) '(:agent :port :edge)))
     (closure-nor-demo-make-graph-leaf-matcher form success failure))
    (t
     (error "Unsupported graph matcher form: ~S" form))))

(defun closure-nor-demo-make-matcher (form)
  "Compile FORM into a graph matcher made of closures."
  (closure-nor-demo-make-matcher-aux form
                                     #'closure-nor-demo-final-success
                                     #'closure-nor-demo-final-failure))

(defun closure-nor-demo-run (expression graph)
  "Compile EXPRESSION to closures, run it on GRAPH, and return an inspectable report."
  (let ((matcher (closure-nor-demo-make-matcher expression))
        (*closure-nor-demo-trace* nil))
    (let ((result (funcall matcher graph)))
      (list :expression expression
            :graph graph
            :result result
            :trace (nreverse *closure-nor-demo-trace*)))))

(defexample closure-nor-demo-graph-leaf-example
    (:system "hyperdoc/closures-nor-demo"
     :page "Graham Closures and the NOR Graph Matcher"
     :tags '(:graham :closures :nor :graph :teaching))
    "A graph leaf closure remembers its form and the two continuations."
  (let ((report
          (closure-nor-demo-run '(:agent :moon)
                                *closure-nor-demo-apollo-graph*)))
    (assert-eql (getf report :result) t)
    report))

(defexample closure-nor-demo-graph-nor-success-example
    (:system "hyperdoc/closures-nor-demo"
     :page "Graham Closures and the NOR Graph Matcher"
     :tags '(:graham :closures :nor :graph :teaching))
    "A NOR graph matcher succeeds when none of the forbidden graph leaves succeed."
  (let ((report
          (closure-nor-demo-run '(nor (:agent :shuttle) (:agent :joke))
                                *closure-nor-demo-apollo-graph*)))
    (assert-eql (getf report :result) t)
    report))

(defexample closure-nor-demo-graph-nor-short-circuit-example
    (:system "hyperdoc/closures-nor-demo"
     :page "Graham Closures and the NOR Graph Matcher"
     :tags '(:graham :closures :nor :graph :teaching))
    "A NOR graph matcher fails immediately when one forbidden graph leaf succeeds."
  (let ((report
          (closure-nor-demo-run '(nor (:agent :shuttle) (:agent :joke))
                                *closure-nor-demo-shuttle-graph*)))
    (assert-eql (getf report :result) nil)
    report))

(defexample closure-nor-demo-original-query-graph-positive-example
    (:system "hyperdoc/closures-nor-demo"
     :page "Graham Closures and the NOR Graph Matcher"
     :tags '(:graham :closures :nor :graph :teaching))
    "The graph-shaped original query matches the Apollo graph."
  (let ((report
          (closure-nor-demo-run *closure-nor-demo-original-graph-query*
                                *closure-nor-demo-apollo-graph*)))
    (assert-eql (getf report :result) t)
    report))

(defexample closure-nor-demo-original-query-graph-negative-example
    (:system "hyperdoc/closures-nor-demo"
     :page "Graham Closures and the NOR Graph Matcher"
     :tags '(:graham :closures :nor :graph :teaching))
    "The graph-shaped original query rejects the shuttle graph."
  (let ((report
          (closure-nor-demo-run *closure-nor-demo-original-graph-query*
                                *closure-nor-demo-shuttle-graph*)))
    (assert-eql (getf report :result) nil)
    report))

(defun ensure-closure-nor-demo-source-page-registered ()
  "Expose the Graham closure/NOR graph demo source file as a HyperDoc code page."
  (when (boundp '*hyperdoc*)
    (when-let (module (asdf:find-component (asdf:find-system :hyperdoc/closures-nor-demo)
                                           "hyperdoc"))
      (when-let (component (asdf:find-component module "graham-closures-nor-demo"))
        (let ((page (make-code-page *hyperdoc* component)))
          (setf (gethash (title-of page) (pages-of *hyperdoc*)) page)
          page)))))

(eval-when (:load-toplevel :execute)
  (ensure-closure-nor-demo-source-page-registered))
