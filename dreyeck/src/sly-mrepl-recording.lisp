(in-package #:dreyeck/sly-mrepl/recording)

(defclass sly-mrepl-evaluation-capture nil
          ((remote-id :initarg :remote-id :reader capture-remote-id-of)
           (input-string :initarg :input-string :reader
            capture-input-string-of)
           (package-before :initarg :package-before :reader
            capture-package-before-of)
           (directory-before :initarg :directory-before :reader
            capture-directory-before-of)
           (inner-returned-p :initform nil :accessor capture-inner-returned-p)
           (results :initform nil :accessor capture-results-of)
           (condition-object :initform nil :accessor
            capture-condition-object-of)
           (package-after :initform nil :accessor capture-package-after-of)
           (directory-after :initform nil :accessor
            capture-directory-after-of)))

(defun make-capture-from-repl (repl input-string)
  (let* ((environment (slot-value repl 'slynk::env))
         (package-object (cdr (assoc '*package* environment)))
         (directory-pathname
          (cdr (assoc '*default-pathname-defaults* environment))))
    (make-instance 'sly-mrepl-evaluation-capture :remote-id
                   (slynk-mrepl::mrepl-remote-id repl) :input-string
                   input-string :package-before (package-name package-object)
                   :directory-before (namestring directory-pathname))))

(defun finish-capture-from-repl (capture repl results returned-p)
  (let* ((environment (slot-value repl 'slynk::env))
         (package-object (cdr (assoc '*package* environment)))
         (directory-pathname
          (cdr (assoc '*default-pathname-defaults* environment))))
    (setf (capture-inner-returned-p capture) returned-p
          (capture-results-of capture) (and returned-p results)
          (capture-package-after-of capture) (package-name package-object)
          (capture-directory-after-of capture) (namestring directory-pathname))
    capture))

(defun record-from-capture (capture outer-returned-p)
  (dreyeck/sly-mrepl:make-sly-mrepl-evaluation-record :remote-id
                                                      (capture-remote-id-of
                                                       capture)
                                                      :input-string
                                                      (capture-input-string-of
                                                       capture)
                                                      :package-before
                                                      (capture-package-before-of
                                                       capture)
                                                      :directory-before
                                                      (capture-directory-before-of
                                                       capture)
                                                      :status
                                                      (if outer-returned-p
                                                          :returned
                                                          :aborted)
                                                      :results
                                                      (and outer-returned-p
                                                           (capture-results-of
                                                            capture))
                                                      :condition-object
                                                      (and
                                                       (not outer-returned-p)
                                                       (capture-condition-object-of
                                                        capture))
                                                      :package-after
                                                      (capture-package-after-of
                                                       capture)
                                                      :directory-after
                                                      (capture-directory-after-of
                                                       capture)))
