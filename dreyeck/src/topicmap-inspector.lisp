;;;; Dreyeck-owned generic native topicmap inspector view.

(in-package #:dreyeck/inspector/topicmap)

(defvar *topicmap-renderer* :native-svg
  "Renderer designator used by the generic Topicmap Inspector view.")

(defgeneric render-topicmap-html (renderer projection)
  (:documentation
   "Render PROJECTION with RENDERER without changing the projection model."))

(defun topicmap-html-escape (value)
  (let ((text (format nil "~A" value)))
    (with-output-to-string (stream)
      (loop for character across text
            do (write-string
                (case character
                  (#\& "&amp;")
                  (#\< "&lt;")
                  (#\> "&gt;")
                  (#\" "&quot;")
                  (#\' "&#39;")
                  (otherwise (string character)))
                stream)))))

(defun topicmap-property (properties key default)
  (let ((tail (member key properties)))
    (if tail (second tail) default)))



(defun topicmap-visible-topics (projection)
  (remove-if-not
   (lambda (topic)
     (topicmap-property
      (dreyeck/topicmap:topicmap-topic-view-properties-of topic) :visible t))
   (dreyeck/topicmap:topicmap-projection-topics-of projection)))

(defun topicmap-topic-position (topic)
  (let ((properties
          (dreyeck/topicmap:topicmap-topic-view-properties-of topic)))
    (values (topicmap-property properties :x 0)
            (topicmap-property properties :y 0))))

(defun topicmap-topic-by-id (projection id)
  (find id
        (dreyeck/topicmap:topicmap-projection-topics-of projection)
        :key #'dreyeck/topicmap:topicmap-topic-id-of
        :test #'string=))

(DEFUN %TOPICMAP-ASSOCIATION-PRESENTATION-OF (ASSOCIATION)
  (TOPICMAP-PROPERTY
   (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF ASSOCIATION)
   :PRESENTATION :RELATION))

(DEFUN %STRUCTURAL-CONTAINED-TOPIC-ID (ASSOCIATION)
  (ECASE
      (TOPICMAP-PROPERTY
       (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF ASSOCIATION)
       :CONTAINED-ENDPOINT :FROM)
    (:FROM (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF ASSOCIATION))
    (:TO (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF ASSOCIATION))))

(DEFUN %STRUCTURAL-CONTAINER-TOPIC-ID (ASSOCIATION)
  (ECASE
      (TOPICMAP-PROPERTY
       (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-PROPERTIES-OF ASSOCIATION)
       :CONTAINED-ENDPOINT :FROM)
    (:FROM (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF ASSOCIATION))
    (:TO (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF ASSOCIATION))))

(DEFUN %STRUCTURAL-CONTAINER-TOPIC-IDS (PROJECTION)
  (REMOVE-DUPLICATES
   (LOOP FOR ASSOCIATION IN (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF
                             PROJECTION)
         WHEN (EQ :STRUCTURAL-CONTAINMENT
                  (%TOPICMAP-ASSOCIATION-PRESENTATION-OF ASSOCIATION))
         COLLECT (%STRUCTURAL-CONTAINER-TOPIC-ID ASSOCIATION))
   :TEST #'EQUAL))

(DEFUN %RENDER-NATIVE-TOPICMAP-RELATION-SIGN (PROJECTION ASSOCIATION STREAM)
  (LET ((FROM
         (TOPICMAP-TOPIC-BY-ID PROJECTION
                               (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-FROM-OF
                                ASSOCIATION)))
        (TO
         (TOPICMAP-TOPIC-BY-ID PROJECTION
                               (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TO-OF
                                ASSOCIATION))))
    (WHEN
        (AND FROM TO (MEMBER FROM (TOPICMAP-VISIBLE-TOPICS PROJECTION))
             (MEMBER TO (TOPICMAP-VISIBLE-TOPICS PROJECTION)))
      (MULTIPLE-VALUE-BIND (FROM-X FROM-Y)
          (TOPICMAP-TOPIC-POSITION FROM)
        (MULTIPLE-VALUE-BIND (TO-X TO-Y)
            (TOPICMAP-TOPIC-POSITION TO)
          (LET ((X1 (+ FROM-X 105))
                (Y1 (+ FROM-Y 30))
                (X2 (+ TO-X 105))
                (Y2 (+ TO-Y 30)))
            (FORMAT STREAM
                    "<g class='dreyeck-topicmap-association' data-association-id='~A' data-association-type='~A' data-presentation='RELATION'><line x1='~D' y1='~D' x2='~D' y2='~D' marker-end='url(#dreyeck-topicmap-arrow)'></line><text x='~D' y='~D'>~A</text></g>"
                    (TOPICMAP-HTML-ESCAPE
                     (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF ASSOCIATION))
                    (TOPICMAP-HTML-ESCAPE
                     (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                      ASSOCIATION))
                    X1 Y1 X2 Y2 (ROUND (/ (+ X1 X2) 2))
                    (- (ROUND (/ (+ Y1 Y2) 2)) 6)
                    (TOPICMAP-HTML-ESCAPE
                     (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF
                      ASSOCIATION)))))))))

(DEFUN %RENDER-NATIVE-TOPICMAP-STRUCTURAL-CONTAINMENT-SIGN
       (PROJECTION ASSOCIATION STREAM)
  (LET ((CONTAINED
         (TOPICMAP-TOPIC-BY-ID PROJECTION
                               (%STRUCTURAL-CONTAINED-TOPIC-ID ASSOCIATION)))
        (CONTAINER
         (TOPICMAP-TOPIC-BY-ID PROJECTION
                               (%STRUCTURAL-CONTAINER-TOPIC-ID ASSOCIATION))))
    (WHEN
        (AND CONTAINED CONTAINER
             (MEMBER CONTAINED (TOPICMAP-VISIBLE-TOPICS PROJECTION))
             (MEMBER CONTAINER (TOPICMAP-VISIBLE-TOPICS PROJECTION)))
      (MULTIPLE-VALUE-BIND (X Y)
          (TOPICMAP-TOPIC-POSITION CONTAINED)
        (LET ((BOUNDARY-X (- X 30)) (BOUNDARY-Y (- Y 50)))
          (FORMAT STREAM
                  "<g class='dreyeck-topicmap-structural-containment' data-association-id='~A' data-association-type='~A' data-topic-id='~A' data-presentation='STRUCTURAL-CONTAINMENT'><rect x='~D' y='~D' width='270' height='140' rx='8' fill='none' stroke='currentColor' stroke-width='2'></rect><text x='~D' y='~D'>~A</text><text class='dreyeck-topicmap-topic-kind' x='~D' y='~D'>~A · ~A</text></g>"
                  (TOPICMAP-HTML-ESCAPE (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-ID-OF ASSOCIATION))
                  (TOPICMAP-HTML-ESCAPE
                   (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF ASSOCIATION))
                  (TOPICMAP-HTML-ESCAPE (DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF CONTAINER))
                  BOUNDARY-X BOUNDARY-Y (+ BOUNDARY-X 12) (+ BOUNDARY-Y 22)
                  (TOPICMAP-HTML-ESCAPE (DREYECK/TOPICMAP:TOPICMAP-TOPIC-LABEL-OF CONTAINER))
                  (+ BOUNDARY-X 12) (+ BOUNDARY-Y 40)
                  (TOPICMAP-HTML-ESCAPE (DREYECK/TOPICMAP:TOPICMAP-TOPIC-TYPE-OF CONTAINER))
                  (TOPICMAP-HTML-ESCAPE
                   (DREYECK/TOPICMAP:TOPICMAP-ASSOCIATION-TYPE-OF ASSOCIATION))))))))

(defun topicmap-topic-path-of (topic)
  (topicmap-property (dreyeck/topicmap:topicmap-topic-view-properties-of topic)
                     :path nil))

(defun %render-native-topicmap-subject-sign (topic stream)
  (let ((path (topicmap-topic-path-of topic)))
    (when path
      (format stream "<a href='~A' data-presentation='RESOURCE-GET'>"
              (topicmap-html-escape path)))
    (multiple-value-bind (x y)
        (topicmap-topic-position topic)
      (let ((properties
             (dreyeck/topicmap:topicmap-topic-view-properties-of topic)))
        (format stream
                "<g class='dreyeck-topicmap-topic' data-topic-id='~A' data-topic-type='~A' data-temporal-scope='~A' data-pinned='~:[false~;true~]'><rect x='~D' y='~D' width='210' height='60' rx='8'></rect><text x='~D' y='~D'>~A</text><text class='dreyeck-topicmap-topic-kind' x='~D' y='~D'>~A · ~A</text></g>"
                (topicmap-html-escape
                 (dreyeck/topicmap:topicmap-topic-id-of topic))
                (topicmap-html-escape
                 (dreyeck/topicmap:topicmap-topic-type-of topic))
                (topicmap-html-escape
                 (dreyeck/topicmap:topicmap-topic-temporal-scope-of topic))
                (topicmap-property properties :pinned nil) x y (+ x 12)
                (+ y 24)
                (topicmap-html-escape
                 (dreyeck/topicmap:topicmap-topic-label-of topic))
                (+ x 12) (+ y 46)
                (topicmap-html-escape
                 (dreyeck/topicmap:topicmap-topic-type-of topic))
                (topicmap-html-escape
                 (dreyeck/topicmap:topicmap-topic-temporal-scope-of topic)))))
    (when path (write-string "</a>" stream))))

(DEFUN %TOPICMAP-POINT-TOPIC-ID (PROJECTION)
  (TOPICMAP-PROPERTY
   (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-VIEW-PROPERTIES-OF PROJECTION) :POINT
   NIL))

(DEFUN %TOPICMAP-POINT-TOPIC-P (PROJECTION TOPIC)
  (LET ((POINT-ID (%TOPICMAP-POINT-TOPIC-ID PROJECTION)))
    (AND POINT-ID
         (EQUAL POINT-ID (DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF TOPIC)))))

(DEFUN %RENDER-NATIVE-TOPICMAP-POINT-SIGN (TOPIC STREAM)
  (MULTIPLE-VALUE-BIND (X Y)
      (TOPICMAP-TOPIC-POSITION TOPIC)
    (FORMAT STREAM
            "<g class='dreyeck-topicmap-point-sign' data-topic-id='~A' data-presentation='POINT'><rect x='~D' y='~D' width='202' height='52' rx='6' fill='none' stroke='currentColor' stroke-width='2'></rect></g>"
            (TOPICMAP-HTML-ESCAPE
             (DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF TOPIC))
            (+ X 4) (+ Y 4))))

(DEFUN TOPICMAP-WORKSPACE-TOPIC-ACTION-ID (PROJECTION TOPIC)
  (LET ((SOURCE (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-SOURCE-OF PROJECTION)))
    (WHEN (TYPEP SOURCE 'DREYECK/TOPICMAP:TOPICMAP-WORKSPACE)
      (LET ((TOPIC-ID (DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF TOPIC)))
        (VIEWS:ACTION-ID
         (VIEWS:THUNK
           (DREYECK/TOPICMAP:TOPICMAP-WORKSPACE-GO-TO SOURCE TOPIC-ID)))))))

(defun %render-native-topicmap-workspace-action-sign (projection topic stream)
  (unless (topicmap-topic-path-of topic)
    (let ((action-id (topicmap-workspace-topic-action-id projection topic)))
      (when action-id
        (multiple-value-bind (x y)
            (topicmap-topic-position topic)
          (format stream
                  "<rect id='~A' class='dreyeck-topicmap-workspace-action inspector-action' data-topic-id='~A' data-presentation='WORKSPACE-GO-TO' x='~D' y='~D' width='210' height='60' rx='8' fill='transparent' style='cursor:pointer'></rect>"
                  (topicmap-html-escape action-id)
                  (topicmap-html-escape
                   (dreyeck/topicmap:topicmap-topic-id-of topic))
                  x y))))))

(DEFUN %RENDER-NATIVE-TOPICMAP-TOPIC-SIGN (PROJECTION TOPIC STREAM)
  (%RENDER-NATIVE-TOPICMAP-SUBJECT-SIGN TOPIC STREAM)
  (WHEN (%TOPICMAP-POINT-TOPIC-P PROJECTION TOPIC)
    (%RENDER-NATIVE-TOPICMAP-POINT-SIGN TOPIC STREAM))
  (%RENDER-NATIVE-TOPICMAP-WORKSPACE-ACTION-SIGN PROJECTION TOPIC STREAM))

(defun topicmap-projection-viewbox-origin (common-lisp-user::projection)
  (block topicmap-projection-viewbox-origin
    (let* ((common-lisp-user::properties
            (dreyeck/topicmap:topicmap-projection-view-properties-of
             common-lisp-user::projection))
           (common-lisp-user::width
            (topicmap-property common-lisp-user::properties :width 1200))
           (common-lisp-user::height
            (topicmap-property common-lisp-user::properties :height 720))
           (common-lisp-user::point-id
            (topicmap-property common-lisp-user::properties :point nil))
           (common-lisp-user::point-topic
            (and common-lisp-user::point-id
                 (topicmap-topic-by-id common-lisp-user::projection
                                       common-lisp-user::point-id))))
      (if common-lisp-user::point-topic
          (multiple-value-bind (common-lisp-user::x common-lisp-user::y)
              (topicmap-topic-position common-lisp-user::point-topic)
            (values
             (- (+ common-lisp-user::x 105)
                (truncate common-lisp-user::width 2))
             (- (+ common-lisp-user::y 30)
                (truncate common-lisp-user::height 2))))
          (values 0 0)))))

(defun render-native-topicmap-svg (projection stream)
  (let* ((properties
          (dreyeck/topicmap:topicmap-projection-view-properties-of projection))
         (width (topicmap-property properties :width 1200))
         (height (topicmap-property properties :height 720))
         (visible-topics (topicmap-visible-topics projection))
         (structural-container-ids
          (%structural-container-topic-ids projection)))
    (multiple-value-bind (viewbox-x viewbox-y)
        (topicmap-projection-viewbox-origin projection)
      (format stream
              "<svg class='dreyeck-topicmap-canvas' viewBox='~D ~D ~D ~D' role='img' aria-label='Topicmap'>"
              viewbox-x viewbox-y width height))
    (write-string
     "<defs><marker id='dreyeck-topicmap-arrow' markerWidth='10' markerHeight='7' refX='9' refY='3.5' orient='auto'><polygon points='0 0, 10 3.5, 0 7'></polygon></marker></defs>"
     stream)
    (dolist
        (association
         (dreyeck/topicmap:topicmap-projection-associations-of projection))
      (case (%topicmap-association-presentation-of association)
        (:structural-containment
         (%render-native-topicmap-structural-containment-sign projection
                                                              association
                                                              stream))
        (otherwise
         (%render-native-topicmap-relation-sign projection association
                                                stream))))
    (dolist (topic visible-topics)
      (unless
          (member (dreyeck/topicmap:topicmap-topic-id-of topic)
                  structural-container-ids :test #'equal)
        (%render-native-topicmap-topic-sign projection topic stream)))
    (write-string "</svg>" stream)))

(defun render-native-topicmap-html (projection)
  "Render PROJECTION as dependency-free SVG for the CLOG inspector."
  (with-output-to-string (stream)
    (write-string
     "<style>.dreyeck-topicmap{overflow:auto}.dreyeck-topicmap-canvas{display:block;width:100%;min-width:760px;min-height:440px;border:1px solid #ccd6dd;background:#fafcfd}.dreyeck-topicmap-association line{stroke:#577184;stroke-width:2}.dreyeck-topicmap-association text{font:12px sans-serif;fill:#304b5e;text-anchor:middle}.dreyeck-topicmap-topic rect{fill:#fff;stroke:#315f7d;stroke-width:2}.dreyeck-topicmap-topic text{font:13px sans-serif;fill:#172b3a}.dreyeck-topicmap-topic-kind{font-size:11px!important;fill:#526678!important}</style><section class='dreyeck-topicmap'>"
     stream)
    (render-native-topicmap-svg projection stream)
    (write-string "</section>" stream)))

(defmethod render-topicmap-html
    ((renderer (eql :native-svg))
     (projection dreyeck/topicmap:topicmap-projection))
  (declare (ignore renderer))
  (render-native-topicmap-html projection))

(defun render-topicmap-topic-object (topic)
  (let ((object (dreyeck/topicmap:topicmap-topic-object-of topic)))
    (if object
        (views:object-ref
         object
         :display (dreyeck/topicmap:topicmap-topic-label-of topic))
        (views:html
          (:code
           (views:esc (dreyeck/topicmap:topicmap-topic-label-of topic)))))))

(defun render-topicmap-topic-row (topic)
  (views:html
    (:tr
     (:td
      (:code
       (views:esc (dreyeck/topicmap:topicmap-topic-id-of topic))))
     (:td
      (:code
       (views:esc
        (prin1-to-string (dreyeck/topicmap:topicmap-topic-type-of topic)))))
     (:td
      (:code
       (views:esc
        (prin1-to-string
         (dreyeck/topicmap:topicmap-topic-temporal-scope-of topic)))))
     (:td (render-topicmap-topic-object topic)))))

(defun render-topicmap-association-row (association)
  (views:html
    (:tr
     (:td
      (:code
       (views:esc
        (prin1-to-string
         (dreyeck/topicmap:topicmap-association-type-of association)))))
     (:td
      (:code
       (views:esc
        (dreyeck/topicmap:topicmap-association-from-of association))))
     (:td
      (:code
       (views:esc
        (dreyeck/topicmap:topicmap-association-to-of association)))))))

(defun render-topicmap-legend (projection)
  (views:html
    (:h3 (views:esc "Topics"))
    (:table :class "inspector-table"
            (:tr
             (:th (views:esc "ID"))
             (:th (views:esc "Type"))
             (:th (views:esc "Temporal scope"))
             (:th (views:esc "Inspectable object")))
            (dolist
                (topic
                  (dreyeck/topicmap:topicmap-projection-topics-of projection))
              (render-topicmap-topic-row topic)))
    (:h3 (views:esc "Typed associations"))
    (:table :class "inspector-table"
            (:tr
             (:th (views:esc "Type"))
             (:th (views:esc "From"))
             (:th (views:esc "To")))
            (dolist
                (association
                  (dreyeck/topicmap:topicmap-projection-associations-of projection))
              (render-topicmap-association-row association)))))

(views:defview 👀topicmap (object t)
  (let ((projection (dreyeck/topicmap:topicmap-projection-of object)))
    (when projection
      (views:html-view :title "Topicmap" :priority 4
        (views:html
          (views:str (render-topicmap-html *topicmap-renderer* projection))
          (render-topicmap-legend projection))))))

(defun render-topicmap-workspace-associations (projection)
  (let ((workspace (dreyeck/topicmap:topicmap-projection-source-of projection)))
    (when (typep workspace 'dreyeck/topicmap:topicmap-workspace)
      (let* ((point-topic
              (dreyeck/topicmap:topicmap-workspace-current-topic workspace))
             (associations
              (dreyeck/topicmap::topicmap-associations-of-point workspace))
             (topics
              (dreyeck/topicmap:topicmap-projection-topics-of projection)))
        (views:html
          (:h3 "Point")
          (:p
           (views:object-ref
            (dreyeck/topicmap:topicmap-topic-object-of point-topic) :display
            (dreyeck/topicmap:topicmap-topic-label-of point-topic)))
          (:h3 "Associations")
          (if associations
              (views:html
                (:table :class "inspector-table"
                 (dolist (association associations)
                   (let* ((direction
                           (dreyeck/topicmap::topicmap-association-direction-at-point
                            workspace association))
                          (other-id
                           (dreyeck/topicmap::topicmap-association-other-topic-id
                            workspace association))
                          (other-topic
                           (find other-id topics :key
                                 #'dreyeck/topicmap:topicmap-topic-id-of :test
                                 #'string=)))
                     (when other-topic
                       (let ((path (topicmap-topic-path-of other-topic)))
                         (views:html
                           (:tr :class "dreyeck-topicmap-workspace-association"
                            :data-association-id
                            (dreyeck/topicmap:topicmap-association-id-of
                             association)
                            :data-direction (symbol-name direction)
                            (:td
                             (:tt
                              (cl-who:esc
                               (princ-to-string
                                (dreyeck/topicmap:topicmap-association-type-of
                                 association)))))
                            (:td
                             (cl-who:esc
                              (if (eq direction :outgoing)
                                  "→"
                                  "←")))
                            (:td
                             (if path
                                 (views:html
                                   (:a :href path :data-presentation
                                    "RESOURCE-GET"
                                    (cl-who:esc
                                     (dreyeck/topicmap:topicmap-topic-label-of
                                      other-topic))))
                                 (views:action-button
                                  (dreyeck/topicmap:topicmap-topic-label-of
                                   other-topic)
                                  (views:thunk
                                    (dreyeck/topicmap:topicmap-workspace-go-to
                                     workspace other-id))
                                  (format nil "Go to ~A"
                                          (dreyeck/topicmap:topicmap-topic-label-of
                                           other-topic)))))))))))))
              (views:html
                (:p "No associations."))))))))

(views:defview 👀topicmap (object dreyeck/topicmap:topicmap-workspace)
               (let ((projection
                      (dreyeck/topicmap:topicmap-projection-of object)))
                 (when projection
                   (views:html-view :title "Topicmap" :priority 4
                                    (views:html
                                      (cl-who:str
                                       (render-topicmap-html
                                        *topicmap-renderer* projection))
                                      (render-topicmap-workspace-associations
                                       projection)
                                      (render-topicmap-legend projection))))))
