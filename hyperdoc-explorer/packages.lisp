;;;; Packages in which the HyperDoc defines code or data
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/explorer)

(defun find-packages-used (hd)
  (reduce #'(lambda (acc cp)
              (union acc
                     (find-packages-used-in-file (file-of cp))
                     :test #'eq))
          (hd::code-pages-of hd)
          :initial-value nil))

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
  (or (hd::packages-of hd)
      (setf (slot-value hd 'packages)
            (find-packages-used hd))))

(views:defview 👀packages (hd hyperdoc)
  (-> hd
    packages-used
    views:👀items
    (views:rename :title "Packages" :priority 12)))
