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

(defun build-referee-subgraph-view-present-p ()
  (multiple-value-bind (symbol status)
      (find-symbol "👀BUILD-REFEREE-SUBGRAPH" "DREYECK/CODEX")
    (and status (fboundp symbol))))

(defun run-dreyeck-codex-smoke-tests ()
  (let ((db (temporary-dreyeck-codex-dmx-db-path)))
    (unwind-protect
         (progn
           (initialize-dmx-associative-mirror :db-path db :clear t)
           (materialize-durable-notes-into-production-db :db-path db)
           (let* ((inspection
                    (dmx-materialized-learning-topics :db-path db))
                  (surface
                    (make-test-codex-dmx-learning-topics inspection db))
                  (subgraph
                    (codex-dmx-build-referee-subgraph surface)))
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
              "Explorer load must install the Build Referee Subgraph view"))
           (format t "~&Dreyeck Codex smoke tests passed.~%")
           t)
      (when (probe-file db)
        (delete-file db)))))
