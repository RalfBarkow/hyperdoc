;;;; Transclusions of source code
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(in-package :hyperdoc)

;;
;; Source code for a class
;;

(common-doc:define-node class-source (common-doc.macro:macro-node)
  ()
  (:tag-name "source:of:class")
  (:documentation "Transclusion of source code of a class"))

(defmethod common-doc.macro:expand-macro ((source class-source))
  (let* ((class-name (str:upcase (common-doc.ops:collect-all-text source)))
         (expr (common-doc:make-text
                (format nil
                        "(html-inspector-views/standard:source-code-view (find-class '~a))"
                        class-name))))
    (make-instance 'transclusion
                   :children (list expr)
                   :metadata nil
                   :reference nil)))

;;
;; Source code for a function
;;

(common-doc:define-node function-source (common-doc.macro:macro-node)
  ()
  (:tag-name "source:of:function")
  (:documentation "Transclusion of source code of a function"))

(defmethod common-doc.macro:expand-macro ((source function-source))
  (let* ((function-name (common-doc.ops:collect-all-text source))
         (expr (common-doc:make-text
                (format nil
                        "(html-inspector-views/standard:source-code-view #'~a)"
                        function-name))))
    (make-instance 'transclusion
                   :children (list expr)
                   :metadata nil
                   :reference nil)))
