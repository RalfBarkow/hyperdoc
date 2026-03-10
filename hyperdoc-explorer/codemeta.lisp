;;;; Authors from CodeMeta file
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Read codemeta.json
;;

(defun codemeta-data (hd)
  (let ((codemeta-filename (-> (asdf-system-name-of hd)
                               (asdf:system-relative-pathname "codemeta.json"))))
    (when (probe-file codemeta-filename)
      (njson:decode codemeta-filename))))

;;
;; Author view
;;

(defun codemeta-authors (hd)
  (when-let (metadata (codemeta-data hd))
    (njson:jget "author" metadata)))

(views:defview 👀authors (hd hyperdoc)
  (when-let (authors (codemeta-authors hd))
    (views:html-view :title "Authors" :priority 7
      (loop for author across authors
            do (views:html
                 (:div
                  (:a :href (str:concat "mailto:" (njson:jget "email" author))
                      (views:esc (njson:jget "givenName" author))
                      (views:esc " ")
                      (views:esc (njson:jget "familyName" author)))
                  (:br)
                  (:a :href (njson:jget "id" author)
                      :target "_blank"
                      (views:esc (njson:jget "id" author)))
                  (:br)
                  (:br)))))))
