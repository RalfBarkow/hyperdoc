;;;; The Lisp Critic on the federated context: observation, judgement and
;;;; recommendation stay three kinds of record, a judgement holds through its
;;;; basis and not its label, and observing changes nothing it observes.

(defpackage #:dreyeck/lisp-critic/federated-context/tests
  (:use #:cl)
  (:local-nicknames (#:lc #:dreyeck/lisp-critic/federated-context)
                    (#:rec #:dreyeck/lisp-critic/recorded)
                    (#:critic #:dreyeck/lisp-critic))
  (:export #:run-tests))

(in-package #:dreyeck/lisp-critic/federated-context/tests)

(defun %result (observation key) (getf (getf observation :result) key))

(defun %with-items (observation)
  (mapcar (lambda (mode) (getf mode :with-item)) (%result observation :modes)))

(defun %read-digests ()
  "Every file the critic reads, with the digest of its bytes now."
  (mapcar (lambda (pathname) (cons pathname (rec::%file-digest pathname)))
          (cons (asdf:system-relative-pathname "dreyeck" lc::+snapshot-file+)
                (mapcar #'hyperdoc::source-code-pathname (lc::%book-pages)))))

(defun %page-text ()
  (uiop:read-file-string (hyperdoc::source-code-pathname (lc::%criticised-page)) :external-format :utf-8))

(defun check-source-identity ()
  "Every form a recorded observation or judgement names is in the 3e84471c
snapshot, identified structurally; re-observed now, each says how it relates
to the form as recorded."
  (let ((snapshot (lc:source-snapshot)))
    (assert (equal "3e84471c" (gethash "state" snapshot)))
    (assert (= 1 (length (remove-duplicates (map 'list (lambda (identity) (gethash "source-sha256" identity))
                                                 (gethash "occurrences" snapshot))
                                            :test #'string=)))))
  (dolist (record (append (lc:prior-observations) (lc:judgements)))
    (dolist (target (getf record :targets))
      (assert (equal target (gethash "form-key" (lc:recorded-target target))))))
  ;; The C1b target, as 3e84471c declared it, is absent from the source now.
  (let ((now (lc:target-now 'context-relation-attribution)))
    (assert (equal "(:DEFINITION CONTEXT-RELATION-ATTRIBUTION)" (getf now :target)))
    (assert (eq :form-absent (getf now :status)))
    (assert (eq :observed (getf now :evidence-status))))
  ;; Each relation an identity can have to the source now, for one current form.
  (let* ((form (find-if (lambda (form) (getf form :occurrence)) (rec:page-forms (lc::%criticised-page))))
         (identity (alexandria:alist-hash-table (rec::%occurrence-identity (getf form :occurrence)) :test 'equal)))
    (flet ((status (changes)
             (let ((copy (alexandria:copy-hash-table identity)))
               (loop for (key value) on changes by #'cddr do (setf (gethash key copy) value))
               (nth-value 1 (rec::%observe-now copy)))))
      (assert (eq :recorded-snapshot (status nil)))
      (assert (eq :form-unchanged (status (list "source-sha256" "0"))))
      (assert (eq :form-changed (status (list "source-sha256" "0" "text" "(changed)"))))
      (assert (eq :form-absent (status (list "form-key" "(:DEFINITION NO-SUCH-FORM)"))))))
  t)

(defun check-current-observations ()
  "What the probes observe in this commit's source."
  (let ((c1a (lc:observe-attribution-tests)))
    (assert (= 1 (%result c1a :count)))
    (assert (equal "(:DEFINITION CONTEXT-ITEM-ATTRIBUTION)" (gethash "form-key" (first (getf c1a :targets))))))
  (assert (zerop (%result (lc:observe-links-by-bare-item) :count)))
  (let ((c4 (lc:observe-event-summary-field)))
    (assert (zerop (%result c4 :writers)))
    (assert (zerop (%result c4 :readers)))
    (assert (not (%result c4 :field-present-p))))
  t)

(defun check-probes-discriminate ()
  "Each source probe counts the condition it names: one more occurrence in the
text, one more observed; a search keyed otherwise, or through one page's own
items, not observed."
  (let ((text (%page-text)))
    (flet ((with (form) (format nil "~A~%~A~%" text form)))
      (assert (= (1+ (%result (lc:observe-attribution-tests) :count))
                 (%result (lc:observe-attribution-tests (with "(search \"via Thompson\" \"\")")) :count)))
      (let ((lookup (lc:observe-links-by-bare-item
                     (with "(find \"\" (gethash \"links\" (gethash \"observed\" (context-data nil))) :key (lambda (link) (gethash \"item\" link)))"))))
        (assert (= 1 (%result lookup :count)))
        (assert (rest (getf (first (%result lookup :operations)) :pages-in-collection))))
      (dolist (other '("(find \"\" (gethash \"items\" nil) :key (lambda (link) (gethash \"item\" link)))"
                       "(find \"\" (gethash \"links\" (gethash \"observed\" (context-data nil))) :key (lambda (link) (gethash \"id\" link)))"))
        (assert (zerop (%result (lc:observe-links-by-bare-item (with other)) :count))))
      (let ((c4 (lc:observe-event-summary-field
                 (with "(list (context-table \"summary\" \"\") (gethash \"summary\" nil) (setf (gethash \"summary\" nil) nil))"))))
        (assert (= 1 (%result c4 :writers)))
        (assert (= 1 (%result c4 :readers)))
        (assert (%result c4 :field-present-p)))))
  t)

(defun check-f1-discriminates ()
  "The F1 witness tells the reading's resolution from one that finds the
source items. While F1 stands the reading finds none of them; when F1 is
fixed, the reading's count will equal the control's and this check must
change with that fix."
  (let* ((f1 (lc:f1-discrimination))
         (original (getf f1 :original)) (control (getf f1 :control)) (restored (getf f1 :restored)))
    (dolist (observation (list original control restored))
      (assert (equal '(4 4) (mapcar (lambda (mode) (getf mode :trail-associations))
                                    (%result observation :modes)))))
    (assert (equal '(4 4) (%with-items control)))
    (assert (equal (%with-items original) (%with-items restored)))
    (assert (equal '(0 0) (%with-items original)))
    (assert (eq :reading (%result original :resolution)))
    (assert (eq :instrument (%result control :resolution))))
  t)

(defun check-basis-integrity ()
  "A judgement is tied to its evidence by its basis. Withhold the observation
it rests on, or let it name a target its observations did not observe, and
resolving it signals. Changing its evidence-status label changes nothing."
  (dolist (judgement (lc:judgements))
    (assert (every (lambda (observation) (eq :observed (getf observation :evidence-status)))
                   (lc:resolve-judgement-basis judgement))))
  (let* ((c1b (lc:judgement "C1b"))
         (observation (first (lc:resolve-judgement-basis c1b))))
    ;; source target <- observed result <- interpreted judgement
    (assert (eq :c1b (getf observation :id)))
    (assert (member "(:DEFINITION CONTEXT-RELATION-ATTRIBUTION)" (getf observation :targets) :test #'equal))
    (assert (lc:recorded-target "(:DEFINITION CONTEXT-RELATION-ATTRIBUTION)"))
    (assert (handler-case (progn (lc:resolve-judgement-basis
                                  c1b (remove :c1b (lc:prior-observations) :key (lambda (o) (getf o :id))))
                                 nil)
              (error () t)))
    (assert (handler-case (progn (lc:resolve-judgement-basis
                                  (append (list :targets (list "(:DEFINITION DERIVE-FEDERATED-DATA)")) c1b))
                                 nil)
              (error () t)))
    (let ((relabelled (copy-list c1b)))
      (setf (getf relabelled :evidence-status) :observed)
      (assert (equal (lc:resolve-judgement-basis c1b) (lc:resolve-judgement-basis relabelled)))))
  t)

(defun %critic-object-p (value)
  (typep value '(or critic:critique critic:critic-rule critic:critic-target critic:lisp-critic-run-record)))

(defun %tree-contains-p (tree predicate)
  (or (funcall predicate tree)
      (and (consp tree)
           (or (%tree-contains-p (car tree) predicate) (%tree-contains-p (cdr tree) predicate)))))

(defun check-kinds-apart ()
  "Observations, judgements and the recommendation are three kinds of record,
with their own provenance, and none of them is an engine's."
  (let ((observations (append (lc:prior-observations)
                              (list (lc:observe-attribution-tests) (lc:observe-links-by-bare-item)
                                    (lc:observe-event-summary-field) (lc:observe-trail-source-items))))
        (judgements (lc:judgements))
        (proposal (lc:reduction-proposal)))
    (dolist (observation observations)
      (assert (eq :observed (getf observation :evidence-status)))
      (assert (getf observation :result))
      (assert (not (getf observation :basis)))
      (assert (member (getf (getf observation :provenance) :kind) '(:claude-code-session :executed-probe)))
      (assert (getf (getf observation :provenance) :observation-time)))
    (dolist (judgement judgements)
      (assert (eq :interpreted (getf judgement :evidence-status)))
      (assert (getf judgement :basis))
      (assert (getf judgement :statement))
      (assert (not (getf judgement :result)))
      (let ((provenance (getf judgement :provenance)))
        (assert (eq :llm-critic (getf provenance :kind)))
        (assert (equal "Claude Code" (getf provenance :critic)))
        (assert (equal "Opus 5.5 Extra" (getf provenance :model)))
        (assert (integerp (getf provenance :recorded-at)))
        (assert (not (getf provenance :observation-time)))
        (assert (equal '(:target-commit "3e84471c") (getf provenance :scope)))))
    (assert (not (nth-value 2 (get-properties proposal '(:evidence-status)))))
    (assert (getf proposal :predictions))
    (assert (eq :llm-critic (getf (getf proposal :provenance) :kind)))
    (assert (notany (lambda (record) (%tree-contains-p record #'%critic-object-p))
                    (append observations judgements (list proposal)))))
  t)

(defun check-page ()
  "The reading shows the three kinds apart and labels the judgements as an
LLM's; every expression on it evaluates."
  (let* ((book (hyperbook:find-hyperbook "dreyeck/lisp-critic/reading" :signal-error? t))
         (page (hyperbook:find-page book "Lisp Critic on the Federated Context" :signal-error? t))
         (text (uiop:read-file-string (hyperdoc:file-of page) :external-format :utf-8))
         (*package* (find-package :dreyeck/lisp-critic/federated-context)))
    (dolist (phrase '("3e84471c" "Claude" "LLM" "not evidence"))
      (assert (search phrase text) () "The page does not say ~S." phrase))
    (dolist (element (plump:get-elements-by-tag-name (plump:parse text) "a"))
      (let ((expression (plump:attribute element "expr")))
        (when expression
          (assert (not (typep (hyperdoc::parse-and-eval expression) 'condition)))))))
  t)

(defun run-tests ()
  (let ((before (%read-digests)))
    (check-source-identity)
    (check-current-observations)
    (check-probes-discriminate)
    (check-f1-discriminates)
    (check-basis-integrity)
    (check-kinds-apart)
    (check-page)
    (assert (equal before (%read-digests)) () "Observing changed a source the critic reads."))
  (format t "~&LISP-CRITIC-FEDERATED-CONTEXT-PASS: 3e84471c targets identified structurally and re-observed; probes count C1a 1, C1b 0, C4 absent now and discriminate; F1 witness discriminates; judgements resolve only through their basis; observation, judgement and recommendation apart, none an engine's; criticised source unchanged.~%")
  t)
