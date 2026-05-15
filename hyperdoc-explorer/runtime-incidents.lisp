;;;; Explorer views for runtime incidents and service log evidence
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun render-string-list (items)
  (if items
      (views:html
       (:ul
        (loop for item in items
              do (views:html
                  (:li (views:esc item))))))
      (views:html
       (:p (views:esc "None recorded.")))))

(defun render-object-list (items)
  (if items
      (views:html
       (:ul
        (loop for item in items
              do (views:html
                  (:li (views:object-ref item))))))
      (views:html
       (:p (views:esc "None available.")))))

(defun render-log-entry-row (entry)
  (views:html
   (:tr (:td (views:esc
              (or (nixos-service-log-entry-timestamp-of entry)
                  "")))
        (:td (views:esc
              (or (nixos-service-log-entry-unit-of entry)
                  "")))
        (:td (views:esc
              (or (nixos-service-log-entry-priority-of entry)
                  "")))
        (:td (views:esc
              (or (nixos-service-log-entry-message-of entry)
                  ""))))))

(defmethod views:text-representation ((entry nixos-service-log-entry))
  (format nil "~@[~A ~]~A"
          (nixos-service-log-entry-timestamp-of entry)
          (nixos-service-log-entry-message-of entry)))

(defmethod views:text-representation ((query nixos-service-log-query))
  (format nil "Log query ~A (~D entries)"
          (nixos-service-log-query-service-of query)
          (length (nixos-service-log-query-entries-of query))))

(defmethod views:text-representation ((answer goldberg-incident-question-answer))
  (format nil "~D. ~A"
          (goldberg-incident-question-answer-number-of answer)
          (goldberg-incident-question-answer-question-of answer)))

(defmethod views:text-representation ((incident hyperdoc-runtime-incident))
  (title-of incident))

(views:defview 👀summary (query nixos-service-log-query)
  (views:html-view :title "Summary" :priority 1
                   (views:html
                    (:h3 (views:esc
                          (format nil "Service log: ~A"
                                  (nixos-service-log-query-service-of query))))
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Host"))
                                 (:td (views:esc
                                       (or (nixos-service-log-query-host-of query)
                                           ""))))
                            (:tr (:td (views:esc "Service"))
                                 (:td (:tt (views:esc
                                            (nixos-service-log-query-service-of query)))))
                            (:tr (:td (views:esc "Since"))
                                 (:td (views:esc
                                       (or (nixos-service-log-query-since-of query)
                                           ""))))
                            (:tr (:td (views:esc "Until"))
                                 (:td (views:esc
                                       (or (nixos-service-log-query-until-of query)
                                           ""))))
                            (:tr (:td (views:esc "Pattern"))
                                 (:td (views:esc
                                       (or (nixos-service-log-query-pattern-of query)
                                           ""))))
                            (:tr (:td (views:esc "Command"))
                                 (:td (:code (views:esc
                                              (nixos-service-log-query-command-of query)))))
                            (:tr (:td (views:esc "Exit status"))
                                 (:td (:tt (views:esc
                                            (princ-to-string
                                             (nixos-service-log-query-exit-status-of query))))))
                            (:tr (:td (views:esc "Entry count"))
                                 (:td (:tt (views:esc
                                            (format nil "~D"
                                                    (length
                                                     (nixos-service-log-query-entries-of
                                                      query))))))))
                    (when (nixos-service-log-query-unavailable-reason-of query)
                      (views:html
                       (:p (:strong (views:esc "Unavailable: "))
                           (views:esc
                            (nixos-service-log-query-unavailable-reason-of query))))))))

(views:defview 👀log-entries (query nixos-service-log-query)
  (views:html-view :title "Log entries" :priority 2
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:th (views:esc "Timestamp"))
                                 (:th (views:esc "Unit"))
                                 (:th (views:esc "Priority"))
                                 (:th (views:esc "Message")))
                            (loop for entry in (nixos-service-log-query-entries-of query)
                                  do (render-log-entry-row entry))))))

(views:defview 👀raw (query nixos-service-log-query)
  (views:html-view :title "Raw" :priority 3
                   (views:html
                    (:h4 (views:esc "Command"))
                    (:pre (views:esc (nixos-service-log-query-command-of query)))
                    (:h4 (views:esc "Error output"))
                    (:pre (views:esc
                           (or (nixos-service-log-query-error-output-of query)
                               "")))
                    (:h4 (views:esc "Unavailable reason"))
                    (:pre (views:esc
                           (or (nixos-service-log-query-unavailable-reason-of query)
                               ""))))))

(views:defview 👀summary (entry nixos-service-log-entry)
  (views:html-view :title "Summary" :priority 1
                   (views:html
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Timestamp"))
                                 (:td (views:esc
                                       (or (nixos-service-log-entry-timestamp-of entry)
                                           ""))))
                            (:tr (:td (views:esc "Unit"))
                                 (:td (views:esc
                                       (or (nixos-service-log-entry-unit-of entry)
                                           ""))))
                            (:tr (:td (views:esc "Priority"))
                                 (:td (views:esc
                                       (or (nixos-service-log-entry-priority-of entry)
                                           ""))))
                            (:tr (:td (views:esc "Message"))
                                 (:td (views:esc
                                       (or (nixos-service-log-entry-message-of entry)
                                           ""))))))))

(views:defview 👀raw (entry nixos-service-log-entry)
  (views:html-view :title "Raw" :priority 2
                   (views:html
                    (:pre (views:esc
                           (or (nixos-service-log-entry-raw-json-of entry)
                               "")))
                    (:h4 (views:esc "Source command"))
                    (:pre (views:esc
                           (or (nixos-service-log-entry-source-command-of entry)
                               ""))))))

(views:defview 👀summary (answer goldberg-incident-question-answer)
  (views:html-view :title "Summary" :priority 1
                   (views:html
                    (:h3 (views:esc
                          (format nil "~D. ~A"
                                  (goldberg-incident-question-answer-number-of answer)
                                  (goldberg-incident-question-answer-question-of answer))))
                    (:p (views:esc
                         (goldberg-incident-question-answer-answer-of answer)))
                    (:h4 (views:esc "Evidence"))
                    (render-string-list
                     (goldberg-incident-question-answer-evidence-of answer))
                    (:h4 (views:esc "Related objects"))
                    (render-object-list
                     (goldberg-incident-question-answer-related-objects-of answer))
                    (when (goldberg-incident-question-answer-recovery-action-of answer)
                      (views:html
                       (:h4 (views:esc "Recovery action"))
                       (:p (views:esc
                            (goldberg-incident-question-answer-recovery-action-of
                             answer))))))))

(views:defview 👀summary (incident hyperdoc-runtime-incident)
  (views:html-view :title "Summary" :priority 1
                   (views:html
                    (:h3 (views:esc (title-of incident)))
                    (:table :class "inspector-table"
                            (:tr (:td (views:esc "Observed at"))
                                 (:td (:tt (views:esc
                                            (princ-to-string
                                             (hyperdoc-runtime-incident-observed-at-of
                                              incident))))))
                            (:tr (:td (views:esc "Page"))
                                 (:td (views:esc
                                       (hyperdoc-runtime-incident-page-title-of incident))))
                            (:tr (:td (views:esc "Object kind"))
                                 (:td (:tt (views:esc
                                            (hyperdoc-runtime-incident-object-kind-of
                                             incident)))))
                            (:tr (:td (views:esc "Object summary"))
                                 (:td (views:esc
                                       (hyperdoc-runtime-incident-object-summary-of
                                        incident))))
                            (:tr (:td (views:esc "Likely layer"))
                                 (:td (views:esc
                                       (hyperdoc-runtime-incident-likely-layer-of
                                        incident)))))
                    (:h4 (views:esc "Symptom"))
                    (:p (views:esc (hyperdoc-runtime-incident-symptom-of incident)))
                    (:h4 (views:esc "Browser message"))
                    (:p (views:esc
                         (hyperdoc-runtime-incident-browser-message-of incident)))
                    (:h4 (views:esc "Recovery actions"))
                    (render-string-list
                     (hyperdoc-runtime-incident-recovery-actions-of incident)))))

(views:defview 👀goldberg-questions (incident hyperdoc-runtime-incident)
  (views:html-view :title "Goldberg questions" :priority 2
                   (views:html
                    (:ol
                     (loop for answer in
                           (hyperdoc-runtime-incident-goldberg-question-answers-of
                            incident)
                           do (views:html
                               (:li (views:object-ref answer))))))))

(views:defview 👀log-query (incident hyperdoc-runtime-incident)
  (views:html-view :title "Log query" :priority 3
                   (views:html
                    (if (hyperdoc-runtime-incident-related-log-query-of incident)
                        (views:object-ref
                         (hyperdoc-runtime-incident-related-log-query-of incident))
                        (views:html
                         (:p (views:esc "No log query is attached.")))))))

(views:defview 👀log-entries (incident hyperdoc-runtime-incident)
  (views:html-view :title "Log entries" :priority 4
                   (views:html
                    (render-object-list
                     (hyperdoc-runtime-incident-related-log-excerpts-of incident)))))

(views:defview 👀recovery-actions (incident hyperdoc-runtime-incident)
  (views:html-view :title "Recovery actions" :priority 5
                   (views:html
                    (render-string-list
                     (hyperdoc-runtime-incident-recovery-actions-of incident)))))

(views:defview 👀raw (incident hyperdoc-runtime-incident)
  (views:html-view :title "Raw" :priority 6
                   (views:html
                    (:pre (views:esc
                           (with-output-to-string (stream)
                             (write incident :stream stream :pretty t)))))))
