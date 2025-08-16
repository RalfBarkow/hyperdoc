;;;; Packages in which the HyperDoc defines code or data
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defun find-packages-used (hd)
  (let ((packages nil))
    (dolist (source-file (code-files hd))
      (setf packages
            (union packages
                   (find-packages-used-in-file source-file)
                   :test #'eq)))
    packages))

(defun find-packages-used-in-file (source-file)
  (let* ((pathname (asdf:component-pathname source-file))
         (tlfs (html-inspector-views/standard:s-exp
                (html-inspector-views/standard:parse-lisp-code pathname))))
    (remove-duplicates
     (loop for tlf in tlfs
           when (eq (car tlf) 'in-package)
             collect (find-package (cadr tlf)))
     :test #'eq)))

(defun packages-used (hd)
  (or (packages hd)
      (setf (slot-value hd 'packages)
            (find-packages-used hd))))

(views:defview 👀packages (hd hyperdoc)
  (-> hd
    packages-used
    views:👀items
    (views:rename :title "Packages" :priority 5)))
