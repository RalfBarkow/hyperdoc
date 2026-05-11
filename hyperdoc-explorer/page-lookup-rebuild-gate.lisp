;;;; Page-lookup rebuild gate
;;
;; Inspectable report object for the running-image coherence rebuild workflow.
;; This file lives in hyperdoc/explorer because it depends on loaded page
;; objects, exact HyperBook lookup, and render-time lookup-issue discovery.

(in-package :hyperdoc)

(defclass page-lookup-rebuild-issue-record ()
  ((page
    :initarg :page
    :reader page-lookup-rebuild-record-page-of)
   (page-title
    :initarg :page-title
    :reader page-lookup-rebuild-record-page-title-of)
   (page-id
    :initarg :page-id
    :reader page-lookup-rebuild-record-page-id-of)
   (issue
    :initarg :issue
    :reader page-lookup-rebuild-record-issue-of)))

(defclass page-lookup-rebuild-report ()
  ((hyperdoc
    :initarg :hyperdoc
    :reader page-lookup-rebuild-report-hyperdoc-of)
   (created-at
    :initarg :created-at
    :reader page-lookup-rebuild-report-created-at-of)
   (reloaded-p
    :initarg :reloaded-p
    :reader page-lookup-rebuild-report-reloaded-p-of)
   (pages-scanned-count
    :initarg :pages-scanned-count
    :reader page-lookup-rebuild-report-pages-scanned-count-of)
   (issue-records
    :initarg :issue-records
    :initform nil
    :reader page-lookup-rebuild-report-issue-records-of)
   (status
    :initarg :status
    :reader page-lookup-rebuild-report-status-of)))

(defun page-lookup-rebuild-safe-page-title (page)
  (handler-case
      (hyperbook:title-of page)
    (condition ()
      "<unavailable title>")))

(defun page-lookup-rebuild-safe-page-id (page)
  (handler-case
      (hyperbook:id-of page)
    (condition ()
      "<unavailable id>")))

(defun make-page-lookup-rebuild-issue-record (page issue)
  (make-instance 'page-lookup-rebuild-issue-record
                 :page page
                 :page-title (page-lookup-rebuild-safe-page-title page)
                 :page-id (page-lookup-rebuild-safe-page-id page)
                 :issue issue))

(defun page-lookup-rebuild-pages (hdoc)
  (ensure-pages-loaded hdoc)
  (loop for page being the hash-values of (pages-of hdoc)
        collect page))

(defun page-lookup-rebuild-issues-for-page (page)
  (handler-case
      (hyperbook:lookup-issues-of page)
    (condition (condition)
      (list condition))))

(defun page-lookup-rebuild-issue-records
    (&key
       (hyperdoc *hyperdoc*)
       (reload t))
  (when reload
    (reload-text-pages hyperdoc))
  (loop for page in (page-lookup-rebuild-pages hyperdoc)
        append
        (mapcar (lambda (issue)
                  (make-page-lookup-rebuild-issue-record page issue))
                (page-lookup-rebuild-issues-for-page page))))

(defun make-page-lookup-rebuild-report
    (&key
       (hyperdoc *hyperdoc*)
       (reload t))
  (let* ((records (page-lookup-rebuild-issue-records
                   :hyperdoc hyperdoc
                   :reload reload))
         (pages (page-lookup-rebuild-pages hyperdoc)))
    (make-instance 'page-lookup-rebuild-report
                   :hyperdoc hyperdoc
                   :created-at (get-universal-time)
                   :reloaded-p reload
                   :pages-scanned-count (length pages)
                   :issue-records records
                   :status (if records :issues :clean))))

(defun page-lookup-rebuild-report-issue-count (report)
  (length (page-lookup-rebuild-report-issue-records-of report)))

(defun page-lookup-rebuild-report-clean-p (report)
  (eq :clean (page-lookup-rebuild-report-status-of report)))

(defun assert-no-page-lookup-issues-after-rebuild
    (&key
       (hyperdoc *hyperdoc*)
       (reload t))
  (let ((report (make-page-lookup-rebuild-report
                 :hyperdoc hyperdoc
                 :reload reload)))
    (unless (page-lookup-rebuild-report-clean-p report)
      (error "Page-lookup rebuild gate failed with ~D issue(s)."
             (page-lookup-rebuild-report-issue-count report)))
    report))

(defmethod print-object ((report page-lookup-rebuild-report) stream)
  (print-unreadable-object (report stream :type t :identity t)
    (format stream "~A ~D page(s), ~D issue(s)"
            (page-lookup-rebuild-report-status-of report)
            (page-lookup-rebuild-report-pages-scanned-count-of report)
            (page-lookup-rebuild-report-issue-count report))))

(defmethod views:text-representation ((report page-lookup-rebuild-report))
  (format nil "Page lookup rebuild gate: ~A, ~D issue~:P"
          (string-downcase
           (symbol-name (page-lookup-rebuild-report-status-of report)))
          (page-lookup-rebuild-report-issue-count report)))

(defmethod views:text-representation ((record page-lookup-rebuild-issue-record))
  (format nil "~A: ~A"
          (page-lookup-rebuild-record-page-title-of record)
          (page-lookup-rebuild-record-issue-of record)))

(views:defview 👀overview
    (report page-lookup-rebuild-report)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:h3 (views:esc "Page-lookup rebuild gate"))
      (:table :class "inspector-table"
              (:tr
               (:td (views:esc "Status"))
               (:td (:tt (views:esc
                          (string-downcase
                           (symbol-name
                            (page-lookup-rebuild-report-status-of report)))))))
              (:tr
               (:td (views:esc "Pages scanned"))
               (:td (:tt (views:esc
                          (format nil "~D"
                                  (page-lookup-rebuild-report-pages-scanned-count-of report))))))
              (:tr
               (:td (views:esc "Issues"))
               (:td (:tt (views:esc
                          (format nil "~D"
                                  (page-lookup-rebuild-report-issue-count report))))))
              (:tr
               (:td (views:esc "Reloaded before scan"))
               (:td (:tt (views:esc
                          (if (page-lookup-rebuild-report-reloaded-p-of report)
                              "yes"
                              "no"))))))
      (:p
       (views:esc
        "Exact HyperBook lookup remains authoritative. This report does not rewrite links; it exposes lookup issues after a rebuild so they can be repaired as authored changes.")))))

(views:defview 👀issues
    (report page-lookup-rebuild-report)
  (views:html-view :title "Issues" :priority 2
    (let ((records (page-lookup-rebuild-report-issue-records-of report)))
      (views:html
        (if records
            (views:html
              (:table :class "inspector-table"
                      (:tr
                       (:th (views:esc "Page"))
                       (:th (views:esc "Page id"))
                       (:th (views:esc "Issue")))
                      (dolist (record records)
                        (views:html
                          (:tr
                           (:td
                            (views:object-ref
                             (page-lookup-rebuild-record-page-of record)
                             :display (page-lookup-rebuild-record-page-title-of record)))
                           (:td (:tt (views:esc
                                      (page-lookup-rebuild-record-page-id-of record))))
                           (:td
                            (views:object-ref
                             (page-lookup-rebuild-record-issue-of record)
                             :display (princ-to-string
                                       (page-lookup-rebuild-record-issue-of record)))))))))
            (views:html
              (:p (views:esc "No page-lookup issues found after rebuild."))))))))

(views:defview 👀pages
    (report page-lookup-rebuild-report)
  (views:html-view :title "Scanned pages" :priority 3
    (views:list-view
     (page-lookup-rebuild-pages
      (page-lookup-rebuild-report-hyperdoc-of report))
     :title "Scanned pages")))
