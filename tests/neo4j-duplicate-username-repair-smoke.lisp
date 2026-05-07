;;;; Smoke tests for the narrow Neo4j duplicate-username repair slice
;;
;;;; Copyright (c) 2026

(eval-when (:compile-toplevel :load-toplevel :execute)
  (unless (find-package :hyperdoc/tests)
    (make-package :hyperdoc/tests :use '(:cl)))
  (export (list (intern "RUN-NEO4J-DUPLICATE-USERNAME-REPAIR-SMOKE-TESTS"
                        :hyperdoc/tests))
          :hyperdoc/tests))

(in-package :hyperdoc/tests)

(defun neo4j-repair-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun neo4j-repair-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun neo4j-repair-assert-typep (type object message)
  (unless (typep object type)
    (error "~A -- expected type: ~S actual type: ~S"
           message type (type-of object))))

(defun neo4j-repair-assert-contains (substring string message)
  (unless (search substring string :test #'char=)
    (error "~A -- missing substring: ~S" message substring)))

(defun neo4j-repair-assert-not-contains (substring string message)
  (when (search substring string :test #'char=)
    (error "~A -- unexpected substring: ~S" message substring)))

(defun neo4j-repair-smoke-relative-path (relative-path)
  (asdf:system-relative-pathname :hyperdoc relative-path))

(defun neo4j-repair-read-file (relative-path)
  (uiop:read-file-string
   (neo4j-repair-smoke-relative-path relative-path)))

(defun neo4j-repair-normalize-whitespace (string)
  (with-output-to-string (stream)
    (loop with pending-space = nil
          with wrote-char = nil
          for char across string
          do (if (find char '(#\Space #\Tab #\Newline #\Return))
                 (setf pending-space t)
                 (progn
                   (when pending-space
                     (when wrote-char
                       (write-char #\Space stream))
                     (setf pending-space nil))
                   (write-char char stream)
                   (setf wrote-char t))))))

(defun neo4j-repair-page-contains-all (relative-path needles)
  (neo4j-repair-string-contains-all
   (neo4j-repair-read-file relative-path)
   relative-path
   needles))

(defun neo4j-repair-string-contains-all (string label needles)
  (let ((normalized
         (neo4j-repair-normalize-whitespace string)))
    (dolist (needle needles)
      (neo4j-repair-assert-true
       (search (neo4j-repair-normalize-whitespace needle)
               normalized
               :test #'char=)
       (format nil "~A must contain ~S" label needle)))))

(defun neo4j-repair-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun neo4j-repair-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun neo4j-repair-make-unresolved-report ()
  (hyperdoc::make-neo4j-username-ambiguity-report
   (hyperdoc::example-admin-username-read-operation)
   :status :ok
   :raw-payload
   (shasht:read-json
    "{\"matchingCount\":2,\"matchingTopics\":[{\"nodeId\":11,\"value\":\"admin\",\"userAccounts\":[{\"userAccountId\":101}]},{\"nodeId\":12,\"value\":\"admin\",\"userAccounts\":[{\"userAccountId\":102}]}]}")
   :raw-json nil
   :command-records nil))

(defun run-neo4j-duplicate-username-runtime-smoke-test ()
  (asdf:load-system :hyperdoc/tests)
  (dolist (symbol '(hyperdoc::make-local-neo4j-store-target
                    hyperdoc::make-local-dmx-neo4j-instance-target
                    hyperdoc::make-local-admin-username-ambiguity-read-operation
                    hyperdoc::make-example-admin-username-ambiguity-report
                    hyperdoc::plan-neo4j-duplicate-username-repair
                    hyperdoc::make-example-admin-duplicate-username-repair-plan
                    hyperdoc::make-example-refused-admin-duplicate-username-repair-operation))
    (neo4j-repair-assert-true
     (fboundp symbol)
     (format nil "Runtime entrypoint must be available after ASDF load: ~A" symbol)))
  (dolist (class '(hyperdoc::neo4j-store-target
                   hyperdoc::dmx-neo4j-instance-target
                   hyperdoc::neo4j-read-query-operation
                   hyperdoc::neo4j-username-ambiguity-report
                   hyperdoc::neo4j-duplicate-username-repair-plan
                   hyperdoc::neo4j-repair-operation))
    (neo4j-repair-assert-true
     (find-class class nil)
     (format nil "Runtime class must be available after ASDF load: ~A" class)))
  (let* ((store-target (hyperdoc::make-local-neo4j-store-target))
         (instance-target (hyperdoc::make-local-dmx-neo4j-instance-target
                           :store-target store-target))
         (read-operation (hyperdoc::make-local-admin-username-ambiguity-read-operation
                          :instance-target instance-target))
         (report (hyperdoc::make-example-admin-username-ambiguity-report))
         (plan (hyperdoc::make-example-admin-duplicate-username-repair-plan))
         (refused (hyperdoc::make-example-refused-admin-duplicate-username-repair-operation))
         (unsupported-report (neo4j-repair-make-unresolved-report))
         (unsupported-plan
          (hyperdoc::plan-neo4j-duplicate-username-repair unsupported-report)))
    (neo4j-repair-assert-typep 'hyperdoc::neo4j-store-target store-target
                               "Store target type")
    (neo4j-repair-assert-typep 'hyperdoc::dmx-neo4j-instance-target instance-target
                               "Instance target type")
    (neo4j-repair-assert-typep 'hyperdoc::neo4j-read-query-operation read-operation
                               "Read operation type")
    (neo4j-repair-assert-typep 'hyperdoc::neo4j-username-ambiguity-report report
                               "Report type")
    (neo4j-repair-assert-typep 'hyperdoc::neo4j-duplicate-username-repair-plan plan
                               "Plan type")
    (neo4j-repair-assert-typep 'hyperdoc::neo4j-repair-operation refused
                               "Repair operation type")
    (neo4j-repair-assert-equal :canonical-vs-stale-duplicate
                               (hyperdoc::neo4j-username-ambiguity-report-classification-of report)
                               "Example report classification")
    (neo4j-repair-assert-equal :review-pending
                               (hyperdoc::neo4j-duplicate-username-repair-plan-status-of plan)
                               "Example plan status")
    (neo4j-repair-assert-equal :unsupported
                               (hyperdoc::neo4j-duplicate-username-repair-plan-status-of unsupported-plan)
                               "Unsupported ambiguity shapes must stay unsupported")
    (neo4j-repair-assert-equal :refused
                               (hyperdoc::neo4j-repair-operation-status-of refused)
                               "Unapproved example operation must refuse instead of mutating")
    (neo4j-repair-assert-true
     (null (hyperdoc::neo4j-repair-operation-execution-records-of refused))
     "Refused example operation must not carry execution records")
    (neo4j-repair-assert-contains
     "has not been explicitly approved"
     (hyperdoc::neo4j-repair-operation-refusal-reason-of refused)
     "Refused example operation must preserve the review guardrail")
    (neo4j-repair-assert-contains
     "do not reduce to one account-backed canonical identity plus one standalone stale duplicate"
     (hyperdoc::neo4j-duplicate-username-repair-plan-refusal-reason-of unsupported-plan)
     "Unsupported plan must preserve an inspectable refusal reason")))

(defun run-neo4j-duplicate-username-view-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (let* ((store-target (hyperdoc::make-local-neo4j-store-target))
         (read-operation (hyperdoc::make-local-admin-username-ambiguity-read-operation))
         (report (hyperdoc::make-example-admin-username-ambiguity-report))
         (plan (hyperdoc::make-example-admin-duplicate-username-repair-plan))
         (refused (hyperdoc::make-example-refused-admin-duplicate-username-repair-operation))
         (store-views (neo4j-repair-load-inspector-views-for-object store-target))
         (read-views (neo4j-repair-load-inspector-views-for-object read-operation))
         (report-views (neo4j-repair-load-inspector-views-for-object report))
         (plan-views (neo4j-repair-load-inspector-views-for-object plan))
         (refused-views (neo4j-repair-load-inspector-views-for-object refused)))
    (dolist (title '("Summary" "Adapter boundary"))
      (neo4j-repair-assert-true
       (neo4j-repair-find-view-by-title store-views title)
       (format nil "Store target must expose view ~A" title)))
    (dolist (title '("Summary" "Materialization" "Boundary"))
      (neo4j-repair-assert-true
       (neo4j-repair-find-view-by-title read-views title)
       (format nil "Read operation must expose view ~A" title)))
    (dolist (title '("Overview" "Matching topics" "Command records"))
      (neo4j-repair-assert-true
       (neo4j-repair-find-view-by-title report-views title)
       (format nil "Report must expose view ~A" title)))
    (dolist (title '("Overview" "Materialization" "Guardrails"))
      (neo4j-repair-assert-true
       (neo4j-repair-find-view-by-title plan-views title)
       (format nil "Plan must expose view ~A" title)))
    (dolist (title '("Overview" "Execution" "Verification"))
      (neo4j-repair-assert-true
       (neo4j-repair-find-view-by-title refused-views title)
       (format nil "Repair operation must expose view ~A" title)))
    (neo4j-repair-string-contains-all
     (html-inspector-views:view-html
      (neo4j-repair-find-view-by-title report-views "Overview"))
     "Neo4j report Overview view"
     '("Canonical account plus stale duplicate"
       "906722"
       "2827"))
    (neo4j-repair-string-contains-all
     (html-inspector-views:view-html
      (neo4j-repair-find-view-by-title plan-views "Materialization"))
     "Neo4j plan Materialization view"
     '("# Stop the DMX server before running the store mutation."
       "admin__stale_2827"
       "dmx-db.pre-repair-example"))
    (neo4j-repair-string-contains-all
     (html-inspector-views:view-html
      (neo4j-repair-find-view-by-title refused-views "Overview"))
     "Neo4j refused operation Overview view"
     '("Refused"
       "has not been explicitly approved"))
    (neo4j-repair-string-contains-all
     (html-inspector-views:view-html
      (neo4j-repair-find-view-by-title refused-views "Verification"))
     "Neo4j refused operation Verification view"
     '("Store verification and live verification stay separate"
       "No live verification record is attached yet."))))

(defun run-neo4j-duplicate-username-doc-slice-smoke-test ()
  (asdf:load-system :hyperdoc/explorer)
  (dolist (spec '((hyperdoc::guarded-local-neo4j-repair-boundary-in-hyperdoc-topic
                   . "Guarded local Neo4j repair boundary in HyperDoc")
                  (hyperdoc::guarded-datastore-repair-topic
                   . "Guarded datastore repair")
                  (hyperdoc::datastore-adapter-boundary-topic
                   . "Datastore adapter boundary")
                  (hyperdoc::repairing-duplicate-dmx-admin-username-ambiguity-topic
                   . "Repairing duplicate DMX admin username ambiguity")))
    (let* ((symbol (car spec))
           (title (cdr spec))
           (topic (funcall symbol)))
      (neo4j-repair-assert-true
       (fboundp symbol)
       (format nil "Missing topic function ~A" symbol))
      (neo4j-repair-assert-equal title
                                 (hyperbook:title-of topic)
                                 (format nil "Topic title for ~A" symbol))
      (neo4j-repair-assert-true
       (hyperbook:find-page hyperdoc::*topics* title :signal-error? t)
       (format nil "Missing topic page ~A" title))))
  (dolist (title '("Guarded local Neo4j repair boundary in HyperDoc"
                   "Repairing duplicate DMX admin username ambiguity"))
    (neo4j-repair-assert-true
     (hyperbook:find-page hyperdoc::*hyperdoc* title :signal-error? t)
     (format nil "Missing HyperDoc page ~A" title)))
  (neo4j-repair-page-contains-all
   "hyperdoc/Guarded local Neo4j repair boundary in HyperDoc.html"
   '("not</b> a raw Neo4j console"
     "Lisp owns supported-case classification, refusal, approval, offline confirmation"
     "No arbitrary Cypher entry."
     "No hidden mutation path in explorer or inspector views."))
  (neo4j-repair-page-contains-all
   "hyperdoc/Repairing duplicate DMX admin username ambiguity.html"
   '("inspection first, plan second, guarded repair third, verification fourth"
     "Offline-only preconditions"
     "Unsupported cases remain inspectable refusals"
     "Verification remains separate from mutation.")))

(defun run-neo4j-duplicate-username-view-boundary-smoke-test ()
  (let ((source (neo4j-repair-read-file
                 "hyperdoc-explorer/neo4j-duplicate-username-repair.lisp")))
    (dolist (needle '("execute-approved-neo4j-duplicate-username-repair"
                      "approve-neo4j-duplicate-username-repair-plan"
                      "confirm-neo4j-duplicate-username-repair-plan-offline"
                      "uiop:run-program"
                      "neo4j-duplicate-username-adapter-prepare-commands"
                      "neo4j-duplicate-username-adapter-report-command"
                      "neo4j-duplicate-username-adapter-rename-command"
                      ":button"))
      (neo4j-repair-assert-not-contains
       needle
       source
       (format nil "Explorer layer must stay presentation-only; forbidden source marker ~A" needle)))))

(defun run-neo4j-duplicate-username-repair-smoke-tests ()
  (run-neo4j-duplicate-username-runtime-smoke-test)
  (run-neo4j-duplicate-username-view-smoke-test)
  (run-neo4j-duplicate-username-doc-slice-smoke-test)
  (run-neo4j-duplicate-username-view-boundary-smoke-test)
  (format t "~&Neo4j duplicate-username repair smoke tests passed.~%"))
