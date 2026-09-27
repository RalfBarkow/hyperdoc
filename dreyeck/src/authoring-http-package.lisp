;;;; Signed HyperDoc authoring over HTTP: transport only

(defpackage #:dreyeck/authoring-http
  (:use #:cl)
  (:local-nicknames (#:aa #:dreyeck/authenticated-page-authoring)
                    (#:ae #:dreyeck/authoring-envelope)
                    (#:pa #:dreyeck/fedwiki-page-authoring))
  (:export #:base64url-encode #:base64url-decode
           #:authoring-http-adapter #:make-authoring-http-adapter
           #:authoring-http-adapter-authority
           #:authoring-http-response #:authoring-http-app
           #:authoring-http-listener #:start-authoring-http-listener
           #:stop-authoring-http-listener #:authoring-http-listener-port
           #:authoring-http-listener-address))
