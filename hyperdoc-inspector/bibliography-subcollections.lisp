;;;; Inspector views for bibliography subcollections and authoring plans
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun bibliography-path-string (path)
  (and path
       (hyperdoc::pathname-namestring-or-nil path)))

(defun bibliography-keyword-label (value)
  (string-downcase
   (substitute #\Space #\- (symbol-name value))))

(defun bibliography-signal-row (signal)
  (list (hyperdoc::candidate-topic-signal-source-kind-of signal)
        (hyperdoc::candidate-topic-signal-field-of signal)
        (hyperdoc::candidate-topic-signal-display-title-of signal)
        (and (hyperdoc::candidate-topic-signal-entry-of signal)
             (hyperdoc::bibliography-entry-title-of
              (hyperdoc::candidate-topic-signal-entry-of signal)))))

(defun bibliography-display-list (strings)
  (or strings '()))

(defun bibliography-decision-match-summary (decision)
  (let ((topic (hyperdoc::authoring-decision-matched-existing-topic-title-of decision))
        (page (hyperdoc::authoring-decision-matched-existing-page-title-of decision)))
    (cond
      ((and topic page)
       (format nil "topic: ~A; page: ~A" topic page))
      (topic
       (format nil "topic: ~A" topic))
      (page
       (format nil "page: ~A" page))
      (t
       "none"))))

(defun bibliography-consequence-labels (decision)
  (mapcar #'bibliography-keyword-label
          (hyperdoc::authoring-decision-materialization-consequence-of decision)))

(defun bibliography-boolean-label (value)
  (cond
    ((eq value t) "yes")
    ((null value) "no")
    (t
     (format nil "~A" value))))

(defmethod views:text-representation ((status hyperdoc::zotero-backend-unavailable))
  (format nil "Zotero unavailable (~A)"
          (bibliography-keyword-label
           (hyperdoc::zotero-backend-unavailable-reason-of status))))

(views:defview 👀overview (status hyperdoc::zotero-backend-unavailable)
  (views:html-view :title "Unavailable" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Backend"))
                   (:td (:tt (views:esc "Zotero"))))
              (:tr (:td (views:esc "Operation"))
                   (:td (views:esc
                         (hyperdoc::zotero-backend-unavailable-operation-of status))))
              (:tr (:td (views:esc "Reason"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::zotero-backend-unavailable-reason-of status))))))
              (:tr (:td (views:esc "Configuration variable"))
                   (:td (:code
                         (views:esc
                          (hyperdoc::zotero-backend-unavailable-configuration-variable-of
                           status)))))
              (:tr (:td (views:esc "Configuration value"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::zotero-backend-unavailable-configuration-value-of
                               status)
                              "")))))
              (:tr (:td (views:esc "Message"))
                   (:td (views:esc
                         (hyperdoc::zotero-backend-unavailable-message-of status))))
              (:tr (:td (views:esc "Optional system"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::zotero-backend-unavailable-system-name-of status)))))))))

(defmethod views:text-representation ((subcollection hyperdoc::bibliography-subcollection))
  (format nil "Bibliography subcollection ~A (~D entries)"
          (hyperdoc::bibliography-collection-path-of
           (hyperdoc::bibliography-subcollection-collection-hit-of subcollection))
          (length (hyperdoc::bibliography-subcollection-entries-of subcollection))))

(defmethod views:title-bar-action-buttons ((subcollection hyperdoc::bibliography-subcollection))
  (views:html
    (views:action-button
     "Open authoring plan"
     (views:thunk
       (hyperdoc::ensure-bibliography-subcollection-authoring-plan subcollection))
     "Open the reviewed authoring-plan object for this bibliography subcollection.")))

(views:defview 👀collection-summary (subcollection hyperdoc::bibliography-subcollection)
  (views:html-view :title "Collection summary" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Source system"))
               (:td (:tt
                     (views:esc
                      (bibliography-keyword-label
                       (hyperdoc::bibliography-subcollection-source-system-of
                        subcollection))))))
              (:tr
               (:td (views:esc "Requested collection"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::bibliography-subcollection-query-text-of subcollection)))))
              (:tr
               (:td (views:esc "Resolved collection"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-subcollection-collection-hit-of
                      subcollection))))
              (:tr
               (:td (views:esc "Collection query"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-subcollection-collection-query-of
                      subcollection))))
              (:tr
               (:td (views:esc "Imported entries"))
               (:td (views:object-ref
                     (length
                      (hyperdoc::bibliography-subcollection-entries-of
                       subcollection)))))
              (:tr
               (:td (views:esc "Candidate topics"))
               (:td (views:object-ref
                     (length
                      (hyperdoc::ensure-bibliography-subcollection-candidate-topics
                       subcollection)))))
              (:tr
               (:td (views:esc "Authoring plan"))
               (:td
                (if-let (plan (hyperdoc::bibliography-subcollection-authoring-plan-of
                               subcollection))
                  (views:object-ref plan)
                  (views:html
                    (:tt
                     (views:esc "Deferred; use Open authoring plan."))))))))))

(views:defview 👀entries (subcollection hyperdoc::bibliography-subcollection)
  (views:html-view :title "Entries" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:th (views:esc "Item"))
               (:th (views:esc "Title"))
               (:th (views:esc "Authors"))
               (:th (views:esc "Year"))
               (:th (views:esc "Type"))
               (:th (views:esc "Tags")))
              (dolist (entry (hyperdoc::bibliography-subcollection-entries-of subcollection))
                (views:html
                  (:tr
                   (:td (views:object-ref entry))
                   (:td (views:esc
                         (or (hyperdoc::bibliography-entry-title-of entry) "")))
                   (:td (views:esc
                         (format nil "~{~A~^; ~}"
                                 (hyperdoc::bibliography-entry-authors-of entry))))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-entry-year-of entry)))
                   (:td (views:esc
                         (or (hyperdoc::bibliography-entry-work-type-of entry) "")))
                   (:td (views:esc
                         (format nil "~{~A~^; ~}"
                                 (hyperdoc::bibliography-entry-tags-of entry)))))))))))

(views:defview 👀candidate-topics (subcollection hyperdoc::bibliography-subcollection)
  (views:html-view :title "Candidate topics" :priority 3
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:th (views:esc "Candidate"))
               (:th (views:esc "Collection cues"))
               (:th (views:esc "Entry cues"))
               (:th (views:esc "Entries")))
              (dolist (candidate (hyperdoc::ensure-bibliography-subcollection-candidate-topics
                                  subcollection))
                (views:html
                  (:tr
                   (:td (views:object-ref candidate))
                   (:td (views:object-ref
                         (length
                          (hyperdoc::candidate-topic-collection-signals-of
                           candidate))))
                   (:td (views:object-ref
                         (length
                          (hyperdoc::candidate-topic-entry-signals-of candidate))))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-support-count-of
                          candidate))))))))))

(defmethod views:text-representation ((entry hyperdoc::bibliography-entry))
  (format nil "Bibliography entry ~A"
          (hyperdoc::bibliography-entry-title-of entry)))

(views:defview 👀overview (entry hyperdoc::bibliography-entry)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source system"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::bibliography-entry-source-system-of entry))))))
              (:tr (:td (views:esc "Collection path"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::bibliography-entry-collection-path-of entry)))))
              (:tr (:td (views:esc "Item ID"))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-entry-item-id-of entry))))
              (:tr (:td (views:esc "Item key"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::bibliography-entry-item-key-of entry)))))
              (:tr (:td (views:esc "Title"))
                   (:td (views:esc
                         (or (hyperdoc::bibliography-entry-title-of entry) ""))))
              (:tr (:td (views:esc "Authors"))
                   (:td (views:esc
                         (format nil "~{~A~^; ~}"
                                 (hyperdoc::bibliography-entry-authors-of entry)))))
              (:tr (:td (views:esc "Year"))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-entry-year-of entry))))
              (:tr (:td (views:esc "Type"))
                   (:td (views:esc
                         (or (hyperdoc::bibliography-entry-work-type-of entry) ""))))
              (:tr (:td (views:esc "Venue / publisher"))
                   (:td (views:esc
                         (or (hyperdoc::bibliography-entry-venue-of entry) ""))))
              (:tr (:td (views:esc "DOI"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::bibliography-entry-doi-of entry) "")))))
              (:tr (:td (views:esc "URL"))
                   (:td (:code
                         (views:esc
                          (or (hyperdoc::bibliography-entry-url-of entry) "")))))
              (:tr (:td (views:esc "Tags"))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-entry-tags-of entry))))))))

(views:defview 👀raw-data (entry hyperdoc::bibliography-entry)
  (views:html-view :title "Raw data" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Raw source text"))
                   (:td (:pre
                         (views:esc
                          (hyperdoc::bibliography-entry-raw-source-text-of entry)))))
              (:tr (:td (views:esc "Raw source row"))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-entry-raw-row-of entry))))
              (:tr (:td (views:esc "Author rows"))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-entry-author-rows-of entry))))
              (:tr (:td (views:esc "Tag rows"))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-entry-tag-rows-of entry))))))))

(defmethod views:text-representation ((signal hyperdoc::candidate-topic-signal))
  (format nil "~A cue ~A"
          (bibliography-keyword-label
           (hyperdoc::candidate-topic-signal-source-kind-of signal))
          (hyperdoc::candidate-topic-signal-display-title-of signal)))

(views:defview 👀overview (signal hyperdoc::candidate-topic-signal)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source kind"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::candidate-topic-signal-source-kind-of signal))))))
              (:tr (:td (views:esc "Field"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::candidate-topic-signal-field-of signal))))))
              (:tr (:td (views:esc "Display title"))
                   (:td (views:esc
                         (hyperdoc::candidate-topic-signal-display-title-of signal))))
              (:tr (:td (views:esc "Aliases"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-signal-aliases-of signal))))
              (:tr (:td (views:esc "Entry"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-signal-entry-of signal))))
              (:tr (:td (views:esc "Detail"))
                   (:td (views:esc
                         (or (hyperdoc::candidate-topic-signal-detail-of signal) ""))))))))

(defmethod views:text-representation ((candidate hyperdoc::candidate-topic))
  (format nil "Candidate topic ~A"
          (hyperdoc::candidate-topic-title-of candidate)))

(views:defview 👀overview (candidate hyperdoc::candidate-topic)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Candidate title"))
                   (:td (views:esc
                         (hyperdoc::candidate-topic-title-of candidate))))
              (:tr (:td (views:esc "Aliases"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-aliases-of candidate))))
              (:tr (:td (views:esc "Broader hints"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-broader-hints-of candidate))))
              (:tr (:td (views:esc "Collection-name cues"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-collection-signals-of candidate))))
              (:tr (:td (views:esc "Entry-derived cues"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-entry-signals-of candidate))))
              (:tr (:td (views:esc "Supporting entries"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-source-entries-of candidate))))
              (:tr (:td (views:esc "Editorial notes"))
                   (:td (views:object-ref
                         (hyperdoc::candidate-topic-editorial-notes-of candidate))))))))

(views:defview 👀evidence (candidate hyperdoc::candidate-topic)
  (views:html-view :title "Evidence" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Source"))
                   (:th (views:esc "Field"))
                   (:th (views:esc "Value"))
                   (:th (views:esc "Entry")))
              (dolist (signal (hyperdoc::candidate-topic-signals-of candidate))
                (destructuring-bind (source field value entry-title)
                    (bibliography-signal-row signal)
                  (views:html
                    (:tr (:td (views:esc
                               (bibliography-keyword-label source)))
                         (:td (views:esc
                               (bibliography-keyword-label field)))
                         (:td (views:esc value))
                         (:td (views:esc
                               (or entry-title "")))))))))))

(defmethod views:text-representation ((report hyperdoc::topic-comparison-report))
  (format nil "Topic comparison ~A (~A)"
          (hyperdoc::candidate-topic-title-of
           (hyperdoc::topic-comparison-report-candidate-topic-of report))
          (bibliography-keyword-label
           (hyperdoc::topic-comparison-report-status-of report))))

(views:defview 👀overview (report hyperdoc::topic-comparison-report)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Candidate"))
                   (:td (views:object-ref
                         (hyperdoc::topic-comparison-report-candidate-topic-of report))))
              (:tr (:td (views:esc "Status"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::topic-comparison-report-status-of report))))))
              (:tr (:td (views:esc "Exact title match"))
                   (:td (views:object-ref
                         (hyperdoc::topic-comparison-report-exact-match-of report))))
              (:tr (:td (views:esc "Alias matches"))
                   (:td (views:object-ref
                         (hyperdoc::topic-comparison-report-alias-matches-of report))))
              (:tr (:td (views:esc "Near-duplicate matches"))
                   (:td (views:object-ref
                         (hyperdoc::topic-comparison-report-near-duplicate-matches-of
                          report))))
              (:tr (:td (views:esc "Broader-topic matches"))
                   (:td (views:object-ref
                         (hyperdoc::topic-comparison-report-broader-topic-matches-of
                          report))))
              (:tr (:td (views:esc "Review notes"))
                   (:td (views:object-ref
                         (hyperdoc::topic-comparison-report-review-notes-of report))))))))

(defmethod views:text-representation ((decision hyperdoc::authoring-decision))
  (format nil "Authoring decision ~A (~A)"
          (hyperdoc::candidate-topic-title-of
           (hyperdoc::authoring-decision-candidate-topic-of decision))
          (bibliography-keyword-label
           (hyperdoc::authoring-decision-kind-of decision))))

(views:defview 👀overview (decision hyperdoc::authoring-decision)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Decision kind"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::authoring-decision-kind-of decision))))))
              (:tr (:td (views:esc "Canonical candidate title"))
                   (:td (views:object-ref
                         (hyperdoc::authoring-decision-candidate-topic-of decision))))
              (:tr (:td (views:esc "Matched existing topic/page"))
                   (:td (views:esc
                         (bibliography-decision-match-summary decision))))
              (:tr (:td (views:esc "Topic action"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::authoring-decision-topic-action-of decision))))))
              (:tr (:td (views:esc "Page action"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::authoring-decision-page-action-of decision))))))
              (:tr (:td (views:esc "Target topic"))
                   (:td (views:esc
                         (or (hyperdoc::authoring-decision-target-topic-title-of decision)
                             ""))))
              (:tr (:td (views:esc "Target page"))
                   (:td (views:esc
                         (or (hyperdoc::authoring-decision-target-page-title-of decision)
                             ""))))
              (:tr (:td (views:esc "Rationale"))
                   (:td (views:esc
                         (or (hyperdoc::authoring-decision-rationale-of decision)
                             ""))))
              (:tr (:td (views:esc "Materialization consequence"))
                   (:td (views:object-ref
                         (bibliography-display-list
                          (bibliography-consequence-labels decision)))))
              (:tr (:td (views:esc "Notes"))
                   (:td (views:object-ref
                         (hyperdoc::authoring-decision-notes-of decision))))))))

(views:defview 👀evidence (decision hyperdoc::authoring-decision)
  (views:html-view :title "Evidence" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source provenance evidence"))
                   (:td (views:object-ref
                         (bibliography-display-list
                          (hyperdoc::authoring-decision-source-provenance-evidence-of
                           decision)))))
              (:tr (:td (views:esc "Entry-title evidence"))
                   (:td (views:object-ref
                         (bibliography-display-list
                          (hyperdoc::authoring-decision-entry-title-evidence-of
                           decision)))))
              (:tr (:td (views:esc "Notes/keywords/tag evidence"))
                   (:td (views:object-ref
                         (bibliography-display-list
                          (hyperdoc::authoring-decision-notes-keywords-tag-evidence-of
                           decision)))))
              (:tr (:td (views:esc "Broader-neighborhood/editorial evidence"))
                   (:td (views:object-ref
                         (bibliography-display-list
                          (hyperdoc::authoring-decision-broader-neighborhood-evidence-of
                           decision)))))))))

(views:defview 👀touch-preview (decision hyperdoc::authoring-decision)
  (views:html-view :title "Touch preview" :priority 3
    (views:html
      (:pre
       (views:esc
        (format nil "~{~A~^~%~}"
                (or (hyperdoc::authoring-decision-repo-touch-preview-of decision)
                    '("= no direct repo write yet; keep as reviewed plan evidence"))))))))

(defmethod views:text-representation ((entry hyperdoc::bibliography-materialization-entry))
  (format nil "Materialization ~A"
          (bibliography-path-string
           (hyperdoc::bibliography-materialization-entry-target-path-of entry))))

(views:defview 👀overview (entry hyperdoc::bibliography-materialization-entry)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Kind"))
                   (:td (:tt
                         (views:esc
                          (bibliography-keyword-label
                           (hyperdoc::bibliography-materialization-entry-kind-of entry))))))
              (:tr (:td (views:esc "Target path"))
                   (:td (:code
                         (views:esc
                          (bibliography-path-string
                           (hyperdoc::bibliography-materialization-entry-target-path-of
                            entry))))))
              (:tr (:td (views:esc "Decision"))
                   (:td (views:object-ref
                         (hyperdoc::bibliography-materialization-entry-decision-of entry))))
              (:tr (:td (views:esc "Proposed repo touches"))
                   (:td (views:object-ref
                         (bibliography-display-list
                          (hyperdoc::bibliography-materialization-entry-repo-touch-preview-of
                           entry)))))
              (:tr (:td (views:esc "Existing"))
                   (:td (:tt
                         (views:esc
                          (if (hyperdoc::bibliography-materialization-entry-existing-p entry)
                              "yes"
                              "no")))))))))

(views:defview 👀preview (entry hyperdoc::bibliography-materialization-entry)
  (views:html-view :title "Preview" :priority 2
    (views:html
      (:div
       (:pre
        (views:esc
         (hyperdoc::bibliography-materialization-entry-preview-text-of entry)))
       (:h4 (views:esc "Proposed repo touches"))
       (:pre
        (views:esc
         (format nil "~{~A~^~%~}"
                 (or (hyperdoc::bibliography-materialization-entry-repo-touch-preview-of
                      entry)
                     '("= bundle-only preview")))))))))

(defmethod views:text-representation ((plan hyperdoc::hyperdoc-authoring-plan))
  (format nil "Bibliography authoring plan ~A"
          (hyperdoc::bibliography-collection-path-of
           (hyperdoc::bibliography-subcollection-collection-hit-of
            (hyperdoc::hyperdoc-authoring-plan-source-subcollection-of plan)))))

(defmethod views:title-bar-action-buttons ((plan hyperdoc::hyperdoc-authoring-plan))
  (views:html
    (views:action-button
     "Materialize bundle"
     (views:thunk
       (hyperdoc:materialize-bibliography-authoring-plan plan)
       plan)
     "Write the reviewed authoring bundle into the configured output root without patching hyperdoc/topics.lisp or authored pages directly.")))

(views:defview 👀collection-summary (plan hyperdoc::hyperdoc-authoring-plan)
  (let ((subcollection (hyperdoc::hyperdoc-authoring-plan-source-subcollection-of plan)))
    (views:html-view :title "Collection summary" :priority 1
      (views:html
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Source system"))
                     (:td (:tt
                           (views:esc
                            (bibliography-keyword-label
                             (hyperdoc::bibliography-subcollection-source-system-of
                              subcollection))))))
                (:tr (:td (views:esc "Collection path"))
                     (:td (:tt
                           (views:esc
                            (hyperdoc::bibliography-collection-path-of
                             (hyperdoc::bibliography-subcollection-collection-hit-of
                              subcollection))))))
                (:tr (:td (views:esc "Imported entries"))
                     (:td (views:object-ref
                           (length
                            (hyperdoc::bibliography-subcollection-entries-of
                             subcollection)))))
                (:tr (:td (views:esc "Output root"))
                     (:td (:code
                           (views:esc
                            (bibliography-path-string
                             (hyperdoc::hyperdoc-authoring-plan-output-root-of plan))))))
                (:tr (:td (views:esc "Editorial notes"))
                     (:td (views:object-ref
                           (hyperdoc::hyperdoc-authoring-plan-editorial-notes-of
                            plan)))))))))

(views:defview 👀existing-topic-matches (plan hyperdoc::hyperdoc-authoring-plan)
  (views:html-view :title "Existing-topic matches" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Candidate"))
                   (:th (views:esc "Status"))
                   (:th (views:esc "Existing topic")))
              (dolist (report (hyperdoc::hyperdoc-authoring-plan-comparison-reports-of plan))
                (let ((status (hyperdoc::topic-comparison-report-status-of report)))
                  (when (member status
                                '(:exact-title-match :alias-match
                                  :near-duplicate-match :broader-topic-review))
                    (views:html
                      (:tr (:td (views:object-ref
                                 (hyperdoc::topic-comparison-report-candidate-topic-of report)))
                           (:td (views:esc
                                 (bibliography-keyword-label status)))
                           (:td (views:esc
                                 (or (and (hyperdoc::topic-comparison-report-exact-match-of report)
                                          (hyperbook:title-of
                                           (hyperdoc::topic-comparison-report-exact-match-of report)))
                                     (and (first (hyperdoc::topic-comparison-report-alias-matches-of report))
                                          (hyperbook:title-of
                                           (first (hyperdoc::topic-comparison-report-alias-matches-of report))))
                                     (and (first (hyperdoc::topic-comparison-report-near-duplicate-matches-of report))
                                          (hyperbook:title-of
                                           (first (hyperdoc::topic-comparison-report-near-duplicate-matches-of report))))
                                     (and (first (hyperdoc::topic-comparison-report-broader-topic-matches-of report))
                                          (hyperbook:title-of
                                           (first (hyperdoc::topic-comparison-report-broader-topic-matches-of report))))
                                     ""))))))))))))

(views:defview 👀new-topics (plan hyperdoc::hyperdoc-authoring-plan)
  (views:html-view :title "New topics" :priority 3
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Candidate"))
                   (:th (views:esc "Collection cues"))
                   (:th (views:esc "Entry cues"))
                   (:th (views:esc "Decision")))
              (dolist (decision (hyperdoc::hyperdoc-authoring-plan-authoring-decisions-of plan))
                (when (member (hyperdoc::authoring-decision-topic-action-of decision)
                              '(:add-new-topic-factory
                                :leave-arrangement-only
                                :leave-unmaterialized))
                  (let ((candidate (hyperdoc::authoring-decision-candidate-topic-of decision)))
                    (views:html
                      (:tr (:td (views:object-ref candidate))
                           (:td (views:object-ref
                                 (mapcar #'hyperdoc::candidate-topic-signal-display-title-of
                                         (hyperdoc::candidate-topic-collection-signals-of
                                          candidate))))
                           (:td (views:object-ref
                                 (mapcar #'hyperdoc::candidate-topic-signal-display-title-of
                                         (hyperdoc::candidate-topic-entry-signals-of
                                          candidate))))
                           (:td (views:esc
                                 (bibliography-keyword-label
                                  (hyperdoc::authoring-decision-topic-action-of
                                   decision)))))))))))))

(views:defview 👀page-write-update-plan (plan hyperdoc::hyperdoc-authoring-plan)
  (views:html-view :title "Page write/update plan" :priority 4
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Candidate"))
                   (:th (views:esc "Decision kind"))
                   (:th (views:esc "Matched existing topic/page"))
                   (:th (views:esc "Source provenance evidence"))
                   (:th (views:esc "Entry-title evidence"))
                   (:th (views:esc "Notes/keywords/tag evidence"))
                   (:th (views:esc "Broader-neighborhood/editorial evidence"))
                   (:th (views:esc "Rationale"))
                   (:th (views:esc "Materialization consequence")))
              (dolist (decision (hyperdoc::hyperdoc-authoring-plan-authoring-decisions-of plan))
                (views:html
                  (:tr (:td (views:object-ref
                             (hyperdoc::authoring-decision-candidate-topic-of decision)))
                       (:td (:tt
                             (views:esc
                              (bibliography-keyword-label
                               (hyperdoc::authoring-decision-kind-of decision)))))
                       (:td (views:esc
                             (bibliography-decision-match-summary decision)))
                       (:td (views:object-ref
                             (bibliography-display-list
                              (hyperdoc::authoring-decision-source-provenance-evidence-of
                               decision))))
                       (:td (views:object-ref
                             (bibliography-display-list
                              (hyperdoc::authoring-decision-entry-title-evidence-of
                               decision))))
                       (:td (views:object-ref
                             (bibliography-display-list
                              (hyperdoc::authoring-decision-notes-keywords-tag-evidence-of
                               decision))))
                       (:td (views:object-ref
                             (bibliography-display-list
                              (hyperdoc::authoring-decision-broader-neighborhood-evidence-of
                               decision))))
                       (:td (views:esc
                             (or (hyperdoc::authoring-decision-rationale-of decision)
                                 "")))
                       (:td (views:object-ref
                             (bibliography-display-list
                              (bibliography-consequence-labels decision)))))))))))

(views:defview 👀materialization-preview (plan hyperdoc::hyperdoc-authoring-plan)
  (views:html-view :title "Materialization preview" :priority 5
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Kind"))
                   (:th (views:esc "Bundle target"))
                   (:th (views:esc "Proposed repo touches"))
                   (:th (views:esc "Preview")))
              (dolist (entry (hyperdoc::hyperdoc-authoring-plan-materialization-entries-of plan))
                (views:html
                  (:tr (:td (views:esc
                             (bibliography-keyword-label
                              (hyperdoc::bibliography-materialization-entry-kind-of entry))))
                       (:td (:code
                             (views:esc
                              (bibliography-path-string
                               (hyperdoc::bibliography-materialization-entry-target-path-of
                                entry)))))
                       (:td (:pre
                             (views:esc
                              (format nil "~{~A~^~%~}"
                                      (or (hyperdoc::bibliography-materialization-entry-repo-touch-preview-of
                                           entry)
                                          '("= bundle-only preview"))))))
                       (:td (views:object-ref entry)))))))))

(views:defview 👀execution-report (plan hyperdoc::hyperdoc-authoring-plan)
  (views:html-view :title "Execution report" :priority 6
    (let ((report (hyperdoc::hyperdoc-authoring-plan-execution-report-of plan)))
      (if report
          (views:html
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Kind"))
                         (:th (views:esc "Target")))
                    (dolist (entry report)
                      (views:html
                        (:tr (:td (views:esc
                                   (bibliography-keyword-label
                                    (getf entry :kind))))
                             (:td (:code
                                   (views:esc
                                    (bibliography-path-string
                                     (getf entry :target-path))))))))))
          (views:html
            (:p (views:esc
                 "Materialize the plan to write the review bundle and populate the execution report.")))))))

(defmethod views:text-representation ((report hyperdoc::bibliography-authoring-plan-standin-report))
  (format nil "Bibliography stand-in ~A (~A)"
          (hyperdoc::bibliography-standin-collection-name-of report)
          (hyperdoc::bibliography-standin-failure-classification-before-browser-of report)))

(views:defview 👀overview (report hyperdoc::bibliography-authoring-plan-standin-report)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Mode"))
               (:td (:tt
                     (views:esc
                      (bibliography-keyword-label
                       (hyperdoc::bibliography-standin-mode-of report))))))
              (:tr
               (:td (views:esc "Collection"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::bibliography-standin-collection-name-of report)))))
              (:tr
               (:td (views:esc "Entry page"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-entry-page-of report))))
              (:tr
               (:td (views:esc "Authoring plan"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-authoring-plan-of report))))
              (:tr
               (:td (views:esc "Last protocol boundary"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::bibliography-standin-last-protocol-boundary-of report)
                          "")))))
              (:tr
               (:td (views:esc "Failure classification before browser"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::bibliography-standin-failure-classification-before-browser-of
                           report)
                          "")))))))))

(views:defview 👀entry-page-selection (report hyperdoc::bibliography-authoring-plan-standin-report)
  (views:html-view :title "Entry-page selection" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Entry-page title"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::bibliography-standin-entry-page-title-of report)))))
              (:tr
               (:td (views:esc "Entry-page object"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-entry-page-of report))))
              (:tr
               (:td (views:esc "Entry-page source path"))
               (:td (:code
                     (views:esc
                      (or (bibliography-path-string
                           (hyperdoc::bibliography-standin-entry-page-source-path-of report))
                          "")))))
              (:tr
               (:td (views:esc "Tracked in git"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (hyperdoc::bibliography-standin-entry-page-tracked-in-git-p report))))))
              (:tr
               (:td (views:esc "Link present"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (hyperdoc::bibliography-standin-entry-page-link-present-p report))))))
              (:tr
               (:td (views:esc "Selection classification"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::bibliography-standin-entry-page-selection-classification-of
                       report)))))))))

(views:defview 👀runtime-surface-inventory-classification
    (report hyperdoc::bibliography-authoring-plan-standin-report)
  (views:html-view :title "Runtime-surface inventory classification" :priority 3
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Inventory classification"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::bibliography-standin-runtime-surface-inventory-classification-of
                       report)))))
              (:tr
               (:td (views:esc "Link text"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::bibliography-standin-link-text-of report)))))
              (:tr
               (:td (views:esc "Entry-page object present"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (not (null
                             (hyperdoc::bibliography-standin-entry-page-of report))))))))
              (:tr
               (:td (views:esc "Source path present"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (not (null
                             (hyperdoc::bibliography-standin-entry-page-source-path-of
                              report))))))))))))

(views:defview 👀workspace-vs-flake-mismatch-classification
    (report hyperdoc::bibliography-authoring-plan-standin-report)
  (views:html-view :title "Workspace-vs-flake mismatch classification" :priority 4
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Mismatch classification"))
               (:td (:tt
                     (views:esc
                      (hyperdoc::bibliography-standin-workspace-vs-flake-mismatch-classification-of
                       report)))))
              (:tr
               (:td (views:esc "Tracked in git"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (hyperdoc::bibliography-standin-entry-page-tracked-in-git-p report))))))
              (:tr
               (:td (views:esc "Entry-page source path"))
               (:td (:code
                     (views:esc
                      (or (bibliography-path-string
                           (hyperdoc::bibliography-standin-entry-page-source-path-of report))
                          "")))))))))

(views:defview 👀plan-readiness (report hyperdoc::bibliography-authoring-plan-standin-report)
  (views:html-view :title "Plan readiness" :priority 5
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Plan ready"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (hyperdoc::bibliography-standin-plan-ready-p report))))))
              (:tr
               (:td (views:esc "Plan build ms"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-plan-build-ms-of report))))
              (:tr
               (:td (views:esc "Authoring plan"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-authoring-plan-of report))))
              (:tr
               (:td (views:esc "Imported entries"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-imported-entry-count-of report))))
              (:tr
               (:td (views:esc "Candidate topics"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-candidate-count-of report))))
              (:tr
               (:td (views:esc "Authoring decisions"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-decision-count-of report))))
              (:tr
               (:td (views:esc "Plan error"))
               (:td (:pre
                     (views:esc
                      (or (hyperdoc::bibliography-standin-plan-error-of report)
                          "")))))))))

(views:defview 👀artifact-bundle-readiness
    (report hyperdoc::bibliography-authoring-plan-standin-report)
  (views:html-view :title "Artifact-bundle readiness" :priority 6
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Artifact bundle ready"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (hyperdoc::bibliography-standin-artifact-bundle-ready-p report))))))
              (:tr
               (:td (views:esc "Output root"))
               (:td (:code
                     (views:esc
                      (or (bibliography-path-string
                           (hyperdoc::bibliography-standin-output-root-of report))
                          "")))))
              (:tr
               (:td (views:esc "Plan summary path"))
               (:td (:code
                     (views:esc
                      (or (bibliography-path-string
                           (hyperdoc::bibliography-standin-plan-summary-path-of report))
                          "")))))
              (:tr
               (:td (views:esc "Materialization entry count"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-materialization-entry-count-of report))))
              (:tr
               (:td (views:esc "Materialization ms"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-materialization-ms-of report))))
              (:tr
               (:td (views:esc "Execution report count"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-execution-report-count-of report))))))))

(views:defview 👀failure-classification-before-browser
    (report hyperdoc::bibliography-authoring-plan-standin-report)
  (views:html-view :title "Failure classification before browser" :priority 7
    (views:html
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Failure classification"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::bibliography-standin-failure-classification-before-browser-of
                           report)
                          "")))))
              (:tr
               (:td (views:esc "Last protocol boundary"))
               (:td (:tt
                     (views:esc
                      (or (hyperdoc::bibliography-standin-last-protocol-boundary-of report)
                          "")))))
              (:tr
               (:td (views:esc "Plan ready"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (hyperdoc::bibliography-standin-plan-ready-p report))))))
              (:tr
               (:td (views:esc "Artifact bundle ready"))
               (:td (:tt
                     (views:esc
                      (bibliography-boolean-label
                       (hyperdoc::bibliography-standin-artifact-bundle-ready-p report))))))
              (:tr
               (:td (views:esc "Authoring plan"))
               (:td (views:object-ref
                     (hyperdoc::bibliography-standin-authoring-plan-of report))))))))
