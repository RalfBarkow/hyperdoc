;;;; Smoke tests for Dreyeck Codex collaboration surfaces.

(in-package #:dreyeck/codex/tests)

(defun assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A: expected ~S, got ~S" message expected actual)))

(defun assert-true (value message)
  (unless value
    (error "~A" message)))

(defun temporary-dreyeck-codex-dmx-db-path ()
  (merge-pathnames
   (format nil "dreyeck-codex-dmx-~D.sqlite" (random 1000000))
   (uiop:temporary-directory)))

(defun make-test-codex-dmx-learning-topics (inspection db-path)
  (make-instance
   'dreyeck/codex::codex-dmx-learning-topics
   :id "codex-dmx-learning-topics-test"
   :title "Codex DMX Learning Topics"
   :summary "Test projection for materialized DMX learning topics."
   :production-db-path (namestring db-path)
   :status (getf inspection :status)
   :topics (getf inspection :topics)
   :support-topics (getf inspection :support-topics)
   :associations (getf inspection :associations)
   :last-replay-status :idempotent
   :build-tasks nil
   :inspect-task-result nil
   :validation-task-result nil
   :referee-result nil
   :referee-route nil
   :optional-provider-results nil))

(defun record-test-described-by-edge (db source target)
  (record-dmx-association-value
   db
   (format nil "assoc:~A:described-by:~A" source target)
   "dreyeck.dmx.association.described-by"
   :players
   (topic-association-players
    source "dmx.role.player1" target "dmx.role.player2")
   :value "described-by"))

(defun initialize-repaired-edge-reader-surface-fixture (db)
  (initialize-dmx-associative-mirror :db-path db :clear t)
  (dolist (topic-id
           '("asdf-3-3-session-action-model"
             "domkin-2017"
             "goldman-pipping-rideau-2017-asdf-3-3"
             "bounded-convergent-association-edge-reassignment"
             "bounded-convergent-association-edge-reassignment-fedwiki-page"))
    (record-dmx-topic-value db topic-id "dmx.test.topic" topic-id))
  (record-test-described-by-edge
   db
   "asdf-3-3-session-action-model"
   "goldman-pipping-rideau-2017-asdf-3-3"))

(defun build-referee-subgraph-view-present-p ()
  (multiple-value-bind (symbol status)
      (find-symbol "👀BUILD-REFEREE-SUBGRAPH" "DREYECK/CODEX")
    (and status (fboundp symbol))))

(defun domkin-2017-source-subgraph-view-present-p ()
  (multiple-value-bind (symbol status)
      (find-symbol "👀DOMKIN-2017-SOURCE-SUBGRAPH" "DREYECK/CODEX")
    (and status (fboundp symbol))))

(defun association-edge-reassignment-reader-surface-view-present-p ()
  (multiple-value-bind (symbol status)
      (find-symbol "👀ASSOCIATION-EDGE-REASSIGNMENT-READER-SURFACE"
                   "DREYECK/CODEX")
    (and status (fboundp symbol))))

(defun entry-present-p (entries id)
  (let ((entry
          (find id entries
                :key (lambda (item) (getf item :id))
                :test #'equal)))
    (and entry (getf entry :present-p))))

(defun run-dreyeck-codex-smoke-tests ()
  (let ((db (temporary-dreyeck-codex-dmx-db-path))
        (reader-db (temporary-dreyeck-codex-dmx-db-path)))
    (unwind-protect
         (progn
           (initialize-dmx-associative-mirror :db-path db :clear t)
           (materialize-durable-notes-into-production-db :db-path db)
           (initialize-repaired-edge-reader-surface-fixture reader-db)
           (let* ((inspection
                    (dmx-materialized-learning-topics :db-path db))
                  (surface
                    (make-test-codex-dmx-learning-topics inspection db))
                  (subgraph
                    (codex-dmx-build-referee-subgraph surface))
                  (domkin-surface
                    (codex-domkin-2017-source-topics :db-path db))
                  (domkin-subgraph
                    (codex-domkin-2017-source-subgraph domkin-surface))
                  (repaired-old-edge
                    '("asdf-3-3-session-action-model"
                      "described-by"
                      "domkin-2017"))
                  (repaired-new-edge
                    '("asdf-3-3-session-action-model"
                      "described-by"
                      "goldman-pipping-rideau-2017-asdf-3-3"))
                  (reader-surface
                    (codex-dmx-association-edge-reassignment-reader-surface
                     :db-path db))
                  (repaired-reader-surface
                    (codex-dmx-association-edge-reassignment-reader-surface
                     :db-path reader-db
                     :old-edge repaired-old-edge
                     :new-edge repaired-new-edge))
                  (repaired-primary-answer
                    (dreyeck/codex::codex-dmx-operation-reader-surface-primary-answer-of
                     repaired-reader-surface)))
             (assert-equal
              :build-referee-topics-in-production-dmx
              (getf subgraph :view)
              "Projection must identify the build/referee subgraph view")
             (assert-equal
              :passed
              (getf subgraph :status)
              "Build/referee subgraph projection must pass")
             (assert-equal
              8
              (length (getf subgraph :topics))
              "Build/referee subgraph must return exactly eight topics")
             (assert-equal
              8
              (getf subgraph :topic-count)
              "Build/referee subgraph must count eight present topics")
             (assert-equal
              8
              (length (getf subgraph :associations))
              "Build/referee subgraph must return exactly eight associations")
             (assert-equal
              8
              (getf subgraph :association-count)
              "Build/referee subgraph must count eight present associations")
             (assert-equal
              nil
              (getf subgraph :missing-topic-ids)
              "Build/referee subgraph must report no missing topics")
             (assert-equal
              nil
              (getf subgraph :missing-association-ids)
              "Build/referee subgraph must report no missing associations")
             (assert-true
              (build-referee-subgraph-view-present-p)
              "Explorer load must install the Build Referee Subgraph view")
             (assert-equal
              :passed
              (dreyeck/codex::codex-dmx-operation-reader-surface-status-of
               reader-surface)
              "Reader surface must validate its materialized topic cluster")
             (assert-equal
              :reassign-association-edge
              (getf
               (dreyeck/codex::codex-dmx-operation-reader-surface-primary-answer-of
                reader-surface)
               :operation)
              "Reader surface primary answer must name the operation")
             (assert-equal
              nil
              (getf
               (dreyeck/codex::codex-dmx-operation-reader-surface-secondary-evidence-of
                reader-surface)
               :raw-report)
              "Reader surface must not require a raw materializer dump")
             (assert-true
              (association-edge-reassignment-reader-surface-view-present-p)
              "Explorer load must install the association edge reader-surface view")
             (assert-equal
              nil
              (association-edge-present-p reader-db repaired-old-edge)
              "Regression fixture old edge must be absent")
             (assert-true
              (association-edge-present-p reader-db repaired-new-edge)
              "Regression fixture new edge must be present")
             (assert-true
              (dreyeck/codex::codex-dmx-operation-reader-surface-operation-topic-of
               repaired-reader-surface)
              "Regression fixture must expose the operation topic")
             (assert-true
              (dreyeck/codex::codex-dmx-operation-reader-surface-fedwiki-page-topic-of
               repaired-reader-surface)
              "Regression fixture must expose the FedWiki page topic")
             (assert-equal
              :passed
              (getf repaired-primary-answer :status)
              "Regression fixture primary answer must pass")
             (assert-equal
              nil
              (getf repaired-primary-answer :unexpected-graph-delta)
              "Regression fixture primary answer must report no unexpected delta")
             (assert-equal
              :passed
              (dreyeck/codex::codex-dmx-operation-reader-surface-status-of
               repaired-reader-surface)
              "Reader surface status must pass when old edge is absent and new edge is present")
             (assert-equal
              (getf repaired-primary-answer :status)
              (dreyeck/codex::codex-dmx-operation-reader-surface-status-of
               repaired-reader-surface)
              "Reader surface status must not fail while the primary answer passes")
             (assert-equal
              :domkin-2017-source-subgraph
              (getf domkin-subgraph :view)
              "Projection must identify the Domkin 2017 source subgraph")
             (assert-equal
              :passed
              (getf domkin-subgraph :status)
              "Domkin 2017 source subgraph projection must pass")
             (assert-equal
              nil
              (getf domkin-subgraph :missing-topic-ids)
              "Domkin 2017 source subgraph must report no missing topics")
             (assert-equal
              nil
              (getf domkin-subgraph :missing-association-ids)
              "Domkin 2017 source subgraph must report no missing associations")
             (dolist (topic-id '("domkin-2017-loading-multiple-asdf-versions"
                                 "common-lisp-dependency-hell"
                                 "package-name-conflict"
                                 "global-package-registry"
                                 "asdf-unversioned-system-registry"
                                 "package-renaming-conflict-resolution"
                                 "load-system-with-renamings"
                                 "asdf-public-api-gap"
                                 "asdf-plan-api-underdocumented"
                                 "implicit-transitive-dependency-limitation"
                                 "runtime-intern-eval-renaming-limitation"
                                 "hyperdoc-asdf-session-action-reading"))
               (assert-true
                (entry-present-p (getf domkin-subgraph :topics) topic-id)
                (format nil
                        "Domkin 2017 source subgraph must include topic ~A"
                        topic-id)))
             (dolist (association-id
                      '("assoc:domkin-2017-loading-multiple-asdf-versions:addresses:common-lisp-dependency-hell"
                        "assoc:common-lisp-dependency-hell:manifests-as:package-name-conflict"
                        "assoc:package-name-conflict:occurs-in:global-package-registry"
                        "assoc:load-system-with-renamings:implements:package-renaming-conflict-resolution"
                        "assoc:load-system-with-renamings:performs:dependency-tree-conflict-analysis"
                        "assoc:asdf-public-api-gap:limits:load-system-with-renamings"
                        "assoc:asdf-plan-api-underdocumented:limits:alternative-asdf-system-strategies"
                        "assoc:implicit-transitive-dependency-limitation:constrains:load-system-with-renamings"
                        "assoc:runtime-intern-eval-renaming-limitation:constrains:load-system-with-renamings"
                        "assoc:hyperdoc-asdf-session-action-reading:derived-from:domkin-2017-loading-multiple-asdf-versions"
                        "assoc:build-referee-decision-route:responds-to:asdf-plan-api-underdocumented"
                        "assoc:lisp-referee-form:responds-to:asdf-monolithic-loading-strategy"))
               (assert-true
                (entry-present-p (getf domkin-subgraph :associations)
                                 association-id)
                (format nil
                        "Domkin 2017 source subgraph must include association ~A"
                        association-id)))
             (assert-true
              (domkin-2017-source-subgraph-view-present-p)
              "Explorer load must install the Domkin 2017 Source Subgraph view"))
           (format t "~&Dreyeck Codex smoke tests passed.~%")
           t)
      (when (probe-file db)
        (delete-file db))
      (when (probe-file reader-db)
        (delete-file reader-db)))))
