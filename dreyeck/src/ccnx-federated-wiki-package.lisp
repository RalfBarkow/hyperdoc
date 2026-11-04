;;;; Package for the reading "The CCNx Federated Wiki and the Power of Plain Text".

(defpackage #:dreyeck/ccnx-federated-wiki
  (:use #:cl)
  (:local-nicknames (#:lp #:dreyeck/local-fedwiki-page))
  (:export #:example-page #:example-site-root #:example-slug #:+example-kinds+))
