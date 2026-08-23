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
      (dreyeck/topicmap:topicmap-topic-view-properties-of topic)
      :visible
      t))
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

(DEFUN %RENDER-NATIVE-TOPICMAP-SUBJECT-SIGN (TOPIC STREAM)
  (MULTIPLE-VALUE-BIND (X Y)
      (TOPICMAP-TOPIC-POSITION TOPIC)
    (LET ((PROPERTIES
           (DREYECK/TOPICMAP:TOPICMAP-TOPIC-VIEW-PROPERTIES-OF TOPIC)))
      (FORMAT STREAM
              "<g class='dreyeck-topicmap-topic' data-topic-id='~A' data-topic-type='~A' data-temporal-scope='~A' data-pinned='~:[false~;true~]'><rect x='~D' y='~D' width='210' height='60' rx='8'></rect><text x='~D' y='~D'>~A</text><text class='dreyeck-topicmap-topic-kind' x='~D' y='~D'>~A · ~A</text></g>"
              (TOPICMAP-HTML-ESCAPE
               (DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF TOPIC))
              (TOPICMAP-HTML-ESCAPE
               (DREYECK/TOPICMAP:TOPICMAP-TOPIC-TYPE-OF TOPIC))
              (TOPICMAP-HTML-ESCAPE
               (DREYECK/TOPICMAP:TOPICMAP-TOPIC-TEMPORAL-SCOPE-OF TOPIC))
              (TOPICMAP-PROPERTY PROPERTIES :PINNED NIL) X Y (+ X 12) (+ Y 24)
              (TOPICMAP-HTML-ESCAPE
               (DREYECK/TOPICMAP:TOPICMAP-TOPIC-LABEL-OF TOPIC))
              (+ X 12) (+ Y 46)
              (TOPICMAP-HTML-ESCAPE
               (DREYECK/TOPICMAP:TOPICMAP-TOPIC-TYPE-OF TOPIC))
              (TOPICMAP-HTML-ESCAPE
               (DREYECK/TOPICMAP:TOPICMAP-TOPIC-TEMPORAL-SCOPE-OF TOPIC))))))

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

(DEFUN %RENDER-NATIVE-TOPICMAP-TOPIC-SIGN (PROJECTION TOPIC STREAM)
  (%RENDER-NATIVE-TOPICMAP-SUBJECT-SIGN TOPIC STREAM)
  (WHEN (%TOPICMAP-POINT-TOPIC-P PROJECTION TOPIC)
    (%RENDER-NATIVE-TOPICMAP-POINT-SIGN TOPIC STREAM)))

(DEFUN RENDER-NATIVE-TOPICMAP-SVG (PROJECTION STREAM)
  (LET* ((PROPERTIES
          (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-VIEW-PROPERTIES-OF PROJECTION))
         (WIDTH (TOPICMAP-PROPERTY PROPERTIES :WIDTH 1200))
         (HEIGHT (TOPICMAP-PROPERTY PROPERTIES :HEIGHT 720))
         (VISIBLE-TOPICS (TOPICMAP-VISIBLE-TOPICS PROJECTION))
         (STRUCTURAL-CONTAINER-IDS
          (%STRUCTURAL-CONTAINER-TOPIC-IDS PROJECTION)))
    (FORMAT STREAM
            "<svg class='dreyeck-topicmap-canvas' viewBox='0 0 ~D ~D' role='img' aria-label='Topicmap'>"
            WIDTH HEIGHT)
    (WRITE-STRING
     "<defs><marker id='dreyeck-topicmap-arrow' markerWidth='10' markerHeight='7' refX='9' refY='3.5' orient='auto'><polygon points='0 0, 10 3.5, 0 7'></polygon></marker></defs>"
     STREAM)
    (DOLIST
        (ASSOCIATION
         (DREYECK/TOPICMAP:TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION))
      (CASE (%TOPICMAP-ASSOCIATION-PRESENTATION-OF ASSOCIATION)
        (:STRUCTURAL-CONTAINMENT
         (%RENDER-NATIVE-TOPICMAP-STRUCTURAL-CONTAINMENT-SIGN PROJECTION
                                                              ASSOCIATION
                                                              STREAM))
        (OTHERWISE
         (%RENDER-NATIVE-TOPICMAP-RELATION-SIGN PROJECTION ASSOCIATION
                                                STREAM))))
    (DOLIST (TOPIC VISIBLE-TOPICS)
      (UNLESS
          (MEMBER (DREYECK/TOPICMAP:TOPICMAP-TOPIC-ID-OF TOPIC)
                  STRUCTURAL-CONTAINER-IDS :TEST #'EQUAL)
        (%RENDER-NATIVE-TOPICMAP-TOPIC-SIGN PROJECTION TOPIC STREAM)))
    (WRITE-STRING "</svg>" STREAM)))
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
