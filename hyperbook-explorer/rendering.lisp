;;;; Rendering DOM trees
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;; A generic function for retrieving the DOM tree to be rendered

(defgeneric dom-of (page)
  (:method ((page page))
    nil))

;; The tags with special treatment in serialization

(defvar *hyperbook-tags* plump:*html-tags*)

;; A special variable holding the current page

(defvar *current-page* nil)

;; A container for HTML nodes to be rendered

(defclass html-nodes ()
  ((nodes :accessor nodes-of :initarg :nodes)))

;; ... and its rendering function.

(defmethod views:html-representation ((nodes html-nodes) &optional id)
  (views:html
    (:span :id id
           (loop for node across (nodes-of nodes)
                 do (plump:serialize-object node)))))

(defun render-node (node)
  (views:html
    (views:str "<")
    (views:str (plump:tag-name node))
    (plump:serialize (plump:attributes node) views::*html-stream*)
    (if (< 0 (length (plump:children node)))
        (progn
          (views:str ">")
          (loop for child across (plump:children node)
                do (plump:serialize-object child))
          (views:str "</")
          (views:str (plump:tag-name node))
          (views:str ">"))
        (views:str "/>"))))

;; Plump extension for rendering links

(plump:define-tag-dispatcher (a *hyperbook-tags*) (name)
  (string-equal name "a"))

(plump:define-tag-printer a (element)
  (let ((hyperbook-attr (plump:attribute element "hyperbook"))
        (page-attr (plump:attribute element "page"))
        (view-attr (plump:attribute element "view"))
        (href-attr (plump:attribute element "href"))
        (text (plump:text element))
        (render-children (let ((children (plump:children element)))
                           (unless (zerop (length children))
                             (make-instance 'html-nodes
                                            :nodes children)))))
    (cond
      (page-attr
       (handler-case
           (let* ((hyperbook (or (and hyperbook-attr
                                      (find-hyperbook hyperbook-attr))
                                 (-> *current-page*
                                     hyperbook-of)))
                  (page (find-page hyperbook page-attr :signal-error? t)))
             (views:html
               (:span :class "hyperbook-reference"
                      :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                                     (cl-who:escape-string page-attr)
                                     (cl-who:escape-string (title-of hyperbook)))
                      (views:object-ref page
                                        :display render-children
                                        :select view-attr))))
         (lookup-failure (c)
           (views:html
             (:span :class "hyperbook-reference hyperbook-error"
                    (views:object-ref c :display render-children)))))
       t)
      (hyperbook-attr
       (handler-case
           (let ((hyperbook (find-hyperbook hyperbook-attr :signal-error? t)))
             (views:html
               (:span :class "hyperbook-reference"
                      :title (format nil "HyperBook \"~A\""
                                     (cl-who:escape-string hyperbook-attr))
                      (views:object-ref hyperbook
                                        :display render-children
                                        :select view-attr))))
         (lookup-failure (c)
           (views:html
             (:span :class "hyperbook-reference hyperbook-error"
                    (views:object-ref c :display text))))))
      (href-attr
       ;; Force target="_blank" for href links
       (views:html
         (:a :href href-attr :target "_blank"
             (loop for child across (plump:children element)
                   do (plump:serialize child plump:*stream*)))))
      (t
       ;; Nonstandard links, i.e. neither hrefs nor HyperBook links.
       ;; Provide a generic function for extensions, with dispatch
       ;; on the elements attribute names.
       (let* ((attrs (sort (-> element plump:attributes alexandria:hash-table-keys)
                           #'string<))
              (kw (alexandria:make-keyword 
                   (str:upcase (str:join "." attrs)))))
         (serialize-a-element kw element)))))
  t)

(defgeneric serialize-a-element (attrs element)
  (:method ((attrs t) element)
    (render-node element)))

;;
;; Content view for pages
;;

(views:defview views:👀content (page page)
  (when-let (dom (dom-of page))
    (views:html-view :title "Content" :priority 1
      (views:add-asset-path "/hyperbook/"
                            (asdf:system-relative-pathname
                             :hyperbook
                             "assets/hyperbook/"))
      (views:include-css "/hyperbook/css/hyperbook.css")
      (let ((*current-page* page))
        (views:html
          (:div :class "hyperbook-page"
                (let ((plump:*tag-dispatchers* *hyperbook-tags*))
                  (plump:serialize dom views::*html-stream*))
                (:br)))))))
