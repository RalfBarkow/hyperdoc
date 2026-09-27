;;;; Signed HyperDoc authoring envelopes: public vectors and refusals.
;;;;
;;;; The vectors in fixtures/authoring-envelope-vectors.json were signed by
;;;; sessionless-node 0.11.0 with keys that were never stored. Nothing here
;;;; needs Node, and no private key exists anywhere in the repository.

(defpackage #:dreyeck/authoring-envelope/tests
  (:use #:cl)
  (:local-nicknames (#:ae #:dreyeck/authoring-envelope)
                    (#:views #:html-inspector-views))
  (:export #:run-authoring-envelope-tests))

(in-package #:dreyeck/authoring-envelope/tests)

(defun fixture-path ()
  (asdf:system-relative-pathname "dreyeck" "dreyeck/tests/fixtures/authoring-envelope-vectors.json"))

(defun vectors ()
  (with-open-file (in (fixture-path) :external-format :utf-8)
    (shasht:read-json in)))

(defun vector-field (vectors &rest path)
  (reduce (lambda (object key) (gethash key object)) path :initial-value vectors))

(defun utf8 (string) (sb-ext:string-to-octets string :external-format :utf-8))
(defun hex (octets) (ironclad:byte-array-to-hex-string octets))
(defun unhex (string) (ironclad:hex-string-to-byte-array string))

(defun refusal (thunk)
  "The refusal reason THUNK signals, or NIL if it returns."
  (handler-case (progn (funcall thunk) nil)
    (ae:authoring-envelope-refused (condition) (ae:authoring-envelope-refusal-reason condition))))

(defun with-digit (signature position)
  "SIGNATURE with the hex digit at POSITION changed."
  (let ((copy (copy-seq signature)))
    (setf (char copy position) (if (char= #\0 (char copy position)) #\1 #\0))
    copy))

(defun signature-of (r s) (format nil "~(~64,'0X~64,'0X~)" r s))

(defun test-digest-is-ethereum-keccak (vectors)
  (let ((empty (make-array 0 :element-type '(unsigned-byte 8))))
    (assert (string= (vector-field vectors "digestKnownAnswers" "emptyKeccak256") (hex (ae:keccak-256 empty))))
    ;; SHA3-256 differs from it: a verifier using SHA3 would reject every vector.
    (assert (string= (vector-field vectors "digestKnownAnswers" "emptySha3_256")
                     (hex (ironclad:digest-sequence :sha3/256 empty))))
    (assert (string/= (hex (ae:keccak-256 empty)) (hex (ironclad:digest-sequence :sha3/256 empty))))))

(defun test-message-vector (vectors)
  (let* ((text (vector-field vectors "message" "text"))
         (bytes (utf8 text))
         (key (vector-field vectors "message" "publicKey"))
         (other (vector-field vectors "envelope" "publicKey"))
         (signature (vector-field vectors "message" "signature"))
         (n (parse-integer "fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364141" :radix 16))
         (r (parse-integer signature :end 64 :radix 16))
         (s (parse-integer signature :start 64 :radix 16)))
    (assert (string= "hyperdoc interop vector: é ✓" text))
    (assert (string= (vector-field vectors "message" "utf8Hex") (hex bytes)))
    (assert (string= (vector-field vectors "message" "keccak256") (hex (ae:keccak-256 bytes))))
    (assert (eq t (ae:verify-secp256k1-keccak-signature key bytes signature)))
    ;; Wrong, not malformed: the answer is false.
    (let ((changed (copy-seq bytes)))
      (setf (aref changed 0) (logxor 1 (aref changed 0)))
      (assert (null (ae:verify-secp256k1-keccak-signature key changed signature))))
    (assert (null (ae:verify-secp256k1-keccak-signature other bytes signature)))
    (assert (null (ae:verify-secp256k1-keccak-signature key bytes (with-digit signature 127))))
    ;; Not canonical: refused before any curve arithmetic.
    (dolist (bad (list (signature-of r (- n s))            ; the high-s twin of a valid signature
                       (signature-of 0 s) (signature-of r 0)
                       (signature-of n s) (signature-of r (1+ (floor n 2)))
                       (string-upcase signature) (subseq signature 2) (concatenate 'string signature "00")
                       (concatenate 'string (subseq signature 0 127) "g")))
      (assert (eq :malformed-signature (refusal (lambda () (ae:verify-secp256k1-keccak-signature key bytes bad))))
              () "~S was not refused as malformed." bad))
    (dolist (bad (list (vector-field vectors "offCurvePublicKey")
                       (concatenate 'string "04" (subseq key 2)) (string-upcase key) (subseq key 2)
                       (concatenate 'string key "00") ""))
      (assert (eq :malformed-public-key (refusal (lambda () (ae:verify-secp256k1-keccak-signature bad bytes signature))))
              () "~S was not refused as a malformed key." bad))))

(defun test-envelope-vector (vectors)
  (let* ((text (vector-field vectors "envelope" "text"))
         (octets (utf8 text))
         (body (utf8 (vector-field vectors "envelope" "body")))
         (key (vector-field vectors "envelope" "publicKey"))
         (signature (vector-field vectors "envelope" "signature"))
         (envelope (ae:parse-authoring-envelope octets)))
    (assert (string= (vector-field vectors "envelope" "keccak256") (hex (ae:keccak-256 octets))))
    (assert (string= (vector-field vectors "envelope" "bodyUtf8Hex") (hex body)))
    (assert (equal '("hyperdoc-authoring-test" "principal-5f1c0a9e3b7d4c2a8e6f1b0d9c7a5e3f"
                     "fedwiki-page-edit" "dreyeck.ch" "work-breakdown"
                     "3c9e1f7a5b2d8e4c6a0f1b3d5e7a9c2e4f6b8d0a1c3e5f7b9d2a4c6e8f0b1d3a"
                     1790486348545 1790486408545)
                   (list (ae:authoring-envelope-service envelope) (ae:authoring-envelope-claimed-principal envelope)
                         (ae:authoring-envelope-operation envelope) (ae:authoring-envelope-site envelope)
                         (ae:authoring-envelope-page envelope) (ae:authoring-envelope-nonce envelope)
                         (ae:authoring-envelope-claimed-issued-at envelope) (ae:authoring-envelope-claimed-expires-at envelope))))
    (assert (string= (vector-field vectors "envelope" "bodyKeccak256") (ae:authoring-envelope-body-keccak-256 envelope)))
    (assert (equalp octets (ae:authoring-envelope-octets envelope)))
    (assert (not (eq octets (ae:authoring-envelope-octets envelope))))
    (assert (eq t (ae:verify-authoring-envelope-signature envelope key signature)))
    (assert (eq t (ae:verify-authoring-body-binding envelope body)))
    ;; One body byte changed breaks the binding; the body is never parsed.
    (let ((changed (copy-seq body)))
      (setf (aref changed (1- (length changed))) (char-code #\]))
      (assert (eq :body-mismatch (refusal (lambda () (ae:verify-authoring-body-binding envelope changed))))))
    (assert (eq :body-mismatch (refusal (lambda () (ae:verify-authoring-body-binding envelope (subseq body 1))))))
    ;; The signature binds every field: each one changed to another valid value
    ;; still parses and no longer verifies.
    (dolist (swap '(("service=hyperdoc-authoring-test" . "service=hyperdoc-authoring-other")
                    ("principal=principal-5f1c" . "principal=principal-5f1d")
                    ("operation=fedwiki-page-edit" . "operation=fedwiki-page-remove")
                    ("site=dreyeck.ch" . "site=elsewhere.example")
                    ("page=work-breakdown" . "page=work-breakdowns")
                    ("nonce=3c9e" . "nonce=3c9f")
                    ("issued-at=1790486348545" . "issued-at=1790486348546")
                    ("expires-at=1790486408545" . "expires-at=1790486408546")
                    ("body-keccak256=7744" . "body-keccak256=7745")))
      (let ((changed (ae:parse-authoring-envelope (utf8 (swap-once text (car swap) (cdr swap))))))
        (assert (eq :invalid-signature (refusal (lambda () (ae:verify-authoring-envelope-signature changed key signature))))
                () "Changing ~S kept the signature valid." (car swap))))
    (assert (eq :invalid-signature
                (refusal (lambda () (ae:verify-authoring-envelope-signature
                                     envelope (vector-field vectors "message" "publicKey") signature)))))
    ;; Domain separation: the version line is signed, so the rest alone fails.
    (assert (null (ae:verify-secp256k1-keccak-signature
                   key (utf8 (subseq text (1+ (position #\Newline text)))) signature)))
    envelope))

(defun swap-once (string old new)
  (let ((at (search old string)))
    (assert (and at (null (search old string :start2 (1+ at)))) () "~S must occur once." old)
    (concatenate 'string (subseq string 0 at) new (subseq string (+ at (length old))))))

(defun test-envelope-grammar (vectors)
  (let* ((text (vector-field vectors "envelope" "text"))
         (lines (loop with start = 0 for end = (position #\Newline text :start start)
                      collect (subseq text start end) while end do (setf start (1+ end))))
         (lf (string #\Newline)))
    (flet ((joined (lines) (format nil "~{~A~^~%~}" lines))
           (refused-as (reason text)
             (let ((result (refusal (lambda () (ae:parse-authoring-envelope
                                                (if (stringp text) (utf8 text) text))))))
               (assert (eq reason result) () "~S parsed as ~S, not ~S." text result reason))))
      (dolist (case (list (joined (remove (nth 3 lines) lines :test #'string=))              ; a field missing
                          (joined (append lines (list (nth 3 lines))))                         ; a field twice
                          (joined (append (butlast lines) (list "colour=red" (car (last lines))))) ; an unknown field
                          (joined (list* (first lines) (third lines) (second lines) (nthcdr 3 lines))) ; reordered
                          (joined (rest lines))                                                ; header omitted
                          (joined (cons "other-protocol-v1" (rest lines)))                     ; another protocol
                          (concatenate 'string text lf)                                        ; trailing LF
                          (concatenate 'string text lf "extra=1")                              ; trailing data
                          (swap-once text (format nil "~%service=") (format nil "~C~%service=" #\Return)) ; CRLF
                          (swap-once text "site=dreyeck.ch" "site=")                           ; empty value
                          (swap-once text "site=dreyeck.ch" (format nil "site=~A" (make-string 129 :initial-element #\a))) ; overlong
                          (swap-once text "site=dreyeck.ch" "site=dreyeck ch")                 ; outside the alphabet
                          (swap-once text "site=dreyeck.ch" "site=dreyeck/ch")
                          (swap-once text "site=dreyeck.ch" "site==dreyeck.ch")
                          (swap-once text "nonce=3c9e" "nonce=3C9E")                           ; uppercase hex
                          (swap-once text "nonce=3c9e" "nonce=3c9")                            ; short nonce
                          (swap-once text "body-keccak256=7744" "body-keccak256=774")
                          (swap-once text "issued-at=1790486348545" "issued-at=-1790486348545") ; not decimal digits
                          (swap-once text "issued-at=1790486348545" "issued-at=1.5")
                          (swap-once text "expires-at=1790486408545" "expires-at=")
                          (swap-once text "site=dreyeck.ch" "site=dreyeck.ch ")
                          (swap-once text "site=dreyeck.ch" (format nil "site=~A" (make-string 2100 :initial-element #\a))))) ; over 2 KiB
        (refused-as :malformed-envelope case))
      ;; Not ASCII: valid UTF-8 outside the alphabet, and malformed UTF-8.
      (refused-as :malformed-envelope (swap-once text "site=dreyeck.ch" "site=dreyéck.ch"))
      (refused-as :malformed-envelope (concatenate '(vector (unsigned-byte 8))
                                                   (utf8 (subseq text 0 (search "dreyeck.ch" text)))
                                                   (vector #xc3 #x28)
                                                   (utf8 (subseq text (+ (search "dreyeck.ch" text) 10)))))
      (refused-as :malformed-envelope (make-array 0 :element-type '(unsigned-byte 8)))
      (assert (eq :malformed-envelope (refusal (lambda () (ae:parse-authoring-envelope text)))))  ; a string, not octets
      ;; Another version of this protocol is named as such.
      (refused-as :unsupported-version (joined (cons "hyperdoc-authoring-v2" (rest lines))))
      (refused-as :unsupported-version (joined (cons "hyperdoc-authoring-v10" (rest lines))))
      ;; Controls: the vector itself parses, and a boundary-length token is accepted.
      (assert (typep (ae:parse-authoring-envelope (utf8 text)) 'ae:authoring-envelope))
      (assert (typep (ae:parse-authoring-envelope
                      (utf8 (swap-once text "site=dreyeck.ch" (format nil "site=~A" (make-string 128 :initial-element #\a)))))
                     'ae:authoring-envelope)))))

(defun test-inspection (envelope)
  (let* ((view (find "Authoring envelope" (views:all-views envelope) :key #'views:view-title :test #'equal))
         (html (views:view-html view)))
    (dolist (text '("hyperdoc-authoring-v1" "fedwiki-page-edit" "dreyeck.ch" "work-breakdown"
                    "Principal (claimed)" "Issued at (claimed)" "Parsed, not trusted"))
      (assert (search text html) () "The envelope view lacks ~S." text))
    (assert (null (views:view-references view)))))

(defun test-only-public-material ()
  (let ((fixture (uiop:read-file-string (fixture-path) :external-format :utf-8)))
    (assert (not (search "private" fixture :test #'char-equal))))
  (let ((direct (mapcar #'asdf:coerce-name (asdf:system-depends-on (asdf:find-system "dreyeck/authoring-envelope")))))
    (dolist (name '("clog" "clack" "hunchentoot" "drakma" "dreyeck/fedwiki-page-authoring"
                    "dreyeck/workflow/authoring"))
      (assert (not (member name direct :test #'string-equal))))))

(defun run-authoring-envelope-tests ()
  (let ((vectors (vectors)))
    (test-digest-is-ethereum-keccak vectors)
    (test-message-vector vectors)
    (test-inspection (test-envelope-vector vectors))
    (test-envelope-grammar vectors)
    (test-only-public-material))
  (format t "~&AUTHORING-ENVELOPE-PASS: sessionless-node signatures verify over ~
Ethereum Keccak-256; high-s, zero, out-of-range and malformed signatures and ~
off-curve or malformed keys are refused; the envelope binds every field and ~
its body bytes; the strict v1 grammar refuses missing, repeated, unknown, ~
reordered, trailing, CRLF, empty, overlong, non-ASCII and other-version input.~%")
  t)
