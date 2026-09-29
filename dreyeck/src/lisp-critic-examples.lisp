;;;; A DEFEXAMPLE, read back from its code page, as a Lisp Critic target.
;;;;
;;;; Reading a code page finds its examples as source occurrences
;;;; (PAGE-EXAMPLE-OCCURRENCES). This file lets the existing Critic judge one
;;;; of them without losing which one it is: the target keeps the occurrence,
;;;; and every Evaluation Record and Critique the Critic makes already leads
;;;; to its target. The Critic itself is unchanged.
;;;;
;;;; Four things are kept apart here, and none stands in for another:
;;;;
;;;;   source occurrence   the example as reading its page now observes it
;;;;   execution result    what calling the example returns; nothing here
;;;;                       calls it, and the Critic does not evaluate its
;;;;                       target
;;;;   critic evaluation   one rule applied to the example's form: the run's
;;;;                       Evaluation Record, completed or failed
;;;;   critique            one finding of that run, with the rule it comes
;;;;                       from, the match it rests on and the rule's
;;;;                       recommendation
;;;;
;;;; A recommendation is not an improvement proposal. Nothing here turns one
;;;; into a change. Nor can a suggestion from anywhere else pass as a
;;;; critique: a CRITIQUE is one rule's finding and names its rule.
;;;;
;;;; The target form is the example as written, not the DEFUN it expands to.
;;;; The two are different inputs: rules about DEFUNs match the expansion and
;;;; not the source, and a finding on the expansion would be about a form no
;;;; page shows.

(defpackage #:dreyeck/lisp-critic/examples
  (:use #:cl)
  (:local-nicknames (#:critic #:dreyeck/lisp-critic)
                    (#:r #:dreyeck/gesture/operation-request)
                    (#:hv #:html-inspector-views/standard)
                    (#:views #:html-inspector-views))
  (:export #:example-critic-target
           #:example-occurrence-of
           #:critic-target-for-example))

(in-package #:dreyeck/lisp-critic/examples)

(defclass example-critic-target (critic:critic-target)
  ((occurrence :initarg :occurrence :reader example-occurrence-of))
  (:documentation "A Critic target that is one DEFEXAMPLE on a code page: the
example's form as its occurrence's snapshot reads, and that occurrence."))

(defun critic-target-for-example (occurrence)
  "The Critic target for the DEFEXAMPLE at OCCURRENCE. Its form is the example
as written in the occurrence's snapshot, which must still be its page's source.
Signals unless OCCURRENCE is a current source occurrence of a DEFEXAMPLE. Runs
nothing and loads nothing."
  (unless (and (typep occurrence 'r:source-occurrence)
               (eq :example (first (r:occurrence-form-key occurrence))))
    (error "~S is not the source occurrence of a DEFEXAMPLE." occurrence))
  (make-instance 'example-critic-target
                 :form (hv:s-exp (r:resolve-occurrence occurrence))
                 :occurrence occurrence))

(views:defview example-source-view (target example-critic-target)
  (views:html-view :title "Example source" :priority 2
    (let ((occurrence (example-occurrence-of target)))
      (views:html
        (:table :class "inspector-table"
          (:tr (:td "Source occurrence")
               (:td (views:object-ref occurrence
                                      :display (prin1-to-string (r:occurrence-form-key occurrence)))))
          (:tr (:td "Page") (:td (views:object-ref (r:occurrence-page occurrence))))
          (:tr (:td "Status now") (:td (views:esc (symbol-name (r:occurrence-status occurrence)))))
          (:tr (:td "Executed")
               (:td "no -- the Critic judges the example's form and does not call it")))))))
