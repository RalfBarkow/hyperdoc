;;;; Inspectable promotion plans for localhost FedWiki page promotion slices
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *localhost-fedwiki-page-promotion-default-workspace-topicmap-id*
  919822)

(defstruct localhost-fedwiki-page-promotion-plan
  id
  title
  summary
  pipeline
  source-chunk
  promoted-topic-chunks
  topic-page
  topic-definition
  dmx-snippet
  composed-page-target
  topic-factory-metadata
  local-artifact-writer
  page-renderer
  default-workspace-topicmap-id)

(defstruct localhost-fedwiki-page-promotion-surface
  title
  summary
  plans)

(defun localhost-fedwiki-page-promotion-plans ()
  (list (the-life-cycle-of-collective-knowledge-promotion-plan)
        (reproducible-devenv-as-knowledge-artifact-promotion-plan)))

(defmethod print-object ((plan localhost-fedwiki-page-promotion-plan) stream)
  (print-unreadable-object (plan stream :type t)
    (format stream "~A"
            (localhost-fedwiki-page-promotion-plan-title plan))))

(defmethod print-object ((surface localhost-fedwiki-page-promotion-surface) stream)
  (print-unreadable-object (surface stream :type t)
    (format stream "~A"
            (localhost-fedwiki-page-promotion-surface-title surface))))

(defun localhost-fedwiki-page-promotion-plan-source (plan)
  (localhost-fedwiki-page-pipeline-result-source
   (localhost-fedwiki-page-promotion-plan-pipeline plan)))

(defun localhost-fedwiki-page-promotion-plan-story-items (plan)
  (localhost-fedwiki-source-data-story-items
   (localhost-fedwiki-page-promotion-plan-source plan)))

(defun localhost-fedwiki-page-promotion-plan-fragments (plan)
  (loop for item in (localhost-fedwiki-page-promotion-plan-story-items plan)
        append (copy-list (localhost-fedwiki-item-data-fragments item))))

(defun localhost-fedwiki-page-promotion-plan-source-page-id (plan)
  (localhost-fedwiki-source-data-fedwiki-page-id
   (localhost-fedwiki-page-promotion-plan-source plan)))

(defun localhost-fedwiki-page-promotion-plan-source-page-slug (plan)
  (localhost-fedwiki-source-data-fedwiki-slug
   (localhost-fedwiki-page-promotion-plan-source plan)))

(defun localhost-fedwiki-page-promotion-plan-source-page-path (plan)
  (localhost-fedwiki-source-data-fedwiki-relative-path
   (localhost-fedwiki-page-promotion-plan-source plan)))

(defun localhost-fedwiki-page-promotion-plan-related-topic-id (plan)
  (getf (localhost-fedwiki-page-promotion-plan-topic-factory-metadata plan)
        :related-topic-id))

(defun localhost-fedwiki-page-promotion-plan-related-hyperdoc-page-title (plan)
  (getf (localhost-fedwiki-page-promotion-plan-topic-factory-metadata plan)
        :related-hyperdoc-page-title))

(defun localhost-fedwiki-page-promotion-plan-generated-page
    (plan &key signal-error?)
  (let ((hyperdoc (and (boundp '*hyperdoc*)
                       (symbol-value '*hyperdoc*)))
        (title (localhost-fedwiki-page-promotion-plan-related-hyperdoc-page-title
                plan)))
    (if (and hyperdoc title)
        (find-page hyperdoc title :signal-error? signal-error?)
        (when signal-error?
          (error "No generated HyperDoc page is available for ~A."
                 (or (and plan
                          (localhost-fedwiki-page-promotion-plan-id plan))
                     "the requested promotion plan"))))))

(defun localhost-fedwiki-source-generated-page (source &key signal-error?)
  (if-let (plan (find-localhost-fedwiki-page-promotion-plan-for-source
                 source
                 :signal-error? signal-error?))
    (localhost-fedwiki-page-promotion-plan-generated-page
     plan
     :signal-error? signal-error?)
    (when signal-error?
      (error "No generated HyperDoc page is available for source page ~A."
             (localhost-fedwiki-source-data-fedwiki-page-id source)))))

(defun localhost-fedwiki-page-promotion-plan-topic-count (plan)
  (length (localhost-fedwiki-page-promotion-plan-promoted-topic-chunks plan)))

(defun localhost-fedwiki-page-promotion-plan-fragment-count (plan)
  (length (localhost-fedwiki-page-promotion-plan-fragments plan)))

(defun localhost-fedwiki-page-promotion-plan-story-item-count (plan)
  (length (localhost-fedwiki-page-promotion-plan-story-items plan)))

(defun localhost-fedwiki-page-promotion-plan-umbrella-topic (plan)
  (find :umbrella
        (localhost-fedwiki-page-promotion-plan-promoted-topic-chunks plan)
        :key #'topic-kind-of))

(defun localhost-fedwiki-page-promotion-plan-subtopics (plan)
  (remove :umbrella
          (localhost-fedwiki-page-promotion-plan-promoted-topic-chunks plan)
          :key #'topic-kind-of))

(defun localhost-fedwiki-page-promotion-plan-provenance-rows (plan)
  (loop for chunk in (localhost-fedwiki-page-promotion-plan-promoted-topic-chunks plan)
        for provenance = (provenance-of chunk)
        collect (list :id (id-of chunk)
                      :title (title-of chunk)
                      :kind (topic-kind-of chunk)
                      :granularity
                      (getf provenance :provenance-granularity)
                      :classification
                      (getf provenance :provenance-classification)
                      :story-item-id
                      (getf provenance :source-story-item-id)
                      :story-item-index
                      (getf provenance :source-story-item-index)
                      :story-item-indexes
                      (copy-tree
                       (getf provenance :source-story-item-indexes))
                      :fragment-ordinals
                      (copy-tree
                       (getf provenance :source-fragment-ordinals)))))

(defun localhost-fedwiki-page-promotion-plan-composed-page-pathname (plan)
  (asdf:system-relative-pathname
   :hyperdoc
   (localhost-fedwiki-page-promotion-plan-composed-page-target plan)))

(defun localhost-fedwiki-page-promotion-plan-topic-snippet-pathname (plan)
  (asdf:system-relative-pathname
   :hyperdoc
   (source-path-of
    (localhost-fedwiki-page-promotion-plan-topic-definition plan))))

(defun localhost-fedwiki-page-promotion-plan-rendered-page (plan)
  (if-let (renderer (localhost-fedwiki-page-promotion-plan-page-renderer plan))
    (funcall renderer)
    ""))

(defun localhost-fedwiki-page-promotion-plan-rendered-page-artifact (plan)
  (render-localhost-fedwiki-page-artifact-with-source-snapshot
   (localhost-fedwiki-page-promotion-plan-rendered-page plan)
   (localhost-fedwiki-page-promotion-plan-source plan)))

(defun localhost-fedwiki-page-promotion-plan-rendered-snippet-artifact (plan)
  (render-localhost-fedwiki-topic-snippet-artifact-with-source-snapshot
   (snippet-text-of (localhost-fedwiki-page-promotion-plan-topic-definition plan))
   (localhost-fedwiki-page-promotion-plan-source plan)))

(defun localhost-fedwiki-page-promotion-plan-current-source-snapshot (plan)
  (localhost-fedwiki-source-snapshot-metadata
   (localhost-fedwiki-page-promotion-plan-source plan)))

(defun write-localhost-fedwiki-page-promotion-plan-string-artifact (path content)
  (ensure-directories-exist path)
  (with-open-file (stream path
                          :direction :output
                          :if-exists :supersede
                          :if-does-not-exist :create
                          :external-format :utf-8)
    (write-string content stream))
  path)

(defun localhost-fedwiki-page-promotion-plan-write-page-artifact (plan)
  (let ((path (localhost-fedwiki-page-promotion-plan-composed-page-pathname plan)))
    (write-localhost-fedwiki-page-promotion-plan-string-artifact
     path
     (localhost-fedwiki-page-promotion-plan-rendered-page-artifact plan))
    path))

(defun localhost-fedwiki-page-promotion-plan-write-snippet-artifact (plan)
  (let ((path (localhost-fedwiki-page-promotion-plan-topic-snippet-pathname plan)))
    (write-localhost-fedwiki-page-promotion-plan-string-artifact
     path
     (localhost-fedwiki-page-promotion-plan-rendered-snippet-artifact plan))
    path))

(defun localhost-fedwiki-page-promotion-plan-write-local-artifacts (plan)
  (if-let (writer (localhost-fedwiki-page-promotion-plan-local-artifact-writer plan))
    (funcall writer)
    (error "No local artifact writer configured for ~S." plan)))

(defun write-localhost-fedwiki-page-promotion-plan-artifacts (plan)
  (localhost-fedwiki-page-promotion-plan-write-local-artifacts plan))

(defun localhost-fedwiki-page-promotion-plan-page-output-synced-p
    (plan &key file-contents)
  (let ((path (localhost-fedwiki-page-promotion-plan-composed-page-pathname plan)))
    (and (or file-contents
             (uiop:file-exists-p path))
         (string=
          (or file-contents
              (uiop:read-file-string path))
          (localhost-fedwiki-page-promotion-plan-rendered-page-artifact plan)))))

(defun localhost-fedwiki-page-promotion-plan-snippet-output-synced-p
    (plan &key file-contents)
  (let ((path (localhost-fedwiki-page-promotion-plan-topic-snippet-pathname plan)))
    (and (or file-contents
             (uiop:file-exists-p path))
         (string=
          (or file-contents
              (uiop:read-file-string path))
          (localhost-fedwiki-page-promotion-plan-rendered-snippet-artifact plan)))))

(defun localhost-fedwiki-page-promotion-plan-snippet-provenance (plan)
  (copy-tree
   (getf (localhost-fedwiki-page-promotion-plan-topic-factory-metadata plan)
         :provenance)))

(defun localhost-fedwiki-page-promotion-plan-page-source-snapshot-reflection
    (plan &key file-contents)
  (let ((path (localhost-fedwiki-page-promotion-plan-composed-page-pathname plan)))
    (if (or file-contents
            (uiop:file-exists-p path))
        (localhost-fedwiki-page-artifact-reflected-source-snapshot-reflection
         (or file-contents
             (uiop:read-file-string path)))
        (make-localhost-fedwiki-source-snapshot-envelope-reflection
         :artifact-kind :hyperdoc-html-page
         :status :missing))))

(defun localhost-fedwiki-page-promotion-plan-snippet-source-snapshot-reflection
    (plan &key file-contents)
  (let ((path (localhost-fedwiki-page-promotion-plan-topic-snippet-pathname plan)))
    (if (or file-contents
            (uiop:file-exists-p path))
        (localhost-fedwiki-topic-snippet-artifact-reflected-source-snapshot-reflection
         (or file-contents
             (uiop:read-file-string path)))
        (make-localhost-fedwiki-source-snapshot-envelope-reflection
         :artifact-kind :topic-factory-lisp-snippet
         :status :missing))))

(defun localhost-fedwiki-page-promotion-plan-page-source-snapshot
    (plan &key file-contents)
  (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
   (localhost-fedwiki-page-promotion-plan-page-source-snapshot-reflection
    plan
    :file-contents file-contents)))

(defun localhost-fedwiki-page-promotion-plan-snippet-source-snapshot
    (plan &key file-contents)
  (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
   (localhost-fedwiki-page-promotion-plan-snippet-source-snapshot-reflection
    plan
    :file-contents file-contents)))

(defun localhost-fedwiki-page-promotion-plan-source-freshness-state-from-reflection
    (reflection current-source-snapshot)
  (case (localhost-fedwiki-source-snapshot-envelope-reflection-status reflection)
    (:present
     (if (and current-source-snapshot
              (equal (getf (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
                            reflection)
                           :fingerprint)
                     (getf current-source-snapshot :fingerprint)))
         :fresh
         :stale))
    (:malformed
     :unknown-malformed-envelope)
    (otherwise
     :unknown-missing-envelope)))

(defun localhost-fedwiki-source-snapshot-fingerprint-field (snapshot)
  (and snapshot
       (getf snapshot :fingerprint)))

(defun localhost-fedwiki-source-snapshot-summary-field (snapshot)
  (and snapshot
       (getf snapshot :summary)))

(defun localhost-fedwiki-page-promotion-plan-source-freshness-reason-from-reflection
    (reflection current-source-snapshot)
  (let* ((state
           (localhost-fedwiki-page-promotion-plan-source-freshness-state-from-reflection
            reflection
            current-source-snapshot))
         (reflected-snapshot
           (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
            reflection))
         (current-fingerprint
           (localhost-fedwiki-source-snapshot-fingerprint-field
            current-source-snapshot))
         (reflected-fingerprint
           (localhost-fedwiki-source-snapshot-fingerprint-field
            reflected-snapshot)))
    (case state
      (:fresh
       (format nil "Current normalized source fingerprint ~A matches reflected snapshot fingerprint ~A."
               (or current-fingerprint "n/a")
               (or reflected-fingerprint "n/a")))
      (:stale
       (format nil "Current normalized source fingerprint ~A differs from reflected snapshot fingerprint ~A."
               (or current-fingerprint "n/a")
               (or reflected-fingerprint "n/a")))
      (:unknown-malformed-envelope
       (format nil "Reflected source snapshot envelope is malformed~@[: ~A~]."
               (localhost-fedwiki-source-snapshot-envelope-reflection-error-message
                reflection)))
      (otherwise
       "Reflected source snapshot envelope is missing."))))

(defun localhost-fedwiki-page-promotion-plan-source-freshness-recommendation
    (artifact freshness-state)
  (let ((artifact-label
          (case artifact
            (:page "page artifact")
            (:snippet "snippet artifact")
            (otherwise "artifact")))
        (operation
          (case artifact
            (:page
             'regenerate-localhost-fedwiki-page-promotion-plan-page-artifact)
            (:snippet
             'regenerate-localhost-fedwiki-page-promotion-plan-snippet-artifact)
            (otherwise
             'localhost-fedwiki-page-promotion-plan-sync-status))))
    (case freshness-state
      (:fresh
       (list :action :no-regeneration-needed
             :label
             (format nil
                     "No regeneration needed; the ~A already reflects the current source snapshot."
                     artifact-label)
             :operation nil))
      (:stale
       (list :action :regenerate-artifact
             :label
             (format nil
                     "Regenerate the ~A to refresh its reflected source snapshot evidence."
                     artifact-label)
             :operation operation))
      (:unknown-malformed-envelope
       (list :action :regenerate-artifact
             :label
             (format nil
                     "Regenerate the ~A to repair reflected source snapshot evidence."
                     artifact-label)
             :operation operation))
      (otherwise
       (list :action :regenerate-artifact
             :label
             (format nil
                     "Regenerate the ~A to restore reflected source snapshot evidence."
                     artifact-label)
             :operation operation)))))

(defun localhost-fedwiki-page-promotion-plan-page-source-freshness-state
    (plan &key file-contents current-source-snapshot)
  (localhost-fedwiki-page-promotion-plan-source-freshness-state-from-reflection
   (localhost-fedwiki-page-promotion-plan-page-source-snapshot-reflection
    plan
    :file-contents file-contents)
   (or current-source-snapshot
       (localhost-fedwiki-page-promotion-plan-current-source-snapshot plan))))

(defun localhost-fedwiki-page-promotion-plan-snippet-source-freshness-state
    (plan &key file-contents current-source-snapshot)
  (localhost-fedwiki-page-promotion-plan-source-freshness-state-from-reflection
   (localhost-fedwiki-page-promotion-plan-snippet-source-snapshot-reflection
    plan
    :file-contents file-contents)
   (or current-source-snapshot
       (localhost-fedwiki-page-promotion-plan-current-source-snapshot plan))))

(defun localhost-fedwiki-page-promotion-plan-page-source-fresh-p
    (plan &key file-contents current-source-snapshot)
  (eql (localhost-fedwiki-page-promotion-plan-page-source-freshness-state
        plan
        :file-contents file-contents
        :current-source-snapshot current-source-snapshot)
       :fresh))

(defun localhost-fedwiki-page-promotion-plan-snippet-source-fresh-p
    (plan &key file-contents current-source-snapshot)
  (eql (localhost-fedwiki-page-promotion-plan-snippet-source-freshness-state
        plan
        :file-contents file-contents
        :current-source-snapshot current-source-snapshot)
       :fresh))

(defun localhost-fedwiki-page-promotion-plan-sync-status-report
    (plan
     &key page-contents snippet-contents current-source-snapshot)
  (let* ((resolved-current-source-snapshot
           (or current-source-snapshot
               (localhost-fedwiki-page-promotion-plan-current-source-snapshot
                plan)))
         (page-reflection
           (localhost-fedwiki-page-promotion-plan-page-source-snapshot-reflection
            plan
            :file-contents page-contents))
         (snippet-reflection
           (localhost-fedwiki-page-promotion-plan-snippet-source-snapshot-reflection
            plan
            :file-contents snippet-contents))
         (page-source-snapshot
           (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
            page-reflection))
         (snippet-source-snapshot
           (localhost-fedwiki-source-snapshot-envelope-reflection-snapshot
            snippet-reflection))
         (page-freshness-state
           (localhost-fedwiki-page-promotion-plan-source-freshness-state-from-reflection
            page-reflection
            resolved-current-source-snapshot))
         (snippet-freshness-state
           (localhost-fedwiki-page-promotion-plan-source-freshness-state-from-reflection
            snippet-reflection
            resolved-current-source-snapshot))
         (page-freshness-reason
           (localhost-fedwiki-page-promotion-plan-source-freshness-reason-from-reflection
            page-reflection
            resolved-current-source-snapshot))
         (snippet-freshness-reason
           (localhost-fedwiki-page-promotion-plan-source-freshness-reason-from-reflection
            snippet-reflection
            resolved-current-source-snapshot))
         (page-freshness-recommendation
           (localhost-fedwiki-page-promotion-plan-source-freshness-recommendation
            :page
            page-freshness-state))
         (snippet-freshness-recommendation
           (localhost-fedwiki-page-promotion-plan-source-freshness-recommendation
            :snippet
            snippet-freshness-state)))
    (list :plan-id
          (localhost-fedwiki-page-promotion-plan-id plan)
          :page-path
          (namestring
           (localhost-fedwiki-page-promotion-plan-composed-page-pathname plan))
          :snippet-path
          (namestring
           (localhost-fedwiki-page-promotion-plan-topic-snippet-pathname plan))
          :page-synced
          (localhost-fedwiki-page-promotion-plan-page-output-synced-p
           plan
           :file-contents page-contents)
          :snippet-synced
          (localhost-fedwiki-page-promotion-plan-snippet-output-synced-p
           plan
           :file-contents snippet-contents)
          :page-reflected-snapshot-status
          (localhost-fedwiki-source-snapshot-envelope-reflection-status
           page-reflection)
          :page-reflected-snapshot-present
          (eql (localhost-fedwiki-source-snapshot-envelope-reflection-status
                page-reflection)
               :present)
          :page-reflected-snapshot-malformed
          (eql (localhost-fedwiki-source-snapshot-envelope-reflection-status
                page-reflection)
               :malformed)
          :page-reflected-snapshot-fingerprint
          (localhost-fedwiki-source-snapshot-fingerprint-field page-source-snapshot)
          :page-reflected-snapshot-summary
          (localhost-fedwiki-source-snapshot-summary-field page-source-snapshot)
          :page-reflected-snapshot-error-message
          (localhost-fedwiki-source-snapshot-envelope-reflection-error-message
           page-reflection)
          :page-source-freshness-state
          page-freshness-state
          :page-source-freshness-reason
          page-freshness-reason
          :page-source-freshness-recommended-action
          (getf page-freshness-recommendation :action)
          :page-source-freshness-recommended-action-label
          (getf page-freshness-recommendation :label)
          :page-source-freshness-recommended-operation
          (getf page-freshness-recommendation :operation)
          :page-source-freshness-known
          (not (null (member page-freshness-state
                             '(:fresh :stale))))
          :page-source-freshness-unknown-reason
          (case page-freshness-state
            (:unknown-malformed-envelope :malformed-envelope)
            (:unknown-missing-envelope :missing-envelope))
          :page-source-fresh
          (eql page-freshness-state :fresh)
          :snippet-reflected-snapshot-status
          (localhost-fedwiki-source-snapshot-envelope-reflection-status
           snippet-reflection)
          :snippet-reflected-snapshot-present
          (eql (localhost-fedwiki-source-snapshot-envelope-reflection-status
                snippet-reflection)
               :present)
          :snippet-reflected-snapshot-malformed
          (eql (localhost-fedwiki-source-snapshot-envelope-reflection-status
                snippet-reflection)
               :malformed)
          :snippet-reflected-snapshot-fingerprint
          (localhost-fedwiki-source-snapshot-fingerprint-field snippet-source-snapshot)
          :snippet-reflected-snapshot-summary
          (localhost-fedwiki-source-snapshot-summary-field snippet-source-snapshot)
          :snippet-reflected-snapshot-error-message
          (localhost-fedwiki-source-snapshot-envelope-reflection-error-message
           snippet-reflection)
          :snippet-source-freshness-state
          snippet-freshness-state
          :snippet-source-freshness-reason
          snippet-freshness-reason
          :snippet-source-freshness-recommended-action
          (getf snippet-freshness-recommendation :action)
          :snippet-source-freshness-recommended-action-label
          (getf snippet-freshness-recommendation :label)
          :snippet-source-freshness-recommended-operation
          (getf snippet-freshness-recommendation :operation)
          :snippet-source-freshness-known
          (not (null (member snippet-freshness-state
                             '(:fresh :stale))))
          :snippet-source-freshness-unknown-reason
          (case snippet-freshness-state
            (:unknown-malformed-envelope :malformed-envelope)
            (:unknown-missing-envelope :missing-envelope))
          :snippet-source-fresh
          (eql snippet-freshness-state :fresh)
          :current-source-snapshot
          (copy-tree resolved-current-source-snapshot)
          :current-source-fingerprint
          (getf resolved-current-source-snapshot :fingerprint)
          :current-source-summary
          (getf resolved-current-source-snapshot :summary)
          :page-source-snapshot
          (copy-tree page-source-snapshot)
          :snippet-source-snapshot
          (copy-tree snippet-source-snapshot)
          :dmx-dry-run-summary
          (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan))))

(defun localhost-fedwiki-page-promotion-plan-source-freshness-action-label
    (artifact freshness-state)
  (case freshness-state
    (:fresh
     "No action needed")
    (:stale
     (case artifact
       (:page "Regenerate page artifact")
       (:snippet "Regenerate snippet artifact")
       (otherwise "Regenerate artifact")))
    (:unknown-malformed-envelope
     (case artifact
       (:page "Repair page snapshot evidence")
       (:snippet "Repair snippet snapshot evidence")
       (otherwise "Repair snapshot evidence")))
    (otherwise
     (case artifact
       (:page "Restore page snapshot evidence")
       (:snippet "Restore snippet snapshot evidence")
       (otherwise "Restore snapshot evidence")))))

(defun localhost-fedwiki-page-promotion-plan-attention-severity-for-state
    (freshness-state)
  (case freshness-state
    (:unknown-malformed-envelope 0)
    (:unknown-missing-envelope 1)
    (:stale 2)
    (:fresh 3)
    (otherwise 4)))

(defun localhost-fedwiki-page-promotion-plan-triage-category (status)
  (let ((page-state (getf status :page-source-freshness-state))
        (snippet-state (getf status :snippet-source-freshness-state)))
    (cond
      ((and (eql page-state :fresh)
            (eql snippet-state :fresh))
       :all-fresh)
      ((eql page-state snippet-state)
       (case page-state
         (:stale :stale)
         (:unknown-missing-envelope :unknown-missing-envelope)
         (:unknown-malformed-envelope :unknown-malformed-envelope)
         (otherwise :mixed-states)))
      (t
       :mixed-states))))

(defun localhost-fedwiki-page-promotion-plan-attention-needed-p (status)
  (not (eql (localhost-fedwiki-page-promotion-plan-triage-category status)
            :all-fresh)))

(defun localhost-fedwiki-page-promotion-plan-recommended-next-action-summary
    (status)
  (let* ((page-state (getf status :page-source-freshness-state))
         (snippet-state (getf status :snippet-source-freshness-state))
         (page-label
           (localhost-fedwiki-page-promotion-plan-source-freshness-action-label
            :page
            page-state))
         (snippet-label
           (localhost-fedwiki-page-promotion-plan-source-freshness-action-label
            :snippet
            snippet-state)))
    (if (and (eql page-state :fresh)
             (eql snippet-state :fresh))
        "No action needed"
        (format nil "Page: ~A; Snippet: ~A"
                page-label
                snippet-label))))

(defun localhost-fedwiki-page-promotion-plan-triage-row
    (plan &key status)
  (let* ((resolved-status
           (or status
               (localhost-fedwiki-page-promotion-plan-sync-status-report plan)))
         (page-state (getf resolved-status :page-source-freshness-state))
         (snippet-state (getf resolved-status :snippet-source-freshness-state))
         (attention-severity
           (min
            (localhost-fedwiki-page-promotion-plan-attention-severity-for-state
             page-state)
            (localhost-fedwiki-page-promotion-plan-attention-severity-for-state
             snippet-state))))
    (list :plan plan
          :inspect-target plan
          :plan-id (localhost-fedwiki-page-promotion-plan-id plan)
          :title (localhost-fedwiki-page-promotion-plan-title plan)
          :source-page-id
          (localhost-fedwiki-page-promotion-plan-source-page-id plan)
          :source-slug
          (localhost-fedwiki-page-promotion-plan-source-page-slug plan)
          :page-freshness-state page-state
          :snippet-freshness-state snippet-state
          :page-freshness-reason
          (getf resolved-status :page-source-freshness-reason)
          :snippet-freshness-reason
          (getf resolved-status :snippet-source-freshness-reason)
          :attention-category
          (localhost-fedwiki-page-promotion-plan-triage-category resolved-status)
          :attention-needed
          (localhost-fedwiki-page-promotion-plan-attention-needed-p resolved-status)
          :attention-severity attention-severity
          :recommended-next-action-summary
          (localhost-fedwiki-page-promotion-plan-recommended-next-action-summary
           resolved-status)
          :status resolved-status)))

(defun localhost-fedwiki-page-promotion-surface-triage-row-matches-filter-p
    (row filter)
  (case filter
    (:all t)
    (:attention-needed
     (getf row :attention-needed))
    (:all-fresh
     (eql (getf row :attention-category) :all-fresh))
    (:stale
     (eql (getf row :attention-category) :stale))
    (:unknown-missing-envelope
     (eql (getf row :attention-category) :unknown-missing-envelope))
    (:unknown-malformed-envelope
     (eql (getf row :attention-category) :unknown-malformed-envelope))
    (:mixed-states
     (eql (getf row :attention-category) :mixed-states))
    (otherwise
     t)))

(defun localhost-fedwiki-page-promotion-surface-triage-rows
    (surface &key status-overrides (filter :all))
  (remove-if-not
   (lambda (row)
     (localhost-fedwiki-page-promotion-surface-triage-row-matches-filter-p
      row
      filter))
   (sort
    (loop for plan in (localhost-fedwiki-page-promotion-surface-plans surface)
          for override = (cdr (assoc (localhost-fedwiki-page-promotion-plan-id
                                      plan)
                                     status-overrides
                                     :test #'equal))
          collect
          (localhost-fedwiki-page-promotion-plan-triage-row
           plan
           :status override))
    (lambda (left right)
      (or (< (getf left :attention-severity)
             (getf right :attention-severity))
          (and (= (getf left :attention-severity)
                  (getf right :attention-severity))
               (string-lessp (getf left :title)
                             (getf right :title))))))))

(defun localhost-fedwiki-page-promotion-surface-triage-counts
    (surface &key status-overrides)
  (let ((rows (localhost-fedwiki-page-promotion-surface-triage-rows
               surface
               :status-overrides status-overrides)))
    (list :plan-count (length rows)
          :attention-needed
          (count-if (lambda (row)
                      (getf row :attention-needed))
                    rows)
          :all-fresh
          (count :all-fresh rows :key (lambda (row) (getf row :attention-category)))
          :stale
          (count :stale rows :key (lambda (row) (getf row :attention-category)))
          :unknown-missing-envelope
          (count :unknown-missing-envelope
                 rows
                 :key (lambda (row) (getf row :attention-category)))
          :unknown-malformed-envelope
          (count :unknown-malformed-envelope
                 rows
                 :key (lambda (row) (getf row :attention-category)))
          :mixed-states
          (count :mixed-states
                 rows
                 :key (lambda (row) (getf row :attention-category))))))

;; Generic operations so the inspector exposes them in the Operations view.
(defgeneric localhost-fedwiki-page-promotion-plan-sync-status (plan)
  (:method ((plan localhost-fedwiki-page-promotion-plan))
    (localhost-fedwiki-page-promotion-plan-sync-status-report plan)))

(defgeneric regenerate-localhost-fedwiki-page-promotion-plan-page-artifact (plan)
  (:method ((plan localhost-fedwiki-page-promotion-plan))
    (localhost-fedwiki-page-promotion-plan-write-page-artifact plan)
    (append
     (list :action :page-artifact-regenerated)
     (localhost-fedwiki-page-promotion-plan-sync-status-report plan))))

(defgeneric regenerate-localhost-fedwiki-page-promotion-plan-snippet-artifact (plan)
  (:method ((plan localhost-fedwiki-page-promotion-plan))
    (localhost-fedwiki-page-promotion-plan-write-snippet-artifact plan)
    (append
     (list :action :snippet-artifact-regenerated)
     (localhost-fedwiki-page-promotion-plan-sync-status-report plan))))

(defgeneric regenerate-localhost-fedwiki-page-promotion-plan-artifacts (plan)
  (:method ((plan localhost-fedwiki-page-promotion-plan))
    (localhost-fedwiki-page-promotion-plan-write-page-artifact plan)
    (localhost-fedwiki-page-promotion-plan-write-snippet-artifact plan)
    (append
     (list :action :all-artifacts-regenerated)
     (localhost-fedwiki-page-promotion-plan-sync-status-report plan))))

(defgeneric review-localhost-fedwiki-page-promotion-plan-dmx-dry-run (plan)
  (:method ((plan localhost-fedwiki-page-promotion-plan))
    (list :plan-id
          (localhost-fedwiki-page-promotion-plan-id plan)
          :summary
          (localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary plan)
          :evidence
          (localhost-fedwiki-page-promotion-plan-dmx-dry-run-evidence plan))))

(defun find-localhost-fedwiki-page-promotion-plan-if
    (predicate &key signal-error? error-context)
  (or (find-if predicate
               (localhost-fedwiki-page-promotion-plans))
      (when signal-error?
        (error "No localhost FedWiki page promotion plan for ~A."
               (or error-context "the requested designator")))))

(defun find-localhost-fedwiki-page-promotion-plan-for-topic-id
    (topic-id &key signal-error?)
  (find-localhost-fedwiki-page-promotion-plan-if
   (lambda (plan)
     (equal topic-id
            (localhost-fedwiki-page-promotion-plan-related-topic-id plan)))
   :signal-error? signal-error?
   :error-context (format nil "topic id ~S" topic-id)))

(defun find-localhost-fedwiki-page-promotion-plan-for-topic
    (topic &key signal-error?)
  (and topic
       (find-localhost-fedwiki-page-promotion-plan-for-topic-id
        (id-of topic)
        :signal-error? signal-error?)))

(defun find-localhost-fedwiki-page-promotion-plan-for-topic-page
    (page &key signal-error?)
  (and page
       (find-localhost-fedwiki-page-promotion-plan-for-topic
        (topic-of page)
        :signal-error? signal-error?)))

(defun find-localhost-fedwiki-page-promotion-plan-for-source-page-id
    (page-id &key signal-error?)
  (find-localhost-fedwiki-page-promotion-plan-if
   (lambda (plan)
     (equal page-id
            (localhost-fedwiki-page-promotion-plan-source-page-id plan)))
   :signal-error? signal-error?
   :error-context (format nil "source page id ~S" page-id)))

(defun find-localhost-fedwiki-page-promotion-plan-for-source
    (source &key signal-error?)
  (and source
       (find-localhost-fedwiki-page-promotion-plan-for-source-page-id
        (localhost-fedwiki-source-data-fedwiki-page-id source)
        :signal-error? signal-error?)))

(defun find-localhost-fedwiki-page-promotion-plan-for-hyperdoc-page-title
    (title &key signal-error?)
  (find-localhost-fedwiki-page-promotion-plan-if
   (lambda (plan)
     (equal title
            (localhost-fedwiki-page-promotion-plan-related-hyperdoc-page-title
             plan)))
   :signal-error? signal-error?
   :error-context (format nil "HyperDoc page title ~S" title)))

(defun ensure-localhost-fedwiki-page-promotion-dmx-support ()
  (or (fboundp 'plan-topic-factory-snippet-dmx-write)
      (ignore-errors
        (asdf:load-system :hyperdoc/dmx-import))
      (fboundp 'plan-topic-factory-snippet-dmx-write)))

(defun make-localhost-fedwiki-page-promotion-memory-dmx-client ()
  (when (ensure-localhost-fedwiki-page-promotion-dmx-support)
    (when (find-class 'memory-dmx-import-client nil)
      (make-instance 'memory-dmx-import-client :next-topic-id 7000))))

(defun localhost-fedwiki-page-promotion-plan-dmx-dry-run-plan
    (plan
     &key workspace-topicmap-id client)
  (when (ensure-localhost-fedwiki-page-promotion-dmx-support)
    (funcall (symbol-function 'plan-topic-factory-snippet-dmx-write)
             (localhost-fedwiki-page-promotion-plan-topic-definition plan)
             :workspace-topicmap-id
             (or workspace-topicmap-id
                 (localhost-fedwiki-page-promotion-plan-default-workspace-topicmap-id
                  plan)
                 *localhost-fedwiki-page-promotion-default-workspace-topicmap-id*)
             :client
             (or client
                 (make-localhost-fedwiki-page-promotion-memory-dmx-client)))))

(defun localhost-fedwiki-page-promotion-plan-dmx-dry-run-summary
    (plan
     &key workspace-topicmap-id client)
  (if-let (dmx-plan
           (localhost-fedwiki-page-promotion-plan-dmx-dry-run-plan
            plan
            :workspace-topicmap-id workspace-topicmap-id
            :client client))
    (list :available t
          :uri (topic-factory-snippet-dmx-write-plan-uri dmx-plan)
          :snippet-id
          (topic-factory-snippet-dmx-write-plan-snippet-id dmx-plan)
          :workspace-topicmap-id
          (topic-factory-snippet-dmx-write-plan-workspace-topicmap-id dmx-plan)
          :topic-action
          (topic-factory-snippet-dmx-write-plan-topic-action dmx-plan)
          :topicmap-action
          (topic-factory-snippet-dmx-write-plan-topicmap-action dmx-plan)
          :source-path
          (topic-factory-snippet-dmx-write-plan-source-path dmx-plan)
          :related-hyperdoc-page-title
          (topic-factory-snippet-dmx-write-plan-related-hyperdoc-page-title
           dmx-plan)
          :related-topic-id
          (topic-factory-snippet-dmx-write-plan-related-topic-id dmx-plan)
          :provenance
          (copy-tree
           (topic-factory-snippet-dmx-write-plan-provenance dmx-plan)))
    (list :available nil
          :message
          "DMX dry-run planner is unavailable; load :hyperdoc/dmx-import to inspect the dry-run plan.")))

(defun localhost-fedwiki-page-promotion-plan-dmx-dry-run-evidence
    (plan
     &key workspace-topicmap-id client)
  (if (ensure-localhost-fedwiki-page-promotion-dmx-support)
      (with-output-to-string (stream)
        (funcall (symbol-function 'execute-topic-factory-snippet-dmx-write)
                 (localhost-fedwiki-page-promotion-plan-topic-definition plan)
                 :workspace-topicmap-id
                 (or workspace-topicmap-id
                     (localhost-fedwiki-page-promotion-plan-default-workspace-topicmap-id
                      plan)
                     *localhost-fedwiki-page-promotion-default-workspace-topicmap-id*)
                 :client
                 (or client
                     (make-localhost-fedwiki-page-promotion-memory-dmx-client))
                 :dry-run t
                 :stream stream))
      "DMX dry-run execution support is unavailable; load :hyperdoc/dmx-import to render dry-run evidence."))

(defun the-life-cycle-of-collective-knowledge-promotion-plan ()
  (make-localhost-fedwiki-page-promotion-plan
   :id "the-life-cycle-of-collective-knowledge-promotion-plan"
   :title "The Life Cycle of Collective Knowledge promotion plan"
   :summary
   "Inspectable plan for promoting fragment-derived topic chunks and local artifacts from the localhost FedWiki page the-life-cycle-of-collective-knowledge."
   :pipeline (the-life-cycle-of-collective-knowledge-page-pipeline)
   :source-chunk
   (the-life-cycle-of-collective-knowledge-localhost-fedwiki-source-chunk)
   :promoted-topic-chunks
   (the-life-cycle-of-collective-knowledge-topic-chunks)
   :topic-page (the-life-cycle-of-collective-knowledge-topic-page-chunk)
   :topic-definition
   (the-life-cycle-of-collective-knowledge-topic-definition-chunk)
   :dmx-snippet (the-life-cycle-of-collective-knowledge-dmx-snippet-chunk)
   :composed-page-target *the-life-cycle-of-collective-knowledge-page-path*
   :topic-factory-metadata
   (the-life-cycle-of-collective-knowledge-topic-factory-metadata)
   :local-artifact-writer
   'write-the-life-cycle-of-collective-knowledge-artifacts
   :page-renderer
   'render-the-life-cycle-of-collective-knowledge-page
   :default-workspace-topicmap-id
   *localhost-fedwiki-page-promotion-default-workspace-topicmap-id*))

(defun reproducible-devenv-as-knowledge-artifact-promotion-plan ()
  (make-localhost-fedwiki-page-promotion-plan
   :id "reproducible-devenv-as-knowledge-artifact-promotion-plan"
   :title "Reproducible DevEnv as Knowledge Artifact promotion plan"
   :summary
   "Inspectable plan for promoting whole-item topic chunks and local artifacts from the localhost FedWiki page reproducible-devenv-as-knowledge-artifact."
   :pipeline (reproducible-devenv-as-knowledge-artifact-page-pipeline)
   :source-chunk
   (reproducible-devenv-as-knowledge-artifact-localhost-fedwiki-source-chunk)
   :promoted-topic-chunks
   (reproducible-devenv-as-knowledge-artifact-topic-chunks)
   :topic-page
   (reproducible-devenv-as-knowledge-artifact-topic-page-chunk)
   :topic-definition
   (reproducible-devenv-as-knowledge-artifact-topic-definition-chunk)
   :dmx-snippet
   (reproducible-devenv-as-knowledge-artifact-dmx-snippet-chunk)
   :composed-page-target *reproducible-devenv-as-knowledge-artifact-page-path*
   :topic-factory-metadata
   (reproducible-devenv-as-knowledge-artifact-topic-factory-metadata)
   :local-artifact-writer
   'write-reproducible-devenv-as-knowledge-artifact-artifacts
   :page-renderer
   'render-reproducible-devenv-as-knowledge-artifact-page
   :default-workspace-topicmap-id
   *localhost-fedwiki-page-promotion-default-workspace-topicmap-id*))

(defun current-localhost-fedwiki-page-promotion-surface ()
  (make-localhost-fedwiki-page-promotion-surface
   :title "Localhost FedWiki page promotion plans"
   :summary
   "Reusable inspectable workflow surface for localhost FedWiki page promotion plans, their local composed outputs, and their dry-run DMX snippet twins."
   :plans
   (localhost-fedwiki-page-promotion-plans)))
