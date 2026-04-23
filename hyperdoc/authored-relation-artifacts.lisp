;;;; Generic authored relation artifact pattern
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass authored-relation-role ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (kind :reader authored-relation-role-kind-of
         :initarg :kind
         :initform nil)
   (binding :reader authored-relation-role-binding-of
            :initarg :binding
            :initform nil)
   (participants :reader authored-relation-role-participants-of
                 :initarg :participants
                 :initform nil)
   (findings :reader authored-relation-role-findings-of
             :initarg :findings
             :initform nil)))

(defclass authored-relation ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (layer :reader authored-relation-layer-of
          :initarg :layer
          :initform nil)
   (subject :reader authored-relation-subject-of
            :initarg :subject
            :initform nil)
   (predicate :reader authored-relation-predicate-of
              :initarg :predicate
              :initform nil)
   (object :reader authored-relation-object-of
           :initarg :object
           :initform nil)
   (attributes :reader authored-relation-attributes-of
               :initarg :attributes
               :initform nil)))

(defclass authored-relation-artifact ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (artifact-kind :reader authored-relation-artifact-kind-of
                  :initarg :artifact-kind
                  :initform :authored-relation-artifact)
   (workflow-role :reader authored-relation-artifact-workflow-role-of
                  :initarg :workflow-role
                  :initform nil)
   (compiler-pipeline
     :reader authored-relation-artifact-compiler-pipeline-of
     :initarg :compiler-pipeline
     :initform nil)
   (semantic-roles
     :reader authored-relation-artifact-semantic-roles-of
     :initarg :semantic-roles
     :initform nil)
   (semantic-relations
     :reader authored-relation-artifact-semantic-relations-of
     :initarg :semantic-relations
     :initform nil)
   (behavior-relations
     :reader authored-relation-artifact-behavior-relations-of
     :initarg :behavior-relations
     :initform nil)
   (layout-relations
     :reader authored-relation-artifact-layout-relations-of
     :initarg :layout-relations
     :initform nil)
   (relations :reader authored-relation-artifact-relations-of
              :initarg :relations
              :initform nil)
   (compiled-targets
     :reader authored-relation-artifact-compiled-targets-of
     :initarg :compiled-targets
     :initform nil)
   (findings :reader authored-relation-artifact-findings-of
             :initarg :findings
             :initform nil)))

(defclass authored-relation-artifact-source ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (source-kind :reader authored-relation-artifact-source-kind-of
                :initarg :source-kind
                :initform :repo-native-lisp)
   (source-path :reader authored-relation-artifact-source-path-of
                :initarg :source-path
                :initform nil)
   (schema-version :reader authored-relation-artifact-source-schema-version-of
                   :initarg :schema-version
                   :initform 1)
   (artifact-id :reader authored-relation-artifact-source-artifact-id-of
                :initarg :artifact-id)
   (artifact-title :reader authored-relation-artifact-source-artifact-title-of
                   :initarg :artifact-title)
   (artifact-summary :reader authored-relation-artifact-source-artifact-summary-of
                     :initarg :artifact-summary
                     :initform nil)
   (workflow-role :reader authored-relation-artifact-source-workflow-role-of
                  :initarg :workflow-role
                  :initform nil)
   (compiler-pipeline
     :reader authored-relation-artifact-source-compiler-pipeline-of
     :initarg :compiler-pipeline
     :initform nil)
   (semantic-role-definitions
     :reader authored-relation-artifact-source-semantic-role-definitions-of
     :initarg :semantic-role-definitions
     :initform nil)
   (relation-definitions
     :reader authored-relation-artifact-source-relation-definitions-of
     :initarg :relation-definitions
     :initform nil)
   (compiled-targets
     :reader authored-relation-artifact-source-compiled-targets-of
     :initarg :compiled-targets
     :initform nil)
   (findings :reader authored-relation-artifact-source-findings-of
             :initarg :findings
             :initform nil)))

(defclass compiled-artifact ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (summary :reader summary-of
            :initarg :summary
            :initform nil)
   (artifact-kind :reader compiled-artifact-kind-of
                  :initarg :artifact-kind
                  :initform :compiled-artifact)
   (authored-artifact :reader compiled-artifact-authored-artifact-of
                      :initarg :authored-artifact
                      :initform nil)
   (compiler-stage :reader compiled-artifact-compiler-stage-of
                   :initarg :compiler-stage
                   :initform nil)
   (compiler-inputs :reader compiled-artifact-compiler-inputs-of
                    :initarg :compiler-inputs
                    :initform nil)
   (relations :reader compiled-artifact-relations-of
              :initarg :relations
              :initform nil)
   (findings :reader compiled-artifact-findings-of
             :initarg :findings
             :initform nil)))

(defclass compiled-behavior-artifact (compiled-artifact)
  ((primary-machine :reader compiled-behavior-artifact-primary-machine-of
                    :initarg :primary-machine
                    :initform nil)
   (primary-machine-scxml
     :reader compiled-behavior-artifact-primary-machine-scxml-of
     :initarg :primary-machine-scxml
     :initform nil)
   (related-machines :reader compiled-behavior-artifact-related-machines-of
                     :initarg :related-machines
                     :initform nil)
   (related-machine-scxml
     :reader compiled-behavior-artifact-related-machine-scxml-of
     :initarg :related-machine-scxml
     :initform nil)))

(defclass compiled-layout-artifact (compiled-artifact)
  ((pane-relations :reader compiled-layout-artifact-pane-relations-of
                   :initarg :pane-relations
                   :initform nil)
   (comparison-relations
     :reader compiled-layout-artifact-comparison-relations-of
     :initarg :comparison-relations
     :initform nil)
   (layout-spec :reader compiled-layout-artifact-layout-spec-of
                :initarg :layout-spec
                :initform nil)))

(defun make-authored-relation-role (&rest initargs)
  (apply #'make-instance 'authored-relation-role initargs))

(defun make-authored-relation (&rest initargs)
  (apply #'make-instance 'authored-relation initargs))

(defun make-authored-relation-artifact (&rest initargs)
  (apply #'make-instance 'authored-relation-artifact initargs))

(defun make-authored-relation-artifact-source (&rest initargs)
  (apply #'make-instance 'authored-relation-artifact-source initargs))

(defun make-compiled-behavior-artifact (&rest initargs)
  (apply #'make-instance 'compiled-behavior-artifact initargs))

(defun make-compiled-layout-artifact (&rest initargs)
  (apply #'make-instance 'compiled-layout-artifact initargs))

(defun authored-relation-artifact-relations-by-layer (artifact layer)
  (remove layer
          (authored-relation-artifact-relations-of artifact)
          :key #'authored-relation-layer-of
          :test-not #'eq))

(defun authored-relation-artifact-source-relations-by-layer (source layer)
  (remove layer
          (authored-relation-artifact-source-relation-definitions-of source)
          :key (lambda (definition) (getf definition :layer))
          :test-not #'eq))

(defun authored-relation-artifact-source-role-count (source)
  (length
   (authored-relation-artifact-source-semantic-role-definitions-of source)))

(defun authored-relation-artifact-source-relation-count (source)
  (length (authored-relation-artifact-source-relation-definitions-of source)))

(defun compiled-artifact-derived-p (artifact authored-artifact)
  (eq authored-artifact
      (compiled-artifact-authored-artifact-of artifact)))

(defun compiled-behavior-artifact-machine (artifact &optional (key :primary))
  (if (eq key :primary)
      (compiled-behavior-artifact-primary-machine-of artifact)
      (cdr (assoc key
                  (compiled-behavior-artifact-related-machines-of artifact)
                  :test #'eq))))

(defun compiled-behavior-artifact-machine-scxml (artifact
                                                 &optional (key :primary))
  (if (eq key :primary)
      (compiled-behavior-artifact-primary-machine-scxml-of artifact)
      (cdr (assoc key
                  (compiled-behavior-artifact-related-machine-scxml-of artifact)
                  :test #'eq))))

(defun authored-relation-artifact-display-label (object)
  (or (title-of object)
      (id-of object)
      (format nil "~A" (class-name (class-of object)))))

(defmethod print-object ((object authored-relation-role) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (authored-relation-artifact-display-label object))))

(defmethod print-object ((object authored-relation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (authored-relation-artifact-display-label object))))

(defmethod print-object ((object authored-relation-artifact) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (authored-relation-artifact-display-label object))))

(defmethod print-object ((object authored-relation-artifact-source) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (authored-relation-artifact-display-label object))))

(defmethod print-object ((object compiled-artifact) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (authored-relation-artifact-display-label object))))
