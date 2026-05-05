;;;; Inspectable operation IR for HyperdocNeo4jTopicDeleteTool
;;
;; This file intentionally models command metadata only. It never shells out,
;; opens a Neo4j database, or generates graph mutation code.

(in-package :hyperdoc)

(defparameter +hyperdoc-neo4j-topic-delete-tool-operation-ir-relative-path+
  "tools/hyperdoc-neo4j-topic-delete-tool.operations.sexp")

(defclass hyperdoc-neo4j-topic-delete-tool-operation-model ()
  ((id :reader id-of
       :initarg :id
       :initform "HyperdocNeo4jTopicDeleteTool")
   (title :reader title-of
          :initarg :title
          :initform "Hyperdoc Neo4j Topic Delete Tool operation model")
   (summary :reader summary-of
            :initarg :summary
            :initform "Source-parity operation model for the offline HyperDoc Neo4j topic delete helper.")
   (data :reader hyperdoc-neo4j-topic-delete-tool-operation-model-data-of
         :initarg :data)))

(defmethod print-object ((object hyperdoc-neo4j-topic-delete-tool-operation-model)
                         stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (id-of object))))

(defun hyperdoc-neo4j-topic-delete-tool-operation-ir-path ()
  (asdf:system-relative-pathname
   :hyperdoc
   +hyperdoc-neo4j-topic-delete-tool-operation-ir-relative-path+))

(defun read-hyperdoc-neo4j-topic-delete-tool-operation-ir
    (&key (pathname (hyperdoc-neo4j-topic-delete-tool-operation-ir-path)))
  (with-open-file (stream pathname :direction :input)
    (let ((*read-eval* nil))
      (read stream))))

(defun hyperdoc-neo4j-topic-delete-tool-operation-ir-tool (ir)
  (getf ir :tool))

(defun hyperdoc-neo4j-topic-delete-tool-operation-ir
    (&key (pathname (hyperdoc-neo4j-topic-delete-tool-operation-ir-path)))
  (let ((ir (read-hyperdoc-neo4j-topic-delete-tool-operation-ir
             :pathname pathname)))
    (unless (and (consp ir)
                 (getf ir :tool)
                 (getf (getf ir :tool) :operations))
      (error "Invalid HyperdocNeo4jTopicDeleteTool operation IR: ~S"
             pathname))
    ir))

(defun hyperdoc-neo4j-topic-delete-tool-operations
    (&optional (ir (hyperdoc-neo4j-topic-delete-tool-operation-ir)))
  (getf (hyperdoc-neo4j-topic-delete-tool-operation-ir-tool ir)
        :operations))

(defun hyperdoc-neo4j-topic-delete-tool-operation-by-id
    (id &optional (ir (hyperdoc-neo4j-topic-delete-tool-operation-ir)))
  (find id
        (hyperdoc-neo4j-topic-delete-tool-operations ir)
        :key (lambda (operation)
               (getf operation :id))
        :test #'equal))

(defun hyperdoc-neo4j-topic-delete-tool-operation-by-command
    (command &optional (ir (hyperdoc-neo4j-topic-delete-tool-operation-ir)))
  (find command
        (hyperdoc-neo4j-topic-delete-tool-operations ir)
        :key (lambda (operation)
               (getf operation :command))
        :test #'string=))

(defun hyperdoc-neo4j-topic-delete-tool-operation-argument-names
    (operation)
  (mapcar (lambda (argument)
            (getf argument :name))
          (getf operation :arguments)))

(defun hyperdoc-neo4j-topic-delete-tool-operation-destructive-p
    (operation)
  (or (getf operation :destructive-p)
      (member (getf operation :mode)
              '(:write :emergency-write)
              :test #'eq)))

(defun hyperdoc-neo4j-topic-delete-tool-operation-command-preview
    (operation)
  (format nil "java HyperdocNeo4jTopicDeleteTool ~A~{ <~A>~}"
          (getf operation :command)
          (hyperdoc-neo4j-topic-delete-tool-operation-argument-names
           operation)))

(defun hyperdoc-neo4j-topic-delete-tool-operation-metadata
    (&optional (ir (hyperdoc-neo4j-topic-delete-tool-operation-ir)))
  (mapcar
   (lambda (operation)
     (list
      :id (getf operation :id)
      :command (getf operation :command)
      :mode (getf operation :mode)
      :arity (getf operation :arity)
      :arguments
      (hyperdoc-neo4j-topic-delete-tool-operation-argument-names operation)
      :confirmation-token (getf operation :confirmation-token)
      :requires-prior-plan-p (getf operation :requires-prior-plan-p)
      :destructive-p
      (hyperdoc-neo4j-topic-delete-tool-operation-destructive-p operation)
      :safety-classification (getf operation :safety-classification)
      :warning (getf operation :warning)
      :command-preview
      (hyperdoc-neo4j-topic-delete-tool-operation-command-preview
       operation)))
   (hyperdoc-neo4j-topic-delete-tool-operations ir)))

(defun make-hyperdoc-neo4j-topic-delete-tool-operation-model
    (&key (data (hyperdoc-neo4j-topic-delete-tool-operation-ir)))
  (let ((tool (hyperdoc-neo4j-topic-delete-tool-operation-ir-tool data)))
    (make-instance
     'hyperdoc-neo4j-topic-delete-tool-operation-model
     :id (getf tool :id)
     :title "Hyperdoc Neo4j Topic Delete Tool operation model"
     :summary "Inspectable source-parity model of the Java tool command surface; no Neo4j database access or destructive execution is provided."
     :data data)))

(defun hyperdoc-neo4j-topic-delete-tool-operation-model-operations-of
    (model)
  (hyperdoc-neo4j-topic-delete-tool-operations
   (hyperdoc-neo4j-topic-delete-tool-operation-model-data-of model)))
