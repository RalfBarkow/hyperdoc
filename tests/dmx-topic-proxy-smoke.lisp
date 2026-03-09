;;;; Smoke tests for DMX topic proxy wrapper mapping

(defpackage :hyperdoc/tests
  (:use :cl)
  (:export :run-dmx-topic-proxy-smoke-tests))

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
  (run-topicmap-endpoint-regression-test)
  (run-unknown-wrapper-smoke-test)
  (format t "~&DMX topic proxy smoke tests passed (~D wrappers + endpoint regression + unknown-wrapper condition).~%"
          (length *dmx-wrapper-smoke-specs*))
  t)
