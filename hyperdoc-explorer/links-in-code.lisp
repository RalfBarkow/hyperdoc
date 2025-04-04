;;;; Implementation of page and HyperDoc links embedded in Lisp code
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Find the linked object in a top-level see form. If an error occurs
;; in evaluating the argument, link to the condition object.
;;

(defmethod html-inspector-views/standard:find-linked-object
    ((head (eql 'see)) cst)
  (handler-case
      (funcall (eval (cst:raw cst)))
    (error (c) c)))

;;
;; Implementations of the page and hyperdoc lookup functions
;; for use with "see".
;;

(defmethod page ((title string) &key hyperdoc)
  (let ((hyperdoc (or (and hyperdoc (find-hyperdoc hyperdoc :signal-error? t))
                      (current-hyperdoc))))
    (find-page hyperdoc title :signal-error? t)))

(defun current-hyperdoc ()
  (when-let (source html-inspector-views/standard:*current-source-code-file*)
    (let ((directory (make-pathname
                      :directory (pathname-directory source))))
      (find-hyperdoc-in-directory directory :signal-error? t))))

(defmethod hyperdoc ((title string))
  (find-hyperdoc title :signal-error? t))
