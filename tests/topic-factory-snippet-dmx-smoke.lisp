;;;; Smoke tests for DMX topic-factory snippet writer
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-TOPIC-FACTORY-SNIPPET-DMX-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defparameter *topic-factory-snippet-dmx-workspace-topicmap-id* 919822)

(defun run-topic-factory-snippet-dmx-plan-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 7000))
         (plan (hyperdoc::plan-topic-factory-snippet-dmx-write
                nil
                :workspace-topicmap-id
                *topic-factory-snippet-dmx-workspace-topicmap-id*
                :client client))
         (payload (hyperdoc::topic-factory-snippet-dmx-write-plan-payload plan))
         (children (getf payload :children)))
    (assert-equal :create
                  (hyperdoc::topic-factory-snippet-dmx-write-plan-topic-action plan)
                  "Fresh snippet plan must start with CREATE")
    (assert-equal :add
                  (hyperdoc::topic-factory-snippet-dmx-write-plan-topicmap-action plan)
                  "Fresh snippet plan must add the topic to the workspace topicmap")
    (assert-equal "hyperdoc:topic-factory-snippet/the-life-cycle-of-collective-knowledge-topic-set"
                  (hyperdoc::topic-factory-snippet-dmx-write-plan-uri plan)
                  "Snippet plan must keep the stable snippet URI")
    (assert-equal "The Life Cycle of Collective Knowledge"
                  (gethash hyperdoc::*dmx-topic-factory-snippet-page-title-type-uri*
                           children)
                  "Payload must keep the related HyperDoc page title")
    (assert-equal "assets/the-life-cycle-of-collective-knowledge-topic.lisp"
                  (gethash hyperdoc::*dmx-topic-factory-snippet-source-file-type-uri*
                           children)
                  "Payload must use the repo-relative snippet source path")
    (assert-equal "the-life-cycle-of-collective-knowledge"
                  (gethash hyperdoc::*dmx-topic-factory-snippet-topic-id-type-uri*
                           children)
                  "Payload must keep the related umbrella topic id")
    (assert-true
     (search "fedwiki:wiki.ralfbarkow.ch/the-life-cycle-of-collective-knowledge"
             (gethash hyperdoc::*dmx-topic-factory-snippet-provenance-type-uri*
                      children))
     "Payload provenance must preserve the canonical FedWiki page id")
    (assert-true
     (search "pages/the-life-cycle-of-collective-knowledge"
             (gethash hyperdoc::*dmx-topic-factory-snippet-provenance-type-uri*
                      children))
     "Payload provenance must preserve the repo-relative FedWiki page path")
    (assert-true
     (not (search "/Users/"
                  (gethash hyperdoc::*dmx-topic-factory-snippet-provenance-type-uri*
                           children)))
     "Payload provenance must not preserve machine-local absolute paths")
    (assert-true
     (search "defun THE-LIFE-CYCLE-OF-COLLECTIVE-KNOWLEDGE-TOPIC"
             (gethash hyperdoc::*dmx-topic-factory-snippet-text-type-uri*
                      children))
     "Payload must carry the snippet text body")))

(defun run-topic-factory-snippet-dmx-dry-run-create-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 7000))
         (output
           (with-output-to-string (stream)
             (hyperdoc::execute-topic-factory-snippet-dmx-write
              nil
              :workspace-topicmap-id
              *topic-factory-snippet-dmx-workspace-topicmap-id*
              :client client
              :dry-run t
              :stream stream))))
    (assert-true (search "topic-action=CREATE" output)
                 "Dry-run create output must expose CREATE")
    (assert-true (search "topicmap-action=ADD" output)
                 "Dry-run create output must expose topicmap ADD")
    (assert-true (search "source=assets/the-life-cycle-of-collective-knowledge-topic.lisp"
                         output)
                 "Dry-run create output must expose the canonical repo-relative snippet path")
    (assert-equal 0 (hash-table-count (hyperdoc::topics-by-external-key-of client))
                  "Dry-run create must not mutate the memory client topic store")
    (assert-equal 0 (hash-table-count (hyperdoc::topicmap-memberships-of client))
                  "Dry-run create must not mutate the memory client topicmap memberships")))

(defun run-topic-factory-snippet-dmx-dry-run-update-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 7000))
         (bootstrap-plan (hyperdoc::plan-topic-factory-snippet-dmx-write
                          nil
                          :workspace-topicmap-id
                          *topic-factory-snippet-dmx-workspace-topicmap-id*
                          :client client))
         (uri (hyperdoc::topic-factory-snippet-dmx-write-plan-uri bootstrap-plan))
         (existing-topic (list :id 7010 :external-key uri)))
    (setf (gethash uri (hyperdoc::topics-by-external-key-of client))
          existing-topic)
    (hyperdoc::dmx-import-add-topic-to-topicmap
     client
     *topic-factory-snippet-dmx-workspace-topicmap-id*
     7010
     '(:x 10 :y 20 :visibility t :pinned nil))
    (let ((output
            (with-output-to-string (stream)
              (hyperdoc::execute-topic-factory-snippet-dmx-write
               nil
               :workspace-topicmap-id
               *topic-factory-snippet-dmx-workspace-topicmap-id*
               :client client
               :dry-run t
               :stream stream))))
      (assert-true (search "topic-action=UPDATE" output)
                   "Dry-run update output must expose UPDATE")
      (assert-true (search "topicmap-action=ALREADY-PRESENT" output)
                   "Dry-run update output must preserve the existing topicmap membership")
      (assert-equal existing-topic
                    (gethash uri (hyperdoc::topics-by-external-key-of client))
                    "Dry-run update must not mutate the existing topic entry")
      (assert-equal 1 (hash-table-count (hyperdoc::topicmap-memberships-of client))
                    "Dry-run update must not change topicmap membership count"))))

(defun run-topic-factory-snippet-dmx-smoke-tests ()
  (run-topic-factory-snippet-dmx-plan-smoke-test)
  (run-topic-factory-snippet-dmx-dry-run-create-smoke-test)
  (run-topic-factory-snippet-dmx-dry-run-update-smoke-test)
  (format t "~&Topic-factory snippet DMX smoke tests passed.~%")
  t)
