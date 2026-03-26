;;;; Narrow chunk-driven slice for The Life Cycle of Collective Knowledge
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *the-life-cycle-of-collective-knowledge-source-asset*
  "assets/The Life Cycle of Collective Knowledge.html")

(defparameter *the-life-cycle-of-collective-knowledge-topic-asset*
  "assets/the-life-cycle-of-collective-knowledge-topic.lisp")

(defparameter *the-life-cycle-of-collective-knowledge-page-path*
  "hyperdoc/The Life Cycle of Collective Knowledge.html")

(defparameter *the-life-cycle-of-collective-knowledge-json-script-id*
  "hyperdoc-topic-chunks")

(defclass collective-knowledge-chunk ()
  ((id :initarg :id :reader id-of)
   (title :initarg :title :reader title-of)
   (summary :initarg :summary :reader summary-of)
   (source-path :initarg :source-path
                :initform nil
                :reader source-path-of)
   (references :initarg :references
               :initform nil
               :reader references-of)))

(defclass source-asset-chunk (collective-knowledge-chunk)
  ((fedwiki-slug :initarg :fedwiki-slug :reader fedwiki-slug-of)
   (fedwiki-title :initarg :fedwiki-title :reader fedwiki-title-of)
   (fedwiki-url :initarg :fedwiki-url :reader fedwiki-url-of)
   (claim :initarg :claim :reader claim-of)
   (umbrella-topic-spec :initarg :umbrella-topic-spec
                        :reader umbrella-topic-spec-of)
   (subtopic-specs :initarg :subtopic-specs :reader subtopic-specs-of)
   (raw-asset :initarg :raw-asset :reader raw-asset-of)))

(defclass topic-definition-chunk (collective-knowledge-chunk)
  ((snippet-id :initarg :snippet-id :reader snippet-id-of)
   (snippet-text :initarg :snippet-text :reader snippet-text-of)
   (source-asset-file :initarg :source-asset-file
                      :reader source-asset-file-of)
   (related-hyperdoc-page-title :initarg :related-hyperdoc-page-title
                                :reader related-hyperdoc-page-title-of)
   (related-topic-id :initarg :related-topic-id
                     :reader related-topic-id-of)
   (related-topic-ids :initarg :related-topic-ids
                      :reader related-topic-ids-of)
   (provenance :initarg :provenance :reader provenance-of)))

(defclass subtopic-chunk (collective-knowledge-chunk)
  ((body :initarg :body :reader body-of)
   (topic-kind :initarg :topic-kind
               :initform :subtopic
               :reader topic-kind-of)
   (page-title :initarg :page-title :reader page-title-of)))

(defclass topic-page-chunk (collective-knowledge-chunk)
  ((page-path :initarg :page-path :reader page-path-of)
   (page-html :initarg :page-html :reader page-html-of)
   (composed-from :initarg :composed-from :reader composed-from-of)))

(defclass dmx-snippet-chunk (collective-knowledge-chunk)
  ((snippet-id :initarg :snippet-id :reader snippet-id-of)
   (snippet-uri :initarg :snippet-uri :reader snippet-uri-of)
   (snippet-text :initarg :snippet-text :reader snippet-text-of)
   (related-hyperdoc-page-title :initarg :related-hyperdoc-page-title
                                :reader related-hyperdoc-page-title-of)
   (related-topic-id :initarg :related-topic-id
                     :reader related-topic-id-of)
   (related-topic-ids :initarg :related-topic-ids
                      :reader related-topic-ids-of)
   (provenance :initarg :provenance :reader provenance-of)))

(defmethod print-object ((chunk collective-knowledge-chunk) stream)
  (print-unreadable-object (chunk stream :type t)
    (format stream "~A" (title-of chunk))))

(defun the-life-cycle-of-collective-knowledge-source-asset-path ()
  (asdf:system-relative-pathname :hyperdoc
                                 *the-life-cycle-of-collective-knowledge-source-asset*))

(defun the-life-cycle-of-collective-knowledge-topic-asset-path ()
  (asdf:system-relative-pathname :hyperdoc
                                 *the-life-cycle-of-collective-knowledge-topic-asset*))

(defun the-life-cycle-of-collective-knowledge-page-pathname ()
  (asdf:system-relative-pathname :hyperdoc
                                 *the-life-cycle-of-collective-knowledge-page-path*))

(defun absolute-pathname-string (path)
  (namestring (uiop:ensure-pathname path)))

(defun read-utf8-file-string (path)
  (uiop:read-file-string path))

(defun write-utf8-file-string (path content &key (if-exists :supersede))
  (uiop:ensure-all-directories-exist (list path))
  (with-open-file (stream path
                          :direction :output
                          :if-exists if-exists
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string content stream))
  path)

(defun string-between-markers (string start-marker end-marker &key (start 0))
  (let ((start-pos (search start-marker string :start2 start :test #'char=)))
    (unless start-pos
      (error "Missing marker ~S in source asset." start-marker))
    (let* ((content-start (+ start-pos (length start-marker)))
           (end-pos (search end-marker string :start2 content-start :test #'char=)))
      (unless end-pos
        (error "Missing marker ~S in source asset." end-marker))
      (subseq string content-start end-pos))))

(defun extract-json-script-body (html script-id)
  (string-between-markers
   html
   (format nil "<script type=\"application/json\" id=\"~A\">" script-id)
   "</script>"))

(defun json-array-elements (value)
  (cond
    ((null value) nil)
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t
     (error "Expected JSON array, got ~S" value))))

(defun json-string-list (value)
  (mapcar (lambda (item)
            (or item ""))
          (json-array-elements value)))

(defun the-life-cycle-of-collective-knowledge-source-metadata ()
  (let* ((html (read-utf8-file-string
                (the-life-cycle-of-collective-knowledge-source-asset-path)))
         (json (extract-json-script-body
                html
                *the-life-cycle-of-collective-knowledge-json-script-id*)))
    (shasht:read-json json)))

(defun the-life-cycle-of-collective-knowledge-source-asset-chunk ()
  (let* ((metadata (the-life-cycle-of-collective-knowledge-source-metadata))
         (source-path (absolute-pathname-string
                       (the-life-cycle-of-collective-knowledge-source-asset-path))))
    (make-instance 'source-asset-chunk
                   :id "the-life-cycle-of-collective-knowledge-source-asset"
                   :title "The Life Cycle of Collective Knowledge source asset"
                   :summary (gethash "pageSummary" metadata)
                   :source-path source-path
                   :references (list (gethash "sourceFedwikiUrl" metadata))
                   :fedwiki-slug (gethash "sourceFedwikiSlug" metadata)
                   :fedwiki-title (gethash "sourceFedwikiTitle" metadata)
                   :fedwiki-url (gethash "sourceFedwikiUrl" metadata)
                   :claim (gethash "claim" metadata)
                   :umbrella-topic-spec (gethash "umbrellaTopic" metadata)
                   :subtopic-specs (json-array-elements (gethash "subtopics" metadata))
                   :raw-asset (read-utf8-file-string
                               (the-life-cycle-of-collective-knowledge-source-asset-path)))))

(defun the-life-cycle-topic-hash->chunk (topic-hash &key topic-kind)
  (make-instance 'subtopic-chunk
                 :id (gethash "id" topic-hash)
                 :title (gethash "title" topic-hash)
                 :summary (gethash "summary" topic-hash)
                 :source-path (absolute-pathname-string
                               (the-life-cycle-of-collective-knowledge-source-asset-path))
                 :references (json-string-list (gethash "references" topic-hash))
                 :body (gethash "body" topic-hash)
                 :topic-kind topic-kind
                 :page-title "The Life Cycle of Collective Knowledge"))

(defun the-life-cycle-of-collective-knowledge-umbrella-topic-chunk ()
  (the-life-cycle-topic-hash->chunk
   (umbrella-topic-spec-of
    (the-life-cycle-of-collective-knowledge-source-asset-chunk))
   :topic-kind :umbrella))

(defun the-life-cycle-of-collective-knowledge-subtopic-chunks ()
  (mapcar (lambda (topic-hash)
            (the-life-cycle-topic-hash->chunk topic-hash :topic-kind :subtopic))
          (subtopic-specs-of
           (the-life-cycle-of-collective-knowledge-source-asset-chunk))))

(defun the-life-cycle-of-collective-knowledge-topic-chunks ()
  (cons (the-life-cycle-of-collective-knowledge-umbrella-topic-chunk)
        (the-life-cycle-of-collective-knowledge-subtopic-chunks)))

(defun find-the-life-cycle-of-collective-knowledge-topic-chunk (topic-id
                                                                &key signal-error?)
  (or (find topic-id
            (the-life-cycle-of-collective-knowledge-topic-chunks)
            :key #'id-of
            :test #'equal)
      (and signal-error?
           (error "Unknown The Life Cycle of Collective Knowledge topic id ~S."
                  topic-id))))

(defun the-life-cycle-of-collective-knowledge-topic-factory-metadata ()
  (labels ((default-metadata ()
             (list :id "the-life-cycle-of-collective-knowledge-topic-set"
                   :source-file *the-life-cycle-of-collective-knowledge-topic-asset*
                   :source-asset-file
                   *the-life-cycle-of-collective-knowledge-source-asset*
                   :related-hyperdoc-page-title
                   "The Life Cycle of Collective Knowledge"
                   :related-topic-id "the-life-cycle-of-collective-knowledge"
                   :related-topic-ids
                   (mapcar #'id-of
                           (the-life-cycle-of-collective-knowledge-topic-chunks))
                   :provenance
                   (list :source-kind "localhost-fedwiki-page"
                         :source-fedwiki-slug
                         "the-life-cycle-of-collective-knowledge"
                         :source-fedwiki-url
                         "https://hyperdoc.wiki.khinsen.net/view/the-life-cycle-of-collective-knowledge"
                         :note
                         "Dry-run-first DMX snippet twin for authored HyperDoc topic factories."))))
    (let ((path (the-life-cycle-of-collective-knowledge-topic-asset-path)))
      (if (uiop:file-exists-p path)
          (with-open-file (stream path
                                  :direction :input
                                  :external-format :utf-8)
            (let ((form (read stream nil nil)))
              (unless (and (consp form)
                           (eq (first form) :topic-factory-snippet))
                (error "Topic-factory asset must start with a :topic-factory-snippet plist."))
              (rest form)))
          (default-metadata)))))

(defun make-the-life-cycle-of-collective-knowledge-dmx-snippet-uri (snippet-id)
  (format nil "hyperdoc:topic-factory-snippet/~A" snippet-id))

(defun the-life-cycle-of-collective-knowledge-topic-definition-chunk ()
  (let* ((metadata (the-life-cycle-of-collective-knowledge-topic-factory-metadata))
         (snippet-path (the-life-cycle-of-collective-knowledge-topic-asset-path)))
    (make-instance 'topic-definition-chunk
                   :id (getf metadata :id)
                   :title "The Life Cycle of Collective Knowledge topic-definition chunk"
                   :summary "Topic-factory snippet bundle for the authored The Life Cycle of Collective Knowledge topic set."
                   :source-path (absolute-pathname-string snippet-path)
                   :references (list *the-life-cycle-of-collective-knowledge-source-asset*
                                     *the-life-cycle-of-collective-knowledge-page-path*)
                   :snippet-id (getf metadata :id)
                   :snippet-text (if (uiop:file-exists-p snippet-path)
                                     (read-utf8-file-string snippet-path)
                                     "")
                   :source-asset-file (getf metadata :source-asset-file)
                   :related-hyperdoc-page-title (getf metadata :related-hyperdoc-page-title)
                   :related-topic-id (getf metadata :related-topic-id)
                   :related-topic-ids (copy-list (getf metadata :related-topic-ids))
                   :provenance (copy-tree (getf metadata :provenance)))))

(defun the-life-cycle-of-collective-knowledge-dmx-snippet-chunk ()
  (let ((definition (the-life-cycle-of-collective-knowledge-topic-definition-chunk)))
    (make-instance 'dmx-snippet-chunk
                   :id (format nil "~A-dmx" (snippet-id-of definition))
                   :title "The Life Cycle of Collective Knowledge DMX snippet chunk"
                   :summary "DMX twin/snippet chunk for the topic-factory bundle, kept separate from the authored HyperDoc page."
                   :source-path (source-path-of definition)
                   :references (list (related-hyperdoc-page-title-of definition)
                                     "DMX FedWiki Write Model"
                                     "Runtime write live-proof gate")
                   :snippet-id (snippet-id-of definition)
                   :snippet-uri (make-the-life-cycle-of-collective-knowledge-dmx-snippet-uri
                                 (snippet-id-of definition))
                   :snippet-text (snippet-text-of definition)
                   :related-hyperdoc-page-title
                   (related-hyperdoc-page-title-of definition)
                   :related-topic-id (related-topic-id-of definition)
                   :related-topic-ids (copy-list (related-topic-ids-of definition))
                   :provenance (copy-tree (provenance-of definition)))))

(defun the-life-cycle-topic-factory-symbol-name (topic-id)
  (format nil "~A-TOPIC" (string-upcase topic-id)))

(defun render-the-life-cycle-topic-factory-form (chunk)
  (with-output-to-string (stream)
    (format stream "(defun ~A ()~%  (make-topic~%   :id ~S~%   :title ~S~%   :summary ~S~%   :references '~S))"
            (the-life-cycle-topic-factory-symbol-name (id-of chunk))
            (id-of chunk)
            (title-of chunk)
            (summary-of chunk)
            (references-of chunk))))

(defun render-the-life-cycle-of-collective-knowledge-topic-factory-snippet ()
  (let* ((definition (the-life-cycle-of-collective-knowledge-topic-definition-chunk))
         (metadata
           (list :topic-factory-snippet
                 :id (snippet-id-of definition)
                 :source-file *the-life-cycle-of-collective-knowledge-topic-asset*
                 :source-asset-file (source-asset-file-of definition)
                 :related-hyperdoc-page-title
                 (related-hyperdoc-page-title-of definition)
                 :related-topic-id (related-topic-id-of definition)
                 :related-topic-ids (related-topic-ids-of definition)
                 :provenance (provenance-of definition)))
         (topic-forms
           (mapcar #'render-the-life-cycle-topic-factory-form
                   (the-life-cycle-of-collective-knowledge-topic-chunks))))
    (with-output-to-string (stream)
      (pprint metadata stream)
      (terpri stream)
      (terpri stream)
      (format stream ";; Topic-factory snippet bundle for The Life Cycle of Collective Knowledge.~%~%")
      (loop for form in topic-forms
            for first? = t then nil
            do (unless first?
                 (terpri stream)
                 (terpri stream))
               (write-string form stream))
      (terpri stream))))

(defun render-the-life-cycle-topic-list-item (chunk)
  (format nil
          "  <li><a hyperbook=\"topics\" page=\"~A\"><tt>~A</tt></a>: ~A</li>"
          (title-of chunk)
          (title-of chunk)
          (summary-of chunk)))

(defun render-the-life-cycle-of-collective-knowledge-page ()
  (let* ((source (the-life-cycle-of-collective-knowledge-source-asset-chunk))
         (umbrella (the-life-cycle-of-collective-knowledge-umbrella-topic-chunk))
         (subtopics (the-life-cycle-of-collective-knowledge-subtopic-chunks))
         (definition (the-life-cycle-of-collective-knowledge-topic-definition-chunk))
         (dmx-snippet (the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)))
    (with-output-to-string (stream)
      (format stream "<h1>The Life Cycle of Collective Knowledge</h1>~%~%")
      (format stream "<in-package>hyperdoc</in-package>~%~%")
      (format stream "<p>~%")
      (format stream "  This authored HyperDoc page is composed from the local source asset~%")
      (format stream "  <tt>~A</tt> and the separate topic-factory snippet asset~%"
              *the-life-cycle-of-collective-knowledge-source-asset*)
      (format stream "  <tt>~A</tt>.~%" *the-life-cycle-of-collective-knowledge-topic-asset*)
      (format stream "</p>~%~%")
      (format stream "<p>~%")
      (format stream "  The local composition path stays usable without DMX. The DMX writer is a~%")
      (format stream "  separate, explicit, dry-run-first twin path for the snippet bundle, not a~%")
      (format stream "  live proxy for this authored page.~%")
      (format stream "</p>~%~%")
      (format stream "<h2>Source claim</h2>~%~%")
      (format stream "<p>~%  ~A~% </p>~%~%" (claim-of source))
      (format stream "<p>~%  ~A~% </p>~%~%" (body-of umbrella))
      (format stream "<h2>Reusable topic chunks</h2>~%~%")
      (format stream "<ul>~%")
      (format stream "~A~%" (render-the-life-cycle-topic-list-item umbrella))
      (dolist (chunk subtopics)
        (format stream "~A~%" (render-the-life-cycle-topic-list-item chunk)))
      (format stream "</ul>~%~%")
      (format stream "<h2>Local composition path</h2>~%~%")
      (format stream "<p>~%")
      (format stream "  The page composition remains local: the source asset is parsed into topic-shaped~%")
      (format stream "  chunks, the topic-factory snippet stays as a separate authored asset, and this~%")
      (format stream "  page is rendered from those chunks without depending on a DMX lookup or write.~%")
      (format stream "</p>~%~%")
      (format stream "<ul>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-source-asset-chunk)\"><tt>Source asset chunk</tt></a></li>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-topic-definition-chunk)\"><tt>Topic-definition chunk</tt></a></li>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-subtopic-chunks)\"><tt>Subtopic chunks</tt></a></li>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-topic-page-chunk)\"><tt>Topic-page chunk</tt></a></li>~%")
      (format stream "</ul>~%~%")
      (format stream "<h2>DMX snippet twin</h2>~%~%")
      (format stream "<p>~%")
      (format stream "  The DMX twin/snippet chunk writes the topic-factory bundle under the stable URI~%")
      (format stream "  <tt>~A</tt>. It carries snippet text, source-file provenance, the~%"
              (snippet-uri-of dmx-snippet))
      (format stream "  related HyperDoc page title, and the related umbrella topic id <tt>~A</tt>.~%"
              (related-topic-id-of definition))
      (format stream "</p>~%~%")
      (format stream "<ul>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)\"><tt>DMX twin/snippet chunk</tt></a></li>~%")
      (format stream "  <li><a page=\"DMX FedWiki Write Model\">DMX FedWiki Write Model</a></li>~%")
      (format stream "  <li><a hyperbook=\"topics\" page=\"Runtime write live-proof gate\"><tt>Runtime write live-proof gate</tt></a></li>~%")
      (format stream "</ul>~%~%")
      (format stream "<h2>FedWiki source</h2>~%~%")
      (format stream "<p>~%")
      (format stream "  Source FedWiki slug: <tt>~A</tt>. Source page title: <tt>~A</tt>.~%"
              (fedwiki-slug-of source)
              (fedwiki-title-of source))
      (format stream "</p>~%~%")
      (format stream "<p>~%")
      (format stream "  External source URL: <a href=\"~A\"><tt>~A</tt></a>.~%"
              (fedwiki-url-of source)
              (fedwiki-url-of source))
      (format stream "</p>~%~%")
      (format stream "<h2>Inspectable objects</h2>~%~%")
      (format stream "<ul>~%")
      (format stream "~A~%" (render-the-life-cycle-topic-list-item umbrella))
      (dolist (chunk subtopics)
        (format stream "~A~%" (render-the-life-cycle-topic-list-item chunk)))
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-topic-definition-chunk)\"><tt>~A</tt></a></li>~%"
              (title-of definition))
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)\"><tt>~A</tt></a></li>~%"
              (title-of dmx-snippet))
      (format stream "</ul>~%"))))

(defun the-life-cycle-of-collective-knowledge-topic-page-chunk ()
  (make-instance 'topic-page-chunk
                 :id "the-life-cycle-of-collective-knowledge-topic-page"
                 :title "The Life Cycle of Collective Knowledge topic-page chunk"
                 :summary "Composed HyperDoc page chunk for The Life Cycle of Collective Knowledge."
                 :source-path (absolute-pathname-string
                               (the-life-cycle-of-collective-knowledge-page-pathname))
                 :references '("The Life Cycle of Collective Knowledge")
                 :page-path *the-life-cycle-of-collective-knowledge-page-path*
                 :page-html (render-the-life-cycle-of-collective-knowledge-page)
                 :composed-from
                 (list *the-life-cycle-of-collective-knowledge-source-asset*
                       *the-life-cycle-of-collective-knowledge-topic-asset*)))

(defun parse-the-life-cycle-of-collective-knowledge-chunks ()
  (list :source-asset (the-life-cycle-of-collective-knowledge-source-asset-chunk)
        :topic-definition (the-life-cycle-of-collective-knowledge-topic-definition-chunk)
        :umbrella-topic (the-life-cycle-of-collective-knowledge-umbrella-topic-chunk)
        :subtopics (the-life-cycle-of-collective-knowledge-subtopic-chunks)
        :topic-page (the-life-cycle-of-collective-knowledge-topic-page-chunk)
        :dmx-snippet (the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)))

(defun write-the-life-cycle-of-collective-knowledge-artifacts ()
  (let ((snippet-path (the-life-cycle-of-collective-knowledge-topic-asset-path))
        (page-path (the-life-cycle-of-collective-knowledge-page-pathname)))
    (write-utf8-file-string snippet-path
                            (render-the-life-cycle-of-collective-knowledge-topic-factory-snippet))
    (write-utf8-file-string page-path
                            (render-the-life-cycle-of-collective-knowledge-page))
    (list :topic-asset (absolute-pathname-string snippet-path)
          :page (absolute-pathname-string page-path))))
