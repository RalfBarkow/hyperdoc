;;;; HyperDoc inspectable topic proxies backed by DMX
;;
;;;; Copyright (c) 2026

(in-package :hyperdoc)

(defparameter *dmx-base-url* "https://dmx.ralfbarkow.ch")
(defparameter *dmx-topicmap-id* 912102)
(defparameter *dmx-default-topic-id* 912384)
(defparameter *dmx-cache-max-entries* 32)
(defparameter *dmx-cache-ttl-seconds* 120)

(define-condition dmx-proxy-error (error)
  ((url :reader dmx-error-url-of :initarg :url)
   (message :reader dmx-error-message-of :initarg :message)
   (cause :reader dmx-error-cause-of :initarg :cause))
  (:report (lambda (condition stream)
             (format stream "~A (~A)"
                     (dmx-error-message-of condition)
                     (dmx-error-url-of condition)))))

(defclass dmx-hyperbook (hb:hyperbook)
  ((base-url :reader dmx-base-url-of :type string :initarg :base-url)
   (topicmap-id :reader dmx-topicmap-id-of :type integer :initarg :topicmap-id)
   (title :reader hb:title-of :type string :initarg :title)
   (main-page-id :reader hb:main-page-id-of :type string :initarg :main-page-id)
   (pages :reader dmx-pages-of :type hash-table
          :initform (make-hash-table :test #'eql))
   (cache :reader dmx-cache-of :type hash-table
          :initform (make-hash-table :test #'equal))
   (cache-order :accessor dmx-cache-order-of :type list :initform nil)))

(defclass dmx-topic-proxy (hb:page)
  ((topic-id :reader dmx-topic-id-of :type integer :initarg :topic-id)
   (topicmap-id :reader dmx-topicmap-id-of :type integer :initarg :topicmap-id)
   (topic-data :accessor dmx-topic-data-of :initform nil)
   (topicmap-data :accessor dmx-topicmap-data-of :initform nil)
   (related-topics :accessor dmx-related-topics-of :initform nil)
   (load-error :accessor dmx-load-error-of :initform nil)))

(defmethod hb:title-of ((page dmx-topic-proxy))
  (or (and (dmx-topic-data-of page)
           (gethash "value" (dmx-topic-data-of page)))
      (format nil "DMX Topic ~D" (dmx-topic-id-of page))))

(defmethod hb:path-item-of ((page dmx-topic-proxy))
  (format nil "topic-~D" (dmx-topic-id-of page)))

(defvar *dmx-hyperbooks* (make-hash-table :test #'equal))

(defun dmx-webclient-url (page)
  (let ((book (hb:hyperbook-of page)))
    (format nil "~A/systems.dmx.webclient/#/topicmap/~D/topic/~D"
            (dmx-base-url-of book)
            (dmx-topicmap-id-of page)
            (dmx-topic-id-of page))))

(defun parse-positive-integer (designator)
  (labels ((parse-from-string (string)
             (let ((start (position-if #'digit-char-p string)))
               (when start
                 (let ((end (or (position-if-not #'digit-char-p
                                                 string
                                                 :start start)
                                (length string))))
                   (handler-case
                       (let ((value (parse-integer string
                                                   :start start
                                                   :end end)))
                         (and (plusp value) value))
                     (error () nil)))))))
    (cond
      ((integerp designator)
       (and (plusp designator) designator))
      ((stringp designator)
       (parse-from-string designator))
      ((symbolp designator)
       (parse-from-string (symbol-name designator)))
      (t
       nil))))

(defun parse-id-from-dmx-topic-symbol (symbol)
  (let* ((name (string-downcase (symbol-name symbol)))
         (prefix "dmx-topic-"))
    (when (and (>= (length name) (length prefix))
               (string= prefix name :end2 (length prefix)))
      (let ((suffix (subseq name (length prefix))))
        (when (and (> (length suffix) 0)
                   (every #'digit-char-p suffix))
          (parse-integer suffix))))))

(defun make-dmx-hyperbook-id (topicmap-id)
  (format nil "dmx:~D" topicmap-id))

(defun ensure-dmx-hyperbook (&key
                               (base-url *dmx-base-url*)
                               (topicmap-id *dmx-topicmap-id*)
                               (main-topic-id *dmx-default-topic-id*))
  (let ((key (list base-url topicmap-id)))
    (or (gethash key *dmx-hyperbooks*)
        (let ((book (make-instance 'dmx-hyperbook
                                   :id (make-dmx-hyperbook-id topicmap-id)
                                   :base-url base-url
                                   :topicmap-id topicmap-id
                                   :title (format nil "DMX Topicmap ~D" topicmap-id)
                                   :main-page-id (format nil "~D" main-topic-id))))
          (setf (gethash key *dmx-hyperbooks*) book)
          (hb:register book)
          book))))

(defun get-dmx-hyperbook (path &optional signal-error?)
  (declare (ignore signal-error?))
  (ensure-dmx-hyperbook
   :topicmap-id (or (parse-positive-integer path)
                    *dmx-topicmap-id*)))

(hb:register-scheme :dmx #'get-dmx-hyperbook)

(defmethod hb:find-page ((book dmx-hyperbook) page-id &key signal-error?)
  (let ((topic-id (parse-positive-integer page-id)))
    (if topic-id
        (or (gethash topic-id (dmx-pages-of book))
            (let ((page (make-instance 'dmx-topic-proxy
                                       :hyperbook book
                                       :id (format nil "~D" topic-id)
                                       :topic-id topic-id
                                       :topicmap-id (dmx-topicmap-id-of book))))
              (setf (gethash topic-id (dmx-pages-of book)) page)
              page))
        (and signal-error?
             (error 'hb:page-lookup-failure
                    :hyperbook book
                    :page-id (format nil "~A" page-id))))))

(defun dmx-cache-key (kind id)
  (list kind id))

(defun dmx-touch-cache-key (book key)
  (setf (dmx-cache-order-of book)
        (cons key (remove key (dmx-cache-order-of book) :test #'equal))))

(defun dmx-trim-cache (book)
  (loop while (> (length (dmx-cache-order-of book)) *dmx-cache-max-entries*)
        do (let ((oldest (car (last (dmx-cache-order-of book)))))
             (setf (dmx-cache-order-of book)
                   (butlast (dmx-cache-order-of book)))
             (remhash oldest (dmx-cache-of book)))))

(defun dmx-cache-get (book key)
  (when-let (entry (gethash key (dmx-cache-of book)))
    (let ((timestamp (getf entry :timestamp))
          (value (getf entry :value)))
      (if (<= (- (get-universal-time) timestamp) *dmx-cache-ttl-seconds*)
          (progn
            (dmx-touch-cache-key book key)
            value)
          (progn
            (remhash key (dmx-cache-of book))
            (setf (dmx-cache-order-of book)
                  (remove key (dmx-cache-order-of book) :test #'equal))
            nil)))))

(defun dmx-cache-put (book key value)
  (setf (gethash key (dmx-cache-of book))
        (list :timestamp (get-universal-time)
              :value value))
  (dmx-touch-cache-key book key)
  (dmx-trim-cache book)
  value)

(defun dmx-cache-fetch (book key thunk)
  (or (dmx-cache-get book key)
      (dmx-cache-put book key (funcall thunk))))

(defun dmx-fetch-json (book endpoint &key parameters)
  (let* ((url (format nil "~A~A" (dmx-base-url-of book) endpoint))
         (request-args (append (list url
                                     :method :get
                                     :want-stream t)
                               (when parameters
                                 (list :parameters parameters)))))
    (handler-case
        (let ((stream (apply #'drakma:http-request request-args)))
          (unwind-protect
               (shasht:read-json stream)
            (ignore-errors (close stream))))
      (error (cause)
        (error 'dmx-proxy-error
               :url url
               :message "Failed to fetch DMX JSON"
               :cause cause)))))

(defun fetch-dmx-topic-data (page)
  (let* ((book (hb:hyperbook-of page))
         (topic-id (dmx-topic-id-of page))
         (key (dmx-cache-key :topic topic-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (dmx-fetch-json book
                       (format nil "/core/topic/~D" topic-id)
                       :parameters '(("children" . "true")
                                     ("assocChildren" . "true")))))))

(defun fetch-dmx-related-topics (page)
  (let* ((book (hb:hyperbook-of page))
         (topic-id (dmx-topic-id-of page))
         (key (dmx-cache-key :related topic-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (dmx-fetch-json book
                       (format nil "/core/topic/~D/related-topics" topic-id)
                       :parameters '(("children" . "false")
                                     ("assocChildren" . "false")))))))

(defun fetch-dmx-topicmap-data (page)
  (let* ((book (hb:hyperbook-of page))
         (topicmap-id (dmx-topicmap-id-of page))
         (key (dmx-cache-key :topicmap topicmap-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (dmx-fetch-json book
                       (format nil "/topicmaps/~D" topicmap-id)
                       :parameters '(("children" . "false")))))))

(defun ensure-dmx-topic-data (page &key force?)
  (when (or force?
            (null (dmx-topic-data-of page)))
    (handler-case
        (progn
          (setf (dmx-topic-data-of page)
                (fetch-dmx-topic-data page))
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-topic-data-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun ensure-dmx-related-topics (page &key force?)
  (when (or force?
            (null (dmx-related-topics-of page)))
    (handler-case
        (progn
          (setf (dmx-related-topics-of page)
                (fetch-dmx-related-topics page))
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-related-topics-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)

(defun ensure-dmx-topicmap-data (page &key force?)
  (when (or force?
            (null (dmx-topicmap-data-of page)))
    (handler-case
        (progn
          (setf (dmx-topicmap-data-of page)
                (fetch-dmx-topicmap-data page))
          (setf (dmx-load-error-of page) nil))
      (dmx-proxy-error (condition)
        (setf (dmx-topicmap-data-of page) nil)
        (setf (dmx-load-error-of page) condition))))
  page)


(defun make-dmx-topic-proxy (&key topic-id topicmap-id
                                   (base-url *dmx-base-url*))
  (let ((resolved-topic-id (or (parse-positive-integer topic-id)
                               (error 'unknown-dmx-topic-identifier
                                      :identifier topic-id)))
        (resolved-topicmap-id (or (parse-positive-integer topicmap-id)
                                  (error 'unknown-dmx-topic-identifier
                                         :identifier topicmap-id))))
    (hb:find-page (ensure-dmx-hyperbook :base-url base-url
                                        :topicmap-id resolved-topicmap-id)
                  resolved-topic-id
                  :signal-error? t)))

(define-condition unknown-dmx-topic-wrapper (error)
  ((function-name :reader unknown-wrapper-name-of :initarg :function-name))
  (:report (lambda (condition stream)
             (format stream "No DMX topic mapping for wrapper ~S"
                     (unknown-wrapper-name-of condition)))))

(define-condition unknown-dmx-topic-identifier (error)
  ((identifier :reader unknown-topic-identifier-of :initarg :identifier))
  (:report (lambda (condition stream)
             (format stream "Cannot resolve DMX topic from identifier ~S"
                     (unknown-topic-identifier-of condition)))))

(defparameter *topic-proxy-mapping*
  '(
    (concept-operational-definition :topic-id 912384 :topicmap-id 912102)
    (topic-map-operational-definition :topic-id 912384 :topicmap-id 912102)
    (dmx-topic-operational-definition :topic-id 912384 :topicmap-id 912102)
    (prepare-aarch64-image-topic :topic-id 912384 :topicmap-id 912102)
    (create-sd-card-from-playground-task-topic :topic-id 912384 :topicmap-id 912102)
    (sd-card-command-plan-playground-topic :topic-id 912384 :topicmap-id 912102)
    (sd-card-procedure-step-raw-structure-fix-topic :topic-id 912384 :topicmap-id 912102)
    (semantic-navigation-visible-clickable-topic :topic-id 912384 :topicmap-id 912102)
    (runbook-build-and-flash-sd-image-topic :topic-id 912384 :topicmap-id 912102)
    (official-rpi-sd-image-tutorial-topic :topic-id 912384 :topicmap-id 912102)
    (sd-image-zstd-to-img-handoff-defect-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-latest-filename-handoff-defect-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-filename-loss-topic :topic-id 912384 :topicmap-id 912102)
    (expr-string-quoting-regression-topic :topic-id 912384 :topicmap-id 912102)
    (preflight-rpi-sd-image-checklist-topic :topic-id 912384 :topicmap-id 912102)
    (two-installation-models-topic :topic-id 912384 :topicmap-id 912102)
    (dmx-topic-912138 :topic-id 912138 :topicmap-id 912102 :label "Explicit DMX topic mapping")
    (nix-shell-topic :topic-id 912384 :topicmap-id 912102)
    (wget-topic :topic-id 912384 :topicmap-id 912102)
    (zstd-topic :topic-id 912384 :topicmap-id 912102)
    (unzstd-topic :topic-id 912384 :topicmap-id 912102)
    (dmesg-follow-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-latest-job-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-build-323111513-topic :topic-id 912384 :topicmap-id 912102)
    (nixos-image-sd-card-26-05pre958232-80bdc1e5ce51-aarch64-linux-img-zst-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-click-path-hop-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-latest-download-link-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-download-artifact-procedure-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-artifact-to-flashable-image-handoff-topic :topic-id 912384 :topicmap-id 912102)
    (hydra-sha256-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-select-source-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-record-provenance-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-decompress-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-verify-integrity-topic :topic-id 912384 :topicmap-id 912102)
    (aarch64-procedure-confirm-architecture-topic :topic-id 912384 :topicmap-id 912102)
    (chronology-violation-topic :topic-id 912384 :topicmap-id 912102)
    (replay-precondition-violation-topic :topic-id 912384 :topicmap-id 912102)
    (journal-checker-commit-gate-topic :topic-id 912384 :topicmap-id 912102)
    (journal-gate-script-lisp-topic :topic-id 912384 :topicmap-id 912102)
    (journal-date-origin-and-fork-chronology-topic :topic-id 912384 :topicmap-id 912102)
    (journal-monotonic-normalization-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-page-generation-workflow-topic :topic-id 912384 :topicmap-id 912102)
    (git-blame-operation-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-story-item-id-policy-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-id-runtime-contract-topic :topic-id 912384 :topicmap-id 912102)
    (semantic-item-id-effects-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-id-normalization-map-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-system-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-component-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-module-serial-order-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-load-system-force-topic :topic-id 912384 :topicmap-id 912102)
    (asdf-find-system-topic :topic-id 912384 :topicmap-id 912102)
    (undefined-function-triage-topic :topic-id 912384 :topicmap-id 912102)
    (sbcl-process-topic :topic-id 912384 :topicmap-id 912102)
    (sbcl-topic :topic-id 912384 :topicmap-id 912102)
    (isolated-evaluation-workers-topic :topic-id 912384 :topicmap-id 912102)
    (fedwiki-content-runtime-policy-split-topic :topic-id 912384 :topicmap-id 912102)
    (playground-eval-surface-topic :topic-id 912384 :topicmap-id 912102)
    (playground-debug-report-surface-topic :topic-id 912384 :topicmap-id 912102)
    (web-debugger-surface-topic :topic-id 912384 :topicmap-id 912102)
    (playground-stepper-surface-topic :topic-id 912384 :topicmap-id 912102)
    (diagramming-debugger-surface-topic :topic-id 912384 :topicmap-id 912102)
    (playground-debugging-and-tooling-topic :topic-id 912384 :topicmap-id 912102)
    (step-trace-message-events-topic :topic-id 912384 :topicmap-id 912102)
    (graphviz-sequence-export-topic :topic-id 912384 :topicmap-id 912102)
    (mermaid-sequence-export-topic :topic-id 912384 :topicmap-id 912102)
    (playground-stepper-class-layout-topic :topic-id 912384 :topicmap-id 912102)
    (graph-based-discovery-and-traversal-topic :topic-id 912384 :topicmap-id 912102)
    (hyperbook-interface-no-media-discontinuity-topic :topic-id 912384 :topicmap-id 912102)
    (uniform-robot-access-topic :topic-id 912384 :topicmap-id 912102)
    (human-written-robot-code-topic :topic-id 912384 :topicmap-id 912102)
    (processing-code-inside-hyperdoc-topic :topic-id 912384 :topicmap-id 912102)
    (topic-map-work-alignment-topic :topic-id 912384 :topicmap-id 912102)
    (concept-graph-leaf-for-humans-and-robots-topic :topic-id 912384 :topicmap-id 912102)
    (second-order-hypertext-topic :topic-id 912384 :topicmap-id 912102)
    (surface-answer-topic :topic-id 912384 :topicmap-id 912102)
    (artifact-answer-topic :topic-id 912384 :topicmap-id 912102)
    (reconstruction-protocol-topic :topic-id 912384 :topicmap-id 912102)
    (skillization-loop-topic :topic-id 912384 :topicmap-id 912102)
    (codex-resume-branch-context-topic :topic-id 912384 :topicmap-id 912102)
    (hyperdoc-operating-environment-assessment-2026-03-06-topic :topic-id 912384 :topicmap-id 912102)
    (violated-handoff-topic :topic-id 912384 :topicmap-id 912102)
    (express-both-sides-of-handoff-without-manually-reversing-perspective-topic :topic-id 912384 :topicmap-id 912102)
    (prose-to-object-bridge-topic :topic-id 912384 :topicmap-id 912102)
    (display-argument-removal-topic :topic-id 912384 :topicmap-id 912102)
    (semantic-object-ref-renderer-topic :topic-id 912384 :topicmap-id 912102)
    (satechi-usbc-pro-hub-4k-hdmi-topic :topic-id 912384 :topicmap-id 912102)
    (sd-card-topic :topic-id 912384 :topicmap-id 912102)
    (micro-sd-card-topic :topic-id 912384 :topicmap-id 912102)
    (transcend-16gb-micro-sd-card-topic :topic-id 912384 :topicmap-id 912102)
    (dita-task-topic-topic :topic-id 912384 :topicmap-id 912102)
    (four-pane-browser-metaphor-topic :topic-id 912384 :topicmap-id 912102)
    (static-context-frame-topic :topic-id 912384 :topicmap-id 912102)
    (dynamic-investigation-scene-topic :topic-id 912384 :topicmap-id 912102)
    (message-flow-navigation-topic :topic-id 912384 :topicmap-id 912102)
    (ide-composition-gap-topic :topic-id 912384 :topicmap-id 912102)
    (investigation-thread-memory-topic :topic-id 912384 :topicmap-id 912102)
    (frankenstein-tool-problem-topic :topic-id 912384 :topicmap-id 912102)
    (hermit-tool-problem-topic :topic-id 912384 :topicmap-id 912102)
    (alien-tool-problem-topic :topic-id 912384 :topicmap-id 912102)
    (saturated-environment-problem-topic :topic-id 912384 :topicmap-id 912102)
    (workspace-as-graph-topic :topic-id 912384 :topicmap-id 912102)
    (scene-graph-node-topic :topic-id 912384 :topicmap-id 912102)
    (scene-graph-edge-topic :topic-id 912384 :topicmap-id 912102)
    (scene-graph-edit-cycle-topic :topic-id 912384 :topicmap-id 912102)
    (hyperdoc-scene-graph-adaptation-topic :topic-id 912384 :topicmap-id 912102)
    (human-written-robot-process-graphs-topic :topic-id 912384 :topicmap-id 912102)
    (ward-beck-diagram-1986-topic :topic-id 912384 :topicmap-id 912102)
    (ward-collaborating-objects-topic :topic-id 912384 :topicmap-id 912102)
    (class-browser-inspector-debugger-triangulation-topic :topic-id 912384 :topicmap-id 912102)
    (compiledmethod-interpretnextinstruction-topic :topic-id 912384 :topicmap-id 912102)
    (expanding-tools-literate-environment-topic :topic-id 912384 :topicmap-id 912102)
    (ward-diagramming-debugger-remembrance-topic :topic-id 912384 :topicmap-id 912102)
    (mech-op-args-emit-dispatch-topic :topic-id 912384 :topicmap-id 912102)
    (python-json-tool-source-topic :topic-id 912384 :topicmap-id 912102)
    (surviving-autonomous-weapons-environment-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-weapons-resilience-playbook-topic :topic-id 912384 :topicmap-id 912102)
    (post-incident-recovery-under-autonomous-threat-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-weapons-civilian-resilience-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-threat-risk-model-topic :topic-id 912384 :topicmap-id 912102)
    (protective-infrastructure-hardening-topic :topic-id 912384 :topicmap-id 912102)
    (civilian-alerting-fallback-channels-topic :topic-id 912384 :topicmap-id 912102)
    (disinformation-verification-loop-topic :topic-id 912384 :topicmap-id 912102)
    (continuity-of-care-under-disruption-topic :topic-id 912384 :topicmap-id 912102)
    (autonomous-weapons-governance-accountability-topic :topic-id 912384 :topicmap-id 912102)
    (incident-ledger-and-evidence-topic :topic-id 912384 :topicmap-id 912102)
    (service-restoration-prioritization-topic :topic-id 912384 :topicmap-id 912102)
    (community-psychological-recovery-topic :topic-id 912384 :topicmap-id 912102)
    (after-action-learning-loop-topic :topic-id 912384 :topicmap-id 912102)
    (dmx-topic-912384 :topic-id 912384 :topicmap-id 912102 :label "Explicit DMX topic mapping")
    ))

(defun lookup-topic-proxy-mapping (function-name &key signal-error?)
  (or (assoc function-name *topic-proxy-mapping*)
      (and signal-error?
           (error 'unknown-dmx-topic-wrapper
                  :function-name function-name))))

(defun mapped-topic-id (function-name)
  (let ((entry (lookup-topic-proxy-mapping function-name :signal-error? t)))
    (getf (cdr entry) :topic-id)))

(defun mapped-topicmap-id (function-name)
  (let ((entry (lookup-topic-proxy-mapping function-name :signal-error? t)))
    (getf (cdr entry) :topicmap-id)))

(defun make-mapped-topic-proxy (function-name)
  (make-dmx-topic-proxy :topic-id (mapped-topic-id function-name)
                        :topicmap-id (mapped-topicmap-id function-name)))

(defun install-topic-proxy-wrappers ()
  (dolist (entry *topic-proxy-mapping*)
    (destructuring-bind (function-name &key topic-id topicmap-id &allow-other-keys)
        entry
      (setf (fdefinition function-name)
            (lambda ()
              (make-dmx-topic-proxy :topic-id topic-id
                                    :topicmap-id topicmap-id))))))

(defun wrapper-symbol-from-designator (designator)
  (cond
    ((symbolp designator)
     designator)
    ((stringp designator)
     (nth-value 0 (find-symbol (string-upcase designator) :hyperdoc)))
    (t
     nil)))

(defun make-topic (&key id title summary references)
  (declare (ignore title summary references))
  (let* ((wrapper-symbol (wrapper-symbol-from-designator id))
         (mapping (and wrapper-symbol
                       (lookup-topic-proxy-mapping wrapper-symbol))))
    (cond
      (mapping
       (make-dmx-topic-proxy :topic-id (getf (cdr mapping) :topic-id)
                             :topicmap-id (getf (cdr mapping) :topicmap-id)))
      ((parse-positive-integer id)
       (make-dmx-topic-proxy :topic-id (parse-positive-integer id)
                             :topicmap-id *dmx-topicmap-id*))
      (t
       (error 'unknown-dmx-topic-identifier :identifier id)))))

(eval-when (:load-toplevel :execute)
  (install-topic-proxy-wrappers))
