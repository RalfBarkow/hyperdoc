;;;; Artifact materialization and reconstruction checks.

(in-package #:the-1998-ai-planning-systems-competition)

(defun materialize-reading-artifact
    (&key (db-path (asset-db-pathname))
       (page-path (page-json-pathname))
       clear-db)
  "Materialize the SQLite topic basis and FedWiki page projection."
  (initialize-dmx-sqlite-asset :db-path db-path :clear clear-db)
  (seed-reading-topics :db-path db-path)
  (let ((page-report
          (materialize-fedwiki-page-from-dmx
           :db-path db-path
           :page-path page-path)))
    (list :db-path db-path
          :relative-db-path (relative-artifact-path db-path)
          :page page-report
          :schema (schema-status :db-path db-path)
          :topics-present-p
          (required-topics-present-p :db-path db-path)
          :associations-present-p
          (required-associations-present-p :db-path db-path)
          :network-required-p *network-required-p*)))

(defun validate-reconstruction-idempotence
    (&key (db-path (asset-db-pathname))
       (page-path (page-json-pathname))
       clear-db)
  "Materialize twice and compare the reconstructed page projection."
  (materialize-reading-artifact
   :db-path db-path
   :page-path page-path
   :clear-db clear-db)
  (let ((first (file-string page-path)))
    (materialize-reading-artifact
     :db-path db-path
     :page-path page-path
     :clear-db nil)
    (let ((second (file-string page-path)))
      (list :idempotent-p (and first second (string= first second))
            :page-path page-path
            :bytes (and second (length second))
            :network-required-p *network-required-p*))))
