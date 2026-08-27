(in-package #:dreyeck/evaluation-record)

(defmethod evaluation-specification-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-contract-of record))

(defmethod evaluation-input-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-target-paths record))

(defmethod evaluation-status-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-status record))

(defmethod evaluation-result-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-raw-output record))

(defmethod evaluation-trace-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (declare (ignore record))
  nil)

(defmethod evaluation-evidence-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (list :invocation-form
        (dreyeck/lisp-critic:lisp-critic-run-record-invocation-form-of record)
        :raw-output
        (dreyeck/lisp-critic:lisp-critic-run-record-raw-output record)
        :error-output
        (dreyeck/lisp-critic:lisp-critic-run-record-error-output-of record)
        :condition-summary
        (dreyeck/lisp-critic:lisp-critic-run-record-condition-summary-of
         record)))

(defmethod evaluation-failure-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-condition-summary-of record))

(defmethod evaluation-started-at-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-started-at-of record))

(defmethod evaluation-finished-at-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-finished-at-of record))

(defmethod evaluation-identity-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-id-of record))

(defmethod evaluation-annotation-of
           ((record dreyeck/lisp-critic:lisp-critic-run-record))
  (dreyeck/lisp-critic:lisp-critic-run-record-notes-of record))
