;;;; Smoke tests for dmx-platform workspace-assignment semantics documentation
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun dmx-platform-semantics-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun dmx-platform-semantics-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected ~S but got ~S" message expected actual)))

(defun dmx-platform-semantics-repo-text (relative-path)
  (uiop:read-file-string
   (asdf:system-relative-pathname :hyperdoc relative-path)))

(defun run-dmx-platform-workspace-assignment-semantics-object-smoke-test ()
  (let* ((semantics
          (hyperdoc::dmx-platform-workspace-assignment-semantics))
         (route (getf semantics :public-route))
         (checks (getf semantics :public-route-checks))
         (helper (getf semantics :initial-assignment-helper))
         (unassigned (getf semantics :unassigned-object-policy))
         (http (getf semantics :http-mapping))
         (implication (getf semantics :implication-for-936040)))
    (dmx-platform-semantics-assert-equal
     :dmx-platform-workspace-assignment-semantics
     (getf semantics :state)
     "Semantics object must expose the platform semantics state")
    (dmx-platform-semantics-assert-equal
     :put
     (getf route :method)
     "Semantics object must model the public route method")
    (dmx-platform-semantics-assert-equal
     "/workspaces/{workspaceId}/object/{objectId}"
     (getf route :path-template)
     "Semantics object must model the public route path")
    (dmx-platform-semantics-assert-equal
     "WorkspacesPlugin.assignToWorkspace"
     (getf route :entrypoint)
     "Semantics object must model the dmx-platform entrypoint")
    (dmx-platform-semantics-assert-true
     (getf checks :target-workspace-write-required-p)
     "Public route must require target workspace WRITE")
    (dmx-platform-semantics-assert-true
     (getf checks :object-write-required-p)
     "Public route must require object WRITE")
    (dmx-platform-semantics-assert-equal
     nil
     (getf checks :rest-route-skips-object-check-p)
     "Public route must not skip object write check")
    (dmx-platform-semantics-assert-true
     (getf helper :exists-p)
     "Initial assignment helper must be represented")
    (dmx-platform-semantics-assert-true
     (getf helper :skips-object-write-check-p)
     "Initial assignment helper must skip object write check")
    (dmx-platform-semantics-assert-equal
     nil
     (getf helper :public-rest-route-p)
     "Initial assignment helper must not be modeled as public REST")
    (dmx-platform-semantics-assert-true
     (getf unassigned :read-permitted-p)
     "Unassigned object READ must be permitted")
    (dmx-platform-semantics-assert-true
     (getf unassigned :write-refused-p)
     "Unassigned object WRITE must be refused")
    (dmx-platform-semantics-assert-equal
     401
     (getf http :access-control-failure-status)
     "Access-control failure must map to 401")
    (dmx-platform-semantics-assert-equal
     :dmx-permission-semantics
     (getf implication :failure-class)
     "Topic 936040 implication must classify platform permission semantics")
    (dmx-platform-semantics-assert-equal
     :permission-repair
     (getf implication :next-operation-outside-hyperdoc-write-loop)
     "Next operation must be permission repair outside HyperDoc")
    (dmx-platform-semantics-assert-equal
     :keep-topic-936040
     (getf implication :recommendation)
     "Semantics object must recommend keeping topic 936040")
    t))

(defun run-dmx-platform-workspace-assignment-semantics-scxml-smoke-test ()
  (let* ((path
          (asdf:system-relative-pathname
           :hyperdoc
           "hyperdoc/dmx-platform-workspace-assignment-semantics.scxml"))
         (chart (hyperdoc/scxml:parse-scxml-file path))
         (states (hyperdoc/scxml:scxml-chart-states-of chart)))
    (dmx-platform-semantics-assert-equal
     "dmx-platform-workspace-assignment-semantics"
     (hyperdoc/scxml:scxml-chart-name-of chart)
     "SCXML chart must parse with the expected name")
    (dolist (state-id '("public-route-entered"
                        "target-workspace-write-check"
                        "object-write-check"
                        "unassigned-object-write-refused"
                        "access-control-exception"
                        "http-401"
                        "private-initial-assignment-helper"
                        "permission-repair-required"
                        "assignment-permitted"))
      (dmx-platform-semantics-assert-true
       (find state-id
             states
             :test #'string=
             :key #'hyperdoc/scxml:scxml-state-id-of)
       (format nil "SCXML must include state ~S" state-id)))
    t))

(defun run-dmx-platform-workspace-assignment-semantics-pages-smoke-test ()
  (let* ((semantics-page
          (dmx-platform-semantics-repo-text
           "hyperdoc/DMX platform workspace assignment semantics.html"))
         (runbook-page
          (dmx-platform-semantics-repo-text
           "hyperdoc/DMX workspace assignment permission repair runbook.html"))
         (scxml
          (dmx-platform-semantics-repo-text
           "hyperdoc/dmx-platform-workspace-assignment-semantics.scxml"))
         (combined
          (concatenate 'string semantics-page #(#\Newline)
                       runbook-page #(#\Newline)
                       scxml))
         (live-gate
          (concatenate 'string
                       "HYPERDOC_RUN_LIVE_DMX_"
                       "WORKSPACE_ASSIGNMENT_936040")))
    (dolist (phrase '("public REST route"
                      "object write access"
                      "initial assignment"
                      "unassigned object"
                      "HTTP 401"
                      "permission repair outside the HyperDoc write loop"
                      "keep topic 936040"))
      (dmx-platform-semantics-assert-true
       (search phrase combined :test #'char-equal)
       (format nil "Semantics docs must contain phrase ~S" phrase)))
    (dolist (forbidden (list live-gate
                             (concatenate 'string "assignment is " "fixed")
                             (concatenate 'string "workspace assignment is "
                                          "fixed")
                             (concatenate 'string "JSESSION" "ID=")
                             (concatenate 'string "Author" "ization:")
                             (concatenate 'string "response" " body")
                             (concatenate 'string "pass" "word")
                             (concatenate 'string "tok" "en")))
      (dmx-platform-semantics-assert-true
       (null (search forbidden combined :test #'char-equal))
       (format nil "Semantics docs must not contain forbidden string ~S"
               forbidden)))
    t))

(defun run-dmx-platform-workspace-assignment-semantics-smoke-tests ()
  (run-dmx-platform-workspace-assignment-semantics-object-smoke-test)
  (run-dmx-platform-workspace-assignment-semantics-scxml-smoke-test)
  (run-dmx-platform-workspace-assignment-semantics-pages-smoke-test)
  t)
