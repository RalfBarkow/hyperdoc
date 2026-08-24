;;;; Dreyeck-owned renderer-independent topicmap projection model.

(in-package #:dreyeck/topicmap)

(defclass topicmap-topic ()
  ((id
    :reader topicmap-topic-id-of
    :initarg :id
    :type string)
   (type
    :reader topicmap-topic-type-of
    :initarg :type)
   (label
    :reader topicmap-topic-label-of
    :initarg :label
    :type string)
   (object
    :reader topicmap-topic-object-of
    :initarg :object
    :initform nil)
   (temporal-scope
    :reader topicmap-topic-temporal-scope-of
    :initarg :temporal-scope
    :initform :unspecified)
   (view-properties
    :reader topicmap-topic-view-properties-of
    :initarg :view-properties
    :initform '(:x 0 :y 0 :visible t :pinned nil)
    :type list))
  (:documentation
   "One renderer-independent topic with an optional inspectable object."))

(defclass topicmap-association ()
  ((id
    :reader topicmap-association-id-of
    :initarg :id
    :type string)
   (type
    :reader topicmap-association-type-of
    :initarg :type)
   (from
    :reader topicmap-association-from-of
    :initarg :from
    :type string)
   (to
    :reader topicmap-association-to-of
    :initarg :to
    :type string)
   (properties
    :reader topicmap-association-properties-of
    :initarg :properties
    :initform nil
    :type list))
  (:documentation
   "One typed association whose endpoints are stable topic IDs."))

(defclass topicmap-projection ()
  ((source
    :reader topicmap-projection-source-of
    :initarg :source)
   (topics
    :reader topicmap-projection-topics-of
    :initarg :topics
    :initform nil
    :type list)
   (associations
    :reader topicmap-projection-associations-of
    :initarg :associations
    :initform nil
    :type list)
   (view-properties
    :reader topicmap-projection-view-properties-of
    :initarg :view-properties
    :initform '(:width 1200 :height 720)
    :type list))
  (:documentation
   "A renderer-independent projection of objects and relations as a topicmap."))

(defun make-topicmap-topic
    (&key id type label object (temporal-scope :unspecified)
          (view-properties '(:x 0 :y 0 :visible t :pinned nil)))
  (check-type id string)
  (check-type label string)
  (make-instance 'topicmap-topic
                 :id id
                 :type type
                 :label label
                 :object object
                 :temporal-scope temporal-scope
                 :view-properties (copy-list view-properties)))

(defun make-topicmap-association (&key id type from to properties)
  (check-type id string)
  (check-type from string)
  (check-type to string)
  (make-instance 'topicmap-association
                 :id id
                 :type type
                 :from from
                 :to to
                 :properties (copy-list properties)))

(defun validate-topicmap-projection (topics associations)
  (let ((ids (mapcar #'topicmap-topic-id-of topics)))
    (unless (= (length ids)
               (length (remove-duplicates ids :test #'string=)))
      (error "Topicmap topic IDs are not unique: ~S." ids))
    (dolist (association associations)
      (dolist (endpoint
                (list (topicmap-association-from-of association)
                      (topicmap-association-to-of association)))
        (unless (member endpoint ids :test #'string=)
          (error "Topicmap association ~A refers to missing topic ~S."
                 (topicmap-association-id-of association)
                 endpoint)))))
  t)

(defun make-topicmap-projection
    (&key source topics associations
          (view-properties '(:width 1200 :height 720)))
  (validate-topicmap-projection topics associations)
  (make-instance 'topicmap-projection
                 :source source
                 :topics (copy-list topics)
                 :associations (copy-list associations)
                 :view-properties (copy-list view-properties)))

(defgeneric topicmap-projection-of (object)
  (:documentation
   "Return OBJECT's current renderer-independent topicmap projection or NIL."))

(defmethod topicmap-projection-of ((object t))
  (declare (ignore object))
  nil)

(defmethod topicmap-projection-of ((projection topicmap-projection))
  projection)


(DEFCLASS TOPICMAP-WORKSPACE NIL
          ((PROJECTION :READER TOPICMAP-WORKSPACE-PROJECTION-OF :INITARG
            :PROJECTION)
           (POINT :ACCESSOR TOPICMAP-WORKSPACE-POINT-OF :INITARG :POINT)
           (HISTORY :ACCESSOR TOPICMAP-WORKSPACE-HISTORY-OF :INITARG :HISTORY
            :INITFORM NIL)))

(DEFUN MAKE-TOPICMAP-WORKSPACE (PROJECTION POINT)
  (UNLESS
      (FIND POINT (TOPICMAP-PROJECTION-TOPICS-OF PROJECTION) :KEY
            #'TOPICMAP-TOPIC-ID-OF :TEST #'STRING=)
    (ERROR "Topic ~S is absent from projection." POINT))
  (MAKE-INSTANCE 'TOPICMAP-WORKSPACE :PROJECTION PROJECTION :POINT POINT))

(DEFUN TOPICMAP-WORKSPACE-CURRENT-TOPIC (WORKSPACE)
  (OR
   (FIND (TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)
         (TOPICMAP-PROJECTION-TOPICS-OF
          (TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))
         :KEY #'TOPICMAP-TOPIC-ID-OF :TEST #'STRING=)
   (ERROR "Workspace point ~S no longer resolves."
          (TOPICMAP-WORKSPACE-POINT-OF WORKSPACE))))

(DEFUN TOPICMAP-WORKSPACE-CURRENT-OBJECT (WORKSPACE)
  (TOPICMAP-TOPIC-OBJECT-OF (TOPICMAP-WORKSPACE-CURRENT-TOPIC WORKSPACE)))

(DEFUN TOPICMAP-WORKSPACE-GO-TO (WORKSPACE TOPIC-ID)
  (LET ((TOPIC
         (FIND TOPIC-ID
               (TOPICMAP-PROJECTION-TOPICS-OF
                (TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))
               :KEY #'TOPICMAP-TOPIC-ID-OF :TEST #'STRING=)))
    (UNLESS TOPIC (ERROR "Topic ~S is absent from workspace." TOPIC-ID))
    (LET ((OLD-POINT (TOPICMAP-WORKSPACE-POINT-OF WORKSPACE)))
      (UNLESS (STRING= OLD-POINT TOPIC-ID)
        (PUSH OLD-POINT (TOPICMAP-WORKSPACE-HISTORY-OF WORKSPACE)))
      (SETF (TOPICMAP-WORKSPACE-POINT-OF WORKSPACE) TOPIC-ID))
    TOPIC))

(DEFMETHOD TOPICMAP-PROJECTION-OF ((WORKSPACE TOPICMAP-WORKSPACE))
  (LET* ((PROJECTION (TOPICMAP-WORKSPACE-PROJECTION-OF WORKSPACE))
         (VIEW-PROPERTIES
          (COPY-LIST (TOPICMAP-PROJECTION-VIEW-PROPERTIES-OF PROJECTION))))
    (SETF (GETF VIEW-PROPERTIES :POINT)
            (TOPICMAP-WORKSPACE-POINT-OF WORKSPACE))
    (MAKE-INSTANCE 'TOPICMAP-PROJECTION :SOURCE WORKSPACE :TOPICS
                   (TOPICMAP-PROJECTION-TOPICS-OF PROJECTION) :ASSOCIATIONS
                   (TOPICMAP-PROJECTION-ASSOCIATIONS-OF PROJECTION)
                   :VIEW-PROPERTIES VIEW-PROPERTIES)))
