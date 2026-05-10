;;;; Git ref preflight interpretation objects.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc)

(defclass git-probe-result ()
  ((args
    :reader git-probe-result-args-of
    :initarg :args
    :type list)
   (ok?
    :reader git-probe-result-ok-p
    :initarg :ok?
    :type boolean)
   (value
    :reader git-probe-result-value-of
    :initarg :value
    :initform nil)
   (stdout
    :reader git-probe-result-stdout-of
    :initarg :stdout
    :type string)
   (stderr
    :reader git-probe-result-stderr-of
    :initarg :stderr
    :type string)
   (exit-code
    :reader git-probe-result-exit-code-of
    :initarg :exit-code
    :type integer))
  (:documentation
   "One read-only Git command result captured as an inspectable value."))

(defmethod print-object ((result git-probe-result) stream)
  (print-unreadable-object (result stream :type t :identity nil)
    (format stream "~:[FAILED~;OK~] git ~{~A~^ ~}"
            (git-probe-result-ok-p result)
            (git-probe-result-args-of result))))

(defun git-trim-output (string)
  (string-trim '(#\Space #\Tab #\Newline #\Return) string))

(defun git-probe (repository-root &rest args)
  "Run a read-only Git probe and return a GIT-PROBE-RESULT.

This function does not signal on non-zero exit; failures are inspector values."
  (multiple-value-bind (stdout stderr exit-code)
      (uiop:run-program
       (cons "git" args)
       :directory repository-root
       :output :string
       :error-output :string
       :ignore-error-status t)
    (make-instance 'git-probe-result
                   :args args
                   :ok? (zerop exit-code)
                   :value (and (zerop exit-code)
                               (git-trim-output stdout))
                   :stdout stdout
                   :stderr stderr
                   :exit-code exit-code)))

(defclass git-preflight-problem ()
  ((severity
    :reader git-preflight-problem-severity-of
    :initarg :severity)
   (message
    :reader git-preflight-problem-message-of
    :initarg :message
    :type string)
   (probe
    :reader git-preflight-problem-probe-of
    :initarg :probe
    :initform nil))
  (:documentation
   "One interpreted readiness issue in a Git ref preflight."))

(defmethod print-object ((problem git-preflight-problem) stream)
  (print-unreadable-object (problem stream :type t :identity nil)
    (format stream "~A: ~A"
            (git-preflight-problem-severity-of problem)
            (git-preflight-problem-message-of problem))))

(defun make-git-preflight-problem (severity message &optional probe)
  (make-instance 'git-preflight-problem
                 :severity severity
                 :message message
                 :probe probe))

(defclass git-ref-preflight ()
  ((repository-root
    :reader git-ref-preflight-repository-root-of
    :initarg :repository-root
    :type pathname)
   (left-ref
    :reader git-ref-preflight-left-ref-of
    :initarg :left-ref
    :type string)
   (right-ref
    :reader git-ref-preflight-right-ref-of
    :initarg :right-ref
    :type string)
   (status
    :reader git-ref-preflight-status-of
    :initarg :status)
   (current-branch
    :reader git-ref-preflight-current-branch-of
    :initarg :current-branch)
   (head
    :reader git-ref-preflight-head-of
    :initarg :head)
   (left
    :reader git-ref-preflight-left-of
    :initarg :left)
   (right
    :reader git-ref-preflight-right-of
    :initarg :right)
   (hauptsache
    :reader git-ref-preflight-hauptsache-of
    :initarg :hauptsache)
   (merge-base
    :reader git-ref-preflight-merge-base-of
    :initarg :merge-base)
   (merge-base-short
    :reader git-ref-preflight-merge-base-short-of
    :initarg :merge-base-short))
  (:documentation
   "Read-only preflight interpretation for comparing two Git refs."))

(defmethod print-object ((preflight git-ref-preflight) stream)
  (print-unreadable-object (preflight stream :type t :identity nil)
    (format stream "~A ... ~A in ~A"
            (git-ref-preflight-left-ref-of preflight)
            (git-ref-preflight-right-ref-of preflight)
            (git-ref-preflight-repository-root-of preflight))))

(defun git-probe-ok-value (probe)
  (and probe
       (git-probe-result-ok-p probe)
       (git-probe-result-value-of probe)))

(defun git-ref-preflight-probes (preflight)
  (list (git-ref-preflight-status-of preflight)
        (git-ref-preflight-current-branch-of preflight)
        (git-ref-preflight-head-of preflight)
        (git-ref-preflight-left-of preflight)
        (git-ref-preflight-right-of preflight)
        (git-ref-preflight-hauptsache-of preflight)
        (git-ref-preflight-merge-base-of preflight)
        (git-ref-preflight-merge-base-short-of preflight)))

(defun make-git-ref-preflight (&key repository-root
                                      (left-ref "upstream/main")
                                      (right-ref "HEAD"))
  "Return a read-only preflight object for LEFT-REF and RIGHT-REF."
  (let* ((root repository-root)
         (status
           (git-probe root "status" "--short" "--branch"))
         (current-branch
           (git-probe root "branch" "--show-current"))
         (head
           (git-probe root "rev-parse" "--short" "HEAD"))
         (left
           (git-probe root "rev-parse" "--verify" "--short" left-ref))
         (right
           (git-probe root "rev-parse" "--verify" "--short" right-ref))
         (hauptsache
           (git-probe root "rev-parse" "--verify" "--short" "hauptsache"))
         (merge-base
           (git-probe root "merge-base" left-ref right-ref))
         (merge-base-short
           (if (git-probe-result-ok-p merge-base)
               (git-probe root "rev-parse" "--short"
                          (git-probe-result-value-of merge-base))
               (make-instance 'git-probe-result
                              :args (list "rev-parse" "--short" "<merge-base>")
                              :ok? nil
                              :value nil
                              :stdout ""
                              :stderr "Skipped because merge-base failed."
                              :exit-code 1))))
    (make-instance 'git-ref-preflight
                   :repository-root root
                   :left-ref left-ref
                   :right-ref right-ref
                   :status status
                   :current-branch current-branch
                   :head head
                   :left left
                   :right right
                   :hauptsache hauptsache
                   :merge-base merge-base
                   :merge-base-short merge-base-short)))

(defun current-repository-root-pathname ()
  (pathname
   (concatenate
    'string
    (git-trim-output
     (uiop:run-program
      '("git" "rev-parse" "--show-toplevel")
      :directory *default-pathname-defaults*
      :output :string
      :error-output :string))
    "/")))

(defun upstream-main-vs-hauptsache-preflight ()
  "Preflight the live comparison upstream/main versus current HEAD/hauptsache."
  (make-git-ref-preflight
   :repository-root (current-repository-root-pathname)
   :left-ref "upstream/main"
   :right-ref "HEAD"))

(defun git-ref-preflight-problems (preflight)
  (let ((problems nil))
    (labels ((require-ok (probe message)
               (unless (git-probe-result-ok-p probe)
                 (push (make-git-preflight-problem :error message probe)
                       problems))))
      (require-ok (git-ref-preflight-head-of preflight)
                  "HEAD does not resolve.")
      (require-ok (git-ref-preflight-left-of preflight)
                  "upstream/main does not resolve. Fetch upstream/main first.")
      (require-ok (git-ref-preflight-right-of preflight)
                  "The right ref does not resolve.")
      (require-ok (git-ref-preflight-merge-base-of preflight)
                  "No merge base could be computed for upstream/main and HEAD.")
      (let ((branch (git-probe-ok-value
                     (git-ref-preflight-current-branch-of preflight))))
        (cond
          ((null branch)
           (push (make-git-preflight-problem
                  :warning
                  "Current branch name is unavailable, possibly detached HEAD."
                  (git-ref-preflight-current-branch-of preflight))
                 problems))
          ((not (string= branch "hauptsache"))
           (push (make-git-preflight-problem
                  :warning
                  (format nil "Current branch is ~A, not hauptsache." branch)
                  (git-ref-preflight-current-branch-of preflight))
                 problems)))))
    (nreverse problems)))

(defun git-ref-preflight-ready-p (preflight)
  (notany (lambda (problem)
            (eq (git-preflight-problem-severity-of problem) :error))
          (git-ref-preflight-problems preflight)))

(defun git-ref-preflight-summary-line (preflight)
  (if (git-ref-preflight-ready-p preflight)
      "Ready: upstream/main, HEAD, and merge base all resolve."
      "Blocked: at least one required Git ref or merge base is unavailable."))

(defun git-ref-preflight-next-action-lines (preflight)
  (if (git-ref-preflight-ready-p preflight)
      '("Open or build the merge-forecast object."
        "Inspect upstream-only, hauptsache-only, and overlapping paths."
        "Promote path rows into inspectable path-delta objects where needed.")
      '("Resolve all :error preflight problems first."
        "Most commonly: git fetch upstream main, or switch to hauptsache."
        "Rerun upstream-main-vs-hauptsache-preflight after repairing refs.")))
