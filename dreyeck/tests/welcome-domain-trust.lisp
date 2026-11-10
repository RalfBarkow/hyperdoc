;;;; D1 review probes: all tags/writes belong to a disposable test repository.
(in-package #:dreyeck/work/welcome-development)

(defvar *w2-special-argument* 0)
(defvar ?w2-unbound-special)
(defvar ?w2-special-argument 0) ; A Lisp special can also have a SHOP3 variable name.

(defun w2-trust-cases ()
  ;; Source strings and expected native items are independently retained fixtures.
  ;; Historical source is never read by the host reader to manufacture a tag ID.
  (list
   (list :d "((slice ?s) (shop3:call < (clear-development-domain-cache) 1))"
         '((slice ?s) (shop3:call < (clear-development-domain-cache) 1)))
   (list :e "(:sort-by (clear-development-domain-cache) ((slice ?s)))"
         '(:sort-by (clear-development-domain-cache) ((slice ?s))))
   (list :special-variable "((shop3:call < *w2-special-argument* 1))"
         '((shop3:call < *w2-special-argument* 1)))
   (list :sort-comparison "(:sort-by ?s (clear-development-domain-cache) ((slice ?s)))"
         '(:sort-by ?s (clear-development-domain-cache) ((slice ?s))))
   (list :method-task "()" nil "((shop3:call < (clear-development-domain-cache) 1))"
         '((shop3:call < (clear-development-domain-cache) 1)))
   (list :method-task-flat-call "()" nil "((shop3:call < 0 1))" '((shop3:call < 0 1)))
   (list :special-shop-variable "((shop3:call < ?w2-special-argument 1))"
         '((shop3:call < ?w2-special-argument 1)))
   (list :unbound-special "((shop3:call < ?w2-unbound-special 1))"
         '((shop3:call < ?w2-unbound-special 1)))
   (list :keyword-variable "((shop3:call < :?w2-argument 1))"
         '((shop3:call < :?w2-argument 1)))
   (list :nested-call "((shop3:call < (shop3:call < 0 1) 1))"
         '((shop3:call < (shop3:call < 0 1) 1)))
   (list :bare-symbol "((shop3:call < clear-development-domain-cache 1))"
         '((shop3:call < clear-development-domain-cache 1)))
   (list :under-not "((not (shop3:call < (clear-development-domain-cache) 1)))"
         '((not (shop3:call < (clear-development-domain-cache) 1))))
   (list :under-or "((or (shop3:call < (clear-development-domain-cache) 1) (slice s1)))"
         '((or (shop3:call < (clear-development-domain-cache) 1) (slice s1))))
   (list :under-forall "((shop3:forall (?s) ((slice ?s)) ((shop3:call < (clear-development-domain-cache) 1))))"
         '((shop3:forall (?s) ((slice ?s)) ((shop3:call < (clear-development-domain-cache) 1)))))
   (list :nested-predicate-term "((probe (clear-development-domain-cache)))"
         '((probe (clear-development-domain-cache))))
   (list :effect-call "()" nil nil nil "((shop3:call < 0 1))" '((shop3:call < 0 1)))
   (list :effect-forall-call "()" nil nil nil
         "((shop3:forall (?s) ((slice ?s) (shop3:call < 0 1)) ((planned-complete-report))))"
         '((shop3:forall (?s) ((slice ?s) (shop3:call < 0 1)) ((planned-complete-report)))))
   (list :effect-sort "()" nil nil nil
         "((shop3:forall (?s) (:sort-by (clear-development-domain-cache) ((slice ?s))) ((planned-complete-report))))"
         '((shop3:forall (?s) (:sort-by (clear-development-domain-cache) ((slice ?s))) ((planned-complete-report)))))
   (list :operator-precondition "()" nil nil nil nil nil
         "((shop3:call < (clear-development-domain-cache) 1))"
         '((shop3:call < (clear-development-domain-cache) 1)))
   (list :axiom-body "((probe ?s))" '((probe ?s)) nil nil nil nil nil nil
         "((shop3:call < (clear-development-domain-cache) 1))"
         '((shop3:call < (clear-development-domain-cache) 1)))))

(defun w2-trust-fixture (case)
  (destructuring-bind (label pre-text pre &optional task-text tasks effect-text effects
                      op-pre-text op-pre axiom-text axiom-body) case
    (declare (ignore label))
    (let* ((items (list (list :operator '(!report-complete) op-pre nil
                             (if effect-text effects '((planned-complete-report))))
                        (list :method '(advance-welcome) 'probe pre
                              (if task-text tasks '((!report-complete)))))))
      (when axiom-text (setf items (append items (list (list :- '(probe ?s) axiom-body)))))
      (values
       (format nil "(shop3:defdomain (welcome-development :noset t)~% ((:operator (!report-complete) ~A () ~A)~% (:method (advance-welcome) probe ~A ~A)~A))"
               (or op-pre-text "()") (or effect-text "((planned-complete-report))")
               pre-text (or task-text "((!report-complete))")
               (if axiom-text (format nil "~% (:- (probe ?s) ~A)" axiom-text) ""))
       items))))

(defun w2-trust-record (root source items)
  (let* ((path "dreyeck/work/welcome-development.lisp")
         (repository (make-instance 'dreyeck/git:git-repository-checkout :root root :root-source :disposable-trust-probe))
         (id (domain-version-id (cons '(:operator (shop3::!!inop) () () () 0) (copy-tree items)))))
    (w2-write (merge-pathnames path root) source)
    (w2-write (merge-pathnames +validator-path+ root) ";; Test validator provenance only, never loaded.")
    (w2-fixture-git root "add" ".") (w2-fixture-git root "commit" "-qm" "Tagged trust probe")
    (let ((commit (w2-fixture-git root "rev-parse" "HEAD")))
      (w2-fixture-git root "tag" (subseq (domain-version-tag id) 10) commit)
      (make-development-record 'dev-domain-version id :observed
       :version-id id :items-source :git :repository repository :tag (domain-version-tag id)
       :commit commit :path path :blob (version-git repository "rev-parse" (format nil "~A:~A" commit path))
       :form-sha256 (text-sha256 source) :reader (copy-tree +domain-reader-contract+)
       :planner (running-development-planner-pin)
       :validator (list :path +validator-path+ :blob (version-git repository "rev-parse" (format nil "~A:~A" commit +validator-path+)))))))

(defun w2-cache-snapshot ()
  (loop for id being the hash-keys of *development-domain-cache* using (hash-value entry) collect (cons id entry)))
(defun w2-cache-unchanged (snapshot)
  (assert (= (length snapshot) (hash-table-count *development-domain-cache*)))
  (dolist (pair snapshot) (assert (eq (cdr pair) (gethash (car pair) *development-domain-cache*)))))

(defun run-domain-trust-probes (&optional baseline)
  (let ((root (uiop:ensure-directory-pathname
               (string-trim '(#\Newline #\Return)
                            (uiop:run-program '("mktemp" "-d" "-t" "hyperdoc-d1-XXXXXXXX") :output :string)))))
    (unwind-protect
         (progn
           (w2-fixture-git root "init" "-q")
           (w2-fixture-git root "config" "user.email" "fixture@example.invalid")
           (w2-fixture-git root "config" "user.name" "D1 disposable fixture")
           (dolist (case (if baseline (subseq (w2-trust-cases) 0 2) (w2-trust-cases)))
             (clear-development-domain-cache)
             (admit-development-domain-version (fixture-domain-version-record))
             (multiple-value-bind (text items) (w2-trust-fixture case)
               (let* ((record (w2-trust-record root text items)) (public (w2-public-snapshot))
                      (cache (w2-cache-snapshot)) (problems (copy-list shop3::*all-problems*))
                      (current shop3::*problem*) (builds 0) (calls 0))
                 (w2-wrapped (shop3::make-domain (lambda (original &rest args) (incf builds) (apply original args)))
                   (w2-wrapped (clear-development-domain-cache
                                (lambda (original &rest args) (incf calls) (apply original args)))
                     (if baseline
                         (let* ((version (admit-development-domain-version record))
                                (before (hash-table-count *development-domain-cache*))
                                (result (plan-development-state '((slice s1) (slice s2)) (domain-version-domain version))))
                           (assert (plusp builds)) (assert (plusp calls))
                           (assert (zerop (hash-table-count *development-domain-cache*)))
                           (assert (eq :plan-only (dreyeck/shop3:execution-mode-of result)))
                           (format t "~&D1 BASELINE ~A: admitted; builds=~D; cache-clear calls=~D; cache ~D -> 0; ~D native plans; :PLAN-ONLY.~%"
                                   (first case) builds calls before (length (dreyeck/shop3:plans-of result))))
                         (progn
                           (w2-refuses :domain-version-untrusted (lambda () (admit-development-domain-version record)))
                           (assert (zerop builds)) (assert (zerop calls)) (w2-cache-unchanged cache)
                           (format t "~&D1 ~A PASS: refused before construction; builds=0; cache-clear calls=0; cache/public/problem registry unchanged.~%" (first case))))))
                 (w2-public-unchanged public)
                 (assert (equal problems shop3::*all-problems*)) (assert (eq current shop3::*problem*)))))
           (unless baseline
             ;; Read the exact accepted W1 blob locally; no tag is created in the project.
             (let* ((repository (make-instance 'dreyeck/git:git-repository-checkout
                                               :root (asdf:system-source-directory "dreyeck/work/welcome-development")
                                               :root-source :accepted-w1-local-source))
                    (text (development-domain-form-text
                           (version-git repository "show" "61cdec068116891d8455cdff9bb7b81ef1df171a:dreyeck/work/welcome-development.lisp")))
                    (items (read-development-domain-form text))
                    (record (w2-trust-record root text items))
                    (version (admit-development-domain-version record))
                    (state (project-development-records (list (fixture-policy))))
                    (result (plan-development-state state (domain-version-domain version)))
                    (plans (dreyeck/shop3:plans-of result)))
               (assert (equal (domain-version-identity version)
                              (domain-version-id (shop3::domain-items (shop3:find-domain 'welcome-development)))))
               (assert (= 2 (length plans) (length (dreyeck/shop3:plan-trees-of result))
                          (length (dreyeck/shop3:final-states-of result))))
               (dolist (executor '(codex claude-code))
                 (assert (member `((!assign s1 ,executor ,+fixture-base+)) plans :test #'equal)))
               (assert (eq :plan-only (dreyeck/shop3:execution-mode-of result)))
               (format t "~&D1 W1-61CDEC0 PASS: exact tagged source admitted; two expected S1 assignments, native trees/states and :PLAN-ONLY.~%"))))
      (clear-development-domain-cache)
      (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore)))
  t)
