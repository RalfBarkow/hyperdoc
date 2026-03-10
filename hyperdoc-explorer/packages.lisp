;;;; Packages in which the HyperDoc defines code or data
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

(defun find-packages-used (hd)
  (reduce #'(lambda (acc cp)
              (union acc
                     (find-packages-used-in-file (file-of cp))
                     :test #'eq))
          (code-pages-of hd)
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
  (or (packages-of hd)
      (setf (slot-value hd 'packages)
            (find-packages-used hd))))

(defun cl-source-files-in-component (component)
  (cond
    ((typep component 'asdf:cl-source-file)
     (list component))
    ((typep component 'asdf:parent-component)
     (loop for child in (asdf:component-children component)
           append (cl-source-files-in-component child)))
    (t
     nil)))

(defun packages-defined-by-system (system)
  (sort
   (remove-duplicates
    (loop for file in (cl-source-files-in-component system)
          append (find-packages-used-in-file file))
    :test #'eq)
   #'string<
   :key #'package-name))

(views:defview 👀packages (hd hyperdoc)
  (-> hd
    packages-used
    views:👀items
    (views:rename :title "Packages" :priority 13)))

(views:defview 👀packages (system asdf:system)
  (let ((packages (packages-defined-by-system system)))
    (when packages
      (-> packages
          views:👀items
          (views:rename :title "Packages" :priority 8)))))
