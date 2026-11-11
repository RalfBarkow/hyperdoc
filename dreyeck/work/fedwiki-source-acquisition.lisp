;;;; S1: evidence at the existing FedWiki HTTP boundary. No executor or new reader.
(defpackage #:dreyeck/work/fedwiki-source-acquisition
  (:use #:cl)
  (:local-nicknames (#:fw #:hyperbook/fedwiki) (#:hb #:hyperbook)
                    (#:local #:dreyeck/local-fedwiki-page)
                    (#:offline #:dreyeck/work/fedwiki-local-only)
                    (#:v #:html-inspector-views))
  (:export #:acquire-source #:source-acquisition #:response-observation
           #:acquisition-status #:acquisition-stage #:acquisition-reason
           #:acquisition-condition #:acquisition-site #:acquisition-slug
           #:acquisition-protocol #:acquisition-sitemap #:acquisition-sitemap-state
           #:acquisition-entry #:acquisition-sitemap-response #:acquisition-page-response
           #:acquisition-root #:acquisition-page #:acquisition-local-source
           #:response-url #:response-effective-url #:response-started-at
           #:response-finished-at #:response-status #:response-headers #:response-reason
           #:response-octets #:response-sha256 #:response-complete-p #:response-kind
           #:verify-snapshot #:source-acquisition-refusal #:refusal-reason #:refusal-cause #:run-tests))
(in-package #:dreyeck/work/fedwiki-source-acquisition)

(define-condition source-acquisition-refusal (error)
  ((reason :initarg :reason :reader refusal-reason)
   (cause :initarg :cause :initform nil :reader refusal-cause))
  (:report (lambda (c s) (format s "Source acquisition refused: ~S" (refusal-reason c)))))
(defun refuse (reason) (error 'source-acquisition-refusal :reason reason))
(defclass response-observation ()
  ((url :initarg :url :reader response-url)
   (effective-url :initform nil :accessor response-effective-url)
   (started :initform (get-universal-time) :reader response-started-at)
   (finished :initform nil :accessor response-finished-at)
   (status :initform nil :accessor response-status)
   (headers :initform nil :accessor response-headers)
   (reason :initform nil :accessor response-reason)
   (octets :initform (make-array 0 :element-type '(unsigned-byte 8)) :accessor response-octets)
   (sha256 :initform nil :accessor response-sha256)
   (complete :initform nil :accessor response-complete-p)
   (kind :initarg :kind :reader response-kind)))
(defclass source-acquisition ()
  ((status :initform :refused :accessor acquisition-status)
   (stage :initform :inputs :accessor acquisition-stage)
   (reason :initform nil :accessor acquisition-reason)
   (condition :initform nil :accessor acquisition-condition)
   (site :initarg :site :reader acquisition-site)
   (slug :initarg :slug :reader acquisition-slug)
   (protocol :initarg :protocol :reader acquisition-protocol)
   (root :initform nil :accessor acquisition-root)
   (sitemap-response :initform nil :accessor acquisition-sitemap-response)
   (page-response :initform nil :accessor acquisition-page-response)
   (sitemap :initform nil :accessor acquisition-sitemap)
   (sitemap-state :initform nil :accessor acquisition-sitemap-state)
   (entry :initform nil :accessor acquisition-entry)
   (page :initform nil :accessor acquisition-page)
   (local-source :initform nil :accessor acquisition-local-source)))

(defun sha256 (octets)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))
(defun header (name headers)
  (let ((values (loop for (key . value) in headers when (eq key name) collect value)))
    (when (or (> (length values) 1) (some (complement #'stringp) values))
      (refuse (list :ambiguous-header name)))
    (first values)))
(defun uri-text (uri)
  (etypecase uri (string uri) (puri:uri (puri:render-uri uri nil))))
(defun http-transport (url)
  ;; No protocol probe, initializer, redirects, decompression or implicit text conversion.
  (drakma:http-request url :method :get :want-stream t :force-binary t
                      :decode-content nil :redirect nil :close t
                      :accept "application/json"
                      :additional-headers '(("Accept-Encoding" . "identity"))))
(defun receive-response (observation transport max-bytes timeout)
  "TRANSPORT has Drakma's seven-value contract. Always close returned streams.
Digest identifies retained body octets, not HTTP framing. COMPLETE is false on partial reads."
  (let ((body nil) (connection nil)
        (bytes (make-array 0 :element-type '(unsigned-byte 8) :adjustable t :fill-pointer 0)))
    (unwind-protect
         (sb-ext:with-timeout timeout
           (multiple-value-bind (stream status headers effective raw must-close reason)
               (funcall transport (response-url observation))
             (declare (ignore must-close))
             (setf body stream connection raw
                   (response-status observation) status
                   (response-headers observation) (copy-tree headers)
                   (response-effective-url observation) (uri-text effective)
                   (response-reason observation) reason)
             (unless (streamp body) (refuse :binary-response-stream-required))
             (loop for byte = (read-byte body nil nil) while byte do
               (when (= (length bytes) max-bytes) (refuse :body-limit))
               (vector-push-extend byte bytes))
             (let ((length-header (header :content-length headers)))
               (when length-header
                 (unless (and (plusp (length length-header))
                              (every #'digit-char-p length-header)
                              (= (parse-integer length-header) (length bytes)))
                   (refuse :content-length-mismatch))))
             (setf (response-complete-p observation) t)))
      (setf (response-octets observation) (copy-seq bytes)
            (response-sha256 observation) (sha256 bytes)
            (response-finished-at observation) (get-universal-time))
      (when (streamp body) (ignore-errors (close body)))
      (when (and (streamp connection) (not (eq body connection)))
        (ignore-errors (close connection))))))
(defun response-json (response)
  (unless (equal (response-url response) (response-effective-url response))
    (refuse :response-url-mismatch))
  (unless (eql 200 (response-status response)) (refuse :unexpected-http-status))
  (let* ((headers (response-headers response))
         (encoding (header :content-encoding headers))
         (type (header :content-type headers))
         (parts (and type (mapcar (lambda (s) (string-trim '(#\Space #\Tab) s))
                                  (uiop:split-string type :separator ";")))))
    (unless (or (null encoding) (string-equal encoding "identity"))
      (refuse :unsupported-content-encoding))
    (unless (and parts (string-equal "application/json" (first parts))
                 (every (lambda (p) (member (string-downcase p)
                                           '("charset=utf-8" "charset=\"utf-8\"") :test #'equal))
                        (rest parts)))
      (refuse :unsupported-content-type)))
  (let ((text (handler-case
                  (sb-ext:octets-to-string (response-octets response) :external-format :utf-8)
                (sb-int:character-decoding-error (c)
                  (error 'source-acquisition-refusal :reason :invalid-utf-8 :cause c)))))
    (with-input-from-string (in text)
      ;; SINGLE-VALUE=T already rejects trailing input in the existing SHASHT reader.
      (handler-case (shasht:read-json in t nil t)
        (error (c) (error 'source-acquisition-refusal :reason :invalid-json :cause c))))))
(defun checked-sitemap (json)
  ;; FETCH-SITEMAP owns sitemap interpretation and skeleton construction.
  ;; Check its input shape first so malformed remote data cannot partially hydrate a site.
  (unless (offline::json-array-p json) (refuse :sitemap-needs-array))
  (let ((slugs (make-hash-table :test #'equal)))
    (loop for entry across json do
      (unless (and (hash-table-p entry)
                   (stringp (gethash "slug" entry))
                   (dreyeck/fedwiki-assets:fedwiki-page-slug-p (gethash "slug" entry))
                   (offline::name-string-p (gethash "title" entry))
                   (or (null (gethash "links" entry)) (hash-table-p (gethash "links" entry))))
        (refuse :invalid-sitemap-entry))
      (when (gethash (gethash "slug" entry) slugs) (refuse :duplicate-sitemap-slug))
      (setf (gethash (gethash "slug" entry) slugs) t)))
  json)
(defun checked-root (root)
  (let* ((path (uiop:ensure-directory-pathname root))
         (parent (uiop:pathname-parent-directory-pathname path)))
    (unless (and (uiop:absolute-pathname-p path) (not (wild-pathname-p path))
                 parent (equal parent (truename parent))
                 (stringp (car (last (pathname-directory path))))
                 (not (member (car (last (pathname-directory path))) '("." "..") :test #'equal)))
      (refuse :capture-root-needs-canonical-parent))
    (when (probe-file path) (refuse :capture-root-exists))
    path))
(defun write-octets-exclusive (path octets)
  (with-open-file (out path :direction :output :element-type '(unsigned-byte 8)
                           :if-exists :error :if-does-not-exist :create)
    (write-sequence octets out)))

(defun %verify-snapshot (acquisition)
  "Fresh local reads only. Does not confer independent-verifier or remote-freshness status.
Return another native local source observation; signal an inspectable refusal on mismatch."
  (unless (eq :acquired (acquisition-status acquisition)) (refuse :acquisition-not-successful))
  (let* ((root (acquisition-root acquisition))
         (sitemap-path (merge-pathnames "sitemap.json" root))
         (page-path (dreyeck/fedwiki-assets:local-fedwiki-page-pathname root (acquisition-slug acquisition))))
    (dolist (path (list root (merge-pathnames "pages/" root) sitemap-path page-path))
      (unless (equal path (truename path)) (refuse :snapshot-path-changed)))
    (let ((bytes (local::%read-octets sitemap-path))
          (response (acquisition-sitemap-response acquisition)))
      (unless (and (equalp bytes (response-octets response))
                   (equal (sha256 bytes) (response-sha256 response)))
        (refuse :sitemap-snapshot-mismatch)))
    (let ((bytes (local::%read-octets page-path))
          (response (acquisition-page-response acquisition))
          (source (local:observe-local-fedwiki-page-source root (acquisition-slug acquisition))))
      (unless (and (equalp bytes (response-octets response))
                   (equal (sha256 bytes) (response-sha256 response))
                   (= (length bytes) (local:page-source-octet-count source))
                   (equal (sha256 bytes) (local:page-source-sha256 source)))
        (refuse :page-snapshot-mismatch))
      source)))

(defun verify-snapshot (acquisition)
  "Read-only verification; preserve the original file/reader condition on refusal."
  (handler-case (%verify-snapshot acquisition)
    (source-acquisition-refusal (c) (error c))
    (error (c) (error 'source-acquisition-refusal :reason :snapshot-read-failure :cause c))))

(defun acquire-source (site slug protocol capture-root
                       &key expected-title transport allow-network
                         (max-bytes 1048576) (timeout 20))
  "Explicit, bounded sitemap + page capture; never called by loading or rendering.
TRANSPORT is an injected fixture boundary; without it real HTTP requires ALLOW-NETWORK.
CAPTURE-ROOT must be new, below an existing canonical parent. It is an inert evidence
store, never the S2 destination. No Catalog registration, Wiki write or fork occurs."
  (let ((result (make-instance 'source-acquisition :site site :slug slug :protocol protocol)))
    (handler-case
        (progn
          (unless (and (stringp site) (cl-ppcre:scan "\\A[A-Za-z0-9.-]+(?::[0-9]+)?\\z" site)
                       (stringp slug) (dreyeck/fedwiki-assets:fedwiki-page-slug-p slug)
                       (member protocol '("http" "https") :test #'equal)
                       (or (null expected-title) (offline::name-string-p expected-title))
                       (integerp max-bytes) (plusp max-bytes)
                       (realp timeout) (plusp timeout))
            (refuse :invalid-inputs))
          (unless (or transport allow-network) (refuse :network-not-authorized))
          (let* ((root (checked-root capture-root))
                 (kind (if transport :fixture :http))
                 (fetch (or transport #'http-transport))
                 ;; Plain construction never runs the normal network initializer.
                 (wiki (make-instance 'fw::fedwiki :id (concatenate 'string "fedwiki:" site))))
            (setf (slot-value wiki 'fw::protocol) protocol
                  (acquisition-stage result) :sitemap)
            (unwind-protect
                 (fw::fetch-sitemap
                  wiki :json-fetcher
                  (lambda (url)
                    (let ((response (make-instance 'response-observation :url url :kind kind)))
                      (setf (acquisition-sitemap-response result) response)
                      (receive-response response fetch max-bytes timeout)
                      (checked-sitemap (response-json response)))))
              (setf (acquisition-sitemap result) (fw::sitemap-of wiki)
                    (acquisition-sitemap-state result) (fw::sitemap-snapshot wiki)))
            (let* ((entry (find slug (acquisition-sitemap result) :test #'equal
                                :key (lambda (e) (gethash "slug" e))))
                   (page (gethash slug (fw::pages-of wiki))))
              (unless (and entry page
                           (or (null expected-title) (equal expected-title (gethash "title" entry))))
                (refuse :sitemap-target-mismatch))
              (setf (acquisition-entry result) entry
                    (acquisition-stage result) :page)
              (let* ((origin (fw::origin-of page))
                     (url (fw::wiki-url (fw::domain-name-of origin) (fw::protocol-of origin)
                                       (concatenate 'string "/" (fw::origin-id-of page) ".json")))
                     (response (make-instance 'response-observation :url url :kind kind)))
                (setf (acquisition-page-response result) response)
                (receive-response response fetch max-bytes timeout)
                (let* ((parsed (response-json response))
                       (json (handler-case (offline::checked-page-json parsed)
                               (offline:invalid-observation (c)
                                 (error 'source-acquisition-refusal :reason :invalid-page-json :cause c)))))
                  (unless (equal (gethash "title" entry) (gethash "title" json))
                    (refuse :page-title-mismatch)))
                (setf (acquisition-stage result) :snapshot)
                ;; Atomic root reservation refuses collisions, including a concurrent creator.
                (sb-posix:mkdir (namestring root) #o700)
                (setf (acquisition-root result) (truename root))
                (ensure-directories-exist (merge-pathnames "pages/" root))
                (write-octets-exclusive (merge-pathnames "sitemap.json" root)
                                        (response-octets (acquisition-sitemap-response result)))
                (write-octets-exclusive (dreyeck/fedwiki-assets:local-fedwiki-page-pathname root slug)
                                        (response-octets response))
                (setf (acquisition-stage result) :offline-hydration)
                (let ((local-site (offline:make-own-site root (hb:id-of wiki))))
                  (setf (slot-value local-site 'fw::protocol) protocol)
                  (let ((hydrated (hb:find-page local-site slug :signal-error? t)))
                    (unless (equal (local:page-source-sha256 (offline::source-of hydrated))
                                   (response-sha256 response))
                      (refuse :hydration-snapshot-mismatch))
                    ;; Check a separate disk read before publishing a successful acquisition.
                    (setf (acquisition-status result) :acquired)
                    (verify-snapshot result)
                    (setf (acquisition-page result) hydrated
                          (acquisition-local-source result) (offline::source-of hydrated)
                          (acquisition-stage result) :complete))))))
          result)
      ((or error sb-ext:timeout) (c)
        (setf (acquisition-status result) :refused
              (acquisition-reason result) (typecase c
                                           (source-acquisition-refusal (refusal-reason c))
                                           (sb-ext:timeout :timeout)
                                           (t :operation-error))
              (acquisition-condition result) c)
        result))))

(v:defview acquisition-evidence (record source-acquisition)
  (v:html-view :title "Source acquisition evidence" :priority 0
    (v:html (:h2 "FedWiki source acquisition")
      (:p (v:esc (format nil "~S at ~S. No S2 destination observation or fork."
                         (acquisition-status record) (acquisition-stage record))))
      (:p (v:esc (format nil "Requested ~A://~A/~A.json"
                           (acquisition-protocol record) (acquisition-site record) (acquisition-slug record))))
      (:p "Injected transport is fixture evidence; HTTP capture is not authenticated authorship.")
      (:p (v:object-ref (acquisition-sitemap-response record) :display "Sitemap response")
          " · " (v:object-ref (acquisition-sitemap record) :display "Retained sitemap")
          " · " (v:object-ref (acquisition-sitemap-state record) :display "Sitemap snapshot")
          " · " (v:object-ref (acquisition-entry record) :display "Selected entry"))
      (:p (v:object-ref (acquisition-page-response record) :display "Page response")
          " · " (v:object-ref (acquisition-local-source record) :display "Local snapshot observation")
          " · " (v:object-ref (acquisition-page record) :display "Offline FedWiki page"))
      (when (acquisition-condition record)
        (v:html (:p (v:esc (princ-to-string (acquisition-reason record)))
                    " " (v:object-ref (acquisition-condition record) :display "Refusal condition")))))))
(v:defview response-evidence (response response-observation)
  (v:html-view :title "HTTP evidence" :priority 0
    (v:html (:p (v:esc (format nil "~S · status ~S · complete ~S · ~D retained body octets"
                                (response-kind response) (response-status response)
                                (response-complete-p response) (length (response-octets response)))))
      (:p "Partial-body digests identify retained bytes only; they are not complete source digests.")
      (:p (v:esc (response-url response)))
      (:p (v:object-ref (response-headers response) :display "Response headers")
          " · " (v:object-ref (response-octets response) :display "Original body octets")
          " · " (v:object-ref (response-sha256 response) :display "SHA-256")))))
