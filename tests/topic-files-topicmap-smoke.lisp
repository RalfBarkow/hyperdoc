;;;; Smoke tests for the topic source files topicmap inspector slice.

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-TOPIC-FILES-TOPICMAP-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun topic-files-topicmap-smoke-assert (condition message)
  (unless condition
    (error "~A" message)))

(defun topic-files-topicmap-smoke-db-path ()
  (merge-pathnames
   (format nil "topic-files-topicmap-smoke/topics-~36R.sqlite"
           (get-universal-time))
   (uiop:temporary-directory)))

(defun topic-files-topicmap-smoke-load-inspector-views (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun topic-files-topicmap-smoke-view-titles (object)
  (mapcar #'html-inspector-views:view-title
          (topic-files-topicmap-smoke-load-inspector-views object)))

(defun topic-files-topicmap-smoke-assert-view (titles title)
  (topic-files-topicmap-smoke-assert
   (member title titles :test #'string=)
   (format nil "Missing inspector view ~S in ~S" title titles)))

(defun run-topic-files-topicmap-smoke-tests ()
  (asdf:load-system :hyperdoc)
  (asdf:load-system :hyperdoc/inspector)
  (let* ((diagnostic (hyperdoc:make-topic-registry-diagnostic))
         (topicmap
           (hyperdoc:make-topic-files-topicmap
            :source-files
            (hyperdoc:topic-registry-diagnostic-loaded-topic-files-of
             diagnostic)
            :db-path (topic-files-topicmap-smoke-db-path))))
    (hyperdoc:materialize-topic-files-topicmap topicmap)
    (topic-files-topicmap-smoke-assert
     (> (length (hyperdoc::topic-files-topicmap-source-files-of topicmap)) 0)
     "Expected loaded topic source files")
    (topic-files-topicmap-smoke-assert
     (> (hyperdoc::topic-files-topicmap-table-count
         topicmap
         "topic_node")
        0)
     "Expected persisted topic_node rows")
    (topic-files-topicmap-smoke-assert
     (> (hyperdoc::topic-files-topicmap-table-count
         topicmap
         "topic_factory")
        0)
     "Expected persisted topic_factory rows")
    (let ((payload (hyperdoc:topic-files-topicmap-payload topicmap)))
      (topic-files-topicmap-smoke-assert
       (member :nodes payload)
       "Expected payload to include :nodes")
      (topic-files-topicmap-smoke-assert
       (member :edges payload)
       "Expected payload to include :edges"))
    (let ((titles (topic-files-topicmap-smoke-view-titles topicmap)))
      (dolist (title '("Overview" "Files" "Factories" "Topicmap" "SQLite"))
        (topic-files-topicmap-smoke-assert-view titles title))))
  (format t "~&Topic files topicmap smoke tests passed.~%")
  t)
