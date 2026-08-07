;;;; Rendering DOM trees
;;
;;;; Copyright (c) 2025-2026 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperbook)

;; A generic function for retrieving the DOM tree to be rendered

(defgeneric dom-of (page)
  (:method ((page page))
    nil))

;; The tags with special treatment in serialization

(defvar *hyperbook-tags* plump:*html-tags*)

;; Special variables holding the current page and hyperbook

(defvar *current-page* nil)
(defvar *current-hyperbook* nil)

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
        (href-attr (plump:attribute element "href"))
        (render-children (let ((children (plump:children element)))
                           (unless (zerop (length children))
                             (make-instance 'html-nodes
                                            :nodes children)))))
    (when-let (hb-link (and href-attr
                            (replace-by-hyperbook-link href-attr)))
      ;; Replace Web link by HyperBook link
      (setf href-attr nil)
      (when (consp hb-link)
        (setf hyperbook-attr (first hb-link))
        (setf page-attr (second hb-link))))
    (cond
      (page-attr
       (let ((hyperbook-id (or hyperbook-attr
                               (-> *current-hyperbook* id-of))))
         (render-hyperbook-page-link hyperbook-id page-attr render-children))
       t)
      (hyperbook-attr
       (render-hyperbook-link hyperbook-attr render-children)
       t)
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

(defun render-hyperbook-link (hyperbook-id link-text)
  (handler-case
      (let ((hyperbook (find-hyperbook hyperbook-id :signal-error? t)))
        (views:html
          (:span :class "hyperbook-reference"
                 :title (format nil "HyperBook \"~A\""
                                (cl-who:escape-string hyperbook-id))
                 (views:object-ref hyperbook
                                   :display link-text))))
    (lookup-failure (c)
      (views:html
        (:span :class "hyperbook-reference hyperbook-error"
               (views:object-ref c :display link-text)))))  )

(defun render-hyperbook-page-link (hyperbook-id page-id link-text)
  (handler-case
      (let* ((hyperbook (find-hyperbook hyperbook-id :signal-error? t))
             (page (find-page hyperbook page-id :signal-error? t)))
        (views:html
          (:span :class "hyperbook-reference"
                 :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                                (cl-who:escape-string page-id)
                                (cl-who:escape-string (title-of hyperbook)))
                 (views:object-ref page
                                   :display link-text))))
    (lookup-failure (c)
      (views:html
        (:span :class "hyperbook-reference hyperbook-error"
               (views:object-ref c :display link-text))))))

(defun render-hyperbook-or-page-link (hyperbook-id page-id link-text)
  (if page-id
      (render-hyperbook-page-link hyperbook-id page-id link-text)
      (render-hyperbook-link hyperbook-id link-text)))

(defgeneric serialize-a-element (attrs element)
  (:method ((attrs t) element)
    (render-node element)))

;;
;; Content view for pages
;;

(defgeneric serialize-page-dom (page)
  (:method ((page page))
    (plump:serialize (dom-of page) views::*html-stream*)))

(defun collect-assets (assets)
  (let ((inherit (inherit-of (first assets))))
    (if inherit
        (cons inherit assets)
        assets)))

(defun collect-tag-dispatchers (all-assets)
  (loop for assets in all-assets
        for dispatcher-ref = (tag-dispatchers-of assets)
        append (if (symbolp dispatcher-ref)
                   (symbol-value dispatcher-ref)
                   dispatcher-ref)))

(views:defview views:👀content (page page)
  (when-let (dom (dom-of page))
    (let* ((page-assets (html-page-assets-of page))
           (all-assets (reverse (collect-assets (list page-assets)))))
      (views:html-view :title "Content" :priority 1
        (loop for assets in all-assets do
          (loop for (url . filename) in (paths-of assets)
                do (views:add-asset-path url filename))
          (loop for filename in (css-of assets)
                do (views:include-css filename))
          (loop for filename in (js-of assets)
                do (views:include-js filename)))
        (let* ((*current-page* page)
               (*current-hyperbook* (hyperbook-of page)))
          (views:html
            (:div :class "hyperbook-page"
                  (let ((plump:*tag-dispatchers* (collect-tag-dispatchers
                                                  all-assets)))
                    (serialize-page-dom page))
                  (:br))))))))
