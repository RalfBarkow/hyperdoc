;;;; Focused tests for the authored Wiki-link lookup contract demonstration

(eval-when (:compile-toplevel :load-toplevel :execute)
  (asdf:load-asd
   (merge-pathnames "dreyeck.asd"
                    (asdf:system-source-directory :hyperbook)))
  (asdf:load-system :dreyeck/wiki-link-contract-demo))

(defpackage :hyperbook/fedwiki/tests
  (:use :cl)
  (:export :run-wiki-link-slug-contract-test
           :run-wiki-link-slug-contract-tests))

(in-package :hyperbook/fedwiki/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun observation-route (observation)
  (dreyeck/wiki-link-contract-demo:wiki-link-lookup-observation-route
   observation))

(defun observation-value (observation)
  (dreyeck/wiki-link-contract-demo:wiki-link-lookup-observation-lookup-value
   observation))

(defun observation-outcome (observation)
  (dreyeck/wiki-link-contract-demo:wiki-link-lookup-observation-outcome
   observation))

(defun evidence-shape (observation)
  (dreyeck/wiki-link-contract-demo:wiki-link-lookup-evidence-shape
   observation))

(defun route-evidence-relation (observation)
  (dreyeck/wiki-link-contract-demo:wiki-link-route-evidence-relation
   observation))

(defun condition-slot-value (condition slot)
  (when (slot-boundp condition slot)
    (slot-value condition slot)))

(defun run-observation-model-test ()
  (let ((slot-names
          (mapcar
           (lambda (slot)
             (intern (symbol-name (closer-mop:slot-definition-name slot))
                     :keyword))
           (closer-mop:class-slots
            (find-class
             'dreyeck/wiki-link-contract-demo:wiki-link-lookup-observation)))))
    (check (equal '(:route :lookup-value :outcome) slot-names)
           "Observation slots are ~S instead of ROUTE, LOOKUP-VALUE, OUTCOME."
           slot-names))
  t)

(defun run-successful-lookup-observation-test ()
  (let* ((observations
           (dreyeck/wiki-link-contract-demo::wiki-link-successful-lookup-equivalence-example))
         (title-observation (first observations))
         (slug-observation (second observations)))
    (check (= 2 (length observations))
           "The successful example returned ~D observations instead of two."
           (length observations))
    (check (eq :title (observation-route title-observation))
           "The title observation declares route ~S."
           (observation-route title-observation))
    (check (equal "Existing Human Title"
                  (observation-value title-observation))
           "The title observation lost its exact lookup value.")
    (check (dreyeck/wiki-link-contract-demo:wiki-link-lookup-resolved-p
            title-observation)
           "FIND-TARGET-BY-TITLE did not resolve the existing page.")
    (check (typep (observation-outcome title-observation)
                  'hyperbook/fedwiki::fedwiki-page)
           "Title lookup returned ~S instead of a FEDWIKI-PAGE."
           (observation-outcome title-observation))
    (check (eq :slug (observation-route slug-observation))
           "The slug observation declares route ~S."
           (observation-route slug-observation))
    (check (equal "existing-human-title"
                  (observation-value slug-observation))
           "The slug observation lost its exact lookup value.")
    (check (dreyeck/wiki-link-contract-demo:wiki-link-lookup-resolved-p
            slug-observation)
           "FIND-TARGET-BY-SLUG did not resolve the existing page.")
    (check (typep (observation-outcome slug-observation)
                  'hyperbook/fedwiki::fedwiki-page)
           "Slug lookup returned ~S instead of a FEDWIKI-PAGE."
           (observation-outcome slug-observation))
    (check (dreyeck/wiki-link-contract-demo:same-resolved-target-p
            title-observation slug-observation)
           "Title and slug lookup did not return the same page object by EQ.")
    (check (eq (observation-outcome title-observation)
               (observation-outcome slug-observation))
           "The successful observations do not retain the same page object.")
    (check (eq :not-applicable (evidence-shape title-observation))
           "A resolved observation has evidence shape ~S."
           (evidence-shape title-observation))
    (check (eq :not-applicable
               (route-evidence-relation slug-observation))
           "A resolved observation has route/evidence relation ~S."
           (route-evidence-relation slug-observation)))
  t)

(defun run-failure-evidence-observation-test ()
  (let* ((title-observation
           (dreyeck/wiki-link-contract-demo::wiki-link-upstream-title-path-example))
         (slug-observation
           (dreyeck/wiki-link-contract-demo::wiki-link-strict-slug-path-example))
         (title-condition (observation-outcome title-observation))
         (slug-condition (observation-outcome slug-observation))
         (slug-slot 'hyperbook/fedwiki::slug)
         (title-slot 'hyperbook/fedwiki::title))
    (check (typep title-condition
                  'hyperbook/fedwiki::wiki-lookup-failure)
           "Title-with-slug outcome is ~S instead of WIKI-LOOKUP-FAILURE."
           title-condition)
    (check (slot-boundp title-condition title-slot)
           "Historic title-with-slug failure did not bind TITLE evidence.")
    (check (equal (observation-value title-observation)
                  (condition-slot-value title-condition title-slot))
           "Historic title evidence does not match the supplied slug.")
    (check (equal (observation-value title-observation)
                  (condition-slot-value title-condition slug-slot))
           "Historic failure did not preserve the expected slug evidence.")
    (check (eq :title-and-slug-evidence
               (evidence-shape title-observation))
           "Historic failure derived evidence shape ~S."
           (evidence-shape title-observation))
    (check (eq :consistent (route-evidence-relation title-observation))
           "Historic title route has relation ~S."
           (route-evidence-relation title-observation))
    (check (typep slug-condition
                  'hyperbook/fedwiki::wiki-lookup-failure)
           "Direct slug outcome is ~S instead of WIKI-LOOKUP-FAILURE."
           slug-condition)
    (check (not (slot-boundp slug-condition title-slot))
           "Direct slug failure unexpectedly bound TITLE evidence.")
    (check (equal (observation-value slug-observation)
                  (condition-slot-value slug-condition slug-slot))
           "Direct failure did not preserve the expected slug evidence.")
    (check (eq :slug-only-evidence (evidence-shape slug-observation))
           "Direct slug failure derived evidence shape ~S."
           (evidence-shape slug-observation))
    (check (eq :consistent (route-evidence-relation slug-observation))
           "Direct slug route has relation ~S."
           (route-evidence-relation slug-observation))
    (let ((title-route-with-slug-evidence
            (dreyeck/wiki-link-contract-demo::%make-wiki-link-lookup-observation
             :title
             (observation-value slug-observation)
             slug-condition)))
      (check (eq :slug-only-evidence
                 (evidence-shape title-route-with-slug-evidence))
             "Changing the declared route changed the raw evidence shape.")
      (check (eq :inconsistent
                 (route-evidence-relation title-route-with-slug-evidence))
             "A title route with slug-only evidence was not inconsistent.")))
  t)

;; The condition in this test is intentionally synthetic. It exercises
;; classifier totality and route/evidence separation; it is not a reproduction
;; of an existing FIND-TARGET-BY-SLUG production path.
(defun run-synthetic-route-evidence-separation-test ()
  (let* ((lookup-value "some-slug")
         (condition
           (make-condition 'hyperbook/fedwiki::wiki-lookup-failure
                           :slug lookup-value
                           :title lookup-value))
         (observation
           (dreyeck/wiki-link-contract-demo::%make-wiki-link-lookup-observation
            :slug lookup-value condition)))
    (check (eq :title-and-slug-evidence (evidence-shape observation))
           "The synthetic bound-title condition derived shape ~S."
           (evidence-shape observation))
    (check (eq :inconsistent (route-evidence-relation observation))
           "A slug route with bound title evidence has relation ~S."
           (route-evidence-relation observation)))
  t)

(defun run-installed-thunk-observation-test ()
  (let* ((observation
           (dreyeck/wiki-link-contract-demo::wiki-link-installed-thunk-example))
         (shape (evidence-shape observation))
         (outcome (observation-outcome observation)))
    (check (eq :installed (observation-route observation))
           "The installed thunk observation declares route ~S."
           (observation-route observation))
    (check (equal "missing-human-title" (observation-value observation))
           "The installed thunk did not retain its captured target slug.")
    (check (typep outcome 'hyperbook/fedwiki::wiki-lookup-failure)
           "The installed missing-target thunk returned ~S."
           outcome)
    (check (eq :slug-only-evidence shape)
           "The installed thunk's actual outcome derived shape ~S."
           shape)
    (check (eq :matches-slug-path
               (dreyeck/wiki-link-contract-demo:installed-lookup-pattern
                observation))
           "The installed thunk pattern was not derived from its outcome.")
    (check (eq :not-declared (route-evidence-relation observation))
           "The installed route declared an evidence relation ~S."
           (route-evidence-relation observation)))
  t)

(defun run-unexpected-thunk-condition-test ()
  (let ((unexpected
          (make-condition 'simple-error
                          :format-control "Unexpected thunk failure")))
    (handler-case
        (progn
          ;; MAKE-WIKI-LINK thunks return caught ERROR conditions as values.
          ;; The execution-and-recording helper must re-signal the identical one.
          (dreyeck/wiki-link-contract-demo::%execute-and-record-wiki-lookup
           :installed "missing-human-title" (lambda () unexpected))
          (error "The unrelated returned thunk condition did not escape."))
      (simple-error (caught)
        (check (eq unexpected caught)
               "The escaping thunk condition was translated from ~S to ~S."
               unexpected caught))))
  t)

(defun run-invalid-normal-return-tests ()
  (dolist (invalid-value (list nil :not-a-page))
    (let ((rejected-p nil))
      (handler-case
          (dreyeck/wiki-link-contract-demo::%execute-and-record-wiki-lookup
           :slug "missing-human-title" (lambda () invalid-value))
        (hyperbook/fedwiki::wiki-lookup-failure ()
          (error "Invalid normal return ~S became lookup evidence."
                 invalid-value))
        (error ()
          (setf rejected-p t)))
      (check rejected-p
             "Invalid normal return ~S was accepted as an observation."
             invalid-value)))
  t)

(defun run-global-plugin-page-restoration-tests ()
  (let* ((name 'hyperbook/fedwiki::get-plugin-page)
         (original (symbol-function name)))
    (check (eq :normal
               (dreyeck/wiki-link-contract-demo::%call-with-global-plugin-page-lookup-disabled
                (lambda () :normal)))
           "The global suppression helper changed a normal return.")
    (check (eq original (symbol-function name))
           "GET-PLUGIN-PAGE was not restored after normal return.")
    (let ((failure
            (make-condition 'hyperbook/fedwiki::wiki-lookup-failure
                            :slug "missing-human-title"))
          (caught-p nil))
      (handler-case
          (dreyeck/wiki-link-contract-demo::%call-with-global-plugin-page-lookup-disabled
           (lambda () (error failure)))
        (hyperbook/fedwiki::wiki-lookup-failure (caught)
          (setf caught-p t)
          (check (eq failure caught)
                 "The WIKI-LOOKUP-FAILURE changed during exceptional exit.")))
      (check caught-p "The restoration test did not observe WIKI-LOOKUP-FAILURE.")
      (check (eq original (symbol-function name))
             "GET-PLUGIN-PAGE was not restored after WIKI-LOOKUP-FAILURE."))
    (let ((unexpected
            (make-condition 'simple-error
                            :format-control "Unexpected restoration exit"))
          (caught-p nil))
      (handler-case
          (dreyeck/wiki-link-contract-demo::%call-with-global-plugin-page-lookup-disabled
           (lambda () (error unexpected)))
        (simple-error (caught)
          (setf caught-p t)
          (check (eq unexpected caught)
                 "The unrelated exceptional exit changed condition object.")))
      (check caught-p "The restoration test did not observe the unrelated error.")
      (check (eq original (symbol-function name))
             "GET-PLUGIN-PAGE was not restored after unrelated condition.")))
  t)

(defun substrings-between (string opening closing)
  (loop with position = 0
        for open = (search opening string :start2 position)
        while open
        for content-start = (+ open (length opening))
        for close = (search closing string :start2 content-start)
        do (check close "Unclosed ~A tag in the demonstration HTML." opening)
        collect (subseq string content-start close)
        do (setf position (+ close (length closing)))))

(defun run-html-executable-reference-test ()
  (let* ((page-path
           (asdf:system-relative-pathname
            :dreyeck/wiki-link-contract-demo
            "dreyeck/pages/Wiki-link title and slug lookup contracts.html"))
         (html (uiop:read-file-string page-path))
         (dom (plump:parse page-path))
         (function-names
           (substrings-between html
                               "<source-of-function>"
                               "</source-of-function>")))
    (dolist (forbidden-phrase
              '("executable observation" "executable observations"))
      (check (null (search forbidden-phrase html :test #'char-equal))
             "The HTML still contains the terminology regression ~S."
             forbidden-phrase))
    (check (= 4 (length function-names))
           "The HTML contains ~D executable example references instead of four."
           (length function-names))
    (let ((*package* (find-package :dreyeck/wiki-link-contract-demo)))
      (dolist (text function-names)
        (multiple-value-bind (name end)
            (read-from-string (string-trim '(#\Space #\Tab #\Newline) text))
          (declare (ignore end))
          (check (and (symbolp name) (fboundp name))
                 "HTML executable reference ~S does not resolve."
                 text)))
      (let ((expression-count 0))
        (dolist (element (plump:get-elements-by-tag-name dom "a"))
          (let ((expression (plump:attribute element "expr")))
            (when expression
              (incf expression-count)
              (check (eval (read-from-string expression))
                     "HTML expression reference ~S did not resolve."
                     expression))))
        (check (= 2 expression-count)
               "The HTML contains ~D expression references instead of two."
               expression-count))))
  t)

(defun run-all-four-examples-test ()
  (let* ((first-success
           (dreyeck/wiki-link-contract-demo::wiki-link-successful-lookup-equivalence-example))
         (second-success
           (dreyeck/wiki-link-contract-demo::wiki-link-successful-lookup-equivalence-example))
         (title-failure
           (dreyeck/wiki-link-contract-demo::wiki-link-upstream-title-path-example))
         (slug-failure
           (dreyeck/wiki-link-contract-demo::wiki-link-strict-slug-path-example))
         (installed
           (dreyeck/wiki-link-contract-demo::wiki-link-installed-thunk-example)))
    (check (not (eq (observation-outcome (first first-success))
                    (observation-outcome (first second-success))))
           "Repeated successful examples shared a mutable page fixture.")
    (check (typep (observation-outcome title-failure)
                  'hyperbook/fedwiki::wiki-lookup-failure)
           "The historic title-path example is not executable.")
    (check (typep (observation-outcome slug-failure)
                  'hyperbook/fedwiki::wiki-lookup-failure)
           "The direct slug-path example is not executable.")
    (check (member
            (dreyeck/wiki-link-contract-demo:installed-lookup-pattern installed)
            '(:matches-title-path :matches-slug-path :other :resolved))
           "The installed example did not yield a valid observation."))
  t)

(defun run-wiki-link-slug-contract-test ()
  (run-installed-thunk-observation-test)
  (format t "Wiki-link installed thunk contract test passed.~%")
  t)

(defun run-wiki-link-slug-contract-tests ()
  (check (asdf:find-system :dreyeck/wiki-link-contract-demo nil)
         "The demo ASDF system did not load.")
  (run-observation-model-test)
  (run-successful-lookup-observation-test)
  (run-failure-evidence-observation-test)
  (run-synthetic-route-evidence-separation-test)
  (run-installed-thunk-observation-test)
  (run-unexpected-thunk-condition-test)
  (run-invalid-normal-return-tests)
  (run-global-plugin-page-restoration-tests)
  (run-html-executable-reference-test)
  (run-all-four-examples-test)
  (format t "All Wiki-link contract demonstration tests passed.~%")
  t)
