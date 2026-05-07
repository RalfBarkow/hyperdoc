;;;; HyperBook documentation as a HTML HyperBook
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

(defvar *hyperbook*
  (let* ((directory (asdf:system-relative-pathname
                     :hyperbook
                     "hyperbook-the-book/"))
         (page-files (-> directory
                         uiop:directory-files
                         (sort #'string< :key #'pathname-name))))
    (make-instance 'html-hyperbook
                   :id "hyperbook"
                   :title "HyperBook"
                   :html-files page-files)))

(eval-when (:load-toplevel)
  (register *hyperbook*))
