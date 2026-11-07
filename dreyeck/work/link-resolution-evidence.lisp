;;;; Domain evaluations use the existing Evaluation Record protocol; no Critic rule runs here.
(defpackage #:dreyeck/work/link-resolution/evidence
  (:use #:cl)
  (:local-nicknames (#:m #:dreyeck/work/link-resolution) (#:h #:dreyeck/shop3)
                    (#:er #:dreyeck/evaluation-record) (#:v #:html-inspector-views))
  (:export #:evaluate-fixture #:study #:*link-resolution-book* #:context-of))
(in-package #:dreyeck/work/link-resolution/evidence)
(defclass resolution-evaluation ()
  ((context :initform nil :accessor context-of)
   (reference :initarg :reference :reader reference-of)
   (methods :initarg :methods :reader methods-of)
   (status :initform :running :accessor status-of)
   (result :initform nil :accessor result-of)
   (failure :initform nil :accessor failure-of)
   (started :initform (get-universal-time) :reader started-of)
   (finished :initform nil :accessor finished-of)
   (identity :initform (symbol-name (gensym "RESOLUTION-EVALUATION-")) :reader identity-of)))
(defvar *reference-evidence* nil)
(defun reference-evidence ()
  (or *reference-evidence*
      (setf *reference-evidence*
            (with-open-file (in (asdf:system-relative-pathname "dreyeck/work/link-resolution"
                                 "docs/fedwiki-java-link-resolution-evidence/java.json"))
              (shasht:read-json in)))))
(defun evaluate-fixture (&optional (id "context-order") (policy :collaborative))
  "Actually run SHOP3 and evaluate its selected site. Java evidence is recorded,
not rerun by the Inspector. This is a model comparison, never an Engine Critique."
  (let ((record (make-instance 'resolution-evaluation :reference (reference-evidence)
                  :methods (shop3:methods 'm::fedwiki-ordered-resolution 'm::search-sites))))
    (handler-case
        (let* ((context (m:resolution-experiment id policy)) (case (getf context :fixture))
               (result (getf context :result))
               (expected (m::site-key (gethash "expectedSite" case)))
               (expected (if (eq policy :local-only) (and (eq expected :origin) :origin) expected))
               (actual (mapcar #'first (first (m:fixture-outcomes result)))))
          (setf (context-of record) context (status-of record) :completed
                (result-of record) (list :matches-expected
                                       (if expected (equal (make-list (or (gethash "repeat" case) 1)
                                                                    :initial-element expected) actual)
                                           (null (h:raw-plans-of result)))
                                       :expected-site expected :actual-sites actual)))
      (error (condition) (setf (status-of record) :failed (failure-of record) (princ-to-string condition))))
    (setf (finished-of record) (get-universal-time)) record))
(defmethod er:evaluation-specification-of ((r resolution-evaluation))
  (list :kind :model-comparison :policy (getf (context-of r) :policy) :not-a-critic-rule t))
(defmethod er:evaluation-input-of ((r resolution-evaluation)) (getf (context-of r) :initial-state))
(defmethod er:evaluation-status-of ((r resolution-evaluation)) (status-of r))
(defmethod er:evaluation-result-of ((r resolution-evaluation)) (result-of r))
(defmethod er:evaluation-trace-of ((r resolution-evaluation))
  (let ((plan (getf (context-of r) :result))) (and plan (h:plan-trees-of plan))))
(defmethod er:evaluation-evidence-of ((r resolution-evaluation))
  (list :java-reference (reference-of r) :java-mode :recorded-offline-probe
        :java-case-observation
        (let ((fixture (getf (context-of r) :fixture)))
          (and fixture (find (gethash "id" fixture)
                             (gethash "cases" (reference-of r)) :test #'equal
                             :key (lambda (case) (gethash "id" case)))))
        :comparison-mode (if (eq :local-only (getf (context-of r) :policy))
                             :counterfactual-local-policy :source-derived-collaborative-search)
        :shop3-methods (methods-of r) :context (context-of r)
        :live-lisp-critic :not-invoked :authentic-station :not-verified
        :cloud-engine-status :engine-unavailable :new-engine-critiques nil))
(defmethod er:evaluation-failure-of ((r resolution-evaluation)) (failure-of r))
(defmethod er:evaluation-started-at-of ((r resolution-evaluation)) (started-of r))
(defmethod er:evaluation-finished-at-of ((r resolution-evaluation)) (finished-of r))
(defmethod er:evaluation-identity-of ((r resolution-evaluation)) (identity-of r))
(defmethod er:evaluation-annotation-of ((r resolution-evaluation))
  (declare (ignore r)) '(:wiki-execution :not-executed :critic-engine :not-invoked))
(v:defview evaluation-view (r resolution-evaluation)
  (v:html-view :title "Resolution evaluation" :priority 0
    (v:html
      (:p "Executed model comparison; not a Lisp Critic rule or Critique.")
      (:p (v:esc (format nil "Status ~S; result ~S" (status-of r) (result-of r))))
      (:table
        (:tr (:td "Java source / recorded observations") (:td (v:object-ref (reference-of r))))
        (:tr (:td "Derived SHOP3 method definitions") (:td (v:object-ref (methods-of r))))
        (:tr (:td "Probe context") (:td (v:object-ref (context-of r))))
        (:tr (:td "Actual hyperdoc-htn-plan-result")
             (:td (v:object-ref (getf (context-of r) :result)))))
      (:p "No Wiki action executed. No live Critic invoked; the Cloud study has no verified historical station."))))
(defvar *study* nil)
(defun study ()
  "Stable Inspector objects after actual first evaluation; no HTTP or real fork."
  (or *study* (setf *study*
                   (loop for case in (m:fixture-cases)
                         append (loop for policy in '(:collaborative :local-only)
                                      collect (evaluate-fixture (gethash "id" case) policy))))))
(hyperdoc:defhyperdoc *link-resolution-book*
  :id "dreyeck/work/link-resolution" :title "Learning Federated Wiki Link Resolution"
  :asdf-system-name "dreyeck/work/link-resolution/reading"
  :subdirectory "dreyeck/pages/link-resolution"
  :main-page-id "Learning Federated Wiki Link Resolution")
