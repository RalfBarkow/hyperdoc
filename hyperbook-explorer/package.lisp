;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

;; No new package, we add to :hyperbook

(in-package :hyperbook)

(export '(link source-page-of target-hyperbook-of target-page-of key-of
          object-link thunk-of view-of
          page-link
          hyperbook-link
          web-link url-of
          make-page-link
          make-hyperbook-link
          make-web-link
          links web-links-of page-links-of hyperbook-links-of
          no-links?
          extract-links
          replace-by-hyperbook-link
          render-hyperbook-or-page-link
          👀links
          👀backlinks
          dom-of
          html-nodes
          render-node
          serialize-a-element))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook)
(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperbook)
