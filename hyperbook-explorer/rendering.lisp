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
(defvar *link-target-rewriters* nil)

(defun register-link-target-rewriter (hook)
  "Register HOOK to rewrite HyperBook link targets before rendering.
HOOK may return three values: new hyperbook id, new page id, and a handled flag."
  (pushnew hook *link-target-rewriters* :test #'equal))

(defun rewrite-link-target (hyperbook-id page-id &key element link-text)
  (loop with current-hyperbook = hyperbook-id
        with current-page-id = page-id
        for hook in *link-target-rewriters*
        do (multiple-value-bind (new-hyperbook new-page handledp)
               (funcall hook
                        *current-page*
                        current-hyperbook
                        current-page-id
                        :element element
                        :link-text link-text)
             (when handledp
               (setf current-hyperbook new-hyperbook
                     current-page-id new-page)))
        finally (return (values current-hyperbook current-page-id))))

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
      ((or page-attr hyperbook-attr)
       (let ((hyperbook-id (or hyperbook-attr
                               (-> *current-page* hyperbook-of id-of))))
         (render-hyperbook-or-page-link hyperbook-id page-attr render-children
                                        :element element))
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

(defun rendered-link-text (link-text)
  (or link-text
      (views:html (views:esc ""))))

(defun render-hyperbook-link (hyperbook-id link-text &key element)
  (declare (ignore element))
  (handler-case
      (let ((hyperbook (find-hyperbook hyperbook-id :signal-error? t)))
        (views:html
          (:span :class "hyperbook-reference"
                 :title (format nil "HyperBook \"~A\""
                                (cl-who:escape-string hyperbook-id))
                 (views:object-ref hyperbook
                                   :display (rendered-link-text link-text)))))
    (lookup-failure (c)
      (let ((issue (enrich-lookup-issue
                    (make-basic-hyperbook-lookup-issue c *current-page*))))
        (views:html
          (:span :class "hyperbook-reference hyperbook-error"
                 (views:object-ref issue
                                   :display (rendered-link-text link-text)))))))  )

(defun render-hyperbook-page-link (hyperbook-id page-id link-text &key element)
  (handler-case
      (let* ((hyperbook (find-hyperbook hyperbook-id :signal-error? t))
             (page (find-page hyperbook page-id :signal-error? t)))
        (views:html
          (:span :class "hyperbook-reference"
                 :title (format nil "Page \"~A\"~%HyperBook \"~A\""
                                (cl-who:escape-string page-id)
                                (cl-who:escape-string (title-of hyperbook)))
                 (views:object-ref page
                                   :display (rendered-link-text link-text)))))
    (lookup-failure (c)
      (let ((issue
              (make-render-time-lookup-issue
               c
               :source-page *current-page*
               :target-hyperbook-id hyperbook-id
               :expected-page-id page-id
               :link-text (typecase link-text
                            (string link-text)
                            (t (or (and element (trimmed-node-text element))
                                   page-id)))
               :source-section (and *current-page* element
                                    (source-section-for-link-element
                                     (dom-of *current-page*)
                                     element)))))
        (views:html
          (:span :class "hyperbook-reference hyperbook-error"
                 (views:object-ref issue
                                   :display (rendered-link-text link-text))))))))

(defun render-hyperbook-or-page-link (hyperbook-id page-id link-text &key element)
  (multiple-value-bind (hyperbook-id* page-id*)
      (rewrite-link-target hyperbook-id page-id
                           :element element
                           :link-text link-text)
    (if page-id*
        (render-hyperbook-page-link hyperbook-id* page-id* link-text :element element)
        (render-hyperbook-link hyperbook-id* link-text :element element))))

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
