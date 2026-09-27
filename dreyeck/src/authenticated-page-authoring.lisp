;;;; Authenticated, authorized, single-use FedWiki page authoring
;;;;
;;;; The layer between a signed authoring envelope (AUTHORING-ENVELOPE, which
;;;; only verifies signed octets) and the FedWiki page edit (M0,
;;;; EDIT-FEDWIKI-PAGE-ITEM, which only applies an edit it is authorized for).
;;;; It supplies identity, freshness, authorization and the capability, and
;;;; nothing else: no HTTP, no session, no persistence, no Lisp authoring.
;;;;
;;;; Four facts, kept apart:
;;;;
;;;;   principal   who signed: a server-assigned id and the public keys the
;;;;               server accepts for it. A request names a principal; it never
;;;;               supplies a key.
;;;;   challenge   freshness the server owns: one nonce, issued for one
;;;;               principal, with its times, used at most once. The nonce and
;;;;               times in an envelope are claims that must equal it.
;;;;   rule        authorization: this principal may perform this operation on
;;;;               this page of this site. Signing does not grant it.
;;;;   capability  the existing FEDWIKI-PAGE-AUTHORING-CAPABILITY, derived only
;;;;               after the three above hold, with the site root chosen here.
;;;;
;;;; The order, and why:
;;;;
;;;;   parse -> principal -> signature -> body binding -> service
;;;;     -> challenge check -> rule -> body data -> CONSUME -> capability -> M0
;;;;
;;;; Nothing before CONSUME uses the challenge up: a bad signature, a changed
;;;; body, another principal's challenge, a missing rule or an unreadable body
;;;; leaves it usable by its principal. CONSUME re-checks under one lock, so of
;;;; two identical requests exactly one goes on. Everything M0 does -- the
;;;; expected Item, the page lock, the journal, persistence, verification --
;;;; stays in M0.
;;;;
;;;; Challenges live in memory. A Lisp restart forgets them, so every challenge
;;;; outstanding at a restart is refused afterwards; replay protection does not
;;;; extend to requests signed before a restart. Time is the server's clock,
;;;; passed as :NOW so that tests need not wait.

(in-package #:dreyeck/authenticated-page-authoring)

(define-condition authoring-request-refused (error)
  ((reason :initarg :reason :reader authoring-request-refusal-reason)
   (detail :initarg :detail :reader authoring-request-refusal-detail))
  (:report (lambda (condition stream)
             (format stream "Authoring request refused (~(~A~)): ~A"
                     (authoring-request-refusal-reason condition)
                     (authoring-request-refusal-detail condition))))
  (:documentation "Identity, freshness or authorization failed; nothing was
consumed and nothing was written. A malformed envelope, a bad signature or a
body mismatch is signalled as AUTHORING-ENVELOPE-REFUSED instead."))

(defun %refuse (reason control &rest arguments)
  (error 'authoring-request-refused
         :reason reason :detail (apply #'format nil control arguments)))

(defun %now-ms ()
  (multiple-value-bind (seconds microseconds) (sb-ext:get-time-of-day)
    (+ (* 1000 seconds) (floor microseconds 1000))))

(defun %token-p (string)
  (and (stringp string)
       (<= 1 (length string) 128)
       (every (lambda (character)
                (or (char<= #\a character #\z) (char<= #\A character #\Z)
                    (char<= #\0 character #\9) (find character "._:-")))
              string)))

;;; Principals

(defun new-principal-id ()
  "A fresh opaque principal id, drawn from the operating system's random source."
  (format nil "principal-~A" (ironclad:byte-array-to-hex-string (ironclad:random-data 16))))

(defclass authoring-principal ()
  ((id :initarg :id :reader authoring-principal-id)
   (keys :initarg :keys :reader authoring-principal-keys))
  (:documentation "A principal: a server-assigned id and the compressed
secp256k1 public keys currently accepted for it. The id is not a key, a name,
a connection or a secret; keys can be added without changing it."))

(defclass principal-registry ()
  ((principals :initform (make-hash-table :test #'equal) :reader %registry-principals)))

(defparameter +probe-signature+ (format nil "~64,'0D~64,'0D" 1 1)
  "A well-formed signature, used only to have a key's encoding checked.")

(defun %check-public-key (key)
  (handler-case (ae:verify-secp256k1-keccak-signature
                 key (make-array 0 :element-type '(unsigned-byte 8)) +probe-signature+)
    (ae:authoring-envelope-refused (condition)
      (when (eq :malformed-public-key (ae:authoring-envelope-refusal-reason condition))
        (error "~S is not a compressed secp256k1 public key." key)))))

(defun make-principal-registry (entries)
  "A registry from trusted configuration: ENTRIES is a list of (ID . KEYS)."
  (let ((registry (make-instance 'principal-registry)))
    (loop for (id . keys) in entries
          do (unless (%token-p id) (error "~S is not a principal id." id))
             (when (gethash id (%registry-principals registry))
               (error "The principal ~A is listed twice." id))
             (mapc #'%check-public-key keys)
             (setf (gethash id (%registry-principals registry))
                   (make-instance 'authoring-principal :id id :keys (copy-list keys))))
    registry))

(defun find-authoring-principal (registry id)
  (and (stringp id) (gethash id (%registry-principals registry))))

(defclass authenticated-principal ()
  ((principal :initarg :principal :reader %authenticated-principal)
   (envelope :initarg :envelope :reader authenticated-principal-envelope))
  (:documentation "A principal whose registered key signed this envelope, and
whose envelope binds the body it came with. Made only by
AUTHENTICATE-AUTHORING-REQUEST. It authorizes nothing."))

(defun authenticated-principal-id (authenticated)
  (authoring-principal-id (%authenticated-principal authenticated)))

;;; Challenges

(defclass authoring-challenge ()
  ((nonce :initarg :nonce :reader authoring-challenge-nonce)
   (principal-id :initarg :principal-id :reader authoring-challenge-principal-id)
   (issued-at :initarg :issued-at :reader authoring-challenge-issued-at)
   (expires-at :initarg :expires-at :reader authoring-challenge-expires-at)
   (used-p :initform nil :reader authoring-challenge-used-p))
  (:documentation "Freshness the server owns: one nonce for one principal,
usable once until EXPIRES-AT, both in server milliseconds."))

(defclass challenge-store ()
  ((challenges :initform (make-hash-table :test #'equal) :reader %store-challenges)
   (lock :initform (bt:make-lock "authoring challenges") :reader %store-lock)))

(defun make-challenge-store () (make-instance 'challenge-store))

(defun issue-authoring-challenge (store principal-id &key (now (%now-ms)) (lifetime-ms 60000))
  "A new challenge for PRINCIPAL-ID, valid until NOW plus LIFETIME-MS."
  (check-type lifetime-ms (integer 1))
  (let ((challenge (make-instance 'authoring-challenge
                                  :nonce (ironclad:byte-array-to-hex-string (ironclad:random-data 32))
                                  :principal-id principal-id
                                  :issued-at now :expires-at (+ now lifetime-ms))))
    (bt:with-lock-held ((%store-lock store))
      (setf (gethash (authoring-challenge-nonce challenge) (%store-challenges store)) challenge))))

(defun find-authoring-challenge (store nonce)
  (bt:with-lock-held ((%store-lock store))
    (gethash nonce (%store-challenges store))))

(defun %challenge-problem (challenge envelope principal-id now)
  "Why CHALLENGE cannot serve ENVELOPE from PRINCIPAL-ID at NOW, or NIL."
  (cond ((null challenge) :unknown-challenge)
        ((string/= principal-id (authoring-challenge-principal-id challenge)) :challenge-principal-mismatch)
        ((not (and (= (ae:authoring-envelope-claimed-issued-at envelope) (authoring-challenge-issued-at challenge))
                   (= (ae:authoring-envelope-claimed-expires-at envelope) (authoring-challenge-expires-at challenge))))
         :challenge-time-mismatch)
        ((> now (authoring-challenge-expires-at challenge)) :expired-challenge)
        ((authoring-challenge-used-p challenge) :used-challenge)))

(defun %check-challenge (store envelope principal-id now)
  "The challenge ENVELOPE names, if it can serve it; a refusal otherwise. Uses nothing up."
  (let* ((challenge (find-authoring-challenge store (ae:authoring-envelope-nonce envelope)))
         (problem (%challenge-problem challenge envelope principal-id now)))
    (when problem (%refuse problem "challenge ~A" (ae:authoring-envelope-nonce envelope)))
    challenge))

(defun %consume-challenge (store challenge envelope principal-id now)
  "Mark CHALLENGE used, after checking it again under the store's lock; of two
callers with the same challenge exactly one succeeds."
  (bt:with-lock-held ((%store-lock store))
    (let ((problem (%challenge-problem challenge envelope principal-id now)))
      (when problem (%refuse problem "challenge ~A" (authoring-challenge-nonce challenge)))
      (setf (slot-value challenge 'used-p) t))))

;;; Authorization

(defclass authoring-rule ()
  ((principal-id :initarg :principal-id :reader authoring-rule-principal-id)
   (operation :initarg :operation :reader authoring-rule-operation)
   (site :initarg :site :reader authoring-rule-site)
   (page :initarg :page :reader authoring-rule-page))
  (:documentation "Authorization: PRINCIPAL-ID may perform OPERATION on PAGE of
SITE. Several principals may hold rules for the same page."))

(defun make-authoring-rule (principal-id operation site page)
  (dolist (value (list principal-id operation site page))
    (unless (%token-p value) (error "~S is not a rule value." value)))
  (make-instance 'authoring-rule :principal-id principal-id :operation operation :site site :page page))

(defparameter +operations+ '(("fedwiki-page-edit" . "edit"))
  "Each authoring operation and the FedWiki Action type its capability permits.")

(defclass authoring-authority ()
  ((service-id :initarg :service-id :reader %authority-service-id)
   (registry :initarg :registry :reader authoring-authority-registry)
   (challenges :initarg :challenges :reader authoring-authority-challenges)
   (rules :initarg :rules :reader %authority-rules)
   (sites :initarg :sites :reader %authority-sites))
  (:documentation "Trusted configuration: the service name envelopes must
carry, the principals, the challenge store, the rules, and for each site id
the local site root that site id means here."))

(defun make-authoring-authority (&key service-id registry (challenges (make-challenge-store)) rules sites)
  "SITES is a list of (SITE-ID . SITE-ROOT). Site roots come from here only."
  (unless (%token-p service-id) (error "~S is not a service id." service-id))
  (make-instance 'authoring-authority
                 :service-id service-id :registry registry :challenges challenges
                 :rules (copy-list rules)
                 :sites (loop for (site . root) in sites
                              do (unless (%token-p site) (error "~S is not a site id." site))
                              collect (cons site (truename (uiop:ensure-directory-pathname root))))))

(defun %authorize (authority principal-id envelope)
  "The Action type ENVELOPE's operation grants PRINCIPAL-ID on its page, or a refusal."
  (let* ((operation (ae:authoring-envelope-operation envelope))
         (site (ae:authoring-envelope-site envelope))
         (page (ae:authoring-envelope-page envelope))
         (rules (remove principal-id (%authority-rules authority)
                        :key #'authoring-rule-principal-id :test-not #'string=)))
    (flet ((matching (predicate) (remove-if-not predicate rules)))
      (cond ((null rules) (%refuse :no-authoring-rule "no rule for ~A" principal-id))
            ((null (matching (lambda (r) (string= site (authoring-rule-site r)))))
             (%refuse :site-not-authorized "~A may not author ~A" principal-id site))
            ((null (matching (lambda (r) (and (string= site (authoring-rule-site r))
                                              (string= page (authoring-rule-page r))))))
             (%refuse :page-not-authorized "~A may not author ~A/~A" principal-id site page))
            ((or (null (assoc operation +operations+ :test #'string=))
                 (null (matching (lambda (r) (and (string= site (authoring-rule-site r))
                                                  (string= page (authoring-rule-page r))
                                                  (string= operation (authoring-rule-operation r)))))))
             (%refuse :operation-not-authorized "~A may not ~A ~A/~A" principal-id operation site page))
            ((null (assoc site (%authority-sites authority) :test #'string=))
             (%refuse :unknown-site "no authority is configured for ~A" site))
            (t (cdr (assoc operation +operations+ :test #'string=)))))))

(defun %derive-capability (authority envelope action)
  "The existing page-authoring capability: site root from AUTHORITY, the one page, the one Action type."
  (pa:make-fedwiki-page-authoring-capability
   (cdr (assoc (ae:authoring-envelope-site envelope) (%authority-sites authority) :test #'string=))
   (list (ae:authoring-envelope-page envelope))
   :actions (list action)))

;;; Requests

(defparameter +body-limit+ 65536 "The most octets of body this entry point reads.")

(defun %verifies-for-principal-p (principal octets signature)
  (some (lambda (key) (ae:verify-secp256k1-keccak-signature key octets signature))
        (authoring-principal-keys principal)))

(defun authenticate-authoring-request (authority request)
  "An AUTHENTICATED-PRINCIPAL for REQUEST, a plist with :ENVELOPE and :BODY
octets and a :SIGNATURE, verified against the keys AUTHORITY registers for the
principal the envelope names. Any other key in REQUEST is ignored."
  (let* ((envelope (ae:parse-authoring-envelope (getf request :envelope)))
         (principal (find-authoring-principal (authoring-authority-registry authority)
                                              (ae:authoring-envelope-claimed-principal envelope))))
    (unless principal
      (%refuse :unknown-principal "~A" (ae:authoring-envelope-claimed-principal envelope)))
    (unless (authoring-principal-keys principal)
      (%refuse :no-verification-key "~A has no registered key" (authoring-principal-id principal)))
    (unless (%verifies-for-principal-p principal (ae:authoring-envelope-octets envelope) (getf request :signature))
      (error 'ae:authoring-envelope-refused :reason :invalid-signature
                                            :detail "no key registered for the principal verifies it"))
    (ae:verify-authoring-body-binding envelope (getf request :body))
    (unless (string= (%authority-service-id authority) (ae:authoring-envelope-service envelope))
      (%refuse :wrong-service "the envelope is for ~A" (ae:authoring-envelope-service envelope)))
    (make-instance 'authenticated-principal :principal principal :envelope envelope)))

(defun %edit-body (octets)
  "The expected Item and the Action from the authenticated BODY, or a refusal."
  (let ((body (and (<= (length octets) +body-limit+)
                   (ignore-errors
                    (let ((shasht:*read-level* 32))
                      (shasht:read-json (sb-ext:octets-to-string octets :external-format :utf-8)))))))
    (unless (and (hash-table-p body)
                 (equal '("action" "expected")
                        (sort (loop for key being the hash-keys of body collect key) #'string<))
                 (hash-table-p (gethash "expected" body))
                 (hash-table-p (gethash "action" body)))
      (%refuse :malformed-body "the body is not {expected, action}"))
    (values (gethash "expected" body) (gethash "action" body))))

(defun authenticate-authorize-fedwiki-page-edit (authority request &key (now (%now-ms)))
  "Authenticate REQUEST, check its challenge, authorize its target, parse its
body, use the challenge up, derive the page capability and apply the edit with
EDIT-FEDWIKI-PAGE-ITEM. Returns what that returns, and the authenticated
principal. Everything about the edit itself is M0's."
  (let* ((authenticated (authenticate-authoring-request authority request))
         (principal-id (authenticated-principal-id authenticated))
         (envelope (authenticated-principal-envelope authenticated))
         (store (authoring-authority-challenges authority))
         (challenge (%check-challenge store envelope principal-id now))
         (action-type (%authorize authority principal-id envelope)))
    (multiple-value-bind (expected action) (%edit-body (getf request :body))
      (%consume-challenge store challenge envelope principal-id now)
      (values (pa:edit-fedwiki-page-item (%derive-capability authority envelope action-type)
                                         (ae:authoring-envelope-page envelope)
                                         expected action)
              authenticated))))

;;; Inspection: identifiers and states only; no keys to copy, no buttons.

(defun %fingerprint (hex) (subseq (ironclad:byte-array-to-hex-string
                                   (ae:keccak-256 (ironclad:hex-string-to-byte-array hex))) 0 16))

(defun %rows (rows)
  (views:html
    (:table :class "inspector-table"
      (dolist (row rows)
        (views:html (:tr (:td (views:esc (first row))) (:td (:code (views:esc (second row))))))))))

(views:defview authoring-principal-view (principal authoring-principal)
  (views:html-view :title "Authoring principal" :priority 1
    (%rows (list* (list "Principal id" (authoring-principal-id principal))
                  (or (loop for key in (authoring-principal-keys principal)
                            collect (list "Key fingerprint" (%fingerprint key)))
                      (list (list "Keys" "none registered")))))))

(views:defview authenticated-principal-view (authenticated authenticated-principal)
  (views:html-view :title "Authenticated principal" :priority 1
    (let ((envelope (authenticated-principal-envelope authenticated)))
      (views:html
        (%rows (list (list "Principal id" (authenticated-principal-id authenticated))
                     (list "Signed operation" (ae:authoring-envelope-operation envelope))
                     (list "Signed site / page" (format nil "~A / ~A" (ae:authoring-envelope-site envelope)
                                                        (ae:authoring-envelope-page envelope)))))
        (:p (views:esc "Authenticated only: freshness and authorization are separate checks."))))))

(views:defview authoring-challenge-view (challenge authoring-challenge)
  (views:html-view :title "Authoring challenge" :priority 1
    (%rows (list (list "Principal id" (authoring-challenge-principal-id challenge))
                 (list "Nonce" (format nil "~A…" (subseq (authoring-challenge-nonce challenge) 0 8)))
                 (list "Issued at" (princ-to-string (authoring-challenge-issued-at challenge)))
                 (list "Expires at" (princ-to-string (authoring-challenge-expires-at challenge)))
                 (list "Used" (if (authoring-challenge-used-p challenge) "yes" "no"))))))

(views:defview authoring-rule-view (rule authoring-rule)
  (views:html-view :title "Authoring rule" :priority 1
    (%rows (list (list "Principal id" (authoring-rule-principal-id rule))
                 (list "Operation" (authoring-rule-operation rule))
                 (list "Site" (authoring-rule-site rule))
                 (list "Page" (authoring-rule-page rule))))))
