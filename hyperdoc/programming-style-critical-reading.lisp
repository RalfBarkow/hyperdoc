;;;; Kernighan/Plauger critical reading, rewriting, and style-rule extraction.

(in-package :hyperdoc)

(defclass program-code-fragment ()
  ((id :initarg :id :reader program-code-fragment-id-of)
   (title :initarg :title :reader program-code-fragment-title-of)
   (language :initarg :language :reader program-code-fragment-language-of)
   (text :initarg :text :reader program-code-fragment-text-of)
   (idea :initarg :idea :reader program-code-fragment-idea-of)))

(defclass reader-difficulty ()
  ((id :initarg :id :reader reader-difficulty-id-of)
   (summary :initarg :summary :reader reader-difficulty-summary-of)
   (questions :initarg :questions :reader reader-difficulty-questions-of)))

(defclass program-shortcoming ()
  ((id :initarg :id :reader program-shortcoming-id-of)
   (kind :initarg :kind :reader program-shortcoming-kind-of)
   (summary :initarg :summary :reader program-shortcoming-summary-of)
   (reader-effect :initarg :reader-effect
                  :reader program-shortcoming-reader-effect-of)))

(defclass program-rewrite ()
  ((id :initarg :id :reader program-rewrite-id-of)
   (title :initarg :title :reader program-rewrite-title-of)
   (language :initarg :language :reader program-rewrite-language-of)
   (text :initarg :text :reader program-rewrite-text-of)
   (intent :initarg :intent :reader program-rewrite-intent-of)))

(defclass before-after-comparison ()
  ((id :initarg :id :reader before-after-comparison-id-of)
   (before :initarg :before :reader before-after-comparison-before-of)
   (after :initarg :after :reader before-after-comparison-after-of)
   (reader-gain :initarg :reader-gain
                :reader before-after-comparison-reader-gain-of)))

(defclass programming-style-rule ()
  ((id :initarg :id :reader programming-style-rule-id-of)
   (title :initarg :title :reader programming-style-rule-title-of)
   (statement :initarg :statement :reader programming-style-rule-statement-of)
   (rationale :initarg :rationale :reader programming-style-rule-rationale-of)
   (transfer :initarg :transfer :reader programming-style-rule-transfer-of)))

(defclass critical-reading-example ()
  ((id :initarg :id :reader critical-reading-example-id-of)
   (title :initarg :title :reader critical-reading-example-title-of)
   (source-lineage :initarg :source-lineage
                   :reader critical-reading-example-source-lineage-of)
   (original-fragment :initarg :original-fragment
                      :reader critical-reading-example-original-fragment-of)
   (reader-difficulty :initarg :reader-difficulty
                      :reader critical-reading-example-reader-difficulty-of)
   (shortcomings :initarg :shortcomings
                 :reader critical-reading-example-shortcomings-of)
   (rewrite :initarg :rewrite :reader critical-reading-example-rewrite-of)
   (comparison :initarg :comparison
               :reader critical-reading-example-comparison-of)
   (style-rule :initarg :style-rule
               :reader critical-reading-example-style-rule-of)
   (goldberg-question :initarg :goldberg-question
                      :reader critical-reading-example-goldberg-question-of)
   (knuth-web-projection :initarg :knuth-web-projection
                         :reader critical-reading-example-knuth-web-projection-of)))

(defmethod print-object ((object critical-reading-example) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (critical-reading-example-id-of object))))

(defmethod id-of ((object critical-reading-example))
  (critical-reading-example-id-of object))

(defmethod title-of ((object critical-reading-example))
  (critical-reading-example-title-of object))

(defmethod summary-of ((object critical-reading-example))
  (reader-difficulty-summary-of
   (critical-reading-example-reader-difficulty-of object)))

(defmethod title-of ((object program-code-fragment))
  (program-code-fragment-title-of object))

(defmethod summary-of ((object program-code-fragment))
  (program-code-fragment-idea-of object))

(defmethod title-of ((object program-rewrite))
  (program-rewrite-title-of object))

(defmethod summary-of ((object program-rewrite))
  (program-rewrite-intent-of object))

(defmethod title-of ((object programming-style-rule))
  (programming-style-rule-title-of object))

(defmethod summary-of ((object programming-style-rule))
  (programming-style-rule-statement-of object))

(defparameter *critical-reading-selected-plan*
  '((establish-programming-style-readability-problem)
    (select-real-program-example)
    (read-program-critically)
    (identify-obscure-expressions)
    (identify-confusing-control-flow)
    (identify-poor-data-representation)
    (identify-missing-validity-boundary-checks)
    (rewrite-program-for-clarity)
    (compare-original-and-rewrite)
    (derive-style-rule-from-rewrite)
    (record-critical-reading-lesson)
    (connect-base-plan-to-goldberg-reader-questions)
    (connect-base-plan-to-knuth-web-projections)
    (validate-critical-reading-plan-artifact)))

(defparameter *critical-reading-base-cycle*
  '(:critical-reading
    :identify-shortcomings
    :rewrite
    :compare-before-after
    :derive-style-rule
    :record-reusable-style-lesson))

(defun make-program-code-fragment (&key id title language text idea)
  (make-instance 'program-code-fragment
                 :id id
                 :title title
                 :language language
                 :text text
                 :idea idea))

(defun make-reader-difficulty (&key id summary questions)
  (make-instance 'reader-difficulty
                 :id id
                 :summary summary
                 :questions questions))

(defun make-program-shortcoming (&key id kind summary reader-effect)
  (make-instance 'program-shortcoming
                 :id id
                 :kind kind
                 :summary summary
                 :reader-effect reader-effect))

(defun make-program-rewrite (&key id title language text intent)
  (make-instance 'program-rewrite
                 :id id
                 :title title
                 :language language
                 :text text
                 :intent intent))

(defun make-before-after-comparison (&key id before after reader-gain)
  (make-instance 'before-after-comparison
                 :id id
                 :before before
                 :after after
                 :reader-gain reader-gain))

(defun make-programming-style-rule (&key id title statement rationale transfer)
  (make-instance 'programming-style-rule
                 :id id
                 :title title
                 :statement statement
                 :rationale rationale
                 :transfer transfer))

(defun make-critical-reading-example
    (&key id title source-lineage original-fragment reader-difficulty
          shortcomings rewrite comparison style-rule goldberg-question
          knuth-web-projection)
  "Create a complete critical-reading example object.

The object preserves the Kernighan/Plauger cycle as inspectable data:
original fragment, reader difficulty, named shortcomings, rewrite, comparison,
style rule, and crosswalks to Goldberg and Knuth."
  (make-instance 'critical-reading-example
                 :id id
                 :title title
                 :source-lineage source-lineage
                 :original-fragment original-fragment
                 :reader-difficulty reader-difficulty
                 :shortcomings shortcomings
                 :rewrite rewrite
                 :comparison comparison
                 :style-rule style-rule
                 :goldberg-question goldberg-question
                 :knuth-web-projection knuth-web-projection))

(defun %identity-matrix-critical-reading-example ()
  (let* ((original
           (make-program-code-fragment
            :id "identity-matrix-clever-integer-division"
            :title "Identity matrix integer-division expression"
            :language :pseudocode
            :text
            "matrix[row,column] := compact_integer_division_expression(row,column)"
            :idea
            "The original idea is a clever integer-division expression that produces the identity-matrix values without directly saying so."))
         (difficulty
           (make-reader-difficulty
            :id "reader-reconstructs-identity-intent"
            :summary
            "The reader must reconstruct identity-matrix intent from a clever arithmetic encoding before judging whether the code is correct."
            :questions
            '("What value is intended on the diagonal?"
              "What value is intended away from the diagonal?"
              "Why is integer division being used here?")))
         (shortcomings
           (list
            (make-program-shortcoming
             :id "obscure-integer-division-expression"
             :kind :obscure-expression
             :summary
             "The expression hides an identity-matrix rule inside arithmetic cleverness."
             :reader-effect
             "Readers spend effort decoding the trick instead of checking the matrix invariant.")
            (make-program-shortcoming
             :id "poor-data-representation-of-matrix-intent"
             :kind :poor-data-representation
             :summary
             "The data representation does not name diagonal versus off-diagonal intent."
             :reader-effect
             "Maintenance changes risk preserving the trick while losing the intended matrix meaning.")
            (make-program-shortcoming
             :id "implicit-validity-boundary"
             :kind :missing-validity-boundary-check
             :summary
             "The valid index boundary is not made part of the readable contract."
             :reader-effect
             "A maintainer cannot see where row and column bounds are guaranteed.")))
         (rewrite
           (make-program-rewrite
            :id "explicit-identity-matrix-rewrite"
            :title "Explicit identity-matrix rewrite"
            :language :pseudocode
            :text
            "matrix[row,column] := if row = column then 1 else 0"
            :intent
            "The rewrite states the identity-matrix rule directly: diagonal entries are one, other entries are zero."))
         (comparison
           (make-before-after-comparison
            :id "identity-matrix-before-after"
            :before
            "Before: correctness depends on the reader reverse-engineering a compact integer-division trick."
            :after
            "After: correctness can be checked against the visible identity-matrix predicate."
            :reader-gain
            "The rewrite moves effort from decoding expression mechanics to criticizing the stated invariant."))
         (rule
           (make-programming-style-rule
            :id "write-clearly-do-not-be-too-clever"
            :title "Write clearly; do not be too clever"
            :statement
            "Prefer a direct statement of program intent over a clever expression that makes readers reconstruct the intent."
            :rationale
            "A readable program supports criticism, rewriting, and maintenance after it has already passed execution tests."
            :transfer
            "When a compact expression is interesting mainly because it is clever, rewrite it so the domain rule is visible.")))
    (make-critical-reading-example
     :id "identity-matrix"
     :title "Identity matrix critical reading example"
     :source-lineage
     '(:kernighan-plauger-1974 :goldberg-1987 :knuth-1986)
     :original-fragment original
     :reader-difficulty difficulty
     :shortcomings shortcomings
     :rewrite rewrite
     :comparison comparison
     :style-rule rule
     :goldberg-question
     '(:what-is-that
       :where-is-it
       :what-is-needed
       :current-state
       :exploratory-environment-restatement)
     :knuth-web-projection
     '(:reader-order
       :machine-order-projection
       :projection-response-not-base-method))))

(defparameter *critical-reading-examples*
  (list (%identity-matrix-critical-reading-example)))

(defun critical-reading-examples ()
  "Return the built-in critical-reading examples."
  (copy-list *critical-reading-examples*))

(defun %normalize-critical-reading-designator (designator)
  (etypecase designator
    (critical-reading-example designator)
    (null "identity-matrix")
    (keyword (string-downcase (symbol-name designator)))
    (symbol (string-downcase (symbol-name designator)))
    (string (string-downcase designator))))

(defun %critical-reading-example (designator)
  (if (typep designator 'critical-reading-example)
      designator
      (let ((id (%normalize-critical-reading-designator designator)))
        (or (find id *critical-reading-examples*
                  :key #'critical-reading-example-id-of
                  :test #'string=)
            (find id *critical-reading-examples*
                  :key #'critical-reading-example-title-of
                  :test #'string-equal)
            (error "Unknown critical-reading example ~S." designator)))))

(defun %fragment-plist (fragment)
  (list :id (program-code-fragment-id-of fragment)
        :title (program-code-fragment-title-of fragment)
        :language (program-code-fragment-language-of fragment)
        :text (program-code-fragment-text-of fragment)
        :idea (program-code-fragment-idea-of fragment)))

(defun %difficulty-plist (difficulty)
  (list :id (reader-difficulty-id-of difficulty)
        :summary (reader-difficulty-summary-of difficulty)
        :questions (copy-list (reader-difficulty-questions-of difficulty))))

(defun %shortcoming-plist (shortcoming)
  (list :id (program-shortcoming-id-of shortcoming)
        :kind (program-shortcoming-kind-of shortcoming)
        :summary (program-shortcoming-summary-of shortcoming)
        :reader-effect (program-shortcoming-reader-effect-of shortcoming)))

(defun %rewrite-plist (rewrite)
  (list :id (program-rewrite-id-of rewrite)
        :title (program-rewrite-title-of rewrite)
        :language (program-rewrite-language-of rewrite)
        :text (program-rewrite-text-of rewrite)
        :intent (program-rewrite-intent-of rewrite)))

(defun %comparison-plist (comparison)
  (list :id (before-after-comparison-id-of comparison)
        :before (before-after-comparison-before-of comparison)
        :after (before-after-comparison-after-of comparison)
        :reader-gain (before-after-comparison-reader-gain-of comparison)))

(defun %style-rule-plist (rule)
  (list :id (programming-style-rule-id-of rule)
        :title (programming-style-rule-title-of rule)
        :statement (programming-style-rule-statement-of rule)
        :rationale (programming-style-rule-rationale-of rule)
        :transfer (programming-style-rule-transfer-of rule)))

(defun critical-reading-plan ()
  "Return the selected ordered plan from the committed plan artifact."
  (list :id :kernighan-plauger-critical-reading-style
        :problem
        "A program can run and still fail as material for human reading, criticism, rewriting, maintenance, and style-rule extraction."
        :source-lineage '(:kernighan-plauger-1974 :goldberg-1987 :knuth-1986)
        :base-cycle (copy-list *critical-reading-base-cycle*)
        :selected-ordered-plan (copy-tree *critical-reading-selected-plan*)
        :plan-artifact
        "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp"))

(defun criticize-program-fragment (&optional (example-designator "identity-matrix"))
  "Return the critical reading result for EXAMPLE-DESIGNATOR."
  (let ((example (%critical-reading-example example-designator)))
    (list :operation :read-program-critically
          :original-fragment
          (%fragment-plist
           (critical-reading-example-original-fragment-of example))
          :reader-difficulty
          (%difficulty-plist
           (critical-reading-example-reader-difficulty-of example))
          :identified-shortcomings
          (mapcar #'%shortcoming-plist
                  (critical-reading-example-shortcomings-of example)))))

(defun rewrite-program-fragment (&optional (example-designator "identity-matrix"))
  "Return the rewrite operation for EXAMPLE-DESIGNATOR."
  (let ((example (%critical-reading-example example-designator)))
    (list :operation :rewrite-program-for-clarity
          :original-fragment
          (%fragment-plist
           (critical-reading-example-original-fragment-of example))
          :rewrite
          (%rewrite-plist
           (critical-reading-example-rewrite-of example)))))

(defun derive-style-rule (&optional (example-designator "identity-matrix"))
  "Return the style rule derived from EXAMPLE-DESIGNATOR's rewrite."
  (%style-rule-plist
   (critical-reading-example-style-rule-of
    (%critical-reading-example example-designator))))

(defun critical-reading-report (&optional (example-designator "identity-matrix"))
  "Return the full Kernighan/Plauger critical-reading report."
  (let ((example (%critical-reading-example example-designator)))
    (list :example-id (critical-reading-example-id-of example)
          :title (critical-reading-example-title-of example)
          :source-lineage
          (copy-list (critical-reading-example-source-lineage-of example))
          :original
          (%fragment-plist
           (critical-reading-example-original-fragment-of example))
          :readability-problem
          (%difficulty-plist
           (critical-reading-example-reader-difficulty-of example))
          :shortcomings
          (mapcar #'%shortcoming-plist
                  (critical-reading-example-shortcomings-of example))
          :rewrite
          (%rewrite-plist
           (critical-reading-example-rewrite-of example))
          :comparison
          (%comparison-plist
           (critical-reading-example-comparison-of example))
          :rule
          (%style-rule-plist
           (critical-reading-example-style-rule-of example))
          :goldberg-crosswalk
          (goldberg-long-recognized-problem-crosswalk example)
          :knuth-crosswalk
          (knuth-web-projection-crosswalk example))))

(defun goldberg-long-recognized-problem-crosswalk
    (&optional (example-designator "identity-matrix"))
  "Connect the base critical-reading cycle to Goldberg's restatement."
  (let ((example (%critical-reading-example example-designator)))
    (list :lineage :goldberg-1987
          :base-problem
          "Kernighan/Plauger start from the long-recognized problem that executable code can still be hard to read."
          :exploratory-environment-restatement
          "Goldberg restates the same reader problem for exploratory programming environments: the system must answer reading questions, not only accept program text."
          :reader-questions
          (copy-list (critical-reading-example-goldberg-question-of example))
          :connection
          "Critical reading supplies the local training cycle; Goldberg asks the environment to support comparable reading operations across code, state, history, and structure.")))

(defun knuth-web-projection-crosswalk
    (&optional (example-designator "identity-matrix"))
  "Connect the base critical-reading cycle to Knuth's WEB projection response."
  (let ((example (%critical-reading-example example-designator)))
    (list :lineage :knuth-1986
          :reader-order
          "WEB arranges program material in the order a reader should encounter motivation, vocabulary, mechanism, and evidence."
          :machine-order-projection
          "Tangling preserves the machine-order projection so the reader-oriented source remains a program."
          :boundary
          "WEB is a projection response to the readability problem, not the same thing as the Kernighan/Plauger style-training cycle."
          :example-projection
          (copy-list (critical-reading-example-knuth-web-projection-of
                      example)))))

(defun %critical-reading-exported-function-names ()
  '(kernighan-plauger-critical-reading-summary
    make-critical-reading-example
    critical-reading-examples
    critical-reading-plan
    criticize-program-fragment
    rewrite-program-fragment
    derive-style-rule
    critical-reading-report
    programming-style-coverage-report
    goldberg-long-recognized-problem-crosswalk
    knuth-web-projection-crosswalk
    inspect-kernighan-plauger-critical-reading))

(defun %plan-artifact-single-form-p ()
  (let ((path (asdf:system-relative-pathname
               :hyperdoc
               "hyperdoc/kernighan-plauger-critical-reading-style-plan.sexp")))
    (with-open-file (stream path)
      (read stream)
      (eq (read stream nil :eof) :eof))))

(defun programming-style-coverage-report ()
  "Report implementation coverage for the critical-reading slice."
  (list :exports
        (mapcar (lambda (name)
                  (let ((symbol (find-symbol (symbol-name name) :hyperdoc)))
                    (list :symbol name
                          :present (and symbol (fboundp symbol)))))
                (%critical-reading-exported-function-names))
        :examples
        (mapcar #'critical-reading-example-id-of *critical-reading-examples*)
        :pages
        '("hyperdoc/Kernighan Plauger critical reading plan.html"
          "hyperdoc/Programming style readability problem.html"
          "hyperdoc/Critical reading to rewriting.html"
          "hyperdoc/Goldberg long recognized problem crosswalk.html"
          "hyperdoc/Knuth WEB as projection response.html")
        :topics
        '(programming-style-readability-problem-topic
          kernighan-plauger-critical-reading-topic
          critical-reading-rewriting-style-rule-topic
          goldberg-long-recognized-problem-crosswalk-topic
          knuth-web-projection-response-topic)
        :plan-artifact-single-form
        (%plan-artifact-single-form-p)))

(defun kernighan-plauger-critical-reading-summary ()
  "Return a compact summary of the critical-reading base plan."
  (list :title "Kernighan/Plauger critical reading to rewriting"
        :problem
        "Program execution is not the same as program readability."
        :base-cycle (copy-list *critical-reading-base-cycle*)
        :example-count (length *critical-reading-examples*)
        :entry-report "(hyperdoc:critical-reading-report)"
        :goldberg-crosswalk
        "(hyperdoc:goldberg-long-recognized-problem-crosswalk)"
        :knuth-crosswalk
        "(hyperdoc:knuth-web-projection-crosswalk)"))

(defun inspect-kernighan-plauger-critical-reading ()
  "Return the primary inspection bundle for the critical-reading slice."
  (list :summary (kernighan-plauger-critical-reading-summary)
        :plan (critical-reading-plan)
        :examples (critical-reading-examples)
        :identity-matrix-report (critical-reading-report "identity-matrix")
        :coverage (programming-style-coverage-report)))
