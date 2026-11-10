;;;; Explicitly synthetic W1 examples. These never assert real S1–S4 work.
(in-package #:dreyeck/work/welcome-development)

(defparameter +fixture-base+ "99dbe5599dc6c0b080bec1b743dd864aa5635e0b")
(defun fixture-sha (character &optional (length 40)) (make-string length :initial-element character))
(defun fixture-policy (&optional extra-reviewer)
  (make-development-record
   'dev-policy :policy :fixture :base +fixture-base+ :attempt-limit 2
   :implementers '((codex s1) (claude-code s1) (codex s2) (codex s3) (claude-code s4))
   :reviewers (append '((claude-code s1) (claude-code s2) (claude-code s3) (codex s4))
                      (when extra-reviewer '((codex s1))))))
(defun fixture-assignment (id slice executor base prior-records)
  (make-development-record
   'dev-assignment id :fixture :slice slice :executor executor :base base
   :branch (format nil "fixture/~A" id) :allowed-paths '("fixture/*")
   :required-tests (list (list :system "fixture/slice-tests" :markers '("FIXTURE-PASS")))
   :forbidden-actions '(:wiki-write :merge :deployment :agent-execution)
   :source-plan (assignment-proposal-binding prior-records `(!assign ,slice ,executor ,base)
                                            :domain-version (fixture-version-id prior-records))))
(defun fixture-version-id (records)
  (data (find-if (lambda (r) (typep r 'dev-domain-version)) records) :version-id))
(defun fixture-first-assignment (records)
  (find-if (lambda (r) (typep r 'dev-assignment)) records))
(defun fixture-policy-prefix (records)
  (subseq records 0 (position-if (lambda (r) (typep r 'dev-assignment)) records)))
(defun fixture-submission (assignment commit)
  (make-development-record
   'dev-submission (list :claim (record-id assignment)) :fixture
   :slice (data assignment :slice) :assignment (record-id assignment)
   :executor (data assignment :executor) :commit commit :status :claimed
   :text "Fixture agent claim, not verification."))
(defun fixture-record-key (&rest parts)
  "Explicit fixture-only serialization of composite identity into a CHARACTER string.
No incoming development record ID is implicitly encoded or repaired."
  (development-canonical-string parts))
(defun fixture-verification (assignment commit &optional (verdict :verified))
  (make-development-record
   'dev-verification (fixture-record-key :verification (record-id assignment) verdict) :fixture
   :slice (data assignment :slice) :assignment (record-id assignment) :commit commit
   :verifier 'independent-checker :independent t :observed-at "fixture-time"
   :verdict verdict :platform :fixture :network-isolation :none :syscall-trace :unverified
   :limits '(:synthetic-artifacts :no-real-tests-observed :no-repository-observed)
   :repository-evidence (list :base (data assignment :base) :commit commit
                              :tree (fixture-sha #\a) :ancestor t :files '("fixture/implementation.lisp")
                              :scope-compliant t)
   :tests (list (list :system "fixture/slice-tests" :command '("fixture-test-command")
                      :status (if (eq verdict :verified) :passed :failed)
                      :exit-code (if (eq verdict :verified) 0 1)
                      :commit commit :tree (fixture-sha #\a)
                      :markers '("FIXTURE-PASS") :log-sha256 (fixture-sha #\b 64)))))
(defun fixture-review (assignment commit &optional (decision :accepted))
  (make-development-record
   'dev-review (fixture-record-key :review (record-id assignment) decision commit) :fixture
   :slice (data assignment :slice) :assignment (record-id assignment) :commit commit
   :reviewer (if (eq 'claude-code (data assignment :executor)) 'codex 'claude-code)
   :decision decision :findings '("Synthetic review") :text-digest (fixture-sha #\e 64)))
(defun fixture-integration (assignment commit)
  (make-development-record
   'integration-observation (list :integration (record-id assignment)) :fixture
   :slice (data assignment :slice) :commit commit :head (fixture-sha #\f)
   :observer 'repository-observer :observed-at "fixture-time" :ancestor t
   :head-source '(:fixture-ls-remote "origin" "refs/heads/dreyeck.ch")))

(defun fixture-records (scenario)
  (let* ((p (fixture-policy (eq scenario :p7)))
         (p0 (list p (fixture-domain-version-record)))
         (c1 (fixture-sha #\1)) (c2 (fixture-sha #\2))
         (a1 (fixture-assignment :a1 's1 (if (eq scenario :p9) 'claude-code 'codex) +fixture-base+ p0))
         (p1 (append p0 (list a1)))
         (p2 (append p1 (list (fixture-submission a1 c1))))
         (p3 (append p2 (list (fixture-verification a1 c1))))
         (p4 (append p3 (list (fixture-review a1 c1))))
         (p5 (append p4 (list (fixture-integration a1 c1))))
         (a2 (when (member scenario '(:p8 :p10 :p11))
               (fixture-assignment :a2 's2 'codex c1 (if (eq scenario :p8) p5 p4)))))
    (ecase scenario
      (:p0 p0) (:p1 p1) (:p2 p2) (:p3 p3) (:p4 p4)
      (:p4b (append p3 (list (fixture-review a1 (fixture-sha #\0)))))
      (:p5 p5)
      (:p6 (append p2 (list (fixture-verification a1 c1 :rejected))))
      (:p7 (let* ((prior (append p2 (list (fixture-verification a1 c1 :rejected))))
                   (retry (fixture-assignment :retry 's1 'claude-code +fixture-base+ prior))
                   (c (fixture-sha #\3)))
              (append prior (list retry (fixture-submission retry c)
                               (fixture-verification retry c) (fixture-review retry c :rejected)))))
      (:p8 (append p5 (list a2 (fixture-submission a2 c2)
                            (fixture-verification a2 c2 :rejected))))
      (:p9 p3)
      (:p10 (append p2 (list a2 (fixture-submission a2 c2))))
      (:p11 (append p4 (list a2 (fixture-submission a2 c2)
                             (fixture-verification a2 c2) (fixture-review a2 c2))))
      (:complete
       (let ((records (copy-list p0)) (base +fixture-base+))
         (loop for s in '(s1 s2 s3 s4) for executor in '(codex codex codex claude-code)
               for character across "1234"
               for a = (fixture-assignment (fixture-record-key :all s) s executor base records)
               for c = (fixture-sha character)
               do (setf records (append records (list a (fixture-submission a c)
                                                       (fixture-verification a c) (fixture-review a c)
                                                       (fixture-integration a c))) base c))
         records)))))

(defun welcome-development-demo (&optional (scenario :p0))
  "Read-only fixture entry point; all record provenance remains visibly :FIXTURE."
  (development-workflow (fixture-records scenario)))
