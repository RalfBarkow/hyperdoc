;;;; Authenticated, authorized, single-use FedWiki page authoring

(defpackage #:dreyeck/authenticated-page-authoring
  (:use #:cl)
  (:local-nicknames (#:ae #:dreyeck/authoring-envelope)
                    (#:pa #:dreyeck/fedwiki-page-authoring)
                    (#:bt #:bordeaux-threads)
                    (#:views #:html-inspector-views))
  (:export #:new-principal-id
           #:authoring-principal #:authoring-principal-id #:authoring-principal-keys
           #:principal-registry #:make-principal-registry #:find-authoring-principal
           #:authenticated-principal #:authenticated-principal-id #:authenticated-principal-envelope
           #:authoring-challenge #:authoring-challenge-nonce #:authoring-challenge-principal-id
           #:authoring-challenge-issued-at #:authoring-challenge-expires-at #:authoring-challenge-used-p
           #:challenge-store #:make-challenge-store #:issue-authoring-challenge #:find-authoring-challenge
           #:authoring-rule #:make-authoring-rule #:authoring-rule-principal-id #:authoring-rule-operation
           #:authoring-rule-site #:authoring-rule-page
           #:authoring-authority #:make-authoring-authority
           #:authoring-authority-registry #:authoring-authority-challenges
           #:authenticate-authoring-request
           #:authenticate-authorize-fedwiki-page-edit
           #:authoring-request-refused #:authoring-request-refusal-reason #:authoring-request-refusal-detail))
