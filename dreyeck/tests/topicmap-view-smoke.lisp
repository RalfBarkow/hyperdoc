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

(defun run-topicmap-workspace-test ()
  (let* ((target (list :workspace-target))
         (fixture (make-instance 'topicmap-fixture :target target))
         (projection (dreyeck/topicmap:topicmap-projection-of fixture))
         (topics (dreyeck/topicmap:topicmap-projection-topics-of projection))
         (initial-topic (first topics))
         (next-topic (second topics))
         (initial-id (dreyeck/topicmap:topicmap-topic-id-of initial-topic))
         (next-id (dreyeck/topicmap:topicmap-topic-id-of next-topic))
         (workspace
          (dreyeck/topicmap:make-topicmap-workspace projection initial-id)))
    (check
     (eq initial-topic
         (dreyeck/topicmap:topicmap-workspace-current-topic workspace))
     "Workspace does not initially resolve its point topic.")
    (check
     (eq (dreyeck/topicmap:topicmap-topic-object-of initial-topic)
         (dreyeck/topicmap:topicmap-workspace-current-object workspace))
     "Workspace does not initially resolve the point's live object.")
    (let ((workspace-projection
           (dreyeck/topicmap:topicmap-projection-of workspace)))
      (check
       (eq workspace
           (dreyeck/topicmap:topicmap-projection-source-of
            workspace-projection))
       "Workspace projection does not retain the workspace as source.")
      (check
       (equal initial-id
              (getf
               (dreyeck/topicmap:topicmap-projection-view-properties-of
                workspace-projection)
               :point))
       "Workspace projection does not expose the initial point."))
    (check
     (eq next-topic
         (dreyeck/topicmap:topicmap-workspace-go-to workspace next-id))
     "Workspace navigation did not return the target topic.")
    (check
     (equal next-id (dreyeck/topicmap:topicmap-workspace-point-of workspace))
     "Workspace navigation did not move the point.")
    (check
     (equal (list initial-id)
            (dreyeck/topicmap:topicmap-workspace-history-of workspace))
     "Workspace navigation did not record the previous point.")
    (check
     (eq next-topic
         (dreyeck/topicmap:topicmap-workspace-current-topic workspace))
     "Workspace current topic does not follow navigation.")
    (check
     (eq (dreyeck/topicmap:topicmap-topic-object-of next-topic)
         (dreyeck/topicmap:topicmap-workspace-current-object workspace))
     "Workspace current live object does not follow navigation.")
    (check
     (equal next-id
            (getf
             (dreyeck/topicmap:topicmap-projection-view-properties-of
              (dreyeck/topicmap:topicmap-projection-of workspace))
             :point))
     "Workspace projection does not expose the moved point.")
    (dreyeck/topicmap:topicmap-workspace-go-to workspace next-id)
    (check
     (equal (list initial-id)
            (dreyeck/topicmap:topicmap-workspace-history-of workspace))
     "Navigating to the current point changed workspace history.")
    t))

(defun run-topicmap-projection-completion-test ()
  (let* ((present-id "topic:present")
         (missing-id "topic:missing")
         (source :test-source)
         (view-properties '(:width 100 :height 100))
         (association
          (make-instance 'dreyeck/topicmap:topicmap-association :id
                         "association:test" :type :test :from present-id :to
                         missing-id))
         (associations (list association))
         (projection
          (make-instance 'dreyeck/topicmap:topicmap-projection :source source
                         :topics
                         (list
                          (make-instance 'dreyeck/topicmap:topicmap-topic :id
                                         present-id :type :test :label
                                         present-id))
                         :associations associations :view-properties
                         view-properties))
         (once (dreyeck/topicmap::complete-topicmap-projection projection))
         (twice (dreyeck/topicmap::complete-topicmap-projection once))
         (ghost
          (find missing-id
                (dreyeck/topicmap:topicmap-projection-topics-of once) :key
                #'dreyeck/topicmap:topicmap-topic-id-of :test #'string=))
         (once-ids
          (mapcar #'dreyeck/topicmap:topicmap-topic-id-of
                  (dreyeck/topicmap:topicmap-projection-topics-of once)))
         (twice-ids
          (mapcar #'dreyeck/topicmap:topicmap-topic-id-of
                  (dreyeck/topicmap:topicmap-projection-topics-of twice))))
    (assert ghost)
    (assert (null (dreyeck/topicmap:topicmap-topic-object-of ghost)))
    (assert (equal once-ids twice-ids))
    (assert (eq source (dreyeck/topicmap:topicmap-projection-source-of once)))
    (assert
     (eq associations
         (dreyeck/topicmap:topicmap-projection-associations-of once)))
    (assert
     (eq view-properties
         (dreyeck/topicmap:topicmap-projection-view-properties-of once)))
    t))

(defun run-page-attached-workspace-projection-test ()
  (let* ((system-id "asdf-system:example")
         (workspace-id "workspace:example")
         (projection
          (make-instance 'dreyeck/topicmap:topicmap-projection :source :test
                         :topics
                         (list
                          (make-instance 'dreyeck/topicmap:topicmap-topic :id
                                         system-id :type :asdf-system :label
                                         "example"))
                         :associations nil))
         (once
          (dreyeck/topicmap::project-page-attached-workspace projection
                                                             "example"))
         (twice
          (dreyeck/topicmap::project-page-attached-workspace once "example"))
         (workspace
          (find workspace-id
                (dreyeck/topicmap:topicmap-projection-topics-of once) :key
                #'dreyeck/topicmap:topicmap-topic-id-of :test #'string=))
         (once-association-ids
          (mapcar #'dreyeck/topicmap:topicmap-association-id-of
                  (dreyeck/topicmap:topicmap-projection-associations-of once)))
         (twice-association-ids
          (mapcar #'dreyeck/topicmap:topicmap-association-id-of
                  (dreyeck/topicmap:topicmap-projection-associations-of
                   twice))))
    (assert workspace)
    (assert (null (dreyeck/topicmap:topicmap-topic-object-of workspace)))
    (assert (equal once-association-ids twice-association-ids))
    t))

(defun run-topicmap-workspace-inspector-action-test ()
  (let* ((target (list :workspace-target))
         (fixture (make-instance 'topicmap-fixture :target target))
         (projection (dreyeck/topicmap:topicmap-projection-of fixture))
         (topics (dreyeck/topicmap:topicmap-projection-topics-of projection))
         (initial-topic (first topics))
         (initial-id (dreyeck/topicmap:topicmap-topic-id-of initial-topic))
         (workspace
          (dreyeck/topicmap:make-topicmap-workspace projection initial-id))
         (view (view-named "Topicmap" workspace))
         (html (and view (html-inspector-views:view-html view)))
         (action-references
          (and view
               (remove-if-not
                (lambda (reference)
                  (and (stringp (car reference))
                       (uiop/utility:string-prefix-p "action-" (car reference))
                       (search
                        (format nil
                                "id='~A' class='dreyeck-topicmap-workspace-action "
                                (car reference))
                        html :test #'char-equal)))
                (html-inspector-views:view-references view)))))
    (check view "Workspace has no Topicmap view.")
    (check html "Workspace Topicmap view rendered no HTML.")
    (check (= (length topics) (length action-references))
           "Workspace Topicmap does not expose one action per topic.")
    (check
     (every
      (lambda (reference) (typep (cdr reference) 'html-inspector-views:thunk))
      action-references)
     "Workspace Topicmap actions are not Inspector thunks.")
    (let ((reached-topic-ids nil))
      (dolist (reference action-references)
        (setf (dreyeck/topicmap:topicmap-workspace-point-of workspace)
                initial-id
              (dreyeck/topicmap:topicmap-workspace-history-of workspace) nil)
        (let ((result (html-inspector-views:eval-thunk (cdr reference))))
          (check (typep result 'dreyeck/topicmap:topicmap-topic)
                 "Workspace action did not return a topic.")
          (let* ((result-id (dreyeck/topicmap:topicmap-topic-id-of result))
                 (view-after (view-named "Topicmap" workspace))
                 (html-after
                  (and view-after (html-inspector-views:view-html view-after)))
                 (point-marker
                  (format nil "data-topic-id='~A' data-presentation='POINT'"
                          (dreyeck/inspector/topicmap::topicmap-html-escape
                           result-id))))
            (check
             (eq result
                 (dreyeck/topicmap:topicmap-workspace-current-topic workspace))
             "Workspace action result is not the current topic.")
            (check
             (equal result-id
                    (dreyeck/topicmap:topicmap-workspace-point-of workspace))
             "Workspace action did not move the point.")
            (check
             (equal result-id
                    (getf
                     (dreyeck/topicmap:topicmap-projection-view-properties-of
                      (dreyeck/topicmap:topicmap-projection-of workspace))
                     :point))
             "Workspace action did not update projection point.")
            (check
             (if (string= result-id initial-id)
                 (null
                  (dreyeck/topicmap:topicmap-workspace-history-of workspace))
                 (equal (list initial-id)
                        (dreyeck/topicmap:topicmap-workspace-history-of
                         workspace)))
             "Workspace action produced incorrect history.")
            (check
             (and html-after
                  (search point-marker html-after :test #'char-equal))
             "Workspace Topicmap did not render the moved point.")
            (push result-id reached-topic-ids))))
      (check
       (equal (sort (copy-list reached-topic-ids) #'string<)
              (sort (mapcar #'dreyeck/topicmap:topicmap-topic-id-of topics)
                    #'string<))
       "Workspace Topicmap actions do not reach every topic."))
    t))


(defun run-topicmap-workspace-snapshot-test ()
  (let* ((topic-a
           (dreyeck/topicmap:make-topicmap-topic
            :id "snapshot:a"
            :type :test
            :label "A"
            :object :a))
         (topic-b
           (dreyeck/topicmap:make-topicmap-topic
            :id "snapshot:b"
            :type :test
            :label "B"
            :object :b))
         (topic-c
           (dreyeck/topicmap:make-topicmap-topic
            :id "snapshot:c"
            :type :test
            :label "C"
            :object :c))
         (projection
           (dreyeck/topicmap:make-topicmap-projection
            :source :workspace-snapshot-test
            :topics (list topic-a topic-b topic-c)
            :associations nil))
         (workspace
           (dreyeck/topicmap:make-topicmap-workspace
            projection
            "snapshot:a")))
    (dreyeck/topicmap:topicmap-workspace-go-to
     workspace
     "snapshot:b")
    (let* ((point-before
             (dreyeck/topicmap:topicmap-workspace-point-of
              workspace))
           (history-before
             (copy-list
              (dreyeck/topicmap:topicmap-workspace-history-of
               workspace)))
           (snapshot
             (dreyeck/topicmap:topicmap-workspace-snapshot-at
              workspace
              "snapshot:c")))
      (check
       (eq topic-b
           (dreyeck/topicmap:topicmap-projection-topic-by-id
            projection
            "snapshot:b"))
       "Projection lookup did not return the existing topic.")
      (check
       (null
        (dreyeck/topicmap:topicmap-projection-topic-by-id
         projection
         "snapshot:missing"))
       "Projection lookup resolved a missing topic.")
      (check
       (and
        (not (eq workspace snapshot))
        (eq projection
            (dreyeck/topicmap:topicmap-workspace-projection-of
             snapshot))
        (string=
         "snapshot:c"
         (dreyeck/topicmap:topicmap-workspace-point-of
          snapshot))
        (null
         (dreyeck/topicmap:topicmap-workspace-history-of
          snapshot))
        (eq topic-c
            (dreyeck/topicmap:topicmap-workspace-current-topic
             snapshot)))
       "Workspace snapshot does not preserve its independent point over the shared projection.")
      (check
       (and
        (string=
         point-before
         (dreyeck/topicmap:topicmap-workspace-point-of
          workspace))
        (equal
         history-before
         (dreyeck/topicmap:topicmap-workspace-history-of
          workspace)))
       "Creating a snapshot changed the source workspace.")
      t)))

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

(DEFUN RUN-SEMANTIC-TOPICMAP-ENDPOINT-ROLE-SMOKE-TEST ()
  (LET* ((CONTAINED
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-TOPIC :ID "test:contained" :TYPE
                         :TEST-CONTAINED :LABEL "contained" :OBJECT :CONTAINED
                         :TEMPORAL-SCOPE :CURRENT-LISP-IMAGE :VIEW-PROPERTIES
                         '(:X 120 :Y 260 :VISIBLE T :PINNED T)))
         (CONTAINER
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-TOPIC :ID "test:container" :TYPE
                         :TEST-CONTAINER :LABEL "container" :OBJECT :CONTAINER
                         :TEMPORAL-SCOPE :CURRENT-LISP-IMAGE :VIEW-PROPERTIES
                         '(:X 700 :Y 260 :VISIBLE T :PINNED T)))
         (ASSOCIATION
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION :ID "test:containment"
                         :TYPE :CONTAINING-METHOD :FROM "test:container" :TO
                         "test:contained" :PROPERTIES
                         '(:PRESENTATION :STRUCTURAL-CONTAINMENT :CONTAINED-ENDPOINT
                           :TO)))
         (PROJECTION
          (MAKE-INSTANCE 'DREYECK/TOPICMAP:TOPICMAP-PROJECTION :SOURCE :TEST :TOPICS
                         (LIST CONTAINED CONTAINER) :ASSOCIATIONS (LIST ASSOCIATION)
                         :VIEW-PROPERTIES
                         '(:WIDTH 1050 :HEIGHT 520 :POINT "test:contained")))
         (HTML
          (DREYECK/INSPECTOR/TOPICMAP:RENDER-TOPICMAP-HTML :NATIVE-SVG PROJECTION)))
    (ASSERT (SEARCH "class='dreyeck-topicmap-structural-containment'" HTML))
    (ASSERT (SEARCH "data-presentation='STRUCTURAL-CONTAINMENT'" HTML))
    (ASSERT (SEARCH "class='dreyeck-topicmap-point-sign'" HTML))
    (ASSERT (SEARCH "data-presentation='POINT'" HTML))
    (ASSERT
     (NULL
      (SEARCH
       "class='dreyeck-topicmap-association' data-association-id='test:containment'"
       HTML)))
    (ASSERT (SEARCH "data-topic-id='test:container'" HTML))
    (ASSERT (SEARCH "data-topic-id='test:contained'" HTML))
    T))

(defun run-topicmap-workspace-association-navigation-test ()
  (block run-topicmap-workspace-association-navigation-test
    (let* ((common-lisp-user::projection
            (dreyeck/topicmap:make-topicmap-projection :source
                                                       :workspace-association-test
                                                       :topics
                                                       (list
                                                        (dreyeck/topicmap:make-topicmap-topic
                                                         :id "point-a" :type
                                                         :test :label "A"
                                                         :object :a
                                                         :view-properties
                                                         '(:visible t))
                                                        (dreyeck/topicmap:make-topicmap-topic
                                                         :id "point-b" :type
                                                         :test :label "B"
                                                         :object :b
                                                         :view-properties
                                                         '(:visible t))
                                                        (dreyeck/topicmap:make-topicmap-topic
                                                         :id "point-c" :type
                                                         :test :label "C"
                                                         :object :c
                                                         :view-properties
                                                         '(:visible t)))
                                                       :associations
                                                       (list
                                                        (dreyeck/topicmap:make-topicmap-association
                                                         :id "r1" :type :r1
                                                         :from "point-a" :to
                                                         "point-b")
                                                        (dreyeck/topicmap:make-topicmap-association
                                                         :id "r2" :type :r2
                                                         :from "point-b" :to
                                                         "point-c"))))
           (common-lisp-user::workspace
            (dreyeck/topicmap:make-topicmap-workspace
             common-lisp-user::projection "point-a"))
           (common-lisp-user::associations
            (dreyeck/topicmap:topicmap-projection-associations-of
             common-lisp-user::projection))
           (common-lisp-user::r1
            (find "r1" common-lisp-user::associations :key
                  #'dreyeck/topicmap:topicmap-association-id-of :test
                  #'string=))
           (common-lisp-user::r2
            (find "r2" common-lisp-user::associations :key
                  #'dreyeck/topicmap:topicmap-association-id-of :test
                  #'string=)))
      (labels ((common-lisp-user::association-types ()
                 (mapcar #'dreyeck/topicmap:topicmap-association-type-of
                         (dreyeck/topicmap::topicmap-associations-of-point
                          common-lisp-user::workspace))))
        (assert
         (string= "point-a"
                  (dreyeck/topicmap:topicmap-workspace-point-of
                   common-lisp-user::workspace)))
        (assert (equal '(:r1) (common-lisp-user::association-types)))
        (assert
         (eq :outgoing
             (dreyeck/topicmap::topicmap-association-direction-at-point
              common-lisp-user::workspace common-lisp-user::r1)))
        (assert
         (string= "point-b"
                  (dreyeck/topicmap::topicmap-association-other-topic-id
                   common-lisp-user::workspace common-lisp-user::r1)))
        (dreyeck/topicmap:topicmap-workspace-go-to common-lisp-user::workspace
                                                   "point-b")
        (assert
         (equal '("point-a")
                (dreyeck/topicmap:topicmap-workspace-history-of
                 common-lisp-user::workspace)))
        (assert (equal '(:r1 :r2) (common-lisp-user::association-types)))
        (assert
         (eq :incoming
             (dreyeck/topicmap::topicmap-association-direction-at-point
              common-lisp-user::workspace common-lisp-user::r1)))
        (assert
         (eq :outgoing
             (dreyeck/topicmap::topicmap-association-direction-at-point
              common-lisp-user::workspace common-lisp-user::r2)))
        (assert
         (string= "point-a"
                  (dreyeck/topicmap::topicmap-association-other-topic-id
                   common-lisp-user::workspace common-lisp-user::r1)))
        (assert
         (string= "point-c"
                  (dreyeck/topicmap::topicmap-association-other-topic-id
                   common-lisp-user::workspace common-lisp-user::r2)))
        (dreyeck/topicmap:topicmap-workspace-go-to common-lisp-user::workspace
                                                   "point-c")
        (assert
         (equal '("point-b" "point-a")
                (dreyeck/topicmap:topicmap-workspace-history-of
                 common-lisp-user::workspace)))
        (assert (equal '(:r2) (common-lisp-user::association-types)))
        (assert
         (eq :incoming
             (dreyeck/topicmap::topicmap-association-direction-at-point
              common-lisp-user::workspace common-lisp-user::r2)))
        (assert
         (string= "point-b"
                  (dreyeck/topicmap::topicmap-association-other-topic-id
                   common-lisp-user::workspace common-lisp-user::r2)))
        (dreyeck/topicmap:topicmap-workspace-go-to common-lisp-user::workspace
                                                   (dreyeck/topicmap::topicmap-association-other-topic-id
                                                    common-lisp-user::workspace
                                                    common-lisp-user::r2))
        (assert
         (string= "point-b"
                  (dreyeck/topicmap:topicmap-workspace-point-of
                   common-lisp-user::workspace)))
        (assert
         (equal '("point-c" "point-b" "point-a")
                (dreyeck/topicmap:topicmap-workspace-history-of
                 common-lisp-user::workspace)))
        (let* ((common-lisp-user::view
                (dreyeck/inspector/topicmap::👀topicmap
                 common-lisp-user::workspace))
               (common-lisp-user::html
                (html-inspector-views:view-html common-lisp-user::view)))
          (assert (search "Point" common-lisp-user::html))
          (assert (search "Associations" common-lisp-user::html))
          (assert
           (search "dreyeck-topicmap-workspace-association"
                   common-lisp-user::html))
          (assert (search "R1" common-lisp-user::html))
          (assert (search "R2" common-lisp-user::html)))
        (list :status :passed :point
              (dreyeck/topicmap:topicmap-workspace-point-of
               common-lisp-user::workspace)
              :history
              (dreyeck/topicmap:topicmap-workspace-history-of
               common-lisp-user::workspace)
              :association-types (common-lisp-user::association-types))))))

(defun run-topicmap-workspace-for-object-test ()
  (block run-topicmap-workspace-for-object-test
    (let* ((common-lisp-user::projection
            (dreyeck/topicmap:make-topicmap-projection :source
                                                       :workspace-for-object-test
                                                       :topics
                                                       (list
                                                        (dreyeck/topicmap:make-topicmap-topic
                                                         :id "first" :type
                                                         :test :label "First"
                                                         :object :first
                                                         :view-properties
                                                         '(:visible t)))
                                                       :associations nil))
           (common-lisp-user::workspace
            (dreyeck/topicmap::make-topicmap-workspace-for-object
             common-lisp-user::projection)))
      (assert
       (typep common-lisp-user::workspace
              'dreyeck/topicmap:topicmap-workspace))
      (assert
       (string= "first"
                (dreyeck/topicmap:topicmap-workspace-point-of
                 common-lisp-user::workspace)))
      (assert
       (string= "First"
                (dreyeck/topicmap:topicmap-topic-label-of
                 (dreyeck/topicmap:topicmap-workspace-current-topic
                  common-lisp-user::workspace))))
      (assert
       (eq common-lisp-user::workspace
           (dreyeck/topicmap::make-topicmap-workspace-for-object
            common-lisp-user::workspace)))
      (list :status :passed :point
            (dreyeck/topicmap:topicmap-workspace-point-of
             common-lisp-user::workspace)
            :current-label
            (dreyeck/topicmap:topicmap-topic-label-of
             (dreyeck/topicmap:topicmap-workspace-current-topic
              common-lisp-user::workspace))))))

(defun run-topicmap-workspace-point-relative-viewbox-test ()
  (block run-topicmap-workspace-point-relative-viewbox-test
    (let* ((common-lisp-user::target (list :point-relative-viewbox))
           (common-lisp-user::fixture
            (make-instance 'topicmap-fixture :target common-lisp-user::target))
           (common-lisp-user::projection
            (dreyeck/topicmap:topicmap-projection-of
             common-lisp-user::fixture))
           (common-lisp-user::topics
            (dreyeck/topicmap:topicmap-projection-topics-of
             common-lisp-user::projection))
           (common-lisp-user::initial-id
            (dreyeck/topicmap:topicmap-topic-id-of
             (first common-lisp-user::topics)))
           (common-lisp-user::next-id
            (dreyeck/topicmap:topicmap-topic-id-of
             (second common-lisp-user::topics)))
           (common-lisp-user::workspace
            (dreyeck/topicmap:make-topicmap-workspace
             common-lisp-user::projection common-lisp-user::initial-id)))
      (multiple-value-bind (common-lisp-user::x common-lisp-user::y)
          (dreyeck/inspector/topicmap::topicmap-projection-viewbox-origin
           common-lisp-user::projection)
        (check (and (= 0 common-lisp-user::x) (= 0 common-lisp-user::y))
               "Projection without a point does not retain the original viewBox origin."))
      (check
       (null
        (member :point
                (dreyeck/topicmap:topicmap-projection-view-properties-of
                 common-lisp-user::projection)
                :test #'eq))
       "Base projection unexpectedly acquired a point.")
      (let* ((common-lisp-user::workspace-projection
              (dreyeck/topicmap:topicmap-projection-of
               common-lisp-user::workspace))
             (common-lisp-user::initial-html
              (html-inspector-views:view-html
               (dreyeck/inspector/topicmap::👀topicmap
                common-lisp-user::workspace))))
        (multiple-value-bind (common-lisp-user::x common-lisp-user::y)
            (dreyeck/inspector/topicmap::topicmap-projection-viewbox-origin
             common-lisp-user::workspace-projection)
          (check (and (= -155 common-lisp-user::x) (= -20 common-lisp-user::y))
                 "Initial workspace point does not determine the expected viewBox origin."))
        (check
         (search "viewBox='-155 -20 560 160'" common-lisp-user::initial-html)
         "Initial workspace point is not centered by the rendered SVG viewBox.")
        (check
         (eq
          (dreyeck/topicmap:topicmap-projection-topics-of
           common-lisp-user::projection)
          (dreyeck/topicmap:topicmap-projection-topics-of
           common-lisp-user::workspace-projection))
         "Workspace point-relative presentation replaced the projection topics.")
        (check
         (eq
          (dreyeck/topicmap:topicmap-projection-associations-of
           common-lisp-user::projection)
          (dreyeck/topicmap:topicmap-projection-associations-of
           common-lisp-user::workspace-projection))
         "Workspace point-relative presentation replaced the projection associations."))
      (dreyeck/topicmap:topicmap-workspace-go-to common-lisp-user::workspace
                                                 common-lisp-user::next-id)
      (let* ((common-lisp-user::workspace-projection
              (dreyeck/topicmap:topicmap-projection-of
               common-lisp-user::workspace))
             (common-lisp-user::moved-html
              (html-inspector-views:view-html
               (dreyeck/inspector/topicmap::👀topicmap
                common-lisp-user::workspace))))
        (multiple-value-bind (common-lisp-user::x common-lisp-user::y)
            (dreyeck/inspector/topicmap::topicmap-projection-viewbox-origin
             common-lisp-user::workspace-projection)
          (check (and (= 125 common-lisp-user::x) (= -20 common-lisp-user::y))
                 "Moved workspace point does not determine the expected viewBox origin."))
        (check
         (search "viewBox='125 -20 560 160'" common-lisp-user::moved-html)
         "Moved workspace point is not centered by the rendered SVG viewBox.")
        (check
         (string= common-lisp-user::next-id
                  (dreyeck/topicmap:topicmap-workspace-point-of
                   common-lisp-user::workspace))
         "Point-relative rendering test did not retain the navigated workspace point.")
        (check
         (eq
          (dreyeck/topicmap:topicmap-projection-topics-of
           common-lisp-user::projection)
          (dreyeck/topicmap:topicmap-projection-topics-of
           common-lisp-user::workspace-projection))
         "Navigation changed topic identity while changing the point of view.")
        (check
         (eq
          (dreyeck/topicmap:topicmap-projection-associations-of
           common-lisp-user::projection)
          (dreyeck/topicmap:topicmap-projection-associations-of
           common-lisp-user::workspace-projection))
         "Navigation changed association identity while changing the point of view."))
      t)))

(defun run-topicmap-workspace-resource-get-test ()
  (let* ((path "/workspace/topics/point-b")
         (topic-a
          (dreyeck/topicmap:make-topicmap-topic :id "point-a" :type :test
                                                :label "A" :object :a
                                                :view-properties
                                                '(:visible t)))
         (topic-b
          (dreyeck/topicmap:make-topicmap-topic :id "point-b" :type :test
                                                :label "B" :object :b
                                                :view-properties
                                                (list :visible t :path path)))
         (projection
          (dreyeck/topicmap:make-topicmap-projection :source :resource-get-test
                                                     :topics
                                                     (list topic-a topic-b)
                                                     :associations
                                                     (list
                                                      (dreyeck/topicmap:make-topicmap-association
                                                       :id "r1" :type :r1 :from
                                                       "point-a" :to
                                                       "point-b"))))
         (workspace
          (dreyeck/topicmap:make-topicmap-workspace projection "point-a"))
         (point-before
          (dreyeck/topicmap:topicmap-workspace-point-of workspace))
         (history-before
          (copy-list
           (dreyeck/topicmap:topicmap-workspace-history-of workspace)))
         (view (view-named "Topicmap" workspace))
         (html (and view (html-inspector-views:view-html view)))
         (action-references
          (and view
               (remove-if-not
                (lambda (reference)
                  (and (stringp (car reference))
                       (uiop/utility:string-prefix-p "action-" (car reference))
                       (search
                        (format nil
                                "id='~A' class='dreyeck-topicmap-workspace-action "
                                (car reference))
                        html :test #'char-equal)))
                (html-inspector-views:view-references view)))))
    (labels ((occurrences (needle)
               (loop with start = 0
                     for position = (search needle html :start2 start :test
                                            #'char-equal)
                     while position
                     collect position
                     do (setf start (+ position (length needle))))))
      (check view "Resource-GET workspace has no Topicmap view.")
      (check html "Resource-GET workspace rendered no HTML.")
      (check (= 2 (length (occurrences path)))
             "Resource path is not present in both topic and association navigation.")
      (check (= 2 (length (occurrences "RESOURCE-GET")))
             "Expected exactly two Resource-GET presentations.")
      (check
       (search "data-topic-id='point-a' data-presentation='WORKSPACE-GO-TO'"
               html :test #'char-equal)
       "Pathless topic lost its Workspace go-to action.")
      (check
       (null
        (search "data-topic-id='point-b' data-presentation='WORKSPACE-GO-TO'"
                html :test #'char-equal))
       "Addressed topic still exposes Workspace go-to.")
      (check (= 1 (length action-references))
             "Expected exactly one remaining Inspector action.")
      (check
       (every
        (lambda (reference)
          (typep (cdr reference) 'html-inspector-views:thunk))
        action-references)
       "Remaining Inspector action is not a thunk.")
      (check
       (equal point-before
              (dreyeck/topicmap:topicmap-workspace-point-of workspace))
       "Rendering changed the workspace point.")
      (check
       (equal history-before
              (dreyeck/topicmap:topicmap-workspace-history-of workspace))
       "Rendering changed workspace history.")
      t)))

(defun run-topicmap-view-smoke-tests ()
  (check-ownership-contract)
  (run-generic-topicmap-view-test)
  (run-topicmap-workspace-test)
  (run-topicmap-workspace-inspector-action-test)
  (run-topicmap-workspace-association-navigation-test)
  (run-topicmap-workspace-point-relative-viewbox-test)
  (run-topicmap-workspace-for-object-test)
  (run-topicmap-workspace-snapshot-test)
  (run-endpoint-validation-test)
  (format t "Generic renderer-independent Topicmap view tests passed.~%")
  (run-semantic-topicmap-presentation-smoke-test)
  (run-semantic-topicmap-endpoint-role-smoke-test)
  (run-topicmap-workspace-resource-get-test)
  t)
