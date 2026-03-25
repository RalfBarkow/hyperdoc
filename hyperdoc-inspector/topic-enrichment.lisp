;;;; Inspector views for topic enrichment routes, plans, and reports
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/inspector)

(defun topic-enrichment-label (value)
  (if value
      (bibliography-keyword-label value)
      ""))

(defun topic-enrichment-match-table (items)
  (views:html
    (:table :class "inspector-table"
            (:tr
             (:th (views:esc "Item"))
             (:th (views:esc "Title"))
             (:th (views:esc "DOI"))
             (:th (views:esc "Citation key"))
             (:th (views:esc "Date"))
             (:th (views:esc "Type")))
            (dolist (item items)
              (views:html
                (:tr
                 (:td (views:object-ref item))
                 (:td (views:esc
                       (or (hyperdoc::zotero-item-title-of item) "")))
                 (:td (:tt
                       (views:esc
                        (or (hyperdoc::zotero-item-doi-of item) ""))))
                 (:td (:tt
                       (views:esc
                        (or (hyperdoc::zotero-item-citation-key-of item)
                            ""))))
                 (:td (:tt
                       (views:esc
                        (or (hyperdoc::zotero-item-date-of item) ""))))
                 (:td (:tt
                       (views:esc
                        (or (hyperdoc::zotero-item-type-of item) ""))))))))))

(defun topic-enrichment-signal-table (signals)
  (views:html
    (:table :class "inspector-table"
            (:tr
             (:th (views:esc "Signal"))
             (:th (views:esc "Source kind"))
             (:th (views:esc "Field"))
             (:th (views:esc "Display title"))
             (:th (views:esc "Detail")))
            (dolist (signal signals)
              (views:html
                (:tr
                 (:td (views:object-ref signal))
                 (:td (:tt
                       (views:esc
                        (topic-enrichment-label
                         (hyperdoc::candidate-topic-signal-source-kind-of
                          signal)))))
                 (:td (:tt
                       (views:esc
                        (topic-enrichment-label
                         (hyperdoc::candidate-topic-signal-field-of signal)))))
                 (:td (views:esc
                       (hyperdoc::candidate-topic-signal-display-title-of
                        signal)))
                 (:td (views:esc
                       (or (hyperdoc::candidate-topic-signal-detail-of signal)
                           "")))))))))

(defun topic-enrichment-consequence-table (consequences)
  (views:html
    (:table :class "inspector-table"
            (:tr
             (:th (views:esc "Consequence"))
             (:th (views:esc "Kind"))
             (:th (views:esc "Summary"))
             (:th (views:esc "Evidence")))
            (dolist (consequence consequences)
              (views:html
                (:tr
                 (:td (views:object-ref consequence))
                 (:td (:tt
                       (views:esc
                        (topic-enrichment-label
                         (hyperdoc::topic-enrichment-consequence-kind-of
                          consequence)))))
                 (:td (views:esc
                       (hyperdoc::summary-of consequence)))
                 (:td (views:object-ref
                       (hyperdoc::topic-enrichment-consequence-evidence-of
                        consequence)))))))))

(defmethod views:text-representation
    ((source hyperdoc::zotero-library-source-designator))
  (format nil "Source ~A"
          (hyperdoc::title-of source)))

(views:defview 👀overview (source hyperdoc::zotero-library-source-designator)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Stable key"))
                   (:td (:tt (views:esc (hyperdoc::id-of source)))))
              (:tr (:td (views:esc "Title"))
                   (:td (views:esc (hyperdoc::title-of source))))
              (:tr (:td (views:esc "Summary"))
                   (:td (views:esc (hyperdoc::summary-of source))))
              (:tr (:td (views:esc "Source kind"))
                   (:td (:tt
                         (views:esc
                          (topic-enrichment-label
                           (hyperdoc::topic-enrichment-source-kind-of
                            source))))))
              (:tr (:td (views:esc "Bridge provider"))
                   (:td (:tt
                         (views:esc
                          (prin1-to-string
                           (hyperdoc::topic-enrichment-source-bridge-provider-of
                            source))))))
              (:tr (:td (views:esc "Notes"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-source-notes-of
                          source))))))))

(defmethod views:text-representation ((route hyperdoc::topic-source-route))
  (format nil "Route ~A"
          (hyperdoc::title-of route)))

(defmethod views:title-bar-action-buttons ((route hyperdoc::topic-source-route))
  (views:html
    (views:action-button
     "Open exact plan"
     (views:thunk
       (hyperdoc::topic-source-route-default-plan route))
     "Open the inspectable exact-title query plan for this route.")
    (views:action-button
     "Open loose plan"
     (views:thunk
       (hyperdoc::topic-source-route-explicit-loose-plan route))
     "Open the explicitly broader follow-up plan as a separate inspectable object.")))

(defun topic-source-route-overview-table (route annotation definition)
  (views:html
    (:table :class "inspector-table"
            (:tr (:td (views:esc "Stable key"))
                 (:td (:tt (views:esc (hyperdoc::id-of route)))))
            (:tr (:td (views:esc "Topic"))
                 (:td (views:object-ref
                       (hyperdoc::topic-source-route-topic-of route))))
            (:tr (:td (views:esc "Source designator"))
                 (:td (views:object-ref
                       (hyperdoc::topic-source-route-source-designator-of
                        route))))
            (:tr (:td (views:esc "Default match mode"))
                 (:td (:tt
                       (views:esc
                        (topic-enrichment-label
                         (hyperdoc::topic-source-route-default-match-mode-of
                          route))))))
            (:tr (:td (views:esc "Connect relation"))
                 (:td (if annotation
                          (views:object-ref annotation)
                          (views:html
                           (:span :style "opacity:0.55"
                                  (views:esc "Not authored yet.")))))))
            (:tr (:td (views:esc "Authoring note"))
                 (:td (views:esc
                       (or (and definition
                                (hyperdoc::topic-enrichment-route-definition-notes-of
                                 definition))
                           "No authoring notes."))))))

(views:defview 👀overview (route hyperdoc::topic-source-route)
  (let ((annotation (hyperdoc::topic-source-route-annotation-of route))
         (definition (hyperdoc::topic-source-route-definition-of route)))
     (views:html-view :title "Overview" :priority 1
       (topic-source-route-overview-table route annotation definition))))

(views:defview 👀inputs (route hyperdoc::topic-source-route)
  (views:html-view :title "Inputs" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Topic title"))
                   (:td (views:esc
                         (hyperdoc::title-of
                          (hyperdoc::topic-source-route-topic-of route)))))
              (:tr (:td (views:esc "Source title"))
                   (:td (views:esc
                         (hyperdoc::title-of
                          (hyperdoc::topic-source-route-source-designator-of
                           route)))))
              (:tr (:td (views:esc "Source summary"))
                   (:td (views:esc
                         (hyperdoc::summary-of
                          (hyperdoc::topic-source-route-source-designator-of
                           route)))))))))

(defmethod views:text-representation ((plan hyperdoc::topic-enrichment-query-plan))
  (format nil "Topic enrichment plan ~A (~A)"
          (hyperdoc::title-of
           (hyperdoc::topic-enrichment-plan-source-topic-of plan))
          (hyperdoc::topic-enrichment-plan-readiness-label
           (hyperdoc::topic-enrichment-plan-execution-readiness-of plan))))

(defmethod views:title-bar-action-buttons
    ((plan hyperdoc::topic-enrichment-query-plan))
  (views:html
    (views:action-button
     "Run plan"
     (views:thunk
       (hyperdoc::run-topic-enrichment-query-plan plan))
     "Execute the read-only Zotero lookup described by this inspectable query plan.")))

(views:defview 👀overview (plan hyperdoc::topic-enrichment-query-plan)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Route"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-route-of plan))))
              (:tr (:td (views:esc "Source topic"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-source-topic-of plan))))
              (:tr (:td (views:esc "Source designator"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-source-designator-of
                          plan))))
              (:tr (:td (views:esc "Query text"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::topic-enrichment-plan-query-text-of
                           plan)))))
              (:tr (:td (views:esc "Match mode"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::topic-enrichment-match-mode-label
                           (hyperdoc::topic-enrichment-plan-match-mode-of
                            plan))))))
              (:tr (:td (views:esc "Execution readiness"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::topic-enrichment-plan-readiness-label
                           (hyperdoc::topic-enrichment-plan-execution-readiness-of
                            plan))))))
              (:tr (:td (views:esc "Intended backend"))
                   (:td (views:esc
                         (hyperdoc::topic-enrichment-plan-intended-backend-of
                          plan))))
              (:tr (:td (views:esc "Intended bridge"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-intended-bridge-of
                          plan))))))))

(views:defview 👀execution-path (plan hyperdoc::topic-enrichment-query-plan)
  (views:html-view :title "Execution path" :priority 2
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Step 1"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-route-of plan))))
              (:tr (:td (views:esc "Step 2"))
                   (:td (views:esc "Use the topic title as inspectable query text.")))
              (:tr (:td (views:esc "Step 3"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-intended-bridge-of
                          plan))))
              (:tr (:td (views:esc "Step 4"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-expected-functions-of
                          plan))))
              (:tr (:td (views:esc "Step 5"))
                   (:td (views:esc
                         "Execute the live read-only Zotero title query only when Run plan is chosen.")))
              (:tr (:td (views:esc "Step 6"))
                   (:td (views:esc
                         "Record a topic-enrichment-report object and keep the query evidence chain inspectable.")))))))

(views:defview 👀raw-data (plan hyperdoc::topic-enrichment-query-plan)
  (views:html-view :title "Raw data" :priority 3
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Expected functions"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-expected-functions-of
                          plan))))
              (:tr (:td (views:esc "Expected objects"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-expected-objects-of
                          plan))))
              (:tr (:td (views:esc "Notes"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-notes-of plan))))
              (:tr (:td (views:esc "Failure evidence"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-failure-evidence-of
                          plan))))))))

(views:defview 👀failure/repair (plan hyperdoc::topic-enrichment-query-plan)
  (views:html-view :title "Failure / repair" :priority 4
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Failure classification"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::topic-enrichment-plan-failure-classification-of
                               plan)
                              "")))))
              (:tr (:td (views:esc "Repair hint"))
                   (:td (views:esc
                         (or (hyperdoc::topic-enrichment-plan-repair-hint-of plan)
                             "Execution is currently possible."))))
              (:tr (:td (views:esc "Failure evidence"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-plan-failure-evidence-of
                          plan))))))))

(defmethod views:text-representation
    ((consequence hyperdoc::topic-enrichment-editorial-consequence))
  (format nil "Editorial consequence ~A"
          (hyperdoc::title-of consequence)))

(views:defview 👀overview
    (consequence hyperdoc::topic-enrichment-editorial-consequence)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Stable key"))
                   (:td (:tt (views:esc (hyperdoc::id-of consequence)))))
              (:tr (:td (views:esc "Title"))
                   (:td (views:esc (hyperdoc::title-of consequence))))
              (:tr (:td (views:esc "Kind"))
                   (:td (:tt
                         (views:esc
                          (topic-enrichment-label
                           (hyperdoc::topic-enrichment-consequence-kind-of
                            consequence))))))
              (:tr (:td (views:esc "Summary"))
                   (:td (views:esc
                         (hyperdoc::summary-of consequence))))
              (:tr (:td (views:esc "Evidence"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-consequence-evidence-of
                          consequence))))))))

(defmethod views:text-representation ((report hyperdoc::topic-enrichment-report))
  (format nil "Topic enrichment report ~A (~A)"
          (hyperdoc::title-of
           (hyperdoc::topic-enrichment-report-source-topic-of report))
          (hyperdoc::topic-enrichment-report-status-label
           (hyperdoc::topic-enrichment-report-status-of report))))

(defmethod views:title-bar-action-buttons ((report hyperdoc::topic-enrichment-report))
  (views:html
    (views:action-button
     "Rerun plan"
     (views:thunk
       (hyperdoc::run-topic-enrichment-query-plan
        (hyperdoc::topic-enrichment-report-plan-of report)))
     "Re-run the report through the stored inspectable query plan.")))

(views:defview 👀overview (report hyperdoc::topic-enrichment-report)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Route"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-route-of report))))
              (:tr (:td (views:esc "Plan"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-plan-of report))))
              (:tr (:td (views:esc "Source topic"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-source-topic-of
                          report))))
              (:tr (:td (views:esc "Source designator"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-source-designator-of
                          report))))
              (:tr (:td (views:esc "Query evidence"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-query-evidence-of
                          report))))
              (:tr (:td (views:esc "Query attempt"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-query-attempt-of
                          report))))
              (:tr (:td (views:esc "Status"))
                   (:td (:tt
                         (views:esc
                          (hyperdoc::topic-enrichment-report-status-label
                           (hyperdoc::topic-enrichment-report-status-of
                            report))))))
              (:tr (:td (views:esc "Failure classification"))
                   (:td (:tt
                         (views:esc
                          (or (hyperdoc::topic-enrichment-report-failure-classification-of
                               report)
                              "")))))
              (:tr (:td (views:esc "Detail"))
                   (:td (views:esc
                         (or (hyperdoc::topic-enrichment-report-detail-of report)
                             ""))))
              (:tr (:td (views:esc "Matched items"))
                   (:td (views:object-ref
                         (length
                          (hyperdoc::topic-enrichment-report-matched-items-of
                           report)))))
              (:tr (:td (views:esc "Candidate signals"))
                   (:td (views:object-ref
                         (length
                          (hyperdoc::topic-enrichment-report-candidate-signals-of
                           report)))))
              (:tr (:td (views:esc "Editorial consequences"))
                   (:td (views:object-ref
                         (length
                          (hyperdoc::topic-enrichment-report-editorial-consequences-of
                           report)))))))))

(views:defview 👀matches (report hyperdoc::topic-enrichment-report)
  (views:html-view :title "Matches" :priority 2
    (let ((items (hyperdoc::topic-enrichment-report-matched-items-of report)))
      (if items
          (topic-enrichment-match-table items)
          (views:html
            (views:esc "No matched Zotero items."))))))

(views:defview 👀candidate-signals (report hyperdoc::topic-enrichment-report)
  (views:html-view :title "Candidate signals" :priority 3
    (let ((signals (hyperdoc::topic-enrichment-report-candidate-signals-of report)))
      (if signals
          (topic-enrichment-signal-table signals)
          (views:html
            (views:esc "No safe candidate signals were derived for this report."))))))

(views:defview 👀editorial-consequences (report hyperdoc::topic-enrichment-report)
  (views:html-view :title "Editorial consequences" :priority 4
    (let ((consequences
            (hyperdoc::topic-enrichment-report-editorial-consequences-of report)))
      (if consequences
          (topic-enrichment-consequence-table consequences)
          (views:html
            (views:esc "No editorial consequences recorded."))))))

(views:defview 👀raw-data (report hyperdoc::topic-enrichment-report)
  (views:html-view :title "Raw data" :priority 5
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Query evidence"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-query-evidence-of
                          report))))
              (:tr (:td (views:esc "Query attempt"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-query-attempt-of
                          report))))
              (:tr (:td (views:esc "Matched items"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-matched-items-of
                          report))))
              (:tr (:td (views:esc "Candidate signals"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-candidate-signals-of
                          report))))
              (:tr (:td (views:esc "Editorial consequences"))
                   (:td (views:object-ref
                         (hyperdoc::topic-enrichment-report-editorial-consequences-of
                          report))))))))
