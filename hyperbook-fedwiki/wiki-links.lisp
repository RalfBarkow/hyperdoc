;;;; Wiki links
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

(defclass wiki-link (hb:object-link)
  ((target-title :reader target-title-of :type (or null string) :initarg :target-title)
   (target-slug :reader target-slug-of :type string :initarg :target-slug)))

(defmethod hb:key-of ((link wiki-link))
  (target-slug-of link))

(defun make-wiki-link (source-page &key target-title target-slug)
  (make-instance 'wiki-link
                 :source-hyperbook (-> source-page hb:hyperbook-of hb:id-of)
                 :source-page (-> source-page hb:id-of)
                 :target-title target-title
                 :target-slug target-slug
                 :thunk (views:thunk
                          (handler-case
                              (find-target-by-slug target-slug source-page)
                            (error (c) c)))))

(defclass fedwiki-links (hb:links)
  ((wiki-links :reader wiki-links-of :initarg :wiki-links :initform nil)))

(defmethod wiki-links-of ((links null))
  nil)

(defmethod hb:no-links? ((links fedwiki-links))
  (and (null (wiki-links-of links))
       (call-next-method)))

;;
;; Resolve a Wiki link, i.e. a slug in the context of a page
;;

(defun lookup-slug-in-page-context (slug page)
  (let ((wiki (hb:hyperbook-of page)))
    (or (hb:find-page wiki slug)
        (get-plugin-page wiki slug)
        (loop for remote in (context-of page)
              for page = (hb:find-page remote slug)
              when page
                return (make-remote wiki page)))))

(defun make-remote (wiki page-on-remote-wiki)
  (let* ((remote-wiki (hb:hyperbook-of page-on-remote-wiki))
         (page-id (str:concat (domain-name-of remote-wiki)
                              "/"
                              (hb:id-of page-on-remote-wiki)))
         (title (hb:title-of page-on-remote-wiki))
         (remote-page (get-remote-page wiki page-id title)))
    (setf (slot-value remote-page 'story)
          (story-of page-on-remote-wiki))
    (setf (slot-value remote-page 'journal)
          (journal-of page-on-remote-wiki))
    (setf (slot-value remote-page 'context)
          (cons remote-wiki (context-of page-on-remote-wiki)))
    remote-page))

;; The JavaScript function for computing slugs is:
;;
;; const asSlug = name =>
;;   name
;;     .replace(/\s/g, '-')
;;     .replace(/[^A-Za-z0-9-]/g, '')
;;     .toLowerCase()

(defun slug (title)
  (-<> title
    (cl-ppcre:regex-replace-all "\\s" <> "-")
    (cl-ppcre:regex-replace-all "[^A-Za-z0-9-]" <> "")
    str:downcase))

(define-condition wiki-lookup-failure (hb:lookup-failure)
  ((title :initarg :title :type string)
   (slug :initarg :slug :type string)))

(defun find-target-by-title (title page)
  (or (lookup-slug-in-page-context (slug title) page)
      (error 'wiki-lookup-failure
             :title title
             :slug (slug title))))

(defun find-target-by-slug (slug page)
  (or (lookup-slug-in-page-context slug page)
      (error 'wiki-lookup-failure :slug slug)))

;;
;; Find backlinks
;;

(defmethod hb:find-link-sources ((target fedwiki) hyperbook-id page-id)
  (loop for page being the hash-values of (pages-of target)
        append (hb:find-link-sources page hyperbook-id page-id)))

(defmethod hb:find-link-sources ((target fedwiki-page) hyperbook-id page-id)
  (when (str:starts-with? "fedwiki:" hyperbook-id)
    (loop for link in (-> target hb:links-of wiki-links-of)
          when (equal page-id (target-slug-of link))
            collect target)))
;;
;; Link view
;;

(views:defview 👀links (links fedwiki-links)
  (views:html-view :title "Links" :priority 10
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:html
      (:div :class "hyperbook-page"
            (when-let (wlinks (wiki-links-of links))
              (views:html
                (:h2 (views:esc "Wiki links"))
                (:table :class "inspector-table"
                        (dolist (link wlinks)
                          (let ((text (or (target-title-of link)
                                          (target-slug-of link)))
                                (target (-> link hb:thunk-of views:eval-thunk)))
                            (views:html
                              (:tr (:td (views:object-ref target :display text)))))))))
            (views:transclusion (hb::👀links links))))))
