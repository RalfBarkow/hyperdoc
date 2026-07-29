;;;; Topic constructors and optional registration into a loaded HyperDoc image.

(in-package #:hyperdoc-graham-roots-of-lisp)

(defparameter *roots-topic-data*
  '(("graham-the-roots-of-lisp"
     "The Roots of Lisp"
     "Executable source station for Graham's reconstruction of McCarthy's semantic core."
     "The Roots of Lisp.html"
     ("Paul Graham, The Roots of Lisp"
      "John McCarthy, Recursive Functions of Symbolic Expressions"))
    ("roots-seven-primitive-operators"
     "Roots of Lisp seven primitive operators"
     "QUOTE, ATOM, EQ, CAR, CDR, CONS, and COND as the axiomatic evaluator boundary."
     "The Roots of Lisp reconstruction layers.html"
     ("The Roots of Lisp" "What Made Lisp Different"))
    ("roots-denoting-functions"
     "Roots of Lisp denoting functions"
     "LAMBDA and LABEL as data notations interpreted through explicit dynamic environments."
     "The Roots of Lisp reconstruction layers.html"
     ("Roots of Lisp seven primitive operators"))
    ("roots-the-surprise"
     "The Surprise as an evaluation trace"
     "The object-language EVAL. definition evaluating another object-language expression."
     "The Surprise as an evaluation trace.html"
     ("The Roots of Lisp" "HyperDoc Evaluation and Inspection Model"))
    ("roots-stanford-interpreter-adapter"
     "Stanford Lisp interpreter adapter"
     "Crosswalk separating Graham's semantic core from parser, top-level, error, prelude, and browser adapters."
     "Stanford Lisp interpreter crosswalk.html"
     ("The Roots of Lisp" "Lambda calculus - Lisp"))
    ("roots-what-made-lisp-different"
     "What Made Lisp Different crosswalk"
     "Nine historical language ideas mapped to concrete evaluator and HyperDoc surfaces."
     "What Made Lisp Different crosswalk.html"
     ("The Roots of Lisp" "What Made Lisp Different"))
    ("roots-graham-corrected-bugs"
     "Which bugs did Graham correct?"
     "Source-backed comparison of McCarthy's named-call double evaluation, Graham's executable correction, and the separate dynamic-binding limitation."
     "Which bugs did Graham correct?.html"
     ("The Roots of Lisp"
      "Recursive Functions of Symbolic Expressions and Their Computation by Machine, Part I"))
    ("roots-dynamic-capture-maplist-diff"
     "Dynamic capture in MAPLIST and DIFF"
     "Executable minimal witness for dynamic capture, related conservatively to Graham's MAPLIST/DIFF collision diagnosis."
     "Dynamic capture in MAPLIST and DIFF.html"
     ("The Roots of Lisp" "Which bugs did Graham correct?"))
    ("roots-of-lisp-browser-runner-comparison"
     "Roots of Lisp browser runner comparison"
     "Inspectable comparison of Ben Lynn's pinned browser/Wasm runner, its FedWiki frame projection, and HyperDoc's distinct Common Lisp evaluator."
     "Roots of Lisp runner comparison.html"
     ("The Roots of Lisp"
      "The Surprise as an evaluation trace"
      "https://crypto.stanford.edu/~blynn/lambda/lisp.html"))))

(defun make-roots-topic-from-data (data)
  (destructuring-bind (id title summary page references) data
    (make-instance 'roots-topic
                   :id id
                   :title title
                   :summary summary
                   :page page
                   :references references)))

(defparameter *roots-topics*
  (mapcar #'make-roots-topic-from-data *roots-topic-data*))

(defun all-roots-topics ()
  (copy-list *roots-topics*))

(defun roots-topic-by-id (id)
  (find id *roots-topics* :key #'id-of :test #'string=))

(defun roots-topic-by-title (title)
  (find title *roots-topics* :key #'title-of :test #'string=))

(defun roots-of-lisp-topic ()
  (roots-topic-by-id "graham-the-roots-of-lisp"))

(defun roots-seven-primitives-topic ()
  (roots-topic-by-id "roots-seven-primitive-operators"))

(defun roots-denoting-functions-topic ()
  (roots-topic-by-id "roots-denoting-functions"))

(defun roots-surprise-topic ()
  (roots-topic-by-id "roots-the-surprise"))

(defun roots-stanford-adapter-topic ()
  (roots-topic-by-id "roots-stanford-interpreter-adapter"))

(defun roots-nine-ideas-topic ()
  (roots-topic-by-id "roots-what-made-lisp-different"))

(defun roots-corrected-bugs-topic ()
  (roots-topic-by-id "roots-graham-corrected-bugs"))

(defun roots-dynamic-capture-topic ()
  (roots-topic-by-id "roots-dynamic-capture-maplist-diff"))

(defun roots-lynn-runner-topic ()
  (roots-topic-by-id "roots-of-lisp-browser-runner-comparison"))

(defun register-roots-topics-into-hyperdoc (&key (signal-error nil))
  "Materialize the local topics through HYPERDOC::MAKE-TOPIC when available."
  (let* ((package (find-package "HYPERDOC"))
         (make-topic
           (and package (find-symbol "MAKE-TOPIC" package))))
    (cond
      ((and make-topic (fboundp make-topic))
       (list
        :status :registered
        :count
        (length
         (mapcar
          (lambda (topic)
            (funcall
             (symbol-function make-topic)
             :id (id-of topic)
             :title (title-of topic)
             :summary (summary-of topic)
             :references (references-of topic)))
          *roots-topics*))))
      (signal-error
       (error "HYPERDOC::MAKE-TOPIC is not available."))
      (t
       (list :status :unavailable
             :reason "Load :HYPERDOC/TOPICS before registration."
             :topics (mapcar #'title-of *roots-topics*))))))

(in-package #:hyperdoc)

(defun roots-of-lisp-browser-runner-comparison-topic ()
  "Return the durable Topics-hyperbook projection of the Roots runner topic."
  (let ((topic
          (hyperdoc-graham-roots-of-lisp:roots-lynn-runner-topic)))
    (make-topic
     :id (hyperdoc-graham-roots-of-lisp:id-of topic)
     :title (hyperdoc-graham-roots-of-lisp:title-of topic)
     :summary (hyperdoc-graham-roots-of-lisp:summary-of topic)
     :references (hyperdoc-graham-roots-of-lisp:references-of topic))))

(defun roots-of-lisp-corrected-bugs-topic ()
  "Return the Topics-hyperbook projection of the corrected-bugs topic."
  (let ((topic
          (hyperdoc-graham-roots-of-lisp:roots-corrected-bugs-topic)))
    (make-topic
     :id (hyperdoc-graham-roots-of-lisp:id-of topic)
     :title (hyperdoc-graham-roots-of-lisp:title-of topic)
     :summary (hyperdoc-graham-roots-of-lisp:summary-of topic)
     :references (hyperdoc-graham-roots-of-lisp:references-of topic))))

(defun roots-of-lisp-dynamic-capture-topic ()
  "Return the Topics-hyperbook projection of the dynamic-capture topic."
  (let ((topic
          (hyperdoc-graham-roots-of-lisp:roots-dynamic-capture-topic)))
    (make-topic
     :id (hyperdoc-graham-roots-of-lisp:id-of topic)
     :title (hyperdoc-graham-roots-of-lisp:title-of topic)
     :summary (hyperdoc-graham-roots-of-lisp:summary-of topic)
     :references (hyperdoc-graham-roots-of-lisp:references-of topic))))

(in-package #:hyperdoc-graham-roots-of-lisp)

(eval-when (:load-toplevel :execute)
  (hyperdoc::roots-of-lisp-browser-runner-comparison-topic)
  (hyperdoc::roots-of-lisp-corrected-bugs-topic)
  (hyperdoc::roots-of-lisp-dynamic-capture-topic))
