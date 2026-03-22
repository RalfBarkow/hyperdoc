;;;; HTML pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; An HTML page stores the page contents as the parse tree
;; returned by the plump parser.
;;

(defclass html-page (text-page)
  ((parse-tree :reader dom-of :initform nil)
   (counterpart-section-issues
    :reader counterpart-section-issues-of
    :initform nil)))

;;
;; The page class for file type "html" is html-page.
;;

(defmethod page-class ((filetype (eql :html)))
  (find-class 'html-page))

;;
;; Load an HTML page, parse it, set the title, and compile a
;; list of the links it contains.
;;
;; The title is given by a TITLE tag, if one exists, or else as the text
;; of the highest-level header tag in the page. If neither TITLE
;; nor any header tag exists, return "Untitled".
;;

(defmethod load-page ((page html-page))
  (with-slots (links file parse-tree title) page
    (let ((plump:*tag-dispatchers* plump:*html-tags*))
      (setf parse-tree (plump:parse file))
      (set-title page)
      (setf (slot-value page 'counterpart-section-issues)
            (normalize-fedwiki-counterpart-sections! page parse-tree))
      (setf links (hb:extract-links page))))
  page)

(defun set-title (page)
  (with-slots (parse-tree id) page
    (setf id (or (loop for tag in '("title" "h1" "h2" "h3" "h4" "h5" "h6")
                          do (let ((elements (-> (dom-of page)
                                               (plump:get-elements-by-tag-name tag))))
                               (when elements
                                 (return (-> elements first plump:text str:trim)))))
                    "Untitled"))))

(defun copy-plump-attributes! (from to)
  (maphash #'(lambda (key value)
               (plump:set-attribute to key value))
           (plump:attributes from))
  to)

(defun replace-element-text! (element new-text)
  (let* ((root (plump:make-root))
         (replacement (plump:make-element root (plump:tag-name element))))
    (copy-plump-attributes! element replacement)
    (plump:make-text-node replacement new-text)
    (plump:replace-child element replacement)
    replacement))

(defun normalize-fedwiki-counterpart-link! (anchor domain)
  (let* ((current-text (or (hb::trimmed-node-text anchor)
                           (plump:get-attribute anchor "page")
                           domain))
         (labelled-text
           (if (and current-text
                    (uiop:string-prefix-p "[" current-text))
               current-text
               (format nil "[~A] ~A" domain current-text))))
    (replace-element-text! anchor labelled-text)))

(defun fedwiki-counterpart-heading-p (text)
  (member text
          '("Localhost FedWiki twin"
            "Localhost FedWiki twins")
          :test #'string-equal))

(defun fedwiki-counterpart-section-title (domains)
  (cond
    ((null domains)
     "FedWiki counterparts")
    ((every #'localhost-like-fedwiki-domain-p domains)
     "Local FedWiki counterparts")
    ((= 1 (length domains))
     "FedWiki counterparts")
    (t
     "FedWiki counterpart targets")))

(defun fedwiki-links-in-section (nodes)
  (loop for node in nodes
        when (typep node 'plump:element)
          append (loop for element across (lquery:$ node "a[hyperbook]")
                       for hyperbook = (plump:get-attribute element "hyperbook")
                       when (and hyperbook
                                 (uiop:string-prefix-p "fedwiki:" hyperbook))
                         collect element)))

(defun node-vector-to-list (vector)
  (loop for node across vector
        collect node))

(defun normalize-fedwiki-counterpart-sections! (page dom)
  (let* ((children (node-vector-to-list (plump:children dom)))
         (page-hyperbook-id (hb:id-of (hb:hyperbook-of page)))
         (page-id (hb:id-of page))
         (page-title (title-of page))
         (issues nil))
    (loop for index from 0 below (length children)
          for node = (nth index children)
          when (and (typep node 'plump:element)
                    (member (plump:tag-name node)
                            '("h2" "h3" "h4" "h5" "h6")
                            :test #'string-equal))
            do (let ((heading-text (hb::trimmed-node-text node)))
                 (when (fedwiki-counterpart-heading-p heading-text)
                   (let* ((section-nodes
                            (loop for section-index from (1+ index) below (length children)
                                  for section-node = (nth section-index children)
                                  while (not (and (typep section-node 'plump:element)
                                                  (member (plump:tag-name section-node)
                                                          '("h1" "h2" "h3" "h4" "h5" "h6")
                                                          :test #'string-equal)))
                                  collect section-node))
                          (anchors (fedwiki-links-in-section section-nodes))
                          (domains
                            (remove-duplicates
                             (loop for anchor in anchors
                                   for hyperbook = (plump:get-attribute anchor "hyperbook")
                                   collect (subseq hyperbook (length "fedwiki:")))
                             :test #'string-equal))
                          (replacement-title
                            (fedwiki-counterpart-section-title domains)))
                     (when (or (not (string= heading-text replacement-title))
                               (some #'(lambda (domain)
                                         (not (localhost-like-fedwiki-domain-p domain)))
                                     domains))
                       (push
                        (hb:make-target-grouping-issue
                         :source-object page
                         :source-hyperbook page-hyperbook-id
                         :source-page-id page-id
                         :source-page-title page-title
                         :source-section heading-text
                         :target-hyperbook-id (and (= 1 (length domains))
                                                   (format nil "fedwiki:~A"
                                                           (first domains)))
                         :target-kind (if (> (length domains) 1)
                                          :unknown
                                          :remote-fedwiki-page)
                         :classification :mislabelled-target-grouping
                         :status :mislabelled-target
                         :suggested-repair :normalize-fedwiki-counterpart-labels
                         :repair-description
                         "Render FedWiki counterpart sections with truthful scope labels rather than a flat Localhost heading."
                         :details (list :original-heading heading-text
                                        :replacement-heading replacement-title
                                        :domains domains))
                        issues))
                     (replace-element-text! node replacement-title)
                     (loop for anchor in anchors
                           for hyperbook = (plump:get-attribute anchor "hyperbook")
                           for domain = (subseq hyperbook (length "fedwiki:"))
                           do (normalize-fedwiki-counterpart-link! anchor domain))))))
    (nreverse issues)))

(defmethod hb:enrich-lookup-issue ((issue hb:page-lookup-issue))
  (route-hyperdoc-page-lookup-issue! issue))

(defmethod hb:lookup-issues-of ((page html-page))
  (let ((issues (copy-list (counterpart-section-issues-of page))))
    (dolist (link (or (-> page hb:links-of hb:page-links-of) '()))
      (let ((result (-> link hb:thunk-of views:eval-thunk)))
        (when (typep result 'hb:lookup-failure)
          (push
           (hb:enrich-lookup-issue
            (hb:make-page-lookup-issue
             result
             :source-object page
             :source-hyperbook (hb:source-hyperbook-of link)
             :source-page-id (hb:source-page-of link)
             :source-page-title (title-of page)
             :source-section (hb:source-section-of link)
             :link-text (hb:link-text-of link)
             :target-hyperbook-id (hb:target-hyperbook-of link)
             :expected-page-id (hb:target-page-of link)
             :link link
             :classification :lookup-failure
             :details (list :condition-type (type-of result))))
           issues))))
    (remove-duplicates issues
                       :test #'equal
                       :key #'hb:lookup-issue-signature)))

;;
;; Render HTML pages
;;

;; The tags with special treatment in serialization

(defvar *hyperdoc-tags* hb::*hyperbook-tags*)

;; A special variable holding the current package

(defvar *current-package* nil)

;;
;; Process special tags
;;

;; in-package: set the current package, no not render

(plump:define-tag-dispatcher (in-package-tag *hyperdoc-tags*) (name)
  (string-equal name "in-package"))

(plump:define-tag-printer in-package-tag (element)
  (setf *current-package*
        (-> element plump:text string-upcase find-package))
  t)

;; value-of: parse and eval text, render result

(plump:define-tag-dispatcher (value-of *hyperdoc-tags*) (name)
  (string-equal name "value-of"))

(plump:define-tag-printer value-of (element)
  (let* ((*package* *current-package*)
         (text (-> element plump:text))
         (value (-> text parse-and-eval)))
    (views:html
      (:span :class "hyperdoc-computed-value"
             :title text
             (views:html-representation value))))
  t)

;; html-expr: parse and eval text, insert result as HTML

(plump:define-tag-dispatcher (html-expr *hyperdoc-tags*) (name)
  (string-equal name "html-expr"))

(plump:define-tag-printer html-expr (element)
  (let* ((*package* *current-package*)
         (text (-> element plump:text))
         (value (-> text parse-and-eval)))
    (if (typep value 'condition)
        (views:html-representation value)
        (views:html (views:str value))))
  t)

;; html-generator: parse and eval text, which generates HTML as an effect

(plump:define-tag-dispatcher (html-generator *hyperdoc-tags*) (name)
  (string-equal name "html-generator"))

(plump:define-tag-printer html-generator (element)
  (let* ((*package* *current-package*)
         (expr (plump:text element)))
    (let ((result (parse-and-eval expr)))
      (when (typep result 'condition)
        (views:html-representation result))))
  t)

;; view-transclusion: parse and eval text, transclude result

(plump:define-tag-dispatcher (view-transclusion *hyperdoc-tags*) (name)
  (string-equal name "view-transclusion"))

(plump:define-tag-printer view-transclusion (element)
  (let* ((*package* *current-package*)
         (expr (plump:text element))
         (value (parse-and-eval expr)))
    (if (typep value 'condition)
        (views:html-representation value)
        (views:transclusion value)))
  t)

;; source-of-class: find class named by text, transclude its source view

(plump:define-tag-dispatcher (source-of-class *hyperdoc-tags*) (name)
  (string-equal name "source-of-class"))

(plump:define-tag-printer source-of-class (element)
  (let* ((*package* *current-package*)
         (name (plump:text element))
         (class (parse-and-eval (format nil "(find-class '~a)" name))))
    (if (typep class 'condition)
        (views:html-representation class)
        (views:transclusion
         (html-inspector-views/standard:source-code-view class))))
  t)

;; source-of-class: find function named by text, transclude its source view

(plump:define-tag-dispatcher (source-of-function *hyperdoc-tags*) (name)
  (string-equal name "source-of-function"))

(plump:define-tag-printer source-of-function (element)
  (let* ((*package* *current-package*)
         (name (plump:text element))
         (fn (parse-and-eval (format nil "(function ~a)" name))))
    (if (typep fn 'condition)
        (views:html-representation fn)
        (views:transclusion
         (html-inspector-views/standard:source-code-view fn))))
  t)

;; lisp-code: parse text as Lisp, render with syntax highlighting

(plump:define-tag-dispatcher (lisp-code *hyperdoc-tags*) (name)
  (string-equal name "lisp-code"))

(plump:define-tag-printer lisp-code (element)
  (let* ((package-name (plump:attribute element "package"))
         (package (or (and package-name
                           (find-package (str:upcase package-name)))
                      *current-package*)))
    (-> element
        plump:text
        str:trim
        (views/standard:parse-lisp-code package)
        views/standard:render-as-html))
  t)


(plump:define-tag-dispatcher (img *hyperdoc-tags*) (name)
  (string-equal name "img"))

(plump:define-tag-printer img (element)
  (let* ((src (plump:attribute element "src"))
         (uri (handler-case (and src (puri:parse-uri src))
                (error () nil))))
    ;; If the src has a URI scheme, leave as a img element.  If the
    ;; src starts with "/", do the same.  Otherwise, it's a local file
    ;; that a browser cannot access, replace it with a data URL.
    (unless (or (and uri (puri:uri-scheme uri))
                (and src (str:starts-with? "/" src)))
      (let* ((page-base-directory
               (ignore-errors
                 (let ((file-of-symbol (find-symbol "FILE-OF" :hyperbook)))
                   (when (and (boundp 'hb::*current-page*)
                              hb::*current-page*
                              file-of-symbol
                              (fboundp file-of-symbol))
                     (uiop:pathname-directory-pathname
                      (funcall file-of-symbol hb::*current-page*))))))
             (hyperdoc-base-directory
               (ignore-errors
                 (when (and (boundp 'hb::*current-page*)
                            hb::*current-page*)
                   (-> hb::*current-page*
                       (slot-value 'hyperbook)
                       directory-of))))
             (candidate
               (cond ((and src page-base-directory)
                      (merge-pathnames src page-base-directory))
                     ((and src hyperdoc-base-directory)
                      (merge-pathnames src hyperdoc-base-directory))
                     (src
                      (ignore-errors (pathname src)))))
             (existing (and candidate (probe-file candidate))))
        (when existing
          (let* ((bytes (alexandria:read-file-into-byte-vector existing))
                 (encoded (base64:usb8-array-to-base64-string bytes))
                 (image-type (-> existing pathname-type str:downcase))
                 (mime-type (if (equal image-type "jpg") "jpeg" image-type))
                 (data-url (str:concat "data:image/" mime-type ";base64," encoded)))
            (plump:set-attribute element "src" data-url)
            (hb:render-node element))))))
  t)

(defmethod hb:serialize-a-element ((attr (eql ':expr)) element)
  (serialize-a-expr-element element))

(defmethod hb:serialize-a-element ((attr (eql ':expr.view)) element)
  (serialize-a-expr-element element))

(defun serialize-a-expr-element (element)
  (let* ((expr-attr (plump:attribute element "expr"))
         (view-attr (plump:attribute element "view"))
         (*package* *current-package*)
         (value (parse-and-eval expr-attr))
         (render-children (let ((children (plump:children element)))
                            (unless (zerop (length children))
                              (make-instance 'hb:html-nodes
                                             :nodes children)))))
    (views:html
      (:span :class "hyperbook-reference"
             :title (cl-who:escape-string-all expr-attr)
             (views:object-ref value :display render-children :select view-attr)))))

;;
;; Content view on HTML pages
;;

(views:defview views:👀content (page html-page)
  (views:html-view :title "Content" :priority 1
    (views:add-asset-path "/hyperbook/"
                          (asdf:system-relative-pathname
                           :hyperbook
                           "assets/hyperbook/"))
    (views:add-asset-path "/hyperdoc/"
                          (asdf:system-relative-pathname
                           :hyperdoc
                           "assets/hyperdoc/"))
    (views:include-css "/hyperbook/css/hyperbook.css")
    (views:include-css "/hyperdoc/css/hyperdoc.css")
    (let ((hb::*current-page* page)
          (*current-package* (find-package "CL-USER")))
      (when-let (dom (dom-of page))
        (render-dom-connect-surface
         page
         "Content"
         #'(lambda ()
             (views:html
               (:div :class "hyperbook-page"
                     (let ((plump:*tag-dispatchers* *hyperdoc-tags*))
                       (plump:serialize dom views::*html-stream*))
                     (:br)))))))))

;;
;; Parse tree view
;;

(views:defview 👀parse-tree (page html-page)
  (-> (dom-of page)
      plump-inspector-views::👀children
      (views:rename :title "Parse tree" :priority 11)))
