(in-package #:dreyeck/lisp-image)

(defun generic-function-topic-id (generic-function)
  (block generic-function-topic-id
    (format nil "lisp-generic-function:~S"
            (sb-mop:generic-function-name generic-function))))

(defun method-topic-id (generic-function method)
  (block method-topic-id
    (format nil "lisp-method:~S:~S"
            (sb-mop:generic-function-name generic-function)
            (method-source-descriptor-of method))))

(defun definition-source-topic-id (generic-function method)
  (block definition-source-topic-id
    (format nil "lisp-definition-source:~S:~S"
            (sb-mop:generic-function-name generic-function)
            (method-source-descriptor-of method))))

(defun source-file-topic-id
       (generic-function method common-lisp-user::source-file)
  (block source-file-topic-id
    (etypecase common-lisp-user::source-file
      (pathname
       (format nil "lisp-source-file:~A"
               (namestring common-lisp-user::source-file)))
      (missing-lisp-source-file
       (format nil "lisp-missing-source-file:~S:~S"
               (sb-mop:generic-function-name generic-function)
               (method-source-descriptor-of method))))))

(defun generic-function-topicmap-projection (generic-function)
  (block generic-function-topicmap-projection
    (let ((common-lisp-user::topics nil)
          (common-lisp-user::associations nil)
          (common-lisp-user::topic-ids (make-hash-table :test #'equal))
          (common-lisp-user::generic-id
           (generic-function-topic-id generic-function)))
      (labels ((common-lisp-user::add-topic (common-lisp-user::topic)
                 (let ((common-lisp-user::id
                        (dreyeck/topicmap:topicmap-topic-id-of
                         common-lisp-user::topic)))
                   (unless
                       (gethash common-lisp-user::id
                                common-lisp-user::topic-ids)
                     (setf (gethash common-lisp-user::id
                                    common-lisp-user::topic-ids)
                             t)
                     (push common-lisp-user::topic common-lisp-user::topics)))))
        (common-lisp-user::add-topic
         (dreyeck/topicmap:make-topicmap-topic :id common-lisp-user::generic-id
                                               :type :lisp-generic-function
                                               :label
                                               (format nil "~S"
                                                       (sb-mop:generic-function-name
                                                        generic-function))
                                               :object generic-function
                                               :view-properties '(:visible t)))
        (dolist (method (sb-mop:generic-function-methods generic-function))
          (let* ((common-lisp-user::method-id
                  (method-topic-id generic-function method))
                 (common-lisp-user::descriptor
                  (method-source-descriptor-of method))
                 (common-lisp-user::source
                  (method-definition-source-of generic-function method)))
            (common-lisp-user::add-topic
             (dreyeck/topicmap:make-topicmap-topic :id
                                                   common-lisp-user::method-id
                                                   :type :lisp-method :label
                                                   (format nil "~S"
                                                           common-lisp-user::descriptor)
                                                   :object method
                                                   :view-properties
                                                   '(:visible t)))
            (push
             (dreyeck/topicmap:make-topicmap-association :id
                                                         (format nil
                                                                 "association:has-method:~A"
                                                                 common-lisp-user::method-id)
                                                         :type :has-method
                                                         :from
                                                         common-lisp-user::generic-id
                                                         :to
                                                         common-lisp-user::method-id)
             common-lisp-user::associations)
            (when common-lisp-user::source
              (let* ((common-lisp-user::source-id
                      (definition-source-topic-id generic-function method))
                     (common-lisp-user::source-file
                      (definition-source-file-object-of
                       common-lisp-user::source))
                     (common-lisp-user::source-file-id
                      (source-file-topic-id generic-function method
                                            common-lisp-user::source-file)))
                (common-lisp-user::add-topic
                 (dreyeck/topicmap:make-topicmap-topic :id
                                                       common-lisp-user::source-id
                                                       :type
                                                       :lisp-definition-source
                                                       :label
                                                       (format nil
                                                               "Definition source ~S"
                                                               common-lisp-user::descriptor)
                                                       :object
                                                       common-lisp-user::source
                                                       :view-properties
                                                       '(:visible t)))
                (common-lisp-user::add-topic
                 (dreyeck/topicmap:make-topicmap-topic :id
                                                       common-lisp-user::source-file-id
                                                       :type
                                                       (if (pathnamep
                                                            common-lisp-user::source-file)
                                                           :lisp-source-file
                                                           :missing-lisp-source-file)
                                                       :label
                                                       (if (pathnamep
                                                            common-lisp-user::source-file)
                                                           (namestring
                                                            common-lisp-user::source-file)
                                                           "Missing Lisp source file")
                                                       :object
                                                       common-lisp-user::source-file
                                                       :view-properties
                                                       '(:visible t)))
                (push
                 (dreyeck/topicmap:make-topicmap-association :id
                                                             (format nil
                                                                     "association:defined-by:~A"
                                                                     common-lisp-user::method-id)
                                                             :type :defined-by
                                                             :from
                                                             common-lisp-user::method-id
                                                             :to
                                                             common-lisp-user::source-id)
                 common-lisp-user::associations)
                (push
                 (dreyeck/topicmap:make-topicmap-association :id
                                                             (format nil
                                                                     "association:source-file:~A"
                                                                     common-lisp-user::source-id)
                                                             :type :source-file
                                                             :from
                                                             common-lisp-user::source-id
                                                             :to
                                                             common-lisp-user::source-file-id)
                 common-lisp-user::associations)))))
        (dreyeck/topicmap:make-topicmap-projection :source generic-function
                                                   :topics
                                                   (nreverse
                                                    common-lisp-user::topics)
                                                   :associations
                                                   (nreverse
                                                    common-lisp-user::associations))))))

(defmethod dreyeck/topicmap:topicmap-projection-of
           ((common-lisp-user::object function))
  (when (typep common-lisp-user::object 'generic-function)
    (generic-function-topicmap-projection common-lisp-user::object)))
