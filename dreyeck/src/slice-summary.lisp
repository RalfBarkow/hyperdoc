(in-package #:dreyeck/slice-summary)

(defclass slice-summary nil
          ((records :initarg :records :reader slice-summary-records-of)))

(defun make-slice-summary (records)
  (make-instance 'slice-summary :records (copy-list records)))

(defun slice-summary-record-count (summary)
  (length (slice-summary-records-of summary)))

(defun slice-summary-status-observations (summary)
  (mapcar
   (lambda (record)
     (list :record record :status
           (dreyeck/evaluation-record:evaluation-status-of record)))
   (slice-summary-records-of summary)))

(defun slice-summary-failure-records (summary)
  (remove-if-not #'dreyeck/evaluation-record:evaluation-failure-of
                 (slice-summary-records-of summary)))

(defun slice-summary-trace-records (summary)
  (remove-if-not #'dreyeck/evaluation-record:evaluation-trace-of
                 (slice-summary-records-of summary)))

(defun slice-summary-evidence-records (summary)
  (remove-if-not #'dreyeck/evaluation-record:evaluation-evidence-of
                 (slice-summary-records-of summary)))

(defun slice-summary-identified-records (summary)
  (remove-if-not #'dreyeck/evaluation-record:evaluation-identity-of
                 (slice-summary-records-of summary)))

(defun slice-summary-annotated-records (summary)
  (remove-if-not #'dreyeck/evaluation-record:evaluation-annotation-of
                 (slice-summary-records-of summary)))
