;;;; Inspector views for the source-station-backed LISP-CRITIC contract.

(in-package :hyperdoc/inspector)

(defun lisp-critic-contract-view-string (value)
  (cond
    ((null value) "none")
    ((typep value 'hyperdoc::lisp-critic-source-station)
     (hyperdoc::title-of value))
    ((typep value 'hyperdoc::lisp-critic-contract)
     (hyperdoc::title-of value))
    ((keywordp value)
     (string-downcase (symbol-name value)))
    ((symbolp value)
     (string-downcase (symbol-name value)))
    ((pathnamep value)
     (namestring value))
    ((stringp value)
     value)
    ((consp value)
     (format nil "~{~A~^, ~}"
             (mapcar #'lisp-critic-contract-view-string value)))
    (t
     (format nil "~A" value))))

(defun lisp-critic-contract-row (label value)
  (html-inspector-views:html
    (:tr
     (:th :scope "row" (html-inspector-views:esc label))
     (:td (html-inspector-views:esc
           (lisp-critic-contract-view-string value))))))

(defun lisp-critic-contract-bullets (values)
  (html-inspector-views:html
    (:ul
     (if values
         (dolist (value values)
           (html-inspector-views:html
             (:li (html-inspector-views:esc
                   (lisp-critic-contract-view-string value)))))
         (html-inspector-views:html
           (:li (html-inspector-views:esc "none")))))))

(defmethod html-inspector-views:text-representation
    ((source-station hyperdoc::lisp-critic-source-station))
  (hyperdoc::title-of source-station))

(defmethod html-inspector-views:text-representation
    ((contract hyperdoc::lisp-critic-contract))
  (hyperdoc::title-of contract))

(defmethod html-inspector-views:text-representation
    ((record hyperdoc::lisp-critic-run-record))
  (hyperdoc::title-of record))

(html-inspector-views:defview 👀summary
    (source-station hyperdoc::lisp-critic-source-station)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc
            (hyperdoc::title-of source-station)))
      (:p
       (html-inspector-views:esc
        "This source station represents the local FedWiki LISP-CRITIC asset. It is data, not vendored source."))
      (:table :class "inspector-table"
              (lisp-critic-contract-row
               "Id"
               (hyperdoc::lisp-critic-source-station-id-of source-station))
              (lisp-critic-contract-row
               "Site"
               (hyperdoc::lisp-critic-source-station-site-of source-station))
              (lisp-critic-contract-row
               "Page"
               (hyperdoc::lisp-critic-source-station-page-of source-station))
              (lisp-critic-contract-row
               "Asset root"
               (hyperdoc::lisp-critic-source-station-asset-root-of
                source-station))
              (lisp-critic-contract-row
               "Present locally"
               (if (hyperdoc::lisp-critic-source-station-present-p
                    source-station)
                   "yes"
                   "no"))
              (lisp-critic-contract-row
               "Wrapper system"
               (hyperdoc::lisp-critic-source-station-wrapper-system-of
                source-station))
              (lisp-critic-contract-row
               "Wrapper loader"
               (hyperdoc::lisp-critic-source-station-wrapper-loader-symbol-of
                source-station))
              (lisp-critic-contract-row
               "Wrapper entrypoint"
               (hyperdoc::lisp-critic-source-station-wrapper-entrypoint-symbol-of
                source-station))
              (lisp-critic-contract-row
               "Upstream system"
               (hyperdoc::lisp-critic-source-station-upstream-system-of
                source-station))
              (lisp-critic-contract-row
               "Upstream file entrypoint"
               (hyperdoc::lisp-critic-source-station-upstream-file-entrypoint-symbol-of
                source-station)))
      (:h3 (html-inspector-views:esc "Provenance"))
      (lisp-critic-contract-bullets
       (hyperdoc::lisp-critic-source-station-provenance-of
        source-station)))))

(html-inspector-views:defview 👀summary
    (contract hyperdoc::lisp-critic-contract)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc
            (hyperdoc::title-of contract)))
      (:table :class "inspector-table"
              (lisp-critic-contract-row
               "Id"
               (hyperdoc::lisp-critic-contract-id-of contract))
              (lisp-critic-contract-row
               "Source station"
               (hyperdoc::title-of
                (hyperdoc::lisp-critic-contract-source-station-of
                 contract)))
              (lisp-critic-contract-row
               "Available now"
               (if (hyperdoc::lisp-critic-contract-available-p contract)
                   "yes"
                   "no"))
              (lisp-critic-contract-row
               "Review contract role"
               (hyperdoc::lisp-critic-contract-review-contract-role-of
                contract)))
      (:h3 (html-inspector-views:esc "Input policy"))
      (lisp-critic-contract-bullets
       (hyperdoc::lisp-critic-contract-input-policy-of contract))
      (:h3 (html-inspector-views:esc "Invocation policy"))
      (lisp-critic-contract-bullets
       (hyperdoc::lisp-critic-contract-invocation-policy-of contract))
      (:h3 (html-inspector-views:esc "Output policy"))
      (lisp-critic-contract-bullets
       (hyperdoc::lisp-critic-contract-output-policy-of contract))
      (:h3 (html-inspector-views:esc "Availability policy"))
      (lisp-critic-contract-bullets
       (hyperdoc::lisp-critic-contract-availability-policy-of contract))
      (:h3 (html-inspector-views:esc "Failure policy"))
      (lisp-critic-contract-bullets
       (hyperdoc::lisp-critic-contract-failure-policy-of contract)))))

(html-inspector-views:defview 👀summary
    (record hyperdoc::lisp-critic-run-record)
  (html-inspector-views:html-view :title "Summary" :priority 1
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc
            (hyperdoc::title-of record)))
      (:table :class "inspector-table"
              (lisp-critic-contract-row
               "Status"
               (hyperdoc::lisp-critic-run-record-status record))
              (lisp-critic-contract-row
               "Contract"
               (hyperdoc::title-of
                (hyperdoc::lisp-critic-run-record-contract-of record)))
              (lisp-critic-contract-row
               "Source station"
               (hyperdoc::title-of
                (hyperdoc::lisp-critic-contract-source-station-of
                 (hyperdoc::lisp-critic-run-record-contract-of record))))
              (lisp-critic-contract-row
               "Reviewed paths"
               (hyperdoc::lisp-critic-run-record-target-paths record))
              (lisp-critic-contract-row
               "Invocation boundary"
               (hyperdoc::lisp-critic-run-record-invocation-form-of record))
              (lisp-critic-contract-row
               "Started at"
               (hyperdoc::lisp-critic-run-record-started-at-of record))
              (lisp-critic-contract-row
               "Finished at"
               (hyperdoc::lisp-critic-run-record-finished-at-of record))
              (lisp-critic-contract-row
               "Notes"
               (hyperdoc::lisp-critic-run-record-notes-of record))))))

(html-inspector-views:defview 👀raw-output
    (record hyperdoc::lisp-critic-run-record)
  (html-inspector-views:html-view :title "Raw output" :priority 2
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc "Raw LISP-CRITIC output"))
      (:p
       (html-inspector-views:esc
        "This is raw critic evidence. It has not been normalized into findings."))
      (:pre
       (html-inspector-views:esc
        (hyperdoc::lisp-critic-run-record-raw-output record))))))

(html-inspector-views:defview 👀failure-condition
    (record hyperdoc::lisp-critic-run-record)
  (html-inspector-views:html-view :title "Failure / condition" :priority 3
    (html-inspector-views:html
      (:h2 (html-inspector-views:esc "Failure / condition"))
      (:table :class "inspector-table"
              (lisp-critic-contract-row
               "Status"
               (hyperdoc::lisp-critic-run-record-status record))
              (lisp-critic-contract-row
               "Condition summary"
               (hyperdoc::lisp-critic-run-record-condition-summary-of
                record))
              (lisp-critic-contract-row
               "Error output"
               (hyperdoc::lisp-critic-run-record-error-output-of record)))
      (:p
       (html-inspector-views:esc
        "Missing assets, load failures, unavailable critic APIs, and invocation failures are recorded here instead of being hidden or converted into success.")))))
