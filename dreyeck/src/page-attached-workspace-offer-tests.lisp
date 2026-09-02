
(defpackage #:dreyeck/page-attached-workspace-offer/tests
  (:use #:cl)
  (:export #:run-tests))

(in-package #:dreyeck/page-attached-workspace-offer/tests)

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
