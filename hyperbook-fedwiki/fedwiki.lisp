;;;; Wikis
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;; A fedwiki object stores the information retrieved from
;; a wiki's site map. The HyperBook id is "fedwiki:"
;; followed by the wiki's domain name. Page ids are
;;  - the page slugs for local pages
;;  - domain/slug for remote pages
;;
;; The map from slugs to page titles is stored because
;; the title -> slug function is not invertible.

(defclass fedwiki (hb:hyperbook)
  ((pages :reader pages-of :type hash-table
          :initform (make-hash-table :test #'equal)
          :documentation "A map from page ids to page objects")
   (remote-pages :reader remote-pages-of :type hash-table
                 :initform (make-hash-table :test #'equal)
                 :documentation "A map from remote page ids to page objects")
   (plugins :reader plugins-of :type hash-table
            :initform (make-hash-table :test #'equal)
            :documentation "The map from plugin names to plugins")
   (owner :reader owner-of :type (or null string) :initform nil
          :documentation "The name of the owner of the site")
   (slugs :reader slugs-of :type hash-table
          :initform (make-hash-table :test #'equal)
          :documentation "A map from slugs to titles and back")
   (status :accessor status-of :initform nil
           :documentation "The initialization status of the wiki,
one of (1) the thread loading the site map, (2) t for a fully
loaded site map, or (3) a conditon object recording an error
that occurred when reading the site map.")))

;; Computed attributes

(defun domain-name-of (wiki)
  (->> wiki
    hb:id-of
    (str:split ":")
    second))

(defmethod hb:title-of ((wiki fedwiki))
  (domain-name-of wiki))

(defmethod hb:main-page-id-of ((wiki fedwiki))
  "welcome-visitors")

;;
;; Create a fedwiki proxy
;;

(defparameter *uri-scheme* "fedwiki:")

(defun make-fedwiki (domain-name)
  (let* ((wiki (make-instance 'fedwiki
                              :id (str:concat *uri-scheme* domain-name))))
    (setf (status-of wiki)
          (bt:make-thread
           #'(lambda ()
               (handler-case
                   (progn (fetch-sitemap wiki)
                          ;; (fetch-plugin-data wiki)
                          (setf (status-of wiki) t))
                 ((or stream-error
                   usocket:timeout-error
                   usocket:ns-host-not-found-error
                   shasht:shasht-invalid-char) (c)
                   (setf (status-of wiki) c))))))
    wiki))

(defun fetch-sitemap (wiki)
  (let* ((sitemap-url (wiki-url (domain-name-of wiki)
                                "/system/sitemap.json"))
         (sitemap (fetch-json sitemap-url)))
    (loop for page-spec across sitemap
          for slug = (gethash "slug" page-spec)
          for title = (gethash "title" page-spec)
          for links = (some->> page-spec
                        (gethash "links")
                        alexandria:hash-table-keys)
          for page = (make-fedwiki-page wiki slug title)
          do (setf (gethash slug (pages-of wiki))
                   page)
             (setf (gethash slug (slugs-of wiki))
                   title)
             (setf (gethash title (slugs-of wiki))
                   slug)
             ;; (setf (slot-value page 'links)
             ;;       (make-links page links))
          )))

;; see https://matrix.to/#/!BkPDqaI4Qv3Gjcxk1HoInFDyL14M41hU7aC9evyWGZQ/$4MOZVD4F5_BMRwWv6GjsfrCTPqJlmrFZ7qxIhtSapzU
;; and https://matrix.to/#/!BkPDqaI4Qv3Gjcxk1HoInFDyL14M41hU7aC9evyWGZQ/$hdhNbB8kOl5kOYghNwaudGVbk1JlnqCWlbB8lS2bgXo
(defparameter *magic-owner-item-id* "63ad2e58eecdd9e5")

(defun get-site-owner (wiki)
  (wait-for-sitemap wiki)
  (or (owner-of wiki)
      (when-let (welcome-page (hb:find-page wiki "welcome-visitors"))
        (load-page welcome-page)
        (when-let (item (find *magic-owner-item-id*
                              (story-of welcome-page)
                              :test #'equal :key #'id-of))
          (let (owner)
            (process-text-and-links (text-of item) welcome-page
                                    #'(lambda (chunk page)
                                        (declare (ignore chunk page))
                                        nil)
                                    #'(lambda (chunk page)
                                        (declare (ignore page))
                                        (unless owner
                                          (setf owner (str:substring 2 -2 chunk)))))
            (setf (slot-value wiki 'owner) owner)
            owner)))))

;; (defun make-links (page link-slugs)
;;   (format t "Page: ~A~%" (hb:id-of page))
;;   (format t "Link slugs: ~A~%" link-slugs)
;;   (unless (hb:links-of page)
;;     (make-instance 'wiki-links
;;                    :wiki-links (loop for slug in link-slugs
;;                                      collect (make-wiki-link
;;                                               page :target-slug slug)))))

;;
;; Global register of visited FedWiki sites
;; stored as a mapping from domain name to fedwiki object
;;

(defvar *neighborhood* (make-hash-table :test #'equal))

(defun get-fedwiki (domain-name &optional signal-error? wait-for-sitemap?)
  (declare (ignore signal-error?))
  (let ((wiki (if-let (wiki (gethash domain-name *neighborhood*))
                wiki
                (setf (gethash domain-name *neighborhood*)
                      (make-fedwiki domain-name)))))
    (when wait-for-sitemap?
      (wait-for-sitemap wiki))
    wiki))

;;
;; Page lookup
;;

(defmethod hb:find-page ((wiki fedwiki) id  &key signal-error?)
  (wait-for-sitemap wiki)
  (or (gethash id (pages-of wiki))
      (and (remote-page-id? id)
           (get-remote-page wiki id))
      (and signal-error?
           (error 'hb:page-lookup-failure :hyperbook wiki :page-id id))))

(defun wait-for-sitemap (wiki)
  (let ((status (status-of wiki)))
    (when (typep status 'bt:thread)
      (bt:join-thread status))))

;;
;; Main page
;;

(views:defview 👀main-page (wiki fedwiki)
  (when-let (main-page (hb:find-page wiki "welcome-visitors"))
    (-> main-page
      👀story
      (views:rename :title "Main page" :priority 1))))

;;
;; Register a HyperBook factory
;;

(hb:register-scheme :fedwiki #'get-fedwiki)
