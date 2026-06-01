;;;; Views for Topics hyperbook pages
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defun topic-localhost-fedwiki-promotion-plan-view (plan context-label)
  (when plan
    (let ((dmx-summary
           (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan)))
      (views:html-view :title "Promotion plan" :priority 2
                       (views:add-asset-path "/hyperbook/"
                                             (asdf:system-relative-pathname
                                              :hyperbook
                                              "assets/hyperbook/"))
                       (views:include-css "/hyperbook/css/hyperbook.css")
                       (views:html
                        (:div :class "hyperbook-page"
                              (:h1 (views:esc "Promotion plan"))
                              (:p (views:esc context-label))
                              (:table :class "inspector-table"
                                      (:tr (:th "Plan object")
                                           (:td (views:object-ref plan)))
                                      (:tr (:th "Plan id")
                                           (:td (:tt (views:esc
                                                      (localhost-fedwiki-page-promotion-plan-id
                                                       plan)))))
                                      (:tr (:th "Source page")
                                           (:td (:tt (views:esc
                                                      (localhost-fedwiki-page-promotion-plan-source-page-id
                                                       plan)))))
                                      (:tr (:th "Page output synced")
                                           (:td (:tt (views:esc
                                                      (if (localhost-fedwiki-page-promotion-plan-page-output-synced-p
                                                           plan)
                                                          "yes"
                                                          "no")))))
                                      (:tr (:th "Snippet output synced")
                                           (:td (:tt (views:esc
                                                      (if (localhost-fedwiki-page-promotion-plan-snippet-output-synced-p
                                                           plan)
                                                          "yes"
                                                          "no")))))
                                      (:tr (:th "DMX dry-run")
                                           (:td (:tt (views:esc
                                                      (if (getf dmx-summary :available)
                                                          (format nil "~A / ~A"
                                                                  (getf dmx-summary :topic-action)
                                                                  (getf dmx-summary :topicmap-action))
                                                          "unavailable"))))))
                              (:h2 (views:esc "Open"))
                              (:ul
                               (:li (views:object-ref plan
                                                      :display "Overview"
                                                      :select "Overview"))
                               (:li (views:object-ref plan
                                                      :display "Source page"
                                                      :select "Source page"))
                               (:li (views:object-ref plan
                                                      :display "Promoted topics"
                                                      :select "Promoted topics"))
                               (:li (views:object-ref plan
                                                      :display "Page output"
                                                      :select "Page output"))
                               (:li (views:object-ref plan
                                                      :display "Snippet metadata"
                                                      :select "Snippet metadata"))
                               (:li (views:object-ref plan
                                                      :display "DMX dry-run"
                                                      :select "DMX dry-run")))))))))

(views:defview 👀overview (hb topics-hyperbook)
  (declare (ignore hb))
  (views:html-view :title "Overview" :priority 1
                   (views:add-asset-path "/hyperbook/"
                                         (asdf:system-relative-pathname
                                          :hyperbook
                                          "assets/hyperbook/"))
                   (views:include-css "/hyperbook/css/hyperbook.css")
                   (views:html
                    (:div :class "hyperbook-page"
                          (:h1 (views:esc "Topics"))
                          (:p (views:esc "Each page in this hyperbook wraps one HyperDoc topic object."))
                          (:p (views:esc "Page to topic relations are authored explicitly in HyperDoc page markup through links to this hyperbook. Topic to page relations are derived automatically through backlinks."))
                          (:p (views:esc "Optional editorial references remain available on topic objects, but they are not the primary mechanism for internal topic-to-page association."))))))

(views:defview views:👀items (hb topics-hyperbook)
  (declare (ignore hb))
  (ensure-topic-indexes)
  (-> (loop for title in (sort (alexandria:hash-table-keys *topics-by-title*) #'string<)
            collect (find-page *topics* title :signal-error? t))
      views:👀items
      (views:rename :title "Topic pages" :priority 3)))

(views:defview views:👀content (page topic-page)
  (let* ((topic (topic-of page))
         (backlinks (find-backlink-sources "topics" (id-of page)))
         (references (references-of topic)))
    (views:html-view :title "Content" :priority 1
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc (title-of topic)))
                            (:p (views:esc (summary-of topic)))
                            (:table :class "inspector-table"
                                    (:tr (:th "Stable key")
                                         (:td (:tt (views:esc (id-of topic)))))
                                    (:tr (:th "Topic object")
                                         (:td (views:object-ref topic))))
                            (:h2 (views:esc "Referencing pages"))
                            (if backlinks
                                (views:html-table backlinks)
                                (views:html (views:esc "None")))
                            (:h2 (views:esc "Editorial references"))
                            (if references
                                (views:html-table
                                 (mapcar #'list references))
                                (views:html (views:esc "None"))))))))

(views:defview 👀promotion-plan (page topic-page)
  (topic-localhost-fedwiki-promotion-plan-view
   (find-localhost-fedwiki-page-promotion-plan-for-topic-page page)
   "This topic page has a direct entry point into its localhost FedWiki promotion plan, including provenance, output status, and DMX dry-run evidence."))

(views:defview 👀topic-object (page topic-page)
  (let ((topic (topic-of page)))
    (views:html-view :title "Topic object" :priority 5
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc "Topic object"))
                            (:p (views:object-ref topic)))))))

(views:defview views:👀content (topic topic)
  (views:html-view :title "Topic" :priority 1
                   (views:add-asset-path "/hyperbook/"
                                         (asdf:system-relative-pathname
                                          :hyperbook
                                          "assets/hyperbook/"))
                   (views:include-css "/hyperbook/css/hyperbook.css")
                   (views:html
                    (:div :class "hyperbook-page"
                          (:h1 (views:esc (title-of topic)))
                          (:p (views:esc (summary-of topic)))
                          (:table :class "inspector-table"
                                  (:tr (:th "Stable key")
                                       (:td (:tt (views:esc (id-of topic)))))
                                  (:tr (:th "Topic page")
                                       (:td (views:object-ref
                                             (find-page *topics* (title-of topic) :signal-error? t)))))
                          (:h2 (views:esc "Editorial references"))
                          (if (references-of topic)
                              (views:html-table
                               (mapcar #'list (references-of topic)))
                              (views:html (views:esc "None")))))))

(views:defview 👀promotion-plan (topic topic)
  (topic-localhost-fedwiki-promotion-plan-view
   (find-localhost-fedwiki-page-promotion-plan-for-topic topic)
   "This topic object has a direct entry point into its localhost FedWiki promotion plan, including provenance, output status, and DMX dry-run evidence."))

(defun topic-registry-diagnostic-string (value)
  (cond
    ((null value) "")
    ((symbolp value)
     (if (keywordp value)
         (symbol-name value)
         (format nil "~A::~A"
                 (package-name (symbol-package value))
                 (symbol-name value))))
    (t (format nil "~A" value))))

(defun topic-registry-diagnostic-count-by (items key)
  (let ((counts (make-hash-table :test #'equal)))
    (dolist (item items)
      (incf (gethash (funcall key item) counts 0)))
    (sort (loop for key being the hash-keys of counts
                  using (hash-value count)
                collect (list key count))
          #'string<
          :key (lambda (row)
                 (topic-registry-diagnostic-string (first row))))))

(defun topic-registry-diagnostic-title-counts (diagnostic)
  (list
   (list "Initial registry titles"
         (length (topic-registry-diagnostic-initial-titles-of diagnostic)))
   (list "After first rebuild"
         (length (topic-registry-diagnostic-first-rebuild-titles-of diagnostic)))
   (list "After second rebuild"
         (length (topic-registry-diagnostic-second-rebuild-titles-of diagnostic)))
   (list "With cached signature provider"
         (length (topic-registry-diagnostic-cached-provider-titles-of
                  diagnostic)))
   (list "With signature provider disabled"
         (length (topic-registry-diagnostic-nil-provider-titles-of
                  diagnostic)))
   (list "Current registry titles"
         (length (topic-registry-diagnostic-current-titles-of diagnostic)))))

(defun topic-registry-diagnostic-render-title-list (titles &key (limit 80))
  (views:html
   (:p (:tt (views:esc (format nil "~D titles" (length titles)))))
   (:ul
    (loop for title in titles
          for index from 0
          while (< index limit)
          do (views:html
              (:li (views:esc (or title "<untitled>")))))
    (when (> (length titles) limit)
      (views:html
       (:li (views:esc (format nil "... ~D more"
                               (- (length titles) limit)))))))))

(views:defview 👀overview (diagnostic topic-registry-diagnostic)
  (let ((constructor-calls
          (topic-registry-diagnostic-constructor-calls-of diagnostic)))
    (views:html-view
     :title "Overview"
     :priority 1
     (views:add-asset-path "/hyperbook/"
                           (asdf:system-relative-pathname
                            :hyperbook
                            "assets/hyperbook/"))
     (views:include-css "/hyperbook/css/hyperbook.css")
     (views:html
      (:div :class "hyperbook-page"
            (:h1 (views:esc "Topic registry diagnostic"))
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Diagnostic id"))
                         (:td (:tt (views:esc
                                    (topic-registry-diagnostic-id-of
                                     diagnostic)))))
                    (:tr (:th (views:esc "Initial index state"))
                         (:td (:tt (views:esc
                                    (topic-registry-diagnostic-string
                                     (topic-registry-diagnostic-initial-index-state-of
                                      diagnostic))))))
                    (:tr (:th (views:esc "Loaded topic files"))
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (length
                                             (topic-registry-diagnostic-loaded-topic-files-of
                                              diagnostic)))))))
                    (:tr (:th (views:esc "Discovered constructors"))
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (length
                                             (topic-registry-diagnostic-discovered-constructors-of
                                              diagnostic)))))))
                    (:tr (:th (views:esc "Constructor call records"))
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (length constructor-calls)))))))
            (:h2 (views:esc "Registry snapshots"))
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Snapshot"))
                         (:th (views:esc "Title count")))
                    (loop for (label count) in
                          (topic-registry-diagnostic-title-counts diagnostic)
                          do (views:html
                              (:tr (:td (views:esc label))
                                   (:td (:tt (views:esc
                                              (format nil "~D" count))))))))
            (:h2 (views:esc "Constructor statuses"))
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Mode"))
                         (:th (views:esc "Status"))
                         (:th (views:esc "Count")))
                    (loop for (mode-status count)
                          in (topic-registry-diagnostic-count-by
                              constructor-calls
                              (lambda (call)
                                (list (topic-constructor-call-mode-of call)
                                      (topic-constructor-call-status-of call))))
                          do (destructuring-bind (mode status) mode-status
                               (views:html
                                (:tr (:td (:tt (views:esc
                                                (topic-registry-diagnostic-string
                                                 mode))))
                                     (:td (:tt (views:esc
                                                (topic-registry-diagnostic-string
                                                 status))))
                                     (:td (:tt (views:esc
                                                (format nil "~D" count)))))))))
            (:h2 (views:esc "Recommendation"))
            (:p (views:esc
                 (topic-registry-diagnostic-recommended-repair-of
                  diagnostic))))))))

(views:defview 👀loaded-topic-files
    (diagnostic topic-registry-diagnostic)
  (let ((topicmap
          (topic-registry-diagnostic-topic-files-topicmap diagnostic)))
    (views:html-view
     :title "Loaded topic files"
     :priority 2
     (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Path"))
                   (:th (views:esc "Status"))
                   (:th (views:esc "Factories")))
              (loop for file in
                    (topic-files-topicmap-source-files-of topicmap)
                    do (views:html
                        (:tr
                         (:td (views:object-ref
                               file
                               :display
                               (namestring
                                (topic-source-file-pathname-of file))))
                         (:td (:tt (views:esc
                                    (topic-registry-diagnostic-string
                                     (topic-source-file-status-of file)))))
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (length
                                             (topic-source-file-factories-of
                                              file))))))))))))))

(views:defview 👀constructors (diagnostic topic-registry-diagnostic)
  (views:html-view
   :title "Constructors"
   :priority 3
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Symbol"))
                 (:th (views:esc "Mode"))
                 (:th (views:esc "Status"))
                 (:th (views:esc "Title"))
                 (:th (views:esc "Value type"))
                 (:th (views:esc "Condition")))
            (loop for call in
                  (topic-registry-diagnostic-constructor-calls-of diagnostic)
                  do (views:html
                      (:tr
                       (:td (:tt (views:esc
                                  (topic-registry-diagnostic-string
                                   (topic-constructor-call-symbol-of call)))))
                       (:td (:tt (views:esc
                                  (topic-registry-diagnostic-string
                                   (topic-constructor-call-mode-of call)))))
                       (:td (:tt (views:esc
                                  (topic-registry-diagnostic-string
                                   (topic-constructor-call-status-of call)))))
                       (:td (views:esc
                             (or (topic-constructor-call-title-of call)
                                 "")))
                       (:td (:tt (views:esc
                                  (topic-registry-diagnostic-string
                                   (topic-constructor-call-value-type-of
                                    call)))))
                       (:td
                        (:tt (views:esc
                              (if (topic-constructor-call-condition-type-of
                                   call)
                                  (format nil "~A: ~A"
                                          (topic-registry-diagnostic-string
                                           (topic-constructor-call-condition-type-of
                                            call))
                                          (topic-constructor-call-condition-message-of
                                           call))
                                  "")))))))))))

(views:defview 👀topics (diagnostic topic-registry-diagnostic)
  (views:html-view
   :title "Registry titles"
   :priority 4
   (views:html
    (:h2 (views:esc "Current registry titles"))
    (topic-registry-diagnostic-render-title-list
     (topic-registry-diagnostic-current-titles-of diagnostic)
     :limit 200)
    (:h2 (views:esc "Initial titles"))
    (topic-registry-diagnostic-render-title-list
     (topic-registry-diagnostic-initial-titles-of diagnostic)
     :limit 80)
    (:h2 (views:esc "After first rebuild"))
    (topic-registry-diagnostic-render-title-list
     (topic-registry-diagnostic-first-rebuild-titles-of diagnostic)
     :limit 80))))

(views:defview 👀sqlite-status (diagnostic topic-registry-diagnostic)
  (views:html-view
   :title "SQLite status"
   :priority 5
   (views:html
    (:p (views:esc
         "The Topics HyperBook uses the in-image topic registry, not these SQLite databases. These counts are shown only to keep the source-artifact and path-evidence stores separate from the topic registry diagnosis."))
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Database"))
                 (:th (views:esc "Path"))
                 (:th (views:esc "Exists"))
                 (:th (views:esc "Tables")))
            (loop for status in
                  (topic-registry-diagnostic-sqlite-statuses-of diagnostic)
                  do (views:html
                      (:tr
                       (:td (:tt (views:esc
                                  (topic-registry-diagnostic-string
                                   (getf status :name)))))
                       (:td (:tt (views:esc (getf status :path))))
                       (:td (:tt (views:esc
                                  (if (getf status :exists-p)
                                      "yes"
                                      "no"))))
                       (:td
                        (if (getf status :tables)
                            (views:html
                             (:table :class "inspector-table"
                                     (:tr (:th (views:esc "Table"))
                                          (:th (views:esc "Count")))
                                     (loop for table in (getf status :tables)
                                           do (views:html
                                               (:tr
                                                (:td (:tt (views:esc
                                                           (getf table :table))))
                                                (:td (:tt (views:esc
                                                           (or (getf table
                                                                     :count)
                                                               "")))))))))
                            (views:html (views:esc "n/a")))))))))))
