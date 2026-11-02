;;;; The worked example of the assessment: Konrad Hinsen's 58a2b2c "Catch more name service errors", against the real source of this checkout, from recorded
;;;; evidence and the ledger. It needs no Git repository (a Nix build has none) and runs no library code. It states what is true of the commit and of the fork
;;;; in a way that stays true when the open draft change to INITIALIZE-FEDWIKI (RalfBarkow/hyperdoc#15) is merged: the fork's list is then an extension of the
;;;; old one rather than the old one.
(in-package #:dreyeck/upstream-assessment/tests)

(defparameter +example-commit+ "58a2b2c66f0f5a0900a32910e5991e7d1833d9ed")
(defun checkout-root () (uiop:ensure-directory-pathname (asdf:system-source-directory "dreyeck")))
(defun in-checkout (path) (merge-pathnames path (checkout-root)))

(defun example-run ()
  (let ((root (checkout-root)))
    (ua:assess-upstream :fork-root root :policy (ua:default-ownership-policy root) :commits (list +example-commit+)
                        :state (ua:read-state (in-checkout "docs/upstream-intake/state.lisp-data"))
                        :ledger (ua:read-ledger (in-checkout "docs/upstream-intake/ledger.lisp-data"))
                        :recorded-evidence (ua:read-evidence-directory (in-checkout "docs/upstream-intake/evidence/")))))

(defun example-change () (first (ua:commit-assessment-changes (first (ua:intake-run-commits (example-run))))))

(defun check-example-upstream-change ()
  (let* ((run (example-run)) (assessment (first (ua:intake-run-commits run))) (evidence (ua:commit-assessment-evidence assessment))
         (c (ua:change-assessment-change (example-change))))
    (assert (eq :new-commits (ua:intake-run-status run)))
    (assert (equal +example-commit+ (ua:commit-evidence-sha evidence)))
    (assert (eq :recorded (ua:commit-evidence-availability evidence)) () "the commit's objects are not in this checkout: it is known from recorded evidence")
    (assert (equal '("9f919fc64f13a9101c970bbea10a2524576723d2") (ua:commit-evidence-parents evidence)))
    (assert (equal "Catch more name service errors" (ua:commit-evidence-subject evidence)))
    (assert (equal "function:make-fedwiki" (ua:definition-change-key c))) (assert (equal "hyperbook-fedwiki/fedwiki.lisp" (ua:definition-change-path c)))
    ;; the changed handler: ns-host-not-found-error becomes ns-error in a type list, and nothing else differs
    (assert (= 1 (length (ua:definition-change-fragments c))))
    (destructuring-bind (before . after) (first (ua:definition-change-fragments c))
      (assert (equal '("or" "stream-error" "usocket:timeout-error" "usocket:ns-host-not-found-error" "shasht:shasht-invalid-char") before))
      (assert (equal '("or" "stream-error" "usocket:timeout-error" "usocket:ns-error" "shasht:shasht-invalid-char") after)))
    ;; the first connection attempt is handled differently and is untouched
    (destructuring-bind (first-handler second-handler) (ua:definition-change-handlers c)
      (assert (not (getf first-handler :changed-p))) (assert (getf second-handler :changed-p))
      (let ((first-attempt (getf first-handler :after)) (sitemap (getf second-handler :after)))
        (assert (equal '("usocket:socket-connect" "usocket:socket-close") (getf first-attempt :protected-calls)))
        (assert (equal '("usocket:connection-refused-error" "usocket:ns-host-not-found-error") (getf first-attempt :clauses)))
        (assert (equal '("fetch-sitemap" "fetch-plugin-data") (subseq (getf sitemap :protected-calls) 0 2)))
        (assert (search "usocket:ns-error" (first (getf sitemap :clauses)))))))
  t)

(defun check-example-in-the-fork ()
  (let* ((change (example-change)) (s (ua:change-assessment-situation change)) (o (ua:change-assessment-ownership change)))
    ;; its definition stands in the fork, but the changed list is in another definition: the upstream hunk has no place
    (assert (eq :replaced (ua:fork-situation-relation s)) () "~S" (ua:fork-situation-relation s))
    (let ((fragment (first (ua:fork-situation-fragments s))))
      (assert (member (getf fragment :status) '(:before-elsewhere :extended-elsewhere)))
      (assert (equal '("hyperbook-fedwiki/fedwiki.lisp" "function:initialize-fedwiki") (subseq (first (getf fragment :elsewhere)) 0 2))))
    (assert (equal '("hyperbook/fedwiki") (ua:change-assessment-owners change)))
    ;; Without an ownership inventory the library path is upstream-owned; with docs/code-ownership/inventory.lisp-data (which this checkout has) the inventory decides case by case:
    ;; MAKE-FEDWIKI's neighbours are recorded as a reusable extension that stays in hyperbook/fedwiki until upstream has the seam.
    (let ((inventory-p (probe-file (in-checkout "docs/code-ownership/inventory.lisp-data"))))
      (assert (eq (if inventory-p :reusable-extension :upstream-owned) (getf o :category)) () "~S" (getf o :category)))
    (assert (member "hyperbook/fedwiki" (let ((should (getf o :should-own))) (if (listp should) should (list should))) :test #'equal))
    ;; the dependents and tests that may be affected are real systems of this checkout
    (let ((impact (ua:change-assessment-impact change)))
      (assert (member "hyperbook/fedwiki" (ua:impact-systems impact) :test #'equal))
      (assert (member "dreyeck/wiki-link/tests" (ua:impact-tests impact) :test #'equal))
      (assert (find "function:get-fedwiki" (ua:impact-callers impact) :key #'second :test #'equal)
              () "GET-FEDWIKI makes the sites through MAKE-FEDWIKI: a definition that mentions the changed one"))
    ;; a proposal by rule, and the recorded decisions beside it
    (assert (eq :defer (ua:decision-kind (ua:change-assessment-proposal change))))
    (assert (eq :proposed (ua:decision-status (ua:change-assessment-proposal change)))))
  t)

(defun check-example-decisions ()
  (let* ((recorded (ua:change-assessment-recorded (example-change))))
    (assert (equal '(:defer :prepare-upstream-contribution) (sort (mapcar #'ua:decision-kind recorded) #'string<)))
    (assert (every (lambda (d) (eq :proposed (ua:decision-status d))) recorded) () "no decision here has been accepted or executed")
    (dolist (d recorded)
      (assert (ua:decision-evidence d)) (assert (ua:decision-verification d)) (assert (ua:decision-required-migration d))
      (assert (every (lambda (claim) (member (ua:claim-status claim) ua:+epistemic-statuses+)) (ua:decision-evidence d))))
    (let ((statuses (remove-duplicates (mapcar #'ua:claim-status (ua:decision-evidence (find :defer recorded :key #'ua:decision-kind))))))
      (assert (= 4 (length statuses)) () "the decision on the class keeps observation, derivation, inference and hypothesis apart: ~S" statuses))
    ;; observing again records nothing twice
    (let ((again (ua:change-assessment-recorded (example-change))))
      (assert (equal (mapcar #'ua:decision-id recorded) (mapcar #'ua:decision-id again)))))
  t)

(defun tsv-rows (file)
  (mapcar (lambda (line) (uiop:split-string line :separator '(#\Tab))) (remove "" (uiop:read-file-lines file) :test #'string=)))

(defun check-example-reused-analysis ()
  "The analysis of RalfBarkow/hyperdoc#15 is reused as it was: imported byte for byte, and what the ledger says of it is what it says."
  (let* ((directory (in-checkout "docs/upstream-intake/evidence/58a2b2c/")) (imported (uiop:read-file-lines (merge-pathnames "IMPORTED.txt" directory))))
    (let ((checked 0))
      (dolist (line imported)
        (let ((body (string-left-trim "# " line)))
          (when (and (> (length body) 66) (every (lambda (c) (digit-char-p c 16)) (subseq body 0 64)) (char= #\Space (char body 64)))
            (let* ((rest (string-left-trim " " (subseq body 64))) (name (subseq rest 0 (position #\Space rest))))
              (unless (char= #\( (char name 0))
                (let ((file (merge-pathnames name directory)))
                  (assert (probe-file file) () "~A is imported but not there" name)
                  (assert (equal (subseq body 0 64) (string-downcase (ironclad:byte-array-to-hex-string (ironclad:digest-file :sha256 file))))
                          () "~A is not what was imported" name)
                  (incf checked)))))))
      (assert (= 3 checked) () "three files are imported and checked"))
    ;; what the decisions say about the matrix is what the matrix says
    (let* ((rows (tsv-rows (merge-pathnames "pr15-matrix.tsv" directory))) (header (first rows))
           ;; rows are the checkouts, columns the scenarios
           (cell (lambda (scenario label)
                   (nth (position scenario header :test #'string=) (find-if (lambda (row) (search label (first row))) (rest rows))))))
      (assert (uiop:string-prefix-p "DIED" (funcall cell "probe-real" "58a2b2c")) () "upstream 58a2b2c ends the process in the first attempt")
      (assert (uiop:string-prefix-p "DIED" (funcall cell "sitemap-try-again" "9f919fc")))
      (assert (uiop:string-prefix-p "S(" (funcall cell "sitemap-try-again" "58a2b2c")) () "...and survives it in the site-map step")
      (assert (uiop:string-prefix-p "S(" (funcall cell "probe-real" "PR #15")) () "the fork with the open change survives both")
      (assert (uiop:string-prefix-p "DIED" (funcall cell "probe-real" "0a7d4de")) () "the fork at dreyeck.ch ends the process in the first attempt")))
  t)

(defun check-example-nothing-moved ()
  "The assessment moved neither the last examined state nor the references of the library contract."
  (let ((state (ua:read-state (in-checkout "docs/upstream-intake/state.lisp-data")))
        (contract (uiop:read-file-string (in-checkout "dreyeck/tests/hyperdoc-library-delta.lisp"))))
    (assert (equal "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8" (ua:state-last-examined state)))
    (assert (search "8a1149197fabcb1ab5622316f09c5a60c2d3f1f8" contract) () "the contract's upstream reference is the last examined state")
    (assert (search "401953522ec503cf78764bddc5534f7a9f16fd22" contract) () "+PREVIOUS+ is where it was")
    (assert (not (search +example-commit+ contract)) () "the contract does not name the new commit"))
  t)

(defun rendered-views (object)
  (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil))
    (format nil "~{~A~^~%~}" (loop for view in (html-inspector-views:all-views object)
                                    when (typep view 'html-inspector-views:html-view) collect (html-inspector-views:view-html view)))))

(defun check-example-views ()
  (let* ((run (example-run)) (assessment (first (ua:intake-run-commits run))) (change (example-change)) (decision (first (ua:change-assessment-recorded change))))
    (dolist (needle '("Upstream intake" "58a2b2c")) (assert (search needle (rendered-views run)) () "the run does not show ~S" needle))
    (let ((html (rendered-views assessment)))
      (dolist (needle '("Catch more name service errors" "recorded" "Git ancestry and source adoption are different relations" "function:make-fedwiki" "replaced"))
        (assert (search needle html) () "the commit view does not show ~S" needle)))
    (let ((html (rendered-views change)))
      (dolist (needle '("1. What upstream changed" "usocket:ns-host-not-found-error" "usocket:ns-error" "usocket:socket-connect" "fetch-sitemap"
                        "2. Where it stands in the fork now" "function:initialize-fedwiki" "3. ASDF owner now, and who should own it" "hyperbook/fedwiki"
                        "4. What may be affected" "dreyeck/wiki-link/tests" "5. Decision" "defer" "prepare-upstream-contribution" "The chain as a Topicmap"))
        (assert (search needle html) () "the change view does not show ~S" needle)))
    (let ((html (rendered-views decision)))
      (dolist (needle '("A decision is not its execution" "observed in the source" "mechanically derived" "design inference" "working hypothesis" "Required migration" "Verification"))
        (assert (search needle html) () "the decision view does not show ~S" needle)))
    ;; reading offers no control
    (dolist (object (list run assessment change decision))
      (dolist (view (html-inspector-views:all-views object))
        (when (and (typep view 'html-inspector-views:html-view) (member (html-inspector-views:view-title view)
                                                                        '("Upstream intake run" "Upstream commit" "Change in the fork" "Decision" "Claim") :test #'equal))
          (let ((html (progv (list (find-symbol "*SERVER-PARAMETERS*" :hyperbook/server)) (list (list "700px" nil)) (html-inspector-views:view-html view))))
            (dolist (control '("<button" "<form" "<input")) (assert (not (search control html)) () "view ~A has ~A" (html-inspector-views:view-title view) control)))))))
  ;; the chain: eight steps, each linked to the next with an epistemic status
  (let* ((workspace (dreyeck/inspector/upstream-assessment:change-chain-workspace (example-change))) (html (rendered-views workspace)))
    (dolist (label '("Upstream commit" "Changed definition function:make-fedwiki" "Current definition: replaced" "ASDF owner hyperbook/fedwiki" "Impact:" "Decision:" "Required migration" "Verification"))
      (assert (search label html) () "the chain does not show ~S" label))
    (assert (= 8 (length (dreyeck/inspector/upstream-assessment:chain-steps (example-change))))))
  t)

(defun run-example-tests ()
  (check-example-upstream-change)
  (check-example-in-the-fork)
  (check-example-decisions)
  (check-example-reused-analysis)
  (check-example-nothing-moved)
  (check-example-views)
  (format t "~&UPSTREAM-ASSESSMENT-EXAMPLE-PASS: 58a2b2c from recorded evidence against the real source: the changed handler, the untouched first attempt, the replaced definition, owners, impact, decisions, the reused analysis, nothing moved, the views and the chain.~%")
  t)
