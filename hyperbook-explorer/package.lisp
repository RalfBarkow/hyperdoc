;;;; Package definition
;;
;;;; Copyright (c) 2025 Konrad Hinsen <konrad.hinsen@fastmail.net>

;; No new package, we add to :hyperbook

(in-package :hyperbook)

(export '(link source-page-of source-hyperbook-of key-of
          link-text-of source-section-of
          target-hyperbook-of target-page-of
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
          lookup-issue page-lookup-issue function-lookup-issue target-grouping-issue
          make-page-lookup-issue make-function-lookup-issue make-target-grouping-issue
          lookup-issue-source-page-title-of
          lookup-issue-source-page-id-of
          lookup-issue-source-section-of
          lookup-issue-link-text-of
          lookup-issue-expected-page-id-of
          lookup-issue-target-hyperbook-id-of
          lookup-issue-target-site-of
          lookup-issue-target-kind-of
          lookup-issue-classification-of
          lookup-issue-status-of
          lookup-issue-suggested-repair-of
          lookup-issue-repair-description-of
          lookup-issue-details-of
          lookup-issue-underlying-condition-of
          lookup-issue-underlying-message-of
          lookup-issue-link-of
          lookup-issue-source-object-of
          lookup-issue-signature
          mark-lookup-issue!
          bounded-lookup-issue-current-status-of
          bounded-lookup-issue-current-suggested-repair-of
          bounded-lookup-issue-current-repair-description-of
          bounded-lookup-issue-current-repair-thunk-of
          bounded-lookup-issue-current-details-of
          enrich-lookup-issue
          lookup-issues-of
          replace-by-hyperbook-link
          register-link-target-rewriter
          render-hyperbook-or-page-link
          render-source-surface-lines
          render-file-source-surface
          👀links
          👀backlinks
          👀lookup-issues
          dom-of
          html-nodes
          render-node
          serialize-a-element))

(trivial-package-local-nicknames:add-package-local-nickname
 :views :html-inspector-views :hyperbook)
(trivial-package-local-nicknames:add-package-local-nickname
 :views/standard :html-inspector-views/standard :hyperbook)
