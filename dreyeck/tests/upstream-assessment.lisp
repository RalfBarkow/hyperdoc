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


;;; Identity of definitions: the five points. Keys are of source text and package context only; nothing is read, nothing is loaded.

(defun keys-of (text) (mapcar #'ua:source-definition-key (ua:top-level-definitions text)))
(defun last-key (text) (car (last (keys-of text))))

(defun check-package-context ()
  "HYPERDOC:HYPERDOC and HYPERDOC are one symbol only where the file's own package says so; nowhere is a name normalized by its symbol name alone."
  (let ((qualified "(defmethod page-class ((h hyperdoc:hyperdoc) (type (eql :html))) 1)") (plain "(defmethod page-class ((h hyperdoc) (type (eql :html))) 2)")
        (function-q "(defun hyperdoc::render (x) 1)") (function-p "(defun render (x) 2)"))
    ;; without a package context nothing shows them to be the same
    (assert (not (equal (keys-of qualified) (keys-of plain))) () "no in-package: HYPERDOC:HYPERDOC is not shown to be HYPERDOC")
    (assert (not (equal (keys-of function-q) (keys-of function-p))))
    ;; in the file's own package they are the same symbol: same key, whichever way the package is named
    (dolist (in-package '("(in-package :hyperdoc)" "(in-package #:hyperdoc)" "(in-package \"HYPERDOC\")" "(in-package hyperdoc)"))
      (assert (equal (last-key (format nil "~A ~A" in-package qualified)) (last-key (format nil "~A ~A" in-package plain))) () "~A" in-package)
      (assert (equal (last-key (format nil "~A ~A" in-package function-q)) (last-key (format nil "~A ~A" in-package function-p))) () "~A" in-package))
    ;; in another package, or with another qualifier, they are not
    (assert (not (equal (last-key (format nil "(in-package :other) ~A" qualified)) (last-key (format nil "(in-package :other) ~A" plain)))))
    (assert (not (equal (last-key (format nil "(in-package :hyperdoc) ~A" "(defun other:render (x) 1)")) (last-key (format nil "(in-package :hyperdoc) ~A" function-p)))))
    ;; the context is that of the form: a later IN-PACKAGE changes it for the forms after it, not for those before
    (assert (equal '("in-package:a" "function:f" "in-package:b" "function:a:f") (keys-of "(in-package :a) (defun a:f ()) (in-package :b) (defun a:f ())")))
    ;; the same text in two files with different contexts has two keys: the key is of the text in its context, never of the symbol name alone
    (assert (not (equal (last-key "(in-package :hyperdoc) (defun hyperdoc:x ())") (last-key "(in-package :elsewhere) (defun hyperdoc:x ())"))))
    ;; in a change between two versions, the spellings are told apart without a context and the same with one
    (let ((without (ua:definition-changes "lib/a.lisp" plain qualified))
          (within (ua:definition-changes "lib/a.lisp" (format nil "(in-package :hyperdoc) ~A" plain) (format nil "(in-package :hyperdoc) ~A" qualified))))
      (assert (equal '(:added :removed) (sort (mapcar #'ua:definition-change-kind without) #'string<)) () "without context: one removed, one added, never one changed")
      (dolist (c without) (assert (= 1 (length (ua:definition-change-counterparts c))) () "the other spelling is shown as a possible counterpart"))
      (assert (equal '(:changed) (mapcar #'ua:definition-change-kind within))))
    ;; a candidate is not an equation: counterparts are listed, and the two keys stay two
    (let ((c (find :added (ua:definition-changes "lib/a.lisp" plain qualified) :key #'ua:definition-change-kind)))
      (assert (not (equal (ua:definition-change-key c) (first (ua:definition-change-counterparts c)))))))
  t)

(defun check-method-identity ()
  "A method is its generic function, its qualifiers and its specializers, as written."
  (let* ((base "(defmethod render ((x page) (type (eql :html))) 1)")
         (variants (list base
                         "(defmethod display ((x page) (type (eql :html))) 1)"                  ; other generic function
                         "(defmethod render :around ((x page) (type (eql :html))) 1)"          ; qualifier
                         "(defmethod render :before ((x page) (type (eql :html))) 1)"          ; other qualifier
                         "(defmethod render ((x view) (type (eql :html))) 1)"                  ; other specializer
                         "(defmethod render ((x page) (type (eql :json))) 1)"                  ; other eql specializer
                         "(defmethod render ((x page) type) 1)"                                ; unspecialized second argument
                         "(defmethod render ((x page)) 1)"                                     ; fewer arguments
                         "(defmethod (setf render) (v (x page)) v)"))                          ; a setf method
         (keys (mapcar #'last-key variants)))
    (assert (= (length keys) (length (remove-duplicates keys :test #'equal))) () "every difference of generic function, qualifier or specializer is a different key: ~S" keys)
    ;; what does not belong to the identity does not change it
    (assert (equal (last-key base) (last-key "(defmethod RENDER ((object page) (kind (eql :html)))
  ;; a comment
  (list 1 2 3))")) () "parameter names, body, case and layout are not identity")
    (assert (equal (last-key base) (last-key "(defmethod render ((x page) (type (eql :html)) &key a b) 1)")) () "lambda-list keywords after the specializers are not identity"))
  ;; two methods of one generic function are two definitions that a change tells apart
  (let ((changes (ua:definition-changes "lib/m.lisp" "(defmethod render ((x page)) 1) (defmethod render ((x view)) 1)" "(defmethod render ((x page)) 1) (defmethod render ((x view)) 2)")))
    (assert (= 1 (length changes)))
    (assert (equal "method:render::view" (ua:definition-change-key (first changes)))))
  t)

(defun check-repeated-anonymous-forms ()
  "Forms that define nothing named are identified by their text; identical ones are told apart by their number among the identical, and different ones never merge."
  (let ((a "(setf (get 'a 'b) 1)") (b "(setf (get 'c 'd) 2)"))
    (let ((keys (keys-of (format nil "~A ~A ~A" a a b))))
      (assert (= 3 (length (remove-duplicates keys :test #'equal))) () "~S" keys)
      (assert (equal (first keys) (subseq (second keys) 0 (position #\# (second keys)))) () "the second identical form is numbered, the first is not")
      (assert (uiop:string-suffix-p (second keys) "#2")))
    ;; one of two identical forms removed: exactly one removal, whichever of the two it was
    (let ((changes (ua:definition-changes "lib/f.lisp" (format nil "~A ~A ~A" a b a) (format nil "~A ~A" a b))))
      (assert (= 1 (length changes))) (assert (eq :removed (ua:definition-change-kind (first changes)))))
    ;; one added: exactly one addition; a third identical form is the third
    (let ((changes (ua:definition-changes "lib/f.lisp" (format nil "~A" a) (format nil "~A ~A ~A" a a a))))
      (assert (equal '(:added :added) (mapcar #'ua:definition-change-kind changes)))
      (assert (equal '("#2" "#3") (mapcar (lambda (c) (let ((k (ua:definition-change-key c))) (subseq k (position #\# k)))) changes))))
    ;; two forms of the same shape and different text are not one form that changed: no equation without proof
    (let ((changes (ua:definition-changes "lib/f.lisp" "(setf (get 'a 'b) 1)" "(setf (get 'a 'b) 2)")))
      (assert (equal '(:added :removed) (sort (mapcar #'ua:definition-change-kind changes) #'string<))))
    (let ((changes (ua:definition-changes "lib/f.lisp" (format nil "~A ~A" a b) (format nil "~A ~A" b a))))
      (assert (null changes) () "reordering is not a change of a form")))
  t)

(defmacro with-scratch-index ((index files) &body body)
  "An index over FILES, a list of (path text), in a scratch directory that exists for BODY."
  `(let ((root (uiop:ensure-directory-pathname (merge-pathnames (format nil "ua-index-~D/" (random 1000000 (make-random-state t))) (uiop:temporary-directory)))))
     (unwind-protect
          (progn (dolist (f ,files) (write-file root (first f) (second f)))
                 (let ((,index (ua:make-fork-index root))) ,@body))
       (uiop:delete-directory-tree root :validate t :if-does-not-exist :ignore))))

(defun relation-in (files path before after &key (key nil))
  (with-scratch-index (index files)
    (let* ((changes (ua:definition-changes path before after))
           (change (if key (find key changes :key #'ua:definition-change-key :test #'equal) (first changes))))
      (assert change () "no such change in ~S" (mapcar #'ua:definition-change-key changes))
      (values (ua:fork-situation-relation (ua:situation-of change index)) (ua:situation-of change index)))))

(defun check-ambiguity ()
  "A definition that the fork has twice, or that it has only under another spelling, stays visible as that: it is neither adopted nor absent without a trace."
  ;; two definitions with one key: ambiguous, whatever either says
  (multiple-value-bind (relation situation)
      (relation-in '(("x/a.lisp" "(defun greet (x) 1)") ("x/b.lisp" "(defun greet (x) 3)")) "lib/core.lisp" "(defun greet (x) 1)" "(defun greet (x) 3)")
    (assert (eq :ambiguous relation) () "~S" relation)
    (assert (= 2 (length (ua:fork-situation-locations situation))) () "both definitions stay in view")
    (assert (find :mechanically-derived (ua:fork-situation-claims situation) :key #'ua:claim-status)))
  ;; only one of them has the commit's text: still ambiguous, not adopted
  (assert (eq :ambiguous (relation-in '(("lib/core.lisp" "(defun greet (x) 3)") ("x/b.lisp" "(defun greet (x) 9)")) "lib/core.lisp" "(defun greet (x) 1)" "(defun greet (x) 3)")))
  ;; one definition: not ambiguous
  (assert (eq :adopted (relation-in '(("lib/core.lisp" "(defun greet (x) 3)")) "lib/core.lisp" "(defun greet (x) 1)" "(defun greet (x) 3)")))
  ;; the same definition under another spelling of its package is a candidate, listed, with the relation left at :absent
  (multiple-value-bind (relation situation)
      (relation-in '(("lib/page.lisp" "(defmethod render ((h hyperdoc) (type (eql :html))) 2)")) "lib/page.lisp" "" "(defmethod render ((h hyperdoc:hyperdoc) (type (eql :html))) 1)")
    (assert (eq :absent relation) () "not equated: ~S" relation)
    (assert (= 1 (length (ua:fork-situation-counterparts situation))))
    (assert (eq :working-hypothesis (claim-status-of situation "differ")) () "a candidate is a working hypothesis"))
  ;; with the context that proves it, there is nothing to guess
  (assert (eq :changed (relation-in '(("lib/page.lisp" "(in-package :hyperdoc) (defmethod render ((h hyperdoc) (type (eql :html))) 2)")) "lib/page.lisp"
                                    "(in-package :hyperdoc) (defmethod render ((h hyperdoc:hyperdoc) (type (eql :html))) 0)" "(in-package :hyperdoc) (defmethod render ((h hyperdoc:hyperdoc) (type (eql :html))) 1)")))
  ;; an unnamed form is the same form only in the same file
  (assert (eq :absent (relation-in '(("elsewhere.lisp" "(setf (get 'a 'b) 1)")) "lib/p.lisp" "" "(setf (get 'a 'b) 1)")))
  (assert (eq :adopted (relation-in '(("lib/p.lisp" "(setf (get 'a 'b) 1)")) "lib/p.lisp" "" "(setf (get 'a 'b) 1)")))
  ;; through the whole assessment: an ambiguous definition is no adoption, and the proposal is to defer
  (let ((extra "ext/greet-copy.lisp"))
    (unwind-protect
         (progn
           (write-file *fork-root* extra "(defun greet (name) (format nil \"hi again ~A\" name))")
           (let* ((assessment (assessment-of (third *commits*)))
                  (greet (find "function:greet" (ua:commit-assessment-changes assessment) :key (lambda (c) (ua:definition-change-key (ua:change-assessment-change c))) :test #'equal)))
             (assert (eq :ambiguous (ua:fork-situation-relation (ua:change-assessment-situation greet))))
             (assert (eq :defer (ua:decision-kind (ua:change-assessment-proposal greet))))
             (assert (not (eq :all-adopted (ua:commit-assessment-source-adoption assessment))))
             (let ((report (with-output-to-string (s) (ua:report-run (policy-run :upstream-repository *upstream* :commits (list (third *commits*))) s))))
               (assert (search "fork: ambiguous" report)))))
      (ignore-errors (delete-file (merge-pathnames extra *fork-root*)))))
  t)

(defun claim-status-of (situation text-part)
  (let ((claim (find-if (lambda (c) (search text-part (ua:claim-text c))) (ua:fork-situation-claims situation)))) (and claim (ua:claim-status claim))))

(defun report-of (run) (with-output-to-string (s) (ua:report-run run s)))

(defun check-intake-is-idempotent-and-history-is-kept ()
  "Taking in a revision again changes nothing. When the fork changes, a new assessment is possible; the decisions taken before stay as they were."
  (let* ((ledger (ua:make-ledger)) (u1 (second *commits*)) (subject "lib/net.lisp::function:connect")
         (state (list :upstream-intake-state :last-examined (first *commits*))))
    ;; the same revision twice: the same report, the same digests, nothing recorded
    (let ((first (policy-run :upstream-repository *upstream* :state state :ledger ledger)) (second (policy-run :upstream-repository *upstream* :state state :ledger ledger)))
      (assert (string= (report-of first) (report-of second)))
      (assert (null (ua:ledger-decisions ledger)) () "an assessment records no decision"))
    (let* ((before (change-of (assessment-of u1 :ledger ledger))) (again (change-of (assessment-of u1 :ledger ledger)))
           (digest (ua:change-assessment-situation-digest before)))
      (assert (equal digest (ua:change-assessment-situation-digest again)))
      ;; a person decides, against the situation as it is
      (let* ((d1 (ua:make-decision :commit u1 :subject subject :kind :defer :status :accepted :rationale "compare by hand" :proposed-by "maintainer"
                                   :assessed-situation digest))
             (d1-form (ua::decision-form d1)))
        (ua:ledger-record ledger d1)
        (assert (null (ua:change-assessment-stale (change-of (assessment-of u1 :ledger ledger)))) () "a decision against the present situation is not stale")
        ;; the fork changes
        (let ((original (uiop:read-file-string (merge-pathnames "lib/net.lisp" *fork-root*))))
          (unwind-protect
               (progn
                 (write-file *fork-root* "lib/net.lisp"
                             (let ((p (search "other-error)" original)))
                               (concatenate 'string (subseq original 0 p) "other-error extra-error)" (subseq original (+ p (length "other-error)"))))))
                 (let* ((after (change-of (assessment-of u1 :ledger ledger))) (new-digest (ua:change-assessment-situation-digest after)))
                   (assert (not (equal digest new-digest)) () "another fork, another situation")
                   ;; the historical decision is still there, unchanged, and marked as taken against another situation
                   (assert (equal (list d1) (ua:change-assessment-recorded after)))
                   (assert (equal (list d1) (ua:change-assessment-stale after)))
                   (assert (equal d1-form (ua::decision-form (first (ua:ledger-decisions ledger)))) () "the old decision was not touched")
                   (assert (search "STALE" (string-upcase (report-of (policy-run :upstream-repository *upstream* :commits (list u1) :ledger ledger)))) () "the report says so")
                   ;; a new decision may be recorded beside it, naming what it supersedes
                   (assert (handler-case (progn (ua:ledger-record ledger (ua:make-decision :commit u1 :subject subject :kind :adopt-upstream-change :rationale "no" :proposed-by "x")) nil)
                             (ua:decision-conflict () t))
                           () "without naming the decision it replaces, a second decision for the subject is a conflict")
                   (let ((d2 (ua:make-decision :commit u1 :subject subject :kind :prepare-upstream-contribution :status :proposed :rationale "the fork extends the list"
                                               :proposed-by "maintainer" :supersedes (ua:decision-id d1) :assessed-situation new-digest)))
                     (assert (eq d2 (ua:ledger-record ledger d2)))
                     (assert (eq d2 (ua:ledger-record ledger d2)) () "recording it again is the same record")
                     (assert (= 2 (length (ua:ledger-decisions ledger))))
                     (assert (equal (list d1 d2) (ua:ledger-history ledger u1 subject)) () "both stay in the history, oldest first")
                     (assert (equal (list d2) (ua:ledger-find ledger u1 subject)) () "only the later one is in force")
                     (assert (equal d1-form (ua::decision-form (first (ua:ledger-decisions ledger)))))
                     (let ((now (change-of (assessment-of u1 :ledger ledger))))
                       (assert (equal (list d2) (ua:change-assessment-recorded now)))
                       (assert (null (ua:change-assessment-stale now))))
                     ;; the superseded decision cannot be superseded a second time
                     (assert (handler-case (progn (ua:ledger-record ledger (ua:make-decision :commit u1 :subject subject :kind :do-not-adopt :rationale "other" :proposed-by "y"
                                                                                           :supersedes (ua:decision-id d1)))
                                                  nil)
                               (ua:decision-conflict () t)))
                     ;; the ledger as plain data keeps the whole history
                     (let ((back (ua:ledger-from-form (read-from-string (prin1-to-string (ua:ledger-form ledger))))))
                       (assert (equal (ua:ledger-form ledger) (ua:ledger-form back)))
                       (assert (= 1 (length (ua:ledger-find back u1 subject))))))))
            (write-file *fork-root* "lib/net.lisp" original))))))
  t)

(defun run-tests ()
  (check-syntax-layer)
  (check-package-context)
  (check-method-identity)
  (check-repeated-anonymous-forms)
  (with-fixture ()
    (let ((untouched (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*))))
      (run-fixture-checks)
      (assert (equal untouched (list (repository-fingerprint *upstream-root*) (repository-fingerprint *fork-root*)))
              () "the whole run, every assessment of every commit, left both repositories exactly as it found them")))
  (format t "~&UPSTREAM-ASSESSMENT-PASS: syntax without READ; the identity of definitions (package context, methods, repeated anonymous forms, ambiguity); idempotent intake and a kept history; a replaced handler, adoption without ancestry, runs over several commits, missing and recorded evidence, nothing executed or changed, the ledger.~%")
  t)

(defun run-fixture-checks ()
  (progn
    (check-replaced-handler)
    (check-extended-fragment)
    (check-adoption-is-not-ancestry)
    (check-runs-and-observation)
    (check-nothing-executed-nothing-changed)
    (check-recorded-evidence)
    (check-ledger)
    (check-ambiguity)
    (check-intake-is-idempotent-and-history-is-kept)))
