;;;; NOR matcher teaching code

(in-package :hyperdoc)

(see (page "NOR Matcher Teaching Story"))
(see (page "Running HyperDoc Examples"))
(see (page "Writing source code pages"))

(defparameter *nor-demo-expression*
  '(nor
    (nor
     (nor (nor "space")
          (nor "mission"))
     (nor (nor (nor (nor "moon" "lunar")))
          (nor "landing"))))
  "NOR-only spelling of:
(or (and \"space\" \"mission\")
    (and (or \"moon\" \"lunar\") \"landing\"))")

(defvar *nor-demo-trace* nil
  "Dynamically bound trace events for one matcher run.")

(defun nor-demo-record (event)
  (push event *nor-demo-trace*)
  event)

(defun nor-demo-find-word (word target)
  (search word target :test #'char-equal))

(defun nor-demo-final-success (target)
  (declare (ignore target))
  (nor-demo-record '(:continuation :success))
  t)

(defun nor-demo-final-failure (target)
  (declare (ignore target))
  (nor-demo-record '(:continuation :failure))
  nil)

(defun nor-demo-make-string-matcher (word success failure)
  (lambda (target)
    (let ((position (nor-demo-find-word word target)))
      (nor-demo-record
       (list :test word
             :foundp (not (null position))
             :position position))
      (if position
          (funcall success target)
          (funcall failure target)))))

(defun nor-demo-make-nor-matcher (forms success failure)
  "Build a matcher for (nor ...).

A NOR form succeeds only if every subform fails.
If any subform succeeds, the whole NOR form fails immediately."
  (if (endp forms)
      success
      (let ((rest-matcher
             (nor-demo-make-nor-matcher (rest forms) success failure)))
        (nor-demo-make-matcher-aux
         (first forms)
         ;; If the subform succeeds, the enclosing NOR fails.
         (lambda (target)
           (nor-demo-record
            (list :nor-short-circuit
                  :because (first forms)
                  :succeeded))
           (funcall failure target))
         ;; If the subform fails, continue checking the rest.
         rest-matcher))))

(defun nor-demo-make-matcher-aux (form success failure)
  (etypecase form
    (string
     (nor-demo-make-string-matcher form success failure))
    (cons
     (ecase (first form)
       (nor
        (nor-demo-make-nor-matcher (rest form) success failure))))))

(defun nor-demo-make-matcher (form)
  (nor-demo-make-matcher-aux form
                             #'nor-demo-final-success
                             #'nor-demo-final-failure))

(defun nor-demo-run (expression target)
  "Compile EXPRESSION to closures, run it on TARGET, and return an inspectable report."
  (let ((*nor-demo-trace* nil))
    (let ((result (funcall (nor-demo-make-matcher expression) target)))
      (list :expression expression
            :target target
            :result result
            :trace (nreverse *nor-demo-trace*)))))

(defexample nor-demo-empty-success
    "An empty NOR succeeds because no subform succeeds."
  (let ((report
         (nor-demo-run '(nor)
                       "Any target string.")))
    (prog1 report
      (assert-eql (getf report :result) t))))

(defexample nor-demo-simple-success
    "A simple NOR succeeds because neither forbidden word occurs."
  (let ((report
         (nor-demo-run '(nor "shuttle" "joke")
                       "The moon landing was a triumph.")))
    (prog1 report
      (assert-eql (getf report :result) t))))

(defexample nor-demo-simple-failure
    "A simple NOR fails because at least one forbidden word occurs."
  (let ((report
         (nor-demo-run '(nor "shuttle" "joke")
                       "The shuttle program is a joke, though.")))
    (prog1 report
      (assert-eql (getf report :result) nil))))

(defexample nor-demo-original-query-positive
    "The NOR-only spelling of the original query matches a moon-landing sentence."
  (let ((report
         (nor-demo-run *nor-demo-expression*
                       "The moon landing was a triumph of technology.")))
    (prog1 report
      (assert-eql (getf report :result) t))))

(defexample nor-demo-original-query-negative
    "The NOR-only spelling of the original query rejects an unrelated sentence."
  (let ((report
         (nor-demo-run *nor-demo-expression*
                       "The shuttle program is a joke, though.")))
    (prog1 report
      (assert-eql (getf report :result) nil))))

(defun ensure-nor-demo-source-page-registered ()
  "Expose the scoped NOR demo source file as a HyperDoc code page."
  (when (boundp '*hyperdoc*)
    (when-let (module (asdf:find-component (asdf:find-system :hyperdoc/nor-demo)
                                           "hyperdoc"))
      (when-let (component (asdf:find-component module "nor-matcher-demo"))
        (let ((page (make-code-page *hyperdoc* component)))
          (setf (gethash (title-of page) (pages-of *hyperdoc*)) page)
          page)))))

(eval-when (:load-toplevel :execute)
  (ensure-nor-demo-source-page-registered))
