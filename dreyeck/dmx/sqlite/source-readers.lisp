;;;; Local-first source readers for the Zettel 6537 / Advice Taker slice.

(in-package #:dreyeck.dmx.sqlite)

(defparameter *default-fedwiki-site*
  "wiki.ralfbarkow.ch")

(defparameter *default-fedwiki-site-root*
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/")

(defparameter *advice-taker-asset-root*
  #P"/Users/rgb/.wiki/wiki.ralfbarkow.ch/assets/pages/advice-taker/")

(defparameter *advice-taker-asd-path*
  (merge-pathnames "advice-taker.asd" *advice-taker-asset-root*))

(defun source-reader-json-keyword (key)
  (intern (string-upcase key) :keyword))

(defun source-reader-normalize-json (value &optional key)
  (labels ((normalize-type (type-value)
             (if (stringp type-value)
                 (intern (string-upcase type-value) :keyword)
                 type-value)))
    (cond
      ((hash-table-p value)
       (loop for json-key being each hash-key of value
             using (hash-value json-value)
             for normalized-key = (source-reader-json-keyword json-key)
             append (list normalized-key
                          (source-reader-normalize-json
                           json-value
                           normalized-key))))
      ((stringp value)
       (if (eql key :type)
           (normalize-type value)
           value))
      ((vectorp value)
       (map 'list #'source-reader-normalize-json value))
      ((listp value)
       (mapcar #'source-reader-normalize-json value))
      (t value))))

(defun source-reader-read-json-file (path)
  (with-open-file (stream path :direction :input :external-format :utf-8)
    (source-reader-normalize-json (shasht:read-json stream))))

(defun source-reader-fedwiki-page-path (slug &key
                                               (site-root *default-fedwiki-site-root*))
  (merge-pathnames (format nil "pages/~A" slug) site-root))

(defun source-reader-stable-fedwiki-id (site slug)
  (format nil "fedwiki:~A/~A" site slug))

(defun source-reader-result
    (&key reader source-identity provenance extracted-fragments derived-topics
       failure-state)
  (list :kind :source-reader-result
        :reader reader
        :source-identity source-identity
        :provenance provenance
        :extracted-fragments extracted-fragments
        :derived-topics derived-topics
        :failure-state failure-state
        :network-required-p nil))

(defun source-reader-failure-result
    (reader source-identity provenance condition)
  (source-reader-result
   :reader reader
   :source-identity source-identity
   :provenance provenance
   :extracted-fragments nil
   :derived-topics nil
   :failure-state
   (list :status :failed
         :condition-type (type-of condition)
         :detail (princ-to-string condition))))

(defun source-reader-story-item-text (item)
  (or (getf item :text) ""))

(defun source-reader-story-fragment
    (stable-page-id item index &key fragment-kind)
  (list :id (getf item :id)
        :source-id (if (getf item :id)
                       (format nil "~A#story-item/~A"
                               stable-page-id
                               (getf item :id))
                       (format nil "~A#story-index/~D"
                               stable-page-id
                               index))
        :index index
        :type (getf item :type)
        :fragment-kind (or fragment-kind :fedwiki-story-item)
        :text (source-reader-story-item-text item)))

(defun source-reader-story-fragments
    (page stable-page-id &key predicate fragment-kind)
  (loop for item in (or (getf page :story) '())
        for index from 0
        when (or (null predicate)
                 (funcall predicate item))
          collect
          (source-reader-story-fragment stable-page-id
                                        item
                                        index
                                        :fragment-kind fragment-kind)))

(defun source-reader-text-contains-p (text needle)
  (and text
       (search needle text :test #'char-equal)))

(defun source-reader-wikilinks (text)
  (loop with start = 0
        for open = (search "[[" text :start2 start :test #'char=)
        while open
        for close = (search "]]" text :start2 (+ open 2) :test #'char=)
        while close
        collect (subseq text (+ open 2) close)
        do (setf start (+ close 2))))

(defun source-reader-slug-from-title (title)
  (with-output-to-string (stream)
    (loop with pending-hyphen-p = nil
          for char across (string-downcase (or title ""))
          do (cond
               ((alphanumericp char)
                (when pending-hyphen-p
                  (write-char #\- stream)
                  (setf pending-hyphen-p nil))
                (write-char char stream))
               (t
                (setf pending-hyphen-p t))))))

(defun source-reader-derived-topic
    (id title &key kind source evidence)
  (list :id id
        :title title
        :kind kind
        :source source
        :evidence evidence))

(defun source-reader-derived-wikilink-topics (fragments)
  (let ((titles
          (remove-duplicates
           (loop for fragment in fragments
                 append (source-reader-wikilinks (getf fragment :text)))
           :test #'string=)))
    (loop for title in titles
          collect
          (source-reader-derived-topic
           (source-reader-slug-from-title title)
           title
           :kind :fedwiki-wikilink
           :source :story-text
           :evidence "[[...]] wiki link"))))

(defun source-reader-page-provenance (reader slug path page)
  (list :reader reader
        :access-mode :local-file
        :slug slug
        :path (namestring path)
        :page-title (getf page :title)
        :story-count (length (or (getf page :story) '()))
        :journal-count (length (or (getf page :journal) '()))
        :network-required-p nil))

(defun read-local-fedwiki-page-source
    (slug &key (site *default-fedwiki-site*)
            (site-root *default-fedwiki-site-root*)
            (reader :fedwiki-page-reader))
  "Read a local FedWiki page JSON file as an inspectable source object."
  (let* ((path (source-reader-fedwiki-page-path slug :site-root site-root))
         (stable-id (source-reader-stable-fedwiki-id site slug))
         (identity
           (list :kind :fedwiki-page
                 :site site
                 :slug slug
                 :stable-id stable-id
                 :path (namestring path))))
    (handler-case
        (let* ((page (source-reader-read-json-file path))
               (fragments (source-reader-story-fragments page stable-id))
               (derived-topics
                 (source-reader-derived-wikilink-topics fragments)))
          (source-reader-result
           :reader reader
           :source-identity identity
           :provenance (source-reader-page-provenance reader slug path page)
           :extracted-fragments fragments
           :derived-topics derived-topics
           :failure-state nil))
      (error (condition)
        (source-reader-failure-result
         reader
         identity
         (list :reader reader
               :access-mode :local-file
               :path (namestring path)
               :network-required-p nil)
         condition)))))

(defun read-physics-not-advice-source ()
  "Read the local Physics, Not Advice page as source-station evidence."
  (let ((result (read-local-fedwiki-page-source "physics-not-advice")))
    (if (getf result :failure-state)
        result
        (let ((augmented-result (copy-list result)))
          (setf
           (getf augmented-result :derived-topics)
           (append
            (getf result :derived-topics)
            (list
             (source-reader-derived-topic
              "physics-not-advice"
              "Physics, Not Advice"
              :kind :source-page
              :source :fedwiki-page
              :evidence "page slug")
             (source-reader-derived-topic
              "zettel-6537"
              "Zettel 6537"
              :kind :source-station
              :source :story-text
              :evidence "Zettel 6537 bridge")
             (source-reader-derived-topic
              "planning-as-contingency-reduction"
              "Planning as Contingency Reduction"
              :kind :interpretive-claim
              :source :story-text
              :evidence "planning reduces a structurally opened contingency space"))))
          augmented-result))))

(defun source-reader-zettel-6537-story-item-p (item)
  (let ((text (source-reader-story-item-text item)))
    (or (source-reader-text-contains-p text "Zettel 6537")
        (source-reader-text-contains-p text "contingency")
        (source-reader-text-contains-p text "structurally opened"))))

(defun read-zettel-6537-source ()
  "Read Zettel 6537 evidence from the local Physics, Not Advice page."
  (let* ((slug "physics-not-advice")
         (site *default-fedwiki-site*)
         (path (source-reader-fedwiki-page-path slug))
         (stable-page-id (source-reader-stable-fedwiki-id site slug))
         (identity
           (list :kind :zettel-note
                 :id "zettel-6537"
                 :title "Zettel 6537"
                 :source-station "zettel-6537-source-station"
                 :base-page stable-page-id
                 :path (namestring path))))
    (handler-case
        (let* ((page (source-reader-read-json-file path))
               (fragments
                 (source-reader-story-fragments
                  page
                  stable-page-id
                  :predicate #'source-reader-zettel-6537-story-item-p
                  :fragment-kind :zettel-evidence))
               (failure-state
                 (unless fragments
                   (list :status :partial
                         :reason :zettel-fragments-missing
                         :detail "No local FedWiki story item matched Zettel 6537."))))
          (source-reader-result
           :reader :zettel-reader
           :source-identity identity
           :provenance
           (append
            (source-reader-page-provenance :zettel-reader slug path page)
            (list :filter "Zettel 6537 / contingency / structurally opened"))
           :extracted-fragments fragments
           :derived-topics
           (list
            (source-reader-derived-topic
             "zettel-6537"
             "Zettel 6537"
             :kind :zettel
             :source :fedwiki-story
             :evidence "Zettel 6537 story text")
            (source-reader-derived-topic
             "planning-as-contingency-reduction"
             "Planning as Contingency Reduction"
             :kind :interpretive-claim
             :source :fedwiki-story
             :evidence "planning reduces contingency")
            (source-reader-derived-topic
             "structurally-opened-contingency-space"
             "Structurally Opened Contingency Space"
             :kind :zettel-concept
             :source :fedwiki-story
             :evidence "structurally opened contingency space"))
           :failure-state failure-state))
      (error (condition)
        (source-reader-failure-result
         :zettel-reader
         identity
         (list :reader :zettel-reader
               :access-mode :local-file
               :path (namestring path)
               :network-required-p nil)
         condition)))))

(defun source-reader-load-advice-taker-system ()
  (unless (uiop:file-exists-p *advice-taker-asd-path*)
    (error "Advice Taker ASDF file is absent: ~A"
           (namestring *advice-taker-asd-path*)))
  (asdf:load-asd *advice-taker-asd-path* :name "advice-taker")
  (asdf:load-system :advice-taker))

(defun source-reader-advice-taker-snapshot ()
  (source-reader-load-advice-taker-system)
  (let* ((package (or (find-package "ADVICE-TAKER")
                      (error "ADVICE-TAKER package was not loaded.")))
         (symbol (or (find-symbol "ADVICE-TAKER-TOPICMAP-SNAPSHOT" package)
                     (error "ADVICE-TAKER-TOPICMAP-SNAPSHOT is absent."))))
    (unless (fboundp symbol)
      (error "ADVICE-TAKER-TOPICMAP-SNAPSHOT is not fbound."))
    (funcall symbol)))

(defun source-reader-advice-taker-page-fragments (stable-page-id)
  (let* ((path (source-reader-fedwiki-page-path "advice-taker"))
         (page (source-reader-read-json-file path)))
    (source-reader-story-fragments page stable-page-id)))

(defun source-reader-advice-taker-topic-fragments (snapshot stable-id)
  (loop for topic in (or (getf snapshot :topics) '())
        for index from 0
        for excerpt = (getf topic :excerpt)
        for summary = (getf topic :summary)
        collect
        (list :id (getf topic :id)
              :source-id (format nil "~A#topic/~A"
                                 stable-id
                                 (getf topic :id))
              :index index
              :type :topicmap-topic
              :fragment-kind :advice-taker-topic
              :text (or excerpt summary ""))))

(defun source-reader-advice-taker-derived-topics (snapshot)
  (loop for topic in (or (getf snapshot :topics) '())
        collect
        (source-reader-derived-topic
         (getf topic :id)
         (getf topic :title)
         :kind (getf topic :kind)
         :source :advice-taker-topicmap
         :evidence (or (getf topic :excerpt)
                       (getf topic :summary)))))

(defun read-advice-taker-source ()
  "Read Advice Taker as a source station from local FedWiki and ASDF assets."
  (let* ((site *default-fedwiki-site*)
         (slug "advice-taker")
         (stable-page-id (source-reader-stable-fedwiki-id site slug))
         (stable-id "source:advice-taker")
         (identity
           (list :kind :source-note
                 :id "advice-taker"
                 :title "Advice Taker"
                 :source-station "advice-taker-source-station"
                 :fedwiki-page stable-page-id
                 :asset-root (namestring *advice-taker-asset-root*)
                 :stable-id stable-id)))
    (handler-case
        (let* ((snapshot (source-reader-advice-taker-snapshot))
               (page-fragments
                 (source-reader-advice-taker-page-fragments stable-page-id))
               (topic-fragments
                 (source-reader-advice-taker-topic-fragments
                  snapshot
                  stable-id))
               (transcript-present-p (getf snapshot :transcript-present-p))
               (failure-state
                 (unless transcript-present-p
                   (list :status :partial
                         :reason :transcript-missing
                         :detail "Advice Taker transcript text is absent; using page and topicmap summaries."
                         :transcript-path
                         (namestring (getf snapshot :transcript-path))))))
          (source-reader-result
           :reader :advice-taker-note-reader
           :source-identity identity
           :provenance
           (list :reader :advice-taker-note-reader
                 :access-mode :local-asdf-asset
                 :page-path
                 (namestring (source-reader-fedwiki-page-path slug))
                 :asset-root (namestring *advice-taker-asset-root*)
                 :transcript-present-p transcript-present-p
                 :network-required-p nil)
           :extracted-fragments (append page-fragments topic-fragments)
           :derived-topics (source-reader-advice-taker-derived-topics snapshot)
           :failure-state failure-state))
      (error (condition)
        (source-reader-failure-result
         :advice-taker-note-reader
         identity
         (list :reader :advice-taker-note-reader
               :access-mode :local-asdf-asset
               :asset-root (namestring *advice-taker-asset-root*)
               :network-required-p nil)
         condition)))))

(defun read-zettel-6537-and-advice-taker-sources ()
  "Return all source-reader surfaces selected by the SHOP3 plan."
  (list :kind :source-reader-surface-set
        :plan "read-zettel-6537-and-advice-taker"
        :network-required-p nil
        :sources
        (list (read-zettel-6537-source)
              (read-physics-not-advice-source)
              (read-advice-taker-source))))
