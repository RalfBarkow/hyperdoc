;;;; Executable debugger steps for the observed FedWiki journal context failure

(defpackage :dreyeck/fedwiki-journal-context-debugger
  (:use :cl)
  (:import-from :hyperdoc
                #:defexample)
  (:export
   #:fedwiki-debug-step
   #:make-fedwiki-debug-step
   #:fedwiki-debug-step-step
   #:fedwiki-debug-step-input
   #:fedwiki-debug-step-operation
   #:fedwiki-debug-step-outcome
   #:fedwiki-journal-reference-example
   #:fedwiki-context-references-example
   #:fedwiki-context-resolution-boundary-example
   #:fedwiki-protocol-probe-example))

(in-package :dreyeck/fedwiki-journal-context-debugger)

(defstruct fedwiki-debug-step
  "Four facts retained from one operation in the FedWiki failure path."
  step
  input
  operation
  outcome)

(defun %observed-journal-entry ()
  (let ((data (make-hash-table :test #'equal)))
    (setf (gethash "type" data) "fork"
          (gethash "site" data) "localhost:3000"
          (gethash "date" data) 1786347264584)
    (hyperbook/fedwiki::make-journal-entry data)))

(defun %observed-journal ()
  (vector (%observed-journal-entry)))

(defmethod html-inspector-views:text-representation
    ((debug-step fedwiki-debug-step))
  (format nil "FedWiki debug step: ~A"
          (fedwiki-debug-step-step debug-step)))

(defun %debug-step-view-row (label value &key object-reference-p)
  (html-inspector-views:html
    (:tr
     (:td (html-inspector-views:esc label))
     (:td
      (if object-reference-p
          (html-inspector-views:object-ref value)
          (html-inspector-views:html
            (:code
             (html-inspector-views:esc
              (prin1-to-string value)))))))))

(html-inspector-views:defview fedwiki-debug-step-view
    (debug-step fedwiki-debug-step)
  (html-inspector-views:html-view
      :title "FedWiki failure trace step"
      :priority 1
    (html-inspector-views:html
      (:table
       :class "inspector-table"
       (%debug-step-view-row
        "Step"
        (fedwiki-debug-step-step debug-step))
       (%debug-step-view-row
        "Input"
        (fedwiki-debug-step-input debug-step)
        :object-reference-p t)
       (%debug-step-view-row
        "Operation"
        (fedwiki-debug-step-operation debug-step))
       (%debug-step-view-row
        "Outcome"
        (fedwiki-debug-step-outcome debug-step)
        :object-reference-p t)))))

(defexample fedwiki-journal-reference-example
  "Call SITE-OF on the observed fork journal entry."
  (let ((entry (%observed-journal-entry)))
    (make-fedwiki-debug-step
     :step :journal-reference
     :input entry
     :operation 'hyperbook/fedwiki::site-of
     :outcome (hyperbook/fedwiki::site-of entry))))

(defexample fedwiki-context-references-example
  "Extract ordered site references from the observed journal without I/O."
  (let ((journal (%observed-journal)))
    (make-fedwiki-debug-step
     :step :context-references
     :input journal
     :operation 'hyperbook/fedwiki::context-site-references
     :outcome (hyperbook/fedwiki::context-site-references journal))))

(defexample fedwiki-context-resolution-boundary-example
  "Resolve with a local recording resolver and no network."
  (let* ((references
           (hyperbook/fedwiki::context-site-references
            (%observed-journal)))
         (received-references nil)
         (resolution-outcome
           (hyperbook/fedwiki::resolve-context-site-references
            references
            (lambda (site-reference)
              (push site-reference received-references)
              site-reference))))
    (make-fedwiki-debug-step
     :step :context-resolution-boundary
     :input (nreverse received-references)
     :operation 'hyperbook/fedwiki::resolve-context-site-references
     :outcome resolution-outcome)))

(defexample fedwiki-protocol-probe-example
  "Run the real HTTPS probe synchronously and retain any ERROR as its outcome."
  (let ((site-reference "localhost:3000"))
    (make-fedwiki-debug-step
     :step :protocol-probe
     :input site-reference
     :operation 'hyperbook/fedwiki::probe-fedwiki-protocol
     :outcome
     (handler-case
         (hyperbook/fedwiki::probe-fedwiki-protocol site-reference)
       (error (condition)
         condition)))))
