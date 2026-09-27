;;;; Signed HyperDoc authoring over HTTP
;;;;
;;;; Transport, and nothing else. A request's intent travels in its signed
;;;; envelope; this module decodes the envelope and signature from two
;;;; headers, reads the exact body octets, checks that the route names the
;;;; operation, site and page the envelope signs, and hands all three to
;;;; AUTHENTICATE-AUTHORIZE-FEDWIKI-PAGE-EDIT. Verification, principals,
;;;; challenges, rules, capabilities and the edit itself stay there and in
;;;; M0; nothing here verifies, looks up, authorizes, locks or persists.
;;;;
;;;;   POST /authoring/v1/challenge               {"principal": id}
;;;;   PUT  /authoring/v1/fedwiki/<site-id>/<slug>
;;;;        HyperDoc-Authoring-Envelope: base64url of the envelope octets, no padding
;;;;        HyperDoc-Authoring-Signature: the compact signature, 128 hex digits
;;;;        body: the exact octets the envelope's digest names
;;;;
;;;; No ambient authority. A request carries no session, cookie or proxy
;;;; identity that could count: other headers are never read, and the
;;;; authority is the one the adapter was made with, not a global.
;;;;
;;;; Every body is read, within a bound, before routing, so that no answer
;;;; resets a connection the client is still writing. Refusals answer with a
;;;; coarse status. The adapter keeps no record of what it answered; a caller
;;;; that wants the precise reason passes an observer, which is told and
;;;; never asked.
;;;;
;;;; Loading this system opens no socket. START-AUTHORING-HTTP-LISTENER is the
;;;; only thing that listens, and only on a loopback address. It returns
;;;; exactly when this adapter's own socket is bound, and signals when it is
;;;; not; reaching it from elsewhere is the operator's business. Production
;;;; here means committed and tested, not deployed.

(in-package #:dreyeck/authoring-http)

;;; base64url without padding, strict both ways

(defparameter +alphabet+ "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_")

(defun base64url-encode (octets)
  "OCTETS as unpadded base64url."
  (with-output-to-string (out)
    (loop for i from 0 below (length octets) by 3
          for n = (min 3 (- (length octets) i))
          for word = (loop for k below 3
                           sum (ash (if (< k n) (aref octets (+ i k)) 0) (* 8 (- 2 k))))
          do (loop for k below (1+ n)
                   do (write-char (char +alphabet+ (ldb (byte 6 (* 6 (- 3 k))) word)) out)))))

(defun base64url-decode (string)
  "The octets STRING encodes, or NIL unless it is canonical unpadded base64url:
no padding, no character outside the alphabet, no unused bits set."
  (when (and (stringp string) (/= 1 (mod (length string) 4))
             (every (lambda (character) (find character +alphabet+)) string))
    (let ((values (map 'list (lambda (character) (position character +alphabet+)) string))
          (octets (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0)))
      (loop while values
            for group = (loop repeat 4 while values collect (pop values))
            for word = (loop for value in group for k from 0 sum (ash value (* 6 (- 3 k))))
            do (loop for k below (1- (length group))
                     do (vector-push-extend (ldb (byte 8 (* 8 (- 2 k))) word) octets)))
      (let ((result (coerce octets '(simple-array (unsigned-byte 8) (*)))))
        (and (string= string (base64url-encode result)) result)))))

;;; The adapter

(defparameter +body-limit+ 65536 "The most body octets a request may carry.")
(defparameter +drain-limit+ (* 4 65536)
  "How much of a too-large body is read and discarded before answering.")
(defparameter +challenge-request-limit+ 1024)
(defparameter +envelope-header-limit+ 2800)
(defparameter +edit-prefix+ "/authoring/v1/fedwiki/")
(defparameter +challenge-path+ "/authoring/v1/challenge")

(defclass authoring-http-adapter ()
  ((authority :initarg :authority :reader authoring-http-adapter-authority)
   (observer :initarg :observer :initform nil :reader %adapter-observer))
  (:documentation "HTTP transport for one authoring authority. It keeps no
record of the requests it answers."))

(defun make-authoring-http-adapter (authority &key observer)
  "An adapter for AUTHORITY. OBSERVER, if given, is a function called with
the method, path, status and internal reason of each answer. It is told and
never asked: what it returns or signals changes no answer."
  (check-type authority aa:authoring-authority)
  (check-type observer (or null function))
  (make-instance 'authoring-http-adapter :authority authority :observer observer))

(defun %observe (adapter method path status reason)
  (let ((observer (%adapter-observer adapter)))
    (when observer
      (ignore-errors (funcall observer method path status reason)))))

;;; Answers: coarse outside; the precise reason only to an observer

(defparameter +statuses+
  '((400 "malformed request" :malformed-transport :malformed-envelope :unsupported-version
     :malformed-body :route-mismatch :malformed :id-mismatch)
    (401 "authentication failed" :malformed-public-key :malformed-signature :invalid-signature
     :body-mismatch :unknown-principal :no-verification-key :wrong-service :unknown-challenge
     :challenge-principal-mismatch :challenge-time-mismatch :expired-challenge :used-challenge)
    (403 "not authorized" :no-authoring-rule :site-not-authorized :page-not-authorized
     :operation-not-authorized :unknown-site)
    (404 "not found" :not-found :no-page)
    (405 "method not allowed" :method)
    (409 "conflict with the current page" :stale :absent-id :duplicate-id :no-change)
    (413 "request too large" :too-large)
    (429 "too many outstanding challenges" :challenge-limit-reached))
  "Each external status, its text, and the reasons it stands for.")

(defun %status (reason)
  (let ((entry (find-if (lambda (entry) (member reason (cddr entry))) +statuses+)))
    (if entry (values (first entry) (second entry)) (values 500 "not applied"))))

(defun %respond (status body &key (type "text/plain") close)
  (list status
        (list* :content-type (format nil "~A; charset=utf-8" type)
               (when close (list :connection "close")))
        (list body)))

(defun %refuse (adapter method path reason &key close)
  (multiple-value-bind (status text) (%status reason)
    (%observe adapter method path status reason)
    (%respond status text :close close)))

(defun %json (plist)
  (let ((object (make-hash-table :test #'equal)))
    (loop for (key value) on plist by #'cddr do (setf (gethash key object) value))
    (let ((*print-pretty* nil)) (shasht:write-json object nil))))

;;; Reading the request

(defun %discard (stream count)
  (let ((buffer (make-array 4096 :element-type '(unsigned-byte 8))))
    (loop while (plusp count)
          for read = (read-sequence buffer stream :end (min count (length buffer)))
          while (plusp read)
          do (decf count read))))

(defun %read-body (env)
  "The exact body octets; :TOO-LARGE once past +BODY-LIMIT+, after discarding
up to +DRAIN-LIMIT+ more; :TRUNCATED if the client sent less than it declared.
A body with neither a length nor chunked encoding is empty, as HTTP says."
  (let* ((length (getf env :content-length))
         (stream (getf env :raw-body))
         (chunked (search "chunked" (or (gethash "transfer-encoding" (getf env :headers)) "")
                          :test #'char-equal)))
    (cond ((or (null stream) (and (null length) (not chunked)) (eql length 0))
           (make-array 0 :element-type '(unsigned-byte 8)))
          ((and length (<= length +body-limit+))
           (let ((octets (make-array length :element-type '(unsigned-byte 8))))
             (if (= length (read-sequence octets stream)) octets :truncated)))
          (t
           (let* ((buffer (make-array (1+ +body-limit+) :element-type '(unsigned-byte 8)))
                  (read (read-sequence buffer stream)))
             (if (<= read +body-limit+)
                 (subseq buffer 0 read)
                 (progn (%discard stream (- +drain-limit+ read)) :too-large)))))))

(defun %header (env name) (gethash name (getf env :headers)))

;;; Routes

(defun %challenge-route (adapter body)
  (let* ((data (and (vectorp body) (<= (length body) +challenge-request-limit+)
                    (ignore-errors
                     (let ((shasht:*read-level* 2))
                       (shasht:read-json (sb-ext:octets-to-string body :external-format :utf-8))))))
         (principal (and (hash-table-p data) (= 1 (hash-table-count data))
                         (gethash "principal" data))))
    (unless (and (stringp principal) (<= 1 (length principal) 128)
                 (every (lambda (character)
                          (and (< (char-code character) 128)
                               (or (alphanumericp character) (find character "._:-"))))
                        principal))
      (return-from %challenge-route (%refuse adapter :post +challenge-path+ :malformed-transport)))
    (handler-case
        (let ((challenge (aa:issue-authoring-challenge (authoring-http-adapter-authority adapter)
                                                       principal)))
          (%observe adapter :post +challenge-path+ 200 :issued)
          (%respond 200 (%json (list "principal" principal
                                     "nonce" (aa:authoring-challenge-nonce challenge)
                                     "issuedAt" (aa:authoring-challenge-issued-at challenge)
                                     "expiresAt" (aa:authoring-challenge-expires-at challenge)))
                    :type "application/json"))
      (aa:authoring-request-refused (condition)
        (%refuse adapter :post +challenge-path+ (aa:authoring-request-refusal-reason condition))))))

(defun %edit-route (adapter env site page body)
  (let* ((path (getf env :path-info))
         (encoded (%header env "hyperdoc-authoring-envelope"))
         (signature (%header env "hyperdoc-authoring-signature"))
         (envelope (and (stringp encoded) (<= (length encoded) +envelope-header-limit+)
                        (base64url-decode encoded))))
    (flet ((refuse (reason) (return-from %edit-route (%refuse adapter :put path reason))))
      (unless (and envelope (stringp signature) (plusp (length signature)))
        (refuse :malformed-transport))
      ;; The route must be the target the envelope signs. Parsing reads the
      ;; envelope's claims; it trusts none of them.
      (let ((parsed (handler-case (ae:parse-authoring-envelope envelope)
                      (ae:authoring-envelope-refused (condition)
                        (refuse (ae:authoring-envelope-refusal-reason condition))))))
        (unless (and (string= "fedwiki-page-edit" (ae:authoring-envelope-operation parsed))
                     (string= site (ae:authoring-envelope-site parsed))
                     (string= page (ae:authoring-envelope-page parsed)))
          (refuse :route-mismatch)))
      (handler-case
          (let ((edit (aa:authenticate-authorize-fedwiki-page-edit
                       (authoring-http-adapter-authority adapter)
                       (list :envelope envelope :body body :signature signature))))
            (%observe adapter :put path 200 :applied)
            (%respond 200 (%json (list "applied" "edit" "id" (pa:page-edit-item-id edit)))
                      :type "application/json"))
        (ae:authoring-envelope-refused (condition)
          (refuse (ae:authoring-envelope-refusal-reason condition)))
        (aa:authoring-request-refused (condition)
          (refuse (aa:authoring-request-refusal-reason condition)))
        (pa:fedwiki-page-edit-refused (condition)
          (refuse (pa:page-edit-refusal-reason condition)))
        (error () (refuse :internal-error))))))

(defun authoring-http-response (adapter env)
  "The Clack response ADAPTER gives the request ENV."
  (let* ((method (getf env :request-method))
         (path (getf env :path-info))
         (body (%read-body env)))
    (cond ((eq body :too-large) (%refuse adapter method path :too-large :close t))
          ((eq body :truncated) (%refuse adapter method path :malformed-transport :close t))
          ((string= path +challenge-path+)
           (if (eq method :post)
               (%challenge-route adapter body)
               (%refuse adapter method path :method)))
          ((and (> (length path) (length +edit-prefix+))
                (string= +edit-prefix+ path :end2 (length +edit-prefix+)))
           (let ((segments (uiop:split-string (subseq path (length +edit-prefix+)) :separator "/")))
             (cond ((not (and (= 2 (length segments)) (every #'plusp (mapcar #'length segments))))
                    (%refuse adapter method path :not-found))
                   ((not (eq method :put)) (%refuse adapter method path :method))
                   (t (%edit-route adapter env (first segments) (second segments) body)))))
          (t (%refuse adapter method path :not-found)))))

(defun authoring-http-app (adapter)
  "A Clack application answering with ADAPTER."
  (lambda (env) (authoring-http-response adapter env)))

;;; The listener
;;
;; HUNCHENTOOT:START binds the socket in the calling thread and signals if
;; it cannot; only after that bind does it start accepting, in threads of
;; its own. That bind is the one fact of ownership, so the listener is
;; returned exactly when it succeeded. Nothing probes the port before or
;; after: another listener answering there would say nothing about ours.

(defclass %acceptor (hunchentoot:acceptor)
  ((adapter :initarg :adapter :reader %acceptor-adapter)))

(defun %request-env (request)
  "REQUEST in the form AUTHORING-HTTP-RESPONSE reads."
  (list :request-method (hunchentoot:request-method* request)
        :path-info (hunchentoot:script-name* request)
        :content-length (let ((length (hunchentoot:header-in* :content-length request)))
                          (and length (parse-integer length :junk-allowed t)))
        :raw-body (hunchentoot:raw-post-data :request request :want-stream t)
        :headers (let ((headers (make-hash-table :test #'equal)))
                   (loop for (name . value) in (hunchentoot:headers-in* request)
                         do (setf (gethash (string-downcase name) headers) value))
                   headers)))

(defmethod hunchentoot:acceptor-dispatch-request ((acceptor %acceptor) request)
  (destructuring-bind (status headers (text))
      (authoring-http-response (%acceptor-adapter acceptor) (%request-env request))
    (let ((octets (sb-ext:string-to-octets text :external-format :utf-8)))
      (setf (hunchentoot:return-code*) status
            (hunchentoot:content-type*) (getf headers :content-type)
            (hunchentoot:content-length*) (length octets))
      (when (getf headers :connection)
        (setf (hunchentoot:header-out :connection) (getf headers :connection)))
      octets)))

(defclass authoring-http-listener ()
  ((acceptor :initarg :acceptor :reader %listener-acceptor)
   (address :initarg :address :reader authoring-http-listener-address)))

(defun authoring-http-listener-port (listener)
  "The port LISTENER's own socket is bound to."
  (hunchentoot:acceptor-port (%listener-acceptor listener)))

(defparameter +loopback-addresses+ '("127.0.0.1" "::1"))

(defun start-authoring-http-listener (adapter &key (port 0) (address "127.0.0.1"))
  "Bind ADAPTER's own socket on the loopback ADDRESS and PORT, 0 for any free
port, and return the listener. Returns only if that bind succeeded, and
signals if it did not, whatever else listens there. Any other address is
refused before anything is made."
  (check-type adapter authoring-http-adapter)
  (check-type port (integer 0 65535))
  (unless (member address +loopback-addresses+ :test #'equal)
    (error "The authoring listener binds only a loopback address, not ~S." address))
  (let ((acceptor (make-instance '%acceptor :adapter adapter :address address :port port
                                            :access-log-destination nil
                                            :message-log-destination nil)))
    (handler-case (hunchentoot:start acceptor)
      (error (condition)
        (error "The authoring listener could not bind ~A:~D: ~A" address port condition)))
    (make-instance 'authoring-http-listener :acceptor acceptor :address address)))

(defun stop-authoring-http-listener (listener)
  "Close LISTENER's socket and stop accepting."
  (hunchentoot:stop (%listener-acceptor listener))
  t)

(defmethod print-object ((listener authoring-http-listener) stream)
  (print-unreadable-object (listener stream :type t)
    (format stream "~A:~D" (authoring-http-listener-address listener)
            (authoring-http-listener-port listener))))
