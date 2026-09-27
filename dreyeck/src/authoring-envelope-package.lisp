;;;; Signed HyperDoc authoring envelopes: parsing and verification only

(defpackage #:dreyeck/authoring-envelope
  (:use #:cl)
  (:local-nicknames (#:views #:html-inspector-views))
  (:export #:+authoring-envelope-version+
           #:keccak-256
           #:verify-secp256k1-keccak-signature
           #:authoring-envelope
           #:parse-authoring-envelope
           #:authoring-envelope-octets
           #:authoring-envelope-service
           #:authoring-envelope-claimed-principal
           #:authoring-envelope-operation
           #:authoring-envelope-site
           #:authoring-envelope-page
           #:authoring-envelope-nonce
           #:authoring-envelope-claimed-issued-at
           #:authoring-envelope-claimed-expires-at
           #:authoring-envelope-body-keccak-256
           #:verify-authoring-envelope-signature
           #:verify-authoring-body-binding
           #:authoring-envelope-refused
           #:authoring-envelope-refusal-reason
           #:authoring-envelope-refusal-detail))
