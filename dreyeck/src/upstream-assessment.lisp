;;;; Assessing what an upstream commit means for dreyeck.ch: observe, compare, locate, own, weigh, propose.
;;;;
;;;; Read-only. Nothing here loads, compiles or evaluates library source: Lisp and ASDF text is scanned as syntax (DREYECK/ASDF-SOURCE:SCAN-ASDF-SOURCE,
;;;; a package-free tree made without READ), Git is asked through DREYECK/GIT with commands that do not write, and ASDF is asked only what a system
;;;; DEFINITION says (owned paths, dependencies), never to compile or load a component. A commit whose objects are not in a repository is missing
;;;; evidence, not something to fetch.
;;;;
;;;; Observation, integration, adoption and decision are kept apart:
;;;;   observed upstream state  - where the upstream ref stands now (a tip) and whether its objects are in a repository we were given
;;;;   last examined state      - recorded in the state file, by a person's decision, never by this code
;;;;   fork availability        - whether the commit's objects are in the dreyeck.ch checkout
;;;;   Git ancestry             - whether the commit is an ancestor of the fork's HEAD
;;;;   source adoption          - whether the commit's definitions stand in the fork's source, whatever its history
;;;;   decision                 - what to do about it, with its evidence; a proposal is not an execution
;;;; Every claim carries one of the epistemic statuses of the workflow reading: :SOURCE-OBSERVED, :MECHANICALLY-DERIVED, :DESIGN-INFERENCE,
;;;; :WORKING-HYPOTHESIS.

(in-package #:dreyeck/upstream-assessment)

(defparameter +epistemic-statuses+ '(:source-observed :mechanically-derived :design-inference :working-hypothesis))

(defstruct (claim (:constructor %make-claim (text status basis)))
  "A statement with its epistemic status and what it rests on (a list of strings)."
  text status basis)

(defun make-claim (text status &optional basis)
  (unless (member status +epistemic-statuses+) (error "~S is not one of ~S." status +epistemic-statuses+))
  (%make-claim text status basis))

;;; ------------------------------------------------------------------------------------------------------------------------------------
;;; Source text as data. Tokens are lower-cased strings; a string literal is (:S "text"); a list is a list. No package is consulted.

(defun canonical-token (raw)
  (if (or (and (>= (length raw) 2) (string= "#\\" raw :end2 2)) (find #\| raw)) raw (string-downcase raw)))

(defun node-tree (node)
  (ecase (src:asdf-source-node-kind node)
    (:list (mapcar #'node-tree (src:asdf-source-node-children node)))
    (:string (list :s (src:asdf-source-node-value node)))
    (:token (canonical-token (src:asdf-source-node-raw node)))
    ((:reader-eval :error) (list :unsupported (src:asdf-source-node-raw node)))))

(defun keyword-headed-p (tree) (and (consp tree) (keywordp (car tree))))

(defun tree-text (tree)
  (let ((*print-pretty* nil) (*print-readably* nil))
    (cond ((stringp tree) tree)
          ((keyword-headed-p tree) (if (eq (car tree) :s) (prin1-to-string (second tree)) (format nil "~A" (second tree))))
          ((null tree) "()")
          (t (format nil "(~{~A~^ ~})" (mapcar #'tree-text tree))))))

(defun sha256-hex (string)
  (ironclad:byte-array-to-hex-string (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets string :external-format :utf-8))))

(defun tree-digest (tree) (sha256-hex (tree-text tree)))

(defstruct source-definition key kind name tree text digest path)

(defun strip-package (token)
  (let ((position (position #\: token :from-end t))) (if position (subseq token (1+ position)) token)))

(defparameter +definition-heads+
  '(("defun" . :function) ("defmacro" . :macro) ("defgeneric" . :generic) ("defmethod" . :method) ("defparameter" . :parameter)
    ("defvar" . :parameter) ("defconstant" . :parameter) ("defclass" . :class) ("define-condition" . :condition) ("defstruct" . :structure)
    ("deftype" . :type) ("defpackage" . :package) ("defsystem" . :system) ("defview" . :view) ("defexample" . :example)
    ("defhyperdoc" . :hyperdoc) ("define-compiler-macro" . :compiler-macro) ("defsetf" . :setf-expander)))

(defun name-string (tree)
  (cond ((stringp tree)
         (cond ((and (> (length tree) 2) (string= "#:" tree :end2 2)) (subseq tree 2))
               ((and (> (length tree) 1) (char= #\: (char tree 0))) (subseq tree 1))
               (t tree)))
        ((and (consp tree) (eq (car tree) :s)) (string-downcase (second tree)))
        (t (tree-text tree))))

(defun method-key-parts (rest)
  "Qualifiers and specializers of a DEFMETHOD whose REST follows the name."
  (let* ((qualifiers (loop for item in rest while (and (stringp item) (plusp (length item)) (char= #\: (char item 0))) collect item))
         (lambda-list (nth (length qualifiers) rest))
         (specializers (and (listp lambda-list) (not (keyword-headed-p lambda-list))
                            (loop for parameter in lambda-list
                                  until (and (stringp parameter) (plusp (length parameter)) (char= #\& (char parameter 0)))
                                  collect (if (and (consp parameter) (not (keyword-headed-p parameter)))
                                      (let ((specializer (second parameter))) (if (stringp specializer) (strip-package specializer) (tree-text specializer)))
                                      "t")))))
    (format nil "~{~A~^,~}:~{~A~^,~}" qualifiers specializers)))

(defun definition-identity (tree)
  "KIND, NAME and KEY (a string) of a top-level form, or NIL for a form that defines nothing named."
  (when (and (consp tree) (not (keyword-headed-p tree)) (stringp (first tree)))
    (let* ((head (strip-package (first tree))) (kind (cdr (assoc head +definition-heads+ :test #'string=))))
      (cond ((and kind (second tree))
             (let ((name (name-string (second tree))))
               (values kind name (if (eq kind :method)
                                     (format nil "method:~A:~A" name (method-key-parts (cddr tree)))
                                     (format nil "~(~A~):~A" kind name)))))
            ((and (string= head "in-package") (second tree))
             (values :in-package (name-string (second tree)) (format nil "in-package:~A" (name-string (second tree)))))))))

(defun top-level-definitions (text &key path)
  "The top-level forms of TEXT as SOURCE-DEFINITIONs, in order, scanned and not read. A form that defines nothing named has no name to follow across
versions: its key is FORM:HEAD:DIGEST, so that it is the same form only when it is the same text, and inserting one does not renumber the others."
  (let ((seen (make-hash-table :test #'equal)) (definitions '()))
    (multiple-value-bind (nodes) (src:scan-asdf-source text)
      (dolist (node nodes)
        (when (eq :list (src:asdf-source-node-kind node))
          (let ((tree (node-tree node)))
            (multiple-value-bind (kind name key) (definition-identity tree)
              (unless key
                (let ((head (if (and (consp tree) (stringp (first tree))) (strip-package (first tree)) "list")))
                  (setf kind :form name head key (format nil "form:~A:~A" head (subseq (tree-digest tree) 0 10)))))
              (let ((n (incf (gethash key seen 0)))) (when (> n 1) (setf key (format nil "~A#~D" key n))))
              (push (make-source-definition
                     :key key :kind kind :name name :tree tree
                     :text (subseq text (src:asdf-source-node-start node) (src:asdf-source-node-end node))
                     :digest (tree-digest tree) :path path)
                    definitions))))))
    (nreverse definitions)))

(defun changed-fragments (before after)
  "The smallest enclosing list pairs in which BEFORE and AFTER differ, as (BEFORE . AFTER) conses."
  (cond ((equal before after) '())
        ((and (consp before) (consp after) (not (keyword-headed-p before)) (not (keyword-headed-p after))
              (= (length before) (length after)))
         (if (some (lambda (x y) (and (not (equal x y)) (or (atom x) (atom y) (keyword-headed-p x) (keyword-headed-p y)))) before after)
             (list (cons before after))
             (loop for x in before for y in after append (changed-fragments x y))))
        (t (list (cons before after)))))

(defun tree-contains-p (tree fragment)
  (or (equal tree fragment)
      (and (consp tree) (not (keyword-headed-p tree)) (some (lambda (child) (tree-contains-p child fragment)) tree))))

(defparameter +noise-heads+ '("progn" "let" "let*" "setf" "->" "lambda" "unwind-protect" "when" "unless" "if" "cond" "and" "or" "not" "block" "declare"))

(defun list-heads (tree)
  (let ((heads '()))
    (labels ((walk (x) (when (and (consp x) (not (keyword-headed-p x)))
                         (when (and (stringp (car x)) (not (member (strip-package (car x)) +noise-heads+ :test #'string=)))
                           (pushnew (car x) heads :test #'string=))
                         (mapc #'walk x))))
      (walk tree))
    (nreverse heads)))

(defun handler-profiles (tree)
  "For every HANDLER-CASE in TREE, in order: the calls its protected form makes and the type specifier of each clause. Derived from syntax only."
  (let ((profiles '()))
    (labels ((walk (x)
               (when (and (consp x) (not (keyword-headed-p x)))
                 (when (and (stringp (car x)) (string= "handler-case" (strip-package (car x))))
                   (push (list :protected-calls (list-heads (second x))
                               :clauses (loop for clause in (cddr x) when (and (consp clause) (not (keyword-headed-p clause))) collect (tree-text (car clause))))
                         profiles))
                 (mapc #'walk x))))
      (walk tree))
    (nreverse profiles)))

;;; ------------------------------------------------------------------------------------------------------------------------------------
;;; Repositories, the observed upstream state, commits

(defun open-repository (path)
  "A DREYECK/GIT checkout object for the repository at PATH, which is only ever read."
  (let ((root (uiop:ensure-directory-pathname (truename path))))
    (multiple-value-bind (stdout stderr code) (g:git-run-values root "rev-parse" "--git-dir")
      (declare (ignore stdout))
      (unless (zerop code) (error "~A is not a Git repository: ~A" root stderr)))
    (make-instance 'g:git-repository-checkout :root root :root-source :explicit)))

(defun repository-root (repository) (g:git-repository-root-of repository))

(defun resolve-commit (repository name)
  (multiple-value-bind (stdout stderr code) (g:git-run-values (repository-root repository) "rev-parse" "--verify" "--quiet" (format nil "~A^{commit}" name))
    (declare (ignore stderr))
    (and (zerop code) (g:trim-git-output stdout))))

(defclass upstream-observation ()
  ((repository :initarg :repository :reader upstream-observation-repository)
   (ref :initarg :ref :reader upstream-observation-ref)
   (tip :initarg :tip :reader upstream-observation-tip :documentation "The commit the ref names in that repository now, or NIL.")
   (tip-present-p :initarg :tip-present-p :reader upstream-observation-tip-present-p)
   (observed-at :initarg :observed-at :reader upstream-observation-observed-at)))

(defun observe-upstream (repository ref)
  "Where REF stands in REPOSITORY now. Never fetches: a ref that is not there is a NIL tip, which is missing evidence."
  (let ((tip (resolve-commit repository ref)))
    (make-instance 'upstream-observation :repository repository :ref ref :tip tip :tip-present-p (and tip t) :observed-at (get-universal-time))))

(defun commits-between (repository base tip)
  "The commits reachable from TIP and not from BASE, oldest first; :BASE-MISSING when BASE is not in REPOSITORY."
  (if (not (g:git-commit-object-present-p repository base))
      :base-missing
      (remove "" (uiop:split-string (g:git-run-string (repository-root repository) "rev-list" "--topo-order" "--reverse" (format nil "~A..~A" base tip))
                                    :separator '(#\Newline))
              :test #'string=)))

(defstruct (definition-change (:conc-name definition-change-))
  key kind path before after fragments handlers)

(defclass commit-evidence ()
  ((sha :initarg :sha :reader commit-evidence-sha)
   (parents :initarg :parents :initform nil :reader commit-evidence-parents)
   (subject :initarg :subject :initform nil :reader commit-evidence-subject)
   (authored-at :initarg :authored-at :initform nil :reader commit-evidence-authored-at)
   (origin :initarg :origin :initform nil :reader commit-evidence-origin :documentation ":GIT-OBJECT, :RECORDED, or NIL when there is none.")
   (availability :initarg :availability :reader commit-evidence-availability :documentation ":GIT-OBJECT, :RECORDED or :MISSING.")
   (files :initarg :files :initform nil :reader commit-evidence-files :documentation "Plists (:PATH :STATUS) of every file the commit changed.")
   (changes :initarg :changes :initform nil :reader commit-evidence-changes :documentation "DEFINITION-CHANGEs of the Lisp and ASDF files.")
   (recorded-from :initarg :recorded-from :initform nil :reader commit-evidence-recorded-from)))

(defun missing-evidence (sha)
  (make-instance 'commit-evidence :sha sha :availability :missing))

(defun code-path-p (path) (member (pathname-type path) '("lisp" "asd") :test #'equal))

(defun make-change (key kind path before after)
  (let* ((fragments (and before after (changed-fragments (source-definition-tree before) (source-definition-tree after))))
         (handlers (and before after
                        (let ((b (handler-profiles (source-definition-tree before))) (a (handler-profiles (source-definition-tree after))))
                          (loop for index from 0 below (max (length b) (length a))
                                collect (list :index index :before (nth index b) :after (nth index a)
                                              :changed-p (not (equal (nth index b) (nth index a)))))))))
    (make-definition-change :key key :kind kind :path path :before before :after after :fragments fragments :handlers handlers)))

(defun definition-changes (path before-text after-text)
  "The definitions that differ between two texts of PATH (either may be NIL), by key."
  (let* ((before (and before-text (top-level-definitions before-text :path path)))
         (after (and after-text (top-level-definitions after-text :path path)))
         (by-key (lambda (list) (let ((table (make-hash-table :test #'equal))) (dolist (d list table) (setf (gethash (source-definition-key d) table) d)))))
         (b (funcall by-key before)) (a (funcall by-key after)) (changes '()))
    (dolist (d after)
      (let ((old (gethash (source-definition-key d) b)))
        (cond ((null old) (push (make-change (source-definition-key d) :added path nil d) changes))
              ((not (equal (source-definition-digest old) (source-definition-digest d)))
               (push (make-change (source-definition-key d) :changed path old d) changes)))))
    (dolist (d before)
      (unless (gethash (source-definition-key d) a) (push (make-change (source-definition-key d) :removed path d nil) changes)))
    (nreverse changes)))

(defun blob-text (repository sha path)
  (multiple-value-bind (stdout stderr code) (g:git-run-values (repository-root repository) "show" "--no-color" (format nil "~A:~A" sha path))
    (declare (ignore stderr))
    (and (zerop code) stdout)))

(defun evidence-from-repository (repository sha)
  "Commit evidence read from the objects of REPOSITORY with commands that do not write. A commit that is not there gives MISSING-EVIDENCE."
  (if (not (g:git-commit-object-present-p repository sha))
      (missing-evidence sha)
      (let* ((root (repository-root repository))
             (line (uiop:split-string (g:trim-git-output (g:git-run-string root "rev-list" "--parents" "-n" "1" sha)) :separator '(#\Space)))
             (full (first line)) (parents (rest line))
             (parent (first parents))
             (subject (g:trim-git-output (g:git-run-string root "show" "-s" "--format=%s" full)))
             (authored (g:trim-git-output (g:git-run-string root "show" "-s" "--format=%aI" full)))
             (diff (if parent
                       (g:git-run-string root "diff-tree" "--no-commit-id" "--name-status" "-r" parent full)
                       (g:git-run-string root "diff-tree" "--root" "--no-commit-id" "--name-status" "-r" full)))
             (files (loop for l in (uiop:split-string diff :separator '(#\Newline))
                          for tab = (position #\Tab l)
                          when tab collect (list :path (subseq l (1+ tab)) :status (subseq l 0 tab))))
             (changes (loop for f in files
                            for path = (getf f :path) for status = (getf f :status)
                            when (code-path-p path)
                              append (definition-changes path
                                       (and parent (not (string= status "A")) (blob-text repository parent path))
                                       (and (not (string= status "D")) (blob-text repository full path))))))
        (make-instance 'commit-evidence :sha full :parents parents :subject subject :authored-at authored :origin :git-object
                                        :availability :git-object :files files :changes changes))))

;;; Recorded evidence: what a read-only observer saw in the objects of a repository that this checkout does not have, as plain data.

(defun change-form (change)
  (list :key (definition-change-key change) :kind (definition-change-kind change) :path (definition-change-path change)
        :before-text (and (definition-change-before change) (source-definition-text (definition-change-before change)))
        :after-text (and (definition-change-after change) (source-definition-text (definition-change-after change)))
        :before-digest (and (definition-change-before change) (source-definition-digest (definition-change-before change)))
        :after-digest (and (definition-change-after change) (source-definition-digest (definition-change-after change)))))

(defun recorded-evidence-form (evidence &key recorded-from)
  `(:upstream-commit-evidence :version 1 :sha ,(commit-evidence-sha evidence) :parents ,(commit-evidence-parents evidence)
    :subject ,(commit-evidence-subject evidence) :authored-at ,(commit-evidence-authored-at evidence)
    :recorded-from ,(or recorded-from (commit-evidence-recorded-from evidence))
    :files ,(commit-evidence-files evidence) :changes ,(mapcar #'change-form (commit-evidence-changes evidence))))

(defun plain-data-p (form)
  (typecase form
    (null t) ((eql t) t) (keyword t) (string t) (integer t)
    (cons (and (plain-data-p (car form)) (plain-data-p (cdr form))))
    (t nil)))

(defun read-plain-data (pathname)
  (with-open-file (in pathname :external-format :utf-8)
    (let* ((*read-eval* nil) (*package* (find-package :cl-user)) (form (read in)))
      (when (read in nil nil) (error "~A holds more than one form." pathname))
      (unless (plain-data-p form) (error "~A holds more than plain data." pathname))
      form)))

(defun write-plain-data (form pathname)
  (ensure-directories-exist pathname)
  (with-open-file (out pathname :direction :output :if-exists :supersede :external-format :utf-8)
    (let ((*print-readably* nil) (*print-pretty* t) (*print-right-margin* 150) (*package* (find-package :cl-user)))
      (prin1 form out) (terpri out)))
  pathname)

(defun write-recorded-evidence (evidence pathname &key recorded-from)
  (write-plain-data (recorded-evidence-form evidence :recorded-from recorded-from) pathname))

(defun read-recorded-evidence (pathname)
  (let ((form (read-plain-data pathname)))
    (unless (and (consp form) (eq :upstream-commit-evidence (first form))) (error "~A is not recorded commit evidence." pathname))
    (destructuring-bind (&key version sha parents subject authored-at recorded-from files changes) (rest form)
      (unless (eql 1 version) (error "Unsupported evidence version ~S." version))
      (make-instance
       'commit-evidence :sha sha :parents parents :subject subject :authored-at authored-at :origin :recorded :availability :recorded
                        :recorded-from recorded-from :files files
                        :changes (loop for c in changes
                                       collect (destructuring-bind (&key key kind path before-text after-text &allow-other-keys) c
                                                 (make-change key kind path
                                                              (and before-text (first (top-level-definitions before-text :path path)))
                                                              (and after-text (first (top-level-definitions after-text :path path))))))))))

(defun verify-recorded-evidence (evidence repository)
  "Whether recorded EVIDENCE agrees with the objects of REPOSITORY: :VERIFIED, :MISMATCH (with what differs) or :UNVERIFIABLE when the commit is not there."
  (if (not (g:git-commit-object-present-p repository (commit-evidence-sha evidence)))
      (values :unverifiable nil)
      (let* ((fresh (evidence-from-repository repository (commit-evidence-sha evidence)))
             (digests (lambda (e) (sort (mapcar (lambda (c) (list (definition-change-key c) (definition-change-kind c)
                                                                  (and (definition-change-before c) (source-definition-digest (definition-change-before c)))
                                                                  (and (definition-change-after c) (source-definition-digest (definition-change-after c)))))
                                                (commit-evidence-changes e))
                                        #'string< :key #'first)))
             (mine (funcall digests evidence)) (theirs (funcall digests fresh))
             (differences (append (set-difference mine theirs :test #'equal) (set-difference theirs mine :test #'equal))))
        (if differences (values :mismatch differences) (values :verified nil)))))

;;; ------------------------------------------------------------------------------------------------------------------------------------
;;; The fork: where a changed definition stands now

(defparameter +excluded-directories+ '(".git" "node_modules" "docs" ".cache"))

(defclass fork-index ()
  ((root :initarg :root :reader fork-index-root)
   (files :reader fork-index-files)
   (texts :initform (make-hash-table :test #'equal))
   (definitions :initform (make-hash-table :test #'equal))
   (system-map :initform nil)))

(defun collect-code-files (root)
  (let ((files '()))
    (labels ((walk (directory)
               (dolist (file (uiop:directory-files directory))
                 (when (code-path-p (namestring file)) (push (enough-namestring file root) files)))
               (dolist (sub (uiop:subdirectories directory))
                 (unless (member (car (last (pathname-directory sub))) +excluded-directories+ :test #'string=) (walk sub)))))
      (walk root))
    (sort files #'string<)))

(defun make-fork-index (root)
  "An index over the Lisp and ASDF files under ROOT. Texts and scanned definitions are read on demand and kept."
  (let* ((root (uiop:ensure-directory-pathname (truename root))) (index (make-instance 'fork-index :root root)))
    (setf (slot-value index 'files) (collect-code-files root))
    index))

(defun index-text (index path)
  (let ((table (slot-value index 'texts)))
    (multiple-value-bind (text present) (gethash path table)
      (if present text
          (setf (gethash path table)
                (or (ignore-errors (uiop:read-file-string (merge-pathnames path (fork-index-root index)) :external-format :utf-8)) ""))))))

(defun index-definitions (index path)
  (let ((table (slot-value index 'definitions)))
    (or (gethash path table) (setf (gethash path table) (top-level-definitions (index-text index path) :path path)))))

(defun files-mentioning (index needle)
  (remove-if-not (lambda (path) (search needle (index-text index path) :test #'char-equal)) (fork-index-files index)))

(defun unnamed-key-p (key) (or (uiop:string-prefix-p "form:" key) (uiop:string-prefix-p "in-package:" key)))

(defun find-definitions (index key name &optional path)
  "The definitions with KEY in the fork. A form without a name is the same form only in the same file: with PATH, only there."
  (loop for path in (if (and path (unnamed-key-p key)) (list path) (files-mentioning index name))
        append (remove-if-not (lambda (d) (equal key (source-definition-key d))) (index-definitions index path))))

(defun tree-strings (tree)
  (cond ((stringp tree) (list tree)) ((keyword-headed-p tree) '()) ((consp tree) (mapcan #'tree-strings tree)) (t '())))

(defun tree-contains-extension-p (tree fragment)
  "Whether TREE holds a list with FRAGMENT's head that has every other element of FRAGMENT and more: the same list, extended."
  (and (consp tree) (not (keyword-headed-p tree))
       (or (and (consp fragment) (equal (car tree) (car fragment)) (> (length tree) (length fragment))
                (every (lambda (x) (member x (cdr tree) :test #'equal)) (cdr fragment)))
           (some (lambda (child) (tree-contains-extension-p child fragment)) tree))))

(defun find-extended-fragment (index fragment)
  (let ((anchor (first (sort (remove-if (lambda (s) (< (length s) 5)) (copy-list (tree-strings fragment))) #'> :key #'length))))
    (when anchor
      (loop for path in (files-mentioning index anchor)
            append (remove-if-not (lambda (d) (tree-contains-extension-p (source-definition-tree d) fragment)) (index-definitions index path))))))

(defun find-fragment (index fragment)
  "The definitions of the fork that contain FRAGMENT (a canonical tree) anywhere in them."
  (let ((anchor (first (sort (remove-if (lambda (s) (< (length s) 5)) (copy-list (tree-strings fragment))) #'> :key #'length))))
    (when anchor
      (loop for path in (files-mentioning index anchor)
            append (remove-if-not (lambda (d) (tree-contains-p (source-definition-tree d) fragment)) (index-definitions index path))))))

(defstruct fork-situation relation locations fragments claims)

(defun location (definition) (list (source-definition-path definition) (source-definition-key definition) (source-definition-digest definition)))

(defun situation-of (change index)
  "Where CHANGE's definition stands in the fork. RELATION is :UNCHANGED (as upstream had it before), :ADOPTED (as upstream has it after), :CHANGED (a local
version), :REPLACED (its changed part now stands in other definitions), :MOVED (the same key at another path) or :ABSENT."
  (let* ((before (definition-change-before change)) (after (definition-change-after change))
         (key (definition-change-key change)) (path (definition-change-path change))
         (name (source-definition-name (or after before)))
         (defs (find-definitions index key name path))
         (same-path (remove-if-not (lambda (d) (equal path (source-definition-path d))) defs))
         (claims '()) (fragments '()) (relation nil))
    (flet ((digest= (d x) (and x (equal (source-definition-digest d) (source-definition-digest x)))))
      (cond
        ((null defs) (setf relation :absent))
        ((some (lambda (d) (digest= d after)) defs)
         (setf relation :adopted))
        ((some (lambda (d) (digest= d before)) defs)
         (setf relation :unchanged))
        (t (setf relation :changed)))
      (when (and defs (null same-path) (member relation '(:unchanged :adopted :changed)))
        (setf relation :moved)
        (push (make-claim (format nil "The key ~A stands only at ~{~A~^, ~}, not at ~A." key (mapcar #'source-definition-path defs) path)
                          :mechanically-derived (list "scan of the fork's Lisp and ASDF files")) claims))
      ;; the changed parts of a changed definition: where each of them stands now
      (when (eq :changed (definition-change-kind change))
        (dolist (pair (definition-change-fragments change))
          (let* ((b (car pair)) (a (cdr pair))
                 (in-local (lambda (fragment) (remove-if-not (lambda (d) (tree-contains-p (source-definition-tree d) fragment)) defs)))
                 (status (cond ((funcall in-local a) :after-present)
                               ((funcall in-local b) :before-present)
                               (t nil)))
                 (elsewhere nil))
            (unless status
              (let ((b-found (find-fragment index b)) (a-found (find-fragment index a)) (extended (find-extended-fragment index b)))
                (cond (a-found (setf status :after-elsewhere elsewhere a-found))
                      (b-found (setf status :before-elsewhere elsewhere b-found))
                      (extended (setf status :extended-elsewhere elsewhere extended))
                      (t (setf status :absent)))))
            (push (list :before b :after a :status status :elsewhere (mapcar #'location elsewhere)) fragments)))
        (setf fragments (nreverse fragments))
        (when (and fragments (member relation '(:changed :absent))
                   (every (lambda (f) (member (getf f :status) '(:before-elsewhere :after-elsewhere :extended-elsewhere))) fragments))
          (setf relation :replaced)))
      (push (make-claim (ecase relation
                          (:unchanged "The fork's definition is the upstream definition as it was before the commit.")
                          (:adopted "The fork's definition is the upstream definition as it is after the commit.")
                          (:changed "The fork has a version of this definition that is neither the upstream one before nor after the commit.")
                          (:replaced "The definition's changed part no longer stands in it: it stands, before or after, in other definitions.")
                          (:moved "The definition stands at another path than upstream's.")
                          (:absent "The fork has no definition with this key."))
                        :mechanically-derived (list "digests of canonical source trees, compared; no source was read or loaded"))
            claims))
    (make-fork-situation :relation relation :locations (mapcar #'location defs) :fragments fragments :claims (nreverse claims))))

(defun fork-integration (fork-repository sha)
  "What the fork's own Git says of SHA, through the existing intake classification: whether its objects are there, whether it is an ancestor of HEAD, and
the classification (:NOT-AVAILABLE-LOCALLY, :AVAILABLE-NOT-INTEGRATED, :ALREADY-INTEGRATED). Not whether its source stands in the fork: that is source adoption."
  (if (null fork-repository)
      (list :object-present-p :unknown :ancestor-of-head-p :unknown :classification :unknown)
      (let ((reference (dreyeck/upstream-intake:make-upstream-commit-intake sha :origin "upstream intake" :repository fork-repository)))
        (list :object-present-p (dreyeck/upstream-intake:git-commit-upstream-object-present-p reference)
              :ancestor-of-head-p (dreyeck/upstream-intake:git-commit-upstream-ancestor-of-head-p reference)
              :classification (dreyeck/upstream-intake:git-commit-upstream-classification-of reference)
              :merge-base (let ((m (dreyeck/upstream-intake:git-commit-upstream-merge-base-of reference))) (and m (princ-to-string m)))))))

;;; ------------------------------------------------------------------------------------------------------------------------------------
;;; Ownership: which ASDF system owns a definition now, and which should

(defclass ownership-policy ()
  ((upstream-paths :initarg :upstream-paths :initform nil :reader policy-upstream-paths)
   (inventory :initarg :inventory :initform nil :reader policy-inventory
              :documentation "Plists (:PATH :KEY :CATEGORY :TARGET-SYSTEM :BASIS) of decided ownership, from the ownership inventory.")
   (contract-paths :initarg :contract-paths :initform nil :reader policy-contract-paths)
   (page-directory :initarg :page-directory :initform "dreyeck/pages" :reader policy-page-directory)))

(defun make-ownership-policy (&rest initargs) (apply #'make-instance 'ownership-policy initargs))

(defun path-under-p (path prefix)
  (or (string= path prefix) (uiop:string-prefix-p (concatenate 'string prefix "/") path)))

(defun ownership-of (policy path key owners)
  "(VALUES CATEGORY SHOULD-OWN CLAIM): :UPSTREAM-OWNED, :DREYECK-OWNED or :REUSABLE-EXTENSION, and the ASDF system(s) that should own the definition."
  (let ((entry (find-if (lambda (e) (and (equal path (getf e :path)) (or (equal key (getf e :key)) (equal "*" (getf e :key))))) (policy-inventory policy))))
    (cond (entry (values (getf entry :category) (getf entry :target-system)
                         (make-claim (format nil "The ownership inventory records ~(~A~) for this definition, target ~A." (getf entry :category) (getf entry :target-system))
                                     :source-observed (list (or (getf entry :basis) "ownership inventory")))))
          ((some (lambda (p) (path-under-p path p)) (policy-upstream-paths policy))
           (values :upstream-owned owners
                   (make-claim "The path is one of the library paths of the upstream contract: upstream owns it, and the owning systems are those that list it."
                               :mechanically-derived (list "library paths of dreyeck/hyperdoc/library-tests"))))
          (t (values :dreyeck-owned owners
                     (make-claim "The path is not a library path: dreyeck owns it." :mechanically-derived (list "library paths of dreyeck/hyperdoc/library-tests")))))))

(defparameter +library-paths+
  '("hyperdoc" "hyperbook" "hyperdoc-explorer" "hyperbook-explorer" "inspector-hyperdoc" "hyperbook-fedwiki" "hyperbook-wikipedia" "hyperbook-server"
    "hyperdoc.asd" "hyperbook.asd")
  "The library paths of the upstream contract, dreyeck/hyperdoc/library-tests.")

(defun default-ownership-policy (root)
  "The policy for the checkout at ROOT: the contract's library paths, its contract files, and the ownership inventory when the checkout has one."
  (let* ((inventory-file (merge-pathnames "docs/code-ownership/inventory.lisp-data" (uiop:ensure-directory-pathname root)))
         (inventory (and (probe-file inventory-file) (getf (rest (read-plain-data inventory-file)) :entries))))
    (make-ownership-policy :upstream-paths +library-paths+ :inventory inventory :page-directory "dreyeck/pages"
                           :contract-paths '("dreyeck/tests/hyperdoc-library-delta.lisp" "dreyeck/tests/hyperdoc-boundary.lisp"))))

(defun system-names-in-root (root)
  (loop for asd in (directory (merge-pathnames "*.asd" root))
        append (let ((text (ignore-errors (uiop:read-file-string asd :external-format :utf-8))))
                 (when text
                   (loop for node in (src:scan-asdf-source text)
                         when (src:asdf-defsystem-form-p node)
                           collect (let ((designator (second (src:asdf-source-node-children node))))
                                     (and designator (let ((n (src:simple-asdf-designator-name designator))) (and n (string-downcase n))))))))))

(defun dependency-name (dependency)
  (typecase dependency
    (string (string-downcase dependency))
    (symbol (string-downcase (symbol-name dependency)))
    (cons (case (first dependency) (:version (dependency-name (second dependency))) (:feature (dependency-name (third dependency))) (t nil)))))

(defun system-map (index)
  "(VALUES PATHS DEPENDENCIES): which systems list each file, and what each system depends on, from the ASDF definitions in the root's .asd files.
ASDF is asked what the definitions say (component pathnames, DEPENDS-ON); no component is compiled or loaded."
  (or (slot-value index 'system-map)
      (setf (slot-value index 'system-map)
            (let ((paths (make-hash-table :test #'equal)) (deps (make-hash-table :test #'equal)))
              (dolist (name (remove nil (remove-duplicates (system-names-in-root (fork-index-root index)) :test #'equal)))
                (let ((system (ignore-errors (asdf:find-system name nil))))
                  (when system
                    (dolist (p (ignore-errors (dreyeck/workflow::owned-paths system)))
                      (let ((truename (ignore-errors (truename p))))
                        (when truename (pushnew name (gethash (namestring truename) paths) :test #'string=))))
                    (setf (gethash name deps) (remove nil (mapcar #'dependency-name (ignore-errors (asdf:system-depends-on system))))))))
              (cons paths deps)))))

(defun system-owners-of (index path)
  (let ((truename (ignore-errors (truename (merge-pathnames path (fork-index-root index))))))
    (and truename (reverse (gethash (namestring truename) (car (system-map index)))))))

(defun dependent-systems (index names)
  "Every system that depends, directly or transitively, on one of NAMES, among the systems the root defines."
  (let ((deps (cdr (system-map index))) (found '()) (frontier (copy-list names)))
    (loop while frontier
          do (let ((current (pop frontier)))
               (maphash (lambda (system dependencies)
                          (when (and (member current dependencies :test #'string=) (not (member system found :test #'string=)) (not (member system names :test #'string=)))
                            (push system found) (push system frontier)))
                        deps)))
    (sort found #'string<)))

;;; ------------------------------------------------------------------------------------------------------------------------------------
;;; Impact

(defstruct impact systems tests callers pages contracts claims)

(defun tree-mentions-p (tree token)
  (cond ((stringp tree) (string= (strip-package tree) token))
        ((keyword-headed-p tree) nil)
        ((consp tree) (some (lambda (child) (tree-mentions-p child token)) tree))
        (t nil)))

(defun test-system-name-p (name)
  (or (uiop:string-suffix-p name "/tests") (uiop:string-suffix-p name "-tests") (search "/tests/" name)))

(defun impact-of (change situation index policy owners)
  "What may be affected if CHANGE's definition changes: the owning and dependent ASDF systems, the tests among them, definitions that mention the name, HyperDoc
pages that mention it, and the contract files that name it. Found by search over the fork's source; a mention is a lead, not proof of a call."
  (declare (ignore situation))
  (let* ((definition (or (definition-change-after change) (definition-change-before change)))
         (name (source-definition-name definition)) (token (strip-package name))
         (systems (remove-duplicates (append owners (dependent-systems index owners)) :test #'string=))
         (named (not (unnamed-key-p (definition-change-key change))))
         (callers (let ((found '()))
                    (dolist (path (and named (files-mentioning index token)))
                      (dolist (d (index-definitions index path))
                        (when (and (not (and (equal path (definition-change-path change)) (equal (source-definition-key d) (definition-change-key change))))
                                   (tree-mentions-p (source-definition-tree d) token))
                          (push (list path (source-definition-key d)) found))))
                    (let ((list (nreverse found))) (subseq list 0 (min 60 (length list))))))
         (pages (let ((dir (merge-pathnames (uiop:ensure-directory-pathname (policy-page-directory policy)) (fork-index-root index))))
                  (when (and named (probe-file dir))
                    (loop for file in (directory (merge-pathnames "**/*.html" dir))
                          when (let ((text (ignore-errors (uiop:read-file-string file :external-format :utf-8)))) (and text (search token text :test #'char-equal)))
                            collect (enough-namestring file (fork-index-root index))))))
         (contracts (loop for path in (and named (policy-contract-paths policy))
                          for text = (ignore-errors (uiop:read-file-string (merge-pathnames path (fork-index-root index)) :external-format :utf-8))
                          when (and text (search token text :test #'char-equal))
                            collect (list path (count-occurrences token text)))))
    (make-impact :systems (sort (copy-list systems) #'string<)
                 :tests (sort (remove-if-not #'test-system-name-p systems) #'string<)
                 :callers callers :pages pages :contracts contracts
                 :claims (list (make-claim (format nil "Search for the name ~S over the fork's Lisp, ASDF and page files; owners and dependents from the ASDF definitions." token)
                                           :mechanically-derived (list "text search" "ASDF DEPENDS-ON of the systems the root defines"))))))

(defun count-occurrences (needle text)
  (loop with start = 0 for found = (search needle text :start2 start :test #'char-equal) while found count t do (setf start (1+ found))))

;;; ------------------------------------------------------------------------------------------------------------------------------------
;;; Decisions and their ledger

(defparameter +decision-kinds+
  '(:adopt-upstream-change :already-covered :move-dreyeck-extension :prepare-upstream-contribution :do-not-adopt :defer))
(defparameter +decision-statuses+ '(:proposed :accepted :rejected :executed))

(defstruct (decision (:conc-name decision-) (:constructor %make-decision))
  id commit subject kind status rationale evidence required-migration verification proposed-by)

(defun make-decision (&key commit subject kind (status :proposed) rationale evidence required-migration verification proposed-by)
  (unless (member kind +decision-kinds+) (error "~S is not a decision kind: ~S." kind +decision-kinds+))
  (unless (member status +decision-statuses+) (error "~S is not a decision status: ~S." status +decision-statuses+))
  (%make-decision :id (subseq (sha256-hex (format nil "~A|~A" commit subject)) 0 16) :commit commit :subject subject :kind kind :status status
                  :rationale rationale :evidence evidence :required-migration required-migration :verification verification :proposed-by proposed-by))

(defun claim-form (claim) (list :text (claim-text claim) :status (claim-status claim) :basis (claim-basis claim)))
(defun form-claim (form) (destructuring-bind (&key text status basis) form (make-claim text status basis)))

(defun decision-form (d)
  (list :id (decision-id d) :commit (decision-commit d) :subject (decision-subject d) :kind (decision-kind d) :status (decision-status d)
        :rationale (decision-rationale d) :evidence (mapcar #'claim-form (decision-evidence d))
        :required-migration (decision-required-migration d) :verification (decision-verification d) :proposed-by (decision-proposed-by d)))

(defun form-decision (form)
  (destructuring-bind (&key commit subject kind status rationale evidence required-migration verification proposed-by &allow-other-keys) form
    (make-decision :commit commit :subject subject :kind kind :status status :rationale rationale :evidence (mapcar #'form-claim evidence)
                   :required-migration required-migration :verification verification :proposed-by proposed-by)))

(define-condition decision-conflict (error)
  ((existing :initarg :existing :reader conflict-existing) (offered :initarg :offered :reader conflict-offered))
  (:report (lambda (c stream) (format stream "A different decision is already recorded for ~A / ~A." (decision-commit (conflict-existing c)) (decision-subject (conflict-existing c))))))

(defclass ledger () ((decisions :initform '() :accessor ledger-decisions-slot)))
(defun make-ledger () (make-instance 'ledger))
(defun ledger-decisions (ledger) (reverse (ledger-decisions-slot ledger)))

(defun ledger-find (ledger commit &optional subject-prefix)
  "The recorded decisions for COMMIT; with SUBJECT, those for that subject and for its sub-subjects (SUBJECT#PART)."
  (remove-if-not (lambda (d) (and (equal commit (decision-commit d)) (or (null subject-prefix) (string= subject-prefix (decision-subject d))
                                                                                           (uiop:string-prefix-p (concatenate 'string subject-prefix "#") (decision-subject d)))))
                 (ledger-decisions ledger)))

(defun ledger-record (ledger decision)
  "Record DECISION once. The same decision again returns the recorded one (observing a commit twice does not double its decisions); a different decision for
the same commit and subject is a conflict that a person resolves, never an overwrite."
  (let ((existing (find (decision-id decision) (ledger-decisions-slot ledger) :key #'decision-id :test #'string=)))
    (cond ((null existing) (push decision (ledger-decisions-slot ledger)) decision)
          ((equal (decision-form existing) (decision-form decision)) existing)
          (t (error 'decision-conflict :existing existing :offered decision)))))

(defun ledger-form (ledger) `(:upstream-decision-ledger :version 1 :decisions ,(mapcar #'decision-form (ledger-decisions ledger))))

(defun ledger-from-form (form)
  (unless (and (consp form) (eq :upstream-decision-ledger (first form))) (error "Not a decision ledger form."))
  (let ((ledger (make-ledger)))
    (dolist (d (getf (rest form) :decisions) ledger) (ledger-record ledger (form-decision d)))))

(defun read-ledger (pathname) (ledger-from-form (read-plain-data pathname)))
(defun write-ledger (ledger pathname) (write-plain-data (ledger-form ledger) pathname))

;;; The assessment of one change and of one commit

(defstruct change-assessment change situation owners ownership impact proposal recorded commit)
(defstruct commit-assessment evidence integration changes source-adoption notes)

(defun change-subject (change) (format nil "~A::~A" (definition-change-path change) (definition-change-key change)))

(defun propose-decision (commit-sha change situation ownership-category)
  "A mechanical PROPOSAL for one change. It is :PROPOSED by rule, never executed, and a person's recorded decision stands beside it, not under it."
  (let* ((relation (fork-situation-relation situation)) (kind (definition-change-kind change))
         (upstream-owned (eq :upstream-owned ownership-category))
         (decision-kind (cond ((eq relation :adopted) :already-covered)
                              ((and (eq relation :unchanged) (eq kind :changed) upstream-owned) :adopt-upstream-change)
                              ((and (eq relation :absent) (eq kind :added) upstream-owned) :adopt-upstream-change)
                              ((and (eq relation :absent) (eq kind :removed)) :already-covered)
                              (t :defer)))
         (rationale (ecase decision-kind
                      (:already-covered "The fork already has the definition as the commit leaves it, or already lacks what the commit removed.")
                      (:adopt-upstream-change "The fork's definition is as upstream had it before the commit and upstream owns the path: the change can be taken as it is, by an explicit step.")
                      (:defer (format nil "The fork's definition stands as ~(~A~) against upstream's: a person must compare what the local version does that the commit changes." relation)))))
    (make-decision :commit commit-sha :subject (change-subject change) :kind decision-kind :status :proposed :rationale rationale
                   :evidence (fork-situation-claims situation) :proposed-by "rule")))

(defun source-adoption-of (evidence changes)
  (cond ((eq :missing (commit-evidence-availability evidence)) :undetermined)
        ((null changes) :no-code-change)
        (t (let ((adopted (count-if (lambda (c) (let ((relation (fork-situation-relation (change-assessment-situation c))) (kind (definition-change-kind (change-assessment-change c))))
                                                  (or (eq relation :adopted) (and (eq kind :removed) (eq relation :absent)))))
                                    changes)))
             (cond ((= adopted (length changes)) :all-adopted) ((zerop adopted) :none-adopted) (t :partial))))))

(defun assess-commit (evidence index policy ledger &key fork-repository)
  "The full assessment of one commit's evidence against the fork INDEX."
  (let* ((sha (commit-evidence-sha evidence))
         (changes (loop for change in (commit-evidence-changes evidence)
                        collect (let* ((situation (situation-of change index))
                                       (path (definition-change-path change))
                                       (owners (system-owners-of index path)))
                                  (multiple-value-bind (category should-own claim) (ownership-of policy path (definition-change-key change) owners)
                                    (make-change-assessment
                                     :change change :situation situation :owners owners
                                     :ownership (list :category category :should-own should-own :claim claim)
                                     :impact (impact-of change situation index policy owners)
                                     :proposal (propose-decision sha change situation category)
                                     :recorded (ledger-find ledger sha (change-subject change))
                                     :commit nil)))))
         (notes '()))
    (when (eq :missing (commit-evidence-availability evidence))
      (push (make-claim "Neither the objects of this commit nor recorded evidence for it are available here: nothing can be said of what it changes. The objects were not fetched."
                        :source-observed (list "git cat-file in the repositories given" "no recorded evidence file")) notes))
    (when (eq :recorded (commit-evidence-availability evidence))
      (push (make-claim "This commit is known from recorded evidence, not from objects in a repository given to this run."
                        :source-observed (list "recorded evidence file")) notes))
    (let ((assessment (make-commit-assessment :evidence evidence :integration (fork-integration fork-repository sha) :changes changes
                                              :source-adoption (source-adoption-of evidence changes) :notes (nreverse notes))))
      (dolist (change changes assessment) (setf (change-assessment-commit change) assessment)))))

;;; ------------------------------------------------------------------------------------------------------------------------------------
;;; The run

(defclass intake-run ()
  ((observation :initarg :observation :reader intake-run-observation)
   (last-examined :initarg :last-examined :reader intake-run-last-examined)
   (commits :initarg :commits :reader intake-run-commits)
   (status :initarg :status :reader intake-run-status :documentation ":UP-TO-DATE, :NEW-COMMITS or :EVIDENCE-MISSING")
   (state :initarg :state :reader intake-run-state)))

(defun read-evidence-directory (directory)
  "Recorded commit evidence in DIRECTORY (every *.lisp-data file that is such evidence), or NIL when there is none."
  (when (probe-file directory)
    (loop for file in (directory (merge-pathnames "*.lisp-data" (uiop:ensure-directory-pathname directory)))
          for form = (ignore-errors (read-plain-data file))
          when (and (consp form) (eq :upstream-commit-evidence (first form))) collect (read-recorded-evidence file))))

(defun read-state (pathname) (and (probe-file pathname) (read-plain-data pathname)))
(defun write-state (state pathname) (write-plain-data state pathname))
(defun state-last-examined (state) (getf (rest state) :last-examined))

(defun assess-upstream (&key upstream-repository fork-repository fork-root (ref "main") state (ledger (make-ledger)) policy
                             recorded-evidence commits)
  "One read-only intake run. UPSTREAM-REPOSITORY and FORK-REPOSITORY are repositories this run may read; FORK-ROOT is the fork's working tree.
RECORDED-EVIDENCE is a list of COMMIT-EVIDENCE read from evidence files. COMMITS names commits to assess regardless of the observed range (a notification
that tells of a commit). Nothing is fetched, written or loaded."
  (let* ((observation (and upstream-repository (observe-upstream upstream-repository ref)))
         (last-examined (and state (state-last-examined state)))
         (range (cond (commits commits)
                      ((and observation (upstream-observation-tip observation) last-examined
                            (g:git-commit-object-present-p upstream-repository last-examined))
                       (commits-between upstream-repository last-examined (upstream-observation-tip observation)))
                      ((and observation (upstream-observation-tip observation) (null last-examined)) (list (upstream-observation-tip observation)))
                      (t '())))
         (index (make-fork-index fork-root))
         (policy (or policy (make-ownership-policy)))
         (assessments
           (loop for sha in range
                 collect (let ((evidence (or (and upstream-repository (g:git-commit-object-present-p upstream-repository sha)
                                                  (evidence-from-repository upstream-repository sha))
                                             (and fork-repository (g:git-commit-object-present-p fork-repository sha)
                                                  (evidence-from-repository fork-repository sha))
                                             (find sha recorded-evidence :key #'commit-evidence-sha :test #'uiop:string-prefix-p)
                                             (find sha recorded-evidence :key #'commit-evidence-sha :test (lambda (a b) (uiop:string-prefix-p b a)))
                                             (missing-evidence sha))))
                           (assess-commit evidence index policy ledger :fork-repository fork-repository)))))
    (make-instance 'intake-run :observation observation :last-examined last-examined :commits assessments :state state
                               :status (cond ((null assessments) :up-to-date)
                                             ((some (lambda (a) (eq :missing (commit-evidence-availability (commit-assessment-evidence a)))) assessments) :evidence-missing)
                                             (t :new-commits)))))

(defun run-exit-status (run) (ecase (intake-run-status run) (:up-to-date 0) (:new-commits 10) (:evidence-missing 20)))

(defun short (sha) (and sha (subseq sha 0 (min 9 (length sha)))))

(defun report-run (run &optional (stream *standard-output*))
  "A plain-text report of RUN."
  (let ((observation (intake-run-observation run)))
    (format stream "Upstream intake~%")
    (format stream "  last examined : ~A~%" (or (short (intake-run-last-examined run)) "none recorded"))
    (if observation
        (format stream "  observed      : ~A = ~A (objects ~:[NOT present~;present~] in the upstream repository given)~%"
                (upstream-observation-ref observation) (or (short (upstream-observation-tip observation)) "not found") (upstream-observation-tip-present-p observation))
        (format stream "  observed      : no upstream repository given~%"))
    (format stream "  status        : ~(~A~) (~D commit~:P to assess)~%" (intake-run-status run) (length (intake-run-commits run)))
    (dolist (assessment (intake-run-commits run))
      (let ((evidence (commit-assessment-evidence assessment)) (integration (commit-assessment-integration assessment)))
        (format stream "~%commit ~A  ~A~%" (short (commit-evidence-sha evidence)) (or (commit-evidence-subject evidence) "(no evidence)"))
        (format stream "  evidence      : ~(~A~)~%  fork objects   : ~(~A~)   Git ancestry (of HEAD): ~(~A~)   source adoption: ~(~A~)~%"
                (commit-evidence-availability evidence) (getf integration :object-present-p) (getf integration :ancestor-of-head-p)
                (commit-assessment-source-adoption assessment))
        (dolist (note (commit-assessment-notes assessment)) (format stream "  note [~(~A~)]: ~A~%" (claim-status note) (claim-text note)))
        (dolist (change (commit-assessment-changes assessment))
          (let* ((c (change-assessment-change change)) (s (change-assessment-situation change)) (o (change-assessment-ownership change)) (i (change-assessment-impact change))
                 (p (change-assessment-proposal change)))
            (format stream "  ~(~A~) ~A  [~A]~%    fork: ~(~A~)~@[ at ~{~A~^, ~}~]~%    owner now: ~{~A~^, ~}  ~(~A~)  should own: ~{~A~^, ~}~%    impact: ~D system~:P, ~D test system~:P, ~D mentioning definition~:P, ~D page~:P, ~D contract file~:P~%    proposal: ~(~A~) (~(~A~))~%"
                    (definition-change-kind c) (definition-change-key c) (definition-change-path c)
                    (fork-situation-relation s) (mapcar #'first (fork-situation-locations s))
                    (change-assessment-owners change) (getf o :category) (let ((so (getf o :should-own))) (if (listp so) so (list so)))
                    (length (impact-systems i)) (length (impact-tests i)) (length (impact-callers i)) (length (impact-pages i)) (length (impact-contracts i))
                    (decision-kind p) (decision-status p))
            (dolist (r (change-assessment-recorded change))
              (format stream "    recorded: ~(~A~) (~(~A~)), by ~A~%" (decision-kind r) (decision-status r) (decision-proposed-by r)))))))))

;;; Printing: short, and never circular (a change assessment points back to its commit assessment, which holds it).

(defmethod print-object ((x claim) stream)
  (print-unreadable-object (x stream :type t) (format stream "~(~A~)" (claim-status x))))
(defmethod print-object ((x source-definition) stream)
  (print-unreadable-object (x stream :type t) (format stream "~A" (source-definition-key x))))
(defmethod print-object ((x definition-change) stream)
  (print-unreadable-object (x stream :type t) (format stream "~(~A~) ~A" (definition-change-kind x) (definition-change-key x))))
(defmethod print-object ((x fork-situation) stream)
  (print-unreadable-object (x stream :type t) (format stream "~(~A~)" (fork-situation-relation x))))
(defmethod print-object ((x impact) stream)
  (print-unreadable-object (x stream :type t) (format stream "~D systems" (length (impact-systems x)))))
(defmethod print-object ((x change-assessment) stream)
  (print-unreadable-object (x stream :type t) (format stream "~A" (definition-change-key (change-assessment-change x)))))
(defmethod print-object ((x commit-assessment) stream)
  (print-unreadable-object (x stream :type t) (format stream "~A" (short (commit-evidence-sha (commit-assessment-evidence x))))))
(defmethod print-object ((x decision) stream)
  (print-unreadable-object (x stream :type t) (format stream "~(~A~) ~(~A~)" (decision-kind x) (decision-status x))))
(defmethod print-object ((x commit-evidence) stream)
  (print-unreadable-object (x stream :type t) (format stream "~A ~(~A~)" (short (commit-evidence-sha x)) (commit-evidence-availability x))))
