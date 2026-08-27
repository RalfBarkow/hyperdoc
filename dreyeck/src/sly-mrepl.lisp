(in-package #:dreyeck/sly-mrepl)

(defclass sly-mrepl-evaluation-record nil
          ((remote-id :initarg :remote-id :reader
            sly-mrepl-evaluation-remote-id-of)
           (input-string :initarg :input-string :reader
            sly-mrepl-evaluation-input-string-of)
           (package-before :initarg :package-before :reader
            sly-mrepl-evaluation-package-before-of)
           (directory-before :initarg :directory-before :reader
            sly-mrepl-evaluation-directory-before-of)
           (status :initarg :status :reader sly-mrepl-evaluation-status-of)
           (results :initarg :results :reader sly-mrepl-evaluation-results-of)
           (condition-object :initarg :condition :reader
            sly-mrepl-evaluation-condition-of)
           (package-after :initarg :package-after :reader
            sly-mrepl-evaluation-package-after-of)
           (directory-after :initarg :directory-after :reader
            sly-mrepl-evaluation-directory-after-of)))

(defun make-sly-mrepl-evaluation-record
       (
        &key remote-id input-string package-before directory-before status
        results condition-object package-after directory-after)
  (make-instance 'sly-mrepl-evaluation-record :remote-id remote-id
                 :input-string input-string :package-before package-before
                 :directory-before directory-before :status status :results
                 results :condition condition-object :package-after
                 package-after :directory-after directory-after))
