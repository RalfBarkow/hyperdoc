;;;; Smoke tests for first-class DMX workspace-journal sink boundaries
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun journal-sink-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun journal-sink-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected ~S but got ~S" message expected actual)))

(defun journal-sink-test-payload (title)
  (let ((children (make-hash-table :test #'equal)))
    (setf (gethash hyperdoc::*dmx-notes-title-type-uri* children) title)
    (list :external-key (format nil "hyperdoc:test/~A" title)
          :type-uri hyperdoc::*dmx-notes-note-type-uri*
          :value title
          :children children)))

(defun journal-sink-test-snapshot
    (subject-key workspace-topicmap-id &key topic-id subject-kind title)
  (hyperdoc::dmx-workspace-journal-snapshot-from-payload
   subject-key
   "uri"
   subject-key
   workspace-topicmap-id
   (hyperdoc::dmx-workspace-journal-payload-json-from-payload
    (journal-sink-test-payload (or title "Journal sink smoke")))
   :subject-uri subject-key
   :subject-kind (or subject-kind "workspace-topic")
   :ownership-class "hyperdoc-test-topic"
   :topic-id topic-id
   :in-topicmap t
   :workspace-id 919815))

(defun run-dmx-workspace-journal-default-sink-smoke-test ()
  (journal-sink-assert-true
   (not (eq hyperdoc::*workspace-journal-sink* :dmx))
   "Default workspace journal sink must not be DMX")
  (journal-sink-assert-equal
   nil
   hyperdoc::*allow-dmx-workspace-journal-writes*
   "DMX workspace-journal writes must be opt-in by default"))

(defun run-dmx-workspace-journal-dmx-opt-in-smoke-test ()
  (let* ((previous
          (hyperdoc::dmx-workspace-journal-absent-snapshot
           "hyperdoc:test/dmx-opt-in"
           "uri"
           "hyperdoc:test/dmx-opt-in"
           919822
           :subject-uri "hyperdoc:test/dmx-opt-in"
           :subject-kind "workspace-topic"))
         (after
          (journal-sink-test-snapshot
           "hyperdoc:test/dmx-opt-in"
           919822
           :topic-id 936040)))
    (let ((hyperdoc::*allow-dmx-workspace-journal-writes* nil))
      (multiple-value-bind (events diagnostic)
          (hyperdoc::record-workspace-transition
           :dmx
           previous
           after
           919822
           :client (make-instance 'hyperdoc::null-dmx-import-client))
        (journal-sink-assert-equal
         nil
         events
         "DMX sink must not emit events without explicit opt-in")
        (journal-sink-assert-equal
         :blocked
         (getf diagnostic :journal-status)
         "DMX sink must report blocked when opt-in is missing")
        (journal-sink-assert-equal
         :dmx-journal-write-disabled
         (getf diagnostic :reason)
         "DMX sink block reason must identify the disabled write gate")))))

(defun run-dmx-workspace-journal-recursion-guard-smoke-test ()
  (let* ((subject-key "hyperdoc:mcp/workspace-journal/workspace-journal-test")
         (previous
          (hyperdoc::dmx-workspace-journal-absent-snapshot
           subject-key
           "uri"
           subject-key
           919822
           :subject-uri subject-key
           :subject-kind "workspace-journal"))
         (after
          (journal-sink-test-snapshot
           subject-key
           919822
           :topic-id 936041
           :subject-kind "workspace-journal")))
    (let ((hyperdoc::*allow-dmx-workspace-journal-writes* t))
      (multiple-value-bind (events diagnostic)
          (hyperdoc::record-workspace-transition
           :dmx
           previous
           after
           919822
           :client (make-instance 'hyperdoc::null-dmx-import-client))
        (journal-sink-assert-equal
         nil
         events
         "Journal-of-journal attempt must not emit events")
        (journal-sink-assert-equal
         :blocked
         (getf diagnostic :journal-status)
         "Journal-of-journal attempt must be blocked")
        (journal-sink-assert-equal
         :workspace-journal-recursion
         (getf diagnostic :reason)
         "Journal-of-journal attempt must identify recursion guard")))))

(defun run-dmx-workspace-journal-local-sink-smoke-test ()
  (let ((hyperdoc::*hyperdoc-local-workspace-journal-write-files-p* nil))
    (hyperdoc::clear-hyperdoc-local-workspace-journal-store)
    (let* ((subject-key "hyperdoc:test/local-sink")
           (previous
            (hyperdoc::dmx-workspace-journal-absent-snapshot
             subject-key
             "uri"
             subject-key
             919822
             :subject-uri subject-key
             :subject-kind "workspace-topic"))
           (after
            (journal-sink-test-snapshot
             subject-key
             919822
             :topic-id 936040)))
      (multiple-value-bind (events diagnostic)
          (hyperdoc::record-workspace-transition
           :hyperdoc-local
           previous
           after
           919822
           :client (make-instance 'hyperdoc::null-dmx-import-client))
        (journal-sink-assert-true
         (plusp (length events))
         "HyperDoc-local sink must emit bounded local journal events")
        (journal-sink-assert-equal
         :hyperdoc-local
         (getf diagnostic :journal-sink)
         "HyperDoc-local sink must report local journal authority")
        (journal-sink-assert-true
         (gethash subject-key
                  hyperdoc::*hyperdoc-local-workspace-journal-streams*)
         "HyperDoc-local sink must store the stream in the local journal store")))))

(defun run-dmx-workspace-annotation-default-sink-no-dmx-journal-write-smoke-test ()
  (let ((hyperdoc::*workspace-journal-sink* :hyperdoc-local)
        (hyperdoc::*allow-dmx-workspace-journal-writes* nil)
        (hyperdoc::*hyperdoc-local-workspace-journal-write-files-p* nil))
    (hyperdoc::clear-hyperdoc-local-workspace-journal-store)
    (let* ((client (make-instance 'hyperdoc::memory-dmx-import-client
                                  :next-topic-id 936100))
           (annotation (make-test-dock-annotation
                        :note "Default sink avoids DMX journal companion"))
           (_result
            (hyperdoc::execute-dmx-workspace-annotation-write-from-object
             annotation
             :workspace-id *dmx-annotations-smoke-workspace-id*
             :workspace-topicmap-id
             *dmx-annotations-smoke-workspace-topicmap-id*
             :client client
             :dry-run nil
             :storage-mode
             hyperdoc::*dmx-workspace-annotation-compatibility-storage-mode*))
           (journal-topic-keys '()))
      (declare (ignore _result))
      (maphash (lambda (external-key _topic)
                 (declare (ignore _topic))
                 (when (hyperdoc::dmx-string-prefix-p
                        hyperdoc::*hyperdoc-workspace-journal-uri-prefix*
                        external-key)
                   (push external-key journal-topic-keys)))
               (hyperdoc::topics-by-external-key-of client))
      (journal-sink-assert-true
       (plusp (hash-table-count (hyperdoc::topics-by-external-key-of client)))
       "Annotation persistence with default local sink must still persist an annotation topic in memory")
      (journal-sink-assert-equal
       nil
       journal-topic-keys
       "Annotation persistence with default local sink must not create a DMX workspace-journal companion topic")
      (journal-sink-assert-true
       (plusp (hash-table-count
               hyperdoc::*hyperdoc-local-workspace-journal-streams*))
       "Annotation persistence with default local sink must leave a HyperDoc-local journal trace"))))

(defun run-dmx-workspace-journal-sink-smoke-tests ()
  (run-dmx-workspace-journal-default-sink-smoke-test)
  (run-dmx-workspace-journal-dmx-opt-in-smoke-test)
  (run-dmx-workspace-journal-recursion-guard-smoke-test)
  (run-dmx-workspace-journal-local-sink-smoke-test)
  (run-dmx-workspace-annotation-default-sink-no-dmx-journal-write-smoke-test)
  t)
