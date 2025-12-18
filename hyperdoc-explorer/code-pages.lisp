;;;; Code pages
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Source code view
;;

(views:defview views:👀source (page code-page)
  (-> page
      file-of
      views:👀source
      (views:rename :title "Source" :priority 1)))

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
