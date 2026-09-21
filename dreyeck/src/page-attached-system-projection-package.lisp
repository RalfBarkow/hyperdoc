
(defpackage #:dreyeck/page-attached-system-projection
  (:use #:cl)
  (:export #:page-attached-system-projection
           #:execution-permitted-p
           #:execution-not-permitted
           #:reconstruct-page-attached-workspace
           #:page-attached-workspace-eligibility
           #:run-fresh-page-attached-workspace-reconstruction))
