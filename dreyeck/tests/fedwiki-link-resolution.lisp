;;;; Tests for dreyeck/work/fedwiki-link-resolution: agreement with the recorded fedwiki-java run, the counter-probes,
;;;; and mutants that each check must kill. All searches use :WHICH :ALL through PLAN-LINK-RESOLUTION. No network.

(defpackage #:dreyeck/work/fedwiki-link-resolution/tests
  (:use #:cl)
  (:local-nicknames (#:m #:dreyeck/work/fedwiki-link-resolution) (#:r #:dreyeck/shop3))
  (:export #:run-tests #:run-mutants))
(in-package #:dreyeck/work/fedwiki-link-resolution/tests)

(defparameter *domain* 'm::fedwiki-link-resolution)

(defun pass (label format &rest args)
  (format t "~&LINK-RESOLUTION ~A PASS: ~?~%" label format args))

(defun plan (state tasks &optional (domain *domain*))
  "(values OUTCOMES RESULT) for one search."
  (let ((result (m:plan-link-resolution state tasks :domain domain)))
    (assert (= (length (r:raw-plans-of result)) (length (r:plans-of result))
               (length (r:plan-trees-of result)) (length (r:final-states-of result))))
    (assert (eq :plan-only (r:execution-mode-of result)))
    (values (m:plan-outcomes result state) result)))

(defun state (&key (journal '(:s1 :s2)) item (panel :origin) facts)
  "Synthetic facts: origin :ORIGIN, Java candidates for a link on a panel at PANEL, plus FACTS."
  (append '((m::origin :origin))
          (m:candidate-facts :r (m:java-link-candidates :origin :origin :panel-site panel :item-site item :journal-sites journal))
          facts))

(defun available (site &optional (slug :target)) `(m::page-available ,site ,slug))
(defun unavailable (site &optional (slug :target) (status 404)) `(m::page-unavailable ,site ,slug ,status))
(defun collaborative (&optional (slug :target)) `((m::resolve :r ,slug m::collaborative)))
(defun local-only (&optional (slug :target)) `((m::resolve :r ,slug m::local-only)))
(defun prepare (&optional (slug :target)) `((m::prepare-local-target ,slug)))
(defun only (outcomes) (assert (= 1 (length outcomes)) () "expected exactly one plan, got ~S" outcomes) (first outcomes))

;;; 1. Agreement with the recorded Java run (tests/fedwiki-java-reference/observed.json).

(defun %k (string) (intern (string-upcase string) :keyword))

(defun check-java-agreement (&key (domain *domain*) quiet)
  "For every scenario: the planned page requests, in order, are the requests the Java servers received (after the
initial load of the origin's welcome page, and except for a 'dead' site, which cannot log), and each link's outcome
is the Java outcome: the lineup site, 'can't find page in current context', or 'http error'."
  (let ((observations (m:load-observations)))
    (assert observations () "observed.json is missing: run tests/fedwiki-java-reference/run-reference.py")
    (assert (equal m:+reference-revision+ (gethash "revision" (gethash "reference" observations))))
    (dolist (scenario (m:load-scenarios) t)
      (let* ((id (gethash "id" scenario))
             (observed (find id (coerce (gethash "scenarios" observations) 'list) :key (lambda (s) (gethash "id" s)) :test #'equal))
             (dead (mapcar #'%k (coerce (or (gethash "dead" scenario) #()) 'list)))
             (java-requests (map 'list (lambda (r) (list (%k (elt r 0)) (%k (elt r 1)))) (gethash "page_requests" observed)))
             (lineup (map 'list (lambda (entry) (%k (elt entry 1))) (gethash "lineup" observed)))
             (trouble (coerce (gethash "trouble" observed) 'list))
             (planned (list (list :origin :welcome-visitors)))
             (outcomes '()))
        (dotimes (i (length (gethash "links" scenario)))
          (multiple-value-bind (result state) (m:scenario-plan id i :domain domain)
            (let ((outcome (only (m:plan-outcomes result state))))
              (push outcome outcomes)
              (setf planned (append planned (getf outcome :requests))))))
        (setf outcomes (nreverse outcomes))
        (let ((loggable (remove-if (lambda (request) (member (first request) dead)) planned)))
          (assert (equal loggable java-requests) () "~A: planned ~S, Java requested ~S" id loggable java-requests))
        (cond ((null trouble)
               (assert (zerop (gethash "exit_code" observed)))
               (assert (equal (mapcar (lambda (o) (getf o :resolved-at)) outcomes) (rest lineup)) ()
                       "~A: resolved at ~S, Java lineup ~S" id (mapcar (lambda (o) (getf o :resolved-at)) outcomes) lineup))
              ((search "can't find page" (first trouble))
               (assert (eq :not-found (getf (car (last outcomes)) :outcome)) () "~A: ~S" id outcomes))
              ((search "http error" (first trouble))
               (assert (eq :aborted-network-error (getf (car (last outcomes)) :outcome)) () "~A: ~S" id outcomes))
              (t (error "~A: unexpected Java trouble ~S" id trouble)))
        (unless quiet
          (pass (format nil "JAVA ~A" id) "~D page requests as Java; outcomes ~S"
                (length java-requests) (mapcar (lambda (o) (getf o :outcome)) outcomes)))))))

;;; 2. Counter-probes.

(defun check-local-precedence (&key (domain *domain*) quiet)
  "1. A local hit takes precedence, in both policies, although s1 and s2 also have the page."
  (let ((facts (list (available :origin) (available :s1) (available :s2))))
    (dolist (policy (list (collaborative) (local-only)))
      (let ((o (only (plan (state :facts facts) policy domain))))
        (assert (eq :local-observed (getf o :outcome)))
        (assert (equal '((:origin :target)) (getf o :requests))))))
  (unless quiet (pass "LOCAL-PRECEDENCE" "origin first in both policies; no other request"))
  t)

(defun check-context-order (&key quiet)
  "2.-4. Without a local hit the context decides; an item site and a newer journal entry each change the order
(the agreement check proves the same against Java; these are the candidate lists themselves)."
  (assert (equal '((:origin . :origin) (:s2 . :journal) (:s1 . :journal))
                 (m:java-link-candidates :origin :origin :panel-site :origin :journal-sites '(:s1 :s2 nil))))
  (assert (equal '((:origin . :origin) (:s1 . :item) (:s2 . :journal))
                 (m:java-link-candidates :origin :origin :panel-site :origin :item-site :s1 :journal-sites '(:s1 :s2))))
  (assert (equal '((:origin . :origin) (:s1 . :journal) (:s2 . :journal))
                 (m:java-link-candidates :origin :origin :panel-site :origin :journal-sites '(:s1 :s2 :s1))))
  (assert (equal '((:origin . :origin) (:s1 . :panel) (:s2 . :journal))
                 (m:java-link-candidates :origin :origin :panel-site :s1 :journal-sites '(nil :s2))))
  (assert (equal '((:origin . :origin) (:origin . :journal) (:s1 . :journal))
                 (m:java-link-candidates :origin :origin :panel-site :origin :journal-sites '(:s1 :origin))))
  (unless quiet (pass "CONTEXT-ORDER" "journal newest first; item site, panel site, newer journal entry; origin may recur"))
  t)

(defun check-local-only-gate (&key (domain *domain*) quiet)
  "5. Local-only requests nothing but the own site and never resolves remotely, for every recorded scenario and
for synthetic states where every remote candidate has the page."
  (dolist (scenario (m:load-scenarios))
    (let ((id (gethash "id" scenario)))
      (dotimes (i (length (gethash "links" scenario)))
        (multiple-value-bind (state slug) (m:scenario-link-state id i)
          (let ((outcomes (plan state (local-only slug) domain)))
            (dolist (o outcomes)
              (assert (every (lambda (request) (eq :origin (first request))) (getf o :requests)) () "~A: ~S" id o)
              (assert (member (getf o :outcome) '(:local-observed :not-found :aborted-network-error)) () "~A: ~S" id o)
              (assert (not (member 'm::!plan-fork (getf o :steps))))))))))
  (let ((facts (list (unavailable :origin) (available :s1) (available :s2))))
    (assert (eq :remote-context (getf (only (plan (state :facts facts) (collaborative) domain)) :outcome)))
    (let ((o (only (plan (state :facts facts) (local-only) domain))))
      (assert (eq :not-found (getf o :outcome)))
      (assert (equal '((:origin :target)) (getf o :requests)))))
  (let ((o (only (plan (state :facts (list `(m::request-error :origin :target) (available :s1))) (local-only) domain))))
    (assert (eq :aborted-network-error (getf o :outcome)))
    (assert (equal '((:origin :target)) (getf o :requests))))
  (unless quiet (pass "LOCAL-ONLY-GATE" "13 scenarios and synthetic states: own site only, no remote fallback, no fork"))
  t)

(defparameter +fork-evidence+
  '((m::fork-source-policy m::verified-copy-suffices)
    (m::verified-copy :copy-1 :s1 :target)
    (m::fork-permitted :origin :s1 :target)))

(defun check-planned-fork-not-executed (&key (domain *domain*) quiet)
  "6. A planned fork makes the target available only hypothetically: resolution then says :MODELED-LOCAL, the final
state has MODELED-LOCAL-PAGE and PLANNED-FORK, keeps the 404 observation, and has no PAGE-AVAILABLE for the origin."
  (let ((initial (state :facts (cons (unavailable :origin) +fork-evidence+))))
    (multiple-value-bind (outcomes result) (plan initial (append (prepare) (local-only)) domain)
      (let* ((o (only outcomes))
             (atoms (shop3:state-atoms (first (r:final-states-of result)))))
        (assert (equal '(m::!plan-fork m::!use-modeled-page) (getf o :steps)) () "~S" o)
        (assert (eq :modeled-local (getf o :outcome)))
        (assert (member '(m::modeled-local-page :origin :target) atoms :test #'equal))
        (assert (member '(m::planned-fork :origin :target :s1 m::verified-copy :copy-1) atoms :test #'equal))
        (assert (member (unavailable :origin) atoms :test #'equal))
        (assert (not (member (available :origin) atoms :test #'equal)))
        (assert (notany (lambda (a) (member (first a) '(m::planned-panel))) atoms))))
    ;; The collaborative policy sees the modeled page as modeled, too, and requests nothing for it.
    (let ((o (only (plan initial (append (prepare) (collaborative)) domain))))
      (assert (eq :modeled-local (getf o :outcome)))
      (assert (null (getf o :requests)))))
  (unless quiet (pass "PLANNED-FORK-NOT-EXECUTED" "modeled, not observed; the 404 observation is kept; :PLAN-ONLY"))
  t)

(defun check-no-second-fork (&key (domain *domain*) quiet)
  "7. Planning the same target repeatedly forks once; re-planning on the simulated final state forks not at all."
  (let ((initial (state :facts (cons (unavailable :origin) +fork-evidence+))))
    (dolist (tasks (list (append (prepare) (prepare))
                         (append (prepare) (local-only) (prepare) (collaborative))))
      (let ((o (only (plan initial tasks domain))))
        (assert (= 1 (count 'm::!plan-fork (getf o :steps))) () "~S: ~S" tasks o)))
    (multiple-value-bind (outcomes result) (plan initial (prepare) domain)
      (declare (ignore outcomes))
      (let* ((final (shop3:state-atoms (first (r:final-states-of result))))
             (again (only (plan final (prepare) domain))))
        (assert (null (getf again :steps)))
        (assert (eq :already-modeled-local (getf again :outcome))))))
  (unless quiet (pass "NO-SECOND-FORK" "one fork per target; the simulated state needs none"))
  t)

(defun check-unknown-not-absent (&key (domain *domain*) quiet)
  "8. An unknown availability is not an absence: the search does not pass it, and the diagnosis names it."
  (let* ((facts (list (unavailable :origin) (available :s1)))        ; s2 (newest, asked second) is unknown
         (initial (state :facts facts)))
    (assert (null (plan initial (collaborative) domain)))
    (assert (equal '(:evidence-missing-or-contradictory :site :s2 :evidence :unknown)
                   (m:diagnose-no-plan initial :r :target 'm::collaborative)))
    (assert (eq :remote-context (getf (only (plan (state :facts (cons (unavailable :s2) facts)) (collaborative) domain)) :outcome))))
  (assert (null (plan (state :facts (list (available :s1))) (local-only) domain)))
  (assert (null (plan (state :facts (cons (unavailable :origin) (remove 'm::fork-permitted +fork-evidence+ :key #'first)))
                      (prepare) domain)))
  (unless quiet (pass "UNKNOWN-NOT-ABSENT" "unknown candidate blocks; unknown own page blocks local-only; unknown permission blocks the fork"))
  t)

(defun check-distinctions (&key (domain *domain*) quiet)
  "The outcomes the model must keep apart, and the open fork-source decision both ways."
  ;; Several remote candidates: collaborative takes the first in order (one plan); preparation offers alternatives.
  (let ((o (only (plan (state :facts (list (unavailable :origin) (available :s1) (available :s2))) (collaborative) domain))))
    (assert (eq :s2 (getf o :resolved-at))))
  (let ((two (plan (state :facts (append (list (unavailable :origin) '(m::verified-copy :copy-2 :s2 :target)
                                               '(m::fork-permitted :origin :s2 :target))
                                         +fork-evidence+))
                   (prepare) domain)))
    (assert (= 2 (length two)))
    (assert (every (lambda (o) (eq :fork-planned (getf o :outcome))) two)))
  ;; Not found vs evidence missing.
  (assert (eq :not-found (getf (only (plan (state :facts (list (unavailable :origin) (unavailable :s1) (unavailable :s2)))
                                           (collaborative) domain)) :outcome)))
  ;; Contradictory evidence blocks and is diagnosed.
  (let ((initial (state :facts (list (unavailable :origin) (available :s2) (unavailable :s2) (available :s1)))))
    (assert (null (plan initial (collaborative) domain)))
    (assert (eq :contradictory (getf (rest (m:diagnose-no-plan initial :r :target 'm::collaborative)) :evidence))))
  ;; Open decision: a verified copy suffices only under that explicit policy; without a policy no fork is planned.
  (let ((base (list (unavailable :origin) '(m::verified-copy :copy-1 :s1 :target) '(m::fork-permitted :origin :s1 :target))))
    (assert (null (plan (state :facts base) (prepare) domain)))
    (assert (null (plan (state :facts (cons '(m::fork-source-policy m::require-remote-confirmation) base)) (prepare) domain)))
    (let ((o (only (plan (state :facts (list* '(m::fork-source-policy m::require-remote-confirmation) (available :s1) base))
                         (prepare) domain))))
      (assert (member '(m::planned-fork :origin :target :s1 m::confirmed-remote :s1) (getf o :simulated) :test #'equal)))
    (assert (null (plan (state :facts (list* '(m::fork-forbidden :origin :s1 :target) (first +fork-evidence+) base)) (prepare) domain))))
  (unless quiet (pass "DISTINCTIONS" "first remote candidate wins; fork alternatives; not found vs unknown; contradiction; fork-source policy both ways"))
  t)

(defun check-zero-step-plans (&key (domain *domain*) quiet)
  "A successful task with no primitive step (target already local) is a plan, not a failure, despite the pinned SHOP3
defect in plan-tree extraction for empty plans."
  (multiple-value-bind (outcomes result) (plan (state :facts (list (available :origin))) (prepare) domain)
    (let ((o (only outcomes)))
      (assert (null (getf o :steps)))
      (assert (eq :already-local-observed (getf o :outcome)))
      (assert (equal '((:plan-tree-unavailable :shop3-empty-plan-defect)) (r:plan-trees-of result)))))
  (unless quiet (pass "ZERO-STEP" "empty plan kept as success; tree marked as unavailable (SHOP3 ce53f9b defect)"))
  t)

(defun check-registrations (&key quiet)
  "No problem of ours is left registered, and loading did not make our domain SHOP3's default."
  (let ((package (find-package '#:dreyeck/work/fedwiki-link-resolution)))
    (assert (notany (lambda (p) (let ((name (shop3::name p))) (and (symbolp name) (eq package (symbol-package name)))))
                    shop3::*all-problems*))
    (assert (notany (lambda (p) (search "LINK-RESOLUTION-" (string (shop3::name p)))) shop3::*all-problems*))
    (assert (not (and shop3:*domain* (eq 'm::fedwiki-link-resolution (shop3::domain-name shop3:*domain*))))))
  (unless quiet (pass "REGISTRATIONS" "no leftover problems; SHOP3:*DOMAIN* untouched"))
  t)

;;; 3. Mutants. Each must be killed by the check named with it.

(defun domain-items ()
  (let ((*read-eval* nil) (*package* (find-package '#:dreyeck/work/fedwiki-link-resolution)))
    (with-open-file (in (asdf:system-relative-pathname "dreyeck/work/fedwiki-link-resolution"
                                                       "dreyeck/work/fedwiki-link-resolution.lisp"))
      (loop for form = (read in nil :eof)
            until (eq form :eof)
            when (and (consp form) (eq (first form) 'shop3:defdomain))
              return (copy-tree (third form))))))

(defun in-m (tree)
  "TREE with this package's symbols interned in the model's package, where the domain's labels and variables live."
  (let ((here (find-package '#:dreyeck/work/fedwiki-link-resolution/tests)) (there (find-package '#:dreyeck/work/fedwiki-link-resolution)))
    (labels ((walk (x) (cond ((consp x) (cons (walk (car x)) (walk (cdr x))))
                             ((and (symbolp x) (eq (symbol-package x) here)) (intern (symbol-name x) there))
                             (t x))))
      (walk tree))))
(defun method-item (items label)
  (or (find-if (lambda (i) (and (eq (first i) :method) (eq (third i) (in-m label)))) items) (error "no method ~S" label)))
(defun operator-item (items name)
  (or (find-if (lambda (i) (and (eq (first i) :operator) (eq (first (second i)) (in-m name)))) items) (error "no operator ~S" name)))

(defun killed-p (check &rest keys)
  (let ((*standard-output* (make-broadcast-stream)))
    (handler-case (progn (apply check :quiet t keys) nil)
      (error () t))))

(defun domain-mutant (change check)
  (let ((items (domain-items)) (name (gensym "LINK-RESOLUTION-MUTANT-")))
    (funcall change items)
    (eval `(shop3:defdomain (,name :noset t :silently t) ,items))
    (unwind-protect (killed-p check :domain name)
      (shop3:delete-domain name))))

(defun function-mutant (symbol replacement check)
  (let ((original (fdefinition symbol)))
    (setf (fdefinition symbol) (funcall replacement original))
    (unwind-protect (killed-p check)
      (setf (fdefinition symbol) original))))

(defparameter +mutants+
  `(;; Candidate order: the production functions, replaced for the duration of one check.
    ("journal context oldest first" :function m:java-page-context check-java-agreement
     ,(lambda (original) (declare (ignore original))
        (lambda (sites) (remove-duplicates (remove nil sites) :test #'equal :from-end t))))
    ("item site not moved to the front" :function m:java-link-candidates check-java-agreement
     ,(lambda (original) (lambda (&rest keys) (apply original :item-site nil keys))))
    ("panel site not moved to the front" :function m:java-panel-context check-java-agreement
     ,(lambda (original) (declare (ignore original))
        (lambda (panel-site origin journal-sites) (declare (ignore panel-site origin)) (m:java-page-context journal-sites))))
    ("origin removed from the context" :function m:java-link-candidates check-java-agreement
     ,(lambda (original) (lambda (&rest keys)
                           (let ((all (apply original keys))) (cons (first all) (remove (car (first all)) (rest all) :key #'car :test #'equal))))))
    ;; Local-only gate.
    ("local-only walks the collaborative candidates" :domain check-local-only-gate
     ,(lambda (items) (setf (fifth (method-item items 'own-site-only)) (in-m '((try-candidate ?request ?slug 0))))))
    ("local-only falls back to the context when missing" :domain check-local-only-gate
     ,(lambda (items) (setf (fifth (method-item items 'missing-locally))
                            (in-m '((!request ?request ?own ?slug origin) (try-candidate ?request ?slug 1))))))
    ("local-only forks instead of reporting the miss" :domain check-local-only-gate
     ,(lambda (items) (setf (fifth (method-item items 'missing-locally))
                            (in-m '((!request ?request ?own ?slug origin) (prepare-local-target ?slug) (!use-modeled-page ?request ?own ?slug))))))
    ;; Resolution semantics.
    ("origin skipped" :domain check-local-precedence
     ,(lambda (items) (setf (fifth (method-item items 'walk-candidates)) (in-m '((try-candidate ?request ?slug 1))))))
    ("network error treated as 'not here'" :domain check-java-agreement
     ,(lambda (items)
        (push (in-m '(candidate-after ?request ?position ?next)) (fourth (method-item items 'candidate-request-error)))
        (setf (fifth (method-item items 'candidate-request-error))
              (in-m '((!request ?request ?site ?slug ?source) (try-candidate ?request ?slug ?next))))))
    ("closed world: unknown counts as unavailable" :domain check-unknown-not-absent
     ,(lambda (items)
        (let ((m (method-item items 'candidate-unavailable-next)))
          (setf (fourth m) (subst (in-m '(not (page-available ?site ?slug))) (in-m '(page-unavailable ?site ?slug ?_status)) (fourth m) :test #'equal)))))
    ;; Fork: idempotence and provenance.
    ("fork does not check for a modeled page" :domain check-no-second-fork
     ,(lambda (items)
        (setf (fourth (method-item items 'fork-planned)) (remove (in-m '(not (modeled-local-page ?own ?slug))) (fourth (method-item items 'fork-planned)) :test #'equal))
        (setf (third (operator-item items '!plan-fork)) (remove (in-m '(not (modeled-local-page ?own ?slug))) (third (operator-item items '!plan-fork)) :test #'equal))
        (setf (fourth (method-item items 'already-modeled-local)) (in-m '((origin ?own) (modeled-local-page ?own ?slug) (page-available ?own ?slug))))))
    ("planned fork writes an observation" :domain check-planned-fork-not-executed
     ,(lambda (items) (push (in-m '(page-available ?own ?slug)) (fifth (operator-item items '!plan-fork)))))
    ("fork ignores an explicit prohibition" :domain check-distinctions
     ,(lambda (items)
        (dolist (i (list (method-item items 'fork-planned) (operator-item items '!plan-fork)))
          (let ((place (if (eq (first i) :method) 4 3)))
            (setf (nth (1- place) i) (remove (in-m '(not (fork-forbidden ?own ?remote ?slug))) (nth (1- place) i) :test #'equal))))))
    ("verified copy suffices without the explicit policy" :domain check-distinctions
     ,(lambda (items)
        (let ((axiom (find-if (lambda (i) (and (eq (first i) :-) (equal (second i) (in-m '(fork-source-ok ?remote ?slug verified-copy ?copy))))) items)))
          (setf (third axiom) (in-m '((verified-copy ?copy ?remote ?slug)))))))))

(defun check-unchanged-copy-survives (&key quiet)
  "Control for the mutants: the same copy-and-define path without a change kills nothing, so a killed mutant is
killed by its change and not by the copying."
  (dolist (check '(check-java-agreement check-local-precedence check-local-only-gate check-planned-fork-not-executed
                   check-no-second-fork check-unknown-not-absent check-distinctions check-zero-step-plans))
    (assert (not (domain-mutant (lambda (items) (declare (ignore items))) check)) () "the unchanged copy fails ~A" check))
  (unless quiet (pass "MUTANT-CONTROL" "an unchanged copy of the domain passes all eight domain checks"))
  t)

(defun run-mutants (&key quiet)
  (check-unchanged-copy-survives :quiet quiet)
  (let ((results (loop for (label kind symbol-or-check . rest) in +mutants+
                       collect (cons label
                                     (ecase kind
                                       (:function (function-mutant symbol-or-check (second rest) (first rest)))
                                       (:domain (domain-mutant (first rest) symbol-or-check)))))))
    (unless quiet
      (dolist (r results) (format t "~&LINK-RESOLUTION MUTANT ~:[SURVIVED~;KILLED~]: ~A~%" (cdr r) (car r))))
    (assert (every #'cdr results) () "surviving mutants: ~S" (mapcar #'car (remove-if #'cdr results)))
    (length results)))

(defun run-tests ()
  (check-java-agreement)
  (check-local-precedence)
  (check-context-order)
  (check-local-only-gate)
  (check-planned-fork-not-executed)
  (check-no-second-fork)
  (check-unknown-not-absent)
  (check-distinctions)
  (check-zero-step-plans)
  (let ((n (run-mutants)))
    (check-registrations)
    (format t "~&FEDWIKI-LINK-RESOLUTION-PASS: Java agreement on ~D scenarios; 8 counter-probes and the distinctions; ~D mutants killed; plans only, nothing executed.~%"
            (length (m:load-scenarios)) n))
  t)
