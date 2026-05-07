;;;; Topic-pane Touch-Fahrplan view for topic enrichment
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun topic-enrichment-inline-labels (strings)
  (if strings
      (format nil "~{~A~^, ~}" strings)
      "None"))

(defun topic-enrichment-inline-match-titles (report)
  (mapcar #'zotero-item-title-of
          (topic-enrichment-report-matched-items-of report)))

(defun topic-enrichment-inline-signal-titles (report)
  (mapcar #'candidate-topic-signal-display-title-of
          (topic-enrichment-report-candidate-signals-of report)))

(defun topic-touch-fahrplan-view-html (topic)
  (let* ((sources (default-topic-enrichment-source-designators))
         (latest-successful-reports
          (remove nil
                  (mapcar (lambda (source)
                            (topic-source-route-latest-successful-report
                             (make-topic-source-route topic source)))
                          sources)))
         (durable-routes
          (topic-source-route-durable-routes-for-topic topic)))
    (views:html-view :title "Touch-Fahrplan" :priority 2
                     (views:add-asset-path "/hyperbook/"
                                           (asdf:system-relative-pathname
                                            :hyperbook
                                            "assets/hyperbook/"))
                     (views:include-css "/hyperbook/css/hyperbook.css")
                     (views:html
                      (:div :class "hyperbook-page"
                            (:h1 (views:esc "Touch-Fahrplan"))
                            (:p (views:esc
                                 "The current topic is the left endpoint. Each source tile opens a durable route object first, then an inspectable query plan, and only then the live read-only Zotero query."))
                            (:table :class "inspector-table"
                                    (:tr (:th "Topic endpoint")
                                         (:td (views:object-ref topic)))
                                    (:tr (:th "Topic page")
                                         (:td (views:object-ref
                                               (find-page *topics*
                                                          (title-of topic)
                                                          :signal-error? t)))))
                            (:h2 (views:esc "Durable Touch-Fahrplan routes"))
                            (if durable-routes
                                (views:html
                                 (:table :class "inspector-table"
                                         (:tr (:th "Definition")
                                              (:th "Route")
                                              (:th "Connect relation")
                                              (:th "Notes"))
                                         (dolist (route durable-routes)
                                           (let ((definition
                                                  (topic-source-route-definition-of route))
                                                 (annotation
                                                  (topic-source-route-annotation-of route)))
                                             (views:html
                                              (:tr
                                               (:td
                                                (if definition
                                                    (views:object-ref definition)
                                                    (views:html
                                                     (:span :style "opacity:0.55"
                                                            (views:esc "None yet")))))
                                               (:td (views:object-ref route))
                                               (:td
                                                (if annotation
                                                    (views:object-ref annotation)
                                                    (views:html
                                                     (:span :style "opacity:0.55"
                                                            (views:esc "None yet"))))))
                                              (:td (views:esc
                                                    (or (and definition
                                                             (topic-enrichment-route-definition-notes-of
                                                              definition))
                                                        "No authoring notes."))))))))
                                (views:html
                                 (:p (views:esc
                                      "No durable Touch-Fahrplan routes have been authored for this topic yet.")))))
                      (:h2 (views:esc "Source palette"))
                      (:table :class "inspector-table"
                              (:tr (:th "Source")
                                   (:th "Durable")
                                   (:th "Route")
                                   (:th "Open")
                                   (:th "Run")
                                   (:th "Latest report"))
                              (dolist (source sources)
                                (let* ((durable-route
                                        (topic-source-route-durable-route-for-topic-source
                                         topic
                                         source))
                                       (definition
                                        (and durable-route
                                             (topic-source-route-definition-of
                                              durable-route)))
                                       (route (or durable-route
                                                  (make-topic-source-route topic source)))
                                       (latest-report
                                        (topic-source-route-latest-report route)))
                                  (views:html
                                   (:tr
                                    (:td (views:object-ref source))
                                    (:td
                                     (if definition
                                         (views:object-ref definition)
                                         (views:action-button
                                          "Create durable route"
                                          (views:thunk
                                           (create-durable-topic-source-route!
                                            topic
                                            source))
                                          "Persist a durable Touch-Fahrplan route definition and open the resulting route.")))
                                    (:td (views:object-ref route))
                                    (:td
                                     (views:eval-button
                                      "Open route"
                                      (views:thunk route)
                                      "Inspect the durable relation object between this topic and Zotero source.")
                                     (views:eval-button
                                      "Open exact plan"
                                      (views:thunk
                                       (topic-source-route-default-plan route))
                                      "Inspect the exact-title query plan before any live lookup runs."))
                                    (:td
                                     (views:eval-button
                                      "Run exact plan"
                                      (views:thunk
                                       (run-topic-enrichment-query-plan
                                        (topic-source-route-default-plan route)))
                                      "Run the live read-only Zotero lookup described by the exact-title plan."))
                                    (:td
                                     (if latest-report
                                         (views:object-ref latest-report)
                                         (views:html
                                          (:tt
                                           (views:esc "None yet")))))))))
                              (:h2 (views:esc "Latest successful enrichment"))
                              (if latest-successful-reports
                                  (views:html
                                   (:table :class "inspector-table"
                                           (:tr (:th "Report")
                                                (:th "Matched items")
                                                (:th "Candidate signals")
                                                (:th "Editorial consequences"))
                                           (dolist (report latest-successful-reports)
                                             (views:html
                                              (:tr
                                               (:td (views:object-ref report))
                                               (:td (views:esc
                                                     (topic-enrichment-inline-labels
                                                      (topic-enrichment-inline-match-titles
                                                       report))))
                                               (:td (views:esc
                                                     (topic-enrichment-inline-labels
                                                      (topic-enrichment-inline-signal-titles
                                                       report))))
                                               (:td (views:object-ref
                                                     (topic-enrichment-report-editorial-consequences-of
                                                      report))))))))
                                  (views:html
                                   (:p (views:esc
                                        "No successful enrichment report is cached yet. Open a plan first, inspect it, then run it explicitly.")))))))))

(views:defview 👀touch-fahrplan (page topic-page)
  (topic-touch-fahrplan-view-html (topic-of page)))

(views:defview 👀touch-fahrplan (topic topic)
  (topic-touch-fahrplan-view-html topic))
