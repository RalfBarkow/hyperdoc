;;;; Support code for writing views
;;
;;;; Copyright (c) 2024 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package #:html-inspector-views)

(eval-when (:compile-toplevel :load-toplevel :execute)
  (defun kwargs-then-body (body)
    (let ((kwargs))
      (loop while (and (member (car body) '(:title :priority)) (cadr body))
            do (let* ((keyword (pop body))
                      (value (pop body)))
                 (push value kwargs)
                 (push keyword kwargs)))
      (values kwargs body))))

(defmacro html-view (&rest args-and-body)
  (multiple-value-bind (kwargs body)
      (kwargs-then-body args-and-body)
    `(make-html-view (thunk (html-and-references ,@body))
                     ,@kwargs)))

;;
;; Reusable HTML snippets
;;

(defun html-table (items
                   &key (columns nil)
                     (display (list #'identity))
                     (inspect #'identity)
                     (inspect-items :row))
  (html
   (:table :class "inspector-table"
           (when columns
             (html (:tr (loop for label in (coerce columns 'list)
                              do (html (:th (str label)))))))
           (loop for item in (coerce items 'list) do
                 (case inspect-items
                   (:row (html
                          (:tr :id (inspect-id (funcall inspect item))
                               :class "inspector-inspect"
                               (loop for fn in (coerce display 'list)
                                     do (html-table-entry (funcall fn item))))))
                   (:by-column (html
                                (:tr (loop for fn in (coerce display 'list) do
                                           (html-table-entry (funcall fn item) t))))))))))

(defun html-table-entry (value &optional (inspect? nil))
  (let ((align (if (typep value 'integer) "right" "left")))
    (if inspect?
        (html
         (:td :id (inspect-id value)
              :class "inspector-inspect"
              :align align
              (html-representation value)))
        (html
         (:td :align align
              (html-representation value))))))

;;
;; Table views
;;

(defun list-view (items-or-thunk &key title priority (display #'identity))
  (html-view :title title :priority priority
             (let ((items (eval-thunk items-or-thunk)))
               (html
                (:small :class "inspector-index"
                        (fmt "~a item(s)" (length items)))
                (html-table items :display (list display))))))

(defun enumerated-list-view (items-or-thunk &key title priority (display #'identity))
  (html-view :title title :priority priority
             (let ((items (coerce (eval-thunk items-or-thunk) 'vector)))
               (html
                (:small :class "inspector-index"
                        (fmt "~a item(s)" (length items)))
                (:table :class "inspector-table"
                        (loop for i from 0
                              and item across items
                              do (html
                                  (:tr :id (inspect-id item)
                                       :class "inspector-inspect"
                                       (:td (:small :class "inspector-index"
                                                    (fmt "~d" i)))
                                       (:td (html-representation
                                             (funcall display item)))))))))))

(defun multi-column-list-view (items-or-thunk
                               &key title priority
                                 columns display
                                 (inspect #'identity)
                                 (inspect-items :row))
  (html-view :title title :priority priority
             (let ((items (eval-thunk items-or-thunk)))
               (html-table items :columns columns :display display
                           :inspect inspect :inspect-items inspect-items))))

(defun key-value-table-view (kv-pairs-or-thunk
                             &key title priority (display #'identity))
  (html-view :title title :priority priority
             (html
              (:table :class "inspector-table"
                      (loop for (key . value) in (eval-thunk kv-pairs-or-thunk)
                            do (html
                                (:tr (:td (str key))
                                     (:td (object-ref (funcall display value))))))))))

;;
;; Tree views
;;

(defun tree-view (cons-tree-or-thunk)
  (html-view (tree (eval-thunk cons-tree-or-thunk) t)))

(defun tree (cons-tree root?)
  (if (consp cons-tree)
      (let ((head (and cons-tree (car cons-tree)))
            (open-subtrees? (= (length cons-tree) 1)))
        (cond
          ((null (cdr cons-tree)) (object-ref head))
          (t (let* ((ul-classes (if root? "inspector-tree" "")))
               (if head
                   (html
                    (:details :open open-subtrees?
                              (:summary (object-ref head))
                              (:ul :class ul-classes
                                   (loop for item in (cdr cons-tree)
                                         do (html
                                             (:li (tree item nil)))))))
                   (html
                    (:ul :class ul-classes
                         (loop for item in (cdr cons-tree)
                               do (html
                                   (:li (tree item nil)))))))))))
      (object-ref cons-tree)))

;;
;; HTML code views
;;

(defun html-code-view (html-string-or-thunk &key title priority)
  (html-view :title title :priority priority
             (html-snippet html-string-or-thunk)))

(defun html-snippet (string-or-thunk)
  (include-html-beautify-assets)
  (html
   (:html-code (esc (eval-thunk string-or-thunk)))))

(defun include-html-beautify-assets ()
  (add-asset-path "/html-inspector-views/"
                  (asdf:system-relative-pathname
                   :html-inspector-views
                   "assets/html-inspector-views/"))
  (include-js "/html-inspector-views/js/beautify-html.min.js")
  (include-js "/html-inspector-views/js/beautify-html-code-elements.js")
  (include-js "/html-inspector-views/js/highlight.min.js")
  (include-css "/html-inspector-views/css/hljs.css")
  (include-script "processHtmlCodeElements(window.currentInspectorView)"))

;;
;; Lisp code views
;;

(defun lisp-code-view (string-or-thunk &key title priority)
  (html-view :title title :priority priority
             (lisp-snippet string-or-thunk)))

(defun lisp-snippet (string-or-thunk)
  (include-lisp-highlight-assets)
  (html
   (:pre (:code :class "language-lisp" (esc (eval-thunk string-or-thunk))))))

(defun include-lisp-highlight-assets ()
  (add-asset-path "/html-inspector-views/"
                  (asdf:system-relative-pathname
                   :html-inspector-views
                   "assets/html-inspector-views/"))
  (include-js "/html-inspector-views/js/highlight.min.js")
  (include-js "/html-inspector-views/js/highlight-lisp.min.js")
  (include-css "/html-inspector-views/css/hljs.css")
  (include-js "/html-inspector-views/js/highlight-code-elements.js")
  (include-script "highlightLispCodeElements(window.currentInspectorView)"))

;;
;; Graphviz views
;;

(defun include-graphviz-assets ()
  (add-asset-path "/html-inspector-views/"
                  (asdf:system-relative-pathname
                   :html-inspector-views
                   "assets/html-inspector-views/"))
  (include-css "/html-inspector-views/css/graphviz.css")
  (include-js "/html-inspector-views/js/viz-standalone.js")
  (include-js "/html-inspector-views/js/graphviz.js")
  (include-script
   "(function initInspectorGraphviz(attempt) {
      if (window.inspectorGraphviz &&
          typeof window.inspectorGraphviz.initCurrentView === 'function') {
        window.inspectorGraphviz.initCurrentView(window.currentInspectorView);
        return;
      }
      if ((attempt || 0) >= 40) {
        return;
      }
      window.setTimeout(function () {
        initInspectorGraphviz((attempt || 0) + 1);
      }, 50);
    }(0));"))

(defun graphviz-snippet (dot-source-or-thunk
                         &key (engine "dot")
                           (fallback-title "Derived DOT source"))
  (let* ((dot-source (eval-thunk dot-source-or-thunk))
         (dot (if dot-source (dot-string dot-source) "")))
    (include-graphviz-assets)
    (html
     (:div :class "inspector-graphviz"
           :data-inspector-graphviz "true"
           :data-inspector-graphviz-state "pending"
           :data-inspector-graphviz-engine engine
           :data-inspector-graphviz-dot dot
           (:div :class "inspector-graphviz-canvas"
                 (:p :class "inspector-graphviz-pending"
                     "Rendering Graphviz diagram..."))
           (:details :class "inspector-graphviz-dot-fallback"
                     (:summary (esc fallback-title))
                     (:pre (esc dot)))))))

(defun graphviz-view (dot-source-or-thunk
                      &key title priority (engine "dot")
                        (fallback-title "Derived DOT source"))
  (html-view :title title :priority priority
             (graphviz-snippet dot-source-or-thunk
                               :engine engine
                               :fallback-title fallback-title)))

(defgeneric dot-string (object)
  (:method ((object string))
    object))

;;
;; Encode/decode in base32 (used in inspect- references)
;;

(defun encode-base32 (plain-string)
  (str:replace-all "=" "0"
                   (cl-base32:bytes-to-base32
                    (flexi-streams:string-to-octets plain-string :external-format :utf-8))))

(defun decode-base32 (base32-string)
  (flexi-streams:octets-to-string
   (base32:base32-to-bytes (str:replace-all "0" "=" base32-string))
   :external-format :utf-8))
