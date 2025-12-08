;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

(defpackage :hyperdoc/explorer
  (:use :cl :hyperdoc)
  (:import-from :alexandria
                #:if-let #:when-let #:compose)
  (:import-from :arrow-macros
                #:-> #:-<> #:->> #:-<>> #:<> #:some-> #:some->>)
  (:import-from :hyperbook
                #:id-of :hyperbook-of #:title-of #:main-page-id-of
                #:find-page #:find-hyperbook)
  (:import-from :hyperbook/explorer
                #:link #:object-link
                #:make-page-link #:make-hyperbook-link #:make-web-link))

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperdoc/explorer)

(trivial-package-local-nicknames:add-package-local-nickname
 :hbe :hyperbook/explorer :hyperdoc/explorer)

(trivial-package-local-nicknames:add-package-local-nickname
 :hd :hyperdoc :hyperdoc/explorer)

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperdoc/explorer)

(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperdoc/explorer)
