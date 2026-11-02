;;;; The upstream assessment, against synthetic Git and ASDF fixtures: an "upstream" repository with four commits and a "fork" that adopted, replaced and
;;;; extended some of it. Nothing of the fixture's library source is loaded: it holds a canary that must stay untouched and a package that must not appear.
(defpackage #:dreyeck/upstream-assessment/tests
  (:use #:cl)
  (:local-nicknames (#:ua #:dreyeck/upstream-assessment) (#:g #:dreyeck/git))
  (:export #:run-tests #:run-example-tests #:with-fixture #:*upstream* #:*fork* #:*commits* #:*fork-root* #:*upstream-root* #:fixture-policy))
(in-package #:dreyeck/upstream-assessment/tests)

(defvar *upstream-root*) (defvar *fork-root*) (defvar *upstream*) (defvar *fork*)
(defvar *commits* nil "The upstream commits, oldest first: U0 .. U3 (full hashes).")

(defun git (directory &rest arguments)
  (string-trim '(#\Newline #\Space)
               (uiop:run-program (list* "git" "-C" (namestring directory) "-c" "user.name=Fixture" "-c" "user.email=fixture@example.invalid"
                                        "-c" "commit.gpgsign=false" arguments)
                                 :output :string :error-output :string)))

(defun write-file (root path text)
  (let ((file (merge-pathnames path root)))
    (ensure-directories-exist file)
    (with-open-file (out file :direction :output :if-exists :supersede :external-format :utf-8) (write-string text out))))

(defparameter +core-0+ "(in-package :iafx-lib)
;; a comment that must not matter
(defun greet (name) (format nil \"hello ~A\" name))
(defparameter *level* 1)
(setf (get 'iafx-canary 'ran) t)
#.(setf (get 'iafx-canary 'evaluated) t)
")

(defparameter +net-0+ "(in-package :iafx-lib)
(defun connect (host)
  (handler-case (probe host)
    (refused (c) (setf (protocol host) \"http\"))
    (not-found (c) (setf (status host) c)))
  (handler-case (progn (fetch-map host) (fetch-data host) (setf (status host) t))
    ((or stream-error timeout not-found other-error) (c) (setf (status host) c))))
")

(defparameter +helper+ "(defun helper (x) (* 2 x))")
(defun with-greeting (core greeting)
  (let* ((old "(format nil \"hello ~A\" name)") (p (search old core)))
    (concatenate 'string (subseq core 0 p) greeting (subseq core (+ p (length old))))))

(defun make-upstream (root)
  (git root "init" "-q" "-b" "main")
  (write-file root "lib/core.lisp" +core-0+)
  (write-file root "lib/net.lisp" +net-0+)
  (write-file root "iafx-upstream.asd" "(defsystem #:iafx-lib :components ((:module \"lib\" :components ((:file \"core\") (:file \"net\")))))")
  (git root "add" "-A") (git root "commit" "-q" "-m" "U0 base")
  (let ((u0 (git root "rev-parse" "HEAD")))
    ;; U1: the second handler's type list changes, the first handler does not
    (write-file root "lib/net.lisp" (let ((p (search "not-found other-error)" +net-0+)))
                                      (concatenate 'string (subseq +net-0+ 0 p) "name-error other-error)" (subseq +net-0+ (+ p (length "not-found other-error)"))))))
    (git root "commit" "-q" "-am" "U1 Catch more name errors")
    (let ((u1 (git root "rev-parse" "HEAD")))
      ;; U2: a new definition
      (write-file root "lib/core.lisp" (concatenate 'string (with-greeting +core-0+ "(format nil \"hello, ~A!\" name)") +helper+ (string #\Newline)))
      (git root "commit" "-q" "-am" "U2 Add helper, change greeting")
      (let ((u2 (git root "rev-parse" "HEAD")))
        ;; U3: no code
        (write-file root "NOTES.md" "notes")
        (git root "add" "-A") (git root "commit" "-q" "-m" "U3 Notes")
        (list u0 u1 u2 (git root "rev-parse" "HEAD"))))))

(defparameter +fork-net+ "(in-package :iafx-lib)
(defun connect (host) (attempt host))
(defun attempt (host)
  (handler-case (probe host)
    (refused (c) (setf (protocol host) \"http\"))
    (not-found (c) (setf (status host) c)))
  (handler-case (progn (fetch-map host) (fetch-data host) (setf (status host) t))
    ((or stream-error timeout not-found other-error) (c) (setf (status host) c))))
")

(defun make-fork (root upstream-root u0)
  (git root "init" "-q" "-b" "dreyeck")
  (git root "fetch" "-q" (namestring upstream-root) u0)       ; only U0 and its ancestors: U1..U3 are not in the fork
  (git root "checkout" "-q" "-B" "dreyeck" u0)
  (write-file root "lib/net.lisp" +fork-net+)                  ; the changed handler list now stands in ATTEMPT
  ;; HELPER adopted by hand; GREET a local version, neither upstream's before nor its after
  (write-file root "lib/core.lisp" (concatenate 'string (with-greeting +core-0+ "(format nil \"hi ~A\" name)") +helper+ (string #\Newline)))
  (write-file root "ext/extension.lisp" "(defun use-connection (host) (connect host))")
  (write-file root "pages/intro.html" "<p>The connect function is described here.</p>")
  (write-file root "tests/contract.lisp" "(defun check-attempt () (attempt :x)) (defun check-connect () (connect :x))")
  (write-file root "iafx-fork.asd"
              "(defsystem \"iafx-fork/lib\" :components ((:module \"lib\" :components ((:file \"core\") (:file \"net\")))))
(defsystem \"iafx-fork/ext\" :depends-on (\"iafx-fork/lib\") :components ((:module \"ext\" :components ((:file \"extension\")))))
(defsystem \"iafx-fork/tests\" :depends-on (\"iafx-fork/ext\") :components ((:module \"tests\" :components ((:file \"contract\")))))")
  (git root "add" "-A") (git root "commit" "-q" "-m" "fork: attempt, helper, extension"))

(defun fixture-policy ()
  (ua:make-ownership-policy :upstream-paths '("lib") :contract-paths '("tests/contract.lisp") :page-directory "pages"))

(defun call-with-fixture (function)
  (let* ((base (uiop:ensure-directory-pathname (merge-pathnames (format nil "ua-fixture-~D/" (random 1000000 (make-random-state t))) (uiop:temporary-directory))))
         (*upstream-root* (merge-pathnames "upstream/" base)) (*fork-root* (merge-pathnames "fork/" base)))
    (ensure-directories-exist *upstream-root*) (ensure-directories-exist *fork-root*)
    (unwind-protect
         (let ((*commits* (make-upstream *upstream-root*)))
           (make-fork *fork-root* *upstream-root* (first *commits*))
           (asdf:load-asd (merge-pathnames "iafx-fork.asd" *fork-root*))
           (let ((*upstream* (ua:open-repository *upstream-root*)) (*fork* (ua:open-repository *fork-root*)))
             (funcall function)))
      (dolist (name '("iafx-fork/lib" "iafx-fork/ext" "iafx-fork/tests")) (asdf:clear-system name))
      (uiop:delete-directory-tree base :validate t :if-does-not-exist :ignore))))

(defmacro with-fixture (() &body body) `(call-with-fixture (lambda () ,@body)))

(defun repository-fingerprint (root)
  "Everything that a read of a repository must leave as it was: refs, HEAD, the status of the work tree and the number of objects."
  (list (git root "for-each-ref") (git root "rev-parse" "HEAD") (git root "status" "--porcelain") (git root "count-objects" "-v")))

(defun policy-run (&rest arguments)
  (apply #'ua:assess-upstream :fork-repository *fork* :fork-root *fork-root* :policy (fixture-policy) arguments))

(defun assessment-of (sha &key (ledger (ua:make-ledger)) recorded (upstream *upstream*))
  (first (ua:intake-run-commits (policy-run :upstream-repository upstream :commits (list sha) :ledger ledger :recorded-evidence recorded))))

(defun change-of (assessment) (first (ua:commit-assessment-changes assessment)))

;;; Syntax

(defun check-syntax-layer ()
  (let ((a (ua:top-level-definitions "(defun f (x) ; comment
   (+ x 1))
#| block |# (defparameter *p* 2)"))
        (b (ua:top-level-definitions "(DEFUN F (X) (+ X   1)) (defparameter *p* 2)")))
    (assert (equal '("function:f" "parameter:*p*") (mapcar #'ua:source-definition-key a)))
    (assert (equal (mapcar #'ua:source-definition-digest a) (mapcar #'ua:source-definition-digest b)) () "formatting, comments and case must not change a digest"))
  (let ((defs (ua:top-level-definitions "(defmethod print-object :around ((x foo) s) 1) (defmethod print-object ((x bar) s) 2) (setf (get 'a 'b) 1) (setf (get 'c 'd) 2) (defun f ()) (defun f ())")))
    (let ((keys (mapcar #'ua:source-definition-key defs)))
      (assert (equal '("method:print-object::around:foo,t" "method:print-object::bar,t") (subseq keys 0 2)) () "~S" keys)
      (assert (and (uiop:string-prefix-p "form:setf:" (third keys)) (uiop:string-prefix-p "form:setf:" (fourth keys)) (string/= (third keys) (fourth keys))) () "~S" keys)
      (assert (equal '("function:f" "function:f#2") (subseq keys 4)) () "~S" keys)
      ;; an inserted unnamed form does not renumber the others
      (let ((before (ua:top-level-definitions "(setf (get 'a 'b) 1) (setf (get 'c 'd) 2)"))
            (after (ua:top-level-definitions "(setf (get 'x 'y) 0) (setf (get 'a 'b) 1) (setf (get 'c 'd) 2)")))
        (assert (equal (mapcar #'ua:source-definition-key before) (cdr (mapcar #'ua:source-definition-key after)))))))
  ;; the same method spelled with and without the package of its specializer is the same method
  (assert (equal (mapcar #'ua:source-definition-key (ua:top-level-definitions "(defmethod page-class ((h hyperdoc:hyperdoc) (type (eql :html))) 1)"))
                 (mapcar #'ua:source-definition-key (ua:top-level-definitions "(defmethod page-class ((h hyperdoc) (type (eql :html))) 2)"))))
  ;; a reader-evaluation form is data, not an instruction
  (setf (get 'iafx-unit-canary 'ran) nil)
  (ua:top-level-definitions "#.(setf (get 'iafx-unit-canary 'ran) t) (in-package :nowhere-at-all) (defun x () (nowhere:thing))")
  (assert (null (get 'iafx-unit-canary 'ran)))
  (assert (null (find-package "NOWHERE-AT-ALL")))
  (let ((fragments (ua:changed-fragments '("or" "a" "b" "c") '("or" "a" "x" "c"))))
    (assert (equal '((("or" "a" "b" "c") . ("or" "a" "x" "c"))) fragments)))
  (assert (null (ua:changed-fragments '("f" ("g" "1")) '("f" ("g" "1")))))
  (let ((profiles (ua:handler-profiles (ua:source-definition-tree (find "function:connect" (ua:top-level-definitions +net-0+) :key #'ua:source-definition-key :test #'equal)))))
    (assert (= 2 (length profiles)))
    (assert (equal '("probe") (getf (first profiles) :protected-calls)))
    (assert (equal '("fetch-map" "fetch-data" "status") (getf (second profiles) :protected-calls)))
    (assert (equal '("(or stream-error timeout not-found other-error)") (getf (second profiles) :clauses))))
  t)

;;; The one-commit story: U1 changes a handler list that the fork has moved into another definition

(defun check-replaced-handler (&optional (u1 (second *commits*)))
  (let* ((assessment (assessment-of u1)) (change (change-of assessment))
         (c (ua:change-assessment-change change)) (s (ua:change-assessment-situation change)) (i (ua:change-assessment-impact change))
         (o (ua:change-assessment-ownership change)))
    (assert (eq :git-object (ua:commit-evidence-availability (ua:commit-assessment-evidence assessment))))
    (assert (= 1 (length (ua:commit-assessment-changes assessment))))
    (assert (equal "function:connect" (ua:definition-change-key c))) (assert (eq :changed (ua:definition-change-kind c)))
    (assert (equal "lib/net.lisp" (ua:definition-change-path c)))
    ;; what upstream changed: the type list of the second handler, and not the first
    (assert (= 1 (length (ua:definition-change-fragments c))))
    (destructuring-bind (b . a) (first (ua:definition-change-fragments c))
      (assert (and (member "not-found" b :test #'equal) (not (member "not-found" a :test #'equal)) (member "name-error" a :test #'equal))))
    (let ((handlers (ua:definition-change-handlers c)))
      (assert (equal '(nil t) (mapcar (lambda (h) (getf h :changed-p)) handlers)) () "the first handler must be unchanged and the second changed: ~S" handlers))
    ;; where it stands in the fork: the definition is there, its changed part is not; the part stands in ATTEMPT
    (assert (eq :replaced (ua:fork-situation-relation s)))
    (let ((fragment (first (ua:fork-situation-fragments s))))
      (assert (eq :before-elsewhere (getf fragment :status)))
      (assert (equal "function:attempt" (second (first (getf fragment :elsewhere))))))
    ;; who owns it, who should, what it may affect
    (assert (equal '("iafx-fork/lib") (ua:change-assessment-owners change)))
    (assert (eq :upstream-owned (getf o :category)))
    (assert (equal '("iafx-fork/lib") (getf o :should-own)))
    (assert (equal '("iafx-fork/ext" "iafx-fork/lib" "iafx-fork/tests") (ua:impact-systems i)))
    (assert (equal '("iafx-fork/tests") (ua:impact-tests i)))
    (assert (find "function:use-connection" (ua:impact-callers i) :key #'second :test #'equal))
    (assert (equal '("pages/intro.html") (ua:impact-pages i)))
    (assert (equal '(("tests/contract.lisp" 2)) (ua:impact-contracts i)))
    ;; the decision: a proposal, never an execution, and a difference needs a person
    (assert (eq :defer (ua:decision-kind (ua:change-assessment-proposal change))))
    (assert (eq :proposed (ua:decision-status (ua:change-assessment-proposal change))))
    ;; the fork's own Git does not have the commit, whatever its source says
    (assert (eq :not-available-locally (getf (ua:commit-assessment-integration assessment) :classification)))
    (assert (eq :none-adopted (ua:commit-assessment-source-adoption assessment))))
  t)

(defun check-extended-fragment ()
  "A fork that did not take the commit's list but extended the old one (as RalfBarkow/hyperdoc#15 does) is a replacement, found as an extension."
  (let ((original (uiop:read-file-string (merge-pathnames "lib/net.lisp" *fork-root*))))
    (unwind-protect
         (progn
           (write-file *fork-root* "lib/net.lisp"
                       (let ((p (search "other-error)" original)))
                         (concatenate 'string (subseq original 0 p) "other-error extra-error)" (subseq original (+ p (length "other-error)"))))))
           (let* ((change (change-of (assessment-of (second *commits*)))) (s (ua:change-assessment-situation change)))
             (assert (eq :replaced (ua:fork-situation-relation s)))
             (assert (eq :extended-elsewhere (getf (first (ua:fork-situation-fragments s)) :status)))))
      (write-file *fork-root* "lib/net.lisp" original)))
  t)

(defun check-adoption-is-not-ancestry ()
  (let* ((assessment (assessment-of (third *commits*)))
         (helper (find "function:helper" (ua:commit-assessment-changes assessment) :key (lambda (c) (ua:definition-change-key (ua:change-assessment-change c))) :test #'equal))
         (greet (find "function:greet" (ua:commit-assessment-changes assessment) :key (lambda (c) (ua:definition-change-key (ua:change-assessment-change c))) :test #'equal)))
    (assert (= 2 (length (ua:commit-assessment-changes assessment))))
    (assert (eq :adopted (ua:fork-situation-relation (ua:change-assessment-situation helper))))
    (assert (eq :already-covered (ua:decision-kind (ua:change-assessment-proposal helper))))
    ;; a local version of a definition is not an adoption of the commit's
    (assert (eq :changed (ua:fork-situation-relation (ua:change-assessment-situation greet))))
    (assert (eq :defer (ua:decision-kind (ua:change-assessment-proposal greet))))
    (assert (eq :partial (ua:commit-assessment-source-adoption assessment)))
    (let ((integration (ua:commit-assessment-integration assessment)))
      (assert (eq :not-available-locally (getf integration :classification)) () "a definition stands in the fork's source; its commit is not in the fork's history")
      (assert (null (getf integration :ancestor-of-head-p)))))
  ;; the base commit IS in the fork's history, and nothing in it changes anything
  (let* ((assessment (assessment-of (first *commits*))) (integration (ua:commit-assessment-integration assessment)))
    (assert (eq :already-integrated (getf integration :classification)))
    (assert (getf integration :ancestor-of-head-p)))
  ;; a commit that changes no code
  (let ((assessment (assessment-of (fourth *commits*))))
    (assert (null (ua:commit-assessment-changes assessment)))
    (assert (eq :no-code-change (ua:commit-assessment-source-adoption assessment))))
  t)

(defun check-runs-and-observation ()
  (let ((state (list :upstream-intake-state :last-examined (first *commits*))))
    (let ((run (policy-run :upstream-repository *upstream* :state state)))
      (assert (eq :new-commits (ua:intake-run-status run))) (assert (= 10 (ua:run-exit-status run)))
      (assert (equal (rest *commits*) (mapcar (lambda (a) (ua:commit-evidence-sha (ua:commit-assessment-evidence a))) (ua:intake-run-commits run)))
              () "the three new commits, oldest first, each once")
      (assert (equal (fourth *commits*) (ua:upstream-observation-tip (ua:intake-run-observation run))) () "observed tip: the fixture's main is U3")
      (let ((report (with-output-to-string (s) (ua:report-run run s))))
        (assert (search "Upstream intake" report)) (assert (search "source adoption" report))))
    ;; observing again, and from the last examined tip, finds nothing new
    (let ((run (policy-run :upstream-repository *upstream* :state (list :upstream-intake-state :last-examined (fourth *commits*)))))
      (assert (eq :up-to-date (ua:intake-run-status run))) (assert (= 0 (ua:run-exit-status run)))))
  ;; a commit that is nowhere: missing evidence, and nothing was fetched
  (let* ((before (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*)))
         (run (policy-run :upstream-repository *upstream* :commits (list "0123456789abcdef0123456789abcdef01234567")))
         (assessment (first (ua:intake-run-commits run))))
    (assert (eq :evidence-missing (ua:intake-run-status run))) (assert (= 20 (ua:run-exit-status run)))
    (assert (eq :missing (ua:commit-evidence-availability (ua:commit-assessment-evidence assessment))))
    (assert (eq :undetermined (ua:commit-assessment-source-adoption assessment)))
    (assert (equal before (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*))) () "a read changed a repository"))
  t)

(defun check-nothing-executed-nothing-changed ()
  (setf (get 'iafx-canary 'ran) nil (get 'iafx-canary 'evaluated) nil)
  (let ((before (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*))))
    (dolist (sha *commits*) (assessment-of sha))
    (policy-run :upstream-repository *upstream* :state (list :upstream-intake-state :last-examined (first *commits*)))
    (assert (null (get 'iafx-canary 'ran))) (assert (null (get 'iafx-canary 'evaluated)))
    (assert (null (find-package "IAFX-LIB")) () "a library package of the fixture was created")
    (assert (equal before (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*))) () "an assessment changed a repository"))
  t)

(defun check-recorded-evidence ()
  (let* ((u1 (second *commits*)) (file (merge-pathnames "u1-evidence.lisp-data" (uiop:temporary-directory)))
         (live (assessment-of u1)))
    (unwind-protect
         (progn
           (ua:write-recorded-evidence (ua:commit-assessment-evidence live) file :recorded-from '(:repository "fixture" :method "evidence-from-repository"))
           (let* ((evidence (ua:read-recorded-evidence file))
                  (recorded (assessment-of u1 :upstream nil :recorded (list evidence)))
                  (a (change-of live)) (b (change-of recorded)))
             (assert (eq :recorded (ua:commit-evidence-availability (ua:commit-assessment-evidence recorded))))
             (assert (equal (ua:definition-change-key (ua:change-assessment-change a)) (ua:definition-change-key (ua:change-assessment-change b))))
             (assert (eq (ua:fork-situation-relation (ua:change-assessment-situation a)) (ua:fork-situation-relation (ua:change-assessment-situation b)))
                     () "recorded evidence must give the same situation as the objects")
             (assert (equal (mapcar (lambda (h) (getf h :changed-p)) (ua:definition-change-handlers (ua:change-assessment-change a)))
                            (mapcar (lambda (h) (getf h :changed-p)) (ua:definition-change-handlers (ua:change-assessment-change b)))))
             (assert (eq :verified (ua:verify-recorded-evidence evidence *upstream*)))
             (assert (eq :unverifiable (ua:verify-recorded-evidence evidence *fork*)) () "the fork does not have the object: unverifiable, not verified")
             ;; a recorded text that is not what the objects say
             (let ((tampered (ua:read-recorded-evidence file)))
               (let* ((change (first (ua:commit-evidence-changes tampered)))
                      (after (ua:definition-change-after change)))
                 (setf (ua:source-definition-digest after) "0000"))
               (assert (eq :mismatch (ua:verify-recorded-evidence tampered *upstream*))))))
      (ignore-errors (delete-file file))))
  t)

(defun check-ledger ()
  (let* ((ledger (ua:make-ledger)) (u1 (second *commits*))
         (d (ua:make-decision :commit u1 :subject "lib/net.lisp::function:connect" :kind :defer :status :proposed :rationale "r"
                              :evidence (list (ua:make-claim "e" :source-observed '("b"))) :proposed-by "fixture")))
    (assert (eq (ua:ledger-record ledger d) (ua:ledger-record ledger d)))
    (assert (eq (ua:ledger-record ledger d)
                (ua:ledger-record ledger (ua:make-decision :commit u1 :subject "lib/net.lisp::function:connect" :kind :defer :status :proposed :rationale "r"
                                                           :evidence (list (ua:make-claim "e" :source-observed '("b"))) :proposed-by "fixture")))
            () "the same decision, recorded again, is the one recorded")
    (assert (= 1 (length (ua:ledger-decisions ledger))))
    (assert (handler-case (progn (ua:ledger-record ledger (ua:make-decision :commit u1 :subject "lib/net.lisp::function:connect" :kind :adopt-upstream-change
                                                                            :rationale "other" :proposed-by "fixture"))
                                 nil)
              (ua:decision-conflict () t)) () "a different decision for the same subject is a conflict, not an overwrite")
    (assert (handler-case (ua:make-decision :commit u1 :subject "x" :kind :merge-it) (error () t)))
    (assert (handler-case (ua:make-claim "x" :certain) (error () t)))
    ;; round trip as plain data
    (let ((back (ua:ledger-from-form (read-from-string (prin1-to-string (ua:ledger-form ledger))))))
      (assert (equal (ua:ledger-form ledger) (ua:ledger-form back))))
    ;; a recorded decision stands beside the proposal in the assessment, and observing twice adds nothing
    (let* ((change (change-of (assessment-of u1 :ledger ledger))) (again (change-of (assessment-of u1 :ledger ledger))))
      (assert (= 1 (length (ua:change-assessment-recorded change)))) (assert (= 1 (length (ua:change-assessment-recorded again))))
      (assert (equal (ua:decision-id (first (ua:change-assessment-recorded change))) (ua:decision-id (first (ua:change-assessment-recorded again)))))
      (assert (eq :proposed (ua:decision-status (ua:change-assessment-proposal change))))))
  t)

(defun run-tests ()
  (check-syntax-layer)
  (with-fixture ()
    (let ((untouched (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*))))
      (run-fixture-checks)
      (assert (equal untouched (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*)))
              () "the whole run, every assessment of every commit, left both repositories exactly as it found them")))
  (format t "~&UPSTREAM-ASSESSMENT-PASS: syntax without READ; a replaced handler, adoption without ancestry, runs over several commits, missing and recorded evidence, nothing executed or changed, the ledger.~%")
  t)

(defun run-fixture-checks ()
  (progn
    (check-replaced-handler)
    (check-extended-fragment)
    (check-adoption-is-not-ancestry)
    (check-runs-and-observation)
    (check-nothing-executed-nothing-changed)
    (check-recorded-evidence)
    (check-ledger)))
