(in-package #:dreyeck/evaluation-record)

(defmethod evaluation-specification-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  nil)

(defmethod evaluation-input-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  (dreyeck/sly-mrepl:sly-mrepl-evaluation-input-string-of record))

(defmethod evaluation-status-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  (dreyeck/sly-mrepl:sly-mrepl-evaluation-status-of record))

(defmethod evaluation-result-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  (dreyeck/sly-mrepl:sly-mrepl-evaluation-results-of record))

(defmethod evaluation-trace-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  nil)

(defmethod evaluation-evidence-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  (dreyeck/sly-mrepl:sly-mrepl-evaluation-condition-of record))

(defmethod evaluation-failure-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  (dreyeck/sly-mrepl:sly-mrepl-evaluation-condition-of record))

(defmethod evaluation-started-at-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  nil)

(defmethod evaluation-finished-at-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  nil)

(defmethod evaluation-identity-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  nil)

(defmethod evaluation-annotation-of
           ((record dreyeck/sly-mrepl:sly-mrepl-evaluation-record))
  (list :remote-id (dreyeck/sly-mrepl:sly-mrepl-evaluation-remote-id-of record)
        :package-before
        (dreyeck/sly-mrepl:sly-mrepl-evaluation-package-before-of record)
        :directory-before
        (dreyeck/sly-mrepl:sly-mrepl-evaluation-directory-before-of record)
        :package-after
        (dreyeck/sly-mrepl:sly-mrepl-evaluation-package-after-of record)
        :directory-after
        (dreyeck/sly-mrepl:sly-mrepl-evaluation-directory-after-of record)))
