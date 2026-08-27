(defpackage #:dreyeck/sly-mrepl
  (:use #:cl)
  (:export #:sly-mrepl-evaluation-record
           #:make-sly-mrepl-evaluation-record
           #:sly-mrepl-evaluation-remote-id-of
           #:sly-mrepl-evaluation-input-string-of
           #:sly-mrepl-evaluation-package-before-of
           #:sly-mrepl-evaluation-directory-before-of
           #:sly-mrepl-evaluation-status-of
           #:sly-mrepl-evaluation-results-of
           #:sly-mrepl-evaluation-condition-of
           #:sly-mrepl-evaluation-package-after-of
           #:sly-mrepl-evaluation-directory-after-of))
