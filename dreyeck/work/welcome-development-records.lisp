;;;; W1 data boundary. Trusted local producers supply records; no action runner.
(in-package #:dreyeck/work/welcome-development)

(define-condition invalid-development-record (error)
  ((reason :initarg :reason :reader refusal-reason))
  (:report (lambda (condition stream)
             (format stream "Invalid development records: ~S" (refusal-reason condition)))))
(defun refuse-record (reason) (error 'invalid-development-record :reason reason))

(defclass development-record ()
  ((id :initarg :id :reader record-id)
   (source :initarg :source :reader record-source)
   (data :initarg :data :reader record-data))
  (:documentation "Inspectable retained observations, with explicit :FIXTURE or :OBSERVED provenance.
Records are trusted local producer data, not authenticated statements from agents.
The state builder revalidates them; it never accepts a plan or raw state atoms."))
(defclass dev-policy (development-record) ())
(defclass dev-assignment (development-record) ())
(defclass dev-submission (development-record) ())
(defclass dev-verification (development-record) ())
(defclass dev-review (development-record) ())
(defclass integration-observation (development-record) ())
(defclass dev-domain-version (development-record) ())

(defmethod print-object ((record development-record) stream)
  (print-unreadable-object (record stream :type t)
    (format stream "~S ~S" (record-id record) (record-source record))))

(defun copy-record-data (data)
  (typecase data
    (cons (cons (copy-record-data (car data)) (copy-record-data (cdr data))))
    (string (copy-seq data)) (t data)))
(defun make-development-record (class id source &rest data)
  "Retain data without treating it as verified. DEVELOPMENT-STATE validates it.
Only explicit fixture provenance permits synthetic git/test observations."
  (unless (member class '(dev-policy dev-assignment dev-submission dev-verification
                         dev-review integration-observation dev-domain-version))
    (refuse-record :unknown-record-class))
  (make-instance class :id id :source source :data (copy-record-data data)))

(defun data (record key) (getf (record-data record) key))
(defun text-p (value) (and (stringp value) (plusp (length value))))
(defun sha-p (value &optional (length 40))
  (and (stringp value) (= length (length value))
       (every (lambda (c) (digit-char-p c 16)) value)))
(defun require-fields (record fields &optional nullable)
  (dolist (field fields)
    (unless (or (data record field)
                (and (member field nullable)
                     (loop for tail on (record-data record) by #'cddr
                           thereis (eq field (first tail)))))
      (refuse-record (list :missing-field (record-id record) field)))))
(defun actor= (a b) (equalp (string a) (string b)))

(defun observed-record-value (entry)
  ;; A successful workspace call only transports its value. :FAILED supplies no
  ;; observation, and :RETURNED NIL / arbitrary text supplies no verification.
  (typecase entry
    (development-record entry)
    (dreyeck/workspace-operation:workspace-operation-invocation
     (when (eq :returned
               (dreyeck/evaluation-record:evaluation-status-of entry))
       (let ((value (dreyeck/evaluation-record:evaluation-result-of entry)))
         (when (typep value 'development-record) value))))
    (t (refuse-record :records-required-not-planned-effects))))

(defun accepted-records (entries)
  (unless (alexandria:proper-list-p entries) (refuse-record :records-not-a-list))
  (let ((records (remove nil (mapcar #'observed-record-value entries)))
        (ids (make-hash-table :test #'equal)))
    (dolist (record records)
      (unless (and (member (type-of record) '(dev-policy dev-assignment dev-submission
                                             dev-verification dev-review integration-observation dev-domain-version))
                   (record-id record)
                   (member (record-source record) '(:fixture :observed))
                   (alexandria:proper-list-p (record-data record))
                   (evenp (length (record-data record))))
        (refuse-record :malformed-record))
      (let ((keys (loop for tail on (record-data record) by #'cddr collect (first tail))))
        (unless (and (every #'keywordp keys)
                     (= (length keys) (length (remove-duplicates keys))))
          (refuse-record :ambiguous-record-fields)))
      (when (gethash (record-id record) ids)
        (refuse-record (list :duplicate-record-id (record-id record))))
      (setf (gethash (record-id record) ids) t))
    (when (> (length (remove-duplicates (mapcar #'record-source records))) 1)
      (refuse-record :mixed-fixture-and-observed-records))
    records))

(defun assignment-for (record assignments)
  (let ((assignment (find (data record :assignment) assignments :key #'record-id :test #'equal)))
    (unless (and assignment (eq (data record :slice) (data assignment :slice)))
      (refuse-record (list :unknown-assignment (record-id record))))
    assignment))

(defun commit-implementer-p (actor record records assignments)
  (some (lambda (claim)
          (and (typep claim 'dev-submission)
               (eq (data claim :slice) (data record :slice))
               (equal (data claim :commit) (data record :commit))
               (actor= actor (data (assignment-for claim assignments) :executor))))
        records))

(defun path-in-scope-p (path globs)
  ;; W1's deliberately small path-glob contract: exact relative path or trailing
  ;; '*' prefix. No generic shell or implementation-dependent pathname globbing.
  (and (text-p path) (not (char= #\/ (char path 0)))
       (not (member ".." (uiop:split-string path :separator "/") :test #'equal))
       (some (lambda (glob)
               (if (and (plusp (length glob)) (char= #\* (char glob (1- (length glob)))))
                   (uiop:string-prefix-p (subseq glob 0 (1- (length glob))) path)
                   (equal glob path))) globs)))

(defun observe-local-development-repository (repository base commit allowed-paths)
  "Read this explicitly supplied checkout with DREYECK/GIT. No fetch or merge.
This W1-local adapter does not observe the remote dreyeck.ch HEAD or execute tests;
those shared observer/producer APIs remain absent. Never use the memoized checkout."
  (unless (typep repository 'dreyeck/git:git-repository-checkout)
    (refuse-record :explicit-repository-required))
  (unless (and (sha-p base) (sha-p commit)) (refuse-record :full-commit-identities-required))
  (let ((root (dreyeck/git:git-repository-root-of repository)))
    (unless (and (dreyeck/git:git-commit-object-present-p repository base)
                 (dreyeck/git:git-commit-object-present-p repository commit))
      (refuse-record :commit-not-observed))
    (let* ((b (dreyeck/git:make-git-commit :repository repository :commit-ish base))
           (c (dreyeck/git:make-git-commit :repository repository :commit-ish commit))
           (files (remove "" (uiop:split-string
                              (dreyeck/git:git-run-string
                               root "diff" "--no-renames" "--name-only" "-z" base commit "--")
                              :separator (string #\Null)) :test #'equal)))
      (list :repository repository :base (dreyeck/git:git-commit-hash-of b)
            :commit (dreyeck/git:git-commit-hash-of c)
            :commit-object c
            :ancestor (dreyeck/git:git-commit-ancestor-p b c)
            :files files :scope-compliant (every (lambda (p) (path-in-scope-p p allowed-paths)) files)
            :tree (dreyeck/git:trim-git-output
                   (dreyeck/git:git-run-string root "rev-parse" (concatenate 'string commit "^{tree}")))))))

(defun verification-passed-p (record assignment)
  (require-fields record '(:assignment :slice :commit :verifier :independent
                          :verdict :observed-at :repository-evidence :tests :platform
                          :network-isolation :syscall-trace))
  (when (actor= (data record :verifier) (data assignment :executor))
    (refuse-record :implementer-cannot-verify))
  (unless (eq t (data record :independent)) (refuse-record :verifier-not-independent))
  (unless (member (data record :verdict) '(:verified :rejected))
    (refuse-record :invalid-verification-verdict))
  (let* ((evidence (data record :repository-evidence))
         (commit (data record :commit))
         (tests (data record :tests)))
    (unless (and (sha-p commit) (sha-p (getf evidence :tree))
                 (equal commit (getf evidence :commit))
                 (equal (data assignment :base) (getf evidence :base)))
      (refuse-record :verification-identity-mismatch))
    (when (eq :observed (record-source record))
      ;; Reobserve local artifact identities and the full base..commit scope.
      (let ((now (observe-local-development-repository
                  (getf evidence :repository) (data assignment :base) commit
                  (data assignment :allowed-paths))))
        (dolist (key '(:base :commit :tree :files :ancestor :scope-compliant))
          (unless (equal (getf now key) (getf evidence key))
            (refuse-record :repository-observation-mismatch)))))
    (let ((passed
            (and (eq t (getf evidence :ancestor))
                 (eq t (getf evidence :scope-compliant))
                 (every (lambda (p) (path-in-scope-p p (data assignment :allowed-paths)))
                        (getf evidence :files))
                 (every
                  (lambda (required)
                    (let ((test (find (getf required :system) tests
                                      :key (lambda (x) (getf x :system)) :test #'equal)))
                      (and test (getf test :command) (eql 0 (getf test :exit-code))
                           (eq :passed (getf test :status))
                           (equal commit (getf test :commit))
                           (equal (getf evidence :tree) (getf test :tree))
                           (sha-p (getf test :log-sha256) 64)
                           (if (eq :fixture (record-source record))
                               (subsetp (getf required :markers) (getf test :markers) :test #'equal)
                               (let* ((log (getf test :log-path))
                                      (digest (and log (ironclad:byte-array-to-hex-string
                                                       (ironclad:digest-file :sha256 log))))
                                      (body (and log (uiop:read-file-string log))))
                                 (and (equal digest (getf test :log-sha256))
                                      (actor= (data record :verifier) (getf test :observer))
                                      (getf test :observed-at)
                                      (every (lambda (marker) (search marker body))
                                             (getf required :markers))))))))
                  (data assignment :required-tests)))))
      (when (and (eq :verified (data record :verdict)) (not passed))
        (refuse-record :positive-verdict-without-passing-evidence))
      (when (and (eq :rejected (data record :verdict)) passed)
        (refuse-record :negative-verdict-with-passing-evidence))
      passed)))

(defun project-development-records (entries)
  "Validate record contents and project facts, without planning or history replay.
Only DEVELOPMENT-STATE publishes a state after validating assignment history."
  (let* ((records (accepted-records entries))
         (policies (remove-if-not (lambda (r) (typep r 'dev-policy)) records))
         (assignments (remove-if-not (lambda (r) (typep r 'dev-assignment)) records))
         (policy (first policies)) (facts nil)
         (verdicts (make-hash-table :test #'equal)))
    (unless (= 1 (length policies)) (refuse-record :one-policy-required))
    (require-fields policy '(:base :attempt-limit :implementers :reviewers))
    (unless (and (sha-p (data policy :base)) (integerp (data policy :attempt-limit))
                 (plusp (data policy :attempt-limit))) (refuse-record :invalid-policy))
    (setf facts `((slice s1) (slice s2) (slice s3) (slice s4)
                  (depends-on s2 s1) (depends-on s3 s2) (depends-on s4 s3)
                  (attempt-limit ,(data policy :attempt-limit)) (observed-base ,(data policy :base))))
    (dolist (pair (data policy :implementers)) (push `(may-implement ,@pair) facts))
    (dolist (pair (data policy :reviewers)) (push `(may-review ,@pair) facts))
    (labels ((decision (kind record value)
               (let* ((key (list kind (data record :assignment) (data record :commit)))
                      (old (gethash key verdicts)))
                 (when (and old (not (eq old value)))
                   (refuse-record (list :contradictory-records key)))
                 (setf (gethash key verdicts) value))))
      (dolist (a assignments)
        (require-fields a '(:slice :executor :base :branch :allowed-paths :required-tests
                           :forbidden-actions :source-plan))
        (unless (and (member (data a :slice) '(s1 s2 s3 s4)) (sha-p (data a :base))
                     (member (list (data a :executor) (data a :slice))
                             (data policy :implementers) :test #'equal)
                     (equal (getf (data a :source-plan) :step)
                            `(!assign ,(data a :slice) ,(data a :executor) ,(data a :base)))
                     (sha-p (getf (data a :source-plan) :digest) 64))
          (refuse-record :invalid-assignment))
        (push `(assignment ,(data a :slice) ,(record-id a) ,(data a :executor) ,(data a :base)) facts))
      (dolist (s '(s1 s2 s3 s4))
        (push `(attempts ,s ,(count s assignments :key (lambda (a) (data a :slice)))) facts))
      (dolist (record records)
        (typecase record
          (dev-submission
           (let ((a (assignment-for record assignments)))
             (unless (and (sha-p (data record :commit))
                          (equal (data record :executor) (data a :executor))
                          (eq :claimed (data record :status)))
               (refuse-record :invalid-submission))
             (push `(claimed ,(data record :slice) ,(record-id a) ,(data record :commit)) facts)))
          (dev-verification
           (let ((a (assignment-for record assignments)))
             (unless (find-if (lambda (r) (and (typep r 'dev-submission)
                                               (equal (data r :assignment) (record-id a))
                                               (equal (data r :commit) (data record :commit)))) records)
               (refuse-record :verification-without-submission))
             (when (commit-implementer-p (data record :verifier) record records assignments)
               (refuse-record :implementer-cannot-verify))
             (verification-passed-p record a)
             (decision :verification record (data record :verdict))
             (push `(,(if (eq :verified (data record :verdict)) 'slice-verified 'verification-failed)
                      ,(data record :slice) ,(data record :commit) ,(record-id record)) facts)))
          (dev-review
           (let ((a (assignment-for record assignments)))
             (require-fields record '(:reviewer :commit :decision :findings :text-digest) '(:findings))
             (unless (and (sha-p (data record :commit)) (sha-p (data record :text-digest) 64)
                          (member (data record :decision) '(:accepted :rejected))
                          (member (list (data record :reviewer) (data record :slice))
                                  (data policy :reviewers) :test #'equal))
               (refuse-record :invalid-review))
             (unless (find-if (lambda (r) (and (typep r 'dev-submission)
                                               (equal (data r :assignment) (record-id a))
                                               (equal (data r :commit) (data record :commit)))) records)
               (refuse-record :review-without-submission))
             (when (and (eq :accepted (data record :decision))
                        (not (find-if (lambda (r) (and (typep r 'dev-verification)
                                                       (equal (data r :assignment) (record-id a))
                                                       (equal (data r :commit) (data record :commit))
                                                       (eq :verified (data r :verdict)))) records)))
               (refuse-record :positive-review-without-verification))
             (when (or (actor= (data a :executor) (data record :reviewer))
                       (commit-implementer-p (data record :reviewer) record records assignments))
               (refuse-record :implementer-cannot-review))
             (decision :review record (data record :decision))
             (push `(,(if (eq :accepted (data record :decision))
                          'slice-review-accepted 'slice-review-rejected)
                      ,(data record :slice) ,(data record :commit) ,(record-id record)) facts)))
          (integration-observation
           (require-fields record '(:slice :commit :head :observer :observed-at :ancestor :head-source))
           (unless (and (sha-p (data record :commit)) (sha-p (data record :head))
                        (eq t (data record :ancestor))) (refuse-record :invalid-integration))
           ;; W1 has no remote-head observer. Never accept a local HEAD as proof
           ;; of integration into dreyeck.ch. Fixtures are explicitly hypothetical.
           (unless (eq :fixture (record-source record))
             (refuse-record :remote-integration-observer-unavailable))
           (push `(slice-integrated ,(data record :slice) ,(data record :commit) ,(data record :head)) facts)))))
    ;; SHOP3 joins on slice/commit, so opposite decisions cannot be hidden behind
    ;; different assignments that happen to name that same slice and commit.
    (dolist (pair '((slice-verified verification-failed)
                    (slice-review-accepted slice-review-rejected)))
      (dolist (fact facts)
        (when (and (eq (first fact) (first pair))
                   (find-if (lambda (other) (and (eq (first other) (second pair))
                                                 (equal (subseq fact 1 3) (subseq other 1 3)))) facts))
          (refuse-record :contradictory-slice-commit))))
    (nreverse (remove-duplicates facts :test #'equal))))

(defun development-state (entries)
  "Replay the ordered record journal, checking assignments and submissions against SHOP3.
Return state, assignment validations, version table and submission checks as four values.
Projection never calls this function or the planner: there is no circular path."
  (with-development-domain-invariants
    (let ((records (accepted-records entries)) (prefix nil) (state nil) (validations nil)
          (versions (make-hash-table :test #'equal)) (submission-checks nil))
      (dolist (record records)
        (when (typep record 'dev-domain-version)
          (let ((id (data record :version-id)))
            (when (gethash id versions) (domain-refuse :duplicate-domain-version))
            (setf (gethash id versions) (admit-development-domain-version record))))
        (when (typep record 'dev-assignment)
          (unless prefix (refuse-record :one-policy-required))
          (let* ((recorded (data record :source-plan))
                 (version (binding-domain-version recorded versions))
                 (result (plan-development-state state (domain-version-domain version)))
                 (step `(!assign ,(data record :slice) ,(data record :executor) ,(data record :base)))
                 (source (record-source record))
                 (binding (plan-assignment-binding state result source step version)))
            (unless (and (equal (getf recorded :step) step)
                         (equal (getf recorded :digest) (getf binding :digest))
                         (equal (getf recorded :alternative-id) (getf binding :alternative-id))
                         (equal (getf recorded :inputs) (getf binding :inputs)))
              (refuse-record (list :assignment-plan-binding-mismatch (record-id record))))
            (push (list :assignment record :prior-records (copy-list prefix)
                        :prior-state (copy-tree state) :planning-result result :binding binding :domain-version version)
                  validations)))
        (when (typep record 'dev-submission)
          (let* ((assignment (or (find-if (lambda (r) (and (typep r 'dev-assignment)
                                                          (equal (record-id r) (data record :assignment)))) prefix)
                                 (refuse-record :submission-not-proposed)))
                 (version (binding-domain-version (data assignment :source-plan) versions))
                 (result (plan-development-state state (domain-version-domain version)))
                 (step `(!await-submission ,(data record :slice)
                                           ,(data record :assignment) ,(data record :executor))))
            (unless (member (list step) (dreyeck/shop3:plans-of result) :test #'equal)
              (refuse-record :submission-not-proposed))
            (push (list :submission record :prior-state (copy-tree state) :planning-result result
                        :domain-version version) submission-checks)))
        (setf prefix (append prefix (list record))
              state (project-development-records prefix)))
      (unless records (refuse-record :one-policy-required))
      (values state (nreverse validations) versions (nreverse submission-checks)))))

(defun binding-domain-version (binding versions)
  (unless (equal "welcome-development-plan-v2" (getf binding :format))
    (domain-refuse :unsupported-binding-format))
  (or (gethash (getf (getf binding :inputs) :domain-version) versions)
      (domain-refuse :domain-version-unavailable :record-must-precede-use)))

(defparameter *development-validator-source*
  (list :path +validator-path+
        :sha256 (file-sha256 (asdf:system-relative-pathname "dreyeck/work/welcome-development" +validator-path+))))

(defun fixture-domain-version-record ()
  (let* ((items (copy-tree (shop3::domain-items (shop3:find-domain 'welcome-development))))
         (id (domain-version-id items)))
    (setf (gethash id *fixture-domain-sources*) items)
    (make-development-record 'dev-domain-version (list :domain-version id) :fixture
                             :version-id id :items-source :loaded-image
                             :form-sha256 (development-data-digest items)
                             :reader (copy-tree +domain-reader-contract+)
                             :planner (running-development-planner-pin)
                             :validator (copy-tree *development-validator-source*))))

(defun git-domain-version-record (id repository commit &optional (path "dreyeck/work/welcome-development.lisp"))
  "Prepare a record from local artifacts. Admission still requires its pre-existing dedicated tag."
  (let ((description (describe-development-domain-version repository commit path)))
    (apply #'make-development-record 'dev-domain-version id :observed
           :items-source :git :repository repository
           :validator (list :path +validator-path+
                            :blob (version-git repository "rev-parse" (format nil "~A:~A" commit +validator-path+)))
           (loop for key in '(:version-id :tag :commit :path :blob :form-sha256 :reader :planner)
                 append (list key (getf description key))))))

;; All development records fit the existing evaluation-record inspection protocol.
(defmethod dreyeck/evaluation-record:evaluation-specification-of ((r development-record)) (type-of r))
(defmethod dreyeck/evaluation-record:evaluation-input-of ((r development-record)) (data r :assignment))
(defmethod dreyeck/evaluation-record:evaluation-status-of ((r development-record))
  (typecase r (dev-submission :claimed) (dev-verification (data r :verdict))
    (dev-review (data r :decision)) (t :recorded)))
(defmethod dreyeck/evaluation-record:evaluation-result-of ((r development-record)) (record-data r))
(defmethod dreyeck/evaluation-record:evaluation-evidence-of ((r development-record)) (record-data r))
(defmethod dreyeck/evaluation-record:evaluation-identity-of ((r development-record)) (record-id r))
(defmethod dreyeck/evaluation-record:evaluation-failure-of ((r development-record))
  (and (eq :rejected (data r :verdict)) (data r :findings)))
(defmethod dreyeck/evaluation-record:evaluation-trace-of ((r development-record)) nil)
(defmethod dreyeck/evaluation-record:evaluation-started-at-of ((r development-record)) nil)
(defmethod dreyeck/evaluation-record:evaluation-finished-at-of ((r development-record)) (data r :observed-at))
(defmethod dreyeck/evaluation-record:evaluation-annotation-of ((r development-record))
  (list :source (record-source r) :planner-mode :plan-only :record-role :retained-observation))
