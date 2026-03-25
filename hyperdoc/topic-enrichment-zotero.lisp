;;;; Zotero-backed execution for topic enrichment routes
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defun topic-enrichment-present-string (value)
  (let ((string (and value (string-trim '(#\Space #\Tab #\Newline #\Return)
                                        (princ-to-string value)))))
    (and string
         (not (string= string ""))
         string)))

(defun topic-enrichment-signal
    (source-kind field raw-value display-title detail)
  (let* ((display-title (topic-enrichment-present-string display-title))
         (aliases (and display-title
                       (phrase-aliases display-title))))
    (when display-title
      (make-instance 'candidate-topic-signal
                     :source-kind source-kind
                     :field field
                     :raw-value raw-value
                     :display-title display-title
                     :normalized-key (candidate-topic-key display-title aliases)
                     :aliases aliases
                     :entry nil
                     :detail detail))))

(defun topic-enrichment-item-signals (item)
  (remove nil
          (list
           (topic-enrichment-signal
            :zotero-item-title
            :title
            (zotero-item-title-of item)
            (zotero-item-title-of item)
            "Exact-title Zotero item title candidate from the matched bibliographic item.")
           (topic-enrichment-signal
            :zotero-item-doi
            :doi
            (zotero-item-doi-of item)
            (zotero-item-doi-of item)
            "DOI cue from the matched Zotero item.")
           (topic-enrichment-signal
            :zotero-item-citation-key
            :citation-key
            (zotero-item-citation-key-of item)
            (zotero-item-citation-key-of item)
            "Citation-key cue from the matched Zotero item.")
           (topic-enrichment-signal
            :zotero-item-date
            :date
            (zotero-item-date-of item)
            (zotero-item-date-of item)
            "Date cue from the matched Zotero item.")
           (topic-enrichment-signal
            :zotero-item-type
            :item-type
            (zotero-item-type-of item)
            (zotero-item-type-of item)
            "Zotero item-type cue from the matched bibliographic item."))))

(defun topic-enrichment-signal-labels (signals)
  (mapcar #'candidate-topic-signal-display-title-of signals))

(defun make-topic-enrichment-report-object
    (plan query-evidence query-attempt matched-items candidate-signals
     editorial-consequences status &key failure-classification detail)
  (make-instance 'topic-enrichment-report
                 :route (topic-enrichment-plan-route-of plan)
                 :plan plan
                 :source-topic (topic-enrichment-plan-source-topic-of plan)
                 :source-designator
                 (topic-enrichment-plan-source-designator-of plan)
                 :query-text (topic-enrichment-plan-query-text-of plan)
                 :match-mode (topic-enrichment-plan-match-mode-of plan)
                 :query-evidence query-evidence
                 :query-attempt query-attempt
                 :matched-items matched-items
                 :candidate-signals candidate-signals
                 :editorial-consequences editorial-consequences
                 :status status
                 :failure-classification failure-classification
                 :detail detail))

(defun single-item-topic-enrichment-consequences
    (plan item query-evidence query-attempt candidate-signals)
  (let ((evidence (remove nil
                          (append (list query-evidence query-attempt item)
                                  candidate-signals))))
    (list
     (make-topic-enrichment-editorial-consequence
      :id (format nil "~A/report/possible-addition"
                  (id-of (topic-enrichment-plan-route-of plan)))
      :title "Possible inspectable additions"
      :summary
      (format nil
              "Zotero could add inspectable cues for ~A such as ~{~A~^, ~} while keeping the Zotero item as evidence rather than editorial truth."
              (title-of (topic-enrichment-plan-source-topic-of plan))
              (topic-enrichment-signal-labels candidate-signals))
      :kind :possible-addition
      :evidence evidence)
     (make-topic-enrichment-editorial-consequence
      :id (format nil "~A/report/editorial-boundary"
                  (id-of (topic-enrichment-plan-route-of plan)))
      :title "Evidence stays separate from authored truth"
      :summary
      "The enriched topic surface may point at Zotero evidence and derived cues, but the matched Zotero item is not promoted into a first-class HyperDoc topic in this slice."
      :kind :boundary
      :evidence evidence))))

(defun zero-match-topic-enrichment-consequences
    (plan query-evidence query-attempt)
  (list
   (make-topic-enrichment-editorial-consequence
    :id (format nil "~A/report/no-change"
                (id-of (topic-enrichment-plan-route-of plan)))
    :title "No editorial change yet"
    :summary
    "The read-only Zotero lookup found no title match, so HyperDoc should keep the topic unchanged until the route or query text is revised."
    :kind :no-change
    :evidence (remove nil (list query-evidence query-attempt plan)))))

(defun ambiguous-topic-enrichment-consequences
    (plan query-evidence query-attempt matched-items)
  (list
   (make-topic-enrichment-editorial-consequence
    :id (format nil "~A/report/review-needed"
                (id-of (topic-enrichment-plan-route-of plan)))
    :title "Review ambiguous Zotero matches"
    :summary
    "Multiple Zotero items matched the same topic title. Inspect the matched items before deriving candidate signals or editorial consequences."
    :kind :review-needed
    :evidence (remove nil
                      (append (list query-evidence query-attempt plan)
                              matched-items)))))

(defun failed-topic-enrichment-consequences
    (plan query-evidence query-attempt)
  (list
   (make-topic-enrichment-editorial-consequence
    :id (format nil "~A/report/query-failure"
                (id-of (topic-enrichment-plan-route-of plan)))
    :title "Query evidence needs repair"
    :summary
    "The title-query evidence did not expose a selected attempt, so the route stays inspectable and the topic surface should not claim enrichment yet."
    :kind :repair-needed
    :evidence (remove nil (list query-evidence query-attempt plan)))))

(defun execute-topic-enrichment-query-plan (plan)
  (let ((bridge (topic-enrichment-plan-intended-bridge-of plan)))
    (when (zotero-backend-unavailable-p bridge)
      (return-from execute-topic-enrichment-query-plan bridge))
    (multiple-value-bind (matched-items query-evidence)
        (lookup-zotero-items-by-title
         (topic-enrichment-plan-query-text-of plan)
         :bridge bridge
         :match-mode (topic-enrichment-plan-match-mode-of plan))
      (let ((query-attempt
              (normalize-zotero-query-attempt
               query-evidence
               :attempted-operation 'zotero-query-attempt-rows-of
               :receiver (and query-evidence
                              (zotero-query-selected-attempt-of query-evidence))
               :arguments
               (list (topic-enrichment-plan-query-text-of plan)
                     :match-mode (topic-enrichment-plan-match-mode-of plan))
               :higher-level-intent
               (list 'lookup-zotero-items-by-title
                     (topic-enrichment-plan-query-text-of plan))
               :repair-hint
               "Inspect the title-query evidence before assuming a selected Zotero attempt exists.")))
        (cond
          ((typep query-attempt 'zotero-query-missing-attempt)
           (make-topic-enrichment-report-object
            plan
            query-evidence
            query-attempt
            matched-items
            nil
            (failed-topic-enrichment-consequences
             plan query-evidence query-attempt)
            :query-error
            :failure-classification "missing-zotero-selected-attempt"
            :detail (or (zotero-query-missing-attempt-detail-of query-attempt)
                        "No Zotero query attempt was selected for this title lookup.")))
          ((null matched-items)
           (make-topic-enrichment-report-object
            plan
            query-evidence
            query-attempt
            nil
            nil
            (zero-match-topic-enrichment-consequences
             plan query-evidence query-attempt)
            :zero-matches
            :failure-classification "no-zotero-title-match"
            :detail
            "No Zotero items matched the current topic title under the selected match mode."))
          ((cdr matched-items)
           (make-topic-enrichment-report-object
            plan
            query-evidence
            query-attempt
            matched-items
            nil
            (ambiguous-topic-enrichment-consequences
             plan query-evidence query-attempt matched-items)
            :ambiguous-matches
            :failure-classification "ambiguous-zotero-title-match"
            :detail
            "Multiple Zotero items matched the topic title. Inspect the matched items before deriving enrichment cues."))
          (t
           (let* ((item (first matched-items))
                  (candidate-signals (topic-enrichment-item-signals item)))
             (make-topic-enrichment-report-object
              plan
              query-evidence
              query-attempt
              matched-items
              candidate-signals
              (single-item-topic-enrichment-consequences
               plan item query-evidence query-attempt candidate-signals)
              :matched
              :detail
              "One Zotero item matched the topic title and yielded inspectable metadata cues for the enriched topic surface."))))))))
