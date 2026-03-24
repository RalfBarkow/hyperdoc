;;;; Inspector views for the read-only Zotero bridge
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun zotero-keyword-label (value)
  (when value
    (string-downcase
     (substitute #\Space #\- (symbol-name value)))))

(defun zotero-yes-no (value)
  (if value "yes" "no"))

(defun zotero-path-string (pathname)
  (and pathname
       (hyperdoc::pathname-namestring-or-nil pathname)))

(defun zotero-query-display-attempt (query)
  (hyperdoc::normalize-zotero-query-attempt
   query
   :attempted-operation 'hyperdoc::zotero-query-attempt-rows-of
   :receiver (and query (hyperdoc::zotero-query-selected-attempt-of query))
   :higher-level-intent
   (and query
        (list :inspect-zotero-query (hyperdoc::zotero-query-name-of query)))
   :repair-hint "Inspect query evidence before assuming a selected SQLite attempt exists."))

(defun zotero-query-row-count (query)
  (length (or (hyperdoc::zotero-query-protocol-rows-of
               (zotero-query-display-attempt query))
              nil)))

(defmethod views:text-representation ((bridge hyperdoc::zotero-library-bridge))
  (format nil "Zotero bridge (~A)"
          (or (zotero-path-string (hyperdoc::zotero-db-path-of bridge))
              "no db")))

(defmethod views:title-bar-action-buttons ((bridge hyperdoc::zotero-library-bridge))
  (let ((demo-title (hyperdoc::mind-and-mechanism-zotero-demo-title)))
    (views:html
      (views:action-button
       (format nil "Resolve ~A" demo-title)
       (views:thunk
         (hyperdoc::resolve-zotero-title-to-local-pdf-report
          demo-title
          :bridge bridge))
       "Run the narrow title-to-local-PDF report through this configured bridge."))))

(views:defview 👀overview (bridge hyperdoc::zotero-library-bridge)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Zotero DB path"))
               (:td (:code
                     (views:esc
                      (or (zotero-path-string
                           (hyperdoc::zotero-db-path-of bridge))
                          "")))))
              (:tr
               (:td (views:esc "DB exists"))
               (:td (:tt
                     (views:esc
                      (zotero-yes-no
                       (hyperdoc::zotero-db-exists-p bridge))))))
              (:tr
               (:td (views:esc "Storage root"))
               (:td (:code
                     (views:esc
                      (or (zotero-path-string
                           (hyperdoc::zotero-storage-root-of bridge))
                          "")))))
              (:tr
               (:td (views:esc "Storage root exists"))
               (:td (:tt
                     (views:esc
                      (zotero-yes-no
                       (hyperdoc::zotero-storage-root-exists-p bridge))))))
              (:tr
               (:td (views:esc "sqlite3 program"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-sqlite-program-of bridge)
                          "")))))
              (:tr
               (:td (views:esc "Configured note roots"))
               (:td (views:object-ref
                     (mapcar #'zotero-path-string
                             (hyperdoc::zotero-note-roots-of bridge)))))
              (:tr
               (:td (views:esc "Existing note roots"))
               (:td (views:object-ref
                     (mapcar #'zotero-path-string
                             (hyperdoc::zotero-existing-note-roots bridge)))))
              (:tr
               (:td (views:esc "Demo report"))
               (:td (views:object-ref
                     (hyperdoc::resolve-zotero-title-to-local-pdf-report
                      (hyperdoc::mind-and-mechanism-zotero-demo-title)
                      :bridge bridge))))))))

(defmethod views:text-representation ((query hyperdoc::zotero-title-query))
  (format nil "Zotero title query ~A (~A, ~D hits)"
          (hyperdoc::zotero-title-query-text-of query)
          (zotero-keyword-label
           (hyperdoc::zotero-title-query-match-mode-of query))
          (length (hyperdoc::zotero-title-query-matched-items-of query))))

(views:defview 👀overview (query hyperdoc::zotero-title-query)
  (let ((attempt (zotero-query-display-attempt query)))
    (views:html-view :title "Overview" :priority 1
      (views:html
        (:table :class "inspector-table"
                (:tr
                 (:td (views:esc "Query text"))
                 (:td (:tt
                       (views:esc
                        (hyperdoc::zotero-title-query-text-of query)))))
                (:tr
                 (:td (views:esc "Match mode"))
                 (:td (:tt
                       (views:esc
                        (zotero-keyword-label
                         (hyperdoc::zotero-title-query-match-mode-of query))))))
                (:tr
                 (:td (views:esc "Bridge"))
                 (:td (views:object-ref
                       (hyperdoc::zotero-title-query-bridge-of query))))
                (:tr
                 (:td (views:esc "Selected attempt"))
                 (:td (views:object-ref attempt)))
                (:tr
                 (:td (views:esc "Matched items"))
                 (:td (views:object-ref
                       (hyperdoc::zotero-title-query-matched-items-of query))))
                (:tr
                 (:td (views:esc "Raw row count"))
                 (:td (views:object-ref
                       (zotero-query-row-count query)))))))))

(defmethod views:text-representation ((query hyperdoc::zotero-item-id-query))
  (format nil "Zotero item-id query ~A (~A)"
          (hyperdoc::zotero-item-id-query-item-id-of query)
          (if (hyperdoc::zotero-item-id-query-matched-item-of query)
              "hit"
              "miss")))

(views:defview 👀overview (query hyperdoc::zotero-item-id-query)
  (let ((attempt (zotero-query-display-attempt query)))
    (views:html-view :title "Overview" :priority 1
      (views:html
        (:table :class "inspector-table"
                (:tr
                 (:td (views:esc "Item ID"))
                 (:td (views:object-ref
                       (hyperdoc::zotero-item-id-query-item-id-of query))))
                (:tr
                 (:td (views:esc "Bridge"))
                 (:td (views:object-ref
                       (hyperdoc::zotero-item-id-query-bridge-of query))))
                (:tr
                 (:td (views:esc "Selected attempt"))
                 (:td (views:object-ref attempt)))
                (:tr
                 (:td (views:esc "Matched item"))
                 (:td (views:object-ref
                       (hyperdoc::zotero-item-id-query-matched-item-of query))))
                (:tr
                 (:td (views:esc "Raw row count"))
                 (:td (views:object-ref
                       (zotero-query-row-count query)))))))))

(defmethod views:text-representation ((query hyperdoc::zotero-query-evidence))
  (let ((attempt (zotero-query-display-attempt query)))
    (format nil "Zotero query ~A (~A, ~D rows)"
            (hyperdoc::zotero-query-name-of query)
            (if (typep attempt 'hyperdoc::zotero-query-attempt)
                (zotero-keyword-label
                 (hyperdoc::zotero-query-attempt-access-mode-of attempt))
                "error")
            (zotero-query-row-count query))))

(defmethod views:text-representation ((attempt hyperdoc::zotero-query-attempt))
  (format nil "SQLite ~A (~A)"
          (zotero-keyword-label
           (hyperdoc::zotero-query-attempt-access-mode-of attempt))
          (zotero-keyword-label
           (hyperdoc::zotero-query-attempt-status-of attempt))))

(views:defview 👀overview (query hyperdoc::zotero-query-evidence)
  (let ((attempt (zotero-query-display-attempt query)))
    (views:html-view :title "Overview" :priority 1
      (views:html
        (:table :class "inspector-table"
                (:tr
                 (:td (views:esc "Name"))
                 (:td (views:esc (hyperdoc::zotero-query-name-of query))))
                (:tr
                 (:td (views:esc "Selected attempt"))
                 (:td (views:object-ref attempt)))
                (:tr
                 (:td (views:esc "Selected access mode"))
                 (:td (:tt
                       (views:esc
                        (or (and (typep attempt 'hyperdoc::zotero-query-attempt)
                                 (zotero-keyword-label
                                  (hyperdoc::zotero-query-attempt-access-mode-of
                                   attempt)))
                            "none")))))
                (:tr
                 (:td (views:esc "Row count"))
                 (:td (views:object-ref
                       (zotero-query-row-count query))))
                (:tr
                 (:td (views:esc "Attempts"))
                 (:td (views:object-ref
                       (hyperdoc::zotero-query-attempts-of query)))))))))

(views:defview 👀raw-data (query hyperdoc::zotero-query-evidence)
  (let ((attempt (zotero-query-display-attempt query)))
    (views:html-view :title "Raw data" :priority 2
      (views:html
        (:table :class "inspector-table"
                (:tr
                 (:td (views:esc "SQL"))
                 (:td (:pre
                       (views:esc
                        (hyperdoc::zotero-query-sql-of query)))))
                (:tr
                 (:td (views:esc "Selected rows"))
                 (:td (views:object-ref
                       (hyperdoc::zotero-query-protocol-rows-of attempt))))
                (:tr
                 (:td (views:esc "Attempt details"))
                 (:td (views:object-ref
                       (mapcar (lambda (candidate)
                                 (list :access-mode
                                       (hyperdoc::zotero-query-attempt-access-mode-of
                                        candidate)
                                       :status
                                       (hyperdoc::zotero-query-attempt-status-of
                                        candidate)
                                       :exit-code
                                       (hyperdoc::zotero-query-attempt-exit-code-of
                                        candidate)
                                       :detail
                                       (hyperdoc::zotero-query-attempt-detail-of
                                        candidate)
                                       :command
                                       (hyperdoc::zotero-query-attempt-command-of
                                        candidate)))
                               (hyperdoc::zotero-query-attempts-of query))))))))))

(defmethod views:text-representation ((attempt hyperdoc::zotero-query-missing-attempt))
  (format nil "Missing Zotero attempt (~A)"
          (zotero-keyword-label
           (hyperdoc::zotero-query-missing-attempt-status-of attempt))))

(views:defview 👀overview (attempt hyperdoc::zotero-query-missing-attempt)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Attempted operation"))
               (:td (:tt
                     (views:esc
                      (prin1-to-string
                       (hyperdoc::zotero-query-missing-attempt-operation-of attempt))))))
              (:tr
               (:td (views:esc "Receiver"))
               (:td (views:object-ref
                     (hyperdoc::zotero-query-missing-attempt-receiver-of attempt))))
              (:tr
               (:td (views:esc "Arguments"))
               (:td (views:object-ref
                     (hyperdoc::zotero-query-missing-attempt-arguments-of attempt))))
              (:tr
               (:td (views:esc "Higher-level intent"))
               (:td (views:object-ref
                     (hyperdoc::zotero-query-missing-attempt-intent-of attempt))))
              (:tr
               (:td (views:esc "Status"))
               (:td (:tt
                     (views:esc
                      (zotero-keyword-label
                       (hyperdoc::zotero-query-missing-attempt-status-of attempt))))))
              (:tr
               (:td (views:esc "Detail"))
               (:td (:pre
                     (views:esc
                      (or (hyperdoc::zotero-query-missing-attempt-detail-of attempt)
                          "")))))
              (:tr
               (:td (views:esc "Repair hint"))
               (:td (views:esc
                     (or (hyperdoc::zotero-query-missing-attempt-repair-hint-of attempt)
                         ""))))
              (:tr
               (:td (views:esc "Metadata"))
               (:td (views:object-ref
                     (hyperdoc::zotero-query-protocol-metadata-of attempt))))))))

(defmethod views:text-representation ((item hyperdoc::zotero-item-hit))
  (format nil "Zotero item ~A ~A"
          (hyperdoc::zotero-item-id-of item)
          (hyperdoc::zotero-item-title-of item)))

(views:defview 👀overview (item hyperdoc::zotero-item-hit)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Item ID"))
               (:td (views:object-ref
                     (hyperdoc::zotero-item-id-of item))))
              (:tr
               (:td (views:esc "Item key"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-item-key-of item)
                          "")))))
              (:tr
               (:td (views:esc "Type"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-item-type-of item)
                          "")))))
              (:tr
               (:td (views:esc "Title"))
               (:td (views:esc
                     (hyperdoc::zotero-item-title-of item))))
              (:tr
               (:td (views:esc "DOI"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-item-doi-of item)
                          "")))))
              (:tr
               (:td (views:esc "Better BibTeX citekey"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-item-citation-key-of item)
                          "")))))
              (:tr
               (:td (views:esc "Date"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-item-date-of item)
                          "")))))
              (:tr
               (:td (views:esc "Attachments"))
               (:td (views:object-ref
                     (hyperdoc::zotero-item-attachments-of item))))
              (:tr
               (:td (views:esc "Raw row"))
               (:td (views:object-ref
                     (hyperdoc::zotero-item-raw-row-of item))))))))

(defmethod views:text-representation ((attachment hyperdoc::zotero-attachment-hit))
  (format nil "Zotero attachment ~A (~A)"
          (hyperdoc::zotero-attachment-item-id-of attachment)
          (zotero-keyword-label
           (hyperdoc::zotero-attachment-normalized-kind-of attachment))))

(views:defview 👀overview (attachment hyperdoc::zotero-attachment-hit)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Attachment item ID"))
               (:td (views:object-ref
                     (hyperdoc::zotero-attachment-item-id-of attachment))))
              (:tr
               (:td (views:esc "Parent item ID"))
               (:td (views:object-ref
                     (hyperdoc::zotero-attachment-parent-item-id-of attachment))))
              (:tr
               (:td (views:esc "Attachment key"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-attachment-key-of attachment)
                          "")))))
              (:tr
               (:td (views:esc "Link mode"))
               (:td (views:object-ref
                     (hyperdoc::zotero-attachment-link-mode-of attachment))))
              (:tr
               (:td (views:esc "Normalized kind"))
               (:td (:tt
                     (views:esc
                      (zotero-keyword-label
                       (hyperdoc::zotero-attachment-normalized-kind-of
                        attachment))))))
              (:tr
               (:td (views:esc "Content type"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-attachment-content-type-of attachment)
                          "")))))
              (:tr
               (:td (views:esc "Filename"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-attachment-filename-of attachment)
                          "")))))
              (:tr
               (:td (views:esc "Raw path"))
               (:td (:code
                     (views:esc
                      (or (hyperdoc::zotero-attachment-raw-path-of attachment)
                          "")))))
              (:tr
               (:td (views:esc "Raw row"))
               (:td (views:object-ref
                     (hyperdoc::zotero-attachment-raw-row-of attachment))))))))

(defmethod views:text-representation
    ((resolution hyperdoc::zotero-path-resolution-report))
  (format nil "Attachment path ~A"
          (or (zotero-path-string
               (hyperdoc::zotero-path-report-resolved-path-of resolution))
              (zotero-keyword-label
               (hyperdoc::zotero-path-report-failure-mode-of
                resolution))
              "unresolved")))

(views:defview 👀overview (resolution hyperdoc::zotero-path-resolution-report)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Item hit"))
               (:td (views:object-ref
                     (hyperdoc::zotero-path-report-item-hit-of resolution))))
              (:tr
               (:td (views:esc "Attachment"))
               (:td (views:object-ref
                     (hyperdoc::zotero-path-report-attachment-hit-of
                      resolution))))
              (:tr
               (:td (views:esc "Attachment mode"))
               (:td (:tt
                     (views:esc
                      (zotero-keyword-label
                       (hyperdoc::zotero-path-report-attachment-mode-of
                        resolution))))))
              (:tr
               (:td (views:esc "Attachment key"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-path-report-attachment-key-of
                           resolution)
                          "")))))
              (:tr
               (:td (views:esc "Storage-relative path"))
               (:td (:code
                     (views:esc
                      (or (hyperdoc::zotero-path-report-storage-relative-path-of
                           resolution)
                          "")))))
              (:tr
               (:td (views:esc "Resolved path"))
               (:td (:code
                     (views:esc
                      (or (zotero-path-string
                           (hyperdoc::zotero-path-report-resolved-path-of
                            resolution))
                          "")))))
              (:tr
               (:td (views:esc "Exists"))
               (:td (:tt
                     (views:esc
                      (zotero-yes-no
                       (hyperdoc::zotero-path-report-exists-p
                        resolution))))))
              (:tr
               (:td (views:esc "Failure mode"))
               (:td (:tt
                     (views:esc
                      (or (zotero-keyword-label
                           (hyperdoc::zotero-path-report-failure-mode-of
                            resolution))
                          "")))))
              (:tr
               (:td (views:esc "Detail"))
               (:td (views:esc
                     (or (hyperdoc::zotero-path-report-detail-of
                          resolution)
                         ""))))))))

(defmethod views:text-representation ((evidence hyperdoc::zotero-note-evidence))
  (format nil "Note evidence ~A (~D matches)"
          (or (zotero-path-string
               (hyperdoc::zotero-note-evidence-note-path-of evidence))
              "")
          (length (hyperdoc::zotero-note-evidence-matches-of evidence))))

(views:defview 👀overview (evidence hyperdoc::zotero-note-evidence)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Note path"))
               (:td (:code
                     (views:esc
                      (or (zotero-path-string
                           (hyperdoc::zotero-note-evidence-note-path-of evidence))
                          "")))))
              (:tr
               (:td (views:esc "Root"))
               (:td (:code
                     (views:esc
                      (or (and (hyperdoc::zotero-note-evidence-root-of evidence)
                               (zotero-path-string
                                (hyperdoc::zotero-note-evidence-root-of evidence)))
                          "")))))
              (:tr
               (:td (views:esc "Matches"))
               (:td (views:object-ref
                     (hyperdoc::zotero-note-evidence-matches-of evidence))))))))

(defmethod views:text-representation
    ((evidence hyperdoc::zotero-resolution-evidence))
  (format nil "Resolution evidence ~A (~A)"
          (or (hyperdoc::zotero-resolution-evidence-attachment-key-of evidence)
              "no attachment key")
          (zotero-keyword-label
           (or (hyperdoc::zotero-resolution-evidence-failure-mode-of evidence)
               :resolved))))

(views:defview 👀overview (evidence hyperdoc::zotero-resolution-evidence)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Item hit"))
               (:td (views:object-ref
                     (hyperdoc::zotero-resolution-evidence-item-hit-of evidence))))
              (:tr
               (:td (views:esc "Attachment hit"))
               (:td (views:object-ref
                     (hyperdoc::zotero-resolution-evidence-attachment-hit-of evidence))))
              (:tr
               (:td (views:esc "Path report"))
               (:td (views:object-ref
                     (hyperdoc::zotero-resolution-evidence-path-report-of evidence))))
              (:tr
               (:td (views:esc "Attachment mode"))
               (:td (:tt
                     (views:esc
                      (zotero-keyword-label
                       (hyperdoc::zotero-resolution-evidence-attachment-mode-of
                        evidence))))))
              (:tr
               (:td (views:esc "Attachment key"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::zotero-resolution-evidence-attachment-key-of
                           evidence)
                          "")))))
              (:tr
               (:td (views:esc "Storage-relative path"))
               (:td (:code
                     (views:esc
                      (or (hyperdoc::zotero-resolution-evidence-storage-relative-path-of
                           evidence)
                          "")))))
              (:tr
               (:td (views:esc "Resolved path"))
               (:td (:code
                     (views:esc
                      (or (zotero-path-string
                           (hyperdoc::zotero-resolution-evidence-resolved-path-of
                            evidence))
                          "")))))
              (:tr
               (:td (views:esc "Exists"))
               (:td (:tt
                     (views:esc
                      (zotero-yes-no
                       (hyperdoc::zotero-resolution-evidence-exists-p evidence))))))
              (:tr
               (:td (views:esc "Failure mode"))
               (:td (:tt
                     (views:esc
                      (or (zotero-keyword-label
                           (hyperdoc::zotero-resolution-evidence-failure-mode-of
                            evidence))
                          "")))))
              (:tr
               (:td (views:esc "Note evidence"))
               (:td (views:object-ref
                     (hyperdoc::zotero-resolution-evidence-note-evidence-of
                      evidence))))
              (:tr
               (:td (views:esc "Detail"))
               (:td (views:esc
                     (or (hyperdoc::zotero-resolution-evidence-detail-of evidence)
                         ""))))))))

(defmethod views:text-representation
    ((report hyperdoc::zotero-title-resolution-report))
  (format nil "Zotero title report ~A (~A)"
          (hyperdoc::zotero-report-query-title-of report)
          (zotero-keyword-label (hyperdoc::zotero-report-status-of report))))

(defmethod views:title-bar-action-buttons
    ((report hyperdoc::zotero-title-resolution-report))
  (views:html
    (views:action-button
     "Reload"
     (views:thunk
       (hyperdoc::resolve-zotero-title-to-local-pdf-report
        (hyperdoc::zotero-report-query-title-of report)
        :bridge (hyperdoc::zotero-report-bridge-of report)))
     "Re-run the same title lookup against the configured read-only Zotero bridge.")))

(views:defview 👀overview (report hyperdoc::zotero-title-resolution-report)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Query title"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::zotero-report-query-title-of report)))))
              (:tr
               (:td (views:esc "Title query"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-title-query-of report))))
              (:tr
               (:td (views:esc "Bridge"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-bridge-of report))))
              (:tr
               (:td (views:esc "Status"))
               (:td (:tt
                     (views:esc
                      (zotero-keyword-label
                       (hyperdoc::zotero-report-status-of report))))))
              (:tr
               (:td (views:esc "Failure mode"))
               (:td (:tt
                     (views:esc
                      (or (zotero-keyword-label
                           (hyperdoc::zotero-report-failure-mode-of report))
                          "")))))
              (:tr
               (:td (views:esc "Detail"))
               (:td (views:esc
                     (or (hyperdoc::zotero-report-detail-of report)
                         ""))))
              (:tr
               (:td (views:esc "Resolved path"))
               (:td (:code
                     (views:esc
                      (or (zotero-path-string
                           (hyperdoc::zotero-report-resolved-path-of report))
                          "")))))
              (:tr
               (:td (views:esc "Resolved path exists"))
               (:td (:tt
                     (views:esc
                      (zotero-yes-no
                       (hyperdoc::zotero-report-exists-p report))))))
              (:tr
               (:td (views:esc "Selected item"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-selected-item-of report))))
              (:tr
               (:td (views:esc "Selected attachment"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-selected-attachment-of report))))
              (:tr
               (:td (views:esc "Selected path resolution"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-selected-resolution-of report))))
              (:tr
               (:td (views:esc "Selected evidence"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-selected-evidence-of report))))
              (:tr
               (:td (views:esc "Item candidates"))
               (:td (views:object-ref
                     (length
                      (hyperdoc::zotero-report-item-candidates-of report)))))
              (:tr
               (:td (views:esc "Attachment candidates"))
               (:td (views:object-ref
                     (length
                      (hyperdoc::zotero-report-attachment-candidates-of
                       report)))))
              (:tr
               (:td (views:esc "Candidate PDF reports"))
               (:td (views:object-ref
                     (length
                      (hyperdoc::zotero-report-attachment-resolutions-of
                       report)))))
              (:tr
               (:td (views:esc "Note search"))
               (:td (:tt
                     (views:esc
                      (zotero-keyword-label
                       (hyperdoc::zotero-report-note-search-status-of
                        report))))))
              (:tr
               (:td (views:esc "Note files searched"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-note-files-searched-of
                      report))))
              (:tr
               (:td (views:esc "Note evidence"))
               (:td (views:object-ref
                     (length
                      (hyperdoc::zotero-report-note-evidence-of
                       report)))))
              (:tr
               (:td (views:esc "Candidate evidence"))
               (:td (views:object-ref
                     (length
                      (hyperdoc::zotero-report-candidate-evidence-of
                       report)))))))))

(views:defview 👀candidates (report hyperdoc::zotero-title-resolution-report)
  (views:html-view :title "Candidates" :priority 2
    (views:html
      (:h3 (views:esc "Bibliographic items"))
      (:table :class "inspector-table"
              (:tr
               (:th (views:esc "Item ID"))
               (:th (views:esc "Key"))
               (:th (views:esc "Type"))
               (:th (views:esc "Title"))
               (:th (views:esc "DOI"))
               (:th (views:esc "Citekey")))
              (dolist (item (hyperdoc::zotero-report-item-candidates-of report))
                (views:html
                  (:tr
                   (:td (views:object-ref
                         (hyperdoc::zotero-item-id-of item)))
                   (:td (views:object-ref item))
                   (:td (views:esc
                         (or (hyperdoc::zotero-item-type-of item)
                             "")))
                   (:td (views:esc
                         (hyperdoc::zotero-item-title-of item)))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::zotero-item-doi-of item)
                              ""))))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::zotero-item-citation-key-of item)
                              ""))))))))
      (:h3 (views:esc "Candidate PDF reports"))
      (:table :class "inspector-table"
              (:tr
               (:th (views:esc "Item"))
               (:th (views:esc "Attachment"))
               (:th (views:esc "Mode"))
               (:th (views:esc "Attachment key"))
               (:th (views:esc "Storage-relative path"))
               (:th (views:esc "Resolved path"))
               (:th (views:esc "Exists"))
               (:th (views:esc "Failure mode")))
              (dolist (resolution
                       (hyperdoc::zotero-report-attachment-resolutions-of report))
                (let ((attachment
                        (hyperdoc::zotero-path-report-attachment-hit-of
                         resolution)))
                  (views:html
                    (:tr
                     (:td (views:object-ref
                           (hyperdoc::zotero-path-report-item-hit-of resolution)))
                     (:td (views:object-ref attachment))
                     (:td (:tt
                           (views:esc
                            (zotero-keyword-label
                             (hyperdoc::zotero-path-report-attachment-mode-of
                              resolution)))))
                     (:td (:tt
                           (views:esc
                            (or (hyperdoc::zotero-path-report-attachment-key-of
                                 resolution)
                                ""))))
                     (:td (:code
                           (views:esc
                            (or (hyperdoc::zotero-path-report-storage-relative-path-of
                                 resolution)
                                ""))))
                     (:td (:code
                           (views:esc
                            (or (zotero-path-string
                                 (hyperdoc::zotero-path-report-resolved-path-of
                                  resolution))
                                ""))))
                     (:td (:tt
                           (views:esc
                            (zotero-yes-no
                             (hyperdoc::zotero-path-report-exists-p
                              resolution)))))
                     (:td (:tt
                           (views:esc
                            (or (zotero-keyword-label
                                 (hyperdoc::zotero-path-report-failure-mode-of
                                  resolution))
                                ""))))))))))))

(views:defview 👀evidence-chain (report hyperdoc::zotero-title-resolution-report)
  (views:html-view :title "Evidence chain" :priority 3
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Selected evidence"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-selected-evidence-of report))))
              (:tr
               (:td (views:esc "Chosen chain"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-evidence-chain-of report))))
              (:tr
               (:td (views:esc "Note evidence"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-note-evidence-of report))))
              (:tr
               (:td (views:esc "Candidate evidence"))
               (:td (views:object-ref
                     (hyperdoc::zotero-report-candidate-evidence-of report))))))))

(views:defview 👀raw-data (report hyperdoc::zotero-title-resolution-report)
  (views:html-view :title "Raw data" :priority 4
    (let ((item-query (hyperdoc::zotero-report-item-query-of report))
          (attachment-query (hyperdoc::zotero-report-attachment-query-of report)))
      (views:html
        (:table :class "inspector-table"
                (:tr
                 (:td (views:esc "Item query"))
                 (:td (views:object-ref item-query)))
                (:tr
                 (:td (views:esc "Attachment query"))
                 (:td (views:object-ref
                       (or attachment-query "not run"))))
                (:tr
                 (:td (views:esc "Raw item rows"))
                 (:td (views:object-ref
                       (and item-query
                            (hyperdoc::zotero-query-selected-attempt-of
                             item-query)
                            (hyperdoc::zotero-query-attempt-rows-of
                             (hyperdoc::zotero-query-selected-attempt-of
                              item-query)))))
                (:tr
                 (:td (views:esc "Raw attachment rows"))
                 (:td (views:object-ref
                       (and attachment-query
                            (hyperdoc::zotero-query-selected-attempt-of
                             attachment-query)
                            (hyperdoc::zotero-query-attempt-rows-of
                             (hyperdoc::zotero-query-selected-attempt-of
                              attachment-query))))))))))))
