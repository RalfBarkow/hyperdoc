;;;; Isolated review prototype, NOT an ASDF system or production entrypoint.
;;;; Selected transport forms from hyperdoc/mcp-server.lisp at
;;;; 591f275fc26ebef7967cc8d3e3fb5a0efc19cc85, BSD (see LICENSE).
;;;; Only prefix/accessor renaming below; no DMX client, dispatcher or tools loaded.
(require :asdf)
(dolist (system '("topic-maps/ctm" "topic-maps/cxtm" "hunchentoot" "shasht" "ironclad" "babel" "cl-base64"))
  (asdf:load-system system))
(defpackage #:hyperdoc-tmdm-mcp-review
  (:use #:cl)
  (:local-nicknames (#:tm #:topic-maps.tmdm)))
(in-package #:hyperdoc-tmdm-mcp-review)
(defparameter *mcp-protocol-version* "2025-03-26")
(defstruct mcp-server bearer-token allowed-origins sessions)
(defun non-empty-string-p (x) (and (stringp x) (plusp (length x))))
(defun encode-json-string (x) (shasht:write-json x nil))
;;; BEGIN selected historical transport forms (renamed, otherwise unchanged).
(defun mcp-json-object (&rest key-values)
  (let ((json (make-hash-table :test #'equal)))
    (loop for (key value) on key-values by #'cddr
          do (setf (gethash key json) value))
    json))

(defun mcp-json-array (&rest items)
  (coerce items 'vector))

(defun mcp-text-content (text)
  (mcp-json-object
   "type" "text"
   "text" text))

(defun mcp-json-response (body &key (status 200) session-id)
  (setf (hunchentoot:return-code*) status
        (hunchentoot:content-type*) "application/json; charset=utf-8"
        (hunchentoot:header-out "MCP-Protocol-Version") *mcp-protocol-version*)
  (when session-id
    (setf (hunchentoot:header-out "Mcp-Session-Id") session-id))
  (encode-json-string body))

(defun mcp-empty-response (&key (status 202) session-id)
  (setf (hunchentoot:return-code*) status
        (hunchentoot:content-type*) "application/json; charset=utf-8"
        (hunchentoot:header-out "MCP-Protocol-Version") *mcp-protocol-version*)
  (when session-id
    (setf (hunchentoot:header-out "Mcp-Session-Id") session-id))
  "")

(defun mcp-json-rpc-success (id result &key session-id)
  (mcp-json-response
   (mcp-json-object
    "jsonrpc" "2.0"
    "id" id
    "result" result)
   :session-id session-id))

(defun mcp-json-rpc-error (id code message &key data (status 200) session-id)
  (let ((error-object (mcp-json-object
                       "code" code
                       "message" message)))
    (when data
      (setf (gethash "data" error-object) data))
    (mcp-json-response
     (mcp-json-object
      "jsonrpc" "2.0"
      "id" id
      "error" error-object)
     :status status
     :session-id session-id)))

(defun mcp-server-require-auth (server)
  (let ((expected-token (and server (mcp-server-bearer-token server))))
    (when (non-empty-string-p expected-token)
      (let ((auth (or (hunchentoot:header-in* "authorization")
                      "")))
        (unless (string= auth (format nil "Bearer ~A" expected-token))
          (setf (hunchentoot:return-code*) 401
                (hunchentoot:content-type*) "application/json; charset=utf-8")
          (return-from mcp-server-require-auth
            (encode-json-string
             (mcp-json-object
              "error" "unauthorized"
              "message" "Missing or invalid bearer token")))))))
  nil)

(defun mcp-server-origin-allowed-p (server)
  (let ((allowed-origins (and server (mcp-server-allowed-origins server)))
        (origin (hunchentoot:header-in* "origin")))
    (or (null origin)
        (null allowed-origins)
        (member origin allowed-origins :test #'string=))))

(defun mcp-server-require-origin (server)
  (unless (mcp-server-origin-allowed-p server)
    (setf (hunchentoot:return-code*) 403
          (hunchentoot:content-type*) "application/json; charset=utf-8")
    (return-from mcp-server-require-origin
      (encode-json-string
       (mcp-json-object
        "error" "forbidden_origin"
        "message" "Origin is not allowed for this MCP server"))))
  nil)

(defun mcp-request-id (request)
  (and (hash-table-p request)
       (gethash "id" request)))

(defun mcp-request-method-name (request)
  (and (hash-table-p request)
       (gethash "method" request)))

(defun mcp-request-params (request)
  (and (hash-table-p request)
       (gethash "params" request)))

(defun mcp-session-for-request (server &key initialize?)
  (let ((session-id (hunchentoot:header-in* "Mcp-Session-Id")))
    (cond
      (initialize?
       (values nil nil))
      ((null session-id)
       (values nil :missing))
      (t
       (let ((session (gethash session-id (mcp-server-sessions server))))
         (if session
             (values session-id session)
             (values session-id :unknown)))))))
;;; END selected historical forms.

;;; New read-only adapter. All paths/configuration come from the trusted launcher.
(defparameter +revision+ "0484a4b76128c3ed302a6a8d6e0343bfe03cece5")
(defparameter +pin+ "88994c1b9e1edbf13e665e984a5c9c3b2cdf7575")
(defparameter +sha+ "8b4142421f5bfa1cc089e7ac53b43ebc6975e597cdedea5a49f6fc226dcc2e1d")
(defparameter +cxtm-sha+ "776145ba5cc30bdf6b699de245f2c0b5ffc08ebbe07d21b8ceb3a46695128f3f")
(defparameter +document+ "tag:dreyeck.ch,2026:hyperdoc/project.ctm")
(defparameter +root+ (concatenate 'string "hyperdoc-iso13250://snapshot/" +sha+ "/"))
(defparameter +ctm-uri+ (concatenate 'string +root+ "project.ctm"))
(defparameter +manifest-uri+ (concatenate 'string +root+ "manifest.json"))
(defvar *server*)
(defvar *octets*)
(defvar *map*)
(defvar *resources* (make-hash-table :test #'equal))
(defun sha256 (bytes)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 bytes)))
(defun bytes (path)
  (with-open-file (in path :element-type '(unsigned-byte 8))
    (let ((data (make-array (file-length in) :element-type '(unsigned-byte 8))))
      (assert (= (length data) (read-sequence data in))) data)))
(defun uri-component (text)
  ;; Exact precomputed dispatch; no request URI decoding or path interpretation.
  (with-output-to-string (out)
    (loop for byte across (babel:string-to-octets text :encoding :utf-8)
          do (if (or (<= 65 byte 90) (<= 97 byte 122) (<= 48 byte 57)
                     (member byte '(45 46 95 126)))
                 (write-char (code-char byte) out)
                 (format out "%~2,'0X" byte)))))
(defun ref (topic)
  (when topic
    (let ((canonical (tm:canonical-topic topic)))
      (mcp-json-object "subjectIdentifiers" (coerce (tm:topic-subject-identifiers canonical) 'vector)
                       "subjectLocators" (coerce (tm:topic-subject-locators canonical) 'vector)
                       "itemIdentifiers" (coerce (tm:topic-item-identifiers canonical) 'vector)))))
(defun occurrence-view (item)
  (mcp-json-object "type" (ref (tm:occurrence-type item))
                   "value" (tm:occurrence-value item) "datatype" (tm:occurrence-datatype item)
                   "scope" (map 'vector #'ref (tm:occurrence-scope item))
                   "parent" (ref (tm:occurrence-parent item))
                   "reifier" (ref (tm:item-reifier item))))
(defun association-view (item)
  (mcp-json-object "type" (ref (tm:association-type item))
                   "scope" (map 'vector #'ref (tm:association-scope item))
                   "reifier" (ref (tm:item-reifier item))
                   "roles" (map 'vector
                                (lambda (role)
                                  (mcp-json-object "type" (ref (tm:association-role-type role))
                                                   "player" (ref (tm:association-role-player role))))
                                (tm:association-roles item))))
(defun topic-view (topic)
  ;; An inspection projection of these native objects, never a second model.
  (let ((reified (tm:topic-reified topic)))
    (mcp-json-object
     "sourceRevision" +revision+ "sha256" +sha+ "identity" (ref topic)
     "names" (map 'vector #'tm:topic-name-value (tm:topic-names topic))
     "occurrences" (map 'vector #'occurrence-view (tm:topic-occurrences topic))
     "reifiedOccurrence" (when (typep reified 'tm:occurrence) (occurrence-view reified))
     "associations" (map 'vector #'association-view
                         (remove-duplicates
                          (mapcar #'tm:association-role-parent (tm:topic-roles-played topic)) :test #'eq)))))
(defun text-resource (uri data)
  (mcp-json-object "uri" uri "mimeType" "application/json" "text" (encode-json-string data)))
(defun resource-content (uri)
  (cond
    ((equal uri +ctm-uri+)
     (mcp-json-object "uri" uri "mimeType" "application/octet-stream"
                      "blob" (cl-base64:usb8-array-to-base64-string *octets*)))
    ((equal uri +manifest-uri+)
     (text-resource uri
                    (mcp-json-object "format" "hyperdoc-project-ctm-snapshot-1"
                                     "sourceRevision" +revision+ "topicMapsRevision" +pin+
                                     "sha256" +sha+ "cxtmSha256" +cxtm-sha+
                                     "documentIRI" +document+ "ctmResource" +ctm-uri+)))
    ((gethash uri *resources*) (text-resource uri (topic-view (gethash uri *resources*))))))
(defun resource-metadata (uri name mime)
  (mcp-json-object "uri" uri "name" name "mimeType" mime))
(defun dispatch (request session-id session)
  (let ((id (mcp-request-id request)) (method (mcp-request-method-name request))
        (params (or (mcp-request-params request) (mcp-json-object))))
    (cond
      ((equal method "initialize")
       (unless (and id (equal *mcp-protocol-version* (gethash "protocolVersion" params)))
         (return-from dispatch (mcp-json-rpc-error id -32602 "Unsupported protocol version")))
       (when (>= (hash-table-count (mcp-server-sessions *server*)) 16)
         (return-from dispatch (mcp-json-rpc-error id -32000 "Review session limit" :status 429)))
       (let ((new-id (ironclad:byte-array-to-hex-string (ironclad:random-data 24))))
         (setf (gethash new-id (mcp-server-sessions *server*)) (list :initialized nil))
         (mcp-json-rpc-success
          id (mcp-json-object "protocolVersion" *mcp-protocol-version*
                              "capabilities" (mcp-json-object "resources" (mcp-json-object))
                              "serverInfo" (mcp-json-object "name" "hyperdoc-iso13250-review" "version" "0"))
          :session-id new-id)))
      ((equal method "notifications/initialized")
       (setf (getf session :initialized) t)
       (mcp-empty-response :session-id session-id))
      ((not (getf session :initialized))
       (mcp-json-rpc-error id -32000 "Session not initialized"))
      ((equal method "ping") (mcp-json-rpc-success id (mcp-json-object)))
      ((equal method "resources/list")
       (mcp-json-rpc-success id
                            (mcp-json-object "resources"
                                             (mcp-json-array
                                              (resource-metadata +ctm-uri+ "Verified project CTM" "application/octet-stream")
                                              (resource-metadata +manifest-uri+ "Snapshot provenance" "application/json")))))
      ((equal method "resources/templates/list")
       (mcp-json-rpc-success id
                            (mcp-json-object "resourceTemplates"
                                             (mcp-json-array
                                              (mcp-json-object "uriTemplate" (concatenate 'string +root+ "topic?si={si}")
                                                               "name" "Native TMDM Topic by Subject Identifier"
                                                               "mimeType" "application/json")))))
      ((equal method "resources/read")
       (let ((content (resource-content (gethash "uri" params))))
         (if content (mcp-json-rpc-success id (mcp-json-object "contents" (mcp-json-array content)))
             (mcp-json-rpc-error id -32002 "Unknown reviewed resource"))))
      (t (mcp-json-rpc-error id -32601 "Method not found")))))

(hunchentoot:define-easy-handler (review-endpoint :uri "/mcp") ()
  (or (mcp-server-require-auth *server*) (mcp-server-require-origin *server*)
      (handler-case
          (case (hunchentoot:request-method*)
            (:post
             ;; Bounded fixture request surface. No EVAL, READ or network resolver.
             (let ((size (ignore-errors (parse-integer (or (hunchentoot:header-in* "content-length") "")))))
               (unless (and size (<= 0 size 16384))
                 (return-from review-endpoint (mcp-json-rpc-error nil -32600 "Request size refused" :status 413))))
             (let* ((request (shasht:read-json (hunchentoot:raw-post-data :force-text t)))
                    (method (mcp-request-method-name request)))
               (unless (and (hash-table-p request) (equal (gethash "jsonrpc" request) "2.0")
                            (stringp method) (or (null (mcp-request-params request))
                                                (hash-table-p (mcp-request-params request))))
                 (return-from review-endpoint (mcp-json-rpc-error nil -32600 "Invalid request" :status 400)))
               (multiple-value-bind (sid session)
                   (mcp-session-for-request *server* :initialize? (equal method "initialize"))
                 (cond
                   ((eq session :missing) (mcp-json-rpc-error (mcp-request-id request) -32000 "Missing session" :status 400))
                   ((eq session :unknown) (mcp-json-rpc-error (mcp-request-id request) -32001 "Unknown session" :status 404))
                   (t (dispatch request sid session))))))
            (:delete
             (multiple-value-bind (sid session) (mcp-session-for-request *server*)
               (if (or (eq session :missing) (eq session :unknown))
                   (mcp-json-rpc-error nil -32001 "Unknown session" :status 404)
                   (progn (remhash sid (mcp-server-sessions *server*)) (mcp-empty-response :status 204)))))
            (otherwise (mcp-json-rpc-error nil -32600 "Use POST" :status 405)))
        (error () (mcp-json-rpc-error nil -32603 "Review request refused" :status 400)))))

(let* ((source (asdf:system-source-directory "topic-maps/ctm"))
       (actual (string-trim '(#\Space #\Newline #\Return)
                            (uiop:run-program (list "git" "-C" (namestring source) "rev-parse" "HEAD") :output :string)))
       (token (uiop:getenv "HYPERDOC_REVIEW_TOKEN")))
  (assert (equal +pin+ actual))
  (dolist (system '("topic-maps" "topic-maps/tmdm" "topic-maps/ctm" "topic-maps/cxtm"))
    (assert (equal (truename source) (truename (asdf:system-source-directory system)))))
  (assert (zerop (length (uiop:run-program
                         (list "git" "-C" (namestring source) "status" "--porcelain") :output :string))))
  (assert (non-empty-string-p token))
  (setf *octets* (bytes (uiop:getenv "HYPERDOC_REVIEW_CTM")))
  (assert (equal +sha+ (sha256 *octets*)))
  (setf *map* (topic-maps.ctm:deserialize-string (babel:octets-to-string *octets* :encoding :utf-8)
                                               :document-iri +document+ :source-name "reviewed PR #1 snapshot"))
  (assert (equal +cxtm-sha+ (sha256 (topic-maps.cxtm:canonicalize-octets *map* :base-locator +document+))))
  (dolist (topic (tm:topic-map-topics *map*))
    (dolist (si (tm:topic-subject-identifiers topic))
      (setf (gethash (concatenate 'string +root+ "topic?si=" (uri-component si)) *resources*)
            (tm:canonical-topic topic))))
  (setf *server* (make-mcp-server :bearer-token token :allowed-origins '("https://review.invalid")
                                  :sessions (make-hash-table :test #'equal)))
  (let ((acceptor (make-instance 'hunchentoot:easy-acceptor :address "127.0.0.1"
                                :port (parse-integer (uiop:getenv "HYPERDOC_REVIEW_PORT"))
                                :access-log-destination nil :message-log-destination nil)))
    (unwind-protect
         (progn
           (hunchentoot:start acceptor)
           (format t "~&MCP-REVIEW-READY CTM ~A; CXTM ~A; core pin ~A~%" +sha+ +cxtm-sha+ +pin+)
           (finish-output)
           (loop repeat 600 until (probe-file (uiop:getenv "HYPERDOC_REVIEW_STOP")) do (sleep 0.1))
           (let* ((received (bytes (uiop:getenv "HYPERDOC_REVIEW_RECEIVED")))
                  (readback (progn
                              (assert (equal +sha+ (sha256 received)))
                              (topic-maps.ctm:deserialize-string
                               (babel:octets-to-string received :encoding :utf-8)
                               :document-iri +document+ :source-name "MCP client verified bytes"))))
             (assert (equalp *octets* received))
             (assert (equal +cxtm-sha+ (sha256 (topic-maps.cxtm:canonicalize-octets readback :base-locator +document+))))
             (format t "~&MCP-REVIEW-READBACK PASS: digest, octets, native CTM, same-base CXTM~%"))
           (assert (equal +cxtm-sha+ (sha256 (topic-maps.cxtm:canonicalize-octets *map* :base-locator +document+))))
           (format t "~&MCP-REVIEW-UNCHANGED native map and CTM ~A~%" (sha256 *octets*)))
      (hunchentoot:stop acceptor))))
