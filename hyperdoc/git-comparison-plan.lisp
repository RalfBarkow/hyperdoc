;;;; Git comparison plan object.
;;;; Created from SLY MREPL; reload this file instead of redefining ad hoc.

(in-package :hyperdoc)

(defclass git-comparison-plan ()
  ((title
    :reader git-comparison-plan-title-of
    :initarg :title
    :type string)
   (left-ref
    :reader git-comparison-plan-left-ref-of
    :initarg :left-ref
    :type string)
   (right-ref
    :reader git-comparison-plan-right-ref-of
    :initarg :right-ref
    :type string)
   (repository-root
    :reader git-comparison-plan-repository-root-of
    :initarg :repository-root
    :type pathname)
   (preflight
    :reader git-comparison-plan-preflight-of
    :initarg :preflight
    :initform nil))
  (:documentation
   "Inspectable plan for comparing Konrad upstream/main with hauptsache."))

(defmethod print-object ((plan git-comparison-plan) stream)
  (print-unreadable-object (plan stream :type t :identity nil)
    (format stream "~A ... ~A"
            (git-comparison-plan-left-ref-of plan)
            (git-comparison-plan-right-ref-of plan))))

(defun git-comparison-plan-comparison-command (plan)
  (format nil "git diff --name-status ~A...~A"
          (git-comparison-plan-left-ref-of plan)
          (git-comparison-plan-right-ref-of plan)))

(defun git-comparison-plan-current-stage (plan)
  (declare (ignore plan))
  "We have a Git ref preflight object and views. The next durable object should be the tree/path comparison.")

(defun git-comparison-plan-done-lines (plan)
  (declare (ignore plan))
  '("Created source-backed git-repository-checkout object."
    "Created source-backed git-commit object and commit inspector views."
    "Made commit changed-file entries inspectable as file objects."
    "Created git-ref-preflight object for upstream/main versus HEAD."
    "Created preflight inspector views, but their operator story needs simplification."))

(defun git-comparison-plan-now-lines (plan)
  (list
   "Use this plan object as the orientation surface."
   "Keep the preflight object as evidence, not as the main navigation surface."
   (format nil "The comparison basis is: ~A"
           (git-comparison-plan-comparison-command plan))
   "The next implementation object is git-tree-comparison."))

(defun git-comparison-plan-next-lines (plan)
  (declare (ignore plan))
  '("Create git-tree-comparison as a source-backed object."
    "Parse git diff --name-status upstream/main...HEAD into inspectable path-delta objects."
    "Give git-tree-comparison views: Overview, Upstream-only, Hauptsache-only, Overlapping paths."
    "Make every path row clickable."
    "Only after that, classify individual paths and decide merge actions."))

(defun git-comparison-plan-not-yet-lines (plan)
  (declare (ignore plan))
  '("Do not merge upstream/main yet."
    "Do not decide file-level merge policy from the preflight object."
    "Do not use Repomix as the primary comparison substrate."
    "Do not add more raw Git probe tabs unless they answer an operator question."))

(defun current-git-comparison-plan ()
  "Return the current plan for comparing upstream/main with hauptsache/HEAD."
  (let* ((root (current-repository-root-pathname))
         (preflight
           (when (fboundp 'upstream-main-vs-hauptsache-preflight)
             (upstream-main-vs-hauptsache-preflight))))
    (make-instance 'git-comparison-plan
                   :title "Compare Konrad upstream/main with hauptsache"
                   :left-ref "upstream/main"
                   :right-ref "HEAD"
                   :repository-root root
                   :preflight preflight)))
