;;;; Generic bibliography subcollections and authoring plans
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *bibliography-default-hyperbook-id* "bibliography")
(defparameter *bibliography-default-main-page-id* "coachmark")
(defparameter *bibliography-default-materialization-root*
  (merge-pathnames "tools/generated/bibliography-authoring/"
                   (asdf:system-source-directory :hyperdoc)))
(defparameter *bibliography-stop-words*
  '("a" "an" "and" "app" "application" "applications" "for" "from" "in" "into"
    "of" "on" "or" "software" "system" "systems" "the" "to" "with"))
(defparameter *bibliography-candidate-head-tokens*
  '("coachmark" "coachmarks" "mark" "marks" "onboarding" "overlay" "overlays"
    "tour" "tours" "walkthrough" "walkthroughs" "help" "pattern" "patterns"
    "ux" "ui"))

(defclass bibliography-source ()
  ((source-system :reader bibliography-source-system-of
                  :initarg :source-system
                  :initform :unknown)
   (description :reader bibliography-source-description-of
                :initarg :description
                :initform nil)
   (default-collection :reader bibliography-source-default-collection-of
                       :initarg :default-collection
                       :initform *bibliography-default-main-page-id*)
   (materialization-root :reader bibliography-source-materialization-root-of
                         :initarg :materialization-root
                         :initform *bibliography-default-materialization-root*)))

(defclass bibliography-collection-hit ()
  ((collection-id :reader bibliography-collection-id-of
                  :initarg :collection-id
                  :initform nil)
   (collection-key :reader bibliography-collection-key-of
                   :initarg :collection-key
                   :initform nil)
   (collection-name :reader bibliography-collection-name-of
                    :initarg :collection-name)
   (collection-path :reader bibliography-collection-path-of
                    :initarg :collection-path)
   (path-components :reader bibliography-collection-path-components-of
                    :initarg :path-components
                    :initform nil)
   (parent-collection-id :reader bibliography-collection-parent-id-of
                         :initarg :parent-collection-id
                         :initform nil)
   (library-id :reader bibliography-collection-library-id-of
               :initarg :library-id
               :initform nil)
   (raw-row :reader bibliography-collection-raw-row-of
            :initarg :raw-row
            :initform nil)))

(defclass bibliography-subcollections-hyperbook (hb:hyperbook)
  ((source :reader bibliography-hyperbook-source-of
           :initarg :source)
   (title :reader hb:title-of
          :initarg :title
          :initform "Bibliography")
   (main-page-id :reader hb:main-page-id-of
                 :initarg :main-page-id
                 :initform *bibliography-default-main-page-id*)
   (pages :reader bibliography-hyperbook-pages-of
          :initform (make-hash-table :test #'equal))))

(defclass bibliography-subcollection (hb:page)
  ((source :reader bibliography-subcollection-source-of
           :initarg :source)
   (source-system :reader bibliography-subcollection-source-system-of
                  :initarg :source-system
                  :initform :unknown)
   (query-text :reader bibliography-subcollection-query-text-of
               :initarg :query-text)
   (collection-hit :reader bibliography-subcollection-collection-hit-of
                   :initarg :collection-hit)
   (collection-query :reader bibliography-subcollection-collection-query-of
                     :initarg :collection-query
                     :initform nil)
   (entry-query :reader bibliography-subcollection-entry-query-of
                :initarg :entry-query
                :initform nil)
   (author-query :reader bibliography-subcollection-author-query-of
                 :initarg :author-query
                 :initform nil)
   (tag-query :reader bibliography-subcollection-tag-query-of
              :initarg :tag-query
              :initform nil)
   (entries :reader bibliography-subcollection-entries-of
            :initarg :entries
            :initform nil)
   (candidate-topics :accessor bibliography-subcollection-candidate-topics-of
                     :initarg :candidate-topics
                     :initform nil)
   (authoring-plan :accessor bibliography-subcollection-authoring-plan-of
                   :initarg :authoring-plan
                   :initform nil)))

(defclass bibliography-entry ()
  ((source-system :reader bibliography-entry-source-system-of
                  :initarg :source-system
                  :initform :unknown)
   (collection-name :reader bibliography-entry-collection-name-of
                    :initarg :collection-name)
   (collection-path :reader bibliography-entry-collection-path-of
                    :initarg :collection-path)
   (collection-key :reader bibliography-entry-collection-key-of
                   :initarg :collection-key
                   :initform nil)
   (item-id :reader bibliography-entry-item-id-of
            :reader bibliography-entry-zotero-item-id-of
            :initarg :item-id)
   (item-key :reader bibliography-entry-item-key-of
             :reader bibliography-entry-zotero-item-key-of
             :initarg :item-key)
   (title :reader bibliography-entry-title-of :initarg :title)
   (authors :reader bibliography-entry-authors-of
            :initarg :authors
            :initform nil)
   (year :reader bibliography-entry-year-of
         :initarg :year
         :initform nil)
   (work-type :reader bibliography-entry-work-type-of
              :initarg :work-type
              :initform nil)
   (venue :reader bibliography-entry-venue-of
          :initarg :venue
          :initform nil)
   (doi :reader bibliography-entry-doi-of
        :initarg :doi
        :initform nil)
   (url :reader bibliography-entry-url-of
        :initarg :url
        :initform nil)
   (notes :reader bibliography-entry-notes-of
          :initarg :notes
          :initform nil)
   (tags :reader bibliography-entry-tags-of
         :initarg :tags
         :initform nil)
   (raw-source-text :reader bibliography-entry-raw-source-text-of
                    :initarg :raw-source-text)
   (raw-row :reader bibliography-entry-raw-row-of
            :initarg :raw-row)
   (author-rows :reader bibliography-entry-author-rows-of
                :initarg :author-rows
                :initform nil)
   (tag-rows :reader bibliography-entry-tag-rows-of
             :initarg :tag-rows
             :initform nil)))

(defclass candidate-topic-signal ()
  ((source-kind :reader candidate-topic-signal-source-kind-of
                :initarg :source-kind)
   (field :reader candidate-topic-signal-field-of
          :initarg :field)
   (raw-value :reader candidate-topic-signal-raw-value-of
              :initarg :raw-value)
   (display-title :reader candidate-topic-signal-display-title-of
                  :initarg :display-title)
   (normalized-key :reader candidate-topic-signal-normalized-key-of
                   :initarg :normalized-key)
   (aliases :reader candidate-topic-signal-aliases-of
            :initarg :aliases
            :initform nil)
   (entry :reader candidate-topic-signal-entry-of
          :initarg :entry
          :initform nil)
   (detail :reader candidate-topic-signal-detail-of
           :initarg :detail
           :initform nil)))

(defclass candidate-topic ()
  ((title :reader candidate-topic-title-of :initarg :title)
   (normalized-key :reader candidate-topic-normalized-key-of
                   :initarg :normalized-key)
   (aliases :reader candidate-topic-aliases-of
            :initarg :aliases
            :initform nil)
   (signals :reader candidate-topic-signals-of
            :initarg :signals
            :initform nil)
   (collection-signals :reader candidate-topic-collection-signals-of
                       :initarg :collection-signals
                       :initform nil)
   (entry-signals :reader candidate-topic-entry-signals-of
                  :initarg :entry-signals
                  :initform nil)
   (source-entries :reader candidate-topic-source-entries-of
                   :initarg :source-entries
                   :initform nil)
   (support-count :reader candidate-topic-support-count-of
                  :initarg :support-count
                  :initform 0)
   (broader-hints :reader candidate-topic-broader-hints-of
                  :initarg :broader-hints
                  :initform nil)
   (editorial-notes :reader candidate-topic-editorial-notes-of
                    :initarg :editorial-notes
                    :initform nil)))

(defclass topic-comparison-report ()
  ((candidate-topic :reader topic-comparison-report-candidate-topic-of
                    :initarg :candidate-topic)
   (exact-match :reader topic-comparison-report-exact-match-of
                :initarg :exact-match
                :initform nil)
   (alias-matches :reader topic-comparison-report-alias-matches-of
                  :initarg :alias-matches
                  :initform nil)
   (near-duplicate-matches
    :reader topic-comparison-report-near-duplicate-matches-of
    :initarg :near-duplicate-matches
    :initform nil)
   (broader-topic-matches
    :reader topic-comparison-report-broader-topic-matches-of
    :initarg :broader-topic-matches
    :initform nil)
   (status :reader topic-comparison-report-status-of
           :initarg :status)
   (review-notes :reader topic-comparison-report-review-notes-of
                 :initarg :review-notes
                 :initform nil)))

(defclass authoring-decision ()
  ((candidate-topic :reader authoring-decision-candidate-topic-of
                    :initarg :candidate-topic)
   (comparison-report :reader authoring-decision-comparison-report-of
                      :initarg :comparison-report)
   (decision-kind :reader authoring-decision-kind-of
                  :initarg :decision-kind)
   (topic-action :reader authoring-decision-topic-action-of
                 :initarg :topic-action)
   (page-action :reader authoring-decision-page-action-of
                :initarg :page-action)
   (target-topic-title :reader authoring-decision-target-topic-title-of
                       :initarg :target-topic-title
                       :initform nil)
   (target-page-title :reader authoring-decision-target-page-title-of
                      :initarg :target-page-title
                      :initform nil)
   (matched-existing-topic-title
    :reader authoring-decision-matched-existing-topic-title-of
    :initarg :matched-existing-topic-title
    :initform nil)
   (matched-existing-page-title
    :reader authoring-decision-matched-existing-page-title-of
    :initarg :matched-existing-page-title
    :initform nil)
   (source-provenance-evidence
    :reader authoring-decision-source-provenance-evidence-of
    :reader authoring-decision-zotero-provenance-evidence-of
    :initarg :source-provenance-evidence
    :initarg :zotero-provenance-evidence
    :initform nil)
   (entry-title-evidence
    :reader authoring-decision-entry-title-evidence-of
    :initarg :entry-title-evidence
    :initform nil)
   (notes-keywords-tag-evidence
    :reader authoring-decision-notes-keywords-tag-evidence-of
    :initarg :notes-keywords-tag-evidence
    :initform nil)
   (broader-neighborhood-evidence
    :reader authoring-decision-broader-neighborhood-evidence-of
    :initarg :broader-neighborhood-evidence
    :initform nil)
   (rationale :reader authoring-decision-rationale-of
              :initarg :rationale
              :initform nil)
   (materialization-consequence
    :reader authoring-decision-materialization-consequence-of
    :initarg :materialization-consequence
    :initform nil)
   (repo-touch-preview
    :reader authoring-decision-repo-touch-preview-of
    :initarg :repo-touch-preview
    :initform nil)
   (decision-notes :reader authoring-decision-notes-of
                   :initarg :decision-notes
                   :initform nil)))

(defclass bibliography-materialization-entry ()
  ((kind :reader bibliography-materialization-entry-kind-of
         :initarg :kind)
   (action :reader bibliography-materialization-entry-action-of
           :initarg :action)
   (target-path :reader bibliography-materialization-entry-target-path-of
                :initarg :target-path)
   (preview-text :reader bibliography-materialization-entry-preview-text-of
                 :initarg :preview-text)
   (decision :reader bibliography-materialization-entry-decision-of
             :initarg :decision
             :initform nil)
   (repo-touch-preview
    :reader bibliography-materialization-entry-repo-touch-preview-of
    :initarg :repo-touch-preview
    :initform nil)
   (existing-p :reader bibliography-materialization-entry-existing-p
               :initarg :existing-p
               :initform nil)))

(defclass hyperdoc-authoring-plan ()
  ((source-subcollection :reader hyperdoc-authoring-plan-source-subcollection-of
                         :initarg :source-subcollection)
   (candidate-topics :reader hyperdoc-authoring-plan-candidate-topics-of
                     :initarg :candidate-topics
                     :initform nil)
   (comparison-reports :reader hyperdoc-authoring-plan-comparison-reports-of
                       :initarg :comparison-reports
                       :initform nil)
   (authoring-decisions :reader hyperdoc-authoring-plan-authoring-decisions-of
                        :initarg :authoring-decisions
                        :initform nil)
   (materialization-entries
    :reader hyperdoc-authoring-plan-materialization-entries-of
    :initarg :materialization-entries
    :initform nil)
   (output-root :reader hyperdoc-authoring-plan-output-root-of
                :initarg :output-root)
   (editorial-notes :reader hyperdoc-authoring-plan-editorial-notes-of
                    :initarg :editorial-notes
                    :initform nil)
   (execution-report :accessor hyperdoc-authoring-plan-execution-report-of
                     :initarg :execution-report
                     :initform nil)))

(defun ensure-bibliography-subcollection-candidate-topics (subcollection)
  (or (bibliography-subcollection-candidate-topics-of subcollection)
      (setf (bibliography-subcollection-candidate-topics-of subcollection)
            (extract-candidate-topics subcollection))))

(defun ensure-bibliography-subcollection-authoring-plan (subcollection &key output-root)
  (or (bibliography-subcollection-authoring-plan-of subcollection)
      (let ((plan (build-hyperdoc-authoring-plan subcollection
                                                 :output-root output-root)))
        ;; Keep the summary surface aligned once the plan has been requested.
        (setf (bibliography-subcollection-candidate-topics-of subcollection)
              (hyperdoc-authoring-plan-candidate-topics-of plan)
              (bibliography-subcollection-authoring-plan-of subcollection)
              plan)
        plan)))

(defclass bibliography-authoring-plan-standin-report ()
  ((mode :reader bibliography-standin-mode-of
         :initarg :mode
         :initform :live)
   (collection-name :reader bibliography-standin-collection-name-of
                    :initarg :collection-name)
   (entry-page-title :reader bibliography-standin-entry-page-title-of
                     :initarg :entry-page-title)
   (link-text :reader bibliography-standin-link-text-of
              :initarg :link-text)
   (entry-page :reader bibliography-standin-entry-page-of
               :initarg :entry-page
               :initform nil)
   (entry-page-source-path :reader bibliography-standin-entry-page-source-path-of
                           :initarg :entry-page-source-path
                           :initform nil)
   (entry-page-tracked-in-git-p
    :reader bibliography-standin-entry-page-tracked-in-git-p
    :initarg :entry-page-tracked-in-git-p
    :initform nil)
   (entry-page-link-present-p
    :reader bibliography-standin-entry-page-link-present-p
    :initarg :entry-page-link-present-p
    :initform nil)
   (entry-page-selection-classification
    :reader bibliography-standin-entry-page-selection-classification-of
    :initarg :entry-page-selection-classification)
   (runtime-surface-inventory-classification
    :reader bibliography-standin-runtime-surface-inventory-classification-of
    :initarg :runtime-surface-inventory-classification)
   (workspace-vs-flake-mismatch-classification
    :reader bibliography-standin-workspace-vs-flake-mismatch-classification-of
    :initarg :workspace-vs-flake-mismatch-classification)
   (source :reader bibliography-standin-source-of
           :initarg :source)
   (authoring-plan :reader bibliography-standin-authoring-plan-of
                   :initarg :authoring-plan
                   :initform nil)
   (plan-ready-p :reader bibliography-standin-plan-ready-p
                 :initarg :plan-ready-p
                 :initform nil)
   (plan-build-ms :reader bibliography-standin-plan-build-ms-of
                  :initarg :plan-build-ms
                  :initform nil)
   (plan-error :reader bibliography-standin-plan-error-of
               :initarg :plan-error
               :initform nil)
   (output-root :reader bibliography-standin-output-root-of
                :initarg :output-root
                :initform nil)
   (last-protocol-boundary :reader bibliography-standin-last-protocol-boundary-of
                           :initarg :last-protocol-boundary
                           :initform nil)
   (failure-classification-before-browser
    :reader bibliography-standin-failure-classification-before-browser-of
    :initarg :failure-classification-before-browser
    :initform nil)
   (imported-entry-count :reader bibliography-standin-imported-entry-count-of
                         :initarg :imported-entry-count
                         :initform 0)
   (candidate-count :reader bibliography-standin-candidate-count-of
                    :initarg :candidate-count
                    :initform 0)
   (decision-count :reader bibliography-standin-decision-count-of
                   :initarg :decision-count
                   :initform 0)
   (materialization-entry-count
    :reader bibliography-standin-materialization-entry-count-of
    :initarg :materialization-entry-count
    :initform 0)
   (materialization-ms :reader bibliography-standin-materialization-ms-of
                       :initarg :materialization-ms
                       :initform nil)
   (artifact-bundle-ready-p :reader bibliography-standin-artifact-bundle-ready-p
                            :initarg :artifact-bundle-ready-p
                            :initform nil)
   (execution-report-count :reader bibliography-standin-execution-report-count-of
                           :initarg :execution-report-count
                           :initform 0)
   (plan-summary-path :reader bibliography-standin-plan-summary-path-of
                      :initarg :plan-summary-path
                      :initform nil)))

(defvar *bibliography-subcollections* nil)

(defgeneric load-bibliography-subcollection-using-source
    (source query-text &key signal-error? output-root))

(defmethod load-bibliography-subcollection-using-source
    ((source zotero-backend-unavailable) query-text &key signal-error? output-root)
  (declare (ignore query-text signal-error? output-root))
  source)

(defmethod load-bibliography-subcollection-using-source
    ((source bibliography-source) query-text &key signal-error? output-root)
  (declare (ignore output-root))
  (if signal-error?
      (error "No bibliography backend implementation is available for ~A (~A)."
             query-text
             (bibliography-source-system-of source))
      (make-zotero-backend-unavailable
       "bibliography subcollection lookup"
       :detail (format nil "no load-bibliography-subcollection-using-source method for source system ~A"
                       (bibliography-source-system-of source)))))

(defmethod print-object ((object bibliography-source) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A"
            (or (bibliography-source-description-of object)
                (string-downcase
                 (symbol-name (bibliography-source-system-of object)))))))

(defmethod print-object ((object bibliography-collection-hit) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A"
            (bibliography-collection-path-of object))))

(defmethod print-object ((object bibliography-subcollection) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~D entries)"
            (bibliography-collection-path-of
             (bibliography-subcollection-collection-hit-of object))
            (length (bibliography-subcollection-entries-of object)))))

(defmethod print-object ((object bibliography-entry) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A"
            (bibliography-entry-title-of object))))

(defmethod print-object ((object candidate-topic) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~D entry signals~:[~; + collection cue~])"
            (candidate-topic-title-of object)
            (length (candidate-topic-entry-signals-of object))
            (not (null (candidate-topic-collection-signals-of object))))))

(defmethod print-object ((object topic-comparison-report) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~A)"
            (candidate-topic-title-of
             (topic-comparison-report-candidate-topic-of object))
            (string-downcase
             (symbol-name (topic-comparison-report-status-of object))))))

(defmethod print-object ((object authoring-decision) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~A) -> ~A / ~A"
            (candidate-topic-title-of
             (authoring-decision-candidate-topic-of object))
            (string-downcase
             (symbol-name (authoring-decision-kind-of object)))
            (string-downcase
             (symbol-name (authoring-decision-topic-action-of object)))
            (string-downcase
             (symbol-name (authoring-decision-page-action-of object))))))

(defmethod print-object ((object bibliography-materialization-entry) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A ~A"
            (string-downcase
             (symbol-name (bibliography-materialization-entry-kind-of object)))
            (pathname-namestring-or-nil
             (bibliography-materialization-entry-target-path-of object)))))

(defmethod print-object ((object hyperdoc-authoring-plan) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~D candidates, ~D decisions)"
            (bibliography-collection-path-of
             (bibliography-subcollection-collection-hit-of
              (hyperdoc-authoring-plan-source-subcollection-of object)))
            (length (hyperdoc-authoring-plan-candidate-topics-of object))
            (length (hyperdoc-authoring-plan-authoring-decisions-of object)))))

(defmethod print-object ((object bibliography-authoring-plan-standin-report) stream)
  (print-unreadable-object (object stream :type t :identity t)
    (format stream "~A (~A)"
            (bibliography-standin-collection-name-of object)
            (bibliography-standin-failure-classification-before-browser-of object))))

(defmethod hb:title-of ((page bibliography-subcollection))
  (bibliography-collection-name-of
   (bibliography-subcollection-collection-hit-of page)))

(defun bibliography-standin-current-millis ()
  (round (* 1000 (/ (get-internal-real-time)
                    internal-time-units-per-second))))

(defun bibliography-standin-elapsed-millis (start)
  (- (bibliography-standin-current-millis) start))

(defun bibliography-entry-page-object (title)
  (ignore-errors
    (hyperbook:find-page (symbol-value '*hyperdoc*)
                         title
                         :signal-error? t)))

(defun bibliography-entry-page-source-pathname (page)
  (and page
       (typep page 'text-page)
       (file-of page)))

(defun bibliography-tracked-pathname (pathname)
  (and pathname
       (uiop:file-exists-p pathname)
       pathname))

(defun bibliography-entry-page-link-present-p (pathname string)
  (and pathname
       string
       (let ((contents (uiop:read-file-string pathname)))
         (not (null (search string contents :test #'char=))))))

(defun bibliography-git-tracked-p (pathname)
  (let* ((root (uiop:ensure-directory-pathname
                (asdf:system-source-directory :hyperdoc)))
         (relative (and pathname
                        (enough-namestring pathname root))))
    (cond
      ((null relative)
       nil)
      (t
       (handler-case
           (zerop
            (nth-value
             2
             (uiop:run-program
              (list "git" "-C" (namestring root) "ls-files" "--error-unmatch" relative)
              :output :string
              :error-output :output
              :ignore-error-status t)))
         (error ()
           :unavailable))))))

(defun bibliography-entry-page-selection-classification (page source-path tracked-p link-present-p)
  (cond
    ((and page source-path (eq tracked-p t) link-present-p)
     "tracked-entry-page-selected")
    ((and page source-path link-present-p)
     "workspace-entry-page-selected")
    ((and page source-path)
     "entry-page-selected-link-missing")
    (page
     "runtime-entry-page-selected-no-source-path")
    (t
     "entry-page-missing")))

(defun bibliography-runtime-surface-inventory-classification (page source-path link-present-p)
  (cond
    ((and page source-path link-present-p)
     "runtime-entry-page-with-live-link")
    ((and page source-path)
     "runtime-entry-page-without-live-link")
    (page
     "runtime-entry-page-without-workspace-source")
    (t
     "runtime-entry-page-missing")))

(defun bibliography-workspace-vs-flake-mismatch-classification (source-path tracked-p)
  (cond
    ((and source-path (eq tracked-p t))
     "tracked-page-no-mismatch-risk")
    ((eq tracked-p :unavailable)
     "git-tracking-unavailable")
    (source-path
     "workspace-only-page-mismatch-risk")
    (t
     "missing-workspace-page")))

(defun bibliography-failure-classification-before-browser
    (selection-classification mismatch-classification plan plan-ready-p artifact-ready-p)
  (cond
    ((zotero-backend-unavailable-p plan)
     (case (zotero-backend-unavailable-reason-of plan)
       (:disabled-by-configuration
        "zotero-disabled-by-configuration")
       (otherwise
        "zotero-backend-load-failed")))
    ((string/= selection-classification "tracked-entry-page-selected")
     "tracked-entry-page-selection-defect")
    ((string/= mismatch-classification "tracked-page-no-mismatch-risk")
     "workspace-vs-flake-mismatch")
    ((not plan-ready-p)
     "authoring-plan-construction-defect")
    ((not artifact-ready-p)
     "artifact-bundle-production-defect")
    (t
     "ready-before-pane-open")))

(defun bibliography-standin-output-root (label)
  (uiop:ensure-directory-pathname
   (merge-pathnames
    (format nil "bibliography-standin-~A-~D/"
            label
            (get-universal-time))
    (uiop:temporary-directory))))

(defun bibliography-materialize-plan-and-summarize (plan)
  (let* ((materialization-start (bibliography-standin-current-millis))
         (materialized (materialize-bibliography-authoring-plan plan))
         (subcollection (hyperdoc-authoring-plan-source-subcollection-of materialized))
         (output-root (hyperdoc-authoring-plan-output-root-of materialized))
         (plan-summary (merge-pathnames "plan-summary.txt" output-root))
         (execution-report (hyperdoc-authoring-plan-execution-report-of materialized)))
    (list :artifact-ready-p (uiop:file-exists-p plan-summary)
          :materialization-ms
          (bibliography-standin-elapsed-millis materialization-start)
          :plan-summary-path plan-summary
          :execution-report-count (length execution-report)
          :materialization-entry-count
          (length (hyperdoc-authoring-plan-materialization-entries-of materialized))
          :candidate-count
          (length (hyperdoc-authoring-plan-candidate-topics-of materialized))
          :decision-count
          (length (hyperdoc-authoring-plan-authoring-decisions-of materialized))
          :imported-entry-count
          (length (bibliography-subcollection-entries-of subcollection)))))

(defun bibliography-authoring-plan-standin-report
    (collection-name
     &key (source (make-default-bibliography-source))
       (mode :live)
       (entry-page-title "Bibliography subcollections in HyperDoc")
       (link-text collection-name)
       output-root)
  (let* ((page (bibliography-entry-page-object entry-page-title))
         (source-path (bibliography-tracked-pathname
                       (bibliography-entry-page-source-pathname page)))
         (tracked-p (bibliography-git-tracked-p source-path))
         (link-present-p (bibliography-entry-page-link-present-p source-path link-text))
         (selection-classification
           (bibliography-entry-page-selection-classification
            page
            source-path
            tracked-p
            link-present-p))
         (inventory-classification
           (bibliography-runtime-surface-inventory-classification
            page
            source-path
            link-present-p))
         (mismatch-classification
           (bibliography-workspace-vs-flake-mismatch-classification
            source-path
            tracked-p))
         (resolved-output-root
           (or output-root
               (bibliography-standin-output-root
                (substitute #\- #\Space
                            (string-downcase collection-name)))))
         (plan-build-start (bibliography-standin-current-millis))
         (plan nil)
         (plan-error nil))
    (handler-case
        (setf plan (plan-bibliography-authoring
                    collection-name
                    :source source
                    :signal-error? t
                    :output-root resolved-output-root))
      (error (condition)
        (setf plan-error (princ-to-string condition))))
    (when (zotero-backend-unavailable-p plan)
      (setf plan-error (zotero-backend-unavailable-message-of plan)))
    (let* ((plan-build-ms (bibliography-standin-elapsed-millis plan-build-start))
           (plan-ready-p (typep plan 'hyperdoc-authoring-plan))
           (materialization-summary
             (and plan-ready-p
                  (bibliography-materialize-plan-and-summarize plan)))
           (artifact-ready-p (getf materialization-summary :artifact-ready-p))
           (failure-classification
             (bibliography-failure-classification-before-browser
              selection-classification
              mismatch-classification
              plan
              plan-ready-p
              artifact-ready-p))
           (last-protocol-boundary
             (cond
               (artifact-ready-p "artifact-bundle-written")
               (plan-ready-p "authoring-plan-ready")
               ((zotero-backend-unavailable-p plan)
                "zotero-backend-unavailable")
               ((string= selection-classification "tracked-entry-page-selected")
                "tracked-entry-page-selected")
               (t
                "pre-entry-page-ready"))))
      (make-instance 'bibliography-authoring-plan-standin-report
                     :mode mode
                     :collection-name collection-name
                     :entry-page-title entry-page-title
                     :link-text link-text
                     :entry-page page
                     :entry-page-source-path source-path
                     :entry-page-tracked-in-git-p tracked-p
                     :entry-page-link-present-p link-present-p
                     :entry-page-selection-classification selection-classification
                     :runtime-surface-inventory-classification inventory-classification
                     :workspace-vs-flake-mismatch-classification mismatch-classification
                     :source source
                     :authoring-plan plan
                     :plan-ready-p plan-ready-p
                     :plan-build-ms plan-build-ms
                     :plan-error plan-error
                     :output-root resolved-output-root
                     :last-protocol-boundary last-protocol-boundary
                     :failure-classification-before-browser failure-classification
                     :imported-entry-count
                     (or (getf materialization-summary :imported-entry-count) 0)
                     :candidate-count
                     (or (getf materialization-summary :candidate-count) 0)
                     :decision-count
                     (or (getf materialization-summary :decision-count) 0)
                     :materialization-entry-count
                     (or (getf materialization-summary :materialization-entry-count) 0)
                     :materialization-ms
                     (getf materialization-summary :materialization-ms)
                     :artifact-bundle-ready-p artifact-ready-p
                     :execution-report-count
                     (or (getf materialization-summary :execution-report-count) 0)
                     :plan-summary-path
                     (getf materialization-summary :plan-summary-path)))))

(defun coachmark-bibliography-authoring-plan-standin-report
    (&key (source (make-default-bibliography-source)))
  (bibliography-authoring-plan-standin-report
   "coachmark"
   :source source
   :mode :live
   :link-text "coachmark"))

(defun plastics-packaging-bibliography-authoring-plan-standin-report
    (&key (source (make-default-bibliography-source)))
  (bibliography-authoring-plan-standin-report
   "Plastics Packaging"
   :source source
   :mode :live
   :link-text "Plastics Packaging live plan"))

(defun ensure-bibliography-subcollections-hyperbook
    (&key (source (make-default-bibliography-source))
       (id *bibliography-default-hyperbook-id*)
       (title "Bibliography")
       (main-page-id (and (typep source 'bibliography-source)
                          (bibliography-source-default-collection-of source)))
       register?)
  (if (zotero-backend-unavailable-p source)
      source
      (let ((book
              (or (and *bibliography-subcollections*
                       (equal (hb:id-of *bibliography-subcollections*) id)
                       (typep *bibliography-subcollections* 'bibliography-subcollections-hyperbook)
                       (eq (bibliography-hyperbook-source-of *bibliography-subcollections*)
                           source)
                       *bibliography-subcollections*)
                  (setf *bibliography-subcollections*
                        (make-instance 'bibliography-subcollections-hyperbook
                                       :id id
                                       :source source
                                       :title title
                                       :main-page-id (or main-page-id
                                                         *bibliography-default-main-page-id*))))))
        (when register?
          (register book))
        book)))

(defun string-blank-p (value)
  (or (null value)
      (and (symbolp value)
           (string-equal (symbol-name value) "NULL"))
      (and (stringp value)
           (string= "" (string-trim '(#\Space #\Tab #\Newline #\Return) value)))))

(defun maybe-string (value)
  (unless (string-blank-p value)
    (format nil "~A" value)))

(defun lowercase-string (value)
  (string-downcase (or value "")))

(defun collapse-whitespace (value)
  (with-output-to-string (stream)
    (let ((pending-space nil))
      (loop for char across (or value "")
            do (if (find char '(#\Space #\Tab #\Newline #\Return))
                   (setf pending-space t)
                   (progn
                     (when (and pending-space
                                (> (file-position stream) 0))
                       (write-char #\Space stream))
                     (setf pending-space nil)
                     (write-char char stream)))))))

(defun sentence-case-term (value)
  (let ((trimmed (collapse-whitespace (string-trim '(#\Space #\Tab) (or value "")))))
    (if (string= trimmed "")
        ""
        (concatenate 'string
                     (string-upcase (subseq trimmed 0 1))
                     (subseq trimmed 1)))))

(defun alphanumeric-or-space-string (value)
  (with-output-to-string (stream)
    (loop for char across (or value "")
          do (cond
               ((or (alpha-char-p char)
                    (digit-char-p char))
                (write-char (char-downcase char) stream))
               (t
                (write-char #\Space stream))))))

(defun split-words (value)
  (remove-if #'string-blank-p
             (uiop:split-string (alphanumeric-or-space-string value)
                                :separator '(#\Space))))

(defun string-ends-with-p (string suffix)
  (let ((string (or string ""))
        (suffix (or suffix "")))
    (and (<= (length suffix) (length string))
         (string-equal suffix
                       (subseq string (- (length string) (length suffix)))))))

(defun singularize-word (word)
  (cond
    ((<= (length word) 3) word)
    ((string-ends-with-p word "ies")
     (format nil "~A~A" (subseq word 0 (- (length word) 3)) "y"))
    ((and (string-ends-with-p word "s")
          (not (string-ends-with-p word "ss")))
     (subseq word 0 (1- (length word))))
    (t
     word)))

(defun phrase-display-title (words)
  (sentence-case-term
   (format nil "~{~A~^ ~}"
           (mapcar #'string-downcase words))))

(defun title-normalized-key-from-phrase (value)
  (format nil "~{~A~^ ~}"
          (mapcar #'singularize-word
                  (split-words value))))

(defun maybe-split-compound-mark (value)
  (let* ((downcased (lowercase-string value)))
    (cond
      ((string-ends-with-p downcased "marks")
       (let ((stem (subseq downcased 0 (- (length downcased) 5))))
         (unless (string-blank-p stem)
           (list (format nil "~A marks" stem)
                 (format nil "~A mark" stem)))))
      ((string-ends-with-p downcased "mark")
       (let ((stem (subseq downcased 0 (- (length downcased) 4))))
         (unless (string-blank-p stem)
           (list (format nil "~A mark" stem)
                 (format nil "~A marks" stem)))))
      (t
       nil))))

(defun phrase-aliases (value)
  (let* ((trimmed (string-trim '(#\Space #\Tab) (or value "")))
         (words (split-words trimmed))
         (joined (and words (format nil "~{~A~^ ~}" words)))
         (aliases (remove nil
                          (append (list joined)
                                  (when (> (length words) 1)
                                    (list (format nil "~{~A~^-~}" words)
                                          (format nil "~{~A~}" words)
                                          (format nil "~{~A~^ ~}"
                                                  (append (butlast words)
                                                          (list (singularize-word
                                                                 (car (last words))))))))
                                  (maybe-split-compound-mark trimmed)))))
    (remove-duplicates
     (mapcar #'sentence-case-term aliases)
     :test #'string-equal)))

(defun candidate-broader-hints (title)
  (let ((words (split-words title)))
    (remove-duplicates
     (loop for tail on words
           when (> (length tail) 0)
             collect (phrase-display-title tail))
     :test #'string-equal)))

(defun parse-year-from-date-string (value)
  (let ((string (maybe-string value)))
    (when string
      (let ((start (position-if #'digit-char-p string)))
      (when start
        (ignore-errors
          (parse-integer string
                         :start start
                         :end (+ start 4))))))))

(defun hyperdoc-page-present-p (title)
  (let ((book (find-hyperbook "hyperdoc")))
    (and book
         (ignore-errors
           (hb:find-page book title)))))

(defun all-current-topics ()
  (ensure-topic-indexes)
  (loop for topic being each hash-value of *topics-by-id*
        collect topic))

(defun unique-topic-list (topics)
  (remove-duplicates (remove nil topics)
                     :key #'title-of
                     :test #'string=))

(defun string-score-for-preferred-title (signal)
  (+ (ecase (candidate-topic-signal-source-kind-of signal)
       (:entry-tag 50)
       (:entry-title 40)
       (:entry-note 30)
       (:entry-venue 20)
       (:collection-name 10))
     (if (search " " (candidate-topic-signal-display-title-of signal)) 5 0)
     (length (candidate-topic-signal-display-title-of signal))))

(defun choose-candidate-title (signals)
  (candidate-topic-signal-display-title-of
   (first (sort (copy-list signals) #'> :key #'string-score-for-preferred-title))))

(defun hash-table-values (table)
  (loop for value being each hash-value of table
        collect value))

(defun group-rows-by-key (rows key)
  (let ((table (make-hash-table :test #'equal)))
    (dolist (row rows)
      (push row (gethash (gethash key row) table)))
    (maphash (lambda (group-key group-rows)
               (setf (gethash group-key table) (nreverse group-rows)))
             table)
    table))

(defun candidate-topic-key (title aliases)
  (or (let ((keys
              (remove-if #'string-blank-p
                         (mapcar #'title-normalized-key-from-phrase aliases))))
        (when keys
          (first (sort (copy-list keys) #'string<))))
      (title-normalized-key-from-phrase title)))

(defun bibliography-output-root-for-subcollection (subcollection &optional source)
  (let* ((source (or source (bibliography-subcollection-source-of subcollection)))
         (base (uiop:ensure-directory-pathname
                (or (and (typep source 'bibliography-source)
                         (bibliography-source-materialization-root-of source))
                    *bibliography-default-materialization-root*))))
    (merge-pathnames
     (format nil "~A/"
             (string-downcase
              (substitute #\- #\Space
                          (bibliography-collection-name-of
                           (bibliography-subcollection-collection-hit-of
                            subcollection)))))
     base)))

(defun bibliography-page-filename (title)
  (merge-pathnames (format nil "~A.html" title)
                   #P"page-fragments/"))

(defun bibliography-update-note-filename (title)
  (let* ((slug (substitute #\- #\Space (string-downcase title))))
    (merge-pathnames (format nil "~A.txt" slug)
                     #P"page-update-notes/")))

(defun bibliography-topic-snippet-filename (title)
  (let* ((slug (substitute #\- #\Space (string-downcase title))))
    (merge-pathnames (format nil "~A-topic.lisp" slug)
                     #P"topic-factories/")))

(defun bibliography-summary-path ()
  #P"plan-summary.txt")

(defun bibliography-field-label (field)
  (case field
    (:title "Title")
    (:notes "Notes")
    (:tags "Tag")
    (:venue "Venue")
    (:collection-name "Collection")
    (otherwise
     (string-capitalize
      (substitute #\Space #\- (string-downcase (symbol-name field)))))))

(defun bibliography-preview-string (value &key (limit 96))
  (let* ((string (maybe-string value)))
    (cond
      ((null string) "")
      ((<= (length string) limit) string)
      (t (format nil "~A..." (subseq string 0 (- limit 3)))))))

(defun bibliography-signal-evidence-line (signal &key (show-field? t))
  (let* ((field (candidate-topic-signal-field-of signal))
         (raw (bibliography-preview-string
               (candidate-topic-signal-raw-value-of signal)))
         (display (candidate-topic-signal-display-title-of signal))
         (prefix (if show-field?
                     (format nil "~A " (bibliography-field-label field))
                     "")))
    (format nil "~A\"~A\" -> ~A"
            prefix
            raw
            display)))

(defun candidate-evidence-lines (candidate predicate &key (show-field? t))
  (remove-duplicates
   (loop for signal in (candidate-topic-signals-of candidate)
         when (funcall predicate signal)
           collect (bibliography-signal-evidence-line signal
                                                     :show-field? show-field?))
   :test #'string-equal))

(defun topic-constructor-symbol-for-title (title)
  (ensure-topic-indexes)
  (let (matches)
    (do-symbols (symbol (find-package :hyperdoc))
      (when (topic-constructor-symbol-p symbol)
        (handler-case
            (let ((topic (funcall (authored-topic-factory symbol))))
              (when (and (typep topic 'topic)
                         (string= (title-of topic) title))
                (push symbol matches)))
          (error () nil))))
    (first (sort matches #'string< :key #'symbol-name))))

(defun bibliography-topic-function-reference (title)
  (when-let (symbol (topic-constructor-symbol-for-title title))
    (format nil "hyperdoc::~(~A~)" symbol)))

(defun bibliography-topics-repo-path ()
  "hyperdoc/topics.lisp")

(defun bibliography-page-repo-path (title)
  (format nil "hyperdoc/~A.html" title))

(defun decision-kind-for-actions (status topic-action)
  (case status
    ((:exact-title-match :alias-match :near-duplicate-match)
     :merge-into-existing-topic)
    (:broader-topic-review
     :merge-into-broader-topic)
    (:new-topic
     (case topic-action
       (:add-new-topic-factory :new-topic-proposal)
       (:leave-arrangement-only :arrangement-only)
       (:leave-unmaterialized :continuity-shell)
       (otherwise :editorial-review)))))

(defun decision-materialization-consequence (topic-action page-action)
  (remove-duplicates
   (remove nil
           (list (case topic-action
                   (:add-new-topic-factory :add-topic)
                   ((:merge-into-existing-topic-factory
                     :merge-into-broader-topic-factory)
                    :update-topic)
                   (otherwise nil))
                 (case page-action
                   (:write-new-page :write-page)
                   (:update-existing-page :update-page)
                   ((:arrangement-only-mention
                     :continuity-shell-mention)
                    :no-write-yet)
                   (otherwise nil))))
   :test #'eq))

(defun decision-existing-page-title (target-page-title)
  (and target-page-title
       (hyperdoc-page-present-p target-page-title)
       target-page-title))

(defun decision-source-provenance-evidence (candidate subcollection)
  (let* ((collection-hit (bibliography-subcollection-collection-hit-of subcollection))
         (item-ids (remove nil
                           (mapcar #'bibliography-entry-item-id-of
                                   (candidate-topic-source-entries-of candidate)))))
    (remove nil
            (append
             (list (format nil "Collection path: ~A"
                           (bibliography-collection-path-of collection-hit))
                   (format nil "Collection key: ~A"
                           (bibliography-collection-key-of collection-hit)))
             (when item-ids
               (list (format nil "~A item ids: ~{~A~^, ~}"
                             (string-capitalize
                              (string-downcase
                               (symbol-name
                                (bibliography-subcollection-source-system-of
                                 subcollection))))
                             item-ids)))
             (candidate-evidence-lines
              candidate
              (lambda (signal)
                (eq (candidate-topic-signal-source-kind-of signal)
                    :collection-name))
              :show-field? nil)))))

(defun decision-entry-title-evidence (candidate)
  (candidate-evidence-lines
   candidate
   (lambda (signal)
     (eq (candidate-topic-signal-field-of signal) :title))))

(defun decision-notes-keywords-tag-evidence (candidate)
  (candidate-evidence-lines
   candidate
   (lambda (signal)
     (member (candidate-topic-signal-field-of signal)
             '(:notes :tags)))))

(defun decision-broader-neighborhood-evidence (candidate comparison decision-notes)
  (remove-duplicates
   (append
    (loop for signal in (candidate-topic-signals-of candidate)
          when (and (not (eq (candidate-topic-signal-source-kind-of signal)
                             :collection-name))
                    (not (member (candidate-topic-signal-field-of signal)
                                 '(:title :notes :tags))))
            collect (bibliography-signal-evidence-line signal))
    (loop for title in (candidate-topic-broader-hints-of candidate)
          collect (format nil "Broader hint: ~A" title))
    (loop for note in (topic-comparison-report-review-notes-of comparison)
          collect (format nil "Comparison note: ~A" note))
    (loop for note in decision-notes
          collect (format nil "Editorial note: ~A" note)))
   :test #'string-equal))

(defun decision-repo-touch-preview (topic-action page-action
                                     &key target-topic-title
                                       target-page-title
                                       matched-existing-topic-title)
  (let ((lines '()))
    (case topic-action
      (:add-new-topic-factory
       (push (format nil "+ ~A :: function ~A for topic \"~A\""
                     (bibliography-topics-repo-path)
                     (bibliography-topic-function-name-from-title
                      target-topic-title)
                     target-topic-title)
             lines))
      ((:merge-into-existing-topic-factory
        :merge-into-broader-topic-factory)
       (let* ((title (or matched-existing-topic-title target-topic-title))
              (reference (or (bibliography-topic-function-reference title)
                             (format nil "existing topic factory for \"~A\"" title))))
         (push (format nil "~A ~A :: ~A"
                       "~"
                       (bibliography-topics-repo-path)
                       reference)
               lines))))
    (case page-action
      (:write-new-page
       (push (format nil "+ ~A :: page \"~A\""
                     (bibliography-page-repo-path target-page-title)
                     target-page-title)
             lines))
      (:update-existing-page
       (when target-page-title
         (push (format nil "~A ~A :: page \"~A\""
                       "~"
                       (bibliography-page-repo-path target-page-title)
                       target-page-title)
               lines)))
      ((:arrangement-only-mention :continuity-shell-mention)
       (push "= no direct repo write yet; keep as reviewed plan evidence"
             lines)))
    (nreverse lines)))

(defun make-authoring-decision
    (candidate comparison subcollection
     &key topic-action page-action target-topic-title target-page-title decision-notes)
  (let* ((status (topic-comparison-report-status-of comparison))
         (decision-kind (decision-kind-for-actions status topic-action))
         (matched-existing-topic-title
           (and (not (eq status :new-topic))
                (decision-target-topic comparison)))
         (matched-existing-page-title
           (decision-existing-page-title
            (or matched-existing-topic-title target-page-title)))
         (rationale (or (first decision-notes)
                        "Editorial review required."))
         (materialization-consequence
           (decision-materialization-consequence topic-action page-action))
         (repo-touch-preview
           (decision-repo-touch-preview
            topic-action
            page-action
            :target-topic-title target-topic-title
            :target-page-title target-page-title
            :matched-existing-topic-title matched-existing-topic-title)))
    (make-instance 'authoring-decision
                   :candidate-topic candidate
                   :comparison-report comparison
                   :decision-kind decision-kind
                   :topic-action topic-action
                   :page-action page-action
                   :target-topic-title target-topic-title
                   :target-page-title target-page-title
                   :matched-existing-topic-title matched-existing-topic-title
                   :matched-existing-page-title matched-existing-page-title
                   :source-provenance-evidence
                   (decision-source-provenance-evidence candidate subcollection)
                   :entry-title-evidence
                   (decision-entry-title-evidence candidate)
                   :notes-keywords-tag-evidence
                   (decision-notes-keywords-tag-evidence candidate)
                   :broader-neighborhood-evidence
                   (decision-broader-neighborhood-evidence
                    candidate comparison decision-notes)
                   :rationale rationale
                   :materialization-consequence materialization-consequence
                   :repo-touch-preview repo-touch-preview
                   :decision-notes decision-notes)))

(defun candidate-topic-provenance-summary (candidate)
  (list :collection-signals
        (mapcar #'candidate-topic-signal-display-title-of
                (candidate-topic-collection-signals-of candidate))
        :entry-signals
        (mapcar #'candidate-topic-signal-display-title-of
                (candidate-topic-entry-signals-of candidate))))

(defun extract-ngram-signals-from-text (text &key entry field source-kind)
  (let* ((tokens (remove-if (lambda (token)
                              (member token *bibliography-stop-words* :test #'string=))
                            (split-words text)))
         (signals '()))
    (loop for size from 1 to 3 do
      (loop for start from 0 to (- (length tokens) size)
            for phrase-words = (subseq tokens start (+ start size))
            for last-word = (car (last phrase-words))
            when (member last-word *bibliography-candidate-head-tokens* :test #'string=)
              do (let* ((display-title (phrase-display-title phrase-words))
                        (aliases (phrase-aliases display-title)))
                   (push (make-instance 'candidate-topic-signal
                                        :source-kind source-kind
                                        :field field
                                        :raw-value display-title
                                        :display-title display-title
                                        :normalized-key (candidate-topic-key
                                                         display-title
                                                         aliases)
                                        :aliases aliases
                                        :entry entry
                                        :detail "Derived by simple n-gram extraction from bibliography metadata text.")
                         signals))))
    (nreverse signals)))

(defun collection-name-signals (collection-hit)
  (let* ((name (bibliography-collection-name-of collection-hit))
         (display-title (sentence-case-term name))
         (aliases (phrase-aliases display-title)))
    (list (make-instance 'candidate-topic-signal
                         :source-kind :collection-name
                         :field :collection-name
                         :raw-value name
                         :display-title display-title
                         :normalized-key (candidate-topic-key display-title aliases)
                         :aliases aliases
                         :detail "Collection/subcollection provenance cue from the bibliography source."))))

(defun entry-tag-signals (entry)
  (loop for tag in (bibliography-entry-tags-of entry)
        for display-title = (sentence-case-term tag)
        for aliases = (phrase-aliases display-title)
        collect (make-instance 'candidate-topic-signal
                               :source-kind :entry-tag
                               :field :tags
                               :raw-value tag
                               :display-title display-title
                               :normalized-key (candidate-topic-key display-title aliases)
                               :aliases aliases
                               :entry entry
                               :detail "Explicit source tag on the bibliography item.")))

(defun entry-title-signals (entry)
  (extract-ngram-signals-from-text (bibliography-entry-title-of entry)
                                   :entry entry
                                   :field :title
                                   :source-kind :entry-title))

(defun entry-note-signals (entry)
  (extract-ngram-signals-from-text (or (bibliography-entry-notes-of entry) "")
                                   :entry entry
                                   :field :notes
                                   :source-kind :entry-note))

(defun entry-venue-signals (entry)
  (extract-ngram-signals-from-text (or (bibliography-entry-venue-of entry) "")
                                   :entry entry
                                   :field :venue
                                   :source-kind :entry-venue))

(defun extract-candidate-topic-signals (subcollection)
  (append (collection-name-signals
           (bibliography-subcollection-collection-hit-of subcollection))
          (loop for entry in (bibliography-subcollection-entries-of subcollection)
                append (append (entry-tag-signals entry)
                               (entry-title-signals entry)
                               (entry-note-signals entry)
                               (entry-venue-signals entry)))))

(defun build-candidate-topic (signals)
  (let* ((title (choose-candidate-title signals))
         (aliases (remove-duplicates
                   (append (list title)
                           (mapcan #'candidate-topic-signal-aliases-of signals))
                   :test #'string-equal))
         (entries (remove-duplicates
                   (remove nil
                           (mapcar #'candidate-topic-signal-entry-of signals))
                   :test #'eq))
         (collection-signals
           (remove-if-not (lambda (signal)
                            (eq (candidate-topic-signal-source-kind-of signal)
                                :collection-name))
                          signals))
         (entry-signals
           (remove-if (lambda (signal)
                        (eq (candidate-topic-signal-source-kind-of signal)
                            :collection-name))
                      signals)))
    (make-instance 'candidate-topic
                   :title title
                   :normalized-key (candidate-topic-key title aliases)
                   :aliases aliases
                   :signals signals
                   :collection-signals collection-signals
                   :entry-signals entry-signals
                   :source-entries entries
                   :support-count (length entries)
                   :broader-hints (remove title
                                          (candidate-broader-hints title)
                                          :test #'string-equal)
                   :editorial-notes
                   (list (format nil "Collection-name evidence: ~D; entry-derived evidence: ~D."
                                 (length collection-signals)
                                 (length entry-signals))))))

(defun extract-candidate-topics (subcollection)
  (let ((groups (make-hash-table :test #'equal)))
    (dolist (signal (extract-candidate-topic-signals subcollection))
      (push signal
            (gethash (candidate-topic-signal-normalized-key-of signal) groups)))
    (sort (loop for signals in (hash-table-values groups)
                collect (build-candidate-topic (nreverse signals)))
          #'string<
          :key #'candidate-topic-title-of)))

(defun candidate-has-collection-only-evidence-p (candidate)
  (and (plusp (length (candidate-topic-collection-signals-of candidate)))
       (zerop (length (candidate-topic-entry-signals-of candidate)))))

(defun compare-candidate-topic (candidate)
  (let* ((exact (find-topic-by-title (candidate-topic-title-of candidate)))
         (alias-matches
           (unless exact
             (unique-topic-list
              (loop for alias in (remove (candidate-topic-title-of candidate)
                                         (candidate-topic-aliases-of candidate)
                                         :test #'string-equal)
                    collect (find-topic-by-title alias)))))
         (near-duplicate-matches
           (unless (or exact alias-matches)
             (remove-if-not
              (lambda (topic)
                (and (not (string= (title-of topic)
                                   (candidate-topic-title-of candidate)))
                     (string= (title-normalized-key-from-phrase
                               (title-of topic))
                              (candidate-topic-normalized-key-of candidate))))
              (all-current-topics))))
         (broader-topic-matches
           (unless (or exact alias-matches near-duplicate-matches)
             (unique-topic-list
              (loop for broader in (candidate-topic-broader-hints-of candidate)
                    collect (find-topic-by-title broader)))))
         (status (cond
                   (exact :exact-title-match)
                   (alias-matches :alias-match)
                   (near-duplicate-matches :near-duplicate-match)
                   (broader-topic-matches :broader-topic-review)
                   (t :new-topic))))
    (make-instance 'topic-comparison-report
                   :candidate-topic candidate
                   :exact-match exact
                   :alias-matches alias-matches
                   :near-duplicate-matches near-duplicate-matches
                   :broader-topic-matches broader-topic-matches
                   :status status
                   :review-notes
                   (list (case status
                           (:exact-title-match
                            "Exact title already exists in the Topics HyperBook.")
                           (:alias-match
                            "Exact title missing; an alias variant already exists as a topic title.")
                           (:near-duplicate-match
                            "Exact and alias matches failed; normalized title overlaps an existing topic title.")
                           (:broader-topic-review
                            "Candidate has broader-title hints that already exist as topic titles.")
                           (otherwise
                            "No exact, alias, near-duplicate, or broader-topic match was found in the current Topics model."))))))

(defun arrangement-only-candidate-p (candidate candidates)
  (and (zerop (length (candidate-topic-collection-signals-of candidate)))
       (let ((broader-candidates
               (remove nil
                       (loop for broader in (candidate-topic-broader-hints-of candidate)
                             collect (find broader candidates
                                           :key #'candidate-topic-title-of
                                           :test #'string-equal)))))
         (and broader-candidates
              (every (lambda (broader)
                       (>= (candidate-topic-support-count-of broader)
                           (candidate-topic-support-count-of candidate)))
                     broader-candidates)))))

(defun decision-target-topic (comparison)
  (or (and (topic-comparison-report-exact-match-of comparison)
           (title-of (topic-comparison-report-exact-match-of comparison)))
      (and (topic-comparison-report-alias-matches-of comparison)
           (title-of (first (topic-comparison-report-alias-matches-of comparison))))
      (and (topic-comparison-report-near-duplicate-matches-of comparison)
           (title-of (first (topic-comparison-report-near-duplicate-matches-of comparison))))
      (and (topic-comparison-report-broader-topic-matches-of comparison)
           (title-of (first (topic-comparison-report-broader-topic-matches-of comparison))))))

(defun decide-authoring (comparison all-candidates subcollection)
  (let* ((candidate (topic-comparison-report-candidate-topic-of comparison))
         (status (topic-comparison-report-status-of comparison))
         (target-topic-title (decision-target-topic comparison))
         (default-plan-page "Coachmark bibliography authoring plan"))
    (ecase status
      (:exact-title-match
       (make-authoring-decision
        candidate comparison subcollection
        :topic-action :merge-into-existing-topic-factory
        :page-action (if (hyperdoc-page-present-p target-topic-title)
                         :update-existing-page
                         :write-new-page)
        :target-topic-title target-topic-title
        :target-page-title target-topic-title
        :decision-notes
        (list "Exact-title match wins before any alias or broader-topic review.")))
      (:alias-match
       (make-authoring-decision
        candidate comparison subcollection
        :topic-action :merge-into-existing-topic-factory
        :page-action :update-existing-page
        :target-topic-title target-topic-title
        :target-page-title target-topic-title
        :decision-notes
        (list "Alias/near-title normalization absorbs this candidate into an existing canonical topic.")))
      (:near-duplicate-match
       (make-authoring-decision
        candidate comparison subcollection
        :topic-action :merge-into-existing-topic-factory
        :page-action :update-existing-page
        :target-topic-title target-topic-title
        :target-page-title target-topic-title
        :decision-notes
        (list "Normalized near-duplicate title suggests editing the existing topic factory instead of adding a parallel one.")))
      (:broader-topic-review
       (make-authoring-decision
        candidate comparison subcollection
        :topic-action :merge-into-broader-topic-factory
        :page-action :update-existing-page
        :target-topic-title target-topic-title
        :target-page-title target-topic-title
        :decision-notes
        (list "Broader-topic review wins only after exact and alias checks fail.")))
      (:new-topic
       (cond
         ((candidate-has-collection-only-evidence-p candidate)
          (make-authoring-decision
           candidate comparison subcollection
           :topic-action :leave-unmaterialized
           :page-action :continuity-shell-mention
           :target-topic-title nil
           :target-page-title default-plan-page
           :decision-notes
           (list "Only the source collection/subcollection name supports this candidate so far; keep it as editorial continuity-shell evidence instead of forcing a topic.")))
         ((arrangement-only-candidate-p candidate all-candidates)
          (let ((broader (or (find (first (candidate-topic-broader-hints-of candidate))
                                   all-candidates
                                   :key #'candidate-topic-title-of
                                   :test #'string-equal)
                             candidate)))
            (make-authoring-decision
             candidate comparison subcollection
             :topic-action :leave-arrangement-only
             :page-action :arrangement-only-mention
             :target-topic-title (candidate-topic-title-of broader)
             :target-page-title (candidate-topic-title-of broader)
             :decision-notes
             (list "Scoped variant stays in the arrangement/outline layer for now instead of becoming its own topic/page."))))
         (t
          (make-authoring-decision
           candidate comparison subcollection
           :topic-action :add-new-topic-factory
           :page-action :write-new-page
           :target-topic-title (candidate-topic-title-of candidate)
           :target-page-title (candidate-topic-title-of candidate)
           :decision-notes
           (list (format nil "New topic/page candidate supported by ~D bibliography entries from ~A collection ~A."
                         (candidate-topic-support-count-of candidate)
                         (string-downcase
                          (symbol-name
                           (bibliography-subcollection-source-system-of subcollection)))
                         (bibliography-collection-path-of
                          (bibliography-subcollection-collection-hit-of subcollection)))))))))))

(defun bibliography-topic-id-from-title (title)
  (let ((chars
          (loop for char across (string-downcase title)
                collect (if (or (alpha-char-p char)
                                (digit-char-p char))
                            char
                            #\-))))
    (string-trim "-" (coerce chars 'string))))

(defun bibliography-topic-function-name-from-title (title)
  (format nil "~A-topic" (bibliography-topic-id-from-title title)))

(defun bibliography-topic-factory-preview (decision)
  (let* ((title (authoring-decision-target-topic-title-of decision))
         (references '("Coachmark bibliography authoring plan"
                       "Bibliography subcollections in HyperDoc"))
         (summary
           (format nil "Proposed topic scaffold derived from bibliography evidence for ~A; tighten after editorial review."
                   title)))
    (format nil "(defun ~A ()~%  (make-topic~%   :id ~S~%   :title ~S~%   :summary ~S~%   :references '~S))~%"
            (bibliography-topic-function-name-from-title title)
            (bibliography-topic-id-from-title title)
            title
            summary
            references)))

(defun bibliography-page-fragment-preview (decision plan)
  (let* ((title (authoring-decision-target-page-title-of decision))
         (subcollection (hyperdoc-authoring-plan-source-subcollection-of plan))
         (collection-path
           (bibliography-collection-path-of
            (bibliography-subcollection-collection-hit-of subcollection))))
    (format nil "<h1>~A</h1>~%~%<in-package>hyperdoc</in-package>~%~%<p>~%  This page was scaffolded from the inspectable authoring plan for the bibliography subcollection <tt>~A</tt>. Replace this scaffold with durable HyperDoc prose after reviewing the supporting bibliography entries and candidate-topic comparison report.~%</p>~%~%<h2>Inspectable objects</h2>~%~%<ul>~%  <li><a hyperbook=\"topics\" page=\"~A\"><tt>~A</tt></a></li>~%  <li><a expr=\"(coachmark-bibliography-authoring-plan)\"><tt>(coachmark-bibliography-authoring-plan)</tt></a></li>~%</ul>~%"
            title
            collection-path
            title
            title)))

(defun bibliography-page-update-preview (decision plan)
  (let* ((candidate (authoring-decision-candidate-topic-of decision))
         (subcollection (hyperdoc-authoring-plan-source-subcollection-of plan)))
    (with-output-to-string (stream)
      (format stream "Target page: ~A~%~%"
              (or (authoring-decision-target-page-title-of decision)
                  "(editorial review)"))
      (format stream "Candidate topic: ~A~%~%"
              (candidate-topic-title-of candidate))
      (format stream "Collection-path evidence: ~{~A~^, ~}~%"
              (mapcar #'candidate-topic-signal-display-title-of
                      (candidate-topic-collection-signals-of candidate)))
      (format stream "Entry-derived evidence: ~{~A~^, ~}~%"
              (mapcar #'candidate-topic-signal-display-title-of
                      (candidate-topic-entry-signals-of candidate)))
      (format stream "Supporting entries from ~A collection ~A:~%  ~{~A~^~%  ~}~%"
              (string-downcase
               (symbol-name
                (bibliography-subcollection-source-system-of subcollection)))
              (bibliography-collection-path-of
               (bibliography-subcollection-collection-hit-of subcollection))
              (mapcar #'bibliography-entry-title-of
                      (candidate-topic-source-entries-of candidate)))
      (dolist (note (authoring-decision-notes-of decision))
        (format stream "~%Note: ~A~%" note)))))

(defun bibliography-page-update-target-title (decision)
  (or (authoring-decision-target-page-title-of decision)
      (candidate-topic-title-of
       (authoring-decision-candidate-topic-of decision))))

(defun merge-decision-into-update-note-groups (groups decision)
  (let* ((target-title (bibliography-page-update-target-title decision))
         (group (assoc target-title groups :test #'string-equal)))
    (if group
        (push decision (cdr group))
        (push (cons target-title (list decision)) groups))
    groups))

(defun bibliography-page-update-bundle-preview (target-title decisions plan)
  (with-output-to-string (stream)
    (format stream "Target page: ~A~%~%" target-title)
    (dolist (decision (sort (copy-list decisions)
                            #'string<
                            :key (lambda (entry)
                                   (candidate-topic-title-of
                                    (authoring-decision-candidate-topic-of entry)))))
      (format stream "=== Candidate: ~A ===~%~%"
              (candidate-topic-title-of
               (authoring-decision-candidate-topic-of decision)))
      (write-string (bibliography-page-update-preview decision plan) stream)
      (terpri stream)
      (terpri stream))))

(defun bibliography-plan-summary-preview (plan)
  (with-output-to-string (stream)
    (format stream "Bibliography authoring plan for ~A collection ~A~%~%"
            (string-downcase
             (symbol-name
              (bibliography-subcollection-source-system-of
               (hyperdoc-authoring-plan-source-subcollection-of plan))))
            (bibliography-collection-path-of
             (bibliography-subcollection-collection-hit-of
              (hyperdoc-authoring-plan-source-subcollection-of plan))))
    (dolist (decision (hyperdoc-authoring-plan-authoring-decisions-of plan))
      (format stream "- ~A (~A): topic ~A, page ~A"
              (candidate-topic-title-of (authoring-decision-candidate-topic-of decision))
              (string-downcase
               (symbol-name (authoring-decision-kind-of decision)))
              (string-downcase
               (symbol-name (authoring-decision-topic-action-of decision)))
              (string-downcase
               (symbol-name (authoring-decision-page-action-of decision))))
      (when-let (target (authoring-decision-target-page-title-of decision))
        (format stream " -> ~A" target))
      (when (authoring-decision-materialization-consequence-of decision)
        (format stream " [~{~A~^, ~}]"
                (mapcar (lambda (keyword)
                          (string-downcase (symbol-name keyword)))
                        (authoring-decision-materialization-consequence-of
                         decision))))
      (terpri stream))))

(defun make-bibliography-materialization-entry (kind target-path preview-text &key decision)
  (make-instance 'bibliography-materialization-entry
                 :kind kind
                 :action :write
                 :target-path target-path
                 :preview-text preview-text
                 :decision decision
                 :repo-touch-preview
                 (and decision
                      (authoring-decision-repo-touch-preview-of decision))
                 :existing-p (uiop:file-exists-p target-path)))

(defun bibliography-materialization-entries (plan)
  (let* ((root (uiop:ensure-directory-pathname
                (hyperdoc-authoring-plan-output-root-of plan)))
         (page-update-groups '())
         (entries
           (list (make-bibliography-materialization-entry
                  :plan-summary
                  (merge-pathnames (bibliography-summary-path) root)
                  (bibliography-plan-summary-preview plan)))))
    (dolist (decision (hyperdoc-authoring-plan-authoring-decisions-of plan))
      (case (authoring-decision-topic-action-of decision)
        (:add-new-topic-factory
         (push (make-bibliography-materialization-entry
                :topic-factory-snippet
                (merge-pathnames
                 (bibliography-topic-snippet-filename
                  (authoring-decision-target-topic-title-of decision))
                 root)
                (bibliography-topic-factory-preview decision)
                :decision decision)
               entries)))
      (case (authoring-decision-page-action-of decision)
        (:write-new-page
         (push (make-bibliography-materialization-entry
                :page-fragment
                (merge-pathnames
                 (bibliography-page-filename
                  (authoring-decision-target-page-title-of decision))
                 root)
                (bibliography-page-fragment-preview decision plan)
                :decision decision)
               entries))
        ((:update-existing-page :arrangement-only-mention :continuity-shell-mention)
         (setf page-update-groups
               (merge-decision-into-update-note-groups
                page-update-groups
                decision)))))
    (dolist (group (sort (copy-list page-update-groups) #'string<
                         :key #'car))
      (destructuring-bind (target-title . decisions) group
        (push (make-bibliography-materialization-entry
               :page-update-note
               (merge-pathnames
                (bibliography-update-note-filename target-title)
                root)
               (bibliography-page-update-bundle-preview target-title decisions plan))
              entries)))
    (nreverse entries)))

(defun build-hyperdoc-authoring-plan (subcollection &key output-root)
  (let* ((candidates (ensure-bibliography-subcollection-candidate-topics
                      subcollection))
         (comparisons (mapcar #'compare-candidate-topic candidates))
         (decisions (mapcar (lambda (comparison)
                              (decide-authoring comparison candidates subcollection))
                            comparisons))
         (plan (make-instance 'hyperdoc-authoring-plan
                              :source-subcollection subcollection
                              :candidate-topics candidates
                              :comparison-reports comparisons
                              :authoring-decisions decisions
                              :output-root (or output-root
                                               (bibliography-output-root-for-subcollection
                                                subcollection))
                              :editorial-notes
                              (list "Collection/subcollection provenance remains distinct from editorial topic inference."
                                    "Materialization writes a separate review bundle; it does not patch hyperdoc/topics.lisp or authored pages directly."))))
    (setf (slot-value plan 'materialization-entries)
          (bibliography-materialization-entries plan))
    plan))

(defun plan-bibliography-authoring
    (subcollection-or-name &key (source (make-default-bibliography-source))
       signal-error? output-root)
  (let ((subcollection
          (typecase subcollection-or-name
            (zotero-backend-unavailable subcollection-or-name)
            (string
             (cond
               ((zotero-backend-unavailable-p source)
                source)
               (t
                (load-bibliography-subcollection-using-source
                 source
                 subcollection-or-name
                 :signal-error? signal-error?
                 :output-root output-root))))
            (bibliography-subcollection
             subcollection-or-name)
            (otherwise
             (error "Unsupported bibliography authoring target ~S." subcollection-or-name)))))
    (if (zotero-backend-unavailable-p subcollection)
        subcollection
        (and subcollection
             (ensure-bibliography-subcollection-authoring-plan
              subcollection
              :output-root output-root)))))

(defun plan-materialization-write! (entry)
  (let ((path (bibliography-materialization-entry-target-path-of entry)))
    (when (uiop:file-exists-p path)
      (error "Refusing to overwrite existing bibliography materialization output ~A" path))
    (ensure-directories-exist path)
    (with-open-file (stream path
                            :direction :output
                            :external-format :utf-8
                            :if-exists :error
                            :if-does-not-exist :create)
      (write-string (bibliography-materialization-entry-preview-text-of entry)
                    stream))
    path))

(defun materialize-bibliography-authoring-plan (plan)
  (let ((report '()))
    (dolist (entry (hyperdoc-authoring-plan-materialization-entries-of plan))
      (push (list :kind (bibliography-materialization-entry-kind-of entry)
                  :target-path (plan-materialization-write! entry))
            report))
    (setf (hyperdoc-authoring-plan-execution-report-of plan)
          (nreverse report))
    plan))

(defmethod hb:find-page ((book bibliography-subcollections-hyperbook) page-id
                         &key signal-error?)
  (let ((source (bibliography-hyperbook-source-of book))
        (cache (bibliography-hyperbook-pages-of book))
        (lookup (or page-id (hb:main-page-id-of book))))
    (or (gethash lookup cache)
        (let ((subcollection
                (load-bibliography-subcollection-using-source
                 source
                 lookup
                 :signal-error? signal-error?)))
          (cond
            ((zotero-backend-unavailable-p subcollection)
             subcollection)
            (subcollection
            (setf (gethash lookup cache) subcollection)
            (let ((path (bibliography-collection-path-of
                         (bibliography-subcollection-collection-hit-of
                          subcollection))))
              (setf (gethash path cache) subcollection
                    (gethash (bibliography-collection-name-of
                              (bibliography-subcollection-collection-hit-of
                               subcollection))
                             cache)
                    subcollection))
             subcollection)
            (t nil))))))

(defun coachmark-bibliography-subcollection (&key (source (make-default-bibliography-source))
                                               signal-error?
                                               output-root)
  (if (zotero-backend-unavailable-p source)
      source
      (load-bibliography-subcollection-using-source
       source
       "coachmark"
       :signal-error? signal-error?
       :output-root output-root)))

(defun coachmark-bibliography-authoring-plan (&key (source (make-default-bibliography-source))
                                                signal-error?
                                                output-root)
  (plan-bibliography-authoring
   "coachmark"
   :source source
   :signal-error? signal-error?
   :output-root output-root))
