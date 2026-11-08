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

;;; The Judgement view, and what must not have changed around it.

(defun %html-views (object)
  (remove-if-not (lambda (v) (typep v 'html-inspector-views:html-view)) (html-inspector-views:all-views object)))

(defun %normalized (html)
  "HTML with what differs between images taken out: the running numbers of reference ids (inspect-N, eval-N, action-N)
and the memory addresses printed in unreadable objects ({10071C5E23}). A digest then depends on the views alone."
  (with-output-to-string (out)
    (loop with i = 0 while (< i (length html))
          do (let ((hit (loop for prefix in '("inspect-" "eval-" "action-")
                              when (and (<= (+ i (length prefix)) (length html))
                                        (string= prefix html :start2 i :end2 (+ i (length prefix))))
                                return prefix))
                   (address-end (and (char= #\{ (char html i))
                                     (let ((close (position #\} html :start i)))
                                       (and close (> close (1+ i))
                                            (every (lambda (ch) (digit-char-p ch 16)) (subseq html (1+ i) close))
                                            close)))))
               (cond (hit (write-string hit out) (write-char #\N out) (incf i (length hit))
                          (loop while (and (< i (length html)) (digit-char-p (char html i))) do (incf i)))
                     (address-end (write-string "{ADDRESS}" out) (setf i (1+ address-end)))
                     (t (write-char (char html i) out) (incf i)))))))

(defun %views-digest (object)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence
    :sha256 (sb-ext:string-to-octets
             (%normalized (apply #'concatenate 'string (mapcar #'html-inspector-views:view-html (%html-views object))))
             :external-format :utf-8))))

(defun check-judgement-view (review)
  "The specialized Judgement view is registered and renders; J-USE-EQL shows its verdict, its evidence and its 21
findings as object references made by the Inspector's own OBJECT-REF, and they are the review's finding objects."
  (let* ((judgement (find "J-USE-EQL" (c:review-judgements-of review)
                          :key #'dreyeck/work/fedwiki-link-resolution/critic::judgement-id-of :test #'string=))
         (view (find "Judgement" (html-inspector-views:all-views judgement) :key #'html-inspector-views:view-title :test #'equal))
         (html (and view (html-inspector-views:view-html view)))
         (findings (dreyeck/work/fedwiki-link-resolution/critic::judgement-findings-of judgement))
         (referenced (and view (remove-if-not (lambda (r) (typep (cdr r) 'c:pr-critique-finding))
                                                (html-inspector-views:view-references view)))))
    (assert view () "no Judgement view is registered for PR-JUDGEMENT")
    (assert (typep view 'html-inspector-views:html-view))
    (dolist (text '("J-USE-EQL" "Claude" "USE-EQL" "disputed" "compares site-name strings"))
      (assert (search text html) () "the Judgement view does not show ~S" text))
    (assert (= 21 (length findings)))
    (assert (every (lambda (f) (member f (c:review-findings-of review) :test #'eq)) findings)
            () "a judgement's finding is not the review's finding object")
    (assert (= 21 (length referenced)) () "~D finding references instead of 21" (length referenced))
    (assert (null (set-difference (mapcar #'cdr referenced) findings :test #'eq)))
    (assert (null (set-difference findings (mapcar #'cdr referenced) :test #'eq)))
    (assert (every (lambda (r) (uiop:string-prefix-p "inspect-" (car r))) referenced)
            () "a finding reference was not made by OBJECT-REF")
    ;; Every judgement renders, and one without findings, made from the same class, too.
    (dolist (j (c:review-judgements-of review))
      (assert (html-inspector-views:view-html
               (find "Judgement" (html-inspector-views:all-views j) :key #'html-inspector-views:view-title :test #'equal))))
    (let* ((empty (make-instance 'c:pr-judgement :id "J-NO-FINDING" :author "Claude" :rule "NO-SUCH-RULE" :verdict "none"
                                 :statement "A judgement about a rule without findings." :evidence "None." :findings '()))
           (view (find "Judgement" (html-inspector-views:all-views empty) :key #'html-inspector-views:view-title :test #'equal))
           (html (html-inspector-views:view-html view)))
      (assert (search "No engine finding is attached to this judgement." html))
      (assert (notany (lambda (r) (typep (cdr r) 'c:pr-critique-finding)) (html-inspector-views:view-references view))))
    t))

(defparameter +existing-view-digests+
  '((:finding . "dd961af41b2646e3ae29686973214e31de0a3ee08d964ec07abd9d4db5aa3413")
    (:target . "477d9f58c3ebc434df300d95f2661f41aefc7dc49f5a39125796ca19cdca2c25")
    (:record . "727bd8004f49dbab586d7ff7d2bbe4a7cba055de3f37d7cd0d934a425cd21968")
    (:critique . "fbcd2309d07dd06ff26b567035aabbcbc04b8125e7013a3fbca54080381c8b48"))
  "Normalized SHA-256 of all HTML views of the review's first finding, its reconstituted target, run and Critique,
computed on an unchanged copy of 82126d5 (before the Judgement view existed) in two fresh images.")

(defun check-existing-views-unchanged (review)
  "The views of review, Finding, Evaluation Record and Critique are the ones they were before the Judgement view."
  (let* ((finding (first (c:review-findings-of review)))
         (target (c:finding-target-of finding))
         (record (first (critic:target-runs-of target)))
         (critique (first (critic:critiques-of record))))
    (flet ((titles (object) (mapcar #'html-inspector-views:view-title (html-inspector-views:all-views object))))
      (assert (equal '("PR critique") (titles review)))
      (assert (equal '("Finding") (titles finding)))
      (dolist (object (list target record critique)) (assert (equal '("Critic relations") (titles object)))))
    (loop for (key . expected) in +existing-view-digests+
          for object in (list finding target record critique)
          do (assert (string= expected (%views-digest object)) () "the ~(~A~) views changed" key))
    t))

(defparameter +record-digests+
  '(("docs/fedwiki-link-resolution/critic/pr-32-critique.json" . "99091e8c5b485ed29fa7ec3f7d5d372f15bf667a343dc6086d4ef344033f48fd")
    ("docs/fedwiki-link-resolution/critic/judgements.json" . "4ab11bc52ad906d9aecd66b7cce9ac2117c46d631b8285d06fa6ed0543f2e6c0"))
  "The recorded evaluations and judgements as committed at 82126d5.")

(defun check-records-inert ()
  "The records are unchanged, and reading and rendering them loaded neither the engine nor the page-attached system."
  (loop for (file . expected) in +record-digests+
        do (assert (string= expected (ironclad:byte-array-to-hex-string
                                      (ironclad:digest-file :sha256 (asdf:system-relative-pathname
                                                                     "dreyeck/work/fedwiki-link-resolution/critic" file))))
                   () "~A changed" file))
  (assert (not (find-package "LISP-CRITIC")))
  (assert (not (find-package "LISP-CRITIC-USER")))
  (assert (not (find-package "A-CRITIC-FOR-LISP")))
  (assert (not (asdf:registered-system "a-critic-for-lisp")))
  (assert (not (asdf:registered-system "lisp-critic")))
  t)

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
    (check-judgement-view review)
    (check-existing-views-unchanged review)
    (check-records-inert)
    (format t "~&FEDWIKI-LINK-RESOLUTION-CRITIC-PASS: ~D forms judged by all ~D rules of the real engine (digests as stored); ~D runs with findings (~D matches), the rest completed without one; every form unchanged here; every Evaluation Record reconstituted; ~D judgements kept apart; no engine loaded by reading.~%"
            (length forms) rules (length findings)
            (reduce #'+ (mapcar (lambda (f) (length (c:finding-matches-of f))) findings))
            (length (c:review-judgements-of review))))
  t)
