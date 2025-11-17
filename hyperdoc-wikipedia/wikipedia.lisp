;;;; HyperDoc interface to Wikipedia
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc/wikipedia)

;;
;; Implementation of the abstract HyperDoc interface
;;

(defclass wikipedia (hyperdoc:abstract-hyperdoc)
  ((edition :reader edition-of :type keyword :initarg :edition
            :documentation "Edition code")
   (title :reader title-of :type string :initarg :title)
   (main-page :reader main-page-of :type string :initarg :main-page)))

(defclass wikipedia-page (hyperdoc:abstract-page)
  ((wikipedia :reader wikipedia-of :type wikipedia :initarg :wikipedia)
   (title :reader title-of :type string :initarg :title)))

(defmethod hyperdoc:find-page ((wp wikipedia) title  &key signal-error?)
  (make-instance 'wikipedia-page
                 :wikipedia wp
                 :title title))

(defmethod hyperdoc:entry-of ((wp wikipedia))
  (hyperdoc:find-page wp (main-page-of wp)))

(defmethod hyperdoc:title-of ((wp wikipedia))
  (title-of wp))

;;
;; Make and manage wikipedia objects
;;

(defvar *wikipedias* (make-hash-table))

(defun make-wikipedia (edition title main-page)
  (assert (eq (type-of edition) 'keyword))
  (let* ((edition-name (symbol-name edition))
         (id (alexandria:make-keyword (str:concat "WIKIPEDIA-" edition-name))))
    (setf (gethash edition *wikipedias*)
          (make-instance 'wikipedia
                         :id id
                         :edition edition
                         :title title
                         :main-page main-page))
    (hyperdoc:register (gethash edition *wikipedias*))))

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
  (-> wp title-of))

(defmethod views:text-representation ((page wikipedia-page))
  (-> page title-of))

(views:defview views:👀content (page wikipedia-page)
  (views:html-view :title "Content" :priority 1
    (views:html
      (:iframe :src (page-url (-> page wikipedia-of edition-of)
                              (-> page title-of))
               :title (-> page title-of)
               :style "border:none;width:100%;height:100%" ))))

(views:defview views:👀content (wp wikipedia)
  (let ((entry (hyperdoc:entry-of wp)))
    (views:rename (views:👀content entry)
                  :title (title-of entry)
                  :priority 1)))

(views:defview views:👀source (page wikipedia-page)
  (views:html-view :title "Source" :priority 3
    (let* ((stream (drakma:http-request "https://en.wikipedia.org/w/api.php"
                                        :method :get
                                        :parameters `(("action" . "parse")
                                                      ("page" . ,(-> page title-of
                                                                   encode-page-title-for-url))
                                                      ("prop" . "wikitext")
                                                      ("format" . "json"))
                                        :want-stream t))
           (data (shasht:read-json stream))
           (wikitext (->> data
                       (gethash "parse")
                       (gethash "wikitext")
                       (gethash "*"))))
      (views:html
        (:pre (views:esc wikitext))))))

(views:defview 👀parse-tree (page wikipedia-page)
  (let* ((stream (drakma:http-request "https://en.wikipedia.org/w/api.php"
                                      :method :get
                                      :parameters `(("action" . "parse")
                                                    ("page" . ,(-> page title-of
                                                                 encode-page-title-for-url))
                                                    ("prop" . "parsetree")
                                                    ("format" . "json"))
                                      :want-stream t))
         (data (shasht:read-json stream)))
    (-<> data
      (gethash "parse" <>)
      (gethash "parsetree" <>)
      (gethash "*" <>)
      (plump:parse)
      (plump:get-elements-by-tag-name <> "root")
      (first)
      (plump-inspector-views::👀children)
      (views:rename :title "Parse tree" :priority 5))))
