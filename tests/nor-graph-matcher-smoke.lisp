;;;; Smoke tests for the NOR graph matcher teaching demo

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-NOR-GRAPH-MATCHER-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun nor-graph-smoke-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun nor-graph-smoke-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun nor-graph-smoke-plist-key-present-p (plist key)
  (loop for (plist-key nil) on plist by #'cddr
        thereis (eq plist-key key)))

(defun nor-graph-smoke-leaf-events (report leaf)
  (remove-if-not (lambda (event)
                   (and (consp event)
                        (eq (getf event :leaf) leaf)))
                 (getf report :trace)))

(defun nor-graph-smoke-successful-leaf-evidence (report leaf)
  (loop for event in (nor-graph-smoke-leaf-events report leaf)
        when (and (getf event :matched-p)
                  (getf event :evidence))
          return (getf event :evidence)))

(defun nor-graph-smoke-report-shape-p (report)
  (and (nor-graph-smoke-plist-key-present-p report :expression)
       (nor-graph-smoke-plist-key-present-p report :target)
       (nor-graph-smoke-plist-key-present-p report :result)
       (nor-graph-smoke-plist-key-present-p report :trace)))

(defun nor-graph-smoke-example-results ()
  (mapcar (lambda (example)
            (list example
                  (getf (funcall example) :result)))
          '(hyperdoc::nor-graph-active-pair-leaf-success
            hyperdoc::nor-graph-active-pair-nor-failure
            hyperdoc::nor-graph-normal-form-success
            hyperdoc::nor-graph-normal-form-failure)))

(defun run-nor-graph-matcher-example-smoke-test ()
  (asdf:load-system :hyperdoc/nor-graph-demo :force t)
  (nor-graph-smoke-assert-equal
   '((hyperdoc::nor-graph-active-pair-leaf-success t)
     (hyperdoc::nor-graph-active-pair-nor-failure nil)
     (hyperdoc::nor-graph-normal-form-success t)
     (hyperdoc::nor-graph-normal-form-failure nil))
   (nor-graph-smoke-example-results)
   "NOR graph examples must return the expected Boolean results")
  (dolist (example '(hyperdoc::nor-graph-active-pair-leaf-success
                     hyperdoc::nor-graph-active-pair-nor-failure
                     hyperdoc::nor-graph-normal-form-success
                     hyperdoc::nor-graph-normal-form-failure))
    (nor-graph-smoke-assert-true
     (nor-graph-smoke-report-shape-p (funcall example))
     (format nil "Example ~S must return expression/target/result/trace"
             example))))

(defun run-nor-graph-matcher-evidence-smoke-test ()
  (let* ((active-report
           (hyperdoc::nor-graph-run
            '(:active-alive-pair hyperdoc::lefty hyperdoc::rita)
            (hyperdoc::make-lefty-rita-active-graph)))
         (nor-failure-report
           (hyperdoc::nor-graph-run
            '(hyperdoc::nor (:any-active-alive-pair))
            (hyperdoc::make-lefty-rita-active-graph)))
         (normal-report
           (hyperdoc::nor-graph-run
            '(hyperdoc::nor (:any-active-alive-pair))
            (hyperdoc::make-lefty-rita-inactive-graph)))
         (active-evidence
           (nor-graph-smoke-successful-leaf-evidence active-report
                                                     :active-alive-pair))
         (any-evidence
           (nor-graph-smoke-successful-leaf-evidence nor-failure-report
                                                     :any-active-alive-pair))
         (normal-leaf
           (first (nor-graph-smoke-leaf-events normal-report
                                               :any-active-alive-pair))))
    (dolist (key '(:leaf :left-agent :right-agent :edge :left-port :right-port
                   :alive-p))
      (nor-graph-smoke-assert-true
       (nor-graph-smoke-plist-key-present-p active-evidence key)
       (format nil "Active/alive evidence must include ~S" key)))
    (nor-graph-smoke-assert-equal
     'hyperdoc::edge-lefty-rita
     (getf active-evidence :edge)
     "Active/alive pair evidence must name the principal edge")
    (nor-graph-smoke-assert-equal
     'hyperdoc::edge-lefty-rita
     (getf any-evidence :edge)
     "Any-active evidence must include a graph witness edge")
    (nor-graph-smoke-assert-equal
     nil
     (getf normal-leaf :matched-p)
     "Normal-form success must record the failed any-active leaf")
    (nor-graph-smoke-assert-equal
     nil
     (getf normal-leaf :evidence)
     "Failed graph leaves must carry NIL evidence")))

(defun run-nor-graph-matcher-boundary-smoke-test ()
  (let* ((agent
           (hyperdoc::make-nor-graph-agent
            :id 'lefty
            :symbol 'L
            :alive-p t))
         (graph
           (hyperdoc::make-nor-graph
            :agents (list agent)
            :edges nil)))
    (nor-graph-smoke-assert-equal
     t
     (hyperdoc::nor-graph-agent-alive-p agent)
     "DEFSTRUCT accessor NOR-GRAPH-AGENT-ALIVE-P must remain the agent accessor")
    (nor-graph-smoke-assert-equal
     t
     (hyperdoc::nor-graph-agent-alive-in-graph-p graph 'lefty)
     "Graph-level alive predicate must resolve existing live agents")
    (multiple-value-bind (matched-p evidence)
        (hyperdoc::nor-graph-evaluate-leaf '(:agent-dead missing) graph)
      (nor-graph-smoke-assert-equal
       nil
       matched-p
       "Missing agents must not count as dead")
      (nor-graph-smoke-assert-equal
       nil
       evidence
       "Missing dead-agent checks must not fabricate evidence"))))

(defun run-nor-graph-matcher-page-smoke-test ()
  (asdf:load-system :hyperdoc/server)
  (let ((page
          (hyperbook:find-page hyperdoc::*hyperdoc*
                               "NOR Graph Matcher Teaching Story"
                               :signal-error? t))
        (source
          (uiop:read-file-string
           (asdf:system-relative-pathname
            :hyperdoc
            "hyperdoc/NOR Graph Matcher Teaching Story.html"))))
    (nor-graph-smoke-assert-true
     (uiop:string-prefix-p "<h1>NOR Graph Matcher Teaching Story</h1>" source)
     "Teaching page must start with the required h1")
    (dolist (name '("nor-graph-active-pair-leaf-success"
                    "nor-graph-active-pair-nor-failure"
                    "nor-graph-normal-form-success"
                    "nor-graph-normal-form-failure"))
      (nor-graph-smoke-assert-true
       (search (format nil "<source-of-function>~A</source-of-function>" name)
               source
               :test #'char=)
       (format nil "Teaching page must include source block for ~A" name)))
    (nor-graph-smoke-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc*
                          "NOR graph matcher teaching code"
                          :signal-error? t)
     "Server-facing runtime must register the graph source code page")
    (nor-graph-smoke-assert-equal
     nil
     (hyperbook:lookup-issues-of page)
     "Teaching page must not introduce page-level lookup issues")))

(defun run-nor-graph-matcher-smoke-tests ()
  (run-nor-graph-matcher-example-smoke-test)
  (run-nor-graph-matcher-evidence-smoke-test)
  (run-nor-graph-matcher-boundary-smoke-test)
  (run-nor-graph-matcher-page-smoke-test)
  (format t "~&NOR graph matcher smoke tests passed.~%")
  t)
