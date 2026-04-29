;;;; Smoke tests for DMX annotation local-first continuation SCXML runbook
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun dmx-annotation-runbook-assert-true (condition message)
  (unless condition
    (error "~A" message)))

(defun dmx-annotation-runbook-assert-equal (expected actual message)
  (unless (equal expected actual)
    (error "~A -- expected: ~S actual: ~S" message expected actual)))

(defun dmx-annotation-runbook-assert-substring (needle haystack message)
  (dmx-annotation-runbook-assert-true
   (and haystack
        (search needle haystack :test #'char-equal))
   (format nil "~A -- missing substring ~S" message needle)))

(defparameter *dmx-annotation-runbook-secret-patterns*
  '("Authorization:"
    "Authorization="
    "Cookie:"
    "Cookie="
    "JSESSIONID="
    "Bearer "
    "bearer "
    "password="
    "password:"
    "\"password\""
    "token="
    "\"token\":\""))

(defun dmx-annotation-runbook-assert-no-secret-patterns (label text)
  (dolist (pattern *dmx-annotation-runbook-secret-patterns*)
    (dmx-annotation-runbook-assert-true
     (or (null text)
         (null (search pattern text :test #'char-equal)))
     (format nil "~A must not include ~S" label pattern))))

(defun dmx-annotation-runbook-read-file-string (pathname)
  (with-open-file (stream pathname
                          :direction :input
                          :if-does-not-exist :error
                          :external-format :utf-8)
    (let ((content (make-string (file-length stream))))
      (read-sequence content stream)
      content)))

(defun dmx-annotation-runbook-find-view-by-title (views title)
  (find title
        views
        :key #'html-inspector-views:view-title
        :test #'string=))

(defun dmx-annotation-runbook-load-inspector-views-for-object (object)
  (let ((pane (make-instance 'clog-moldable-inspector::pane
                             :inspector nil
                             :object object)))
    (clog-moldable-inspector::load-views pane)
    (slot-value pane 'clog-moldable-inspector::views)))

(defun dmx-annotation-runbook-scxml-pathname ()
  (asdf:system-relative-pathname
   :hyperdoc
   "hyperdoc/dmx-annotation-local-first-continuation-runbook.scxml"))

(defun dmx-annotation-runbook-validation-error-findings (findings)
  (remove-if-not (lambda (finding)
                   (eq :error
                       (hyperdoc/scxml:scxml-validation-finding-severity-of
                        finding)))
                 findings))

(defun dmx-annotation-runbook-trace-string (run)
  (format nil "~{~A~%~}"
          (or (hyperdoc::dmx-annotation-acceptance-scxml-run-trace-of run)
              '())))

(defun dmx-annotation-runbook-facts-string (run)
  (with-output-to-string (stream)
    (let ((*print-pretty* t))
      (pprint
       (hyperdoc::dmx-annotation-acceptance-scxml-run-semantic-facts-of run)
       stream))))

(defun run-dmx-annotation-acceptance-scxml-runbook-parse-and-validate-smoke-test ()
  (let* ((path (dmx-annotation-runbook-scxml-pathname))
         (chart (hyperdoc/scxml:parse-scxml-file path))
         (findings (hyperdoc/scxml:validate-scxml-chart chart))
         (errors (dmx-annotation-runbook-validation-error-findings findings)))
    (dmx-annotation-runbook-assert-true
     (null errors)
     (format nil "Runbook SCXML must validate without errors: ~S"
             (mapcar #'hyperdoc/scxml:scxml-validation-finding-code-of
                     errors)))))

(defun run-dmx-annotation-acceptance-scxml-runbook-local-replay-smoke-test ()
  (asdf:load-system :hyperdoc/inspector)
  (let* ((run (hyperdoc::run-dmx-annotation-acceptance-scxml-runbook
               :live? nil))
         (trace-text (dmx-annotation-runbook-trace-string run))
         (facts-text (dmx-annotation-runbook-facts-string run))
         (skipped-checks
           (hyperdoc::dmx-annotation-acceptance-scxml-run-skipped-checks-of run))
         (create-topic-skip
           (find "create-topic failure evidence smoke"
                 skipped-checks
                 :key (lambda (entry) (getf entry :check))
                 :test #'string=))
         (views (dmx-annotation-runbook-load-inspector-views-for-object run))
         (overview (dmx-annotation-runbook-find-view-by-title views
                                                              "DMX annotation acceptance SCXML runbook"))
         (replay (dmx-annotation-runbook-find-view-by-title views "Replay"))
         (overview-html (and overview
                             (html-inspector-views:view-html overview)))
         (replay-html (and replay
                           (html-inspector-views:view-html replay)))
         (scxml-text
           (dmx-annotation-runbook-read-file-string
            (dmx-annotation-runbook-scxml-pathname))))
    (dmx-annotation-runbook-assert-true
     (hyperdoc::dmx-annotation-acceptance-scxml-run-done-p-of run)
     "Local runbook replay must reach a final state")
    (dmx-annotation-runbook-assert-true
     (hyperdoc::dmx-annotation-acceptance-scxml-run-passed-p-of run)
     "Local runbook replay must pass")
    (dmx-annotation-runbook-assert-equal
     "accepted"
     (hyperdoc::dmx-annotation-acceptance-scxml-run-final-state-of run)
     "Local runbook replay must finish in accepted")
    (dmx-annotation-runbook-assert-equal
     '("0c2673e" "242410c" "9f489ab")
     (hyperdoc::dmx-annotation-acceptance-scxml-run-accepted-commits-of run)
     "Runbook replay must record accepted commit set")
    (dolist (state-id
             '("preflightCleanTree"
               "recordAcceptedCommits"
               "localFirstSaveWithoutCredentials"
               "optionalDmxMaterialization"
               "createTopicFailureEvidenceSmokeSkippedPreTopicUpsert"
               "guardedContinuationForExistingTopic936040"
               "workspaceAssignmentReadback919815"
               "topicmapReadbackIncludes919822"
               "reopenReconstructsWorkspaceDockAnnotation"
               "secretLeakageAudit"
               "liveSmokeReplay"
               "accepted"))
      (dmx-annotation-runbook-assert-substring
       (format nil "Entering: ~A" state-id)
       trace-text
       (format nil "Runbook trace must include state ~A" state-id)))
    (dmx-annotation-runbook-assert-true
     (and create-topic-skip
          (eq :skipped (getf create-topic-skip :status)))
     "Runbook replay must record create-topic evidence check as skipped")
    (dmx-annotation-runbook-assert-substring
     "pre-topic-upsert"
     (or (getf create-topic-skip :reason) "")
     "Runbook replay must preserve designed pre-topic-upsert skip reason")
    (dmx-annotation-runbook-assert-true
     (null (search "PUT /core/topic/936040" trace-text :test #'char-equal))
     "Runbook trace must not include raw topic upsert for preserved topic 936040")
    (dmx-annotation-runbook-assert-true
     overview
     "Runbook object must expose an overview inspector view")
    (dmx-annotation-runbook-assert-true
     replay
     "Runbook object must expose a replay inspector view")
    (dmx-annotation-runbook-assert-substring
     "Accepted commits"
     overview-html
     "Overview view must expose accepted commits")
    (dmx-annotation-runbook-assert-substring
     "Final state"
     overview-html
     "Overview view must expose final state")
    (dmx-annotation-runbook-assert-substring
     "Validation findings"
     overview-html
     "Overview view must expose validation findings")
    (dmx-annotation-runbook-assert-substring
     "Trace"
     overview-html
     "Overview view must expose replay trace")
    (dmx-annotation-runbook-assert-substring
     "Replay SCXML locally"
     replay-html
     "Replay view must expose local replay action label")
    (dmx-annotation-runbook-assert-substring
     "Replay live smoke"
     replay-html
     "Replay view must expose live replay action label or guard text")
    (dmx-annotation-runbook-assert-no-secret-patterns "SCXML artifact" scxml-text)
    (dmx-annotation-runbook-assert-no-secret-patterns "Runbook trace" trace-text)
    (dmx-annotation-runbook-assert-no-secret-patterns "Runbook facts" facts-text)
    (dmx-annotation-runbook-assert-no-secret-patterns "Overview HTML" overview-html)
    (dmx-annotation-runbook-assert-no-secret-patterns "Replay HTML" replay-html)
    (dmx-annotation-runbook-assert-no-secret-patterns
     "Live stdout"
     (hyperdoc::dmx-annotation-acceptance-scxml-run-live-stdout-of run))
    (dmx-annotation-runbook-assert-no-secret-patterns
     "Live stderr"
     (hyperdoc::dmx-annotation-acceptance-scxml-run-live-stderr-of run))))

(defun run-dmx-annotation-acceptance-scxml-runbook-smoke-tests ()
  (run-dmx-annotation-acceptance-scxml-runbook-parse-and-validate-smoke-test)
  (run-dmx-annotation-acceptance-scxml-runbook-local-replay-smoke-test)
  (format t "~&DMX annotation acceptance SCXML runbook smoke tests passed.~%")
  t)
