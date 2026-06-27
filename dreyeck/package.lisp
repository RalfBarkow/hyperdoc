;;;; Package definitions for the dreyeck downstream systems
;;
;;;; Copyright (c) 2026

(defpackage :dreyeck/codex
  (:use :cl)
  (:import-from :hyperbook
                #:id-of
                #:title-of
                #:find-page)
  (:import-from :hyperdoc
                #:*hyperdoc*)
  (:export #:codex
           #:codex-context-window
           #:codex-recent-changes
           #:codex-next
           #:codex-context-provider-result
           #:codex-context-window-entry
           #:codex-context-window-chain
           #:codex-context-window-graph
           #:codex-context-window-nor-expression
           #:codex-context-window-nor-proof-for-graph
           #:codex-context-window-nor-proof
           #:codex-recent-changes-neighborhood
           #:codex-next-for-recent-changes
           #:codex-context-window-example
           #:codex-kioskbeerli-context-window-example
           #:codex-recursive-context-window-example
           #:codex-recursive-context-window-graph-example
           #:codex-recursive-context-window-nor-proof-example
           #:codex-cyclic-context-window-graph-example
           #:codex-cyclic-context-window-graph-proof-example
           #:codex-recent-changes-example
           #:codex-next-example
           #:codex-next-for-kioskbeerli-pending-work-example))

(defpackage :dreyeck/server
  (:use :cl)
  (:export #:install-dreyeck-server-scaffold
           #:dreyeck-local-boot-link-redirection
           #:dreyeck-link-target-rewriter))

(defpackage :dreyeck
  (:use :cl)
  (:import-from :dreyeck/server
                #:install-dreyeck-server-scaffold)
  (:import-from :dreyeck/codex
                #:codex
                #:codex-context-window
                #:codex-recent-changes
                #:codex-next
                #:codex-context-provider-result)
  (:export #:install-dreyeck-server-scaffold
           #:codex
           #:codex-context-window
           #:codex-recent-changes
           #:codex-next
           #:codex-context-provider-result))
