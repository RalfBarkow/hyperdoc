;;;; Topic files topicmap inspector topic objects.

(in-package :hyperdoc)

(defun topic-files-topicmap-inspector-topic ()
  (make-topic
   :id "topic-files-topicmap-inspector"
   :title "Topic Files Topicmap Inspector"
   :summary "Inspector slice that turns loaded topic source files into inspectable file, factory, topic, reference, and SQLite projection objects."
   :references '("Topic Files Topicmap Inspector"
                 "Topics HyperBook in HyperDoc"
                 "DM6 AppEmbed HyperDoc Inline Proof")))

(defun topic-files-topicmap-topic ()
  (make-topic
   :id "topic-files-topicmap"
   :title "Topic files topicmap"
   :summary "SQLite-backed projection object that materializes loaded topic source files into renderer-neutral topicmap payload nodes and edges."
   :references '("Topic Files Topicmap Inspector"
                 "Topic Files Topicmap Inspector")))

(defun topic-source-file-topic ()
  (make-topic
   :id "topic-source-file"
   :title "Topic source file"
   :summary "Inspectable source-file object for one loaded topic file, including parse status, package forms, factory records, and soft parse failures."
   :references '("Topic Files Topicmap Inspector"
                 "Topic files topicmap")))

(defun topic-factory-source-record-topic ()
  (make-topic
   :id "topic-factory-source-record"
   :title "Topic factory source record"
   :summary "Inspectable parser record for a defun whose body constructs a make-topic form, preserving static topic metadata when available."
   :references '("Topic Files Topicmap Inspector"
                 "Topic source file")))
