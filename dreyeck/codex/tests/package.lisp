;;;; Tests for Dreyeck Codex collaboration surfaces.

(defpackage #:dreyeck/codex/tests
  (:use #:cl)
  (:import-from #:dreyeck/codex
                #:codex-dmx-build-referee-subgraph
                #:codex-dmx-association-edge-reassignment-reader-surface
                #:codex-domkin-2017-source-topics
                #:codex-domkin-2017-source-subgraph)
  (:import-from #:dreyeck.dmx.sqlite
                #:initialize-dmx-associative-mirror
                #:materialize-durable-notes-into-production-db
                #:dmx-materialized-learning-topics)
  (:export #:run-dreyeck-codex-smoke-tests))
