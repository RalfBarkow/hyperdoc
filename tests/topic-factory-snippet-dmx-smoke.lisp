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

(defparameter *topic-factory-snippet-dmx-custom-topic-value*
  "HyperDoc localhost FedWiki promotion workflow")

(defun run-topic-factory-snippet-dmx-plan-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 7000))
         (plan (hyperdoc::plan-topic-factory-snippet-dmx-write
                nil
                :workspace-topicmap-id
                *topic-factory-snippet-dmx-workspace-topicmap-id*
                :client client))
         (payload (hyperdoc::topic-factory-snippet-dmx-write-plan-payload plan))
         (children (getf payload :children))
         (provenance-json
           (gethash hyperdoc::*dmx-topic-factory-snippet-provenance-type-uri*
                    children))
         (provenance-object (shasht:read-json provenance-json))
         (fragment-ordinals
           (sort (coerce (gethash "source_fragment_ordinals" provenance-object)
                         'list)
                 #'<)))
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
             provenance-json)
     "Payload provenance must preserve the canonical FedWiki page id")
    (assert-true
     (search "pages/the-life-cycle-of-collective-knowledge"
             provenance-json)
     "Payload provenance must preserve the repo-relative FedWiki page path")
    (assert-equal "story-item-fragment"
                  (gethash "provenance_granularity" provenance-object)
                  "Payload provenance JSON must preserve fragment-level provenance granularity")
    (assert-equal '(0 3 4 5 6)
                  fragment-ordinals
     "Payload provenance JSON must preserve fragment ordinals with canonical provenance")
    (assert-true
     (not (search "/Users/" provenance-json))
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

(defun run-topic-factory-snippet-dmx-custom-topic-value-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 7000))
         (plan (hyperdoc::plan-topic-factory-snippet-dmx-write
                nil
                :workspace-topicmap-id
                *topic-factory-snippet-dmx-workspace-topicmap-id*
                :client client
                :topic-value *topic-factory-snippet-dmx-custom-topic-value*))
         (payload (hyperdoc::topic-factory-snippet-dmx-write-plan-payload plan))
         (output
           (with-output-to-string (stream)
             (hyperdoc::execute-topic-factory-snippet-dmx-write
              nil
              :workspace-topicmap-id
              *topic-factory-snippet-dmx-workspace-topicmap-id*
              :client client
              :topic-value *topic-factory-snippet-dmx-custom-topic-value*
              :dry-run t
              :stream stream))))
    (assert-equal *topic-factory-snippet-dmx-custom-topic-value*
                  (getf payload :value)
                  "Custom topic-value override must be preserved in the DMX payload")
    (assert-equal *topic-factory-snippet-dmx-custom-topic-value*
                  (hyperdoc::topic-factory-snippet-dmx-write-plan-topic-value
                   plan)
                  "Custom topic-value override must be preserved in the write plan")
    (assert-true
     (search "TOPIC_FACTORY_SNIPPET_DMX_TOPIC value=\"HyperDoc localhost FedWiki promotion workflow\""
             output)
     "Dry-run evidence must expose the custom DMX topic title override")))

(defun run-topic-factory-snippet-dmx-zettel-payload-smoke-test ()
  (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                :next-topic-id 7000))
         (plan (hyperdoc::plan-topic-factory-snippet-dmx-write
                nil
                :workspace-topicmap-id
                *topic-factory-snippet-dmx-workspace-topicmap-id*
                :client client
                :topic-type-uri hyperdoc::*dmx-zettelkasten-zettel-type-uri*
                :topic-value *topic-factory-snippet-dmx-custom-topic-value*))
         (payload (hyperdoc::topic-factory-snippet-dmx-write-plan-payload plan))
         (children (getf payload :children))
         (json (hyperdoc::dmx-import-json-object payload))
         (json-children (gethash "children" json))
         (json-title
           (gethash hyperdoc::*dmx-zettelkasten-zettel-title-type-uri*
                    json-children))
         (json-content
           (gethash hyperdoc::*dmx-zettelkasten-zettel-content-type-uri*
                    json-children)))
    (assert-equal hyperdoc::*dmx-zettelkasten-zettel-type-uri*
                  (getf payload :type-uri)
                  "Zettel payload must preserve the explicit zettel topic type")
    (assert-equal *topic-factory-snippet-dmx-custom-topic-value*
                  (getf payload :value)
                  "Zettel payload must preserve the explicit human-facing topic value")
    (assert-equal *topic-factory-snippet-dmx-custom-topic-value*
                  (gethash hyperdoc::*dmx-zettelkasten-zettel-title-type-uri*
                           children)
                  "Zettel payload must map the explicit topic value into the installed zettel title child")
    (assert-true
     (search "defun THE-LIFE-CYCLE-OF-COLLECTIVE-KNOWLEDGE-TOPIC"
             (gethash hyperdoc::*dmx-zettelkasten-zettel-content-type-uri*
                      children))
     "Zettel payload must map the snippet text into the installed zettel content child")
    (assert-equal *topic-factory-snippet-dmx-custom-topic-value*
                  (gethash "value" json)
                  "HTTP JSON must preserve the explicit human-facing topic value at the top level")
    (assert-equal *topic-factory-snippet-dmx-custom-topic-value*
                  json-title
                  "HTTP JSON must serialize the zettel title child as its plain TopicModel child value")
    (assert-true
     (search "defun THE-LIFE-CYCLE-OF-COLLECTIVE-KNOWLEDGE-TOPIC"
             json-content)
     "HTTP JSON must preserve the zettel content text as the plain TopicModel child value")))

(defun run-topic-factory-snippet-dmx-http-no-content-plan-smoke-test ()
  (let ((original (symbol-function 'drakma:http-request)))
    (unwind-protect
         (progn
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method &allow-other-keys)
                   (assert-true (search "/core/topic/uri/" url)
                                "HTTP lookup test must probe the DMX topic URI endpoint")
                   (assert-equal :get method
                                 "HTTP lookup test must only exercise the lookup GET")
                   (values (make-string-input-stream "") 204 nil nil nil "No Content")))
           (let* ((client (make-instance 'hyperdoc::http-dmx-import-client
                                         :base-url "https://dmx.ralfbarkow.ch"))
                  (plan (hyperdoc::plan-topic-factory-snippet-dmx-write
                         nil
                         :workspace-topicmap-id
                         *topic-factory-snippet-dmx-workspace-topicmap-id*
                         :client client)))
             (assert-equal :create
                           (hyperdoc::topic-factory-snippet-dmx-write-plan-topic-action
                            plan)
                           "HTTP 204 lookup must still classify the snippet write as CREATE")
             (assert-equal :add
                           (hyperdoc::topic-factory-snippet-dmx-write-plan-topicmap-action
                            plan)
                           "HTTP 204 lookup must still classify missing topicmap membership as ADD")))
      (setf (symbol-function 'drakma:http-request) original))))

(defun run-topic-factory-snippet-dmx-smoke-tests ()
  (run-topic-factory-snippet-dmx-plan-smoke-test)
  (run-topic-factory-snippet-dmx-dry-run-create-smoke-test)
  (run-topic-factory-snippet-dmx-dry-run-update-smoke-test)
  (run-topic-factory-snippet-dmx-custom-topic-value-smoke-test)
  (run-topic-factory-snippet-dmx-zettel-payload-smoke-test)
  (run-topic-factory-snippet-dmx-http-no-content-plan-smoke-test)
  (format t "~&Topic-factory snippet DMX smoke tests passed.~%")
  t)
