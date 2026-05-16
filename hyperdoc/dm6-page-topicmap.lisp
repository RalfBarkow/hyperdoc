;;;; DM6 page-local topicmap seed generation.
;;;;
;;;; This file is loaded by hyperdoc/explorer because it depends on the
;;;; concrete Plump-backed page classes and inspector view packages.

(in-package :hyperdoc)

(defparameter *page-dm6-topicmap-generated-marker*
  "page-parse-tree-v1")

(defparameter *page-dm6-topicmap-kept-tags*
  '("h1" "h2" "h3" "h4" "h5" "h6"
    "p" "ul" "ol" "li" "pre" "code" "blockquote"
    "table" "tr" "th" "td"
    "section" "article" "header" "nav" "details" "summary"
    "a" "in-package" "value-of" "html-expr" "html-generator"
    "view-transclusion" "source-of-function" "source-of-class"))

(defparameter *page-dm6-topicmap-dangerous-tags*
  '("script" "style"))

(defstruct page-dm6-topicmap-entry
  id
  node
  parent-id
  label
  depth
  preorder)

(defclass dm6-page-topicmap-seed-report ()
  ((source-page :reader dm6-page-topicmap-seed-report-source-page-of
                :initarg :source-page
                :initform nil)
   (source-file :reader dm6-page-topicmap-seed-report-source-file-of
                :initarg :source-file
                :initform nil)
   (kept-node-count :reader dm6-page-topicmap-seed-report-kept-node-count-of
                    :initarg :kept-node-count
                    :initform 0)
   (skipped-node-count :reader dm6-page-topicmap-seed-report-skipped-node-count-of
                       :initarg :skipped-node-count
                       :initform 0)
   (topic-count :reader dm6-page-topicmap-seed-report-topic-count-of
                :initarg :topic-count
                :initform 0)
   (assoc-count :reader dm6-page-topicmap-seed-report-assoc-count-of
                :initarg :assoc-count
                :initform 0)
   (json-byte-count :reader dm6-page-topicmap-seed-report-json-byte-count-of
                    :initarg :json-byte-count
                    :initform 0)
   (first-labels :reader dm6-page-topicmap-seed-report-first-labels-of
                 :initarg :first-labels
                 :initform nil)
   (script-action :reader dm6-page-topicmap-seed-report-script-action-of
                  :initarg :script-action
                  :initform :not-materialized)
   (warnings :reader dm6-page-topicmap-seed-report-warnings-of
             :initarg :warnings
             :initform nil)
   (json :reader dm6-page-topicmap-seed-report-json-of
         :initarg :json
         :initform nil)))

(defmethod print-object ((report dm6-page-topicmap-seed-report) stream)
  (print-unreadable-object (report stream :type t :identity nil)
    (format stream "~D topics, ~D assocs"
            (dm6-page-topicmap-seed-report-topic-count-of report)
            (dm6-page-topicmap-seed-report-assoc-count-of report))))

(defmethod views:text-representation ((report dm6-page-topicmap-seed-report))
  (format nil "DM6 page topicmap seed: ~D topics"
          (dm6-page-topicmap-seed-report-topic-count-of report)))

(defmethod views:title-bar-representation ((report dm6-page-topicmap-seed-report))
  "DM6 page topicmap seed")

(defun page-dm6-topicmap-source-dom (page)
  "Return PAGE's loaded Plump DOM, using HyperDoc's page loader as authority."
  (unless (dom-of page)
    (load-page page))
  (dom-of page))

(defun page-dm6-topicmap-pathname-dom (pathname)
  (let ((plump:*tag-dispatchers* plump:*html-tags*))
    (plump:parse pathname)))

(defun page-dm6-topicmap-vector-list (vector)
  (loop for item across vector collect item))

(defun page-dm6-topicmap-normalize-space (text)
  (let ((raw (string-trim '(#\Space #\Tab #\Newline #\Return)
                          (or text ""))))
    (with-output-to-string (out)
      (loop with emitted? = nil
            with pending-space? = nil
            for char across raw
            do (cond
                 ((find char '(#\Space #\Tab #\Newline #\Return #\Page))
                  (setf pending-space? t))
                 (t
                  (when (and pending-space? emitted?)
                    (write-char #\Space out))
                  (write-char char out)
                  (setf emitted? t
                        pending-space? nil)))))))

(defun page-dm6-topicmap-compact-text (text &key (limit 96))
  (let ((normalized (page-dm6-topicmap-normalize-space text)))
    (if (> (length normalized) limit)
        (concatenate 'string (subseq normalized 0 (- limit 3)) "...")
        normalized)))

(defun page-dm6-topicmap-class-list (element)
  (let ((class (and (typep element 'plump:element)
                    (plump:get-attribute element "class"))))
    (when class
      (remove ""
              (uiop:split-string class :separator '(#\Space #\Tab #\Newline #\Return))
              :test #'string=))))

(defun page-dm6-topicmap-element-class-p (element class-name)
  (member class-name
          (page-dm6-topicmap-class-list element)
          :test #'string=))

(defun page-dm6-topicmap-generated-seed-script-p (element)
  (and (typep element 'plump:element)
       (string-equal (plump:tag-name element) "script")
       (or (page-dm6-topicmap-element-class-p element "dm6-stored")
           (plump:get-attribute element "data-dm6-generated"))))

(defun page-dm6-topicmap-dangerous-element-p (element)
  (and (typep element 'plump:element)
       (member (plump:tag-name element)
               *page-dm6-topicmap-dangerous-tags*
               :test #'string-equal)))

(defun page-dm6-topicmap-custom-tag-p (tag-name)
  (or (find #\- tag-name)
      (string-equal tag-name "in-package")))

(defun page-dm6-topicmap-kept-tag-p (tag-name)
  (or (member tag-name *page-dm6-topicmap-kept-tags* :test #'string-equal)
      (page-dm6-topicmap-custom-tag-p tag-name)))

(defun page-dm6-topicmap-element-prefix (element)
  (let* ((tag-name (plump:tag-name element))
         (classes (page-dm6-topicmap-class-list element))
         (interesting-classes
           (remove-if-not
            (lambda (class)
              (or (uiop:string-prefix-p "dm6-" class)
                  (member class '("hyperbook-page" "inspector-table")
                          :test #'string=)))
            classes)))
    (format nil "~A~{.~A~}" tag-name interesting-classes)))

(defun page-dm6-topicmap-link-target (element)
  (or (let ((hyperbook (plump:get-attribute element "hyperbook"))
            (page (plump:get-attribute element "page")))
        (and hyperbook page
             (format nil "~A/~A" hyperbook page)))
      (plump:get-attribute element "href")
      (plump:get-attribute element "expr")))

(defun page-dm6-topicmap-first-child-text (element tag-name)
  (loop for child across (plump:children element)
        when (and (typep child 'plump:element)
                  (string-equal (plump:tag-name child) tag-name))
          return (plump:text child)))

(defun page-dm6-topicmap-node-label (node)
  "Return the compact DM6 topic label for one kept Plump element, or NIL."
  (when (typep node 'plump:element)
    (let* ((tag-name (plump:tag-name node))
           (prefix (page-dm6-topicmap-element-prefix node))
           (raw-text
             (cond
               ((string-equal tag-name "details")
                (or (page-dm6-topicmap-first-child-text node "summary")
                    (plump:text node)))
               (t
                (plump:text node))))
           (text (page-dm6-topicmap-compact-text raw-text))
           (slug (or (plump:get-attribute node "data-dm6-slug")
                     (plump:get-attribute node "id"))))
      (cond
        ((not (page-dm6-topicmap-kept-tag-p tag-name))
         nil)
        ((string-equal tag-name "a")
         (let ((target (page-dm6-topicmap-link-target node)))
           (cond
             ((and (> (length text) 0) target)
              (format nil "a: ~A -> ~A" text (page-dm6-topicmap-compact-text target)))
             ((> (length text) 0)
              (format nil "a: ~A" text))
             (target
              (format nil "a: ~A" (page-dm6-topicmap-compact-text target)))
             (t nil))))
        ((and (member tag-name '("section" "article" "header" "nav" "details")
                      :test #'string-equal)
              slug)
         (format nil "~A: ~A" prefix (page-dm6-topicmap-compact-text slug)))
        ((> (length text) 0)
         (format nil "~A: ~A" prefix text))
        (slug
         (format nil "~A: ~A" prefix (page-dm6-topicmap-compact-text slug)))
        (t nil)))))

(defun page-dm6-topicmap-dom-nodes (dom &key page-title)
  "Return kept DOM entries, skipped element count, and warnings."
  (declare (ignore page-title))
  (let ((entries nil)
        (skipped-count 0)
        (warnings nil)
        (next-id 1)
        (preorder 0))
    (labels ((skip-subtree-p (node)
               (or (page-dm6-topicmap-generated-seed-script-p node)
                   (page-dm6-topicmap-dangerous-element-p node)))
             (walk (node parent-id depth)
               (cond
                 ((skip-subtree-p node)
                  (incf skipped-count))
                 ((typep node 'plump:element)
                  (let* ((label (page-dm6-topicmap-node-label node))
                         (keep? (and label (> (length label) 0)))
                         (current-parent parent-id)
                         (current-depth depth))
                    (if keep?
                        (let ((id next-id))
                          (incf next-id)
                          (incf preorder)
                          (push (make-page-dm6-topicmap-entry
                                 :id id
                                 :node node
                                 :parent-id parent-id
                                 :label label
                                 :depth depth
                                 :preorder preorder)
                                entries)
                          (setf current-parent id
                                current-depth (1+ depth)))
                        (incf skipped-count))
                    (loop for child across (plump:children node)
                          do (walk child current-parent current-depth))))
                 ((and (typep node 'plump:text-node)
                       (> (length (page-dm6-topicmap-normalize-space
                                   (plump:text node)))
                          0))
                  (incf skipped-count)))))
      (loop for child across (plump:children dom)
            do (walk child 0 1)))
    (let ((kept (nreverse entries)))
      (unless kept
        (push "No visible DOM nodes were kept for the DM6 seed." warnings))
      (values kept skipped-count (nreverse warnings)))))

(defun page-dm6-topicmap-title-from-dom (dom)
  (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
            do (let ((elements (plump:get-elements-by-tag-name dom tag)))
                 (when elements
                   (return (page-dm6-topicmap-compact-text
                            (plump:text (first elements))
                            :limit 160)))))
      "Untitled"))

(defun page-dm6-topicmap-source-title (source page-title)
  (or page-title
      (and (typep source 'page) (title-of source))
      (and (typep source 'plump:node) (page-dm6-topicmap-title-from-dom source))
      "Untitled"))

(defun page-dm6-topicmap-source-file (source source-file)
  (or source-file
      (and (typep source 'text-page) (file-of source))))

(defun page-dm6-topicmap-source->dom (source)
  (etypecase source
    (page (page-dm6-topicmap-source-dom source))
    (plump:node source)))

(defun page-dm6-topicmap-json-array (items)
  (coerce items 'vector))

(defun page-dm6-topicmap-size-object (width height)
  `(("w" . ,width)
    ("h" . ,height)))

(defun page-dm6-topicmap-topic-width (label)
  (min 320 (max 140 (+ 48 (* 7 (min (length label) 36))))))

(defun page-dm6-topicmap-topic-object (id label assoc-ids &key (icon "circle"))
  (let* ((width (if (zerop id)
                    0
                    (page-dm6-topicmap-topic-width label)))
         (height (if (zerop id) 0 42))
         (size `(("view" . ,(page-dm6-topicmap-size-object width height))
                 ("editor" . ,(page-dm6-topicmap-size-object width height)))))
    `(("id" . ,id)
      ("icon" . ,icon)
      ("text" . ,label)
      ("size" . ,size)
      ("assocIds" . ,(page-dm6-topicmap-json-array assoc-ids)))))

(defun page-dm6-topicmap-assoc-object (id parent-id child-id)
  `(("id" . ,id)
    ("type" . "Hierarchy")
    ("topicId1" . ,parent-id)
    ("topicId2" . ,child-id)))

(defun page-dm6-topicmap-item-object (topic-id)
  `(("topicId" . ,topic-id)))

(defun page-dm6-topicmap-box-topic-object (topic-id)
  `(("id" . ,topic-id)
    ("expansion" . "Collapsed")))

(defun page-dm6-topicmap-position-object (entry)
  (let ((x (+ 80 (* (max 0 (1- (page-dm6-topicmap-entry-depth entry))) 260)))
        (y (+ 80 (* (1- (page-dm6-topicmap-entry-preorder entry)) 72))))
    `(("id" . ,(page-dm6-topicmap-entry-id entry))
      ("pos" . (("x" . ,x)
                ("y" . ,y))))))

(defun page-dm6-topicmap-canvas-size (entries)
  (let ((max-x 1400)
        (max-y 900))
    (dolist (entry entries)
      (let ((x (+ 80 (* (max 0 (1- (page-dm6-topicmap-entry-depth entry))) 260)))
            (y (+ 80 (* (1- (page-dm6-topicmap-entry-preorder entry)) 72))))
        (setf max-x (max max-x (+ x 360))
              max-y (max max-y (+ y 180)))))
    (values max-x max-y)))

(defun page-dm6-topicmap-native-model (source &key page-title source-file)
  "Build the native AppEmbed model JSON value for SOURCE's Plump DOM."
  (let* ((dom (page-dm6-topicmap-source->dom source))
         (title (page-dm6-topicmap-source-title source page-title))
         (file (page-dm6-topicmap-source-file source source-file)))
    (declare (ignore file))
    (multiple-value-bind (entries skipped warnings)
        (page-dm6-topicmap-dom-nodes dom :page-title title)
      (let* ((topic-count (1+ (length entries)))
             (first-assoc-id topic-count)
             (assoc-ids-by-topic (make-hash-table))
             (assocs
               (loop for entry in entries
                     for assoc-id from first-assoc-id
                     do (push assoc-id
                              (gethash (page-dm6-topicmap-entry-parent-id entry)
                                       assoc-ids-by-topic))
                        (push assoc-id
                              (gethash (page-dm6-topicmap-entry-id entry)
                                       assoc-ids-by-topic))
                     collect (page-dm6-topicmap-assoc-object
                              assoc-id
                              (page-dm6-topicmap-entry-parent-id entry)
                              (page-dm6-topicmap-entry-id entry))))
             (visible-topic-ids (mapcar #'page-dm6-topicmap-entry-id entries))
             (root-assoc-ids (sort (copy-list (gethash 0 assoc-ids-by-topic)) #'<))
             (topics
               (cons (page-dm6-topicmap-topic-object
                      0
                      (format nil "page: ~A" title)
                      root-assoc-ids
                      :icon "")
                     (loop for entry in entries
                           for assoc-ids = (sort
                                            (copy-list
                                             (gethash
                                              (page-dm6-topicmap-entry-id entry)
                                              assoc-ids-by-topic))
                                            #'<)
                           collect (page-dm6-topicmap-topic-object
                                    (page-dm6-topicmap-entry-id entry)
                                    (page-dm6-topicmap-entry-label entry)
                                    assoc-ids)))))
        (multiple-value-bind (canvas-width canvas-height)
            (page-dm6-topicmap-canvas-size entries)
          (let* ((max-id (if assocs
                             (max (1- topic-count)
                                  (cdr (assoc "id"
                                              (alexandria:lastcar assocs)
                                              :test #'string=)))
                             (1- topic-count)))
                 (model
                   `(("topics" . ,(page-dm6-topicmap-json-array topics))
                     ("assocs" . ,(page-dm6-topicmap-json-array assocs))
                     ("itemSets" . ,(page-dm6-topicmap-json-array
                                     (list `(("id" . 1)
                                             ("items" . ,(page-dm6-topicmap-json-array
                                                          (mapcar #'page-dm6-topicmap-item-object
                                                                  visible-topic-ids)))))))
                     ("boxes" . ,(page-dm6-topicmap-json-array
                                  (list `(("id" . 0)
                                          ("itemSetId" . 1)
                                          ("topics" . ,(page-dm6-topicmap-json-array
                                                        (mapcar #'page-dm6-topicmap-box-topic-object
                                                                visible-topic-ids)))
                                          ("renderer" . "TopicMap")))))
                     ("boxId" . 0)
                     ("nextId" . ,(1+ max-id))
                     ("topicMap" . (("viewProps" . ,(page-dm6-topicmap-json-array
                                                     (list
                                                      `(("id" . 0)
                                                        ("rect" . (("x1" . 0)
                                                                   ("y1" . 0)
                                                                   ("x2" . ,canvas-width)
                                                                   ("y2" . ,canvas-height)))
                                                        ("scroll" . (("x" . 0)
                                                                     ("y" . 0)))
                                                        ("topics" . ,(page-dm6-topicmap-json-array
                                                                      (mapcar #'page-dm6-topicmap-position-object
                                                                              entries)))))))))
                     ("topicList" . (("viewProps" . ,(page-dm6-topicmap-json-array
                                                      (list
                                                       `(("id" . 0)
                                                         ("order" . ,(page-dm6-topicmap-json-array
                                                                      visible-topic-ids))
                                                         ("size" . (("w" . ,canvas-width)
                                                                    ("h" . ,canvas-height)))))))))
                     ("tool" . (("lineStyle" . "Cornered"))))))
            (values model entries skipped warnings)))))))

(defun page-dm6-topicmap-write-json (model)
  (with-output-to-string (stream)
    (let ((shasht:*write-alist-as-object* t))
      (shasht:write-json model stream))))

(defun page-dm6-topicmap-json (source &key page-title source-file)
  "Return deterministic native AppEmbed JSON and generation metadata."
  (multiple-value-bind (model entries skipped warnings)
      (page-dm6-topicmap-native-model source
                                      :page-title page-title
                                      :source-file source-file)
    (values (page-dm6-topicmap-write-json model)
            model
            entries
            skipped
            warnings)))

(defun page-dm6-topicmap-required-native-keys-present-p (model)
  (every (lambda (key) (assoc key model :test #'string=))
         '("topics" "assocs" "itemSets" "boxes" "boxId" "nextId"
           "topicMap" "topicList" "tool")))

(defun page-dm6-topicmap-script (json)
  (format nil
          "  <script type=\"application/json\" class=\"dm6-stored\" data-dm6-generated=\"~A\">~%~A~%  </script>~%"
          *page-dm6-topicmap-generated-marker*
          json))

(defun page-dm6-topicmap-tag-end (source start)
  (position #\> source :start start))

(defun page-dm6-topicmap-tag-has-token-p (tag-source token)
  (search token tag-source :test #'char-equal))

(defun page-dm6-topicmap-find-island-range (source)
  (loop with start = 0
        for section-start = (search "<section" source
                                    :start2 start
                                    :test #'char-equal)
        while section-start
        for open-end = (page-dm6-topicmap-tag-end source section-start)
        for open-tag = (and open-end (subseq source section-start (1+ open-end)))
        do (if (and open-tag
                    (page-dm6-topicmap-tag-has-token-p open-tag "dm6-hyperdoc-map")
                    (page-dm6-topicmap-tag-has-token-p open-tag "dm6-island"))
               (let ((close-start (search "</section>" source
                                          :start2 (1+ open-end)
                                          :test #'char-equal)))
                 (return (and close-start
                              (values section-start
                                      (+ close-start (length "</section>"))
                                      (1+ open-end)))))
               (setf start (if open-end (1+ open-end) (1+ section-start))))))

(defun page-dm6-topicmap-script-ranges-in (source start end)
  (let ((ranges nil)
        (cursor start))
    (loop for script-start = (search "<script" source
                                     :start2 cursor
                                     :end2 end
                                     :test #'char-equal)
          while script-start
          for open-end = (page-dm6-topicmap-tag-end source script-start)
          while (and open-end (< open-end end))
          for open-tag = (subseq source script-start (1+ open-end))
          for close-start = (search "</script>" source
                                    :start2 (1+ open-end)
                                    :end2 end
                                    :test #'char-equal)
          do (when (and close-start
                        (page-dm6-topicmap-tag-has-token-p open-tag "dm6-stored"))
               (push (cons script-start
                           (+ close-start (length "</script>")))
                     ranges))
             (setf cursor (if close-start
                              (+ close-start (length "</script>"))
                              (1+ open-end))))
    (nreverse ranges)))

(defun page-dm6-topicmap-upsert-script-in-source (source script)
  (multiple-value-bind (island-start island-end content-start)
      (page-dm6-topicmap-find-island-range source)
    (unless island-start
      (return-from page-dm6-topicmap-upsert-script-in-source
        (values source :missing-island
                '("No .dm6-hyperdoc-map.dm6-island section was found."))))
    (let ((ranges (page-dm6-topicmap-script-ranges-in
                   source content-start island-end)))
      (cond
        (ranges
         (let ((first-range (first ranges)))
           (values
            (with-output-to-string (out)
              (write-string source out :start 0 :end (car first-range))
              (write-string script out)
              (loop with cursor = (cdr first-range)
                    for range in (rest ranges)
                    do (write-string source out :start cursor :end (car range))
                       (setf cursor (cdr range))
                    finally (write-string source out :start cursor)))
            :replaced
            (and (rest ranges)
                 (list "Multiple script.dm6-stored nodes were collapsed into one generated seed.")))))
        (t
         (values
          (concatenate 'string
                       (subseq source 0 content-start)
                       (string #\Newline)
                       script
                       (subseq source content-start))
          :inserted
          nil))))))

(defun dm6-page-topicmap-build-report
    (&key source-page source-file json model entries skipped script-action warnings)
  (let ((warnings (append warnings
                          (unless (page-dm6-topicmap-required-native-keys-present-p
                                   model)
                            (list "Generated model is missing one or more native AppEmbed keys.")))))
    (make-instance 'dm6-page-topicmap-seed-report
                   :source-page source-page
                   :source-file source-file
                   :kept-node-count (length entries)
                   :skipped-node-count skipped
                   :topic-count (length (cdr (assoc "topics" model :test #'string=)))
                   :assoc-count (length (cdr (assoc "assocs" model :test #'string=)))
                   :json-byte-count (length json)
                   :first-labels (subseq (mapcar #'page-dm6-topicmap-entry-label entries)
                                         0
                                         (min 8 (length entries)))
                   :script-action script-action
                   :warnings warnings
                   :json json)))

(defun dm6-page-topicmap-seed-report (&key page pathname dom page-title)
  "Return an inspectable seed-generation report without modifying files."
  (let* ((source (or page dom (and pathname (page-dm6-topicmap-pathname-dom pathname))))
         (title (or page-title
                    (and page (title-of page))
                    (and source (typep source 'plump:node)
                         (page-dm6-topicmap-title-from-dom source))))
         (source-file (or pathname (and page (file-of page)))))
    (multiple-value-bind (json model entries skipped warnings)
        (page-dm6-topicmap-json source
                                :page-title title
                                :source-file source-file)
      (dm6-page-topicmap-build-report
       :source-page page
       :source-file source-file
       :json json
       :model model
       :entries entries
       :skipped skipped
       :script-action :not-materialized
       :warnings warnings))))

(defun insert-or-replace-dm6-stored-script! (pathname &key page-title)
  "Materialize the generated native DM6 seed inside PATHNAME's DM6 island."
  (let* ((dom (page-dm6-topicmap-pathname-dom pathname))
         (title (or page-title (page-dm6-topicmap-title-from-dom dom)))
         (source (alexandria:read-file-into-string pathname)))
    (multiple-value-bind (json model entries skipped warnings)
        (page-dm6-topicmap-json dom :page-title title :source-file pathname)
      (multiple-value-bind (new-source script-action upsert-warnings)
          (page-dm6-topicmap-upsert-script-in-source
           source
           (page-dm6-topicmap-script json))
        (when (not (eq script-action :missing-island))
          (with-open-file (stream pathname
                                  :direction :output
                                  :if-exists :supersede
                                  :if-does-not-exist :create
                                  :external-format :utf-8)
            (write-string new-source stream)))
        (dm6-page-topicmap-build-report
         :source-file pathname
         :json json
         :model model
         :entries entries
         :skipped skipped
         :script-action script-action
         :warnings (append warnings upsert-warnings))))))

(defun dm6-inline-proof-page-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/DM6 AppEmbed HyperDoc Inline Proof.html"))

(defun materialize-dm6-inline-proof-page-topicmap-seed! ()
  (insert-or-replace-dm6-stored-script!
   (dm6-inline-proof-page-pathname)
   :page-title "DM6 AppEmbed HyperDoc Inline Proof"))

(views:defview 👀summary (report dm6-page-topicmap-seed-report)
  (views:html-view
   :title "Summary"
   :priority 1
   (views:html
    (:h3 "DM6 page topicmap seed")
    (:table :class "inspector-table"
            (:tr (:th "Source page")
                 (:td (if (dm6-page-topicmap-seed-report-source-page-of report)
                          (views:object-ref
                           (dm6-page-topicmap-seed-report-source-page-of report))
                          (views:esc "none"))))
            (:tr (:th "Source file")
                 (:td (:tt (views:esc
                            (or (and (dm6-page-topicmap-seed-report-source-file-of report)
                                     (namestring
                                      (dm6-page-topicmap-seed-report-source-file-of report)))
                                "none")))))
            (:tr (:th "Kept DOM nodes")
                 (:td (:tt (views:esc
                            (format nil "~D"
                                    (dm6-page-topicmap-seed-report-kept-node-count-of
                                     report))))))
            (:tr (:th "Skipped DOM nodes")
                 (:td (:tt (views:esc
                            (format nil "~D"
                                    (dm6-page-topicmap-seed-report-skipped-node-count-of
                                     report))))))
            (:tr (:th "Topics")
                 (:td (:tt (views:esc
                            (format nil "~D"
                                    (dm6-page-topicmap-seed-report-topic-count-of
                                     report))))))
            (:tr (:th "Associations")
                 (:td (:tt (views:esc
                            (format nil "~D"
                                    (dm6-page-topicmap-seed-report-assoc-count-of
                                     report))))))
            (:tr (:th "JSON bytes")
                 (:td (:tt (views:esc
                            (format nil "~D"
                                    (dm6-page-topicmap-seed-report-json-byte-count-of
                                     report))))))
            (:tr (:th "Stored script")
                 (:td (:tt (views:esc
                            (string-downcase
                             (symbol-name
                              (dm6-page-topicmap-seed-report-script-action-of
                               report))))))))
    (:h4 "First labels")
    (if (dm6-page-topicmap-seed-report-first-labels-of report)
        (views:html
         (:ol
          (loop for label in (dm6-page-topicmap-seed-report-first-labels-of
                              report)
                do (views:html (:li (views:esc label))))))
        (views:html (:p "No labels generated.")))
    (:h4 "Warnings")
    (if (dm6-page-topicmap-seed-report-warnings-of report)
        (views:html
         (:ul
          (loop for warning in (dm6-page-topicmap-seed-report-warnings-of
                                report)
                do (views:html (:li (views:esc warning))))))
        (views:html (:p "None."))))))
