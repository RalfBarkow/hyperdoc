(defpackage #:dreyeck/slice-summary
  (:use #:cl)
  (:export #:slice-summary
           #:make-slice-summary
           #:slice-summary-records-of
           #:slice-summary-record-count
           #:slice-summary-status-observations
           #:slice-summary-failure-records
           #:slice-summary-trace-records
           #:slice-summary-evidence-records
           #:slice-summary-identified-records
           #:slice-summary-annotated-records))
