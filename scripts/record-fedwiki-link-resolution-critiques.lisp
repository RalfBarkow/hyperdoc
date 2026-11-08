;;;; Record what the real Riesbeck/Beane Lisp Critic says about the Lisp code of PR #32, form by form and rule by rule.
;;;;
;;;; RUNS THE ENGINE. Only in an authorized, isolated development runtime whose DREYECK_LISP_CRITIC_ROOT names the page
;;;; assets of the page-attached ASDF system a-critic-for-lisp (its definition and vendor/lisp-critic/). Never where the
;;;; result is read: the reader (dreyeck/work/fedwiki-link-resolution/critic) reads the JSON this writes and runs nothing.
;;;;   DREYECK_LISP_CRITIC_ROOT=<page assets> sbcl --non-interactive --load scripts/record-fedwiki-link-resolution-critiques.lisp
;;;;
;;;; The target forms are read as data (*READ-EVAL* NIL) and never evaluated. Every rule the engine has is applied to every
;;;; top-level form; a run without a finding is a result and is counted. Runs with findings keep their whole Evaluation
;;;; Record (the existing snapshot), the matched subform and its path, and the engine's own recommendation text.
(require :asdf)
(asdf:load-asd (merge-pathnames "../dreyeck.asd" (uiop:pathname-directory-pathname *load-truename*)))
(asdf:load-system "dreyeck/lisp-critic/engine-integration/tests")
(asdf:load-system "dreyeck/work/fedwiki-link-resolution/tests")
(asdf:load-system "html-inspector-views/standard")     ; the packages the runner script names

(defpackage #:record-pr-critiques
  (:use #:cl)
  (:local-nicknames (#:critic #:dreyeck/lisp-critic) (#:rec #:dreyeck/lisp-critic/recorded)))
(in-package #:record-pr-critiques)

(defparameter +root+ (uiop:pathname-parent-directory-pathname (uiop:pathname-directory-pathname *load-truename*)))
(defparameter +pull-request+ "RalfBarkow/hyperdoc#32")
(defparameter +targets+
  '(("dreyeck/work/fedwiki-link-resolution.lisp" :all)
    ("dreyeck/tests/fedwiki-link-resolution.lisp" :all)
    ("scripts/test-fedwiki-link-resolution.lisp" :all)
    ("dreyeck.asd" ("dreyeck/work/fedwiki-link-resolution" "dreyeck/work/fedwiki-link-resolution/tests")))
  "The Lisp code PR #32 adds: whole files, and in dreyeck.asd only the two systems it adds.")
(defparameter +not-critiqued+
  '(("docs/fedwiki-link-resolution/evidence/hyperdoc-comparison.lisp" "evidence probe; defines its own package inside the file, so its later forms cannot be read without evaluating an earlier one")
    ("docs/lisp-critic-page-assets/evidence/discovery-probe.lisp" "evidence probe; same reason")
    ("scripts/record-fedwiki-link-resolution-critiques.lisp" "this recorder itself")))

(defun git (&rest arguments)
  (string-trim '(#\Newline #\Space)
               (uiop:run-program (list* "git" "-C" (namestring +root+) arguments) :output :string)))

(defun file-text (relative)
  (with-open-file (in (merge-pathnames relative +root+) :external-format :utf-8)
    (let ((text (make-string (file-length in))))
      (subseq text 0 (read-sequence text in)))))

(defun skip-blank (text position)
  "The start of the next form: past whitespace and ; comments."
  (loop while (< position (length text))
        do (let ((c (char text position)))
             (cond ((member c '(#\Space #\Tab #\Newline #\Return #\Page)) (incf position))
                   ((char= c #\;) (setf position (or (position #\Newline text :start position) (length text))))
                   (t (return)))))
  position)

(defun line-of (text position) (1+ (count #\Newline text :end position)))

(defun read-forms (text)
  "Every top-level form of TEXT as (FORM START END PACKAGE), read as data, following IN-PACKAGE."
  (let ((*read-eval* nil) (*package* (find-package '#:cl-user)) (position 0) (forms '()))
    (loop
      (setf position (skip-blank text position))
      (when (>= position (length text)) (return (nreverse forms)))
      (multiple-value-bind (form next) (read-from-string text t nil :start position)
        (push (list form position next *package*) forms)
        (when (and (consp form) (eq (first form) 'in-package))
          (setf *package* (find-package (second form))))
        (setf position next)))))

(defun form-key (form package)
  (let ((*package* package) (*print-pretty* nil))
    (if (and (consp form) (symbolp (first form)))
        (prin1-to-string (list (first form) (if (consp (rest form)) (second form) nil)))
        (prin1-to-string (type-of form)))))

(defun quoted-along-p (form path)
  "Whether QUOTE or a backquote encloses the subform PATH leads to."
  (let ((here form))
    (dolist (index path nil)
      (when (and (consp here) (member (first here) (list 'quote 'sb-int:quasiquote)))
        (return t))
      (setf here (nth index here)))))

(defun domain-notation-p (form)
  (and (consp form) (eq (first form) 'shop3:defdomain)))

(defun contract ()
  (make-instance 'critic:lisp-critic-contract
                 :id "pr-32-critique" :title "Every rule of the real Critic on each top-level form PR #32 adds"
                 :source-station (critic:make-critic-source-station)
                 :input-policy '(:form :not-evaluated) :invocation-policy '(:apply-one-rule)
                 :output-policy '(:structured-findings :raw-output-preserved)
                 :availability-policy '(:local-source-required)
                 :failure-policy '(:record-condition) :review-contract-role :critique))

(defun record-form (contract rules form package)
  "Apply every rule to FORM. Returns the counts and, for runs with findings or failures, their records."
  (let ((completed 0) (with-findings '()) (failed '()))
    (dolist (rule rules)
      (let* ((target (make-instance 'critic:critic-target :form (copy-tree form)))
             (record (critic:run-critic-rule contract rule target))
             (status (critic:lisp-critic-run-record-status record))
             (critiques (critic:critiques-of record)))
        (cond ((not (eq status :completed))
               (push (list (cons "rule" rule) (cons "run" (critic:critic-run-snapshot target))) failed))
              ((null critiques) (incf completed))
              (t
               (incf completed)
               (push (list (cons "rule" rule)
                           (cons "run" (critic:critic-run-snapshot target))
                           (cons "matches"
                                 (coerce
                                  (mapcar (lambda (critique)
                                            (let ((code (uiop:symbol-call :lisp-critic "CRITIQUE-CODE"
                                                                          (critic:critique-evidence-of critique))))
                                              (multiple-value-bind (path found) (rec::%path-to code form)
                                                (list (cons "matched" (let ((*package* package) (*print-pretty* nil)) (prin1-to-string code)))
                                                      (cons "path" (if found (coerce path 'vector) :null))
                                                      (cons "quoted" (if (and found (quoted-along-p form path)) t :false))
                                                      (cons "recommendation" (critic:critique-explanation-of critique))))))
                                          critiques)
                                  'vector)))
                     with-findings)))))
    (values completed (nreverse with-findings) (nreverse failed))))

(defun record-file (contract rules relative selection commit)
  (let* ((text (file-text relative))
         (blob (git "rev-parse" (format nil "~A:~A" commit relative)))
         (forms (read-forms text))
         (chosen (if (eq selection :all)
                     forms
                     (remove-if-not (lambda (entry)
                                      (let ((form (first entry)))
                                        (and (consp form) (symbolp (first form)) (string= "DEFSYSTEM" (symbol-name (first form)))
                                             (member (string (second form)) selection :test #'string=))))
                                    forms))))
    (list (cons "file" relative)
          (cons "commit" commit)
          (cons "git-blob" blob)
          (cons "file-sha256" (rec::%text-digest text))
          (cons "selection" (if (eq selection :all) "every top-level form" (format nil "the systems ~{~A~^, ~}" selection)))
          (cons "forms"
                (coerce
                 (loop for (form start end package) in chosen
                       collect (let* ((first-line (line-of text start)) (last-line (line-of text (1- end))))
                                 (multiple-value-bind (completed with-findings failed) (record-form contract rules form package)
                                   (format t "~&RECORD ~A ~A: ~D completed, ~D with findings, ~D failed~%"
                                           relative (form-key form package) completed (length with-findings) (length failed))
                                   (list (cons "index" (position start (mapcar #'second forms)))
                                         (cons "form-key" (form-key form package))
                                         (cons "package" (package-name package))
                                         (cons "range" (vector start end))
                                         (cons "lines" (vector first-line last-line))
                                         (cons "url" (format nil "https://github.com/RalfBarkow/hyperdoc/blob/~A/~A#L~D-L~D"
                                                             commit relative first-line last-line))
                                         (cons "text-sha256" (rec::%text-digest (subseq text start end)))
                                         (cons "shop3-domain-notation" (if (domain-notation-p form) t :false))
                                         (cons "runs" (list (cons "rules-applied" (length rules))
                                                            (cons "completed" completed)
                                                            (cons "completed-without-finding" (- completed (length with-findings)))
                                                            (cons "failed" (length failed))))
                                         (cons "findings" (coerce with-findings 'vector))
                                         (cons "failures" (coerce failed 'vector))))))
                 'vector)))))

(let* ((root (uiop:symbol-call :dreyeck/lisp-critic/engine-integration/tests :require-station))
       (commit (git "rev-parse" "HEAD"))
       (dirty (git "status" "--porcelain" "--" "dreyeck/work/fedwiki-link-resolution.lisp" "dreyeck/tests/fedwiki-link-resolution.lisp"
                   "scripts/test-fedwiki-link-resolution.lisp" "dreyeck.asd"))
       (contract (contract))
       (rules (progn (critic::%load-lisp-critic-source-station (critic:lisp-critic-contract-source-station-of contract))
                     (mapcar #'symbol-name (uiop:symbol-call :lisp-critic "GET-PATTERN-NAMES"))))
       (out (merge-pathnames "docs/fedwiki-link-resolution/critic/" +root+)))
  (unless (string= dirty "") (error "The target files differ from ~A; commit first so every link names what was judged." commit))
  (ensure-directories-exist out)
  (let ((files (loop for (relative selection) in +targets+ collect (record-file contract rules relative selection commit))))
    (with-open-file (stream (merge-pathnames "pr-32-critique.json" out) :direction :output :if-exists :supersede :external-format :utf-8)
      (let ((shasht:*write-alist-as-object* t) (shasht:*write-indent-string* " "))
        (shasht:write-json
         (list (cons "pr-critic-evaluation-version" 1)
               (cons "pull-request" +pull-request+)
               (cons "commit" commit)
               (cons "engine" (rec::%engine-identity))
               (cons "page-assets" (list (cons "page" "a-critic-for-lisp")
                                         (cons "asset-root-source" "DREYECK_LISP_CRITIC_ROOT")
                                         (cons "copied-from" "RalfBarkow/assets@856cf07da89c09cad311de82188f49d99a47a1c7:pages/a-critic-for-lisp/")))
               (cons "rules" (coerce rules 'vector))
               (cons "recording" (list (cons "context" "An authorized, isolated development runtime: own SBCL process, own network namespace without network, empty HOME, own FASL cache.")
                                       (cons "recorded-at" (get-universal-time))
                                       (cons "station-checked-by" "require-station")
                                       (cons "station" (namestring root))))
               (cons "not-critiqued" (coerce (mapcar (lambda (entry) (list (cons "file" (first entry)) (cons "why" (second entry)))) +not-critiqued+) 'vector))
               (cons "files" (coerce files 'vector)))
         stream))
      (terpri stream))
    (format t "~&PR-CRITIQUE-RECORDED: ~D files, ~D forms, ~D rules each, commit ~A~%"
            (length files) (reduce #'+ (mapcar (lambda (f) (length (cdr (assoc "forms" f :test #'string=)))) files)) (length rules) commit)))
