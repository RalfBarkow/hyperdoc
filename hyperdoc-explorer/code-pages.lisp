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
;; Link extraction
;;

(defmethod extract-links ((page code-page))
  (let ((html-inspector-views/standard:*current-source-code-file*
          (source-code-pathname page))
        page-links hyperdoc-links web-links expr-links)
    (dolist (tlf (parsed-toplevel-forms page))
      (let ((cst (-> tlf views/standard:cst-of)))
        (when (and (cst:consp cst)
                   (eq (-> cst cst:first cst:raw) 'hyperdoc:see))
          (let* ((target-form (cst:second cst))
                 (target (handler-case
                             (eval (cst:raw target-form))
                           (error (c) c))))
            (typecase target
              (page  (pushnew (list (cons (title-of (hyperdoc-of target))
                                          (title-of target))
                                    target
                                    nil)
                              page-links
                              :test #'equal :key #'first))
              (hyperdoc (pushnew (list (title-of target) target nil)
                                 hyperdoc-links
                                 :test #'equal :key #'first))
              (t (pushnew (list (cons (princ-to-string (cst:raw target-form))
                                      (views/standard:package-of tlf))
                                target
                                nil)
                          expr-links
                          :test #'equal :key #'first)))))))
    (with-slots (links) page
      (when page-links
        (push (cons :page (nreverse page-links)) links))
      (when hyperdoc-links
        (push (cons :hyperdoc (nreverse hyperdoc-links)) links))
      (when web-links
        (push (cons :web (nreverse web-links)) links))
      (when expr-links
        (push (cons :expr (nreverse expr-links)) links)))))

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
                                           source))))))
))
