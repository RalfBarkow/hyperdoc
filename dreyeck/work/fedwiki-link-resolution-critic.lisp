;;;; What the real Riesbeck/Beane Lisp Critic said about the Lisp code of PR #32, as inspectable objects.
;;;;
;;;; Reads docs/fedwiki-link-resolution/critic/pr-32-critique.json, written by
;;;; scripts/record-fedwiki-link-resolution-critiques.lisp where the engine was allowed to run. Reading builds nothing that
;;;; runs: the JSON interns no symbol, the Evaluation Records and Critiques are rebuilt with the existing
;;;; RECONSTITUTE-CRITIC-RUN (so the existing Lisp Critic views apply), and no engine or page code is loaded.
;;;; Each source form is observed again here: is the recorded text still what this checkout has at that place?
;;;; Judgements are Claude's, read from a separate file, and are never mixed into the engine's Critiques.

(defpackage #:dreyeck/work/fedwiki-link-resolution/critic
  (:use #:cl)
  (:local-nicknames (#:critic #:dreyeck/lisp-critic) (#:views #:html-inspector-views))
  (:export #:read-pr-critique-review #:pr-critique-review #:pr-source-form #:pr-critique-finding #:pr-judgement
           #:review-forms-of #:review-findings-of #:review-judgements-of #:review-engine-of #:review-rules-of
           #:form-findings-of #:form-current-p #:form-url-of #:form-key-of #:form-file-of
           #:finding-rule-of #:finding-target-of #:finding-matches-of #:finding-form-of))
(in-package #:dreyeck/work/fedwiki-link-resolution/critic)

(defun %path (name) (asdf:system-relative-pathname "dreyeck/work/fedwiki-link-resolution/critic"
                                                    (format nil "docs/fedwiki-link-resolution/critic/~A" name)))
(defun %json (pathname) (with-open-file (in pathname :external-format :utf-8) (shasht:read-json in)))
(defun %list (value) (if (vectorp value) (coerce value 'list) value))
(defun %digest (string)
  (ironclad:byte-array-to-hex-string
   (ironclad:digest-sequence :sha256 (sb-ext:string-to-octets string :external-format :utf-8))))

(defclass pr-critique-review ()
  ((pull-request :initarg :pull-request :reader review-pull-request-of)
   (commit :initarg :commit :reader review-commit-of)
   (engine :initarg :engine :reader review-engine-of :documentation "Edition and file digests of the engine that ran.")
   (page-assets :initarg :page-assets :reader review-page-assets-of)
   (rules :initarg :rules :reader review-rules-of :documentation "Every rule the engine had; each was applied to every form.")
   (recording :initarg :recording :reader review-recording-of)
   (not-critiqued :initarg :not-critiqued :reader review-not-critiqued-of)
   (forms :initarg :forms :reader review-forms-of)
   (judgements :initarg :judgements :reader review-judgements-of :documentation "Claude's judgements; not engine output.")))

(defclass pr-source-form ()
  ((file :initarg :file :reader form-file-of)
   (commit :initarg :commit :reader form-commit-of)
   (form-key :initarg :form-key :reader form-key-of)
   (lines :initarg :lines :reader form-lines-of)
   (url :initarg :url :reader form-url-of)
   (text-sha256 :initarg :text-sha256 :reader form-text-sha256-of)
   (current-p :initarg :current-p :reader form-current-p
              :documentation "Whether this checkout has the recorded text at the recorded range (observed when read).")
   (rules-applied :initarg :rules-applied :reader form-rules-applied-of)
   (without-finding :initarg :without-finding :reader form-without-finding-of
                    :documentation "Completed runs without a finding: results, not omissions.")
   (failed :initarg :failed :reader form-failed-of)
   (findings :initarg :findings :accessor form-findings-of)))

(defclass pr-critique-finding ()
  ((form :initarg :form :reader finding-form-of)
   (rule :initarg :rule :reader finding-rule-of)
   (target :initarg :target :reader finding-target-of
           :documentation "The reconstituted CRITIC-TARGET: its run is the Evaluation Record, its Critiques the engine's.")
   (matches :initarg :matches :reader finding-matches-of
            :documentation "Per Critique: the matched subform, its path in the form, whether it is quoted data, the recommendation.")))

(defclass pr-judgement ()
  ((id :initarg :id :reader judgement-id-of)
   (author :initarg :author :reader judgement-author-of)
   (rule :initarg :rule :reader judgement-rule-of)
   (verdict :initarg :verdict :reader judgement-verdict-of)
   (statement :initarg :statement :reader judgement-statement-of)
   (evidence :initarg :evidence :reader judgement-evidence-of)
   (findings :initarg :findings :reader judgement-findings-of :documentation "The engine findings this judgement is about.")))

(defun %current-p (file range text-sha256)
  (let ((path (asdf:system-relative-pathname "dreyeck/work/fedwiki-link-resolution/critic" file)))
    (and (probe-file path)
         (let ((text (with-open-file (in path :external-format :utf-8)
                       (let ((s (make-string (file-length in)))) (subseq s 0 (read-sequence s in)))))
               (start (elt range 0)) (end (elt range 1)))
           (and (<= end (length text)) (string= text-sha256 (%digest (subseq text start end))))))))

(defun read-pr-critique-review (&key (record (%path "pr-32-critique.json")) (judgements (%path "judgements.json")))
  "The recorded PR #32 critique as objects. Runs no engine; loads no page code."
  (let* ((data (%json record))
         (forms
           (loop for file in (%list (gethash "files" data))
                 append (loop for form-data in (%list (gethash "forms" file))
                              for runs = (gethash "runs" form-data)
                              collect (let ((form (make-instance
                                                   'pr-source-form
                                                   :file (gethash "file" file) :commit (gethash "commit" file)
                                                   :form-key (gethash "form-key" form-data)
                                                   :lines (%list (gethash "lines" form-data)) :url (gethash "url" form-data)
                                                   :text-sha256 (gethash "text-sha256" form-data)
                                                   :current-p (%current-p (gethash "file" file) (gethash "range" form-data)
                                                                          (gethash "text-sha256" form-data))
                                                   :rules-applied (gethash "rules-applied" runs)
                                                   :without-finding (gethash "completed-without-finding" runs)
                                                   :failed (%list (gethash "failures" form-data)))))
                                        (setf (form-findings-of form)
                                              (mapcar (lambda (finding)
                                                        (make-instance 'pr-critique-finding
                                                                       :form form :rule (gethash "rule" finding)
                                                                       :target (critic:reconstitute-critic-run (gethash "run" finding))
                                                                       :matches (%list (gethash "matches" finding))))
                                                      (%list (gethash "findings" form-data))))
                                        form))))
         (all-findings (loop for form in forms append (form-findings-of form))))
    (make-instance 'pr-critique-review
                   :pull-request (gethash "pull-request" data) :commit (gethash "commit" data)
                   :engine (gethash "engine" data) :page-assets (gethash "page-assets" data)
                   :rules (%list (gethash "rules" data)) :recording (gethash "recording" data)
                   :not-critiqued (%list (gethash "not-critiqued" data)) :forms forms
                   :judgements
                   (when (probe-file judgements)
                     (mapcar (lambda (j)
                               (make-instance 'pr-judgement
                                              :id (gethash "id" j) :author (gethash "author" j) :rule (gethash "rule" j)
                                              :verdict (gethash "verdict" j) :statement (gethash "statement" j)
                                              :evidence (gethash "evidence" j)
                                              :findings (remove (gethash "rule" j) all-findings :key #'finding-rule-of
                                                                :test-not #'string=)))
                             (%list (gethash "judgements" (%json judgements))))))))

(defun review-findings-of (review) (loop for form in (review-forms-of review) append (form-findings-of form)))

(defun %recommendations (finding)
  (remove-duplicates (mapcar (lambda (m) (gethash "recommendation" m)) (finding-matches-of finding)) :test #'equal))

;;; Views: the relation PR form → rule → Evaluation Record → match → recommendation, and Judgements apart.

(views:defview pr-critique-review-view (review pr-critique-review)
  (views:html-view :title "PR critique" :priority 1
    (let ((findings (review-findings-of review)))
      (views:html
        (:h2 (views:esc (format nil "~A: the real Riesbeck/Beane Lisp Critic" (review-pull-request-of review))))
        (:p (views:esc (format nil "Commit ~A. ~D top-level forms, each judged by all ~D rules of the engine: ~D runs without a finding, ~D runs with a finding, ~D failed. Every number is a result of a run, not an estimate."
                               (review-commit-of review) (length (review-forms-of review)) (length (review-rules-of review))
                               (reduce #'+ (mapcar #'form-without-finding-of (review-forms-of review)))
                               (length findings)
                               (reduce #'+ (mapcar (lambda (f) (length (form-failed-of f))) (review-forms-of review))))))
        (:table :class "inspector-table"
          (:tr (:th "lines") (:th "form") (:th "rule") (:th "recommendation (engine text)"))
          (dolist (finding findings)
            (let ((form (finding-form-of finding)))
              (views:html
                (:tr (:td (:a :href (form-url-of form) :target "_blank"
                              (views:esc (format nil "~A ~{~A~^–~}" (form-file-of form) (form-lines-of form)))))
                     (:td (views:object-ref form :display (form-key-of form)))
                     (:td (views:object-ref finding :display (finding-rule-of finding)))
                     (:td (views:esc (first (%recommendations finding)))))))))
        (:h3 "Judgements (Claude, not engine output)")
        (:table :class "inspector-table"
          (dolist (judgement (review-judgements-of review))
            (views:html
              (:tr (:td (views:object-ref judgement :display (judgement-rule-of judgement)))
                   (:td (views:esc (judgement-verdict-of judgement)))
                   (:td (views:esc (judgement-statement-of judgement)))))))))))

(views:defview pr-critique-finding-view (finding pr-critique-finding)
  (views:html-view :title "Finding" :priority 1
    (let ((form (finding-form-of finding)))
      (views:html
        (:p (views:esc (format nil "Rule ~A, applied by the engine to " (finding-rule-of finding)))
            (:a :href (form-url-of form) :target "_blank"
                (views:esc (format nil "~A lines ~{~A~^–~}" (form-file-of form) (form-lines-of form))))
            (views:esc (format nil " at ~A (~:[changed since recorded~;unchanged in this checkout~])."
                               (form-commit-of form) (form-current-p form))))
        (:p "Evaluation Record and Critiques: " (views:object-ref (finding-target-of finding) :display "reconstituted run"))
        (:table :class "inspector-table"
          (:tr (:th "matched") (:th "path") (:th "quoted data") (:th "recommendation"))
          (dolist (m (finding-matches-of finding))
            (views:html
              (:tr (:td (:tt (views:esc (gethash "matched" m))))
                   (:td (views:esc (princ-to-string (%list (gethash "path" m)))))
                   (:td (views:esc (if (eq t (gethash "quoted" m)) "yes" "no")))
                   (:td (views:esc (gethash "recommendation" m)))))))))))
