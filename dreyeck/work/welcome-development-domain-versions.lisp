;;;; W2: local, tagged source provenance; screened trusted code, not a sandbox.
(in-package #:dreyeck/work/welcome-development)

(defparameter +domain-reader-contract+
  '(:package "DREYECK/WORK/WELCOME-DEVELOPMENT" :read-eval nil :syntax :standard :symbol-policy :w2-v1))
(defparameter +domain-planner-pin+
  '(:shop3-rev "ce53f9b651acde8c44dc21eddb1a1c5b97f10536"
    :shop3-nar-hash "sha256-uJ4Fxv82wvZn+tgZjAswcqXxHfNDh2w5kOKrJKVwsRU="
    :shop3-asdf-version "4.3.1"))
(defparameter +validator-path+ "dreyeck/work/welcome-development-records.lisp")
(defvar *development-domain-cache* (make-hash-table :test #'equal))
(defvar *development-domain-debug* nil
  "When true, assert public SHOP3 registration/dynamic-domain invariants on every replay, including unwind.")
(defmacro with-development-domain-invariants (&body body)
  `(let ((snapshot (when *development-domain-debug*
                     (list (get 'welcome-development :domain)
                           (copy-list (symbol-plist 'welcome-development)) shop3:*domain*))))
     (unwind-protect (progn ,@body)
       (when snapshot
         (assert (eq (first snapshot) (get 'welcome-development :domain)))
         (assert (equal (second snapshot) (symbol-plist 'welcome-development)))
         (assert (eq (third snapshot) shop3:*domain*))))))

;; Fixture-only source snapshots captured by the factory, never supplied in records.
;; They are volatile loaded-image provenance; durable replay uses tagged Git blobs.
(defvar *fixture-domain-sources* (make-hash-table :test #'equal))

(defun domain-refuse (reason &optional detail)
  (refuse-record (if detail (list reason detail) reason)))
(defun text-sha256 (text)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets text :external-format :utf-8))))
(defun file-sha256 (file)
  (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 file)))
(defun running-development-planner-pin ()
  (let* ((json (shasht:read-json
                (uiop:read-file-string (asdf:system-relative-pathname
                                       "dreyeck/work/welcome-development" "flake.lock")) t nil t))
         (locked (gethash "locked" (gethash "shop3" (gethash "nodes" json))))
         (pin (list :shop3-rev (gethash "rev" locked) :shop3-nar-hash (gethash "narHash" locked)
                    :shop3-asdf-version (asdf:component-version (asdf:find-system "shop3")))))
    (unless (equal pin +domain-planner-pin+) (domain-refuse :planner-version-mismatch))
    pin))
(defun domain-version-id (items)
  (development-data-digest (list "welcome-development-domain-v1" :options '(:noset t) :items items)))
(defun domain-version-tag (id) (concatenate 'string "refs/tags/hyperdoc/welcome-development/" id))

;; Text-only location, with the authority-policy %FORM-TEXT rules for strings,
;; line comments and character syntax; nested block comments/escaped tokens are
;; also skipped. No host reader sees the other forms in a historical Lisp file.
(defun source-token-end (text start)
  (let ((i start))
    (loop while (and (< i (length text))
                     (not (find (char text i) '(#\Space #\Tab #\Newline #\Return #\( #\) #\;))))
          do (incf i)) i))
(defun source-skip (text i)
  "Return the end of a string, escaped token, comment or character; otherwise I."
  (let ((n (length text)))
    (cond
      ((find (char text i) '(#\" #\|))
       (let ((delimiter (char text i)))
         (incf i)
         (loop while (< i n) do
           (cond ((char= (char text i) #\\) (incf i))
                 ((char= (char text i) delimiter) (return-from source-skip (1+ i))))
           (incf i))
         (domain-refuse :domain-version-untrusted :unterminated-source-token)))
      ((char= (char text i) #\;) (or (position #\Newline text :start i) n))
      ((and (< (1+ i) n) (string= text "#|" :start1 i :end1 (+ i 2)))
       (let ((depth 1))
         (incf i 2)
         (loop while (< i n) do
           (cond ((and (< (1+ i) n) (string= text "#|" :start1 i :end1 (+ i 2)))
                  (incf depth) (incf i))
                 ((and (< (1+ i) n) (string= text "|#" :start1 i :end1 (+ i 2)))
                  (decf depth) (incf i)
                  (when (zerop depth) (return-from source-skip (1+ i)))))
           (incf i))
         (domain-refuse :domain-version-untrusted :unterminated-comment)))
      ((and (< (+ i 2) n) (string= text "#\\" :start1 i :end1 (+ i 2)))
       (max (+ i 3) (source-token-end text (+ i 2))))
      (t i))))
(defun development-domain-form-text (text)
  (let ((marker "(shop3:defdomain") (starts nil) (i 0) (n (length text)))
    (loop while (< i n) do
      (let ((next (source-skip text i)))
        (if (> next i) (setf i next)
            (progn
              (when (and (<= (+ i (length marker)) n)
                         (string-equal marker text :start2 i :end2 (+ i (length marker)))
                         (or (= (+ i (length marker)) n)
                             (find (char text (+ i (length marker))) '(#\Space #\Tab #\Newline #\Return #\())) )
                (push i starts))
              (incf i)))))
    (unless (= 1 (length starts)) (domain-refuse :domain-version-untrusted :one-defdomain-required))
    (let ((start (first starts)) (depth 0))
      (setf i start)
      (loop while (< i n) do
        (let ((next (source-skip text i)))
          (if (> next i) (setf i next)
              (progn (case (char text i) (#\( (incf depth)) (#\) (decf depth)))
                     (when (zerop depth)
                       (return-from development-domain-form-text (subseq text start (1+ i))))
                     (incf i)))))
      (domain-refuse :domain-version-untrusted :unbalanced-domain-form))))

(defclass development-domain-reader () ())
(defparameter +domain-cl-symbols+ '(< <= > >= = /= not and or nil t))
(defparameter +domain-shop-symbols+ '(shop3:defdomain shop3:call shop3:forall))
(defun allowed-domain-symbol-p (symbol)
  (or (eq (symbol-package symbol) (find-package "DREYECK/WORK/WELCOME-DEVELOPMENT"))
      (eq (symbol-package symbol) (find-package "KEYWORD"))
      (member symbol +domain-cl-symbols+) (member symbol +domain-shop-symbols+)))
(defmethod eclector.reader:interpret-symbol
    ((client development-domain-reader) stream indicator name internp)
  (declare (ignore stream))
  (unless indicator (domain-refuse :domain-version-untrusted :uninterned-symbol))
  (let* ((package (cond ((eq indicator :keyword) (find-package "KEYWORD"))
                        ((eq indicator :current) (find-package (eclector.reader:state-value client '*package*)))
                        ((stringp indicator) (find-package indicator))))
         (own (find-package "DREYECK/WORK/WELCOME-DEVELOPMENT")))
    (unless (member package (list own (find-package "KEYWORD") (find-package "SHOP3")
                                 (find-package "COMMON-LISP")))
      (domain-refuse :domain-version-untrusted :foreign-package))
    (multiple-value-bind (symbol status) (find-symbol name package)
      (cond
        (symbol
         (unless (and (allowed-domain-symbol-p symbol)
                      (or internp (eq status :external) (not (stringp indicator))))
           (domain-refuse :domain-version-untrusted :symbol-not-allowlisted)) symbol)
        ((and internp (member package (list own (find-package "KEYWORD")))) (intern name package))
        (t (domain-refuse :domain-version-untrusted :symbol-not-allowlisted))))))
(defmethod eclector.reader:evaluate-expression ((client development-domain-reader) expression)
  (declare (ignore expression)) (domain-refuse :domain-version-untrusted :read-time-evaluation))
(defmethod eclector.reader:evaluate-feature-expression ((client development-domain-reader) expression)
  (declare (ignore expression)) (domain-refuse :domain-version-untrusted :feature-expression))
(defmethod eclector.reader:make-structure-instance ((client development-domain-reader) name initargs)
  (declare (ignore name initargs)) (domain-refuse :domain-version-untrusted :structure))
(defmethod eclector.reader:call-reader-macro
    ((client development-domain-reader) stream char readtable)
  (unless (find char '(#\( #\) #\; #\" #\#))
    (domain-refuse :domain-version-untrusted :unsupported-reader-macro))
  (when (char= char #\#)
    (unless (find (peek-char nil stream nil nil) '(#\. #\+ #\- #\S #\s #\P #\p #\\ #\|))
      (domain-refuse :domain-version-untrusted :unsupported-dispatch-macro)))
  (call-next-method))

(defun screen-development-domain-items (items)
  "Check W1's supported source contexts before invoking SHOP3's native parser.
CALL operands are evaluated by SHOP3, unlike ordinary predicate terms. Method
networks must stay quoted data; effects cannot introduce executable queries."
  (development-canonical-string items)
  (labels
      ((refuse (reason) (domain-refuse :domain-version-untrusted reason))
       (proper (x) (unless (alexandria:proper-list-p x) (refuse :improper-domain-form)))
       (variable (x)
         ;; Use the pinned engine's name rule without VARIABLEP's plist writes.
         (and (symbolp x) (plusp (length (symbol-name x))) (shop3.unifier::variable-symbol-p x)))
       (symbols (x)
         (cond ((symbolp x)
                (unless (allowed-domain-symbol-p x) (refuse :symbol-not-allowlisted))
                (when (string= "SORT-BY" (symbol-name x)) (refuse :sort-by-not-supported)))
               ((consp x)
                (when (and (symbolp (car x))
                           (member (symbol-name (car x))
                                   '("EVAL" "ASSIGN" "ASSIGN*" "ENFORCE" "SETOF" "BAGOF" "EXTERNAL" "INCLUDE")
                                   :test #'string=))
                  (refuse :evaluating-logical-form))
                (symbols (car x)) (symbols (cdr x)))))
       (flat-term (x)
         ;; Nested source terms could bind a CALL variable to executable Lisp.
         ;; W1 needs only atomic terms; reject those extensions instead.
         (unless (typep x '(or symbol string integer)) (refuse :non-flat-domain-term)))
       (plain-form (x context)
         (proper x)
         (unless (and x (symbolp (first x)) (not (variable (first x)))
                      (eq (symbol-package (first x)) (find-package "DREYECK/WORK/WELCOME-DEVELOPMENT"))
                      (not (member (symbol-name (first x))
                                   '("CALL" "FORALL" "IMPLY" "AND" "OR" "NOT" "QUOTE" "SIMPLE-BACKQUOTE")
                                   :test #'string=)))
           (refuse (list :unsupported-atomic-form context)))
         (mapc #'flat-term (rest x)))
       (call-operand (x)
         (unless (if (variable x)
                     (and (eq (symbol-package x) (find-package "DREYECK/WORK/WELCOME-DEVELOPMENT"))
                          (not (boundp x))
                          ;; A Lisp special can have a ?-prefixed name too,
                          ;; and can be declared but still unbound.
                          (not (eq :special (sb-int:info :variable :kind x))))
                     (or (integerp x) (stringp x) (keywordp x) (member x '(nil t))))
           (refuse :non-plain-call-argument)))
       (goals (xs allow-call)
         (proper xs)
         (dolist (x xs) (goal x allow-call)))
       (goal (x allow-call)
         (proper x)
         (unless x (refuse :empty-logical-form))
         (case (first x)
           (shop3:call
            (unless allow-call (refuse :call-outside-precondition))
            (unless (and (>= (length x) 3) (member (second x) '(< <= > >= = /=)))
              (refuse :call-not-allowlisted))
            (mapc #'call-operand (cddr x)))
           (not
            (unless (= 2 (length x)) (refuse :unsupported-logical-shape))
            (goal (second x) allow-call))
           ((and or) (mapc (lambda (g) (goal g allow-call)) (rest x)))
           (shop3:forall (quantified x allow-call nil))
           (otherwise (plain-form x :predicate))))
       (quantified (x allow-call effects-p)
         (unless (= 4 (length x)) (refuse :unsupported-forall-shape))
         (proper (second x))
         (unless (every #'variable (second x)) (refuse :forall-variables-required))
         (goals (third x) allow-call)
         (if effects-p (effects (fourth x)) (goals (fourth x) allow-call)))
       (effects (xs)
         (proper xs)
         (dolist (x xs)
           (if (and (consp x) (eq 'shop3:forall (first x)))
               ;; Even the bounds of quantified effects cannot contain CALL.
               (progn (proper x) (quantified x nil t))
               (plain-form x :effect))))
       (tasks (xs)
         (proper xs)
         (dolist (x xs) (plain-form x :task)))
       (branches (tail method-p)
         (unless tail (refuse :missing-domain-branch))
         (loop while tail do
           ;; Only the ordinary optional branch labels used by W1 are supported.
           (when (and (first tail) (symbolp (first tail)))
             (when (variable (first tail)) (refuse :variable-branch-label))
             (pop tail))
           (unless (>= (length tail) (if method-p 2 1)) (refuse :incomplete-domain-branch))
           (goals (pop tail) t)
           (when method-p (tasks (pop tail))))))
    (proper items)
    (dolist (item items)
      (proper item)
      ;; SHOP3 injects this exact operator; it is not reader-allowlisted source.
      (unless (equal item '(:operator (shop3::!!inop) () () () 0))
        (symbols item)
        (case (first item)
          (:operator
           (unless (member (length item) '(5 6)) (refuse :unsupported-operator-shape))
           (when (and (= 6 (length item)) (not (integerp (sixth item))))
             (refuse :nonliteral-operator-cost))
           (plain-form (second item) :operator-head)
           (goals (third item) t)
           (effects (fourth item)) (effects (fifth item)))
          (:method
           (plain-form (second item) :method-head)
           (branches (cddr item) t))
          (:-
           (plain-form (second item) :axiom-head)
           (branches (cddr item) nil))
          (otherwise (refuse :unsupported-domain-item))))))
  t)

(defun read-development-domain-form (text)
  "Read only one extracted form. Every reader error/warning escapes without restart recovery."
  (unless (equal "0.11.0" (asdf:component-version (asdf:find-system "eclector")))
    (domain-refuse :domain-version-untrusted :unsupported-eclector-version))
  (let* ((client (make-instance 'development-domain-reader))
         (outcome
           (catch 'domain-read-refused
             (handler-bind ((error (lambda (c) (throw 'domain-read-refused c)))
                            (warning (lambda (c) (throw 'domain-read-refused c))))
               (eclector.reader:call-with-state-value
                client
                (lambda ()
                  (eclector.reader:call-with-state-value
                   client
                   (lambda ()
                     (eclector.reader:call-with-state-value
                      client
                      (lambda ()
                        (let ((eclector.reader:*client* client)
                              (eclector.reader:*readtable*
                                (eclector.readtable:copy-readtable eclector.reader::*standard-readtable*)))
                          (multiple-value-bind (form end) (eclector.reader:read-from-string text)
                            (unless (every (lambda (c) (find c '(#\Space #\Tab #\Newline #\Return)))
                                           (subseq text end))
                              (domain-refuse :domain-version-untrusted :trailing-input))
                            (list :read form))))
                      '*read-base* 10)) '*read-eval* nil))
                '*package* (find-package "DREYECK/WORK/WELCOME-DEVELOPMENT"))))))
    (unless (and (consp outcome) (eq :read (first outcome)))
      (domain-refuse :domain-version-untrusted (list :reader-condition (type-of outcome))))
    (let ((form (second outcome)))
      (unless (and (alexandria:proper-list-p form) (= 3 (length form))
                   (eq 'shop3:defdomain (first form))
                   (equal '(welcome-development :noset t) (second form)))
        (domain-refuse :domain-version-untrusted :domain-name-or-options))
      (handler-case (screen-development-domain-items (third form))
        (invalid-development-record (c) (domain-refuse :domain-version-untrusted (refusal-reason c))))
      (values (third form) '(:passed :w2-v1)))))

(defun development-domain-object (id items)
  "Build privately with SHOP3 itself. Cleanup covers failures after INSTALL-DOMAIN."
  (screen-development-domain-items items)
  (let ((cached (cdr (gethash id *development-domain-cache*))))
    (when cached
      (unless (and (equal id (domain-version-id (shop3::domain-items cached)))
                   (or (equal items (shop3::domain-items cached))
                       (and (equal '(:operator (shop3::!!inop) () () () 0)
                                   (first (shop3::domain-items cached)))
                            (equal items (rest (shop3::domain-items cached))))))
        (domain-refuse :domain-version-mismatch :cached-source))
      (return-from development-domain-object cached)))
  (let ((name (make-symbol (format nil "WELCOME-DEVELOPMENT@~A" id))) (domain nil) (done nil))
    (unwind-protect
         (progn
           (screen-development-domain-items items)
           (setf domain (eval `(shop3:defdomain (,name :noset t :silently t) ,(copy-tree items))))
           (unless (equal id (domain-version-id (shop3::domain-items domain)))
             (domain-refuse :domain-version-mismatch))
           (setf (gethash id *development-domain-cache*) (cons name domain) done t)
           domain)
      (unless done
        (let ((partial (or domain (get name :domain))))
          (when partial (shop3:delete-domain partial)))))))

(defun clear-development-domain-cache ()
  (let ((entries (loop for key being the hash-keys of *development-domain-cache* collect key)) (n 0))
    (dolist (key entries n)
      (let ((entry (gethash key *development-domain-cache*)))
        (unwind-protect (when entry (shop3:delete-domain (cdr entry)) (incf n))
          (remhash key *development-domain-cache*))))))

(defclass development-domain-version ()
  ((record :initarg :record :reader domain-version-record)
   (id :initarg :id :reader domain-version-identity)
   (commit :initarg :commit :initform nil :reader domain-version-commit)
   (tag :initarg :tag :initform nil :reader domain-version-tag-provenance)
   (blob :initarg :blob :initform nil :reader domain-version-blob)
   (form-digest :initarg :form-digest :reader domain-version-form-digest)
   (screen :initarg :screen :reader domain-version-screen)
   (domain :initarg :domain :reader domain-version-domain)
   (planner :initarg :planner :reader domain-version-planner)))

(defun version-git (repository &rest arguments)
  (unless (typep repository 'dreyeck/git:git-repository-checkout)
    (domain-refuse :domain-version-unavailable :explicit-repository-required))
  (multiple-value-bind (out err code)
      (apply #'dreyeck/git:git-run-values (dreyeck/git:git-repository-root-of repository) arguments)
    (declare (ignore err))
    (unless (zerop code) (domain-refuse :domain-version-unavailable arguments))
    (dreyeck/git:trim-git-output out)))
(defun domain-version-tag-commit (repository id)
  (unless (sha-p id 64) (domain-refuse :domain-version-mismatch))
  (let* ((ref (domain-version-tag id))
         (commit (version-git repository "rev-parse" "--verify" "--quiet" (concatenate 'string ref "^{commit}")))
         (kind (version-git repository "cat-file" "-t" ref))
         (object (version-git repository "rev-parse" "--verify" ref)))
    (unless (member kind '("tag" "commit") :test #'equal) (domain-refuse :domain-version-unavailable :tag-kind))
    (values commit (list :ref ref :kind kind :object-id object :signature :not-verified))))

(defun describe-development-domain-version (&optional repository commit
                                           (path "dreyeck/work/welcome-development.lisp"))
  "Read-only description and proposed tag name. Never creates a tag."
  (let* ((text (if repository (version-git repository "show" (format nil "~A:~A" commit path))
                   (uiop:read-file-string (asdf:system-relative-pathname "dreyeck/work/welcome-development" path))))
         (form (development-domain-form-text text)))
    (multiple-value-bind (items screen) (read-development-domain-form form)
      (declare (ignore screen))
      ;; DEFDOMAIN inserts !!INOP; use a disposable private construction to obtain
      ;; the canonical post-expansion items, then clean up even if it fails.
      (let ((name (make-symbol "WELCOME-DESCRIPTION")) (domain nil))
        (unwind-protect
             (progn
               (setf domain (eval `(shop3:defdomain (,name :noset t :silently t) ,(copy-tree items))))
               (let ((id (domain-version-id (shop3::domain-items domain))))
                 (list :version-id id :tag (domain-version-tag id) :commit commit :path path
                       :blob (when repository (version-git repository "rev-parse" (format nil "~A:~A" commit path)))
                       :form-sha256 (text-sha256 form) :reader (copy-tree +domain-reader-contract+)
                       :planner (running-development-planner-pin)
                       :planner-source (namestring (asdf:system-source-file "shop3")))))
          (let ((partial (or domain (get name :domain))))
            (when partial (shop3:delete-domain partial))))))))

(defun admit-development-domain-version (record)
  (let* ((id (data record :version-id)) (source (record-source record))
         (pin (running-development-planner-pin)) (domain nil) (commit nil) (tag nil) (screen nil))
    (unless (and (sha-p id 64) (equal (data record :reader) +domain-reader-contract+))
      (domain-refuse :domain-version-mismatch))
    (unless (equal (data record :planner) pin) (domain-refuse :planner-version-mismatch))
    (when (data record :items) (domain-refuse :domain-version-untrusted :record-carried-items))
    (unless (and (equal (getf (data record :validator) :path) +validator-path+)
                 (sha-p (getf (data record :validator) (if (eq source :fixture) :sha256 :blob))
                        (if (eq source :fixture) 64 40)))
      (domain-refuse :domain-version-mismatch :validator-provenance))
    (ecase source
      (:fixture
       (unless (eq :loaded-image (data record :items-source)) (domain-refuse :domain-version-untrusted :fixture-source))
       (let ((items (gethash id *fixture-domain-sources*)))
         (unless items (domain-refuse :domain-version-unavailable :fixture-source-not-captured))
         (unless (equal (data record :form-sha256) (development-data-digest items))
           (domain-refuse :domain-version-mismatch))
         (setf domain (development-domain-object id items) screen '(:passed :fixture-loaded-image))))
      (:observed
       (unless (and (eq :git (data record :items-source))
                    (equal (domain-version-tag id) (data record :tag))
                    (sha-p (data record :commit)) (sha-p (data record :blob))
                    (stringp (data record :path)))
         (domain-refuse :domain-version-mismatch))
       (let* ((repository (data record :repository)) (sha (data record :commit)))
         (unless (and (typep repository 'dreyeck/git:git-repository-checkout)
                      (dreyeck/git:git-commit-object-present-p repository sha))
           (domain-refuse :domain-version-unavailable :local-commit-required))
         (multiple-value-bind (resolved provenance) (domain-version-tag-commit repository id)
           (unless (equal sha resolved) (domain-refuse :domain-version-mismatch :tag-target))
           (setf tag provenance))
         (unless (equal (data record :blob)
                        (version-git repository "rev-parse" (format nil "~A:~A" sha (data record :path))))
           (domain-refuse :domain-version-mismatch :blob))
         (let* ((text (version-git repository "show" (format nil "~A:~A" sha (data record :path))))
                (form (development-domain-form-text text)))
           (unless (equal (text-sha256 form) (data record :form-sha256))
             (domain-refuse :domain-version-mismatch :form-digest))
           (multiple-value-bind (items verdict) (read-development-domain-form form)
             (setf screen verdict domain (development-domain-object id items))))
         (unless (equal (data record :validator)
                        (list :path +validator-path+
                              :blob (version-git repository "rev-parse" (format nil "~A:~A" sha +validator-path+))))
           (domain-refuse :domain-version-mismatch :validator-provenance))
         (setf commit (dreyeck/git:make-git-commit :repository repository :commit-ish sha)))))
    (make-instance 'development-domain-version :record record :id id :domain domain
                   :commit commit :tag tag :blob (data record :blob)
                   :form-digest (data record :form-sha256) :screen screen :planner pin)))
