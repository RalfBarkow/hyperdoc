;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

;; No new package, we add to :hyperdoc

(in-package :hyperdoc)

;; Import symbols from :hyperbook that were added
;; by system hyperbook/explorer.

(import '(hyperbook:link
          hyperbook:target-hyperbook-of hyperbook:target-page-of
          hyperbook:key-of
          hyperbook:object-link
          hyperbook:thunk-of hyperbook:view-of
          hyperbook:web-link
          hyperbook:url-of
          hyperbook:make-page-link
          hyperbook:make-hyperbook-link
          hyperbook:make-web-link))

(trivial-package-local-nicknames:add-package-local-nickname
 :hb :hyperbook :hyperdoc)

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperdoc)

(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperdoc)
