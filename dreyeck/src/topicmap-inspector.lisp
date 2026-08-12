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

(defun render-native-topicmap-svg (projection stream)
  (let* ((properties
           (dreyeck/topicmap:topicmap-projection-view-properties-of projection))
         (width (topicmap-property properties :width 1200))
         (height (topicmap-property properties :height 720)))
    (format stream
            "<svg class='dreyeck-topicmap-canvas' viewBox='0 0 ~D ~D' role='img' aria-label='Topicmap'>"
            width height)
    (write-string
     "<defs><marker id='dreyeck-topicmap-arrow' markerWidth='10' markerHeight='7' refX='9' refY='3.5' orient='auto'><polygon points='0 0, 10 3.5, 0 7'></polygon></marker></defs>"
     stream)
    (dolist
        (association
          (dreyeck/topicmap:topicmap-projection-associations-of projection))
      (let ((from
              (topicmap-topic-by-id
               projection
               (dreyeck/topicmap:topicmap-association-from-of association)))
            (to
              (topicmap-topic-by-id
               projection
               (dreyeck/topicmap:topicmap-association-to-of association))))
        (when (and from to
                   (member from (topicmap-visible-topics projection))
                   (member to (topicmap-visible-topics projection)))
          (multiple-value-bind (from-x from-y)
              (topicmap-topic-position from)
            (multiple-value-bind (to-x to-y)
                (topicmap-topic-position to)
              (let ((x1 (+ from-x 105))
                    (y1 (+ from-y 30))
                    (x2 (+ to-x 105))
                    (y2 (+ to-y 30)))
                (format stream
                        "<g class='dreyeck-topicmap-association' data-association-id='~A' data-association-type='~A'><line x1='~D' y1='~D' x2='~D' y2='~D' marker-end='url(#dreyeck-topicmap-arrow)'></line><text x='~D' y='~D'>~A</text></g>"
                        (topicmap-html-escape
                         (dreyeck/topicmap:topicmap-association-id-of association))
                        (topicmap-html-escape
                         (dreyeck/topicmap:topicmap-association-type-of association))
                        x1 y1 x2 y2
                        (round (/ (+ x1 x2) 2))
                        (- (round (/ (+ y1 y2) 2)) 6)
                        (topicmap-html-escape
                         (dreyeck/topicmap:topicmap-association-type-of association)))))))))
    (dolist (topic (topicmap-visible-topics projection))
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
                  (topicmap-property properties :pinned nil)
                  x y (+ x 12) (+ y 24)
                  (topicmap-html-escape
                   (dreyeck/topicmap:topicmap-topic-label-of topic))
                  (+ x 12) (+ y 46)
                  (topicmap-html-escape
                   (dreyeck/topicmap:topicmap-topic-type-of topic))
                  (topicmap-html-escape
                   (dreyeck/topicmap:topicmap-topic-temporal-scope-of topic))))))
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
