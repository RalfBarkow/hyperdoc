;;;; Smoke tests for DMX topic proxy wrapper mapping

(defpackage :hyperdoc/tests
  (:use :cl)
  (:export :run-dmx-topic-proxy-smoke-tests
           :run-check-runner-smoke-tests))

(in-package :hyperdoc/tests)

(defparameter *dmx-wrapper-smoke-specs*
  '((hyperdoc::concept-operational-definition 912384 912102)
    (hyperdoc::dmx-topic-912138 912138 912102)
    (hyperdoc::prepare-aarch64-image-topic 912384 912102)
    (hyperdoc::dmx-topic-912384 912384 912102)))

(defun expected-dmx-topicmap-url (topicmap-id)
  (format nil "https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/~D/topic/~D"
          topicmap-id
          topicmap-id))

(defun expected-dmx-core-topic-url (id)
  (format nil "https://dmx.ralfbarkow.ch/core/topic/~D?children=true&assocChildren=true"
          id))

(defun expected-dmx-workspace-object-url (id)
  (format nil "https://dmx.ralfbarkow.ch/workspaces/object/~D" id))

(defun expected-dmx-topicmap-memberships-url (id)
  (format nil "https://dmx.ralfbarkow.ch/topicmaps/object/~D" id))

(defun expected-dmx-workspace-owner-url (workspace-id)
  (format nil "https://dmx.ralfbarkow.ch/access-control/workspace/~D/owner"
          workspace-id))

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun assert-type (expected-type object message)
  (unless (eq expected-type (type-of object))
    (error "~A -- expected type: ~S actual type: ~S" message expected-type (type-of object))))

(defun run-one-wrapper-smoke-test (spec)
  (destructuring-bind (wrapper topic-id topicmap-id) spec
    (let ((proxy (funcall (symbol-function wrapper))))
      (assert-type 'hyperdoc::dmx-topic-proxy
                   proxy
                   (format nil "Wrapper ~S must return DMX proxy" wrapper))
      (assert-equal topic-id
                    (hyperdoc::dmx-topic-id-of proxy)
                    (format nil "Wrapper ~S topic-id" wrapper))
      (assert-equal topicmap-id
                    (hyperdoc::dmx-topicmap-id-of proxy)
                    (format nil "Wrapper ~S topicmap-id" wrapper))
      (assert-equal (expected-dmx-topicmap-url topicmap-id)
                    (hyperdoc::dmx-webclient-url proxy)
                    (format nil "Wrapper ~S URL" wrapper)))))

(defun make-smoke-json (label)
  (let ((table (make-hash-table :test #'equal)))
    (setf (gethash "value" table) label)
    table))

(defun run-topicmap-endpoint-regression-test ()
  (let* ((proxy (hyperdoc::make-dmx-topic-proxy :topic-id 912384
                                                :topicmap-id 912102))
         (book (hyperbook:hyperbook-of proxy))
         (calls nil)
         (topic-json (make-smoke-json "topic"))
         (topicmap-json (make-smoke-json "topicmap"))
         (original (symbol-function 'hyperdoc::dmx-fetch-json)))
    (clrhash (hyperdoc::dmx-cache-of book))
    (setf (hyperdoc::dmx-cache-order-of book) nil
          (hyperdoc::dmx-topic-data-of proxy) nil
          (hyperdoc::dmx-topicmap-data-of proxy) nil
          (hyperdoc::dmx-load-error-of proxy) nil)
    (unwind-protect
         (progn
           (setf (symbol-function 'hyperdoc::dmx-fetch-json)
                 (lambda (book endpoint &key parameters)
                   (declare (ignore book))
                   (push (list endpoint parameters) calls)
                   (cond
                     ((and (string= endpoint "/core/topic/912384")
                           (equal parameters
                                  (hyperdoc::dmx-children+assoc-parameters)))
                      topic-json)
                     ((and (string= endpoint "/core/topic/912102")
                           (equal parameters
                                  (hyperdoc::dmx-children+assoc-parameters)))
                      topicmap-json)
                     (t
                      (error "Unexpected DMX fetch call ~S ~S"
                             endpoint
                             parameters)))))
        (hyperdoc::ensure-dmx-topic-data proxy :force? t)
        (hyperdoc::ensure-dmx-topicmap-data proxy :force? t)
        (assert-equal topic-json
                      (hyperdoc::dmx-topic-data-of proxy)
                      "Topic data should come from /core/topic/<topic-id>")
        (assert-equal topicmap-json
                      (hyperdoc::dmx-topicmap-data-of proxy)
                      "Topicmap data should come from /core/topic/<topicmap-id>")
        (assert-equal (expected-dmx-core-topic-url 912102)
                      (hyperdoc::dmx-topicmap-core-topic-url proxy)
                      "Topicmap helper must expose the exact core-topic URL")
        (assert-true
         (member (list "/core/topic/912102"
                       (hyperdoc::dmx-children+assoc-parameters))
                 calls
                 :test #'equal)
         "Topicmap data fetch must use the core topic endpoint")
        (assert-true
         (notany (lambda (call)
                   (search "/topicmaps/" (first call)))
                 calls)
         "No /topicmaps/<id> fetch should remain in the exercised topicmap path"))
      (setf (symbol-function 'hyperdoc::dmx-fetch-json) original))))

(defun run-workspace-diagnostics-regression-test ()
  (let* ((missing-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922464))
         (fixed-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922586))
         (foreign-proxy (hyperdoc::make-dmx-shared-workspace-topic-proxy 922451))
         (book (hyperbook:hyperbook-of missing-proxy))
         (calls nil)
         (topicmap-json (make-smoke-json "context-window"))
         (original-http (symbol-function 'hyperdoc::dmx-http-request-body)))
    (labels ((make-membership (topicmap-id assoc-id &optional (value "context-window"))
               (let ((membership (make-hash-table :test #'equal))
                     (assoc (make-hash-table :test #'equal)))
                 (setf (gethash "id" membership) topicmap-id
                       (gethash "value" membership) value
                       (gethash "assoc" membership) assoc
                       (gethash "id" assoc) assoc-id)
                 membership))
             (make-topic-json (id uri type-uri value)
               (let ((json (make-hash-table :test #'equal))
                     (children (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) id
                       (gethash "uri" json) uri
                       (gethash "typeUri" json) type-uri
                       (gethash "value" json) value
                       (gethash "children" json) children)
                 json))
             (make-workspace-json (id value)
               (let ((json (make-hash-table :test #'equal)))
                 (setf (gethash "id" json) id
                       (gethash "typeUri" json) "dmx.workspaces.workspace"
                       (gethash "value" json) value
                       (gethash "children" json) (make-hash-table :test #'equal))
                 json)))
      (clrhash (hyperdoc::dmx-cache-of book))
      (setf (hyperdoc::dmx-cache-order-of book) nil)
      (dolist (proxy (list missing-proxy fixed-proxy foreign-proxy))
        (setf (hyperdoc::dmx-topic-data-of proxy) nil
              (hyperdoc::dmx-workspace-data-of proxy) nil
              (hyperdoc::dmx-workspace-owner-of proxy) nil
              (hyperdoc::dmx-topicmap-memberships-of proxy) nil
              (hyperdoc::dmx-diagnostics-of proxy) nil
              (hyperdoc::dmx-topicmap-data-of proxy) nil
              (hyperdoc::dmx-related-topics-of proxy) nil
              (hyperdoc::dmx-load-error-of proxy) nil))
      (unwind-protect
           (progn
             (setf (symbol-function 'hyperdoc::dmx-http-request-body)
                   (lambda (book endpoint &key parameters)
                     (declare (ignore book parameters))
                     (push endpoint calls)
                     (cond
                       ((string= endpoint "/core/topic/922464")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           922464
                           "hyperdoc:mcp/workspace-note/operational-definition-chunk-chunk-note-manifest-note-content-topic"
                           "dmx.notes.note"
                           "Operational definition: chunk, chunk note, manifest note, content topic"))
                         200
                         (expected-dmx-core-topic-url 922464)
                         "OK"))
                       ((string= endpoint "/core/topic/922586")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           922586
                           "hyperdoc:mcp/workspace-note/topic-922586"
                           "dmx.notes.note"
                           "Guarded workspace default verification note"))
                         200
                         (expected-dmx-core-topic-url 922586)
                         "OK"))
                       ((string= endpoint "/core/topic/922451")
                        (values
                         (hyperdoc::encode-json-string
                          (make-topic-json
                           922451
                           "hyperdoc:mcp/auth-probe-20260330-1"
                           "dmx.notes.note"
                           "auth probe"))
                         200
                         (expected-dmx-core-topic-url 922451)
                         "OK"))
                       ((string= endpoint "/core/topic/919822")
                        (values
                         (hyperdoc::encode-json-string topicmap-json)
                         200
                         (expected-dmx-core-topic-url 919822)
                         "OK"))
                       ((string= endpoint "/workspaces/object/922464")
                        (values "" 204 (expected-dmx-workspace-object-url 922464) "No Content"))
                       ((string= endpoint "/workspaces/object/922586")
                        (values
                         (hyperdoc::encode-json-string
                          (make-workspace-json 919815 "context-window"))
                         200
                         (expected-dmx-workspace-object-url 922586)
                         "OK"))
                       ((string= endpoint "/workspaces/object/922451")
                        (values "" 204 (expected-dmx-workspace-object-url 922451) "No Content"))
                       ((string= endpoint "/access-control/workspace/919815/owner")
                        (values "rgb" 200 (expected-dmx-workspace-owner-url 919815) "OK"))
                       ((string= endpoint "/topicmaps/object/922464")
                        (values
                         (hyperdoc::encode-json-string
                          (vector (make-membership 919822 922471)))
                         200
                         (expected-dmx-topicmap-memberships-url 922464)
                         "OK"))
                       ((string= endpoint "/topicmaps/object/922586")
                        (values
                         (hyperdoc::encode-json-string
                          (vector (make-membership 919822 922599)))
                         200
                         (expected-dmx-topicmap-memberships-url 922586)
                         "OK"))
                       ((string= endpoint "/topicmaps/object/922451")
                        (values
                         (hyperdoc::encode-json-string
                          (vector (make-membership 919822 922524)))
                         200
                         (expected-dmx-topicmap-memberships-url 922451)
                         "OK"))
                       (t
                        (error "Unexpected DMX diagnostics fetch ~S" endpoint)))))
             (hyperdoc::ensure-dmx-topic-diagnostics missing-proxy :force? t)
             (hyperdoc::ensure-dmx-topic-diagnostics fixed-proxy :force? t)
             (hyperdoc::ensure-dmx-topic-diagnostics foreign-proxy :force? t)
             (let ((missing (hyperdoc::dmx-diagnostics-of missing-proxy))
                   (fixed (hyperdoc::dmx-diagnostics-of fixed-proxy))
                   (foreign (hyperdoc::dmx-diagnostics-of foreign-proxy)))
               (assert-equal :in-topicmap-but-unassigned
                             (hyperdoc::dmx-topic-diagnostics-status missing)
                             "Missing-assignment topic must surface in-topicmap-but-unassigned")
               (assert-true
                (hyperdoc::dmx-topic-diagnostics-repair-needed-p missing)
                "Missing-assignment topic must flag repair-needed")
               (assert-equal 919822
                             (hyperdoc::dmx-topic-diagnostics-topicmap-id missing)
                             "Missing-assignment topic must keep the selected topicmap id")
               (assert-equal "operational-definition-chunk-chunk-note-manifest-note-content-topic"
                             (hyperdoc::dmx-topic-diagnostics-note-key missing)
                             "Workspace-note URI must expose the note key")
               (assert-equal :ok
                             (hyperdoc::dmx-topic-diagnostics-status fixed)
                             "Assigned topic must surface OK")
               (assert-equal 919815
                             (hyperdoc::dmx-topic-diagnostics-workspace-id fixed)
                             "Assigned topic must carry workspace 919815")
               (assert-equal "rgb"
                             (hyperdoc::dmx-topic-diagnostics-workspace-owner fixed)
                             "Assigned topic must carry workspace owner rgb")
               (assert-equal :foreign-object
                             (hyperdoc::dmx-topic-diagnostics-status foreign)
                             "Foreign probe topic must surface foreign-object")
               (assert-true
                (not (hyperdoc::dmx-topic-diagnostics-repair-needed-p foreign))
                "Foreign topic must not be marked repair-needed"))
             (assert-true
              (member "/workspaces/object/922464" calls :test #'equal)
              "Diagnostics must read the workspace-assignment endpoint")
             (assert-true
              (member "/topicmaps/object/922464" calls :test #'equal)
              "Diagnostics must read the topicmap-memberships endpoint")
             (assert-true
              (member "/access-control/workspace/919815/owner" calls :test #'equal)
              "Diagnostics must read the workspace-owner endpoint when a workspace exists"))
        (setf (symbol-function 'hyperdoc::dmx-http-request-body) original-http)))))

(defun run-topicmap-designator-helper-test ()
  (let* ((id 913836)
         (url "https://dmx.ralfbarkow.ch/core/topic/913836?children=true&assocChildren=true")
         (proxy-from-integer (hyperdoc::make-dmx-topicmap-proxy id))
         (proxy-from-url (hyperdoc::make-dmx-topicmap-proxy url)))
    (dolist (proxy (list proxy-from-integer proxy-from-url))
      (assert-type 'hyperdoc::dmx-topic-proxy
                   proxy
                   "Topicmap helper must return DMX proxy")
      (assert-equal id
                    (hyperdoc::dmx-topic-id-of proxy)
                    "Topicmap helper topic-id")
      (assert-equal id
                    (hyperdoc::dmx-topicmap-id-of proxy)
                    "Topicmap helper topicmap-id")
      (assert-equal (expected-dmx-core-topic-url id)
                    (hyperdoc::dmx-topicmap-core-topic-url proxy)
                    "Topicmap helper must expose the exact core-topic URL")))
  (let ((raised nil))
    (handler-case
        (hyperdoc::make-dmx-topicmap-proxy 'hyperdoc::not-a-topicmap)
      (hyperdoc::unknown-dmx-topic-identifier ()
        (setf raised t)))
    (unless raised
      (error "Bad topicmap helper input must signal HYPERDOC::UNKNOWN-DMX-TOPIC-IDENTIFIER"))))

(defun run-unknown-wrapper-smoke-test ()
  (let ((raised nil))
    (handler-case
        (hyperdoc::make-mapped-topic-proxy 'hyperdoc::not-a-mapped-wrapper)
      (hyperdoc::unknown-dmx-topic-wrapper ()
        (setf raised t)))
    (unless raised
      (error "Unknown wrapper must signal HYPERDOC::UNKNOWN-DMX-TOPIC-WRAPPER"))))

(defun run-dmx-topic-proxy-smoke-tests ()
  (dolist (spec *dmx-wrapper-smoke-specs*)
    (run-one-wrapper-smoke-test spec))
  (run-topicmap-designator-helper-test)
  (run-topicmap-endpoint-regression-test)
  (run-workspace-diagnostics-regression-test)
  (run-unknown-wrapper-smoke-test)
  (format t "~&DMX topic proxy smoke tests passed (~D wrappers + topicmap helper + endpoint regression + workspace diagnostics regression + unknown-wrapper condition).~%"
          (length *dmx-wrapper-smoke-specs*))
  t)
