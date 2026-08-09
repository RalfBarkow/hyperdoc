;;;; Source-backed Git repository checkout objects.
;;;; Created from SLY MREPL; reload this file rather than redefining classes ad hoc.

(in-package :hyperdoc)

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
   "Source-backed object representing the live Git checkout used by HyperDoc."))

(defmethod print-object ((checkout git-repository-checkout) stream)
  (print-unreadable-object (checkout stream :type t :identity nil)
    (format stream "~A via ~A"
            (git-repository-root-of checkout)
            (git-repository-root-source-of checkout))))

(defvar *git-repository-checkout* nil)

(defun make-current-git-repository-checkout ()
  "Return a source-backed object for the live HyperDoc Git checkout."
  (multiple-value-bind (root source)
      (system-repository-root-info :hyperdoc)
    (unless (and root (probe-file root))
      (error "No usable HyperDoc Git repository root: ~S from ~S"
             root source))
    (make-instance 'git-repository-checkout
                   :root root
                   :root-source source)))

(defun current-git-repository-checkout ()
  "Return the memoized live checkout object, constructing it if needed."
  (or *git-repository-checkout*
      (setf *git-repository-checkout*
            (make-current-git-repository-checkout))))
