;;;; HyperDoc inspectable topics and DMX topic proxies
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

(in-package :hyperdoc)

(defparameter *dmx-base-url* "https://dmx.ralfbarkow.ch")
(defparameter *dmx-topicmap-id* 912102)
(defparameter *dmx-default-topic-id* 912384)
(defparameter *dmx-cache-max-entries* 32)
(defparameter *dmx-cache-ttl-seconds* 120)
(defparameter *dmx-context-window-workspace-id* 919815)
(defparameter *dmx-context-window-topicmap-id* 919822)
(defparameter *dmx-proxy-workspace-note-uri-prefix*
  "hyperdoc:mcp/workspace-note/")
(defparameter *dmx-proxy-handover-uri-prefix*
  "hyperdoc:mcp/handover/")
(defparameter *dmx-proxy-topic-factory-snippet-uri-prefix*
  "hyperdoc:topic-factory-snippet/")

(define-condition dmx-proxy-error (error)
  ((url :reader dmx-error-url-of :initarg :url)
   (message :reader dmx-error-message-of :initarg :message)
   (cause :reader dmx-error-cause-of :initarg :cause))
  (:report (lambda (condition stream)
             (format stream "~A (~A)"
                     (dmx-error-message-of condition)
                     (dmx-error-url-of condition)))))

(define-condition unknown-dmx-topic-wrapper (error)
  ((function-name :reader unknown-wrapper-name-of :initarg :function-name))
  (:report (lambda (condition stream)
             (format stream "No DMX topic mapping for wrapper ~S"
                     (unknown-wrapper-name-of condition)))))

(define-condition unknown-dmx-topic-identifier (error)
  ((identifier :reader unknown-topic-identifier-of :initarg :identifier))
  (:report (lambda (condition stream)
             (format stream "Cannot resolve DMX topic from identifier ~S"
                     (unknown-topic-identifier-of condition)))))

(defclass dmx-hyperbook (hb:hyperbook)
  ((base-url :reader dmx-base-url-of :type string :initarg :base-url)
   (topicmap-id :reader dmx-topicmap-id-of :type integer :initarg :topicmap-id)
   (title :reader hb:title-of :type string :initarg :title)
   (main-page-id :reader hb:main-page-id-of :type string :initarg :main-page-id)
   (pages :reader dmx-pages-of :type hash-table
          :initform (make-hash-table :test #'eql))
   (cache :reader dmx-cache-of :type hash-table
          :initform (make-hash-table :test #'equal))
   (cache-order :accessor dmx-cache-order-of :type list :initform nil)))

(defclass dmx-topic-proxy (hb:page)
  ((topic-id :reader dmx-topic-id-of :type integer :initarg :topic-id)
   (topicmap-id :reader dmx-topicmap-id-of :type integer :initarg :topicmap-id)
   (topic-data :accessor dmx-topic-data-of :initform nil)
   (workspace-data :accessor dmx-workspace-data-of :initform nil)
   (workspace-owner :accessor dmx-workspace-owner-of :initform nil)
   (topicmap-memberships :accessor dmx-topicmap-memberships-of :initform nil)
   (diagnostics :accessor dmx-diagnostics-of :initform nil)
   (repair-results :accessor dmx-repair-results-of :initform nil)
   (topicmap-data :accessor dmx-topicmap-data-of :initform nil)
   (related-topics :accessor dmx-related-topics-of :initform nil)
   (load-error :accessor dmx-load-error-of :initform nil)))

(defclass dmx-workspace-repair-triage (hb:page)
  ((topicmap-id :reader dmx-topicmap-id-of :type integer :initarg :topicmap-id)
   (topicmap-projection :accessor dmx-topicmap-projection-of :initform nil)
   (topic-proxies :accessor dmx-triage-topic-proxies-of :initform nil)
   (repair-topic-proxies :accessor dmx-repair-topic-proxies-of :initform nil)
   (repair-results :accessor dmx-repair-results-of :initform nil)
   (repair-summary :accessor dmx-repair-summary-of :initform nil)
   (load-error :accessor dmx-load-error-of :initform nil)))

(defgeneric dmx-workspace-id-of (page))

(defmethod dmx-workspace-id-of ((page dmx-workspace-repair-triage))
  *dmx-context-window-workspace-id*)

(defmethod dmx-workspace-id-of ((page dmx-topic-proxy))
  *dmx-context-window-workspace-id*)

(defclass dmx-shared-workspace-object (dmx-workspace-repair-triage)
  ((workspace-id :reader dmx-workspace-id-of
                 :type integer
                 :initarg :workspace-id)))

(defclass dmx-shared-topicmap-object (dmx-workspace-repair-triage)
  ((workspace-id :reader dmx-workspace-id-of
                 :type integer
                 :initarg :workspace-id)))

(defstruct dmx-topic-diagnostics
  topic-id
  topicmap-id
  topic-uri
  topic-type-uri
  topic-title
  workspace-id
  workspace-title
  workspace-owner
  topicmap-memberships
  selected-topicmap-membership-p
  ownership-class
  ownership-reason
  hyperdoc-owned-p
  note-key
  handover-key
  source-endpoints
  status
  status-reason
  repair-needed-p)

(defmethod hb:title-of ((page dmx-topic-proxy))
  (or (and (dmx-topic-data-of page)
           (gethash "value" (dmx-topic-data-of page)))
      (format nil "DMX Topic ~D" (dmx-topic-id-of page))))

(defmethod hb:path-item-of ((page dmx-topic-proxy))
  (format nil "topic-~D" (dmx-topic-id-of page)))

(defmethod hb:title-of ((page dmx-workspace-repair-triage))
  (format nil "DMX workspace repair triage ~D"
          (dmx-topicmap-id-of page)))

(defmethod hb:path-item-of ((page dmx-workspace-repair-triage))
  (format nil "workspace-repair-triage-~D"
          (dmx-topicmap-id-of page)))

(defun dmx-workspace-display-label (workspace-id)
  (if (eql workspace-id *dmx-context-window-workspace-id*)
      (format nil "Workspace context-window workspace (~D)"
              workspace-id)
      (format nil "Workspace ~D" workspace-id)))

(defun dmx-topicmap-display-label (topicmap-id)
  (if (eql topicmap-id *dmx-context-window-topicmap-id*)
      (format nil "Topicmap context-window topicmap (~D)"
              topicmap-id)
      (format nil "Topicmap ~D" topicmap-id)))

(defmethod hb:title-of ((page dmx-shared-workspace-object))
  (dmx-workspace-display-label (dmx-workspace-id-of page)))

(defmethod hb:path-item-of ((page dmx-shared-workspace-object))
  (format nil "shared-workspace-~D-in-topicmap-~D"
          (dmx-workspace-id-of page)
          (dmx-topicmap-id-of page)))

(defmethod hb:title-of ((page dmx-shared-topicmap-object))
  (dmx-topicmap-display-label (dmx-topicmap-id-of page)))

(defmethod hb:path-item-of ((page dmx-shared-topicmap-object))
  (format nil "shared-topicmap-~D-for-workspace-~D"
          (dmx-topicmap-id-of page)
          (dmx-workspace-id-of page)))

(defvar *dmx-hyperbooks* (make-hash-table :test #'equal))

(defun dmx-topic-webclient-url (page)
  (let ((book (hb:hyperbook-of page)))
    (format nil "~A/systems.dmx.webclient/#/topicmap/~D/topic/~D"
            (dmx-base-url-of book)
            (dmx-topicmap-id-of page)
            (dmx-topic-id-of page))))

(defun dmx-topicmap-webclient-url (page)
  (let ((book (hb:hyperbook-of page)))
    (format nil "~A/systems.dmx.webclient/#/topicmap/~D/topic/~D"
            (dmx-base-url-of book)
            (dmx-topicmap-id-of page)
            (dmx-topicmap-id-of page))))

(defun dmx-webclient-url (page)
  (typecase page
    (dmx-topic-proxy
     (dmx-topic-webclient-url page))
    (t
     (dmx-topicmap-webclient-url page))))

(defun dmx-core-topic-endpoint (id)
  (format nil "/core/topic/~D" id))

(defun dmx-workspace-object-endpoint (id)
  (format nil "/workspaces/object/~D" id))

(defun dmx-topicmap-memberships-endpoint (id)
  (format nil "/topicmaps/object/~D" id))

(defun dmx-topicmap-projection-endpoint (id)
  (format nil "/topicmaps/~D" id))

(defun dmx-workspace-owner-endpoint (workspace-id)
  (format nil "/access-control/workspace/~D/owner" workspace-id))

(defun dmx-children+assoc-parameters ()
  '(("children" . "true")
    ("assocChildren" . "true")))

(defun dmx-related-topics-parameters ()
  '(("children" . "false")
    ("assocChildren" . "false")))

(defun dmx-topicmap-children-parameters ()
  '(("children" . "true")))

(defun dmx-query-string (parameters)
  (with-output-to-string (stream)
    (loop for (key . value) in parameters
          for first? = t then nil
          do (unless first?
               (write-char #\& stream))
          (format stream "~A=~A" key value))))

(defun dmx-endpoint-url (book endpoint &key parameters)
  (format nil "~A~A~@[?~A~]"
          (dmx-base-url-of book)
          endpoint
          (and parameters
               (dmx-query-string parameters))))

(defun dmx-http-success-status-p (status-code)
  (and status-code (<= 200 status-code 299)))

(defun blank-dmx-http-response-body-p (body)
  (or (null body)
      (zerop (length (string-trim '(#\Space #\Tab #\Newline #\Return) body)))))

(defun dmx-http-request-body (book endpoint &key parameters accept)
  (let* ((request-url (format nil "~A~A" (dmx-base-url-of book) endpoint))
         (display-url (dmx-endpoint-url book endpoint :parameters parameters))
         (request-args (append (list request-url
                                     :method :get
                                     :want-stream t)
                               (when accept
                                 (list :additional-headers
                                       (list (cons "Accept" accept))))
                               (when parameters
                                 (list :parameters parameters)))))
    (handler-case
        (multiple-value-bind (stream status-code response-headers response-uri must-close reason-phrase)
            (apply #'drakma:http-request request-args)
          (declare (ignore response-headers response-uri must-close))
          (unwind-protect
               (values (and stream
                            (ignore-errors
                              (uiop:slurp-stream-string stream)))
                       status-code
                       display-url
                       reason-phrase)
            (when stream
              (ignore-errors (close stream)))))
      (error (cause)
        (error 'dmx-proxy-error
               :url display-url
               :message "Failed to fetch DMX data"
               :cause cause)))))

(defun parse-dmx-http-json-body (body)
  (unless (blank-dmx-http-response-body-p body)
    (shasht:read-json body)))

(defun dmx-core-topic-url (book id &key (parameters (dmx-children+assoc-parameters)))
  (dmx-endpoint-url book
                    (dmx-core-topic-endpoint id)
                    :parameters parameters))

(defun dmx-topicmap-core-topic-url (page)
  (dmx-core-topic-url (hb:hyperbook-of page)
                      (dmx-topicmap-id-of page)
                      :parameters (dmx-children+assoc-parameters)))

(defun dmx-workspace-object-url (page)
  (dmx-endpoint-url (hb:hyperbook-of page)
                    (dmx-workspace-object-endpoint (dmx-topic-id-of page))))

(defun dmx-topicmap-memberships-url (page)
  (dmx-endpoint-url (hb:hyperbook-of page)
                    (dmx-topicmap-memberships-endpoint (dmx-topic-id-of page))))

(defun dmx-workspace-owner-url (page workspace-id)
  (and workspace-id
       (dmx-endpoint-url (hb:hyperbook-of page)
                         (dmx-workspace-owner-endpoint workspace-id))))

(defun dmx-topicmap-projection-url (page)
  (dmx-endpoint-url (hb:hyperbook-of page)
                    (dmx-topicmap-projection-endpoint
                     (dmx-topicmap-id-of page))
                    :parameters (dmx-topicmap-children-parameters)))

(defun dmx-fetch-json (book endpoint &key parameters)
  (multiple-value-bind (body status-code display-url reason-phrase)
      (dmx-http-request-body book endpoint
                             :parameters parameters
                             :accept "application/json")
    (cond
      ((or (eql status-code 204)
           (eql status-code 205))
       nil)
      ((dmx-http-success-status-p status-code)
       (parse-dmx-http-json-body body))
      (t
       (error 'dmx-proxy-error
              :url display-url
              :message (or reason-phrase
                           (format nil "DMX request failed with HTTP ~D"
                                   status-code))
              :cause body)))))

(defun dmx-fetch-optional-json (book endpoint &key parameters)
  (dmx-fetch-json book endpoint :parameters parameters))

(defun dmx-fetch-text (book endpoint &key parameters)
  (multiple-value-bind (body status-code display-url reason-phrase)
      (dmx-http-request-body book endpoint :parameters parameters)
    (cond
      ((or (eql status-code 204)
           (eql status-code 205))
       nil)
      ((dmx-http-success-status-p status-code)
       (and body
            (string-trim '(#\Space #\Tab #\Newline #\Return) body)))
      (t
       (error 'dmx-proxy-error
              :url display-url
              :message (or reason-phrase
                           (format nil "DMX request failed with HTTP ~D"
                                   status-code))
              :cause body)))))

(defun fetch-dmx-core-topic-data (book id)
  (dmx-fetch-json book
                  (dmx-core-topic-endpoint id)
                  :parameters (dmx-children+assoc-parameters)))

(defun fetch-dmx-related-topics-data (book topic-id)
  (dmx-fetch-json book
                  (format nil "/core/topic/~D/related-topics" topic-id)
                  :parameters (dmx-related-topics-parameters)))

(defun parse-positive-integer (designator)
  (labels ((parse-from-string (string)
             (let ((start (position-if #'digit-char-p string)))
               (when start
                 (let ((end (or (position-if-not #'digit-char-p
                                                 string
                                                 :start start)
                                (length string))))
                   (handler-case
                       (let ((value (parse-integer string
                                                   :start start
                                                   :end end)))
                         (and (plusp value) value))
                     (error () nil)))))))
    (cond
      ((integerp designator)
       (and (plusp designator) designator))
      ((stringp designator)
       (parse-from-string designator))
      ((symbolp designator)
       (parse-from-string (symbol-name designator)))
      (t
       nil))))

(defun parse-id-from-dmx-topic-symbol (symbol)
  (let* ((name (string-downcase (symbol-name symbol)))
         (prefix "dmx-topic-"))
    (when (and (>= (length name) (length prefix))
               (string= prefix name :end2 (length prefix)))
      (let ((suffix (subseq name (length prefix))))
        (when (and (> (length suffix) 0)
                   (every #'digit-char-p suffix))
          (parse-integer suffix))))))

(defun make-dmx-hyperbook-id (topicmap-id)
  (format nil "dmx:~D" topicmap-id))

(defun ensure-dmx-hyperbook (&key
                               (base-url *dmx-base-url*)
                               (topicmap-id *dmx-topicmap-id*)
                               (main-topic-id *dmx-default-topic-id*))
  (let ((key (list base-url topicmap-id)))
    (or (gethash key *dmx-hyperbooks*)
        (let ((book (make-instance 'dmx-hyperbook
                                   :id (make-dmx-hyperbook-id topicmap-id)
                                   :base-url base-url
                                   :topicmap-id topicmap-id
                                   :title (format nil "DMX Topicmap ~D" topicmap-id)
                                   :main-page-id (format nil "~D" main-topic-id))))
          (setf (gethash key *dmx-hyperbooks*) book)
          book))))

(defun get-dmx-hyperbook (path &optional signal-error?)
  (declare (ignore signal-error?))
  (ensure-dmx-hyperbook
   :topicmap-id (or (parse-positive-integer path)
                    *dmx-topicmap-id*)))

(hb:register-scheme :dmx #'get-dmx-hyperbook)

(defmethod hb:find-page ((book dmx-hyperbook) page-id &key signal-error?)
  (let ((topic-id (parse-positive-integer page-id)))
    (if topic-id
        (or (gethash topic-id (dmx-pages-of book))
            (let ((page (make-instance 'dmx-topic-proxy
                                       :hyperbook book
                                       :id (format nil "~D" topic-id)
                                       :topic-id topic-id
                                       :topicmap-id (dmx-topicmap-id-of book))))
              (setf (gethash topic-id (dmx-pages-of book)) page)
              page))
        (and signal-error?
             (error 'hb:page-lookup-failure
                    :hyperbook book
                    :page-id (format nil "~A" page-id))))))

(defun dmx-cache-key (kind id)
  (list kind id))

(defun dmx-touch-cache-key (book key)
  (setf (dmx-cache-order-of book)
        (cons key (remove key (dmx-cache-order-of book) :test #'equal))))

(defun dmx-trim-cache (book)
  (loop while (> (length (dmx-cache-order-of book)) *dmx-cache-max-entries*)
        do (let ((oldest (car (last (dmx-cache-order-of book)))))
             (setf (dmx-cache-order-of book)
                   (butlast (dmx-cache-order-of book)))
             (remhash oldest (dmx-cache-of book)))))

(defun dmx-cache-get (book key)
  (when-let (entry (gethash key (dmx-cache-of book)))
    (let ((timestamp (getf entry :timestamp))
          (value (getf entry :value)))
      (if (<= (- (get-universal-time) timestamp) *dmx-cache-ttl-seconds*)
          (progn
            (dmx-touch-cache-key book key)
            value)
          (progn
            (remhash key (dmx-cache-of book))
            (setf (dmx-cache-order-of book)
                  (remove key (dmx-cache-order-of book) :test #'equal))
            nil)))))

(defun dmx-cache-put (book key value)
  (setf (gethash key (dmx-cache-of book))
        (list :timestamp (get-universal-time)
              :value value))
  (dmx-touch-cache-key book key)
  (dmx-trim-cache book)
  value)

(defun dmx-cache-fetch (book key thunk)
  (or (dmx-cache-get book key)
      (dmx-cache-put book key (funcall thunk))))

(defun fetch-dmx-topic-data (page)
  (let* ((book (hb:hyperbook-of page))
         (topic-id (dmx-topic-id-of page))
         (key (dmx-cache-key :topic topic-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (fetch-dmx-core-topic-data book topic-id)))))

(defun fetch-dmx-related-topics (page)
  (let* ((book (hb:hyperbook-of page))
         (topic-id (dmx-topic-id-of page))
         (key (dmx-cache-key :related topic-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (fetch-dmx-related-topics-data book topic-id)))))

(defun fetch-dmx-topicmap-data (page)
  (let* ((book (hb:hyperbook-of page))
         (topicmap-id (dmx-topicmap-id-of page))
         (key (dmx-cache-key :topicmap topicmap-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (fetch-dmx-core-topic-data book topicmap-id)))))

(defun fetch-dmx-workspace-data (page)
  (let* ((book (hb:hyperbook-of page))
         (topic-id (dmx-topic-id-of page))
         (key (dmx-cache-key :workspace topic-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (dmx-fetch-optional-json book
                                (dmx-workspace-object-endpoint topic-id))))))

(defun fetch-dmx-topicmap-memberships (page)
  (let* ((book (hb:hyperbook-of page))
         (topic-id (dmx-topic-id-of page))
         (key (dmx-cache-key :topicmap-memberships topic-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (dmx-fetch-optional-json book
                                (dmx-topicmap-memberships-endpoint topic-id))))))

(defun fetch-dmx-topicmap-projection (page)
  (let* ((book (hb:hyperbook-of page))
         (topicmap-id (dmx-topicmap-id-of page))
         (key (dmx-cache-key :topicmap-projection topicmap-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (dmx-fetch-json book
                       (dmx-topicmap-projection-endpoint topicmap-id)
                       :parameters (dmx-topicmap-children-parameters))))))

(defun fetch-dmx-workspace-owner (page workspace-id)
  (let* ((book (hb:hyperbook-of page))
         (key (dmx-cache-key :workspace-owner workspace-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (dmx-fetch-text book
                       (dmx-workspace-owner-endpoint workspace-id))))))

(defun ensure-dmx-topic-data (page &key force?)
  (when (or force?
            (null (dmx-topic-data-of page)))
    (handler-case
        (progn
          (setf (dmx-topic-data-of page)
                (fetch-dmx-topic-data page))
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-topic-data-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun ensure-dmx-related-topics (page &key force?)
  (when (or force?
            (null (dmx-related-topics-of page)))
    (handler-case
        (progn
          (setf (dmx-related-topics-of page)
                (fetch-dmx-related-topics page))
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-related-topics-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun ensure-dmx-topicmap-data (page &key force?)
  (when (or force?
            (null (dmx-topicmap-data-of page)))
    (handler-case
        (progn
          (setf (dmx-topicmap-data-of page)
                (fetch-dmx-topicmap-data page))
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-topicmap-data-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun ensure-dmx-workspace-data (page &key force?)
  (when (or force?
            (null (dmx-workspace-data-of page)))
    (handler-case
        (progn
          (setf (dmx-workspace-data-of page)
                (fetch-dmx-workspace-data page))
          (setf (dmx-workspace-owner-of page) nil)
          (setf (dmx-diagnostics-of page) nil)
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-workspace-data-of page) nil)
        (setf (dmx-workspace-owner-of page) nil)
        (setf (dmx-diagnostics-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun ensure-dmx-topicmap-memberships (page &key force?)
  (when (or force?
            (null (dmx-topicmap-memberships-of page)))
    (handler-case
        (progn
          (setf (dmx-topicmap-memberships-of page)
                (or (fetch-dmx-topicmap-memberships page)
                    #()))
          (setf (dmx-diagnostics-of page) nil)
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-topicmap-memberships-of page) #())
        (setf (dmx-diagnostics-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun ensure-dmx-topicmap-projection (page &key force?)
  (when (or force?
            (null (dmx-topicmap-projection-of page)))
    (handler-case
        (progn
          (setf (dmx-topicmap-projection-of page)
                (fetch-dmx-topicmap-projection page))
          (setf (dmx-triage-topic-proxies-of page) nil)
          (setf (dmx-repair-topic-proxies-of page) nil)
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-topicmap-projection-of page) nil)
        (setf (dmx-triage-topic-proxies-of page) nil)
        (setf (dmx-repair-topic-proxies-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun dmx-json-object-field (object key)
  (and (hash-table-p object)
       (gethash key object)))

(defun dmx-json-object-id (object)
  (dmx-json-object-field object "id"))

(defun dmx-json-field-value (object)
  (dmx-json-object-field object "value"))

(defun dmx-vector-elements (value)
  (cond
    ((null value) '())
    ((vectorp value) (coerce value 'list))
    ((listp value) value)
    (t (list value))))

(defun dmx-sorted-json-objects-by-id (objects)
  (sort (copy-list (dmx-vector-elements objects))
        #'<
        :key (lambda (object)
               (or (dmx-json-object-id object)
                   most-positive-fixnum))))

(defun dmx-topic-title-from-topic-data (topic-data)
  (or (dmx-json-field-value topic-data)
      (format nil "DMX Topic ~D"
              (or (dmx-json-object-id topic-data) 0))))

(defun dmx-uri-suffix-after-prefix (uri prefix)
  (and (stringp uri)
       (uiop:string-prefix-p prefix uri)
       (subseq uri (length prefix))))

(defun dmx-topic-ownership-summary-from-uri-prefixes (topic-data)
  (let ((uri (or (dmx-json-object-field topic-data "uri") "")))
    (cond
      ((dmx-uri-suffix-after-prefix uri *dmx-proxy-workspace-note-uri-prefix*)
       (list :class :hyperdoc-workspace-note
             :owned-p t
             :reason "HyperDoc workspace-note URI prefix"
             :note-key
             (dmx-uri-suffix-after-prefix uri
                                          *dmx-proxy-workspace-note-uri-prefix*)
             :handover-key nil))
      ((dmx-uri-suffix-after-prefix uri *dmx-proxy-handover-uri-prefix*)
       (list :class :hyperdoc-handover
             :owned-p t
             :reason "HyperDoc handover URI prefix"
             :note-key nil
             :handover-key
             (dmx-uri-suffix-after-prefix uri
                                          *dmx-proxy-handover-uri-prefix*)))
      ((dmx-uri-suffix-after-prefix uri *dmx-proxy-topic-factory-snippet-uri-prefix*)
       (list :class :hyperdoc-topic-factory-snippet
             :owned-p t
             :reason "HyperDoc topic-factory snippet URI prefix"
             :note-key nil
             :handover-key nil))
      (t
       (list :class :foreign
             :owned-p nil
             :reason "No HyperDoc-owned URI prefix matched"
             :note-key nil
             :handover-key nil)))))

(defun dmx-guarded-workspace-topic-ownership-value (ownership accessor-symbol)
  (when (and ownership
             (fboundp accessor-symbol))
    (funcall (symbol-function accessor-symbol) ownership)))

(defun dmx-topic-diagnostic-ownership-summary (topic-data)
  (if (fboundp 'classify-dmx-workspace-topic-ownership)
      (let* ((ownership (classify-dmx-workspace-topic-ownership topic-data))
             (class (dmx-guarded-workspace-topic-ownership-value
                     ownership
                     'dmx-workspace-topic-ownership-class))
             (uri (or (dmx-guarded-workspace-topic-ownership-value
                       ownership
                       'dmx-workspace-topic-ownership-uri)
                      (dmx-json-object-field topic-data "uri")
                      "")))
        (list :class class
              :owned-p (dmx-guarded-workspace-topic-ownership-value
                        ownership
                        'dmx-workspace-topic-ownership-owned-p)
              :reason (dmx-guarded-workspace-topic-ownership-value
                       ownership
                       'dmx-workspace-topic-ownership-reason)
              :note-key (when (eq class :hyperdoc-workspace-note)
                          (dmx-uri-suffix-after-prefix
                           uri
                           *dmx-proxy-workspace-note-uri-prefix*))
              :handover-key (when (eq class :hyperdoc-handover)
                              (dmx-uri-suffix-after-prefix
                               uri
                               *dmx-proxy-handover-uri-prefix*))))
      (dmx-topic-ownership-summary-from-uri-prefixes topic-data)))

(defun dmx-membership-topicmap-id (membership)
  (dmx-json-object-id membership))

(defun dmx-topicmap-projection-topics (projection)
  (dmx-sorted-json-objects-by-id
   (dmx-json-object-field projection "topics")))

(defun dmx-topicmap-projection-topic-ids (projection)
  (loop for topic in (dmx-topicmap-projection-topics projection)
        for topic-id = (dmx-json-object-id topic)
        when topic-id
        collect topic-id))

(defun dmx-topic-diagnostic-status-summary
    (ownership-class hyperdoc-owned-p selected-topicmap-membership-p workspace-id)
  (cond
    ((eq ownership-class :foreign)
     (values :foreign-object
             nil
             "No HyperDoc-owned URI prefix matched for this object."))
    ((and selected-topicmap-membership-p
          (null workspace-id))
     (values :in-topicmap-but-unassigned
             hyperdoc-owned-p
             "The object is present in the selected topicmap but has no workspace assignment."))
    ((null workspace-id)
     (values :missing-workspace-assignment
             hyperdoc-owned-p
             "The object has no workspace assignment."))
    (t
     (values :ok
             nil
             "Workspace assignment and selected topicmap placement are both present."))))

(defun compute-dmx-topic-diagnostics (page)
  (let* ((topic-data (dmx-topic-data-of page))
         (workspace-data (dmx-workspace-data-of page))
         (workspace-id (dmx-json-object-id workspace-data))
         (workspace-title (dmx-json-field-value workspace-data))
         (workspace-owner (and workspace-id
                               (or (dmx-workspace-owner-of page)
                                   (setf (dmx-workspace-owner-of page)
                                         (fetch-dmx-workspace-owner page
                                                                    workspace-id)))))
         (memberships (dmx-vector-elements (dmx-topicmap-memberships-of page)))
         (selected-topicmap-id (dmx-topicmap-id-of page))
         (selected-topicmap-membership-p
          (loop for membership in memberships
                thereis (eql selected-topicmap-id
                             (dmx-membership-topicmap-id membership))))
         (ownership (dmx-topic-diagnostic-ownership-summary topic-data))
         (topic-uri (dmx-json-object-field topic-data "uri"))
         (topic-type-uri (dmx-json-object-field topic-data "typeUri"))
         (topic-title (dmx-topic-title-from-topic-data topic-data))
         (source-endpoints
          (list (cons "topic"
                      (dmx-core-topic-url (hyperbook:hyperbook-of page)
                                          (dmx-topic-id-of page)
                                          :parameters (dmx-children+assoc-parameters)))
                (cons "workspace-assignment"
                      (dmx-workspace-object-url page))
                (cons "topicmap-memberships"
                      (dmx-topicmap-memberships-url page))
                (cons "workspace-owner"
                      (dmx-workspace-owner-url page workspace-id)))))
    (multiple-value-bind (status repair-needed-p status-reason)
        (dmx-topic-diagnostic-status-summary
         (getf ownership :class)
         (getf ownership :owned-p)
         selected-topicmap-membership-p
         workspace-id)
      (make-dmx-topic-diagnostics
       :topic-id (dmx-topic-id-of page)
       :topicmap-id selected-topicmap-id
       :topic-uri topic-uri
       :topic-type-uri topic-type-uri
       :topic-title topic-title
       :workspace-id workspace-id
       :workspace-title workspace-title
       :workspace-owner workspace-owner
       :topicmap-memberships memberships
       :selected-topicmap-membership-p selected-topicmap-membership-p
       :ownership-class (getf ownership :class)
       :ownership-reason (getf ownership :reason)
       :hyperdoc-owned-p (getf ownership :owned-p)
       :note-key (getf ownership :note-key)
       :handover-key (getf ownership :handover-key)
       :source-endpoints source-endpoints
       :status status
       :status-reason status-reason
       :repair-needed-p repair-needed-p))))

(defun ensure-dmx-topic-diagnostics (page &key force?)
  (ensure-dmx-topic-data page :force? force?)
  (ensure-dmx-topicmap-data page :force? force?)
  (ensure-dmx-workspace-data page :force? force?)
  (ensure-dmx-topicmap-memberships page :force? force?)
  (when (or force?
            (null (dmx-diagnostics-of page)))
    (handler-case
        (progn
          (setf (dmx-diagnostics-of page)
                (compute-dmx-topic-diagnostics page))
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-diagnostics-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun dmx-topic-diagnostics-repair-triage-p (diagnostics)
  (and diagnostics
       (hyperdoc::dmx-topic-diagnostics-hyperdoc-owned-p diagnostics)
       (hyperdoc::dmx-topic-diagnostics-selected-topicmap-membership-p
        diagnostics)
       (null (hyperdoc::dmx-topic-diagnostics-workspace-id diagnostics))
       (eq (hyperdoc::dmx-topic-diagnostics-status diagnostics)
           :in-topicmap-but-unassigned)))

(defun compute-dmx-workspace-repair-triage-topic-proxies (page &key force?)
  (let* ((topicmap-id (dmx-topicmap-id-of page))
         (projection (dmx-topicmap-projection-of page))
         (topic-objects (dmx-topicmap-projection-topics projection))
         (base-url (dmx-base-url-of (hb:hyperbook-of page))))
    (loop for topic in topic-objects
          for topic-id = (dmx-json-object-id topic)
          when topic-id
          collect
          (let ((proxy (make-dmx-topic-proxy :topic-id topic-id
                                             :topicmap-id topicmap-id
                                             :base-url base-url)))
            (setf (dmx-topic-data-of proxy) topic)
            (ensure-dmx-topicmap-data proxy :force? force?)
            (ensure-dmx-workspace-data proxy :force? force?)
            (ensure-dmx-topicmap-memberships proxy :force? force?)
            (when (and (dmx-workspace-data-of proxy)
                       (or force?
                           (null (dmx-workspace-owner-of proxy))))
              (setf (dmx-workspace-owner-of proxy)
                    (fetch-dmx-workspace-owner
                     proxy
                     (dmx-json-object-id (dmx-workspace-data-of proxy)))))
            (setf (dmx-diagnostics-of proxy)
                  (compute-dmx-topic-diagnostics proxy))
            (setf (dmx-load-error-of proxy) nil)
            proxy))))

(defun ensure-dmx-workspace-repair-triage (page &key force?)
  (ensure-dmx-topicmap-projection page :force? force?)
  (when (or force?
            (null (dmx-triage-topic-proxies-of page)))
    (handler-case
        (let* ((topic-proxies
                (compute-dmx-workspace-repair-triage-topic-proxies
                 page
                 :force? force?))
               (repair-topic-proxies
                (loop for proxy in topic-proxies
                      for diagnostics = (dmx-diagnostics-of proxy)
                      when (dmx-topic-diagnostics-repair-triage-p diagnostics)
                      collect proxy)))
          (setf (dmx-triage-topic-proxies-of page) topic-proxies)
          (setf (dmx-repair-topic-proxies-of page) repair-topic-proxies)
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-triage-topic-proxies-of page) nil)
        (setf (dmx-repair-topic-proxies-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun dmx-visible-topic-proxies (page &key force?)
  (ensure-dmx-workspace-repair-triage page :force? force?)
  (or (dmx-triage-topic-proxies-of page) '()))

(defun dmx-visible-assigned-topic-proxies (page &key force?)
  (let ((workspace-id (dmx-workspace-id-of page)))
    (loop for proxy in (dmx-visible-topic-proxies page :force? force?)
          for diagnostics = (dmx-diagnostics-of proxy)
          when (and diagnostics
                    (eql (dmx-topic-diagnostics-workspace-id diagnostics)
                         workspace-id))
          collect proxy)))

(defun dmx-visible-but-unassigned-topic-proxies (page &key force?)
  (loop for proxy in (dmx-visible-topic-proxies page :force? force?)
        for diagnostics = (dmx-diagnostics-of proxy)
        when (and diagnostics
                  (dmx-topic-diagnostics-selected-topicmap-membership-p
                   diagnostics)
                  (null (dmx-topic-diagnostics-workspace-id diagnostics)))
        collect proxy))

(defun make-dmx-topic-proxy (&key topic-id topicmap-id
                               (base-url *dmx-base-url*))
  (let ((resolved-topic-id (or (parse-positive-integer topic-id)
                               (error 'unknown-dmx-topic-identifier
                                      :identifier topic-id)))
        (resolved-topicmap-id (or (parse-positive-integer topicmap-id)
                                  (error 'unknown-dmx-topic-identifier
                                         :identifier topicmap-id))))
    (hb:find-page (ensure-dmx-hyperbook :base-url base-url
                                        :topicmap-id resolved-topicmap-id)
                  resolved-topic-id
                  :signal-error? t)))

(defun make-dmx-topicmap-proxy (designator &key (base-url *dmx-base-url*))
  (let ((id (or (parse-positive-integer designator)
                (error 'unknown-dmx-topic-identifier
                       :identifier designator))))
    (make-dmx-topic-proxy :topic-id id
                          :topicmap-id id
                          :base-url base-url)))

(defun make-dmx-shared-workspace-topic-proxy (topic-id
                                              &key
                                                (topicmap-id
                                                 *dmx-context-window-topicmap-id*)
                                                (base-url *dmx-base-url*))
  (make-dmx-topic-proxy :topic-id topic-id
                        :topicmap-id topicmap-id
                        :base-url base-url))

(defun make-operational-definition-note-proxy
    (&key (topicmap-id *dmx-context-window-topicmap-id*)
       (base-url *dmx-base-url*))
  (make-dmx-shared-workspace-topic-proxy 922464
                                         :topicmap-id topicmap-id
                                         :base-url base-url))

(defun make-dmx-workspace-repair-triage
    (&key (topicmap-id *dmx-context-window-topicmap-id*)
       (base-url *dmx-base-url*))
  (make-instance 'dmx-workspace-repair-triage
                 :hyperbook (ensure-dmx-hyperbook :base-url base-url
                                                  :topicmap-id topicmap-id)
                 :id (format nil "workspace-repair-triage-~D" topicmap-id)
                 :topicmap-id topicmap-id))

(defun make-dmx-shared-workspace-repair-triage
    (&key (topicmap-id *dmx-context-window-topicmap-id*)
       (base-url *dmx-base-url*))
  (make-dmx-workspace-repair-triage :topicmap-id topicmap-id
                                    :base-url base-url))

(defun make-dmx-shared-workspace-object
    (&key (workspace-id *dmx-context-window-workspace-id*)
       (topicmap-id *dmx-context-window-topicmap-id*)
       (base-url *dmx-base-url*))
  (make-instance 'dmx-shared-workspace-object
                 :hyperbook (ensure-dmx-hyperbook :base-url base-url
                                                  :topicmap-id topicmap-id)
                 :id (format nil "shared-workspace-~D-in-topicmap-~D"
                             workspace-id
                             topicmap-id)
                 :workspace-id workspace-id
                 :topicmap-id topicmap-id))

(defun make-dmx-shared-topicmap-object
    (&key (topicmap-id *dmx-context-window-topicmap-id*)
       (workspace-id *dmx-context-window-workspace-id*)
       (base-url *dmx-base-url*))
  (make-instance 'dmx-shared-topicmap-object
                 :hyperbook (ensure-dmx-hyperbook :base-url base-url
                                                  :topicmap-id topicmap-id)
                 :id (format nil "shared-topicmap-~D-for-workspace-~D"
                             topicmap-id
                             workspace-id)
                 :workspace-id workspace-id
                 :topicmap-id topicmap-id))

(defparameter *topic-proxy-mapping*
  '((concept-operational-definition :topic-id 912384 :topicmap-id 912102)
    (topic-map-operational-definition :topic-id 912384 :topicmap-id 912102)
    (dmx-topic-operational-definition :topic-id 912384 :topicmap-id 912102)
    (prepare-aarch64-image-topic :topic-id 912384 :topicmap-id 912102)
    (create-sd-card-from-playground-task-topic :topic-id 912384 :topicmap-id 912102)
    (sd-card-command-plan-playground-topic :topic-id 912384 :topicmap-id 912102)
    (sd-card-procedure-step-raw-structure-fix-topic :topic-id 912384 :topicmap-id 912102)
    (semantic-navigation-visible-clickable-topic :topic-id 912384 :topicmap-id 912102)
    (runbook-build-and-flash-sd-image-topic :topic-id 912384 :topicmap-id 912102)
    (official-rpi-sd-image-tutorial-topic :topic-id 912384 :topicmap-id 912102)
    (sd-image-zstd-to-img-handoff-defect-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-latest-filename-handoff-defect-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-filename-loss-topic :topic-id 912384 :topicmap-id 912102)
    (expr-string-quoting-regression-topic :topic-id 912384 :topicmap-id 912102)
    (preflight-rpi-sd-image-checklist-topic :topic-id 912384 :topicmap-id 912102)
    (two-installation-models-topic :topic-id 912384 :topicmap-id 912102)
    (rpi-first-boot-access-paths-topic :topic-id 912384 :topicmap-id 912102)
    (kioskbeerli-preconfigured-headless-image-topic :topic-id 912384 :topicmap-id 912102)
    (dmx-topic-912138 :topic-id 912138 :topicmap-id 912102 :label "Explicit DMX topic mapping")
    (nix-shell-topic :topic-id 912384 :topicmap-id 912102)
    (wget-topic :topic-id 912384 :topicmap-id 912102)
    (zstd-topic :topic-id 912384 :topicmap-id 912102)
    (unzstd-topic :topic-id 912384 :topicmap-id 912102)
    (dmesg-follow-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-latest-job-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-build-323111513-topic :topic-id 912384 :topicmap-id 912102)
    (nixos-image-sd-card-26-05pre958232-80bdc1e5ce51-aarch64-linux-img-zst-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-click-path-hop-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-latest-download-link-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-download-artifact-procedure-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-artifact-to-flashable-image-handoff-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-sha256-topic :topic-id 912384 :topicmap-id 912102)
    (verify-hydra-artifact-checksum-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-select-source-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-record-provenance-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-decompress-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-verify-integrity-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-confirm-architecture-topic :topic-id 912384 :topicmap-id 912102)
    (chronology-violation-topic :topic-id 912384 :topicmap-id 912102)
    (replay-precondition-violation-topic :topic-id 912384 :topicmap-id 912102)
    (journal-checker-commit-gate-topic :topic-id 912384 :topicmap-id 912102)
    (journal-gate-script-lisp-topic :topic-id 912384 :topicmap-id 912102)
    (journal-date-origin-and-fork-chronology-topic :topic-id 912384 :topicmap-id 912102)
    (journal-monotonic-normalization-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-page-generation-workflow-topic :topic-id 912384 :topicmap-id 912102)
    (git-blame-operation-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-story-item-id-policy-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-id-runtime-contract-topic :topic-id 912384 :topicmap-id 912102)
    (semantic-item-id-effects-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-id-normalization-map-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-system-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-component-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-module-serial-order-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-load-system-force-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-find-system-topic :topic-id 912384 :topicmap-id 912102)
    (undefined-function-triage-topic :topic-id 912384 :topicmap-id 912102)
    (sbcl-process-topic :topic-id 912384 :topicmap-id 912102)
    (sbcl-topic :topic-id 912384 :topicmap-id 912102)
    (isolated-evaluation-workers-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-content-runtime-policy-split-topic :topic-id 912384 :topicmap-id 912102)
    (playground-eval-surface-topic :topic-id 912384 :topicmap-id 912102)
    (playground-debug-report-surface-topic :topic-id 912384 :topicmap-id 912102)
    (web-debugger-surface-topic :topic-id 912384 :topicmap-id 912102)
    (playground-stepper-surface-topic :topic-id 912384 :topicmap-id 912102)
    (diagramming-debugger-surface-topic :topic-id 912384 :topicmap-id 912102)
    (playground-debugging-and-tooling-topic :topic-id 912384 :topicmap-id 912102)
    (step-trace-message-events-topic :topic-id 912384 :topicmap-id 912102)
    (graphviz-sequence-export-topic :topic-id 912384 :topicmap-id 912102)
    (mermaid-sequence-export-topic :topic-id 912384 :topicmap-id 912102)
    (playground-stepper-class-layout-topic :topic-id 912384 :topicmap-id 912102)
    (graph-based-discovery-and-traversal-topic :topic-id 912384 :topicmap-id 912102)
    (hyperbook-interface-no-media-discontinuity-topic :topic-id 912384 :topicmap-id 912102)
    (uniform-robot-access-topic :topic-id 912384 :topicmap-id 912102)
    (human-written-robot-code-topic :topic-id 912384 :topicmap-id 912102)
    (processing-code-inside-hyperdoc-topic :topic-id 912384 :topicmap-id 912102)
    (topic-map-work-alignment-topic :topic-id 912384 :topicmap-id 912102)
    (concept-graph-leaf-for-humans-and-robots-topic :topic-id 912384 :topicmap-id 912102)
    (second-order-hypertext-topic :topic-id 912384 :topicmap-id 912102)
    (surface-answer-topic :topic-id 912384 :topicmap-id 912102)
    (artifact-answer-topic :topic-id 912384 :topicmap-id 912102)
    (reconstruction-protocol-topic :topic-id 912384 :topicmap-id 912102)
    (skillization-loop-topic :topic-id 912384 :topicmap-id 912102)
    (codex-resume-branch-context-topic :topic-id 912384 :topicmap-id 912102)
    (hyperdoc-operating-environment-assessment-2026-03-06-topic :topic-id 912384 :topicmap-id 912102)
    (violated-handoff-topic :topic-id 912384 :topicmap-id 912102)
    (express-both-sides-of-handoff-without-manually-reversing-perspective-topic :topic-id 912384 :topicmap-id 912102)
    (prose-to-object-bridge-topic :topic-id 912384 :topicmap-id 912102)
    (display-argument-removal-topic :topic-id 912384 :topicmap-id 912102)
    (semantic-object-ref-renderer-topic :topic-id 912384 :topicmap-id 912102)
    (satechi-usbc-pro-hub-4k-hdmi-topic :topic-id 912384 :topicmap-id 912102)
    (sd-card-topic :topic-id 912384 :topicmap-id 912102)
    (micro-sd-card-topic :topic-id 912384 :topicmap-id 912102)
    (transcend-16gb-micro-sd-card-topic :topic-id 912384 :topicmap-id 912102)
    (dita-task-topic-topic :topic-id 912384 :topicmap-id 912102)
    (four-pane-browser-metaphor-topic :topic-id 912384 :topicmap-id 912102)
    (static-context-frame-topic :topic-id 912384 :topicmap-id 912102)
    (dynamic-investigation-scene-topic :topic-id 912384 :topicmap-id 912102)
    (message-flow-navigation-topic :topic-id 912384 :topicmap-id 912102)
    (ide-composition-gap-topic :topic-id 912384 :topicmap-id 912102)
    (investigation-thread-memory-topic :topic-id 912384 :topicmap-id 912102)
    (frankenstein-tool-problem-topic :topic-id 912384 :topicmap-id 912102)
    (hermit-tool-problem-topic :topic-id 912384 :topicmap-id 912102)
    (alien-tool-problem-topic :topic-id 912384 :topicmap-id 912102)
    (saturated-environment-problem-topic :topic-id 912384 :topicmap-id 912102)
    (workspace-as-graph-topic :topic-id 912384 :topicmap-id 912102)
    (scene-graph-node-topic :topic-id 912384 :topicmap-id 912102)
    (scene-graph-edge-topic :topic-id 912384 :topicmap-id 912102)
    (scene-graph-edit-cycle-topic :topic-id 912384 :topicmap-id 912102)
    (hyperdoc-scene-graph-adaptation-topic :topic-id 912384 :topicmap-id 912102)
    (human-written-robot-process-graphs-topic :topic-id 912384 :topicmap-id 912102)
    ;; Universal Thing/browser-isolation topics stay authored-only until stable
    ;; DMX topic ids are confirmed in the current topicmap.
    (ward-beck-diagram-1986-topic :topic-id 912384 :topicmap-id 912102)
    (ward-collaborating-objects-topic :topic-id 912384 :topicmap-id 912102)
    (class-browser-inspector-debugger-triangulation-topic :topic-id 912384 :topicmap-id 912102)
    (compiledmethod-interpretnextinstruction-topic :topic-id 912384 :topicmap-id 912102)
    (expanding-tools-literate-environment-topic :topic-id 912384 :topicmap-id 912102)
    (ward-diagramming-debugger-remembrance-topic :topic-id 912384 :topicmap-id 912102)
    (mech-op-args-emit-dispatch-topic :topic-id 912384 :topicmap-id 912102)
    (python-json-tool-source-topic :topic-id 912384 :topicmap-id 912102)
    (surviving-autonomous-weapons-environment-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-weapons-resilience-playbook-topic :topic-id 912384 :topicmap-id 912102)
    (post-incident-recovery-under-autonomous-threat-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-weapons-civilian-resilience-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-threat-risk-model-topic :topic-id 912384 :topicmap-id 912102)
    (protective-infrastructure-hardening-topic :topic-id 912384 :topicmap-id 912102)
    (civilian-alerting-fallback-channels-topic :topic-id 912384 :topicmap-id 912102)
    (disinformation-verification-loop-topic :topic-id 912384 :topicmap-id 912102)
    (continuity-of-care-under-disruption-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-weapons-governance-accountability-topic :topic-id 912384 :topicmap-id 912102)
    (incident-ledger-and-evidence-topic :topic-id 912384 :topicmap-id 912102)
    (service-restoration-prioritization-topic :topic-id 912384 :topicmap-id 912102)
    (community-psychological-recovery-topic :topic-id 912384 :topicmap-id 912102)
    (after-action-learning-loop-topic :topic-id 912384 :topicmap-id 912102)
    (dmx-topic-912384 :topic-id 912384 :topicmap-id 912102 :label "Explicit DMX topic mapping")))

(defun lookup-topic-proxy-mapping (function-name &key signal-error?)
  (or (assoc function-name *topic-proxy-mapping*)
      (and signal-error?
           (error 'unknown-dmx-topic-wrapper
                  :function-name function-name))))

(defun mapped-topic-id (function-name)
  (let ((entry (lookup-topic-proxy-mapping function-name :signal-error? t)))
    (getf (cdr entry) :topic-id)))

(defun mapped-topicmap-id (function-name)
  (let ((entry (lookup-topic-proxy-mapping function-name :signal-error? t)))
    (getf (cdr entry) :topicmap-id)))

(defun make-mapped-topic-proxy (function-name)
  (make-dmx-topic-proxy :topic-id (mapped-topic-id function-name)
                        :topicmap-id (mapped-topicmap-id function-name)))

(defun install-topic-proxy-wrappers ()
  (dolist (entry *topic-proxy-mapping*)
    (destructuring-bind (function-name &key topic-id topicmap-id &allow-other-keys)
        entry
      (when (and (fboundp function-name)
                 (not (gethash function-name *topic-authoring-factories*)))
        (setf (gethash function-name *topic-authoring-factories*)
              (symbol-function function-name)))
      (setf (fdefinition function-name)
            (lambda ()
              (make-dmx-topic-proxy :topic-id topic-id
                                    :topicmap-id topicmap-id)))))
  (setf *topic-index-state* :stale))

(eval-when (:load-toplevel :execute)
  (install-topic-proxy-wrappers))
