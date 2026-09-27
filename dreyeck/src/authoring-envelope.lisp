;;;; Signed HyperDoc authoring envelopes
;;;;
;;;; One question: does this signature, by this public key, authenticate this
;;;; exact envelope, and does the envelope bind these exact body bytes? Nothing
;;;; here looks up a principal, authorizes anything, consumes a nonce, derives
;;;; a capability or edits a page. A parsed envelope is signed DATA: its
;;;; principal is claimed, its times are claimed, and whether its nonce is
;;;; current is a question for a later challenge store.
;;;;
;;;; Cryptography. secp256k1 ECDSA over the Keccak-256 digest (the Ethereum
;;;; variant, not SHA3-256) of the exact message bytes. A public key is a
;;;; compressed SEC1 point: 33 bytes, 66 lowercase hex characters. A signature
;;;; is compact r || s: 64 bytes, 128 lowercase hex characters, with
;;;; 1 <= r < n and 1 <= s <= n/2 -- the low-s rule, enforced here because
;;;; Ironclad accepts either s. These are the primitives of the Sessionless
;;;; protocol, checked against signatures made by sessionless-node; the
;;;; envelope and everything built on it are HyperDoc's own, and compatible
;;;; with no Sessionless-based login or request scheme.
;;;;
;;;; The envelope. Exactly these ten lines, joined by LF with no trailing LF:
;;;;
;;;;   hyperdoc-authoring-v1
;;;;   service=<token>
;;;;   principal=<token>
;;;;   operation=<token>
;;;;   site=<token>
;;;;   page=<token>
;;;;   nonce=<64 lowercase hex>
;;;;   issued-at=<decimal integer>
;;;;   expires-at=<decimal integer>
;;;;   body-keccak256=<64 lowercase hex>
;;;;
;;;; A token is 1 to 128 characters of [A-Za-z0-9._:-]. The envelope is ASCII,
;;;; at most 2048 bytes, and it is the signed message: the version line is
;;;; signed with the rest. Nothing is normalized; anything else is refused.
;;;;
;;;; Transport. There is no HTTP here. When an HTTP route carries an envelope,
;;;; either its method and path become signed envelope fields, or operation,
;;;; site and page must be shown to determine that route unambiguously. That
;;;; is decided with the route, not before.

(in-package #:dreyeck/authoring-envelope)

(define-condition authoring-envelope-refused (error)
  ((reason :initarg :reason :reader authoring-envelope-refusal-reason)
   (detail :initarg :detail :reader authoring-envelope-refusal-detail))
  (:report (lambda (condition stream)
             (format stream "Authoring envelope refused (~(~A~)): ~A"
                     (authoring-envelope-refusal-reason condition)
                     (authoring-envelope-refusal-detail condition))))
  (:documentation "REASON is one of :MALFORMED-ENVELOPE, :UNSUPPORTED-VERSION,
:MALFORMED-PUBLIC-KEY, :MALFORMED-SIGNATURE, :INVALID-SIGNATURE and
:BODY-MISMATCH."))

(defun %refuse (reason control &rest arguments)
  (error 'authoring-envelope-refused
         :reason reason :detail (apply #'format nil control arguments)))

;;; The curve

(defparameter +secp256k1-p+
  #xfffffffffffffffffffffffffffffffffffffffffffffffffffffffefffffc2f
  "The field prime.")

(defparameter +secp256k1-n+
  #xfffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141
  "The group order.")

(defun %expt-mod (base exponent modulus)
  (loop with result = 1
        for b = (mod base modulus) then (mod (* b b) modulus)
        for e = exponent then (ash e -1)
        until (zerop e)
        when (oddp e) do (setf result (mod (* result b) modulus))
        finally (return result)))

(defun %lower-hex-p (string length)
  (and (stringp string)
       (= length (length string))
       (every (lambda (character)
                (or (char<= #\0 character #\9) (char<= #\a character #\f)))
              string)))

(defun keccak-256 (octets)
  "The Ethereum Keccak-256 digest of OCTETS."
  (ironclad:digest-sequence :keccak/256 octets))

(defun %public-key-octets (public-key)
  "The 33 octets of PUBLIC-KEY, a compressed point on the curve, or a refusal."
  (unless (and (%lower-hex-p public-key 66)
               (member (subseq public-key 0 2) '("02" "03") :test #'string=))
    (%refuse :malformed-public-key "not a 66-character compressed point"))
  (let* ((x (parse-integer public-key :start 2 :radix 16))
         (y2 (mod (+ (* x x x) 7) +secp256k1-p+))
         (y (%expt-mod y2 (/ (1+ +secp256k1-p+) 4) +secp256k1-p+)))
    (unless (and (< x +secp256k1-p+) (= y2 (mod (* y y) +secp256k1-p+)))
      (%refuse :malformed-public-key "the point is not on secp256k1")))
  (ironclad:hex-string-to-byte-array public-key))

(defun %signature-octets (signature)
  "The 64 octets of SIGNATURE, a canonical low-s compact signature, or a refusal."
  (unless (%lower-hex-p signature 128)
    (%refuse :malformed-signature "not 128 lowercase hex characters"))
  (let ((r (parse-integer signature :end 64 :radix 16))
        (s (parse-integer signature :start 64 :radix 16)))
    (unless (< 0 r +secp256k1-n+)
      (%refuse :malformed-signature "r is outside 1 .. n-1"))
    (unless (<= 1 s (floor +secp256k1-n+ 2))
      (%refuse :malformed-signature "s is outside 1 .. n/2")))
  (ironclad:hex-string-to-byte-array signature))

(defun verify-secp256k1-keccak-signature (public-key message signature)
  "Whether SIGNATURE is PUBLIC-KEY's signature of the Keccak-256 digest of the
octets MESSAGE. A malformed key or signature is refused, not answered."
  (check-type message (vector (unsigned-byte 8)))
  (let ((key (%public-key-octets public-key))
        (signature (%signature-octets signature)))
    (and (ironclad:verify-signature (ironclad:make-public-key :secp256k1 :y key)
                                    (keccak-256 message) signature)
         t)))

;;; The envelope

(defparameter +authoring-envelope-version+ "hyperdoc-authoring-v1")

(defparameter +authoring-envelope-fields+
  '("service" "principal" "operation" "site" "page" "nonce" "issued-at" "expires-at"
    "body-keccak256")
  "Every field, in the one order the format allows.")

(defparameter +authoring-envelope-limit+ 2048 "The most octets an envelope may have.")

(defclass authoring-envelope ()
  ((octets :initarg :octets)
   (service :initarg :service :reader authoring-envelope-service)
   (principal :initarg :principal :reader authoring-envelope-claimed-principal)
   (operation :initarg :operation :reader authoring-envelope-operation)
   (site :initarg :site :reader authoring-envelope-site)
   (page :initarg :page :reader authoring-envelope-page)
   (nonce :initarg :nonce :reader authoring-envelope-nonce)
   (issued-at :initarg :issued-at :reader authoring-envelope-claimed-issued-at)
   (expires-at :initarg :expires-at :reader authoring-envelope-claimed-expires-at)
   (body-keccak-256 :initarg :body-keccak-256 :reader authoring-envelope-body-keccak-256))
  (:documentation "A parsed hyperdoc-authoring-v1 envelope: the signed message
and what it says. Every value is a claim until a later layer checks it: the
principal may not exist, the site and page may not be authorized, the times
are the signer's, and the nonce may be unknown, spent or expired."))

(defmethod print-object ((envelope authoring-envelope) stream)
  (print-unreadable-object (envelope stream :type t)
    (format stream "~A ~A/~A by ~A" (authoring-envelope-operation envelope)
            (authoring-envelope-site envelope) (authoring-envelope-page envelope)
            (authoring-envelope-claimed-principal envelope))))

(defun authoring-envelope-octets (envelope)
  "A copy of the exact signed octets."
  (copy-seq (slot-value envelope 'octets)))

(defun %token-p (value)
  (and (<= 1 (length value) 128)
       (every (lambda (character)
                (or (char<= #\a character #\z) (char<= #\A character #\Z)
                    (char<= #\0 character #\9) (find character "._:-")))
              value)))

(defun %field-value-p (name value)
  (cond ((member name '("nonce" "body-keccak256") :test #'string=) (%lower-hex-p value 64))
        ((member name '("issued-at" "expires-at") :test #'string=)
         (and (<= 1 (length value) 19) (every #'digit-char-p value)))
        (t (%token-p value))))

(defun %split-lines (text)
  "TEXT split at each LF; a trailing LF yields a final empty line."
  (loop with start = 0
        for end = (position #\Newline text :start start)
        collect (subseq text start end)
        while end
        do (setf start (1+ end))))

(defun parse-authoring-envelope (octets)
  "The envelope OCTETS encode, or AUTHORING-ENVELOPE-REFUSED. Parsing checks
the format and nothing else."
  (unless (typep octets '(vector (unsigned-byte 8)))
    (%refuse :malformed-envelope "an envelope is octets"))
  (unless (<= (length octets) +authoring-envelope-limit+)
    (%refuse :malformed-envelope "more than ~D octets" +authoring-envelope-limit+))
  (unless (every (lambda (octet) (and (< octet 128) (/= octet 13))) octets)
    (%refuse :malformed-envelope "only ASCII without carriage returns"))
  (let* ((text (map 'string #'code-char octets))
         (lines (%split-lines text))
         (header (first lines)))
    (unless (string= header +authoring-envelope-version+)
      (if (and (< 20 (length header)) (string= "hyperdoc-authoring-v" header :end2 20))
          (%refuse :unsupported-version "~S is not ~A" header +authoring-envelope-version+)
          (%refuse :malformed-envelope "the first line is not ~A" +authoring-envelope-version+)))
    (unless (= (length lines) (1+ (length +authoring-envelope-fields+)))
      (%refuse :malformed-envelope "~D lines, not ~D" (length lines) (1+ (length +authoring-envelope-fields+))))
    (let ((values
            (loop for line in (rest lines)
                  for name in +authoring-envelope-fields+
                  for prefix = (concatenate 'string name "=")
                  for value = (and (> (length line) (length prefix))
                                   (string= prefix line :end2 (length prefix))
                                   (subseq line (length prefix)))
                  unless (and value (%field-value-p name value))
                    do (%refuse :malformed-envelope "line ~S is not a valid ~A field" line name)
                  collect value)))
      (destructuring-bind (service principal operation site page nonce issued-at expires-at body)
          values
        (make-instance 'authoring-envelope
                       :octets (copy-seq octets)
                       :service service :principal principal :operation operation
                       :site site :page page :nonce nonce
                       :issued-at (parse-integer issued-at) :expires-at (parse-integer expires-at)
                       :body-keccak-256 body)))))

(defun verify-authoring-envelope-signature (envelope public-key signature)
  "T if SIGNATURE is PUBLIC-KEY's signature of ENVELOPE's exact octets;
otherwise AUTHORING-ENVELOPE-REFUSED. Says nothing about who PUBLIC-KEY is."
  (check-type envelope authoring-envelope)
  (unless (verify-secp256k1-keccak-signature public-key (slot-value envelope 'octets) signature)
    (%refuse :invalid-signature "the signature does not verify for this key"))
  t)

(defun verify-authoring-body-binding (envelope body)
  "T if the Keccak-256 of the exact octets BODY is the envelope's body digest;
otherwise AUTHORING-ENVELOPE-REFUSED. BODY is never parsed or normalized."
  (check-type envelope authoring-envelope)
  (check-type body (vector (unsigned-byte 8)))
  (unless (string= (authoring-envelope-body-keccak-256 envelope)
                   (ironclad:byte-array-to-hex-string (keccak-256 body)))
    (%refuse :body-mismatch "the body's Keccak-256 is not the envelope's"))
  t)

(views:defview authoring-envelope-view (envelope authoring-envelope)
  (views:html-view :title "Authoring envelope" :priority 1
    (views:html
      (:table :class "inspector-table"
        (dolist (row (list (list "Protocol" +authoring-envelope-version+)
                           (list "Service" (authoring-envelope-service envelope))
                           (list "Operation" (authoring-envelope-operation envelope))
                           (list "Site" (authoring-envelope-site envelope))
                           (list "Page" (authoring-envelope-page envelope))
                           (list "Principal (claimed)" (authoring-envelope-claimed-principal envelope))
                           (list "Issued at (claimed)" (princ-to-string (authoring-envelope-claimed-issued-at envelope)))
                           (list "Expires at (claimed)" (princ-to-string (authoring-envelope-claimed-expires-at envelope)))
                           (list "Nonce" (authoring-envelope-nonce envelope))
                           (list "Body Keccak-256" (authoring-envelope-body-keccak-256 envelope))))
          (views:html (:tr (:td (views:esc (first row))) (:td (:code (views:esc (second row))))))))
      (:p (views:esc "Parsed, not trusted: no signature, principal, authorization or nonce has been checked by parsing.")))))
