;;;; Smoke tests for explicit DMX auth/session bootstrap request shape
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun auth-session-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun auth-session-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected ~S but got ~S" message expected actual)))

(defun auth-session-header-value (headers name)
  (cdr (find name headers :test #'string-equal :key #'car)))

(defun auth-session-debug-event (client state)
  (find state
        (hyperdoc::dmx-import-debug-events-of client)
        :key (lambda (event) (getf event :state))
        :test #'eq))

(defun auth-session-string-for-leak-check (object)
  (with-output-to-string (stream)
    (let ((*print-pretty* nil))
      (prin1 object stream))))

(defun run-dmx-auth-session-boundary-smoke-test ()
  (let ((original (symbol-function 'drakma:http-request))
        (login-call nil)
        (put-call nil)
        (condition nil))
    (unwind-protect
         (let ((client nil))
           (setf (symbol-function 'drakma:http-request)
                 (lambda (url &key method additional-headers content
                                content-type content-length &allow-other-keys)
                   (cond
                     ((and (eq method :post)
                           (search "/access-control/login" url
                                   :test #'char-equal))
                      (setf login-call
                            (list :url url
                                  :method method
                                  :headers additional-headers
                                  :content content
                                  :content-type content-type
                                  :content-length content-length))
                      (values (make-string-input-stream "")
                              200
                              '(("Set-Cookie" . "JSESSIONID=abc123; Path=/; HttpOnly"))
                              nil
                              nil
                              "OK"))
                     ((and (eq method :put)
                           (search "/workspaces/919815/object/936040" url
                                   :test #'char-equal))
                      (setf put-call
                            (list :url url
                                  :method method
                                  :headers additional-headers
                                  :content content
                                  :content-type content-type
                                  :content-length content-length))
                      (values
                       (make-string-input-stream
                        "{\"error\":\"Unauthorized\"}")
                       401
                       '(("Content-Type" . "application/json"))
                       nil
                       nil
                       "Unauthorized"))
                     (t
                      (error "Unexpected mocked DMX request: ~A ~A"
                             method
                             url)))))
           (setf client
                 (hyperdoc::make-http-dmx-import-client-from-explicit-auth
                  :base-url "https://dmx.example.test"
                  :workspace-id 919815
                  :auth-mode :basic
                  :username "operator"
                  :password "not-real"
                  :bootstrap-session-p t
                  :derived-auth-scheme :basic
                  :verbose nil))
           (handler-case
               (hyperdoc::dmx-import-assign-topic-to-workspace
                client
                919815
                936040)
             (hyperdoc::dmx-import-http-error (caught)
               (setf condition caught)))
           (auth-session-assert-true
            condition
            "Guarded PUT smoke must terminate at mocked 401 auth boundary")
           (auth-session-assert-equal
            401
            (hyperdoc::dmx-import-http-status-code-of condition)
            "Guarded PUT smoke must classify the terminal status as 401")
           (auth-session-assert-equal
            :post
            (getf login-call :method)
            "Username/password mode must prepare POST /access-control/login")
           (auth-session-assert-equal
            0
            (getf login-call :content-length)
            "Bootstrap login must use an explicit empty body")
           (auth-session-assert-equal
            :put
            (getf put-call :method)
            "Workspace assignment boundary must prepare a guarded PUT")
           (auth-session-assert-equal
            ""
            (getf put-call :content)
            "Guarded PUT must carry an explicit zero-length body")
           (auth-session-assert-equal
            0
            (getf put-call :content-length)
            "Guarded PUT must set Content-Length 0")
           (auth-session-assert-equal
            nil
            (getf put-call :content-type)
            "Guarded PUT must not smuggle form content type")
           (auth-session-assert-equal
            "application/json"
            (auth-session-header-value (getf put-call :headers) "Accept")
            "Guarded PUT must ask for JSON")
           (auth-session-assert-true
            (search "JSESSIONID="
                    (or (auth-session-header-value
                         (getf put-call :headers)
                         "Cookie")
                        "")
                    :test #'char-equal)
            "Guarded PUT must include a JSESSIONID cookie at the wire boundary")
           (auth-session-assert-true
            (search "dmx_workspace_id=919815"
                    (or (auth-session-header-value
                         (getf put-call :headers)
                         "Cookie")
                        "")
                    :test #'char-equal)
            "Guarded PUT must include the workspace cookie")
           (dolist (state '(:s4-bootstrap-request-prepared
                            :s5-bootstrap-request-sent
                            :s6-bootstrap-response-received
                            :s7-session-material-extracted
                            :s8-guarded-repair-request-prepared
                            :s9-guarded-repair-request-sent
                            :s10-guarded-repair-response-received))
             (auth-session-assert-true
              (auth-session-debug-event client state)
              (format nil "Auth debug trace must include ~A" state)))
           (let* ((evidence
                   (hyperdoc::dmx-import-last-http-transaction-evidence-of
                    client))
                  (safe-text
                   (auth-session-string-for-leak-check
                    (list evidence
                          (hyperdoc::dmx-import-debug-events-of client)))))
             (auth-session-assert-equal
              401
              (getf evidence :response-status-code)
              "Bounded evidence must preserve guarded PUT status")
             (auth-session-assert-equal
              "JSESSIONID + dmx_workspace_id"
              (getf evidence :cookie-shape)
              "Bounded evidence must expose cookie shape, not cookie value")
             (dolist (forbidden '("abc123" "not-real" "operator"
                                  "JSESSIONID=abc123"))
               (auth-session-assert-true
                (null (search forbidden safe-text :test #'char-equal))
                (format nil "Evidence/debug output must not leak ~S"
                        forbidden)))))
      (setf (symbol-function 'drakma:http-request) original)))
  t)

(defun run-dmx-auth-session-boundary-smoke-tests ()
  (run-dmx-auth-session-boundary-smoke-test)
  t)
