;;;; Smoke tests for bounded diagnosis of topic 936040 workspace-assignment 401
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun dmx-assignment-auth-diagnosis-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun dmx-assignment-auth-diagnosis-assert-equal
    (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected ~S but got ~S" message expected actual)))

(defun dmx-assignment-auth-diagnosis-text (object)
  (with-output-to-string (stream)
    (let ((*print-pretty* nil))
      (prin1 object stream))))

(defun run-dmx-workspace-assignment-auth-py4dmx-comparison-smoke-test ()
  (let* ((hyperdoc-shape
          (hyperdoc::hyperdoc-workspace-assignment-request-shape))
         (py4dmx-shape
          (hyperdoc::py4dmx-workspace-assignment-request-shape))
         (py4dmx-write (getf py4dmx-shape :write)))
    (dmx-assignment-auth-diagnosis-assert-true
     (hyperdoc::dmx-workspace-assignment-auth-shape-match-p
      hyperdoc-shape
      py4dmx-shape)
     "HyperDoc guarded PUT shape must match py4dmx session/write convention")
    (dmx-assignment-auth-diagnosis-assert-equal
     "session-only"
     (getf hyperdoc-shape :auth-mode)
     "HyperDoc must drop Authorization after session bootstrap")
    (dmx-assignment-auth-diagnosis-assert-equal
     "session-only"
     (getf py4dmx-write :auth-mode)
     "py4dmx writes must use session-only auth after bootstrap")
    (dmx-assignment-auth-diagnosis-assert-equal
     "JSESSIONID + dmx_workspace_id"
     (getf hyperdoc-shape :cookie-shape)
     "HyperDoc must carry both session and workspace cookie shapes")
    (dmx-assignment-auth-diagnosis-assert-equal
     "JSESSIONID + dmx_workspace_id"
     (getf py4dmx-write :cookie-shape)
     "py4dmx must carry both session and workspace cookie shapes for writes")
    (dmx-assignment-auth-diagnosis-assert-equal
     nil
     (getf py4dmx-write :authorization-scheme-after-bootstrap)
     "py4dmx must not require a second Authorization header after bootstrap")
    t))

(defun run-dmx-platform-workspace-assignment-route-inventory-smoke-test ()
  (let* ((inventory
          (hyperdoc::dmx-platform-workspace-assignment-route-inventory))
         (route (getf inventory :workspace-assignment-route))
         (checks (getf inventory :assignment-checks)))
    (dmx-assignment-auth-diagnosis-assert-equal
     "/workspaces/{workspaceId}/object/{objectId}"
     (getf route :path-template)
     "dmx-platform must expose the workspace assignment route template")
    (dmx-assignment-auth-diagnosis-assert-true
     (getf route :endpoint-present-p)
     "dmx-platform route inventory must mark the assignment endpoint present")
    (dmx-assignment-auth-diagnosis-assert-true
     (getf checks :workspace-write-access-required-p)
     "dmx-platform REST route must require target workspace WRITE access")
    (dmx-assignment-auth-diagnosis-assert-true
     (getf checks :object-write-access-required-p)
     "dmx-platform REST route must require object WRITE access")
    (dmx-assignment-auth-diagnosis-assert-true
     (getf checks :initial-assignment-private-helper-skips-object-check-p)
     "dmx-platform has a private initial-assignment helper that skips object write check")
    (dmx-assignment-auth-diagnosis-assert-equal
     nil
     (getf checks :rest-route-skips-object-check-p)
     "dmx-platform REST route must not be treated as the private initial-assignment helper")
    t))

(defun run-dmx-platform-workspace-assignment-permission-semantics-smoke-test ()
  (let* ((inventory
          (hyperdoc::dmx-platform-workspace-assignment-route-inventory))
         (unassigned-policy (getf inventory :unassigned-object-policy))
         (mapping (getf inventory :permission-status-mapping))
         (probe-routes (getf inventory :read-only-probe-routes)))
    (dmx-assignment-auth-diagnosis-assert-true
     (getf unassigned-policy :read-permission-granted-p)
     "dmx-platform grants READ for unassigned objects")
    (dmx-assignment-auth-diagnosis-assert-true
     (getf unassigned-policy :write-permission-refused-p)
     "dmx-platform refuses WRITE for unassigned objects")
    (dmx-assignment-auth-diagnosis-assert-equal
     401
     (getf mapping :nested-access-control-exception-status)
     "Nested AccessControlException must map to HTTP 401")
    (dmx-assignment-auth-diagnosis-assert-true
     (member "/access-control/object/936040" probe-routes
             :test #'string=)
     "Read-only route inventory must include object permission probe")
    (dmx-assignment-auth-diagnosis-assert-true
     (member "/access-control/workspace/919815/memberships" probe-routes
             :test #'string=)
     "Read-only route inventory must include workspace membership probe")
    t))

(defun run-dmx-workspace-assignment-936040-auth-diagnosis-smoke-test ()
  (let* ((terminal-card
          (hyperdoc::read-dmx-workspace-assignment-936040-terminal-card))
         (diagnosis
          (hyperdoc::make-dmx-workspace-assignment-auth-diagnosis
           :terminal-card terminal-card))
         (classification (getf diagnosis :classification)))
    (dmx-assignment-auth-diagnosis-assert-equal
     :workspace-assignment-auth-diagnosis
     (getf diagnosis :state)
     "Diagnosis object must expose the workspace-assignment auth diagnosis state")
    (dmx-assignment-auth-diagnosis-assert-equal
     :single-live-assignment/auth-blocked
     (getf diagnosis :terminal-card-state)
     "Diagnosis must consume the saved terminal auth-blocked card")
    (dmx-assignment-auth-diagnosis-assert-equal
     936040
     (getf diagnosis :topic-id)
     "Diagnosis must preserve topic 936040")
    (dmx-assignment-auth-diagnosis-assert-equal
     919815
     (getf diagnosis :workspace-id)
     "Diagnosis must target workspace 919815")
    (dmx-assignment-auth-diagnosis-assert-equal
     "/workspaces/919815/object/936040"
     (getf diagnosis :endpoint)
     "Diagnosis must target only the single workspace assignment endpoint")
    (dmx-assignment-auth-diagnosis-assert-true
     (getf diagnosis :request-shape-match-p)
     "Diagnosis must classify HyperDoc request shape as matching py4dmx")
    (dmx-assignment-auth-diagnosis-assert-equal
     :request-shape-matches-py4dmx-but-permission-denied
     (getf classification :one-of)
     "Diagnosis must classify the 401 as permission-boundary, not reconstruction")
    (dmx-assignment-auth-diagnosis-assert-equal
     :permission-boundary
     (getf classification :points-to)
     "Diagnosis must point at permission semantics rather than request shape")
    (dolist (invariant '(:no-live-mutation
                         :no-topic-upsert
                         :no-topicmap-placement
                         :no-full-continuation
                         :no-dmx-journal-write
                         :bounded-evidence))
      (dmx-assignment-auth-diagnosis-assert-true
       (member invariant (getf diagnosis :safe-invariants))
       (format nil "Diagnosis must preserve invariant ~S" invariant)))
    t))

(defun run-dmx-workspace-assignment-936040-no-delete-regression-smoke-test ()
  (let ((diagnosis
         (hyperdoc::make-dmx-workspace-assignment-auth-diagnosis)))
    (dmx-assignment-auth-diagnosis-assert-equal
     :keep-topic-936040
     (getf diagnosis :recommendation)
     "Repair recommendation must keep topic 936040")
    (dmx-assignment-auth-diagnosis-assert-equal
     nil
     (getf diagnosis :delete-and-recreate-default-p)
     "Delete/recreate must not be the default repair path")
    (dolist (requirement '(:full-reference-audit
                           :hard-delete-permission
                           :verified-no-foreign-references
                           :operator-approval))
      (dmx-assignment-auth-diagnosis-assert-true
       (member requirement
               (getf diagnosis
                     :delete-and-recreate-last-resort-requirements))
       (format nil "Last-resort deletion must require ~S" requirement)))
    t))

(defun run-dmx-workspace-assignment-auth-diagnosis-bounds-smoke-test ()
  (let* ((diagnosis
          (hyperdoc::make-dmx-workspace-assignment-auth-diagnosis))
         (printed
          (dmx-assignment-auth-diagnosis-text diagnosis)))
    (dolist (forbidden '("abc123"
                         "not-real"
                         "JSESSIONID=abc123"
                         "Cookie: JSESSIONID"
                         "Authorization: Basic"
                         "Authorization: Bearer"
                         ":response-body "))
      (dmx-assignment-auth-diagnosis-assert-true
       (null (search forbidden printed :test #'char-equal))
       (format nil "Diagnosis output must not leak ~S" forbidden)))
    t))

(defun run-dmx-workspace-assignment-live-gate-skipped-smoke-test ()
  (dmx-assignment-auth-diagnosis-assert-equal
   :single-live-assignment/skipped
   (getf (hyperdoc::run-live-dmx-workspace-assignment-936040-once)
         :state)
   "Live single PUT helper must be skipped without the explicit environment gate")
  t)

(defun dmx-assignment-auth-diagnosis-repo-text (relative-path)
  (uiop:read-file-string
   (asdf:system-relative-pathname :hyperdoc relative-path)))

(defun run-dmx-workspace-assignment-auth-diagnosis-docs-smoke-test ()
  (let ((doc
         (dmx-assignment-auth-diagnosis-repo-text
          "hyperdoc/DMX workspace assignment 401 diagnosis.html"))
        (scxml-path
         (asdf:system-relative-pathname
          :hyperdoc
          "hyperdoc/dmx-workspace-assignment-401-diagnosis.scxml"))
        (scxml
         (dmx-assignment-auth-diagnosis-repo-text
          "hyperdoc/dmx-workspace-assignment-401-diagnosis.scxml")))
    (dolist (needle '("REQUEST-SHAPE-MATCHES-PY4DMX-BUT-PERMISSION-DENIED"
                      "run-live-dmx-workspace-assignment-936040-once"
                      "Delete/recreate is not the default repair path"
                      "PUT /workspaces/919815/object/936040"))
      (dmx-assignment-auth-diagnosis-assert-true
       (search needle doc :test #'char-equal)
       (format nil "Diagnosis document must contain ~S" needle)))
    (dolist (state '("current-auth-blocked"
                     "request-shape-compared"
                     "permission-semantics-inspected"
                     "permission-denied-terminal"
                     "live-gated-single-put-dormant"))
      (dmx-assignment-auth-diagnosis-assert-true
       (search state scxml :test #'char-equal)
       (format nil "Diagnosis SCXML must contain state ~S" state)))
    (let ((chart (hyperdoc/scxml:parse-scxml-file scxml-path)))
      (dmx-assignment-auth-diagnosis-assert-equal
       "dmx-workspace-assignment-401-diagnosis"
       (hyperdoc/scxml:scxml-chart-name-of chart)
       "Diagnosis SCXML must parse as the expected chart")
      (dmx-assignment-auth-diagnosis-assert-true
       (find "permission-denied-terminal"
             (hyperdoc/scxml:scxml-chart-states-of chart)
             :test #'string=
             :key #'hyperdoc/scxml:scxml-state-id-of)
       "Diagnosis SCXML must expose the permission-denied terminal state"))
    (dolist (forbidden '("JSESSIONID="
                         "Authorization: Basic"
                         "Authorization: Bearer"
                         ":RESPONSE-BODY"))
      (dmx-assignment-auth-diagnosis-assert-true
       (and (null (search forbidden doc :test #'char-equal))
            (null (search forbidden scxml :test #'char-equal)))
       (format nil "Docs/SCXML must not leak forbidden token ~S"
               forbidden)))
    t))

(defun run-dmx-workspace-assignment-auth-diagnosis-smoke-tests ()
  (run-dmx-workspace-assignment-auth-py4dmx-comparison-smoke-test)
  (run-dmx-platform-workspace-assignment-route-inventory-smoke-test)
  (run-dmx-platform-workspace-assignment-permission-semantics-smoke-test)
  (run-dmx-workspace-assignment-936040-auth-diagnosis-smoke-test)
  (run-dmx-workspace-assignment-936040-no-delete-regression-smoke-test)
  (run-dmx-workspace-assignment-auth-diagnosis-bounds-smoke-test)
  (run-dmx-workspace-assignment-live-gate-skipped-smoke-test)
  (run-dmx-workspace-assignment-auth-diagnosis-docs-smoke-test)
  t)
