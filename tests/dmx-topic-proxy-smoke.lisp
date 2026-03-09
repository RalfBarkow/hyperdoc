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

(defun expected-dmx-url (topicmap-id topic-id)
  (format nil "https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/~D/topic/~D"
          topicmap-id
          topic-id))

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

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
      (assert-equal (expected-dmx-url topicmap-id topic-id)
                    (hyperdoc::dmx-webclient-url proxy)
                    (format nil "Wrapper ~S URL" wrapper)))))

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
  (run-unknown-wrapper-smoke-test)
  (format t "~&DMX topic proxy smoke tests passed (~D wrappers + unknown-wrapper condition).~%"
          (length *dmx-wrapper-smoke-specs*))
  t)
