;;;; Dreyeck-owned renderer-independent Topicmap and Inspector tests.

(defpackage #:dreyeck/topicmap/tests
  (:use #:cl)
  (:export #:run-topicmap-view-smoke-tests))

(in-package #:dreyeck/topicmap/tests)

(defclass topicmap-fixture ()
  ((target :reader fixture-target-of :initarg :target)))

(defmethod dreyeck/topicmap:topicmap-projection-of ((fixture topicmap-fixture))
  (let ((source
          (dreyeck/topicmap:make-topicmap-topic
           :id "fixture:source"
           :type :fixture-source
           :label "Fixture source"
           :object fixture
           :temporal-scope :historical
           :view-properties '(:x 20 :y 30 :visible t :pinned t)))
        (target
          (dreyeck/topicmap:make-topicmap-topic
           :id "fixture:target"
           :type :fixture-target
           :label "Fixture target"
           :object (fixture-target-of fixture)
           :temporal-scope :current
           :view-properties '(:x 300 :y 30 :visible t :pinned nil))))
    (dreyeck/topicmap:make-topicmap-projection
     :source fixture
     :topics (list source target)
     :associations
     (list
      (dreyeck/topicmap:make-topicmap-association
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

(defun direct-dependency-names (system-designator)
  (mapcar #'string-downcase
          (asdf:system-depends-on
           (asdf:find-system system-designator))))

(defun check-ownership-contract ()
  (check (find-package "DREYECK/TOPICMAP")
         "Renderer-independent Topicmap package is absent.")
  (check (find-package "DREYECK/INSPECTOR/TOPICMAP")
         "Topicmap Inspector package is absent.")
  (check
   (eq (symbol-package 'dreyeck/topicmap:topicmap-projection)
       (find-package "DREYECK/TOPICMAP"))
   "Topicmap model symbol is not owned by DREYECK/TOPICMAP.")
  (let ((model-dependencies
          (direct-dependency-names "dreyeck/topicmap"))
        (inspector-dependencies
          (direct-dependency-names "dreyeck/inspector/topicmap")))
    (dolist (forbidden '("hyperdoc"
                         "hyperdoc/inspector"
                         "html-inspector-views"
                         "clog-moldable-inspector"
                         "dm6"
                         "elm"))
      (check (not (member forbidden model-dependencies :test #'string=))
             "Renderer-independent system depends on ~A: ~S."
             forbidden model-dependencies))
    (check (member "dreyeck/topicmap" inspector-dependencies
                   :test #'string=)
           "Inspector system does not depend on the Dreyeck model.")
    (check (member "hyperdoc/inspector" inspector-dependencies
                   :test #'string=)
           "Inspector extension does not use HyperDoc as a library."))
  (dolist (upstream-system '("hyperdoc" "hyperdoc/inspector"))
    (dolist (dependency (direct-dependency-names upstream-system))
      (check (not (uiop:string-prefix-p "dreyeck/" dependency))
             "Upstream system ~A depends back on ~A."
             upstream-system dependency)))
  t)

(defun run-generic-topicmap-view-test ()
  (let* ((target (list :inspectable-target))
         (fixture (make-instance 'topicmap-fixture :target target))
         (projection (dreyeck/topicmap:topicmap-projection-of fixture))
         (view (view-named "Topicmap" fixture))
         (html (and view (html-inspector-views:view-html view))))
    (check (= 2 (length (dreyeck/topicmap:topicmap-projection-topics-of projection)))
           "Generic fixture projection does not contain two topics.")
    (check
     (equal '(:actual-relation)
            (mapcar #'dreyeck/topicmap:topicmap-association-type-of
                    (dreyeck/topicmap:topicmap-projection-associations-of projection)))
     "Generic projection did not preserve its actual association type.")
    (check view "Arbitrary projected object has no Topicmap view.")
    (check (search "dreyeck-topicmap-canvas"
                   (dreyeck/inspector/topicmap:render-topicmap-html
                    :native-svg projection))
           "Native renderer protocol did not render the projection.")
    (dolist (marker '("dreyeck-topicmap-canvas"
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
        (dreyeck/topicmap:make-topicmap-projection
         :source :invalid
         :topics
         (list
          (dreyeck/topicmap:make-topicmap-topic
           :id "present" :type :fixture :label "Present"))
         :associations
         (list
          (dreyeck/topicmap:make-topicmap-association
           :id "broken" :type :actual-relation
           :from "present" :to "missing")))
        (error "Projection accepted a missing association endpoint."))
    (error (condition)
      (check (search "missing topic" (princ-to-string condition)
                     :test #'char-equal)
             "Endpoint validation signalled the wrong error: ~A."
             condition)))
  t)

(DEFUN RUN-SEMANTIC-TOPICMAP-PRESENTATION-SMOKE-TEST ()
  (LET* ((CONTAINED
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-TOPIC :ID "test:contained"
                         :TYPE :TEST-CONTAINED :LABEL "contained" :OBJECT
                         :CONTAINED :TEMPORAL-SCOPE :CURRENT-LISP-IMAGE
                         :VIEW-PROPERTIES
                         '(:X 120 :Y 260 :VISIBLE T :PINNED T)))
         (CONTAINER
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-TOPIC :ID "test:container"
                         :TYPE :TEST-CONTAINER :LABEL "container" :OBJECT
                         :CONTAINER :TEMPORAL-SCOPE :CURRENT-LISP-IMAGE
                         :VIEW-PROPERTIES
                         '(:X 700 :Y 260 :VISIBLE T :PINNED T)))
         (ASSOCIATION
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION :ID
                         "test:containment" :TYPE :CONTAINING-METHOD :FROM
                         "test:contained" :TO "test:container" :PROPERTIES
                         '(:PRESENTATION :STRUCTURAL-CONTAINMENT)))
         (PROJECTION
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-PROJECTION :SOURCE :TEST
                         :TOPICS (LIST CONTAINED CONTAINER) :ASSOCIATIONS
                         (LIST ASSOCIATION) :VIEW-PROPERTIES
                         '(:WIDTH 1050 :HEIGHT 520 :POINT "test:contained")))
         (HTML
          (DREYECK/INSPECTOR/TOPICMAP:RENDER-TOPICMAP-HTML :NATIVE-SVG
                                                           PROJECTION)))
    (ASSERT (SEARCH "class='dreyeck-topicmap-structural-containment'" HTML))
    (ASSERT (SEARCH "data-presentation='STRUCTURAL-CONTAINMENT'" HTML))
    (ASSERT (SEARCH "class='dreyeck-topicmap-point-sign'" HTML))
    (ASSERT (SEARCH "data-presentation='POINT'" HTML))
    (ASSERT
     (NULL
      (SEARCH
       "class='dreyeck-topicmap-association' data-association-id='test:containment'"
       HTML)))
    T))

(DEFUN RUN-TOPICMAP-VIEW-SMOKE-TESTS ()
  (CHECK-OWNERSHIP-CONTRACT)
  (RUN-GENERIC-TOPICMAP-VIEW-TEST)
  (RUN-ENDPOINT-VALIDATION-TEST)
  (FORMAT T "Generic renderer-independent Topicmap view tests passed.~%")
  (RUN-SEMANTIC-TOPICMAP-PRESENTATION-SMOKE-TEST)
  T)