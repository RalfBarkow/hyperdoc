;;;; Authors from CodeMeta file
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Read codemeta.json
;;

(defun codemeta-data (hd)
  (let ((codemeta-filename  (-> hd
                              asdf-system-name 
                              (asdf:system-relative-pathname "codemeta.json"))))
    (when (probe-file codemeta-filename)
      (njson:decode codemeta-filename))))

;;
;; Author view
;;

(defun codemeta-authors (hd)
  (when-let (metadata (codemeta-data hd))
    (njson:jget "author" metadata)))

(defview 👀authors (hd hyperdoc)
  (when-let (authors (codemeta-authors hd))
    (html-view :title "Authors" :priority 2
      (loop for author across authors
            do (html
                 (:div
                  (:a :href (str:concat "mailto:" (njson:jget "email" author))
                      (esc (njson:jget "givenName" author))
                      (esc " ")
                      (esc (njson:jget "familyName" author)))
                  (:br)
                  (:a :href (njson:jget "id" author)
                      :target "_blank"
                      (esc (njson:jget "id" author)))
                  (:br)
                  (:br)))))))
