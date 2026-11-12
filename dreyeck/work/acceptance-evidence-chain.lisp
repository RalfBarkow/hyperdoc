;;;; One source-backed reading. No test runner, acceptance judgment, TMDM schema or planning domain.
(defpackage #:dreyeck/work/acceptance-evidence-chain
  (:use #:cl)
  (:local-nicknames (#:g #:dreyeck/git) (#:ev #:dreyeck/evaluation-record)
                    (#:snap #:dreyeck/source-snapshot) (#:v #:html-inspector-views))
  (:export #:inspect-acceptance-evidence-chain #:acceptance-evidence-chain
           #:chain-source-revision #:chain-report-file #:chain-log-file #:chain-descriptor-file
           #:chain-tested-revision #:chain-report #:chain-report-text #:chain-log-text
           #:chain-statements #:chain-log-sha256 #:chain-log-octets #:chain-blob-ids
           #:evidence-chain-refused #:refusal-reason #:refusal-source #:refusal-cause
           #:+evidence-revision+ #:+tested-revision+))
(in-package #:dreyeck/work/acceptance-evidence-chain)

(defparameter +evidence-revision+ "9176349edb473becd7423a7ca246f9bc07a75388")
(defparameter +tested-revision+ "36c69d3312ae70748ecd40a5452759fcfaad25c4")
(defparameter +report-path+ "docs/topic-maps-integration-acceptance/nix-exporter-check.json")
(defparameter +log-path+ "docs/topic-maps-integration-acceptance/nix-exporter-check.log")
(defparameter +descriptor-path+ "docs/topic-maps-integration-acceptance/candidate-build.nix")
(defparameter +authority+ "https://github.com/RalfBarkow/hyperdoc")

(define-condition evidence-chain-refused (error)
  ((reason :initarg :reason :reader refusal-reason)
   (source :initarg :source :initform nil :reader refusal-source)
   (cause :initarg :cause :initform nil :reader refusal-cause))
  (:report (lambda (condition stream)
             (format stream "Evidence reading refused: ~S" (refusal-reason condition)))))
(defun refuse (reason &optional source cause)
  (error 'evidence-chain-refused :reason reason :source source :cause cause))

(defclass acceptance-evidence-chain ()
  ((source :initarg :source :reader chain-source-revision)
   (tested :initarg :tested :reader chain-tested-revision)
   (report-file :initarg :report-file :reader chain-report-file)
   (log-file :initarg :log-file :reader chain-log-file)
   (descriptor-file :initarg :descriptor-file :reader chain-descriptor-file)
   (report :initarg :report :reader chain-report)
   (report-text :initarg :report-text :reader chain-report-text)
   (log-text :initarg :log-text :reader chain-log-text)
   (log-sha :initarg :log-sha :reader chain-log-sha256)
   (log-octets :initarg :log-octets :reader chain-log-octets)
   (blob-ids :initarg :blob-ids :reader chain-blob-ids)
   (statements :initarg :statements :reader chain-statements)
   (started :initarg :started :reader inspection-started)
   (finished :initarg :finished :reader inspection-finished))
  (:documentation "A retained reading of Git evidence, not the historical process or an acceptance record.
Reported execution fields and checked artifact properties have separate warrants. Native file/revision references are retained by EQ.
The descriptor's literal revision reference is not proof that the historical process used that exact descriptor content."))

(defun git-query (repository &rest arguments)
  ;; Keep the established no-lazy-fetch runner; also exclude local replacement-object interpretations.
  (apply #'g:git-run-string (g:git-repository-root-of repository) "--no-replace-objects" arguments))
(defun require-commit (repository revision)
  (unless (string= "commit" (g:trim-git-output
                            (git-query repository "cat-file" "-t" (g:git-commit-hash-of revision))))
    (refuse :not-a-commit revision)))
(defun read-git-blob (repository file)
  "Recover this UTF-8 blob through the existing Git reader and verify its octets against Git's blob identity.
No temporary file, checkout read, filter, source evaluation or implicit fetch. Refuse a lossy decoding round-trip."
  (let* ((spec (g:git-file-blob-spec file))
         (oid (g:trim-git-output (git-query repository "rev-parse" "--verify" spec)))
         (text (git-query repository "cat-file" "blob" spec))
         (octets (sb-ext:string-to-octets text :external-format :utf-8)))
    (unless (string= oid (snap:git-object-id "blob" octets))
      (refuse :git-text-roundtrip-changed-octets file))
    (values text octets oid)))
(defun sha256 (octets)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 octets)))
(defun text-p (value) (and (stringp value) (plusp (length value))))
(defun digest-p (value)
  (and (stringp value) (= 64 (length value)) (every (lambda (c) (digit-char-p c 16)) value)))
(defun read-report (text file expected-log-name)
  (let ((report (handler-case (shasht:read-json text t nil t)
                  (error (condition) (refuse :invalid-json file condition)))))
    (unless (and (hash-table-p report)
                 (let ((command (gethash "command" report)))
                   (and (vectorp command) (not (stringp command)) (plusp (length command))
                        (text-p (aref command 0)) (every #'stringp command)))
                 (text-p (gethash "cwd" report))
                 (hash-table-p (gethash "environmentOverrides" report))
                 (loop for key being the hash-keys of (gethash "environmentOverrides" report) using (hash-value value)
                       always (and (stringp key) (stringp value)))
                 (text-p (gethash "startedAtUTC" report)) (text-p (gethash "finishedAtUTC" report))
                 (integerp (gethash "exitCode" report))
                 (equal expected-log-name (gethash "log" report))
                 (digest-p (gethash "logSHA256" report)))
      (refuse :invalid-execution-report file))
    report))
(defun statement (predicate value warrant sources basis)
  (list :predicate predicate :value value :warrant warrant :sources sources :basis basis))

(defun %inspect-chain (repository evidence-oid tested-oid report-path log-path descriptor-path authority)
  ;; Internal parameters are used only by explicit temporary-repository tests; the public entry point fixes all sources.
  (let* ((started (get-universal-time))
         (source (g:make-git-revision-reference :repository repository :authority authority :oid evidence-oid
                                               :role :retained-acceptance-artifacts))
         (tested (g:make-git-revision-reference :repository repository :authority authority :oid tested-oid
                                               :role :specified-tested-revision))
         (report-file (g:ensure-git-evidence-file source report-path))
         (log-file (g:ensure-git-evidence-file source log-path))
         (descriptor (g:ensure-git-evidence-file source descriptor-path)))
    (handler-case
        (progn
          (require-commit repository source) (require-commit repository tested)
          (multiple-value-bind (report-text report-octets report-oid) (read-git-blob repository report-file)
            (declare (ignore report-octets))
            (multiple-value-bind (log-text log-octets log-oid) (read-git-blob repository log-file)
              (multiple-value-bind (descriptor-text descriptor-octets descriptor-oid) (read-git-blob repository descriptor)
                (declare (ignore descriptor-octets))
                (let* ((report (read-report report-text report-file (file-namestring log-path)))
                       (actual (sha256 log-octets))
                       (literal (format nil "?rev=~A\"" tested-oid)))
                  (unless (equalp actual (gethash "logSHA256" report))
                    (refuse :retained-log-sha256-mismatch log-file))
                  (unless (search literal descriptor-text)
                    (refuse :descriptor-revision-reference-absent descriptor))
                  (make-instance 'acceptance-evidence-chain
                    :source source :tested tested :report-file report-file :log-file log-file :descriptor-file descriptor
                    :report report :report-text report-text :log-text log-text :log-sha actual :log-octets (length log-octets)
                    :blob-ids (list (cons report-file report-oid) (cons log-file log-oid) (cons descriptor descriptor-oid))
                    :started started :finished (get-universal-time)
                    :statements
                    (append
                     (loop for (key predicate) in '(("command" :reported-command) ("cwd" :reported-working-directory)
                                                   ("environmentOverrides" :reported-environment-overrides)
                                                   ("startedAtUTC" :reported-started-at) ("finishedAtUTC" :reported-finished-at)
                                                   ("exitCode" :reported-exit-code))
                           collect (statement predicate (gethash key report) :reported (list report-file) (list :json-key key)))
                     (list
                      (statement :report-names-log log-file :reported (list report-file) '(:json-key "log"))
                      (statement :log-sha256-matches-report t :artifact-verified (list report-file log-file)
                                 (list :algorithm :sha256 :digest actual :octets (length log-octets)))
                      (statement :git-blob-identities-checked t :artifact-verified (list report-file log-file descriptor)
                                 '(:algorithm :git-blob-sha1 :utf-8-roundtrip :matched))
                      (statement :descriptor-contains-revision-reference tested :observed-in-source (list descriptor) (list :literal literal))
                      (statement :tested-revision-context tested :specified-context (list source descriptor)
                                 '(:public-entry-point :fixed-requested-revision :historical-execution-binding :not-established))
                      (statement :tested-commit-object-present t :artifact-verified (list tested) '(:git-object-kind :commit))))))))))
      (g:git-command-failed (condition) (refuse :git-object-read-failed source condition)))))

(defun inspect-acceptance-evidence-chain (repository)
  "Read only the fixed original Git objects. Never execute the recorded command or access its cwd/environment paths."
  (check-type repository g:git-repository-checkout)
  (%inspect-chain repository +evidence-revision+ +tested-revision+ +report-path+ +log-path+ +descriptor-path+ +authority+))

;; These generic methods describe this inspection, not the reported historical execution.
(defmethod ev:evaluation-specification-of ((chain acceptance-evidence-chain)) 'inspect-acceptance-evidence-chain)
(defmethod ev:evaluation-input-of ((chain acceptance-evidence-chain))
  (list (chain-report-file chain) (chain-log-file chain) (chain-descriptor-file chain)))
(defmethod ev:evaluation-status-of ((chain acceptance-evidence-chain)) :inspected)
(defmethod ev:evaluation-result-of ((chain acceptance-evidence-chain)) (chain-report chain))
(defmethod ev:evaluation-trace-of ((chain acceptance-evidence-chain))
  '(:fixed-commits-checked :git-blob-identities-checked :json-read :retained-log-rehashed :source-reference-observed))
(defmethod ev:evaluation-evidence-of ((chain acceptance-evidence-chain)) (chain-statements chain))
(defmethod ev:evaluation-failure-of ((chain acceptance-evidence-chain)) nil)
(defmethod ev:evaluation-started-at-of ((chain acceptance-evidence-chain)) (inspection-started chain))
(defmethod ev:evaluation-finished-at-of ((chain acceptance-evidence-chain)) (inspection-finished chain))
(defmethod ev:evaluation-identity-of ((chain acceptance-evidence-chain))
  (list :acceptance-evidence-reading-v1 (g:git-revision-identity (chain-source-revision chain))
        (loop for (file . oid) in (chain-blob-ids chain) collect (list (g:git-file-path-of file) oid))
        (g:git-revision-identity (chain-tested-revision chain))))
(defmethod ev:evaluation-annotation-of ((chain acceptance-evidence-chain))
  (declare (ignore chain))
  '(:scope :retained-artifact-inspection :historical-execution :not-reexecuted
    :historical-execution-revision-binding :not-established :acceptance-decision :none
    :independent-author-review :not-assessed :deployment-authority :none))

(defmethod v:text-representation ((chain acceptance-evidence-chain))
  (declare (ignore chain)) "One acceptance evidence chain — artifact inspection")
(v:defview chain-evidence (chain acceptance-evidence-chain)
  (v:html-view :title "Evidence chain" :priority -10
    (v:html (:h2 "Execution report, retained log and revision")
      (:p "The report describes a historical execution. This reading checks retained artifacts; it does not rerun or judge the implementation.")
      (:p (v:object-ref (chain-report-file chain) :display "Original execution report") " · "
          (v:object-ref (chain-log-file chain) :display "Original retained log") " · "
          (v:object-ref (chain-source-revision chain) :display "Fixed evidence revision"))
      (:p (v:object-ref (chain-report chain) :display "Parsed report (retained data)"))
      (:p (v:object-ref (chain-tested-revision chain) :display "Specified tested HyperDoc revision") " · "
          (v:object-ref (chain-descriptor-file chain) :display "Retained Nix reference source"))
      (:p "The JSON has no tested-revision field. The Nix source contains the specified revision reference; that is not proof that its retained contents were used by the historical process.")
      (:p "Checked log SHA-256: " (:code (v:esc (chain-log-sha256 chain)))
          " · original Git octets: " (v:esc (princ-to-string (chain-log-octets chain))))
      (:table :class "inspector-table"
        (:tr (:th "Statement") (:th "Warrant") (:th "Value") (:th "Source / basis"))
        (dolist (s (chain-statements chain))
          (v:html (:tr (:td (v:esc (string-downcase (symbol-name (getf s :predicate)))))
                      (:td (v:esc (string-downcase (symbol-name (getf s :warrant)))))
                      (:td (v:object-ref (getf s :value)))
                      (:td (dolist (source (getf s :sources)) (v:html (v:object-ref source) " "))
                           (v:object-ref (getf s :basis) :display "Basis"))))))
      (:p "Inspection status: :INSPECTED. No acceptance decision, independent-author review assertion or deployment authority."))))
(v:defview retained-report-view (chain acceptance-evidence-chain)
  (v:html-view :title "Retained report text" :priority 0
    (v:html (:pre (v:esc (chain-report-text chain))))))
(v:defview retained-log-view (chain acceptance-evidence-chain)
  (v:html-view :title "Retained log text" :priority 1
    (v:html (:pre (v:esc (chain-log-text chain))))))
(v:defview refused-reading (condition evidence-chain-refused)
  (v:html-view :title "Evidence reading refusal" :priority 0
    (v:html (:p (v:esc (princ-to-string (refusal-reason condition))))
            (:p (v:object-ref (refusal-source condition) :display "Source"))
            (:p (v:object-ref (refusal-cause condition) :display "Original condition")))))

(hyperdoc:defhyperdoc *evidence-chain-reading*
  :id "dreyeck/work/acceptance-evidence-chain" :title "One Acceptance Evidence Chain"
  :asdf-system-name "dreyeck/work/acceptance-evidence-chain"
  :subdirectory "dreyeck/pages/acceptance-evidence-chain"
  :main-page-id "Inspecting One Acceptance Evidence Chain")
