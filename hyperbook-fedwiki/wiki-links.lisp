;;;; Wiki links
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

(defclass wiki-link (hb:object-link)
  ((target-title :reader target-title-of :type string :initarg :target-title)
   (target-slug :reader target-slug-of :type string :initarg :target-slug)))

(defun make-wiki-link (source-page &key target-title target-slug)
  (make-instance 'wiki-link
                 :source-hyperbook (-> source-page hb:hyperbook-of hb:id-of)
                 :source-page (-> source-page hb:id-of)
                 :target-title target-title
                 :target-slug target-slug
                 :thunk (views:thunk
                          (handler-case
                              ;; For now, always fail.
                              (error 'lookup-failure)
                            (error (c) c)))))

(defclass wiki-links (hb:links)
  ((wiki-links :reader wiki-links-of :initarg :wiki-links :initform nil)))
