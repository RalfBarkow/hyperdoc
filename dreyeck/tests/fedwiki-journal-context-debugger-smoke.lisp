;;;; Deterministic tests for the executable FedWiki journal-context debugger.

(defpackage #:dreyeck/fedwiki-journal-context-debugger/tests
  (:use #:cl)
  (:export #:run-fedwiki-journal-context-debugger-tests))

(in-package #:dreyeck/fedwiki-journal-context-debugger/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun make-journal-entry (site date &key attribution-p)
  (let ((data (make-hash-table :test #'equal)))
    (setf (gethash "type" data) "fork"
          (gethash "date" data) date)
    (if attribution-p
        (let ((attribution (make-hash-table :test #'equal)))
          (setf (gethash "site" attribution) site
                (gethash "attribution" data) attribution))
        (setf (gethash "site" data) site))
    (hyperbook/fedwiki::make-journal-entry data)))

(defun make-ordering-journal ()
  (vector
   (make-journal-entry "alpha.example" 1000)
   (make-journal-entry "beta.example" 2000)
   (make-journal-entry "alpha.example" 3000)
   (make-journal-entry "gamma.example" 4000 :attribution-p t)
   (make-journal-entry "beta.example" 5000)))

(defun run-context-site-references-test ()
  (let ((references
          (hyperbook/fedwiki::context-site-references
           (make-ordering-journal))))
    (check
     (equal '("beta.example" "gamma.example" "alpha.example")
            references)
     "Context reference ordering or deduplication changed: ~S."
     references))
  t)

(defun run-resolution-boundary-test ()
  (let* ((references
           (hyperbook/fedwiki::context-site-references
            (make-ordering-journal)))
         (remaining references)
         (received nil)
         (outcome
           (hyperbook/fedwiki::resolve-context-site-references
            references
            (lambda (site-reference)
              (check (eq site-reference (pop remaining))
                     "Resolver did not receive the exact reference object ~S."
                     site-reference)
              (push site-reference received)
              (list :resolved site-reference)))))
    (check (null remaining)
           "Resolver did not receive every reference: ~S."
           remaining)
    (check (equal references (nreverse received))
           "Resolver inputs differ from references: ~S."
           received)
    (check
     (equal '((:resolved "beta.example")
              (:resolved "gamma.example")
              (:resolved "alpha.example"))
            outcome)
     "Resolution outcome differs: ~S."
     outcome))
  t)

(defun make-initialized-wiki (site-reference)
  (let ((wiki
          (make-instance 'hyperbook/fedwiki::fedwiki
                         :id (concatenate
                              'string "fedwiki:" site-reference))))
    (setf (hyperbook/fedwiki::status-of wiki) t)
    wiki))

(defun run-extract-context-composition-test ()
  (let* ((journal (make-ordering-journal))
         (references
           (hyperbook/fedwiki::context-site-references journal))
         (hyperbook/fedwiki::*neighborhood*
           (make-hash-table :test #'equal))
         (expected
           (loop for reference in references
                 for wiki = (make-initialized-wiki reference)
                 do (setf (gethash reference
                                   hyperbook/fedwiki::*neighborhood*)
                          wiki)
                 collect wiki))
         (composed
           (hyperbook/fedwiki::resolve-context-site-references references))
         (extracted
           (hyperbook/fedwiki::extract-context journal)))
    (check (equal expected composed)
           "Explicit context composition differs: ~S."
           composed)
    (check (equal composed extracted)
           "EXTRACT-CONTEXT no longer has the helper composition contract: ~S."
           extracted))
  t)

(defun debug-step-outcome (step)
  (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-outcome step))

(defun run-deterministic-examples-test ()
  (let ((journal-reference
          (dreyeck/fedwiki-journal-context-debugger:fedwiki-journal-reference-example))
        (context-references
          (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-references-example))
        (resolution-boundary
          (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-resolution-boundary-example)))
    (dolist (step (list journal-reference
                        context-references
                        resolution-boundary))
      (check
       (typep step
              'dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step)
       "Example returned ~S rather than a FEDWIKI-DEBUG-STEP."
       step))
    (check
     (typep
      (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-input
       journal-reference)
      'hyperbook/fedwiki::journal-entry)
     "Journal-reference input is not a real JOURNAL-ENTRY.")
    (check (string= "localhost:3000"
                    (debug-step-outcome journal-reference))
           "SITE-OF outcome differs: ~S."
           (debug-step-outcome journal-reference))
    (check (equal '("localhost:3000")
                  (debug-step-outcome context-references))
           "Context-reference example differs: ~S."
           (debug-step-outcome context-references))
    (check (equal '("localhost:3000")
                  (debug-step-outcome resolution-boundary))
           "Resolution-boundary example differs: ~S."
           (debug-step-outcome resolution-boundary))
    (check
     (equal '("localhost:3000")
            (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-input
             resolution-boundary))
     "Resolution-boundary recorder inputs differ: ~S."
     (dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step-input
      resolution-boundary))
    (check
     (equal (debug-step-outcome journal-reference)
            (debug-step-outcome
             (dreyeck/fedwiki-journal-context-debugger:fedwiki-journal-reference-example)))
     "Journal-reference example is not deterministic.")
    (check
     (equal (debug-step-outcome context-references)
            (debug-step-outcome
             (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-references-example)))
     "Context-reference example is not deterministic.")
    (check
     (equal (debug-step-outcome resolution-boundary)
            (debug-step-outcome
             (dreyeck/fedwiki-journal-context-debugger:fedwiki-context-resolution-boundary-example)))
     "Resolution-boundary example is not deterministic."))
  t)

(defun run-raw-outcome-retention-test ()
  (let* ((slot-names
           (mapcar
            (lambda (slot)
              (intern
               (symbol-name (closer-mop:slot-definition-name slot))
               :keyword))
            (closer-mop:class-slots
             (find-class
              'dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step))))
         (raw-outcome (list :unclassified :raw))
         (step
           (dreyeck/fedwiki-journal-context-debugger:make-fedwiki-debug-step
            :step :test
            :input nil
            :operation 'identity
            :outcome raw-outcome)))
    (check (equal '(:step :input :operation :outcome) slot-names)
           "FEDWIKI-DEBUG-STEP stores facts beyond its four fields: ~S."
           slot-names)
    (check (eq raw-outcome (debug-step-outcome step))
           "FEDWIKI-DEBUG-STEP did not retain the raw outcome object."))
  t)

(defun run-protocol-probe-example-test ()
  (let ((escaped-condition nil)
        (step nil))
    (handler-case
        (setf step
              (dreyeck/fedwiki-journal-context-debugger:fedwiki-protocol-probe-example))
      (error (condition)
        (setf escaped-condition condition)))
    (check (null escaped-condition)
           "Protocol-probe example signaled ~S instead of retaining it."
           escaped-condition)
    (check
     (typep step
            'dreyeck/fedwiki-journal-context-debugger:fedwiki-debug-step)
     "Protocol-probe example did not return a FEDWIKI-DEBUG-STEP: ~S."
     step)
    (let ((outcome (debug-step-outcome step)))
      (check (or (typep outcome 'condition)
                 (member outcome '("https" "http") :test #'string=))
             "Protocol-probe outcome is neither a condition nor protocol: ~S."
             outcome)))
  t)

(defun run-inspector-view-test ()
  (let* ((outcome
           (make-condition 'simple-error
                           :format-control "Inspectable raw outcome"))
         (step
           (dreyeck/fedwiki-journal-context-debugger:make-fedwiki-debug-step
            :step :inspector-test
            :input "input"
            :operation 'identity
            :outcome outcome))
         (titles
           (mapcar #'html-inspector-views:view-title
                   (html-inspector-views:all-views step)))
         (view
           (find "FedWiki failure trace step"
                 (html-inspector-views:all-views step)
                 :key #'html-inspector-views:view-title
                 :test #'string=)))
    (check (member "FedWiki failure trace step" titles :test #'string=)
           "FEDWIKI-DEBUG-STEP lacks its specialized inspector view: ~S."
           titles)
    (html-inspector-views:view-html view)
    (check (find outcome
                 (html-inspector-views:view-references view)
                 :key #'cdr
                 :test #'eq)
           "Inspector view does not retain OUTCOME as a clickable object."))
  t)

(defun run-fedwiki-journal-context-debugger-tests ()
  (run-context-site-references-test)
  (run-resolution-boundary-test)
  (run-extract-context-composition-test)
  (run-deterministic-examples-test)
  (run-raw-outcome-retention-test)
  (run-protocol-probe-example-test)
  (run-inspector-view-test)
  (format t "FedWiki journal-context debugger tests passed.~%")
  t)
