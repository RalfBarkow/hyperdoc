;;;; Regression tests for the locally served Common Lisp HyperSpec.

(defpackage #:hyperdoc/inspector/tests
  (:use #:cl)
  (:export #:run-local-hyperspec-tests))

(in-package #:hyperdoc/inspector/tests)

(defun check (value control &rest arguments)
  (unless value
    (error (apply #'format nil control arguments)))
  value)

(defun defmethod-hyperspec-page ()
  (html-inspector-views/standard::make-hyperspec-page 'common-lisp:defmethod))

(defun content-view (page)
  (html-inspector-views/standard:👀content page))

(defun page-url (page)
  (slot-value page 'html-inspector-views/standard::url))

(defun path-asset (view)
  (find :path
        (html-inspector-views:view-assets view)
        :key #'first))

(defun run-configured-address-contract-test ()
  (let* ((lookup
           (html-inspector-views/standard::lookup-symbol-in-hyperspec
            'common-lisp:defmethod))
         (relative-path (format nil "Body/~A.htm" lookup))
         (url
           (html-inspector-views/standard::hyperspec-url
            'common-lisp:defmethod))
         (page (defmethod-hyperspec-page))
         (view (content-view page))
         (html (html-inspector-views:view-html view))
         (asset (path-asset view))
         (root (hyperdoc/inspector::hyperspec-root-pathname)))
    (check (string= "m_defmet" lookup)
           "Existing HyperSpec lookup returned ~S for COMMON-LISP:DEFMETHOD."
           lookup)
    (check (string= "Body/m_defmet.htm" relative-path)
           "Relative DEFMETHOD path differs: ~S."
           relative-path)
    (check (string= "/hyperspec/Body/m_defmet.htm" url)
           "HyperSpec URL is not local: ~S."
           url)
    (check (string= url (page-url page))
           "HYPERSPEC-PAGE retained a different content URL: ~S."
           (page-url page))
    (check (search "/hyperspec/Body/m_defmet.htm" html)
           "Content view does not embed the local DEFMETHOD URL: ~S."
           html)
    (check (null (search "www.lispworks.com" (page-url page)
                         :test #'char-equal))
           "Content URL still points at LispWorks: ~S."
           (page-url page))
    (check root
           "HYPERDOC_HYPERSPEC_ROOT is not a complete HyperSpec corpus.")
    (check asset "Configured HyperSpec view has no static path asset.")
    (check (string= "/hyperspec/" (second asset))
           "HyperSpec HTTP root differs: ~S."
           asset)
    (check (equal (truename root)
                  (truename (uiop:ensure-directory-pathname (third asset))))
           "Static route ~S does not resolve to configured corpus ~S."
           (third asset) root))
  t)

(defun run-corpus-contract-test ()
  (let ((root (hyperdoc/inspector::hyperspec-root-pathname)))
    (dolist (relative-file '("Front/index.htm" "Body/m_defmet.htm"))
      (check (uiop:file-exists-p (merge-pathnames relative-file root))
             "Required HyperSpec file is absent: ~A."
             relative-file))
    (dolist (relative-directory '("Data/" "Issues/"))
      (check (uiop:directory-exists-p
              (merge-pathnames relative-directory root))
             "Required HyperSpec directory is absent: ~A."
             relative-directory)))
  t)

(defun run-missing-configuration-contract-test ()
  (let ((hyperdoc/inspector::*hyperspec-root-override* nil))
    (let* ((page (defmethod-hyperspec-page))
           (view (content-view page))
           (html (html-inspector-views:view-html view)))
      (check (search "HyperSpec not configured" html)
             "Missing configuration has no explicit local state: ~S."
             html)
      (check (null (search "<iframe" html :test #'char-equal))
             "Missing configuration still renders an iframe: ~S."
             html)
      (check (null (path-asset view))
             "Missing configuration registered a static corpus path.")
      (check (string= "/hyperspec/Body/m_defmet.htm" (page-url page))
             "Missing configuration changed the local-only URL contract.")
      (check (null (search "www.lispworks.com" html :test #'char-equal))
             "Missing configuration silently falls back to LispWorks.")))
  t)

(defun run-invalid-configuration-contract-test ()
  (let ((hyperdoc/inspector::*hyperspec-root-override*
          "/definitely/not/a/hyperspec/"))
    (let* ((page (defmethod-hyperspec-page))
           (view (content-view page))
           (html (html-inspector-views:view-html view)))
      (check (search "does not contain a complete HyperSpec 7.0 corpus" html)
             "Invalid configuration is not explained locally: ~S."
             html)
      (check (null (path-asset view))
             "Invalid configuration registered a static corpus path.")))
  t)

(defun test-port ()
  (parse-integer
   (or (uiop:getenv "HYPERDOC_HYPERSPEC_TEST_PORT") "18092")))

(defun local-http-get-once (port path)
  (let* ((socket
           (usocket:socket-connect
            "127.0.0.1" port :element-type 'character))
         (stream (usocket:socket-stream socket)))
    (unwind-protect
         (progn
           (format stream
                   "GET ~A HTTP/1.0~C~C~
                    Host: 127.0.0.1~C~C~
                    Connection: close~C~C~C~C"
                   path #\Return #\Newline
                   #\Return #\Newline
                   #\Return #\Newline
                   #\Return #\Newline)
           (finish-output stream)
           (let ((status-line (read-line stream nil nil))
                 (body
                   (with-output-to-string (output)
                     (loop for line = (read-line stream nil nil)
                           while line
                           do (write-line line output)))))
             (values status-line body)))
      (usocket:socket-close socket))))

(defun local-http-get (port path)
  (loop repeat 50
        for response =
          (handler-case
              (multiple-value-list (local-http-get-once port path))
            (usocket:connection-refused-error () nil))
        when response
          return (values-list response)
        do (sleep 0.1)
        finally
           (error "Local HyperSpec server did not accept connections on port ~D."
                  port)))

(defun run-http-serving-contract-test ()
  (let* ((page (defmethod-hyperspec-page))
         (view (content-view page))
         (asset (path-asset view))
         (port (test-port)))
    (check asset "Cannot run HTTP test without the HyperSpec path asset.")
    (clog:initialize nil :port port)
    (unwind-protect
         (progn
           (clog-connection:add-plugin-path
            (concatenate 'string "^" (second asset))
            (third asset))
           (multiple-value-bind (status-line body)
               (local-http-get port (page-url page))
             (check (and status-line (search " 200 " status-line))
                    "Local HyperSpec request returned ~S."
                    status-line)
             (check (search "<TITLE>CLHS: Macro DEFMETHOD</TITLE>" body)
                    "Local response is not the unchanged DEFMETHOD page.")))
      (clog:shutdown)))
  t)

(defun run-local-hyperspec-tests ()
  (run-configured-address-contract-test)
  (run-corpus-contract-test)
  (run-missing-configuration-contract-test)
  (run-invalid-configuration-contract-test)
  (run-http-serving-contract-test)
  (format t "Local HyperSpec tests passed.~%")
  t)
