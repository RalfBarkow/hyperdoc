;;;; Durable Markdown-note to DMX topic materialization.
;;;;
;;;; Markdown remains a human-readable seed/projection.  The production
;;;; topic memory for this slice is the Dreyeck-owned DMX-shaped SQLite store.

(in-package #:dreyeck.dmx.sqlite)

(defun dreyeck-dmx-sqlite-repo-root ()
  (or (ignore-errors
        (uiop:pathname-directory-pathname
         (asdf:system-source-file :dreyeck/dmx/sqlite)))
      (uiop:getcwd)))

(defparameter *dreyeck-dmx-production-db-path*
  (merge-pathnames #p"var/dmx-associative-mirror.sqlite"
                   (dreyeck-dmx-sqlite-repo-root))
  "Production-path configuration for durable local DMX topic materialization.")

(defparameter *durable-note-materialization-plan-source*
  "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp")

(defparameter *durable-note-materialization-seed-notes*
  '(("hyperdoc/HyperDoc Core.md" "hyperdoc-core")
    ("hyperdoc/Codex Belongs to Dreyeck.md" "codex-belongs-to-dreyeck")
    ("hyperdoc/Ownership Extraction with Compatibility Shell.md"
     "ownership-extraction-with-compatibility-shell")))

(defparameter *durable-note-materialization-topic-definitions*
  '((:id "hyperdoc-core"
     :type :project-concept
     :title "HyperDoc Core"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :seeded-from-markdown
     :summary "HyperDoc core is the upstream-generic substrate boundary, not the local hyperdoc/ path.")
    (:id "ownership-extraction-with-compatibility-shell"
     :type :learned-refactor-pattern
     :title "Ownership Extraction with Compatibility Shell"
     :source "hyperdoc/Ownership Extraction with Compatibility Shell.md"
     :commit-anchor "afa829b9"
     :also-known-as "Substrate / Situated-Surface Split"
     :canonical-example "afa829b9 refactor(codex): move collaboration surface into dreyeck"
     :projection-status :seeded-from-markdown
     :summary "Extract situated project state from a reusable substrate and leave temporary compatibility wrappers.")
    (:id "substrate-situated-surface-split"
     :type :learned-refactor-pattern
     :title "Substrate / Situated-Surface Split"
     :source "hyperdoc/Ownership Extraction with Compatibility Shell.md"
     :commit-anchor "afa829b9"
     :also-known-as "Ownership Extraction with Compatibility Shell"
     :canonical-example "afa829b9 refactor(codex): move collaboration surface into dreyeck"
     :projection-status :derived-from-seed-note
     :summary "A local name for separating upstream-generic substrate from situated collaboration surfaces.")
    (:id "codex-belongs-to-dreyeck"
     :type :architecture-decision
     :title "Codex Belongs to Dreyeck"
     :source "hyperdoc/Codex Belongs to Dreyeck.md"
     :commit-anchor "afa829b9"
     :canonical-example "afa829b9 refactor(codex): move collaboration surface into dreyeck"
     :projection-status :seeded-from-markdown
     :summary "Codex collaboration state belongs to Dreyeck, while HyperDoc supplies reusable substrate.")
    (:id "materialize-durable-notes-into-dreyeck-dmx-sqlite"
     :type :shop3-plan
     :title "Materialize Durable Notes into Dreyeck DMX SQLite"
     :source "hyperdoc/materialize-durable-notes-into-dreyeck-dmx-sqlite-plan.sexp"
     :projection-status :seeded-from-shop3-plan
     :summary "SHOP3-shaped plan for materializing durable Markdown-note seeds into the Dreyeck DMX SQLite store.")
    (:id "markdown-note-as-seed-or-projection"
     :type :project-concept
     :title "Markdown Note as Seed or Projection"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "Markdown notes are reviewable seeds, exports, or handover projections, not the final topic store.")
    (:id "hyperdoc-core-vs-local-hyperdoc-path"
     :type :boundary-distinction
     :title "HyperDoc Core vs Local hyperdoc/ Path"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "A file living under hyperdoc/ is not automatically HyperDoc core.")
    (:id "optional-provider-becomes-inspectable-data"
     :type :learned-problem-solution
     :title "Optional Provider Becomes Inspectable Data"
     :source "hyperdoc/Ownership Extraction with Compatibility Shell.md"
     :commit-anchor "afa829b9"
     :canonical-example "Missing Kioskbeerli providers return structured Codex provider results."
     :projection-status :derived-from-seed-note
     :summary "Missing situated providers should be represented as inspectable data instead of debugger conditions.")
    (:id "dreyeck-dmx-sqlite-production-db"
     :type :production-store
     :title "Dreyeck DMX SQLite Production DB"
     :projection-status :configured-production-store
     :summary "The local DMX-shaped SQLite store for durable Dreyeck project topics.")
    (:id "dmx-topic"
     :type :dmx-object-type
     :title "DMX Topic"
     :projection-status :support-topic
     :summary "The first-class topic object represented in the DMX-shaped SQLite store.")
    (:id "durable-project-topics"
     :type :project-concept
     :title "Durable Project Topics"
     :projection-status :support-topic
     :summary "Project topics that should be persisted in the Dreyeck DMX SQLite production store.")
    (:id "hyperdoc-core-patch"
     :type :classification
     :title "HyperDoc Core Patch"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "A local generic HyperDoc change that could plausibly remain upstream-generic.")
    (:id "hyperdoc-compatibility-shell"
     :type :classification
     :title "HyperDoc Compatibility Shell"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "A temporary wrapper preserving old HyperDoc coordinates after ownership moves elsewhere.")
    (:id "project-owned-extension"
     :type :classification
     :title "Project-Owned Extension"
     :source "hyperdoc/HyperDoc Core.md"
     :commit-anchor "1f4e6298"
     :projection-status :derived-from-seed-note
     :summary "Situated code owned by Dreyeck, Kioskbeerli, Hauptsache, DMX integration, Codex, or another project layer.")))

(defparameter *durable-note-materialization-association-definitions*
  '((:source "hyperdoc-core"
     :predicate "supplies-boundary-for"
     :target "ownership-extraction-with-compatibility-shell")
    (:source "ownership-extraction-with-compatibility-shell"
     :predicate "applied-in"
     :target "codex-belongs-to-dreyeck")
    (:source "hyperdoc-core"
     :predicate "distinguishes"
     :target "hyperdoc-core-patch")
    (:source "hyperdoc-core"
     :predicate "distinguishes"
     :target "hyperdoc-compatibility-shell")
    (:source "hyperdoc-core"
     :predicate "excludes"
     :target "project-owned-extension")
    (:source "markdown-note-as-seed-or-projection"
     :predicate "materializes-to"
     :target "dmx-topic")
    (:source "dreyeck-dmx-sqlite-production-db"
     :predicate "stores"
     :target "durable-project-topics")))

(defparameter *durable-note-materialization-required-topic-ids*
  '("hyperdoc-core"
    "ownership-extraction-with-compatibility-shell"
    "substrate-situated-surface-split"
    "codex-belongs-to-dreyeck"
    "materialize-durable-notes-into-dreyeck-dmx-sqlite"
    "markdown-note-as-seed-or-projection"
    "hyperdoc-core-vs-local-hyperdoc-path"
    "optional-provider-becomes-inspectable-data"))

(defun durable-note-source-pathname (source)
  (when source
    (merge-pathnames source (dreyeck-dmx-sqlite-repo-root))))

(defun durable-note-title-from-markdown (content)
  (loop for line in (uiop:split-string content :separator '(#\Newline))
        thereis
        (when (and (> (length line) 2)
                   (string= "# " line :end2 2))
          (string-trim '(#\Space #\Tab) (subseq line 2)))))

(defun durable-note-source-info (source)
  (let ((pathname (durable-note-source-pathname source)))
    (cond
      ((null source)
       (list :source nil :exists-p nil))
      ((probe-file pathname)
       (let ((content (uiop:read-file-string pathname)))
         (list :source source
               :pathname (namestring pathname)
               :exists-p t
               :source-title (durable-note-title-from-markdown content)
               :source-bytes (length content))))
      (t
       (list :source source
             :pathname (namestring pathname)
             :exists-p nil)))))

(defun dmx-token-string (value)
  (cond
    ((null value)
     "")
    ((keywordp value)
     (string-downcase (symbol-name value)))
    ((symbolp value)
     (string-downcase (symbol-name value)))
    (t
     (format nil "~A" value))))

(defun durable-note-topic-type-uri (type)
  (format nil "dreyeck.dmx.topic.~A" (dmx-token-string type)))

(defun durable-note-association-type-uri (predicate)
  (format nil "dreyeck.dmx.association.~A" (dmx-token-string predicate)))

(defun durable-note-topic-uri (topic-id)
  (format nil "dmx://dreyeck/local-topic/~A" topic-id))

(defun durable-note-association-id (definition)
  (format nil "assoc:~A:~A:~A"
          (getf definition :source)
          (getf definition :predicate)
          (getf definition :target)))

(defun durable-note-topic-payload-json (definition source-info)
  (let ((title (or (getf definition :title)
                   (getf source-info :source-title)
                   (getf definition :id))))
    (json-object
     :id (getf definition :id)
     :type (dmx-token-string (getf definition :type))
     :title title
     :source (getf definition :source)
     :source-title (getf source-info :source-title)
     :source-bytes (getf source-info :source-bytes)
     :commit-anchor (getf definition :commit-anchor)
     :projection-status (dmx-token-string (getf definition :projection-status))
     :also-known-as (getf definition :also-known-as)
     :canonical-example (getf definition :canonical-example)
     :summary (getf definition :summary))))

(defun durable-note-association-payload-json (definition)
  (json-object
   :source (getf definition :source)
   :predicate (getf definition :predicate)
   :target (getf definition :target)
   :projection-status "seeded-from-shop3-plan"))

(defun materialize-durable-note-topic
    (db-path definition &key (replace-existing? t))
  (let* ((source-info (durable-note-source-info (getf definition :source)))
         (missing-source? (and (getf definition :source)
                               (not (getf source-info :exists-p))))
         (topic-id (getf definition :id))
         (title (or (getf definition :title)
                    (getf source-info :source-title)
                    topic-id)))
    (if missing-source?
        (list :id topic-id
              :state :missing-source
              :source (getf definition :source))
        (let* ((state
                 (record-dmx-topic-value
                  db-path
                  topic-id
                  (durable-note-topic-type-uri (getf definition :type))
                  title
                  :uri (durable-note-topic-uri topic-id)
                  :payload-json
                  (durable-note-topic-payload-json definition source-info)
                  :sync-state "local"
                  :replace-existing? replace-existing?)))
          (list :id topic-id
                :state state
                :source (getf definition :source))))))

(defun durable-note-association-players-present-p (db-path definition)
  (and (dmx-sql-object-exists-p db-path (getf definition :source))
       (dmx-sql-object-exists-p db-path (getf definition :target))))

(defun materialize-durable-note-association
    (db-path definition &key (replace-existing? t))
  (let ((assoc-id (durable-note-association-id definition)))
    (if (not (durable-note-association-players-present-p db-path definition))
        (list :id assoc-id
              :state :missing-player
              :source (getf definition :source)
              :target (getf definition :target))
        (list :id assoc-id
              :state
              (record-dmx-association-value
               db-path
               assoc-id
               (durable-note-association-type-uri
                (getf definition :predicate))
               :players
               (topic-association-players
                (getf definition :source)
                "dmx.role.player1"
                (getf definition :target)
                "dmx.role.player2")
               :value (getf definition :predicate)
               :payload-json (durable-note-association-payload-json definition)
               :replace-existing? replace-existing?)
              :source (getf definition :source)
              :predicate (getf definition :predicate)
              :target (getf definition :target)))))

(defun durable-note-known-seed-notes ()
  (loop for (source topic-id) in *durable-note-materialization-seed-notes*
        for info = (durable-note-source-info source)
        collect (list :source source
                      :topic-id topic-id
                      :exists-p (getf info :exists-p)
                      :source-title (getf info :source-title)
                      :pathname (getf info :pathname))))

(defun durable-note-missing-seed-notes ()
  (remove-if (lambda (note) (getf note :exists-p))
             (durable-note-known-seed-notes)))

(defun durable-note-materialized-topic-count (db-path)
  (count-if (lambda (definition)
              (dmx-sqlite-topic db-path (getf definition :id)))
            *durable-note-materialization-topic-definitions*))

(defun durable-note-materialized-association-count (db-path)
  (count-if (lambda (definition)
              (dmx-sqlite-association
               db-path
               (durable-note-association-id definition)))
            *durable-note-materialization-association-definitions*))

(defun durable-note-missing-topic-ids (db-path topic-ids)
  (remove-if (lambda (topic-id) (dmx-sqlite-topic db-path topic-id))
             topic-ids))

(defun durable-note-missing-association-ids (db-path definitions)
  (loop for definition in definitions
        for assoc-id = (durable-note-association-id definition)
        unless (dmx-sqlite-association db-path assoc-id)
          collect assoc-id))

(defun durable-note-materialization-validation (db-path)
  (let* ((db-exists? (probe-file db-path))
         (missing-notes (durable-note-missing-seed-notes))
         (missing-topics
           (if db-exists?
               (durable-note-missing-topic-ids
                db-path
                *durable-note-materialization-required-topic-ids*)
               *durable-note-materialization-required-topic-ids*))
         (missing-associations
           (if db-exists?
               (durable-note-missing-association-ids
                db-path
                *durable-note-materialization-association-definitions*)
               (mapcar #'durable-note-association-id
                       *durable-note-materialization-association-definitions*)))
         (passed? (and db-exists?
                       (null missing-notes)
                       (null missing-topics)
                       (null missing-associations))))
    (list :status (if passed? :passed :failed)
          :db-exists-p (and db-exists? t)
          :missing-notes missing-notes
          :missing-required-topics missing-topics
          :missing-required-associations missing-associations)))

(defun durable-note-materialization-status
    (&key (db-path *dreyeck-dmx-production-db-path*))
  "Return a structured, inspectable status object for this materialization."
  (let* ((db-exists? (probe-file db-path))
         (validation (durable-note-materialization-validation db-path)))
    (list :kind :durable-note-materialization-status
          :production-db-path (namestring db-path)
          :production-db-exists-p (and db-exists? t)
          :known-seed-notes (durable-note-known-seed-notes)
          :materialized-topic-count
          (if db-exists?
              (durable-note-materialized-topic-count db-path)
              0)
          :materialized-association-count
          (if db-exists?
              (durable-note-materialized-association-count db-path)
              0)
          :missing-notes (getf validation :missing-notes)
          :last-validation-status (getf validation :status)
          :validation validation)))

(defun materialize-durable-notes-into-production-db
    (&key (db-path *dreyeck-dmx-production-db-path*) (replace-existing? t))
  "Materialize the canonical durable Markdown-note seed set into the DMX store.

The operation is idempotent: replaying it returns :UNCHANGED for topic and
association rows whose content already matches the seed definitions."
  (initialize-dmx-associative-mirror :db-path db-path)
  (let ((topic-results
          (loop for definition in *durable-note-materialization-topic-definitions*
                collect
                (materialize-durable-note-topic
                 db-path definition
                 :replace-existing? replace-existing?)))
        (association-results
          (loop for definition in *durable-note-materialization-association-definitions*
                collect
                (materialize-durable-note-association
                 db-path definition
                 :replace-existing? replace-existing?))))
    (list :kind :durable-note-materialization
          :production-db-path (namestring db-path)
          :topic-results topic-results
          :association-results association-results
          :status (durable-note-materialization-status :db-path db-path))))
