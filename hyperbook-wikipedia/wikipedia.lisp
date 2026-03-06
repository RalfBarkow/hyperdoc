;;;; HyperBook interface to Wikipedia
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook/wikipedia)

;;
;; Implementation of the HyperBook interface
;;

(defclass wikipedia (hb:hyperbook)
  ((edition :reader edition-of :type string :initarg :edition
            :documentation "Edition code")
   (title :reader hb:title-of :type string :initarg :title)
   (main-page-id :reader hb:main-page-id-of :type string :initarg :main-page)))

(defclass wikipedia-page (hb:page)
  ((title :reader hb:title-of :type string :initarg :title)
   (page-data :reader page-data-of :type string :initarg :page-data)
   (wikipedia-pageid :reader wikipedia-pageid-of :type integer :initform 0)
   (dom :reader hb:dom-of :type (or null plump:node) :initform nil)
   (links :reader hb:links-of :type (or null hb:links) :initform nil)))

(defmethod hb:find-page ((wp wikipedia) id  &key signal-error?)
  (declare (ignore signal-error?))
  (get-page wp id))

;;
;; Pages are created as empty stubs, their content is loaded only when
;; needed by a view. This is done because (1) find-page is called
;; whenever a link is processed, even if the user never follows that
;; link, and (2) loading the HTML content of a Wikipedia page is
;; rather slow. For the same reason, pages are cached and kept for a
;; day.
;;

(defvar *page-cache* nil)

(defparameter *page-cache-retention-delay* (* 24 60 60))

(defclass page-cache ()
  ((pages :reader pages-of :initarg :pages :type hash-table)
   (timestamps :reader timestamps-of :initarg :timestamps :type hash-table)))

(defun ensure-page-cache ()
  (unless *page-cache*
    (setf *page-cache* (make-instance 'page-cache
                                      :pages (make-hash-table :test #'equal)
                                      :timestamps (make-hash-table :test #'equal)))))

(defun purge-page-cache ()
  (let ((now (get-universal-time)))
    (loop for id being the hash-keys
            using (hash-value ts)
              of (timestamps-of *page-cache*)
          do (when (> (- now ts) *page-cache-retention-delay*)
               (remhash id (timestamps-of *page-cache*))
               (remhash id (pages-of *page-cache*))))))

(defun get-page (wp id)
  (ensure-page-cache)
  (purge-page-cache)
  (when-let (page (gethash id (pages-of *page-cache*)))
    (return-from get-page page))
  (let ((page (make-instance 'wikipedia-page
                             :hyperbook wp
                             :id id
                             :title id)))
    (setf (gethash id (pages-of *page-cache*)) page)
    (setf (gethash id (timestamps-of *page-cache*)) (get-universal-time))
    page))

(defun load-page (page)
  (unless (hb:dom-of page)
    (let* ((wp (hb:hyperbook-of page))
           (id (hb:id-of page))
           (page-data (get-page-data wp id))
           (dom (make-dom page-data)))
      (adapt-dom dom (hb:hyperbook-of page) id)
      (setf (slot-value page 'dom) dom)
      (setf (slot-value page 'wikipedia-pageid)
            (some->> page-data
              (gethash "parse")
              (gethash "pageid")))
      (setf (slot-value page 'links) (hb:extract-links page))
      (setf (slot-value page 'page-data) page-data))))

;;
;; Views
;;

(defmethod views:👀content ((page wikipedia-page))
  (load-page page)
  (call-next-method))

(defmethod hb:👀links ((page wikipedia-page))
  (load-page page)
  (call-next-method))

(defun adapt-dom (dom wikipedia page-title)
  ;; Remove the links for editing each section
  (lquery:$ dom ".mw-editsection"
    (remove))
  ;; Remove style nodes
  (lquery:$ dom "style"
    (remove))
  ;; Replace internal Wikipedia links by HyperBook links
  (lquery:$ dom "a[href^=/wiki/]"
    (map #'(lambda (el)
             (let* ((href (plump:get-attribute el "href"))
                    (page-id (str:replace-all
                              "_" " "
                              (str:substring 6 nil href))))
               (unless (or (str:starts-with? "Special:" page-id)
                           (str:starts-with? "File:" page-id))
                 (plump:set-attribute el "page" page-id) 
                 (plump:remove-attribute el "href")
                 (plump:remove-attribute el "title"))))))
  ;; Add Wikipedia base URL to the remaining internal links
  (lquery:$ dom "a[href^=/wiki/]"
    (map #'(lambda (el)
             (let ((href (plump:get-attribute el "href")))
               (plump:set-attribute el "href"
                                    (str:concat (base-url wikipedia)
                                                href))
               (plump:set-attribute el "target" "_blank")))))
  ;; Remove links to anchors inside the page, replace by hover text
  (let ((root (plump:make-root)))
    (lquery:$ dom "a[href^=#]"
      (map #'(lambda (el)
               (let* ((html-id (str:substring 1 nil (plump:get-attribute el "href")))
                      (target (plump:get-element-by-id dom html-id))
                      (target-text (or (and target (plump:text target)) ""))
                      (text (plump:text el))
                      (span (plump:make-element root "span")))
                 (plump:set-attribute span "title" target-text)
                 (plump:make-text-node span text)
                 (plump:replace-child el span))))))
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
  (let* ((response
           (multiple-value-list
            (drakma:http-request (api-url wp)
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

(defvar *wikipedias* (make-hash-table :test #'equal))

(defun make-wikipedia (edition title main-page)
  (assert (typep edition 'string))
  (let* ((ed-code (-> edition str:downcase))
         (id (str:concat "wikipedia:" ed-code))
         (wp (make-instance 'wikipedia
                            :id id
                            :edition ed-code
                            :title title
                            :main-page main-page)))
    (setf (gethash edition *wikipedias*) wp)
    (hb:register wp)
    wp))

;; It should be possible to retrieve a complete list from
;; https://en.wikipedia.org/wiki/List_of_Wikipedias, but
;; there doesn't seem to be a uniform way to obtain the
;; name of the main page.

(defparameter *editions*
  '(("de" "Wikipedia" "Wikipedia:Hauptseite")
    ("en" "Wikipedia" "Main Page")
    ("es" "Wikipedia" "Wikipedia:Portada")
    ("fr" "Wikipédia" "Wikipédia:Accueil principal")
    ("it" "Wikipedia" "Pagina principale")))

(defun get-wikipedia (edition &optional signal-error?)
  (declare (ignore signal-error?))
  (let ((ed-code (str:downcase edition)))
    (or (gethash ed-code *wikipedias*)
        (when-let (wp-spec (assoc ed-code *editions* :test #'equal))
          (make-wikipedia edition (second wp-spec) (third wp-spec))))))

;; Register a HyperBook factory and a link redirection for Wikipedia links

(hb:register-scheme :wikipedia #'get-wikipedia)

(hb:register-link-redirection 'wikipedia-link-redirection)

;;
;; URLs
;;

(defun base-url (wikipedia)
  (format nil "https://~A.wikipedia.org"
          (-> wikipedia edition-of)))

(defun page-url (page)
  (let ((edition (-> page hb:hyperbook-of edition-of))
        (page-title (-> page hb:title-of)))
    (format nil
            "https://~A.wikipedia.org/wiki/~A"
            edition
            (-> page-title encode-page-title-for-url))))

(defun encode-page-title-for-url (page-title)
  (str:replace-all " " "_" page-title))

(defun api-url (wikipedia)
  (format nil "https://~A.wikipedia.org/w/api.php"
          (-> wikipedia edition-of)))

(defun wikipedia-link-redirection (url)
  (let* ((uri (puri:parse-uri url))
         (host (puri:uri-host uri))
         (host-parts (str:split "." host))
         (path (puri:uri-path uri))
         (path-parts (str:split "/" path)))
    (when (and (= 3 (length host-parts))
               (equal "wikipedia" (second host-parts))
               (equal "org" (third host-parts))
               (= 3 (length path-parts))
               (equal "" (first path-parts))
               (equal "wiki" (second path-parts)))
      (let* ((ed-code (first host-parts))
             (hyperbook-id (str:concat "wikipedia:" ed-code))
             (page-name (third path-parts))
             (page-id (str:replace-all "_" " " page-name)))
        (list hyperbook-id page-id)))))

;;
;; Views
;;

(defmethod views:text-representation ((wp wikipedia))
  (-> wp hb:title-of))

(defmethod views:text-representation ((page wikipedia-page))
  (-> page hb:title-of))

(defmethod views:title-bar-action-buttons ((page wikipedia-page))
  (views:action-button "Open in browser"
                       (views:thunk (clog:open-browser :url (page-url page))
                         nil)))

(views:defview views:👀source (page wikipedia-page)
  (views:html-view :title "Source" :priority 10
    (let* ((stream (drakma:http-request
                    (-> page hb:hyperbook-of api-url)
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
  (let* ((stream (drakma:http-request
                  (-> page hb:hyperbook-of api-url)
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


(defmethod hb:find-link-sources ((wp wikipedia) hyperbook-id page-id)
  ;; We are not interested in links between different Wikipedia
  ;; instances (editions), and the API wouldn't allow to retrieve
  ;; them anyway. Therefore HYPERBOOK-ID must match the wikipedia
  ;; instance, and PAGE-ID must be non-nil.
  (when (and (equal (hb:id-of wp) hyperbook-id)
             page-id)
    (let* ((stream (drakma:http-request
                    (-> wp api-url)
                    :method :get
                    :parameters `(("action" . "query")
                                  ("list" . "backlinks")
                                  ("bltitle" . ,page-id)
                                  ("bllimit" . "500")
                                  ("format" . "json"))
                    :want-stream t))
           (data (shasht:read-json stream))
           (links (some->> data
                    (gethash "query")
                    (gethash "backlinks"))))
      (loop for link across links
            when (zerop (gethash "ns" link))
              collect (hb:find-page wp (gethash "title" link))))))
