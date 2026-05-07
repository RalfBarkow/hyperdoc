;;;; Smoke tests for bounded DMX evidence safe for SLY/test output
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun evidence-bounds-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun evidence-bounds-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected ~S but got ~S" message expected actual)))

(defun evidence-bounds-huge-body ()
  (make-string 12000 :initial-element #\x))

(defun evidence-bounds-leak-text (object)
  (with-output-to-string (stream)
    (let ((*print-pretty* nil))
      (prin1 object stream))))

(defun run-sly-evidence-http-body-bounds-smoke-test ()
  (let ((original (symbol-function 'drakma:http-request))
        (condition nil))
    (unwind-protect
         (let ((client
                (make-instance 'hyperdoc::http-dmx-import-client
                               :base-url "https://dmx.example.test"
                               :authorization-header "Bearer redacted"
                               :workspace-id 919815
                               :verbose nil)))
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method &allow-other-keys)
                   (declare (ignore url method))
                   (values (make-string-input-stream
                            (evidence-bounds-huge-body))
                           500
                           '(("Content-Type" . "text/plain"))
                           nil
                           nil
                           "Internal Server Error")))
           (handler-case
               (hyperdoc::http-request-json
                client
                :get
                "/core/topic/936040")
             (hyperdoc::dmx-import-http-error (caught)
               (setf condition caught)))
           (let ((evidence
                  (hyperdoc::dmx-import-last-http-transaction-evidence-of
                   client)))
             (evidence-bounds-assert-true
              condition
              "Huge response smoke must end in an HTTP condition")
             (evidence-bounds-assert-equal
              12000
              (getf evidence :response-body-length)
              "Safe evidence must preserve response body length")
             (evidence-bounds-assert-true
              (<= (length (or (getf evidence :response-body-prefix) ""))
                  hyperdoc::*http-dmx-import-evidence-body-prefix-limit*)
              "Safe evidence must cap response body prefix")
             (evidence-bounds-assert-true
              (null (getf evidence :response-body))
              "Safe evidence must omit raw response body")
             (evidence-bounds-assert-true
              (null (search (evidence-bounds-huge-body)
                            (evidence-bounds-leak-text evidence)
                            :test #'char-equal))
              "Printed evidence must not embed the huge raw response body")))
      (setf (symbol-function 'drakma:http-request) original)))
  t)

(defun run-sly-evidence-debug-event-cap-smoke-test ()
  (let ((client
         (make-instance 'hyperdoc::http-dmx-import-client
                        :base-url "https://dmx.example.test"
                        :authorization-header "Bearer redacted"
                        :workspace-id 919815
                        :verbose nil)))
    (dotimes (index 40)
      (hyperdoc::append-http-dmx-import-debug-event
       client
       :evidence-bounds-test
       :index index
       :authorization-header "Bearer should-not-appear"
       :cookie-header "JSESSIONID=should-not-appear"))
    (let* ((events (hyperdoc::dmx-import-debug-events-of client))
           (printed (evidence-bounds-leak-text events)))
      (evidence-bounds-assert-equal
       hyperdoc::*http-dmx-import-debug-event-limit*
       (length events)
       "HTTP debug events must be capped to the configured limit")
      (evidence-bounds-assert-equal
       8
       (getf (first events) :index)
       "Debug event cap must retain the last events")
      (dolist (forbidden '("should-not-appear" "JSESSIONID=should-not-appear"
                           "Bearer should-not-appear"))
        (evidence-bounds-assert-true
         (null (search forbidden printed :test #'char-equal))
         (format nil "Sanitized debug events must not leak ~S"
                 forbidden))))))

(defun run-sly-evidence-bounds-smoke-tests ()
  (run-sly-evidence-http-body-bounds-smoke-test)
  (run-sly-evidence-debug-event-cap-smoke-test)
  t)
