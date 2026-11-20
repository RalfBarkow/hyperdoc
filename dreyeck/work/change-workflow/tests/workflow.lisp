(in-package #:change-workflow)

(defvar *checks* 0)
(defmacro check (form) `(progn (assert ,form () "Failed: ~S" ',form) (incf *checks*)))

(defun with-facts (changes &rest updates)
  "A copy of CHANGES with (ID FACT ...) added to the named changes."
  (let ((copy (copy-tree changes)))
    (dolist (u updates copy)
      (let ((c (find (first u) copy :key (lambda (c) (getf c :id)))))
        (dolist (f (rest u)) (push (list f "test" "test") (getf c :facts)))))))

(defun offers-for (changes) (let ((*register* changes)) (offers (plan-next changes))))
(defun offered (offers step id) (find (list step id) offers :test #'equal))

(defun initial-register ()
  (load-register (asdf:system-relative-pathname "change-workflow" "tests/register-2026-11-20-initial.sexp")))

(defun test-register-now ()
  "The register as it stood when the plan was written: what the plan proposed then."
  (let ((o (offers-for (initial-register))))
    (check (offered o 'merge :faq-store-gc))
    (check (offered o 'wait-for-dependency :fleet-faq-pin))
    (check (not (offered o 'pull-request :fleet-faq-pin)))
    (check (offered o 'pull-request :operator-keys))
    (dolist (id '(:local-topics :five-ways :codepath-review :site-observation))
      (check (offered o 'review id))
      (check (not (offered o 'pull-request id))))))

(defun test-progress ()
  (let* ((r (initial-register))
         (r1 (with-facts r '(:faq-store-gc :merged)))
         (o1 (offers-for r1)))
    ;; The hyperdoc change is merged: the fleet pin must move to the merged commit before anything else.
    (check (offered o1 'repin :fleet-faq-pin))
    (check (not (offered o1 'merge :fleet-faq-pin)))
    (let* ((r2 (with-facts r1 '(:fleet-faq-pin :pin-on-merged :pr-open)))
           (o2 (offers-for r2)))
      (check (offered o2 'merge :fleet-faq-pin))
      ;; Another fleet branch runs unmerged on staging: a second one waits for staging.
      (let ((o3 (offers-for (with-facts r2 '(:operator-keys :pr-open)))))
        (check (offered o3 'wait-for-staging :operator-keys))
        (check (not (offered o3 'staging :operator-keys))))
      (let* ((r4 (with-facts r2 '(:fleet-faq-pin :merged) '(:operator-keys :pr-open)))
             (o4 (offers-for r4)))
        (check (offered o4 'staging :operator-keys))
        (let ((o5 (offers-for (with-facts r4 '(:operator-keys :staging-accepted :merged)))))
          (check (offered o5 'production :operator-keys))
          (let ((done (with-facts r4 '(:operator-keys :staging-accepted :merged :production-done)
                        '(:local-topics :seen :pr-open :merged) '(:five-ways :seen :pr-open :merged)
                        '(:codepath-review :seen :pr-open :merged) '(:site-observation :seen :pr-open :merged))))
            (check (null (offers-for done)))))))))

(defun test-live-register ()
  "The register as committed now reads, plans, and names only known steps."
  (let ((o (offers-for (load-register))))
    (check (every (lambda (x) (assoc (first x) +steps+)) o))
    (check (offered o 'merge :fleet-faq-pin))
    (check (not (find :faq-store-gc o :key #'second)))))

(defun test-reasons ()
  (let* ((*register* (load-register)) (plan (plan-next)) (facts (dreyeck/shop3::initial-facts-of plan)))
    ;; Every offer has a method of the domain behind it.
    (dolist (o (offers plan))
      (check (assoc (first o) +methods+))
      (check (search "Methode" (first (reasons (first o) (second o) facts)))))
    (let ((why (format nil "~{~A~^ | ~}" (reasons 'merge :fleet-faq-pin facts))))
      (check (search "Methode merge" why))
      (check (search "pin-on-merged" why))
      (check (search "staging-accepted" why))))
  ;; Blocked staging names the branch that holds staging.
  (let* ((*register* (with-facts (load-register) '(:operator-keys :pr-open)))
         (plan (plan-next *register*))
         (why (format nil "~{~A~^ | ~}" (reasons 'wait-for-staging :operator-keys (dreyeck/shop3::initial-facts-of plan)))))
    (check (offered (offers plan) 'wait-for-staging :operator-keys))
    (check (search "fleet: staging-Pin der FAQ" why))))

(defun test-view ()
  (let* ((*register* (initial-register))
         (page (hb:find-page (make-instance 'workflow-book :id +book-id+) "overview" :signal-error? t))
         (html (v:view-html (first (v:all-views page)))))
    (check (search "Mergen (Operator)" (plump:decode-entities html)))
    (check (search "Play" html))
    ;; The renderer may write the umlaut as an entity; the rest of the title is plain.
    (check (search "nderung vom Branch bis auf die Server bringen" html))
    (check (search "Methode" html))
    (check (not (search "dita-unsupported" html)))))

(defun run-tests ()
  (let ((*checks* 0))
    (test-register-now) (test-progress) (test-live-register) (test-reasons) (test-view)
    (format t "~&change-workflow: ~D checks passed.~%" *checks*)
    *checks*))
