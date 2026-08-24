(in-package #:dreyeck/lisp-image)

(eval-when (:compile-toplevel :load-toplevel :execute) (require :sb-introspect))

(defclass missing-lisp-source-file nil
          ((common-lisp-user::definition-source :initarg :definition-source
            :reader missing-lisp-source-file-definition-source)))

(defun definition-source-accessor (common-lisp-user::name)
  (block definition-source-accessor
    (let ((symbol (find-symbol common-lisp-user::name "SB-INTROSPECT")))
      (unless (and symbol (fboundp symbol))
        (error "SB-INTROSPECT accessor ~A is unavailable."
               common-lisp-user::name))
      symbol)))

(defun definition-source-description-of (common-lisp-user::source)
  (block definition-source-description-of
    (funcall (definition-source-accessor "DEFINITION-SOURCE-DESCRIPTION")
             common-lisp-user::source)))

(defun definition-source-pathname-of (common-lisp-user::source)
  (block definition-source-pathname-of
    (funcall (definition-source-accessor "DEFINITION-SOURCE-PATHNAME")
             common-lisp-user::source)))

(defun method-source-descriptor-of (method)
  (block method-source-descriptor-of
    (append (method-qualifiers method)
            (mapcar
             (lambda (common-lisp-user::specializer)
               (if (typep common-lisp-user::specializer 'class)
                   (class-name common-lisp-user::specializer)
                   common-lisp-user::specializer))
             (sb-mop:method-specializers method)))))

(defun method-definition-source-of (generic-function method)
  (block method-definition-source-of
    (let ((common-lisp-user::descriptor (method-source-descriptor-of method)))
      (find common-lisp-user::descriptor
            (sb-introspect:find-definition-sources-by-name
             (sb-mop:generic-function-name generic-function) :method)
            :test #'equal :key #'definition-source-description-of))))

(defun definition-source-file-object-of (common-lisp-user::source)
  (block definition-source-file-object-of
    (or (definition-source-pathname-of common-lisp-user::source)
        (make-instance 'missing-lisp-source-file :definition-source
                       common-lisp-user::source))))
