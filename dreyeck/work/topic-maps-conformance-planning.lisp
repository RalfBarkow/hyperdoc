;;;; Optional investigation planning over two historical records, never a conformance runner.
(defpackage #:dreyeck/work/topic-maps-conformance-planning
  (:use #:cl)
  (:local-nicknames (#:git #:dreyeck/git) (#:h #:dreyeck/shop3) (#:v #:html-inspector-views))
  (:export #:+evidence-revision+ #:read-case-evidence #:case-evidence #:evidence-id
           #:evidence-record #:evidence-row #:evidence-sources #:evidence-execution
           #:evidence-controls-execution #:investigation-state #:qualify-test-case
           #:investigate-case #:investigation-run #:run-evidence #:run-result
           #:run-state #:run-goal #:method-names #:run-tests))
(in-package #:dreyeck/work/topic-maps-conformance-planning)

(defparameter +evidence-revision+ "88994c1b9e1edbf13e665e984a5c9c3b2cdf7575")
(defparameter +corpus-revision+ "cd165b150176c1d6842b37be9cc9051b40d4996b")

(shop3:defdomain (conformance-investigation :noset t)
 ((:operator (!prepare-byte-review ?c)
   ((observed-cxtm-mismatch ?c) (comparison-evidence ?c))
   () ((planned-byte-review ?c)))
  (:operator (!prepare-edition-review ?c)
   ((recorded-disposition ?c :unresolved) (normative-references ?c))
   () ((planned-edition-review ?c)))
  (:operator (!frame-disposition-question ?c ?kind)
   () () ((planned-disposition-question ?c ?kind)))
  (:operator (!separate-original-and-control ?c)
   ((registered-status ?c :not-run) (reader-rejection ?c :template-identity-tail)
    (expanded-control ?c :byte-exact))
   () ((planned-evidence-separation ?c)))
  (:operator (!prepare-original-inquiry ?c)
   ((planned-evidence-separation ?c))
   () ((planned-original-inquiry ?c)))
  (:operator (!report-missing-prerequisite ?c ?p)
   ((requires ?c ?p) (recorded-prerequisite ?c ?p :incomplete))
   () ((planned-prerequisite-blocker ?c ?p)))

  (:method (qualify-test-case ?c) review-observed-mismatch
   ((known-case ?c) (evidence-verified ?c) (investigation-goal ?c :preparation)
    (registered-status ?c :fail) (observed-cxtm-mismatch ?c) (comparison-evidence ?c))
   ((!prepare-byte-review ?c) (!frame-disposition-question ?c :cxtm-difference)))
  (:method (qualify-test-case ?c) prepare-normative-question
   ((known-case ?c) (evidence-verified ?c) (investigation-goal ?c :preparation)
    (registered-status ?c :fail) (recorded-disposition ?c :unresolved) (normative-references ?c))
   ((!prepare-edition-review ?c) (!frame-disposition-question ?c :include-environment)))
  (:method (qualify-test-case ?c) investigate-registered-not-run
   ((known-case ?c) (evidence-verified ?c) (investigation-goal ?c :preparation)
    (registered-status ?c :not-run) (reader-rejection ?c :template-identity-tail)
    (expanded-control ?c :byte-exact))
   ((!separate-original-and-control ?c) (!prepare-original-inquiry ?c)))
  (:method (qualify-test-case ?c) report-explicit-prerequisite-gap
   ((known-case ?c) (evidence-verified ?c)
    (investigation-goal ?c :edition-qualified-disposition)
    (requires ?c ?p) (recorded-prerequisite ?c ?p :incomplete))
   ((!report-missing-prerequisite ?c ?p)))))

(defclass case-evidence ()
  ((id :initarg :id :reader evidence-id)
   (record :initarg :record :reader evidence-record)
   (row :initarg :row :reader evidence-row)
   (sources :initarg :sources :reader evidence-sources)
   (execution :initarg :execution :reader evidence-execution)
   (controls-execution :initarg :controls-execution :reader evidence-controls-execution))
  (:documentation "Reading metadata over unchanged serialized Case Records; not a Topic Maps model or registry."))
(defclass investigation-run ()
  ((evidence :initarg :evidence :reader run-evidence)
   (goal :initarg :goal :reader run-goal)
   (state :initarg :state :reader run-state)
   (result :initarg :result :reader run-result)))

(defun text-digest (text)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets text :external-format :utf-8))))
(defun json-at (table &rest keys)
  (reduce (lambda (value key) (gethash key value)) keys :initial-value table))
(defun case-row (json id)
  (let ((rows (remove-if-not (lambda (row) (equal id (gethash "id" row)))
                             (coerce (gethash "cases" json) 'list))))
    (unless (= 1 (length rows)) (error "Expected exactly one pinned record for ~A." id))
    (first rows)))
(defun read-case-evidence (repository case)
  "Read only Git objects at the fixed revision. Never load Topic Maps code, run a
reader/test, inspect its moving HEAD, or write its worktree. Only these two IDs are supported."
  (check-type repository git:git-repository-checkout)
  (let* ((id (ecase case
               (:include-template "ctm/in/include-template.ctm")
               (:template-subject-identifier2 "ctm/in/template-subject-identifier2.ctm")))
         (commit (git:make-git-commit :repository repository :commit-ish +evidence-revision+))
         (sources nil))
    (labels ((source (path)
               (let* ((file (git:make-git-file-at-commit :commit commit :path path))
                      (text (git:git-file-contents file)))
                 (push file sources) text))
             (json (path) (shasht:read-json (source path) t nil t))
             (require-evidence (test) (unless test (error "Pinned evidence disagrees for ~A." id))))
      (let* ((matrix (json "reports/slice-22a/matrix.json"))
             (registry (json "reports/slice-22a/baseline/ctm.validation.json"))
             (observations (json "reports/slice-22a/investigation/ctm-observations.json"))
             (controls (json "reports/slice-22a/investigation/controls.json"))
             (execution (json "reports/slice-22a/execution.json"))
             (controls-execution (json "reports/slice-22a/investigation/execution.json"))
             (row (case-row matrix id)) (record (case-row registry id)))
        (source "docs/slice-22a-conformance-closure.md")
        (require-evidence (equal +corpus-revision+ (gethash "corpusPin" matrix)))
        (require-evidence (equalp record (gethash "caseRecord" row)))
        (require-evidence (equalp (gethash "observation" row) (case-row observations id)))
        (require-evidence (equal (gethash "status" record) (gethash "registeredStatus" row)))
        (require-evidence (eql 0 (gethash "newOriginalPASS" execution)))
        (require-evidence (equalp (gethash "statusesBefore" execution) (gethash "statusesAfter" execution)))
        ;; These two original/baseline files are ASCII. UTF-8 text hashing is byte-exact here.
        (dolist (description (list (gethash "source" row) (json-at row "expected" "baseline")))
          (let ((text (source (gethash "path" description))))
            (require-evidence (every (lambda (c) (< (char-code c) 128)) text))
            (require-evidence (= (length text) (gethash "bytes" description)))
            (require-evidence (equal (text-digest text) (gethash "sha256" description)))))
        (require-evidence (equal "C" (gethash "normativeDecisionABC" row)))
        (require-evidence (plusp (length (gethash "normativeReferences" row))))
        ;; An explicit 22A evidence limitation, not an inference from an absent fact.
        (require-evidence
         (search "not full" (gethash "evidenceLimit" (aref (gethash "normativeReferences" row) 0))))
        (ecase case
          (:include-template
           (require-evidence (equal "fail" (gethash "status" record)))
           (require-evidence (equal "cxtm-mismatch" (gethash "actualOutcome" record)))
           (require-evidence (and (eql 353 (json-at row "observation" "actualBytes"))
                                  (eql 401 (json-at row "observation" "expectedBytes"))
                                  (eql 58 (json-at row "observation" "firstDifferentByte"))
                                  (eq :null (gethash "condition" row)))))
          (:template-subject-identifier2
           (require-evidence (equal "not-run" (gethash "status" record)))
           (require-evidence (eq :null (gethash "actualOutcome" record)))
           (require-evidence (equal "template-identity-tail" (json-at row "condition" "code")))
           (require-evidence (eql 34 (json-at row "condition" "position")))
           (require-evidence
            (equalp (gethash "expandedControl" row)
                    (find "expanded-subject-identifier2" controls :test #'equal
                          :key (lambda (control) (gethash "label" control)))))
           (require-evidence (and (eq t (json-at row "expandedControl" "byteExact"))
                                  (eql 204 (json-at row "expandedControl" "actualBytes"))
                                  (eql 204 (json-at row "expandedControl" "expectedBytes"))))))
        (make-instance 'case-evidence :id id :record record :row row :sources (nreverse sources)
                       :execution execution :controls-execution controls-execution)))))

(defun investigation-state (evidence &key (goal :preparation))
  "Historical statuses are copied as observations. GOAL is a proposed investigation
scope, never a corpus observation. No absent observation is converted to a negative."
  (unless (member goal '(:preparation :edition-qualified-disposition)) (error "Unknown goal ~S." goal))
  (let* ((id (evidence-id evidence)) (record (evidence-record evidence))
         (status (ecase (intern (string-upcase (gethash "status" record)) :keyword)
                   (:fail :fail) (:not-run :not-run))))
    (append `((known-case ,id) (evidence-verified ,id) (registered-status ,id ,status)
              (investigation-goal ,id ,goal) (recorded-disposition ,id :unresolved)
              (normative-references ,id)
              (recorded-prerequisite ,id :completed-published-edition-review :incomplete))
            (when (eq goal :edition-qualified-disposition)
              `((requires ,id :completed-published-edition-review)))
            (ecase status
              (:fail `((observed-cxtm-mismatch ,id) (comparison-evidence ,id)))
              (:not-run `((reader-rejection ,id :template-identity-tail)
                          (expanded-control ,id :byte-exact)))))))

(defun plan-state (state id &optional (domain (shop3:find-domain 'conformance-investigation)))
  "Native SHOP3 only; temporary problem cleanup also covers exceptional exits."
  (let ((name (gensym "CONFORMANCE-INVESTIGATION-")) (problem nil)
        (shop3::*problem* shop3::*problem*))
    (unwind-protect
         (progn
           (setf problem (shop3:make-problem (list name :domain (shop3::domain-name domain) :silently t)
                                            (copy-tree state) `((qualify-test-case ,id))))
           (multiple-value-bind (raw time trees states)
               (shop3:find-plans problem :domain domain :which :all :verbose 0 :plan-tree t :collect-state t)
             (make-instance 'h:hyperdoc-htn-plan-result :problem-name name :raw-plans raw
                            :plans (mapcar #'shop3:shorter-plan raw) :time time
                            :plan-trees trees :final-states states :execution-mode :plan-only)))
      (let ((partial (or problem (shop3:find-problem name))))
        (when partial (shop3:delete-problem partial))))))
(defun qualify-test-case (evidence &key (goal :preparation))
  "Return the existing native result, plus the initial state. Never select or execute a plan."
  (let ((state (investigation-state evidence :goal goal)))
    (values (plan-state state (evidence-id evidence)) state)))
(defun investigate-case (repository case &key (goal :preparation))
  (let ((evidence (read-case-evidence repository case)))
    (multiple-value-bind (result state) (qualify-test-case evidence :goal goal)
      (make-instance 'investigation-run :evidence evidence :goal goal :state state :result result))))
(defun method-names (tree)
  "Read the pinned SHOP3 tree's own method labels; do not reconstruct a replacement tree."
  ;; FIND-PLANS returns the pinned engine's list-based planning-tree forest,
  ;; not its separate explicit-stack tree structures. Use its native accessors.
  (cond ((shop3::primitive-node-p tree) nil)
        ((shop3::complex-node-p tree)
         (append (when (shop3::complex-node-reduction-label tree)
                   (list (shop3::complex-node-reduction-label tree)))
                 (mapcan #'method-names (shop3::complex-node-children tree))))
        ((listp tree) (mapcan #'method-names tree))))

(v:defview conformance-investigation (run investigation-run)
  (v:html-view :title "Investigation alternatives" :priority 0
    (let* ((evidence (run-evidence run)) (result (run-result run)))
      (v:html (:h2 "Topic Maps investigation — plan only")
        (:p (v:esc (format nil "~A · registered ~A · retained at ~A"
                           (evidence-id evidence) (gethash "status" (evidence-record evidence)) +evidence-revision+)))
        (:p "Historical observations were read, not re-executed. Goals and planned effects are proposals.")
        (:p (v:object-ref (evidence-record evidence) :display "Original serialized Case Record")
            " · " (v:object-ref (evidence-row evidence) :display "Historical matrix row")
            " · " (v:object-ref (run-state run) :display "Initial state"))
        (:p (v:object-ref result :display "Native SHOP3 result"))
        (loop for plan in (h:plans-of result) for tree in (h:plan-trees-of result)
              for state in (h:final-states-of result) for i from 0 do
          (v:html (:h3 (v:esc (format nil "Alternative ~D: ~S" i (method-names tree))))
            (:p (v:object-ref plan :display "Proposed steps")
                " · " (v:object-ref tree :display "Native plan tree / method")
                " · " (v:object-ref state :display "Simulated final state"))))
        (:p "A prerequisite-blocker plan reports an unsatisfied requirement; it is not a completed qualification.")
        (:p (v:object-ref (evidence-execution evidence) :display "Historical execution provenance")
            " · " (v:object-ref (evidence-controls-execution evidence) :display "Reader/control execution provenance"))
        (:ul (dolist (source (evidence-sources evidence))
               (v:html (:li (v:object-ref source :display (git:git-file-path-of source))))))))))

(hyperdoc:defhyperdoc *investigation-reading*
  :id "dreyeck/work/topic-maps-conformance-planning"
  :title "Planning Topic Maps Conformance Investigations"
  :asdf-system-name "dreyeck/work/topic-maps-conformance-planning"
  :subdirectory "dreyeck/pages/topic-maps-conformance-planning"
  :main-page-id "Planning Evidence-Based Investigations")
