;;;; Runtime incidents and read-only service log evidence
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defclass nixos-service-log-entry ()
  ((timestamp :reader nixos-service-log-entry-timestamp-of
              :initarg :timestamp
              :initform nil)
   (unit :reader nixos-service-log-entry-unit-of
         :initarg :unit
         :initform nil)
   (priority :reader nixos-service-log-entry-priority-of
             :initarg :priority
             :initform nil)
   (message :reader nixos-service-log-entry-message-of
            :initarg :message
            :initform "")
   (raw-json :reader nixos-service-log-entry-raw-json-of
             :initarg :raw-json
             :initform nil)
   (source-command :reader nixos-service-log-entry-source-command-of
                   :initarg :source-command
                   :initform nil)))

(defclass nixos-service-log-query ()
  ((host :reader nixos-service-log-query-host-of
         :initarg :host
         :initform nil)
   (service :reader nixos-service-log-query-service-of
            :initarg :service)
   (since :reader nixos-service-log-query-since-of
          :initarg :since
          :initform nil)
   (until :reader nixos-service-log-query-until-of
          :initarg :until
          :initform nil)
   (pattern :reader nixos-service-log-query-pattern-of
            :initarg :pattern
            :initform nil)
   (command :reader nixos-service-log-query-command-of
            :initarg :command)
   (exit-status :reader nixos-service-log-query-exit-status-of
                :initarg :exit-status
                :initform nil)
   (entries :reader nixos-service-log-query-entries-of
            :initarg :entries
            :initform nil)
   (unavailable-reason :reader nixos-service-log-query-unavailable-reason-of
                       :initarg :unavailable-reason
                       :initform nil)
   (error-output :reader nixos-service-log-query-error-output-of
                 :initarg :error-output
                 :initform nil)))

(defclass goldberg-incident-question-answer ()
  ((number :reader goldberg-incident-question-answer-number-of
           :initarg :number)
   (question :reader goldberg-incident-question-answer-question-of
             :initarg :question)
   (answer :reader goldberg-incident-question-answer-answer-of
           :initarg :answer)
   (evidence :reader goldberg-incident-question-answer-evidence-of
             :initarg :evidence
             :initform nil)
   (related-objects :reader goldberg-incident-question-answer-related-objects-of
                    :initarg :related-objects
                    :initform nil)
   (recovery-action :reader goldberg-incident-question-answer-recovery-action-of
                    :initarg :recovery-action
                    :initform nil)))

(defclass hyperdoc-runtime-incident ()
  ((id :reader id-of
       :initarg :id)
   (title :reader title-of
          :initarg :title)
   (observed-at :reader hyperdoc-runtime-incident-observed-at-of
                :initarg :observed-at)
   (symptom :reader hyperdoc-runtime-incident-symptom-of
            :initarg :symptom)
   (page-title :reader hyperdoc-runtime-incident-page-title-of
               :initarg :page-title)
   (object-kind :reader hyperdoc-runtime-incident-object-kind-of
                :initarg :object-kind)
   (object-summary :reader hyperdoc-runtime-incident-object-summary-of
                   :initarg :object-summary)
   (browser-message :reader hyperdoc-runtime-incident-browser-message-of
                    :initarg :browser-message)
   (likely-layer :reader hyperdoc-runtime-incident-likely-layer-of
                 :initarg :likely-layer)
   (related-log-query :reader hyperdoc-runtime-incident-related-log-query-of
                      :initarg :related-log-query
                      :initform nil)
   (related-log-excerpts :reader hyperdoc-runtime-incident-related-log-excerpts-of
                         :initarg :related-log-excerpts
                         :initform nil)
   (recovery-actions :reader hyperdoc-runtime-incident-recovery-actions-of
                     :initarg :recovery-actions
                     :initform nil)
   (goldberg-question-answers
    :reader hyperdoc-runtime-incident-goldberg-question-answers-of
    :initarg :goldberg-question-answers
    :initform nil)))

(defparameter *hyperdoc-release-service-name* "hyperdoc")

(defparameter *goldberg-reading-comprehension-questions*
  '("How do I invoke response?"
    "What specifically can I do now?"
    "What is needed to do a specific function?"
    "What is that?"
    "Where is it?"
    "Does any part of the system do this?"
    "What part of the system knows about that?"
    "How did I get here? What has been happening?"
    "How can I get back?"
    "What is the current state of the system?"
    "Why did that happen?"
    "Why didn't that happen?"))

(defun shell-command-string (argv)
  (format nil "~{~A~^ ~}" argv))

(defun journalctl-command (&key service since until)
  (append (list "journalctl" "-u" service "--output=json" "--no-pager")
          (when since
            (list "--since" since))
          (when until
            (list "--until" until))))

(defun journal-json-field (json key)
  (let* ((needle (format nil "\"~A\":\"" key))
         (start (search needle json :test #'char=)))
    (when start
      (let* ((value-start (+ start (length needle)))
             (value-end (position #\" json :start value-start)))
        (and value-end
             (subseq json value-start value-end))))))

(defun parse-nixos-service-log-entry (line command)
  (make-instance 'nixos-service-log-entry
                 :timestamp (or (journal-json-field line "__REALTIME_TIMESTAMP")
                                (journal-json-field line "_SOURCE_REALTIME_TIMESTAMP"))
                 :unit (journal-json-field line "_SYSTEMD_UNIT")
                 :priority (journal-json-field line "PRIORITY")
                 :message (or (journal-json-field line "MESSAGE")
                              line)
                 :raw-json line
                 :source-command command))

(defun parse-nixos-service-log-entries (output command pattern)
  (let ((entries nil))
    (with-input-from-string (stream (or output ""))
      (loop for line = (read-line stream nil nil)
            while line
            for entry = (parse-nixos-service-log-entry line command)
            when (or (null pattern)
                     (search pattern
                             (or (nixos-service-log-entry-message-of entry)
                                 "")
                             :test #'char-equal)
                     (search pattern line :test #'char-equal))
              do (push entry entries)))
    (nreverse entries)))

(defun make-log-unavailable-query
    (&key host service since until pattern command reason error-output)
  (make-instance 'nixos-service-log-query
                 :host host
                 :service service
                 :since since
                 :until until
                 :pattern pattern
                 :command command
                 :exit-status :unavailable
                 :entries nil
                 :unavailable-reason reason
                 :error-output error-output))

(defun hyperdoc-runtime-log-query
    (&key (service *hyperdoc-release-service-name*) since until pattern
       (host (ignore-errors (machine-instance))))
  (let* ((command (journalctl-command :service service
                                      :since since
                                      :until until))
         (command-string (shell-command-string command)))
    (handler-case
        (multiple-value-bind (output error-output exit-status)
            (uiop:run-program command
                              :output :string
                              :error-output :string
                              :ignore-error-status t)
          (make-instance 'nixos-service-log-query
                         :host host
                         :service service
                         :since since
                         :until until
                         :pattern pattern
                         :command command-string
                         :exit-status exit-status
                         :entries (parse-nixos-service-log-entries
                                   output
                                   command-string
                                   pattern)
                         :error-output error-output))
      (error (condition)
        (make-log-unavailable-query
         :host host
         :service service
         :since since
         :until until
         :pattern pattern
         :command command-string
         :reason (princ-to-string condition))))))

(defun hyperdoc-release-service-log-query (&key since until pattern)
  (hyperdoc-runtime-log-query :service *hyperdoc-release-service-name*
                              :since since
                              :until until
                              :pattern pattern))

(defun hyperdoc-current-service-log-query
    (&key (minutes 30) (service *hyperdoc-release-service-name*) pattern)
  (hyperdoc-runtime-log-query :service service
                              :since (format nil "~D minutes ago" minutes)
                              :pattern pattern))

(defun goldberg-programmer-as-reader-page ()
  (ignore-errors
    (hb:find-page *hyperdoc*
                  "Goldberg Programmer as Reader"
                  :signal-error? t)))

(defun hyperbook-exported-call (symbol-name &rest args)
  (when-let (symbol (find-symbol symbol-name :hyperbook))
    (when (fboundp symbol)
      (apply (symbol-function symbol) args))))

(defun page-lookup-issue-field (issue symbol-name)
  (and issue
       (hyperbook-exported-call symbol-name issue)))

(defun goldberg-page-lookup-issue (&optional (expected-page-id "Program read bug"))
  (when-let (page (goldberg-programmer-as-reader-page))
    (find expected-page-id
          (or (hyperbook-exported-call "LOOKUP-ISSUES-OF" page)
              nil)
          :test #'string=
          :key (lambda (issue)
                 (page-lookup-issue-field
                  issue
                  "LOOKUP-ISSUE-EXPECTED-PAGE-ID-OF")))))

(defun page-lookup-issue-summary-string (issue)
  (if issue
      (format nil "~A -> ~A / ~A"
              (or (page-lookup-issue-field
                   issue
                   "LOOKUP-ISSUE-SOURCE-PAGE-TITLE-OF")
                  (page-lookup-issue-field
                   issue
                   "LOOKUP-ISSUE-SOURCE-PAGE-ID-OF")
                  "unknown source")
              (or (page-lookup-issue-field
                   issue
                   "LOOKUP-ISSUE-TARGET-HYPERBOOK-ID-OF")
                  "unknown target hyperbook")
              (or (page-lookup-issue-field
                   issue
                   "LOOKUP-ISSUE-EXPECTED-PAGE-ID-OF")
                  (page-lookup-issue-field
                   issue
                   "LOOKUP-ISSUE-LINK-TEXT-OF")
                  "unknown page"))
      "No page-lookup-issue object was available in the current image."))

(defun goldberg-question-answer
    (number question answer &key evidence related-objects recovery-action)
  (make-instance 'goldberg-incident-question-answer
                 :number number
                 :question question
                 :answer answer
                 :evidence evidence
                 :related-objects related-objects
                 :recovery-action recovery-action))

(defun goldberg-question (number)
  (nth (1- number) *goldberg-reading-comprehension-questions*))

(defun goldberg-disconnection-question-answers (&key incident issue log-query)
  (let ((related (remove nil (list incident issue log-query))))
    (list
     (goldberg-question-answer
      1
      (goldberg-question 1)
      "Open the Goldberg Programmer as Reader page, then inspect the page-lookup-issue object created by a missing Topics link."
      :evidence (list "Observed page: Goldberg Programmer as Reader"
                      "Observed object kind: page-lookup-issue")
      :related-objects related)
     (goldberg-question-answer
      2
      (goldberg-question 2)
      "Inspect the issue, inspect the service log query, then reload the browser only if the old CLOG connection was already closed."
      :evidence (list "The fix keeps the page-lookup issue render path inside the split topic-source model.")
      :related-objects related
      :recovery-action "Reload an already-disconnected browser; new issue views should render without the stale topics.lisp error.")
     (goldberg-question-answer
      3
      (goldberg-question 3)
      "The page-lookup repair function needs a current source-signature table built from the split hyperdoc/topics/*.lisp files."
      :evidence (list "page-lookup-topic-source-signature-table"
                      "page-lookup-topic-source-paths")
      :related-objects related)
     (goldberg-question-answer
      4
      (goldberg-question 4)
      "The failing object is a page-lookup-issue for a missing Topics page, not a missing Goldberg ASDF package or a publication failure."
      :evidence (list (page-lookup-issue-summary-string issue))
      :related-objects related)
     (goldberg-question-answer
      5
      (goldberg-question 5)
      "The stale read happened in HyperDoc's page-lookup chunk repair source scanner."
      :evidence (list "hyperdoc/page-lookup-chunks.lisp"
                      "formerly: hyperdoc/topics.lisp")
      :related-objects related)
     (goldberg-question-answer
      6
      (goldberg-question 6)
      "Yes. The Topics registry and page-lookup repair chunk model already know how to classify and repair missing topic pages."
      :evidence (list "hyperdoc/topics/registry.lisp"
                      "hyperdoc/page-lookup-chunks.lisp"
                      "hyperdoc-explorer/lookup-repairs.lisp")
      :related-objects related)
     (goldberg-question-answer
      7
      (goldberg-question 7)
      "The page-lookup issue views, lookup repair router, and topic registry together know the target hyperbook, expected page, status, and repair route."
      :evidence (list "hyperbook-explorer/lookup-failures.lisp"
                      "hyperdoc-explorer/lookup-repairs.lisp"
                      "hyperdoc/topics/registry.lisp")
      :related-objects related)
     (goldberg-question-answer
      8
      (goldberg-question 8)
      "The Goldberg page added Topics links before those Goldberg topic objects were registered into the main HyperDoc topics hyperbook, producing page-lookup issues. Opening the issue then hit the stale monolithic topic-source path."
      :evidence (list "Goldberg page topic links"
                      "page-lookup-issue Overview render"
                      "split topic source directory")
      :related-objects related)
     (goldberg-question-answer
      9
      (goldberg-question 9)
      "Use the browser reload path if the socket was already closed, then reopen the page-lookup issue; the issue should now render instead of disconnecting."
      :evidence (list "Browser banner reported a closed HyperDoc connection.")
      :related-objects related
      :recovery-action "Reload browser and re-open the lookup issue.")
     (goldberg-question-answer
      10
      (goldberg-question 10)
      "The current system has an inspectable missing-topic issue and an inspectable log-query object; the topic scanner now reads the split source tree."
      :evidence (list "nixos-service-log-query"
                      "hyperdoc-runtime-incident")
      :related-objects related)
     (goldberg-question-answer
      11
      (goldberg-question 11)
      "It happened because the lookup-issue Overview computed repair status by opening a deleted source path."
      :evidence (list "FILE-DOES-NOT-EXIST for hyperdoc/topics.lisp"
                      "page-lookup-topic-source-signature-table")
      :related-objects related)
     (goldberg-question-answer
      12
      (goldberg-question 12)
      "The page did not recover in place because the unhandled view-render condition escaped through the CLOG event path and closed the browser connection."
      :evidence (list "No local server process crash was reproduced; the failing pane render signaled an uncaught condition.")
      :related-objects related))))

(defun make-hyperdoc-page-lookup-disconnect-incident
    (&key issue log-query question-answers)
  (let* ((issue (or issue (goldberg-page-lookup-issue)))
         (log-query (or log-query
                        (hyperdoc-current-service-log-query
                         :minutes 30
                         :pattern "page-lookup")))
         (incident
          (make-instance
           'hyperdoc-runtime-incident
           :id "hyperdoc/page-lookup-disconnect/goldberg"
           :title "Goldberg page-lookup issue disconnected the browser"
           :observed-at (get-universal-time)
           :symptom "Opening or interacting with a page-lookup-issue closed the CLOG browser connection."
           :page-title "Goldberg Programmer as Reader"
           :object-kind "page-lookup-issue"
           :object-summary (page-lookup-issue-summary-string issue)
           :browser-message "Disconnected from HyperDoc. Clicks will not open new panes until you reload to reconnect."
           :likely-layer "Unhandled page-lookup-issue view rendering condition in the CLOG inspector pane path."
           :related-log-query log-query
           :related-log-excerpts (subseq (nixos-service-log-query-entries-of log-query)
                                         0
                                         (min 5
                                              (length
                                               (nixos-service-log-query-entries-of
                                                log-query))))
           :recovery-actions
           '("Read split hyperdoc/topics/*.lisp sources when computing lookup-issue repair status."
             "Keep the generated topic source as the write target for placeholder topic factories."
             "Inspect service logs when available; return an unavailable log object otherwise."
             "Reload any browser tab whose CLOG connection was already closed."))))
    (setf (slot-value incident 'goldberg-question-answers)
          (or question-answers
              (goldberg-disconnection-question-answers
               :incident incident
               :issue issue
               :log-query log-query)))
    incident))

(defun hyperdoc-page-lookup-disconnect-incident ()
  (make-hyperdoc-page-lookup-disconnect-incident))

(defun page-lookup-issue-disconnection-report (&optional issue)
  (make-hyperdoc-page-lookup-disconnect-incident :issue issue))
