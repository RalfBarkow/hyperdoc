;;;; Structured lookup issues for failed HyperBook links
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperbook)

(declaim (special *lisp-functions*))

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
   (underlying-message :reader lookup-issue-underlying-message-of
                       :initarg :underlying-message
                       :initform nil
                       :type (or null string))
   (link :reader lookup-issue-link-of
         :initarg :link
         :initform nil)))

(defclass page-lookup-issue (lookup-issue) ())

(defclass function-lookup-issue (lookup-issue) ())

(defclass function-lookup-correction ()
  ((mode :reader function-lookup-correction-mode-of
         :initarg :mode)
   (expected-symbol :reader function-lookup-correction-expected-symbol-of
                    :initarg :expected-symbol
                    :initform nil)
   (expected-page-id :reader function-lookup-correction-expected-page-id-of
                     :initarg :expected-page-id
                     :initform nil)
   (source-hyperbook :reader function-lookup-correction-source-hyperbook-of
                     :initarg :source-hyperbook
                     :initform nil)
   (source-page-id :reader function-lookup-correction-source-page-id-of
                   :initarg :source-page-id
                   :initform nil)
   (source-page-title :reader function-lookup-correction-source-page-title-of
                      :initarg :source-page-title
                      :initform nil)
   (reference-kind :reader function-lookup-correction-reference-kind-of
                   :initarg :reference-kind
                   :initform nil)
   (package-name :reader function-lookup-correction-package-name-of
                 :initarg :package-name
                 :initform nil)
   (guidance :reader function-lookup-correction-guidance-of
             :initarg :guidance
             :type string)))

(defclass target-grouping-issue (lookup-issue) ())

(defparameter *lookup-issue-status-overrides* (make-hash-table :test #'equal))

(defun lookup-issue-static-details-of (issue)
  (slot-value issue 'details))

(defun lookup-issue-detail-value (issue key)
  (getf (lookup-issue-static-details-of issue) key))

(defun function-lookup-issue-expected-symbol (issue)
  (lookup-issue-detail-value issue :expected-symbol))

(defun function-lookup-issue-runtime-load-state (issue)
  (let ((symbol (function-lookup-issue-expected-symbol issue)))
    (cond
      ((null symbol)
       :unknown)
      ((fboundp symbol)
       :fbound)
      (t
       :missing))))

(defun function-lookup-issue-guidance (issue)
  (let* ((symbol (function-lookup-issue-expected-symbol issue))
         (package-name (lookup-issue-detail-value issue :package-name))
         (source-page-title (lookup-issue-source-page-title-of issue))
         (source-page-id (lookup-issue-source-page-id-of issue))
         (page-fragment
           (cond
             ((and source-page-title source-page-id)
              (format nil " from page ~A (~A)" source-page-title source-page-id))
             (source-page-title
              (format nil " from page ~A" source-page-title))
             (source-page-id
              (format nil " from page ~A" source-page-id))
             (t
              ""))))
    (case (function-lookup-issue-runtime-load-state issue)
      (:fbound
       (format nil
               "The expected symbol ~A is now fbound in the current image. Retry the Lisp Functions lookup to reopen ~A."
               (or symbol
                   (lookup-issue-expected-page-id-of issue)
                   "the requested function")
               (or (lookup-issue-expected-page-id-of issue)
                   "the function page")))
      (:missing
       (format nil
               "The expected symbol ~A is still not fbound in the current image.~:[~; The authored package context is ~A.~] Load or reload the defining file or system~A, then reopen the Lisp Functions page."
               (or symbol
                   (lookup-issue-expected-page-id-of issue)
                   "the requested function")
               package-name
               package-name
               page-fragment))
      (t
       (format nil
               "HyperDoc could not confirm a concrete symbol binding for ~A. Inspect the authored reference and package context before retrying the Lisp Functions lookup."
               (or (lookup-issue-expected-page-id-of issue)
                   "this source-of-function reference"))))))

(defun make-function-lookup-correction (issue)
  (make-instance 'function-lookup-correction
                 :mode :load-or-reload-definition
                 :expected-symbol (function-lookup-issue-expected-symbol issue)
                 :expected-page-id (lookup-issue-expected-page-id-of issue)
                 :source-hyperbook (source-hyperbook-of issue)
                 :source-page-id (lookup-issue-source-page-id-of issue)
                 :source-page-title (lookup-issue-source-page-title-of issue)
                 :reference-kind (lookup-issue-detail-value issue :reference-kind)
                 :package-name (lookup-issue-detail-value issue :package-name)
                 :guidance (function-lookup-issue-guidance issue)))

(defun function-lookup-issue-repair-operation (issue)
  (case (function-lookup-issue-runtime-load-state issue)
    (:fbound
     (find-page *lisp-functions*
                (lookup-issue-expected-page-id-of issue)
                :signal-error? t))
    (t
     (make-function-lookup-correction issue))))

(defun function-lookup-issue-runtime-details (issue)
  (let ((load-state (function-lookup-issue-runtime-load-state issue)))
    (list :runtime-load-state load-state
          :current-fboundp (eq load-state :fbound)
          :correction-mode
          (case load-state
            (:fbound :reopen-lisp-function-page)
            (:missing :load-or-reload-definition)
            (t :inspect-source-reference))
          :repair-evidence
          (case load-state
            (:fbound
             "fboundp returned true for the expected symbol in the current image.")
            (:missing
             "fboundp returned false for the expected symbol in the current image.")
            (t
             "No concrete expected symbol was available for a direct fboundp check.")))))

(defun function-lookup-issue-status-reason (issue)
  (case (function-lookup-issue-runtime-load-state issue)
    (:fbound
     "The expected symbol is currently fbound in the running image, so HyperDoc can retry the real Lisp Functions lookup now.")
    (:missing
     "The expected symbol is still not fbound in the running image, so HyperDoc can only offer load or reload guidance until the definition is available.")
    (t
     "HyperDoc could not confirm a concrete expected symbol binding in the current image.")))

(defun function-lookup-issue-repair-target-label (issue)
  (case (function-lookup-issue-runtime-load-state issue)
    (:fbound
     "real Lisp Functions page")
    (:missing
     "inspectable load or reload guidance")
    (t
     "inspectable correction guidance")))

(defun function-lookup-issue-retry-available-p (issue)
  (eq (function-lookup-issue-runtime-load-state issue)
      :fbound))

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
                 :underlying-message nil
                 :link link))

(defun make-function-lookup-issue
    (condition
     &key source-object source-hyperbook source-page-id source-page-title
       source-section link-text target-hyperbook-id expected-page-id link
       (target-kind :lisp-function-page)
       (classification :missing-lisp-function-definition)
       (status :open)
       suggested-repair
       repair-description
       repair-thunk
       details)
  (make-instance 'function-lookup-issue
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
                 :underlying-message (princ-to-string condition)
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
      (if (typep issue 'function-lookup-issue)
          (case (function-lookup-issue-runtime-load-state issue)
            (:fbound :fixed)
            (:missing :needs-runtime-load)
            (t (lookup-issue-default-status-of issue)))
          (lookup-issue-default-status-of issue))))

(defun mark-lookup-issue! (issue status)
  (setf (gethash (lookup-issue-signature issue)
                 *lookup-issue-status-overrides*)
        status)
  issue)

(defun append-lookup-issue-details! (issue details)
  (when details
    (setf (lookup-issue-details-of issue)
          (append (lookup-issue-details-of issue)
                  details)))
  issue)

(defun configure-lookup-issue!
    (issue
     &key
       ((:target-kind target-kind) nil target-kind-p)
       ((:classification classification) nil classification-p)
       ((:status status) nil status-p)
       ((:suggested-repair suggested-repair) nil suggested-repair-p)
       ((:repair-description repair-description) nil repair-description-p)
       ((:repair-thunk repair-thunk) nil repair-thunk-p)
       ((:details details) nil details-p))
  (when target-kind-p
    (setf (lookup-issue-target-kind-of issue) target-kind))
  (when classification-p
    (setf (lookup-issue-classification-of issue) classification))
  (when status-p
    (setf (lookup-issue-default-status-of issue) status))
  (when suggested-repair-p
    (setf (lookup-issue-suggested-repair-of issue) suggested-repair))
  (when repair-description-p
    (setf (lookup-issue-repair-description-of issue) repair-description))
  (when repair-thunk-p
    (setf (lookup-issue-repair-thunk-of issue) repair-thunk))
  (when details-p
    (append-lookup-issue-details! issue details))
  issue)

(defun classify-generic-page-lookup-issue! (issue)
  (configure-lookup-issue!
   issue
   :target-kind :hyperbook-page
   :classification :missing-hyperbook-page
   :suggested-repair :inspect-target-hyperbook
   :repair-description
   "This lookup failed against a non-HyperDoc HyperBook. Inspect that HyperBook's own authoring or index path instead of routing through HyperDoc page scaffolding."))

(defgeneric enrich-lookup-issue (issue)
  (:method ((issue lookup-issue))
    issue))

(defmethod lookup-issue-suggested-repair-of ((issue function-lookup-issue))
  (case (function-lookup-issue-runtime-load-state issue)
    (:fbound
     :reopen-lisp-function-page)
    (:missing
     :load-or-reload-definition)
    (t
     (call-next-method))))

(defmethod lookup-issue-repair-description-of ((issue function-lookup-issue))
  (function-lookup-issue-guidance issue))

(defmethod lookup-issue-repair-thunk-of ((issue function-lookup-issue))
  (lambda ()
    (function-lookup-issue-repair-operation issue)))

(defmethod lookup-issue-details-of ((issue function-lookup-issue))
  (append (call-next-method)
          (function-lookup-issue-runtime-details issue)))

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

(defun make-render-time-hyperbook-lookup-issue
    (condition &key source-page target-hyperbook-id link-text source-section)
  (let ((issue (make-basic-hyperbook-lookup-issue condition source-page)))
    (when target-hyperbook-id
      (setf (slot-value issue 'target-hyperbook-id) target-hyperbook-id
            (slot-value issue 'target-site)
            (lookup-issue-target-site target-hyperbook-id)))
    (when link-text
      (setf (slot-value issue 'link-text) link-text))
    (when source-section
      (setf (slot-value issue 'source-section) source-section))
    (append-lookup-issue-details!
     issue
     (list :render-phase :content
           :condition-type (type-of condition)))
    (enrich-lookup-issue issue)))

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

(defmethod views:text-representation ((correction function-lookup-correction))
  (format nil "Function lookup correction: ~A"
          (issue-label
           (function-lookup-correction-mode-of correction))))

(defgeneric render-lookup-issue-overview-extra-rows (issue)
  (:method ((issue lookup-issue))
    nil)
  (:method ((issue function-lookup-issue))
    (views:html
      (:tr (:td (views:esc "Current runtime load state"))
           (:td (:tt (views:esc
                      (issue-label
                       (function-lookup-issue-runtime-load-state issue))))))
      (:tr (:td (views:esc "Current-state reason"))
           (:td (views:esc
                 (function-lookup-issue-status-reason issue))))
      (:tr (:td (views:esc "Repair path on click"))
           (:td (views:esc
                 (function-lookup-issue-repair-target-label issue))))
      (:tr (:td (views:esc "Retry available now"))
           (:td (:tt (views:esc
                      (if (function-lookup-issue-retry-available-p issue)
                          "yes"
                          "no"))))))))

(defgeneric lookup-issue-repair-button-label-of (issue)
  (:method ((issue lookup-issue))
    "Inspect repair operation")
  (:method ((issue function-lookup-issue))
    (if (function-lookup-issue-retry-available-p issue)
        "Retry Lisp Functions lookup"
        "Inspect load or reload guidance")))

(defgeneric render-lookup-issue-repair-extra-content (issue)
  (:method ((issue lookup-issue))
    nil)
  (:method ((issue function-lookup-issue))
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Current runtime load state"))
                   (:td (:tt (views:esc
                              (issue-label
                               (function-lookup-issue-runtime-load-state issue))))))
              (:tr (:td (views:esc "Current-state reason"))
                   (:td (views:esc
                         (function-lookup-issue-status-reason issue))))
              (:tr (:td (views:esc "Repair path on click"))
                   (:td (views:esc
                         (function-lookup-issue-repair-target-label issue))))
              (:tr (:td (views:esc "Retry available now"))
                   (:td (:tt (views:esc
                              (if (function-lookup-issue-retry-available-p issue)
                                  "yes"
                                  "no"))))))
      (:p (views:esc
           "Overview preserves authored provenance for this failure, and Condition preserves the original undefined-function evidence.")))))

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
              (:tr (:td (views:esc "Source page id / slug"))
                   (:td (:tt (views:esc
                              (or (lookup-issue-source-page-id-of issue)
                                  "")))))
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
                                       ""))))
              (render-lookup-issue-overview-extra-rows issue)))))

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
      (render-lookup-issue-repair-extra-content issue)
      (when (lookup-issue-repair-thunk-of issue)
        (views:html
          (:p (views:eval-button
               (lookup-issue-repair-button-label-of issue)
               (views:thunk
                 (funcall (lookup-issue-repair-thunk-of issue))))))))))

(views:defview 👀condition (issue lookup-issue)
  (when-let (condition (lookup-issue-underlying-condition-of issue))
    (views:html-view :title "Condition" :priority 4
      (views:html
        (:div :class "hyperbook-page"
              (when-let (message (lookup-issue-underlying-message-of issue))
                (views:html
                  (:p (views:esc "Preserved condition text"))
                  (:pre (views:esc message))))
              (views:object-ref condition))))))

(views:defview 👀overview (correction function-lookup-correction)
  (views:html-view :title "Overview" :priority 1
    (views:html
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Mode"))
                   (:td (:tt (views:esc
                              (issue-label
                               (function-lookup-correction-mode-of correction))))))
              (:tr (:td (views:esc "Expected symbol"))
                   (:td (views:object-ref
                         (function-lookup-correction-expected-symbol-of correction))))
              (:tr (:td (views:esc "Expected page id / slug"))
                   (:td (:tt (views:esc
                              (or (function-lookup-correction-expected-page-id-of correction)
                                  "")))))
              (:tr (:td (views:esc "Source HyperBook"))
                   (:td (views:esc
                         (or (function-lookup-correction-source-hyperbook-of correction)
                             ""))))
              (:tr (:td (views:esc "Source page"))
                   (:td (views:esc
                         (or (function-lookup-correction-source-page-title-of correction)
                             ""))))
              (:tr (:td (views:esc "Source page id / slug"))
                   (:td (:tt (views:esc
                              (or (function-lookup-correction-source-page-id-of correction)
                                  "")))))
              (:tr (:td (views:esc "Reference kind"))
                   (:td (:tt (views:esc
                              (or (and (function-lookup-correction-reference-kind-of correction)
                                       (issue-label
                                        (function-lookup-correction-reference-kind-of correction)))
                                  "")))))
              (:tr (:td (views:esc "Package"))
                   (:td (:tt (views:esc
                              (or (function-lookup-correction-package-name-of correction)
                                  "")))))))))

(views:defview 👀guidance (correction function-lookup-correction)
  (views:html-view :title "Guidance" :priority 2
    (views:html
      (:p (views:esc (function-lookup-correction-guidance-of correction))))))
