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

(defparameter *the-life-cycle-of-collective-knowledge-fedwiki-site*
  "wiki.ralfbarkow.ch")

(defparameter *the-life-cycle-of-collective-knowledge-fedwiki-slug*
  "the-life-cycle-of-collective-knowledge")

(defparameter *the-life-cycle-of-collective-knowledge-fedwiki-html-url*
  "https://hyperdoc.wiki.khinsen.net/view/the-life-cycle-of-collective-knowledge")

(defparameter +the-life-cycle-of-collective-knowledge-section-headings+
  '(("FedWiki source" . "fedwiki-source")
    ("Why this matters for HyperDoc" . "why-this-matters-for-hyperdoc")
    ("Claim carried by this page" . "claim-carried-by-this-page")
    ("Inspectable objects" . "inspectable-objects")
    ("Related" . "related")))

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

(defclass localhost-fedwiki-item-record ()
  ((page-id :initarg :page-id :reader fedwiki-page-id-of)
   (page-slug :initarg :page-slug :reader fedwiki-slug-of)
   (page-title :initarg :page-title :reader fedwiki-title-of)
   (page-relative-path :initarg :page-relative-path
                       :reader fedwiki-relative-path-of)
   (item-index :initarg :item-index :reader item-index-of)
   (item-id :initarg :item-id :initform nil :reader item-id-of)
   (item-type :initarg :item-type :reader item-type-of)
   (text :initarg :text :initform nil :reader text-of)
   (blocks :initarg :blocks :initform nil :reader blocks-of)
   (fragments :initarg :fragments :initform nil :reader fragments-of)
   (journal-entries :initarg :journal-entries
                    :initform nil
                    :reader journal-entries-of)
   (provenance :initarg :provenance :reader provenance-of)))

(defclass localhost-fedwiki-fragment-record ()
  ((page-id :initarg :page-id :reader fedwiki-page-id-of)
   (page-slug :initarg :page-slug :reader fedwiki-slug-of)
   (page-title :initarg :page-title :reader fedwiki-title-of)
   (page-relative-path :initarg :page-relative-path
                       :reader fedwiki-relative-path-of)
   (item-index :initarg :item-index :reader item-index-of)
   (item-id :initarg :item-id :initform nil :reader item-id-of)
   (item-type :initarg :item-type :reader item-type-of)
   (fragment-index :initarg :fragment-index :reader fragment-index-of)
   (fragment-anchor :initarg :fragment-anchor :reader fragment-anchor-of)
   (section-key :initarg :section-key :reader section-key-of)
   (section-heading :initarg :section-heading
                    :initform nil
                    :reader section-heading-of)
   (text :initarg :text :initform nil :reader text-of)
   (excerpt :initarg :excerpt :reader excerpt-of)
   (provenance :initarg :provenance :reader provenance-of)))

(defclass localhost-fedwiki-source-chunk (collective-knowledge-chunk)
  ((fedwiki-site :initarg :fedwiki-site :reader fedwiki-site-of)
   (fedwiki-page-id :initarg :fedwiki-page-id :reader fedwiki-page-id-of)
   (fedwiki-slug :initarg :fedwiki-slug :reader fedwiki-slug-of)
   (fedwiki-title :initarg :fedwiki-title :reader fedwiki-title-of)
   (fedwiki-url :initarg :fedwiki-url :reader fedwiki-url-of)
   (fedwiki-relative-path :initarg :fedwiki-relative-path
                          :reader fedwiki-relative-path-of)
   (claim :initarg :claim :reader claim-of)
   (story-items :initarg :story-items :reader story-items-of)
   (raw-page :initarg :raw-page :reader raw-page-of)
   (provenance :initarg :provenance :initform nil :reader provenance-of)))

(defclass topic-definition-chunk (collective-knowledge-chunk)
  ((snippet-id :initarg :snippet-id :reader snippet-id-of)
   (snippet-text :initarg :snippet-text :reader snippet-text-of)
   (source-origin-id :initarg :source-origin-id
                     :reader source-origin-id-of)
   (source-origin-path :initarg :source-origin-path
                       :reader source-origin-path-of)
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
   (page-title :initarg :page-title :reader page-title-of)
   (provenance :initarg :provenance :initform nil :reader provenance-of)))

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

(defun the-life-cycle-of-collective-knowledge-localhost-fedwiki-page-path ()
  (merge-pathnames *the-life-cycle-of-collective-knowledge-fedwiki-slug*
                   (article-allegation-default-fedwiki-pages-directory)))

(defun the-life-cycle-of-collective-knowledge-localhost-fedwiki-page-relative-path ()
  (format nil "pages/~A" *the-life-cycle-of-collective-knowledge-fedwiki-slug*))

(defun the-life-cycle-of-collective-knowledge-fedwiki-page-id ()
  (format nil "fedwiki:~A/~A"
          *the-life-cycle-of-collective-knowledge-fedwiki-site*
          *the-life-cycle-of-collective-knowledge-fedwiki-slug*))

(defun pathname-string-relative-to (path root)
  (let* ((pathname (uiop:ensure-pathname path))
         (relative (enough-namestring pathname
                                      (uiop:ensure-directory-pathname root))))
    (if (or (null relative)
            (string= relative ""))
        (namestring pathname)
        relative)))

(defun hyperdoc-relative-path-string (path)
  (pathname-string-relative-to path
                               (asdf:system-source-directory :hyperdoc)))

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

(defun split-blank-line-blocks (text)
  (with-input-from-string (stream (or text ""))
    (loop with current-lines = '()
          with blocks = '()
          for line = (read-line stream nil nil)
          while line
          for trimmed = (string-trim '(#\Space #\Tab #\Newline #\Return) line)
          do (if (string= trimmed "")
                 (when current-lines
                   (push (format nil "~{~A~^~%~}" (nreverse current-lines))
                         blocks)
                   (setf current-lines '()))
                 (push trimmed current-lines))
          finally (when current-lines
                    (push (format nil "~{~A~^~%~}" (nreverse current-lines))
                          blocks))
                  (return (nreverse blocks)))))

(defun trim-whitespace-string (string)
  (string-trim '(#\Space #\Tab #\Newline #\Return)
               (or string "")))

(defun shorten-source-excerpt (text &key (max-length 120))
  (let ((trimmed (trim-whitespace-string text)))
    (if (<= (length trimmed) max-length)
        trimmed
        (format nil "~A..."
                (subseq trimmed 0 (max 0 (- max-length 3)))))))

(defun downcased-alphanumeric-token-slug (text)
  (let ((tokens '())
        (current '()))
    (flet ((flush-current ()
             (when current
               (push (coerce (nreverse current) 'string) tokens)
               (setf current '()))))
      (loop for char across (string-downcase (or text ""))
            do (if (alphanumericp char)
                   (push char current)
                   (flush-current)))
      (flush-current))
    (format nil "~{~A~^-~}" (nreverse tokens))))

(defun the-life-cycle-of-collective-knowledge-heading-key (line)
  (let* ((trimmed (trim-whitespace-string line))
         (known (assoc trimmed
                       +the-life-cycle-of-collective-knowledge-section-headings+
                       :test #'string=)))
    (cond
      (known
       (cdr known))
      ((and (plusp (length trimmed))
            (not (search ":" trimmed))
            (< (length trimmed) 64))
       (downcased-alphanumeric-token-slug trimmed))
      (t
       nil))))

(defun plist-keys (plist)
  (loop for tail on plist by #'cddr
        while tail
        collect (first tail)))

(defun plist-with-overrides (plist &rest overrides)
  (let ((override-keys (plist-keys overrides)))
    (append (copy-tree overrides)
            (loop for (key value) on plist by #'cddr
                  unless (member key override-keys)
                    append (list key (copy-tree value))))))

(defun fedwiki-journal-entry-type-name (entry)
  (let ((type (getf entry :type)))
    (etypecase type
      (keyword (string-downcase (symbol-name type)))
      (string type))))

(defun fedwiki-story-item-provenance-classification (item-id journal-entries item-index)
  (cond
    ((and item-id journal-entries)
     "story-item-id-and-journal")
    (item-id
     "story-item-id-only")
    ((integerp item-index)
     "page-slug-and-item-index-only")
    (t
     "page-slug-only")))

(defun fedwiki-journal-entries-for-item (page item-id)
  (if (null item-id)
      '()
      (loop for entry in (or (getf page :journal) '())
            for nested-item = (getf entry :item)
            when (or (equal (getf entry :id) item-id)
                     (equal (getf nested-item :id) item-id))
              collect (copy-tree entry))))

(defun fedwiki-page-create-date (page)
  (getf (find :create
              (or (getf page :journal) '())
              :key (lambda (entry) (getf entry :type)))
        :date))

(defun fedwiki-story-item-source-id* (page-id item-id item-index)
  (if item-id
      (format nil "~A#story-item/~A"
              page-id
              item-id)
      (format nil "~A#story-index/~D"
              page-id
              item-index)))

(defun fedwiki-story-item-source-id (item-record)
  (fedwiki-story-item-source-id* (fedwiki-page-id-of item-record)
                                 (item-id-of item-record)
                                 (item-index-of item-record)))

(defun fedwiki-story-item-fragment-source-id* (page-id item-id item-index fragment-index)
  (format nil "~A/fragment/~D"
          (fedwiki-story-item-source-id* page-id item-id item-index)
          fragment-index))

(defun normalize-fedwiki-story-item-fragment-records (page item item-index base-provenance)
  (let* ((page-id (getf base-provenance :source-page-id))
         (page-slug (getf base-provenance :source-page-slug))
         (page-title (getf page :title))
         (page-relative-path (getf base-provenance :source-page-path))
         (item-id (getf item :id))
         (item-type (getf base-provenance :source-story-item-type))
         (item-text (or (getf item :text) "")))
    (when (and (string= item-type "paragraph")
               (plusp (length item-text)))
      (let ((fragments '())
            (current-lines '())
            (current-section-key "intro")
            (current-heading nil)
            (fragment-index 0))
        (labels ((emit-fragment ()
                   (when current-lines
                     (let* ((fragment-text
                              (format nil "~{~A~^~%~}" (nreverse current-lines)))
                            (fragment-anchor (format nil "segment:~D" fragment-index))
                            (fragment-excerpt
                              (shorten-source-excerpt fragment-text))
                            (fragment-provenance
                              (plist-with-overrides
                               base-provenance
                               :source-kind "localhost-fedwiki-story-item-fragment"
                               :provenance-granularity "story-item-fragment"
                               :source-story-item-source-id
                               (fedwiki-story-item-source-id* page-id item-id item-index)
                               :source-fragment-index fragment-index
                               :source-fragment-anchor fragment-anchor
                               :source-fragment-section-key current-section-key
                               :source-fragment-heading current-heading
                               :source-fragment-excerpt fragment-excerpt
                               :derivation-note
                               "Split paragraph story item by heading lines and blank-line-separated text segments.")))
                       (push (make-instance 'localhost-fedwiki-fragment-record
                                            :page-id page-id
                                            :page-slug page-slug
                                            :page-title page-title
                                            :page-relative-path page-relative-path
                                            :item-index item-index
                                            :item-id item-id
                                            :item-type item-type
                                            :fragment-index fragment-index
                                            :fragment-anchor fragment-anchor
                                            :section-key current-section-key
                                            :section-heading current-heading
                                            :text fragment-text
                                            :excerpt fragment-excerpt
                                            :provenance fragment-provenance)
                             fragments))
                     (incf fragment-index)
                     (setf current-lines '()))))
          (with-input-from-string (stream item-text)
            (loop for raw-line = (read-line stream nil nil)
                  while raw-line
                  for trimmed = (trim-whitespace-string raw-line)
                  for heading-key = (the-life-cycle-of-collective-knowledge-heading-key
                                     trimmed)
                  do (cond
                       ((string= trimmed "")
                        (emit-fragment))
                       (heading-key
                        (emit-fragment)
                        (setf current-section-key heading-key
                              current-heading trimmed))
                       (t
                        (push trimmed current-lines)))))
          (emit-fragment)
          (nreverse fragments))))))

(defun normalize-fedwiki-story-item-record (page item item-index)
  (let* ((item-id (getf item :id))
         (item-type (string-downcase (symbol-name (getf item :type))))
         (item-text (or (getf item :text) ""))
         (item-blocks (and (string= item-type "paragraph")
                           (split-blank-line-blocks item-text)))
         (journal-entries (fedwiki-journal-entries-for-item page item-id))
         (classification
           (fedwiki-story-item-provenance-classification
            item-id journal-entries item-index))
         (page-id (the-life-cycle-of-collective-knowledge-fedwiki-page-id))
         (page-relative-path
           (the-life-cycle-of-collective-knowledge-localhost-fedwiki-page-relative-path))
         (base-provenance
           (list :source-kind "localhost-fedwiki-story-item"
                 :source-page-id page-id
                 :source-page-slug *the-life-cycle-of-collective-knowledge-fedwiki-slug*
                 :source-page-path page-relative-path
                 :source-story-item-id item-id
                 :source-story-item-index item-index
                 :source-story-item-type item-type
                 :journal-action-count (length journal-entries)
                 :journal-action-types
                 (mapcar #'fedwiki-journal-entry-type-name journal-entries)
                 :journal-last-date
                 (and journal-entries
                      (getf (car (last journal-entries)) :date))
                 :page-create-date (fedwiki-page-create-date page)
                 :provenance-granularity "story-item"
                 :provenance-classification classification)))
    (make-instance 'localhost-fedwiki-item-record
                   :page-id page-id
                   :page-slug *the-life-cycle-of-collective-knowledge-fedwiki-slug*
                   :page-title (getf page :title)
                   :page-relative-path page-relative-path
                   :item-index item-index
                   :item-id item-id
                   :item-type item-type
                   :text item-text
                   :blocks item-blocks
                   :fragments
                   (normalize-fedwiki-story-item-fragment-records
                    page
                    item
                    item-index
                    base-provenance)
                   :journal-entries journal-entries
                   :provenance base-provenance)))

(defun the-life-cycle-of-collective-knowledge-localhost-fedwiki-page ()
  (copy-tree
   (localhost-fedwiki-page-pipeline-result-raw-page
    (the-life-cycle-of-collective-knowledge-page-pipeline))))

(defun the-life-cycle-of-collective-knowledge-primary-story-item (source)
  (or (find "paragraph"
            (story-items-of source)
            :key #'item-type-of
            :test #'equal)
      (error "Expected a paragraph story item in localhost FedWiki page ~A."
             *the-life-cycle-of-collective-knowledge-fedwiki-slug*)))

(defun the-life-cycle-of-collective-knowledge-item-fragment-by-section-key
    (item-record section-key)
  (find section-key
        (fragments-of item-record)
        :key #'section-key-of
        :test #'equal))

(defun the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk ()
  (localhost-fedwiki-source-data->chunk
   (localhost-fedwiki-page-pipeline-result-source
    (the-life-cycle-of-collective-knowledge-page-pipeline))))

(defun the-life-cycle-of-collective-knowledge-source-metadata ()
  (let* ((html (read-utf8-file-string
                (the-life-cycle-of-collective-knowledge-source-asset-path)))
         (json (extract-json-script-body
                html
                *the-life-cycle-of-collective-knowledge-json-script-id*)))
    (shasht:read-json json)))

(defun the-life-cycle-of-collective-knowledge-source-asset-chunk ()
  (let* ((metadata (the-life-cycle-of-collective-knowledge-source-metadata)))
    (make-instance 'source-asset-chunk
                   :id "the-life-cycle-of-collective-knowledge-source-asset"
                   :title "The Life Cycle of Collective Knowledge source asset"
                   :summary (gethash "pageSummary" metadata)
                   :source-path *the-life-cycle-of-collective-knowledge-source-asset*
                   :references (list (gethash "sourceFedwikiUrl" metadata))
                   :fedwiki-slug (gethash "sourceFedwikiSlug" metadata)
                   :fedwiki-title (gethash "sourceFedwikiTitle" metadata)
                   :fedwiki-url (gethash "sourceFedwikiUrl" metadata)
                   :claim (gethash "claim" metadata)
                   :umbrella-topic-spec (gethash "umbrellaTopic" metadata)
                   :subtopic-specs (json-array-elements (gethash "subtopics" metadata))
                   :raw-asset (read-utf8-file-string
                               (the-life-cycle-of-collective-knowledge-source-asset-path)))))

(defparameter +the-life-cycle-of-collective-knowledge-topic-extraction-specs+
  '((:id "the-life-cycle-of-collective-knowledge"
     :title "The Life Cycle of Collective Knowledge"
     :summary "Collective knowledge remains alive only when its representations stay usable long enough to be reviewed, recombined, and reused across time."
     :fragment-selections ((:use-primary-item t
                            :fragment-ordinals (0 3 4 5 6)))
     :topic-kind :umbrella
     :references ("Source-oriented and image-oriented development in Common Lisp"
                  "Opening external FedWiki sites"
                  "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"))
    (:id "collective-knowledge"
     :title "Collective knowledge"
     :summary "Collective knowledge is information that has been published, reviewed, cited, recombined, and carried forward beyond any single contributor or file format."
     :fragment-selections ((:use-primary-item t
                            :fragment-ordinals (0 3 6)))
     :topic-kind :subtopic
     :references ("The Life Cycle of Collective Knowledge"
                  "Source-oriented and image-oriented development in Common Lisp"
                  "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"))
    (:id "refinement-of-information-into-knowledge"
     :title "Refinement of information into knowledge"
     :summary "Information becomes knowledge when communities can inspect, cite, compare, refine, and recombine it through durable representations."
     :fragment-selections ((:use-primary-item t
                            :fragment-ordinals (0 6)))
     :topic-kind :subtopic
     :references ("The Life Cycle of Collective Knowledge"
                  "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"))
    (:id "digital-fragility-of-software-source-code"
     :title "Digital fragility of software source code"
     :summary "Software source code is digitally fragile because its intelligibility and execution depend on machines, runtimes, toolchains, and surrounding environments."
     :fragment-selections ((:use-primary-item t
                            :fragment-ordinals (3)))
     :topic-kind :subtopic
     :references ("The Life Cycle of Collective Knowledge"
                  "Source-oriented and image-oriented development in Common Lisp"
                  "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"))
    (:id "computational-reproducibility-is-not-enough"
     :title "Computational reproducibility is not enough"
     :summary "Archiving old environments preserves rerun capability, but collective knowledge needs more than frozen reproducibility snapshots."
     :fragment-selections ((:use-primary-item t
                            :fragment-ordinals (4)))
     :topic-kind :subtopic
     :references ("The Life Cycle of Collective Knowledge"
                  "Source-oriented and image-oriented development in Common Lisp"
                  "A framework for maintaining the coherence of a running Lisp"
                  "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"))
    (:id "software-interoperability-across-time"
     :title "Software interoperability across time"
     :summary "Long-lived software knowledge requires later systems to inspect, compare, and reuse earlier components across time instead of only preserving them as inert artifacts."
     :fragment-selections ((:use-primary-item t
                            :fragment-ordinals (4)))
     :topic-kind :subtopic
     :references ("The Life Cycle of Collective Knowledge"
                  "Source-oriented and image-oriented development in Common Lisp"
                  "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"))
    (:id "stable-software-environments"
     :title "Stable software environments"
     :summary "Stable software environments provide the language, standards, and implementation continuity that let software remain usable across long spans of time."
     :fragment-selections ((:use-primary-item t
                            :fragment-ordinals (5)))
     :topic-kind :subtopic
     :references ("The Life Cycle of Collective Knowledge"
                  "Source-oriented and image-oriented development in Common Lisp"
                  "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"))))

(defun the-life-cycle-of-collective-knowledge-source-summary-from-pipeline
    (spec story-items primary-item)
  (declare (ignore spec story-items))
  (or (and primary-item
           (localhost-fedwiki-item-data-fragments primary-item)
           (localhost-fedwiki-fragment-data-text
            (first (localhost-fedwiki-item-data-fragments primary-item))))
      "Localhost FedWiki source page for The Life Cycle of Collective Knowledge."))

(defun the-life-cycle-of-collective-knowledge-source-claim-from-pipeline
    (source-data story-items primary-item)
  (let ((claim-fragment
          (and primary-item
               (localhost-fedwiki-item-fragment-by-section-key
                primary-item
                "claim-carried-by-this-page"))))
    (or (and claim-fragment
             (localhost-fedwiki-fragment-data-text claim-fragment))
        (default-localhost-fedwiki-source-claim
         source-data
         story-items
         primary-item))))

(defun the-life-cycle-of-collective-knowledge-page-pipeline-spec ()
  (make-localhost-fedwiki-page-pipeline-spec
   :id *the-life-cycle-of-collective-knowledge-fedwiki-slug*
   :page-title "The Life Cycle of Collective Knowledge"
   :site *the-life-cycle-of-collective-knowledge-fedwiki-site*
   :slug *the-life-cycle-of-collective-knowledge-fedwiki-slug*
   :html-url *the-life-cycle-of-collective-knowledge-fedwiki-html-url*
   :heading-key-map +the-life-cycle-of-collective-knowledge-section-headings+
   :source-summary-function
   #'the-life-cycle-of-collective-knowledge-source-summary-from-pipeline
   :source-claim-function
   #'the-life-cycle-of-collective-knowledge-source-claim-from-pipeline
   :source-chunk-id
   "the-life-cycle-of-collective-knowledge-localhost-fedwiki-source"
   :source-chunk-title
   "The Life Cycle of Collective Knowledge localhost FedWiki source"
   :source-summary-fallback
   "Localhost FedWiki source page for The Life Cycle of Collective Knowledge."))

(defun the-life-cycle-of-collective-knowledge-page-pipeline ()
  (run-localhost-fedwiki-page-pipeline
   (the-life-cycle-of-collective-knowledge-page-pipeline-spec)
   +the-life-cycle-of-collective-knowledge-topic-extraction-specs+))

(defun localhost-fedwiki-fragment-data->record (fragment-data)
  (make-instance 'localhost-fedwiki-fragment-record
                 :page-id (localhost-fedwiki-fragment-data-page-id fragment-data)
                 :page-slug (localhost-fedwiki-fragment-data-page-slug fragment-data)
                 :page-title (localhost-fedwiki-fragment-data-page-title fragment-data)
                 :page-relative-path
                 (localhost-fedwiki-fragment-data-page-relative-path fragment-data)
                 :item-index
                 (localhost-fedwiki-fragment-data-item-index fragment-data)
                 :item-id (localhost-fedwiki-fragment-data-item-id fragment-data)
                 :item-type (localhost-fedwiki-fragment-data-item-type fragment-data)
                 :fragment-index
                 (localhost-fedwiki-fragment-data-fragment-index fragment-data)
                 :fragment-anchor
                 (localhost-fedwiki-fragment-data-fragment-anchor fragment-data)
                 :section-key
                 (localhost-fedwiki-fragment-data-section-key fragment-data)
                 :section-heading
                 (localhost-fedwiki-fragment-data-section-heading fragment-data)
                 :text (localhost-fedwiki-fragment-data-text fragment-data)
                 :excerpt (localhost-fedwiki-fragment-data-excerpt fragment-data)
                 :provenance
                 (copy-tree
                  (localhost-fedwiki-fragment-data-provenance fragment-data))))

(defun localhost-fedwiki-item-data->record (item-data)
  (make-instance 'localhost-fedwiki-item-record
                 :page-id (localhost-fedwiki-item-data-page-id item-data)
                 :page-slug (localhost-fedwiki-item-data-page-slug item-data)
                 :page-title (localhost-fedwiki-item-data-page-title item-data)
                 :page-relative-path
                 (localhost-fedwiki-item-data-page-relative-path item-data)
                 :item-index (localhost-fedwiki-item-data-item-index item-data)
                 :item-id (localhost-fedwiki-item-data-item-id item-data)
                 :item-type (localhost-fedwiki-item-data-item-type item-data)
                 :text (localhost-fedwiki-item-data-text item-data)
                 :blocks (copy-tree (localhost-fedwiki-item-data-blocks item-data))
                 :fragments
                 (mapcar #'localhost-fedwiki-fragment-data->record
                         (localhost-fedwiki-item-data-fragments item-data))
                 :journal-entries
                 (copy-tree (localhost-fedwiki-item-data-journal-entries item-data))
                 :provenance
                 (copy-tree (localhost-fedwiki-item-data-provenance item-data))))

(defun localhost-fedwiki-source-data->chunk (source-data)
  (make-instance 'localhost-fedwiki-source-chunk
                 :id (localhost-fedwiki-source-data-id source-data)
                 :title (localhost-fedwiki-source-data-title source-data)
                 :summary (localhost-fedwiki-source-data-summary source-data)
                 :source-path (localhost-fedwiki-source-data-source-path source-data)
                 :references (copy-list (localhost-fedwiki-source-data-references source-data))
                 :fedwiki-site (localhost-fedwiki-source-data-fedwiki-site source-data)
                 :fedwiki-page-id (localhost-fedwiki-source-data-fedwiki-page-id source-data)
                 :fedwiki-slug (localhost-fedwiki-source-data-fedwiki-slug source-data)
                 :fedwiki-title (localhost-fedwiki-source-data-fedwiki-title source-data)
                 :fedwiki-url (localhost-fedwiki-source-data-fedwiki-url source-data)
                 :fedwiki-relative-path
                 (localhost-fedwiki-source-data-fedwiki-relative-path source-data)
                 :claim (localhost-fedwiki-source-data-claim source-data)
                 :story-items
                 (mapcar #'localhost-fedwiki-item-data->record
                         (localhost-fedwiki-source-data-story-items source-data))
                 :raw-page (copy-tree (localhost-fedwiki-source-data-raw-page source-data))
                 :provenance
                 (copy-tree (localhost-fedwiki-source-data-provenance source-data))))

(defun localhost-fedwiki-promoted-topic-data->chunk (topic-data)
  (make-instance 'subtopic-chunk
                 :id (localhost-fedwiki-promoted-topic-data-id topic-data)
                 :title (localhost-fedwiki-promoted-topic-data-title topic-data)
                 :summary (localhost-fedwiki-promoted-topic-data-summary topic-data)
                 :source-path
                 (localhost-fedwiki-promoted-topic-data-source-path topic-data)
                 :references
                 (copy-list (localhost-fedwiki-promoted-topic-data-references topic-data))
                 :body (localhost-fedwiki-promoted-topic-data-body topic-data)
                 :topic-kind (localhost-fedwiki-promoted-topic-data-topic-kind topic-data)
                 :page-title (localhost-fedwiki-promoted-topic-data-page-title topic-data)
                 :provenance
                 (copy-tree (localhost-fedwiki-promoted-topic-data-provenance topic-data))))

(defun the-life-cycle-of-collective-knowledge-umbrella-topic-chunk ()
  (localhost-fedwiki-promoted-topic-data->chunk
   (localhost-fedwiki-page-pipeline-result-umbrella-topic
    (the-life-cycle-of-collective-knowledge-page-pipeline))))

(defun the-life-cycle-of-collective-knowledge-subtopic-chunks ()
  (mapcar #'localhost-fedwiki-promoted-topic-data->chunk
          (localhost-fedwiki-page-pipeline-result-subtopics
           (the-life-cycle-of-collective-knowledge-page-pipeline))))

(defun the-life-cycle-of-collective-knowledge-topic-chunks ()
  (mapcar #'localhost-fedwiki-promoted-topic-data->chunk
          (localhost-fedwiki-page-pipeline-result-topic-chunks
           (the-life-cycle-of-collective-knowledge-page-pipeline))))

(defun find-the-life-cycle-of-collective-knowledge-topic-chunk (topic-id
                                                                &key signal-error?)
  (or (find topic-id
            (the-life-cycle-of-collective-knowledge-topic-chunks)
            :key #'id-of
            :test #'equal)
      (and signal-error?
           (error "Unknown The Life Cycle of Collective Knowledge topic id ~S."
                  topic-id))))

(defun the-life-cycle-of-collective-knowledge-default-topic-factory-metadata ()
  (let* ((pipeline (the-life-cycle-of-collective-knowledge-page-pipeline))
         (source (localhost-fedwiki-page-pipeline-result-source pipeline))
         (item-data (localhost-fedwiki-page-pipeline-result-primary-item pipeline))
         (fragment-ordinals
           (remove-duplicates
            (loop for topic-spec in +the-life-cycle-of-collective-knowledge-topic-extraction-specs+
                  append (loop for selection in (getf topic-spec :fragment-selections)
                               append (copy-list
                                       (or (getf selection :fragment-ordinals)
                                           '()))))
            :test #'eql))
         (fragments
           (localhost-fedwiki-fragments-by-ordinals item-data fragment-ordinals)))
    (list :id "the-life-cycle-of-collective-knowledge-topic-set"
          :source-file *the-life-cycle-of-collective-knowledge-topic-asset*
          :source-origin-id
          (localhost-fedwiki-source-data-fedwiki-page-id source)
          :source-origin-path
          (localhost-fedwiki-source-data-fedwiki-relative-path source)
          :related-hyperdoc-page-title
          "The Life Cycle of Collective Knowledge"
          :related-topic-id "the-life-cycle-of-collective-knowledge"
          :related-topic-ids
          (mapcar #'id-of
                  (the-life-cycle-of-collective-knowledge-topic-chunks))
          :provenance
          (plist-with-overrides
           (localhost-fedwiki-item-data-provenance item-data)
           :source-kind "localhost-fedwiki-topic-factory-snippet"
           :source-page-id
           (localhost-fedwiki-source-data-fedwiki-page-id source)
           :source-page-path
           (localhost-fedwiki-source-data-fedwiki-relative-path source)
           :provenance-granularity "story-item-fragment"
           :source-story-item-source-id
           (localhost-fedwiki-item-data-source-id item-data)
           :source-fragment-ordinals fragment-ordinals
           :source-fragment-anchors
           (mapcar #'localhost-fedwiki-fragment-data-fragment-anchor fragments)
           :source-fragment-section-keys
           (mapcar #'localhost-fedwiki-fragment-data-section-key fragments)
           :source-fragment-excerpt
           (and fragments
                (localhost-fedwiki-fragment-data-excerpt (first fragments)))
           :source-fragment-excerpts
           (mapcar #'localhost-fedwiki-fragment-data-excerpt fragments)
           :derivation-note
           "Dry-run-first DMX snippet twin for authored HyperDoc topic factories derived from paragraph fragments in one localhost FedWiki story item."))))

(defun normalize-the-life-cycle-of-collective-knowledge-topic-factory-metadata
    (metadata)
  (let ((defaults (the-life-cycle-of-collective-knowledge-default-topic-factory-metadata)))
    (list :id (or (getf metadata :id)
                  (getf defaults :id))
          :source-file (or (getf metadata :source-file)
                           (getf defaults :source-file))
          :source-origin-id (or (getf metadata :source-origin-id)
                                (getf defaults :source-origin-id))
          :source-origin-path (or (getf metadata :source-origin-path)
                                  (getf defaults :source-origin-path))
          :related-hyperdoc-page-title
          (or (getf metadata :related-hyperdoc-page-title)
              (getf defaults :related-hyperdoc-page-title))
          :related-topic-id (or (getf metadata :related-topic-id)
                                (getf defaults :related-topic-id))
          :related-topic-ids (or (copy-list (getf metadata :related-topic-ids))
                                 (copy-list (getf defaults :related-topic-ids)))
          :provenance (copy-tree (getf defaults :provenance)))))

(defun the-life-cycle-of-collective-knowledge-topic-factory-metadata ()
  (let ((path (the-life-cycle-of-collective-knowledge-topic-asset-path)))
    (if (uiop:file-exists-p path)
        (with-open-file (stream path
                                :direction :input
                                :external-format :utf-8)
          (let ((form (read stream nil nil)))
            (unless (and (consp form)
                         (eq (first form) :topic-factory-snippet))
              (error "Topic-factory asset must start with a :topic-factory-snippet plist."))
            (normalize-the-life-cycle-of-collective-knowledge-topic-factory-metadata
             (rest form))))
        (the-life-cycle-of-collective-knowledge-default-topic-factory-metadata))))

(defun make-the-life-cycle-of-collective-knowledge-dmx-snippet-uri (snippet-id)
  (format nil "hyperdoc:topic-factory-snippet/~A" snippet-id))

(defun the-life-cycle-of-collective-knowledge-topic-definition-chunk ()
  (let* ((metadata (the-life-cycle-of-collective-knowledge-topic-factory-metadata))
         (snippet-path (the-life-cycle-of-collective-knowledge-topic-asset-path))
         (source-file (or (getf metadata :source-file)
                          *the-life-cycle-of-collective-knowledge-topic-asset*)))
    (make-instance 'topic-definition-chunk
                   :id (getf metadata :id)
                   :title "The Life Cycle of Collective Knowledge topic-definition chunk"
                   :summary "Topic-factory snippet bundle for the authored The Life Cycle of Collective Knowledge topic set."
                   :source-path source-file
                   :references (list (getf metadata :source-origin-id)
                                     *the-life-cycle-of-collective-knowledge-page-path*)
                   :snippet-id (getf metadata :id)
                   :snippet-text (if (uiop:file-exists-p snippet-path)
                                     (read-utf8-file-string snippet-path)
                                     "")
                   :source-origin-id (getf metadata :source-origin-id)
                   :source-origin-path (getf metadata :source-origin-path)
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
                   :references (list (source-origin-id-of definition)
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
                 :source-origin-id (source-origin-id-of definition)
                 :source-origin-path (source-origin-path-of definition)
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
  (let* ((source (the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk))
         (primary-item
           (the-life-cycle-of-collective-knowledge-primary-story-item source))
         (primary-fragment-count (length (fragments-of primary-item)))
         (umbrella (the-life-cycle-of-collective-knowledge-umbrella-topic-chunk))
         (subtopics (the-life-cycle-of-collective-knowledge-subtopic-chunks))
         (definition (the-life-cycle-of-collective-knowledge-topic-definition-chunk))
         (dmx-snippet (the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)))
    (with-output-to-string (stream)
      (format stream "<h1>The Life Cycle of Collective Knowledge</h1>~%~%")
      (format stream "<in-package>hyperdoc</in-package>~%~%")
      (format stream "<p>~%")
      (format stream "  This authored HyperDoc page is composed from FedWiki-derived chunks read from the~%")
      (format stream "  localhost page <tt>~A</tt> at repo-relative source path <tt>~A</tt>.~%"
              (fedwiki-page-id-of source)
              (fedwiki-relative-path-of source))
      (format stream "</p>~%~%")
      (format stream "<p>~%")
      (format stream "  The local composition path stays usable without DMX. The topic-factory snippet asset~%")
      (format stream "  <tt>~A</tt> remains a separate derived artifact, and the DMX writer stays a~%"
              *the-life-cycle-of-collective-knowledge-topic-asset*)
      (format stream "  separate, explicit, dry-run-first twin path rather than a live proxy for this~%")
      (format stream "  authored page.~%")
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
      (format stream "  The page composition remains local: the localhost FedWiki page is parsed into~%")
      (format stream "  normalized story-item records plus paragraph-fragment records. The current page~%")
      (format stream "  is semantically one large paragraph story item, so the reusable topic chunks~%")
      (format stream "  preserve fragment-level provenance within that item instead of claiming~%")
      (format stream "  independent whole-item origins. The topic-factory snippet stays as a separate~%")
      (format stream "  authored asset, and~%")
      (format stream "  this page renders from those chunks without depending on a DMX lookup or write.~%")
      (format stream "</p>~%~%")
      (format stream "<ul>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk)\"><tt>Localhost FedWiki source chunk</tt></a></li>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-topic-definition-chunk)\"><tt>Topic-definition chunk</tt></a></li>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-subtopic-chunks)\"><tt>Subtopic chunks</tt></a></li>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-topic-page-chunk)\"><tt>Topic-page chunk</tt></a></li>~%")
      (format stream "</ul>~%~%")
      (format stream "<h2>DMX snippet twin</h2>~%~%")
      (format stream "<p>~%")
      (format stream "  The DMX twin/snippet chunk writes the topic-factory bundle under the stable URI~%")
      (format stream "  <tt>~A</tt>. It carries snippet text, canonical source-file provenance, the~%"
              (snippet-uri-of dmx-snippet))
      (format stream "  related HyperDoc page title, and the related umbrella topic id <tt>~A</tt>.~%"
              (related-topic-id-of definition))
      (format stream "</p>~%~%")
      (format stream "<ul>~%")
      (format stream "  <li><a expr=\"(hyperdoc::the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)\"><tt>DMX twin/snippet chunk</tt></a></li>~%")
      (format stream "  <li><tt>plan-topic-factory-snippet-dmx-write</tt> for plan-only inspection.</li>~%")
      (format stream "  <li><tt>execute-topic-factory-snippet-dmx-write</tt> for explicit dry-run or live execution.</li>~%")
      (format stream "  <li><a page=\"DMX FedWiki Write Model\">DMX FedWiki Write Model</a></li>~%")
      (format stream "  <li><a hyperbook=\"topics\" page=\"Runtime write live-proof gate\"><tt>Runtime write live-proof gate</tt></a></li>~%")
      (format stream "</ul>~%~%")
      (format stream "<h2>FedWiki source</h2>~%~%")
      (format stream "<p>~%")
      (format stream "  Source FedWiki page id: <tt>~A</tt>. Repo-relative page path: <tt>~A</tt>.~%"
              (fedwiki-page-id-of source)
              (fedwiki-relative-path-of source))
      (format stream "</p>~%~%")
      (format stream "<p>~%")
      (format stream "  External source URL: <a href=\"~A\"><tt>~A</tt></a>. Parsed story items: <tt>~D</tt>.~%"
              (fedwiki-url-of source)
              (fedwiki-url-of source)
              (length (story-items-of source)))
      (format stream "</p>~%~%")
      (format stream "<p>~%")
      (format stream "  The current reusable topics are derived from <tt>~D</tt> paragraph fragments~%"
              primary-fragment-count)
      (format stream "  inside the primary FedWiki paragraph item, so the provenance reported by the~%")
      (format stream "  derived chunks is fragment-level rather than whole-item-level.~%")
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
                 :source-path *the-life-cycle-of-collective-knowledge-page-path*
                 :references '("The Life Cycle of Collective Knowledge")
                 :page-path *the-life-cycle-of-collective-knowledge-page-path*
                 :page-html (render-the-life-cycle-of-collective-knowledge-page)
                 :composed-from
                 (list (the-life-cycle-of-collective-knowledge-fedwiki-page-id)
                       *the-life-cycle-of-collective-knowledge-topic-asset*)))

(defun parse-the-life-cycle-of-collective-knowledge-chunks ()
  (list :source-fedwiki-page
        (the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk)
        :topic-definition
        (the-life-cycle-of-collective-knowledge-topic-definition-chunk)
        :umbrella-topic
        (the-life-cycle-of-collective-knowledge-umbrella-topic-chunk)
        :subtopics
        (the-life-cycle-of-collective-knowledge-subtopic-chunks)
        :topic-page
        (the-life-cycle-of-collective-knowledge-topic-page-chunk)
        :dmx-snippet
        (the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)))

(defun write-the-life-cycle-of-collective-knowledge-artifacts ()
  (let ((snippet-path (the-life-cycle-of-collective-knowledge-topic-asset-path))
        (page-path (the-life-cycle-of-collective-knowledge-page-pathname)))
    (write-utf8-file-string snippet-path
                            (render-the-life-cycle-of-collective-knowledge-topic-factory-snippet))
    (write-utf8-file-string page-path
                            (render-the-life-cycle-of-collective-knowledge-page))
    (list :topic-asset (hyperdoc-relative-path-string snippet-path)
          :page (hyperdoc-relative-path-string page-path))))
