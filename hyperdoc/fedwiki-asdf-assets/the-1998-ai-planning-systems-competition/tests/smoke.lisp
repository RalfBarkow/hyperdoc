;;;; Smoke tests for the McDermott 2000 FedWiki ASDF reading artifact.

(in-package #:the-1998-ai-planning-systems-competition/tests)

(defun assert-true (value message)
  (unless value
    (error "Smoke test failed: ~A" message))
  value)

(defun assert-contains (needle haystack message)
  (assert-true (and haystack (search needle haystack :test #'char=))
               (format nil "~A -- missing ~S" message needle)))

(defun temp-artifact-pathname (name)
  (merge-pathnames name (uiop:temporary-directory)))

(defun run-smoke-tests ()
  (assert-true
   (asdf:find-system "the-1998-ai-planning-systems-competition" nil)
   "ASDF load makes the reading system findable")
  (assert-true (probe-file (asset-db-pathname))
               "asset SQLite database exists")
  (let ((status (schema-status)))
    (assert-true (getf status :exists-p)
                 "schema status reports an existing DB")
    (assert-true (>= (length (getf status :tables)) 7)
                 "schema status is inspectable"))
  (dolist (topic-id (required-topic-ids))
    (assert-true (topic-exists-p topic-id)
                 (format nil "required topic exists: ~A" topic-id)))
  (dolist (association-id (required-association-ids))
    (assert-true (association-exists-p association-id)
                 (format nil "required association exists: ~A" association-id)))
  (let ((json (reconstruct-fedwiki-page-json-string)))
    (assert-contains "physics, not advice" json
                     "page reconstruction includes physics/not-advice text")
    (assert-contains "Planung als Reduktion" json
                     "page reconstruction includes Zettel 6537 bridge"))
  (let ((db-path
          (temp-artifact-pathname
           "the-1998-ai-planning-systems-competition-smoke.dmx.sqlite"))
        (page-path
          (temp-artifact-pathname
           "the-1998-ai-planning-systems-competition-smoke.json")))
    (when (probe-file db-path)
      (delete-file db-path))
    (when (probe-file page-path)
      (delete-file page-path))
    (let ((report
            (validate-reconstruction-idempotence
             :db-path db-path
             :page-path page-path
             :clear-db t)))
      (assert-true (getf report :idempotent-p)
                   "materialization is idempotent")
      (assert-true (not (getf report :network-required-p))
                   "no live network is required")))
  (list :ok t
        :db-path (asset-db-pathname)
        :page-json-path (page-json-pathname)
        :network-required-p nil))
