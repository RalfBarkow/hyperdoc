;;;; HyperBook interface to Wikipedia
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/wikipedia)

;;
;; Implementation of the HyperBook interface
;;

(defclass wikipedia (hb:hyperbook)
  ((edition :reader edition-of :type keyword :initarg :edition
            :documentation "Edition code")
   (title :reader hb:title-of :type string :initarg :title)
   (main-page-id :reader hb:main-page-id-of :type string :initarg :main-page)))

(defclass wikipedia-page (hb:page)
  ((title :reader hb:title-of :type string :initarg :title)
   (page-data :reader page-data-of :type string :initarg :page-data)
   (dom :reader hb:dom-of :type plump:node :initarg :dom)))

(defmethod hb:find-page ((wp wikipedia) id  &key signal-error?)
  (declare (ignore signal-error?))
  (make-page wp id))

(defun make-page (wp id)
  (make-instance 'wikipedia-page
                 :hyperbook wp
                 :id id
                 :title id
                 :page-data nil
                 :dom nil))

(defun load-page (page)
  (unless (hb:dom-of page)
    (let* ((wp (hb:hyperbook-of page))
           (id (hb:id-of page))
           (page-data (get-page-data wp id))
           (dom (make-dom page-data)))
      (adapt-dom dom id)
      (setf (slot-value page 'dom) dom)
      (setf (slot-value page 'page-data) page-data))))

(defmethod views:👀content ((page wikipedia-page))
  (load-page page)
  (call-next-method))

(defun adapt-dom (dom page-title)
  ;; Remove the links for editing each section
  (lquery:$ dom ".mw-editsection"
    (remove))
  ;; Remove style nodes
  (lquery:$ dom "style"
    (remove))
  ;; Replace internal Wikipedia links by HyperBook links
  (lquery:$ dom "a[href^=/wiki/]"
    (map #'(lambda(el)
             (let* ((href (plump:get-attribute el "href"))
                    (page-id (str:replace-all
                              "_" " "
                              (str:substring 6 nil href))))
               (unless (or (str:starts-with? "Special:" page-id)
                           (str:starts-with? "File:" page-id))
                 (plump:set-attribute el "page" page-id) 
                 (plump:remove-attribute el "href")
                 (plump:remove-attribute el "title"))))))
  ;; Add the page title
  (lquery:$ dom ".mw-parser-output"
    (before (format nil "<h1>~A</h1>" page-title))))

(defun make-dom (page-data)
  (if-let (error (gethash "error" page-data))
    (plump:parse (format nil "<span class=\"hyperbook-error\">~A</span>"
                         (gethash "info" error)))
    (some->> page-data
      (gethash "parse")
      (gethash "text")
      (gethash "*")
      (plump:parse))))

(defun get-page-data (wp page-title)
  (let* ((url (format nil "https://~A.wikipedia.org/w/api.php"
                      (-> wp edition-of str:downcase)))
         (response
           (multiple-value-list
            (drakma:http-request url
                                 :method :get
                                 :parameters `(("action" . "parse")
                                               ("page" . ,page-title)
                                               ("format" . "json"))
                                 :want-stream t)))
         (stream (first response)))
    (shasht:read-json stream)))

;;
;; Make and manage wikipedia objects
;;

(defvar *wikipedias* (make-hash-table))

(defun make-wikipedia (edition title main-page)
  (assert (eq (type-of edition) 'keyword))
  (let ((id (str:concat "wikipedia-" (-> edition symbol-name str:downcase))))
    (setf (gethash edition *wikipedias*)
          (make-instance 'wikipedia
                         :id id
                         :edition edition
                         :title title
                         :main-page main-page))
    (hb:register (gethash edition *wikipedias*))
    (gethash edition *wikipedias*)))

;; It should be possible to retrieve a complete list from
;; https://en.wikipedia.org/wiki/List_of_Wikipedias
(defparameter *editions*
  '((:de "Wikipedia" "Hauptseite")
    (:en "Wikipedia" "Main page")
    (:es "Wikipedia" "Portada")
    (:fr "Wikipédia" "Accueil principal")
    (:it "Wikipedia" "Pagina principale")))

(defun request-wikipedia (edition)
  (or (gethash edition *wikipedias*)
      (let ((wp-spec (assoc edition *editions*)))
        (make-wikipedia edition (second wp-spec) (third wp-spec)))))

;;
;; URLs
;;

;; The mobile site is better adapted to inspector panes
(defun page-url (edition page-title)
  (format nil
          "https://~A.m.wikipedia.org/wiki/~A"
          (-> edition symbol-name str:downcase)
          (-> page-title encode-page-title-for-url)))

(defun encode-page-title-for-url (page-title)
  (str:replace-all " " "_" page-title))

;;
;; Views
;;

(defmethod views:text-representation ((wp wikipedia))
  (-> wp hb:title-of))

(defmethod views:text-representation ((page wikipedia-page))
  (-> page hb:title-of))

(views:defview 👀iframe (page wikipedia-page)
  (views:html-view :title "IFrame" :priority 2
    (views:html
      (:iframe :src (page-url (-> page hb:hyperbook-of edition-of)
                              (-> page hb:title-of))
               :title (-> page hb:title-of)
               :style "border:none;width:100%;height:100%" ))))

(views:defview views:👀source (page wikipedia-page)
  (views:html-view :title "Source" :priority 10
    (let* ((url (format nil "https://~A.wikipedia.org/w/api.php"
                      (-> page hb:hyperbook-of edition-of str:downcase)))
           (stream (drakma:http-request
                    url
                    :method :get
                    :parameters `(("action" . "parse")
                                  ("page" . ,(-> page hb:id-of
                                                 encode-page-title-for-url))
                                  ("prop" . "wikitext")
                                  ("format" . "json"))
                    :want-stream t))
           (data (shasht:read-json stream))
           (wikitext (some->> data
                       (gethash "parse")
                       (gethash "wikitext")
                       (gethash "*"))))
      (when wikitext
        (views:html
          (:pre (views:esc wikitext)))))))

(views:defview 👀parse-tree (page wikipedia-page)
  (let* ((url (format nil "https://~A.wikipedia.org/w/api.php"
                      (-> page hb:hyperbook-of edition-of str:downcase)))
         (stream (drakma:http-request
                  url
                  :method :get
                  :parameters `(("action" . "parse")
                                ("page" . ,(-> page hb:id-of
                                               encode-page-title-for-url))
                                ("prop" . "parsetree")
                                ("format" . "json"))
                  :want-stream t))
         (data (shasht:read-json stream))
         (dom (some->> data
                (gethash "parse")
                (gethash "parsetree")
                (gethash "*")
                (plump:parse))))
    (when dom
      (some-> dom
        (plump:get-elements-by-tag-name  "root")
        (first)
        (plump-inspector-views::👀children)
        (views:rename :title "Parse tree" :priority 11)))))

;;
;; Links and backlinks
;;

(defmethod hb:links-of ((page wikipedia-page))
  ;; TODO
  nil)

(defmethod hb:find-link-sources ((wp wikipedia) hyperbook-id page-id)
  ;; TODO
  nil)
