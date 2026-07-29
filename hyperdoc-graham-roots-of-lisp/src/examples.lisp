;;;; Examples to help us understand McCarthy's EVAL
;;;; and Graham's reconstruction.
;;;;
;;;; Primary texts:
;;;; John McCarthy, “Recursive Functions of Symbolic Expressions and
;;;; Their Computation by Machine, Part I,” Communications of the ACM
;;;; 3(4), April 1960, pp. 184–195.
;;;; Paul Graham, The Roots of Lisp, draft dated 18 January 2002.
;;;;
;;;; Historical comparison:
;;;; Herbert Stoyan, “The Influence of the Designer on the Design—
;;;; J. McCarthy and LISP,” in Vladimir Lifschitz (ed.),
;;;; Artificial Intelligence and Mathematical Theory of Computation,
;;;; Academic Press, 1991, pp. 409–426.


(in-package #:hyperdoc-graham-roots-of-lisp)

(defparameter *roots-subst-call-source*
  "
((label subst
   (lambda (x y z)
     (cond
       ((atom z)
        (cond ((eq z y) x)
              ('t z)))
       ('t
        (cons (subst x y (car z))
              (subst x y (cdr z)))))))
 'm
 'b
 '(a b (a b c) d))
")

(defparameter *roots-surprise-source*
  "
(eval.
 '((label subst
     (lambda (x y z)
       (cond
         ((atom z)
          (cond ((eq z y) x)
                ('t z)))
         ('t
          (cons (subst x y (car z))
                (subst x y (cdr z)))))))
   'm
   'b
   '(a b (a b c) d))
 '())
")

(defparameter *roots-named-call-double-evaluation-source*
  "
((lambda (f)
   (f '(b c)))
 '(lambda (x)
    (cons 'a x)))
")

(defun roots-named-call-version-history ()
  "Return the source-backed history of the named-function clause and its witness."
  (let ((history
         (copy-tree
          '(:terminology
            (:term :named-call-rule :status :hyperdoc-analytic-label :definition
             "The fallback clause in EVAL for an application whose operator is an
atomic name not recognized as a primitive. The clause replaces that name
with its A-list meaning and evaluates the resulting application.")
            :witness
            (:status :derived :source nil :from
             (:author "Paul Graham" :work "The Roots of Lisp" :draft-date "2002-01-18"
              :printed-page 9 :source-form
              "(eval. '(f '(b c)) '((f (lambda (x) (cons 'a x)))))")
             :transformation :environment-binding-to-outer-lambda :purpose
             :closed-empty-environment-replay)
            :versions
            ((:id :mccarthy-1960-published :author "John McCarthy" :work
              "Recursive Functions of Symbolic Expressions and Their Computation by Machine, Part I"
              :publication "Communications of the ACM 3(4), April 1960, pp. 184-195"
              :printed-page 189 :stanford-typesetting-page 16 :named-function-clause
              "eval[cons[assoc[car[e];a];evlis[cdr[e];a]];a]" :argument-policy
              :evaluate-before-operator-rewrite :observed-risk :double-evaluation)
             (:id :mccarthy-1995-annotation :version-of :mccarthy-1960-published
              :source :stanford-typesetting :typesetting-page 17 :footnote 5
              :code-change :none :qualification :published-eval-not-quite-right
              :refers-to :stoyan-1991-historical-comparison)
             (:id :stoyan-1991-historical-comparison :author "Herbert Stoyan" :work
              "The Influence of the Designer on the Design - J. McCarthy and LISP"
              :printed-page-range (409 426) :role :comparison-not-single-corrected-rule
              :first-known-realized-interpreter
              (:printed-pages (414 415) :system-properties (:call-by-value :a-lists)
               :reported-textual-corrections
               ((:location :lines-18-and-26 :repair :restore-parentheses)
                (:location :line-23 :repair :restore-lost-line-ending)
                (:location :vare-lookup :repair :cadar-to-caar))
               :remaining-problems
               (:lambda-clause-missing :functional-arguments-defective))
              :second-theoretical-interpreter
              (:printed-page 418 :argument-policy :mixed-evaluated-and-unevaluated
               :double-evaluation :prevented-by-requoting :remaining-problem
               :lambda-case-missing)
              :later-call-by-value-version
              (:printed-pages (418 419) :argument-policy :strict-call-by-value
               :remaining-problem :functional-arguments-forgotten)
              :evaluator-mode :none)
             (:id :stoyan-1978-handbook :author "Herbert Stoyan" :work
              "LISP - Programmierhandbuch" :publication "Akademie-Verlag, Berlin, 1978"
              :printed-pages (134 135 136) :described-system :dos-es-lisp-1.6-family
              :named-function-step :replace-name-with-expr-meaning :following-step
              :evaluate-arguments-for-lambda :relation-to-graham
              :same-local-order-different-interpreter-architecture)
             (:id :graham-2002-correction :author "Paul Graham" :work
              "The Roots of Lisp" :draft-date "2002-01-18" :printed-pages (8 9 12)
              :named-function-clause "(eval. (cons (assoc. (car e) a) (cdr e)) a)"
              :page-12-diagnosis :replace-evlis-of-cdr-with-cdr :argument-policy
              :preserve-source-forms-until-lambda :effect :single-evaluation)
             (:id :hyperdoc-reconstruction :path
              "hyperdoc-graham-roots-of-lisp/src/evaluator.lisp" :evaluator-modes
              (:mccarthy-paper :graham-corrected) :stoyan-mode-p nil :boundary
              "Stoyan's versions are historical comparison entries, not additional evaluator modes."))))))
    (setf (getf (getf history :witness) :source)
            *roots-named-call-double-evaluation-source*)
    history))

(defparameter *roots-dynamic-binding-capture-source*
  "
((lambda (x)
   ((lambda (f)
      ((lambda (x)
         (f 'ignored))
       'inner))
    '(lambda (z) x)))
 'outer)
")

(defun roots-seven-primitive-reports (&key (event-limit 200))
  "Return one inspectable example for each primitive operator."
  (mapcar
   (lambda (entry)
     (destructuring-bind (name source) entry
       (list :primitive name
             :source source
             :evaluation
             (roots-evaluate-source source :event-limit event-limit))))
   '((:quote "(quote (a b c))")
     (:atom "(atom '())")
     (:eq "(eq 'a 'a)")
     (:car "(car '(a b c))")
     (:cdr "(cdr '(a b c))")
     (:cons "(cons 'a '(b c))")
     (:cond "(cond ((eq 'a 'b) 'first) ((atom 'a) 'second))"))))

(defun roots-direct-subst-report (&key (event-limit 1500))
  "Run Graham's recursive SUBST definition directly through LABEL."
  (roots-evaluate-source
   *roots-subst-call-source*
   :event-limit event-limit))

(defun roots-surprise-report (&key (event-limit 5000))
  "Use the object-language EVAL. definition to evaluate the SUBST example."
  (let ((session (roots-bootstrap-session)))
    (roots-session-evaluate
     session
     (roots-read-form *roots-surprise-source*)
     :source *roots-surprise-source*
     :event-limit event-limit)))

(defun roots-named-call-double-evaluation-report
    (&key (source *roots-named-call-double-evaluation-source*)
          (event-limit 1000))
  "Compare McCarthy's published 1960 named-function clause (p. 189)
with Graham's 2002 named-call correction (pp. 8-9 and 12).

By default, use a closed witness derived from Graham's page-9 example;
SOURCE may supply another witness. McCarthy's 1995 footnote 5 leaves the
printed clause unchanged and refers to Stoyan (1991) for the history of the
different EVAL versions. The historical failure is returned as data; this
report neither signals it nor changes the evaluator's default rule. See
ROOTS-NAMED-CALL-VERSION-HISTORY for version and witness provenance."
  (let* ((witness (roots-read-form source))
         (mccarthy-evaluation
           (roots-evaluate witness
                           :source source
                           :event-limit event-limit
                           :named-call-rule :mccarthy-paper))
         (graham-evaluation
           (roots-evaluate witness
                           :source source
                           :event-limit event-limit
                           :named-call-rule :graham-corrected))
         (replay-status
           (if (and (eq (status-of mccarthy-evaluation) :error)
                    (typep (condition-of mccarthy-evaluation)
                           'roots-language-error)
                    (eq (status-of graham-evaluation) :ok)
                    (roots-object-equal
                     (result-of graham-evaluation)
                     (roots-read-form "(a b c)")))
               :confirmed
               :diverged)))
    (make-instance
     'roots-rule-comparison
     :case :named-call-double-evaluation
     :source-locators
     '((:source :mccarthy-paper
        :work "Recursive Functions of Symbolic Expressions and Their Computation by Machine, Part I"
        :rule :named-function-application)
       (:source :graham-corrected
        :work "The Roots of Lisp"
        :rule :named-function-application)
       (:source :hyperdoc-reconstruction
        :path "hyperdoc-graham-roots-of-lisp/src/evaluator.lisp")
       (:source :hyperdoc-page
        :page "Which bugs did Graham correct?"))
     :witness witness
     :rule-before :mccarthy-paper
     :rule-after :graham-corrected
     :mccarthy-evaluation mccarthy-evaluation
     :graham-evaluation graham-evaluation
     :unlicensed-transition
     (list :argument-source (roots-read-form "'(b c)")
           :argument-value (roots-read-form "(b c)")
           :reinterpreted-as-application (roots-read-form "(b c)")
           :operator (roots-object-symbol "B")
           :status :captured-language-error)
     :replay-status replay-status)))

(defun roots-dynamic-binding-capture-report (&key (event-limit 1000))
  "Run the minimal dynamic-capture witness under the corrected default rule."
  (roots-evaluate-source
   *roots-dynamic-binding-capture-source*
   :event-limit event-limit))

(defun roots-example-report (name &key (event-limit 1000))
  "Return a named inspectable example."
  (ecase name
    (:quote
     (roots-evaluate-source "(quote (a b c))"
                            :event-limit event-limit))
    (:use-mention
     (list
      :code
      (roots-evaluate-source "(atom (atom 'a))"
                             :event-limit event-limit)
      :data
      (roots-evaluate-source "(atom '(atom 'a))"
                             :event-limit event-limit)))
    (:seven-primitives
     (roots-seven-primitive-reports :event-limit event-limit))
    (:lambda
     (roots-evaluate-source
      "((lambda (x y) (cons x (cdr y))) 'z '(a b c))"
      :event-limit event-limit))
    (:higher-order
     (roots-evaluate-source
      "((lambda (f) (f '(b c))) '(lambda (x) (cons 'a x)))"
      :event-limit event-limit))
    (:subst
     (roots-direct-subst-report :event-limit event-limit))
    (:surprise
     (roots-surprise-report :event-limit event-limit))))

(hyperdoc:defexample roots-seven-primitives-example
    (:system "hyperdoc-graham-roots-of-lisp"
     :page "The Roots of Lisp reconstruction layers"
     :title "Run the seven primitive operators"
     :tags '(:kind :example :suite "roots-of-lisp" :concept :primitives))
  "Evaluate deterministic witnesses for all seven primitive operators."
  (roots-seven-primitive-reports))

(hyperdoc:defexample roots-lambda-and-label-example
    (:system "hyperdoc-graham-roots-of-lisp"
     :page "The Surprise as an evaluation trace"
     :title "Compare LAMBDA application and LABEL recursion"
     :tags '(:kind :example :suite "roots-of-lisp" :concept :function-notation))
  "Return inspectable LAMBDA and LABEL evaluations without replacing their reusable reports."
  (list :lambda
        (roots-example-report :lambda)
        :label
        (roots-direct-subst-report)))

(hyperdoc:defexample roots-direct-subst-example
    (:system "hyperdoc-graham-roots-of-lisp"
     :page "The Surprise as an evaluation trace"
     :title "Run recursive SUBST directly"
     :tags '(:kind :example :suite "roots-of-lisp" :concept :subst))
  "Evaluate Graham's recursive SUBST definition directly through LABEL."
  (roots-direct-subst-report))

(hyperdoc:defexample roots-surprise-example
    (:system "hyperdoc-graham-roots-of-lisp"
     :page "The Surprise as an evaluation trace"
     :title "Run the Surprise through object-language EVAL."
     :tags '(:kind :example :suite "roots-of-lisp" :concept :self-interpretation))
  "Run object-language EVAL. over the recursive SUBST witness and return its evaluation."
  (roots-surprise-report))

(hyperdoc:defexample roots-named-call-double-evaluation-example
    (:system "hyperdoc-graham-roots-of-lisp"
     :page "Which bugs did Graham correct?"
     :title "Retrace the named-call double-evaluation correction"
     :tags '(:kind :example :suite "roots-of-lisp" :concept :retrace))
  "Replay McCarthy's published 1960 clause beside Graham's 2002 correction
on the closed witness derived from Graham's page-9 example. See
ROOTS-NAMED-CALL-VERSION-HISTORY for its provenance and Stoyan's comparison
of the earlier EVAL versions."
  (roots-named-call-double-evaluation-report
   :source
   "
((lambda (f)
   (f '(b c)))
 '(lambda (x)
    (cons 'a x)))
"))

(hyperdoc:defexample roots-dynamic-binding-capture-example
    (:system "hyperdoc-graham-roots-of-lisp"
     :page "Dynamic capture in MAPLIST and DIFF"
     :title "Demonstrate dynamic binding capture"
     :tags '(:kind :example :suite "roots-of-lisp" :concept :dynamic-binding))
  "Evaluate the minimal dynamic-capture witness; the historical environment returns INNER."
  (roots-dynamic-binding-capture-report))

(defun roots-reading-order ()
  "Return the human reading order for source, semantics, adapter, and trace."
  (list
   (list :step 1
         :paper-section "Seven Primitive Operators"
         :question "What counts as an expression, and which operators are axioms?"
         :code-surface "ROOTS-EVAL-ATOMIC-OPERATOR")
   (list :step 2
         :paper-section "Denoting Functions"
         :question "How do LAMBDA, LABEL, parameter binding, and recursion work?"
         :code-surface "ROOTS-EVAL-COMPOUND-OPERATOR")
   (list :step 3
         :paper-section "Some Functions"
         :question "How are NULL., AND., NOT., APPEND., PAIR., and ASSOC. built?"
         :code-surface "*ROOTS-GRAHAM-LIBRARY-SOURCE*")
   (list :step 4
         :paper-section "The Surprise"
         :question "How can EVAL. be expressed in the language it evaluates?"
         :code-surface "ROOTS-SURPRISE-REPORT")
   (list :step 5
         :paper-section "Stanford adapter"
         :question "Which parser, top-level, error, and browser facilities are extra?"
         :code-surface "ROOTS-INTERPRET-STRING")
   (list :step 6
         :paper-section "HyperDoc projection"
         :question "How do page links expose source, reports, and traces as objects?"
         :code-surface "The Roots of Lisp.html")))

(defun roots-stanford-crosswalk ()
  "Return the architectural crosswalk from the Stanford Haskell page."
  (list
   (list :concern :tree-model
         :stanford "Expr = Atom String | List [Expr]; dotted pairs omitted."
         :reconstruction
         "Common Lisp cons trees are retained, including quoted dotted pairs.")
   (list :concern :seven-primitives
         :stanford "Pattern matching implements primitive arity and shape checks."
         :reconstruction
         "Explicit checks signal ROOTS-LANGUAGE-ERROR and create trace events.")
   (list :concern :top-level
         :stanford "LABEL and DEFUN return an environment update function."
         :reconstruction
         "ROOTS-SESSION-DEFINE mutates a named session; the core evaluator stays pure.")
   (list :concern :parser
         :stanford "Charser parses atoms, proper lists, quote, whitespace, and comments."
         :reconstruction
         "The Common Lisp reader parses data with *READ-EVAL* NIL.")
   (list :concern :accessor-prelude
         :stanford "CAAR through CDDDDR are generated and preloaded."
         :reconstruction
         "ROOTS-PRELOAD-ACCESSORS generates the same abbreviations.")
   (list :concern :browser-output
         :stanford "A Run button writes strings into a textarea."
         :reconstruction
         "HyperDoc expr links return inspectable ROOTS-EVALUATION objects.")))

(defun roots-nine-ideas-crosswalk ()
  "Relate Graham's nine differences to concrete reconstruction surfaces."
  (list
   (list 1 :conditionals "COND is non-strict and emits clause-selection events.")
   (list 2 :function-type "LAMBDA and LABEL expressions are ordinary cons-tree values.")
   (list 3 :recursion "LABEL adds the function expression to its own dynamic environment.")
   (list 4 :variables "The environment stores newest-first bindings to values.")
   (list 5 :garbage-collection "The host Common Lisp image manages cons-tree lifetime.")
   (list 6 :expressions "Every object-language form returns a value or a condition.")
   (list 7 :symbols "Atoms and binding names are Common Lisp symbols.")
   (list 8 :code-as-trees "Source is read directly into the same cons trees the evaluator traverses.")
   (list 9 :whole-language-available
         "The page, reader, evaluator, definitions, and trace coexist in the running image.")))

(defun roots-reconstruction-summary ()
  "Return a compact status object for the Roots reconstruction."
  (list
   :source "Paul Graham, The Roots of Lisp"
   :semantic-core
   '(:quote :atom :eq :car :cdr :cons :cond :lambda :label)
   :paper-library
   '(:null. :and. :not. :append. :pair. :assoc. :eval. :evcon. :evlis.)
   :adapter
   '(:common-lisp-reader :defun :top-level-label :list-abbreviation
     :generated-cxr-accessors :session)
   :hyperdoc
   '(:authored-pages :topics :expr-links :inspectable-evaluation
     :inspectable-trace)
   :reading-order (roots-reading-order)))
