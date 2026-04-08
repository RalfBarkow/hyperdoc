;;;; Code pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Source code view
;;

(views:defview views:👀source (page code-page)
  (views:html-view :title "Source" :priority 1
    (render-source-connect-surface page
                                   "Source"
                                   (source-code-pathname page))))

(defclass code-page-source-navigation (code-page)
  ((requested-source-function
    :reader requested-source-function-of
    :initarg :requested-source-function
    :initform nil)))

(defun make-code-page-source-navigation (page requested-source-function)
  (if-let (requested-function
           (and requested-source-function
                (let ((text
                        (string-trim '(#\Space #\Tab #\Newline #\Return)
                                     (format nil "~A"
                                             requested-source-function))))
                  (unless (string= text "")
                    text))))
    (make-instance 'code-page-source-navigation
                   :hyperbook (hyperbook-of page)
                   :id (id-of page)
                   :file (file-of page)
                   :requested-source-function requested-function)
    page))

(defun normalize-code-page-source-function-name (name)
  (when name
    (let* ((trimmed (string-trim '(#\Space #\Tab #\Newline #\Return)
                                 (format nil "~A" name)))
           (simple
             (if-let (separator (position #\: trimmed :from-end t))
               (subseq trimmed (1+ separator))
               trimmed)))
      (unless (string= simple "")
        (string-downcase simple)))))

(defun code-page-definition-name-string (raw-name)
  (cond
    ((symbolp raw-name)
     (string-downcase (symbol-name raw-name)))
    ((and (consp raw-name)
          (eq (first raw-name) 'setf)
          (symbolp (second raw-name)))
     (format nil "(setf ~A)"
             (string-downcase (symbol-name (second raw-name)))))
    (t
     nil)))

(defun code-page-toplevel-definition-name (toplevel-form)
  (let ((cst (views/standard:cst-of toplevel-form)))
    (when (cst:consp cst)
      (let* ((head (ignore-errors (cst:raw (cst:first cst))))
             (raw-name
               (and (member head '(defun
                                   defmacro
                                   defgeneric
                                   defmethod
                                   define-compiler-macro
                                   define-setf-expander
                                   define-modify-macro
                                   defclass
                                   define-condition
                                   defstruct)
                            :test #'eq)
                    (ignore-errors (cst:raw (cst:second cst))))))
        (or (code-page-definition-name-string raw-name)
            (and (eq head 'defstruct)
                 (consp raw-name)
                 (code-page-definition-name-string (first raw-name))))))))

(defun source-offset-line-number (source offset &key end-position?)
  (let* ((length (length source))
         (raw-offset (or offset 0))
         (effective-offset
           (if end-position?
               (max 0 (1- raw-offset))
               raw-offset))
         (clamped-offset (max 0 (min effective-offset length))))
    (+ 1 (count #\Newline source :end clamped-offset))))

(defun code-page-source-navigation-focus-spec (page)
  (when-let (requested-source-function (requested-source-function-of page))
    (let ((normalized-request
            (normalize-code-page-source-function-name
             requested-source-function)))
      (when normalized-request
        (let ((focus-spec
                (ignore-errors
                  (let ((source (uiop:read-file-string
                                 (source-code-pathname page))))
                    (loop for toplevel-form in (parsed-toplevel-forms page)
                          for cst = (views/standard:cst-of toplevel-form)
                          for definition-name =
                          (code-page-toplevel-definition-name toplevel-form)
                          when (and definition-name
                                    (string= definition-name normalized-request))
                            do (when-let (source-range (cst:source cst))
                                 (let ((start-line
                                         (source-offset-line-number
                                          source
                                          (car source-range)))
                                       (end-line
                                         (source-offset-line-number
                                          source
                                          (cdr source-range)
                                          :end-position? t)))
                                   (return
                                     (list :requested-source-function
                                           requested-source-function
                                           :start-line start-line
                                           :end-line (max start-line end-line)
                                           :match-p t)))))))))
          (or focus-spec
              (list :requested-source-function requested-source-function
                    :match-p nil)))))))

(defun render-code-page-source-navigation-context (focus-spec)
  (when-let (requested-source-function
             (getf focus-spec :requested-source-function))
    (views:html
      (:div :class "hyperdoc-source-navigation-context"
            (:div :class "hyperdoc-source-navigation-context-main"
                  (:span :class "hyperdoc-source-navigation-context-label"
                         "Requested function")
                  (:code :class "hyperdoc-source-navigation-context-function"
                         (views:esc requested-source-function)))
            (:div :class "hyperdoc-source-navigation-context-note"
                  (views:esc
                   (if (getf focus-spec :match-p)
                       "Best-effort landing highlighted in the source surface below."
                       "Best-effort landing unavailable in this file; showing the full source surface.")))))))

(views:defview views:👀source (page code-page-source-navigation)
  (let* ((focus-spec (code-page-source-navigation-focus-spec page))
         (focus-start-line (getf focus-spec :start-line))
         (focus-end-line (getf focus-spec :end-line)))
    (views:html-view :title "Source" :priority 1
      (views:html
        (:div :class "hyperdoc-source-navigation-view"
              (render-code-page-source-navigation-context focus-spec)
              (:div :class "hyperdoc-source-navigation-source"
                    (render-source-connect-surface page
                                                   "Source"
                                                   (source-code-pathname page)
                                                   :focus-start-line focus-start-line
                                                   :focus-end-line focus-end-line)))))))

;;
;; HTML parse tree
;;

(defmethod dom-of ((page code-page))
  (declare (ignore page))
  ;; TODO
  nil)

;;
;; Link extraction
;;

(defmethod load-page ((page code-page))
  (let ((html-inspector-views/standard:*current-source-code-file*
          (source-code-pathname page))
        page-links hyperbook-links expr-links)
    (dolist (tlf (parsed-toplevel-forms page))
      (let ((cst (-> tlf views/standard:cst-of)))
        (when (and (cst:consp cst)
                   (eq (-> cst cst:first cst:raw) 'hyperdoc:see))
          (let* ((target-form (cst:second cst))
                 (target (handler-case
                             (eval (cst:raw target-form))
                           (error (c) c))))
            (typecase target
              (page  (pushnew (make-page-link page
                                              (id-of (hyperbook-of target))
                                              (title-of target))
                              page-links
                              :test #'equal :key #'key-of))
              (hyperdoc (pushnew (make-hyperbook-link page (id-of target))
                                 hyperbook-links
                                 :test #'equal :key #'key-of))
              (t (pushnew (make-expr-link page
                                          (princ-to-string (cst:raw target-form))
                                          (views/standard:package-of tlf))
                          expr-links
                          :test #'equal :key #'key-of)))))))
    (with-slots (links) page
      (setf links
            (make-instance 'hb:links
                           :page-links (nreverse page-links)
                           :hyperbook-links (nreverse hyperbook-links)
                           :web-links nil))
      ;; (when expr-links
      ;;   (push (cons :expr (nreverse expr-links)) links))
      )))

(defun parsed-toplevel-forms (page)
  (-> page
      source-code-pathname
      views/standard:parse-lisp-code
      views/standard:top-level-forms-of))

(defun source-code-pathname (page)
  (-> page
      file-of
      asdf:component-pathname))

;;
;; Parse tree view
;;

(views:defview 👀parse-tree (page code-page)
  (let ((source (-> page source-code-pathname alexandria:read-file-into-string))
        (forms (-> page parsed-toplevel-forms)))
    (views:html-view :title "Parse tree" :priority 11
      (views:html-table
       forms
       :inspect #'identity
       :display (list #'(lambda (tlf)
                          (let ((source-refs (-> tlf
                                                 views/standard:cst-of
                                                 cst:source)))
                            (str:substring (car source-refs)
                                           (cdr source-refs)
                                           source))))))))
