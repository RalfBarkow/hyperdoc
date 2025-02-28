;;;; Page and HyperDoc links embedded in Lisp code 
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defmethod html-inspector-views/standard:find-linked-object ((head (eql 'see)) cst)
  (funcall (eval (cst:raw cst))))

(defmethod page ((title string) &key hyperdoc)
  (let ((hyperdoc (or (and hyperdoc (find-hyperdoc hyperdoc))
                      (let ((directory (make-pathname
                                        :directory (pathname-directory
                                                    html-inspector-views/standard:*current-source-code-file*))))
                        (find-hyperdoc-in-directory directory)))))
    (find-page hyperdoc title)))

(defmethod hyperdoc ((title string))
  (find-hyperdoc title))
