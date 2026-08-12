;;;; Renderer-independent Topicmap model and generic Inspector view tests.

(defpackage #:hyperdoc/inspector/topicmap-tests
  (:use #:cl)
  (:export #:run-topicmap-view-smoke-tests))

(in-package #:hyperdoc/inspector/topicmap-tests)

(defclass topicmap-fixture ()
  ((target :reader fixture-target-of :initarg :target)))

(defmethod hyperdoc:topicmap-projection-of ((fixture topicmap-fixture))
  (let ((source
          (hyperdoc:make-topicmap-topic
           :id "fixture:source"
           :type :fixture-source
           :label "Fixture source"
           :object fixture
           :temporal-scope :historical
           :view-properties '(:x 20 :y 30 :visible t :pinned t)))
        (target
          (hyperdoc:make-topicmap-topic
           :id "fixture:target"
           :type :fixture-target
           :label "Fixture target"
           :object (fixture-target-of fixture)
           :temporal-scope :current
           :view-properties '(:x 300 :y 30 :visible t :pinned nil))))
    (hyperdoc:make-topicmap-projection
     :source fixture
     :topics (list source target)
     :associations
     (list
      (hyperdoc:make-topicmap-association
       :id "fixture:association"
       :type :actual-relation
       :from "fixture:source"
       :to "fixture:target"))
     :view-properties '(:width 560 :height 160))))

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun view-named (title object)
  (find title
        (html-inspector-views:all-views object)
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun run-generic-topicmap-view-test ()
  (let* ((target (list :inspectable-target))
         (fixture (make-instance 'topicmap-fixture :target target))
         (projection (hyperdoc:topicmap-projection-of fixture))
         (view (view-named "Topicmap" fixture))
         (html (and view (html-inspector-views:view-html view))))
    (check (= 2 (length (hyperdoc:topicmap-projection-topics-of projection)))
           "Generic fixture projection does not contain two topics.")
    (check
     (equal '(:actual-relation)
            (mapcar #'hyperdoc:topicmap-association-type-of
                    (hyperdoc:topicmap-projection-associations-of projection)))
     "Generic projection did not preserve its actual association type.")
    (check view "Arbitrary projected object has no Topicmap view.")
    (check (search "hyperdoc-topicmap-canvas"
                   (hyperdoc/inspector:render-topicmap-html
                    :native-svg projection))
           "Native renderer protocol did not render the projection.")
    (dolist (marker '("hyperdoc-topicmap-canvas"
                      "data-association-type='ACTUAL-RELATION'"
                      "data-temporal-scope='HISTORICAL'"
                      "data-pinned='true'"))
      (check (search marker html :test #'char-equal)
             "Generic native Topicmap rendering lacks ~S."
             marker))
    (check (member target
                   (mapcar #'cdr (html-inspector-views:view-references view))
                   :test #'eq)
           "Generic Topicmap legend does not retain its inspectable target."))
  t)

(defun run-endpoint-validation-test ()
  (handler-case
      (progn
        (hyperdoc:make-topicmap-projection
         :source :invalid
         :topics
         (list
          (hyperdoc:make-topicmap-topic
           :id "present" :type :fixture :label "Present"))
         :associations
         (list
          (hyperdoc:make-topicmap-association
           :id "broken" :type :actual-relation
           :from "present" :to "missing")))
        (error "Projection accepted a missing association endpoint."))
    (error (condition)
      (check (search "missing topic" (princ-to-string condition)
                     :test #'char-equal)
             "Endpoint validation signalled the wrong error: ~A."
             condition)))
  t)

(defun run-topicmap-view-smoke-tests ()
  (run-generic-topicmap-view-test)
  (run-endpoint-validation-test)
  (format t "Generic renderer-independent Topicmap view tests passed.~%")
  t)
