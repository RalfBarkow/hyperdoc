;;;; LISP-CRITIC review integration plan objects
;;
;;;; This slice models the integration plan only.  It preserves the local
;;;; FedWiki asset as a source station and intentionally does not load, copy,
;;;; execute, or normalize LISP-CRITIC output.

(in-package :hyperdoc)

(defclass hyperdoc-plan ()
  ((id :initarg :id :reader hyperdoc-plan-id-of)
   (title :initarg :title :reader hyperdoc-plan-title-of)
   (goal :initarg :goal :reader hyperdoc-plan-goal-of)
   (status :initarg :status :reader hyperdoc-plan-status-of)
   (source-stations :initarg :source-stations
                    :reader hyperdoc-plan-source-stations-of)
   (contracts :initarg :contracts :reader hyperdoc-plan-contracts-of)
   (task-relations :initarg :task-relations
                   :accessor hyperdoc-plan-task-relations-of)
   (goldberg-questions :initarg :goldberg-questions
                       :reader hyperdoc-plan-goldberg-questions-of)))

(defclass hyperdoc-task-topic ()
  ((id :initarg :id :reader hyperdoc-task-topic-id-of)
   (title :initarg :title :reader hyperdoc-task-topic-title-of)
   (shortdesc :initarg :shortdesc :reader hyperdoc-task-topic-shortdesc-of)
   (context :initarg :context :reader hyperdoc-task-topic-context-of)
   (prerequisites :initarg :prerequisites
                  :reader hyperdoc-task-topic-prerequisites-of)
   (steps :initarg :steps :reader hyperdoc-task-topic-steps-of)
   (expected-result :initarg :expected-result
                    :reader hyperdoc-task-topic-expected-result-of)
   (artifacts :initarg :artifacts :reader hyperdoc-task-topic-artifacts-of)
   (evidence :initarg :evidence :reader hyperdoc-task-topic-evidence-of)
   (goldberg-questions :initarg :goldberg-questions
                       :reader hyperdoc-task-topic-goldberg-questions-of)))

(defclass hyperdoc-plan-task-relation ()
  ((plan :initarg :plan :reader hyperdoc-plan-task-relation-plan-of)
   (task :initarg :task :reader hyperdoc-plan-task-relation-task-of)
   (relation-type :initarg :relation-type
                  :reader hyperdoc-plan-task-relation-relation-type-of)
   (ordinal :initarg :ordinal
            :reader hyperdoc-plan-task-relation-ordinal-of)
   (depends-on :initarg :depends-on
               :reader hyperdoc-plan-task-relation-depends-on-of)
   (produces :initarg :produces
             :reader hyperdoc-plan-task-relation-produces-of)
   (validates :initarg :validates
              :reader hyperdoc-plan-task-relation-validates-of)
   (answers :initarg :answers
            :reader hyperdoc-plan-task-relation-answers-of)))

(defmethod print-object ((object hyperdoc-plan) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (hyperdoc-plan-id-of object))))

(defmethod print-object ((object hyperdoc-task-topic) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A" (hyperdoc-task-topic-id-of object))))

(defmethod print-object ((object hyperdoc-plan-task-relation) stream)
  (print-unreadable-object (object stream :type t)
    (format stream "~A -> ~A"
            (hyperdoc-plan-id-of
             (hyperdoc-plan-task-relation-plan-of object))
            (hyperdoc-task-topic-id-of
             (hyperdoc-plan-task-relation-task-of object)))))

(defmethod id-of ((plan hyperdoc-plan))
  (hyperdoc-plan-id-of plan))

(defmethod title-of ((plan hyperdoc-plan))
  (hyperdoc-plan-title-of plan))

(defmethod summary-of ((plan hyperdoc-plan))
  (hyperdoc-plan-goal-of plan))

(defmethod id-of ((task hyperdoc-task-topic))
  (hyperdoc-task-topic-id-of task))

(defmethod title-of ((task hyperdoc-task-topic))
  (hyperdoc-task-topic-title-of task))

(defmethod summary-of ((task hyperdoc-task-topic))
  (hyperdoc-task-topic-shortdesc-of task))

(defmethod title-of ((relation hyperdoc-plan-task-relation))
  (format nil "~A relation in ~A"
          (hyperdoc-task-topic-title-of
           (hyperdoc-plan-task-relation-task-of relation))
          (hyperdoc-plan-title-of
           (hyperdoc-plan-task-relation-plan-of relation))))

(defmethod summary-of ((relation hyperdoc-plan-task-relation))
  (format nil "~A task relation at ordinal ~A; produces ~{~A~^, ~}."
          (hyperdoc-plan-task-relation-relation-type-of relation)
          (hyperdoc-plan-task-relation-ordinal-of relation)
          (hyperdoc-plan-task-relation-produces-of relation)))

(defparameter *lisp-critic-fedwiki-asset-root*
  "~/.wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/")

(defparameter *lisp-critic-review-goldberg-question-aliases*
  '((:does-system-do-this . :does-any-part-do-this))
  "Question id aliases for prompt language that differs from the local
Goldberg Programmer-as-Reader slice.  The prompt's :DOES-SYSTEM-DO-THIS maps
to the local :DOES-ANY-PART-DO-THIS question id.")

(defparameter *lisp-critic-review-source-stations*
  `((:fedwiki-asset
     :site "wiki.ralfbarkow.ch"
     :page "a-critic-for-lisp"
     :asset-root ,*lisp-critic-fedwiki-asset-root*)))

(defparameter *lisp-critic-review-contracts*
  '(:review-contract
    :critic-contract
    :source-station-contract
    :view-contract))

(defparameter *lisp-critic-review-task-data*
  '((:id "inventory-fedwiki-lisp-critic-asset"
     :title "Inventory FedWiki LISP-CRITIC asset"
     :shortdesc "Represent the FedWiki page asset as the source station for the critic."
     :context "LISP-CRITIC is locally available as a FedWiki page asset, not as a vendored dependency for this slice."
     :prerequisites ("HyperDoc can represent source-station metadata without requiring the asset to exist in CI.")
     :steps ("Record the FedWiki site, page, and local asset-root path."
             "Identify the future manifest artifact without creating it here.")
     :expected-result "A source-station-backed inventory task points at the critic asset and names the critic-source-manifest artifact."
     :artifacts (:critic-source-manifest)
     :evidence ((:source-station-path :represented-data)
                (:asset-presence :optional))
     :goldberg-questions (:where-is-it :what-is-that :what-is-needed))
    (:id "define-critic-source-station-contract"
     :title "Define critic source-station contract"
     :shortdesc "Declare how the FedWiki critic source will be trusted and inspected."
     :context "The review slice needs a source-station boundary before any engine adapter is credible."
     :prerequisites ("inventory-fedwiki-lisp-critic-asset")
     :steps ("Name the contract inputs."
             "Preserve local asset identity separately from any future manifest copy.")
     :expected-result "A fedwiki-critic-source contract can be inspected before execution work starts."
     :artifacts (:fedwiki-critic-source)
     :evidence ((:contract :planned))
     :goldberg-questions (:where-is-it :what-is-needed))
    (:id "load-or-invoke-lisp-critic-without-vendoring"
     :title "Load or invoke LISP-CRITIC without vendoring"
     :shortdesc "Define the future invocation boundary without loading or copying the critic now."
     :context "The engine adapter belongs in a later slice after the source-station contract is visible."
     :prerequisites ("define-critic-source-station-contract")
     :steps ("Identify the adapter boundary."
             "Keep live load, ASDF registration, and execution out of this plan-only slice.")
     :expected-result "The lisp-critic-invocation-boundary artifact describes the deferred adapter work."
     :artifacts (:lisp-critic-invocation-boundary)
     :evidence ((:execution :not-in-this-slice))
     :goldberg-questions (:what-can-i-do-now :what-is-needed))
    (:id "normalize-lisp-critic-output-into-findings"
     :title "Normalize LISP-CRITIC output into findings"
     :shortdesc "Plan the finding schema that will hold critic output under review contracts."
     :context "Raw critic output is not yet authoritative review evidence until normalized."
     :prerequisites ("load-or-invoke-lisp-critic-without-vendoring")
     :steps ("Name the lisp-critic-finding artifact."
             "Preserve raw output and finding normalization as separate later work.")
     :expected-result "The plan identifies lisp-critic-finding as the output schema target."
     :artifacts (:lisp-critic-finding)
     :evidence ((:finding-schema :planned))
     :goldberg-questions (:what-is-that :why-happened :why-not-happened))
    (:id "attach-critic-runs-to-review-contracts"
     :title "Attach critic runs to review contracts"
     :shortdesc "Bridge normalized critic findings into HyperDoc review contracts."
     :context "Existing review-contract vocabulary should remain authoritative for automated review."
     :prerequisites ("normalize-lisp-critic-output-into-findings")
     :steps ("Name the review-contract-engine-link artifact."
             "Reuse review priorities, priors, comparison mode, and asymmetric exemplar review vocabulary.")
     :expected-result "Review contracts can later point at critic runs without inventing a parallel review vocabulary."
     :artifacts (:review-contract-engine-link)
     :evidence ((:review-contract-bridge :planned))
     :goldberg-questions (:does-system-do-this :what-knows-about-that :current-state))
    (:id "render-critic-contract-and-run-views"
     :title "Render critic contract and run views"
     :shortdesc "Plan inspector surfaces for critic source, rules, runs, findings, raw output, and suppressions."
     :context "Reviewer-facing output should be inspectable before it becomes executable."
     :prerequisites ("attach-critic-runs-to-review-contracts")
     :steps ("Name the intended inspector surfaces."
             "Keep mutation and execution controls out of this slice.")
     :expected-result "Future inspector views are named as artifacts without pretending they exist yet."
     :artifacts (:contract-view :source-view :rules-view :findings-view :raw-output-view :suppressions-view)
     :evidence ((:views :planned))
     :goldberg-questions (:invoke-response :current-state :what-knows-about-that))
    (:id "expose-task-plan-relation-views"
     :title "Expose task-plan relation views"
     :shortdesc "Make the relation between task topics and plans inspectable."
     :context "This slice adds the reading surface for plan/task/relation navigation."
     :prerequisites ()
     :steps ("Add a Relations to plans view for task topics."
             "Add a Goldberg coverage view for plans.")
     :expected-result "Task topics can answer which plans they belong to and which Goldberg questions they cover."
     :artifacts (:task-to-plan-relation-view :goldberg-coverage-view)
     :evidence ((:inspector-views :implemented-in-this-slice))
     :goldberg-questions (:what-can-i-do-now :current-state :does-system-do-this))
    (:id "add-smoke-tests"
     :title "Add smoke tests"
     :shortdesc "Validate the plan objects, task relations, Goldberg coverage, and view construction."
     :context "The tests must not require a DMX server, FedWiki server, network, or a local critic checkout."
     :prerequisites ("expose-task-plan-relation-views")
     :steps ("Assert the plan and relation shape."
             "Assert Goldberg alias normalization."
             "Render the key inspector views without exact HTML matching.")
     :expected-result "The lisp-critic-review-plan-smoke test proves the plan surface loads and inspects."
     :artifacts (:lisp-critic-review-plan-smoke)
     :evidence ((:tests :implemented-in-this-slice))
     :goldberg-questions (:does-any-part-do-this :current-state :what-is-needed))
    (:id "materialize-documentation-pages"
     :title "Materialize documentation pages"
     :shortdesc "Add durable HyperDoc pages for the integration plan and DITA-like task topics."
     :context "The model needs authored pages that explain the boundary and deferred adapter work."
     :prerequisites ("add-smoke-tests")
     :steps ("Add the plan page."
             "Add the task decomposition page."
             "Link both pages to inspectable objects and existing review-contract topics.")
     :expected-result "The plan and task decomposition are available as durable HyperDoc pages."
     :artifacts (:plan-page :task-decomposition-page)
     :evidence ((:documentation :implemented-in-this-slice))
     :goldberg-questions (:where-is-it :what-is-that :current-state))))

(defparameter *lisp-critic-review-relation-data*
  '((:task "inventory-fedwiki-lisp-critic-asset"
     :relation-type :establishes-source-station
     :ordinal 1
     :depends-on ()
     :produces (:critic-source-manifest)
     :validates (:fedwiki-asset-source-station)
     :answers (:where-is-it :what-is-that :what-is-needed))
    (:task "define-critic-source-station-contract"
     :relation-type :defines-contract
     :ordinal 2
     :depends-on ("inventory-fedwiki-lisp-critic-asset")
     :produces (:fedwiki-critic-source)
     :validates (:source-station-contract)
     :answers (:where-is-it :what-is-needed))
    (:task "load-or-invoke-lisp-critic-without-vendoring"
     :relation-type :implements-engine-adapter
     :ordinal 3
     :depends-on ("define-critic-source-station-contract")
     :produces (:lisp-critic-invocation-boundary)
     :validates (:no-vendor-copy :no-live-execution-in-plan)
     :answers (:what-can-i-do-now :what-is-needed))
    (:task "normalize-lisp-critic-output-into-findings"
     :relation-type :defines-output-schema
     :ordinal 4
     :depends-on ("load-or-invoke-lisp-critic-without-vendoring")
     :produces (:lisp-critic-finding)
     :validates (:finding-schema-boundary)
     :answers (:what-is-that :why-happened :why-not-happened))
    (:task "attach-critic-runs-to-review-contracts"
     :relation-type :bridges-contracts
     :ordinal 5
     :depends-on ("normalize-lisp-critic-output-into-findings")
     :produces (:review-contract-engine-link)
     :validates (:review-contract :critic-contract)
     :answers (:does-system-do-this :what-knows-about-that :current-state))
    (:task "render-critic-contract-and-run-views"
     :relation-type :adds-inspector-surface
     :ordinal 6
     :depends-on ("attach-critic-runs-to-review-contracts")
     :produces (:contract-view :source-view :rules-view :findings-view :raw-output-view :suppressions-view)
     :validates (:inspector-surface-plan)
     :answers (:invoke-response :current-state :what-knows-about-that))
    (:task "expose-task-plan-relation-views"
     :relation-type :adds-reading-surface
     :ordinal 7
     :depends-on ()
     :produces (:task-to-plan-relation-view :goldberg-coverage-view)
     :validates (:task-plan-relation-navigation)
     :answers (:what-can-i-do-now :current-state :does-system-do-this))
    (:task "add-smoke-tests"
     :relation-type :validates-plan
     :ordinal 8
     :depends-on ("expose-task-plan-relation-views")
     :produces (:lisp-critic-review-plan-smoke)
     :validates (:plan-object :task-relations :goldberg-coverage :view-rendering)
     :answers (:does-any-part-do-this :current-state :what-is-needed))
    (:task "materialize-documentation-pages"
     :relation-type :documents-capability
     :ordinal 9
     :depends-on ("add-smoke-tests")
     :produces (:plan-page :task-decomposition-page)
     :validates (:durable-hyperdoc-pages)
     :answers (:where-is-it :what-is-that :current-state))))

(defun lisp-critic-review-normalize-goldberg-question-id (question-id)
  (or (cdr (assoc question-id
                  *lisp-critic-review-goldberg-question-aliases*))
      question-id))

(defun %lisp-critic-review-normalize-goldberg-question-ids (question-ids)
  (mapcar #'lisp-critic-review-normalize-goldberg-question-id question-ids))

(defun %lisp-critic-review-normalize-task-id (task-id)
  (etypecase task-id
    (hyperdoc-task-topic
     (hyperdoc-task-topic-id-of task-id))
    (keyword
     (string-downcase (symbol-name task-id)))
    (symbol
     (string-downcase (symbol-name task-id)))
    (string
     (string-downcase task-id))))

(defun %lisp-critic-review-make-task-topic (data)
  (make-instance
   'hyperdoc-task-topic
   :id (getf data :id)
   :title (getf data :title)
   :shortdesc (getf data :shortdesc)
   :context (getf data :context)
   :prerequisites (getf data :prerequisites)
   :steps (getf data :steps)
   :expected-result (getf data :expected-result)
   :artifacts (getf data :artifacts)
   :evidence (getf data :evidence)
   :goldberg-questions
   (%lisp-critic-review-normalize-goldberg-question-ids
    (getf data :goldberg-questions))))

(defun %lisp-critic-review-make-relation (plan tasks-by-id data)
  (let ((task (cdr (assoc (getf data :task) tasks-by-id :test #'string=))))
    (unless task
      (error "Unknown LISP-CRITIC review task id ~S" (getf data :task)))
    (make-instance
     'hyperdoc-plan-task-relation
     :plan plan
     :task task
     :relation-type (getf data :relation-type)
     :ordinal (getf data :ordinal)
     :depends-on (getf data :depends-on)
     :produces (getf data :produces)
     :validates (getf data :validates)
     :answers
     (%lisp-critic-review-normalize-goldberg-question-ids
      (getf data :answers)))))

(defun %lisp-critic-review-make-plan ()
  (let* ((tasks (mapcar #'%lisp-critic-review-make-task-topic
                        *lisp-critic-review-task-data*))
         (tasks-by-id (mapcar (lambda (task)
                                (cons (hyperdoc-task-topic-id-of task)
                                      task))
                              tasks))
         (plan (make-instance
                'hyperdoc-plan
                :id "integrate-lisp-critic-in-review"
                :title "Integrate LISP-CRITIC into HyperDoc automated code review"
                :goal "Use the FedWiki-sourced LISP-CRITIC asset as an inspectable critic engine under review contracts."
                :status :draft
                :source-stations *lisp-critic-review-source-stations*
                :contracts *lisp-critic-review-contracts*
                :task-relations nil
                :goldberg-questions nil))
         (relations (mapcar (lambda (data)
                               (%lisp-critic-review-make-relation
                                plan tasks-by-id data))
                             *lisp-critic-review-relation-data*)))
    (setf (hyperdoc-plan-task-relations-of plan) relations)
    (setf (slot-value plan 'goldberg-questions)
          (sort (remove-duplicates
                 (mapcan (lambda (relation)
                           (copy-list
                            (hyperdoc-plan-task-relation-answers-of relation)))
                         relations)
                 :test #'eq)
                #'string<
                :key #'symbol-name))
    plan))

(defparameter *integrate-lisp-critic-in-review-plan*
  (%lisp-critic-review-make-plan))

(defun integrate-lisp-critic-in-review-plan ()
  *integrate-lisp-critic-in-review-plan*)

(defun lisp-critic-review-plan-task-topics
    (&optional (plan (integrate-lisp-critic-in-review-plan)))
  (remove-duplicates
   (mapcar #'hyperdoc-plan-task-relation-task-of
           (sort (copy-list (hyperdoc-plan-task-relations-of plan))
                 #'<
                 :key #'hyperdoc-plan-task-relation-ordinal-of))
   :test #'eq))

(defun lisp-critic-review-task-topic-by-id
    (task-id &optional (plan (integrate-lisp-critic-in-review-plan)))
  (let ((normalized-id (%lisp-critic-review-normalize-task-id task-id)))
    (find normalized-id
          (lisp-critic-review-plan-task-topics plan)
          :key #'hyperdoc-task-topic-id-of
          :test #'string=)))

(defun lisp-critic-review-relations-for-task
    (task-id &optional (plan (integrate-lisp-critic-in-review-plan)))
  (let ((normalized-id (%lisp-critic-review-normalize-task-id task-id)))
    (remove-if-not
     (lambda (relation)
       (string= normalized-id
                (hyperdoc-task-topic-id-of
                 (hyperdoc-plan-task-relation-task-of relation))))
     (hyperdoc-plan-task-relations-of plan))))

(defun lisp-critic-review-relations-answering
    (question-id &optional (plan (integrate-lisp-critic-in-review-plan)))
  (let ((normalized-question
          (lisp-critic-review-normalize-goldberg-question-id question-id)))
    (remove-if-not
     (lambda (relation)
       (member normalized-question
               (hyperdoc-plan-task-relation-answers-of relation)
               :test #'eq))
     (hyperdoc-plan-task-relations-of plan))))

(defun lisp-critic-review-goldberg-coverage
    (&optional (plan (integrate-lisp-critic-in-review-plan)))
  (mapcar
   (lambda (question-id)
     (let* ((relations (lisp-critic-review-relations-answering
                        question-id plan))
            (tasks (remove-duplicates
                    (mapcar #'hyperdoc-plan-task-relation-task-of relations)
                    :test #'eq))
            (artifacts (remove-duplicates
                        (mapcan (lambda (relation)
                                  (copy-list
                                   (hyperdoc-plan-task-relation-produces-of
                                    relation)))
                                relations)
                        :test #'equal)))
       (list :question-id question-id
             :task-topics tasks
             :relations relations
             :evidence-artifacts artifacts)))
   (hyperdoc-plan-goldberg-questions-of plan)))

(defun %lisp-critic-fedwiki-asset-pathname ()
  (merge-pathnames
   ".wiki/wiki.ralfbarkow.ch/assets/pages/a-critic-for-lisp/"
   (user-homedir-pathname)))

(defun lisp-critic-fedwiki-asset-present-p ()
  (not (null (probe-file (%lisp-critic-fedwiki-asset-pathname)))))
