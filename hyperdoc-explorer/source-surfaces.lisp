;;;; Source surface strategy and policy helpers for HyperDoc text pages
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass source-surface-strategy ()
  ((id :reader source-surface-strategy-id
       :initarg :id)
   (connect-capable-p :reader source-surface-connect-capable-p
                      :initarg :connect-capable-p)))

(defclass connect-source-surface-strategy (source-surface-strategy) ())

(defclass plain-source-surface-strategy (source-surface-strategy) ())

(defparameter *connect-source-surface-strategy*
  (make-instance 'connect-source-surface-strategy
                 :id :connect
                 :connect-capable-p t))

(defparameter *plain-source-surface-strategy*
  (make-instance 'plain-source-surface-strategy
                 :id :plain
                 :connect-capable-p nil))

(defparameter *source-surface-strategy-override* nil
  "Dynamic-extent override for Source surface strategy selection.")

(defun make-source-surface-strategy-class-policy-table ()
  (make-hash-table :test #'eq))

(defparameter *source-surface-strategy-class-policies*
  (make-source-surface-strategy-class-policy-table)
  "Class-based Source surface strategy policies keyed by class object.")

(defgeneric source-surface-strategy-label (strategy))

(defmethod source-surface-strategy-label
    ((strategy connect-source-surface-strategy))
  "Connect source")

(defmethod source-surface-strategy-label
    ((strategy plain-source-surface-strategy))
  "Plain source")

(defmethod source-surface-strategy-label ((strategy source-surface-strategy))
  (string-capitalize
   (substitute #\Space
               #\-
               (string-downcase
                (symbol-name (source-surface-strategy-id strategy))))))

(defgeneric source-surface-strategy-for (page))

(defmethod source-surface-strategy-for ((page text-page))
  *connect-source-surface-strategy*)

(defun normalize-source-surface-designator (designator)
  (typecase designator
    (null nil)
    (source-surface-strategy
     (source-surface-strategy-id designator))
    (keyword designator)
    (symbol
     (intern (string-upcase (symbol-name designator)) :keyword))
    (string
     (let ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return)
                                 designator)))
       (unless (string= trimmed "")
         (intern (string-upcase trimmed) :keyword))))))

(defun source-surface-strategy-from-designator (designator)
  (etypecase (normalize-source-surface-designator designator)
    (null nil)
    (source-surface-strategy designator)
    ((eql :connect) *connect-source-surface-strategy*)
    ((eql :plain) *plain-source-surface-strategy*)))

(defun source-surface-policy-class-from-designator (designator)
  (etypecase designator
    (class designator)
    (symbol (or (find-class designator nil)
                (error "Unknown Source surface policy class: ~S"
                       designator)))))

(defun copy-source-surface-strategy-class-policies
    (&optional
       (policies *source-surface-strategy-class-policies*))
  (let ((copy (make-source-surface-strategy-class-policy-table)))
    (maphash (lambda (class strategy)
               (setf (gethash class copy) strategy))
             policies)
    copy))

(defun register-source-surface-strategy-policy
    (class-designator strategy-designator)
  (setf (gethash (source-surface-policy-class-from-designator class-designator)
                 *source-surface-strategy-class-policies*)
        (source-surface-strategy-from-designator strategy-designator)))

(defun clear-source-surface-strategy-policy (class-designator)
  (remhash (source-surface-policy-class-from-designator class-designator)
           *source-surface-strategy-class-policies*))

(defun source-surface-strategy-policy-match-for (page)
  (loop for class in (c2mop:class-precedence-list (class-of page))
        for strategy = (gethash class
                                *source-surface-strategy-class-policies*)
        when strategy
          return (values strategy class)))

(defun source-surface-strategy-policy-for (page)
  (nth-value 0 (source-surface-strategy-policy-match-for page)))

(defun source-surface-strategy-stable-id (strategy-designator)
  (let ((strategy (source-surface-strategy-from-designator strategy-designator)))
    (and strategy
         (source-surface-strategy-id strategy))))

(defun source-surface-strategy-display-value (strategy-designator)
  (let ((strategy (source-surface-strategy-from-designator strategy-designator)))
    (if strategy
        (format nil "~(~A~) (~A)"
                (source-surface-strategy-id strategy)
                (source-surface-strategy-label strategy))
        "none")))

(defun source-surface-strategy-catalog ()
  (mapcar (lambda (strategy)
            (list :id (source-surface-strategy-id strategy)
                  :label (source-surface-strategy-label strategy)
                  :connect-capable-p
                  (source-surface-connect-capable-p strategy)
                  :designator (source-surface-strategy-id strategy)))
          (list *connect-source-surface-strategy*
                *plain-source-surface-strategy*)))

(defun source-surface-strategy-catalog-entry-for-designator (designator)
  (find (normalize-source-surface-designator designator)
        (source-surface-strategy-catalog)
        :key (lambda (entry) (getf entry :designator))
        :test #'eq))

(defun source-surface-designator-supported-p (designator)
  (not (null (source-surface-strategy-catalog-entry-for-designator
              designator))))

(defun source-surface-strategy-for-stable-designator (designator)
  (let ((normalized (normalize-source-surface-designator designator)))
    (unless (source-surface-designator-supported-p normalized)
      (error "Unsupported Source surface designator: ~S" designator))
    (source-surface-strategy-from-designator normalized)))

(defun source-surface-resolution-report-for (page)
  (multiple-value-bind (class-policy-strategy class-policy-class)
      (source-surface-strategy-policy-match-for page)
    (let* ((override-strategy
             (source-surface-strategy-from-designator
              *source-surface-strategy-override*))
           (default-strategy (source-surface-strategy-for page))
           (winner (cond (override-strategy :override)
                         (class-policy-strategy :class-policy)
                         (t :default)))
           (effective-strategy
             (ecase winner
               (:override override-strategy)
               (:class-policy class-policy-strategy)
               (:default default-strategy))))
      (list :target page
            :target-class (class-name (class-of page))
            :override-present-p (not (null override-strategy))
            :override-strategy override-strategy
            :override-strategy-id
            (source-surface-strategy-stable-id override-strategy)
            :override-strategy-label
            (and override-strategy
                 (source-surface-strategy-label override-strategy))
            :class-policy-matched-p (not (null class-policy-strategy))
            :class-policy-class (and class-policy-class
                                     (class-name class-policy-class))
            :class-policy-strategy class-policy-strategy
            :class-policy-strategy-id
            (source-surface-strategy-stable-id class-policy-strategy)
            :class-policy-strategy-label
            (and class-policy-strategy
                 (source-surface-strategy-label class-policy-strategy))
            :default-strategy default-strategy
            :default-strategy-id
            (source-surface-strategy-stable-id default-strategy)
            :default-strategy-label
            (source-surface-strategy-label default-strategy)
            :effective-strategy effective-strategy
            :effective-strategy-id
            (source-surface-strategy-stable-id effective-strategy)
            :effective-strategy-label
            (source-surface-strategy-label effective-strategy)
            :winner winner))))

(defun effective-source-surface-strategy-for (page)
  (getf (source-surface-resolution-report-for page)
        :effective-strategy))

(defmacro with-source-surface-strategy-override ((strategy-designator) &body body)
  `(let ((*source-surface-strategy-override* ,strategy-designator))
     ,@body))

(defmacro with-source-surface-strategy-class-policy
    ((class-designator strategy-designator) &body body)
  `(let ((*source-surface-strategy-class-policies*
           (copy-source-surface-strategy-class-policies)))
     (register-source-surface-strategy-policy
      ,class-designator
      ,strategy-designator)
     ,@body))

(defgeneric render-source-surface-with-strategy
    (strategy page &key title priority))

(defmethod render-source-surface-with-strategy
    ((strategy connect-source-surface-strategy) (page text-page)
     &key (title "Source") (priority 10))
  (views:html-view :title title :priority priority
    (render-source-connect-surface page title (file-of page))))

(defmethod render-source-surface-with-strategy
    ((strategy plain-source-surface-strategy) (page text-page)
     &key (title "Source") (priority 10))
  (views:html-view :title title :priority priority
    (hb:render-file-source-surface (file-of page))))

(defun source-surface-resolution-report-display-value (value)
  (typecase value
    (null "none")
    (boolean (if value "yes" "no"))
    (source-surface-strategy (source-surface-strategy-display-value value))
    (symbol (string-downcase (symbol-name value)))
    (t (format nil "~A" value))))

(defun source-surface-resolution-report-strategy-display
    (report strategy-id-key strategy-label-key)
  (let ((strategy-id (getf report strategy-id-key))
        (strategy-label (getf report strategy-label-key)))
    (cond ((and strategy-id strategy-label)
           (format nil "~(~A~) (~A)"
                   strategy-id
                   strategy-label))
          (strategy-id
           (string-downcase (symbol-name strategy-id)))
          (strategy-label
           strategy-label)
          (t
           "none"))))

(defun render-source-surface-resolution-report (page)
  (let* ((report (source-surface-resolution-report-for page))
         (rows
           `(("Target class"
              ,(source-surface-resolution-report-display-value
                (getf report :target-class)))
             ("Winner"
              ,(source-surface-resolution-report-display-value
                (getf report :winner)))
             ("Effective strategy"
              ,(source-surface-resolution-report-strategy-display
                report
                :effective-strategy-id
                :effective-strategy-label))
             ("Default strategy"
              ,(source-surface-resolution-report-strategy-display
                report
                :default-strategy-id
                :default-strategy-label))
             ("Override present"
              ,(source-surface-resolution-report-display-value
                (getf report :override-present-p)))
             ("Override strategy"
              ,(source-surface-resolution-report-strategy-display
                report
                :override-strategy-id
                :override-strategy-label))
             ("Class policy matched"
              ,(source-surface-resolution-report-display-value
                (getf report :class-policy-matched-p)))
             ("Matched class"
              ,(source-surface-resolution-report-display-value
                (getf report :class-policy-class)))
             ("Class policy strategy"
              ,(source-surface-resolution-report-strategy-display
                report
                :class-policy-strategy-id
                :class-policy-strategy-label)))))
    (views:html
      (:table :class "inspector-table"
              (:tr (:th (views:esc "Field"))
                   (:th (views:esc "Value")))
              (dolist (row rows)
                (destructuring-bind (label value) row
                  (views:html
                    (:tr (:td (:tt (views:esc label)))
                         (:td (:tt (views:esc value)))))))))))

(views:defview 👀source-surface (page text-page)
  (views:html-view :title "Source surface" :priority 11
    (render-source-surface-resolution-report page)))

(defun render-source-surface-strategy-catalog ()
  (views:html
    (:table :class "inspector-table"
            (:tr (:th (views:esc "Strategy id"))
                 (:th (views:esc "Label"))
                 (:th (views:esc "Connect-capable"))
                 (:th (views:esc "Designator")))
            (dolist (entry (source-surface-strategy-catalog))
              (views:html
                (:tr (:td (:tt (views:esc
                                (source-surface-resolution-report-display-value
                                 (getf entry :id)))))
                     (:td (:tt (views:esc (getf entry :label))))
                     (:td (:tt (views:esc
                                (source-surface-resolution-report-display-value
                                 (getf entry :connect-capable-p)))))
                     (:td (:tt (views:esc
                                (source-surface-resolution-report-display-value
                                 (getf entry :designator)))))))))))

(views:defview 👀source-strategies (page text-page)
  (views:html-view :title "Source strategies" :priority 14
    (render-source-surface-strategy-catalog)))

(defun render-source-surface-for-page-with-designator
    (page designator &key (title "Source") (priority 10))
  (render-source-surface-with-strategy
   (source-surface-strategy-for-stable-designator designator)
   page
   :title title
   :priority priority))

(defun render-plain-source-surface-for-page
    (page &key (title "Plain source") (priority 12))
  (render-source-surface-for-page-with-designator
   page
   :plain
   :title title
   :priority priority))

(views:defview 👀plain-source (page text-page)
  (render-plain-source-surface-for-page page))

(defun render-source-surface-for-page (page &key (title "Source") (priority 10))
  (render-source-surface-for-page-with-designator
   page
   (source-surface-strategy-id
    (effective-source-surface-strategy-for page))
   :title title
   :priority priority))

(defun source-surface-swap-preview-candidates-for-page (page)
  (let* ((report (source-surface-resolution-report-for page))
         (current-designator (getf report :effective-strategy-id)))
    (loop for entry in (source-surface-strategy-catalog)
          for designator = (getf entry :designator)
          unless (eq current-designator designator)
            collect (list :designator designator
                          :label (getf entry :label)
                          :connect-capable-p (getf entry :connect-capable-p)
                          :preview
                          (make-source-surface-swap-preview page designator)))))

(defclass source-surface-swap-preview ()
  ((page :reader source-surface-swap-preview-page-of
         :initarg :page)
   (current-report :reader source-surface-swap-preview-current-report-of
                   :initarg :current-report)
   (current-designator :reader source-surface-swap-preview-current-designator-of
                       :initarg :current-designator)
   (alternate-designator
    :reader source-surface-swap-preview-alternate-designator-of
    :initarg :alternate-designator)
   (alternate-supported-p
    :reader source-surface-swap-preview-alternate-supported-p
    :initarg :alternate-supported-p)))

(defun make-source-surface-swap-preview (page alternate-designator)
  (let* ((current-report (source-surface-resolution-report-for page))
         (normalized-alternate-designator
           (normalize-source-surface-designator alternate-designator))
         (current-designator (getf current-report :effective-strategy-id)))
    (make-instance 'source-surface-swap-preview
                   :page page
                   :current-report current-report
                   :current-designator current-designator
                   :alternate-designator normalized-alternate-designator
                   :alternate-supported-p
                   (source-surface-designator-supported-p
                    normalized-alternate-designator))))

(defun source-surface-swap-preview-alternate-entry (preview)
  (source-surface-strategy-catalog-entry-for-designator
   (source-surface-swap-preview-alternate-designator-of preview)))

(defun source-surface-swap-preview-designator-display-value (designator)
  (typecase designator
    (symbol (string-downcase (symbol-name designator)))
    (t (format nil "~A" designator))))

(defun source-surface-swap-preview-current-display-value (preview)
  (source-surface-resolution-report-strategy-display
   (source-surface-swap-preview-current-report-of preview)
   :effective-strategy-id
   :effective-strategy-label))

(defun source-surface-swap-preview-alternate-display-value (preview)
  (let ((entry (source-surface-swap-preview-alternate-entry preview))
        (designator (source-surface-swap-preview-alternate-designator-of preview)))
    (if entry
        (format nil "~(~A~) (~A)"
                (getf entry :id)
                (getf entry :label))
        (format nil "~A (unsupported)"
                (source-surface-swap-preview-designator-display-value
                 designator)))))

(defun source-surface-swap-preview-current-connect-capable-p (preview)
  (source-surface-connect-capable-p
   (getf (source-surface-swap-preview-current-report-of preview)
         :effective-strategy)))

(defun source-surface-swap-preview-alternate-connect-capable-p (preview)
  (let ((entry (source-surface-swap-preview-alternate-entry preview)))
    (and entry
         (getf entry :connect-capable-p))))

(defun source-surface-swap-preview-same-designator-p (preview)
  (eq (source-surface-swap-preview-current-designator-of preview)
      (source-surface-swap-preview-alternate-designator-of preview)))

(defmethod views:text-representation ((preview source-surface-swap-preview))
  (format nil "Source swap preview ~A -> ~A"
          (source-surface-swap-preview-designator-display-value
           (source-surface-swap-preview-current-designator-of preview))
          (source-surface-swap-preview-designator-display-value
           (source-surface-swap-preview-alternate-designator-of preview))))

(views:defview 👀overview (preview source-surface-swap-preview)
  (let ((report (source-surface-swap-preview-current-report-of preview)))
    (views:html-view :title "Overview" :priority 1
      (views:html
        (:p
         (views:esc
          "This preview keeps the current Source path intact and renders the alternate path through the public designator-based Source rendering API."))
        (:table :class "inspector-table"
                (:tr (:td (views:esc "Page"))
                     (:td (views:object-ref
                           (source-surface-swap-preview-page-of preview))))
                (:tr (:td (views:esc "Current winner"))
                     (:td (:tt
                           (views:esc
                            (source-surface-resolution-report-display-value
                             (getf report :winner))))))
                (:tr (:td (views:esc "Current Source path"))
                     (:td (:tt
                           (views:esc
                            (source-surface-swap-preview-current-display-value
                             preview)))))
                (:tr (:td (views:esc "Requested alternate"))
                     (:td (:tt
                           (views:esc
                            (source-surface-swap-preview-alternate-display-value
                             preview)))))
                (:tr (:td (views:esc "Alternate supported"))
                     (:td (:tt
                           (views:esc
                            (source-surface-resolution-report-display-value
                             (source-surface-swap-preview-alternate-supported-p
                              preview))))))
                (:tr (:td (views:esc "Same path"))
                     (:td (:tt
                           (views:esc
                            (source-surface-resolution-report-display-value
                             (source-surface-swap-preview-same-designator-p
                              preview)))))))))))

(views:defview 👀compare (preview source-surface-swap-preview)
  (let ((report (source-surface-swap-preview-current-report-of preview))
        (alternate-entry (source-surface-swap-preview-alternate-entry preview)))
    (views:html-view :title "Compare" :priority 2
      (views:html
        (:table :class "inspector-table"
                (:tr (:th (views:esc "Path"))
                     (:th (views:esc "Designator"))
                     (:th (views:esc "Label"))
                     (:th (views:esc "Connect-capable")))
                (:tr (:td (views:esc "Current"))
                     (:td (:tt
                           (views:esc
                            (source-surface-swap-preview-designator-display-value
                             (source-surface-swap-preview-current-designator-of
                              preview)))))
                     (:td (:tt
                           (views:esc
                            (getf report :effective-strategy-label))))
                     (:td (:tt
                           (views:esc
                            (source-surface-resolution-report-display-value
                             (source-surface-swap-preview-current-connect-capable-p
                              preview))))))
                (:tr (:td (views:esc "Alternate"))
                     (:td (:tt
                           (views:esc
                            (source-surface-swap-preview-designator-display-value
                             (source-surface-swap-preview-alternate-designator-of
                              preview)))))
                     (:td (:tt
                           (views:esc
                            (or (and alternate-entry
                                     (getf alternate-entry :label))
                                "unsupported"))))
                     (:td (:tt
                           (views:esc
                            (source-surface-resolution-report-display-value
                             (source-surface-swap-preview-alternate-connect-capable-p
                              preview)))))))))))

(views:defview 👀current-source (preview source-surface-swap-preview)
  (render-source-surface-for-page-with-designator
   (source-surface-swap-preview-page-of preview)
   (source-surface-swap-preview-current-designator-of preview)
   :title "Current Source"
   :priority 3))

(views:defview 👀alternate-source (preview source-surface-swap-preview)
  (let ((designator
          (normalize-source-surface-designator
           (source-surface-swap-preview-alternate-designator-of preview))))
    (case designator
      (:plain
       (render-plain-source-surface-for-page
        (source-surface-swap-preview-page-of preview)
        :title "Alternate Source"
        :priority 4))
      (t
       (render-source-surface-for-page-with-designator
        (source-surface-swap-preview-page-of preview)
        designator
        :title "Alternate Source"
        :priority 4)))))

(defun render-source-surface-swap-operations-for-page (page)
  (let* ((report (source-surface-resolution-report-for page))
         (candidates (source-surface-swap-preview-candidates-for-page page)))
    (views:html
      (:p
       (views:esc
        "This page-level operation surface keeps the current Source path unchanged and exposes inspectable swap previews for supported alternate Source designators."))
      (:table :class "inspector-table"
              (:tr (:td (views:esc "Current winner"))
                   (:td (:tt
                         (views:esc
                          (source-surface-resolution-report-display-value
                           (getf report :winner))))))
              (:tr (:td (views:esc "Current Source path"))
                   (:td (:tt
                         (views:esc
                          (source-surface-resolution-report-strategy-display
                           report
                           :effective-strategy-id
                           :effective-strategy-label))))))
      (if candidates
          (views:html
            (:table :class "inspector-table"
                    (:tr (:th (views:esc "Alternate designator"))
                         (:th (views:esc "Label"))
                         (:th (views:esc "Connect-capable"))
                         (:th (views:esc "Preview")))
                    (dolist (candidate candidates)
                      (views:html
                        (:tr
                         (:td (:tt
                               (views:esc
                                (source-surface-swap-preview-designator-display-value
                                 (getf candidate :designator)))))
                         (:td (:tt (views:esc (getf candidate :label))))
                         (:td (:tt
                               (views:esc
                                (source-surface-resolution-report-display-value
                                 (getf candidate :connect-capable-p)))))
                         (:td (views:object-ref (getf candidate :preview))))))))
          (views:html
            (:p :style "opacity: 0.7;"
                (views:esc
                 "No alternate Source swap previews are available for this page.")))))))

(views:defview 👀source-swap-operations (page text-page)
  (views:html-view :title "Source swap operations" :priority 15
    (render-source-surface-swap-operations-for-page page)))
