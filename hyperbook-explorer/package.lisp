;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

;; No new package, we add to :hyperbook

(in-package :hyperbook)

(export '(link target-hyperbook-of target-page-of key-of
          object-link thunk-of view-of
          web-link url-of
          make-page-link
          make-hyperbook-link
          make-web-link
          dom-of
          content-view
          render-node))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook)
(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperbook)
