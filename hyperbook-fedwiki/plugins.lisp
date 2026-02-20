;;;; Plugins
;;
;;;; Copyright (c) 2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/fedwiki)

;;
;; Plugins and their pages
;;

(defclass fedwiki-plugin ()
  ((wiki :reader wiki-of :initarg :wiki
         :type fedwiki)
   (name :reader name-of :initarg :name
         :type string)
   (pages :reader pages-of :initform (make-hash-table :test #'equal)
          :type hash-table)
   (plugmatic-data :reader plugmatic-data-of :initform nil
                   :type (or null hash-table))))

(defclass fedwiki-plugin-page (fedwiki-page)
  ((plugin :reader plugin-of :type fedwiki-plugin :initarg :plugin)))

;;
;; Retrieve plugin data from the server
;;

(defun fetch-plugin-data (wiki)
  (let* ((plugin-url (wiki-url (domain-name-of wiki)
                               "/system/plugins.json"))
         (plugin-names (fetch-json plugin-url))
         (sorted-plugin-names (sort plugin-names #'string<)))
    (loop for pn across sorted-plugin-names
          do (setf (gethash pn (plugins-of wiki))
                   (make-instance 'fedwiki-plugin :wiki wiki :name pn)))
    (when (find "plugmatic" sorted-plugin-names :test #'equal)
      (fetch-plugmatic-info wiki))))

(defun fetch-plugmatic-info (wiki)
  (let ((plugin-data (->> "/plugin/plugmatic/plugins"
                       (wiki-url (domain-name-of wiki))
                       fetch-json
                       (gethash "install"))))
    (loop for p across plugin-data
          for plugin-name = (gethash "plugin" p)
          for plugin = (gethash plugin-name (plugins-of wiki))
          for pages = (gethash "pages" p)
          when plugin
            do (loop for page across pages
                     do (let* ((slug (gethash "slug" page))
                               (title (gethash "title" page))
                               (page (make-instance 'fedwiki-plugin-page
                                                    :hyperbook wiki
                                                    :id title
                                                    :plugin plugin)))
                          (setf (gethash title (pages-of wiki)) page)
                          (setf (gethash slug (slugs-of wiki)) title)
                          (setf (gethash title (slugs-of wiki)) slug)
                          (setf (gethash title (pages-of plugin)) page)))
               (remhash "pages" p)
               (setf (slot-value plugin 'plugmatic-data) p))))

;;
;; Manage plugin pages
;;

(defun load-plugin-pages (plugin)
  (when (zerop (hash-table-count (pages-of plugin)))
    (get-plugin-about-page (wiki-of plugin) plugin)))

(defun get-plugin-page (wiki slug)
  (if-let (page-id (gethash slug (slugs-of wiki)))
    (gethash page-id (pages-of wiki))
    (handler-case
        (let* ((json (fetch-page-json (domain-name-of wiki) slug))
               (title (gethash "title" json))
               (page (make-instance 'fedwiki-plugin-page
                                    :hyperbook wiki
                                    :id slug)))
          (set-page-data page json)
          (setf (gethash title (pages-of wiki))
                page)
          (setf (gethash slug (slugs-of wiki))
                title)
          (setf (gethash title (slugs-of wiki))
                slug)
          page)
      ;; For missing pages, the server returns
      ;; "Page not found", for which shasht raises
      ;; an error because it is not valid JSON.
      (shasht:shasht-invalid-char (c)
        (declare (ignore c))
        nil))))

(defun get-plugin-about-page (wiki plugin)
  (let* ((slug (str:concat "about-" (name-of plugin) "-plugin"))
         (page (get-plugin-page wiki slug)))
    (when page
      (setf (slot-value page 'plugin) plugin)
      (setf (gethash (hb:id-of page) (pages-of plugin))
            page))
    page))

