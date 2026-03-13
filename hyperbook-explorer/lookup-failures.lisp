;;;; Structured lookup issues for failed HyperBook links
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(defclass lookup-issue ()
  ((source-object :reader lookup-issue-source-object-of
                  :initarg :source-object
                  :initform nil)
   (source-hyperbook :reader source-hyperbook-of
                     :initarg :source-hyperbook
                     :type (or null string))
   (source-page-id :reader lookup-issue-source-page-id-of
                   :initarg :source-page-id
                   :type (or null string))
   (source-page-title :reader lookup-issue-source-page-title-of
                      :initarg :source-page-title
                      :type (or null string))
   (source-section :reader lookup-issue-source-section-of
                   :initarg :source-section
                   :initform nil
                   :type (or null string))
   (link-text :reader lookup-issue-link-text-of
              :initarg :link-text
              :initform nil
              :type (or null string))
   (target-hyperbook-id :reader lookup-issue-target-hyperbook-id-of
                        :initarg :target-hyperbook-id
                        :initform nil
                        :type (or null string))
   (target-site :reader lookup-issue-target-site-of
                :initarg :target-site
                :initform nil
                :type (or null string))
   (expected-page-id :reader lookup-issue-expected-page-id-of
                     :initarg :expected-page-id
                     :initform nil
                     :type (or null string))
   (target-kind :accessor lookup-issue-target-kind-of
                :initarg :target-kind
                :initform :unknown)
   (classification :accessor lookup-issue-classification-of
                   :initarg :classification
                   :initform :unknown)
   (default-status :accessor lookup-issue-default-status-of
                   :initarg :status
                   :initform :open)
   (suggested-repair :accessor lookup-issue-suggested-repair-of
                     :initarg :suggested-repair
                     :initform nil)
   (repair-description :accessor lookup-issue-repair-description-of
                       :initarg :repair-description
                       :initform nil
                       :type (or null string))
   (repair-thunk :accessor lookup-issue-repair-thunk-of
                 :initarg :repair-thunk
                 :initform nil
                 :type (or null function))
   (details :accessor lookup-issue-details-of
            :initarg :details
            :initform nil)
   (underlying-condition :reader lookup-issue-underlying-condition-of
                         :initarg :underlying-condition
                         :initform nil)
   (link :reader lookup-issue-link-of
         :initarg :link
         :initform nil)))

(defclass page-lookup-issue (lookup-issue) ())

(defclass target-grouping-issue (lookup-issue) ())

(defparameter *lookup-issue-status-overrides* (make-hash-table :test #'equal))

(defun lookup-issue-target-site (target-hyperbook-id)
  (cond
    ((null target-hyperbook-id)
     nil)
    ((uiop:string-prefix-p "fedwiki:" target-hyperbook-id)
     (subseq target-hyperbook-id (length "fedwiki:")))
    (t
     target-hyperbook-id)))

(defun make-page-lookup-issue
    (condition
     &key source-object source-hyperbook source-page-id source-page-title
       source-section link-text target-hyperbook-id expected-page-id link
       (target-kind :unknown)
       (classification :unknown)
       (status :open)
       suggested-repair
       repair-description
       repair-thunk
       details)
  (make-instance 'page-lookup-issue
                 :source-object source-object
                 :source-hyperbook source-hyperbook
                 :source-page-id source-page-id
                 :source-page-title source-page-title
                 :source-section source-section
                 :link-text link-text
                 :target-hyperbook-id target-hyperbook-id
                 :target-site (lookup-issue-target-site target-hyperbook-id)
                 :expected-page-id expected-page-id
                 :target-kind target-kind
                 :classification classification
                 :status status
                 :suggested-repair suggested-repair
                 :repair-description repair-description
                 :repair-thunk repair-thunk
                 :details details
                 :underlying-condition condition
                 :link link))

(defun make-target-grouping-issue
    (&key source-object source-hyperbook source-page-id source-page-title
       source-section link-text target-hyperbook-id expected-page-id
       (target-kind :unknown)
       (classification :mislabelled-target-grouping)
       (status :open)
       suggested-repair
       repair-description
       repair-thunk
       details)
  (make-instance 'target-grouping-issue
                 :source-object source-object
                 :source-hyperbook source-hyperbook
                 :source-page-id source-page-id
                 :source-page-title source-page-title
                 :source-section source-section
                 :link-text link-text
                 :target-hyperbook-id target-hyperbook-id
                 :target-site (lookup-issue-target-site target-hyperbook-id)
                 :expected-page-id expected-page-id
                 :target-kind target-kind
                 :classification classification
                 :status status
                 :suggested-repair suggested-repair
                 :repair-description repair-description
                 :repair-thunk repair-thunk
                 :details details))

(defun lookup-issue-signature (issue)
  (list (class-name (class-of issue))
        (source-hyperbook-of issue)
        (lookup-issue-source-page-id-of issue)
        (lookup-issue-source-section-of issue)
        (lookup-issue-target-hyperbook-id-of issue)
        (lookup-issue-expected-page-id-of issue)
        (lookup-issue-classification-of issue)))

(defun lookup-issue-status-of (issue)
  (or (gethash (lookup-issue-signature issue)
               *lookup-issue-status-overrides*)
      (lookup-issue-default-status-of issue)))

(defun mark-lookup-issue! (issue status)
  (setf (gethash (lookup-issue-signature issue)
                 *lookup-issue-status-overrides*)
        status)
  issue)

(defgeneric enrich-lookup-issue (issue)
  (:method ((issue lookup-issue))
    issue))

(defgeneric lookup-issues-of (page)
  (:method ((page page))
    nil))

(defun make-basic-page-lookup-issue (condition link &optional source-page)
  (make-page-lookup-issue
   condition
   :source-object source-page
   :source-hyperbook (or (and link (source-hyperbook-of link))
                         (and source-page (-> source-page hyperbook-of id-of)))
   :source-page-id (or (and link (source-page-of link))
                       (and source-page (id-of source-page)))
   :source-page-title (or (and source-page (ignore-errors (title-of source-page)))
                          (and link (source-page-of link))
                          "Unknown page")
   :source-section (and link (source-section-of link))
   :link-text (and link (link-text-of link))
   :target-hyperbook-id (and link (ignore-errors (target-hyperbook-of link)))
   :expected-page-id (and link (ignore-errors (target-page-of link)))
   :link link
   :target-kind :unknown
   :classification :lookup-failure
   :details (list :condition-type (type-of condition))))

(defun make-basic-hyperbook-lookup-issue (condition &optional source-page)
  (make-instance 'lookup-issue
                 :source-object source-page
                 :source-hyperbook (and source-page (-> source-page hyperbook-of id-of))
                 :source-page-id (and source-page (id-of source-page))
                 :source-page-title (or (and source-page (ignore-errors (title-of source-page)))
                                        "Unknown page")
                 :target-hyperbook-id (and (slot-boundp condition 'hyperbook-id)
                                           (slot-value condition 'hyperbook-id))
                 :target-site nil
                 :target-kind :unknown
                 :classification :lookup-path-failure
                 :details (list :condition-type (type-of condition))
                 :underlying-condition condition))

(defun make-render-time-lookup-issue
    (condition &key source-page target-hyperbook-id expected-page-id
                 link-text source-section)
  (enrich-lookup-issue
   (make-page-lookup-issue
    condition
    :source-object source-page
    :source-hyperbook (and source-page (-> source-page hyperbook-of id-of))
    :source-page-id (and source-page (id-of source-page))
    :source-page-title (or (and source-page (ignore-errors (title-of source-page)))
                           "Unknown page")
    :source-section source-section
    :link-text link-text
    :target-hyperbook-id target-hyperbook-id
    :expected-page-id expected-page-id
    :target-kind :unknown
    :classification :lookup-failure
    :details (list :condition-type (type-of condition)))))

(defun issue-label (symbol)
  (string-downcase
   (substitute #\Space #\- (symbol-name symbol))))

(defun lookup-issue-summary (issue)
  (format nil "~A: ~A/~A → ~A/~A"
          (issue-label (lookup-issue-classification-of issue))
          (lookup-issue-source-page-title-of issue)
          (or (lookup-issue-source-section-of issue) "root")
          (or (lookup-issue-target-hyperbook-id-of issue) "unknown")
          (or (lookup-issue-expected-page-id-of issue) "unknown")))

(defmethod views:text-representation ((issue lookup-issue))
  (lookup-issue-summary issue))

(defmethod views:html-representation ((issue lookup-issue) &optional id)
  (views:html
    (:span :id id :class "inspector-error"
           (:tt (views:esc (issue-label
                            (lookup-issue-classification-of issue))))
           (views:esc ": ")
           (views:esc (or (lookup-issue-link-text-of issue)
                          (lookup-issue-expected-page-id-of issue)
                          "lookup issue")))))

(defun render-lookup-issue-status-button (issue label status)
  (views:action-button
   label
   (views:thunk
     (mark-lookup-issue! issue status)
     issue)
   (format nil "Mark this lookup issue as ~A."
           (issue-label status))))

(defmethod views:title-bar-action-buttons ((issue lookup-issue))
  (views:html
    (render-lookup-issue-status-button issue "Open" :open)
    " "
    (render-lookup-issue-status-button issue "Publication" :publication-boundary)
    " "
    (render-lookup-issue-status-button issue "Needs materialization"
                                       :needs-local-materialization)
    " "
    (render-lookup-issue-status-button issue "Needs topic"
                                       :needs-topic-creation)
    " "
    (render-lookup-issue-status-button issue "Fixed" :fixed)))

(views:defview 👀overview (issue lookup-issue)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Source page"))
                   (:td (views:esc (lookup-issue-source-page-title-of issue))))
              (:tr (:td (views:esc "Source HyperBook"))
                   (:td (views:esc (source-hyperbook-of issue))))
              (:tr (:td (views:esc "Source section"))
                   (:td (views:esc (or (lookup-issue-source-section-of issue)
                                       ""))))
              (:tr (:td (views:esc "Link text"))
                   (:td (views:esc (or (lookup-issue-link-text-of issue) ""))))
              (:tr (:td (views:esc "Expected page id / slug"))
                   (:td (:tt (views:esc
                              (or (lookup-issue-expected-page-id-of issue)
                                  "")))))
              (:tr (:td (views:esc "Target HyperBook"))
                   (:td (:tt (views:esc
                              (or (lookup-issue-target-hyperbook-id-of issue)
                                  "")))))
              (:tr (:td (views:esc "Target site"))
                   (:td (views:esc (or (lookup-issue-target-site-of issue) ""))))
              (:tr (:td (views:esc "Target kind"))
                   (:td (:tt (views:esc
                              (issue-label
                               (lookup-issue-target-kind-of issue))))))
              (:tr (:td (views:esc "Failure classification"))
                   (:td (:tt (views:esc
                              (issue-label
                               (lookup-issue-classification-of issue))))))
              (:tr (:td (views:esc "Current status"))
                   (:td (:tt (views:esc
                              (issue-label (lookup-issue-status-of issue))))))
              (:tr (:td (views:esc "Suggested repair"))
                   (:td (:tt (views:esc
                              (or (and (lookup-issue-suggested-repair-of issue)
                                       (issue-label
                                        (lookup-issue-suggested-repair-of issue)))
                                  "")))))
              (:tr (:td (views:esc "Repair description"))
                   (:td (views:esc (or (lookup-issue-repair-description-of issue)
                                       ""))))))))

(views:defview 👀details (issue lookup-issue)
  (views:html-view :title "Details" :priority 2
    (let ((details (lookup-issue-details-of issue)))
      (if details
          (views:html
            (:table :class "inspector-table"
                    (loop for (key value) on details by #'cddr
                          do (views:html
                               (:tr (:td (:tt (views:esc (format nil "~(~A~)" key))))
                                    (:td (views:object-ref value)))))))
          (views:html
            (:p (views:esc "No extra details.")))))))

(views:defview 👀repair (issue lookup-issue)
  (views:html-view :title "Repair" :priority 3
    (views:html
      (:p (views:esc
           (or (lookup-issue-repair-description-of issue)
               "No repair operation has been attached to this lookup issue yet.")))
      (when (lookup-issue-repair-thunk-of issue)
        (views:html
          (:p (views:eval-button
               "Inspect repair operation"
               (views:thunk
                 (funcall (lookup-issue-repair-thunk-of issue))))))))))

(views:defview 👀condition (issue lookup-issue)
  (when-let (condition (lookup-issue-underlying-condition-of issue))
    (views:html-view :title "Condition" :priority 4
      (views:html
        (:div :class "hyperbook-page"
              (views:object-ref condition))))))
