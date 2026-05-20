;;;; Native generic topicmap projection IR and DM6 inline-island renderer.

(in-package :hyperdoc)

(%defgeneric-unless-present topics-of (object))
(%defgeneric-unless-present relations-of (object))
(%defgeneric-unless-present layout-of (object))
(%defgeneric-unless-present kind-of (object))
(%defgeneric-unless-present source-index-of (object))
(%defgeneric-unless-present source-of (object))
(%defgeneric-unless-present from-of (object))
(%defgeneric-unless-present to-of (object))
(%defgeneric-unless-present evidence-of (object))
(%defgeneric-unless-present projection-of (object))
(%defgeneric-unless-present selected-topic-of (object))
(%defgeneric-unless-present input-owner-of (object))
(%defgeneric-unless-present capabilities-of (object))
(%defgeneric-unless-present topicmap-projection-of (object)
  (:documentation "Return a meaningful native topicmap projection for OBJECT, or NIL."))
(%defgeneric-unless-present topicmap-view-title-of (object))
(%defgeneric-unless-present topicmap-view-input-owner-of (object))

(defclass parsed-topic ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (kind :initarg :kind :initform :content :reader kind-of)
   (content :initarg :content :initform "" :reader content-of)
   (source-target :initarg :source-target :reader source-target-of)
   (source-index :initarg :source-index :initform nil :reader source-index-of)))

(defclass parsed-relation ()
  ((from :initarg :from :reader from-of)
   (to :initarg :to :reader to-of)
   (kind :initarg :kind :initform :derived-from :reader kind-of)
   (evidence :initarg :evidence :initform nil :reader evidence-of)))

(defclass topicmap-projection ()
  ((source :initarg :source :reader source-of)
   (topics :initarg :topics :initform nil :reader topics-of)
   (relations :initarg :relations :initform nil :reader relations-of)
   (layout :initarg :layout :initform nil :reader layout-of)))

(defclass inline-topicmap-view ()
  ((projection :initarg :projection :reader projection-of)
   (mode :initarg :mode :initform :select :reader mode-of)
   (input-owner :initarg :input-owner
                :initform "content projection"
                :reader input-owner-of)
   (selected-topic :initarg :selected-topic
                   :initform nil
                   :reader selected-topic-of)
   (capabilities :initarg :capabilities
                 :initform '(:select :move :cross :fit :reset :evidence)
                 :reader capabilities-of)))

(defun topicmap-projection-trim (string)
  (string-trim '(#\Space #\Tab #\Newline #\Return) (or string "")))

(defun topicmap-projection-blank-line-p (line)
  (string= "" (topicmap-projection-trim line)))

(defun topicmap-projection-lines (string)
  (with-input-from-string (stream (or string ""))
    (loop for line = (read-line stream nil nil)
          while line
          collect line)))

(defun topicmap-projection-slug (string)
  (let* ((text (string-downcase (topicmap-projection-trim string)))
         (chars
           (loop for char across text
                 collect (cond
                           ((or (alphanumericp char) (char= char #\-))
                            char)
                           ((find char " _/:.,")
                            #\-)
                           (t nil)))))
    (let ((slug (coerce (remove nil chars) 'string)))
      (if (string= slug "") "untitled" slug))))

(defun topicmap-projection-short-text (string &key (limit 96))
  (let ((text (topicmap-projection-trim string)))
    (if (> (length text) limit)
        (concatenate 'string (subseq text 0 (max 0 (- limit 3))) "...")
        text)))

(defun topicmap-projection-html-escape (value)
  (let ((text (format nil "~A" value)))
    (with-output-to-string (stream)
      (loop for char across text
            do (write-string
                (case char
                  (#\< "&lt;")
                  (#\> "&gt;")
                  (#\& "&amp;")
                  (#\" "&quot;")
                  (t (string char)))
                stream)))))

(defun topicmap-projection-source-label (target)
  (cond
    ((pathnamep target) (namestring target))
    ((stringp target) target)
    (t (princ-to-string target))))

(defun topicmap-projection-heading-title (line)
  (let ((trimmed (topicmap-projection-trim line)))
    (cond
      ((and (> (length trimmed) 0)
            (char= (char trimmed 0) #\#))
       (topicmap-projection-trim
        (string-left-trim '(#\# #\Space #\Tab) trimmed)))
      ((and (search "<h1" trimmed :test #'char-equal)
            (search "</h1>" trimmed :test #'char-equal))
       (subseq trimmed
               (1+ (or (position #\> trimmed) 0))
               (search "</h1>" trimmed :test #'char-equal)))
      ((and (search "<h2" trimmed :test #'char-equal)
            (search "</h2>" trimmed :test #'char-equal))
       (subseq trimmed
               (1+ (or (position #\> trimmed) 0))
               (search "</h2>" trimmed :test #'char-equal)))
      ((and (search "<h3" trimmed :test #'char-equal)
            (search "</h3>" trimmed :test #'char-equal))
       (subseq trimmed
               (1+ (or (position #\> trimmed) 0))
               (search "</h3>" trimmed :test #'char-equal)))
      (t nil))))

(defun make-parsed-topic-id (title index)
  (format nil "~A-~D" (topicmap-projection-slug title) index))

(defun parse-source-content-into-topics (source)
  (let ((topics nil)
        (current-title nil)
        (current-lines nil)
        (index 0))
    (labels ((flush-topic ()
               (when (or current-title
                         (some (lambda (line)
                                 (not (topicmap-projection-blank-line-p line)))
                               current-lines))
                 (incf index)
                 (let* ((title (or current-title
                                   (format nil "Content chunk ~D" index)))
                        (content (format nil "~{~A~%~}"
                                         (nreverse current-lines))))
                   (push
                    (make-instance 'parsed-topic
                                   :id (make-parsed-topic-id title index)
                                   :title title
                                   :kind (if current-title :section :content)
                                   :content (topicmap-projection-trim content)
                                   :source-target (source-target-of source)
                                   :source-index index)
                    topics)))
               (setf current-title nil
                     current-lines nil)))
      (dolist (line (topicmap-projection-lines (source-text-of source)))
        (let ((heading (topicmap-projection-heading-title line)))
          (cond
            (heading
             (flush-topic)
             (setf current-title (topicmap-projection-trim heading)))
            ((topicmap-projection-blank-line-p line)
             (when current-lines
               (push "" current-lines)))
            (t
             (push line current-lines)))))
      (flush-topic))
    (nreverse topics)))

(defun topic-links-to-source-relation (source topic)
  (make-instance 'parsed-relation
                 :from (id-of topic)
                 :to (topicmap-projection-source-label (source-target-of source))
                 :kind :derived-from
                 :evidence (source-title-of source)))

(defun make-derived-source-relations (source topics)
  (mapcar (lambda (topic)
            (topic-links-to-source-relation source topic))
          topics))

(defun make-inline-topicmap-layout (topics)
  (loop for topic in topics
        for i from 0
        for column = (mod i 3)
        for row = (floor i 3)
        collect (cons (id-of topic)
                      (list :x (+ 120 (* column 280))
                            :y (+ 110 (* row 120))))))

(defun project-source-content-to-topicmap (source)
  (let* ((topics (parse-source-content-into-topics source)))
    (when topics
      (make-instance 'topicmap-projection
                     :source source
                     :topics topics
                     :relations (make-derived-source-relations source topics)
                     :layout (make-inline-topicmap-layout topics)))))

(defun project-artifact-to-topicmap (artifact-or-name &key root)
  (let ((artifact (ensure-file-artifact artifact-or-name :root root)))
    (topicmap-projection-of artifact)))

(defmethod topicmap-projection-of ((object t))
  nil)

(defmethod topicmap-projection-of ((projection topicmap-projection))
  projection)

(defmethod topicmap-projection-of ((view inline-topicmap-view))
  (projection-of view))

(defmethod topicmap-projection-of ((source source-content))
  (project-source-content-to-topicmap source))

(defmethod topicmap-projection-of ((artifact file-artifact))
  (when (exists-p artifact)
    (topicmap-projection-of (source-content-from-artifact artifact))))

(defmethod topicmap-projection-of ((pathname pathname))
  (when (and pathname (uiop:file-exists-p pathname))
    (topicmap-projection-of (source-content-from-pathname pathname))))

(defmethod topicmap-projection-of ((topic parsed-topic))
  (let* ((source (source-content-from-object
                  topic
                  :title (title-of topic)
                  :text (content-of topic))))
    (make-instance 'topicmap-projection
                   :source source
                   :topics (list topic)
                   :relations (make-derived-source-relations source (list topic))
                   :layout (make-inline-topicmap-layout (list topic)))))

(defmethod topicmap-view-title-of ((object t))
  (format nil "Topic Map: ~A" (type-of object)))

(defmethod topicmap-view-title-of ((artifact file-artifact))
  (format nil "Topic Map: ~A" (title-of artifact)))

(defmethod topicmap-view-title-of ((pathname pathname))
  (format nil "Topic Map: ~A" (file-namestring pathname)))

(defmethod topicmap-view-title-of ((projection topicmap-projection))
  (format nil "Topic Map: ~A"
          (source-title-of (source-of projection))))

(defmethod topicmap-view-input-owner-of ((object t))
  (princ-to-string (type-of object)))

(defmethod topicmap-view-input-owner-of ((artifact file-artifact))
  (title-of artifact))

(defmethod topicmap-view-input-owner-of ((pathname pathname))
  (namestring pathname))

(defmethod topicmap-view-input-owner-of ((projection topicmap-projection))
  "content projection")

(defun project-object-to-topicmap (object)
  (topicmap-projection-of object))

(defun make-inline-topicmap-view (projection &key (mode :select)
                                               (input-owner "content projection")
                                               selected-topic
                                               capabilities)
  (make-instance 'inline-topicmap-view
                 :projection projection
                 :mode mode
                 :input-owner input-owner
                 :selected-topic selected-topic
                 :capabilities (or capabilities
                                   '(:select :move :cross :fit :reset :evidence))))

(defun topicmap-projection-json-array (items)
  (coerce items 'vector))

(defun topicmap-projection-size-object (width height)
  `(("w" . ,width)
    ("h" . ,height)))

(defun topicmap-projection-topic-width (label)
  (min 320 (max 140 (+ 48 (* 7 (min (length label) 36))))))

(defun topicmap-projection-topic-label (topic)
  (format nil "~A: ~A"
          (string-downcase (symbol-name (kind-of topic)))
          (topicmap-projection-short-text (title-of topic) :limit 72)))

(defun topicmap-projection-topic-object (id label assoc-ids &key (icon "circle"))
  (let* ((width (if (zerop id)
                    0
                    (topicmap-projection-topic-width label)))
         (height (if (zerop id) 0 42))
         (size `(("view" . ,(topicmap-projection-size-object width height))
                 ("editor" . ,(topicmap-projection-size-object width height)))))
    `(("id" . ,id)
      ("icon" . ,icon)
      ("text" . ,label)
      ("size" . ,size)
      ("assocIds" . ,(topicmap-projection-json-array assoc-ids)))))

(defun topicmap-projection-assoc-object (id parent-id child-id)
  `(("id" . ,id)
    ("type" . "Hierarchy")
    ("topicId1" . ,parent-id)
    ("topicId2" . ,child-id)))

(defun topicmap-projection-item-object (topic-id)
  `(("topicId" . ,topic-id)))

(defun topicmap-projection-box-topic-object (topic-id)
  `(("id" . ,topic-id)
    ("expansion" . "Collapsed")))

(defun topicmap-projection-layout-for-topic (projection topic)
  (or (cdr (assoc (id-of topic) (layout-of projection) :test #'equal))
      '(:x 120 :y 110)))

(defun topicmap-projection-layout-value (layout key &optional (default 0))
  (let ((tail (member key layout)))
    (if tail (second tail) default)))

(defun topicmap-projection-position-object (projection numeric-id topic)
  (let ((layout (topicmap-projection-layout-for-topic projection topic)))
    `(("id" . ,numeric-id)
      ("pos" . (("x" . ,(topicmap-projection-layout-value layout :x 120))
                ("y" . ,(topicmap-projection-layout-value layout :y 110)))))))

(defun topicmap-projection-canvas-size (projection)
  (let ((max-x 1400)
        (max-y 900))
    (dolist (topic (topics-of projection))
      (let* ((layout (topicmap-projection-layout-for-topic projection topic))
             (x (topicmap-projection-layout-value layout :x 120))
             (y (topicmap-projection-layout-value layout :y 110)))
        (setf max-x (max max-x (+ x 360))
              max-y (max max-y (+ y 180)))))
    (values max-x max-y)))

(defun topicmap-projection-native-model (projection)
  (let* ((projection-topics (topics-of projection))
         (topic-count (1+ (length projection-topics)))
         (first-assoc-id topic-count)
         (assoc-ids-by-topic (make-hash-table))
         (assocs
           (loop for topic in projection-topics
                 for topic-id from 1
                 for assoc-id from first-assoc-id
                 do (push assoc-id (gethash 0 assoc-ids-by-topic))
                    (push assoc-id (gethash topic-id assoc-ids-by-topic))
                 collect (topicmap-projection-assoc-object assoc-id 0 topic-id)))
         (visible-topic-ids (loop for topic in projection-topics
                                  for topic-id from 1
                                  collect topic-id))
         (root-assoc-ids (sort (copy-list (gethash 0 assoc-ids-by-topic)) #'<))
         (topics
           (cons
            (topicmap-projection-topic-object
             0
             (format nil "projection: ~A"
                     (source-title-of (source-of projection)))
             root-assoc-ids
             :icon "")
            (loop for topic in projection-topics
                  for topic-id from 1
                  for assoc-ids = (sort (copy-list
                                          (gethash topic-id assoc-ids-by-topic))
                                         #'<)
                  collect (topicmap-projection-topic-object
                           topic-id
                           (topicmap-projection-topic-label topic)
                           assoc-ids)))))
    (multiple-value-bind (canvas-width canvas-height)
        (topicmap-projection-canvas-size projection)
      (let ((max-id (max (1- topic-count)
                         (if assocs
                             (cdr (assoc "id" (alexandria:lastcar assocs)
                                         :test #'string=))
                             0))))
        `(("topics" . ,(topicmap-projection-json-array topics))
          ("assocs" . ,(topicmap-projection-json-array assocs))
          ("itemSets" . ,(topicmap-projection-json-array
                          (list `(("id" . 1)
                                  ("items" . ,(topicmap-projection-json-array
                                               (mapcar #'topicmap-projection-item-object
                                                       visible-topic-ids)))))))
          ("boxes" . ,(topicmap-projection-json-array
                       (list `(("id" . 0)
                               ("itemSetId" . 1)
                               ("topics" . ,(topicmap-projection-json-array
                                             (mapcar #'topicmap-projection-box-topic-object
                                                     visible-topic-ids)))
                               ("renderer" . "TopicMap")))))
          ("boxId" . 0)
          ("nextId" . ,(1+ max-id))
          ("topicMap" . (("viewProps" . ,(topicmap-projection-json-array
                                          (list
                                           `(("id" . 0)
                                             ("rect" . (("x1" . 0)
                                                        ("y1" . 0)
                                                        ("x2" . ,canvas-width)
                                                        ("y2" . ,canvas-height)))
                                             ("scroll" . (("x" . 0)
                                                          ("y" . 0)))
                                             ("topics" . ,(topicmap-projection-json-array
                                                           (loop for topic in projection-topics
                                                                 for topic-id from 1
                                                                 collect (topicmap-projection-position-object
                                                                          projection
                                                                          topic-id
                                                                          topic))))))))))
          ("topicList" . (("viewProps" . ,(topicmap-projection-json-array
                                           (list
                                            `(("id" . 0)
                                              ("order" . ,(topicmap-projection-json-array
                                                           visible-topic-ids))
                                              ("size" . (("w" . ,canvas-width)
                                                         ("h" . ,canvas-height)))))))))
          ("tool" . (("lineStyle" . "Cornered"))))))))

(defun topicmap-projection-json (projection)
  (with-output-to-string (stream)
    (let ((shasht:*write-alist-as-object* t))
      (shasht:write-json (topicmap-projection-native-model projection) stream))))

(defun topicmap-projection-asset-url (asset-prefix name)
  (format nil "~A~A"
          (if (and (> (length asset-prefix) 0)
                   (char= (char asset-prefix (1- (length asset-prefix))) #\/))
              asset-prefix
              (concatenate 'string asset-prefix "/"))
          name))

(defun render-dm6-inline-topicmap-island-html
    (projection &key (slug "native-topicmap-projection")
                     (title nil)
                     (asset-prefix "/assets/dm6-elm/")
                     (include-assets-p t))
  (let* ((title (or title
                    (format nil "~A Topic Map"
                            (source-title-of (source-of projection)))))
         (bundle-url (topicmap-projection-asset-url asset-prefix "app.js"))
         (css-url (topicmap-projection-asset-url asset-prefix
                                                 "hyperdoc-dm6-inline.css"))
         (js-url (topicmap-projection-asset-url asset-prefix
                                                "hyperdoc-dm6-inline.js"))
         (json (topicmap-projection-json projection)))
    (with-output-to-string (stream)
      (when include-assets-p
        (format stream "<link rel='stylesheet' href='~A'>~%" css-url))
      (format stream
              "<section class='dm6-hyperdoc-map dm6-island' data-dm6-slug='~A' data-dm6-bundle='~A'>~%"
              (topicmap-projection-html-escape slug)
              (topicmap-projection-html-escape bundle-url))
      (format stream
              "<header class='dm6-island-header'><div class='dm6-island-title'><h2>~A</h2><span class='dm6-island-subtitle'>Native topicmap projection rendered through the DM6 AppEmbed island contract</span></div>~%"
              (topicmap-projection-html-escape title))
      (write-string
       "<nav class='dm6-toolbar' aria-label='dm6 controls'><button type='button' data-dm6-action='select'>Select</button><button type='button' data-dm6-action='move'>Move</button><button type='button' data-dm6-action='cross'>Cross</button><button type='button' data-dm6-action='fit'>Fit</button><button type='button' data-dm6-action='reset'>Reset</button><button type='button' data-dm6-action='evidence'>Evidence</button></nav></header>"
       stream)
      (write-string
       "<div class='dm6-mode-banner'><span><b>Input owner:</b> <span class='dm6-input-owner'>page</span></span><span><b>Mode:</b> <span class='dm6-mode'>select</span></span><span><b>HyperDoc:</b> <span class='dm6-hyperdoc-state'>HyperDoc overlays active outside embedded app</span></span></div>"
       stream)
      (write-string
       "<div class='dm6-canvas'><div class='dm6-stage'>dm6 AppEmbed mount pending...</div></div>"
       stream)
      (write-string
       "<div class='dm6-success-card'><div><strong class='dm6-mount-summary'>dm6 mounting...</strong><br>Projection data is supplied as native AppEmbed stored JSON.</div><div><b>Status:</b> <span class='dm6-status'>not mounted</span></div></div>"
       stream)
      (write-string
       "<details class='dm6-evidence-drawer'><summary>Evidence timeline: <span class='dm6-evidence-count'>0</span> events - last: <span class='dm6-evidence-last'>none</span></summary><div class='dm6-evidence-panel'><div class='dm6-evidence-actions'><button type='button' data-dm6-evidence-copy>Copy JSON</button><button type='button' data-dm6-evidence-clear>Clear</button><button type='button' data-dm6-evidence-download>Download</button></div><h3>Evidence summary</h3><pre class='dm6-evidence-summary'>{}</pre><h3>Raw events</h3><pre class='dm6-evidence'></pre></div></details>"
       stream)
      (format stream
              "<script type='application/json' class='dm6-stored' data-dm6-generated='native-topicmap-projection-v1'>~%~A~%</script>~%"
              json)
      (write-string "</section>" stream)
      (when include-assets-p
        (format stream
                "~%<script src='~A'></script><script>window.hyperdocDm6Inline&&window.hyperdocDm6Inline.mountAll(document);</script>"
                js-url)))))

(defun render-inline-topicmap-projection-html (projection &key (asset-prefix "/assets/dm6-elm/")
                                                            (include-assets-p t)
                                                            title slug)
  (render-dm6-inline-topicmap-island-html
   projection
   :asset-prefix asset-prefix
   :include-assets-p include-assets-p
   :title title
   :slug (or slug "native-topicmap-projection")))

(defun render-inline-topicmap-view-html (view &key (asset-prefix "/assets/dm6-elm/")
                                                   (include-assets-p t))
  (render-inline-topicmap-projection-html
   (projection-of view)
   :asset-prefix asset-prefix
   :include-assets-p include-assets-p))

(defun render-topicmap-view-of-object-html
    (object &key (asset-prefix "/assets/dm6-elm/") (include-assets-p t))
  (let ((projection (topicmap-projection-of object)))
    (when projection
      (render-inline-topicmap-projection-html
       projection
       :asset-prefix asset-prefix
       :include-assets-p include-assets-p
       :title (topicmap-view-title-of object)
       :slug (topicmap-projection-slug (topicmap-view-input-owner-of object))))))

(defun write-topicmap-view-html (object pathname &key (if-exists :supersede))
  (let ((html (render-topicmap-view-of-object-html object)))
    (unless html
      (error "No meaningful topicmap projection for ~S." object))
    (with-open-file (stream pathname
                            :direction :output
                            :if-exists if-exists
                            :if-does-not-exist :create
                            :external-format :utf-8)
      (write-string html stream)))
  pathname)
