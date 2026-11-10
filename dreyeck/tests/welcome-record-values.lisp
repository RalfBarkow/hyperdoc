;;;; N1: record values must remain ground data in native SHOP3 facts.
(in-package #:dreyeck/work/welcome-development)

(defvar *n1-special-value* 0)
(defvar n1-unbound-special)
(define-symbol-macro n1-symbol-macro (clear-development-domain-cache))

(defun n1-domain-f ()
  (values
   "(shop3:defdomain (welcome-development :noset t)
 ((:operator (!assign ?s ?e ?b) () () ((planned-assignment ?s ?e ?b)))
  (:operator (!await-submission ?s ?a ?e) () () ())
  (:operator (!report-blocker ?s ?r) () () ((planned-blocker-report ?s ?r)))
  (:method (advance-welcome) first-assignment
   ((observed-base ?b) (may-implement ?e s1) (not (assignment s1 ?_a ?_e ?_b)))
   ((!assign s1 ?e ?b)))
  (:method (advance-welcome) rv-state
   ((assignment ?s ?a ?e ?b) (shop3:call < ?a 1))
   ((!report-blocker ?s rv-state)))
  (:method (advance-welcome) await-submission
   ((assignment ?s ?a ?e ?b) (not (claimed ?s ?a ?_c)))
   ((!await-submission ?s ?a ?e)))))"
   '((:operator (!assign ?s ?e ?b) () () ((planned-assignment ?s ?e ?b)))
     (:operator (!await-submission ?s ?a ?e) () () ())
     (:operator (!report-blocker ?s ?r) () () ((planned-blocker-report ?s ?r)))
     (:method (advance-welcome) first-assignment
      ((observed-base ?b) (may-implement ?e s1) (not (assignment s1 ?_a ?_e ?_b))) ((!assign s1 ?e ?b)))
     (:method (advance-welcome) rv-state
      ((assignment ?s ?a ?e ?b) (shop3:call < ?a 1)) ((!report-blocker ?s rv-state)))
     (:method (advance-welcome) await-submission
      ((assignment ?s ?a ?e ?b) (not (claimed ?s ?a ?_c))) ((!await-submission ?s ?a ?e))))))

(defun n1-tagged-replay (&optional baseline (bad-id '(clear-development-domain-cache)))
  (let ((root (uiop:ensure-directory-pathname
               (string-trim '(#\Newline #\Return)
                            (uiop:run-program '("mktemp" "-d" "-t" "hyperdoc-n1-XXXXXXXX") :output :string)))))
    (unwind-protect
         (progn
           (w2-fixture-git root "init" "-q")
           (w2-fixture-git root "config" "user.email" "fixture@example.invalid")
           (w2-fixture-git root "config" "user.name" "N1 disposable fixture")
           (multiple-value-bind (text items) (n1-domain-f)
             (let* ((version-record (w2-trust-record root text items))
                    (prefix (list (w2-observed (fixture-policy)) version-record))
                    (assignment (w2-observed (fixture-assignment bad-id 's1 'codex +fixture-base+ prefix)))
                    (submission (w2-observed (fixture-submission assignment (fixture-sha #\1))))
                    (records (append prefix (list assignment submission)))
                    (public (w2-public-snapshot)) (cache (w2-cache-snapshot))
                    (problems (copy-list shop3::*all-problems*)) (current shop3::*problem*)
                    (calls 0) (planning 0))
               (w2-wrapped (clear-development-domain-cache
                            (lambda (original &rest args) (incf calls) (apply original args)))
                 (w2-wrapped (plan-development-state
                              (lambda (original &rest args) (incf planning) (apply original args)))
                   (if baseline
                       (progn
                         (development-state records)
                         (assert (plusp calls))
                         (assert (zerop (hash-table-count *development-domain-cache*)))
                         (format t "~&N1 BASELINE F ID=~S: submission admitted; cache-clear calls=~D; planning calls=~D; cache ~D -> 0.~%"
                                 bad-id calls planning (length cache)))
                       (progn
                         (w2-refuses :unsafe-planning-value (lambda () (development-state records)))
                         (assert (zerop calls)) (assert (zerop planning))
                         (w2-cache-unchanged cache)
                         (format t "~&N1 F PASS: bad assignment ID refused; planning=0; cache-clear=0; cache/public/problem state unchanged.~%")))))
               (w2-public-unchanged public)
               (assert (equal problems shop3::*all-problems*)) (assert (eq current shop3::*problem*))
               (unless baseline
                 ;; A numeric identifier is legitimate data for F's comparison.
                 ;; Every real alternative is retained, including the await step.
                 (let* ((a (w2-observed (fixture-assignment 0 's1 'codex +fixture-base+ prefix)))
                        (s (w2-observed (fixture-submission a (fixture-sha #\1))))
                        (before (w2-cache-snapshot)) (calls 0))
                   (w2-wrapped (clear-development-domain-cache
                                (lambda (original &rest args) (incf calls) (apply original args)))
                     (multiple-value-bind (state validations versions checks)
                         (development-state (append prefix (list a s)))
                       (declare (ignore state validations versions))
                       (let* ((result (getf (first checks) :planning-result))
                              (plans (dreyeck/shop3:plans-of result)))
                         (assert (= 2 (length plans)))
                         (assert (member '((!await-submission s1 0 codex)) plans :test #'equal))
                         (assert (member '((!report-blocker s1 rv-state)) plans :test #'equal))
                         (assert (eq :plan-only (dreyeck/shop3:execution-mode-of result))))))
                   (assert (zerop calls)) (w2-cache-unchanged before)
                   (format t "~&N1 F POSITIVE PASS: numeric ID, both native alternatives, :PLAN-ONLY, no mutation.~%"))))))
      (clear-development-domain-cache)
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore)))
  t)

(defun n1-change-field (records record field value)
  (let ((copy (make-instance (type-of record) :id (if (eq :record-id field) value (record-id record))
                            :source (record-source record) :data (copy-record-data (record-data record)))))
    (cond ((consp field)
           (setf (nth (if (eq :actor (second field)) 0 1)
                      (first (data copy (first field)))) value))
          ((not (eq :record-id field))
           (let ((properties (record-data copy)))
             (setf (getf properties field) value (slot-value copy 'data) properties))))
    (substitute copy record records :test #'eq)))

(defun n1-field-cases (records)
  (loop for (class fields) in
        '((dev-policy (:base :attempt-limit (:implementers :actor) (:implementers :slice)
                             (:reviewers :actor) (:reviewers :slice)))
          (dev-assignment (:slice :record-id :executor :base))
          (dev-submission (:slice :assignment :executor :commit))
          (dev-verification (:slice :assignment :commit :record-id))
          (dev-review (:slice :assignment :commit :record-id))
          (integration-observation (:slice :commit :head)))
        for record = (find-if (lambda (r) (typep r class)) records)
        append (loop for field in fields collect (list class record field))))

(defun run-record-value-tests ()
  (n1-tagged-replay)
  (n1-tagged-replay nil 'n1-symbol-macro)
  (let* ((records (fixture-records :complete)) (fields (n1-field-cases records))
         (policy (first records)) (assignment (fixture-first-assignment records))
         (public (w2-public-snapshot)) (cache (w2-cache-snapshot))
         (problems (copy-list shop3::*all-problems*)) (current shop3::*problem*)
         (planning 0) (calls 0))
    (assert (= 25 (length fields)))
    (w2-wrapped (plan-development-state
                 (lambda (original &rest args) (incf planning) (apply original args)))
      (w2-wrapped (clear-development-domain-cache
                   (lambda (original &rest args) (incf calls) (apply original args)))
        (dolist (case fields)
          (destructuring-bind (class record field) case
            (dolist (payload (list '(clear-development-domain-cache) '*n1-special-value*
                                   'n1-unbound-special 'n1-symbol-macro))
              (w2-refuses :unsafe-planning-value
                          (lambda () (project-development-records (n1-change-field records record field payload)))))
            (format t "~&N1 FIELD ~S ~S PASS: compound, bound/unbound special and symbol macro all refused.~%" class field)))
        (dolist (field '(:implementers :reviewers))
          (dolist (value (list 'codex '(codex s1) '(nil) '((codex)) '((codex s1 extra))
                              '((codex . s1)) '((codex s1) . tail) '(0) '((0 s1))
                              '((nil s1)) '((codex unknown-slice)) '((codex "s1")) "roles" #(codex s1)))
            (w2-refuses :invalid-policy-pairs
                        (lambda () (project-development-records (n1-change-field records policy field value)))))
          (format t "~&N1 POLICY ~S PASS: malformed collections, pairs, actors and slices refused.~%" field))
        (let ((uninterned (make-symbol "N1-ID")))
          (dolist (payload (list '(clear-development-domain-cache) '(1 2) #() #\x 1.5 1/2 #P"/tmp/n1-data"
                                 #'clear-development-domain-cache (make-hash-table) uninterned
                                 '?n1-value :?n1-value 'cl:*print-base* 'n1-symbol-macro))
            (w2-refuses :unsafe-planning-value
                        (lambda () (project-development-records
                                    (n1-change-field records assignment :record-id payload))))))
        ;; The output check also rejects new/accidental unsafe fact projections.
        (w2-refuses :unsafe-planning-fact
                    (lambda () (validate-development-facts '((probe (clear-development-domain-cache))))))))
    (assert (zerop planning)) (assert (zerop calls))
    (w2-cache-unchanged cache) (w2-public-unchanged public)
    (assert (equal problems shop3::*all-problems*)) (assert (eq current shop3::*problem*))
    (format t "~&N1 MATRIX PASS: all 25 projected fields; 100 expression/special/macro cases; 28 policy-shape cases; other value types; planning/cache-clear=0.~%"))
  ;; Self-evaluation is distinguished explicitly from permitted symbolic constants.
  (dolist (value (list 0 -1 42 "record-1" "(clear-development-domain-cache)" :a1 nil t))
    (assert (eq :self-evaluating (development-fact-value-kind value))))
  (dolist (value '(s1 s2 s3 s4 codex claude-code n1-human))
    (assert (eq :symbolic-constant (development-fact-value-kind value))))
  (dolist (id (list :legitimate-id 42 "record-1" "(clear-development-domain-cache)" 'n1-constant-id))
    (let* ((prefix (fixture-records :p0))
           (assignment (fixture-assignment id 's1 'codex +fixture-base+ prefix))
           (records (append prefix (list assignment)))
           (run (development-workflow records))
           (projection (development-topicmap run)))
      (assert (member `((!await-submission s1 ,id codex)) (dreyeck/shop3:plans-of (development-plan-result run)) :test #'equal))
      (assert (member assignment (development-records run) :test #'eq))
      (assert (member assignment (mapcar #'dreyeck/topicmap:topicmap-topic-object-of
                                         (dreyeck/topicmap:topicmap-projection-topics-of projection)) :test #'eq))))
  ;; Nonprojected record identities/evidence remain rich first-class provenance.
  (let* ((prefix (fixture-records :p0)) (policy (first prefix))
         (before (development-state prefix)))
    (setf (slot-value policy 'id) '(:retained :policy :identity))
    (assert (equal before (development-state prefix)))
    (assert (consp (record-id (second prefix)))))
  ;; Named actors need not be limited to the example's two implementers.
  (dolist (actor '(n1-human :human "human"))
    (let* ((prefix (fixture-records :p0)) (policy (first prefix)))
      (let ((properties (record-data policy)))
        (push (list actor 's1) (getf properties :implementers))
        (push (list actor 's1) (getf properties :reviewers)))
      (let ((a (fixture-assignment :human 's1 actor +fixture-base+ prefix)))
        (development-state (append prefix (list a))))))
  (let* ((records (fixture-records :complete)) (run (development-workflow records))
         (projection (development-topicmap run))
         (objects (mapcar #'dreyeck/topicmap:topicmap-topic-object-of
                           (dreyeck/topicmap:topicmap-projection-topics-of projection))))
    (assert (eq :complete (development-outcome run)))
    (dolist (record records)
      (assert (member record objects :test #'eq))
      (when (member (type-of record) '(dev-assignment dev-verification dev-review))
        (assert (stringp (record-id record)))))
    (assert (eq :plan-only (dreyeck/shop3:execution-mode-of (development-plan-result run)))))
  (format t "~&N1 POSITIVES PASS: identifiers/actors, explicit fixture ID strings, rich provenance EQ identity and :complete/:PLAN-ONLY.~%")
  t)
