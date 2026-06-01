;;;; Inspector views for the topic source files topicmap.

(in-package :hyperdoc/inspector)

(defun topic-files-topicmap-include-hyperbook-css ()
  (views:add-asset-path "/hyperbook/"
                        (asdf:system-relative-pathname
                         :hyperbook
                         "assets/hyperbook/"))
  (views:include-css "/hyperbook/css/hyperbook.css"))

(defun topic-files-topicmap-string (value)
  (cond
    ((null value) "")
    ((keywordp value) (string-downcase (symbol-name value)))
    ((symbolp value)
     (if (symbol-package value)
         (format nil "~A::~A"
                 (package-name (symbol-package value))
                 (symbol-name value))
         (symbol-name value)))
    (t (format nil "~A" value))))

(defun topic-files-topicmap-table-counts-or-empty (topicmap)
  (handler-case
      (hyperdoc::topic-files-topicmap-sqlite-table-counts topicmap)
    (condition (condition)
      (list (list :table "unavailable"
                  :count (princ-to-string condition))))))

(defun topic-files-topicmap-factories (topicmap)
  (hyperdoc::topic-source-file-factory-records
   (hyperdoc::topic-files-topicmap-source-files-of topicmap)))

(defun topic-files-topicmap-source-file-display (file)
  (namestring (hyperdoc::topic-source-file-pathname-of file)))

(defun topic-files-topicmap-render-factory-row (record)
  (views:html
   (:tr
    (:td (views:object-ref
          record
          :display (hyperdoc::topic-factory-source-record-label record)))
    (:td (:tt (views:esc
               (topic-files-topicmap-string
                (hyperdoc::topic-factory-source-record-status-of record)))))
    (:td (:tt (views:esc
               (or (hyperdoc::topic-factory-source-record-topic-id-of record)
                   ""))))
    (:td (views:esc
          (or (hyperdoc::topic-factory-source-record-topic-title-of record)
              "")))
    (:td (:tt (views:esc
               (format nil "~D"
                       (hyperdoc::topic-factory-source-record-form-index-of
                        record))))))))

(defun topic-files-topicmap-render-topic-row (record)
  (views:html
   (:tr
    (:td (:tt (views:esc
               (or (hyperdoc::topic-factory-source-record-topic-id-of record)
                   ""))))
    (:td (views:esc
          (or (hyperdoc::topic-factory-source-record-topic-title-of record)
              "")))
    (:td (views:esc
          (or (hyperdoc::topic-factory-source-record-topic-summary-of record)
              "")))
    (:td (views:object-ref
          record
          :display (hyperdoc::topic-factory-source-record-label record))))))

(defun topic-files-topicmap-render-reference-row
    (record reference index)
  (views:html
   (:tr
    (:td (views:esc reference))
    (:td (:tt (views:esc (format nil "~D" index))))
    (:td (views:object-ref
          record
          :display (hyperdoc::topic-factory-source-record-label record)))
    (:td (views:esc
          (or (hyperdoc::topic-factory-source-record-topic-title-of record)
              ""))))))

(views:defview 👀overview (topicmap hyperdoc:topic-files-topicmap)
  (let* ((files (hyperdoc::topic-files-topicmap-source-files-of topicmap))
         (factories (topic-files-topicmap-factories topicmap))
         (static-topics
           (remove-if-not
            (lambda (record)
              (hyperdoc::topic-factory-source-record-topic-id-of record))
            factories)))
    (views:html-view
     :title "Overview"
     :priority 1
     (topic-files-topicmap-include-hyperbook-css)
     (views:html
      (:div :class "hyperbook-page"
            (:h1 (views:esc (hyperdoc::topic-files-topicmap-title-of topicmap)))
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "SQLite database"))
                         (:td (:tt (views:esc
                                    (namestring
                                     (hyperdoc::topic-files-topicmap-db-path-of
                                      topicmap))))))
                    (:tr (:th (views:esc "Materialization status"))
                         (:td (:tt (views:esc
                                    (topic-files-topicmap-string
                                     (hyperdoc::topic-files-topicmap-materialization-status-of
                                      topicmap))))))
                    (:tr (:th (views:esc "Source files"))
                         (:td (:tt (views:esc (format nil "~D" (length files))))))
                    (:tr (:th (views:esc "Factories"))
                         (:td (:tt (views:esc
                                    (format nil "~D" (length factories))))))
                    (:tr (:th (views:esc "Static topic nodes"))
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (length static-topics)))))))
            (:p (views:esc
                 "The object separates parsed source records from the SQLite-backed projection payload. The Topicmap view reads the persisted rows and renders a renderer-neutral :nodes/:edges payload.")))))))

(views:defview 👀files (topicmap hyperdoc:topic-files-topicmap)
  (views:html-view
   :title "Files"
   :priority 2
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Source file"))
                 (:th (views:esc "Status"))
                 (:th (views:esc "Forms"))
                 (:th (views:esc "Factories"))
                 (:th (views:esc "Packages")))
            (loop for file in
                  (hyperdoc::topic-files-topicmap-source-files-of topicmap)
                  do (views:html
                      (:tr
                       (:td (views:object-ref
                             file
                             :display
                             (topic-files-topicmap-source-file-display file)))
                       (:td (:tt (views:esc
                                  (topic-files-topicmap-string
                                   (hyperdoc::topic-source-file-status-of
                                    file)))))
                       (:td (:tt (views:esc
                                  (format nil "~D"
                                          (hyperdoc::topic-source-file-form-count-of
                                           file)))))
                       (:td (:tt (views:esc
                                  (format nil "~D"
                                          (length
                                           (hyperdoc::topic-source-file-factories-of
                                            file))))))
                       (:td (:tt (views:esc
                                  (format nil "~{~A~^, ~}"
                                          (hyperdoc::topic-source-file-in-packages-of
                                           file))))))))))))

(views:defview 👀factories (topicmap hyperdoc:topic-files-topicmap)
  (views:html-view
   :title "Factories"
   :priority 3
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Factory"))
                 (:th (views:esc "Status"))
                 (:th (views:esc "Topic id"))
                 (:th (views:esc "Title"))
                 (:th (views:esc "Form")))
            (loop for record in (topic-files-topicmap-factories topicmap)
                  do (topic-files-topicmap-render-factory-row record))))))

(views:defview 👀topics (topicmap hyperdoc:topic-files-topicmap)
  (views:html-view
   :title "Topics"
   :priority 4
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Topic id"))
                 (:th (views:esc "Title"))
                 (:th (views:esc "Summary"))
                 (:th (views:esc "Factory")))
            (loop for record in (topic-files-topicmap-factories topicmap)
                  when (or (hyperdoc::topic-factory-source-record-topic-id-of
                            record)
                           (hyperdoc::topic-factory-source-record-topic-title-of
                            record))
                    do (topic-files-topicmap-render-topic-row record))))))

(views:defview 👀references (topicmap hyperdoc:topic-files-topicmap)
  (views:html-view
   :title "References"
   :priority 5
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Reference"))
                 (:th (views:esc "Index"))
                 (:th (views:esc "Factory"))
                 (:th (views:esc "Topic")))
            (loop for record in (topic-files-topicmap-factories topicmap)
                  do (loop for reference in
                           (hyperdoc::topic-factory-source-record-topic-references-of
                            record)
                           for index from 0
                           do (topic-files-topicmap-render-reference-row
                               record
                               reference
                               index)))))))

(views:defview 👀topicmap (topicmap hyperdoc:topic-files-topicmap)
  (topicmap-view-html-view
   "Topicmap"
   6
   (hyperdoc:render-topicmap-view-of-object-html
    topicmap
    :asset-prefix "/dm6-elm/"
    :include-assets-p nil)))

(views:defview 👀sqlite (topicmap hyperdoc:topic-files-topicmap)
  (hyperdoc:materialize-topic-files-topicmap topicmap)
  (views:html-view
   :title "SQLite"
   :priority 7
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Database"))
                 (:td (:tt (views:esc
                            (namestring
                             (hyperdoc::topic-files-topicmap-db-path-of
                              topicmap))))))
            (:tr (:th (views:esc "Status"))
                 (:td (:tt (views:esc
                            (topic-files-topicmap-string
                             (hyperdoc::topic-files-topicmap-materialization-status-of
                              topicmap))))))
            (:tr (:th (views:esc "Detail"))
                 (:td (:tt (views:esc
                            (or (hyperdoc::topic-files-topicmap-materialization-detail-of
                                 topicmap)
                                ""))))))
    (:h2 (views:esc "Tables"))
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Table"))
                 (:th (views:esc "Rows")))
            (loop for row in
                  (topic-files-topicmap-table-counts-or-empty topicmap)
                  do (views:html
                      (:tr (:td (:tt (views:esc (getf row :table))))
                           (:td (:tt (views:esc
                                      (format nil "~A"
                                              (getf row :count))))))))))))

(views:defview 👀overview (file hyperdoc:topic-source-file)
  (views:html-view
   :title "Overview"
   :priority 1
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Path"))
                 (:td (:tt (views:esc
                            (namestring
                             (hyperdoc::topic-source-file-pathname-of
                              file))))))
            (:tr (:th (views:esc "Status"))
                 (:td (:tt (views:esc
                            (topic-files-topicmap-string
                             (hyperdoc::topic-source-file-status-of file))))))
            (:tr (:th (views:esc "Forms"))
                 (:td (:tt (views:esc
                            (format nil "~D"
                                    (hyperdoc::topic-source-file-form-count-of
                                     file))))))
            (:tr (:th (views:esc "Factories"))
                 (:td (:tt (views:esc
                            (format nil "~D"
                                    (length
                                     (hyperdoc::topic-source-file-factories-of
                                      file)))))))))))

(views:defview 👀factories (file hyperdoc:topic-source-file)
  (views:html-view
   :title "Factories"
   :priority 2
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Factory"))
                 (:th (views:esc "Status"))
                 (:th (views:esc "Topic id"))
                 (:th (views:esc "Title"))
                 (:th (views:esc "Form")))
            (loop for record in
                  (hyperdoc::topic-source-file-factories-of file)
                  do (topic-files-topicmap-render-factory-row record))))))

(views:defview 👀overview (record hyperdoc:topic-factory-source-record)
  (views:html-view
   :title "Overview"
   :priority 1
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Factory"))
                 (:td (:tt (views:esc
                            (hyperdoc::topic-factory-source-record-label
                             record)))))
            (:tr (:th (views:esc "Source file"))
                 (:td (views:object-ref
                       (hyperdoc::topic-factory-source-record-source-file-of
                        record)
                       :display
                       (topic-files-topicmap-source-file-display
                        (hyperdoc::topic-factory-source-record-source-file-of
                         record)))))
            (:tr (:th (views:esc "Status"))
                 (:td (:tt (views:esc
                            (topic-files-topicmap-string
                             (hyperdoc::topic-factory-source-record-status-of
                              record))))))
            (:tr (:th (views:esc "Topic id"))
                 (:td (:tt (views:esc
                            (or (hyperdoc::topic-factory-source-record-topic-id-of
                                 record)
                                "")))))
            (:tr (:th (views:esc "Title"))
                 (:td (views:esc
                       (or (hyperdoc::topic-factory-source-record-topic-title-of
                            record)
                           ""))))
            (:tr (:th (views:esc "Summary"))
                 (:td (views:esc
                       (or (hyperdoc::topic-factory-source-record-topic-summary-of
                            record)
                           ""))))))))

(views:defview 👀overview (diagnostic hyperdoc:topic-registry-diagnostic)
  (views:html-view
   :title "Overview"
   :priority 1
   (topic-files-topicmap-include-hyperbook-css)
   (views:html
    (:div :class "hyperbook-page"
          (:h1 (views:esc "Topic registry diagnostic"))
          (:table :class "inspector-table"
                  (:tr (:th (views:esc "Diagnostic id"))
                       (:td (:tt (views:esc
                                  (hyperdoc:topic-registry-diagnostic-id-of
                                   diagnostic)))))
                  (:tr (:th (views:esc "Loaded topic files"))
                       (:td (:tt (views:esc
                                  (format nil "~D"
                                          (length
                                           (hyperdoc:topic-registry-diagnostic-loaded-topic-files-of
                                            diagnostic)))))))
                  (:tr (:th (views:esc "Constructors"))
                       (:td (:tt (views:esc
                                  (format nil "~D"
                                          (length
                                           (hyperdoc:topic-registry-diagnostic-discovered-constructors-of
                                            diagnostic))))))))))))

(views:defview 👀loaded-topic-files
    (diagnostic hyperdoc:topic-registry-diagnostic)
  (let ((topicmap
          (hyperdoc::topic-registry-diagnostic-topic-files-topicmap
           diagnostic)))
    (views:html-view
     :title "Loaded topic files"
     :priority 2
     (topic-files-topicmap-include-hyperbook-css)
     (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Path"))
                   (:th (views:esc "Status"))
                   (:th (views:esc "Factories")))
              (loop for file in
                    (hyperdoc::topic-files-topicmap-source-files-of topicmap)
                    do (views:html
                        (:tr
                         (:td (views:object-ref
                               file
                               :display
                               (topic-files-topicmap-source-file-display file)))
                         (:td (:tt (views:esc
                                    (topic-files-topicmap-string
                                     (hyperdoc::topic-source-file-status-of
                                      file)))))
                         (:td (:tt (views:esc
                                    (format nil "~D"
                                            (length
                                             (hyperdoc::topic-source-file-factories-of
                                              file))))))))))))))

(views:defview 👀topicmap (diagnostic hyperdoc:topic-registry-diagnostic)
  (let ((topicmap
          (hyperdoc::topic-registry-diagnostic-topic-files-topicmap
           diagnostic)))
    (views:html-view
     :title "Topicmap"
     :priority 6
     (include-topicmap-view-assets)
     (views:html
      (:p (views:object-ref topicmap
                            :display "Inspect topic files topicmap"))
      (views:str
       (hyperdoc:render-topicmap-view-of-object-html
        topicmap
        :asset-prefix "/dm6-elm/"
        :include-assets-p nil))))))
