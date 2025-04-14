;;;; Authors from CodeMeta file
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Read codemeta.json
;;

(defun codemeta-data (hd)
  (-> hd
    asdf-system-name 
    (asdf:system-relative-pathname "codemeta.json")
    njson:decode))

;;
;; Author view
;;

(defun codemeta-authors (hd)
  (->> hd
    codemeta-data
    (njson:jget "author")))

(defview 👀authors (hd hyperdoc)
  (html-view :title "Authors" :priority 2
    (loop for author across (codemeta-authors hd)
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
                (:br))))))
