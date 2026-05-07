;;;; Narrow chunk-backed repair path for missing topic/topic-page lookup issues
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *page-lookup-topic-source-path*
  (asdf:system-relative-pathname :hyperdoc "hyperdoc/topics.lisp"))

(defparameter *page-lookup-topic-loader*
  #'load)

(defparameter +no-info-date+ -1)

(defvar *page-lookup-current-source-signature-table* nil)

(defclass page-lookup-target-chunk ()
  ((id :reader id-of :initarg :id)
   (title :reader title-of :initarg :title)
   (summary :reader summary-of :initarg :summary)
   (last-derived-at :accessor last-derived-at :initarg :last-derived-at :initform nil)))

(defclass authored-topic-factory-chunk (page-lookup-target-chunk)
  ((topic-title :reader page-lookup-topic-title-of :initarg :topic-title)))

(defclass topic-page-availability-chunk (page-lookup-target-chunk)
  ((topic-title :reader page-lookup-topic-title-of :initarg :topic-title)))

(defgeneric chunk-basis (chunk)
  (:method ((chunk page-lookup-target-chunk))
    nil))

(defgeneric derive-date (chunk)
  (:method ((chunk page-lookup-target-chunk))
    (or (last-derived-at chunk)
        +no-info-date+)))

(defgeneric basis-date (chunk)
  (:method ((chunk page-lookup-target-chunk))
    (reduce #'max
            (mapcar #'derive-date (chunk-basis chunk))
            :initial-value +no-info-date+)))

(defgeneric chunk-satisfied-p (chunk))

(defgeneric chunk-up-to-date-p (chunk)
  (:method ((chunk page-lookup-target-chunk))
    (let ((my-date (derive-date chunk))
          (my-basis-date (basis-date chunk)))
      (and (known-chunk-date-p my-date)
           (or (not (known-chunk-date-p my-basis-date))
               (<= my-basis-date my-date))))))

(defgeneric derive-chunk (chunk))

(defgeneric issue-target-chunk (issue)
  (:method (issue)
    (declare (ignore issue))
    nil))

(defun known-chunk-date-p (date)
  (and (numberp date)
       (not (eql date +no-info-date+))))

(defun ensure-chunk (chunk)
  (dolist (basis (chunk-basis chunk))
    (ensure-chunk basis))
  (unless (chunk-up-to-date-p chunk)
    (let ((changed-at (derive-chunk chunk)))
      (when (known-chunk-date-p changed-at)
        (setf (last-derived-at chunk) changed-at))))
  chunk)

(defun page-lookup-topic-source-path ()
  (uiop:ensure-pathname *page-lookup-topic-source-path*))

(defun page-lookup-topic-source-write-date ()
  (or (ignore-errors
        (file-write-date (page-lookup-topic-source-path)))
      +no-info-date+))

(defun page-lookup-title->stable-key (title)
  (let ((pending-separator-p nil))
    (string-downcase
     (string-trim
      "-"
      (with-output-to-string (out)
        (loop for ch across title
              do (cond
                   ((alphanumericp ch)
                    (when pending-separator-p
                      (write-char #\- out)
                      (setf pending-separator-p nil))
                    (write-char ch out))
                   (t
                    (setf pending-separator-p t)))))))))

(defun page-lookup-title->factory-symbol (title)
  (intern (format nil "~A-TOPIC"
                  (string-upcase
                   (page-lookup-title->stable-key title)))
          :hyperdoc))

(defun page-lookup-topic-factory-marker (title)
  (format nil "(DEFUN ~A"
          (symbol-name (page-lookup-title->factory-symbol title))))

(defun page-lookup-topic-source-signature-table ()
  (or *page-lookup-current-source-signature-table*
      (let ((table (make-hash-table :test #'eq)))
        (with-open-file (stream (page-lookup-topic-source-path)
                                :direction :input
                                :external-format :utf-8)
          (with-standard-io-syntax
            (let ((*package* (find-package :hyperdoc)))
              (loop for form = (read stream nil :eof)
                    until (eq form :eof)
                    do (when (and (consp form)
                                  (eq (first form) 'defun)
                                  (symbolp (second form)))
                         (setf (gethash (second form) table)
                               (prin1-to-string form)))))))
        table)))

(defun authored-topic-factory-source-signature (title)
  (gethash (page-lookup-title->factory-symbol title)
           (page-lookup-topic-source-signature-table)))

(defun authored-topic-factory-defined-in-source-p (title)
  (not (null (authored-topic-factory-source-signature title))))

(defun topic-page-materialization-signature (title)
  (gethash (page-lookup-title->factory-symbol title)
           *topic-index-materialization-signatures*))

(defun topic-page-authored-signature-token (title)
  (source-signature->freshness-token
   (authored-topic-factory-source-signature title)))

(defun topic-page-materialization-signature-token (title)
  (source-signature->freshness-token
   (topic-page-materialization-signature title)))

(defun source-signature->freshness-token (signature)
  (if signature
      (logand most-positive-fixnum
              (sxhash signature))
      +no-info-date+))

(defun topic-page-signatures-match-p (title)
  (let ((source-signature (authored-topic-factory-source-signature title))
        (materialized-signature (topic-page-materialization-signature title)))
    (and source-signature
         materialized-signature
         (string= source-signature materialized-signature))))

(defun topic-page-signature-freshness-known-p (title)
  (let ((source-signature (authored-topic-factory-source-signature title))
        (materialized-signature (topic-page-materialization-signature title)))
    (and source-signature
         materialized-signature)))

(defun fallback-topic-page-up-to-date-p (title)
  (declare (ignore title))
  (let ((source-date (page-lookup-topic-source-write-date))
        (materialized-date (or *topic-index-derived-at*
                               +no-info-date+)))
    (and (known-chunk-date-p source-date)
         (known-chunk-date-p materialized-date)
         (<= source-date materialized-date))))

(defun topic-page-lookup-freshness-mode (chunk)
  (let ((title (page-lookup-topic-title-of chunk)))
    (cond
      ((topic-page-signature-freshness-known-p title)
       :per-topic-signature)
      ((and (known-chunk-date-p (page-lookup-topic-source-write-date))
            (known-chunk-date-p (or *topic-index-derived-at*
                                    +no-info-date+)))
       :fallback-write-date)
      (t
       :no-freshness-evidence))))

(defun topic-page-lookup-status-reason (chunk)
  (let* ((title (page-lookup-topic-title-of chunk))
         (authored-factory-defined-p
          (authored-topic-factory-defined-in-source-p title))
         (page-resolves-p (topic-page-resolves-p title))
         (signature-freshness-known-p
          (topic-page-signature-freshness-known-p title))
         (signatures-match-p
          (and signature-freshness-known-p
               (topic-page-signatures-match-p title))))
    (cond
      ((not authored-factory-defined-p)
       "No authored topic factory for this title exists in the bound topics source.")
      ((not page-resolves-p)
       "An authored topic factory exists, but the Topics hyperbook does not currently resolve this page title.")
      ((and signature-freshness-known-p
            (not signatures-match-p))
       "The Topics page resolves, but the materialized per-topic signature no longer matches the current authored topic factory.")
      ((and (not signature-freshness-known-p)
            (not (fallback-topic-page-up-to-date-p title)))
       "The Topics page resolves, but fallback freshness evidence says the materialized topic index is older than the authored topics source.")
      (t
       "The Topics page resolves and the materialized topic entry is current for this authored topic factory."))))

(defun topic-page-lookup-repair-hint (chunk)
  (let ((title (page-lookup-topic-title-of chunk)))
    (declare (ignore title))
    (case (topic-page-lookup-chunk-state chunk)
      (:needs-topic-creation
       "Ensure the authored topic factory basis chunk first. That appends a placeholder topic factory to topics.lisp, reloads the source, and then rebuilds topic indexes through the target chunk.")
      (:needs-local-materialization
       (if (topic-page-resolves-p (page-lookup-topic-title-of chunk))
           "Ensure the target chunk. That reloads topics.lisp and rebuilds topic indexes so the materialized per-topic signature matches the current authored topic factory."
           "Ensure the target chunk. That reloads topics.lisp and rebuilds topic indexes until the Topics page resolves again."))
      (:fixed
       "No repair is needed. Ensuring the target chunk should be a no-op while the authored topic factory and materialized topic entry stay in sync.")
      (otherwise
       "Inspect the target chunk before attempting repair."))))

(defun topic-page-lookup-repair-description (chunk)
  (format nil "~A ~A"
          (topic-page-lookup-status-reason chunk)
          (topic-page-lookup-repair-hint chunk)))

(defun page-lookup-placeholder-topic-form (title &key (summary "TODO: add summary."))
  (let ((stable-key (page-lookup-title->stable-key title))
        (function-name (page-lookup-title->factory-symbol title)))
    (format nil
            "~%~%(defun ~A ()~%  (make-topic~%   :id ~S~%   :title ~S~%   :summary ~S~%   :references '()))~%"
            (symbol-name function-name)
            stable-key
            title
            summary)))

(defun append-placeholder-topic-factory! (title)
  (with-open-file (stream (page-lookup-topic-source-path)
                          :direction :output
                          :if-exists :append
                          :if-does-not-exist :error
                          :external-format :utf-8)
    (write-string (page-lookup-placeholder-topic-form title) stream))
  title)

(defun load-page-lookup-topic-source! ()
  (funcall *page-lookup-topic-loader*
           (page-lookup-topic-source-path))
  t)

(defun find-authored-topic-factory-by-title (title)
  (let ((*topics-by-id* (make-hash-table :test #'equal))
        (*topics-by-title* (make-hash-table :test #'equal)))
    (do-symbols (symbol (find-package :hyperdoc))
      (when (topic-constructor-symbol-p symbol)
        (handler-case
            (let* ((factory (authored-topic-factory symbol))
                   (topic (and factory (funcall factory))))
              (when (and (typep topic 'topic)
                         (string= (title-of topic) title))
                (return symbol)))
          (error () nil))))))

(defun topic-page-resolves-p (title)
  (and (eq *topic-index-state* :ready)
       (ignore-errors
         (hb:find-page *topics* title :signal-error? t)
         t)))

(defun topic-page-lookup-chunk-state (chunk)
  (let ((title (page-lookup-topic-title-of chunk)))
    (cond
      ((not (authored-topic-factory-defined-in-source-p title))
       :needs-topic-creation)
      ((chunk-up-to-date-p chunk)
       :fixed)
      (t
       :needs-local-materialization))))

(defmethod chunk-satisfied-p ((chunk authored-topic-factory-chunk))
  (known-chunk-date-p (derive-date chunk)))

(defmethod chunk-satisfied-p ((chunk topic-page-availability-chunk))
  (chunk-up-to-date-p chunk))

(defmethod derive-date ((chunk authored-topic-factory-chunk))
  (source-signature->freshness-token
   (authored-topic-factory-source-signature
    (page-lookup-topic-title-of chunk))))

(defmethod derive-date ((chunk topic-page-availability-chunk))
  (if (topic-page-resolves-p (page-lookup-topic-title-of chunk))
      (or *topic-index-derived-at*
          +no-info-date+)
      +no-info-date+))

(defmethod chunk-basis ((chunk topic-page-availability-chunk))
  (list
   (make-instance 'authored-topic-factory-chunk
                  :id (format nil "authored-topic-factory/~A"
                              (page-lookup-topic-title-of chunk))
                  :title (format nil "Authored topic factory for ~A"
                                 (page-lookup-topic-title-of chunk))
                  :summary "The authored topic factory exists in the running HyperDoc authoring path."
                  :topic-title (page-lookup-topic-title-of chunk))))

(defmethod chunk-up-to-date-p ((chunk topic-page-availability-chunk))
  (let ((title (page-lookup-topic-title-of chunk)))
    (and (topic-page-resolves-p title)
         (if (topic-page-signature-freshness-known-p title)
             (topic-page-signatures-match-p title)
             (fallback-topic-page-up-to-date-p title)))))

(defmethod derive-chunk ((chunk authored-topic-factory-chunk))
  (let ((title (page-lookup-topic-title-of chunk)))
    (unless (authored-topic-factory-defined-in-source-p title)
      (append-placeholder-topic-factory! title)
      (load-page-lookup-topic-source!))
    (derive-date chunk)))

(defmethod derive-chunk ((chunk topic-page-availability-chunk))
  (unless (chunk-up-to-date-p chunk)
    (let ((*page-lookup-current-source-signature-table*
           (page-lookup-topic-source-signature-table)))
      (load-page-lookup-topic-source!)
      (rebuild-topic-indexes)))
  (derive-date chunk))

(defun make-topic-page-availability-chunk (title)
  (make-instance 'topic-page-availability-chunk
                 :id (format nil "topic-page/~A" title)
                 :title (format nil "Topic page ~A" title)
                 :summary "A target chunk stating that the Topics HyperBook resolves the expected page title."
                 :topic-title title))

(defun repair-lookup-issue-via-chunks (issue)
  (let ((chunk (issue-target-chunk issue)))
    (unless chunk
      (error "No target chunk is available for ~S" issue))
    (ensure-chunk chunk)))

(setf *topic-index-materialization-signature-provider*
      (lambda (symbol topic)
        (declare (ignore topic))
        (gethash symbol
                 (page-lookup-topic-source-signature-table))))
