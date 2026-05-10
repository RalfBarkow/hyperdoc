;;;; Git history map objects.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc)

(defparameter *git-history-map-max-commits-per-side* 80)

(defclass git-history-commit ()
  ((repository-root
    :reader git-history-commit-repository-root-of
    :initarg :repository-root
    :type pathname)
   (hash
    :reader git-history-commit-hash-of
    :initarg :hash
    :type string)
   (side
    :reader git-history-commit-side-of
    :initarg :side)
   (date
    :reader git-history-commit-date-of
    :initarg :date
    :type string)
   (subject
    :reader git-history-commit-subject-of
    :initarg :subject
    :type string)
   (paths-cache
    :accessor git-history-commit-paths-cache-of
    :initarg :paths-cache
    :initform :unknown))
  (:documentation
   "One commit in a left/right Git history comparison. Touched paths are loaded lazily."))

(defmethod print-object ((commit git-history-commit) stream)
  (print-unreadable-object (commit stream :type t :identity nil)
    (format stream "~A ~A"
            (git-history-commit-short-hash commit)
            (git-history-commit-subject-of commit))))

(defclass git-history-map ()
  ((repository-root
    :reader git-history-map-repository-root-of
    :initarg :repository-root
    :type pathname)
   (left-ref
    :reader git-history-map-left-ref-of
    :initarg :left-ref
    :type string)
   (right-ref
    :reader git-history-map-right-ref-of
    :initarg :right-ref
    :type string)
   (merge-base
    :reader git-history-map-merge-base-of
    :initarg :merge-base
    :type string)
   (left-count
    :reader git-history-map-left-count-of
    :initarg :left-count
    :type integer)
   (right-count
    :reader git-history-map-right-count-of
    :initarg :right-count
    :type integer)
   (left-commits
    :reader git-history-map-left-commits-of
    :initarg :left-commits
    :type list)
   (right-commits
    :reader git-history-map-right-commits-of
    :initarg :right-commits
    :type list))
  (:documentation
   "Fast, inspectable map of upstream/main history against hauptsache history."))

(defmethod print-object ((history-map git-history-map) stream)
  (print-unreadable-object (history-map stream :type t :identity nil)
    (format stream "~A ... ~A"
            (git-history-map-left-ref-of history-map)
            (git-history-map-right-ref-of history-map))))

(defun git-history-trim (string)
  (string-trim '(#\Space #\Tab #\Newline #\Return) string))

(defun git-history-current-repository-root-pathname ()
  (pathname
   (concatenate
    'string
    (git-history-trim
     (uiop:run-program
      '("git" "rev-parse" "--show-toplevel")
      :directory *default-pathname-defaults*
      :output :string
      :error-output :string))
    "/")))

(defun git-history-run (repository-root &rest args)
  (multiple-value-bind (stdout stderr code)
      (uiop:run-program
       (cons "git" args)
       :directory repository-root
       :output :string
       :error-output :string
       :ignore-error-status t)
    (unless (zerop code)
      (error "git ~{~A~^ ~} failed with code ~D~%~A"
             args code stderr))
    stdout))

(defun git-history-run-lines (repository-root &rest args)
  (remove ""
          (uiop:split-string
           (apply #'git-history-run repository-root args)
           :separator '(#\Newline))
          :test #'string=))

(defun git-history-short-hash (hash)
  (subseq hash 0 (min 12 (length hash))))

(defun git-history-commit-short-hash (commit)
  (git-history-short-hash
   (git-history-commit-hash-of commit)))

(defun git-history-merge-base (repository-root left-ref right-ref)
  (git-history-trim
   (git-history-run repository-root "merge-base" left-ref right-ref)))

(defun git-history-side-option (side)
  (ecase side
    (:upstream "--left-only")
    (:hauptsache "--right-only")))

(defun git-history-side-commit-count (repository-root side left-ref right-ref)
  (parse-integer
   (git-history-trim
    (git-history-run repository-root
                     "rev-list" "--count"
                     (git-history-side-option side)
                     "--cherry-pick"
                     (format nil "~A...~A" left-ref right-ref)))))

(defun git-history-parse-log-line (repository-root side line)
  (let* ((parts (uiop:split-string line :separator '(#\Tab)))
         (hash (or (first parts) ""))
         (date (or (second parts) ""))
         (subject (or (third parts) "")))
    (make-instance 'git-history-commit
                   :repository-root repository-root
                   :hash hash
                   :side side
                   :date date
                   :subject subject)))

(defun git-history-side-commits (repository-root side left-ref right-ref)
  (mapcar
   (lambda (line)
     (git-history-parse-log-line repository-root side line))
   (git-history-run-lines
    repository-root
    "log"
    (git-history-side-option side)
    "--cherry-pick"
    (format nil "--max-count=~D" *git-history-map-max-commits-per-side*)
    "--format=%H%x09%ad%x09%s"
    "--date=short"
    (format nil "~A...~A" left-ref right-ref))))

(defun make-git-history-map (&key repository-root
                                   (left-ref "upstream/main")
                                   (right-ref "HEAD"))
  (let* ((merge-base
           (git-history-merge-base repository-root left-ref right-ref))
         (left-count
           (git-history-side-commit-count repository-root :upstream left-ref right-ref))
         (right-count
           (git-history-side-commit-count repository-root :hauptsache left-ref right-ref)))
    (make-instance 'git-history-map
                   :repository-root repository-root
                   :left-ref left-ref
                   :right-ref right-ref
                   :merge-base merge-base
                   :left-count left-count
                   :right-count right-count
                   :left-commits
                   (git-history-side-commits
                    repository-root :upstream left-ref right-ref)
                   :right-commits
                   (git-history-side-commits
                    repository-root :hauptsache left-ref right-ref))))

(defun current-git-history-map ()
  "Map Konrad upstream/main history against the current hauptsache/HEAD history."
  (make-git-history-map
   :repository-root (git-history-current-repository-root-pathname)
   :left-ref "upstream/main"
   :right-ref "HEAD"))

(defun git-history-map-truncated-p (history-map)
  (or (> (git-history-map-left-count-of history-map)
         (length (git-history-map-left-commits-of history-map)))
      (> (git-history-map-right-count-of history-map)
         (length (git-history-map-right-commits-of history-map)))))

(defun git-history-commit-paths (commit)
  "Return paths touched by COMMIT, loading them lazily."
  (if (eq (git-history-commit-paths-cache-of commit) :unknown)
      (setf (git-history-commit-paths-cache-of commit)
            (mapcar
             (lambda (line)
               (let ((parts (uiop:split-string line :separator '(#\Tab))))
                 (or (second parts)
                     (first parts)
                     line)))
             (git-history-run-lines
              (git-history-commit-repository-root-of commit)
              "diff-tree" "--no-commit-id" "--name-status" "-r"
              (git-history-commit-hash-of commit))))
      (git-history-commit-paths-cache-of commit)))
