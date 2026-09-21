
(defpackage #:dreyeck/page-attached-workspace-offer/tests
  (:use #:cl)
  (:export #:run-tests #:run-offer-view-tests))

(in-package #:dreyeck/page-attached-workspace-offer/tests)

(defun view-probe (offer)
  "Render the offer's primary view and report what it cost."
  (let* ((before (length (asdf:registered-systems)))
         (views (html-inspector-views:all-views offer))
         (primary (first views))
         (html (html-inspector-views:view-html primary)))
    (list :title (html-inspector-views:view-title primary)
          :html html
          :registrations (- (length (asdf:registered-systems)) before))))

(defun run-offer-view-tests ()
  "An offer must be readable without evaluating what it offers.

A catalog click inspects this object; it does not follow LOOKUP-PATH.
Before this the object had no view of its own, so the click landed on
greyed-out debugging tabs. Giving it one must not cost an evaluation."
  (let* ((offer
           (make-instance
            'dreyeck/page-attached-workspace-offer:page-attached-workspace-offer
            :id "workspace:a-critic-for-lisp" :title "a-critic-for-lisp"))
         (probe (view-probe offer)))
    (assert (equal "Page-attached Workspace offer" (getf probe :title)))
    ;; Reading it registers nothing.
    (assert (= 0 (getf probe :registrations)))
    ;; And does not materialize.
    (assert (not (slot-boundp offer 'dreyeck/page-attached-workspace-offer::workspace)))
    (let ((html (getf probe :html)))
      (dolist (expected '("workspace:a-critic-for-lisp"
                          "a-critic-for-lisp"
                          "assets/pages/a-critic-for-lisp/a-critic-for-lisp.asd"
                          "offered"
                          "not materialized"))
        (assert (search expected html)))))
  ;; A runtime that refuses execution says so, and the refusal is real.
  (asdf:load-system "hyperbook/server")
  (let* ((package (find-package :hyperbook/server))
         (symbol (and package (find-symbol "*SERVER-PARAMETERS*" package)))
         (had (progn (assert package) (assert symbol) (boundp symbol)))
         (old (and had (symbol-value symbol))))
    (unwind-protect
         (progn
           (setf (symbol-value symbol) (list "700px" nil))
           (let* ((offer
                    (make-instance
                     'dreyeck/page-attached-workspace-offer:page-attached-workspace-offer
                     :id "workspace:a-critic-for-lisp" :title "a-critic-for-lisp"))
                  (html (getf (view-probe offer) :html)))
             (assert (search "not available in this runtime" html))
             ;; Not only the view: the path through LOOKUP-PATH must be
             ;; refused too, since a click is not the only way in.
             (assert
              (handler-case (progn (hyperbook:lookup-path offer nil) nil)
                (dreyeck/page-attached-system-projection:execution-not-permitted
                    () t)))))
      (if had (setf (symbol-value symbol) old) (makunbound symbol))))
  (format t "~&PAGE-ATTACHED-OFFER-VIEW-PASS: the offer reads without ~
evaluating, and a runtime that refuses says so and refuses.~%")
  t)

(defun run-tests ()
  (let* ((subject-id "workspace:related-topics-for-topic")
         (offer
          (make-instance
           'dreyeck/page-attached-workspace-offer:page-attached-workspace-offer
           :id subject-id :title subject-id))
         (before
          (handler-case
           (progn
            (dreyeck/page-attached-workspace-offer:page-attached-workspace-of
             offer)
            :returned)
           (unbound-slot nil :unbound-slot)))
         (direct-slots (sb-mop:class-direct-slots (class-of offer)))
         (system-designator-slot
          (find-if
           (lambda (slot)
             (member :system-designator (sb-mop:slot-definition-initargs slot)
                     :test #'eq))
           direct-slots))
         (first-workspace (hyperbook:lookup-path offer nil))
         (reader-after-first
          (dreyeck/page-attached-workspace-offer:page-attached-workspace-of
           offer))
         (second-workspace (hyperbook:lookup-path offer nil)))
    (assert (eq :unbound-slot before))
    (assert (null system-designator-slot))
    (assert first-workspace)
    (assert (eq first-workspace reader-after-first))
    (assert (eq first-workspace second-workspace))
    (list :status :passed :subject-id subject-id
          :workspace-unbound-before-first-activation-p
          (eq :unbound-slot before)
          :workspace-readable-after-first-activation-p
          (eq first-workspace reader-after-first)
          :second-activation-reuses-workspace-p
          (eq first-workspace second-workspace) :system-designator-slot-p
          (not (null system-designator-slot)) :ready-for
          :fresh-image-offer-activation-acceptance)))
