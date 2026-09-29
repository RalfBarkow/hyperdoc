;;;; A DEFEXAMPLE read back from its code page, judged by the real Critic.

(defpackage #:dreyeck/lisp-critic/examples/tests
  (:use #:cl)
  (:local-nicknames (#:ex #:dreyeck/lisp-critic/examples)
                    (#:critic #:dreyeck/lisp-critic)
                    (#:er #:dreyeck/evaluation-record)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:wf #:dreyeck/workflow)
                    (#:views #:html-inspector-views))
  (:export #:run-tests))

(in-package #:dreyeck/lisp-critic/examples/tests)

(defun %work-code-page ()
  "The code page of Working on HyperDoc that declares WORK-LAYOUT-EXAMPLE."
  (let ((book (hyperbook:find-hyperbook "dreyeck/work/reading" :signal-error? t)))
    (or (find "reading.lisp" (coerce (hyperdoc::code-pages-of book) 'list)
              :key (lambda (page) (file-namestring (hyperdoc::source-code-pathname page)))
              :test #'string=)
        (error "Working on HyperDoc has no code page reading.lisp."))))

(defun %example (page name)
  (or (find name (r:page-example-occurrences page)
            :key (lambda (occurrence) (symbol-name (second (r:occurrence-form-key occurrence))))
            :test #'string=)
      (error "~A declares no example ~A." page name)))

(defun %subform-p (part form)
  (or (equal part form)
      (and (consp form) (or (%subform-p part (car form)) (%subform-p part (cdr form))))))

(defun %refused-p (thunk &optional (type 'error))
  (handler-case (progn (funcall thunk) nil)
    (error (condition) (typep condition type))))

(defun check-example-occurrences ()
  "Reading a code page finds each DEFEXAMPLE on it as a source occurrence.
The definitions Insert executable DEFEXAMPLE is offered on stay definitions."
  (let* ((page (%work-code-page))
         (examples (r:page-example-occurrences page))
         (declared (remove :example (wf:source-forms (uiop:read-file-string
                                                      (hyperdoc::source-code-pathname page)))
                           :key (lambda (form) (first (wf:form-key form))) :test-not #'eq))
         (definitions (r:page-occurrences page)))
    (assert examples)
    (assert (equal (mapcar (lambda (form) (wf:form-key form)) declared)
                   (mapcar #'r:occurrence-form-key examples)))
    (dolist (occurrence examples)
      (assert (eq :current (r:occurrence-status occurrence)))
      (assert (equal (r:occurrence-form-key occurrence)
                     (wf:form-key (html-inspector-views/standard:s-exp (r:resolve-occurrence occurrence))))))
    (assert definitions)
    (assert (every (lambda (occurrence) (eq :definition (first (r:occurrence-form-key occurrence))))
                   definitions))
    examples))

(defun check-example-target-refusals ()
  "A target is made only from a current DEFEXAMPLE occurrence."
  (let* ((page (%work-code-page))
         (example (%example page "WORK-LAYOUT-EXAMPLE"))
         (stale (make-instance 'r:source-occurrence
                               :page page :form-key (r:occurrence-form-key example)
                               :source (concatenate 'string (r:occurrence-source example) " ")
                               :range (r:occurrence-range example))))
    (assert (typep (ex:critic-target-for-example example) 'ex:example-critic-target))
    (assert (%refused-p (lambda () (ex:critic-target-for-example (first (r:page-occurrences page))))))
    (assert (%refused-p (lambda () (ex:critic-target-for-example stale)) 'r:stale-source-occurrence))
    (assert (%refused-p (lambda () (ex:critic-target-for-example 42))))
    t))

(defun check-example-critique ()
  "One real rule judges WORK-LAYOUT-EXAMPLE as written: a completed Evaluation
Record, one Critique, and from the Critique back to the example's source
occurrence. The example itself is never called."
  (let* ((page (%work-code-page))
         (occurrence (%example page "WORK-LAYOUT-EXAMPLE"))
         (name (second (r:occurrence-form-key occurrence)))
         (target (ex:critic-target-for-example occurrence))
         (contract (critic:lisp-critic-run-record-contract-of
                    (first (critic:target-runs-of (critic:car-cdr-critique-example)))))
         (calls 0)
         (record (let ((example (fdefinition name)))
                   (unwind-protect
                        (progn (setf (fdefinition name)
                                     (lambda () (incf calls) (funcall example)))
                               (critic:run-critic-rule contract "USE-EQL" target))
                     (setf (fdefinition name) example))))
         (finding (first (critic:critiques-of record))))
    ;; Missing external sources must fail this real-engine proof, never skip it.
    (assert (eq :completed (er:evaluation-status-of record)) ()
            "Real Critic run failed: ~A" (er:evaluation-failure-of record))
    ;; Source occurrence: the target keeps it, and its form is the example as written.
    (assert (eq occurrence (ex:example-occurrence-of target)))
    (assert (equal (r:occurrence-form-key occurrence) (wf:form-key (critic:target-form-of target))))
    ;; Execution result: there is none. The example was judged, not called.
    (assert (zerop calls))
    (assert (member :target-not-evaluated (critic:lisp-critic-run-record-notes-of record)))
    ;; Critic evaluation: the Evaluation Record's input is the target, its result the Critiques.
    (assert (eq target (er:evaluation-input-of record)))
    (assert (equal (list finding) (er:evaluation-result-of record)))
    ;; Critique: one finding of that run, which names its rule and rests on a
    ;; match inside the example.
    (assert (typep finding 'critic:critique))
    (assert (eq record (critic:critique-record-of finding)))
    (assert (eq target (critic:target-of finding)))
    (assert (eq occurrence (ex:example-occurrence-of (critic:target-of finding))))
    (assert (string= "USE-EQL" (symbol-name (critic:rule-name-of (critic:rule-of finding)))))
    (assert (probe-file (getf (critic:rule-source-of (critic:rule-of finding)) :pathname)))
    (let ((matched (uiop:symbol-call :lisp-critic :critique-code (critic:critique-evidence-of finding))))
      (assert (eq 'eq (first matched)))
      (assert (%subform-p matched (critic:target-form-of target))))
    (assert (search "EQL" (critic:critique-explanation-of finding)))
    ;; The Inspector reaches the occurrence from the target.
    (let ((view (find "Example source" (views:all-views target)
                      :key #'views:view-title :test #'string=)))
      (assert view)
      (views:view-html view)
      (assert (find occurrence (views:view-references view) :key #'cdr :test #'eq)))
    record))

(defun run-tests ()
  (let ((examples (check-example-occurrences)))
    (check-example-target-refusals)
    (let ((record (check-example-critique)))
      (format t "~&LISP-CRITIC-EXAMPLE-PASS: ~D examples read from reading.lisp; ~A judged ~A, ~
one Critique back to its source occurrence; the example was not called.~%"
              (length examples) (critic:rule-name-of (critic:rule-of record))
              (second (r:occurrence-form-key (ex:example-occurrence-of (critic:target-of record)))))))
  t)
