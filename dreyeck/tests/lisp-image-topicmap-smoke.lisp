(defpackage #:dreyeck/lisp-image/topicmap/tests
  (:use #:cl)
  (:export #:run-lisp-image-topicmap-smoke-tests))

(in-package #:dreyeck/lisp-image/topicmap/tests)

(defclass dreyeck/lisp-image/topicmap/tests::source-backed-fixture nil nil)

(defclass dreyeck/lisp-image/topicmap/tests::runtime-fixture nil nil)

(defgeneric dreyeck/lisp-image/topicmap/tests::lisp-image-topicmap-fixture
    (dreyeck/lisp-image/topicmap/tests::object))

(defmethod dreyeck/lisp-image/topicmap/tests::lisp-image-topicmap-fixture
           (
            (dreyeck/lisp-image/topicmap/tests::object
             dreyeck/lisp-image/topicmap/tests::source-backed-fixture))
  :source-backed)

(defun dreyeck/lisp-image/topicmap/tests:run-lisp-image-topicmap-smoke-tests ()
  (eval
   (list 'defmethod
         'dreyeck/lisp-image/topicmap/tests::lisp-image-topicmap-fixture
         (list
          (list 'dreyeck/lisp-image/topicmap/tests::object
                'dreyeck/lisp-image/topicmap/tests::runtime-fixture))
         :runtime))
  (let* ((generic-function
          (fdefinition
           'dreyeck/lisp-image/topicmap/tests::lisp-image-topicmap-fixture))
         (dreyeck/lisp-image/topicmap/tests::source-backed-method
          (find-method generic-function nil
                       (list
                        (find-class
                         'dreyeck/lisp-image/topicmap/tests::source-backed-fixture))))
         (dreyeck/lisp-image/topicmap/tests::runtime-method
          (find-method generic-function nil
                       (list
                        (find-class
                         'dreyeck/lisp-image/topicmap/tests::runtime-fixture))))
         (dreyeck/lisp-image/topicmap/tests::source-backed-source
          (dreyeck/lisp-image::method-definition-source-of generic-function
                                                           dreyeck/lisp-image/topicmap/tests::source-backed-method))
         (dreyeck/lisp-image/topicmap/tests::runtime-source
          (dreyeck/lisp-image::method-definition-source-of generic-function
                                                           dreyeck/lisp-image/topicmap/tests::runtime-method))
         (dreyeck/lisp-image/topicmap/tests::source-backed-file
          (dreyeck/lisp-image::definition-source-file-object-of
           dreyeck/lisp-image/topicmap/tests::source-backed-source))
         (dreyeck/lisp-image/topicmap/tests::runtime-file
          (dreyeck/lisp-image::definition-source-file-object-of
           dreyeck/lisp-image/topicmap/tests::runtime-source))
         (dreyeck/lisp-image/topicmap/tests::projection
          (dreyeck/topicmap:topicmap-projection-of generic-function))
         (dreyeck/lisp-image/topicmap/tests::topics
          (dreyeck/topicmap:topicmap-projection-topics-of
           dreyeck/lisp-image/topicmap/tests::projection)))
    (assert dreyeck/lisp-image/topicmap/tests::source-backed-source)
    (assert dreyeck/lisp-image/topicmap/tests::runtime-source)
    (assert (pathnamep dreyeck/lisp-image/topicmap/tests::source-backed-file))
    (assert
     (typep dreyeck/lisp-image/topicmap/tests::runtime-file
            'dreyeck/lisp-image::missing-lisp-source-file))
    (assert
     (find dreyeck/lisp-image/topicmap/tests::source-backed-method
           dreyeck/lisp-image/topicmap/tests::topics :key
           #'dreyeck/topicmap:topicmap-topic-object-of :test #'eq))
    (assert
     (find dreyeck/lisp-image/topicmap/tests::runtime-method
           dreyeck/lisp-image/topicmap/tests::topics :key
           #'dreyeck/topicmap:topicmap-topic-object-of :test #'eq))
    (assert
     (find :missing-lisp-source-file dreyeck/lisp-image/topicmap/tests::topics
           :key #'dreyeck/topicmap:topicmap-topic-type-of :test #'eq))
    (list :status :passed :source-backed-pathname
          dreyeck/lisp-image/topicmap/tests::source-backed-file
          :runtime-source-file-type
          (type-of dreyeck/lisp-image/topicmap/tests::runtime-file)
          :topic-count (length dreyeck/lisp-image/topicmap/tests::topics)
          :association-count
          (length
           (dreyeck/topicmap:topicmap-projection-associations-of
            dreyeck/lisp-image/topicmap/tests::projection)))))
