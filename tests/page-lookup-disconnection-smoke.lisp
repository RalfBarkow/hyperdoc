;;;; Regression smoke tests for page-lookup issue disconnection evidence
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc/tests)

(defun page-lookup-disconnection-find-view (views title)
  (or (find title
            views
            :key #'html-inspector-views:view-title
            :test #'string=)
      (error "Missing inspector view ~S in ~S" title
             (mapcar #'html-inspector-views:view-title views))))

(defun page-lookup-disconnection-render-view (views title)
  (html-inspector-views:view-html
   (page-lookup-disconnection-find-view views title)))

(defun page-lookup-disconnection-goldberg-issue ()
  (let* ((page (hyperbook:find-page hyperdoc:*hyperdoc*
                                    "Goldberg Programmer as Reader"
                                    :signal-error? t))
         (issues (hyperbook:lookup-issues-of page)))
    (or (find "Program read bug"
              issues
              :test #'string=
              :key #'hyperbook:lookup-issue-expected-page-id-of)
        (find "topics"
              issues
              :test #'string=
              :key #'hyperbook:lookup-issue-target-hyperbook-id-of)
        (error "No Goldberg Topics page-lookup issue found."))))

(defun run-page-lookup-disconnection-view-smoke-test ()
  (let* ((issue (page-lookup-disconnection-goldberg-issue))
         (views (page-lookup-load-inspector-views-for-object issue))
         (overview-html (page-lookup-disconnection-render-view views "Overview"))
         (details-html (page-lookup-disconnection-render-view views "Details"))
         (repair-html (page-lookup-disconnection-render-view views "Repair"))
         (condition-html (page-lookup-disconnection-render-view views "Condition")))
    (assert-equal :hyperdoc-topic-page
                  (hyperbook:lookup-issue-target-kind-of issue)
                  "Goldberg topic links should classify as HyperDoc topic-page lookup issues")
    (assert-true
     (search "Program read bug" overview-html :test #'char-equal)
     "Goldberg page-lookup issue overview should render the missing topic title")
    (assert-true
     (> (length details-html) 0)
     "Goldberg page-lookup issue details view should render without closing the pane")
    (assert-true
     (search "Ensure target chunk" repair-html :test #'char-equal)
     "Goldberg page-lookup issue repair view should render the chunk repair action")
    (assert-true
     (> (length condition-html) 0)
     "Goldberg page-lookup issue condition view should render without closing the pane")
    t))

(defun run-page-lookup-disconnection-incident-smoke-test ()
  (let* ((issue (page-lookup-disconnection-goldberg-issue))
         (entries
          (hyperdoc::parse-nixos-service-log-entries
           "{\"MESSAGE\":\"page-lookup issue Overview signaled FILE-DOES-NOT-EXIST\",\"_SYSTEMD_UNIT\":\"hyperdoc.service\",\"PRIORITY\":\"3\",\"__REALTIME_TIMESTAMP\":\"1710000000000000\"}"
           "journalctl -u hyperdoc --output=json --no-pager"
           nil))
         (query
          (make-instance 'hyperdoc::nixos-service-log-query
                         :host "test-host"
                         :service "hyperdoc"
                         :since "30 minutes ago"
                         :pattern "page-lookup"
                         :command "journalctl -u hyperdoc --output=json --no-pager"
                         :exit-status 0
                         :entries entries))
         (incident
          (hyperdoc::make-hyperdoc-page-lookup-disconnect-incident
           :issue issue
           :log-query query))
         (answers
          (hyperdoc::hyperdoc-runtime-incident-goldberg-question-answers-of
           incident))
         (query-views (page-lookup-load-inspector-views-for-object query))
         (incident-views (page-lookup-load-inspector-views-for-object incident)))
    (assert-equal 1
                  (length (hyperdoc::nixos-service-log-query-entries-of query))
                  "Synthetic journal JSON should become a first-class log entry")
    (assert-equal 12
                  (length answers)
                  "The Goldberg incident answer object should contain all 12 questions")
    (assert-true
     (every (lambda (answer)
              (typep answer 'hyperdoc::goldberg-incident-question-answer))
            answers)
     "Goldberg incident answers should be first-class answer objects")
    (page-lookup-disconnection-render-view query-views "Summary")
    (page-lookup-disconnection-render-view query-views "Log entries")
    (page-lookup-disconnection-render-view incident-views "Summary")
    (page-lookup-disconnection-render-view incident-views "Goldberg questions")
    (page-lookup-disconnection-render-view incident-views "Log query")
    t))

(defun run-page-lookup-disconnection-log-unavailable-smoke-test ()
  (let ((query (hyperdoc::hyperdoc-runtime-log-query
                :service "hyperdoc"
                :since "30 minutes ago"
                :pattern "page-lookup")))
    (assert-true
     (typep query 'hyperdoc::nixos-service-log-query)
     "Read-only runtime log query should return an inspectable query object")
    (assert-true
     (hyperdoc::nixos-service-log-query-command-of query)
     "Read-only runtime log query should expose the command it would run")
    t))

(defun run-page-lookup-disconnection-smoke-tests ()
  (run-page-lookup-disconnection-view-smoke-test)
  (run-page-lookup-disconnection-incident-smoke-test)
  (run-page-lookup-disconnection-log-unavailable-smoke-test)
  (format t "~&Page lookup disconnection smoke tests passed.~%")
  t)
