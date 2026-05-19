;;;; Smoke tests for the LISP-CRITIC review integration plan surface.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-LISP-CRITIC-REVIEW-PLAN-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun lisp-critic-review-plan-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun lisp-critic-review-plan-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun lisp-critic-review-plan-length-at-least-p (list minimum)
  (loop for tail = list then (rest tail)
        repeat minimum
        always (consp tail)))

(defun lisp-critic-review-plan-view-html (object title)
  (let ((view (find title
                    (html-inspector-views:all-views object)
                    :key #'html-inspector-views:view-title
                    :test #'string=)))
    (lisp-critic-review-plan-assert-true
     view
     (format nil "Expected inspector view ~S for ~S" title object))
    (let ((html (html-inspector-views:view-html view)))
      (lisp-critic-review-plan-assert-true
       (and (stringp html)
            (plusp (length html)))
       (format nil "Inspector view ~S must render non-empty HTML" title))
      html)))

(defun lisp-critic-review-plan-source-station ()
  (first (hyperdoc::hyperdoc-plan-source-stations-of
          (hyperdoc:integrate-lisp-critic-in-review-plan))))

(defun run-lisp-critic-review-plan-object-smoke-test ()
  (let* ((plan (hyperdoc:integrate-lisp-critic-in-review-plan))
         (relations (hyperdoc::hyperdoc-plan-task-relations-of plan)))
    (lisp-critic-review-plan-assert-true
     (typep plan 'hyperdoc:hyperdoc-plan)
     "Concrete LISP-CRITIC review plan object must exist.")
    (lisp-critic-review-plan-assert-equal
     "integrate-lisp-critic-in-review"
     (hyperdoc::hyperdoc-plan-id-of plan)
     "Concrete plan id must be stable.")
    (lisp-critic-review-plan-assert-true
     (lisp-critic-review-plan-length-at-least-p relations 9)
     "Concrete plan must have at least nine task relations.")
    (dolist (relation relations)
      (lisp-critic-review-plan-assert-true
       (typep (hyperdoc::hyperdoc-plan-task-relation-plan-of relation)
              'hyperdoc:hyperdoc-plan)
       "Each task relation must carry a plan.")
      (lisp-critic-review-plan-assert-true
       (typep (hyperdoc::hyperdoc-plan-task-relation-task-of relation)
              'hyperdoc:hyperdoc-task-topic)
       "Each task relation must carry a task topic.")
      (lisp-critic-review-plan-assert-true
       (hyperdoc::hyperdoc-plan-task-relation-relation-type-of relation)
       "Each task relation must carry a relation type.")
      (lisp-critic-review-plan-assert-true
       (integerp (hyperdoc::hyperdoc-plan-task-relation-ordinal-of relation))
       "Each task relation must carry an ordinal."))))

(defun run-lisp-critic-review-plan-relations-smoke-test ()
  (let* ((plan (hyperdoc:integrate-lisp-critic-in-review-plan))
         (inventory-task
           (hyperdoc:lisp-critic-review-task-topic-by-id
            "inventory-fedwiki-lisp-critic-asset"))
         (inventory-relations
           (hyperdoc:lisp-critic-review-relations-for-task inventory-task)))
    (lisp-critic-review-plan-assert-true
     inventory-task
     "inventory-fedwiki-lisp-critic-asset task must exist.")
    (lisp-critic-review-plan-assert-true
     (some (lambda (relation)
             (eql plan
                  (hyperdoc::hyperdoc-plan-task-relation-plan-of relation)))
           inventory-relations)
     "inventory-fedwiki-lisp-critic-asset must relate back to the concrete plan.")
    (lisp-critic-review-plan-assert-equal
     :does-any-part-do-this
     (hyperdoc:lisp-critic-review-normalize-goldberg-question-id
      :does-system-do-this)
     "Goldberg alias :does-system-do-this must normalize to local :does-any-part-do-this.")))

(defun run-lisp-critic-review-plan-goldberg-smoke-test ()
  (let* ((coverage (hyperdoc:lisp-critic-review-goldberg-coverage))
         (question-ids (mapcar (lambda (entry)
                                 (getf entry :question-id))
                               coverage)))
    (dolist (required '(:where-is-it
                        :what-is-that
                        :what-is-needed
                        :why-happened
                        :why-not-happened))
      (lisp-critic-review-plan-assert-true
       (member required question-ids :test #'eql)
       (format nil "Goldberg coverage must include ~S" required)))))

(defun run-lisp-critic-review-plan-view-smoke-test ()
  (let* ((plan (hyperdoc:integrate-lisp-critic-in-review-plan))
         (inventory-task
           (hyperdoc:lisp-critic-review-task-topic-by-id
            "inventory-fedwiki-lisp-critic-asset"))
         (summary-html
           (lisp-critic-review-plan-view-html plan "Summary"))
         (coverage-html
           (lisp-critic-review-plan-view-html plan "Goldberg coverage"))
         (relations-html
           (lisp-critic-review-plan-view-html
            inventory-task
            "Relations to plans")))
    (lisp-critic-review-plan-assert-true
     (search "Use the FedWiki-sourced LISP-CRITIC asset" summary-html
             :test #'char=)
     "Summary view must render the concrete plan goal.")
    (lisp-critic-review-plan-assert-true
     (search "where-is-it" coverage-html :test #'char=)
     "Goldberg coverage view must render question ids.")
    (lisp-critic-review-plan-assert-true
     (search "establishes-source-station" relations-html :test #'char=)
     "Relations to plans view must render relation types.")))

(defun run-lisp-critic-review-plan-source-station-smoke-test ()
  (let ((source-station (lisp-critic-review-plan-source-station)))
    (lisp-critic-review-plan-assert-equal
     :fedwiki-asset
     (first source-station)
     "Source station kind must be represented as data.")
    (lisp-critic-review-plan-assert-equal
     "wiki.ralfbarkow.ch"
     (getf (rest source-station) :site)
     "Source station site must be represented as data.")
    (lisp-critic-review-plan-assert-equal
     "a-critic-for-lisp"
     (getf (rest source-station) :page)
     "Source station page must be represented as data.")
    (lisp-critic-review-plan-assert-equal
     "~/.wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/"
     (getf (rest source-station) :asset-root)
     "Source station asset root must be represented as data.")
    (format t "~&LISP-CRITIC FedWiki asset present locally: ~:[no~;yes~].~%"
            (hyperdoc:lisp-critic-fedwiki-asset-present-p))))

(defun run-lisp-critic-review-plan-documentation-smoke-test ()
  (dolist (path '("hyperdoc/Integrate LISP-CRITIC into HyperDoc automated review.html"
                  "hyperdoc/DITA-like task topics for LISP-CRITIC review integration.html"))
    (lisp-critic-review-plan-assert-true
     (probe-file (asdf:system-relative-pathname :hyperdoc path))
     (format nil "Documentation page must exist: ~A" path))))

(defun run-lisp-critic-review-plan-smoke-tests ()
  (run-lisp-critic-review-plan-object-smoke-test)
  (run-lisp-critic-review-plan-relations-smoke-test)
  (run-lisp-critic-review-plan-goldberg-smoke-test)
  (run-lisp-critic-review-plan-view-smoke-test)
  (run-lisp-critic-review-plan-source-station-smoke-test)
  (run-lisp-critic-review-plan-documentation-smoke-test)
  (format t "~&LISP-CRITIC review plan smoke tests passed.~%")
  t)
