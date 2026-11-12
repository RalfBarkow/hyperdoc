;;;; Tests of the text criticism against what it reuses: the judgement-basis
;;;; resolver of the federated context, unchanged, and the claim table the
;;;; reading system has loaded. They need a complete HyperDoc.
;;;;
;;;; The resolver reads :ID, :STATE and :TARGETS on observations and :BASIS
;;;; and :TARGETS on a judgement. These tests show that the records of the
;;;; text criticism are in that form, and that the resolver still refuses a
;;;; judgement that has drifted from its evidence.

(defpackage #:dreyeck/lisp-critic/text-criticism/integration-tests
  (:use #:cl)
  (:local-nicknames (#:criticism #:dreyeck/lisp-critic/text-criticism)
                    (#:fc #:dreyeck/lisp-critic/federated-context)
                    (#:reading #:dreyeck/lisp-critic/reading))
  (:export #:run-tests))

(in-package #:dreyeck/lisp-critic/text-criticism/integration-tests)

(defvar *checks* 0)

(defun check (value control &rest arguments)
  (incf *checks*)
  (unless value (error (apply #'format nil control arguments)))
  value)

(defun refuses-p (judgement observations)
  (handler-case (progn (fc:resolve-judgement-basis judgement observations) nil)
    (error () t)))

(defun check-basis-resolution ()
  (let ((judgement (criticism:judgement)) (observations (criticism:recorded-observations)))
    ;; positive: the basis resolves, to exactly the two recorded observations
    (let ((resolved (fc:resolve-judgement-basis judgement observations)))
      (check (equal '(:passage :claims) (mapcar (lambda (observation) (getf observation :id)) resolved))
             "The basis resolved to ~S." (mapcar (lambda (observation) (getf observation :id)) resolved))
      (check (every (lambda (observation) (eq :observed (getf observation :evidence-status))) resolved)
             "A resolved observation is not :OBSERVED."))
    ;; negative: an observation that was not recorded
    (let ((drifted (copy-tree judgement)))
      (setf (getf drifted :basis) (list (list :state criticism:+state+ :observation :papers-read)))
      (check (refuses-p drifted observations) "A basis naming an unrecorded observation resolved."))
    ;; negative: the right observation at another state
    (let ((drifted (copy-tree judgement)))
      (setf (getf drifted :basis)
            (list (list :state "0123456789abcdef0123456789abcdef01234567" :observation :passage)))
      (check (refuses-p drifted observations) "A basis naming another state resolved."))
    ;; negative: a target none of the basis observations observed
    (let ((drifted (copy-tree judgement)))
      (setf (getf drifted :targets) (append (getf drifted :targets) (list "another page")))
      (check (refuses-p drifted observations) "A judgement naming an unobserved target resolved."))
    ;; negative: the federated context's own observations do not carry this judgement
    (check (refuses-p judgement (fc:prior-observations))
           "The judgement resolved against observations of another criticism.")
    ;; and the resolver is the committed one, not a replacement defined here
    (check (eq (symbol-package 'fc:resolve-judgement-basis)
               (find-package "DREYECK/LISP-CRITIC/FEDERATED-CONTEXT"))
           "The resolver is not the federated context's.")))

(defun check-image-agreement ()
  "The table read from the source text is the table this image has loaded."
  (let ((agreement (criticism:image-agreement)))
    (check (eq :image-agrees-with-source (getf agreement :status)) "Image agreement is ~S." (getf agreement :status)))
  (check (= 10 (count :primary-paper (reading:historical-claims)
                      :key (lambda (claim) (getf claim :cited-source-kind))))
         "The loaded table does not hold ten claims citing a primary paper."))

(defun run-tests ()
  (let ((*checks* 0))
    (check-basis-resolution)
    (check-image-agreement)
    (format t "~&TEXT-CRITICISM-INTEGRATION-PASS: ~D checks. The judgement's basis resolves with the federated context's resolver and is refused when it drifts; the loaded claim table is the one the source declares.~%"
            *checks*)
    t))
