;;;; Tests for the read-only reading of the recorded PR #32 critique. They run no engine.

(defpackage #:dreyeck/work/fedwiki-link-resolution/critic/tests
  (:use #:cl)
  (:local-nicknames (#:c #:dreyeck/work/fedwiki-link-resolution/critic) (#:critic #:dreyeck/lisp-critic))
  (:export #:run-tests))
(in-package #:dreyeck/work/fedwiki-link-resolution/critic/tests)

(defun %stored-engine-digests ()
  "The engine digests the repository's stored evaluation records."
  (let ((data (with-open-file (in (asdf:system-relative-pathname "dreyeck/work/fedwiki-link-resolution/critic"
                                                                 "dreyeck/pages/lisp-critic/evaluations/setf-push-reading-plan.json")
                                  :external-format :utf-8)
                (shasht:read-json in))))
    (sort (map 'list (lambda (f) (cons (gethash "file" f) (gethash "sha256" f))) (gethash "files" (gethash "engine" data)))
          #'string< :key #'car)))

(defun run-tests ()
  (let* ((review (c:read-pr-critique-review))
         (forms (c:review-forms-of review))
         (findings (c:review-findings-of review))
         (rules (length (c:review-rules-of review))))
    ;; Reading ran nothing: neither the engine nor the page-attached system is in this image because of it.
    (assert (not (find-package "LISP-CRITIC")) () "the engine package exists; reading must not load the engine")
    (assert (not (find-package "A-CRITIC-FOR-LISP")))
    ;; The engine that ran is the one the stored evaluations were made with.
    (assert (equal (%stored-engine-digests)
                   (sort (map 'list (lambda (f) (cons (gethash "file" f) (gethash "sha256" f)))
                              (gethash "files" (c:review-engine-of review)))
                         #'string< :key #'car))
            () "the recorded engine digests differ from the stored evaluation's")
    ;; Every rule was applied to every form, and each run is accounted for.
    (assert (= 78 rules))
    (assert (= 70 (length forms)))
    (dolist (form forms)
      (let ((with (length (c:form-findings-of form))))
        (assert (= rules (dreyeck/work/fedwiki-link-resolution/critic::form-rules-applied-of form)))
        (assert (= rules (+ (dreyeck/work/fedwiki-link-resolution/critic::form-without-finding-of form) with
                            (length (dreyeck/work/fedwiki-link-resolution/critic::form-failed-of form)))))
        ;; The form judged is the form this checkout has, and the link names commit and lines.
        (assert (c:form-current-p form) () "~A ~A changed since it was judged" (c:form-file-of form) (c:form-key-of form))
        (assert (search (dreyeck/work/fedwiki-link-resolution/critic::form-commit-of form) (c:form-url-of form)))
        (assert (search (format nil "#L~D-L~D" (first (dreyeck/work/fedwiki-link-resolution/critic::form-lines-of form))
                                (second (dreyeck/work/fedwiki-link-resolution/critic::form-lines-of form)))
                        (c:form-url-of form)))))
    ;; Each finding is a reconstituted Evaluation Record with the engine's own Critiques and its match evidence.
    (dolist (finding findings)
      (let* ((target (c:finding-target-of finding))
             (record (first (critic:target-runs-of target))))
        (assert (string-equal "COMPLETED" (string (critic:lisp-critic-run-record-status record))))
        (assert (plusp (length (critic:critiques-of record))))
        (assert (= (length (critic:critiques-of record)) (length (c:finding-matches-of finding))))
        (dolist (m (c:finding-matches-of finding))
          (assert (plusp (length (gethash "recommendation" m))))
          (assert (gethash "matched" m)))))
    (assert (= 30 (count-if #'c:form-findings-of forms)))
    (assert (= 47 (reduce #'+ (mapcar (lambda (f) (length (c:finding-matches-of f))) findings))))
    ;; Judgements are Claude's, refer to real findings, and are not Critiques.
    (let ((judgements (c:review-judgements-of review)))
      (assert judgements)
      (dolist (j judgements)
        (assert (string= "Claude" (dreyeck/work/fedwiki-link-resolution/critic::judgement-author-of j)))
        (assert (dreyeck/work/fedwiki-link-resolution/critic::judgement-findings-of j) ()
                "judgement ~A names a rule without a finding" (dreyeck/work/fedwiki-link-resolution/critic::judgement-id-of j))
        (assert (not (typep j 'critic:critique))))
      (assert (every (lambda (finding) (find (c:finding-rule-of finding) judgements
                                             :key #'dreyeck/work/fedwiki-link-resolution/critic::judgement-rule-of :test #'string=))
                     findings)
              () "a finding's rule has no judgement"))
    ;; The Inspector path: review → finding → reconstituted Evaluation Record → Critique, with the existing views.
    (flet ((render (object)
             (let ((views (remove-if-not (lambda (v) (typep v 'html-inspector-views:html-view)) (html-inspector-views:all-views object))))
               (assert views () "~S has no HTML view" (type-of object))
               (mapcar #'html-inspector-views:view-html views))))
      (let ((html (apply #'concatenate 'string (render review))))
        (assert (search "Judgements (Claude, not engine output)" html))
        (dolist (finding findings) (assert (search (c:finding-rule-of finding) html))))
      (dolist (finding findings)
        (let ((html (apply #'concatenate 'string (render finding))))
          (assert (search (c:form-url-of (c:finding-form-of finding)) html)))
        (let* ((target (c:finding-target-of finding))
               (record (first (critic:target-runs-of target))))
          (render target) (render record)
          (dolist (critique (critic:critiques-of record)) (render critique)))))
    (format t "~&FEDWIKI-LINK-RESOLUTION-CRITIC-PASS: ~D forms judged by all ~D rules of the real engine (digests as stored); ~D runs with findings (~D matches), the rest completed without one; every form unchanged here; every Evaluation Record reconstituted; ~D judgements kept apart; no engine loaded by reading.~%"
            (length forms) rules (length findings)
            (reduce #'+ (mapcar (lambda (f) (length (c:finding-matches-of f))) findings))
            (length (c:review-judgements-of review))))
  t)
