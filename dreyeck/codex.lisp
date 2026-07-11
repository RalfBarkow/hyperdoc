;;;; Codex collaboration home topic

(in-package :dreyeck/codex)

(defun codex--context-provider-candidates (provider-symbol)
  (let ((provider-name (symbol-name provider-symbol)))
    (remove-duplicates
     (append
      (list provider-symbol)
      (loop for package-name in '("KIOSKBEERLI"
                                  "DREYECK/KIOSKBEERLI"
                                  "HYPERDOC")
            for package = (find-package package-name)
            for candidate = (and package
                                 (find-symbol provider-name package))
            when candidate
              collect candidate))
     :test #'eq)))

(defun codex--resolve-context-provider (provider-symbol)
  (find-if #'fboundp
           (codex--context-provider-candidates provider-symbol)))

(defun codex-context-provider-result (provider-symbol)
  "Call an optional CODEX-CONTEXT-WINDOW provider without letting a missing or failing provider abort CODEX.

The context window is a continuation surface. Optional project dashboards
such as KIOSKBEERLI-DASHBOARD must degrade to inspectable data, not to
an UNDEFINED-FUNCTION condition. PROVIDER-SYMBOL may be a Dreyeck-owned
symbol; the dispatcher resolves loaded downstream provider packages by
symbol name without depending on them."
  (let ((resolved-provider (codex--resolve-context-provider provider-symbol)))
    (cond
      (resolved-provider
       (handler-case
           (funcall resolved-provider)
         (error (condition)
           (list
            :provider provider-symbol
            :resolved-provider resolved-provider
            :status :provider-error
            :condition condition
            :repair-hint "Inspect the provider condition; CODEX-CONTEXT-WINDOW stayed alive."))))
      (t
       (list
        :provider provider-symbol
        :candidate-providers (codex--context-provider-candidates
                              provider-symbol)
        :status :missing-optional-provider
        :repair-hint "Load or file out this optional dashboard provider; CODEX-CONTEXT-WINDOW intentionally continues.")))))



(defclass codex-home ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (current-slice :accessor codex-home-current-slice-of
                  :initarg :current-slice)
   (context-window :accessor codex-home-context-window-of
                   :initarg :context-window)
   (recent-changes :accessor codex-home-recent-changes-of
                   :initarg :recent-changes)
   (next :accessor codex-home-next-of
         :initarg :next)
   (primary-review-object :accessor codex-home-primary-review-object-of
                          :initarg :primary-review-object)
   (related-objects :accessor codex-home-related-objects-of
                    :initarg :related-objects)
   (relevant-pages :accessor codex-home-relevant-pages-of
                   :initarg :relevant-pages)
   (validation-commands :accessor codex-home-validation-commands-of
                        :initarg :validation-commands)
   (commit-boundary :accessor codex-home-commit-boundary-of
                    :initarg :commit-boundary
                    :initform nil)))

(defmethod print-object ((object codex-home) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-context-window ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source :accessor codex-context-window-source-of
           :initarg :source)
   (captured-at :accessor codex-context-window-captured-at-of
                :initarg :captured-at)
   (summary :accessor summary-of :initarg :summary)
   (entries :accessor codex-context-window-entries-of
            :initarg :entries)
   (open-questions :accessor codex-context-window-open-questions-of
                   :initarg :open-questions)
   (proposed-actions :accessor codex-context-window-proposed-actions-of
                     :initarg :proposed-actions)
   (related-objects :accessor codex-context-window-related-objects-of
                    :initarg :related-objects)
   (validation-commands :accessor codex-context-window-validation-commands-of
                        :initarg :validation-commands)
   (provenance :accessor codex-context-window-provenance-of
               :initarg :provenance)
   (previous-context-window
    :accessor codex-context-window-previous-context-window-of
    :initarg :previous-context-window
    :initform nil)
   (nested-context-windows
    :accessor codex-context-window-nested-context-windows-of
    :initarg :nested-context-windows
    :initform nil)
   (depth :accessor codex-context-window-depth-of
          :initarg :depth
          :initform 0)
   (max-depth :accessor codex-context-window-max-depth-of
              :initarg :max-depth
              :initform 0)
   (raw-text :accessor codex-context-window-raw-text-of
             :initarg :raw-text
             :initform nil)))

(defmethod print-object ((object codex-context-window) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-context-entry ()
  ((role :accessor codex-context-entry-role-of
         :initarg :role)
   (title :accessor title-of :initarg :title)
   (timestamp :accessor codex-context-entry-timestamp-of
              :initarg :timestamp)
   (text :accessor codex-context-entry-text-of
         :initarg :text)
   (references :accessor codex-context-entry-references-of
               :initarg :references)
   (derived-objects :accessor codex-context-entry-derived-objects-of
                    :initarg :derived-objects)))

(defmethod print-object ((object codex-context-entry) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-context-window-structural-proof ()
  ((title :accessor title-of :initarg :title)
   (context-window
    :accessor codex-context-window-structural-proof-context-window-of
    :initarg :context-window
    :initform nil)
   (graph :accessor codex-context-window-structural-proof-graph-of
          :initarg :graph)
   (expression
    :accessor codex-context-window-structural-proof-expression-of
    :initarg :expression)
   (result :accessor codex-context-window-structural-proof-result-of
           :initarg :result)
   (violations
    :accessor codex-context-window-structural-proof-violations-of
    :initarg :violations)
   (interpretation
    :accessor codex-context-window-structural-proof-interpretation-of
    :initarg :interpretation)))

(defmethod print-object ((object codex-context-window-structural-proof)
                         stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-recent-changes ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source :accessor codex-recent-changes-source-of
           :initarg :source)
   (captured-at :accessor codex-recent-changes-captured-at-of
                :initarg :captured-at)
   (scope :accessor codex-recent-changes-scope-of
          :initarg :scope)
   (summary :accessor summary-of :initarg :summary)
   (entries :accessor codex-recent-changes-entries-of
            :initarg :entries)
   (neighborhood :accessor codex-recent-changes-neighborhood-of
                 :initarg :neighborhood)
   (provenance :accessor codex-recent-changes-provenance-of
               :initarg :provenance)
   (limit :accessor codex-recent-changes-limit-of
          :initarg :limit)))

(defmethod print-object ((object codex-recent-changes) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-recent-change ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (kind :accessor codex-recent-change-kind-of
         :initarg :kind)
   (changed-at :accessor codex-recent-change-changed-at-of
               :initarg :changed-at)
   (actor :accessor codex-recent-change-actor-of
          :initarg :actor)
   (summary :accessor summary-of :initarg :summary)
   (source-object :accessor codex-recent-change-source-object-of
                  :initarg :source-object
                  :initform nil)
   (target-object :accessor codex-recent-change-target-object-of
                  :initarg :target-object
                  :initform nil)
   (affected-files :accessor codex-recent-change-affected-files-of
                   :initarg :affected-files
                   :initform nil)
   (affected-pages :accessor codex-recent-change-affected-pages-of
                   :initarg :affected-pages
                   :initform nil)
   (evidence :accessor codex-recent-change-evidence-of
             :initarg :evidence
             :initform nil)
   (route-hints :accessor codex-recent-change-route-hints-of
                :initarg :route-hints
                :initform nil)))

(defmethod print-object ((object codex-recent-change) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-next ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source :accessor codex-next-source-of
           :initarg :source)
   (changes :accessor codex-next-changes-of
            :initarg :changes)
   (routes :accessor codex-next-routes-of
           :initarg :routes)
   (summary :accessor summary-of :initarg :summary)
   (generated-at :accessor codex-next-generated-at-of
                 :initarg :generated-at)
   (provenance :accessor codex-next-provenance-of
               :initarg :provenance)))

(defmethod print-object ((object codex-next) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-next-route ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (source-topic :accessor codex-next-route-source-topic-of
                 :initarg :source-topic)
   (target-topic :accessor codex-next-route-target-topic-of
                 :initarg :target-topic
                 :initform nil)
   (target-operation :accessor codex-next-route-target-operation-of
                     :initarg :target-operation)
   (reason :accessor codex-next-route-reason-of
           :initarg :reason)
   (derived-from :accessor codex-next-route-derived-from-of
                 :initarg :derived-from)
   (priority :accessor codex-next-route-priority-of
             :initarg :priority)
   (safety-level :accessor codex-next-route-safety-level-of
                 :initarg :safety-level)
   (status :accessor codex-next-route-status-of
           :initarg :status)
   (action-label :accessor codex-next-route-action-label-of
                 :initarg :action-label)
   (evidence :accessor codex-next-route-evidence-of
             :initarg :evidence
             :initform nil)
   (related-objects :accessor codex-next-route-related-objects-of
                    :initarg :related-objects
                    :initform nil)))

(defmethod print-object ((object codex-next-route) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (title-of object))))

(defclass codex-dmx-learning-topic-status ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (production-db-path
    :accessor codex-dmx-learning-topic-status-production-db-path-of
    :initarg :production-db-path)
   (status :accessor codex-dmx-learning-topic-status-status-of
           :initarg :status)
   (build-tasks :accessor codex-dmx-learning-topic-status-build-tasks-of
                :initarg :build-tasks)
   (task-result :accessor codex-dmx-learning-topic-status-task-result-of
                :initarg :task-result)))

(defmethod print-object ((object codex-dmx-learning-topic-status) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (title-of object)
            (codex-dmx-learning-topic-status-status-of object))))

(defclass codex-dmx-learning-topics ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (production-db-path
    :accessor codex-dmx-learning-topics-production-db-path-of
    :initarg :production-db-path)
   (status :accessor codex-dmx-learning-topics-status-of
           :initarg :status)
   (topics :accessor codex-dmx-learning-topics-topics-of
           :initarg :topics)
   (support-topics :accessor codex-dmx-learning-topics-support-topics-of
                   :initarg :support-topics)
   (associations :accessor codex-dmx-learning-topics-associations-of
                 :initarg :associations)
   (last-replay-status
    :accessor codex-dmx-learning-topics-last-replay-status-of
    :initarg :last-replay-status)
   (build-tasks :accessor codex-dmx-learning-topics-build-tasks-of
                :initarg :build-tasks)
   (inspect-task-result
    :accessor codex-dmx-learning-topics-inspect-task-result-of
    :initarg :inspect-task-result)
   (validation-task-result
    :accessor codex-dmx-learning-topics-validation-task-result-of
    :initarg :validation-task-result)
   (referee-result
    :accessor codex-dmx-learning-topics-referee-result-of
    :initarg :referee-result)
   (referee-route
    :accessor codex-dmx-learning-topics-referee-route-of
    :initarg :referee-route)
   (optional-provider-results
    :accessor codex-dmx-learning-topics-optional-provider-results-of
    :initarg :optional-provider-results)))

(defmethod print-object ((object codex-dmx-learning-topics) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (title-of object)
            (codex-dmx-learning-topics-status-of object))))

(defclass codex-dmx-operation-reader-surface ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (production-db-path
    :accessor codex-dmx-operation-reader-surface-production-db-path-of
    :initarg :production-db-path)
   (status :accessor codex-dmx-operation-reader-surface-status-of
           :initarg :status)
   (reader-question
    :accessor codex-dmx-operation-reader-surface-reader-question-of
    :initarg :reader-question)
   (primary-answer
    :accessor codex-dmx-operation-reader-surface-primary-answer-of
    :initarg :primary-answer)
   (operation-topic
    :accessor codex-dmx-operation-reader-surface-operation-topic-of
    :initarg :operation-topic)
   (fedwiki-page-topic
    :accessor codex-dmx-operation-reader-surface-fedwiki-page-topic-of
    :initarg :fedwiki-page-topic)
   (topics :accessor codex-dmx-operation-reader-surface-topics-of
           :initarg :topics)
   (associations
    :accessor codex-dmx-operation-reader-surface-associations-of
    :initarg :associations)
   (secondary-evidence
    :accessor codex-dmx-operation-reader-surface-secondary-evidence-of
    :initarg :secondary-evidence)
   (materialization-status
    :accessor codex-dmx-operation-reader-surface-materialization-status-of
    :initarg :materialization-status)))

(defmethod print-object ((object codex-dmx-operation-reader-surface) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (title-of object)
            (codex-dmx-operation-reader-surface-status-of object))))

(defclass codex-domkin-2017-source-topics ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   (source :accessor codex-domkin-2017-source-topics-source-of
           :initarg :source)
   (paper-title
    :accessor codex-domkin-2017-source-topics-paper-title-of
    :initarg :paper-title)
   (production-db-path
    :accessor codex-domkin-2017-source-topics-production-db-path-of
    :initarg :production-db-path)
   (status :accessor codex-domkin-2017-source-topics-status-of
           :initarg :status)
   (topic-count
    :accessor codex-domkin-2017-source-topics-topic-count-of
    :initarg :topic-count)
   (expected-topic-count
    :accessor codex-domkin-2017-source-topics-expected-topic-count-of
    :initarg :expected-topic-count)
   (association-count
    :accessor codex-domkin-2017-source-topics-association-count-of
    :initarg :association-count)
   (expected-association-count
    :accessor
    codex-domkin-2017-source-topics-expected-association-count-of
    :initarg :expected-association-count)
   (missing-topic-ids
    :accessor codex-domkin-2017-source-topics-missing-topic-ids-of
    :initarg :missing-topic-ids)
   (missing-association-ids
    :accessor codex-domkin-2017-source-topics-missing-association-ids-of
    :initarg :missing-association-ids)
   (topics :accessor codex-domkin-2017-source-topics-topics-of
           :initarg :topics)
   (associations
    :accessor codex-domkin-2017-source-topics-associations-of
    :initarg :associations)
   (source-artifact
    :accessor codex-domkin-2017-source-topics-source-artifact-of
    :initarg :source-artifact)
   (materialization-status
    :accessor codex-domkin-2017-source-topics-materialization-status-of
    :initarg :materialization-status)
   (build-tasks :accessor codex-domkin-2017-source-topics-build-tasks-of
                :initarg :build-tasks)))

(defmethod print-object ((object codex-domkin-2017-source-topics) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A ~A"
            (title-of object)
            (codex-domkin-2017-source-topics-status-of object))))

(defparameter *codex-build-referee-subgraph-topic-ids*
  '("plan-then-perform-build-session"
    "build-referee-decision-route"
    "add-plan-then-perform-session-state-to-dreyeck-build"
    "render-build-referee-decisions-as-routes"
    "lisp-referee-form"
    "dreyeck/build:build-session-next-action"
    "asdf-3-3-session-action-model"
    "domkin-2017"))

(defparameter *codex-build-referee-subgraph-association-ids*
  '("assoc:plan-then-perform-build-session:refines:codex-is-not-the-build-system"
    "assoc:plan-then-perform-build-session:supports:reusable-common-lisp-build-tasks-for-codex"
    "assoc:plan-then-perform-build-session:inspired-by:asdf-3-3-session-action-model"
    "assoc:asdf-3-3-session-action-model:described-by:domkin-2017"
    "assoc:build-referee-decision-route:renders:lisp-referee-form"
    "assoc:build-referee-decision-route:explains:plan-then-perform-build-session"
    "assoc:build-referee-decision-route:supports:codex-is-not-the-build-system"
    "assoc:build-referee-decision-route:inspects:dreyeck/build:build-session-next-action"))

(defun codex--entry-by-id (entries id)
  (find id entries
        :key (lambda (entry) (getf entry :id))
        :test #'equal))

(defun codex--required-entry (entries id)
  (or (codex--entry-by-id entries id)
      (list :id id :present-p nil)))

(defun codex--present-entry-p (entry)
  (and entry (getf entry :present-p) t))

(defun codex--missing-entry-ids (entries)
  (loop for entry in entries
        unless (codex--present-entry-p entry)
          collect (getf entry :id)))

(defun codex-dmx-build-referee-subgraph (surface)
  "Return the build/referee learned-topic subgraph of a Codex DMX surface.

This is a read-only projection from CODEX-DMX-LEARNING-TOPICS.  It does not
materialize, validate, or decide the next build action; those remain in the
DMX/build layers."
  (let* ((all-topic-entries
           (append (codex-dmx-learning-topics-topics-of surface)
                   (codex-dmx-learning-topics-support-topics-of surface)))
         (association-entries
           (codex-dmx-learning-topics-associations-of surface))
         (topics
           (loop for id in *codex-build-referee-subgraph-topic-ids*
                 collect (codex--required-entry all-topic-entries id)))
         (associations
           (loop for id in *codex-build-referee-subgraph-association-ids*
                 collect (codex--required-entry association-entries id)))
         (missing-topic-ids (codex--missing-entry-ids topics))
         (missing-association-ids (codex--missing-entry-ids associations))
         (topic-count (count-if #'codex--present-entry-p topics))
         (association-count
           (count-if #'codex--present-entry-p associations))
         (passed?
           (and (eq :passed (codex-dmx-learning-topics-status-of surface))
                (null missing-topic-ids)
                (null missing-association-ids))))
    (list
     :view :build-referee-topics-in-production-dmx
     :claim
     "Production DMX SQLite contains the build/referee learned topics."
     :production-db-path
     (codex-dmx-learning-topics-production-db-path-of surface)
     :status (if passed? :passed :failed)
     :topic-count topic-count
     :expected-topic-count
     (length *codex-build-referee-subgraph-topic-ids*)
     :association-count association-count
     :expected-association-count
     (length *codex-build-referee-subgraph-association-ids*)
     :missing-topic-ids missing-topic-ids
     :missing-association-ids missing-association-ids
     :topics topics
     :associations associations
     :source "dreyeck/codex:codex-dmx-learning-topics")))

(defun codex-domkin-2017-source-subgraph (surface)
  "Return the Domkin 2017 ASDF source subgraph as inspectable Lisp data."
  (list
   :view :domkin-2017-source-subgraph
   :source (codex-domkin-2017-source-topics-source-of surface)
   :title (codex-domkin-2017-source-topics-paper-title-of surface)
   :production-db-path
   (codex-domkin-2017-source-topics-production-db-path-of surface)
   :status (codex-domkin-2017-source-topics-status-of surface)
   :topic-count
   (codex-domkin-2017-source-topics-topic-count-of surface)
   :expected-topic-count
   (codex-domkin-2017-source-topics-expected-topic-count-of surface)
   :association-count
   (codex-domkin-2017-source-topics-association-count-of surface)
   :expected-association-count
   (codex-domkin-2017-source-topics-expected-association-count-of
    surface)
   :missing-topic-ids
   (codex-domkin-2017-source-topics-missing-topic-ids-of surface)
   :missing-association-ids
   (codex-domkin-2017-source-topics-missing-association-ids-of surface)
   :topics (codex-domkin-2017-source-topics-topics-of surface)
   :associations
   (codex-domkin-2017-source-topics-associations-of surface)
   :source-artifact
   (codex-domkin-2017-source-topics-source-artifact-of surface)))

(defun codex-dmx-learning-topic-status ()
  "Return the read-only Codex status object for DMX learning topic materialization."
  (let* ((session (dreyeck/build:make-build-session))
         (_plan
           (dreyeck/build:plan-build-task
            session :dmx-durable-note-materialization-status))
         (task-result
           (dreyeck/build:check-build-task
            session :dmx-durable-note-materialization-status))
         (result (getf task-result :result)))
    (declare (ignore _plan))
    (make-instance
     'codex-dmx-learning-topic-status
     :id "codex-dmx-learning-topic-status"
     :title "Codex DMX Learning Topic Status"
     :summary
     "Read-only Codex status for the durable-note materialization backing DMX learning topics."
     :production-db-path (getf result :production-db-path)
     :status (getf task-result :status)
     :build-tasks (dreyeck/build:list-build-tasks)
     :task-result task-result)))

(defun codex-build-referee-route
    (&key (task-id :validate-dmx-learning-topics) db-path)
  "Return Codex's display object for the build-owned referee route.

Codex plans and checks so the route has session state to render, but the route
and next-action decision are owned by DREYECK/BUILD."
  (let ((session (if db-path
                     (dreyeck/build:make-build-session :db-path db-path)
                     (dreyeck/build:make-build-session))))
    (dreyeck/build:plan-build-task session task-id)
    (dreyeck/build:check-build-task session task-id)
    (dreyeck/build:build-session-next-action-route
     session
     :task-id task-id)))

(defun codex-dmx-learning-topics ()
  "Return the Codex inspection surface for materialized DMX learning topics.

The surface invokes Dreyeck build/check session APIs. It does not inline
materializer or validation logic in Codex, and it does not replay materializer
work while inspecting."
  (let* ((session (dreyeck/build:make-build-session))
         (_plan
           (dreyeck/build:plan-build-task
            session :validate-dmx-learning-topics))
         (validation-task-result
           (dreyeck/build:check-build-task
            session :validate-dmx-learning-topics))
         (inspect-task-result
           (dreyeck/build:check-build-task
            session :inspect-dmx-learning-topics))
         (referee-route
           (dreyeck/build:build-session-next-action-route
            session
            :task-id :validate-dmx-learning-topics))
         (referee-result
           (dreyeck/build:build-referee-decision-route-referee-result-of
            referee-route))
         (inspection (getf inspect-task-result :result))
         (validation (getf validation-task-result :result)))
    (declare (ignore _plan))
    (make-instance
     'codex-dmx-learning-topics
     :id "codex-dmx-learning-topics"
     :title "Codex DMX Learning Topics"
     :summary
     "Codex-facing inspection of materialized learning topics in the Dreyeck DMX SQLite production store."
     :production-db-path (getf inspection :production-db-path)
     :status (getf inspect-task-result :status)
     :topics (getf inspection :topics)
     :support-topics (getf inspection :support-topics)
     :associations (getf inspection :associations)
     :last-replay-status (getf validation :last-replay-status)
     :build-tasks (dreyeck/build:list-build-tasks)
     :inspect-task-result inspect-task-result
     :validation-task-result validation-task-result
     :referee-result referee-result
     :referee-route referee-route
     :optional-provider-results
     (list (codex-context-provider-result 'dmx-learning-topic-provider)))))

(defun codex-dmx-association-edge-reader-surface-status
    (db-path reader-surface inspection)
  (let* ((primary-answer (getf reader-surface :primary-answer))
         (atomic-change (getf primary-answer :atomic-change))
         (old-edge (getf atomic-change :removed))
         (new-edge (getf atomic-change :added-or-confirmed))
         (primary-status (getf primary-answer :status))
         (unexpected-graph-delta
           (getf primary-answer :unexpected-graph-delta)))
    (if (and old-edge new-edge)
        (if (and (eq primary-status :passed)
                 (null unexpected-graph-delta)
                 (not
                  (dreyeck.dmx.sqlite:association-edge-present-p
                   db-path old-edge))
                 (dreyeck.dmx.sqlite:association-edge-present-p
                  db-path new-edge))
            :passed
            :failed)
        (or primary-status
            (getf inspection :status)))))

(defun codex-dmx-association-edge-reassignment-reader-surface
    (&key
       (db-path dreyeck.dmx.sqlite:*dreyeck-dmx-production-db-path*)
       old-edge
       new-edge
       raw-report)
  "Return Codex's reader-facing surface for association edge reassignment."
  (let* ((reader-surface
           (dreyeck.dmx.sqlite:association-edge-reassignment-reader-surface
            :old-edge old-edge
            :new-edge new-edge
            :raw-report raw-report))
         (inspection
           (dreyeck.dmx.sqlite:dmx-materialized-operation-reader-surface-topics
            :db-path db-path))
         (topics (getf inspection :topics))
         (operation-topic
           (find "bounded-convergent-association-edge-reassignment"
                 topics
                 :key (lambda (topic) (getf topic :id))
                 :test #'equal))
         (fedwiki-page-topic
           (find "bounded-convergent-association-edge-reassignment-fedwiki-page"
                 topics
                 :key (lambda (topic) (getf topic :id))
                 :test #'equal)))
    (make-instance
     'codex-dmx-operation-reader-surface
     :id "codex-dmx-association-edge-reassignment-reader-surface"
     :title "Association Edge Reassignment Reader Surface"
     :summary
     "Reader-facing answer for the convergent DMX SQLite association edge reassignment operation."
     :production-db-path (getf inspection :production-db-path)
     :status
     (codex-dmx-association-edge-reader-surface-status
      db-path reader-surface inspection)
     :reader-question (getf reader-surface :reader-question)
     :primary-answer (getf reader-surface :primary-answer)
     :operation-topic operation-topic
     :fedwiki-page-topic fedwiki-page-topic
     :topics topics
     :associations (getf inspection :associations)
     :secondary-evidence (getf reader-surface :secondary-evidence)
     :materialization-status (getf inspection :materialization-status))))

(defun codex-domkin-2017-source-topics
    (&key (db-path dreyeck.dmx.sqlite:*dreyeck-dmx-production-db-path*))
  "Return Codex's read-only inspection object for the Domkin 2017 DMX subgraph."
  (let ((inspection
          (dreyeck.dmx.sqlite:dmx-materialized-domkin-2017-source-topics
           :db-path db-path)))
    (make-instance
     'codex-domkin-2017-source-topics
     :id "codex-domkin-2017-source-topics"
     :title "Codex Domkin 2017 Source Topics"
     :summary
     "Codex-facing inspection of Domkin 2017 ASDF source topics materialized in the Dreyeck DMX SQLite production store."
     :source (getf inspection :source)
     :paper-title (getf inspection :title)
     :production-db-path (getf inspection :production-db-path)
     :status (getf inspection :status)
     :topic-count (getf inspection :topic-count)
     :expected-topic-count (getf inspection :expected-topic-count)
     :association-count (getf inspection :association-count)
     :expected-association-count
     (getf inspection :expected-association-count)
     :missing-topic-ids (getf inspection :missing-topic-ids)
     :missing-association-ids (getf inspection :missing-association-ids)
     :topics (getf inspection :topics)
     :associations (getf inspection :associations)
     :source-artifact (getf inspection :source-artifact)
     :materialization-status (getf inspection :materialization-status)
     :build-tasks (dreyeck/build:list-build-tasks))))

(defun codex-context-window-entry (role title text
                                   &key timestamp references derived-objects)
  (make-instance 'codex-context-entry
                 :role role
                 :title title
                 :timestamp timestamp
                 :text text
                 :references references
                 :derived-objects derived-objects))

(defun codex-context-window-chain (window &key (limit 10))
  (loop with current = window
        repeat limit
        while current
        collect current
        do (setf current
                 (codex-context-window-previous-context-window-of current))))

(defun codex-context-window-graph-node (window index repeated-p)
  (list :id (id-of window)
        :title (title-of window)
        :index index
        :depth (codex-context-window-depth-of window)
        :max-depth (codex-context-window-max-depth-of window)
        :repeated-p repeated-p))

(defun codex-context-window-graph (window &key (limit 10))
  (let ((effective-limit (max 0 limit))
        (nodes nil)
        (edges nil)
        (seen-node-ids nil)
        (repeated-node-ids nil)
        (current window)
        (steps 0)
        (terminal :nil)
        (truncated-p nil))
    (loop while (and current (< steps effective-limit))
          for node-id = (id-of current)
          for repeated-p = (member node-id seen-node-ids :test #'equal)
          do (push (codex-context-window-graph-node current steps repeated-p)
                   nodes)
             (if repeated-p
                 (progn
                   (pushnew node-id repeated-node-ids :test #'equal)
                   (setf terminal :cycle
                         current nil))
                 (let ((previous
                         (codex-context-window-previous-context-window-of
                          current)))
                   (push node-id seen-node-ids)
                   (if previous
                       (progn
                         (push (list :previous node-id (id-of previous))
                               edges)
                         (setf current previous))
                       (setf current nil
                             terminal :nil))))
             (incf steps))
    (when current
      (setf terminal :limit
            truncated-p t))
    (list :nodes (nreverse nodes)
          :edges (nreverse edges)
          :truncated-p truncated-p
          :limit effective-limit
          :terminal terminal
          :repeated-node-ids (nreverse repeated-node-ids))))

(defun codex-context-window-nor-expression ()
  '(nor (:self-previous-edge)
        (:repeated-node-or-cycle)
        (:depth-exceeds-limit)
        (:traversal-truncated-before-nil)))

(defun codex-context-window-duplicate-node-ids (graph)
  (loop with seen = nil
        with repeated = nil
        for node in (getf graph :nodes)
        for node-id = (getf node :id)
        do (if (member node-id seen :test #'equal)
               (pushnew node-id repeated :test #'equal)
               (push node-id seen))
        finally (return (nreverse repeated))))

(defun codex-context-window-nor-violations (graph)
  (let ((limit (getf graph :limit)))
    (append
     (loop for edge in (getf graph :edges)
           when (and (eq (first edge) :previous)
                     (equal (second edge) (third edge)))
             collect (list :predicate :self-previous-edge
                           :edge edge))
     (loop for node-id in (remove-duplicates
                           (append (getf graph :repeated-node-ids)
                                   (codex-context-window-duplicate-node-ids
                                    graph))
                           :test #'equal)
           collect (list :predicate :repeated-node-or-cycle
                         :node-id node-id))
     (loop for node in (getf graph :nodes)
           for depth = (getf node :depth)
           when (and depth (> depth limit))
             collect (list :predicate :depth-exceeds-limit
                           :node-id (getf node :id)
                           :depth depth
                           :limit limit))
     (when (getf graph :truncated-p)
       (list
        (list :predicate :traversal-truncated-before-nil
              :limit limit
              :terminal (getf graph :terminal)))))))

(defun codex-context-window-nor-proof-for-graph
    (graph &key context-window title interpretation)
  (let* ((violations (codex-context-window-nor-violations graph))
         (result (null violations)))
    (make-instance
     'codex-context-window-structural-proof
     :title (or title "Codex Context Window NOR Structural Proof")
     :context-window context-window
     :graph graph
     :expression (codex-context-window-nor-expression)
     :result result
     :violations violations
     :interpretation
     (or interpretation
         (if result
             "NOR-style structural proof passed: none of the forbidden recursive predicates matched the finite witness graph."
             "NOR-style structural proof failed: at least one forbidden recursive predicate matched the finite witness graph.")))))

(defun codex-context-window-nor-proof (window &key (limit 10))
  (codex-context-window-nor-proof-for-graph
   (codex-context-window-graph window :limit limit)
   :context-window window))

(defun codex-context-window ()
  (let ((previous
          (make-instance
           'codex-context-window
           :id "codex-kioskbeerli-previous-context-window"
           :title "Previous Kioskbeerli Context"
           :source "Codex/User collaboration thread"
           :captured-at "2026-05-14 previous review snapshot"
           :summary
           "Previous context: Codex Home was accepted as the entry surface before adding the context-window object."
           :entries
           (list
            (codex-context-window-entry
             "user"
             "Codex home approved"
             "The Codex Home view is accepted as the entry surface. The next Codex slice adds an inspectable context-window object reachable from that home surface."
             :timestamp "2026-05-14"
             :references '("Codex" "dreyeck/codex.lisp"
                           "dreyeck-explorer/codex.lisp")
             :derived-objects nil))
           :open-questions nil
           :proposed-actions nil
           :related-objects nil
           :validation-commands nil
           :provenance '("Finite previous context snapshot.")
           :depth 0
           :max-depth 1)))
    (make-instance
     'codex-context-window
     :id "codex-kioskbeerli-context-window"
     :title "Codex Context Window"
     :source "Codex/User collaboration thread"
     :captured-at "2026-05-14 review snapshot"
     :summary
     "Current collaboration context for Codex Home and the Kioskbeerli mobile station-board view: source topic Kioskbeerli, target topic Kioskbeerli Cross-Host Build Failure, and five primary mobile dashboard topics."
     :entries
     (list
      (codex-context-window-entry
       "slice"
       "Kioskbeerli station-board review"
       "The pending review target is the standalone Kioskbeerli dashboard object, not the authored Kioskbeerli Dashboard HTML page."
       :timestamp "2026-05-14"
       :references '("Kioskbeerli Dashboard"
                     "Kioskbeerli"
                     "Kioskbeerli Cross-Host Build Failure")
       :derived-objects (list (codex-context-provider-result 'kioskbeerli-dashboard)
                              (codex-context-provider-result 'kioskbeerli-dashboard-status)
                              (codex-context-provider-result 'kioskbeerli-current-blocker)
                              (codex-context-provider-result 'kioskbeerli-build-evidence-status)
                              (codex-context-provider-result 'kioskbeerli-dashboard-stations)))
      (codex-context-window-entry
       "design"
       "Mobile station-board grammar"
       "The desired first mobile viewport is source topic Kioskbeerli, target topic Kioskbeerli Cross-Host Build Failure, and the five visible dashboard topics: Current status, Build evidence, Flash / boot evidence, Public-display layout state, and Related topic board."
       :timestamp "2026-05-14"
       :references '("Touch-Fahrplan route language"
                     "Kioskbeerli Cross-Host Build Failure")
       :derived-objects (list (codex-context-provider-result 'kioskbeerli-dashboard))))
     :open-questions
     '("Is this Codex context-window object useful as the first inspectable current-context surface?"
       "After approval, should the next slice add only the Station board view for kioskbeerli:kioskbeerli-dashboard in the standalone Kioskbeerli system?")
     :proposed-actions
     '("Inspect (dreyeck/codex:codex-context-window) from SLY/CLOG."
       "Use (hyperdoc::codex-context-window) only as the temporary compatibility entry point."
       "If accepted, keep the next Kioskbeerli iteration scoped to the dashboard object view and avoid editing the authored HTML page.")
     :related-objects
     (list (codex-context-provider-result 'kioskbeerli-dashboard)
           (codex-context-provider-result 'kioskbeerli-dashboard-status)
           (codex-context-provider-result 'kioskbeerli-current-blocker)
           (codex-context-provider-result 'kioskbeerli-build-evidence-status)
           (codex-context-provider-result 'kioskbeerli-dashboard-stations))
     :validation-commands
     '("nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/codex/explorer)' --eval '(assert (dreyeck/codex:codex-context-window))' --eval '(uiop:quit)'"
       "nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :hyperdoc/codex/explorer)' --eval '(assert (hyperdoc::codex-context-window))' --eval '(uiop:quit)'"
       "git diff --check")
     :provenance
     '("AGENTS.md read before implementation."
       "Codex canonical systems are :dreyeck/codex and :dreyeck/codex/explorer."
       "HyperDoc Codex systems remain as temporary compatibility coordinates."
       "This object stores validation commands as strings only; it does not execute forms in the user's live Lisp image."
       "No server, external service, browser automation, or deployment behavior is part of this slice.")
     :previous-context-window previous
     :nested-context-windows (list previous)
     :depth 1
     :max-depth 1
     :raw-text
     "Codex context window snapshot: Codex Home is approved; current slice is the Kioskbeerli mobile station-board object view; source topic is Kioskbeerli; target topic is Kioskbeerli Cross-Host Build Failure; primary topics are Current status, Build evidence, Flash / boot evidence, Public-display layout state, and Related topic board.")))

(defun codex-recent-changes-neighborhood ()
  '("Codex"
    "Codex context window"
    "DMX learning topic inspection"
    "Codex examples"
    "Recursive context-window structural proof"
    "Kioskbeerli station-board pending work"))

(defun codex--recent-change (id title kind summary
                             &key changed-at actor source-object
                               target-object affected-files affected-pages
                               evidence route-hints)
  (make-instance 'codex-recent-change
                 :id id
                 :title title
                 :kind kind
                 :changed-at changed-at
                 :actor actor
                 :summary summary
                 :source-object source-object
                 :target-object target-object
                 :affected-files affected-files
                 :affected-pages affected-pages
                 :evidence evidence
                 :route-hints route-hints))

(defun codex--kioskbeerli-pending-change ()
  (codex--recent-change
   "kioskbeerli-station-board-pending"
   "Kioskbeerli station-board work pending"
   :working-tree
   "Uncommitted Kioskbeerli station-board/page/test work remains pending and should stay out of this Codex topic-system slice."
   :changed-at "2026-05-15 pending workspace state"
   :actor "user workspace"
   :target-object (codex-context-provider-result 'kioskbeerli-dashboard)
   :affected-files '("hyperdoc/Kioskbeerli Dashboard.html"
                     "hyperdoc/Kioskbeerli.html"
                     "tests/kioskbeerli-dashboard-smoke.lisp"
                     "tests/package.lisp")
   :affected-pages '("Kioskbeerli Dashboard" "Kioskbeerli")
   :evidence '("Observed as pre-existing dirty workspace state before this slice."
               "This deterministic model entry records the boundary; it does not query git.")
   :route-hints '("Continue only after inspecting live CLOG rendering."
                  "Choose whether the next change belongs to an authored page or an inspector object view.")))

(defun codex--dmx-learning-topics-change ()
  (codex--recent-change
   "dmx-learning-topics-inspection-added"
   "DMX learning-topic inspection added"
   :inspection
   "Codex can inspect materialized DMX learning topics through reusable Dreyeck Common Lisp build/check tasks."
   :changed-at "2026-06-27 current slice"
   :actor "Codex/User collaboration"
   :target-object (codex-dmx-learning-topic-status)
   :affected-files '("dreyeck/codex/inspect-dmx-materialized-learning-topics-plan.sexp"
                     "dreyeck/dmx/sqlite/durable-notes.lisp"
                     "dreyeck/build/tasks.lisp"
                     "dreyeck/codex.lisp"
                     "dreyeck-explorer/codex.lisp")
   :affected-pages nil
   :evidence '("The SHOP3 plan artifact was created before implementation."
               "(dreyeck/build:plan-build-task ...) records session action state."
               "(dreyeck/build:check-build-task ...) gives Codex non-mutating inspection."
               "(dreyeck/build:build-session-next-action ...) is the Lisp referee form for next admissible action selection."
               "(dreyeck/codex:codex-dmx-learning-topics) calls the session task layer instead of embedding build logic.")
   :route-hints '("Inspect (dreyeck/codex:codex-dmx-learning-topics)."
                  "Use (dreyeck/build:list-build-tasks) to see the reusable task boundary.")))

(defun codex--default-recent-change-entries ()
  (list
   (codex--dmx-learning-topics-change)
   (codex--recent-change
    "codex-moved-to-dreyeck"
    "Codex moved to Dreyeck"
    :architecture
    "Codex collaboration objects, examples, and explorer views moved from HyperDoc core into Dreyeck-owned systems while HyperDoc keeps temporary compatibility wrappers."
    :changed-at "2026-06-27 source refactor"
    :actor "Codex/User collaboration"
    :affected-files '("dreyeck/codex.lisp"
                      "dreyeck/codex-examples.lisp"
                      "dreyeck-explorer/codex.lisp"
                      "dreyeck.asd"
                      "dreyeck/package.lisp"
                      "hyperdoc.asd"
                      "hyperdoc/codex-compat.lisp"
                      "hyperdoc/codex-examples-compat.lisp"
                      "hyperdoc/Codex Belongs to Dreyeck.md")
    :affected-pages '("Codex Belongs to Dreyeck")
    :evidence '(":dreyeck/codex, :dreyeck/codex/examples, and :dreyeck/codex/explorer are canonical."
                ":hyperdoc/codex, :hyperdoc/codex/examples, and :hyperdoc/codex/explorer remain compatibility coordinates."
                "The old HYPERDOC:: entry functions delegate to DREYECK/CODEX.")
    :route-hints '("Migrate pages and inspector forms to DREYECK/CODEX symbols."
                   "Remove HyperDoc compatibility wrappers after callers have moved."))
   (codex--recent-change
    "codex-home-added"
    "Codex home object added"
    :topic
    "Codex became the shared inspectable home object for collaboration review state."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :affected-files '("hyperdoc/codex.lisp"
                      "hyperdoc-explorer/codex.lisp")
    :affected-pages '("Codex")
    :evidence '("Committed slice d6ee511 introduced the Codex topic ASDF coordinate."
                "(hyperdoc::codex) is the shared inspectable home object.")
    :route-hints '("Keep the home compact."
                   "Link to derived objects instead of inlining them."))
   (codex--recent-change
    "codex-context-window-added"
    "Codex context window added"
    :context-window
    "The Codex context-window object became reachable from Codex Home as the bounded current-context surface."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :target-object (codex-context-window)
    :affected-files '("hyperdoc/codex.lisp"
                      "hyperdoc-explorer/codex.lisp")
    :affected-pages '("Codex")
    :evidence '("(hyperdoc::codex-context-window) loads through :hyperdoc/codex."
                "Codex Home links to the context-window object.")
    :route-hints '("Inspect the context window before broadening the slice."))
   (codex--recent-change
    "codex-examples-coordinate-added"
    "Codex examples ASDF coordinate added"
    :example
    "The :hyperdoc/codex/examples system provides deterministic inspectable Codex examples."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :affected-files '("hyperdoc.asd"
                      "hyperdoc/codex-examples.lisp")
    :evidence '(":hyperdoc/codex/examples loads deterministic examples."
                "Examples do not call services, run validation, or mutate files.")
    :route-hints '("Use examples as the first proof objects for new Codex concepts."))
   (codex--recent-change
    "codex-recursive-structural-proof-added"
    "Recursive context-window structural proof added"
    :proof
    "A NOR-style structural proof checks finite context-window traversal for forbidden recursive shapes."
    :changed-at "2026-05-14 committed Codex slice"
    :actor "Codex/User collaboration"
    :affected-files '("hyperdoc/codex.lisp"
                      "hyperdoc/codex-examples.lisp"
                      "hyperdoc-explorer/codex.lisp")
    :evidence '("codex-context-window-nor-proof returns an inspectable proof object."
                "Recursive examples expose finite and cyclic witness graphs.")
    :route-hints '("Inspect proof examples as route evidence before adding live adapters."))
   (codex--kioskbeerli-pending-change)))

(defun codex-recent-changes ()
  (make-instance
   'codex-recent-changes
   :id "codex-recent-changes"
   :title "Recent Changes"
   :source "Deterministic Codex collaboration snapshot"
   :captured-at "2026-05-15 bounded model snapshot"
   :scope "Current Codex collaboration neighborhood; no live federation, git, MCP, or remote queries."
   :summary "What changed recently in this collaboration neighborhood."
   :entries (codex--default-recent-change-entries)
   :neighborhood (codex-recent-changes-neighborhood)
   :provenance '("Motivated by Federated Wiki's recent changes here and nearby idea."
                 "Encoded as deterministic inspectable model data for this slice."
                 "No external services, git discovery, MCP queries, or mutation.")
   :limit 5))

(defun codex--recent-change-by-id (changes id)
  (find id (codex-recent-changes-entries-of changes)
        :key #'id-of
        :test #'equal))

(defun codex--next-route (id title source-topic target-topic
                          target-operation reason derived-from priority
                          safety-level status action-label
                          &key evidence related-objects)
  (make-instance 'codex-next-route
                 :id id
                 :title title
                 :source-topic source-topic
                 :target-topic target-topic
                 :target-operation target-operation
                 :reason reason
                 :derived-from derived-from
                 :priority priority
                 :safety-level safety-level
                 :status status
                 :action-label action-label
                 :evidence evidence
                 :related-objects related-objects))

(defun codex--next-routes-for-recent-changes (changes)
  (let ((dmx-learning-change
          (codex--recent-change-by-id
           changes "dmx-learning-topics-inspection-added"))
        (context-change
          (codex--recent-change-by-id changes "codex-context-window-added"))
        (proof-change
          (codex--recent-change-by-id
           changes "codex-recursive-structural-proof-added"))
        (kioskbeerli-change
          (codex--recent-change-by-id
           changes "kioskbeerli-station-board-pending")))
    (append
     (when dmx-learning-change
       (list
        (codex--next-route
         "inspect-dmx-materialized-learning-topics"
         "Inspect DMX learning topics"
         "Codex"
         "Codex DMX learning topics"
         "inspect materialized learning topics"
         "The current slice makes materialized DMX learning topics reachable through a Codex surface backed by reusable build tasks."
         dmx-learning-change
         1
         :inspect
         :available
         "Inspect"
         :evidence '("(dreyeck/codex:codex-dmx-learning-topics) returns the inspection object."
                     "(dreyeck/build:check-build-task ... :inspect-dmx-learning-topics) returns the structured query result without replay."
                     "(dreyeck/build:build-session-next-action ...) returns the next admissible action as inspectable Lisp data."
                     "(dreyeck/build:perform-build-task ... :validate-dmx-learning-topics) verifies materializer replay only when the session marks it needed.")
         :related-objects (list (codex-dmx-learning-topic-status)))))
     (when context-change
       (list
        (codex--next-route
         "inspect-codex-context-window"
         "Inspect context window"
         "Codex"
         "Codex context window"
         "inspect current context"
         "The recent change made the bounded context-window object reachable from Codex Home."
         context-change
         2
         :inspect
         :available
         "Inspect"
         :evidence '("(dreyeck/codex:codex-context-window) is deterministic and inspectable."
                     "(hyperdoc::codex-context-window) remains as temporary compatibility.")
         :related-objects (list (codex-context-window)))))
     (when proof-change
       (list
        (codex--next-route
         "inspect-structural-proof-examples"
         "Inspect structural proof"
         "Codex"
         "recursive context-window NOR proof"
         "inspect proof examples"
         "The proof recent change supplies deterministic evidence for bounded recursive context-window traversal."
         proof-change
         3
         :inspect
         :available
         "Inspect"
         :evidence '("Use codex-recursive-context-window-nor-proof-example after loading :dreyeck/codex/examples."
                     ":hyperdoc/codex/examples remains a temporary compatibility coordinate."))))
     (when kioskbeerli-change
       (list
        (codex--next-route
         "continue-kioskbeerli-station-board-view"
         "Continue station-board view"
         "Codex"
         "Kioskbeerli Dashboard / Kioskbeerli mobile station-board"
         "inspect pending station-board work"
         "Pending Kioskbeerli work is visible in the collaboration neighborhood but needs live-rendering evidence before continuation."
         kioskbeerli-change
         4
         :dry-run
         :needs-evidence
         "Inspect"
         :evidence '("Pre-existing workspace state says Kioskbeerli page/test work remains pending.")
         :related-objects (list (codex-context-provider-result 'kioskbeerli-dashboard)))
        (codex--next-route
         "decide-kioskbeerli-page-vs-object-view"
         "Decide page vs object view"
         "Kioskbeerli Dashboard"
         "Kioskbeerli mobile station-board"
         "choose authored-page path or inspector-view path"
         "The pending work can plausibly continue as authored HyperDoc page work or as an inspector object-view change; the boundary needs confirmation."
         kioskbeerli-change
         5
         :confirm
         :needs-evidence
         "Decide"
         :evidence '("The current slice must not mix Kioskbeerli page/test edits into Codex topic-system work.")
         :related-objects (list (codex-context-provider-result 'kioskbeerli-dashboard)))))
     (when context-change
       (list
        (codex--next-route
         "plan-mcp-context-window-refresh"
         "Plan MCP refresh"
         "Codex context window"
         "DMX / MCP shared workspace"
         "plan context-window refresh adapter"
         "A later adapter can refresh Codex context from MCP or DMX once the deterministic object shape is accepted."
         context-change
         6
         :dry-run
         :deferred
         "Plan"
         :evidence '("This slice intentionally does not query MCP, DMX, git, or remote sites.")))))))

(defun codex-next-for-recent-changes (changes &key limit)
  (let* ((effective-limit (max 0 (or limit 5)))
         (routes (codex--next-routes-for-recent-changes changes))
         (primary-routes (subseq routes 0 (min effective-limit
                                                (length routes)))))
    (make-instance
     'codex-next
     :id "codex-next"
     :title "Next"
     :source changes
     :changes changes
     :routes primary-routes
     :summary "Given these recent changes, plausible source-to-target operation routes for the next Codex move."
     :generated-at "2026-05-15 deterministic route derivation"
     :provenance '("Derived from codex-recent-changes entries."
                   "At most five primary routes are generated by default."
                   "No external services, git discovery, MCP queries, validation runs, or mutation."))))

(defun codex-next ()
  (codex-next-for-recent-changes (codex-recent-changes)))

(defun codex ()
  (make-instance 'codex-home
                 :id "codex-home"
                 :title "Codex"
                 :summary "Inspectable Dreyeck collaboration home surface for situated review state."
                 :current-slice "DMX materialized learning topic inspection"
                 :context-window (codex-context-window)
                 :recent-changes (codex-recent-changes)
                 :next (codex-next)
                 :primary-review-object (codex-dmx-learning-topic-status)
                 :related-objects (list (codex-context-provider-result
                                         'dmx-learning-topic-provider))
                 :relevant-pages '("Codex Belongs to Dreyeck"
                                   "HyperDoc Core"
                                   "Ownership Extraction with Compatibility Shell")
                 :validation-commands
                 '("nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:load-system :dreyeck/codex/explorer)' --eval '(let ((session (dreyeck/build:make-build-session))) (dreyeck/build:plan-build-task session :validate-dmx-learning-topics) (dreyeck/build:check-build-task session :validate-dmx-learning-topics) (assert (dreyeck/codex:codex-dmx-learning-topics)))' --eval '(uiop:quit)'"
                   "nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:test-system :dreyeck/build)' --eval '(uiop:quit)'"
                   "nix develop -c sbcl --noinform --disable-debugger --non-interactive --eval '(require :asdf)' --eval '(asdf:test-system :dreyeck/dmx/sqlite)' --eval '(uiop:quit)'"
                   "git diff --check")
                 :commit-boundary "Codex materializes collaboration/review records and links to the target topic or system. Implementation changes still belong to the relevant target subsystem."))
