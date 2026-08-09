;;;; Source-backed Git repository checkout objects incubated by Dreyeck.

(in-package #:dreyeck/git)

(defun system-repository-root-info (system)
  "Return the Git root for SYSTEM and the source used to discover it."
  (let* ((system (asdf:find-system system))
         (source-file (ignore-errors (asdf:system-source-file system))))
    (unless source-file
      (error "ASDF system ~A has no source file for repository lookup."
             (asdf:component-name system)))
    (values
     (uiop:ensure-directory-pathname
      (pathname
       (string-right-trim
        '(#\Newline #\Return)
        (uiop:run-program
         (list "git" "-C"
               (namestring
                (uiop:pathname-directory-pathname source-file))
               "rev-parse" "--show-toplevel")
         :output :string
         :error-output :output))))
     :system-source-default)))

(defclass git-repository-checkout ()
  ((root :reader git-repository-root-of
         :initarg :root
         :type pathname)
   (root-source :reader git-repository-root-source-of
                :initarg :root-source)
   (git-program :reader git-program-of
                :initarg :git-program
                :initform "git"
                :type string))
  (:documentation
   "Source-backed object representing a live Git checkout used by Dreyeck."))

(defmethod print-object ((checkout git-repository-checkout) stream)
  (print-unreadable-object (checkout stream :type t :identity nil)
    (format stream "~A via ~A"
            (git-repository-root-of checkout)
            (git-repository-root-source-of checkout))))

(defvar *git-repository-checkout* nil)

(defun make-current-git-repository-checkout ()
  "Return a source-backed object for the checkout containing DREYECK/GIT."
  (multiple-value-bind (root source)
      (system-repository-root-info :dreyeck/git)
    (unless (and root (probe-file root))
      (error "No usable Dreyeck Git repository root: ~S from ~S"
             root source))
    (make-instance 'git-repository-checkout
                   :root root
                   :root-source source)))

(defun current-git-repository-checkout ()
  "Return the memoized live checkout object, constructing it if needed."
  (or *git-repository-checkout*
      (setf *git-repository-checkout*
            (make-current-git-repository-checkout))))
