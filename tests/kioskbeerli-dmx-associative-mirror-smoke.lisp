(in-package :hyperdoc/tests)

(defparameter +shop3-coverage-assertion+
  "its SHOP3 checklist projection covers all 16 local tasks")

(defparameter +shop3-coverage-topic-uris+
  '("hyperdoc:kioskbeerli/sops-nix-secrets/assertion/shop3-checklist-covers-16-local-tasks"
    "hyperdoc:kioskbeerli/sops-nix-secrets/local-task-graph"
    "hyperdoc:kioskbeerli/sops-nix-secrets/plan"
    "hyperdoc:kioskbeerli/sops-nix-secrets/shop3-checklist-projection"))

(defun dmx-mirror-assert-true (condition message)
  (unless condition
    (error "Assertion failed: ~A" message)))

(defun dmx-mirror-assert-false (condition message)
  (when condition
    (error "Assertion failed: ~A" message)))

(defun dmx-mirror-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "Assertion failed: ~A~%Expected: ~S~%Actual: ~S"
           message expected actual)))

(defun temporary-dmx-mirror-db-path (name)
  (merge-pathnames
   (format nil "~A-~D-~D.sqlite"
           name
           (get-universal-time)
           (get-internal-real-time))
   (uiop:temporary-directory)))

(defun test-sql-literal (value)
  (if value
      (format nil "'~A'"
              (with-output-to-string (stream)
                (loop for ch across (format nil "~A" value)
                      do (case ch
                           (#\' (write-string "''" stream))
                           (otherwise (write-char ch stream))))))
      "NULL"))

(defun test-sql-scalar (db-path sql)
  (multiple-value-bind (stdout stderr exit-code)
      (kioskbeerli.dmx-associative-mirror:sqlite-run db-path sql)
    (unless (zerop exit-code)
      (error "SQLite test query failed:~%~A~%~A" stdout stderr))
    (string-trim '(#\Space #\Tab #\Newline #\Return) stdout)))

(defun test-sql-values (db-path sql)
  (remove "" (uiop:split-string (test-sql-scalar db-path sql)
                                :separator '(#\Newline))
          :test #'string=))

(defun sql-topic-property (db-path topic-uri property-uri)
  (test-sql-scalar
   db-path
   (format nil
           "select p.value
              from dmx_sql_property p
              join dmx_sql_object o on o.local_id = p.object_id
             where o.uri = ~A
               and p.property_uri = ~A;"
           (test-sql-literal topic-uri)
           (test-sql-literal property-uri))))

(defun sorted-strings (strings)
  (sort (copy-list strings) #'string<))

(defun run-basic-dmx-associative-mirror-smoke-test ()
  (let ((db-path (temporary-dmx-mirror-db-path "dmx-associative-mirror-smoke")))
    (kioskbeerli.dmx-associative-mirror:run-dmx-associative-mirror-smoke
     :db-path db-path)
    (dmx-mirror-assert-true (probe-file db-path)
                 "basic mirror smoke should create a temporary SQLite database")
    t))

(defun persist-shop3-coverage-assertion-for-test (db-path &key replace-existing?)
  (kioskbeerli.dmx-associative-mirror:persist-shop3-checklist-coverage-assertion-as-dmx-sql-topics
   +shop3-coverage-assertion+
   :db-path db-path
   :subject-uri "hyperdoc:kioskbeerli/sops-nix-secrets/plan"
   :subject-label "Kioskbeerli sops-nix secrets plan"
   :plan-system ":kioskbeerli/sops-nix-secrets"
   :checklist-count 16
   :task-count 16
   :evidence "SLY verification: type=SOPS-NIX-SECRETS-PLAN shop3=T mode=:PLAN-ONLY steps=16 tasks=16"
   :source "hyperdoc smoke test"
   :replace-existing? replace-existing?))

(defun run-shop3-coverage-assertion-persistence-smoke-test ()
  (let* ((db-path (temporary-dmx-mirror-db-path "shop3-coverage-assertion"))
         (report (persist-shop3-coverage-assertion-for-test
                  db-path
                  :replace-existing? t)))
    (dmx-mirror-assert-true (getf report :ok)
                 "coverage assertion persistence should return :OK")
    (dmx-mirror-assert-equal :local-sql-mirror-only
                  (getf report :boundary)
                  "coverage assertion persistence must stay local SQL only")
    (dmx-mirror-assert-true (probe-file db-path)
                 "coverage assertion persistence should create a SQLite database")
    (dmx-mirror-assert-equal
     (sorted-strings +shop3-coverage-topic-uris+)
     (test-sql-values db-path
                      "select uri from dmx_sql_object where object_kind = 'topic' order by uri;")
     "exact expected topic URIs should be present")
    (dmx-mirror-assert-equal
     "16"
     (sql-topic-property
      db-path
      "hyperdoc:kioskbeerli/sops-nix-secrets/shop3-checklist-projection"
      "hyperdoc.property.checklist-count")
     "projection checklist count should be persisted")
    (dmx-mirror-assert-equal
     "16"
     (sql-topic-property
      db-path
      "hyperdoc:kioskbeerli/sops-nix-secrets/local-task-graph"
      "hyperdoc.property.task-count")
     "local task graph count should be persisted")
    (dmx-mirror-assert-equal
     "1"
     (test-sql-scalar
      db-path
      "select count(*) from dmx_sql_object where object_kind = 'assoc' and type_uri = 'hyperdoc.relation.covers';")
     "covers association should exist")
    (dmx-mirror-assert-equal
     "0"
     (test-sql-scalar db-path "select count(*) from dmx_sql_sync_journal;")
     "local assertion persistence must not record live sync/write actions")
    (dmx-mirror-assert-equal
     "0"
     (test-sql-scalar
      db-path
      "select count(*) from dmx_sql_sync_identity where host <> 'hyperdoc-local-sql-mirror';")
     "sync identities must remain local mirror provenance records")
    (let ((object-count (test-sql-scalar db-path
                                         "select count(*) from dmx_sql_object;"))
          (property-count (test-sql-scalar db-path
                                           "select count(*) from dmx_sql_property;")))
      (persist-shop3-coverage-assertion-for-test db-path :replace-existing? nil)
      (dmx-mirror-assert-equal object-count
                    (test-sql-scalar db-path
                                     "select count(*) from dmx_sql_object;")
                    "idempotent replay without replacement must not duplicate objects")
      (dmx-mirror-assert-equal property-count
                    (test-sql-scalar db-path
                                     "select count(*) from dmx_sql_property;")
                    "idempotent replay without replacement must not duplicate properties")
      (persist-shop3-coverage-assertion-for-test db-path :replace-existing? t)
      (dmx-mirror-assert-equal object-count
                    (test-sql-scalar db-path
                                     "select count(*) from dmx_sql_object;")
                    "idempotent replacement must not duplicate objects"))
    (let* ((projection
             (kioskbeerli.dmx-sql-topicmap:make-dmx-sql-topicmap-projection
              :db-path db-path
              :title "Kioskbeerli persisted DMX SQL topicmap"))
           (payload
             (kioskbeerli.dmx-sql-topicmap:projection-topicmap-payload
              projection)))
      (dmx-mirror-assert-true
       (find "hyperdoc:kioskbeerli/sops-nix-secrets/assertion/shop3-checklist-covers-16-local-tasks"
             (getf payload :nodes)
             :key (lambda (node) (getf node :uri))
             :test #'string=)
       "topicmap projection should read the assertion topic")
      (dmx-mirror-assert-true
       (find "hyperdoc.relation.covers"
             (getf payload :edges)
             :key (lambda (edge) (getf edge :type-uri))
             :test #'string=)
       "topicmap projection should read the covers edge")))
  t)

(defun run-shop3-coverage-assertion-parse-failure-smoke-test ()
  (let ((db-path (temporary-dmx-mirror-db-path "shop3-coverage-parse-failure")))
    (kioskbeerli.dmx-associative-mirror:initialize-dmx-associative-mirror
     :db-path db-path
     :clear t)
    (dmx-mirror-assert-equal
     "0"
     (test-sql-scalar db-path "select count(*) from dmx_sql_object;")
     "fresh mirror should start without objects")
    (handler-case
        (progn
          (kioskbeerli.dmx-associative-mirror:persist-shop3-checklist-coverage-assertion-as-dmx-sql-topics
           "unrelated assertion text"
           :db-path db-path)
          (error "Expected parse failure did not occur."))
      (error ()
        t))
    (dmx-mirror-assert-equal
     "0"
     (test-sql-scalar db-path "select count(*) from dmx_sql_object;")
     "failed parsing must not persist partial topics"))
  t)

(defun run-kioskbeerli-dmx-associative-mirror-smoke-tests ()
  (run-basic-dmx-associative-mirror-smoke-test)
  (run-shop3-coverage-assertion-persistence-smoke-test)
  (run-shop3-coverage-assertion-parse-failure-smoke-test)
  (format t "~&Kioskbeerli DMX associative mirror smoke tests passed.~%")
  t)
