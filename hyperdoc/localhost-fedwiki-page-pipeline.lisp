;;;; Generic localhost FedWiki page pipeline helpers
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defstruct localhost-fedwiki-page-pipeline-spec
  id
  page-title
  site
  slug
  html-url
  page-relative-path
  page-reader
  heading-key-map
  heading-key-function
  primary-item-selector
  source-summary-function
  source-claim-function
  source-chunk-id
  source-chunk-title
  source-summary-fallback)

(defstruct localhost-fedwiki-fragment-data
  page-id
  page-slug
  page-title
  page-relative-path
  item-index
  item-id
  item-type
  fragment-index
  fragment-anchor
  section-key
  section-heading
  text
  excerpt
  provenance)

(defstruct localhost-fedwiki-item-data
  page-id
  page-slug
  page-title
  page-relative-path
  item-index
  item-id
  item-type
  text
  blocks
  fragments
  journal-entries
  provenance)

(defstruct localhost-fedwiki-source-data
  id
  title
  summary
  source-path
  references
  fedwiki-site
  fedwiki-page-id
  fedwiki-slug
  fedwiki-title
  fedwiki-url
  fedwiki-relative-path
  claim
  story-items
  raw-page
  provenance)

(defstruct localhost-fedwiki-promoted-topic-data
  id
  title
  summary
  source-path
  references
  body
  topic-kind
  page-title
  provenance)

(defstruct localhost-fedwiki-page-pipeline-result
  spec
  raw-page
  source
  primary-item
  topic-specs
  umbrella-topic
  subtopics
  topic-chunks)

(defparameter +localhost-fedwiki-page-source-snapshot-page-prefix+
  "<!-- HYPERDOC_LOCALHOST_FEDWIKI_SOURCE_SNAPSHOT ")
(defparameter +localhost-fedwiki-page-source-snapshot-page-suffix+
  " -->")
(defparameter +localhost-fedwiki-page-source-snapshot-snippet-prefix+
  ";; HYPERDOC_LOCALHOST_FEDWIKI_SOURCE_SNAPSHOT ")
(defparameter +localhost-fedwiki-page-source-snapshot-envelope-tag+
  "HYPERDOC_LOCALHOST_FEDWIKI_SOURCE_SNAPSHOT")
(defparameter +localhost-fedwiki-page-source-snapshot-envelope-format-version+
  1)

(defstruct localhost-fedwiki-source-snapshot-envelope-reflection
  artifact-kind
  status
  snapshot
  error-message
  line)

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

(defun string-prefix-p* (prefix string)
  (and (<= (length prefix) (length string))
       (string= prefix
                string
                :end1 (length prefix)
                :end2 (length prefix))))

(defun string-suffix-p* (suffix string)
  (let ((suffix-length (length suffix))
        (string-length (length string)))
    (and (<= suffix-length string-length)
         (string= suffix
                  string
                  :start1 0
                  :end1 suffix-length
                  :start2 (- string-length suffix-length)
                  :end2 string-length))))

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

(defun default-localhost-fedwiki-page-relative-path (slug)
  (format nil "pages/~A" slug))

(defun localhost-fedwiki-page-pipeline-page-id (spec)
  (format nil "fedwiki:~A/~A"
          (localhost-fedwiki-page-pipeline-spec-site spec)
          (localhost-fedwiki-page-pipeline-spec-slug spec)))

(defun localhost-fedwiki-page-pipeline-page-pathname (spec)
  (merge-pathnames (localhost-fedwiki-page-pipeline-spec-slug spec)
                   (article-allegation-default-fedwiki-pages-directory)))

(defun localhost-fedwiki-page-pipeline-page-relative-path (spec)
  (or (localhost-fedwiki-page-pipeline-spec-page-relative-path spec)
      (default-localhost-fedwiki-page-relative-path
          (localhost-fedwiki-page-pipeline-spec-slug spec))))

(defun read-localhost-fedwiki-page (spec)
  (if-let (reader (localhost-fedwiki-page-pipeline-spec-page-reader spec))
      (funcall reader)
    (article-allegation-read-json-file
     (localhost-fedwiki-page-pipeline-page-pathname spec))))

(defun default-localhost-fedwiki-heading-key (heading-map line)
  (let* ((trimmed (trim-whitespace-string line))
         (known (assoc trimmed heading-map :test #'string=)))
    (cond
      (known
       (cdr known))
      ((and (plusp (length trimmed))
            (not (search ":" trimmed))
            (< (length trimmed) 64))
       (downcased-alphanumeric-token-slug trimmed))
      (t
       nil))))

(defun localhost-fedwiki-heading-key (spec line)
  (if-let (function (localhost-fedwiki-page-pipeline-spec-heading-key-function spec))
      (funcall function line)
    (default-localhost-fedwiki-heading-key
        (localhost-fedwiki-page-pipeline-spec-heading-key-map spec)
        line)))

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

(defun localhost-fedwiki-page-last-journal-date (page)
  (reduce #'max
          (loop for entry in (or (getf page :journal) '())
                for date = (getf entry :date)
                when (numberp date)
                collect date)
          :initial-value 0))

(defun fedwiki-story-item-source-id* (page-id item-id item-index)
  (if item-id
      (format nil "~A#story-item/~A"
              page-id
              item-id)
      (format nil "~A#story-index/~D"
              page-id
              item-index)))

(defun localhost-fedwiki-item-data-source-id (item-data)
  (fedwiki-story-item-source-id* (localhost-fedwiki-item-data-page-id item-data)
                                 (localhost-fedwiki-item-data-item-id item-data)
                                 (localhost-fedwiki-item-data-item-index item-data)))

(defun localhost-fedwiki-source-page-id* (source)
  (typecase source
    (localhost-fedwiki-source-data
     (localhost-fedwiki-source-data-fedwiki-page-id source))
    (t
     (funcall (symbol-function 'fedwiki-page-id-of) source))))

(defun localhost-fedwiki-source-page-slug* (source)
  (typecase source
    (localhost-fedwiki-source-data
     (localhost-fedwiki-source-data-fedwiki-slug source))
    (t
     (funcall (symbol-function 'fedwiki-slug-of) source))))

(defun localhost-fedwiki-source-page-path* (source)
  (typecase source
    (localhost-fedwiki-source-data
     (localhost-fedwiki-source-data-fedwiki-relative-path source))
    (t
     (funcall (symbol-function 'fedwiki-relative-path-of) source))))

(defun localhost-fedwiki-source-page-title* (source)
  (typecase source
    (localhost-fedwiki-source-data
     (localhost-fedwiki-source-data-fedwiki-title source))
    (t
     (funcall (symbol-function 'fedwiki-title-of) source))))

(defun localhost-fedwiki-source-story-items* (source)
  (typecase source
    (localhost-fedwiki-source-data
     (localhost-fedwiki-source-data-story-items source))
    (t
     (funcall (symbol-function 'story-items-of) source))))

(defun localhost-fedwiki-source-raw-page* (source)
  (typecase source
    (localhost-fedwiki-source-data
     (localhost-fedwiki-source-data-raw-page source))
    (t
     (funcall (symbol-function 'raw-page-of) source))))

(defun localhost-fedwiki-item-fragments* (item)
  (typecase item
    (localhost-fedwiki-item-data
     (localhost-fedwiki-item-data-fragments item))
    (t
     (funcall (symbol-function 'fragments-of) item))))

(defun localhost-fedwiki-source-fragment-count (source-data)
  (loop for item in (localhost-fedwiki-source-story-items* source-data)
        sum (length (localhost-fedwiki-item-fragments* item))))

(defun localhost-fedwiki-source-snapshot-fingerprint-input (source-data)
  (let ((raw-page (localhost-fedwiki-source-raw-page* source-data)))
    (list :source-page-id
          (localhost-fedwiki-source-page-id* source-data)
          :source-page-slug
          (localhost-fedwiki-source-page-slug* source-data)
          :source-page-path
          (localhost-fedwiki-source-page-path* source-data)
          :source-page-title
          (localhost-fedwiki-source-page-title* source-data)
          :story
          (copy-tree (or (getf raw-page :story) '()))
          :journal
          (copy-tree (or (getf raw-page :journal) '())))))

(defun serialize-localhost-fedwiki-source-snapshot-object (object)
  (let ((*print-pretty* nil)
        (*print-array* nil)
        (*print-circle* nil)
        (*print-level* nil)
        (*print-length* nil)
        (*print-readably* nil)
        (*print-escape* t)
        (*print-case* :upcase)
        (*package* (find-package :keyword)))
    (prin1-to-string object)))

(defun fnv1a-64-hex-string (string)
  (let ((hash #xcbf29ce484222325)
        (prime #x100000001b3))
    (flet ((mix-byte (byte)
             (setf hash (ldb (byte 64 0)
                             (* (logxor hash byte) prime)))))
      (loop for char across string
            for code = (char-code char)
            do (mix-byte (ldb (byte 8 0) code))
            (mix-byte (ldb (byte 8 8) code))
            (mix-byte (ldb (byte 8 16) code))
            (mix-byte (ldb (byte 8 24) code))))
    (format nil "fnv1a64:~16,'0x" hash)))

(defun localhost-fedwiki-source-snapshot-summary (source-data)
  (let ((raw-page (localhost-fedwiki-source-raw-page* source-data)))
    (format nil "story-items=~D; fragments=~D; journal=~D; last-journal=~A"
            (length (or (getf raw-page :story) '()))
            (localhost-fedwiki-source-fragment-count source-data)
            (length (or (getf raw-page :journal) '()))
            (let ((last-date (localhost-fedwiki-page-last-journal-date raw-page)))
              (if (zerop last-date)
                  "n/a"
                  (format nil "~D" last-date))))))

(defun localhost-fedwiki-source-snapshot-metadata (source-data)
  (let* ((fingerprint-input
          (localhost-fedwiki-source-snapshot-fingerprint-input source-data))
         (fingerprint-string
          (serialize-localhost-fedwiki-source-snapshot-object fingerprint-input))
         (raw-page (localhost-fedwiki-source-raw-page* source-data)))
    (list :snapshot-kind "localhost-fedwiki-page-source-snapshot"
          :snapshot-format-version 1
          :fingerprint-algorithm
          "fnv1a-64-over-normalized-raw-page-story-and-journal"
          :fingerprint
          (fnv1a-64-hex-string fingerprint-string)
          :summary
          (localhost-fedwiki-source-snapshot-summary source-data)
          :source-page-id
          (localhost-fedwiki-source-page-id* source-data)
          :source-page-slug
          (localhost-fedwiki-source-page-slug* source-data)
          :source-page-path
          (localhost-fedwiki-source-page-path* source-data)
          :source-page-title
          (localhost-fedwiki-source-page-title* source-data)
          :story-item-count
          (length (or (getf raw-page :story) '()))
          :fragment-count
          (localhost-fedwiki-source-fragment-count source-data)
          :journal-entry-count
          (length (or (getf raw-page :journal) '()))
          :journal-last-date
          (let ((last-date (localhost-fedwiki-page-last-journal-date raw-page)))
            (unless (zerop last-date)
              last-date))
          :page-create-date
          (fedwiki-page-create-date raw-page))))

(defun localhost-fedwiki-source-snapshot-envelope-prefix (artifact-kind)
  (ecase artifact-kind
    (:hyperdoc-html-page
     +localhost-fedwiki-page-source-snapshot-page-prefix+)
    (:topic-factory-lisp-snippet
     +localhost-fedwiki-page-source-snapshot-snippet-prefix+)))

(defun localhost-fedwiki-source-snapshot-envelope-suffix (artifact-kind)
  (ecase artifact-kind
    (:hyperdoc-html-page
     +localhost-fedwiki-page-source-snapshot-page-suffix+)
    (:topic-factory-lisp-snippet
     nil)))

(defun localhost-fedwiki-source-snapshot-envelope-line
    (artifact-kind snapshot-metadata)
  (format nil "~A~A~@[~A~]"
          (localhost-fedwiki-source-snapshot-envelope-prefix artifact-kind)
          (serialize-localhost-fedwiki-source-snapshot-object snapshot-metadata)
          (localhost-fedwiki-source-snapshot-envelope-suffix artifact-kind)))

(defun valid-localhost-fedwiki-source-snapshot-metadata-p (object)
  (and (alexandria:proper-list-p object)
       (evenp (length object))
       (string= (or (getf object :snapshot-kind) "")
                "localhost-fedwiki-page-source-snapshot")
       (eql (getf object :snapshot-format-version)
            +localhost-fedwiki-page-source-snapshot-envelope-format-version+)
       (stringp (getf object :fingerprint))
       (stringp (getf object :summary))
       (stringp (getf object :source-page-id))
       (stringp (getf object :source-page-path))))

(defun render-localhost-fedwiki-page-source-snapshot-page-comment (source-data)
  (localhost-fedwiki-source-snapshot-envelope-line
   :hyperdoc-html-page
   (localhost-fedwiki-source-snapshot-metadata source-data)))

(defun render-localhost-fedwiki-page-source-snapshot-snippet-comment (source-data)
  (localhost-fedwiki-source-snapshot-envelope-line
   :topic-factory-lisp-snippet
   (localhost-fedwiki-source-snapshot-metadata source-data)))

(defun render-localhost-fedwiki-page-artifact-with-source-snapshot
    (page-html source-data)
  (format nil "~A~%~A"
          (render-localhost-fedwiki-page-source-snapshot-page-comment source-data)
          (strip-leading-localhost-fedwiki-source-snapshot-line
           page-html
           :hyperdoc-html-page
           +localhost-fedwiki-page-source-snapshot-page-prefix+
           +localhost-fedwiki-page-source-snapshot-page-suffix+)))

(defun render-localhost-fedwiki-topic-snippet-artifact-with-source-snapshot
    (snippet-text source-data)
  (format nil "~A~%~A"
          (render-localhost-fedwiki-page-source-snapshot-snippet-comment source-data)
          (strip-leading-localhost-fedwiki-source-snapshot-line
           snippet-text
           :topic-factory-lisp-snippet
           +localhost-fedwiki-page-source-snapshot-snippet-prefix+)))

(defun split-string-first-line (string)
  (let ((newline-position (position #\Newline string)))
    (values (if newline-position
                (subseq string 0 newline-position)
                string)
            (if newline-position
                (subseq string (1+ newline-position))
                ""))))

(defun whitespace-only-string-p (string)
  (every (lambda (character)
           (find character '(#\Space #\Tab #\Newline #\Return)))
         string))

(defun parse-localhost-fedwiki-source-snapshot-line
    (line prefix &optional suffix)
  (let ((reflection
         (reflect-localhost-fedwiki-source-snapshot-envelope-line
          :custom
          line
          prefix
          suffix)))
    (when (eql (localhost-fedwiki-source-snapshot-envelope-reflection-status
                reflection)
               :present)
      (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
       reflection))))

(defun reflect-localhost-fedwiki-source-snapshot-envelope-line
    (artifact-kind line prefix &optional suffix)
  (cond
    ((and (string-prefix-p* prefix line)
          suffix
          (not (string-suffix-p* suffix line)))
     (make-localhost-fedwiki-source-snapshot-envelope-reflection
      :artifact-kind artifact-kind
      :status :malformed
      :error-message "Envelope prefix was present but the closing suffix was missing."
      :line line))
    ((not (string-prefix-p* prefix line))
     (make-localhost-fedwiki-source-snapshot-envelope-reflection
      :artifact-kind artifact-kind
      :status :missing
      :line line))
    (t
     (let* ((start (length prefix))
            (end (if suffix
                     (- (length line) (length suffix))
                     (length line)))
            (payload (subseq line start end)))
       (handler-case
           (let ((*read-eval* nil))
             (multiple-value-bind (object position)
                 (read-from-string payload nil :eof)
               (cond
                 ((eq object :eof)
                  (make-localhost-fedwiki-source-snapshot-envelope-reflection
                   :artifact-kind artifact-kind
                   :status :malformed
                   :error-message "Envelope payload was empty."
                   :line line))
                 ((not (whitespace-only-string-p (subseq payload position)))
                  (make-localhost-fedwiki-source-snapshot-envelope-reflection
                   :artifact-kind artifact-kind
                   :status :malformed
                   :error-message "Envelope payload contained trailing non-whitespace."
                   :line line))
                 ((not (valid-localhost-fedwiki-source-snapshot-metadata-p object))
                  (make-localhost-fedwiki-source-snapshot-envelope-reflection
                   :artifact-kind artifact-kind
                   :status :malformed
                   :error-message "Envelope payload was not valid source snapshot metadata."
                   :line line))
                 (t
                  (make-localhost-fedwiki-source-snapshot-envelope-reflection
                   :artifact-kind artifact-kind
                   :status :present
                   :snapshot object
                   :line line)))))
         (error (condition)
           (make-localhost-fedwiki-source-snapshot-envelope-reflection
            :artifact-kind artifact-kind
            :status :malformed
            :error-message (princ-to-string condition)
            :line line)))))))

(defun reflect-localhost-fedwiki-source-snapshot-envelope
    (artifact-kind string)
  (multiple-value-bind (line)
      (split-string-first-line string)
    (reflect-localhost-fedwiki-source-snapshot-envelope-line
     artifact-kind
     line
     (localhost-fedwiki-source-snapshot-envelope-prefix artifact-kind)
     (localhost-fedwiki-source-snapshot-envelope-suffix artifact-kind))))

(defun strip-leading-localhost-fedwiki-source-snapshot-line
    (string artifact-kind prefix &optional suffix)
  (multiple-value-bind (line remainder)
      (split-string-first-line string)
    (if (not (eql (localhost-fedwiki-source-snapshot-envelope-reflection-status
                   (reflect-localhost-fedwiki-source-snapshot-envelope-line
                    artifact-kind
                    line
                    prefix
                    suffix))
                  :missing))
        remainder
        string)))

(defun localhost-fedwiki-page-artifact-reflected-source-snapshot (page-html)
  (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
   (reflect-localhost-fedwiki-source-snapshot-envelope
    :hyperdoc-html-page
    page-html)))

(defun localhost-fedwiki-page-artifact-reflected-source-snapshot-reflection
    (page-html)
  (reflect-localhost-fedwiki-source-snapshot-envelope
   :hyperdoc-html-page
   page-html))

(defun localhost-fedwiki-topic-snippet-artifact-reflected-source-snapshot
    (snippet-text)
  (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
   (reflect-localhost-fedwiki-source-snapshot-envelope
    :topic-factory-lisp-snippet
    snippet-text)))

(defun localhost-fedwiki-topic-snippet-artifact-reflected-source-snapshot-reflection
    (snippet-text)
  (reflect-localhost-fedwiki-source-snapshot-envelope
   :topic-factory-lisp-snippet
   snippet-text))

(defun default-localhost-fedwiki-primary-item-selector (story-items)
  (find "paragraph"
        story-items
        :key #'localhost-fedwiki-item-data-item-type
        :test #'equal))

(defun localhost-fedwiki-primary-story-item-data (spec story-items)
  (if-let (selector (localhost-fedwiki-page-pipeline-spec-primary-item-selector spec))
      (funcall selector story-items)
    (default-localhost-fedwiki-primary-item-selector story-items)))

(defun localhost-fedwiki-item-fragment-by-section-key (item-data section-key)
  (find section-key
        (localhost-fedwiki-item-data-fragments item-data)
        :key #'localhost-fedwiki-fragment-data-section-key
        :test #'equal))

(defun default-localhost-fedwiki-source-summary (spec story-items primary-item)
  (declare (ignore story-items))
  (or (and primary-item
           (localhost-fedwiki-item-data-fragments primary-item)
           (localhost-fedwiki-fragment-data-text
            (first (localhost-fedwiki-item-data-fragments primary-item))))
      (localhost-fedwiki-page-pipeline-spec-source-summary-fallback spec)
      (format nil "Localhost FedWiki source page for ~A."
              (or (localhost-fedwiki-page-pipeline-spec-page-title spec)
                  (localhost-fedwiki-page-pipeline-spec-slug spec)))))

(defun default-localhost-fedwiki-source-claim (source-data story-items primary-item)
  (declare (ignore source-data story-items))
  (or (and primary-item
           (localhost-fedwiki-item-data-fragments primary-item)
           (localhost-fedwiki-fragment-data-text
            (first (last (localhost-fedwiki-item-data-fragments primary-item)))))
      (and primary-item
           (localhost-fedwiki-item-data-text primary-item))
      ""))

(defun normalize-localhost-fedwiki-story-item-fragment-data (spec
                                                             page
                                                             item
                                                             item-index
                                                             base-provenance)
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
                       (push (make-localhost-fedwiki-fragment-data
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
                  for heading-key = (localhost-fedwiki-heading-key spec trimmed)
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

(defun normalize-localhost-fedwiki-story-item-data (spec page item item-index)
  (let* ((item-id (getf item :id))
         (item-type
          (let ((type-value (getf item :type)))
            (etypecase type-value
              (keyword (string-downcase (symbol-name type-value)))
              (string (string-downcase type-value)))))
         (item-text (or (getf item :text) ""))
         (item-blocks (and (string= item-type "paragraph")
                           (split-blank-line-blocks item-text)))
         (journal-entries (fedwiki-journal-entries-for-item page item-id))
         (classification
          (fedwiki-story-item-provenance-classification
           item-id journal-entries item-index))
         (page-id (localhost-fedwiki-page-pipeline-page-id spec))
         (page-relative-path
          (localhost-fedwiki-page-pipeline-page-relative-path spec))
         (base-provenance
          (list :source-kind "localhost-fedwiki-story-item"
                :source-page-id page-id
                :source-page-slug
                (localhost-fedwiki-page-pipeline-spec-slug spec)
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
    (make-localhost-fedwiki-item-data
     :page-id page-id
     :page-slug (localhost-fedwiki-page-pipeline-spec-slug spec)
     :page-title (getf page :title)
     :page-relative-path page-relative-path
     :item-index item-index
     :item-id item-id
     :item-type item-type
     :text item-text
     :blocks item-blocks
     :fragments
     (normalize-localhost-fedwiki-story-item-fragment-data
      spec
      page
      item
      item-index
      base-provenance)
     :journal-entries journal-entries
     :provenance base-provenance)))

(defun normalize-localhost-fedwiki-story-items (spec page)
  (loop for item in (or (getf page :story) '())
        for item-index from 0
        collect (normalize-localhost-fedwiki-story-item-data
                 spec
                 page
                 item
                 item-index)))

(defun build-localhost-fedwiki-source-data (spec &key page story-items)
  (let* ((resolved-page (or page (read-localhost-fedwiki-page spec)))
         (resolved-story-items
          (or story-items
              (normalize-localhost-fedwiki-story-items spec resolved-page)))
         (primary-item
          (localhost-fedwiki-primary-story-item-data spec resolved-story-items))
         (summary-function
          (or (localhost-fedwiki-page-pipeline-spec-source-summary-function spec)
              #'default-localhost-fedwiki-source-summary))
         (source-data
          (make-localhost-fedwiki-source-data
           :id (or (localhost-fedwiki-page-pipeline-spec-source-chunk-id spec)
                   (format nil "~A-localhost-fedwiki-source"
                           (localhost-fedwiki-page-pipeline-spec-id spec)))
           :title
           (or (localhost-fedwiki-page-pipeline-spec-source-chunk-title spec)
               (format nil "~A localhost FedWiki source"
                       (or (localhost-fedwiki-page-pipeline-spec-page-title spec)
                           (getf resolved-page :title))))
           :summary
           (funcall summary-function spec resolved-story-items primary-item)
           :source-path (localhost-fedwiki-page-pipeline-page-relative-path spec)
           :references
           (list (localhost-fedwiki-page-pipeline-page-id spec)
                 (localhost-fedwiki-page-pipeline-spec-html-url spec))
           :fedwiki-site (localhost-fedwiki-page-pipeline-spec-site spec)
           :fedwiki-page-id (localhost-fedwiki-page-pipeline-page-id spec)
           :fedwiki-slug (localhost-fedwiki-page-pipeline-spec-slug spec)
           :fedwiki-title (getf resolved-page :title)
           :fedwiki-url (localhost-fedwiki-page-pipeline-spec-html-url spec)
           :fedwiki-relative-path
           (localhost-fedwiki-page-pipeline-page-relative-path spec)
           :claim ""
           :story-items resolved-story-items
           :raw-page resolved-page
           :provenance
           (list :source-kind "localhost-fedwiki-page"
                 :source-page-id (localhost-fedwiki-page-pipeline-page-id spec)
                 :source-page-slug
                 (localhost-fedwiki-page-pipeline-spec-slug spec)
                 :source-page-path
                 (localhost-fedwiki-page-pipeline-page-relative-path spec)
                 :story-item-count (length resolved-story-items)
                 :journal-entry-count (length (or (getf resolved-page :journal) '()))
                 :provenance-granularity "page-level-fallback"
                 :provenance-classification "page-story-and-journal"))))
    (setf (localhost-fedwiki-source-data-claim source-data)
          (funcall (or (localhost-fedwiki-page-pipeline-spec-source-claim-function spec)
                       #'default-localhost-fedwiki-source-claim)
                   source-data
                   resolved-story-items
                   primary-item))
    source-data))

(defun find-localhost-fedwiki-item-data-by-selection (source-data
                                                      selection
                                                      primary-item)
  (let ((story-items (localhost-fedwiki-source-data-story-items source-data)))
    (cond
      ((getf selection :use-primary-item)
       primary-item)
      ((integerp (getf selection :item-index))
       (find (getf selection :item-index)
             story-items
             :key #'localhost-fedwiki-item-data-item-index
             :test #'eql))
      ((getf selection :item-id)
       (find (getf selection :item-id)
             story-items
             :key #'localhost-fedwiki-item-data-item-id
             :test #'equal))
      ((getf selection :item-type)
       (find (getf selection :item-type)
             story-items
             :key #'localhost-fedwiki-item-data-item-type
             :test #'equal))
      (t
       nil))))

(defun localhost-fedwiki-fragments-by-ordinals (item-data fragment-ordinals)
  (loop for fragment-ordinal in fragment-ordinals
        collect (or (find fragment-ordinal
                          (localhost-fedwiki-item-data-fragments item-data)
                          :key #'localhost-fedwiki-fragment-data-fragment-index
                          :test #'eql)
                    (error "Missing fragment ~D in story item ~S."
                           fragment-ordinal
                           (localhost-fedwiki-item-data-item-id item-data)))))

(defun resolve-localhost-fedwiki-fragment-selection (source-data
                                                     selection
                                                     primary-item)
  (let* ((item-data
          (or (find-localhost-fedwiki-item-data-by-selection
               source-data
               selection
               primary-item)
              (error "Could not resolve FedWiki item selection ~S." selection)))
         (whole-item-p (getf selection :whole-item))
         (fragments
          (cond
            ((getf selection :fragment-ordinals)
             (localhost-fedwiki-fragments-by-ordinals
              item-data
              (copy-list (getf selection :fragment-ordinals))))
            ((getf selection :section-keys)
             (loop for section-key in (copy-list (getf selection :section-keys))
                   collect (or (localhost-fedwiki-item-fragment-by-section-key
                                item-data
                                section-key)
                               (error "Missing section key ~S in story item ~S."
                                      section-key
                                      (localhost-fedwiki-item-data-item-id item-data)))))
            (whole-item-p
             (copy-list (localhost-fedwiki-item-data-fragments item-data)))
            (t
             '()))))
    (list :selection (copy-tree selection)
          :item-data item-data
          :whole-item-p whole-item-p
          :fragments fragments)))

(defun resolve-localhost-fedwiki-fragment-selections (source-data
                                                      fragment-selections
                                                      primary-item)
  (loop for selection in fragment-selections
        collect (resolve-localhost-fedwiki-fragment-selection
                 source-data
                 selection
                 primary-item)))

(defun localhost-fedwiki-fragment-selection-body (resolved-selections)
  (format nil "~{~A~^~%~%~}"
          (loop for resolved-selection in resolved-selections
                append (let ((fragments (getf resolved-selection :fragments))
                             (item-data (getf resolved-selection :item-data))
                             (whole-item-p (getf resolved-selection :whole-item-p)))
                         (cond
                           (fragments
                            (mapcar #'localhost-fedwiki-fragment-data-text fragments))
                           (whole-item-p
                            (list (localhost-fedwiki-item-data-text item-data)))
                           (t
                            '()))))))

(defun aggregate-resolved-selection-journal-count (resolved-selections)
  (reduce #'+
          (loop for resolved-selection in resolved-selections
                collect (getf (localhost-fedwiki-item-data-provenance
                               (getf resolved-selection :item-data))
                              :journal-action-count
                              0))
          :initial-value 0))

(defun localhost-fedwiki-resolved-selection-provenance (source-data
                                                        resolved-selections
                                                        &key derived-topic-id
                                                          derivation-note)
  (let* ((item-datas
          (remove-duplicates
           (loop for resolved-selection in resolved-selections
                 collect (getf resolved-selection :item-data))
           :key #'localhost-fedwiki-item-data-source-id
           :test #'equal))
         (base-provenance
          (copy-tree
           (if item-datas
               (localhost-fedwiki-item-data-provenance (first item-datas))
               (localhost-fedwiki-source-data-provenance source-data))))
         (fragments
          (loop for resolved-selection in resolved-selections
                append (copy-list (getf resolved-selection :fragments))))
         (whole-item-p
          (and (= (length item-datas) 1)
               (every (lambda (resolved-selection)
                        (and (getf resolved-selection :whole-item-p)
                             (null (getf (getf resolved-selection :selection)
                                         :fragment-ordinals))
                             (null (getf (getf resolved-selection :selection)
                                         :section-keys))))
                      resolved-selections)))
         (granularity
          (cond
            ((null item-datas)
             "page-level-fallback")
            ((> (length item-datas) 1)
             "multi-item-derived")
            (whole-item-p
             "story-item")
            (t
             "story-item-fragment")))
         (classifications
          (remove-duplicates
           (loop for item-data in item-datas
                 collect (getf (localhost-fedwiki-item-data-provenance item-data)
                               :provenance-classification))
           :test #'equal))
         (story-item-source-ids
          (mapcar #'localhost-fedwiki-item-data-source-id item-datas))
         (story-item-ids
          (mapcar #'localhost-fedwiki-item-data-item-id item-datas))
         (story-item-indexes
          (mapcar #'localhost-fedwiki-item-data-item-index item-datas))
         (fragment-ordinals
          (mapcar #'localhost-fedwiki-fragment-data-fragment-index fragments))
         (fragment-anchors
          (mapcar #'localhost-fedwiki-fragment-data-fragment-anchor fragments))
         (fragment-section-keys
          (mapcar #'localhost-fedwiki-fragment-data-section-key fragments))
         (fragment-excerpts
          (mapcar #'localhost-fedwiki-fragment-data-excerpt fragments))
         (shared-overrides
          (append
           (when derived-topic-id
             (list :derived-topic-id derived-topic-id))
           (list :provenance-granularity granularity
                 :provenance-classification
                 (if (= (length classifications) 1)
                     (first classifications)
                     "mixed-story-item-provenance")
                 :source-provenance-classifications classifications
                 :journal-action-count
                 (if item-datas
                     (aggregate-resolved-selection-journal-count resolved-selections)
                     (getf (localhost-fedwiki-source-data-provenance source-data)
                           :journal-entry-count
                           0))
                 :derivation-note
                 (or derivation-note
                     (ecase (intern (string-upcase granularity) :keyword)
                       (:STORY-ITEM
                        "Derived from one whole localhost FedWiki story item.")
                       (:STORY-ITEM-FRAGMENT
                        "Derived from paragraph fragments within one localhost FedWiki story item, not from separate whole story items.")
                       (:MULTI-ITEM-DERIVED
                        "Derived by grouping fragments across multiple localhost FedWiki story items.")
                       (:PAGE-LEVEL-FALLBACK
                        "Derived from page-level FedWiki provenance without resolvable story-item selections.")))
                 :source-fragment-selection-kind
                 (ecase (intern (string-upcase granularity) :keyword)
                   (:STORY-ITEM "whole-story-item")
                   (:STORY-ITEM-FRAGMENT "paragraph-fragments")
                   (:MULTI-ITEM-DERIVED "multi-item-fragments")
                   (:PAGE-LEVEL-FALLBACK "page-level-fallback")))))
         (location-overrides
          (cond
            ((null item-datas)
             (list :source-page-id
                   (localhost-fedwiki-source-data-fedwiki-page-id source-data)
                   :source-page-path
                   (localhost-fedwiki-source-data-fedwiki-relative-path
                    source-data)))
            ((= (length item-datas) 1)
             (append
              (list :source-story-item-source-id (first story-item-source-ids))
              (when fragments
                (list :source-fragment-ordinals fragment-ordinals
                      :source-fragment-anchors fragment-anchors
                      :source-fragment-section-keys fragment-section-keys
                      :source-fragment-excerpt (first fragment-excerpts)
                      :source-fragment-excerpts fragment-excerpts))))
            (t
             (append
              (list :source-story-item-source-ids story-item-source-ids
                    :source-story-item-ids story-item-ids
                    :source-story-item-indexes story-item-indexes)
              (when fragments
                (list :source-fragment-ordinals fragment-ordinals
                      :source-fragment-anchors fragment-anchors
                      :source-fragment-section-keys fragment-section-keys
                      :source-fragment-excerpt (first fragment-excerpts)
                      :source-fragment-excerpts fragment-excerpts)))))))
    (apply #'plist-with-overrides
           base-provenance
           (append shared-overrides location-overrides))))

(defun localhost-fedwiki-topic-source-path (source-data resolved-selections)
  (let ((item-datas
         (remove-duplicates
          (loop for resolved-selection in resolved-selections
                collect (getf resolved-selection :item-data))
          :key #'localhost-fedwiki-item-data-source-id
          :test #'equal)))
    (cond
      ((null item-datas)
       (localhost-fedwiki-source-data-fedwiki-page-id source-data))
      ((= (length item-datas) 1)
       (localhost-fedwiki-item-data-source-id (first item-datas)))
      (t
       (format nil "~A#multi-item-derived"
               (localhost-fedwiki-source-data-fedwiki-page-id source-data))))))

(defun build-localhost-fedwiki-promoted-topic-data (source-data
                                                    primary-item
                                                    page-title
                                                    topic-spec)
  (let* ((resolved-selections
          (resolve-localhost-fedwiki-fragment-selections
           source-data
           (copy-tree (getf topic-spec :fragment-selections))
           primary-item))
         (derivation-note
          (or (getf topic-spec :derivation-note)
              (if (> (length (remove-duplicates
                              (loop for resolved-selection in resolved-selections
                                    collect (localhost-fedwiki-item-data-source-id
                                             (getf resolved-selection :item-data)))
                              :test #'equal))
                     1)
                  "Derived by grouping fragments across multiple localhost FedWiki story items."
                  "Derived from paragraph fragments within one localhost FedWiki story item, not from separate whole story items."))))
    (make-localhost-fedwiki-promoted-topic-data
     :id (getf topic-spec :id)
     :title (getf topic-spec :title)
     :summary (getf topic-spec :summary)
     :source-path (localhost-fedwiki-topic-source-path source-data
                                                       resolved-selections)
     :references (copy-list (getf topic-spec :references))
     :body (localhost-fedwiki-fragment-selection-body resolved-selections)
     :topic-kind (getf topic-spec :topic-kind)
     :page-title page-title
     :provenance
     (localhost-fedwiki-resolved-selection-provenance
      source-data
      resolved-selections
      :derived-topic-id (getf topic-spec :id)
      :derivation-note derivation-note))))

(defun run-localhost-fedwiki-page-pipeline (spec topic-specs)
  (let* ((page (read-localhost-fedwiki-page spec))
         (source (build-localhost-fedwiki-source-data spec :page page))
         (primary-item
          (localhost-fedwiki-primary-story-item-data
           spec
           (localhost-fedwiki-source-data-story-items source)))
         (topic-chunks
          (loop for topic-spec in topic-specs
                collect (build-localhost-fedwiki-promoted-topic-data
                         source
                         primary-item
                         (or (localhost-fedwiki-page-pipeline-spec-page-title spec)
                             (localhost-fedwiki-source-data-fedwiki-title source))
                         topic-spec)))
         (umbrella-topic
          (find :umbrella
                topic-chunks
                :key #'localhost-fedwiki-promoted-topic-data-topic-kind))
         (subtopics
          (remove :umbrella
                  topic-chunks
                  :key #'localhost-fedwiki-promoted-topic-data-topic-kind)))
    (make-localhost-fedwiki-page-pipeline-result
     :spec spec
     :raw-page page
     :source source
     :primary-item primary-item
     :topic-specs (copy-tree topic-specs)
     :umbrella-topic umbrella-topic
     :subtopics subtopics
     :topic-chunks topic-chunks)))

(defun localhost-fedwiki-flatten-fragment-selections (topic-specs)
  (loop for topic-spec in topic-specs
        append (copy-tree (getf topic-spec :fragment-selections))))

(defun make-localhost-fedwiki-topic-factory-metadata-from-pipeline
    (pipeline
     &key id source-file related-hyperdoc-page-title related-topic-id
       related-topic-ids fragment-selections note)
  (let* ((source (localhost-fedwiki-page-pipeline-result-source pipeline))
         (primary-item (localhost-fedwiki-page-pipeline-result-primary-item pipeline))
         (resolved-selections
          (resolve-localhost-fedwiki-fragment-selections
           source
           (or (copy-tree fragment-selections)
               (localhost-fedwiki-flatten-fragment-selections
                (localhost-fedwiki-page-pipeline-result-topic-specs pipeline)))
           primary-item)))
    (list :id id
          :source-file source-file
          :source-origin-id (localhost-fedwiki-source-data-fedwiki-page-id source)
          :source-origin-path (localhost-fedwiki-source-data-fedwiki-relative-path source)
          :related-hyperdoc-page-title related-hyperdoc-page-title
          :related-topic-id related-topic-id
          :related-topic-ids
          (or (copy-list related-topic-ids)
              (mapcar #'localhost-fedwiki-promoted-topic-data-id
                      (localhost-fedwiki-page-pipeline-result-topic-chunks pipeline)))
          :provenance
          (localhost-fedwiki-resolved-selection-provenance
           source
           resolved-selections
           :derived-topic-id related-topic-id
           :derivation-note
           (or note
               "Dry-run-first DMX snippet twin for authored HyperDoc topic factories derived from paragraph fragments in one localhost FedWiki story item.")))))

(defun render-topic-list-item-html (title summary)
  (format nil
          "  <li><a hyperbook=\"topics\" page=\"~A\"><tt>~A</tt></a>: ~A</li>"
          title
          title
          summary))

(defun render-topic-list-html (entries)
  (with-output-to-string (stream)
    (format stream "<ul>~%")
    (dolist (entry entries)
      (format stream "~A~%"
              (render-topic-list-item-html (getf entry :title)
                                           (getf entry :summary))))
    (format stream "</ul>")))

(defun render-hyperdoc-page-shell (page-title intro-blocks section-blocks)
  (with-output-to-string (stream)
    (let ((last-section-block (car (last section-blocks))))
      (format stream "<h1>~A</h1>~%~%" page-title)
      (format stream "<in-package>hyperdoc</in-package>~%~%")
      (dolist (block intro-blocks)
        (write-string block stream)
        (format stream "~%~%"))
      (loop for section-block in section-blocks
            do (format stream "<h2>~A</h2>~%~%~A"
                       (getf section-block :title)
                       (getf section-block :body-html))
            (unless (eq section-block last-section-block)
              (format stream "~%~%"))))))

(defun render-localhost-fedwiki-promotion-workflow-section-html
    (&key promotion-plan-expression
       source-expression
       source-page-id
       source-page-path)
  (with-output-to-string (stream)
    (format stream "<p>~%")
    (format stream "  This generated HyperDoc page can reopen its promotion workflow for source page~%")
    (format stream "  <tt>~A</tt> at repo-relative path <tt>~A</tt>, without leaving the durable~%"
            source-page-id
            source-page-path)
    (format stream "  authored artifact surface.~%")
    (format stream "</p>~%~%")
    (format stream "<ul>~%")
    (format stream "  <li><a expr=\"~A\" view=\"Overview\"><tt>Promotion plan overview</tt></a></li>~%"
            promotion-plan-expression)
    (format stream "  <li><a expr=\"~A\" view=\"Source freshness\"><tt>Review source freshness</tt></a></li>~%"
            promotion-plan-expression)
    (format stream "  <li><a expr=\"~A\" view=\"Source page\"><tt>Promotion-plan source page view</tt></a></li>~%"
            promotion-plan-expression)
    (format stream "  <li><a expr=\"~A\" view=\"Summary\"><tt>Normalized localhost source object</tt></a></li>~%"
            source-expression)
    (format stream "</ul>")))
