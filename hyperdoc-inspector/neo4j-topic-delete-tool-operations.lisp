;;;; Inspector views for HyperdocNeo4jTopicDeleteTool operation metadata
;;
;; These views are intentionally read-only. They surface command metadata and
;; materialized command previews, but never execute the Java tool.

(in-package :hyperdoc/inspector)

(defun neo4j-topic-delete-tool-operation-string (value)
  (cond
    ((null value) "n/a")
    ((stringp value) value)
    ((keywordp value) (string-downcase (string value)))
    ((symbolp value) (string-downcase (string value)))
    ((listp value)
     (format nil "~{~A~^, ~}"
             (mapcar #'neo4j-topic-delete-tool-operation-string value)))
    (t
     (format nil "~A" value))))

(defun neo4j-topic-delete-tool-operation-lines (operations)
  (cons
   "command | mode | arity | destructive | confirmation token | safety"
   (mapcar
    (lambda (operation)
      (format nil "~A | ~A | ~D | ~A | ~A | ~A"
              (getf operation :command)
              (neo4j-topic-delete-tool-operation-string
               (getf operation :mode))
              (getf operation :arity)
              (if (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-destructive-p
                   operation)
                  "yes"
                  "no")
              (or (getf operation :confirmation-token) "n/a")
              (neo4j-topic-delete-tool-operation-string
               (getf operation :safety-classification))))
    operations)))

(defun neo4j-topic-delete-tool-lines-to-string (lines)
  (with-output-to-string (stream)
    (dolist (line lines)
      (write-string line stream)
      (terpri stream))))

(defmethod views:text-representation
    ((model hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model))
  (hyperdoc::title-of model))

(views:defview 👀overview
    (model hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model)
  (let* ((data
          (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model-data-of
           model))
         (tool (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-ir-tool
                data))
         (operations
          (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model-operations-of
           model)))
    (views:html-view :title "Overview" :priority 1
                     (views:html
                      (:p (views:esc (hyperdoc::summary-of model)))
                      (:table :class "inspector-table"
                              (:tr (:td "Tool id")
                                   (:td (:tt (views:esc (getf tool :id)))))
                              (:tr (:td "Class")
                                   (:td (:tt (views:esc (getf tool :class-name)))))
                              (:tr (:td "Source file")
                                   (:td (:tt (views:esc (getf tool :source-file)))))
                              (:tr (:td "Operation count")
                                   (:td (views:esc (format nil "~D"
                                                           (length operations)))))
                              (:tr (:td "Execution")
                                   (:td (views:esc
                                         "Read-only metadata and command previews only."))))))))

(views:defview 👀operations
    (model hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model)
  (let ((operations
         (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model-operations-of
          model)))
    (views:html-view :title "Operations" :priority 2
                     (views:html
                      (:pre
                       (views:esc
                        (neo4j-topic-delete-tool-lines-to-string
                         (neo4j-topic-delete-tool-operation-lines operations))))))))

(views:defview 👀safety-classification
    (model hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model)
  (let ((operations
         (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model-operations-of
          model)))
    (views:html-view :title "Safety classification" :priority 3
                     (views:html
                      (:pre
                       (views:esc
                        (neo4j-topic-delete-tool-lines-to-string
                         (cons
                          "command | mode | destructive | warning"
                          (mapcar
                           (lambda (operation)
                             (format nil "~A | ~A | ~A | ~A"
                                     (getf operation :command)
                                     (neo4j-topic-delete-tool-operation-string
                                      (getf operation :mode))
                                     (if (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-destructive-p
                                          operation)
                                         "yes"
                                         "no")
                                     (getf operation :warning)))
                           operations)))))))))

(views:defview 👀command-previews
    (model hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model)
  (let ((operations
         (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model-operations-of
          model)))
    (views:html-view :title "Command previews" :priority 4
                     (views:html
                      (:p (views:esc
                           "Previews are materialized strings only; the inspector does not run the Java tool."))
                      (:pre
                       (views:esc
                        (with-output-to-string (stream)
                          (dolist (operation operations)
                            (write-string
                             (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-command-preview
                              operation)
                             stream)
                            (terpri stream)))))))))

(views:defview 👀source-ir
    (model hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model)
  (views:html-view :title "Source IR" :priority 5
                   (views:html
                    (:pre
                     (views:esc
                      (prin1-to-string
                       (hyperdoc::hyperdoc-neo4j-topic-delete-tool-operation-model-data-of
                        model)))))))
