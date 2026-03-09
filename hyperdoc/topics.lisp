;;;; HyperDoc inspectable topics and DMX topic proxies
;;
;;;; Part of HyperDoc
;;;; See LICENSE for licensing information.

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

(defun dmx-topicmap-webclient-url (page)
  (let ((book (hb:hyperbook-of page)))
    (format nil "~A/systems.dmx.webclient/#/topicmap/~D/topic/~D"
            (dmx-base-url-of book)
            (dmx-topicmap-id-of page)
            (dmx-topicmap-id-of page))))

(defun dmx-webclient-url (page)
  (dmx-topicmap-webclient-url page))

(defun dmx-core-topic-endpoint (id)
  (format nil "/core/topic/~D" id))

(defun dmx-children+assoc-parameters ()
  '(("children" . "true")
    ("assocChildren" . "true")))

(defun dmx-related-topics-parameters ()
  '(("children" . "false")
    ("assocChildren" . "false")))

(defun fetch-dmx-core-topic-data (book id)
  (dmx-fetch-json book
                  (dmx-core-topic-endpoint id)
                  :parameters (dmx-children+assoc-parameters)))

(defun fetch-dmx-related-topics-data (book topic-id)
  (dmx-fetch-json book
                  (format nil "/core/topic/~D/related-topics" topic-id)
                  :parameters (dmx-related-topics-parameters)))

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
       (fetch-dmx-core-topic-data book topic-id)))))

(defun fetch-dmx-related-topics (page)
  (let* ((book (hb:hyperbook-of page))
         (topic-id (dmx-topic-id-of page))
         (key (dmx-cache-key :related topic-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (fetch-dmx-related-topics-data book topic-id)))))

(defun fetch-dmx-topicmap-data (page)
  (let* ((book (hb:hyperbook-of page))
         (topicmap-id (dmx-topicmap-id-of page))
         (key (dmx-cache-key :topicmap topicmap-id)))
    (dmx-cache-fetch
     book key
     (lambda ()
       (fetch-dmx-core-topic-data book topicmap-id)))))

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

;; Inspectable topic objects used by expr links and the Topics hyperbook.
(defclass topic ()
  ((id :accessor id-of :initarg :id)
   (title :accessor title-of :initarg :title)
   (summary :accessor summary-of :initarg :summary)
   ;; Optional editorial metadata. Internal page associations are derived from
   ;; authored page links plus backlink lookup, not primarily from this slot.
   (references :accessor references-of :initarg :references :initform nil)))

(defclass topics-hyperbook (hb:hyperbook) ())

(defclass topic-page (hb:page)
  ((topic :reader topic-of :initarg :topic :type topic)))

(defvar *topics* (make-instance 'topics-hyperbook :id "topics"))
(defvar *topics-by-id* (make-hash-table :test #'equal))
(defvar *topics-by-title* (make-hash-table :test #'equal))
(defvar *topic-index-state* :stale)
(defvar *topic-authoring-factories* (make-hash-table :test #'eq))
(defparameter *legacy-topic-constructor-symbols*
  '(concept-operational-definition
    topic-map-operational-definition
    dmx-topic-operational-definition
    dmx-topic-912138
    dmx-topic-912384))

(defmethod title-of ((hb topics-hyperbook))
  "Topics")

(eval-when (:load-toplevel)
  (register *topics*))

(defun %register-topic (topic)
  (setf (gethash (id-of topic) *topics-by-id*) topic)
  (setf (gethash (title-of topic) *topics-by-title*) topic)
  topic)

(defun make-topic (&key id title summary references)
  (let ((topic (or (gethash id *topics-by-id*)
                   (gethash title *topics-by-title*)
                   (make-instance 'topic
                                  :id id
                                  :title title
                                  :summary summary
                                  :references references))))
    (setf (id-of topic) id
          (title-of topic) title
          (summary-of topic) summary
          (references-of topic) references)
    (%register-topic topic)))

(defparameter *topic-proxy-mapping*
  '((concept-operational-definition :topic-id 912384 :topicmap-id 912102)
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
    (dmx-topic-912384 :topic-id 912384 :topicmap-id 912102 :label "Explicit DMX topic mapping")))

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

(defun string-suffix-p (suffix string)
  (let ((suffix-length (length suffix))
        (string-length (length string)))
    (and (<= suffix-length string-length)
         (string= suffix
                  string
                  :start1 0
                  :start2 (- string-length suffix-length)))))

(defun topic-constructor-symbol-p (symbol)
  (and (symbolp symbol)
       (fboundp symbol)
       (not (macro-function symbol))
       (or (member symbol *legacy-topic-constructor-symbols*)
           (and (not (eq symbol 'make-topic))
                (string-suffix-p "-TOPIC" (symbol-name symbol))))))

(defun authored-topic-factory (symbol)
  (or (gethash symbol *topic-authoring-factories*)
      (and (fboundp symbol)
           (symbol-function symbol))))

(defun rebuild-topic-indexes ()
  (clrhash *topics-by-id*)
  (clrhash *topics-by-title*)
  (do-symbols (symbol (find-package :hyperdoc))
    (when (topic-constructor-symbol-p symbol)
      (handler-case
          (let ((topic (funcall (authored-topic-factory symbol))))
            (when (typep topic 'topic)
              (%register-topic topic)))
        (error () nil))))
  (setf *topic-index-state* :ready))

(defun ensure-topic-indexes ()
  (unless (eq *topic-index-state* :ready)
    (rebuild-topic-indexes)))

(defun find-topic-by-title (title &key signal-error?)
  (ensure-topic-indexes)
  (or (gethash title *topics-by-title*)
      (and signal-error?
           (error 'page-lookup-failure :hyperbook *topics* :page-id title))))

(defun find-topic-by-id (id &key signal-error?)
  (ensure-topic-indexes)
  (or (gethash id *topics-by-id*)
      (and signal-error?
           (error "No topic with stable key ~S" id))))

(defmethod hb:find-page ((hb topics-hyperbook) page-id &key signal-error?)
  (when-let (topic (find-topic-by-title page-id :signal-error? signal-error?))
    (make-instance 'topic-page
                   :hyperbook hb
                   :id (title-of topic)
                   :topic topic)))

(defun install-topic-proxy-wrappers ()
  (dolist (entry *topic-proxy-mapping*)
    (destructuring-bind (function-name &key topic-id topicmap-id &allow-other-keys)
        entry
      (when (and (fboundp function-name)
                 (not (gethash function-name *topic-authoring-factories*)))
        (setf (gethash function-name *topic-authoring-factories*)
              (symbol-function function-name)))
      (setf (fdefinition function-name)
            (lambda ()
              (make-dmx-topic-proxy :topic-id topic-id
                                    :topicmap-id topicmap-id)))))
  (setf *topic-index-state* :stale))

;; Core topic objects for Concepts/DMX/Topic Maps page.
(defun concept-operational-definition ()
  (make-topic
   :id "concept-operational-definition"
   :title "Concept"
   :summary "A concept is an identifiable subject with stable identity, names, occurrences, and associations."
   :references '("Operational Definition of Subject Identity"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun topic-map-operational-definition ()
  (make-topic
   :id "topic-map-operational-definition"
   :title "Topic Map"
   :summary "A topic map is a graph of topics that separates subject identity from any single document or rendering."
   :references '("Concepts, DMX Topics, and Topic Maps")))

(defun dmx-topic-operational-definition ()
  (make-topic
   :id "dmx-topic-operational-definition"
   :title "DMX Topic"
   :summary "A DMX topic is an addressable runtime topic object with type/value/association structure."
   :references '("Concepts, DMX Topics, and Topic Maps")))

(defun concepts-dmx-topics-and-topic-maps-topic ()
  (make-topic
   :id "concepts-dmx-topics-and-topic-maps"
   :title "Concepts, DMX Topics, and Topic Maps"
   :summary "Explains the relation between concepts, topic maps, and DMX topics and now provides an explicit click path into DMX-backed runtime proxy objects."
   :references '("Concept"
                 "Topic Map"
                 "DMX Topic"
                 "Demonstrating DMX Topic Proxies in HyperDoc")))

;; Topic objects for AArch64 SD-image preparation flow.
(defun prepare-aarch64-image-topic ()
  (make-topic
   :id "prepare-aarch64-image"
   :title "Prepare the AArch64 image"
   :summary "Preparation phase for obtaining and validating an aarch64 NixOS SD-image artifact before flashing."
   :references '("Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun create-sd-card-from-playground-task-topic ()
  (make-topic
   :id "create-sd-card-from-playground-task"
   :title "Create NixOS SD card from HyperDoc Playground task"
   :summary "DITA-style task for producing and flashing a Raspberry Pi NixOS SD card using runbook-aligned command plans from Playground."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Prepare the AArch64 image")))

(defun sd-card-command-plan-playground-topic ()
  (make-topic
   :id "sd-card-command-plan-playground"
   :title "SD card command plan in Playground"
   :summary "Inspectable command-plan and dry-run functions that mirror the official runbook sequence."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "SBCL Process")))

(defun sd-card-procedure-step-raw-structure-fix-topic ()
  (make-topic
   :id "sd-card-procedure-step-raw-structure-fix"
   :title "SD-card procedure-step raw-structure fix"
   :summary "Raw Structure now derives from semantic step slots via computed raw-structure, preventing NIL views when id/title/summary/commands are present."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "official-rpi-tutorial-step-raw-structure-regression-example"
                 "a735927")))

(defun semantic-navigation-visible-clickable-topic ()
  (make-topic
   :id "semantic-navigation-visible-clickable"
   :title "Semantic navigation visible and clickable"
   :summary "Primary navigation must stay semantic, visible, and clickable; raw structure is diagnostics-only and must not become the primary path."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun runbook-build-and-flash-sd-image-topic ()
  (make-topic
   :id "runbook-build-and-flash-sd-image"
   :title "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
   :summary "Operational sequence to obtain a named .img.zst artifact, decompress to .img, flash the .img, boot, and validate on Pi 4."
   :references '("Prepare the AArch64 image")))

(defun official-rpi-sd-image-tutorial-topic ()
  (make-topic
   :id "official-rpi-sd-image-tutorial"
   :title "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
   :summary "Upstream nix.dev SD-image workflow: preinstalled image, first rebuild with nixos-rebuild boot, then reboot."
   :references '("Prepare the AArch64 image")))

(defun sd-image-zstd-to-img-handoff-defect-topic ()
  (make-topic
   :id "sd-image-zstd-to-img-handoff-defect"
   :title "SD-image zstd-to-img handoff defect"
   :summary "Relation bug between official steps 1 and 2: download produces .zstd while flash requires .img; fixed by explicit decompression step, with .img.zst/.img coexistence treated as normal."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Create NixOS SD Card from HyperDoc Playground"
                 "Violated handoff"
                 "official-rpi-zstd-to-img-handoff-regression-example")))

(defun hydra-latest-filename-handoff-defect-topic ()
  (hydra-filename-loss-topic))

(defun hydra-filename-loss-topic ()
  (make-topic
   :id "hydra-filename-loss"
   :title "Hydra filename loss"
   :summary "Failure classification: naive latest/download/1 retrieval can save as file '1', losing artifact filename provenance and requiring recovery."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "SD-image zstd-to-img handoff defect"
                 "Create NixOS SD Card from HyperDoc Playground"
                 "official-rpi-hydra-filename-preservation-regression-example")))

(defun expr-string-quoting-regression-topic ()
  (make-topic
   :id "expr-string-quoting-regression"
   :title "Expr string quoting regression"
   :summary "Resolved regression where expr links with Lisp string args rendered visible labels but produced no clickable inspector refs."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "writing-pages.md"
                 "da8c815"
                 "3cf4ff4")))

(defun preflight-rpi-sd-image-checklist-topic ()
  (make-topic
   :id "preflight-rpi-sd-image-checklist"
   :title "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
   :summary "Checks before reboot to verify boot partition state, extlinux files, and partition labels."
   :references '("Prepare the AArch64 image")))

(defun two-installation-models-topic ()
  (make-topic
   :id "two-installation-models-sd-vs-classic"
   :title "Two Installation Models: SD Image vs Classic Installer"
   :summary "Distinguishes prebuilt SD-image workflow from classic installer workflow to avoid command-model drift."
   :references '("Prepare the AArch64 image")))

(defun nixos-rebuild-topic ()
  (make-topic
   :id "nixos-rebuild"
   :title "nixos-rebuild"
   :summary "Umbrella topic for rebuild operations in this SD-image workflow."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun nixos-rebuild-boot-topic ()
  (make-topic
   :id "nixos-rebuild-boot"
   :title "nixos-rebuild boot"
   :summary "Write next boot generation to /boot; preferred first rebuild in the flashed SD-image workflow."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Invariant: Boot Partition Must Be Big Enough"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun nixos-rebuild-switch-topic ()
  (make-topic
   :id "nixos-rebuild-switch"
   :title "nixos-rebuild switch"
   :summary "Activate immediately; only use later, after reboot safety is established."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images")))

(defun nixos-rebuild-test-topic ()
  (make-topic
   :id "nixos-rebuild-test"
   :title "nixos-rebuild test"
   :summary "Runtime-only activation; does not prove boot-path safety."
   :references '("Invariant: Boot Partition Must Be Big Enough"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images")))

(defun first-rebuild-before-first-reboot-topic ()
  (make-topic
   :id "first-rebuild-before-first-reboot"
   :title "First rebuild before first reboot"
   :summary "The first configuration change after flashing should be followed by nixos-rebuild boot, then reboot."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Two Installation Models: SD Image vs Classic Installer")))

(defun reboot-safety-gate-topic ()
  (make-topic
   :id "reboot-safety-gate"
   :title "Reboot safety gate"
   :summary "Pre-flight checks required before trusting the next reboot after rebuild."
   :references '("Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Invariant: Boot Partition Must Be Big Enough")))

(defun boot-partition-capacity-for-nixos-rebuild-boot-topic ()
  (make-topic
   :id "boot-partition-capacity-for-nixos-rebuild-boot"
   :title "Boot partition capacity for nixos-rebuild boot"
   :summary "nixos-rebuild boot depends on adequate /boot capacity and intact extlinux state."
   :references '("Invariant: Boot Partition Must Be Big Enough"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun sd-image-first-rebuild-model-topic ()
  (make-topic
   :id "sd-image-first-rebuild-model"
   :title "SD-image first rebuild model"
   :summary "The preinstalled-image workflow uses nixos-rebuild boot; contrast with installer workflow."
   :references '("Two Installation Models: SD Image vs Classic Installer"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun classic-installer-model-topic ()
  (make-topic
   :id "classic-installer-model"
   :title "Classic installer model"
   :summary "The /mnt installer path uses nixos-install, not nixos-rebuild boot."
   :references '("Two Installation Models: SD Image vs Classic Installer"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400")))

(defun dreyeck-supported-deployment-model-topic ()
  (make-topic
   :id "dreyeck-supported-deployment-model"
   :title "dreyeck supported deployment model"
   :summary "Verify locally, then deploy dreyeck.ch from local flake state; do not repair the server by branch checkout."
   :references '("Get hauptsache working on dreyeck.ch"
                 "Deploy dreyeck.ch from the local flake"
                 "Verify HyperDoc locally before deployment")))

(defun legacy-workspace-checkout-unit-topic ()
  (make-topic
   :id "legacy-workspace-checkout-unit"
   :title "Legacy workspace-checkout hyperdoc.service"
   :summary "Old unit model that starts HyperDoc from /home/rgb/workspace/hyperdoc/start.sh instead of packaged host deployment."
   :references '("Detect legacy workspace-checkout hyperdoc.service on dreyeck.ch"
                 "Locate and replace the legacy workspace hyperdoc.service definition")))

(defun legacy-sbcl-path-failure-topic ()
  (make-topic
   :id "legacy-sbcl-path-failure"
   :title "Legacy sbcl PATH failure"
   :summary "Legacy workspace service can fail with status 127 when start.sh calls sbcl but service PATH does not provide it."
   :references '("Diagnose sbcl command-not-found in the legacy hyperdoc.service"
                 "Detect legacy workspace-checkout hyperdoc.service on dreyeck.ch")))

(defun replace-legacy-unit-with-flake-host-profile-topic ()
  (make-topic
   :id "replace-legacy-unit-with-flake-host-profile"
   :title "Replace legacy unit with flake host profile"
   :summary "Remove workspace-checkout unit wiring and use flake-driven host deployment outputs for dreyeck.ch."
   :references '("Locate and replace the legacy workspace hyperdoc.service definition"
                 "Deploy dreyeck.ch from the local flake")))

(defun deployment-command-locality-topic ()
  (make-topic
   :id "deployment-command-locality"
   :title "Deployment command locality"
   :summary "Distinguish controller-local commands, commands executed remotely on dreyeck.ch via SSH, and public URL probes."
   :references '("Back up dreyeck.ch before deployment"
                 "Record dreyeck.ch generation before rebuild"
                 "Verify HyperDoc on dreyeck.ch"
                 "Rehearse dreyeck.ch deployment with runner")))

(defun dreyeck-backup-before-rebuild-topic ()
  (make-topic
   :id "dreyeck-backup-before-rebuild"
   :title "dreyeck backup before rebuild"
   :summary "Create timestamped backups on dreyeck.ch before any dry-activate, test, or switch activation."
   :references '("Back up dreyeck.ch before deployment"
                 "Record dreyeck.ch generation before rebuild")))

(defun dreyeck-generation-record-topic ()
  (make-topic
   :id "dreyeck-generation-record"
   :title "dreyeck generation record"
   :summary "Capture list-generations and current/booted system links before activation changes."
   :references '("Record dreyeck.ch generation before rebuild"
                 "Roll back HyperDoc on dreyeck.ch")))

(defun dreyeck-local-verification-gate-topic ()
  (make-topic
   :id "dreyeck-local-verification-gate"
   :title "dreyeck local verification gate"
   :summary "Local deployment gate using git status, nix flake check, and release-smoke before remote activation."
   :references '("Verify HyperDoc locally before deployment"
                 "Deploy dreyeck.ch from the local flake")))

(defun cautious-nixos-rebuild-activation-sequence-topic ()
  (make-topic
   :id "cautious-nixos-rebuild-activation-sequence"
   :title "Cautious nixos-rebuild activation sequence"
   :summary "Use dry-activate, then test, verify HTTP checks, and only then run switch."
   :references '("Deploy dreyeck.ch from the local flake"
                 "Verify HyperDoc on dreyeck.ch"
                 "Roll back HyperDoc on dreyeck.ch")))

(defun dreyeck-http-smoke-probes-topic ()
  (make-topic
   :id "dreyeck-http-smoke-probes"
   :title "dreyeck HTTP smoke probes"
   :summary "Post-activation checks for boot page, official tutorial page, and URL helper asset."
   :references '("Verify HyperDoc on dreyeck.ch"
                 "Deploy dreyeck.ch from the local flake")))

(defun nixos-generation-rollback-topic ()
  (make-topic
   :id "nixos-generation-rollback"
   :title "NixOS generation rollback"
   :summary "Rollback via nixos-rebuild --rollback or activate a specific system generation link."
   :references '("Roll back HyperDoc on dreyeck.ch"
                 "Deploy dreyeck.ch from the local flake")))

(defun dreyeck-runner-rehearsal-topic ()
  (make-topic
   :id "dreyeck-runner-rehearsal"
   :title "dreyeck runner rehearsal"
   :summary "Runner-driven non-destructive rehearsal path that performs backup, generation record, verify, dry-activate, test, and HTTP checks without implicit switch."
   :references '("Rehearse dreyeck.ch deployment with runner"
                 "Deploy dreyeck.ch from the local flake")))

(defun dmx-topic-912138 ()
  (make-topic
   :id "dmx-topic-912138"
   :title "DMX Topic 912138"
   :summary "External DMX topic reference for the AArch64 image preparation context."
   :references '("https://dmx.ralfbarkow.ch/systems.dmx.webclient/#/topicmap/912102/topic/912138/info")))

;; Command and artifact topics for the tutorial sequence.
(defun nix-shell-topic ()
  (make-topic
   :id "nix-shell"
   :title "nix-shell"
   :summary "Ephemeral environment launcher used to provide wget/zstd for image preparation."
   :references '("Prepare the AArch64 image")))

(defun wget-topic ()
  (make-topic
   :id "wget"
   :title "wget"
   :summary "Downloader used to fetch the selected Hydra SD-image artifact."
   :references '("Prepare the AArch64 image")))

(defun zstd-topic ()
  (make-topic
   :id "zstd"
   :title "zstd"
   :summary "Compression tool used for .img.zst artifacts."
   :references '("Prepare the AArch64 image")))

(defun unzstd-topic ()
  (make-topic
   :id "unzstd-d"
   :title "unzstd -d"
   :summary "Decompression command to convert .img.zst into a flashable .img."
   :references '("Prepare the AArch64 image")))

(defun dmesg-follow-topic ()
  (make-topic
   :id "dmesg-follow"
   :title "dmesg --follow"
   :summary "Kernel log follow mode used to observe SD-card device attach events."
   :references '("Prepare the AArch64 image")))

(defun hydra-latest-job-topic ()
  (make-topic
   :id "hydra-latest-job"
   :title "Hydra latest SD-image job"
   :summary "Hydra unstable job endpoint used to select the latest successful aarch64 SD-image build."
   :references '("https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux")))

(defun hydra-build-323111513-topic ()
  (make-topic
   :id "hydra-build-323111513"
   :title "Hydra build 323111513"
   :summary "Concrete chosen build artifact for the current preparation pass."
   :references '("https://hydra.nixos.org/build/323111513")))

(defun nixos-image-sd-card-26-05pre958232-80bdc1e5ce51-aarch64-linux-img-zst-topic ()
  (make-topic
   :id "nixos-image-sd-card-26-05pre958232-80bdc1e5ce51-aarch64-linux-img-zst"
   :title "nixos-image-sd-card-26.05pre958232.80bdc1e5ce51-aarch64-linux.img.zst"
   :summary "Concrete Hydra SD-image artifact filename selected for the current aarch64 preparation flow."
   :references '("Prepare the AArch64 image"
                 "Hydra build 323111513"
                 "https://hydra.nixos.org/build/323111513/download/1/nixos-image-sd-card-26.05pre958232.80bdc1e5ce51-aarch64-linux.img.zst")))

(defun hydra-click-path-hop-topic ()
  (make-topic
   :id "hydra-click-path-hop"
   :title "Hydra click-path hop"
   :summary "A single navigational step in the tutorial Hydra path: job page -> build page -> concrete artifact download."
   :references '("Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Hydra latest SD-image job"
                 "Hydra build 323111513"
                 "nixos-image-sd-card-26.05pre958232.80bdc1e5ce51-aarch64-linux.img.zst")))

(defun hydra-latest-download-link-topic ()
  (make-topic
   :id "hydra-latest-download-link"
   :title "Hydra latest download link"
   :summary "Stable 'latest' download-by-type link for SD-image artifacts."
   :references '("https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download-by-type/file/sd-image"
                 "https://hydra.nixos.org/job/nixos/unstable/nixos.sd_image.aarch64-linux/latest/download/1")))

(defun hydra-download-artifact-procedure-topic ()
  (make-topic
   :id "hydra-download-artifact-procedure"
   :title "Download artifact from Hydra"
   :summary "Normative successful path: download named .img.zst via wget --trust-server-names, verify it, decompress to .img, and use .img as flash input while .img.zst may remain as preserved download identity."
   :references '("Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Hydra artifact to flashable image handoff"
                 "Hydra latest SD-image job"
                 "Hydra latest download link"
                 "Hydra filename loss"
                 "hydra-filename-outcome-states-example")))

(defun hydra-artifact-to-flashable-image-handoff-topic ()
  (make-topic
   :id "hydra-artifact-to-flashable-image-handoff"
   :title "Hydra artifact to flashable image handoff"
   :summary "Decompression handoff transforms the downloaded .img.zst artifact into a flashable .img; both files may coexist afterward and only .img is flash input."
   :references '("Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "hydra-filename-outcome-states-example")))

(defun hydra-sha256-topic ()
  (make-topic
   :id "hydra-sha256"
   :title "Hydra artifact SHA-256"
   :summary "Integrity hash used to verify the downloaded .img.zst artifact before decompression and flashing."
   :references '("6c0f8bffdac01aa95e66505180d51b3557b04f3ad43cf0900376528837b62d0f")))

;; Procedure-step topics for "Prepare the AArch64 image".
(defun aarch64-procedure-select-source-topic ()
  (make-topic
   :id "aarch64-procedure-select-source"
   :title "Procedure step 1: select one source of truth"
   :summary "Choose exactly one source for the SD image artifact: official prebuilt image or project build output."
   :references '("Prepare the AArch64 image"
                 "Official Tutorial: NixOS SD Image on Raspberry Pi 4/400"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun aarch64-procedure-record-provenance-topic ()
  (make-topic
   :id "aarch64-procedure-record-provenance"
   :title "Procedure step 2: record provenance"
   :summary "Download or build the artifact and capture provenance metadata (URL/build/commit/date)."
   :references '("Prepare the AArch64 image"
                 "Hydra latest SD-image job"
                 "Hydra build 323111513")))

(defun aarch64-procedure-decompress-topic ()
  (make-topic
   :id "aarch64-procedure-decompress"
   :title "Procedure step 3: decompress image"
   :summary "Decompress the .img.zst artifact into a flashable .img using zstd/unzstd; .img.zst and .img may coexist afterward."
   :references '("Prepare the AArch64 image"
                 "zstd"
                 "unzstd -d")))

(defun aarch64-procedure-verify-integrity-topic ()
  (make-topic
   :id "aarch64-procedure-verify-integrity"
   :title "Procedure step 4: verify integrity"
   :summary "Verify downloaded artifact integrity using file size and/or SHA-256 checksum before flashing."
   :references '("Prepare the AArch64 image"
                 "Hydra artifact SHA-256")))

(defun aarch64-procedure-confirm-architecture-topic ()
  (make-topic
   :id "aarch64-procedure-confirm-architecture"
   :title "Procedure step 5: confirm architecture"
   :summary "Confirm artifact naming and target architecture include aarch64-linux."
   :references '("Prepare the AArch64 image")))

;; Journal integrity findings as inspectable topics.
(defun chronology-violation-topic ()
  (make-topic
   :id "chronology-violation"
   :title "Chronology violation"
   :summary "Journal action dates go backward, so action order is no longer monotonic."
   :references '("Journalmatic Journal Checker"
                 "Journalmatic Repair Tools"
                 "journalmatic-rectify-chronology-example")))

(defun replay-precondition-violation-topic ()
  (make-topic
   :id "replay-precondition-violation"
   :title "Replay precondition violation"
   :summary "Journal replay preconditions fail (e.g. add/edit/remove references unseen ids), so revision reconstruction can fail."
   :references '("Journalmatic Journal Checker"
                 "Journalmatic Revision Replay"
                 "journalmatic-checker-example")))

(defun journal-checker-commit-gate-topic ()
  (make-topic
   :id "journal-checker-commit-gate"
   :title "Journal checker commit gate"
   :summary "FedWiki page commits must pass creation/chronology/revision/malformed checks; syntax-only json.tool is not sufficient."
   :references '("Journalmatic Journal Checker"
                 "Journal Gate Script and Lisp Implementation"
                 "HyperBook Journal Tools"
                 "Python json.tool Source and Usage")))

(defun journal-gate-script-lisp-topic ()
  (make-topic
   :id "journal-gate-script-lisp"
   :title "Journal gate script and Lisp implementation"
   :summary "Lisp gate functions expose commit blocking for CREATION/CHRONOLOGY/REVISION/MALFORMED and provide inspectable pass/fail results."
   :references '("Journalmatic Journal Checker"
                 "Journal Gate Script and Lisp Implementation"
                 "HyperBook Journal Tools"
                 "journalmatic-commit-gate-script-example")))

(defun journal-date-origin-and-fork-chronology-topic ()
  (make-topic
   :id "journal-date-origin-and-fork-chronology"
   :title "Journal date origin and fork chronology"
   :summary "Action dates use runtime epoch millis with monotonic rule max(now, last-date + 1); avoid hardcoded timestamps to prevent fork-induced chronology errors."
   :references '("Journal Gate Script and Lisp Implementation"
                 "Journalmatic Journal Checker"
                 "journalmatic-date-origin-example")))

(defun journal-monotonic-normalization-topic ()
  (make-topic
   :id "journal-monotonic-normalization"
   :title "Journal monotonic normalization"
   :summary "Normalize journal action dates in existing action order so dates become monotonic and replay remains reconstructable."
   :references '("Journal Gate Script and Lisp Implementation"
                 "Journalmatic Repair Tools"
                 "journalmatic-monotonic-normalization-example")))

(defun fedwiki-page-generation-workflow-topic ()
  (make-topic
   :id "fedwiki-page-generation-workflow"
   :title "FedWiki page-generation workflow"
   :summary "Reproducible Lisp page generation uses deterministic story/journal construction plus wiki-client-style date assignment (max(now, last+1))."
   :references '("FedWiki Page-Generation Workflow"
                 "Journal Gate Script and Lisp Implementation"
                 "journalmatic-page-generation-workflow-example"
                 "journalmatic-page-generation-wiki-client-style-example"
                 "https://github.com/fedwiki/wiki-client/commit/d4420c72a49305ca52d18ce8203bc95bdd3f59d2")))

(defun git-blame-operation-topic ()
  (make-topic
   :id "git-blame-operation"
   :title "Git blame operation"
   :summary "Use git blame on exact file lines to prove which commit introduced timestamp behavior in wiki-client."
   :references '("FedWiki Page-Generation Workflow"
                 "wiki-client-blame-operation-example"
                 "https://github.com/fedwiki/wiki-client/commit/d4420c72a49305ca52d18ce8203bc95bdd3f59d2")))

(defun fedwiki-story-item-id-policy-topic ()
  (make-topic
   :id "fedwiki-story-item-id-policy"
   :title "FedWiki story item id policy"
   :summary "Use stable, opaque story item ids (canonical 16-hex form) in journaled pages; semantic labels belong in text, slugs, and topic ids."
   :references '("FedWiki Story Item IDs"
                 "Journalmatic Journal Checker"
                 "Python json.tool Source and Usage")))

(defun fedwiki-id-runtime-contract-topic ()
  (make-topic
   :id "fedwiki-id-runtime-contract"
   :title "FedWiki id runtime contract"
   :summary "Wiki client and server treat item ids as replay keys for add/edit/remove/move journal actions; id stability is a runtime contract."
   :references '("FedWiki Story Item IDs"
                 "Journalmatic Revision Replay"
                 "Journalmatic Journal Checker")))

(defun semantic-item-id-effects-topic ()
  (make-topic
   :id "semantic-item-id-effects"
   :title "Semantic item id effects"
   :summary "Semantic item ids can improve readability but increase coupling to wording and can raise replay breakage risk during refactors."
   :references '("FedWiki Story Item IDs"
                 "Journalmatic Repair Tools"
                 "Journalmatic Journal Checker")))

(defun fedwiki-id-normalization-map-topic ()
  (make-topic
   :id "fedwiki-id-normalization-map"
   :title "FedWiki id normalization map"
   :summary "Old-to-new story/journal id mapping artifacts preserve lookup after bulk semantic-to-opaque id normalization."
   :references '("FedWiki Story Item IDs"
                 "fedwiki-story-id-normalization-map-2026-03-06"
                 "Journalmatic Journal Checker")))

;; ASDF workflow topics for runtime loading and undefined-function triage.
(defun asdf-topic ()
  (make-topic
   :id "asdf"
   :title "ASDF"
   :summary "ASDF is the Common Lisp system definition and build facility for loading, compiling, testing, and operating on software systems."
   :references '("ASDF Components Workflow"
                 "Creating a HyperDoc")))

(defun asdf-quick-start-summary-topic ()
  (make-topic
   :id "asdf-quick-start-summary"
   :title "ASDF quick-start summary"
   :summary "The quick-start view of ASDF organizes the manual around using systems, defining systems, and extending ASDF."
   :references '("ASDF Components Workflow")))

(defun asdf-user-workflow-topic ()
  (make-topic
   :id "asdf-user-workflow"
   :title "ASDF user workflow"
   :summary "The user-facing ASDF workflow is about locating and loading existing Common Lisp systems."
   :references '("ASDF Components Workflow"
                 "HyperDoc Server")))

(defun asdf-system-definition-topic ()
  (make-topic
   :id "asdf-system-definition"
   :title "ASDF system definition"
   :summary "The author-facing ASDF workflow is about defining systems and their components with defsystem."
   :references '("ASDF Components Workflow"
                 "Creating a HyperDoc")))

(defun asdf-extension-protocol-topic ()
  (make-topic
   :id "asdf-extension-protocol"
   :title "ASDF extension protocol"
   :summary "The implementer-facing ASDF workflow is about extending ASDF's object model and operations."
   :references '("ASDF Components Workflow")))

(defun build-system-versus-package-manager-topic ()
  (make-topic
   :id "build-system-versus-package-manager"
   :title "Build system versus package manager"
   :summary "ASDF is a build/load system, not a package manager or installer."
   :references '("ASDF Components Workflow")))

(defun quicklisp-topic ()
  (make-topic
   :id "quicklisp"
   :title "Quicklisp"
   :summary "Quicklisp is the recommended package distribution and installation tool commonly used alongside ASDF."
   :references '("ASDF Components Workflow"
                 "Goals and values")))

(defun asdf-install-topic ()
  (make-topic
   :id "asdf-install"
   :title "ASDF-Install"
   :summary "ASDF-Install is an obsolete, unmaintained installer that is separate from ASDF."
   :references '("ASDF Components Workflow")))

(defun clbuild-topic ()
  (make-topic
   :id "clbuild"
   :title "clbuild"
   :summary "clbuild is a source-based Common Lisp project management tool historically used alongside ASDF."
   :references '("ASDF Components Workflow")))

(defun asdf-source-registry-topic ()
  (make-topic
   :id "asdf-source-registry"
   :title "ASDF source registry"
   :summary "The ASDF source registry determines where ASDF looks for systems on the filesystem."
   :references '("ASDF Components Workflow"
                 "HyperDoc Server")))

(defun asdf-system-topic ()
  (make-topic
   :id "asdf-system"
   :title "ASDF system"
   :summary "Top-level ASDF unit loaded via asdf:load-system; controls transitive dependencies and component graph."
   :references '("ASDF Components Workflow"
                 "Creating a HyperDoc")))

(defun asdf-component-topic ()
  (make-topic
   :id "asdf-component"
   :title "ASDF component"
   :summary "An ASDF component is a file/module/system entry in the .asd graph that must include the code you expect at runtime."
   :references '("ASDF Components Workflow"
                 "Reloading HyperDoc After Adding Lisp Objects")))

(defun asdf-module-serial-order-topic ()
  (make-topic
   :id "asdf-module-serial-order"
   :title "ASDF module serial order"
   :summary "When :serial t is used, component order defines load order and therefore definition availability."
   :references '("ASDF Components Workflow"
                 "Creating a HyperDoc")))

(defun asdf-load-system-force-topic ()
  (make-topic
   :id "asdf-load-system-force"
   :title "asdf:load-system :force t"
   :summary "Forces recompilation/reload of components to refresh a stale image when new definitions were added."
   :references '("ASDF Components Workflow"
                 "Reloading HyperDoc After Adding Lisp Objects")))

(defun asdf-find-system-topic ()
  (make-topic
   :id "asdf-find-system"
   :title "asdf:find-system"
   :summary "Resolves whether a named system is visible in the current source registry before load/operation."
   :references '("ASDF Components Workflow"
                 "HyperDoc Server")))

(defun undefined-function-triage-topic ()
  (make-topic
   :id "undefined-function-triage"
   :title "Undefined-function triage"
   :summary "Diagnostic path: verify symbol binding, verify component inclusion in .asd, then reload/restart."
   :references '("ASDF Components Workflow"
                 "Reloading HyperDoc After Adding Lisp Objects")))

(defun sbcl-process-topic ()
  (make-topic
   :id "sbcl-process"
   :title "SBCL process"
   :summary "A running SBCL image with its own package state, loaded systems, source registry, and thread-local debugger context."
   :references '("SBCL Process"
                 "ASDF Components Workflow"
                 "HyperDoc Server")))

(defun sbcl-topic ()
  (make-topic
   :id "sbcl"
   :title "SBCL"
   :summary "Steel Bank Common Lisp implementation used to run HyperDoc systems, compile components, and host server/inspector runtime behavior."
   :references '("SBCL"
                 "SBCL Process"
                 "ASDF Components Workflow"
                 "HyperDoc Server")))

(defun isolated-evaluation-workers-topic ()
  (make-topic
   :id "isolated-evaluation-workers"
   :title "Isolated evaluation workers"
   :summary "Run risky evaluation in dedicated worker processes or sandboxes only where needed, while keeping main server state stable."
   :references '("SBCL Process"
                 "Stepper Debugger Surface"
                 "HyperDoc Server")))

(defun fedwiki-content-runtime-policy-split-topic ()
  (make-topic
   :id "fedwiki-content-runtime-policy-split"
   :title "FedWiki content and runtime policy split"
   :summary "Keep page identity and content in FedWiki; keep runtime execution policy in HyperDoc/inspector tooling."
   :references '("SBCL Process"
                 "FedWiki Story Item IDs"
                 "HyperDoc Server")))

;; Topic objects for Playground/debugger runtime surfaces.
(defun playground-eval-surface-topic ()
  (make-topic
   :id "playground-eval-surface"
   :title "Playground eval surface"
   :summary "Runtime wiring for Playground eval/inspect/step/debug actions and action-thunk behavior."
   :references '("hyperdoc-inspector/playground-eval.lisp"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

(defun playground-debug-report-surface-topic ()
  (make-topic
   :id "playground-debug-report-surface"
   :title "Playground debug report surface"
   :summary "Lightweight debug report object with condition/source/backtrace and retry/abort recovery actions."
   :references '("hyperdoc-inspector/playground-debug.lisp"
                 "Playground restarts")))

(defun web-debugger-surface-topic ()
  (make-topic
   :id "web-debugger-surface"
   :title "Web debugger surface"
   :summary "Session-based web debugger registry for paused-thread debugger flow and restart invocation."
   :references '("hyperdoc-inspector/web-debugger.lisp"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

(defun playground-stepper-surface-topic ()
  (make-topic
   :id "playground-stepper-surface"
   :title "Playground stepper surface"
   :summary "Stepper model and run/step/reset operations used by the Playground execution flow."
   :references '("hyperbook-server/playground-stepper.lisp"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

(defun diagramming-debugger-surface-topic ()
  (make-topic
   :id "diagramming-debugger-surface"
   :title "Diagramming Debugger Surface"
   :summary "Playground diagramming debugger that records step events and derives collaboration/message traces."
   :references '("Diagramming Debugger Surface"
                 "Stepper Debugger Surface")))

(defun step-trace-message-events-topic ()
  (make-topic
   :id "step-trace-message-events"
   :title "Step trace message events"
   :summary "Each Playground step is captured as an event with form source, extracted call symbols, and success/error status."
   :references '("Diagramming Debugger Surface")))

(defun graphviz-sequence-export-topic ()
  (make-topic
   :id "graphviz-sequence-export"
   :title "Graphviz sequence export"
   :summary "Diagramming debugger exports Graphviz DOT text for collaboration-flow rendering."
   :references '("Diagramming Debugger Surface")))

;; Backward-compatibility alias.
(defun mermaid-sequence-export-topic ()
  (graphviz-sequence-export-topic))

(defun playground-stepper-class-layout-topic ()
  (make-topic
   :id "playground-stepper-class-layout"
   :title "Playground stepper class layout"
   :summary "Slot layout for playground-stepper state: object/package/source/forms/index/last-value/last-error/parse-report/done?."
   :references '("Diagramming Debugger Surface"
                 "Stepper Debugger Surface"
                 "hyperbook-server/playground-stepper.lisp")))

;; Topic objects for Konrad feedback thread (2026-03-05).
(defun graph-based-discovery-and-traversal-topic ()
  (make-topic
   :id "graph-based-discovery-and-traversal"
   :title "Graph-based discovery and traversal"
   :summary "HyperDoc/HyperBook usage where humans and programs discover and traverse content through graph links."
   :references '("Konrad Feedback on Communication Pages"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun hyperbook-interface-no-media-discontinuity-topic ()
  (make-topic
   :id "hyperbook-interface-no-media-discontinuity"
   :title "HyperBook interface without media discontinuity"
   :summary "The HyperBook interface keeps browsing, running, and inspecting in one medium instead of splitting prose and runtime."
   :references '("Konrad Feedback on Communication Pages"
                 "HyperDoc Server")))

(defun uniform-robot-access-topic ()
  (make-topic
   :id "uniform-robot-access"
   :title "Uniform robot access"
   :summary "Robot code can access the same graph and objects as humans, through the same interface conventions."
   :references '("Konrad Feedback on Communication Pages"
                 "Communication Surfaces Policy")))

(defun human-written-robot-code-topic ()
  (make-topic
   :id "human-written-robot-code"
   :title "Human-written robot code"
   :summary "Processing code is authored by humans and stored as first-class HyperDoc content."
   :references '("Konrad Feedback on Communication Pages")))

(defun processing-code-inside-hyperdoc-topic ()
  (make-topic
   :id "processing-code-inside-hyperdoc"
   :title "Processing code inside HyperDoc"
   :summary "Processing code should live inside HyperDoc and be browsable, runnable, and inspectable by other code."
   :references '("Konrad Feedback on Communication Pages"
                 "Stepper Debugger Surface"
                 "Playground restarts")))

(defun topic-map-work-alignment-topic ()
  (make-topic
   :id "topic-map-work-alignment"
   :title "Topic-map work alignment"
   :summary "Existing topic-map work aligns with HyperDoc's graph-centric discovery and traversal model."
   :references '("Konrad Feedback on Communication Pages"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun concept-graph-leaf-for-humans-and-robots-topic ()
  (make-topic
   :id "concept-graph-leaf-for-humans-and-robots"
   :title "Concept-graph leaf for humans and robots"
   :summary "A page is a leaf in a larger concept graph that both humans and robots can reach via search/traversal."
   :references '("Konrad Feedback on Communication Pages"
                 "Communication Surfaces Policy")))

(defun second-order-hypertext-topic ()
  (make-topic
   :id "second-order-hypertext"
   :title "Second-order hypertext"
   :summary "Hypertext where pages describe and operationalize the graph and traversal logic that produces their own context."
   :references '("Konrad Feedback on Communication Pages"
                 "Concepts, DMX Topics, and Topic Maps")))

;; Topic objects for answer-surface distinction.
(defun surface-answer-topic ()
  (make-topic
   :id "surface-answer"
   :title "Surface Answer"
   :summary "Immediate terminal/Codex response that states the current result and decisions in the active session."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun artifact-answer-topic ()
  (make-topic
   :id "artifact-answer"
   :title "Artifact Answer"
   :summary "Durable answer captured as HyperDoc/FedWiki/Lisp artifacts that can be replayed and inspected later."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun reconstruction-protocol-topic ()
  (make-topic
   :id "reconstruction-protocol"
   :title "Reconstruction protocol"
   :summary "Protocol requiring each answer to include process trace, artifact deltas, and replay checks."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun skillization-loop-topic ()
  (make-topic
   :id "skillization-loop"
   :title "Skillization loop"
   :summary "Recurring workflow extraction into callable Lisp/skill routines so repeated tasks move from ad-hoc execution to reusable runtime behavior."
   :references '("Surface and Artifact Answers"
                 "ASDF Components Workflow")))

(defun codex-resume-branch-context-topic ()
  (make-topic
   :id "codex-resume-branch-context"
   :title "Codex resume branch context"
   :summary "Codex resume exposes the related git branch per session; interpret and replay session outputs in that branch context."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy")))

(defun docs-topic-slice-and-coverage-gate-workflow-topic ()
  (make-topic
   :id "docs-topic-slice-and-coverage-gate-workflow"
   :title "Docs/topic slice and coverage-gate workflow"
   :summary "Canonical maintenance workflow: split docs/topic work into atomic commits and replay topic-coverage checks at commit boundaries."
   :references '("Canonical docs-topic split and coverage gate workflow"
                 "Surface and Artifact Answers"
                 "Reconstruction protocol")))

(defun hyperdoc-operating-environment-assessment-2026-03-06-topic ()
  (make-topic
   :id "hyperdoc-operating-environment-assessment-2026-03-06"
   :title "HyperDoc Operating Environment Assessment 2026-03-06"
   :summary "Assessment that frames HyperDoc as a documented operating environment with explicit maintenance doctrine, highlights three-surface drift risk, and recommends stronger semantic indexing and routine smoke checks."
   :references '("HyperDoc Operating Environment Assessment 2026-03-06"
                 "Communication Surfaces Policy"
                 "ASDF Components Workflow"
                 "HyperDoc Server"
                 "Stepper Debugger Surface"
                 "Diagramming Debugger Surface")))

(defun violated-handoff-topic ()
  (make-topic
   :id "violated-handoff"
   :title "Violated handoff"
   :summary "A handoff is violated when a claimed completed transfer lacks the artifacts, links, or replay checks needed for the receiver to continue without re-deriving context."
   :references '("Surface and Artifact Answers"
                 "Communication Surfaces Policy"
                 "Reconstruction protocol")))

(defun express-both-sides-of-handoff-without-manually-reversing-perspective-topic ()
  (make-topic
   :id "express-both-sides-handoff-without-manually-reversing-perspective"
   :title "Express both sides of a handoff without manually reversing perspective"
   :summary "Model a handoff as one inspectable relation object that exposes producer output and consumer precondition simultaneously, avoiding perspective-flip narration."
   :references '("Violated handoff"
                 "SD-image zstd-to-img handoff defect"
                 "Reconstruction protocol")))

(defun prose-to-object-bridge-topic ()
  (make-topic
   :id "prose-to-object-bridge"
   :title "Prose to object bridge"
   :summary "Operational claims in prose should expose clickable inspectable objects so execution and replay can start from semantic objects, not raw structure."
   :references '("Surface and Artifact Answers"
                 "Create NixOS SD Card from HyperDoc Playground"
                 "Communication Surfaces Policy")))

(defun display-argument-removal-topic ()
  (make-topic
   :id "display-argument-removal"
   :title "Remove :display argument"
   :summary "Remove explicit :display overrides and rely on each object's text representation for consistent semantic navigation labels."
   :references '("Surface and Artifact Answers"
                 "Writing text pages"
                 "Defining custom views")))

(defun semantic-object-ref-renderer-topic ()
  (make-topic
   :id "semantic-object-ref-renderer"
   :title "Semantic object-ref renderer"
   :summary "Confirmed: the SD-card command-plan renderer uses semantic object-ref links for navigation, with raw structure kept as diagnostics-only."
   :references '("Create NixOS SD Card from HyperDoc Playground"
                 "Surface and Artifact Answers"
                 "sd-card-primary-semantic-entrypoints-example")))

;; Kioskberrli hardware context topics.
(defun satechi-usbc-pro-hub-4k-hdmi-topic ()
  (make-topic
   :id "satechi-usbc-pro-hub-4k-hdmi"
   :title "Satechi USB-C Pro Hub (4K HDMI)"
   :summary "Display and peripheral adapter used in the Kioskberrli setup to provide HDMI output and hub functionality from USB-C."
   :references '("Kioskberrli"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun sd-card-topic ()
  (make-topic
   :id "sd-card"
   :title "SD card"
   :summary "Primary removable storage medium for flashing and booting kiosk images in the Kioskberrli workflow."
   :references '("Kioskberrli"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Prepare the AArch64 image")))

(defun micro-sd-card-topic ()
  (make-topic
   :id "micro-sd-card"
   :title "Micro SD card"
   :summary "Physical microSD form-factor card used by Raspberry Pi platforms for NixOS image boot media."
   :references '("Kioskberrli"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Pre-flight Checklist for Raspberry Pi NixOS SD Images")))

(defun transcend-16gb-micro-sd-card-topic ()
  (make-topic
   :id "transcend-16gb-micro-sd-card"
   :title "Transcend 16GB Micro SD Card"
   :summary "Concrete selected boot medium for the current Kioskberrli image/flash task."
   :references '("Kioskberrli"
                 "Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli")))

(defun dita-task-topic-topic ()
  (make-topic
   :id "dita-task-topic"
   :title "DITA task topic"
   :summary "Task representation style using DITA task-topic structure (context, prerequisites, steps, result) for operational runbooks."
   :references '("Prepare the AArch64 image"
                 "Runbook - Build and Flash NixOS SD Image for Kioskberrli"
                 "Surface and Artifact Answers")))

;; Topic objects for Smalltalk browser frame/scene discussion and HyperDoc adaptation.
(defun four-pane-browser-metaphor-topic ()
  (make-topic
   :id "four-pane-browser-metaphor"
   :title "Four-pane browser metaphor"
   :summary "The enduring class/category/protocol/method browser frame that preserves static code context."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun static-context-frame-topic ()
  (make-topic
   :id "static-context-frame"
   :title "Static context frame"
   :summary "A structured code frame (class/package/method neighborhood) that keeps local orientation while editing."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun dynamic-investigation-scene-topic ()
  (make-topic
   :id "dynamic-investigation-scene"
   :title "Dynamic investigation scene"
   :summary "The evolving thread across debugger, inspector, senders/implementors, playground, and decisions."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Stepper Debugger Surface")))

(defun message-flow-navigation-topic ()
  (make-topic
   :id "message-flow-navigation"
   :title "Message-flow navigation"
   :summary "Behavior understanding by following call/message flow across objects and tools rather than within one browser pane."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Stepper Debugger Surface")))

(defun ide-composition-gap-topic ()
  (make-topic
   :id "ide-composition-gap"
   :title "IDE composition gap"
   :summary "Tools coexist but do not carry context seamlessly, creating friction between powerful islands."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Communication Surfaces Policy")))

(defun investigation-thread-memory-topic ()
  (make-topic
   :id "investigation-thread-memory"
   :title "Investigation thread memory"
   :summary "Need to preserve where we came from, what we tried, and why decisions were made."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun frankenstein-tool-problem-topic ()
  (make-topic
   :id "frankenstein-tool-problem"
   :title "Frankenstein tool problem"
   :summary "Feature accretion without holistic redesign yields powerful but hard-to-master tools."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun hermit-tool-problem-topic ()
  (make-topic
   :id "hermit-tool-problem"
   :title "Hermit tool problem"
   :summary "Each tool behaves like an island; transitions lose context."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun alien-tool-problem-topic ()
  (make-topic
   :id "alien-tool-problem"
   :title "Alien tool problem"
   :summary "Image-local workflows can clash with OS conventions where mismatch is accidental rather than essential."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun saturated-environment-problem-topic ()
  (make-topic
   :id "saturated-environment-problem"
   :title "Saturated environment problem"
   :summary "Scale growth raises navigation/discoverability costs and lowers signal-to-noise."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun workspace-as-graph-topic ()
  (make-topic
   :id "workspace-as-graph"
   :title "Workspace as graph"
   :summary "Treat active work as a graph of related tools, objects, and steps rather than independent windows."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Graph-Rooted Publishing")))

(defun scene-graph-node-topic ()
  (make-topic
   :id "scene-graph-node"
   :title "Scene graph node"
   :summary "A node in the investigation scene graph: tool state, object, code location, experiment, or decision."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun scene-graph-edge-topic ()
  (make-topic
   :id "scene-graph-edge"
   :title "Scene graph edge"
   :summary "Typed relation between scene nodes (e.g. led-to, inspected, retried, rejected, superseded)."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Concepts, DMX Topics, and Topic Maps")))

(defun scene-graph-edit-cycle-topic ()
  (make-topic
   :id "scene-graph-edit-cycle"
   :title "Scene graph edit cycle"
   :summary "Operational cycle: capture step -> link to prior state -> annotate outcome -> branch or merge."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc")))

(defun hyperdoc-scene-graph-adaptation-topic ()
  (make-topic
   :id "hyperdoc-scene-graph-adaptation"
   :title "HyperDoc scene graph adaptation"
   :summary "Adapt Smalltalk IDE lessons by making navigation/debugging steps first-class inspectable graph objects in HyperDoc."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Konrad Feedback on Communication Pages")))

(defun human-written-robot-process-graphs-topic ()
  (make-topic
   :id "human-written-robot-process-graphs"
   :title "Human-written robot process graphs"
   :summary "Human-authored process graphs guide automated traversal while staying inspectable/editable by humans."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Konrad Feedback on Communication Pages")))

;; Topic objects for Ward Cunningham input on Smalltalk tooling lineage.
(defun ward-beck-diagram-1986-topic ()
  (make-topic
   :id "ward-beck-diagram-1986"
   :title "Ward/Beck diagram for object-oriented programs (1986)"
   :summary "Citation anchor: Ward Cunningham and Kent Beck, OOPSLA 1986 (Portland), frame object-collaboration diagrams as executable explanation work."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun ward-collaborating-objects-topic ()
  (make-topic
   :id "ward-collaborating-objects"
   :title "Collaborating objects diagrams"
   :summary "Ward first drew collaboration diagrams by hand in the Computer Research Lab to explain object behavior to colleagues."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun class-browser-inspector-debugger-triangulation-topic ()
  (make-topic
   :id "class-browser-inspector-debugger-triangulation"
   :title "Class browser/inspector/debugger triangulation"
   :summary "Diagram extraction combined three windows: class browser, object inspector, and single-step debugger."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Stepper Debugger Surface")))

(defun compiledmethod-interpretnextinstruction-topic ()
  (make-topic
   :id "compiledmethod-interpretnextinstruction"
   :title "CompiledMethod interpretNextInstructionFor: aContext"
   :summary "This stepping primitive exposed execution semantics; once identified, only drawing what it says remained."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun expanding-tools-literate-environment-topic ()
  (make-topic
   :id "expanding-tools-literate-environment"
   :title "Expanding the Role of Tools in a Literate Programming Environment"
   :summary "CASE'87 line of work: tools should compose around explanation, not just editing, anticipating scene-level workflow support."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "https://c2.com/doc/case87.html")))

(defun ward-diagramming-debugger-remembrance-topic ()
  (make-topic
   :id "ward-diagramming-debugger-remembrance"
   :title "Ward diagramming-debugger remembrance"
   :summary "Ward's later recollection ties diagram generation directly to debugger stepping and executable explanation."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Diagramming Debugger")))

(defun mech-op-args-emit-dispatch-topic ()
  (make-topic
   :id "mech-op-args-emit-dispatch"
   :title "Mech op/args and emit dispatch"
   :summary "Mech mirrors the same seam: split command into op/args, assemble execution context, then dispatch to blocks[op].emit."
   :references '("Smalltalk Browser Frame and Scene in HyperDoc"
                 "Mech Credible Maintenance Story")))

(defun python-json-tool-source-topic ()
  (make-topic
   :id "python-json-tool-source"
   :title "Python json.tool source"
   :summary "The json.tool CLI lives in the Python standard library module json/tool.py and can be inspected locally via json.tool.__file__."
   :references '("Python json.tool Source and Usage"
                 "https://github.com/python/cpython/blob/main/Lib/json/tool.py")))

;; Civilian resilience topics for autonomous-weapons threat environments.
(defun surviving-autonomous-weapons-environment-topic ()
  (make-topic
   :id "surviving-in-an-autonomous-weapons-environment"
   :title "Surviving in an Autonomous Weapons Environment"
   :summary "Civilian resilience baseline for preserving life, service continuity, and accountability under autonomous-threat conditions."
   :references '("Surviving in an Autonomous Weapons Environment"
                 "Autonomous Weapons Resilience Playbook"
                 "Post-Incident Recovery Under Autonomous Threat")))

(defun autonomous-weapons-resilience-playbook-topic ()
  (make-topic
   :id "autonomous-weapons-resilience-playbook"
   :title "Autonomous Weapons Resilience Playbook"
   :summary "Layered preparedness, protection, continuity, and recovery framework for civilian communities exposed to autonomous weapons risks."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Surviving in an Autonomous Weapons Environment")))

(defun post-incident-recovery-under-autonomous-threat-topic ()
  (make-topic
   :id "post-incident-recovery-under-autonomous-threat"
   :title "Post-Incident Recovery Under Autonomous Threat"
   :summary "Post-incident stabilization and recovery model centered on evidence preservation, service restoration, and institutional learning."
   :references '("Post-Incident Recovery Under Autonomous Threat"
                 "Autonomous Weapons Resilience Playbook")))

(defun autonomous-weapons-civilian-resilience-topic ()
  (make-topic
   :id "autonomous-weapons-civilian-resilience"
   :title "Autonomous-weapons civilian resilience"
   :summary "Operational view of civilian resilience capabilities required when autonomous systems compress warning and response windows."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Surviving in an Autonomous Weapons Environment")))

(defun autonomous-threat-risk-model-topic ()
  (make-topic
   :id "autonomous-threat-risk-model"
   :title "Autonomous-threat risk model"
   :summary "Risk model combining infrastructure dependency, warning reliability, and disruption impact under autonomous-threat scenarios."
   :references '("Autonomous Weapons Resilience Playbook")))

(defun protective-infrastructure-hardening-topic ()
  (make-topic
   :id "protective-infrastructure-hardening"
   :title "Protective infrastructure hardening"
   :summary "Practical hardening focus on shelters, power, communications, and medical services to reduce civilian harm."
   :references '("Autonomous Weapons Resilience Playbook")))

(defun civilian-alerting-fallback-channels-topic ()
  (make-topic
   :id "civilian-alerting-fallback-channels"
   :title "Civilian alerting fallback channels"
   :summary "Redundant alert and coordination channels used when primary communications are degraded or unavailable."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Surviving in an Autonomous Weapons Environment")))

(defun disinformation-verification-loop-topic ()
  (make-topic
   :id "disinformation-verification-loop"
   :title "Disinformation verification loop"
   :summary "Structured verification cycle for filtering false reports and preserving trusted situational awareness."
   :references '("Autonomous Weapons Resilience Playbook")))

(defun continuity-of-care-under-disruption-topic ()
  (make-topic
   :id "continuity-of-care-under-disruption"
   :title "Continuity of care under disruption"
   :summary "Medical and social-care continuity planning for prolonged disruption and contested logistics."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Post-Incident Recovery Under Autonomous Threat")))

(defun autonomous-weapons-governance-accountability-topic ()
  (make-topic
   :id "autonomous-weapons-governance-accountability"
   :title "Autonomous-weapons governance accountability"
   :summary "Governance requirement to preserve human accountability, evidence trails, and legal oversight during and after incidents."
   :references '("Autonomous Weapons Resilience Playbook"
                 "Post-Incident Recovery Under Autonomous Threat")))

(defun incident-ledger-and-evidence-topic ()
  (make-topic
   :id "incident-ledger-and-evidence"
   :title "Incident ledger and evidence"
   :summary "Structured incident ledger and chain-of-custody practices that support reliable recovery and review."
   :references '("Post-Incident Recovery Under Autonomous Threat")))

(defun service-restoration-prioritization-topic ()
  (make-topic
   :id "service-restoration-prioritization"
   :title "Service restoration prioritization"
   :summary "Prioritization model for restoring essential services under constrained resources after disruptive incidents."
   :references '("Post-Incident Recovery Under Autonomous Threat")))

(defun community-psychological-recovery-topic ()
  (make-topic
   :id "community-psychological-recovery"
   :title "Community psychological recovery"
   :summary "Community mental-health support and social-cohesion recovery operations after persistent high-stress incidents."
   :references '("Post-Incident Recovery Under Autonomous Threat")))

(defun after-action-learning-loop-topic ()
  (make-topic
   :id "after-action-learning-loop"
   :title "After-action learning loop"
   :summary "Closed-loop process for turning incident findings into revised procedures, training, and resilience improvements."
   :references '("Post-Incident Recovery Under Autonomous Threat"
                 "Autonomous Weapons Resilience Playbook")))

;; Glamorous Toolkit acquisition/install topics.
(defun gtoolkit-acquisition-modes-topic ()
  (make-topic
   :id "gtoolkit-acquisition-modes"
   :title "Glamorous Toolkit acquisition modes"
   :summary "GT can be used either from a ready-made distribution or by cloning/building from source."
   :references '("Installing Glamorous Toolkit"
                 "Acknowledgements"
                 "https://gtoolkit.com/download/"
                 "https://github.com/feenkcom/gtoolkit")))

(defun gtoolkit-ready-made-distribution-topic ()
  (make-topic
   :id "gtoolkit-ready-made-distribution"
   :title "Glamorous Toolkit ready-made distribution"
   :summary "The packaged download is the default path for using GT without building it from source."
   :references '("Installing Glamorous Toolkit"
                 "Acknowledgements"
                 "https://gtoolkit.com/download/")))

(defun gtoolkit-source-install-topic ()
  (make-topic
   :id "gtoolkit-source-install"
   :title "Glamorous Toolkit source install"
   :summary "The source-install path installs the VM, clones the GitHub repository, and builds an image; upstream says this is useful for developing GT itself."
   :references '("Installing Glamorous Toolkit"
                 "https://gtoolkit.com/download/"
                 "https://github.com/feenkcom/gtoolkit")))

(defun gtoolkit-moldable-development-topic ()
  (make-topic
   :id "gtoolkit-moldable-development"
   :title "Glamorous Toolkit as moldable development environment"
   :summary "GT is presented upstream as the Moldable Development Environment and is already acknowledged in HyperDoc as a reference platform."
   :references '("Installing Glamorous Toolkit"
                 "Acknowledgements"
                 "Design"
                 "Goals and values"
                 "https://github.com/feenkcom/gtoolkit"
                 "https://moldabledevelopment.com/")))

(defun gtoolkit-nix-installation-note-topic ()
  (make-topic
   :id "gtoolkit-nix-installation-note"
   :title "Glamorous Toolkit Nix installation note"
   :summary "The official download page defers Nix-specific usage instructions to the GT book."
   :references '("Installing Glamorous Toolkit"
                 "https://gtoolkit.com/download/"
                 "https://book.gtoolkit.com")))

(defun gtoolkit-and-hyperdoc-topic ()
  (make-topic
   :id "gtoolkit-and-hyperdoc"
   :title "Glamorous Toolkit and HyperDoc"
   :summary "Conceptual bridge page describing correspondences and distinctions between GT as a moldable environment and HyperDoc as a hypertext documentation system."
   :references '("Glamorous Toolkit and HyperDoc"
                 "Acknowledgements"
                 "Design"
                 "Goals and values"
                 "Installing Glamorous Toolkit"
                 "https://github.com/feenkcom/gtoolkit")))

(defun reference-platforms-topic ()
  (make-topic
   :id "reference-platforms"
   :title "Reference platforms"
   :summary "Reference platforms are used as conceptual anchors to compare adopted ideas, reinterpretations, and intentional omissions."
   :references '("Glamorous Toolkit and HyperDoc"
                 "Acknowledgements"
                 "Design")))

(defun moldable-development-reference-systems-topic ()
  (make-topic
   :id "moldable-development-reference-systems"
   :title "Moldable development reference systems"
   :summary "Systems used as reference points for moldable-development practices while preserving local goals, constraints, and media choices."
   :references '("Glamorous Toolkit and HyperDoc"
                 "Goals and values"
                 "https://moldabledevelopment.com/"
                 "https://github.com/feenkcom/gtoolkit")))

(defun hyperdoc-reference-systems-topic ()
  (make-topic
   :id "hyperdoc-reference-systems"
   :title "HyperDoc reference systems"
   :summary "Reference systems in HyperDoc documentation are explicit conceptual anchors used to compare, adapt, and bound design choices."
   :references '("Reference Systems in HyperDoc"
                 "Design"
                 "Goals and values"
                 "Glamorous Toolkit and HyperDoc")))

(defun reference-system-boundaries-topic ()
  (make-topic
   :id "reference-system-boundaries"
   :title "Reference system boundaries"
   :summary "Boundary statements preserve differences between systems with shared concerns, preventing accidental equivalence in architecture or workflow."
   :references '("Reference Systems in HyperDoc"
                 "Glamorous Toolkit and HyperDoc"
                 "Communication Surfaces Policy")))

(defun adopting-without-equating-topic ()
  (make-topic
   :id "adopting-without-equating"
   :title "Adopting without equating"
   :summary "HyperDoc can adopt methods from reference systems while keeping scope, medium, and ownership distinctions explicit."
   :references '("Reference Systems in HyperDoc"
                 "Glamorous Toolkit and HyperDoc"
                 "Acknowledgements")))

(defun documentation-surfaces-in-hyperdoc-topic ()
  (make-topic
   :id "documentation-surfaces-in-hyperdoc"
   :title "Documentation Surfaces in HyperDoc"
   :summary "Defines durable pages, topic objects, inspectable object handles, and FedWiki twins as distinct documentation surfaces with explicit correspondence rules."
   :references '("Documentation Surfaces in HyperDoc"
                 "Reference Systems in HyperDoc"
                 "Communication Surfaces Policy")))

(defun hyperdoc-surface-boundaries-topic ()
  (make-topic
   :id "hyperdoc-surface-boundaries"
   :title "HyperDoc surface boundaries"
   :summary "Boundary rules separating narrative pages, inspectable topic objects, embedded object handles, and parallel FedWiki artifacts."
   :references '("Documentation Surfaces in HyperDoc"
                 "Communication Surfaces Policy"
                 "Reference Systems in HyperDoc")))

(defun page-topic-twin-correspondence-topic ()
  (make-topic
   :id "page-topic-twin-correspondence"
   :title "Page/topic/twin correspondence"
   :summary "Correspondence model linking pages, topic objects, and FedWiki twins by intent and references rather than literal structural identity."
   :references '("Documentation Surfaces in HyperDoc"
                 "Communication Surfaces Policy"
                 "Glamorous Toolkit and HyperDoc")))

(defun authoring-documentation-in-hyperdoc-topic ()
  (make-topic
   :id "authoring-documentation-in-hyperdoc"
   :title "Authoring Documentation in HyperDoc"
   :summary "Operational guidance for writing documentation slices across durable pages, topic objects, inspectable handles, and optional FedWiki twins."
   :references '("Authoring Documentation in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Reference Systems in HyperDoc"
                 "Communication Surfaces Policy")))

(defun documentation-authoring-decisions-topic ()
  (make-topic
   :id "documentation-authoring-decisions"
   :title "Documentation authoring decisions"
   :summary "Decision rules for when to create pages, topics, inspectable objects, and FedWiki twins without forcing structural symmetry."
   :references '("Authoring Documentation in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Design"
                 "Goals and values")))

(defun documentation-validation-and-commit-gates-topic ()
  (make-topic
   :id "documentation-validation-and-commit-gates"
   :title "Documentation validation and commit gates"
   :summary "Validation and commit-slicing gates for documentation work, including load, topic, coverage, and FedWiki syntax/semantic checks."
   :references '("Authoring Documentation in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Communication Surfaces Policy")))

(defun documentation-architecture-in-hyperdoc-topic ()
  (make-topic
   :id "documentation-architecture-in-hyperdoc"
   :title "Documentation Architecture in HyperDoc"
   :summary "Entry-point map for the documentation architecture cluster, including scope, reading order, and relation model."
   :references '("Documentation Architecture in HyperDoc"
                 "Installing Glamorous Toolkit"
                 "Glamorous Toolkit and HyperDoc"
                 "Reference Systems in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Authoring Documentation in HyperDoc")))

(defun documentation-cluster-reading-order-topic ()
  (make-topic
   :id "documentation-cluster-reading-order"
   :title "Documentation cluster reading order"
   :summary "Recommended reading sequence from installation context to conceptual framing, surface model, and operational authoring guidance."
   :references '("Documentation Architecture in HyperDoc"
                 "Installing Glamorous Toolkit"
                 "Glamorous Toolkit and HyperDoc"
                 "Reference Systems in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Authoring Documentation in HyperDoc")))

(defun documentation-governance-topic ()
  (make-topic
   :id "documentation-governance"
   :title "Documentation governance"
   :summary "Governance model defining how durable pages, topic objects, inspectable handles, and optional FedWiki twins stay aligned without forced symmetry."
   :references '("Documentation Architecture in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Authoring Documentation in HyperDoc"
                 "Reference Systems in HyperDoc")))

(defun hyperdoc-runtime-model-topic ()
  (make-topic
   :id "hyperdoc-runtime-model"
   :title "HyperDoc runtime model"
   :summary "Shared runtime vocabulary for pages, topics, inspectable objects, and linked collaboration surfaces in HyperDoc."
   :references '("HyperDoc Runtime Model"
                 "Documentation Architecture in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Design")))

(defun hyperdoc-runtime-entities-topic ()
  (make-topic
   :id "hyperdoc-runtime-entities"
   :title "HyperDoc runtime entities"
   :summary "Core runtime entities include page objects, topic objects, inspectable links, inspector views, and linked page records."
   :references '("HyperDoc Runtime Model"
                 "Documentation Surfaces in HyperDoc"
                 "Authoring Documentation in HyperDoc"
                 "What is a moldable inspector?")))

(defun hyperdoc-runtime-boundaries-topic ()
  (make-topic
   :id "hyperdoc-runtime-boundaries"
   :title "HyperDoc runtime boundaries"
   :summary "Boundary model separating page narrative, topic semantics, inspector behavior, and FedWiki story/journal collaboration layers."
   :references '("HyperDoc Runtime Model"
                 "Reference Systems in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "FedWiki Page-Generation Workflow")))

(defun hyperdoc-routing-and-navigation-model-topic ()
  (make-topic
   :id "hyperdoc-routing-and-navigation-model"
   :title "HyperDoc routing and navigation model"
   :summary "Architectural model describing how HyperDoc resolves and opens local and remote page targets across contexts."
   :references '("HyperDoc Routing and Navigation Model"
                 "HyperDoc Runtime Model"
                 "Documentation Surfaces in HyperDoc"
                 "Design")))

(defun hyperdoc-navigation-targets-topic ()
  (make-topic
   :id "hyperdoc-navigation-targets"
   :title "HyperDoc navigation targets"
   :summary "Navigation target model distinguishing stable page keys/slugs from display titles across local and remote contexts."
   :references '("HyperDoc Routing and Navigation Model"
                 "HyperDoc Runtime Model"
                 "FedWiki Page-Generation Workflow"
                 "Documentation Surfaces in HyperDoc")))

(defun hyperdoc-routing-boundaries-topic ()
  (make-topic
   :id "hyperdoc-routing-boundaries"
   :title "HyperDoc routing boundaries"
   :summary "Boundary rules separating routing resolution, pane interaction behavior, and source-specific lookup responsibility."
   :references '("HyperDoc Routing and Navigation Model"
                 "HyperDoc Runtime Model"
                 "Documentation Surfaces in HyperDoc"
                 "Authoring Documentation in HyperDoc")))

(defun hyperdoc-evaluation-and-inspection-model-topic ()
  (make-topic
   :id "hyperdoc-evaluation-and-inspection-model"
   :title "HyperDoc evaluation and inspection model"
   :summary "Architectural model for expr evaluation, object inspection, and view rendering in HyperDoc."
   :references '("HyperDoc Evaluation and Inspection Model"
                 "HyperDoc Runtime Model"
                 "HyperDoc Routing and Navigation Model"
                 "What is a moldable inspector?")))

(defun hyperdoc-evaluation-boundaries-topic ()
  (make-topic
   :id "hyperdoc-evaluation-boundaries"
   :title "HyperDoc evaluation boundaries"
   :summary "Boundary rules separating value production, inspection behavior, page navigation, and debugging responsibility."
   :references '("HyperDoc Evaluation and Inspection Model"
                 "HyperDoc Runtime Model"
                 "Documentation Surfaces in HyperDoc"
                 "Design")))

(defun hyperdoc-view-selection-topic ()
  (make-topic
   :id "hyperdoc-view-selection"
   :title "HyperDoc view selection"
   :summary "View-selection model mapping evaluated objects to inspectable views through moldable inspector extension points."
   :references '("HyperDoc Evaluation and Inspection Model"
                 "What is a moldable inspector?"
                 "HyperDoc Runtime Model"
                 "Authoring Documentation in HyperDoc")))

(defun vom-antisemitismus-der-keiner-sein-will-topic ()
  (make-topic
   :id "vom-antisemitismus-der-keiner-sein-will"
   :title "Vom Antisemitismus, der keiner sein will"
   :summary "Source argument page reconstructing Richard Schuberth's claim that anti-Israel discourse often presents itself as something other than antisemitism."
   :references '("Vom Antisemitismus, der keiner sein will"
                 "Ein paar Widersprüche des postkolonialen Denkens"
                 "Israel als Projektionsfläche"
                 "Wer will glückliche Palästinenser?"
                 "Palästinensische Stimmen gegen Projektion und Hamas")))

(defun antisemitism-debate-topic ()
  (make-topic
   :id "antisemitism-debate"
   :title "Antisemitism debate"
   :summary "Topic for the contested argument that contemporary anti-Israel discourse can function as disavowed antisemitism."
   :references '("Vom Antisemitismus, der keiner sein will"
                 "Israel als Projektionsfläche"
                 "Temporalismus")))

(defun postcolonial-critique-topic ()
  (make-topic
   :id "postcolonial-critique"
   :title "Postcolonial critique"
   :summary "Topic for Schuberth's critique of postcolonial discourse as identity-political, antiuniversalist, and prone to projection."
   :references '("Vom Antisemitismus, der keiner sein will"
                 "Ein paar Widersprüche des postkolonialen Denkens"
                 "Temporalismus")))

(defun universalism-topic ()
  (make-topic
   :id "universalism"
   :title "Universalism"
   :summary "Topic for the conflict between universalist standards and cultural-essentializing or identity-political frameworks in Schuberth's argument."
   :references '("Vom Antisemitismus, der keiner sein will"
                 "Ein paar Widersprüche des postkolonialen Denkens")))

(defun progress-and-modernity-topic ()
  (make-topic
   :id "progress-and-modernity"
   :title "Progress and modernity"
   :summary "Topic covering Schuberth's disputed use of developmental difference, modernity, and progress against postcolonial tabooing of such distinctions."
   :references '("Temporalismus"
                 "Ein paar Widersprüche des postkolonialen Denkens"
                 "Vom Antisemitismus, der keiner sein will")))

(defun double-standard-topic ()
  (make-topic
   :id "double-standard"
   :title "Double standard"
   :summary "Topic for Schuberth's claim that Israel is judged under a different moral and political standard than other actors or regimes."
   :references '("Temporalismus"
                 "Israel als Projektionsfläche"
                 "Vom Antisemitismus, der keiner sein will")))

(defun projection-topic ()
  (make-topic
   :id "projection"
   :title "Projection"
   :summary "Topic for the claim that Israel and Palestinians are turned into symbolic surfaces for external ideological needs."
   :references '("Ein paar Widersprüche des postkolonialen Denkens"
                 "Israel als Projektionsfläche"
                 "Wer will glückliche Palästinenser?"
                 "Vom Antisemitismus, der keiner sein will")))

(defun dehumanization-topic ()
  (make-topic
   :id "dehumanization"
   :title "Dehumanization"
   :summary "Topic for the argument that symbolic victimization can erase concrete Palestinian life and subjectivity."
   :references '("Wer will glückliche Palästinenser?"
                 "Palästinensische Stimmen gegen Projektion und Hamas"
                 "Vom Antisemitismus, der keiner sein will")))

(defun palestinian-subjectivity-topic ()
  (make-topic
   :id "palestinian-subjectivity"
   :title "Palestinian subjectivity"
   :summary "Topic for the contrast between symbolic Palestinian victim-figures and concrete Palestinian persons with divergent lives and views."
   :references '("Wer will glückliche Palästinenser?"
                 "Palästinensische Stimmen gegen Projektion und Hamas")))

(defun palestinian-dissent-topic ()
  (make-topic
   :id "palestinian-dissent"
   :title "Palestinian dissent"
   :summary "Topic for examples of Palestinian voices resisting Hamas or western projection frameworks in Schuberth's reconstruction."
   :references '("Palästinensische Stimmen gegen Projektion und Hamas"
                 "Wer will glückliche Palästinenser?"
                 "Vom Antisemitismus, der keiner sein will")))

(defun time-machine-backup-setup-topic ()
  (make-topic
   :id "time-machine-backup-setup"
   :title "Time Machine backup setup"
   :summary "Operational setup path for getting a working macOS Time Machine backup to a direct disk or SMB-capable NAS target."
   :references '("Time Machine Backup Setup"
                 "Time Machine Backup Troubleshooting"
                 "Time Machine Backup Verification"
                 "Time Machine Backup on Synology NAS")))

(defun time-machine-backup-troubleshooting-topic ()
  (make-topic
   :id "time-machine-backup-troubleshooting"
   :title "Time Machine backup troubleshooting"
   :summary "Diagnostic sequence for cases where a Time Machine destination is visible but backups do not start, stall, or fail."
   :references '("Time Machine Backup Troubleshooting"
                 "Time Machine Backup Setup"
                 "Time Machine Backup Verification"
                 "Time Machine Backup on Synology NAS")))

(defun time-machine-backup-verification-topic ()
  (make-topic
   :id "time-machine-backup-verification"
   :title "Time Machine backup verification"
   :summary "Checks for confirming that a configured Time Machine destination is producing usable backups rather than only appearing configured."
   :references '("Time Machine Backup Verification"
                 "Time Machine Backup Troubleshooting"
                 "Time Machine Backup Setup")))

(defun time-machine-backup-on-synology-nas-topic ()
  (make-topic
   :id "time-machine-backup-on-synology-nas"
   :title "Time Machine backup on Synology NAS"
   :summary "Synology-specific SMB and Bonjour setup path for exposing a shared folder as a Time Machine destination for macOS."
   :references '("Time Machine Backup on Synology NAS"
                 "Time Machine Backup Setup"
                 "Time Machine Backup Troubleshooting")))

(defun topics-hyperbook-in-hyperdoc-topic ()
  (make-topic
   :id "topics-hyperbook-in-hyperdoc"
   :title "Topics HyperBook in HyperDoc"
   :summary "HyperDoc topic objects are exposed as first-class pages in the Topics hyperbook, with internal topic-to-page relations derived from backlinks."
   :references '("Topics HyperBook in HyperDoc"
                 "Documentation Surfaces in HyperDoc"
                 "Authoring Documentation in HyperDoc"
                 "Documentation Architecture in HyperDoc")))

(defun demonstrating-dmx-topic-proxies-in-hyperdoc-topic ()
  (make-topic
   :id "demonstrating-dmx-topic-proxies-in-hyperdoc"
   :title "Demonstrating DMX Topic Proxies in HyperDoc"
   :summary "Clickable walkthrough showing how authored topic pages in HyperBook topics differ from live DMX-backed runtime proxy objects in the inspector."
   :references '("Concepts, DMX Topics, and Topic Maps"
                 "Topics HyperBook in HyperDoc"
                 "Documentation Surfaces in HyperDoc")))

(defun topic-backlinks-model-topic ()
  (make-topic
   :id "topic-backlinks-model"
   :title "Topic backlinks model"
   :summary "Authored page-to-topic links in HyperDoc generate automatic topic-to-page backlinks through the existing HyperBook link extraction and backlink machinery."
   :references '("Topics HyperBook in HyperDoc"
                 "HyperDoc Routing and Navigation Model"
                 "Documentation Surfaces in HyperDoc")))

(defun topic-editorial-references-topic ()
  (make-topic
   :id "topic-editorial-references"
   :title "Topic editorial references"
   :summary "Optional editorial references on topic objects remain reader-visible curated context and are distinct from automatically derived backlinks."
   :references '("Topics HyperBook in HyperDoc"
                 "Editorial References in Topic Pages"
                 "Authoring Documentation in HyperDoc"
                 "Documentation Surfaces in HyperDoc")))

(defun topic-title-changes-and-canonical-link-maintenance-topic ()
  (make-topic
   :id "topic-title-changes-and-canonical-link-maintenance"
   :title "Topic title changes and canonical link maintenance"
   :summary "Changing a topic title is also a link migration problem because canonical topic page ids are titles and authored topic links plus backlinks depend on exact title matches."
   :references '("Topic Title Changes and Canonical Link Maintenance"
                 "Topics HyperBook in HyperDoc"
                 "HyperDoc Routing and Navigation Model")))

(defun editorial-references-in-topic-pages-topic ()
  (make-topic
   :id "editorial-references-in-topic-pages"
   :title "Editorial references in topic pages"
   :summary "Editorial references remain optional reader-visible curated context, but they are no longer the primary mechanism for internal topic-to-page association."
   :references '("Editorial References in Topic Pages"
                 "Topics HyperBook in HyperDoc"
                 "Authoring Documentation in HyperDoc"
                 "Documentation Surfaces in HyperDoc")))

(eval-when (:load-toplevel :execute)
  (install-topic-proxy-wrappers))
